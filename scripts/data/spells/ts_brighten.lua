local spell, super = Class(Spell, "ts_brighten")

function spell:init()
    super.init(self)
    self.name = "BRIGHTEN"
    self.effect = "PARTY DEF +1"
    self.description = "Susie and Ralsei strengthen the party's defenses."
    self.cost = 4
    self.target = "none"
    self.tags = {"support"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.brighten()
end

return spell
