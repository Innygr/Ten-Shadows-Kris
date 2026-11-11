local character, super = Class(PartyMember, "noelle")

function character:init()
    super.init(self)
    self.name = "Noelle"
    self:setActor("noelle")
    self.level = Game.chapter
    self.title = "Snowcaster"
    self.soul_priority = 1
    self.has_act = false
    self.has_spells = true
    self.has_xact = true
    self.xact_name = "N-Action"
    self:addSpell("heal_prayer")
    self:addSpell("sleep_mist")
    self:addSpell("ice_shock")
    self:addSpell("ts_ice_wave")
    -- SnowGrave is only listed once the Weird Route has been enabled.
    if Game:getFlag("weird_route", false) then
        self:addSpell("ts_snowgrave")
    end
    self.health = 260
    self.stats = {health = 260, attack = 7, defense = 1, magic = 11}
    self.max_stats = {health = 260}
    self.color = {1, 1, 0}
    self.menu_icon = "party/noelle/head"
    self.head_icons = "party/noelle/icon"
    self.name_sprite = "party/noelle/name"
    self.attack_sprite = "effects/attack/slap_n"
    self.attack_sound = "laz_c"
    self.attack_pitch = 1.5
end

return character
