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
    self.waves = {"runtime_smoke"}
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

function RoaringKnightTitan:onHurt(damage, battler)
    super.onHurt(self, damage, battler)

    local BossPhase = modRequire("scripts/ten_shadows/boss_phase")
    local next_phase, phase_text = BossPhase.advance(self.health, self.ten_shadows_phase)
    if next_phase ~= self.ten_shadows_phase then
        self.ten_shadows_phase = next_phase
        self.check = BossPhase.checkText(next_phase)
        self.dialogue_override = phase_text
        self.text = {phase_text}
    end
end

function RoaringKnightTitan:onAct(battler, name)
    if name == "Inspect" or name == "Check" then
        return self.check
    end
    return super.onAct(self, battler, name)
end

return RoaringKnightTitan
