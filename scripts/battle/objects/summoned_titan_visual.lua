-- A brief, non-interactive manifestation of Kris and Vessel's own Titan.
-- Purple/blue shadow palette; purely visual, with no collision or red tint.
local SummonedTitan, super = Class(Object)

function SummonedTitan:init(width, height)
    super.init(self)
    self.width = width or 142
    self.height = height or 142
    self.timer = 0
    self.duration = 1.8
    self.layer = 100
end

function SummonedTitan:update()
    self.timer = self.timer + (DT or 1 / 30)
    if self.timer >= self.duration then self:remove() end
    super.update(self)
end

function SummonedTitan:draw()
    local g = love.graphics
    local progress = math.min(1, self.timer / 0.55)
    local fade = math.min(1, (self.duration - self.timer) / 0.45)
    local rise = (1 - progress) * 28
    local cx, cy = self.width * 0.5, self.height * 0.57 + rise
    local pulse = 0.5 + 0.5 * math.sin(self.timer * 8)
    g.push("all")
    g.setColor(0.025, 0.015, 0.075, 0.72 * fade)
    g.ellipse("fill", cx, cy + 17, 42, 15)
    g.setColor(0.20, 0.12, 0.48, 0.88 * fade)
    g.polygon("fill", cx - 25, cy + 27, cx - 20, cy - 17, cx - 8, cy - 42,
        cx + 8, cy - 42, cx + 20, cy - 17, cx + 25, cy + 27)
    g.setColor(0.35, 0.25, 0.72, 0.95 * fade)
    g.polygon("fill", cx - 36, cy + 5, cx - 26, cy - 28, cx - 15, cy - 8, cx - 18, cy + 22)
    g.polygon("fill", cx + 36, cy + 5, cx + 26, cy - 28, cx + 15, cy - 8, cx + 18, cy + 22)
    g.setColor(0.60, 0.82, 1.0, (0.55 + pulse * 0.35) * fade)
    g.setLineWidth(3)
    g.line(cx - 19, cy - 12, cx - 8, cy - 29, cx, cy - 13, cx + 8, cy - 29, cx + 19, cy - 12)
    g.setColor(0.85, 0.94, 1.0, 0.9 * fade)
    g.circle("fill", cx - 8, cy - 7, 2.2)
    g.circle("fill", cx + 8, cy - 7, 2.2)
    g.setColor(0.48, 0.70, 1.0, 0.25 * fade)
    g.circle("line", cx, cy - 5, 34 + pulse * 5)
    g.pop()
    super.draw(self)
end

return SummonedTitan
