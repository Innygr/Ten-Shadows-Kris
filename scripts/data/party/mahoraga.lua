local character, super = Class(PartyMember, "mahoraga")

function character:init()
    super.init(self)
    self.name = "Mahoraga"
    -- A dedicated actor identity keeps future sprite work separate from Kris.
    -- The actor currently falls back to Kris's known-good runtime frames.
    self:setActor("mahoraga")
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
    -- Portrait/name paths remain on Kris until Mahoraga's dedicated icon art
    -- is ready, avoiding missing-texture warnings during the battle takeover.
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.name_sprite = "party/kris/name"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
