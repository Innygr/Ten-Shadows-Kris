-- Runtime effects shared by the party's custom Kristal spells.
local RuntimeSpells = {}

function RuntimeSpells.damage(user, target, amount)
    local state = target and target.ten_shadows_state
    local titan_armour_exposed = target and target.ten_shadows_role == "titan"
        and state and state.boss and state.boss.exposed > 0
    local exposed = (target and target.ten_shadows_exposed_turns or 0) > 0
        or titan_armour_exposed
    if exposed then amount = math.floor(amount * 1.4 + 0.5) end
    target:hurt(amount, user)
    return amount
end

function RuntimeSpells.addChill(target, amount)
    local state = target and target.ten_shadows_state
    if state and state.applyChill then
        return state:applyChill(amount)
    end

    target.ten_shadows_chill = (target.ten_shadows_chill or 0) + amount
    if target.ten_shadows_chill >= 3 then
        target.ten_shadows_chill = target.ten_shadows_chill - 3
        target.ten_shadows_frozen_turns = math.max(target.ten_shadows_frozen_turns or 0, 1)
        target.ten_shadows_exposed_turns = math.max(target.ten_shadows_exposed_turns or 0, 1)
        if target.waves and not target.ten_shadows_saved_waves then
            target.ten_shadows_saved_waves = target.waves
            target.waves = {}
        end
        return true
    end
    return false
end

function RuntimeSpells.disrupt(target)
    local state = target and target.ten_shadows_state
    if state and state.disruptKnight then
        state:disruptKnight()
    else
        target.ten_shadows_disrupted = true
    end
end

function RuntimeSpells.heal(target, amount)
    if not target or target.is_down then return false end
    target:heal(amount)
    return true
end

function RuntimeSpells.revive(target)
    if not target or not target.chara then return false end
    local chara = target.chara
    local max_hp = chara:getStat("health")
    if target.is_down or chara:getHealth() <= 0 then
        chara:setHealth(math.ceil(max_hp / 2))
        target:checkHealth(false)
        target:statusMessage("msg", "up", nil, true)
    else
        target:heal(math.ceil(max_hp / 2))
    end
    return true
end

-- Kris can be brought back by another party member's X-Action. The battle
-- battler owns the downed state/status animation; update its PartyMember HP
-- first, then let Kristal refresh the battler exactly as REVIVESONG does.
function RuntimeSpells.wakeKris()
    if not Game or not Game.battle then
        return false, "There is no active battle."
    end

    for _, battler in ipairs(Game.battle.party or {}) do
        local chara = battler and battler.chara
        if chara and chara.id == "kris" then
            local health = chara.getHealth and chara:getHealth() or chara.health
            if not battler.is_down and not (type(health) == "number" and health <= 0) then
                return false, "Kris is already standing."
            end

            if chara.setHealth then
                chara:setHealth(1)
            else
                chara.health = 1
            end
            if battler.checkHealth then
                battler:checkHealth(false)
            end
            if battler.statusMessage then
                battler:statusMessage("msg", "up", nil, true)
            end
            return true
        end
    end

    return false, "Kris cannot be reached right now."
end

function RuntimeSpells.brighten()
    if not Game or not Game.battle then return false end
    local eligible = {kris = true, susie = true, ralsei = true}
    for _, battler in ipairs(Game.battle.party) do
        local id = battler.chara and battler.chara.id
        -- The Brighten buff explicitly excludes reserve recruits and the Vessel.
        if eligible[id] and battler:isActive() then
            battler.chara:addStatBuff("defense", 1, 1)
        end
    end
    Game.battle.ten_shadows_brightened = true
    return true
end

function RuntimeSpells.brightenAct(state)
    local failure = {
        "* The Titan's light cannot be strengthened right now."
    }
    if not state or not Game or not Game.battle then
        return failure
    end
    -- The ACT menu already charged the 4 TP. Do not spend it again here.
    if not state:brighten(true) then
        return failure
    end
    if not RuntimeSpells.brighten() then
        return failure
    end
    return {
        "* Kris, Susie, and Ralsei channel their strength together.",
        "* Their DEF increased for this turn."
    }
end

return RuntimeSpells
