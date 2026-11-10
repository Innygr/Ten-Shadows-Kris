local spell, super = Class(Spell, "ts_rush")

function spell:init()
    super.init(self)
    self.name = "RUSH"
    self.effect = "34 DMG"
    self.description = "Susie charges the target for 34 damage."
    self.cost = 0
    self.target = "enemy"
    self.tags = {"damage"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.damage(user, target, 34)
end

return spell
