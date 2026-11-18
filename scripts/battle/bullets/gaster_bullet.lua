local GasterBullet, super = Class(Bullet)

function GasterBullet:init(x, y, direction, speed, phase)
    super.init(self, x, y)
    self.width = 14
    self.height = 14
    self.collider = CircleCollider(self, 0, 0, 5)
    self.physics.direction = direction
    self.physics.speed = speed or 4
    self.damage = 3
    self.phase = phase or 0
end

function GasterBullet:draw()
    local pulse = 0.82 + 0.18 * math.sin((Game and Game.battle and Game.battle.timer or 0) * 8 + self.phase)
    love.graphics.push("all")
    love.graphics.setColor(0.42, 0.18, 0.72, 0.28)
    love.graphics.circle("fill", 0, 0, 9 * pulse)
    love.graphics.setColor(0.72, 0.48, 0.98, 1)
    love.graphics.circle("fill", 0, 0, 5)
    love.graphics.setColor(0.96, 0.90, 1, 1)
    love.graphics.circle("fill", -1, -1, 2)
    love.graphics.pop()
    super.draw(self)
end

return GasterBullet
