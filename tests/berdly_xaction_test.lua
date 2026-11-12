-- Regression test for Berdly's unique X-Action.
local tension = 0

Game = {
    giveTension = function(_, amount)
        tension = math.min(100, tension + amount)
    end,
}

EnemyBattler = {}
modRequire = function()
    return {use = function() return nil end}
end
function Class(_)
    return {}, {
        getXAction = function(_, battler)
            return "Standard"
        end,
        onAct = function(_, battler, name)
            return "* Base action: " .. tostring(name)
        end,
    }
end

local RuntimeDummy = assert(dofile("scripts/battle/enemies/runtime_dummy.lua"))
local berdly_battler = {chara = {id = "berdly"}}
local kris_battler = {chara = {id = "kris"}}

assert(RuntimeDummy.getXAction({}, berdly_battler) == "B-Action",
    "Berdly must receive his dedicated B-Action label")
assert(RuntimeDummy.getXAction({}, kris_battler) == "Standard",
    "Other party members must retain the standard X-Action")

local target = {ten_shadows_exposed_turns = 0}
local message = RuntimeDummy.onAct(target, berdly_battler, "B-Action")
assert(target.ten_shadows_exposed_turns == 1,
    "B-Action must expose the target for the next player damage window")
assert(tension == 8, "B-Action must grant exactly 8 TP")
assert(message:find("tactical scan", 1, true),
    "B-Action must return battle text rather than softlocking the action")

local other_target = {}
local standard_message = RuntimeDummy.onAct(other_target, kris_battler, "Standard")
assert(standard_message:find("standard X-ACT handler works", 1, true),
    "Standard X-Action must keep the existing ACT_TEXT fallback")
assert(other_target.ten_shadows_exposed_turns == nil,
    "Standard X-Action must not apply Berdly's exposure effect")

print("Berdly B-Action identity, target exposure, TP gain, and standard X-Action fallback passed")
