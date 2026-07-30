#pragma once

#include "lua/scripts/luajit_sync.hpp"

class DuskForgeFunctions {
public:
	static void init(lua_State* L);
	static int luaDuskForgeCraft(lua_State* L); // DuskForge.craft(player, recipeId, container)
};
