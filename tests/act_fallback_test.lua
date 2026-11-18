local mod = assert(io.open("mod.lua", "r")):read("*a")
local actions = assert(io.open("scripts/ten_shadows/boss_actions.lua", "r")):read("*a")

assert(mod:find('{"Nothing Happens", "Nothing happens."', 1, true),
    "Unsupported characters must receive a Nothing Happens ACT option")
assert(mod:find('battle:pushAction("ACT", enemy, item)', 1, true),
    "Fallback ACT must enter the normal action queue")
assert(actions:find('if name == "Nothing Happens" then', 1, true),
    "Nothing Happens must have a dedicated safe resolver")
assert(actions:find('return "* Nothing happens."', 1, true),
    "Fallback ACT must resolve with harmless dialogue")

print("Character ACT fallback checks passed.")
