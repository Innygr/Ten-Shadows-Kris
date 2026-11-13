local RuntimeSmokeTest, super = Class(Encounter)

function RuntimeSmokeTest:init()
    super.init(self)

    self.text = "* The file opens. The battle system is awake."
    self.music = "battle"
    self.background = true

    self:addEnemy("runtime_dummy")
end

function RuntimeSmokeTest:onBattleEnd()
    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    Shadows.onBattleEnd()
end

return RuntimeSmokeTest
