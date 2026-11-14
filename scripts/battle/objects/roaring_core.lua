-- Animated central indicator for THE ROARING's two rotating safe spokes.
-- Attached to Arena.mask so its marks stay clipped to the battle box and are
-- removed with the Wave. It uses only LÖVE primitives; no external art needed.

local RoaringCoreVisual, super = Class(Object)

local TAU = math.pi * 2
local SPOKES = 10
local STEP = TAU / SPOKES

local function point(cx, cy, radius, angle)
    return cx + math.cos(angle) * radius, cy + math.sin(angle) * radius
end

function RoaringCoreVisual:init(width, height)
    super.init(self)
    self.width = math.max(1, width or 142)
    self.height = math.max(1, height or 142)
    self.time = 0
    self.fade = 0
    self.rotation = 0
    self.safe_wedges = {}
    self.has_safe_route = false
    self.layer = 0
end

function RoaringCoreVisual:setSafeWedges(first, second, rotation)
    local function valid(index)
        return type(index) == "number" and index == math.floor(index)
            and index >= 0 and index < SPOKES
    end
    if not valid(first) or not valid(second) or (first + 5) % SPOKES ~= second then
        return false
    end

    self.safe_wedges = {[first] = true, [second] = true}
    self.rotation = type(rotation) == "number" and rotation or 0
    self.has_safe_route = true
    return true
end

function RoaringCoreVisual:update()
    local delta = DT or (1 / 30)
    delta = math.min(math.max(delta, 0), 0.1)
    self.time = self.time + delta
    self.fade = math.min(1, self.fade + delta * 4)
    super.update(self)
end

function RoaringCoreVisual:draw()
    local graphics = love.graphics
    local cx, cy = self.width / 2, self.height / 2
    local radius = math.min(self.width, self.height) * 0.16
    local pulse = 0.5 + 0.5 * math.sin(self.time * 5.2)
    local alpha = self.fade

    graphics.push("all")

    -- Dark core and two thin rings give the radial attack a clear focal point.
    graphics.setColor(0.035, 0.004, 0.018, 0.82 * alpha)
    graphics.circle("fill", cx, cy, radius * 0.57)
    graphics.setColor(0.42, 0.025, 0.10, 0.72 * alpha)
    graphics.setLineWidth(2)
    graphics.circle("line", cx, cy, radius * (0.78 + pulse * 0.06))
    graphics.setColor(0.76, 0.075, 0.19, 0.36 * alpha)
    graphics.setLineWidth(1)
    graphics.circle("line", cx, cy, radius * (1.08 + pulse * 0.10))

    for spoke = 0, SPOKES - 1 do
        local angle = self.rotation + spoke * STEP
        local inner_x, inner_y = point(cx, cy, radius * 0.69, angle)
        local outer_x, outer_y = point(cx, cy, radius * 1.17, angle)
        local safe = self.safe_wedges[spoke] == true

        if safe then
            graphics.setColor(0.77, 0.56, 1.0, (0.58 + pulse * 0.30) * alpha)
            graphics.setLineWidth(2)
            graphics.line(inner_x, inner_y, outer_x, outer_y)
            graphics.circle("fill", outer_x, outer_y, 2.6 + pulse * 0.8)

            -- A small outward chevron makes the open direction legible even
            -- when the eight red projectile tells are moving across it.
            local tip_x, tip_y = point(cx, cy, radius * 1.42, angle)
            local left_x, left_y = point(cx, cy, radius * 1.05, angle - 0.12)
            local right_x, right_y = point(cx, cy, radius * 1.05, angle + 0.12)
            graphics.polygon("fill", tip_x, tip_y, left_x, left_y, right_x, right_y)
        else
            graphics.setColor(0.50, 0.045, 0.12, 0.58 * alpha)
            graphics.setLineWidth(1)
            graphics.line(inner_x, inner_y, outer_x, outer_y)
            graphics.circle("fill", outer_x, outer_y, 1.3)
        end
    end

    graphics.setColor(0.90, 0.14, 0.28, 0.90 * alpha)
    graphics.circle("fill", cx, cy, 2.0 + pulse * 0.7)

    graphics.pop()
    super.draw(self)
end

return RoaringCoreVisual
