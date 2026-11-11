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
    self:addSpell("ts_heal")
    self:addSpell("ts_revivesong")
    self.health = 210
    self.stats = {health = 210, attack = 10, defense = 2, magic = 9}
    self.max_stats = {health = 210}
    self.color = {0, 1, 0}
    self.menu_icon = "party/ralsei/head"
    self.head_icons = "party/ralsei/icon"
    self.name_sprite = "party/ralsei/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
