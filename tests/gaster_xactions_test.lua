local tension = 0
Game = {giveTension = function(first, second) tension = tension + (second or first) end}
local berdly_actions = dofile("scripts/ten_shadows/berdly_actions.lua")
modRequire = function(path)
    assert(path == "scripts/ten_shadows/berdly_actions", "unexpected module requested")
    return berdly_actions
end
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local gaster = {ten_shadows_gaster_encounter = true, ten_shadows_exposed_turns = 0}
local function battler(id) return {chara = {id = id}} end

local b = BossActions.onAct(gaster, battler("berdly"), "B-Action", function()
    error("B-Action must be handled by the custom boss action router")
end)
assert(type(b) == "table" and b[1] == "* BERDLY: I HAVE A THEORY!",
    "Berdly should announce his Gaster theory")
assert(gaster.ten_shadows_exposed_turns == 2, "Berdly's scan still exposes Gaster")
assert(tension == 8, "Berdly's scan still grants 8 TP")
assert(gaster.mercy == 15, "Berdly's theory grants 15% Mercy")

local v = BossActions.onAct(gaster, battler("vessel"), "V-Act", function()
    error("V-Act must be handled by the custom boss action router")
end)
assert(v == "* VESSEL: Gaster is green! (+5% MERCY, +8 TP)", "Vessel should call Gaster green")
assert(tension == 16, "V-Act should grant 8 TP")
assert(gaster.mercy == 20, "V-Act grants 5% Mercy")

local n = BossActions.onAct(gaster, battler("noelle"), "N-Action", function()
    error("N-Action must be handled by the custom boss action router")
end)
assert(n:find("green his natural colour", 1, true), "Noelle should react to Gaster's colour")
assert(gaster.ten_shadows_exposed_turns == 2, "Noelle still exposes Gaster")
assert(gaster.mercy == 35, "Noelle grants 15% Mercy")

local r = BossActions.onAct(gaster, battler("ralsei"), "R-Action", function()
    error("R-Action must be handled by the custom boss action router")
end)
assert(r:find("ask him why", 1, true), "Ralsei should politely react to Gaster")
assert(tension == 24, "R-Action should grant 8 TP")
assert(gaster.mercy == 55, "R-Action grants 20% Mercy")

local s = BossActions.onAct(gaster, battler("susie"), "S-Action", function()
    error("S-Action must be handled by the custom boss action router")
end)
assert(s:find("hasn't slept", 1, true), "Susie should have Gaster-specific dialogue")
assert(gaster.mercy == 55, "Susie's blunt comment does not grant Mercy")

local ordinary = {ten_shadows_exposed_turns = 0}
local ordinary_b = BossActions.onAct(ordinary, battler("berdly"), "B-Action", function() end)
assert(type(ordinary_b) == "string" and ordinary_b:find("tactical scan", 1, true),
    "Berdly should keep his normal action outside the Gaster fight")

assert(gaster.disable_mercy == nil or gaster.disable_mercy == false,
    "Gaster must show his Mercy bar")
print("Gaster-specific X-Actions, Mercy gains, and TP effects passed.")
