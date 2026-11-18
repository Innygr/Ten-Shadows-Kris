local source = assert(io.open("scripts/ten_shadows/boss_actions.lua", "r")):read("*a")
local berdly = assert(io.open("scripts/ten_shadows/berdly_actions.lua", "r")):read("*a")

assert(source:find('character_id == "berdly"', 1, true),
    "Berdly X-Action must be routed by custom enemy handlers")
assert(source:find('character_id == "ralsei"', 1, true),
    "Ralsei X-Action must be routed by custom enemy handlers")
assert(source:find('character_id == "noelle"', 1, true),
    "Noelle X-Action must be routed by custom enemy handlers")
assert(source:find('name == "R-Action" or name == "Standard"', 1, true),
    "Ralsei's custom and engine action names must resolve")
assert(source:find('name == "N-Action" or name == "Standard"', 1, true),
    "Noelle's custom and engine action names must resolve")
assert(source:find('name == "B-Action" or name == "Standard"', 1, true),
    "Berdly's custom and engine action names must resolve")
assert(source:find('BerdlyActions.perform(enemy, battler)', 1, true),
    "Berdly's scan action must execute through boss handlers")
assert(berdly:find('return "* Berdly runs a tactical scan.', 1, true),
    "Berdly's action must return dialogue")

print("Ralsei, Noelle, and Berdly X-Action regression checks passed.")
