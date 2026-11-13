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

-- Integration guard: the boss ACT handler must resolve Brighten directly and
-- must not inject a second Spell action through Kristal's powerAct helper.
local file = assert(io.open("scripts/battle/enemies/roaring_knight_titan.lua", "r"))
local enemy_source = file:read("*a")
file:close()
assert(enemy_source:find("return Effects.brightenAct(state)", 1, true),
    "boss BRIGHTEN handler must call the direct grouped-ACT resolver")
assert(not enemy_source:find('powerAct("ts_brighten"', 1, true),
    "boss BRIGHTEN must not enqueue a nested SPELL action")

-- Keep the menu's TP charge and the exact three-member group intact.
local mod_file = assert(io.open("mod.lua", "r"))
local mod_source = mod_file:read("*a")
mod_file:close()
assert(mod_source:find('{"BRIGHTEN", "Kris strengthens the party.", 4', 1, true),
    "BRIGHTEN must keep its 4 TP menu cost")
assert(mod_source:find('{"kris", "susie", "ralsei"}', 1, true),
    "BRIGHTEN must keep Kris, Susie, and Ralsei as its participant group")

print("Grouped BRIGHTEN ACT tests passed.")
