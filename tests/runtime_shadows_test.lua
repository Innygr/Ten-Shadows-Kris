local Shadows = dofile("scripts/ten_shadows/runtime_shadows.lua")

local tension = 0
local function member()
    return {
        chara = {getHealth = function() return 50 end},
        isActive = function() return true end,
        healed = 0,
        heal = function(self, amount) self.healed = self.healed + amount end,
    }
end
local allies = {member(), member()}
Game = {
    battle = {party = allies},
    giveTension = function(self, amount) tension = tension + amount end,
}

local user = {chara = {getStat = function(_, stat)
    if stat == "attack" then return 17 end
    return 0
end}}
local target = {hp = 500}
function target:hurt(amount) self.hp = self.hp - amount; self.last_damage = amount end

local text = Shadows.use("NUE", user, target)
assert(target.last_damage == 26, "NUE damage must scale from 17 AT")
assert(tension == 5, "NUE must grant 5 TP")

Shadows.use("DIVINE DOG", user, target)
assert(target.ten_shadows_exposed_turns == 1, "Divine Dog must expose")
Shadows.use("NUE", user, target)
assert(target.last_damage == 36, "exposed targets take increased shadow damage")

Shadows.use("TOAD", user, target)
assert(target.ten_shadows_disrupted == true, "Toad must disrupt")
Shadows.use("GREAT SERPENT", user, target)
assert(target.ten_shadows_disrupted == true, "Great Serpent must disrupt")
Shadows.use("PIERCING OX", user, target)
assert(target.ten_shadows_exposed_turns == 2, "Piercing Ox must expose for two turns")
Shadows.use("TIGER FUNERAL", user, target)
assert(target.ten_shadows_chill == 1, "Tiger Funeral must build chill")
Shadows.use("MAHORAGA", user, target)
assert(target.ten_shadows_adapted == true, "Mahoraga must apply adaptation")

Shadows.use("RABBIT ESCAPE", user, target)
assert(allies[1].healed == 8 and allies[2].healed == 8, "Rabbit Escape must heal all active allies")
assert(tension == 18, "Rabbit Escape must grant 8 TP after two NUE uses")
Shadows.use("ROUND DEER", user, target)
assert(allies[1].healed == 26 and allies[2].healed == 26, "Round Deer must heal all active allies")

local chilled = {waves = {"ice_wave"}}
Shadows.addChill(chilled, 3)
assert(chilled.ten_shadows_frozen_turns == 1, "three chill must freeze")
assert(#chilled.waves == 0, "freeze must suppress the next wave")

local kris_member = {id = "kris", health = 290}
local mahoraga_member = {id = "mahoraga", health = 520}
local kris_battler = {chara = kris_member}
Game.party = {kris_member, member()}
Game.getPartyMember = function(_, id)
    if id == "mahoraga" then return mahoraga_member end
end
Game.battle.party = {kris_battler, {chara = Game.party[2]}}

local summon_message = Shadows.use("MAHORAGA", user, target)
assert(string.find(summon_message, "SUMMONED"), "Mahoraga ACT must summon")
assert(Game.party[1] == mahoraga_member, "Mahoraga must replace Kris in the active party")
assert(kris_battler.chara == mahoraga_member, "Kris's battle slot must become Mahoraga")
assert(Shadows.isMahoragaSummoned(), "summon state must be active")
Shadows.onEnemyTurnEnd({})
Shadows.onEnemyTurnEnd({})
assert(Game.party[1] == mahoraga_member, "Mahoraga must remain for the first two turns")
Shadows.onEnemyTurnEnd({})
assert(Game.party[1] == kris_member, "Kris must return after three turns")
assert(kris_battler.chara == kris_member, "Kris's battle slot must be restored")
assert(not Shadows.isMahoragaSummoned(), "summon state must clear on return")

-- Ending a battle early must also restore Kris immediately, without waiting
-- for all three enemy turns.
local early_summon = Shadows.use("MAHORAGA", user, target)
assert(string.find(early_summon, "SUMMONED"), "Mahoraga must be summonable again")
assert(Shadows.onBattleEnd(), "battle-end cleanup must dismiss Mahoraga")
assert(Game.party[1] == kris_member, "battle-end cleanup must restore Kris to the party")
assert(kris_battler.chara == kris_member, "battle-end cleanup must restore Kris's battler")
assert(not Shadows.isMahoragaSummoned(), "battle-end cleanup must clear summon state")

local enemy = {waves = {"test_wave"}, ten_shadows_disrupted = true}
assert(Shadows.onEnemyTurnStart(enemy) == true, "disruption must suppress the next wave")
assert(#enemy.waves == 0, "disrupted enemy must not launch its wave")
Shadows.onEnemyTurnEnd(enemy)
assert(enemy.waves[1] == "test_wave", "enemy waves must restore after disruption")
assert(Shadows.onEnemyTurnStart(enemy) == false, "disruption must not suppress a second wave")

-- Boss-bound status actions must modify the shared scheduler, not suppress
-- the complete Knight + Titan wave (the Titan still gets its attacks).
local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local boss_state = CombatState.new()
local boss_target = {
    hp = 260,
    waves = {"knight_titan_assault"},
    ten_shadows_state = boss_state,
}
function boss_target:hurt(amount)
    self.hp = self.hp - amount
    boss_state.boss.hp = self.hp
end

Shadows.use("TOAD", user, boss_target)
assert(boss_state.knight_disrupted == 1, "Toad must disrupt the Knight's next scheduler action")
assert(boss_target.ten_shadows_saved_waves == nil and #boss_target.waves == 1,
    "Knight disruption must leave the Titan's shared wave available")

local boss_chill = {ten_shadows_state = CombatState.new()}
Shadows.addChill(boss_chill, 3)
assert(boss_chill.ten_shadows_state.boss.frozen_turns == 1,
    "three CHILL stacks must freeze the Knight in the shared state")
assert(boss_chill.ten_shadows_state.boss.exposed == 1,
    "freezing the Knight must expose the shared boss")

local domain_state = CombatState.new()
domain_state.player_domain.active = true
local domain_target = {hp = 260, ten_shadows_state = domain_state}
function domain_target:hurt(amount) self.last_damage = amount end
Shadows.use("NUE", user, domain_target)
assert(domain_target.last_damage == 34,
    "Chimera Shadow Garden must boost summon damage by 1.35")

print("Ten Shadows effects and Attack scaling tests passed.")
