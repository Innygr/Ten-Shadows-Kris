local character, super = Class(PartyMember, "ralsei")

function character:init()
    super.init(self)
    self.name = "Ralsei"
    self:setActor("ralsei")
    self.level = Game.chapter
    self.title = "SUPPORT"
    self.soul_priority = -1
    self.has_act = false
    self.has_spells = true
    self.has_xact = true
    self.xact_name = "R-Action"
    self:addSpell("pacify")
    self:addSpell("heal_prayer")
    self:addSpell("revivesong")
    self:addSpell("ts_revivesong")
    self.health = 250
    self.stats = {health = 250, attack = 10, defense = 2, magic = 14}
    self.max_stats = {health = 250}
    self.color = {0, 1, 0}
    self.menu_icon = "party/ralsei/head"
    self.head_icons = "party/ralsei/icon"
    self.name_sprite = "party/ralsei/name"
    self.attack_sprite = "effects/attack/slap_r"
    self.attack_sound = "laz_c"
    self.attack_pitch = 1.15
end

return character
