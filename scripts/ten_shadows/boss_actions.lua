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
        -- Vessel's 100% output blast hits whichever boss is currently targeted.
        enemy:hurt(58, battler)
        return {
            "* VESSEL FIRES GRANITE BLAST AT 100% OUTPUT!",
            "* The concentrated blast deals 58 damage.",
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
