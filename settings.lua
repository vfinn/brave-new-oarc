data:extend({
    {
        type = "string-setting",
        name = "bno-number-of-silos",     
        setting_type = "startup",
        allowed_values = {"place anywhere", "small (6)", "normal (12)", "large(24)"},
        default_value = "place anywhere",
        order="bnw-01"
    },    
    {
        type = "int-setting",
        name = "bno-increase-logistics",     
        setting_type = "startup",
        minimum_value=0,
        maximum_value=64,
        default_value = 0,
        order="bnw-015"
    },    
    {
        type = "string-setting",
        name = "bno-map-size",     
        setting_type = "startup",
        allowed_values = {"tiny", "small", "normal", "large"},
        default_value = "normal",
        order="bnw-016"
    },
    {
        type = "string-setting",
        name = "bno-num-starting-bots",     
        setting_type = "startup",
        allowed_values = {"10/5", "50/25", "100/50", "200/100", "500/250"},
        default_value = "100/50",
        order="bnw-02"
    },
    {
        type = "int-setting",
        name = "bno-starting-bots_speed",     
        setting_type = "startup",
        minimum_value = 10,
        maximum_value = 400,
        default_value = 13,
        order="bnw-03"
    },
    {
        type = "string-setting",
        name = "bno-bots_energy",     
        setting_type = "startup",
        allowed_values = {"normal", "increase storage", "increase range", "increase movement", "increase all"},
        default_value = "normal",
        order="bnw-04"
    },
    {
        type = "string-setting",
        name = "bno-moat-bridge",     
        setting_type = "startup",
        allowed_values = {"yes", "no", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-04a"
    },
    {
        type = "string-setting",
        name = "bno-anti-grief",     
        setting_type = "startup",
        allowed_values = {"yes", "no", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-04b"
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
        type = "int-setting",
        name = "bno-num-blue-boxes", -- logistic-chest-requester    
        setting_type = "startup",
        minimum_value = 4,
        maximum_value = 10,
        default_value = 4,
        order="bnw-0804"
    },
    {
        type = "int-setting",
        name = "bno-num-red-boxes", -- logistic-chest-passive-provider   
        setting_type = "startup",
        minimum_value = 4,
        maximum_value = 10,
        default_value = 4,
        order="bnw-0806"
    },
--    {
--        type = "int-setting",
--        name = "bno-num-green-boxes", -- logistic-chest-buffer   
--        setting_type = "startup",
--        minimum_value = 4,
--        maximum_value = 10,
--        default_value = 4,
--        order="bnw-0805"
--    },
--    {
--        type = "int-setting",
--        name = "bno-num-purple-boxes", -- logistic-chest-active-provider  
--        setting_type = "startup",
--        minimum_value = 4,
--        maximum_value = 10,
--        default_value = 4,
--        order="bnw-0807"
--    },
    {
        type = "string-setting",
        name = "bno-spawn-base-shape",     
        setting_type = "startup",
        allowed_values = {"circle", "octagon", "square", "diamond", "use config.lua setting"},
        default_value = "use config.lua setting",
        order="bnw-09"
    },    
    {
       type = "string-setting",
        name = "bno-main-area-design-boiler-n-steam-engines",     
        setting_type = "startup",
        allowed_values = {"solar only", "solar plus boiler and steam engines"},
        default_value = "solar only",
        order="bnw-10"
    },
    {
        type = "bool-setting",
        name = "bno-biter-swarm-attack",     
        setting_type = "startup",
        default_value = true,
        order="bnw-86"
    },
    {
        type = "bool-setting",
        name = "bno-auto-deconstruct-miners-allowed",     
        setting_type = "startup",
        default_value = true,
        order="bnw-87"
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
    }   
})

if (mods["scrap-resource"]) then
data:extend({
    {
        type = "string-setting",
        name = "bno-scrap",     
        setting_type = "startup",
        allowed_values = {"many items", "ore only"},
        default_value = "ore only",
        order="bnw-00"
    }    
})
end