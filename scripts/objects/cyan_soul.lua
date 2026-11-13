local CyanSoul, super = Class(Soul, "CyanSoul")

local CHARGE_SECONDS = 0.85
local MIN_PARRY_CHARGE = 0.35
local PARRY_RADIUS = 36
local PULSE_SECONDS = 0.36

function CyanSoul:init(x, y)
    super.init(self, x, y, {0.20, 0.90, 1.0})

    self.is_cyan_soul = true
    self.ten_shadows_mode = "cyan"
    self.cyan_charge = 0
    self.cyan_charging = false
    self.cyan_pulse_timer = 0
    self.cyan_pulse_radius = 36
    self.cyan_last_parry = false
end

function CyanSoul:releaseCharge()
    local charge = self.cyan_charge
    local bullets = Game.stage:getObjects(Bullet)
    local snapshot = {}
    for _, bullet in ipairs(bullets) do
        snapshot[#snapshot + 1] = bullet
    end

    local execution_nearby = false
    if charge >= MIN_PARRY_CHARGE then
        for _, bullet in ipairs(snapshot) do
            if bullet.is_execution_slash and bullet.armed then
                local dx = bullet.x - self.x
                local dy = bullet.y - self.y
                if dx * dx + dy * dy <= PARRY_RADIUS * PARRY_RADIUS then
                    execution_nearby = true
                    break
                end
            end
        end
    end

    -- The Cyan release purifies all projectiles currently on screen.
    for _, bullet in ipairs(snapshot) do
        if bullet and bullet.remove then
            bullet:remove()
        end
    end

    local parried = false
    if execution_nearby then
        local enemies = Game.battle and Game.battle.enemies or {}
        local boss = enemies[1]
        local state = boss and boss.ten_shadows_state
        if state and state.parryExecution then
            parried = state:parryExecution() == true
            if parried and Game.giveTension then
                Game:giveTension(12)
            end
        end
    end

    self.cyan_last_parry = parried
    self.cyan_pulse_radius = 32 + charge * 60
    self.cyan_pulse_timer = PULSE_SECONDS
    self.cyan_charge = 0
    self.cyan_charging = false
    return parried
end

function CyanSoul:update()
    local dt = DT or (1 / 30)
    if self.cyan_pulse_timer > 0 then
        self.cyan_pulse_timer = math.max(0, self.cyan_pulse_timer - dt)
    end

    local battle = Game and Game.battle
    if battle and battle.state == "DEFENDING" and not self.transitioning then
        if Input.down("confirm") then
            self.cyan_charging = true
            self.cyan_charge = math.min(1, self.cyan_charge + dt / CHARGE_SECONDS)
        elseif self.cyan_charging and Input.released("confirm") then
            -- Resolve before Soul:update runs its bullet-collision pass.
            self:releaseCharge()
        end
    else
        self.cyan_charging = false
        self.cyan_charge = 0
    end

    super.update(self)
end

function CyanSoul:draw()
    super.draw(self)

    love.graphics.push("all")
    if self.cyan_charging then
        local radius = 46 - (self.cyan_charge * 32)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.20, 0.90, 1.0, 0.22)
        love.graphics.circle("line", 0, 0, 46)
        love.graphics.setColor(0.42, 0.96, 1.0, 0.95)
        love.graphics.circle("line", 0, 0, radius)
    end

    if self.cyan_pulse_timer > 0 then
        local progress = 1 - (self.cyan_pulse_timer / PULSE_SECONDS)
        local radius = 10 + (self.cyan_pulse_radius - 10) * progress
        local alpha = self.cyan_pulse_timer / PULSE_SECONDS
        if self.cyan_last_parry then
            love.graphics.setColor(1.0, 0.88, 0.36, alpha)
        else
            love.graphics.setColor(0.38, 0.94, 1.0, alpha)
        end
        love.graphics.setLineWidth(self.cyan_last_parry and 4 or 2)
        love.graphics.circle("line", 0, 0, radius)
        if self.cyan_last_parry then
            love.graphics.circle("line", 0, 0, math.max(2, radius - 9))
        end
    end
    love.graphics.pop()
end

return CyanSoul
