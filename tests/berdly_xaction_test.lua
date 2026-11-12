-- Regression test for the shared Berdly X-Action hooks.
local tension = 0

Game = {
    giveTension = function(_, amount)
        tension = math.min(100, tension + amount)
    end,
}

EnemyBattler = {}
function EnemyBattler:getXAction(battler)
    return "Standard"
end
function EnemyBattler:onAct(battler, name)
    return "* Base action: " .. tostring(name)
end

local Actions = assert(dofile("scripts/ten_shadows/berdly_actions.lua"))
assert(Actions.install(), "Berdly X-Action hooks must install")
assert(Actions.install(), "Installing the hook twice must be safe")

local berdly_battler = {chara = {id = "berdly"}}
local kris_battler = {chara = {id = "kris"}}
local enemy = {}

assert(EnemyBattler.getXAction(enemy, berdly_battler) == "B-Action",
    "Berdly must receive his dedicated B-Action label on every enemy")
assert(EnemyBattler.getXAction(enemy, kris_battler) == "Standard",
    "Other party members must retain the enemy's standard X-Action")

enemy.ten_shadows_exposed_turns = 1
local message = EnemyBattler.onAct(enemy, berdly_battler, "B-Action")
assert(enemy.ten_shadows_exposed_turns == 2,
    "B-Action must keep the target exposed through the following player round")
assert(tension == 8, "B-Action must grant exactly 8 TP")
assert(message:find("tactical scan", 1, true),
    "B-Action must return battle text rather than softlocking the action")

local Shadows = dofile("scripts/ten_shadows/runtime_shadows.lua")
Shadows.onEnemyTurnEnd(enemy)
assert(enemy.ten_shadows_exposed_turns == 1,
    "B-Action exposure must survive the current enemy turn for the next party round")
Shadows.onEnemyTurnEnd(enemy)
assert(enemy.ten_shadows_exposed_turns == 0,
    "B-Action exposure must expire after the following enemy turn")

local other_enemy = {}
local standard_message = EnemyBattler.onAct(other_enemy, kris_battler, "Standard")
assert(standard_message == "* Base action: Standard",
    "Standard X-Action must continue through the original enemy handler")
assert(other_enemy.ten_shadows_exposed_turns == nil,
    "Standard X-Action must not apply Berdly's exposure effect")

print("Shared Berdly B-Action hooks, idempotent installation, exposure lifecycle, and standard X-Action fallback passed")
