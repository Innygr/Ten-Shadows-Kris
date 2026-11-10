-- A controllable, detached SOUL object for overworld sequences.
-- The owning cutscene is responsible for pausing Kris and restoring them
-- when this object returns. This keeps character-specific behaviour out of
-- the generic movement object.

local SoulEjection, super = Class(Object, "SoulEjection")

function SoulEjection:init(x, y, options)
    super.init(self, x or 0, y or 0)

    options = options or {}

    self.speed = options.speed or 150
    self.bounds = options.bounds
    self.onInteract = options.onInteract
    self.onReturn = options.onReturn

    self.active = true
    self.returned = false
    self.pulse = 0
    self.depth = options.depth or 0
end

function SoulEjection:update()
    super.update(self)

    if not self.active then
        return
    end

    self.pulse = self.pulse + DT

    -- The SOUL is moved independently while detached.
    local dx = 0
    local dy = 0

    if Input.down("left") then
        dx = dx - 1
    end
    if Input.down("right") then
        dx = dx + 1
    end
    if Input.down("up") then
        dy = dy - 1
    end
    if Input.down("down") then
        dy = dy + 1
    end

    local length = math.sqrt(dx * dx + dy * dy)
    if length > 0 then
        dx = dx / length
        dy = dy / length

        self.x = self.x + dx * self.speed * DT
        self.y = self.y + dy * self.speed * DT
    end

    if self.bounds then
        self.x = Utils.clamp(self.x, self.bounds.left, self.bounds.right)
        self.y = Utils.clamp(self.y, self.bounds.top, self.bounds.bottom)
    end

    if Input.pressed("confirm") and self.onInteract then
        self.onInteract(self)
    end

    if Input.pressed("cancel") then
        self:returnToOwner()
    end
end

function SoulEjection:returnToOwner()
    if self.returned then
        return
    end

    self.active = false
    self.returned = true

    if self.onReturn then
        self.onReturn(self)
    end

    self:remove()
end

function SoulEjection:draw()
    super.draw(self)

    if not self.active then
        return
    end

    local pulse_scale = 1 + math.sin(self.pulse * 5) * 0.06

    love.graphics.push("all")
    love.graphics.translate(0, 0)
    love.graphics.scale(pulse_scale, pulse_scale)

    -- Draw a simple red SOUL without requiring a sprite asset.
    love.graphics.setColor(0.55, 0.02, 0.08, 0.28)
    love.graphics.circle("fill", -4, -3, 7)
    love.graphics.circle("fill", 4, -3, 7)
    love.graphics.polygon("fill", -11, -1, 11, -1, 0, 12)

    love.graphics.setColor(1, 0.08, 0.16, 1)
    love.graphics.circle("fill", -4, -4, 5)
    love.graphics.circle("fill", 4, -4, 5)
    love.graphics.polygon("fill", -9, -2, 9, -2, 0, 10)

    love.graphics.setColor(1, 0.72, 0.76, 0.9)
    love.graphics.circle("fill", -3, -5, 1.5)

    love.graphics.pop()
end

return SoulEjection
