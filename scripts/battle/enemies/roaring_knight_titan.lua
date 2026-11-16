local RoaringKnightTitan, super = Class(EnemyBattler)

local SHIELD_DAMAGE_MULTIPLIERS = {default = 0.35, rude_buster = 3.5, ice_shock = 5.0, fire_shock = 4.0}

local function currentSpellKey()
    local action = Game and Game.battle and Game.battle.current_processing_action
    if not action or action.action ~= "SPELL" or not action.data then return "" end
    local spell = action.data
    local key = spell.id or spell.name
    if not key and spell.getID then key = spell:getID() end
    if not key and spell.getName then key = spell:getName() end
    return tostring(key or ""):lower():gsub("[^%w]", "")
end

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
-- The previous 800 DEF formula subtracted 2,400 from each normal hit.
-- Shield HP now owns the defensive phase while attack timing still matters.
function RoaringKnightTitan:getAttackDamage(damage, battler, points)
    if damage and damage > 0 then return damage end
    local attack = battler and battler.chara and battler.chara.getStat
        and battler.chara:getStat("attack") or 0
    return math.max(0, math.floor((attack * (points or 0)) / 20 + 0.5))
end

function RoaringKnightTitan:hurt(amount, battler, on_defeat, color, show_status, attacked)
    local state = self.ten_shadows_state
    local shield_hp = state and state.titan and state.titan.shield_hp or 0
    if type(amount) == "number" and amount > 0 and shield_hp > 0 then
        local spell_key = currentSpellKey()
        local multiplier = SHIELD_DAMAGE_MULTIPLIERS.default
        if spell_key == "rudebuster" then
            multiplier = SHIELD_DAMAGE_MULTIPLIERS.rude_buster
        elseif spell_key == "iceshock" or spell_key == "tsiceshock" then
            multiplier = SHIELD_DAMAGE_MULTIPLIERS.ice_shock
        elseif spell_key == "fireshock" or spell_key == "tsfireshock" then
            multiplier = SHIELD_DAMAGE_MULTIPLIERS.fire_shock
        end
        local shield_damage, broken = state:damageTitanShield(amount, multiplier)
        self.hurt_timer = 1
        self:onHurt(shield_damage, battler)
        if show_status ~= false then
            local damage_color = color
            if not damage_color and battler and battler.chara and battler.chara.getDamageColor then
                damage_color = {battler.chara:getDamageColor()}
            end
            self:statusMessage("damage", shield_damage, damage_color)
        end
        if broken then self._shield_break_encounter_text = "* The Titan's shield shatters!" end
        self.ten_shadows_shield_hp = state.titan.shield_hp
        return
    end
    return super.hurt(self, amount, battler, on_defeat, color, show_status, attacked)
end

function RoaringKnightTitan:getEncounterText()
    local phase = self.ten_shadows_phase or 1
    if self._shield_break_encounter_text then
        local text = self._shield_break_encounter_text
        self._shield_break_encounter_text = nil
        return text
    end

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
    local shield = self.ten_shadows_state and self.ten_shadows_state.titan
    local current = shield and shield.shield_hp or 0
    local maximum = shield and shield.shield_max_hp or 0
    if current > 0 then
        self.check[#self.check + 1] = "* Shield: " .. tostring(current) .. " / " .. tostring(maximum) .. "."
    else
        self.check[#self.check + 1] = "* The Titan's shield is broken."
    end
    return self.check
end

function RoaringKnightTitan:onAct(battler, name)
    local BossActions = modRequire("scripts/ten_shadows/boss_actions")
    return BossActions.onAct(self, battler, name, super.onAct)
end

return RoaringKnightTitan
