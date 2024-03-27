data:extend(
{
--    {
--        type = "recipe",
--        name = "loader-1x1",
--        enabled = true,
--        hidden = true,
--        energy_required = 1,
--        ingredients =
--        {
--          {"iron-plate", 4}
--        },
--        result = "loader-1x1"
--      },
    {
        type = "recipe",
        name = "loader",
        enabled = true,
        hidden = false,
        energy_required = 1,
        ingredients =
        {
          {"inserter", 5},
          {"iron-plate", 20}
--          {"electronic-circuit", 5},
--          {"iron-gear-wheel", 5},
--          {"transport-belt", 5}
        },
        result = "loader"
      },
      {
        type = "recipe",
        name = "fast-loader",
        enabled = true,
        hidden = false,
        energy_required = 3,
        ingredients =
        {
          {"fast-transport-belt", 5},
          {"loader", 1}
        },
        result = "fast-loader"
      },
      {
        type = "recipe",
        name = "express-loader",
        enabled = true,
        hidden = false,
        energy_required = 10,
        ingredients =
        {
          {"express-transport-belt", 5},
          {"fast-loader", 1}
        },
        result = "express-loader"
      }
    }
)
       