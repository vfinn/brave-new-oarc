require("prototypes.sounds")
-- moved to data-final-fixes.lua to take back box settings done in data-update in Krastorio

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