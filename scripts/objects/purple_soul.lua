local PurpleSoul, super = Class(Soul, "PurpleSoul")

local LANE_COUNT = 5
local PADDING = 16

function PurpleSoul:init(x, y)
    super.init(self, x, y, {0.72, 0.34, 1.00})
    self.ten_shadows_mode = "purple"
    self.purple_lane = 3
    self.purple_lane_y = y
    self.purple_up_down = false
    self.purple_down_down = false
    self:syncLaneFromPosition()
end

function PurpleSoul:syncLaneFromPosition()
    local arena = Game.battle and Game.battle.arena
    if not arena then return end
    local top = arena.getTop and arena:getTop() or arena.top or 0
    local bottom = arena.getBottom and arena:getBottom() or arena.bottom or (top + 142)
    local span = math.max(1, bottom - top - PADDING * 2)
    local nearest = 1
    local nearest_distance = math.huge
    for lane = 1, LANE_COUNT do
        local y = top + PADDING + span * ((lane - 1) / (LANE_COUNT - 1))
        local distance = math.abs(self.y - y)
        if distance < nearest_distance then
            nearest = lane
            nearest_distance = distance
        end
    end
    self.purple_lane = nearest
    self.purple_lane_y = top + PADDING + span * ((nearest - 1) / (LANE_COUNT - 1))
end

function PurpleSoul:doMovement()
    local arena = Game.battle and Game.battle.arena
    if not arena then return end
    local top = arena.getTop and arena:getTop() or arena.top or 0
    local bottom = arena.getBottom and arena:getBottom() or arena.bottom or (top + 142)
    local span = math.max(1, bottom - top - PADDING * 2)

    local up_down = Input.down("up")
    local down_down = Input.down("down")
    if up_down and not self.purple_up_down then
        self.purple_lane = math.max(1, self.purple_lane - 1)
    elseif down_down and not self.purple_down_down then
        self.purple_lane = math.min(LANE_COUNT, self.purple_lane + 1)
    end
    self.purple_up_down = up_down
    self.purple_down_down = down_down
    self.purple_lane_y = top + PADDING + span * ((self.purple_lane - 1) / (LANE_COUNT - 1))

    local move_x = 0
    if Input.down("left") then move_x = move_x - 1 end
    if Input.down("right") then move_x = move_x + 1 end
    self.moving_x = move_x
    self.moving_y = 0
    if move_x ~= 0 then self:move(move_x, 0, self.speed * (DTMULT or 1)) end

    local left = arena.getLeft and arena:getLeft() or arena.left or 0
    local right = arena.getRight and arena:getRight() or arena.right or (left + 142)
    self.x = math.max(left + PADDING, math.min(right - PADDING, self.x))
    self.y = self.purple_lane_y
    self.partial_y = 0
end

function PurpleSoul:draw()
    super.draw(self)
    love.graphics.push("all")
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.78, 0.48, 1.0, 0.34)
    love.graphics.line(-42, 0, 42, 0)
    love.graphics.line(-42, -4, 42, -4)
    love.graphics.line(-42, 4, 42, 4)
    love.graphics.setColor(0.92, 0.78, 1.0, 0.9)
    love.graphics.circle("line", 0, 0, 11)
    love.graphics.pop()
end

return PurpleSoul
