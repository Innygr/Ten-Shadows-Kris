local character, super = Class(PartyMember, "berdly")

function character:init()
    super.init(self)
    self.name = "Berdly"
    -- Temporary actor fallback until dedicated Berdly battle/overworld art is added.
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
    self.stats = {health = 54, attack = 18, defense = 2, magic = 8}
    self.max_stats = {health = 54}
    self.color = {0.2, 0.75, 1}
    self.menu_icon = "party/kris/head"
    self.head_icons = "party/kris/icon"
    self.attack_sprite = "effects/attack/cut"
    self.attack_sound = "laz_c"
end

return character
