package vm.lua;

#if js
import fengari.State;
#end

#if linc_luajit
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
#end

#if cpp
@:headerCode('#include "linc_luajit.h"')
#end
class Thread {
	public var ref(default, null):State;
	public function new(ref) this.ref = ref;

}
