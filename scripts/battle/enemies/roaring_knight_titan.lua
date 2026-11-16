local RoaringKnightTitan, super = Class(EnemyBattler)

function RoaringKnightTitan:init()
    super.init(self)

    self.name = "The Titan"
    self.ten_shadows_role = "titan"
    -- Temporary Kris actor placeholder until dedicated Knight/Titan art is added.
    self:setActor("kris")
    self.max_health = 21000
    self.health = self.max_health
    self.attack = 40
    self.defense = 800
    self.money = 0
    self.experience = 0
    self.spare_points = 0

    -- The Titan owns the phase-bearing HP pool; the Knight has a separate battler.
    self.tired_percentage = 0
    self.can_freeze = false
    self.disable_mercy = true
    self.auto_spare = false
    self.mercy = 0

    self.ten_shadows_phase = 1
    self.waves = {"knight_titan_assault"}

    local CombatState = modRequire("scripts/ten_shadows/combat_state")
    self.ten_shadows_state = CombatState.new()
    self.ten_shadows_state.boss.hp = self.health
    self.ten_shadows_state.boss.max_hp = self.max_health
    self.dialogue = {
        "* The Titan watches from behind its armour.",
        "* The Roaring Knight advances beside it.",
    }
    self.text = {
        "* The Titan has 21,000 HP.",
        "* The Roaring Knight fights independently.",
    }

    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    self.check = BossPhase.checkText(self.ten_shadows_phase, self.health, self.max_health)

    self:registerAct("Inspect", "Read the Titan status")
end

-- Pull flavor from the data-driven registry rather than leaving the
-- registry disconnected from the actual battle loop. Selection occurs each
-- turn, so Vessel name/pronouns and the current boss phase stay up to date.
function RoaringKnightTitan:getEncounterText()
    local phase = self.ten_shadows_phase or 1

    -- onHurt installs a one-turn battle-box announcement alongside the enemy
    -- speech-bubble override. Preserve the encounter-text half until it is read.
    if self._phase_encounter_text then
        local text = self._phase_encounter_text
        self._phase_encounter_text = nil
        self._previous_flavor_text = text
        return text
    end

    local id = "roaring_knight.battle"
    local fallback = super.getEncounterText(self)
    local text = Mod and Mod.flavor_text and Mod.flavor_text.get(id, {
        phase = phase,
        hp = self.health,
        max_hp = self.max_health,
    }, {
        previous = self._previous_flavor_text,
        fallback = fallback,
    }) or fallback
    self._previous_flavor_text = text
    return text
end

function RoaringKnightTitan:getEnemyDialogue()
    -- Phase changes install a one-shot engine override. Preserve its priority
    -- instead of consuming it and replacing it with an ordinary flavor line.
    if self.dialogue_override then
        return super.getEnemyDialogue(self)
    end

    local fallback = super.getEnemyDialogue(self)
    local text = Mod and Mod.flavor_text and Mod.flavor_text.get("roaring_knight.opening", {
        phase = self.ten_shadows_phase or 1,
    }, {
        previous = self._previous_enemy_dialogue,
        fallback = fallback,
    }) or fallback
    self._previous_enemy_dialogue = text
    return text
end

function RoaringKnightTitan:onDefeat(amount, battler)
    if self.ten_shadows_state and self.ten_shadows_state.setTitanAlive then
        self.ten_shadows_state:setTitanAlive(false)
    end
    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    self.check = BossPhase.checkText(3, 0, self.max_health)
    return super.onDefeat(self, amount, battler)
end

function RoaringKnightTitan:onHurt(damage, battler)
    super.onHurt(self, damage, battler)

    if self.ten_shadows_state then
        self.ten_shadows_state.boss.hp = self.health
    end

    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    local next_phase, phase_text = BossPhase.advance(self.health, self.ten_shadows_phase)
    if next_phase ~= self.ten_shadows_phase then
        self.ten_shadows_phase = next_phase
        if self.ten_shadows_state then
            self.ten_shadows_state.boss.phase = next_phase
            self.ten_shadows_state.boss.hp = self.health
        end
        self.dialogue_override = phase_text
        self._phase_encounter_text = phase_text
        self.text = {phase_text}
    end

    -- CHECK must report current HP after every hit, not just at phase changes.
    self.check = BossPhase.checkText(self.ten_shadows_phase, self.health, self.max_health)
end

function RoaringKnightTitan:getCheckText()
    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    self.check = BossPhase.checkText(self.ten_shadows_phase, self.health, self.max_health)
    return self.check
end

function RoaringKnightTitan:onAct(battler, name)
    local BossActions = modRequire("scripts/ten_shadows/boss_actions")
    return BossActions.onAct(self, battler, name, super.onAct)
end

return RoaringKnightTitan
