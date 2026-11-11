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
assert(tension == 13, "Rabbit Escape must grant 8 TP")
Shadows.use("ROUND DEER", user, target)
assert(allies[1].healed == 26 and allies[2].healed == 26, "Round Deer must heal all active allies")

local chilled = {waves = {"ice_wave"}}
Shadows.addChill(chilled, 3)
assert(chilled.ten_shadows_frozen_turns == 1, "three chill must freeze")
assert(#chilled.waves == 0, "freeze must suppress the next wave")

local enemy = {waves = {"test_wave"}, ten_shadows_disrupted = true}
assert(Shadows.onEnemyTurnStart(enemy) == true, "disruption must suppress the next wave")
assert(#enemy.waves == 0, "disrupted enemy must not launch its wave")
Shadows.onEnemyTurnEnd(enemy)
assert(enemy.waves[1] == "test_wave", "enemy waves must restore after disruption")
assert(Shadows.onEnemyTurnStart(enemy) == false, "disruption must not suppress a second wave")

print("Ten Shadows effects and Attack scaling tests passed.")
