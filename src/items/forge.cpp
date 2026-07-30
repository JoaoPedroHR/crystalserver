#include "items/forge.hpp"

#include "items/item.hpp"
#include "lua/scripts/scripts.hpp"
#include "lua/functions/lua_functions_loader.hpp"
#include "lua/scripts/lua_environment.hpp"
#include "lua/modules/modules.hpp"
#include "game/game.hpp"
#include "config/configmanager.hpp"
#include "utils/tools.hpp"

#include <fmt/format.h>

DuskForge& DuskForge::getInstance() {
	static DuskForge instance;
	return instance;
}

bool DuskForge::loadRecipesFromLua(const std::string& /*path*/) {
	recipes.clear();

	lua_State* L = g_luaEnvironment().getLuaState();
	if (!L) {
		g_logger().warn("[DuskForge::loadRecipesFromLua] - Lua state not available");
		return false;
	}

	lua_getglobal(L, "DuskForgeRecipes");
	if (!lua_istable(L, -1)) {
		lua_pop(L, 1);
		g_logger().warn("[DuskForge::loadRecipesFromLua] - DuskForgeRecipes table not found in Lua, check data-global/scripts/forge_recipes.lua");
		return false;
	}

	lua_pushnil(L);
	while (lua_next(L, -2) != 0) {
		// key at -2, value (recipe table) at -1
		if (lua_istable(L, -1)) {
			ForgeRecipe r;

			lua_getfield(L, -1, "id");
			if (lua_isnumber(L, -1)) r.id = static_cast<uint32_t>(lua_tointeger(L, -1));
			lua_pop(L, 1);

			lua_getfield(L, -1, "result");
			if (lua_isnumber(L, -1)) r.resultItemId = static_cast<uint16_t>(lua_tointeger(L, -1));
			lua_pop(L, 1);

			// materials: array of { itemId, count }
			lua_getfield(L, -1, "materials");
			if (lua_istable(L, -1)) {
				lua_pushnil(L);
				while (lua_next(L, -2) != 0) {
					if (lua_istable(L, -1)) {
						lua_geti(L, -1, 1);
						int itemId = lua_isnumber(L, -1) ? static_cast<int>(lua_tointeger(L, -1)) : 0;
						lua_pop(L, 1);

						lua_geti(L, -1, 2);
						int count = lua_isnumber(L, -1) ? static_cast<int>(lua_tointeger(L, -1)) : 0;
						lua_pop(L, 1);

						if (itemId > 0 && count > 0) {
							r.materials.emplace_back(static_cast<uint16_t>(itemId), static_cast<uint32_t>(count));
						}
					}
					lua_pop(L, 1);
				}
			}
			lua_pop(L, 1); // pop materials

			// slotChances: table of [slots] = percent
			lua_getfield(L, -1, "slotChances");
			if (lua_istable(L, -1)) {
				lua_pushnil(L);
				while (lua_next(L, -2) != 0) {
					if (lua_isnumber(L, -2) && lua_isnumber(L, -1)) {
						uint8_t slots = static_cast<uint8_t>(lua_tointeger(L, -2));
						double chance = lua_tonumber(L, -1);
						r.slotChance[slots] = chance;
					}
					lua_pop(L, 1);
				}
			}
			lua_pop(L, 1); // pop slotChances

			// attributes: table of attributeName = { min = X, max = Y } or attributeName = number (exact) or boolean true
			lua_getfield(L, -1, "attributes");
			if (lua_istable(L, -1)) {
				lua_pushnil(L);
				while (lua_next(L, -2) != 0) {
					// key: attribute name (string) at -2, value at -1
					if (lua_isstring(L, -2)) {
						std::string nameStr(lua_tostring(L, -2));
						if (lua_istable(L, -1)) {
							int64_t minv = 0;
							int64_t maxv = 0;
							lua_getfield(L, -1, "min");
							if (lua_isnumber(L, -1)) minv = static_cast<int64_t>(lua_tointeger(L, -1));
							lua_pop(L, 1);
							lua_getfield(L, -1, "max");
							if (lua_isnumber(L, -1)) maxv = static_cast<int64_t>(lua_tointeger(L, -1));
							lua_pop(L, 1);
							if (maxv == 0) maxv = minv;
							r.randomAttributes.push_back({ nameStr, minv, maxv, true });
						} else if (lua_isnumber(L, -1)) {
							int64_t v = static_cast<int64_t>(lua_tointeger(L, -1));
							r.randomAttributes.push_back({ nameStr, v, v, true });
						} else if (lua_isboolean(L, -1)) {
							// boolean true indicates allowed attribute with no numeric value
							r.randomAttributes.push_back({ nameStr, 0, 0, true });
						}
					}
					lua_pop(L, 1);
				}
			}
			lua_pop(L, 1); // pop attributes

			// uniqueAdds: { pool = {"a","b"}, min = X, max = Y }
			lua_getfield(L, -1, "uniqueAdds");
			if (lua_istable(L, -1)) {
				lua_getfield(L, -1, "min");
				if (lua_isnumber(L, -1)) r.uniqueAddMin = static_cast<uint8_t>(lua_tointeger(L, -1));
				lua_pop(L, 1);
				lua_getfield(L, -1, "max");
				if (lua_isnumber(L, -1)) r.uniqueAddMax = static_cast<uint8_t>(lua_tointeger(L, -1));
				lua_pop(L, 1);
				lua_getfield(L, -1, "pool");
				if (lua_istable(L, -1)) {
					lua_pushnil(L);
					while (lua_next(L, -2) != 0) {
						if (lua_isstring(L, -1)) {
							r.uniqueAddPool.emplace_back(lua_tostring(L, -1));
						}
						lua_pop(L, 1);
					}
				}
				lua_pop(L, 1); // pop pool
			}
			lua_pop(L, 1); // pop uniqueAdds

			if (r.id != 0 && r.resultItemId != 0 && !r.materials.empty()) {
				recipes[r.id] = std::move(r);
			} else {
				g_logger().warn("[DuskForge::loadRecipesFromLua] - Ignoring invalid recipe id={} result={} materials={}", r.id, r.resultItemId, r.materials.size());
			}
		}
		lua_pop(L, 1);
	}

	lua_pop(L, 1);

	loaded = true;
	g_logger().info("Loaded {} forge recipes from Lua", recipes.size());
	return true;
}

const ForgeRecipe* DuskForge::getRecipe(uint32_t id) const {
	auto it = recipes.find(id);
	if (it == recipes.end()) return nullptr;
	return &it->second;
}

std::shared_ptr<Item> DuskForge::craft(uint32_t recipeId, const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& /*container*/) {
	if (!player) return nullptr;
	const ForgeRecipe* recipe = getRecipe(recipeId);
	if (!recipe) {
		g_logger().warn("[DuskForge::craft] - Recipe {} not found", recipeId);
		return nullptr;
	}

	// Preliminary checks: ensure player can receive the resulting item (capacity and backpack slot)
	if (recipe->resultItemId == 0) return nullptr;
	{
		const auto &itType = Item::items[recipe->resultItemId];
		uint32_t itemWeight = itType.weight;
		if (player->getFreeCapacity() < itemWeight) {
			g_logger().warn("[DuskForge::craft] - Player {} not enough capacity for forged item {} (need {}, free {})", player->getName(), recipe->resultItemId, itemWeight, player->getFreeCapacity());
			return nullptr;
		}
		if (player->getFreeBackpackSlots() == 0) {
			g_logger().warn("[DuskForge::craft] - Player {} has no free backpack slots to receive forged item {}", player->getName(), recipe->resultItemId);
			return nullptr;
		}
	}

	// Check availability: inventory + stash + depot
	for (const auto &mat : recipe->materials) {
		uint16_t itemId = mat.first;
		uint32_t required = mat.second;

		uint32_t inventoryCount = player->getItemTypeCount(itemId, -1);
		uint32_t stashCount = player->getStashItemCount(itemId);
		uint32_t depotCount = 0;
		const auto &depotItems = player->getDepotChestItemsId();
		auto it = depotItems.find(itemId);
		if (it != depotItems.end()) {
			for (const auto &tierPair : it->second) depotCount += tierPair.second;
		}

		uint32_t available = inventoryCount + stashCount + depotCount;
		if (available < required) {
			g_logger().warn("[DuskForge::craft] - Player {} missing material {} (need {}, have {})", player->getName(), itemId, required, available);
			return nullptr;
		}
	}

	// Consume materials: inventory -> stash -> depot (same pattern as delivery)
	for (const auto &mat : recipe->materials) {
		uint16_t itemId = mat.first;
		uint32_t leftToRemove = mat.second;

		uint32_t inventoryCount = player->getItemTypeCount(itemId, -1);
		if (leftToRemove > 0 && inventoryCount > 0) {
			uint32_t removeFromInventory = [inventoryCount, leftToRemove]() { return (inventoryCount < leftToRemove) ? inventoryCount : leftToRemove; }();
			if (player->removeItemOfType(itemId, removeFromInventory, -1, false)) {
				leftToRemove -= removeFromInventory;
			} else {
				g_logger().warn("[DuskForge::craft] - Failed to remove {}x{} from inventory of {}", removeFromInventory, itemId, player->getName());
				return nullptr;
			}
		}

		if (leftToRemove > 0) {
			uint32_t stashCount = player->getStashItemCount(itemId);
			if (stashCount > 0) {
				uint32_t removeFromStash = (stashCount < leftToRemove) ? stashCount : leftToRemove;
				if (player->withdrawItem(itemId, removeFromStash)) {
					leftToRemove -= removeFromStash;
				} else {
					g_logger().warn("[DuskForge::craft] - Failed to withdraw {}x{} from stash of {}", removeFromStash, itemId, player->getName());
					return nullptr;
				}
			}
		}

		if (leftToRemove > 0) {
			// remove from depot chests across all depots
			uint32_t removed = 0;
			for (uint32_t depotId = 0; depotId <= 20 && removed < leftToRemove; ++depotId) {
				auto depotChest = player->getDepotChest(depotId, false);
				if (!depotChest) continue;
				auto container = depotChest->getContainer();
				if (!container) continue;
				std::vector<std::shared_ptr<Item>> itemsToRemove;
				for (ContainerIterator it2 = container->iterator(); it2.hasNext(); it2.advance()) {
					auto &item = *it2;
					if (item && item->getID() == itemId) itemsToRemove.push_back(item);
				}
				for (const auto &itItem : itemsToRemove) {
					if (removed >= leftToRemove) break;
					uint32_t itemCount = Item::countByType(itItem, -1);
					uint32_t toRemove = (itemCount < (leftToRemove - removed)) ? itemCount : (leftToRemove - removed);
					if (toRemove >= itemCount) {
						g_game().internalRemoveItem(itItem);
						removed += itemCount;
					} else {
						g_game().internalRemoveItem(itItem, toRemove);
						removed += toRemove;
					}
				}
			}
			if (removed < leftToRemove) {
				g_logger().warn("[DuskForge::craft] - Failed to remove {}x{} from depots of {} (removed {})", leftToRemove, itemId, player->getName(), removed);
				return nullptr;
			}
		}
	}


	// Create result item (after materials removed) and place into player inventory (no drop on map)

auto createdItem = Item::CreateItem(recipe->resultItemId, 1, nullptr, true);
	if (!createdItem) {
		g_logger().warn("[DuskForge::craft] - Failed to create item {} for recipe {}", recipe->resultItemId, recipeId);
		return nullptr;
	}

	// Determine slot count using per-recipe chances (fallback: no extra slots)
	double roll = static_cast<double>(uniform_random(0, 10000)) / 100.0;
	double cumulative = 0.0;
	uint8_t chosenSlots = 0;
	for (const auto &p : recipe->slotChance) {
		cumulative += p.second;
		if (roll <= cumulative) {
			chosenSlots = p.first;
			break;
		}
	}

	// Store slot metadata using custom attributes (avoid imbuement system)
	createdItem->setCustomAttribute("forge_slots", static_cast<int64_t>(chosenSlots));
	for (uint8_t i = 1; i <= chosenSlots; ++i) {
		createdItem->setCustomAttribute(fmt::format("forge_slot_{}", i), false);
	}

	// Apply random attributes as configured in the recipe
	for (const auto &spec : recipe->randomAttributes) {
		if (spec.min == 0 && spec.max == 0) {
			// marker for boolean-allowed attribute (no numeric value). Store as flag.
			createdItem->setCustomAttribute(fmt::format("forge_attr_{}", spec.name), true);
			continue;
		}
		int64_t value = spec.min;
		if (spec.max > spec.min) {
			value = static_cast<int64_t>(uniform_random(static_cast<int>(spec.min), static_cast<int>(spec.max)));
		}
		createdItem->setCustomAttribute(fmt::format("forge_attr_{}", spec.name), value);
	}

	// Apply unique adds selection
	if (!recipe->uniqueAddPool.empty() && recipe->uniqueAddMax > 0) {
		uint8_t toPick = recipe->uniqueAddMin;
		if (recipe->uniqueAddMax > recipe->uniqueAddMin) {
			toPick = static_cast<uint8_t>(normal_random(recipe->uniqueAddMin, recipe->uniqueAddMax));
		}
		// clamp to pool size
		if (toPick > recipe->uniqueAddPool.size()) toPick = static_cast<uint8_t>(recipe->uniqueAddPool.size());
		// simple reservoir-like sampling (shuffle indices)
		std::vector<size_t> idx(recipe->uniqueAddPool.size());
		for (size_t i = 0; i < idx.size(); ++i) idx[i] = i;
		std::shuffle(idx.begin(), idx.end(), getRandomGenerator());
		createdItem->setCustomAttribute("forge_unique_count", static_cast<int64_t>(toPick));
		for (size_t i = 0; i < toPick; ++i) {
			createdItem->setCustomAttribute(fmt::format("forge_unique_{}", i + 1), recipe->uniqueAddPool[idx[i]]);
		}
	}

	// Try to add to player's inventory (no dropOnMap)
	auto addResult = g_game().addItemBatch(player, std::vector<std::shared_ptr<Item>>{ createdItem }, 0, false);
	if (std::get<0>(addResult) != RETURNVALUE_NOERROR) {
		g_logger().warn("[DuskForge::craft] - Failed to add forged item {} to player {} inventory, result {}", recipe->resultItemId, player->getName(), static_cast<int>(std::get<0>(addResult)));
		// As pre-checks were done earlier this should rarely happen. Return nullptr to indicate failure.
		return nullptr;
	}

	return createdItem;
}
