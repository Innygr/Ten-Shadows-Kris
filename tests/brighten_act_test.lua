local Effects = dofile("scripts/ten_shadows/runtime_spells.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local buffed = {}
local function member(id, active)
    return {
        isActive = function() return active end,
        chara = {
            id = id,
            addStatBuff = function(_, stat, amount, turns)
                expect(stat, "defense", id .. " buff stat")
                expect(amount, 1, id .. " buff amount")
                expect(turns, 1, id .. " buff duration")
                buffed[#buffed + 1] = id
            end,
        },
    }
end

Game = {
    battle = {
        party = {
            member("kris", true),
            member("susie", true),
            member("ralsei", true),
            member("noelle", true),
            member("berdly", true),
            member("vessel", true),
        },
    },
}

local state_calls = 0
local state = {
    brighten = function(self, skip_cost)
        state_calls = state_calls + 1
        expect(skip_cost, true, "grouped ACT must not charge TP twice")
        return true
    end,
}

local result = Effects.brightenAct(state)
expect(type(result), "table", "successful BRIGHTEN must return ACT dialogue")
expect(#result, 2, "successful BRIGHTEN dialogue lines")
expect(state_calls, 1, "boss light state updated once")
expect(#buffed, 3, "BRIGHTEN buffs exactly three participants")
expect(table.concat(buffed, ","), "kris,susie,ralsei", "BRIGHTEN participant order")
expect(Game.battle.ten_shadows_brightened, true, "battle Brighten flag")

local before_failed_attempt = #buffed
local blocked_state = {
    brighten = function(self, skip_cost)
        expect(skip_cost, true, "failed grouped ACT must not charge TP twice")
        return false
    end,
}
local blocked_result = Effects.brightenAct(blocked_state)
expect(type(blocked_result), "table", "blocked BRIGHTEN must return ACT dialogue")
expect(#buffed, before_failed_attempt, "blocked BRIGHTEN must not apply buffs")

local no_state_result = Effects.brightenAct(nil)
expect(type(no_state_result), "table", "missing boss state must return ACT dialogue")
expect(#buffed, before_failed_attempt, "missing boss state must not apply buffs")

-- Load the real boss class and invoke its real onAct method. If BRIGHTEN
-- regresses to powerAct/pushAction, these stubs fail immediately.
EnemyBattler = {
    onAct = function() return "* fallback ACT" end,
}
function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {__index = base})
    return class, base
end
modRequire = function(path)
    if path == "scripts/ten_shadows/runtime_spells" then
        return Effects
    end
    error("Unexpected module requested by BRIGHTEN test: " .. tostring(path))
end

local queued_actions = {
    [4] = {character_id = 4, action = "SPELL", name = "ICE SHOCK"},
    [5] = {character_id = 5, action = "SPELL", name = "TORNADO"},
    [6] = {character_id = 6, action = "ACT", name = "YELLOW SOUL"},
}
Game.battle.character_actions = queued_actions
Game.battle.powerAct = function()
    error("BRIGHTEN must not call powerAct while the ACT group is resolving")
end
Game.battle.pushAction = function()
    error("BRIGHTEN must not enqueue a second action while the ACT group is resolving")
end

local boss_class = dofile("scripts/battle/enemies/roaring_knight_titan.lua")
local boss = {ten_shadows_state = state}
local before_handler_buff_count = #buffed
local before_handler_state_calls = state_calls
local handler_result = boss_class.onAct(boss, Game.battle.party[1], "BRIGHTEN")
expect(type(handler_result), "table", "real boss BRIGHTEN handler returns ACT dialogue")
expect(#handler_result, 2, "real boss BRIGHTEN dialogue lines")
expect(#buffed, before_handler_buff_count + 3,
    "real boss BRIGHTEN handler applies all three buffs")
expect(state_calls, before_handler_state_calls + 1,
    "real boss BRIGHTEN handler updates the Titan state once")
expect(queued_actions[4].name, "ICE SHOCK", "Noelle action remains queued")
expect(queued_actions[5].name, "TORNADO", "Berdly action remains queued")
expect(queued_actions[6].name, "YELLOW SOUL", "Vessel action remains queued")
expect(Game.battle.character_actions, queued_actions,
    "BRIGHTEN must preserve the original character action queue")

-- Keep the menu's TP charge and the exact three-member group intact.
local mod_file = assert(io.open("mod.lua", "r"))
local mod_source = mod_file:read("*a")
mod_file:close()
assert(mod_source:find('{"BRIGHTEN", "Kris strengthens the party.", 4', 1, true),
    "BRIGHTEN must keep its 4 TP menu cost")
assert(mod_source:find('{"kris", "susie", "ralsei"}', 1, true),
    "BRIGHTEN must keep Kris, Susie, and Ralsei as its participant group")

print("Grouped BRIGHTEN ACT tests passed.")
