local RuntimeDummy, super = Class(EnemyBattler)

local ACT_TEXT = {
    Inspect = "* ACT registration works.\\n* ACT dispatch works.",
    Signal = "* Kris's character-specific ACT works.",
    Standard = "* The standard X-ACT handler works.",
    ["CHIMERA SHADOW GARDEN"] = "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.\\n* The battlefield sinks into a sea of shadows.",
    TOAD = "* TOAD binds the target and disrupts its next attack.",
    NUE = "* NUE dives from above. (+5 TP)",
    ["DIVINE DOG"] = "* DIVINE DOG tears into the target and exposes its guard.",
    ["GREAT SERPENT"] = "* GREAT SERPENT constricts the target, disrupting its next attack.",
    ["MAX ELEPHANT"] = "* MAX ELEPHANT crashes down with overwhelming force.",
    ["RABBIT ESCAPE"] = "* RABBIT ESCAPE fills the field.\\n* The party recovers and gains TP.",
    ["ROUND DEER"] = "* ROUND DEER restores the party's strength.",
    ["PIERCING OX"] = "* PIERCING OX charges through, leaving the target exposed.",
    ["TIGER FUNERAL"] = "* TIGER FUNERAL unleashes a fierce, chilling strike.",
    MAHORAGA = "* MAHORAGA appears.\\n* The adaptation wheel turns."
}

function RuntimeDummy:init()
    super.init(self)

    self.name = "Runtime Check"
    self:setActor("kris")
    self.max_health = 260
    self.health = 260
    self.attack = 1
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.spare_points = 0
    self.tired_percentage = 0

    self.waves = {"runtime_smoke"}
    self.dialogue = {"The runtime is responding."}
    self.check = "AT 1 DF 0\\n* A temporary engine smoke test.\\n* Not the Knight + Titan encounter."
    self.text = {
        "* The battle runtime initialized.",
        "* A test attack is incoming.",
    }

    self:registerAct("Inspect", "Read the runtime status")
    self:registerActFor("kris", "Signal", "Test a character-specific ACT")
    -- Brighten spends only the active trio's turns; reserve recruits and Vessel are excluded.
    self:registerActFor("kris", "BRIGHTEN", "Kris strengthens the party", {"kris", "susie", "ralsei"}, 4)

    -- Kris: Ten Shadows roster and domain.
    local shadows = {
        {"TOAD", "Binding and disruption", 0},
        {"NUE", "Strike and gain TP", 20},
        {"DIVINE DOG", "Damage and expose", 25},
        {"GREAT SERPENT", "Damage and disruption", 30},
        {"MAX ELEPHANT", "Heavy damage", 35},
        {"RABBIT ESCAPE", "Party support", 18},
        {"ROUND DEER", "Party healing", 32},
        {"PIERCING OX", "Heavy charge and expose", 40},
        {"TIGER FUNERAL", "Damage and chill", 55},
        {"MAHORAGA", "Adaptation", 100},
    }
    for _, act in ipairs(shadows) do
        self:registerActFor("kris", act[1], act[2], nil, act[3])
    end
    self:registerActFor("kris", "CHIMERA SHADOW GARDEN", "Expand the domain", nil, 60)

    -- Kris is the only current party member with an ACT menu.
    -- Spell-capable members use SPELL instead; they do not receive ACT entries.
    -- The Vessel/SOUL will receive its own ACT access when its party member is added.
end

function RuntimeDummy:onAct(battler, name)
    if name == "BRIGHTEN" then
        -- The ACT registration consumes Kris, Susie, and Ralsei's turns.
        Game.battle:powerAct("ts_brighten", battler, "kris")
        return
    end

    local message = ACT_TEXT[name]
    if message then
        return message
    end

    -- Keep Kristal's built-in CHECK implementation.
    return super.onAct(self, battler, name)
end

return RuntimeDummy
