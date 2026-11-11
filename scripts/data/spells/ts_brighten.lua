local spell, super = Class(Spell, "ts_brighten")

function spell:init()
    super.init(self)
    self.name = "BRIGHTEN"
    self.effect = "PARTY DEF +1"
    self.description = "Kris calls on the party to strengthen their defenses."
    self.cost = 4
    self.target = "none"
    self.tags = {"support", "team"}
end

function spell:onCast(user, target)
    local Effects = modRequire("scripts/ten_shadows/runtime_spells")
    Effects.brighten()
end

return spell
