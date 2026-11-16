local RoaringKnight, super = Class(EnemyBattler)

local function formatHP(value)
    local digits = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,")
    return grouped:reverse():gsub("^,", "")
end

function RoaringKnight:getCheckText(battler)
    self.check = {
        "AT 1 DF 0",
        "HP: " .. formatHP(self.health) .. " / " .. formatHP(self.max_health) .. ".",
        "Its health is independent from the Titan's.",
    }
    return super.getCheckText(self, battler)
end

function RoaringKnight:init()
    super.init(self)

    self.name = "The Roaring Knight"
    self.ten_shadows_role = "knight"
    -- Temporary Kris actor placeholder until dedicated Knight art is added.
    self:setActor("kris")
    self.max_health = 1460
    self.health = self.max_health
    self.attack = 1
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
        "HP: 1,460.",
        "Its health is independent from the Titan's.",
    }
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

    return super.onAct(self, battler, name)
end

function RoaringKnight:onDefeat(amount, battler)
    if self.ten_shadows_state and self.ten_shadows_state.setKnightAlive then
        self.ten_shadows_state:setKnightAlive(false)
    end
    return super.onDefeat(self, amount, battler)
end

return RoaringKnight
