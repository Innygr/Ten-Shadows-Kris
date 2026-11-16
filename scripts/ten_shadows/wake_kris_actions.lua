-- Dynamic X-Action override used while Kris is down.
-- The selected boss resolves the WAKE KRIS action through boss_actions.lua.
local Actions = {}

function Actions.isKrisDown(battle)
    battle = battle or (Game and Game.battle)
    if not battle or not battle.party then return false end

    for _, battler in ipairs(battle.party) do
        local chara = battler and battler.chara
        if chara and chara.id == "kris" then
            local health = chara.getHealth and chara:getHealth() or chara.health
            return battler.is_down == true
                or (type(health) == "number" and health <= 0)
        end
    end
    -- If Kris is not in the battler roster (for example, while Mahoraga is
    -- occupying Kris's slot), do not offer a misleading revival action.
    return false
end

function Actions.getXAction(battler)
    if not battler or not battler.chara or battler.chara.id == "kris" then
        return nil
    end
    if Actions.isKrisDown() then
        return "WAKE KRIS"
    end
    return nil
end

function Actions.install()
    if not EnemyBattler or type(EnemyBattler.getXAction) ~= "function" then
        return false, "EnemyBattler X-Action hook is unavailable"
    end
    if EnemyBattler._ten_shadows_wake_kris_xaction then
        return true
    end

    local original_get_x_action = EnemyBattler.getXAction
    EnemyBattler.getXAction = function(enemy, battler, ...)
        local action = Actions.getXAction(battler)
        if action then
            return action
        end
        return original_get_x_action(enemy, battler, ...)
    end

    EnemyBattler._ten_shadows_wake_kris_xaction = true
    return true
end

return Actions
