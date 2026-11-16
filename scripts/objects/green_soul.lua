local GreenSoul, super = Class(Soul, "GreenSoul")

local DIRECTIONS = {
    up = {x = 0, y = -1, angle = -math.pi / 2},
    right = {x = 1, y = 0, angle = 0},
    down = {x = 0, y = 1, angle = math.pi / 2},
    left = {x = -1, y = 0, angle = math.pi},
}

function GreenSoul:init(x, y)
    super.init(self, x, y, {0.24, 1.00, 0.42})
    self.ten_shadows_mode = "green"
    self.green_direction = "right"
    self.green_blocked = 0
    self.can_move = false
end

function GreenSoul:doMovement()
    for _, direction in ipairs({"up", "right", "down", "left"}) do
        if Input.pressed and Input.pressed(direction) then
            self.green_direction = direction
            break
        end
    end
    self.moving_x = 0
    self.moving_y = 0
end

function GreenSoul:onCollide(bullet)
    local facing = DIRECTIONS[self.green_direction] or DIRECTIONS.right
    local dx = (bullet.x or self.x) - self.x
    local dy = (bullet.y or self.y) - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 0 and ((dx * facing.x + dy * facing.y) / distance) >= 0.45 then
        if bullet.remove then bullet:remove() end
        self.green_blocked = 0.12
        self.green_last_blocked = true
        return
    end
    self.green_last_blocked = false
    return super.onCollide(self, bullet)
end

function GreenSoul:update()
    if self.green_blocked > 0 then
        self.green_blocked = math.max(0, self.green_blocked - (DT or 1 / 30))
    end
    super.update(self)
end

function GreenSoul:draw()
    super.draw(self)
    local facing = DIRECTIONS[self.green_direction] or DIRECTIONS.right
    love.graphics.push("all")
    love.graphics.setLineWidth(5)
    love.graphics.setColor(0.62, 1.0, 0.70, self.green_blocked > 0 and 1 or 0.85)
    love.graphics.line(facing.x * 10, facing.y * 10,
        facing.x * 25, facing.y * 25)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", facing.x * 27, facing.y * 27, 5)
    love.graphics.pop()
end

return GreenSoul
