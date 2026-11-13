local KnightTitanAssault, super = Class(Wave)

local function spawnFromTop(wave, arena, count, speed)
    for i = 1, count do
        local x = MathUtils.random(arena.left + 8, arena.right - 8)
        wave:spawnBullet("runtime_test_bullet", x, arena.top - 10, math.rad(90), speed)
    end
end

local function spawnSweep(wave, arena, y, count, speed, from_right)
    for i = 1, count do
        local x = from_right and (arena.right + 10) or (arena.left - 10)
        local direction = from_right and math.rad(180) or 0
        local offset = (i - 1) * 18
        wave:spawnBullet("runtime_test_bullet", x, y + offset, direction, speed)
    end
end

function KnightTitanAssault:init()
    super.init(self)
    self.time = 6
end

function KnightTitanAssault:onStart()
    local enemy = Game.battle.enemies and Game.battle.enemies[1] or nil
    local state = enemy and enemy.ten_shadows_state or nil
    local attack, frozen, domain_started

    if state then
        state.boss.hp = enemy.health
        attack, frozen, domain_started = state:chooseEnemyAttack()
    end

    local attack_id = attack and attack.id or "titan_swarm"
    local pattern = attack and attack.pattern or attack_id
    local phase = state and state.boss.phase or 1
    local arena = Game.battle.arena
    local volley = 0
    local speed_bonus = (phase - 1) * 0.45

    if frozen then
        self.time = 2
        return
    end

    self.timer:every(0.8, function()
        volley = volley + 1
        if attack_id == "titan_swarm" or attack_id == "titan_hands"
            or attack_id == "titan_big_shots" or attack_id == "titan_big_shots_2"
            or attack_id == "titan_big_shots_3" or attack_id == "titan_desperation"
            or attack_id == "crystal_barrage" or pattern == "radial-pulse-barrage"
            or pattern == "falling-columns" or pattern == "timed-pulse-rings" then
            local count = (attack_id == "titan_desperation" or phase == 3) and 7 or 4
            spawnFromTop(self, arena, count, 3.0 + speed_bonus + volley * 0.2)
        elseif attack_id == "titan_knight_combo" or attack_id == "knight_combo"
            or attack_id == "cross_attack" or attack_id == "combination"
            or pattern == "crosscut-burst" or pattern == "gravity-arc"
            or pattern == "gravity-slam" or pattern == "feint-then-lunge"
            or pattern == "ricochet-blades" or pattern == "pause-then-strike" then
            local y = MathUtils.random(arena.top + 12, arena.bottom - 54)
            spawnSweep(self, arena, y, phase == 3 and 4 or 3, 3.3 + speed_bonus, volley % 2 == 0)
            if volley % 2 == 0 then
                spawnFromTop(self, arena, 2, 2.9 + speed_bonus)
            end
        elseif attack_id == "box_splitter" or attack_id == "diagonal_bullet_walls"
            or attack_id == "sword_tunnel" or attack_id == "sword_tunnel_d1"
            or attack_id == "sword_tunnel_d2" or pattern == "timed-laser-grid"
            or pattern == "guardbreak-grid" or pattern == "closing-thread-grid"
            or pattern == "thread-cage-crosscut" or pattern == "moving-hazard-lanes" then
            local gap_y = MathUtils.random(arena.top + 25, arena.bottom - 25)
            for i = 1, 5 do
                local y = arena.top + (i - 1) * ((arena.bottom - arena.top) / 4)
                if math.abs(y - gap_y) > 18 then
                    self:spawnBullet("runtime_test_bullet", arena.right + 8, y, math.rad(180), 3.4 + speed_bonus)
                end
            end
        else
            local y = MathUtils.random(arena.top + 10, arena.bottom - 10)
            local count = (attack_id == "tracking_swords" or attack_id == "tracking_swords_d1"
                or attack_id == "tracking_swords_d2") and 4 or 3
            spawnSweep(self, arena, y, count, 3.1 + speed_bonus, volley % 2 == 1)
        end

        if volley >= 6 then
            self.timer:after(0.9, function()
                self:setFinished()
            end)
        end
    end, 6)
end

return KnightTitanAssault
