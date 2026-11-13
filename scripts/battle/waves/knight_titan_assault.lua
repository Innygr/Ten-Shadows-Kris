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
    local arena = Game.battle.arena
    local volley = 0

    if frozen then
        self.time = 2
        return
    end

    self.timer:every(0.8, function()
        volley = volley + 1
        if attack_id == "titan_swarm" or attack_id == "titan_hands"
            or attack_id == "titan_big_shots" or attack_id == "titan_big_shots_2"
            or attack_id == "titan_big_shots_3" or attack_id == "titan_desperation"
            or attack_id == "crystal_barrage" then
            spawnFromTop(self, arena, attack_id == "titan_desperation" and 7 or 4, 3.2 + volley * 0.25)
        elseif attack_id == "titan_knight_combo" or attack_id == "knight_combo"
            or attack_id == "cross_attack" or attack_id == "combination" then
            local y = MathUtils.random(arena.top + 12, arena.bottom - 54)
            spawnSweep(self, arena, y, 3, 3.6, volley % 2 == 0)
            if volley % 2 == 0 then
                spawnFromTop(self, arena, 2, 3.1)
            end
        elseif attack_id == "box_splitter" or attack_id == "diagonal_bullet_walls"
            or attack_id == "sword_tunnel" or attack_id == "sword_tunnel_d1"
            or attack_id == "sword_tunnel_d2" then
            local gap_y = MathUtils.random(arena.top + 25, arena.bottom - 25)
            for i = 1, 5 do
                local y = arena.top + (i - 1) * ((arena.bottom - arena.top) / 4)
                if math.abs(y - gap_y) > 18 then
                    self:spawnBullet("runtime_test_bullet", arena.right + 8, y, math.rad(180), 3.8)
                end
            end
        else
            local y = MathUtils.random(arena.top + 10, arena.bottom - 10)
            spawnSweep(self, arena, y, attack_id == "tracking_swords" or attack_id == "tracking_swords_d1"
                or attack_id == "tracking_swords_d2" and 4 or 3, 3.4, volley % 2 == 1)
        end

        if volley >= 6 then
            self.timer:after(0.9, function()
                self:setFinished()
            end)
        end
    end, 6)
end

return KnightTitanAssault
