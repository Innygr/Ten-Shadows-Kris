local spell, super = Class(Spell, "ts_heal")

function spell:init()
    super.init(self)
    self.name = "HEAL"
    self.effect = "HEAL 22 HP"
    self.description = "Restores 22 HP to one ally."
    self.cost = 16
    self.target = "ally"
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.heal(target, 22)
end

return spell
