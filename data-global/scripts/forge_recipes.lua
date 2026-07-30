-- Example forge recipes (placed in data-global/scripts/forge_recipes.lua)
-- Each recipe has: id, result, materials (list of {itemid, count}), slotChances (map slots->percent)

local recipes = {
	{
		id = 1,
		result = 2410, -- example item id
		materials = {
			{ 2148, 100 }, -- gold coins
			{ 10101, 2 }, -- some material
		},
		slotChances = { [2] = 20.0, [3] = 8.0, [4] = 2.0 }
	},
	{
		id = 2,
		result = 2411,
		materials = {
			{ 2148, 200 },
			{ 10102, 3 },
		},
		slotChances = { [2] = 30.0, [3] = 10.0, [4] = 3.0 }
	}
}

if not DuskForgeRecipes then
	DuskForgeRecipes = {}
end
for _, r in ipairs(recipes) do
	DuskForgeRecipes[r.id] = r
end

return DuskForgeRecipes
