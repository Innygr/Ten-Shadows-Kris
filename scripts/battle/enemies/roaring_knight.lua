local RoaringKnight, super = Class(EnemyBattler)

local function formatHP(value)
    local digits = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,")
    return grouped:reverse():gsub("^,", "")
end

function RoaringKnight:getCheckText(battler)
    local state = self.ten_shadows_state
    local multiplier = state and state.knight_fight
        and state.knight_fight.damage_taken_multiplier or 0.20
    self.check = {
        "AT 40 DF 0",
        "HP: " .. formatHP(self.health) .. " / " .. formatHP(self.max_health) .. ".",
        "Incoming damage: " .. tostring(math.floor(multiplier * 100 + 0.5)) .. "%.",
        "Its health is independent from the Titan's.",
    }
    return super.getCheckText(self, battler)
end

function RoaringKnight:init()
    super.init(self)

    self.name = "The Roaring Knight"
    self.ten_shadows_role = "knight"
    -- Keep a dedicated actor identity; its config safely falls back to Kris until Knight art exists.
    self:setActor("roaring_knight")
    self.max_health = 7300
    self.health = self.max_health
    self.attack = 40
    -- Effective durability uses the per-turn damage multiplier, not DEF.
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.spare_points = 0

    self.tired_percentage = 0
    self.can_freeze = false
    self.disable_mercy = true
    self.auto_spare = false
    self.mercy = 0

    -- Both enemies select one coordinated Wave. Kristal de-duplicates the
    -- shared Wave instance while retaining both attackers in getAttackers().
    -- This lets either survivor keep the encounter active.
    self.waves = {"knight_titan_assault"}
    self.dialogue = {"* The Roaring Knight raises its blade."}
    self.text = {
        "* The Roaring Knight has 1,460 HP.",
        "* Its health is separate from the Titan's.",
    }
    self.check = {
        "AT 40 DF 0",
        "HP: 7,300 / 7,300.",
        "Incoming damage: 20%.",
        "Its health is independent from the Titan's.",
    }

    -- Decorative outline only: no collider, shield HP, or damage interception.
    local ShieldVisual = modRequire("scripts/battle/objects/knight_shield_visual")
    local shield = ShieldVisual(self.width or 24, self.height or 40)
    shield.x = -8
    shield.y = -6
    self:addChild(shield)
    self.ten_shadows_shield_visual = shield
end

function RoaringKnight:getAttackDamage(damage, battler, points)
    local amount = super.getAttackDamage(self, damage, battler, points)
    local state = self.ten_shadows_state
    if state and state.scaleKnightFightDamage then
        return state:scaleKnightFightDamage(amount, battler)
    end
    return amount
end

local function currentSpellKey()
    local action = Game and Game.battle and Game.battle.current_processing_action
    if not action or action.action ~= "SPELL" or not action.data then return "" end
    local spell = action.data
    local key = spell.id or spell.name
    if not key and spell.getID then key = spell:getID() end
    if not key and spell.getName then key = spell:getName() end
    return tostring(key or ""):lower():gsub("[^%w]", "")
end

function RoaringKnight:hurt(amount, battler, on_defeat, color, show_status, attacked)
    local state = self.ten_shadows_state
    if type(amount) == "number" and amount > 0
        and currentSpellKey():find("rudebuster", 1, true)
        and state and state.scaleKnightRudeBusterDamage then
        -- Spell timing is already part of amount; reduce the result once.
        amount = state:scaleKnightRudeBusterDamage(amount)
    end
    return super.hurt(self, amount, battler, on_defeat, color, show_status, attacked)
end

function RoaringKnight:onHurt(damage, battler)
    super.onHurt(self, damage, battler)
    if self.ten_shadows_state and self.ten_shadows_state.syncKnightHP then
        self.ten_shadows_state:syncKnightHP(self.health)
    end
end

function RoaringKnight:onAct(battler, name)
    if name == "EXECUTION COUNTER" then
        local state = self.ten_shadows_state
        if not state then
            return "* The Knight's stagger has already faded."
        end

        local ready, damage = state:consumeExecutionCounter()
        if not ready then
            return "* The Knight is no longer open to a counter."
        end

        -- The parry staggered the Knight, so the counter must hit this
        -- battler's independent 1,460 HP pool, never the Titan's.
        self:hurt(damage, battler)
        return {
            "* Kris strikes through the Knight's opening!",
            "* The counter deals " .. tostring(damage) .. " damage.",
        }
    end

    local BossActions = modRequire("scripts/ten_shadows/boss_actions")
    return BossActions.onAct(self, battler, name, super.onAct)
end

function RoaringKnight:onDefeat(amount, battler)
    if self.ten_shadows_state and self.ten_shadows_state.setKnightAlive then
        self.ten_shadows_state:setKnightAlive(false)
    end
    return super.onDefeat(self, amount, battler)
end

return RoaringKnight
