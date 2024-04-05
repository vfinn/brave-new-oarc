-- update to table for scap-resource patch's items and probability
-- 
-- local prod_score = require('production-score')   - from hidden-relic
-- local values = prod_score.generate_price_list()

if (mods["scrap-resource"]) then
    data.raw.resource.scrap.minable.results =
    {                            -- 1 00.000 % change  
        { amount = 1, probability = 0.00005,  name = "processing-unit",       },
        { amount = 1, probability = 0.0001,   name = "advanced-circuit",      },
        { amount = 1, probability = 0.0001,   name = "low-density-structure", },
        { amount = 1, probability = 0.0050,   name = "solid-fuel",            },
        { amount = 1, probability = 0.0500,   name = "concrete",              },
        { amount = 1, probability = 0.0030,   name = "battery",               },
        { amount = 1, probability = 0.0025,   name = "crude-oil-barrel",      },
        { amount = 1, probability = 0.1000,   name = "stone",                 },
        { amount = 1, probability = 0.1000,   name = "coal",                  },
        { amount = 1, probability = 0.3500,   name = "iron-ore",              },
        { amount = 1, probability = 0.2000,   name = "copper-ore",            },
        { amount = 1, probability = 0.0100,   name = "uranium-ore",           },
        { amount = 1, probability = 0.0400,   name = "iron-gear-wheel",       },
        { amount = 1, probability = 0.0200,   name = "copper-cable",          },
        { amount = 1, probability = 0.0200,   name = "iron-plate",            },
        { amount = 1, probability = 0.0100,   name = "copper-plate",          },
        { amount = 1, probability = 0.0250,   name = "stone-brick",           },
        { amount = 1, probability = 0.0050,   name = "steel-plate",           },
        { amount = 1, probability = 0.0001,   name = "medium-electric-pole",  },
        { amount = 1, probability = 0.0005,   name = "inserter",              },
        { amount = 1, probability = 0.0002,   name = "fast-inserter",         },
        { amount = 1, probability = 0.0002,   name = "long-handed-inserter",  },
        { amount = 1, probability = 0.0010,   name = "transport-belt",        },        
        { amount = 1, probability = 0.0010,   name = "splitter",              },
        { amount = 1, probability = 0.00005,  name = "construction-robot",    },        
        { amount = 1, probability = 0.00005,  name = "logistic-robot",        },        
        { amount = 1, probability = 0.000001, name = "roboport",              },        
        { amount = 1, probability = 0.000003, name = "assembling-machine-2",  },        
        { amount = 1, probability = 0.000003, name = "electric-furnace",      },        
        { amount = 1, probability = 0.00015,  name = "steel-chest",           },     
    }
end