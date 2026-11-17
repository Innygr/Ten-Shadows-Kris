local soul_file = assert(io.open("scripts/objects/yellow_soul.lua", "r"))
local soul = soul_file:read("*a")
soul_file:close()
assert(soul:find("love.graphics.rotate(-math.pi / 2)", 1, true),
    "Yellow SOUL point must face right")
assert(soul:find("YellowShot(self.x + 18, self.y, charged)", 1, true),
    "Yellow shots must originate on the SOUL's right side")
local shot_file = assert(io.open("scripts/objects/yellow_shot.lua", "r"))
local shot = shot_file:read("*a")
shot_file:close()
assert(shot:find("self.x = self.x + self.speed * dtmult", 1, true),
    "Yellow shots must travel right")
local wave_file = assert(io.open("scripts/battle/waves/knight_titan_assault.lua", "r"))
local wave = wave_file:read("*a")
wave_file:close()
assert(wave:find("soul_toss_scene_played", 1, true),
    "the one-time Kris/Vessel SOUL toss scene must be scheduled")
print("Yellow SOUL orientation and throw scene tests passed.")
