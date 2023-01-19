data:extend({
    {
        type = "bool-setting",
        name = "fast-robots",     
        setting_type = "startup",
        default_value = true,
        order="bnw-00"
    },
    {
        type = "int-setting",
        name = "bno-number-of-silos",     
        setting_type = "startup",
        minimum_value=1,
        maximum_value=12,
        default_value = 6,
        order="bnw-01"
    },    
    {
        type = "string-setting",
        name = "bno-num-starting-bots",     
        setting_type = "startup",
        allowed_values = {"10/5", "50/25", "100/50", "200/100"},
        default_value = "100/50",
        order="bnw-02"
    },
    {
        type = "string-setting",
        name = "bno-moat-bridge",     
        setting_type = "startup",
        allowed_values = {"yes", "no", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-03"
    },
    {
        type = "string-setting",
        name = "bno-anti-grief",     
        setting_type = "startup",
        allowed_values = {"yes", "no", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-04"
    },
    {
        type = "string-setting",
        name = "bno-anti-grief-ghost-TTL",     
        setting_type = "startup",
        allowed_values = {"use config.lua setting", "10", "30", "60", "120", "240", "360"},
        default_value = "use config.lua setting",
        order="bnw-05"
    },
    {
        type = "string-setting",
        name = "bno-chest-sharing",     
        setting_type = "startup",
        allowed_values = {"yes", "no", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-08"
    },
    {
        type = "string-setting",
        name = "bno-spawn-base-shape-circle",     
        setting_type = "startup",
        allowed_values = {"circle", "octagon", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-09"
    },    
    {
        type = "bool-setting",
        name = "bno-bots-resistance-acid",     
        setting_type = "startup",
        default_value = false,
        order="bnw-90"
    },
    {
        type = "bool-setting",
        name = "bno-bots-resistance-fire",     
        setting_type = "startup",
        default_value = false,
        order="bnw-91"
    },
    {
        type = "bool-setting",
        name = "bno-bots-resistance-explosion",     
        setting_type = "startup",
        default_value = false,
        order="bnw-92"
    },
    {
        type = "bool-setting",
        name = "bno-bots-resistance-physical",     
        setting_type = "startup",
        default_value = false,
        order="bnw-93"
    },
--  {
--       type = "bool-setting",
--        name = "bno-test",     
--
--
--        setting_type = "runtime-global",
--        default_value = false,
--        order="bnw-99"
--    }

})
