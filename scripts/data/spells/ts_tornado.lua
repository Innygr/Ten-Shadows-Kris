local spell, super = Class(Spell, "ts_tornado")

function spell:init()
    super.init(self)
    self.name = "TORNADO"
    self.effect = "16 DMG + DISRUPT"
    self.description = "Deals 16 damage and disrupts the next Knight attack."
    self.cost = 20
    self.target = "enemy"
    self.tags = {"damage", "wind"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.damage(user, target, 16)
    Effects.disrupt(target)
end

return spell
