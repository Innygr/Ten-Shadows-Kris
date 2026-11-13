local spell, super = Class(Spell, "ts_revivesong")

function spell:init()
    super.init(self)
    self.name = "REVIVESONG"
    self.effect = "REVIVE / HEAL"
    self.description = "Revives an ally at half HP, or heals half max HP."
    self.cost = 84
    self.target = "ally"
    self.tags = {"heal", "revive"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.revive(target)
end

return spell
