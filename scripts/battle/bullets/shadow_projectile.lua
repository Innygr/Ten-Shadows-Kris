local ShadowProjectile, super = Class(Bullet)

local COLORS = {
    knight = {1.0, 0.24, 0.30},
    titan = {0.20, 0.82, 1.0},
    combo = {1.0, 0.78, 0.24},
}

function ShadowProjectile:init(x, y, direction, speed, kind, warning, mechanic)
    super.init(self, x, y)

    self.kind = COLORS[kind] and kind or "titan"
    self.mechanic = mechanic
    self.is_execution_slash = type(mechanic) == "table" and mechanic.kind == "execution_slash"
    self.is_titan_hand = type(mechanic) == "table" and mechanic.kind == "titan_hand"
    self.is_titan_big_shot = type(mechanic) == "table" and mechanic.kind == "titan_big_shot"
    self.big_shot_tier = self.is_titan_big_shot and mechanic.tier or nil
    local radius = self.is_titan_big_shot and (self.big_shot_tier == 3 and 9 or 8)
        or (self.is_titan_hand and 6 or 4)
    self.width = radius * 3
    self.height = radius * 3
    self.collider = CircleCollider(self, 0, 0, radius)
    self.physics.direction = direction
    self.intended_speed = speed
    self.physics.speed = speed
    self.rotation = direction
    self.damage = 2
    self.armed = true
    self.telegraph = nil

    -- Warn along the projectile's actual travel vector, but do not give the
    -- warning a hitbox or movement. The bullet arms only after the tell ends.
    if type(warning) == "table" and (warning.duration or 0) > 0 and (warning.length or 0) > 0 then
        self.telegraph = warning
        self.armed = false
        self.collider = nil
        self.physics.speed = 0

        self.telegraph_timer = Timer()
        self:addChild(self.telegraph_timer)
        self.telegraph_timer:after(warning.duration, function()
            self:arm()
        end)
    end
end

function ShadowProjectile:arm()
    if self.armed then return end

    self.armed = true
    self.telegraph = nil
    local radius = self.is_titan_big_shot and (self.big_shot_tier == 3 and 9 or 8)
        or (self.is_titan_hand and 6 or 4)
    self.collider = CircleCollider(self, 0, 0, radius)
    self.physics.speed = self.intended_speed
end

function ShadowProjectile:draw()
    local color = COLORS[self.kind]

    if self.telegraph then
        local length = self.telegraph.length
        love.graphics.setLineWidth(6)
        love.graphics.setColor(color[1], color[2], color[3], 0.18)
        love.graphics.line(0, 0, length, 0)

        love.graphics.setLineWidth(2)
        love.graphics.setColor(color[1], color[2], color[3], 0.88)
        love.graphics.line(0, 0, length, 0)

        love.graphics.setColor(1, 1, 1, 0.8)
        if self.telegraph.kind == "target" then
            love.graphics.circle("line", length, 0, 8)
            love.graphics.line(length - 5, -5, length + 5, 5)
            love.graphics.line(length - 5, 5, length + 5, -5)
        elseif self.telegraph.kind == "lane" then
            love.graphics.line(0, -5, 0, 5)
            love.graphics.line(length, -5, length, 5)
        else
            love.graphics.polygon("line", length, -5, length + 5, 0, length, 5, length - 5, 0)
        end

        super.draw(self)
        return
    end

    if self.is_titan_big_shot then
        local radius = self.big_shot_tier == 3 and 9 or 8
        love.graphics.setColor(color[1], color[2], color[3], 0.22)
        love.graphics.circle("fill", 0, 0, radius + 5)
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.circle("fill", 0, 0, radius)
        love.graphics.setColor(0.88, 0.98, 1, 1)
        love.graphics.circle("fill", 0, 0, radius * 0.48)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", 0, 0, radius + 2)
        super.draw(self)
        return
    end

    if self.is_titan_hand then
        -- A compact, direction-facing fist silhouette makes the Titan's
        -- sweeping knuckles visually distinct from ordinary Titan shots.
        love.graphics.setColor(color[1], color[2], color[3], 0.28)
        love.graphics.circle("fill", 0, 0, 10)
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.polygon("fill", -9, -6, 3, -7, 9, -3, 9, 3, 3, 7, -9, 6)
        love.graphics.circle("fill", 4, -5, 3)
        love.graphics.circle("fill", 7, -2, 3)
        love.graphics.circle("fill", 7, 2, 3)
        love.graphics.circle("fill", 4, 5, 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.line(-6, -3, 2, -3)
        love.graphics.line(-6, 0, 2, 0)
        love.graphics.line(-6, 3, 2, 3)
        super.draw(self)
        return
    end

    love.graphics.setColor(color[1], color[2], color[3], 0.24)
    love.graphics.circle("fill", 0, 0, 7)

    love.graphics.setColor(color[1], color[2], color[3], 1)
    if self.kind == "knight" then
        love.graphics.polygon("fill", 0, -6, 4, 0, 0, 6, -4, 0)
        love.graphics.setColor(1, 0.86, 0.88, 1)
        love.graphics.line(-3, 0, 3, 0)
        if self.is_execution_slash then
            love.graphics.setLineWidth(3)
            love.graphics.line(-10, -2, 10, 2)
            love.graphics.line(-10, 2, 10, -2)
        end
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
