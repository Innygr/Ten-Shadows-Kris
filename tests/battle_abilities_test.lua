local CombatState = dofile("scripts/ten_shadows/combat_state.lua")

local tension = 4
Game = {
    battle = {
        party = {
            {chara = {
                id = "kris",
                health = 210,
                getHealth = function(self) return self.health end,
                getStat = function() return 290 end,
            }},
            {chara = {
                id = "vessel",
                health = 180,
                getHealth = function(self) return self.health end,
                getStat = function() return 240 end,
            }},
        },
    },
    getTension = function() return tension end,
    setTension = function(_, value) tension = value end,
}
modRequire = function(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    return dofile(path .. ".lua")
end

local Abilities = dofile("scripts/ten_shadows/battle_abilities.lua")
local battle = Game.battle
local state = Abilities.get(battle)
assert(state and state.ten_shadows_general_battle,
    "ordinary encounters must receive their own Ten Shadows state")
assert(Abilities.get(battle) == state,
    "the state must be stable for the lifetime of a battle")

Abilities.syncParty(battle, state)
assert(state:getMember("kris").hp == 210,
    "battle HP must synchronize into the shared state")
assert(state:getMember("vessel").hp == 180,
    "Vessel HP must synchronize into the shared state")
assert(state.tp == 4, "the live Kristal TP pool must be authoritative")

assert(state:expandVesselDomain(true),
    "Vessel can activate their Domain in an ordinary encounter")
Abilities.tickEnemyTurn(battle)
assert(tension == 2 and state.vessel_domain.active,
    "the standalone Vessel Domain must pay its 2 TP upkeep after a Wave")

tension = 0
Abilities.tickEnemyTurn(battle)
assert(not state.vessel_domain.active,
    "the standalone Vessel Domain must end when upkeep cannot be paid")
assert(state.vessel_domain.cancel_reason == "insufficient_tp",
    "Domain cancellation must retain its reason")

-- Granite Blast must work against an ordinary enemy even when the encounter
-- has no arena object (the regression that originally caused the nil-arena crash).
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local target = {x = 300, y = 120, width = 32, height = 32, health = 900}
function target:hurt(amount)
    self.health = self.health - amount
end
local vessel_battler = battle.party[2]
local blast_message = BossActions.onAct(target, vessel_battler, "GRANITE BLAST", function()
    error("Granite Blast must not fall through to the base ACT handler")
end)
assert(target.health == 842, "ordinary-battle Granite Blast must deal its 58 damage")
assert(type(blast_message) == "table", "Granite Blast must return its action dialogue")

-- The Ultimate Beam also matures after one ordinary enemy turn.
local beam_target = {x = 250, y = 90, width = 20, height = 20, health = 1000}
function beam_target:hurt(amount)
    self.health = self.health - amount
end
assert(state:beginUltimateBeam(beam_target, vessel_battler),
    "ordinary battles can begin Vessel's Ultimate Beam")
Abilities.tickEnemyTurn(battle)
assert(beam_target.health == 420,
    "ordinary-battle Ultimate Beam must resolve 580 damage after one enemy turn")

Abilities.endBattle(battle)
assert(battle.ten_shadows_ability_state == nil,
    "battle end must discard the ordinary encounter state")

local mod_file = assert(io.open("mod.lua", "r"))
local mod_source = mod_file:read("*a")
mod_file:close()
assert(mod_source:find("EnemyBattler.onAct = function", 1, true),
    "ordinary EnemyBattlers must route custom ACTs through BossActions")
assert(mod_source:find("Abilities.tickEnemyTurn(Game.battle)", 1, true),
    "ordinary battle Domains must tick at the Wave boundary")

local actions_file = assert(io.open("scripts/ten_shadows/boss_actions.lua", "r"))
local actions_source = actions_file:read("*a")
actions_file:close()
assert(actions_source:find("if not state then", 1, true)
    and actions_source:find("state = Abilities.get(battle)", 1, true),
    "custom actions must fall back to battle-wide state outside boss encounters")

print("Battle-wide Ten Shadows ability tests passed.")
