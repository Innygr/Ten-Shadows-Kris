-- Runtime effects for Kris's Ten Shadows ACT submenu.
local Shadows = {}
local summon_state = nil
local SUMMON_TURNS = 3

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
    local state = target.ten_shadows_state
    local domain_bonus = state and state.player_domain and state.player_domain.active
    local exposed = (target.ten_shadows_exposed_turns or 0) > 0
        or (state and state.boss and state.boss.exposed > 0)
    local amount = math.floor(attackStat(user) * multiplier * (domain_bonus and 1.35 or 1) + 0.5)
    if exposed then
        amount = math.floor(amount * 1.4 + 0.5)
    end
    target:hurt(amount, user)
    return amount
end

local function expose(target, turns)
    local duration = turns or 1
    target.ten_shadows_exposed_turns = math.max(target.ten_shadows_exposed_turns or 0, duration)
    local state = target.ten_shadows_state
    if state and state.expose then
        state:expose(duration)
    end
end

local function suppressNextWave(target)
    if target.waves and not target.ten_shadows_saved_waves then
        target.ten_shadows_saved_waves = target.waves
        target.waves = {}
    end
end

local function disrupt(target)
    local state = target.ten_shadows_state
    if state and state.disruptKnight then
        -- The Knight loses its next action, but the Titan still attacks.
        state:disruptKnight()
    else
        target.ten_shadows_disrupted = true
        suppressNextWave(target)
    end
end

local function chill(target, amount)
    local state = target.ten_shadows_state
    if state and state.applyChill then
        return state:applyChill(amount)
    end

    target.ten_shadows_chill = (target.ten_shadows_chill or 0) + amount
    if target.ten_shadows_chill >= 3 then
        target.ten_shadows_chill = target.ten_shadows_chill - 3
        target.ten_shadows_frozen_turns = math.max(target.ten_shadows_frozen_turns or 0, 1)
        expose(target, 1)
        suppressNextWave(target)
        return true
    end
    return false
end

Shadows.addChill = chill

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

function Shadows.summonMahoraga()
    if summon_state then return false, "Mahoraga is already summoned." end
    if not Game or not Game.battle or not Game.party then return false, "No active battle." end

    local index
    for i, member in ipairs(Game.party) do
        if member.id == "kris" then index = i break end
    end
    if not index then return false, "Kris is not in the active party." end

    local mahoraga = Game.getPartyMember and Game:getPartyMember("mahoraga")
    if not mahoraga then return false, "Mahoraga party data is unavailable." end
    local battler = Game.battle.party[index]
    if not battler then return false, "Kris's battle slot is unavailable." end

    summon_state = {
        index = index,
        kris = Game.party[index],
        battler = battler,
        turns = SUMMON_TURNS,
    }
    Game.party[index] = mahoraga
    battler.chara = mahoraga
    mahoraga.health = 520
    return true
end

function Shadows.dismissMahoraga()
    if not summon_state or not Game or not Game.party then return false end
    local state = summon_state
    Game.party[state.index] = state.kris
    if state.battler then state.battler.chara = state.kris end
    summon_state = nil
    return true
end

function Shadows.isMahoragaSummoned()
    return summon_state ~= nil
end

-- Encounters call this when the battle is ending. Never leave the temporary
-- shikigami occupying Kris's party slot after a victory, defeat, or escape.
function Shadows.onBattleEnd()
    if not summon_state then return false end
    return Shadows.dismissMahoraga()
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
        if Shadows.isMahoragaSummoned() then
            return "* MAHORAGA is already on the field."
        end
        dealt = damage(user, target, DAMAGE_SCALE[name])
        expose(target, 2)
        disrupt(target)
        target.ten_shadows_adapted = true
        local summoned, reason = Shadows.summonMahoraga()
        if not summoned then
            return "* The wheel turns, but Mahoraga could not manifest: "..tostring(reason)
        end
        return "* WITH THIS TREASURE... MAHORAGA IS SUMMONED! Kris is withdrawn for 3 turns."
    end
    return nil
end

-- Call from an EnemyBattler's turn hooks to make disruption/freeze suppress its next wave.
function Shadows.onEnemyTurnStart(enemy)
    local already_suppressed = enemy.ten_shadows_saved_waves ~= nil
    local disrupted = enemy.ten_shadows_disrupted == true
    local frozen = (enemy.ten_shadows_frozen_turns or 0) > 0
    enemy.ten_shadows_disrupted = false
    if frozen then
        enemy.ten_shadows_frozen_turns = enemy.ten_shadows_frozen_turns - 1
    end
    if already_suppressed then
        return true
    end
    if disrupted or frozen then
        suppressNextWave(enemy)
        return true
    end
    return false
end

function Shadows.onEnemyTurnEnd(enemy)
    local first_enemy = Game and Game.battle and Game.battle.enemies and Game.battle.enemies[1]
    local tick_summon = not first_enemy or first_enemy == enemy
    if summon_state and tick_summon then
        summon_state.turns = summon_state.turns - 1
        if summon_state.turns <= 0 then
            Shadows.dismissMahoraga()
        end
    end
    if enemy.ten_shadows_saved_waves then
        enemy.waves = enemy.ten_shadows_saved_waves
        enemy.ten_shadows_saved_waves = nil
    end
    if (enemy.ten_shadows_exposed_turns or 0) > 0 then
        enemy.ten_shadows_exposed_turns = enemy.ten_shadows_exposed_turns - 1
    end
end

return Shadows
