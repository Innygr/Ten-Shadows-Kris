local saved = {
    name = "Rowan",
    gender = "nonbinary",
    pronouns = "they/them",
    presentation = "androgynous",
}
Kristal = {
    loadData = function() return saved end,
    saveData = function(_, data) saved = data end,
}
local Identity = dofile("scripts/ten_shadows/vessel_identity.lua")
Identity.load()
Mod = {
    vessel_identity = Identity,
    flavor_text = dofile("scripts/ten_shadows/flavor_text.lua"),
}

local BossPhase = dofile("scripts/ten_shadows/boss_phase.lua")
local CombatState = {
    new = function()
        return {boss = {hp = 260, max_hp = 260}}
    end,
}
function modRequire(path)
    if path == "scripts/ten_shadows/combat_state" then return CombatState end
    if path == "scripts/ten_shadows/boss_phase" then return BossPhase end
    error("Unexpected module: " .. tostring(path))
end

EnemyBattler = {
    init = function() end,
    setActor = function() end,
    registerAct = function() end,
    getEncounterText = function() return "base encounter fallback" end,
    getEnemyDialogue = function(self)
        if self.dialogue_override then
            local dialogue = self.dialogue_override
            self.dialogue_override = nil
            return dialogue
        end
        return "base dialogue fallback"
    end,
    onHurt = function(self, damage)
        self.health = self.health - damage
    end,
}
function Class(base)
    local class = {}
    setmetatable(class, {__index = base})
    return class, base
end

local Boss = dofile("scripts/battle/enemies/roaring_knight_titan.lua")
local enemy = setmetatable({}, {__index = Boss})
enemy:init()

local early = enemy:getEncounterText()
assert(early == "* The red SOUL flickers beside Rowan.",
    "Phase-one encounter text must use the saved Vessel name")

local dialogue = enemy:getEnemyDialogue()
assert(dialogue == "* The Knight raises its blade at Rowan."
    or dialogue == "* The Titan studies them from behind the armour.",
    "Enemy dialogue must use the saved Vessel name or object pronoun")

enemy.ten_shadows_phase = 2
local second_phase = enemy:getEncounterText()
assert(second_phase == "* The Titan studies them from behind the armour.",
    "Phase-two flavor must use the saved object pronoun")

enemy.ten_shadows_phase = 3
local final_phase = enemy:getEncounterText()
assert(final_phase == "* The Knight waits to see whether they will yield.",
    "Final-phase flavor must use the saved subject pronoun")

Identity.update({name = "Avery", pronouns = "xe/xem"})
enemy.ten_shadows_phase = 2
local updated = enemy:getEncounterText()
assert(updated == "* The Titan studies xem from behind the armour.",
    "The active battle must read updated identity values rather than cached text")

-- Crossing the phase-two threshold installs a one-shot engine dialogue override.
-- The identity-aware dialogue selector must not consume and replace this line.
enemy.ten_shadows_phase = 1
enemy.health = 200
enemy:onHurt(30)
assert(enemy.ten_shadows_phase == 2, "Damage across the threshold must advance to phase two")
local phase_dialogue = enemy:getEnemyDialogue()
assert(phase_dialogue == BossPhase.TEXT[2],
    "Phase transition dialogue must take priority over normal flavor dialogue")
assert(enemy.dialogue_override == nil,
    "The phase transition override must be consumed exactly once")

print("Roaring Knight dialogue, phase overrides, and per-phase flavor use the saved, live Vessel identity")
