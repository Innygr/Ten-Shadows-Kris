local RuntimeTestBullet, super = Class(Bullet)

function RuntimeTestBullet:init(x, y, direction, speed)
    super.init(self, x, y)

    self.width = 10
    self.height = 10
    self.collider = CircleCollider(self, 0, 0, 4)
    self.physics.direction = direction
    self.physics.speed = speed
    self.damage = 2
end

function RuntimeTestBullet:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 0, 0, 4)
    love.graphics.setColor(1, 1, 1, 1)
    super.draw(self)
end

return RuntimeTestBullet
