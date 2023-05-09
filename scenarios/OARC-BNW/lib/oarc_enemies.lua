-- oarc_enemies.lua
-- Feb 2020

-- This is my second attempt at modifying the normal enemy experience. The
-- first attempt ended up in a wave attack system which wasn't well received.
-- This attempt will try to intercept normal vanilla enemy groups and modify
-- them based on player activity.

-- Basic logic:
--  on_unit_group_finished_gathering we check what command is given.
--  find destination position
--  check for closest "player" using find_nearest_enemy function
--  if a player is found, check if player is part of a shared spawn
--  Remove the enemy group if no player in the shared spawn is online.

-- TODO:
--  Add options for modifying the default waves or spawning additional special waves.
--  Add option to disable attacks completely for a given spawn.

-- Generic Utility Includes
require("lib/oarc_utils")

function OarcModifyEnemyGroup(group)

    -- Check validity
    if ((group == nil) or (group.command == nil) or (group.force.name ~= "enemy")) then
        log("OarcModifyEnemyGroup ignoring INVALID group/command")
        return
    end
    -- Make sure the attack is of a TYPE that we care about.
    if ((group.command.type == defines.command.attack) or 
        (group.command.type == defines.command.attack_area) or 
        (group.command.type == defines.command.build_base)) then
        -- log("OarcModifyEnemyGroup MODIFYING command TYPE=" .. group.command.type)
    else
        log("OarcModifyEnemyGroup ignoring command TYPE=" .. group.command.type)
        return
    end

    -- defines.command.attack --> target --> target.position
    if (group.command.type == defines.command.attack) then
        log("OarcModifyEnemyGroup defines.command.attack NOT IMPLEMENTED YET!")
        return
    
    -- defines.command.attack_area --> destination --> closest enemy (within 3 chunk radius?)
    -- defines.command.build_base --> destination --> closest enemy (expansion chunk distance?)
    else
        local destination = group.command.destination
        local distance = CHUNK_SIZE*3
        if (group.command.type == defines.command.build_base) then
            distance = CHUNK_SIZE*(game.map_settings.enemy_expansion.max_expansion_distance)
        end

        -- Find some enemies near the attack point.
        local target_entities = group.surface.find_entities_filtered{
                                                position=destination,
                                                radius=distance,
                                                force={"enemy", "neutral"},
                                                limit=50,
                                                invert=true}

        -- Search through them all to find anything with a last_user.
        local target_entity = nil                                   
        for _,target in ipairs(target_entities) do
            if (target.last_user ~= nil) then
                target_entity = target
                break
            end
        end                                                                

        -- No enemies nearby?
        if (target_entity == nil) then
            if (group.command.type == defines.command.attack_area) then
                if (global.enable_oe_debug) then
                    SendBroadcastMsg("OarcModifyEnemyGroup find_nearest_enemy attack_area FAILED!?!? " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(destination))
                end
                log("OarcModifyEnemyGroup UNEXPECTED find_nearest_enemy did not find anything!")
                for _,member in pairs(group.members) do
                    member.destroy()
                end
            else
                if (global.enable_oe_debug) then
                    log("OarcModifyEnemyGroup find_nearest_enemy did not find anything!")
                end
            end
            return
        end

        -- Probably don't need this I hope?
        if (target_entity.force == "neutral") then
            log("OarcModifyEnemyGroup UNEXPECTED find_nearest_enemy found neutral target?")
            for _,member in pairs(group.members) do
                member.destroy()
            end
            return
        end

        -- Most common target will be a built entity with a "last_user"
        local target_player = target_entity.last_user

        -- Target could also be a player character (more rare)
        if (target_player == nil) and (target_entity.type == "character") then
            target_player = target_entity.player
        end

        -- I don't think this should happen...
        if ((target_player == nil) or (not target_player.valid)) then
            if (global.enable_oe_debug) then
                SendBroadcastMsg("ERROR?? target_player nil/invalid " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position))
                log("OarcModifyEnemyGroup ERROR?? target_player nil/invalid" .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position))
            end
            for _,member in pairs(group.members) do
                member.destroy()
            end
            return
        end

        -- Is the target player online? Then the attack can go through.
        if (target_player.connected) then
            if (global.enable_oe_debug) then
                SendBroadcastMsg("Enemy group released (player): " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
                log("OarcModifyEnemyGroup RELEASING enemy group since player " .. target_player.name .. " is ONLINE, " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position))
            end
            configureSwarmPing(target_player, group)
            return
        end

        -- Find the shared spawn that the player is part of.
        -- This could be the own player's spawn (quite likely)
        local sharedSpawnOwnerName = FindPlayerSharedSpawn(target_player.name)

        -- Is someone in the shared spawn online?
        if (sharedSpawnOwnerName ~= nil) then
            if (GetOnlinePlayersAtSharedSpawn(sharedSpawnOwnerName) > 0) then
                if (global.enable_oe_debug) then
                    SendBroadcastMsg("Enemy group released (shared): " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
                    log("OarcModifyEnemyGroup RELEASING enemy group since someone in the group " .. target_player.name .. " is ONLINE, " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position))
                end
--                target_player.print(target_player.name .. " incoming biter group:" .. GetGPStext(group.position))
                return
            end
        end

        -- Is there a buddy spawn and is the buddy online?
        local buddyName = global.ocore.buddyPairs[sharedSpawnOwnerName]
        if (buddyName ~= nil) and (game.players[buddyName] ~= nil) then
            if (game.players[buddyName].connected or (GetOnlinePlayersAtSharedSpawn(buddyName) > 0)) then
                if (global.enable_oe_debug) then
                    SendBroadcastMsg("Enemy group released (buddy): " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
                    log("OarcModifyEnemyGroup RELEASING enemy group since someone in the BUDDY PAIR " .. target_player.name .. " is ONLINE, " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position))
                end
--                target_player.print(target_player.name .. " incoming biter group!:" .. GetGPStext(group.position))
                configureSwarmPing(target_player, group)
                return
            end
        end

        -- Otherwise, we delete the group.
        if (global.enable_oe_debug) then
            SendBroadcastMsg("Enemy group deleted: " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name)
            log("Enemy group deleted: " .. GetGPStext(group.position) .. " Target: " .. GetGPStext(target_entity.position) .. " " .. target_player.name .. " player not online")
        end
        if (global.enable_attack_offline) then
            return
        end
        for _,member in pairs(group.members) do
            member.destroy()
        end
--        log("OarcModifyEnemyGroup REMOVED enemy group since " .. target_player.name .. " was not online?")
    end
end

-- adds the swarm/group that is ready to act, to tracking stack (global.swarmGroup), one entry per swarm
-- we later validate every swarm to determine if we should ping, or just remove the swarm from the stack
-- global variables
--	global.swarmGroup	{target_player, group, startPosition}		
--          One stack for all players. When the group finishes gathering, we add them to this stack.
--			One entry per swarm

-- events
--	on_unit_group_finished_gathering		- swarm completed grouping and are acting
--	on_tick									- EVERY TICK this is called - where we track the swarm until they go to a moving state, 
--											when the gps tag is created
--	on_player_clicked_gps_tag				- previously sent GPS tag is clicked on
function configureSwarmPing(target_player, group)
        -- Is the target player online? Then the attack can go through.
        if (global.ocfg.warn_biter_setting == nil) then
            global.ocfg.warn_biter_setting = {}
            global.ocfg.warn_biter_setting[target_player.index] = global.ocfg.warn_biter_attack; -- init individual setting to default
        end
        if (global.ocfg.warn_biter_setting[target_player.index]) then
            local groupWithStartPosition = {}
            groupWithStartPosition.target_player = target_player
            groupWithStartPosition.startPosition=group.position
            groupWithStartPosition.group = group
            if ((global.enable_oe_debug) and
                ((group.command.type == defines.command.attack) or 
                 (group.command.type == defines.command.attack_area) or
                 (group.command.type == defines.command.build_base))) then
                log("spawning swarm " .. GetGPStext(group.position) .. " for " .. target_player.name)
            end
            if ((group.command.type == defines.command.attack) or 
                (group.command.type == defines.command.attack_area)) then
                groupWithStartPosition.gpsSent=false    -- start of swarm tracking
                table.insert(global.swarmGroup, groupWithStartPosition) -- later in on_player_clicked_gps_tag when the gps is clicked - we want to track the group                
            else
                if (global.enable_oe_debug) then
                    if (group.command.type == defines.command.build_base) then
                        log("The bastards are building a base " .. GetGPStext(group.position) .. target_player.name)
                        log(target_player.name .. "- bastards are building a base : " .. GetGPStext(group.position))
                    else
                        if (group.command.type == defines.command.go_to_location) then
                            log(target_player.name .. " WTF - got this command - go_to_location " .. GetGPStext(group.position) .. " " .. target_player.name)
                        elseif (group.command.type == defines.command.wander) then
                            log(target_player.name .. " WTF - got this command - wander " .. GetGPStext(group.position) .. " " .. target_player.name)
                        elseif (group.command.type == defines.command.stop) then
                            log(target_player.name .. " WTF - got this command - stop " .. GetGPStext(group.position) .. " " .. target_player.name)
                        elseif (group.command.type == defines.command.flee) then
                            log(target_player.name .. " WTF - got this command - flee " .. GetGPStext(group.position) .. " " .. target_player.name)
                        end
                    end
                end
            end
        end
    end
