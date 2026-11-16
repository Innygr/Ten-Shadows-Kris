-- Animated enclosing barrier used when Vessel expands without Kris.
local VesselDomainBarrier, super = Class(Object)

function VesselDomainBarrier:init(width, height, opening)
    super.init(self)
    self.width = math.max(1, width or 142)
    self.height = math.max(1, height or 142)
    self.time = 0
    self.opening = opening == true and 1 or 0
    self.layer = 0
end

function VesselDomainBarrier:update()
    local delta = math.min(math.max(DT or (1 / 30), 0), 0.1)
    self.time = self.time + delta
    self.opening = math.max(0, self.opening - delta / 0.9)
    super.update(self)
end

function VesselDomainBarrier:draw()
    local graphics = love.graphics
    local width, height = self.width, self.height
    local pulse = 0.5 + 0.5 * math.sin(self.time * 2.8)
    local inset = math.min(width, height) * 0.075
    local x, y = inset, inset
    local w, h = math.max(0, width - inset * 2), math.max(0, height - inset * 2)

    graphics.push("all")
    graphics.setColor(0.025, 0.008, 0.055, 0.18)
    graphics.rectangle("fill", 0, 0, width, height)
    if self.opening > 0 then
        graphics.setColor(0.95, 0.38, 0.50, self.opening * 0.7)
        graphics.setLineWidth(3)
        graphics.rectangle("line", x - self.opening * 12, y - self.opening * 12,
            w + self.opening * 24, h + self.opening * 24, 10, 10)
    end
    graphics.setColor(0.34, 0.055, 0.12, 0.26 + pulse * 0.10)
    graphics.setLineWidth(3)
    graphics.rectangle("line", x, y, w, h, 8, 8)
    graphics.setColor(0.88, 0.30, 0.43, 0.48 + pulse * 0.20)
    graphics.setLineWidth(1)
    graphics.rectangle("line", x + 4, y + 4, math.max(0, w - 8), math.max(0, h - 8), 6, 6)
    for node = 0, 5 do
        local angle = node * math.pi * 2 / 6 - math.pi / 2
        local nx = width / 2 + math.cos(angle) * math.min(width, height) * 0.39
        local ny = height / 2 + math.sin(angle) * math.min(width, height) * 0.39
        local node_pulse = 0.5 + 0.5 * math.sin(self.time * 4 + node)
        graphics.setColor(0.42, 0.045, 0.13, 0.40 + node_pulse * 0.20)
        graphics.circle("fill", nx, ny, 5 + node_pulse * 2)
        graphics.setColor(1.0, 0.62, 0.68, 0.88)
        graphics.circle("line", nx, ny, 4 + node_pulse * 2)
    end
    graphics.pop()
    super.draw(self)
end

return VesselDomainBarrier
