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
        if not battler or not battler.chara or battler.chara.id ~= "vessel" then
            return "* Only Vessel can shape Granite Blast."
        end
        if not state or not arena or not arena.width or not arena.height then
            return "* Granite Blast cannot find a clear path to its target."
        end

        -- Granite Blast is always available. Outside the Fusion Domain it
        -- fires directly from the SOUL's current position. Inside the Domain,
        -- the same shot is routed through the paired shadow portals.
        local soul = battle.soul
        local arena_x, arena_y = arena.x or 0, arena.y or 0
        local origin_x = arena.width * 0.5
        local origin_y = arena.height * 0.5
        if soul then
            origin_x = math.max(8, math.min(arena.width - 8, soul.x - arena_x))
            origin_y = math.max(8, math.min(arena.height - 8, soul.y - arena_y))
        end

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

        local entry = {x = origin_x, y = origin_y}
        local routed = descriptor
        if state.fusion_domain and state.fusion_domain.active then
            entry = {
                x = math.max(8, math.min(arena.width - 8, arena.width - origin_x)),
                y = math.max(8, math.min(arena.height - 8, arena.height - origin_y)),
            }
            routed, reason = state:routePartySpell(descriptor, entry, {
                x = origin_x, y = origin_y,
            })
            if not routed then
                return "* " .. tostring(reason or "The shadow portals could not connect.")
            end
        end

        local damage = math.floor(58 * routed.output + 0.5)
        enemy:hurt(damage, battler)

        -- The visual is presentation only; the ACT above applies the hit once.
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

        if routed.redirected_by_shadow_portal then
            return {
                "* VESSEL FIRES GRANITE BLAST THROUGH THE SHADOW PORTALS!",
                "* The 100% output blast deals " .. tostring(damage) .. " damage.",
            }
        end
        return {
            "* VESSEL FIRES GRANITE BLAST!",
            "* The 100% output blast deals " .. tostring(damage) .. " damage.",
        }
    end

    if name == "ULTIMATE BEAM" then
        if not battler or not battler.chara or battler.chara.id ~= "vessel" then
            return "* Only Vessel can charge the ultimate beam."
        end
        if not state then
            return "* Vessel cannot reach the ultimate beam's charge state."
        end
        local started, reason = state:beginUltimateBeam(enemy, battler)
        if not started then
            return "* " .. tostring(reason or "The ultimate beam cannot charge right now.")
        end
        return {
            "* VESSEL BEGINS CHARGING THE ULTIMATE BEAM.",
            "* The beam will release after one full enemy turn.",
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
