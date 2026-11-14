local RoaringKnightTitan, super = Class(EnemyBattler)

function RoaringKnightTitan:init()
    super.init(self)

    self.name = "Roaring Knight + Titan"
    -- Temporary Kris actor placeholder until dedicated Knight/Titan art is added.
    self:setActor("kris")
    self.max_health = 260
    self.health = 260
    self.attack = 1
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.spare_points = 0

    -- This encounter is one continuous boss with no TIRED or MERCY route.
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
        "* The Knight raises its blade.",
        "* The Titan watches from behind the armour.",
    }
    self.text = {
        "* The Roaring Knight and Titan share one health pool.",
        "* Neither can be made TIRED or spared.",
    }

    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    self.check = BossPhase.checkText(self.ten_shadows_phase)

    self:registerAct("Inspect", "Read the shared boss status")
end

-- Pull flavor from the data-driven registry rather than leaving the
-- registry disconnected from the actual battle loop. Selection occurs each
-- turn, so Vessel name/pronouns and the current boss phase stay up to date.
function RoaringKnightTitan:getEncounterText()
    local phase = self.ten_shadows_phase or 1
    local id
    if phase == 1 and not self._shown_initial_flavor then
        id = "roaring_knight.early"
        self._shown_initial_flavor = true
    else
        id = "roaring_knight.battle"
    end
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

function RoaringKnightTitan:onHurt(damage, battler)
    super.onHurt(self, damage, battler)

    if self.ten_shadows_state then
        self.ten_shadows_state.boss.hp = self.health
    end

    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    local next_phase, phase_text = BossPhase.advance(self.health, self.ten_shadows_phase)
    if next_phase ~= self.ten_shadows_phase then
        self.ten_shadows_phase = next_phase
        self.check = BossPhase.checkText(next_phase)
        if self.ten_shadows_state then
            self.ten_shadows_state.boss.phase = next_phase
            self.ten_shadows_state.boss.hp = self.health
        end
        self.dialogue_override = phase_text
        self.text = {phase_text}
    end
end

local SOUL_MODE_ACTIONS = {
    ["RED SOUL"] = "red", -- setSoulMode("red") intentionally restores the default attack pool.
    ["BLUE SOUL"] = "blue",
    ["GREEN SOUL"] = "green",
    ["YELLOW SOUL"] = "yellow",
    ["PURPLE SOUL"] = "purple",
    ["ORANGE SOUL"] = "orange",
    ["CYAN SOUL"] = "cyan",
}

function RoaringKnightTitan:onAct(battler, name)
    if name == "Inspect" or name == "Check" or name == "CHECK" then
        return self.check
    end

    local state = self.ten_shadows_state
    if name == "EXECUTION COUNTER" then
        if not state then
            return "* The Knight's stagger has already faded."
        end
        local ready, damage = state:consumeExecutionCounter()
        if not ready then
            return "* The Knight is no longer open to a counter."
        end
        self:hurt(damage, battler)
        return {
            "* Kris strikes through the opening left by the parry!",
            "* The counter deals " .. tostring(damage) .. " damage.",
        }
    end

    if name == "BRIGHTEN" then
        local Effects = modRequire("scripts/ten_shadows/runtime_spells")
        -- The menu has already charged 4 TP and grouped Kris, Susie, and Ralsei
        -- into this ACT. Resolve the buff here; powerAct would queue a second
        -- SPELL action while the current ACT group is still being processed.
        return Effects.brightenAct(state)
    end

    if name == "CHIMERA SHADOW GARDEN" then
        if not state or not state:expandChimeraDomain(true) then
            return "* The shadows cannot form the domain again."
        end
        return {
            "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.",
            "* The battlefield sinks into a sea of shadows. Ten Shadows are empowered.",
        }
    end

    local soul_mode = SOUL_MODE_ACTIONS[name]
    if soul_mode then
        if not state then
            return "* The Vessel's SOUL cannot reach the shared battle state."
        end
        local changed, reason = state:setSoulMode(soul_mode)
        if not changed then return "* " .. tostring(reason) end
        return "* The Vessel shifts to " .. string.upper(soul_mode) .. " SOUL. The Knight and Titan adapt."
    end

    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    local shadow_message = Shadows.use(name, battler, self)
    if shadow_message then return shadow_message end

    return super.onAct(self, battler, name)
end

return RoaringKnightTitan
