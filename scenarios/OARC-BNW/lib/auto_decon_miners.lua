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
            if ((not miner) or (not miner.valid)) then
                table.remove(global.oarc_decon_miners, i)

            else
                if (#miner.surface.find_entities_filtered{area = {{miner.position.x-3, miner.position.y-3},
                                                                            {miner.position.x+3, miner.position.y+3}},
                                                                            type = "resource", limit = 1} == 0) then
                    miner.order_deconstruction(miner.force)
                end
                table.remove(global.oarc_decon_miners, i)
            end
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
                                                                          name = {"burner-mining-drill", "electric-mining-drill"}}
        local fmt = "Auto Deconstruct event on resource depleted: " .. event.entity.name
        for i,v in pairs(nearby_miners) do
            fmt = string.format("%s, Allow deconstruction: %s", fmt, tostring(settings.startup["bno-auto-deconstruct-miners-allowed"].value))
            if settings.startup["bno-auto-deconstruct-miners-allowed"].value then
                if global.ocfg.enable_miner_decon[v.force.name] == nil then
                    global.ocfg.enable_miner_decon[v.force.name] = ENABLE_MINER_AUTODECON
                end 
                if (global.ocfg.enable_miner_decon[v.force.name]) then
                    table.insert(global.oarc_decon_miners, v)
                    fmt = string.format("%s%s%s%s%s", fmt, ", force: ", v.force.name, ", Adding miner for decon ", v.gps_tag)
                end
            end
        end
        log(fmt)
    else
        log("Auto Deconstruct event- but no entity")
    end
end
