#include "lua/functions/items/forge_functions.hpp"

#include "lua/functions/lua_functions_loader.hpp"
#include "items/forge.hpp"
#include "items/item.hpp"
#include "creatures/players/player.hpp"
#include "lua/scripts/scripts.hpp"

void DuskForgeFunctions::init(lua_State* L) {
	Lua::registerClass(L, "DuskForge", "", nullptr);
	Lua::registerMethod(L, "DuskForge", "craft", DuskForgeFunctions::luaDuskForgeCraft);
}

int DuskForgeFunctions::luaDuskForgeCraft(lua_State* L) {
	// DuskForge.craft(player, recipeId, container)
	// Params:
	// 1 = Player (userdata)
	// 2 = recipeId (number)
	// 3 = container (Item userdata) - optional

	const auto player = Lua::getUserdataShared<Player>(L, 1);
	if (!player) {
		lua_pushboolean(L, 0);
		return 1;
	}

	const uint32_t recipeId = Lua::getNumber<uint32_t>(L, 2);
	std::shared_ptr<Item> container = Lua::getUserdataShared<Item>(L, 3);

	// call DuskForge (implementation to be completed)
	auto item = g_duskForge().craft(recipeId, player, container);

	if (!item) {
		lua_pushnil(L);
	} else {
		Lua::pushUserdata<Item>(L, item.get());
		Lua::setItemMetatable(L, -1, item);
	}
	return 1;
}
