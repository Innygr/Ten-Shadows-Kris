-- Animated standalone Domain visual for Vessel.
-- A six-gate barrier seals the arena; portals orbit a central SOUL seal.
local VesselDomainBarrier, super = Class(Object)
local TAU = math.pi * 2
local function point(cx, cy, radius, angle)
    return cx + math.cos(angle) * radius, cy + math.sin(angle) * radius
end
local function hexagon(cx, cy, radius, rotation)
    local points = {}
    for index = 0, 5 do
        local x, y = point(cx, cy, radius, rotation + index * TAU / 6)
        points[#points + 1] = x
        points[#points + 1] = y
    end
    return points
end
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
    local cx, cy = width / 2, height / 2
    local radius = math.min(width, height) * 0.405
    local pulse = 0.5 + 0.5 * math.sin(self.time * 2.8)
    local rotation = self.time * 0.16
    graphics.push("all")
    graphics.setColor(0.035, 0.008, 0.025, 0.24)
    graphics.rectangle("fill", 0, 0, width, height)
    graphics.setColor(0.24, 0.018, 0.075, 0.12 + pulse * 0.07)
    graphics.ellipse("fill", cx, cy, width * 0.43, height * 0.42)
    graphics.setColor(0.55, 0.055, 0.16, 0.24 + pulse * 0.12)
    graphics.setLineWidth(5)
    graphics.polygon("line", unpack(hexagon(cx, cy, radius + 4, rotation)))
    graphics.setColor(0.92, 0.20, 0.34, 0.72 + pulse * 0.16)
    graphics.setLineWidth(2)
    graphics.polygon("line", unpack(hexagon(cx, cy, radius, rotation)))
    graphics.setColor(1.0, 0.55, 0.62, 0.62)
    graphics.setLineWidth(1)
    graphics.polygon("line", unpack(hexagon(cx, cy, radius - 5, rotation)))
    for node = 0, 5 do
        local angle = node * TAU / 6 - math.pi / 2 + rotation
        local nx, ny = point(cx, cy, radius, angle)
        local node_pulse = 0.5 + 0.5 * math.sin(self.time * 4 + node * 0.9)
        local gate_radius = 7 + node_pulse * 2
        local next_x, next_y = point(cx, cy, radius, angle + TAU / 6)
        graphics.setColor(0.62, 0.035, 0.14, 0.38)
        graphics.setLineWidth(2)
        graphics.line(nx, ny, next_x, next_y)
        graphics.setColor(0.68, 0.055, 0.19, 0.34 + node_pulse * 0.18)
        graphics.circle("fill", nx, ny, gate_radius + 3)
        graphics.setColor(1.0, 0.38, 0.50, 0.90)
        graphics.setLineWidth(1.5)
        graphics.circle("line", nx, ny, gate_radius)
        graphics.setColor(1.0, 0.78, 0.82, 0.95)
        graphics.circle("fill", nx, ny, 2 + node_pulse)
        local ix, iy = point(cx, cy, radius - 15, angle)
        graphics.setColor(0.92, 0.20, 0.36, 0.65)
        graphics.setLineWidth(1)
        graphics.line(nx, ny, ix, iy)
    end
    graphics.setColor(0.62, 0.055, 0.19, 0.58 + pulse * 0.15)
    graphics.setLineWidth(2)
    graphics.circle("line", cx, cy, radius * 0.48 + pulse * 2)
    graphics.setColor(0.96, 0.24, 0.40, 0.86)
    graphics.setLineWidth(1)
    graphics.circle("line", cx, cy, radius * 0.35)
    graphics.circle("line", cx, cy, radius * 0.22)
    graphics.setColor(0.35, 0.018, 0.09, 0.88)
    graphics.polygon("fill", unpack(hexagon(cx, cy, radius * 0.19, -rotation * 1.8)))
    graphics.setColor(1.0, 0.72, 0.78, 0.96)
    graphics.circle("fill", cx, cy, 2.5 + pulse)
    for index = 1, 12 do
        local angle = index * 2.399 + self.time * (0.25 + (index % 3) * 0.06)
        local orbit = radius * (0.54 + (index % 4) * 0.075)
        local x, y = point(cx, cy, orbit, angle)
        local shimmer = 0.28 + 0.52 * (0.5 + 0.5 * math.sin(self.time * 3 + index))
        graphics.setColor(1.0, 0.34, 0.48, shimmer)
        graphics.circle("fill", x, y, index % 3 == 0 and 2 or 1)
    end
    if self.opening > 0 then
        local progress = 1 - self.opening
        local bloom_radius = radius * (0.12 + progress * 1.35)
        graphics.setColor(1.0, 0.30, 0.46, self.opening * 0.72)
        graphics.setLineWidth(3)
        graphics.circle("line", cx, cy, bloom_radius)
        graphics.setColor(1.0, 0.70, 0.76, self.opening * 0.54)
        graphics.setLineWidth(1)
        graphics.circle("line", cx, cy, bloom_radius * 0.82)
    end
    graphics.pop()
    super.draw(self)
end
return VesselDomainBarrier
