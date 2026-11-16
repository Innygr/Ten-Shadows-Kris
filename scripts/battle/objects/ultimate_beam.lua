-- Vessel's ultimate beam charges through one complete enemy turn.
-- The Wave calls release() after that turn and owns the actual damage event.
local UltimateBeam, super = Class(Object)

local CHARGE_TIME = 7.75
local RELEASE_TIME = 0.72

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function UltimateBeam:init(origin_x, origin_y, target_x, target_y)
    super.init(self, 0, 0)
    self.origin = {x = origin_x or 0, y = origin_y or 0}
    self.target = {x = target_x or 0, y = target_y or 0}
    self.charge_time = 0
    self.release_time = 0
    self.released = false
    self.hit = false
    self.layer = 1000
end

function UltimateBeam:release(hit)
    if self.released then return false end
    self.released = true
    self.hit = hit == true
    -- One full enemy turn has elapsed, regardless of how short a frozen
    -- turn's Wave is in real time.
    self.charge_time = CHARGE_TIME
    self.release_time = RELEASE_TIME
    return true
end

function UltimateBeam:update()
    local dt = DT or (1 / 30)
    if not self.released then
        self.charge_time = math.min(CHARGE_TIME, self.charge_time + dt)
    else
        self.release_time = math.max(0, self.release_time - dt)
        if self.release_time <= 0 then
            self:remove()
        end
    end
    super.update(self)
end

function UltimateBeam:draw()
    local graphics = love.graphics
    local charge = clamp(self.charge_time / CHARGE_TIME, 0, 1)
    local pulse = 0.5 + 0.5 * math.sin(self.charge_time * 10)
    local origin, target = self.origin, self.target

    graphics.push("all")

    -- The thin guide line makes the locked target clear while the source
    -- gathers energy for the full enemy turn.
    graphics.setColor(0.55, 0.18, 0.88, 0.12 + charge * 0.24)
    graphics.setLineWidth(1 + charge * 2)
    graphics.line(origin.x, origin.y, target.x, target.y)

    local radius = 8 + charge * 22 + pulse * (2 + charge * 5)
    graphics.setColor(0.42, 0.12, 0.82, 0.24 + charge * 0.28)
    graphics.circle("fill", origin.x, origin.y, radius + 7)
    graphics.setColor(0.76, 0.52, 1.0, 0.65 + charge * 0.30)
    graphics.setLineWidth(2 + charge * 2)
    graphics.circle("line", origin.x, origin.y, radius)
    graphics.setColor(0.96, 0.90, 1.0, 0.88)
    graphics.circle("fill", origin.x, origin.y, 3 + charge * 5)

    -- Six gathering rays converge on the source as the charge completes.
    for index = 0, 5 do
        local angle = self.charge_time * 1.8 + index * math.pi / 3
        local inner = radius + 5
        local outer = inner + 5 + charge * 14
        graphics.setColor(0.78, 0.55, 1.0, 0.20 + charge * 0.58)
        graphics.setLineWidth(1 + charge * 1.5)
        graphics.line(
            origin.x + math.cos(angle) * inner,
            origin.y + math.sin(angle) * inner,
            origin.x + math.cos(angle) * outer,
            origin.y + math.sin(angle) * outer
        )
    end

    if self.released then
        local fade = clamp(self.release_time / RELEASE_TIME, 0, 1)
        local impact = (1 - fade)
        local width = self.hit and 30 or 8
        graphics.setColor(0.48, 0.13, 0.88, 0.26 * fade)
        graphics.setLineWidth(width * 2.2)
        graphics.line(origin.x, origin.y, target.x, target.y)
        graphics.setColor(0.78, 0.54, 1.0, 0.82 * fade)
        graphics.setLineWidth(width)
        graphics.line(origin.x, origin.y, target.x, target.y)
        graphics.setColor(1.0, 0.96, 1.0, 0.98 * fade)
        graphics.setLineWidth(math.max(2, width * 0.28))
        graphics.line(origin.x, origin.y, target.x, target.y)
        graphics.setColor(0.88, 0.70, 1.0, 0.72 * fade)
        graphics.setLineWidth(3)
        graphics.circle("line", target.x, target.y, 8 + impact * 36)
    end

    graphics.pop()
    super.draw(self)
end

return UltimateBeam
