-- Runtime effects shared by the party's custom Kristal spells.
local RuntimeSpells = {}

function RuntimeSpells.damage(user, target, amount)
    local exposed = target.ten_shadows_exposed_turns or 0
    if exposed > 0 then amount = math.floor(amount * 1.4 + 0.5) end
    target:hurt(amount, user)
    return amount
end

function RuntimeSpells.addChill(target, amount)
    target.ten_shadows_chill = (target.ten_shadows_chill or 0) + amount
    if target.ten_shadows_chill >= 3 then
        target.ten_shadows_chill = target.ten_shadows_chill - 3
        target.ten_shadows_frozen_turns = math.max(target.ten_shadows_frozen_turns or 0, 1)
        target.ten_shadows_exposed_turns = math.max(target.ten_shadows_exposed_turns or 0, 1)
        return true
    end
    return false
end

function RuntimeSpells.disrupt(target)
    target.ten_shadows_disrupted = true
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

return RuntimeSpells
