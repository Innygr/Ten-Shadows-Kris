local RuntimeDummy, super = Class(EnemyBattler)

function RuntimeDummy:init()
    super.init(self)

    self.name = "Runtime Check"
    -- Reuse a built-in Kristal actor so the smoke test needs no custom sprite assets.
    self:setActor("kris")

    self.max_health = 260
    self.health = 260
    self.attack = 1
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.spare_points = 0
    self.tired_percentage = 0

    self.waves = {"runtime_smoke"}

    self.dialogue = {
        "The runtime is responding.",
    }
    self.check = "AT 1 DF 0\n* A temporary engine smoke test.\n* Not the Knight + Titan encounter."
    self.text = {
        "* The battle runtime initialized.",
        "* This placeholder will be replaced by the real encounter.",
    }
end

function RuntimeDummy:onAct(battler, name)
    if name == "Check" then
        return super.onAct(self, battler, name)
    end
    return "* The runtime test has no custom ACTs yet."
end

return RuntimeDummy
