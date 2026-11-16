local OrangeSoul, super = Class(Soul, "OrangeSoul")

local MAX_CHARGE = 0.8

function OrangeSoul:init(x, y)
    super.init(self, x, y, {1.00, 0.48, 0.16})
    self.ten_shadows_mode = "orange"
    self.orange_facing_x = 1
    self.orange_facing_y = 0
    self.orange_was_down = false
    self.orange_charging = false
    self.orange_charge = 0
    self.orange_dash_timer = 0
    self.orange_dash_duration = 0
    self.noclip = self.noclip == true
    self.orange_dash_speed = 0
    self.orange_dashing = false
    self.orange_previous_noclip = false
end

function OrangeSoul:beginDash()
    local charge = math.min(1, self.orange_charge / MAX_CHARGE)
    self.orange_dash_duration = 0.16 + charge * 0.30
    self.orange_dash_timer = self.orange_dash_duration
    self.orange_dash_speed = 9 + charge * 8
    self.orange_dashing = true
    self.orange_previous_noclip = self.noclip == true
    self.noclip = true
    self.orange_charge = 0
    self.orange_charging = false
end

function OrangeSoul:doMovement()
    if self.orange_dashing then
        self.moving_x = self.orange_facing_x
        self.moving_y = self.orange_facing_y
        self:move(self.orange_facing_x, self.orange_facing_y,
            self.orange_dash_speed * (DTMULT or 1))
        return
    end

    local move_x, move_y = 0, 0
    if Input.down("left") then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end
    if Input.down("up") then move_y = move_y - 1 end
    if Input.down("down") then move_y = move_y + 1 end

    if move_x ~= 0 or move_y ~= 0 then
        local length = math.sqrt(move_x * move_x + move_y * move_y)
        self.orange_facing_x = move_x / length
        self.orange_facing_y = move_y / length
    end
    self.moving_x = move_x
    self.moving_y = move_y
    if move_x ~= 0 or move_y ~= 0 then
        self:move(move_x, move_y, self.speed * (Input.down("cancel") and 0.5 or 1) * (DTMULT or 1))
    end
end

function OrangeSoul:update()
    local defending = Game and Game.battle and Game.battle.state == "DEFENDING"
        and not self.transitioning
    local down = defending and Input.down("confirm") or false
    if down then
        if not self.orange_was_down then
            self.orange_charge = 0
            self.orange_charging = true
        end
        self.orange_charge = math.min(MAX_CHARGE, self.orange_charge + (DT or 1 / 30))
    elseif self.orange_was_down and self.orange_charging then
        self:beginDash()
    end
    self.orange_was_down = down

    if not defending then
        self.orange_charge = 0
        self.orange_charging = false
        self.orange_was_down = false
    end

    super.update(self)

    if self.orange_dashing then
        self.orange_dash_timer = math.max(0, self.orange_dash_timer - (DT or 1 / 30))
        if self.orange_dash_timer <= 0 then
            self.orange_dashing = false
            self.noclip = self.orange_previous_noclip == true
            self.moving_x = 0
            self.moving_y = 0
        end
    end
end

function OrangeSoul:onCollide(bullet)
    if self.orange_dashing then
        -- The forward burst phases through incoming projectiles instead of
        -- stopping on them; the dash is the mode's defensive action.
        if bullet and bullet.remove then bullet:remove() end
        self.orange_phase_count = (self.orange_phase_count or 0) + 1
        return
    end
    return super.onCollide(self, bullet)
end

function OrangeSoul:draw()
    super.draw(self)
    love.graphics.push("all")
    if self.orange_charging then
        local radius = 12 + (self.orange_charge / MAX_CHARGE) * 12
        love.graphics.setColor(1.0, 0.42, 0.12, 0.25)
        love.graphics.circle("line", 0, 0, 28)
        love.graphics.setColor(1.0, 0.78, 0.30, 0.95)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", 0, 0, radius)
    end
    if self.orange_dashing then
        local trail = 18 + self.orange_dash_speed * 2
        love.graphics.setColor(1.0, 0.35, 0.10, 0.55)
        love.graphics.setLineWidth(7)
        love.graphics.line(-self.orange_facing_x * trail,
            -self.orange_facing_y * trail, 0, 0)
    end
    love.graphics.pop()
end

return OrangeSoul
