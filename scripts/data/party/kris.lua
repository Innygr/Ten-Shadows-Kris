local character, super = Class(PartyMember, "kris")

function character:init()
    super.init(self)
    self.name = "Kris"
    self:setActor("kris")
    self:setArmor(1, "shadow_cloak")
    self.level = Game.chapter
    self.title = "TEN SHADOWS"
    self.soul_priority = 2
    self.has_act = true
    self.has_spells = false
    self.has_xact = true
    self.xact_name = "K-Action"
    self.health = 290
    self.stats = {health = 290, attack = 17, defense = 2, magic = 10}
    self.max_stats = {health = 290, magic = 10}
    self.color = {0, 1, 1}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.name_sprite = "party/kris/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
