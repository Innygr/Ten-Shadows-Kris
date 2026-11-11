local character, super = Class(PartyMember, "vessel")

function character:init()
    super.init(self)
    self.name = "Vessel"
    self:setActor("vessel")
    self:setWeapon("soul_rapier")
    self:setArmor(1, "soul_anchor")
    self.level = Game.chapter
    self.title = "SOUL BEARER"
    self.soul_priority = 3
    self.soul_color = {0.95, 0.035, 0.08}
    self.has_act = true
    self.has_spells = false
    self.has_xact = false
    self.health = 240
    self.stats = {health = 240, attack = 12, defense = 2, magic = 0}
    self.max_stats = {health = 240}
    self.color = {0.72, 0.72, 0.76}
    self.dmg_color = {0.95, 0.08, 0.12}
    -- Use the SOUL heart as a distinct temporary party-menu icon until custom Vessel UI art exists.
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
