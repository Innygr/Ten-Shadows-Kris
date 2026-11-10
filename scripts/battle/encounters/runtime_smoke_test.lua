local RuntimeSmokeTest, super = Class(Encounter)

function RuntimeSmokeTest:init()
    super.init(self)

    self.text = "* The file opens. The battle system is awake."
    self.music = "battle"
    self.background = true

    self:addEnemy("runtime_dummy")
end

return RuntimeSmokeTest
