local RoaringKnight, super = Class(EnemyBattler)

function RoaringKnight:init()
    super.init(self)

    self.name = "The Roaring Knight"
    -- Temporary Kris actor placeholder until dedicated Knight art is added.
    self:setActor("kris")
    self.max_health = 1460
    self.health = self.max_health
    self.attack = 40
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.spare_points = 0

    self.tired_percentage = 0
    self.can_freeze = false
    self.disable_mercy = true
    self.auto_spare = false
    self.mercy = 0

    self.waves = {}
    self.dialogue = {"* The Roaring Knight raises its blade."}
    self.text = {
        "* The Roaring Knight has 1,460 HP.",
        "* Its health is separate from the Titan's.",
    }
    self.check = "AT 40 DF 0\n* HP: 1,460.\n* The Knight has its own health pool."
end

return RoaringKnight
