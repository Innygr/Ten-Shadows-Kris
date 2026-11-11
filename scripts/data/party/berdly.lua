local character, super = Class(PartyMember, "berdly")

function character:init()
    super.init(self)
    self.name = "Berdly"
    -- Berdly has no canonical playable-party stat block in Deltarune.
    -- This is a mod-balanced profile: strong physical output, moderate HP,
    -- and enough magic for his technical/support spell.
    self:setActor("kris")
    self.level = Game.chapter
    self.title = "TECH SUPPORT"
    self.soul_priority = 0
    self.has_act = true
    self.has_spells = true
    self.has_xact = true
    self.xact_name = "B-Action"
    self:addSpell("ts_tornado")
    self.health = 54
    self.stats = {health = 54, attack = 16, defense = 2, magic = 6}
    self.max_stats = {health = 54}
    self.color = {0.2, 0.75, 1}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
