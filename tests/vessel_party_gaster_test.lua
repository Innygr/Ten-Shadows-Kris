local mod = assert(io.open("mod.lua", "r")):read("*a")
local vessel = assert(io.open("scripts/data/party/vessel.lua", "r")):read("*a")
local boss = assert(io.open("scripts/ten_shadows/boss_actions.lua", "r")):read("*a")
local gaster = assert(io.open("scripts/data/actors/gaster_secret.lua", "r")):read("*a")

assert(vessel:find('self.has_xact = true', 1, true), "Vessel must expose an X-Action")
assert(vessel:find('self.xact_name = "V-Act"', 1, true), "Vessel X-Action label must be V-Act")
assert(mod:find('{"GRANITE BLAST", "Open Vessel', 1, true), "Granite Blast must be a separate ACT root menu")
assert(mod:find('{"ULTIMATE BEAM"', 1, true), "Ultimate Beam must be grouped under Granite Blast")
assert(not mod:find('{"V-ACT",', 1, true), "V-Act must not be an ACT submenu")
assert(boss:find('character_id == "vessel" and (name == "V-Act" or name == "Standard")', 1, true),
    "V-Act must resolve as a normal X-Action")
assert(mod:find('Game:setPartyMembers(unpack(roster))\n            local full_roster = {}', 1, true),
    "Overworld spawn must activate the canonical roster before looking up members")
assert(gaster:find('self.width = 48', 1, true) and gaster:find('self.height = 96', 1, true),
    "Gaster's dimensions must be reduced by at least half")
assert(gaster:find('sprite.scale_x = 0.5', 1, true) and gaster:find('sprite.scale_y = 0.5', 1, true),
    "Gaster's rendered sprite must be half size")
print("Vessel X-Action/menu, six-member overworld roster, and Gaster scale checks passed.")
