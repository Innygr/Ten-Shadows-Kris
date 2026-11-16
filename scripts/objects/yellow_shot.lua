local YellowShot, super = Class(Object, "YellowSoulShot")

function YellowShot:init(x, y, charged)
    super.init(self, x, y)
    self.charged = charged == true
    self.radius = self.charged and 15 or 6
    self.speed = self.charged and 8.5 or 10.5
    self.damage = self.charged and 0 or 0
    self.width = self.radius * 2
    self.height = self.radius * 2
    self.layer = (BATTLE_LAYERS and BATTLE_LAYERS["bullets"] or 0) + 0.2
    self.life = 0
    self.remove_offscreen = true
    self.previous_x = x
end

function YellowShot:update()
    local dtmult = DTMULT or 1
    self.previous_x = self.x
    self.x = self.x + self.speed * dtmult
    self.life = self.life + (DT or 1 / 30)

    local stage = Game and Game.stage
    if stage and stage.getObjects and Bullet then
        local bullets = stage:getObjects(Bullet)
        local removed = {}
        for _, bullet in ipairs(bullets) do
            if bullet and bullet ~= self and bullet.armed ~= false and not bullet.removed then
                local bx, by = bullet.x or 0, bullet.y or 0
                local left = math.min(self.previous_x, self.x) - self.radius - 8
                local right = math.max(self.previous_x, self.x) + self.radius + 8
                local dy = math.abs(by - self.y)
                if bx >= left and bx <= right and dy <= self.radius + 8 then
                    removed[#removed + 1] = bullet
                end
            end
        end
        for _, bullet in ipairs(removed) do
            if bullet.remove then bullet:remove() end
        end
        self.last_cleared = #removed
    end

    if self.x > (SCREEN_WIDTH or 640) + self.radius or self.life > 2.5 then
        self:remove()
    end
    super.update(self)
end

function YellowShot:draw()
    local pulse = 0.75 + math.sin(self.life * 18) * 0.12
    love.graphics.push("all")
    love.graphics.setColor(1.0, 0.82, 0.18, 0.22)
    love.graphics.circle("fill", 0, 0, self.radius + (self.charged and 10 or 5))
    love.graphics.setColor(1.0, 0.88, 0.22, pulse)
    love.graphics.circle("fill", 0, 0, self.radius)
    love.graphics.setColor(1.0, 1.0, 0.88, 1)
    love.graphics.circle("fill", 0, 0, self.charged and 5 or 2.5)
    love.graphics.pop()
    super.draw(self)
end

return YellowShot
