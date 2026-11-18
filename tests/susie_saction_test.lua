local actions = assert(io.open("scripts/ten_shadows/boss_actions.lua", "r")):read("*a")

local marker = 'if battler and battler.chara and battler.chara.id == "susie"'
assert(actions:find(marker, 1, true),
    "Susie's S-Action must be handled for her party member ID")
assert(actions:find('name == "Standard" or name == "S-Action"', 1, true),
    "Susie's S-Action must accept Kristal's resolved default X-Action name")
assert(actions:find('return "* SUSIE swings her axe with all her strength!"', 1, true),
    "Susie's S-Action must return dialogue so Kristal can finish the action")

print("Susie S-Action regression checks passed.")
