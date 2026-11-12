-- Shared X-Action behavior for the playable Berdly party member.
local Actions = {}

function Actions.getXAction(battler)
    if battler and battler.chara and battler.chara.id == "berdly" then
        return "B-Action"
    end
    return nil
end

function Actions.perform(enemy)
    if not enemy then
        return "* Berdly's scan cannot find a target."
    end

    -- Exposure is set to two enemy-turn ticks because Berdly is fifth in the
    -- six-member roster. This lets the remaining ally and the following party
    -- round benefit before the status expires.
    enemy.ten_shadows_exposed_turns = math.max(enemy.ten_shadows_exposed_turns or 0, 2)

    if Game and Game.giveTension then
        Game:giveTension(8)
    end

    return "* Berdly runs a tactical scan. The target's guard is exposed. (+8 TP)"
end

function Actions.install()
    if not EnemyBattler then
        return false, "EnemyBattler is unavailable"
    end
    if EnemyBattler._ten_shadows_berdly_xaction then
        return true
    end

    local original_get_x_action = EnemyBattler.getXAction
    local original_on_act = EnemyBattler.onAct
    if type(original_get_x_action) ~= "function" or type(original_on_act) ~= "function" then
        return false, "EnemyBattler X-Action hooks are unavailable"
    end

    EnemyBattler.getXAction = function(enemy, battler, ...)
        local action = Actions.getXAction(battler)
        if action then
            return action
        end
        return original_get_x_action(enemy, battler, ...)
    end

    EnemyBattler.onAct = function(enemy, battler, name, ...)
        if name == "B-Action" and battler and battler.chara and battler.chara.id == "berdly" then
            return Actions.perform(enemy, battler)
        end
        return original_on_act(enemy, battler, name, ...)
    end

    EnemyBattler._ten_shadows_berdly_xaction = true
    return true
end

return Actions
