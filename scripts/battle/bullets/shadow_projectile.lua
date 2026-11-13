local ShadowProjectile, super = Class(Bullet)

local COLORS = {
    knight = {1.0, 0.24, 0.30},
    titan = {0.20, 0.82, 1.0},
    combo = {1.0, 0.78, 0.24},
}

function ShadowProjectile:init(x, y, direction, speed, kind)
    super.init(self, x, y)

    self.width = 12
    self.height = 12
    self.collider = CircleCollider(self, 0, 0, 4)
    self.physics.direction = direction
    self.physics.speed = speed
    self.rotation = direction
    self.damage = 2
    self.kind = COLORS[kind] and kind or "titan"
end

function ShadowProjectile:draw()
    local color = COLORS[self.kind]
    love.graphics.setColor(color[1], color[2], color[3], 0.24)
    love.graphics.circle("fill", 0, 0, 7)

    love.graphics.setColor(color[1], color[2], color[3], 1)
    if self.kind == "knight" then
        love.graphics.polygon("fill", 0, -6, 4, 0, 0, 6, -4, 0)
        love.graphics.setColor(1, 0.86, 0.88, 1)
        love.graphics.line(-3, 0, 3, 0)
    elseif self.kind == "combo" then
        love.graphics.polygon("fill", 0, -6, 5, 0, 0, 6, -5, 0)
        love.graphics.setColor(1, 1, 0.88, 1)
        love.graphics.circle("fill", 0, 0, 2)
    else
        love.graphics.circle("line", 0, 0, 6)
        love.graphics.circle("fill", 0, 0, 3)
    end

    super.draw(self)
end

return ShadowProjectile
