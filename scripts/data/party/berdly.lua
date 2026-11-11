local character, super = Class(PartyMember, "berdly")

function character:init()
    super.init(self)
    self.name = "Berdly"
    -- The game does not provide a standard playable Berdly profile; this is
    -- the project's custom late-game party implementation.
    -- Temporary actor fallback until dedicated Berdly sprites are supplied.
    self:setActor("kris")
    self:setArmor(1, "aero_cape")
    self.level = Game.chapter
    self.title = "TECH SUPPORT"
    self.soul_priority = 0
    self.has_act = false
    self.has_spells = true
    self.has_xact = true
    self.xact_name = "B-Action"
    self:addSpell("ts_tornado")
    self.health = 310
    self.stats = {health = 310, attack = 20, defense = 2, magic = 8}
    self.max_stats = {health = 310}
    self.color = {0.12, 0.32, 0.78}
    self.dmg_color = {0.35, 0.55, 1}
    self.attack_bar_color = {0.18, 0.38, 0.9}
    self.attack_box_color = {0.06, 0.16, 0.42}
    self.menu_icon = "party/kris/head" -- temporary vanilla icon until Berdly UI art exists
    self.head_icons = "party/kris/icon"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
