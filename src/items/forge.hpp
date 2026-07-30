#pragma once

#include <map>
#include <string>
#include <vector>
#include <memory>

class Item;
class Player;

struct AttributeSpec {
	std::string name;
	int64_t min{};
	int64_t max{};
	bool integer{true};
};

struct ForgeRecipe {
	uint32_t id{};
	uint16_t resultItemId{};
	std::vector<std::pair<uint16_t, uint32_t>> materials; // itemid, count
	std::map<uint8_t, double> slotChance; // slots -> chance (0.0 - 100.0)

	// Random attribute specifications: name -> min/max
	std::vector<AttributeSpec> randomAttributes; // e.g. { {"hp", 10, 50}, {"mp", 5, 20} }

	// Unique adds configuration
	uint8_t uniqueAddMin{0};
	uint8_t uniqueAddMax{0};
	std::vector<std::string> uniqueAddPool; // list of allowed unique add identifiers (strings)
};

// DuskForge: manager for forging/crafting
class DuskForge {
public:
	static DuskForge& getInstance();

	bool loadRecipesFromLua(const std::string& path);
	const ForgeRecipe* getRecipe(uint32_t id) const;

	std::shared_ptr<Item> craft(uint32_t recipeId, const std::shared_ptr<Player>& player, const std::shared_ptr<Item>& container);

private:
	DuskForge() = default;
	bool loaded = false;
	std::map<uint32_t, ForgeRecipe> recipes;
};

constexpr auto g_duskForge = DuskForge::getInstance;