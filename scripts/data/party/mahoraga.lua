local character, super = Class(PartyMember, "mahoraga")

function character:init()
    super.init(self)
    self.name = "Mahoraga"
    -- Temporary actor fallback until dedicated Mahoraga battle sprites are authored.
    self:setActor("kris")
    self.level = Game.chapter
    self.title = "ADAPTIVE SHIKIGAMI"
    self.has_act = false
    self.has_spells = false
    self.health = 999
    self.stats = {health = 999, attack = 32, defense = 12, magic = 0}
    self.max_stats = {health = 999}
    -- White is used by the party UI for Mahoraga's name and HP presentation.
    self.color = {1, 1, 1}
    self.dmg_color = {1, 1, 1}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.name_sprite = "party/kris/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
