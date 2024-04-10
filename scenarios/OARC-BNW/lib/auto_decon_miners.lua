-- auto_decon_miners.lua
-- May 2020
-- My shitty softmod version which is buggy

function OarcAutoDeconOnInit(event)
	if (not global.oarc_decon_miners) then
		global.oarc_decon_miners = {}
	end
end

function OarcAutoDeconOnTick()
    if (global.oarc_decon_miners and (#global.oarc_decon_miners > 0)) then
        for i,miner in pairs(global.oarc_decon_miners) do
            if (miner and miner.valid and miner.mining_target == nil) then
                if miner.last_user then 
                    -- Double check above choice to remove miner
                    if (#miner.surface.find_entities_filtered{area = {{miner.selection_box.left_top.x, miner.selection_box.left_top.y},
                                                                    {miner.selection_box.right_bottom.x, miner.selection_box.right_bottom.y}},
                                                                    type = "resource", limit = 1} == 0) then
                        miner.order_deconstruction(miner.force)
                        rendering.draw_rectangle{color={1,0.1,0.1,1}, left_top=miner.selection_box.left_top, right_bottom=miner.selection_box.right_bottom, surface="oarc", time_to_live=60*30, miner.last_user.force, draw_on_ground=false}
                        game.players[miner.last_user.index].print("Removing miner: " .. miner.gps_tag)
                        log("Removing miner from " .. miner.last_user.name .. miner.gps_tag)
                    end
                else
                    log("no miner.last_user on auto decon of miner")
                end
            end
            table.remove(global.oarc_decon_miners, i)
        end
    end
end

function OarcAutoDeconOnResourceDepleted(event)
	if (not global.oarc_decon_miners) then
		global.oarc_decon_miners = {}
	end
   
    if (event.entity and event.entity.position and event.entity.surface) then
        local nearby_miners = event.entity.surface.find_entities_filtered{area = {{event.entity.position.x-1, event.entity.position.y-1},
                                                                                        {event.entity.position.x+1, event.entity.position.y+1}},
                                                                          type = {type = "mining-drill"}}
        for i,v in pairs(nearby_miners) do
            if settings.startup["bno-auto-deconstruct-miners-allowed"].value then
                if global.ocfg.enable_miner_decon[v.force.name] == nil then
                    global.ocfg.enable_miner_decon[v.force.name] = ENABLE_MINER_AUTODECON
                end 
                if (global.ocfg.enable_miner_decon[v.force.name]) then
                    table.insert(global.oarc_decon_miners, v)
                end
            end
        end
    end
end
