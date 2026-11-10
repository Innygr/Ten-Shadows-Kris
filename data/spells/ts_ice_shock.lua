local spell, super = Class(Spell, "ts_ice_shock")

function spell:init()
    super.init(self)
    self.name = "ICE SHOCK"
    self.effect = "18 ICE DMG"
    self.description = "Deals 18 damage and builds CHILL."
    self.cost = 16
    self.target = "enemy"
    self.tags = {"ice", "damage"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.damage(user, target, 18)
    Effects.addChill(target, 1)
end

return spell
