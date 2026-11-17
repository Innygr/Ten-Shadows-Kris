local GasterSecretEncounter, super = Class(Encounter)

function GasterSecretEncounter:init()
    super.init(self)
    self.text = "* The room falls silent."
    self.music = "battle"
    self.background = true
    self:addEnemy("gaster_secret")
end

function GasterSecretEncounter:onBattleEnd()
    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    Shadows.onBattleEnd()
end

return GasterSecretEncounter
