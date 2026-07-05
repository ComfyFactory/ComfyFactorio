local Public = {}

local base = script.active_mods["base"]
local is_21_cache = base and base:match("^2%.1%.") ~= nil or false

function Public.is_21()
    return is_21_cache
end

function Public.get_fluid(entity, index)
    return entity.get_fluid(index)
end

function Public.set_fluid(entity, index, fluid)
    return entity.set_fluid(index, fluid)
end

function Public.remove_fluid(entity, index, amount, fluid_name)
    if Public.is_21() then
        return entity.remove_fluid(index, amount)
    end

    local name = fluid_name

    if not name then
        local fluid = entity.get_fluid(index)

        if fluid then
            name = fluid.name
        end
    end

    if not name then
        return 0
    end

    return entity.remove_fluid({ name = name, amount = amount })
end

function Public.extract_fluid(entity, fluid_def)
    if Public.is_21() then
        return entity.extract_fluid(fluid_def)
    end

    return entity.remove_fluid(fluid_def)
end

function Public.get_fluid_capacity(entity, index)
    if Public.is_21() then
        return entity.get_fluid_capacity(index)
    end

    return entity.fluidbox.get_capacity(index)
end

function Public.fluidbox_count(entity)
    if Public.is_21() then
        return #entity.prototype.fluidbox_prototypes
    end

    return #entity.fluidbox
end

function Public.set_fluid_filter(entity, index, filter)
    if Public.is_21() then
        entity.set_fluid_filter(index, filter)
    else
        entity.fluidbox.set_filter(index, filter)
    end
end

function Public.get_fluid_contents(entity)
    return entity.get_fluid_contents()
end

function Public.spill_item_stack(surface, position_or_opts, stack, enable_looted)
    if type(position_or_opts) == "table" and position_or_opts.position and stack == nil then
        return surface.spill_item_stack(position_or_opts)
    end

    if enable_looted == nil then
        enable_looted = true
    end

    return surface.spill_item_stack({ position = position_or_opts, stack = stack, enable_looted = enable_looted })
end

function Public.player_flying_text(player, opts)
    player.create_local_flying_text(opts)
end

function Public.flying_text(player, surface, position, text, color)
    if not player then
        for _, p in pairs(game.connected_players) do
            if p.surface == surface then
                p.create_local_flying_text({ text = text, position = position, color = color })
            end
        end
    else
        player.create_local_flying_text({ text = text, position = position, color = color })
    end
end

function Public.get_max_wire_distance(entity)
    if entity.prototype.get_max_wire_distance then
        return entity.prototype.get_max_wire_distance()
    end

    return entity.get_max_wire_distance()
end

function Public.disconnect_foreign_pole_links(entity, force, on_disconnect)
    if not entity.valid or entity.type ~= "electric-pole" then
        return
    end

    if Public.get_max_wire_distance(entity) <= 0 then
        return
    end

    local pole_connector = entity.get_wire_connector(defines.wire_connector_id.pole_copper, false)

    if pole_connector and pole_connector.valid then
        for _, connection in pairs(pole_connector.connections) do
            local connected_connector = connection.target

            if connected_connector and connected_connector.valid then
                local other_pole = connected_connector.owner

                if other_pole and other_pole.valid and other_pole.force ~= force then
                    pole_connector.disconnect_from(connected_connector, defines.wire_origin.script)

                    if on_disconnect then
                        on_disconnect()
                    end
                end
            end
        end
    end
end

function Public.connect_poles(entity, pole)
    local source_wire = entity.get_wire_connector(defines.wire_connector_id.pole_copper, false)

    local target_wire = pole.get_wire_connector(defines.wire_connector_id.pole_copper, false)

    if source_wire and target_wire then
        source_wire.connect_to(target_wire, false, defines.wire_origin.script)
    end
end

function Public.set_minable(entity, minable)
    entity.minable_flag = minable
end

function Public.set_entity_active(entity, active)
    entity.disabled_by_script = not active
end

return Public
