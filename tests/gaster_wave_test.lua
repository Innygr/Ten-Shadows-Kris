local enemy = assert(io.open("scripts/battle/enemies/gaster_secret.lua", "r"))
local enemy_source = enemy:read("*a")
enemy:close()
assert(enemy_source:find('self.waves = {"gaster_first_contact"}', 1, true),
    "Gaster must have a registered first attack wave")

local wave = assert(io.open("scripts/battle/waves/gaster_first_contact.lua", "r"))
local wave_source = wave:read("*a")
wave:close()
assert(wave_source:find('"gaster_bullet"', 1, true),
    "Gaster's first wave must spawn its dedicated projectile")

local bullet = assert(io.open("scripts/battle/bullets/gaster_bullet.lua", "r"))
local bullet_source = bullet:read("*a")
bullet:close()
assert(bullet_source:find("self.damage = 3", 1, true),
    "Gaster's projectile must have a defined damage value")

print("Gaster first-wave registration checks passed.")
