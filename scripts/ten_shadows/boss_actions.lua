-- Shared ACT handling for the coordinated Knight + Titan encounter.
-- The selected EnemyBattler remains the target, so attacks always reduce that
-- boss's independent health pool, including when only one survivor remains.
local BossActions = {}

local SOUL_MODE_ACTIONS = {
    ["RED SOUL"] = "red", -- Red restores the ordinary attack pool.
    ["BLUE SOUL"] = "blue",
    ["GREEN SOUL"] = "green",
    ["YELLOW SOUL"] = "yellow",
    ["PURPLE SOUL"] = "purple",
    ["ORANGE SOUL"] = "orange",
    ["CYAN SOUL"] = "cyan",
}

function BossActions.onAct(enemy, battler, name, base_on_act)
    if name == "Inspect" or name == "Check" or name == "CHECK" then
        return enemy:getCheckText(battler)
    end

    if name == "WAKE KRIS" then
        local Effects = modRequire("scripts/ten_shadows/runtime_spells")
        local restored, reason = Effects.wakeKris()
        if not restored then
            return "* " .. tostring(reason or "Kris cannot be woken right now.")
        end
        return {
            "* The party calls Kris back to their feet!",
            "* Kris returns with 1 HP.",
        }
    end

    local state = enemy.ten_shadows_state
    if name == "BRIGHTEN" then
        local Effects = modRequire("scripts/ten_shadows/runtime_spells")
        -- The menu has already charged 4 TP and grouped Kris, Susie, and Ralsei
        -- into this ACT. Resolve the buff here; powerAct would queue a second
        -- SPELL action while the current ACT group is still being processed.
        return Effects.brightenAct(state)
    end

    if name == "FUSION DOMAIN" then
        if not state or not state:expandFusionDomain(true) then
            return "* Kris and Vessel cannot complete the Domain right now."
        end
        return {
            "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.",
            "* Vessel closes the barrier as Kris floods it with shadows.",
            "* Shadow portals can redirect party spells anywhere inside the Domain.",
            "* Granite Blast can emerge from anywhere within the garden.",
        }
    end

    if name == "CHIMERA SHADOW GARDEN" then
        if not state or not state:expandChimeraDomain(true) then
            return "* The shadows cannot form the domain again."
        end
        return {
            "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.",
            "* The battlefield sinks into a sea of shadows. Ten Shadows are empowered.",
        }
    end

    if name == "GRANITE BLAST" then
        local battle = Game and Game.battle
        local arena = battle and battle.arena
        if not state or not state.fusion_domain or not state.fusion_domain.active
            or not arena or not arena.width or not arena.height then
            return "* GRANITE BLAST requires the active Fusion Domain."
        end

        -- The exit portal follows the SOUL's current arena position. This
        -- gives the player meaningful placement from their last movement
        -- without adding a second targeting UI to Kristal's ACT flow.
        local soul = battle.soul
        local arena_x, arena_y = arena.x or 0, arena.y or 0
        local origin_x = arena.width * 0.5
        local origin_y = arena.height * 0.5
        if soul then
            origin_x = math.max(8, math.min(arena.width - 8, soul.x - arena_x))
            origin_y = math.max(8, math.min(arena.height - 8, soul.y - arena_y))
        end

        -- The entry gate is placed across the Domain from the exit gate.
        -- routePartySpell copies the descriptor and preserves the chosen boss
        -- target while moving the launch origin to the exit portal.
        local entry = {
            x = math.max(8, math.min(arena.width - 8, arena.width - origin_x)),
            y = math.max(8, math.min(arena.height - 8, arena.height - origin_y)),
        }
        local target = {
            x = (enemy.x or 0) + (enemy.width or 0) * 0.5,
            y = (enemy.y or 0) + (enemy.height or 0) * 0.5,
        }
        local descriptor, reason = state:createGraniteBlast(
            {x = origin_x, y = origin_y}, target, 1
        )
        if not descriptor then
            return "* " .. tostring(reason or "Granite Blast could not form.")
        end

        local routed, route_reason = state:routePartySpell(descriptor, entry, {
            x = origin_x, y = origin_y,
        })
        if not routed then
            return "* " .. tostring(route_reason or "The shadow portals could not connect.")
        end

        local damage = math.floor(58 * routed.output + 0.5)
        enemy:hurt(damage, battler)

        -- The visual is attached to the live battle stage and never owns
        -- damage; the ACT above applies the hit exactly once.
        local GraniteBlast = modRequire("scripts/battle/objects/granite_blast")
        local visual = GraniteBlast(
            arena_x + entry.x, arena_y + entry.y,
            arena_x + routed.origin_x, arena_y + routed.origin_y,
            routed.target_x, routed.target_y, routed.output
        )
        local parent = battle.addChild and battle or (Game.stage and Game.stage.addChild and Game.stage)
        if parent then
            parent:addChild(visual)
        end

        return {
            "* VESSEL FIRES GRANITE BLAST THROUGH THE SHADOW PORTALS!",
            "* The 100% output blast deals " .. tostring(damage) .. " damage.",
        }
    end

    local soul_mode = SOUL_MODE_ACTIONS[name]
    if soul_mode then
        if not state then
            return "* The Vessel's SOUL cannot reach the shared battle state."
        end
        local changed, reason = state:setSoulMode(soul_mode)
        if not changed then return "* " .. tostring(reason) end
        return "* The Vessel shifts to " .. string.upper(soul_mode) .. " SOUL. The Knight and Titan adapt."
    end

    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    local shadow_message = Shadows.use(name, battler, enemy)
    if shadow_message then return shadow_message end

    return base_on_act(enemy, battler, name)
end

return BossActions
