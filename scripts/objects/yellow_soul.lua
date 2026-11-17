local YellowSoul, super = Class(Soul, "YellowSoul")

local CHARGE_SECONDS = 0.65

function YellowSoul:init(x, y)
    super.init(self, x, y, {1.00, 0.88, 0.18})
    self.ten_shadows_mode = "yellow"
    self.yellow_charge = 0
    self.yellow_was_down = false
    self.yellow_charging = false
    self.yellow_fired = false
    self.yellow_fire_count = 0
end

function YellowSoul:fire(charged)
    local YellowShot = modRequire("scripts/objects/yellow_shot")
    local shot = YellowShot(self.x + 10, self.y, charged)
    local parent = Game.battle and Game.battle.addChild and Game.battle
        or (Game.stage and Game.stage.addChild and Game.stage)
    if parent then parent:addChild(shot) end
    self.yellow_fire_count = self.yellow_fire_count + 1
    self.yellow_last_charged = charged == true
    self.yellow_charge = 0
    self.yellow_charging = false
    self.yellow_fired = true
end

function YellowSoul:update()
    local defending = Game and Game.battle and Game.battle.state == "DEFENDING"
        and not self.transitioning
    local down = defending and Input.down("confirm") or false

    if down then
        if not self.yellow_was_down then
            self.yellow_charge = 0
            self.yellow_charging = true
            self.yellow_fired = false
        end
        self.yellow_charge = math.min(1, self.yellow_charge + (DT or 1 / 30) / CHARGE_SECONDS)
    elseif self.yellow_was_down and self.yellow_charging then
        self:fire(self.yellow_charge >= 1)
    end

    self.yellow_was_down = down
    if not defending then
        self.yellow_charge = 0
        self.yellow_charging = false
        self.yellow_was_down = false
    end

    super.update(self)
end

function YellowSoul:draw()
    super.draw(self)
    love.graphics.push("all")
    if self.yellow_charging then
        local radius = 12 + self.yellow_charge * 12
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1.0, 0.86, 0.20, 0.3)
        love.graphics.circle("line", 0, 0, 27)
        love.graphics.setColor(1.0, 0.94, 0.45, 0.95)
        love.graphics.circle("line", 0, 0, radius)
    end
    love.graphics.pop()
end

return YellowSoul
