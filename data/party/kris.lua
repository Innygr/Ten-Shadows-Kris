local character, super = Class(PartyMember, "kris")

function character:init()
    super.init(self)
    self.name = "Kris"
    self:setActor("kris")
    self.level = Game.chapter
    self.title = "TEN SHADOWS"
    self.soul_priority = 2
    self.has_act = true
    self.has_spells = false
    self.has_xact = true
    self.xact_name = "K-Action"
    self.health = 48
    self.stats = {health = 48, attack = 17, defense = 2, magic = 0}
    self.max_stats = {health = 48}
    self.color = {0, 1, 1}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.name_sprite = "party/kris/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
