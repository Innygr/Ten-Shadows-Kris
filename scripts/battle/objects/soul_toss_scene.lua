-- Visual-only encounter gag: Kris tosses the SOUL and Vessel dives for it.
local SoulTossScene, super = Class(Object, "SoulTossScene")

function SoulTossScene:init(width, height)
    super.init(self, 0, 0)
    self.width = width or 142
    self.height = height or 142
    self.timer = 0
    self.duration = 2.35
    self.layer = 10000
end

local function drawSoul(x, y, scale, alpha)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
    love.graphics.setColor(0.55, 0.03, 0.12, alpha)
    love.graphics.circle("fill", -5, -4, 7)
    love.graphics.circle("fill", 5, -4, 7)
    love.graphics.polygon("fill", -12, -3, 12, -3, 0, 13)
    love.graphics.setColor(1, 0.12, 0.20, alpha)
    love.graphics.circle("fill", -5, -5, 5)
    love.graphics.circle("fill", 5, -5, 5)
    love.graphics.polygon("fill", -9, -3, 9, -3, 0, 10)
    love.graphics.pop()
end

function SoulTossScene:update()
    self.timer = self.timer + (DT or 1 / 30)
    if self.timer >= self.duration then self:remove() end
    super.update(self)
end

function SoulTossScene:draw()
    local t, w, h = self.timer, self.width, self.height
    local start_x, start_y = w * 0.24, h * 0.62
    local end_x, end_y = w * 0.78, h * 0.40
    local progress = math.max(0, math.min(1, (t - 0.35) / 0.85))
    local eased = progress * progress * (3 - 2 * progress)
    local soul_x = start_x + (end_x - start_x) * eased
    local soul_y = start_y + (end_y - start_y) * eased - math.sin(progress * math.pi) * h * 0.20
    local dive = math.max(0, math.min(1, (t - 1.05) / 0.72))
    local vessel_x = w * 0.92 + (soul_x - w * 0.92) * dive
    local vessel_y = h * 0.18 + (soul_y - h * 0.18) * dive

    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 0.95)
    if t < 0.35 then
        love.graphics.printf("KRIS REMOVES THE SOUL...", 0, h * 0.12, w, "center")
    elseif t < 1.15 then
        love.graphics.printf("KRIS YEETS IT.", 0, h * 0.12, w, "center")
    else
        love.graphics.printf("VESSEL: YO, FREE SOUL", 0, h * 0.12, w, "center")
        love.graphics.setColor(0.55, 0.82, 1, 0.75)
        love.graphics.setLineWidth(5)
        love.graphics.line(w * 0.92, h * 0.18, vessel_x, vessel_y)
        love.graphics.setColor(0.78, 0.90, 1, 0.9)
        love.graphics.circle("fill", vessel_x, vessel_y, 8 + math.sin(t * 22) * 2)
    end
    drawSoul(soul_x, soul_y, 1 + math.sin(t * 15) * 0.08, 1)
    love.graphics.pop()
    super.draw(self)
end

return SoulTossScene
