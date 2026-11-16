local spell, super = Class(Spell, "ts_fire_shock")

function spell:init()
    super.init(self)
    self.name = "FIRE SHOCK"
    self.effect = "28 FIRE DMG"
    self.description = "Deals 28 fire damage and hits the Titan's shield hard."
    self.cost = 20
    self.target = "enemy"
    self.tags = {"fire", "damage"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.damage(user, target, 28)
end

return spell
