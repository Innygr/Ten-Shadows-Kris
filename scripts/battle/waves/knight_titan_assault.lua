local KnightTitanAssault, super = Class(Wave)

function KnightTitanAssault:init()
    super.init(self)
    -- Leave enough room for the final telegraphed volley to cross the arena.
    self.time = 7.75
end

function KnightTitanAssault:onStart()
    local enemy = Game.battle.enemies and Game.battle.enemies[1] or nil
    local state = enemy and enemy.ten_shadows_state or nil
    local attack, frozen, domain_started, disrupted

    if state then
        state.boss.hp = enemy.health
        local soul = Game.battle.soul
        local active_soul_mode = soul and soul.ten_shadows_mode or nil
        attack, frozen, domain_started, disrupted = state:chooseEnemyAttack(active_soul_mode)
        if enemy then
            enemy.ten_shadows_active_soul_mode = active_soul_mode
        end
    end

    if enemy then
        enemy.ten_shadows_last_attack = attack and attack.id or "titan_swarm"
        enemy.ten_shadows_last_attack_disrupted = disrupted == true
    end

    local arena = Game.battle.arena

    -- Kris's domain is rendered inside the arena mask, below live projectiles.
    -- The Wave owns this object, so it is removed automatically when the
    -- current defending turn ends; the next wave recreates it while the
    -- three-turn Chimera Shadow Garden state remains active.
    local garden_visual = nil
    if state and state.player_domain.active and arena and arena.mask then
        local GardenVisual = modRequire("scripts/battle/objects/chimera_shadow_garden")
        local opening = state.player_domain.visual_pending == true
        state.player_domain.visual_pending = false
        garden_visual = GardenVisual(arena.width, arena.height, opening)
        self:spawnObjectTo(arena.mask, garden_visual, 0, 0)
    end

    if frozen then
        self.time = 2
        return
    end

    if domain_started and enemy then
        enemy.ten_shadows_domain_announcement = "* DOMAIN EXPANSION — KINGDOM OF THE ROARING."
    end

    local Patterns = modRequire("scripts/ten_shadows/attack_wave_patterns")
    local phase = state and state.boss.phase or 1
    local volley = 0
    local previous_target = nil

    self.timer:every(0.82, function()
        volley = volley + 1
        local soul = Game.battle.soul
        local target = soul and {x = soul.x, y = soul.y} or nil
        if target then
            target.previous = previous_target
            previous_target = {x = target.x, y = target.y}
        end
        local shots = Patterns.build(
            attack,
            phase,
            volley,
            arena,
            target,
            state and state.knight_domain.active or false,
            state and state.player_domain.active or false
        )

        if garden_visual then
            local active_roots = {}
            for _, shot in ipairs(shots) do
                if shot.mechanic and shot.mechanic.kind == "chimera_domain_blade" then
                    active_roots[#active_roots + 1] = shot.mechanic.root
                end
            end
            garden_visual:setActiveRoots(active_roots)
        end

        for _, shot in ipairs(shots) do
            self:spawnBullet(
                "shadow_projectile",
                shot.x,
                shot.y,
                shot.direction,
                shot.speed,
                shot.kind,
                shot.warning,
                shot.mechanic
            )
        end

        if volley >= 6 then
            self.timer:after(2.55, function()
                self:setFinished()
            end)
        end
    end, 6)
end

function KnightTitanAssault:onEnd(death)
    super.onEnd(self, death)

    if death then return end

    local enemy = Game.battle.enemies and Game.battle.enemies[1] or nil
    local state = enemy and enemy.ten_shadows_state or nil
    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    Shadows.onEnemyTurnEnd(enemy)

    if state then
        -- Status durations are measured in enemy turns, not individual
        -- volleys. Tick once after the complete Wave has ended.
        state:tickEnemyTurnEffects()
    end
end

return KnightTitanAssault
