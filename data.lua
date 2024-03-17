require("prototypes.sounds")
-- moved bot definitions to data-final-fixes.lua to take back bot settings done in data-update in Krastorio2
-- Krastorio2 slows down bots - so this mods speed settings would not work

data:extend({
  -- remove corpses
  {
    type = "custom-input",
    name = "remove-corpses",
    key_sequence = "BACKSPACE",
    alternative_key_sequence = "",
    localised_name = {"keypress.remove-corpses"},
    localised_description = {"keypress-definitions.remove-corpses"}
  },
})

data.raw.recipe["loader"].hidden = false
data.raw.recipe["fast-loader"].hidden = false
data.raw.recipe["express-loader"].hidden = false

-- loader_1x1= data.raw["loader-1x1"]["loader-1x1"]
-- local recipe = {
--     type = "loader-1x1",
--     name = "loader-1x1",
--     enabled = true,
--     energy_required = 1,
--     ingredients = {"iron-plate", 4}
-- }
-- data:extend{recipe}
-- loader_1x1 = table.deepcopy(loader_1x1)
-- loader_1x1.flags={}
-- data:extend({ loader_1x1 })

table.insert(data.raw.technology["logistics"].effects, {type = "unlock-recipe", recipe = "loader"})
table.insert(data.raw.technology["logistics-2"].effects, {type = "unlock-recipe", recipe = "fast-loader"})
table.insert(data.raw.technology["logistics-3"].effects, {type = "unlock-recipe", recipe = "express-loader"})


