local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local function member(id, hp)
    local chara = {id = id, health = hp}
    function chara:getHealth() return self.health end
    return {chara = chara, is_down = false}
end
local kris, vessel = member("kris", 290), member("vessel", 240)
local spawned = 0
local arena = {width=142,height=142,mask={addChild=function(self, child)
    spawned = spawned + 1
    self.child = child
end}}
Game = {battle={party={kris,vessel},arena=arena}}
modRequire = function(path)
    assert(path == "scripts/battle/objects/summoned_titan_visual")
    return function(w,h) return {width=w,height=h,kind="titan_visual"} end
end
local target = {name="W.D. Gaster",health=3000,max_health=6666}
function target:hurt(amount) self.health = self.health - amount end
local message = BossActions.onAct(target,vessel,"KRIS'S IDEA",function() return "base" end)
assert(target.health == 1900, "Kris's Idea must deal 1,100 damage")
assert(target.ten_shadows_own_titan_summoned, "summon must be marked used")
assert(spawned == 1 and arena.mask.child.kind == "titan_visual", "Titan visual must spawn")
assert(message[1] == "* KRIS HAS AN IDEA.", "combined action dialogue must play")
local again = BossActions.onAct(target,vessel,"KRIS'S IDEA",function() return "base" end)
assert(again == "* Their Titan has already answered the call.", "summon must be one-use")
local early = {name="W.D. Gaster",health=5000,max_health=6666}
assert(BossActions.onAct(early,vessel,"KRIS'S IDEA",function() return "base" end)
    == "* Kris is still working on the idea...", "summon must wait until half health")
kris.chara.health = 0
local down = {name="W.D. Gaster",health=3000,max_health=6666}
assert(BossActions.onAct(down,vessel,"KRIS'S IDEA",function() return "base" end)
    == "* Kris needs to be standing for this idea.", "Kris must be standing")
print("Kris's Idea combined Titan summon tests passed.")
