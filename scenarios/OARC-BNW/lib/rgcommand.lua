-- vf lots of 32's replaced with , also 31's with CHUNK_SIZE-1 and 16 with /2
local function RemoveTileGhosts()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * CHUNK_SIZE, c.y * CHUNK_SIZE}, {c.x * CHUNK_SIZE + CHUNK_SIZE, c.y * CHUNK_SIZE + CHUNK_SIZE}}, name= "tile-ghost"})) do  
            entity.destroy()
        end
    end
end

local function RemoveBlueprintedModulesGhosts()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * CHUNK_SIZE, c.y * CHUNK_SIZE}, {c.x * CHUNK_SIZE + CHUNK_SIZE, c.y * CHUNK_SIZE + CHUNK_SIZE}}, name= "item-request-proxy"})) do
            entity.destroy()
        end
    end
end

local function RemoveGhostEntities()
    local surface = game.player.surface
    for c in surface.get_chunks() do
        for key, entity in pairs(surface.find_entities_filtered({area={{c.x * CHUNK_SIZE, c.y * CHUNK_SIZE}, {c.x * CHUNK_SIZE + CHUNK_SIZE, c.y * CHUNK_SIZE + CHUNK_SIZE}}, name= "entity-ghost"})) do
          entity.destroy()
        end
    end
end

commands.add_command("list" , "list players online to log file", function(command)
    local player = game.players[command.player_index];
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
            if command.parameter == "online" or command.parameter == "players" then
                for name,player in pairs(game.connected_players) do   log(player.name )   end 
            elseif command.parameter == "all" then
                for name,player in pairs(game.players) do   log(player.name )   end 
            else
                player.print("list | players | online| all");
            end
        end
    end
end)


commands.add_command("rg", "remove ghosts", function(command)
    local player = game.players[command.player_index];
    if player ~= nil and player.admin then
        if (command.parameter ~= nil) then
            if command.parameter == "all" then
                RemoveTileGhosts()
                RemoveBlueprintedModulesGhosts()
                RemoveGhostEntities()
            elseif command.parameter == "tiles" then
                RemoveTileGhosts()
            elseif command.parameter == "modules" then
                RemoveBlueprintedModulesGhosts()
            elseif command.parameter == "entities" then
                RemoveGhostEntities()
            else
                player.print("remove all ghostes | tiles | modules | entities");
            end
        end
    end
end)
