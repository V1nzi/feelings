local DEFAUTLT_DEATH_BEHAVIOR = "AdditionalFeeling"

local path = minetest.get_modpath("feelings")

dofile(path .. "/hash.lua")
dofile(path .. "/feelings.lua")
dofile(path .. "/override.lua")

local feelings = Feelings.new(minetest.settings:get("feelings_gain") or 1.0, minetest.settings:get("feelings_max_hear_distance") or 10)

local function hash_node(pos, node) -- for some reason I can't use a node as key in a table, so I try to get a unique identifier this way
    return node.name .. pos.x .. pos.y .. pos.z -- I see nodes as blocks and a block usually doesn't move, but I'm not to sure about the internals of minetest and how falling gravel or flowing water is treated, so this might not always work perfectly
end

local function entity_feeling(e) feelings:feel(e.object:get_pos(), e.object, e.object) end

local function entity_force_feeling(e) feelings:feel(e.object:get_pos(), Hash.random(10), e.object) end

local function entity_stop_feeling(e) feelings:stop_feeling(e.object) end

local function entity_do_if_dead(action)
    return function (e) if e.health <= 0 then action(e) end end
end

local death_behaviors = {
    nodes = {
        Nothing = function (_, _, _) end,
        AdditionalFeeling = function (pos, oldnode, _) feelings:feel(pos, hash_node(pos, oldnode)) end,
        AlwaysAdditionalFeeling = function (pos, oldnode, _) feelings:feel(pos, Hash:random(10)) end,
        InstantlyStopFeeling = function (pos, oldnode, _) feelings:stop_feeling(hash_node(pos, oldnode)) end
    },
    players = {
        Nothing = function (_) end,
        AdditionalFeeling = function (player) feelings:feel(player:get_pos(), player, player) end,
        AlwaysAdditionalFeeling = function (player) feelings:feel(player:get_pos(), Hash:random(10), player) end,
        InstantlyStopFeeling = function (player) feelings:stop_feeling(player) end
    },
    entities = {
        Nothing = function (_) end,
        AdditionalFeeling = entity_do_if_dead(entity_feeling),
        AlwaysAdditionalFeeling = entity_do_if_dead(entity_force_feeling),
        InstantlyStopFeeling = entity_do_if_dead(entity_stop_feeling)
    }
}

if minetest.settings:get_bool("feelings_nodes_feel_punches", false) then
    minetest.register_on_punchnode(function (pos, node, _)
        feelings:feel(pos, hash_node(pos, node))
    end)
end

minetest.register_on_dignode(death_behaviors.nodes[minetest.settings:get("feelings_nodes_death_behavior") or DEFAUTLT_DEATH_BEHAVIOR])

if minetest.settings:get_bool("feelings_players_feel_hp_loss", true) then
    minetest.register_on_player_hpchange(function (player, hp_change)
        if hp_change < 0 then
            feelings:feel(player:get_pos(), player, player)
        end
    end, false)
end

minetest.register_on_dieplayer(death_behaviors.players[minetest.settings:get("feelings_players_death_behavior") or DEFAUTLT_DEATH_BEHAVIOR])

local blacklisted_entities = {} -- these entities aren't allowed to have feelings
blacklisted_entities["__builtin:item"] = true -- dropped item stack
blacklisted_entities["__builtin:falling_node"] = true -- falling block

local whitelisted_entities = {} -- these entities must have feelings (cause I want them to)
whitelisted_entities["carts:cart"] = true -- carts are not physical (https://github.com/minetest/minetest_game/blob/c284e52963ee78afda8f12bbaf915c55df2eb3d1/mods/carts/cart_entity.lua#L3), so I have to whitelist them here


local function chain_feeling_functions(predicate, feelings_trigger, feel)
    for name, entity in pairs(minetest.registered_entities) do
        if whitelisted_entities[name] or (predicate(name, entity) and not blacklisted_entities[name] and entity.physical) then -- only physical entities should have these kind of physical feelings
            local definition = {}

            definition[feelings_trigger] = {
                fchain_type = "after",
                fchain_func = function(self, _, _, _, _)
                    feel(self)
                end
            }

            override:rewrite(name, definition)
        end
    end
end

if minetest.settings:get_bool("feelings_entities_feel_punches", true) then
    chain_feeling_functions(function(_,e) return e.on_punch ~= nil end, "on_punch", entity_feeling)
end

chain_feeling_functions(function(_,e) return e.check_for_death ~= nil end, "check_for_death", death_behaviors.entities[minetest.settings:get("feelings_entities_death_behavior") or DEFAUTLT_DEATH_BEHAVIOR])

minetest.debug(dump(minetest.registered_entities))