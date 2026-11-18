-- Regression test for overlapping overworld station dialogue.
local function makeWorld(active)
    return {
        active = active == true,
        starts = 0,
        hasCutscene = function(self)
            return self.active
        end,
        startCutscene = function(self)
            self.starts = self.starts + 1
            return {after = function() end}
        end,
    }
end

Interactable = {
    init = function(self, x, y, shape, properties)
        self.x, self.y = x, y
        self.shape, self.properties = shape, properties or {}
    end,
    onInteract = function(self)
        self.world:startCutscene()
        return true
    end,
    draw = function() end,
}

function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {
        __index = base,
        __call = function(ctor, ...)
            local instance = setmetatable({}, ctor)
            instance:init(...)
            return instance
        end,
    })
    return class, base
end

local Station = dofile("scripts/world/events/station.lua")
Game = {world = makeWorld(false)}

local function stationWithWorld(event_world)
    local station = Station({x = 0, y = 0, width = 40, height = 40, properties = {}})
    station.world = event_world
    return station
end

-- A cutscene on the canonical Game.world must block a station even when its
-- event has a different or stale world reference.
local event_world = makeWorld(false)
Game.world = makeWorld(true)
local station = stationWithWorld(event_world)
assert(station:onInteract() == false, "a station must ignore input during Game.world cutscenes")
assert(event_world.starts == 0, "blocked input must not start an event-world cutscene")

-- The event world is also checked, in case it owns the active cutscene.
event_world = makeWorld(true)
Game.world = makeWorld(false)
station = stationWithWorld(event_world)
assert(station:onInteract() == false, "a station must ignore input during its own world's cutscene")
assert(event_world.starts == 0, "an already-active event cutscene must not be nested")

-- The direct cutscene reference remains a fallback if hasCutscene is absent.
event_world = {cutscene = {ended = false}, starts = 0}
Game.world = makeWorld(false)
station = stationWithWorld(event_world)
assert(station:onInteract() == false, "an active cutscene object must block station input")
assert(event_world.starts == 0, "direct cutscene-state detection must prevent another start")

-- With both worlds idle, the original Interactable behavior still runs once.
event_world = makeWorld(false)
Game.world = makeWorld(false)
station = stationWithWorld(event_world)
assert(station:onInteract() == true, "an idle station must still open its dialogue")
assert(event_world.starts == 1, "an idle station must start exactly one cutscene")

-- A missing event-world reference must not bypass the canonical world guard.
Game.world = makeWorld(true)
station = stationWithWorld(nil)
assert(station:onInteract() == false, "Game.world must still protect an event with no world reference")
assert(Game.world.starts == 0, "the missing event-world fallback must not start a nested cutscene")

print("Testing station nested-cutscene guard passed.")
