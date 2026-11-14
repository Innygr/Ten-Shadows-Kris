-- Animated battle-space visual for Kris's Chimera Shadow Garden.
-- Spawned into Arena.mask so the garden is clipped to the active battle arena
-- and naturally disappears when the defending Wave is cleared.

local ChimeraShadowGarden, super = Class(Object)

local TAU = math.pi * 2

local function color(r, g, b, alpha)
    love.graphics.setColor(r, g, b, alpha)
end

local function point(cx, cy, radius, angle)
    return cx + math.cos(angle) * radius, cy + math.sin(angle) * radius
end

local function diamond(cx, cy, radius, angle)
    local points = {}
    for i = 0, 3 do
        local x, y = point(cx, cy, radius * (i % 2 == 0 and 1 or 0.42), angle + i * math.pi / 2)
        points[#points + 1] = x
        points[#points + 1] = y
    end
    love.graphics.polygon("fill", unpack(points))
end

function ChimeraShadowGarden:init(width, height)
    super.init(self)

    self.width = math.max(1, width or 142)
    self.height = math.max(1, height or 142)
    self.time = 0
    self.fade = 0
    -- Children of Arena.mask share its visual layer; keep this object at the
    -- parent's local layer so it stays between the arena and live projectiles.
    self.layer = 0
end

function ChimeraShadowGarden:update()
    local delta = DT or (1 / 30)
    self.time = self.time + math.min(math.max(delta, 0), 0.1)
    self.fade = math.min(1, self.fade + delta * 2.8)
    super.update(self)
end

function ChimeraShadowGarden:draw()
    local graphics = love.graphics
    local width, height = self.width, self.height
    local cx, cy = width / 2, height / 2
    local radius = math.min(width, height) * 0.43
    local pulse = math.sin(self.time * 2.4)
    local spin = self.time * 0.12
    local fade = self.fade

    graphics.push("all")

    -- The garden floods the arena with layered ink rather than replacing the
    -- battle background outright, so incoming projectile tells remain clear.
    color(0.025, 0.008, 0.055, 0.30 * fade)
    graphics.rectangle("fill", 0, 0, width, height)

    color(0.11, 0.025, 0.20, 0.25 * fade)
    graphics.ellipse("fill", cx, cy, width * 0.44, height * 0.42)
    color(0.20, 0.045, 0.31, 0.13 * fade)
    graphics.ellipse("fill", cx, cy, width * 0.31, height * 0.30)

    -- Ten shadow roots connect the central seal to ten moving petal-shaped
    -- pools. Their offset and pulsing endpoints make the field feel alive.
    for index = 1, 10 do
        local angle = (index - 1) * TAU / 10 + spin
        local end_radius = radius * (0.72 + 0.035 * math.sin(self.time * 1.7 + index))
        local ex, ey = point(cx, cy, end_radius, angle)
        local bend_x, bend_y = point(cx, cy, radius * 0.43, angle + 0.16 * math.sin(self.time + index))

        color(0.19, 0.07, 0.34, 0.58 * fade)
        graphics.setLineWidth(3)
        graphics.line(cx, cy, bend_x, bend_y, ex, ey)

        color(0.43, 0.20, 0.65, 0.72 * fade)
        graphics.setLineWidth(1)
        graphics.line(cx, cy, bend_x, bend_y, ex, ey)

        local petal_x, petal_y = point(cx, cy, end_radius, angle)
        color(0.16, 0.055, 0.27, 0.82 * fade)
        diamond(petal_x, petal_y, math.min(width, height) * 0.075, angle)
        color(0.58, 0.30, 0.78, 0.78 * fade)
        graphics.circle("line", petal_x, petal_y, 4 + (index % 3))
        color(0.83, 0.65, 0.96, 0.86 * fade)
        graphics.circle("fill", petal_x, petal_y, 1.5)
    end

    -- A three-ring seal marks the centre of the domain. The broken outer ring
    -- rotates slowly while the inner diamond breathes with the garden pulse.
    color(0.48, 0.22, 0.70, 0.80 * fade)
    graphics.setLineWidth(2)
    graphics.circle("line", cx, cy, radius * 0.34 + pulse * 2)
    color(0.76, 0.48, 0.91, 0.68 * fade)
    graphics.setLineWidth(1)
    graphics.circle("line", cx, cy, radius * 0.25)
    graphics.circle("line", cx, cy, radius * 0.17)

    color(0.28, 0.09, 0.47, 0.90 * fade)
    diamond(cx, cy, radius * (0.17 + pulse * 0.012), spin)
    color(0.94, 0.82, 1.0, 0.95 * fade)
    graphics.circle("fill", cx, cy, 2.2)

    -- Small drifting motes add movement without obscuring warning lanes.
    for index = 1, 18 do
        local angle = index * 2.399 + self.time * (0.16 + (index % 3) * 0.035)
        local orbit = radius * (0.28 + (index % 5) * 0.12)
        local x, y = point(cx, cy, orbit, angle)
        local shimmer = 0.35 + 0.35 * (0.5 + 0.5 * math.sin(self.time * 2 + index))
        color(0.76, 0.58, 0.96, shimmer * fade)
        graphics.circle("fill", x, y, index % 4 == 0 and 2 or 1)
    end

    -- A fine garden boundary with ten evenly spaced marks frames the arena.
    color(0.40, 0.17, 0.61, 0.64 * fade)
    graphics.setLineWidth(1)
    graphics.rectangle("line", 5, 5, math.max(0, width - 10), math.max(0, height - 10))
    for index = 1, 10 do
        local x = 5 + (width - 10) * (index - 1) / 9
        color(0.72, 0.43, 0.88, 0.76 * fade)
        diamond(x, 5, 3, math.pi / 4)
        diamond(x, height - 5, 3, math.pi / 4)
    end

    graphics.pop()
    super.draw(self)
end

return ChimeraShadowGarden
