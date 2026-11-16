local BlueSoul, super = Class(Soul, "BlueSoul")

local GRAVITY = 0.42
local JUMP_SPEED = 7.6
local FLOOR_PADDING = 8
local CEILING_PADDING = 8

local function justPressed(key, state, field)
    if Input.pressed then return Input.pressed(key) end
    local down = Input.down(key)
    local pressed = down and not state[field]
    state[field] = down
    return pressed
end

function BlueSoul:init(x, y)
    super.init(self, x, y, {0.22, 0.43, 1.00})
    self.ten_shadows_mode = "blue"
    self.blue_velocity_y = 0
    self.blue_grounded = false
    self.blue_jump_was_down = false
end

function BlueSoul:doMovement()
    local arena = Game.battle and Game.battle.arena
    local dtmult = DTMULT or 1
    local move_x = 0
    if Input.down("left") then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end

    local jump_down = Input.down("up") or Input.down("confirm")
    local jump_pressed = jump_down and not self.blue_jump_was_down
    self.blue_jump_was_down = jump_down

    if jump_pressed and self.blue_grounded then
        self.blue_velocity_y = -JUMP_SPEED
        self.blue_grounded = false
    end

    self.moving_x = move_x
    self.moving_y = 0
    if move_x ~= 0 then
        self:move(move_x, 0, self.speed * dtmult)
    end

    self.blue_velocity_y = math.min(10, self.blue_velocity_y + GRAVITY * dtmult)
    self:move(0, self.blue_velocity_y * dtmult, 1)

    if arena then
        local top = arena.getTop and arena:getTop() or arena.top
        local bottom = arena.getBottom and arena:getBottom() or arena.bottom
        if bottom then
            local floor = bottom - FLOOR_PADDING
            if self.y >= floor then
                self.y = floor
                self.partial_y = 0
                self.blue_velocity_y = 0
                self.blue_grounded = true
            else
                self.blue_grounded = false
            end
        end
        if top and self.y < top + CEILING_PADDING then
            self.y = top + CEILING_PADDING
            self.partial_y = 0
            if self.blue_velocity_y < 0 then self.blue_velocity_y = 0 end
        end
    end
end

function BlueSoul:draw()
    super.draw(self)
    love.graphics.push("all")
    love.graphics.setColor(0.50, 0.68, 1.0, 0.65)
    love.graphics.setLineWidth(2)
    love.graphics.line(-10, 12, 10, 12)
    if not self.blue_grounded then
        love.graphics.circle("line", 0, 15, 5)
    end
    love.graphics.pop()
end

return BlueSoul
