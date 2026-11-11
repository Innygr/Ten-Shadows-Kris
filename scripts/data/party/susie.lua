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
    self:addSpell("rude_buster")
    self:addSpell("ultimate_heal")
    self:addSpell("scythemare")
    self:addSpell("ts_rush")
    self.health = 350
    self.stats = {health = 350, attack = 24, defense = 2, magic = 2}
    self.max_stats = {health = 350}
    self.color = {1, 0, 1}
    self.dmg_color = {0.8, 0.6, 0.8}
    self.attack_bar_color = {234/255, 121/255, 200/255}
    self.attack_box_color = {0.5, 0, 0.5}
    self.xact_color = {1, 0.5, 1}
    self.menu_icon = "party/susie/head"
    self.head_icons = "party/susie/icon"
    self.name_sprite = "party/susie/name"
    self.attack_sprite = "effects/attack/mash"
    self.attack_sound = "laz_c"
    self.attack_pitch = 0.9
end

return character
