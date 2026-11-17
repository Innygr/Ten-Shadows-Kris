-- Decorative Knight shield aura. It never collides, absorbs damage, or tracks HP.
local KnightShieldVisual, super = Class(Object)

function KnightShieldVisual:init(width, height)
    super.init(self)
    self.width = math.max(1, width or 24)
    self.height = math.max(1, height or 40)
    self.time = 0
    self.alpha = 0.72
end

function KnightShieldVisual:update()
    local delta = math.min(math.max(DT or (1 / 30), 0), 0.1)
    self.time = self.time + delta
    self.alpha = 0.58 + (math.sin(self.time * 2.6) + 1) * 0.10
    super.update(self)
end

function KnightShieldVisual:draw()
    local graphics = love.graphics
    local cx = self.width / 2
    local cy = self.height / 2
    local pulse = 1 + math.sin(self.time * 2.6) * 0.035

    graphics.push("all")
    graphics.setLineWidth(1.6)
    graphics.setColor(0.34, 0.78, 1.0, self.alpha * 0.28)
    graphics.ellipse("line", cx, cy, self.width * 0.58 * pulse, self.height * 0.59 * pulse)
    graphics.setColor(0.48, 0.88, 1.0, self.alpha)
    graphics.ellipse("line", cx, cy, self.width * 0.52 * pulse, self.height * 0.54 * pulse)
    graphics.setLineWidth(1)
    graphics.setColor(0.86, 0.98, 1.0, self.alpha * 0.76)
    graphics.arc("line", "open", cx, cy, self.width * 0.48, -0.75, 0.75)
    graphics.arc("line", "open", cx, cy, self.width * 0.48, math.pi - 0.75, math.pi + 0.75)
    graphics.pop()

    super.draw(self)
end

return KnightShieldVisual
