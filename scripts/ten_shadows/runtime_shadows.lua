-- Runtime effects for Kris's Ten Shadows ACT submenu.
local Shadows = {}

local DAMAGE_SCALE = {
    NUE = 1.5,
    ["DIVINE DOG"] = 1.8,
    ["GREAT SERPENT"] = 1.6,
    ["MAX ELEPHANT"] = 2.5,
    ["PIERCING OX"] = 3.0,
    ["TIGER FUNERAL"] = 3.8,
    MAHORAGA = 5.6,
}

local function attackStat(user)
    if user and user.chara and user.chara.getStat then
        return math.max(1, user.chara:getStat("attack") or 1)
    end
    return 1
end

local function damage(user, target, multiplier)
    if not target or not target.hurt then return 0 end
    local amount = math.floor(attackStat(user) * multiplier + 0.5)
    if (target.ten_shadows_exposed_turns or 0) > 0 then
        amount = math.floor(amount * 1.4 + 0.5)
    end
    target:hurt(amount, user)
    return amount
end

local function expose(target, turns)
    target.ten_shadows_exposed_turns = math.max(target.ten_shadows_exposed_turns or 0, turns or 1)
end

local function disrupt(target)
    target.ten_shadows_disrupted = true
end

local function chill(target, amount)
    target.ten_shadows_chill = (target.ten_shadows_chill or 0) + amount
    if target.ten_shadows_chill >= 3 then
        target.ten_shadows_chill = target.ten_shadows_chill - 3
        target.ten_shadows_frozen_turns = math.max(target.ten_shadows_frozen_turns or 0, 1)
        expose(target, 1)
        return true
    end
    return false
end

local function healParty(amount)
    if not Game or not Game.battle then return end
    for _, member in ipairs(Game.battle.party) do
        if member.isActive and member:isActive() and member.chara and member.chara:getHealth() > 0 then
            member:heal(amount)
        end
    end
end

local function addTP(amount)
    if Game and Game.giveTension then
        Game:giveTension(amount)
    end
end

function Shadows.use(name, user, target)
    local dealt = 0
    if name == "TOAD" then
        disrupt(target)
        return "* TOAD binds the target. Its next attack is disrupted."
    elseif name == "NUE" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        addTP(5)
        return "* NUE dives from above! "..dealt.." damage. (+5 TP)"
    elseif name == "DIVINE DOG" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        expose(target, 1)
        return "* DIVINE DOG strikes for "..dealt.." damage. The target is exposed!"
    elseif name == "GREAT SERPENT" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        disrupt(target)
        return "* GREAT SERPENT constricts the target for "..dealt.." damage and disrupts it."
    elseif name == "MAX ELEPHANT" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        return "* MAX ELEPHANT crashes down for "..dealt.." damage!"
    elseif name == "RABBIT ESCAPE" then
        healParty(8)
        addTP(8)
        return "* RABBIT ESCAPE restores 8 HP to each active ally. (+8 TP)"
    elseif name == "ROUND DEER" then
        healParty(18)
        return "* ROUND DEER restores 18 HP to each active ally."
    elseif name == "PIERCING OX" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        expose(target, 2)
        return "* PIERCING OX charges for "..dealt.." damage. The target is exposed!"
    elseif name == "TIGER FUNERAL" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        local frozen = chill(target, 1)
        return frozen and ("* TIGER FUNERAL deals "..dealt.." damage and freezes the target!")
            or ("* TIGER FUNERAL deals "..dealt.." damage and builds CHILL.")
    elseif name == "MAHORAGA" then
        dealt = damage(user, target, DAMAGE_SCALE[name])
        expose(target, 2)
        disrupt(target)
        target.ten_shadows_adapted = true
        return "* MAHORAGA deals "..dealt.." damage. The wheel turns; the target is exposed and disrupted."
    end
    return nil
end

-- Call from an EnemyBattler's turn hooks to make disruption/freeze suppress its next wave.
function Shadows.onEnemyTurnStart(enemy)
    local disrupted = enemy.ten_shadows_disrupted == true
    local frozen = (enemy.ten_shadows_frozen_turns or 0) > 0
    enemy.ten_shadows_disrupted = false
    if frozen then
        enemy.ten_shadows_frozen_turns = enemy.ten_shadows_frozen_turns - 1
    end
    if disrupted or frozen then
        if enemy.waves and not enemy.ten_shadows_saved_waves then
            enemy.ten_shadows_saved_waves = enemy.waves
            enemy.waves = {}
        end
        return true
    end
    return false
end

function Shadows.onEnemyTurnEnd(enemy)
    if enemy.ten_shadows_saved_waves then
        enemy.waves = enemy.ten_shadows_saved_waves
        enemy.ten_shadows_saved_waves = nil
    end
    if (enemy.ten_shadows_exposed_turns or 0) > 0 then
        enemy.ten_shadows_exposed_turns = enemy.ten_shadows_exposed_turns - 1
    end
end

return Shadows
