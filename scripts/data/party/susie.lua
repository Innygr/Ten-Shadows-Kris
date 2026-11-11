local character, super = Class(PartyMember, "susie")

function character:init()
    super.init(self)
    self.name = "Susie"
    self:setActor("susie")
    self.level = Game.chapter
    self.title = "HEAVY HITTER"
    self.soul_priority = 2
    self.has_act = false
    self.has_spells = true
    self.has_xact = true
    self.xact_name = "S-Action"
    self:addSpell("ts_rush")
    self:addSpell("ts_brighten")
    self.health = 290
    self.stats = {health = 290, attack = 24, defense = 2, magic = 2}
    self.max_stats = {health = 290}
    self.color = {0.7, 0.1, 0.1}
    self.menu_icon = "party/susie/head"
    self.head_icons = "party/susie/icon"
    self.name_sprite = "party/susie/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
