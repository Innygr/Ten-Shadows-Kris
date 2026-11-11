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
    self.health = 520
    self.stats = {health = 520, attack = 32, defense = 12, magic = 0}
    self.max_stats = {health = 520}
    self.color = {0.8, 0.8, 0.8}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.name_sprite = "party/kris/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
