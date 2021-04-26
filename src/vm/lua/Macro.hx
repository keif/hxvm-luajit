package vm.lua;

import haxe.macro.Expr;
#if linc_luajit
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
#end


class Macro {
	public static macro function loopTable(l:Expr, v:Expr, body:Expr) {
		return macro {
			Lua.pushnil($l);
			while(Lua.next($l, $v < 0 ? $v - 1 : $v) != 0) {
				$body;
				Lua.pop($l, 1);
			}
		}
	}
}
