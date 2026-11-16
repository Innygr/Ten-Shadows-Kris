-- Vessel's Granite Blast: a short, asset-free charge and portal launch effect.
-- Coordinates are screen-space so the effect can bridge the arena and boss sprites.
local GraniteBlast, super = Class(Object)

local CHARGE_TIME = 0.30
local TOTAL_TIME = 0.78

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function GraniteBlast:init(entry_x, entry_y, exit_x, exit_y, target_x, target_y, output)
    super.init(self, 0, 0)

    self.entry = {x = entry_x or 0, y = entry_y or 0}
    self.exit = {x = exit_x or 0, y = exit_y or 0}
    self.target = {x = target_x or 0, y = target_y or 0}
    self.output = clamp(tonumber(output) or 1, 0, 1)
    self.time = 0
    self.fired = false
    self.finished = false
    self.layer = 1000
end

function GraniteBlast:update()
    self.time = self.time + (DT or (1 / 30))
    if self.time >= CHARGE_TIME then
        self.fired = true
    end
    if self.time >= TOTAL_TIME then
        self.finished = true
        self:remove()
    end
    super.update(self)
end

function GraniteBlast:draw()
    local graphics = love.graphics
    local progress = clamp(self.time / TOTAL_TIME, 0, 1)
    local charge = clamp(self.time / CHARGE_TIME, 0, 1)
    local pulse = 0.5 + 0.5 * math.sin(self.time * 24)
    local entry, exit, target = self.entry, self.exit, self.target

    graphics.push("all")

    -- Draw a separate entry gate only when a Fusion Domain portal pair
    -- is active. Outside the Domain the shot launches directly from the SOUL.
    if math.abs(entry.x - exit.x) > 1 or math.abs(entry.y - exit.y) > 1 then
        graphics.setLineWidth(2)
        graphics.setColor(0.38, 0.12, 0.72, 0.24 + charge * 0.34)
        graphics.circle("line", entry.x, entry.y, 8 + charge * 8 + pulse * 2)
        graphics.setColor(0.70, 0.38, 1.0, 0.82)
        graphics.circle("line", entry.x, entry.y, 5 + charge * 4)
    end

    graphics.setColor(0.48, 0.12, 0.78, 0.30 + pulse * 0.15)
    graphics.circle("fill", exit.x, exit.y, 12 + pulse * 3)
    graphics.setColor(0.78, 0.55, 1.0, 0.94)
    graphics.setLineWidth(3)
    graphics.circle("line", exit.x, exit.y, 9 + charge * 5)
    graphics.setLineWidth(1)
    graphics.circle("line", exit.x, exit.y, 4 + charge * 3)

    if self.fired then
        local fade = 1 - clamp((self.time - CHARGE_TIME) / (TOTAL_TIME - CHARGE_TIME), 0, 1)
        local width = 4 + self.output * 7
        -- Layered beam, with a bright core, connects the exit gate to the
        -- selected boss. It is presentation only; damage is resolved once by
        -- the ACT handler, never by this visual.
        graphics.setColor(0.43, 0.18, 0.86, 0.22 * fade)
        graphics.setLineWidth(width * 3)
        graphics.line(exit.x, exit.y, target.x, target.y)
        graphics.setColor(0.66, 0.48, 1.0, 0.72 * fade)
        graphics.setLineWidth(width)
        graphics.line(exit.x, exit.y, target.x, target.y)
        graphics.setColor(0.96, 0.91, 1.0, 0.98 * fade)
        graphics.setLineWidth(math.max(1, width * 0.28))
        graphics.line(exit.x, exit.y, target.x, target.y)

        local impact_radius = 5 + progress * 16
        graphics.setColor(0.82, 0.66, 1.0, 0.72 * fade)
        graphics.setLineWidth(2)
        graphics.circle("line", target.x, target.y, impact_radius)
        graphics.setColor(1, 1, 1, 0.88 * fade)
        graphics.circle("fill", target.x, target.y, math.max(2, impact_radius * 0.22))
    else
        -- A small gathering flare makes the short wind-up legible.
        graphics.setColor(0.74, 0.48, 1.0, 0.34 + pulse * 0.28)
        graphics.setLineWidth(2)
        graphics.circle("line", exit.x, exit.y, 13 + charge * 12)
        for index = 0, 5 do
            local angle = self.time * 4 + index * math.pi / 3
            local inner = 11 + charge * 3
            local outer = 17 + charge * 9
            graphics.line(
                exit.x + math.cos(angle) * inner,
                exit.y + math.sin(angle) * inner,
                exit.x + math.cos(angle) * outer,
                exit.y + math.sin(angle) * outer
            )
        end
    end

    graphics.pop()
    super.draw(self)
end

return GraniteBlast
