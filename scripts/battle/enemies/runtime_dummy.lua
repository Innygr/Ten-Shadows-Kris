local RuntimeDummy, super = Class(EnemyBattler)

function RuntimeDummy:init()
    super.init(self)

    self.name = "Runtime Check"
    -- Reuse a built-in Kristal actor so the smoke test needs no custom actor assets.
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
    self.dialogue = {"The runtime is responding."}
    self.check = "AT 1 DF 0\n* A temporary engine smoke test.\n* Not the Knight + Titan encounter."
    self.text = {
        "* The battle runtime initialized.",
        "* A test attack is incoming.",
    }

    -- Exercise ACT registration and dispatch independently of the real boss ACTs.
    self:registerAct("Inspect", "Read the runtime status")
    self:registerActFor("kris", "Signal", "Test a character-specific ACT")
end

function RuntimeDummy:onAct(battler, name)
    if name == "Inspect" then
        return "* ACT registration works.\n* ACT dispatch works."
    elseif name == "Signal" then
        return "* Kris's character-specific ACT works."
    elseif name == "Standard" then
        return "* The standard X-ACT handler works."
    end

    -- Keep Kristal's built-in CHECK implementation.
    return super.onAct(self, battler, name)
end

return RuntimeDummy
