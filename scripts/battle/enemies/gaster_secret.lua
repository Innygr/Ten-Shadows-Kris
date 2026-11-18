local GasterSecret, super = Class(EnemyBattler)

function GasterSecret:init()
    super.init(self)
    self.name = "W.D. Gaster"
    self:setActor("gaster_secret")
    self.max_health = 6666 -- PLACEHOLDER: replace after balance design.
    self.health = self.max_health
    self.attack = 30 -- PLACEHOLDER: replace after balance design.
    self.defense = 0
    self.money, self.experience, self.spare_points = 0, 0, 0
    self.tired_percentage = 0
    self.can_freeze = false
    self.disable_mercy = true
    self.auto_spare = false
    self.mercy = 0
    self.waves = {"gaster_first_contact"}
    self:registerAct("KRIS'S IDEA", "Kris and Vessel summon their own Titan.")
    self.dialogue = {
        "* ...",
        "* [A voice echoes from somewhere far away.]",
        "* YOU HAVE BEEN LOOKING FOR ME.",
    }
    self.text = {
        "* The man behind the tree.",
        "* Something about this encounter feels out of place.",
    }
    self.check = {
        "AT 30 DF 0",
        "HP: 6,666 / 6,666.",
        "* SECRET BOSS SCAFFOLD — stats are provisional.",
        "* Its first attack is only a prototype.",
    }
end

function GasterSecret:onAct(battler, name)
    local BossActions = modRequire("scripts/ten_shadows/boss_actions")
    return BossActions.onAct(self, battler, name, super.onAct)
end

function GasterSecret:getCheckText(battler)
    self.check = {
        "AT " .. tostring(self.attack) .. " DF " .. tostring(self.defense),
        "HP: " .. tostring(self.health) .. " / " .. tostring(self.max_health) .. ".",
        "* SECRET BOSS SCAFFOLD — stats are provisional.",
        "* Its first attack is only a prototype.",
    }
    return super.getCheckText(self, battler)
end

return GasterSecret
