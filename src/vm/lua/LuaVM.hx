package vm.lua;

import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import haxe.Exception;

import haxe.DynamicAccess;


class LuaException extends Exception {}

class LuaVM {
	public var version(default, never):String = Lua.version();

	public static var l:State;
	static var funcs = [];

	public function new() {
		l = LuaL.newstate();
		LuaL.openlibs(l);

		Lua.init_callbacks(l);
	}

	#if tink_core
	public function tryRun(s, ?g)
		return tink.core.Error.catchExceptions(run.bind(s, g));

	public function tryCall(n, a)
		return tink.core.Error.catchExceptions(call.bind(n, a));
	#end

	public function run(script:String, ?globals:DynamicAccess<Any>):Any {
		if(globals != null) for(key in globals.keys()) setGlobalVar(key, globals.get(key));
		//if(luaL_dostring(l, script) == OK) return getReturnValues(l) else throw getErrorMessage(l);
		if(LuaL.dostring(l,script)!=0)
			throw getErrorMessage(l);
		else
			return getReturnValues(l);
	}

	public function runFile(script:String, ?globals:DynamicAccess<Any>):Any {
		if(globals != null) for(key in globals.keys()) setGlobalVar(key, globals.get(key));
		//if(luaL_dostring(l, script) == OK) return getReturnValues(l) else throw getErrorMessage(l);
		if(LuaL.dofile(l,script)!=0)
			throw getErrorMessage(l);
		else
			return getReturnValues(l);
	}

	public function call(name:String, args:Array<Any>, ?type: String):Any {
		var result : Any = null;
		Lua.getglobal(l, name);
		for(arg in args) Convert.toLua(l, arg);
		result = Lua.pcall(l, args.length, 1, 1);
		var luaError = Lua.tostring(l,result);
		var haxeError = getErrorMessage(l);
		if(luaError!=null && haxeError!=null){
			throw new LuaException(luaError);
		}
		if(result != null){
			return convert(result,type);
		}else{
			return null;
		}
	}

	// https://notabug.org/endes/haxe-lua-plugins/src/master/src/beartek/lua_plugins/Luaplugin.hx
	// Credit to endes
	private function convert(v : Any, type : String) : Dynamic {
    if( Std.is(v, String) && type != null ) {
      var v : String = v;
      if( type.substr(0, 4) == 'array' ) {
        if( type.substr(4) == 'float' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Float> = new Array();

          for( vars in array ) {
            array2.push(Std.parseFloat(vars));
          }

          return array2;
        } else if( type.substr(4) == 'int' ) {
          var array : Array<String> = v.split(',');
          var array2 : Array<Int> = new Array();

          for( vars in array ) {
            array2.push(Std.parseInt(vars));
          }

          return array2;
        } else {
          var array : Array<String> = v.split(',');
          return array;
        }
      } else if( type == 'float' ) {
        return Std.parseFloat(v);
      } else if( type == 'int' ) {
        return Std.parseInt(v);
      } else if( type == 'bool' ) {
        if( v == 'true' ) {
          return true;
        } else {
          return false;
        }
      } else {
        return v;
      }
    } else {
      return v;
    }
  }


	public function setGlobalVar(name:String, value:Any) {
		Convert.toLua(l, value);
		Lua.setglobal(l, name);
	}

	public function getGlobalVar(name:String, ?type:String):Dynamic{
		var result:Any = null;
		Lua.getglobal(l,name);
		result = Convert.fromLua(l,0);

		if(result!=null){
			return convert(result,type);
		}else{
			return null;
		}
	}

	public function unsetGlobalVar(name:String) {
		Lua.pushnil(l);
		Lua.setglobal(l, name);
	}

	public function destroy() {
		trace("closed lua");
		Lua.close(l);
		l = null;
	}


	static function getReturnValues(l) {
		var lua_v:Int;
		var v:Any = null;
		while((lua_v = Lua.gettop(l)) != 0) {
			v = Convert.fromLua(l, lua_v);
			Lua.pop(l, 1);
		}
		// returns the first value (in case of multi return) returned from the Lua function
		return v;
	}

	static function getErrorMessage(l) {
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

}


/**
 *
 *  Stack is pushed downwards, i.e.:
 *    Push: add element to the top
 *    Pop: remove element from the top
 *
 *  Visualization of the Stack:
 *
 *  -- Top of stack, last pushed / newest element, index -1, index n
 *  --
 *  --
 *  --
 *  --
 *  -- Bottom of stack, first pushed / oldest element, index 1, index -n
 *
 */
