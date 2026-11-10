local spell, super = Class(Spell, "ts_ice_wave")

function spell:init()
    super.init(self)
    self.name = "ICE WAVE"
    self.effect = "30 ICE DMG"
    self.description = "Deals 30 damage and builds 2 CHILL."
    self.cost = 28
    self.target = "enemy"
    self.tags = {"ice", "damage"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.damage(user, target, 30)
    Effects.addChill(target, 2)
end

return spell
