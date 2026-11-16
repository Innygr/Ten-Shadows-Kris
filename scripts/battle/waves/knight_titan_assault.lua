local KnightTitanAssault, super = Class(Wave)

local function getStateOwner()
    local battle = Game.battle
    if not battle then return nil end
    for _, enemy in ipairs(battle:getActiveEnemies()) do
        if enemy.ten_shadows_state then
            return enemy
        end
    end
    return nil
end

function KnightTitanAssault:init()
    super.init(self)
    -- Leave enough room for the final telegraphed volley to cross the arena.
    self.time = 7.75
end

function KnightTitanAssault:onStart()
    local enemy = getStateOwner()
    local state = enemy and enemy.ten_shadows_state or nil
    local attack, frozen, domain_started, disrupted

    if state then
        -- Kristal's TP pool is authoritative; mirror it before end-of-Wave upkeep.
        if Game and Game.getTension then state.tp = Game:getTension() end
        if enemy.ten_shadows_role == "titan" then
            state.boss.hp = enemy.health
        end
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

    -- Vessel's ultimate beam begins its one-turn charge at the start of the
    -- defending Wave. The pending target is locked when Vessel selects it.
    if state and state.ultimate_beam and arena then
        local pending = state.ultimate_beam
        local soul = Game.battle.soul
        local arena_x, arena_y = arena.x or 0, arena.y or 0
        local origin_x = arena_x + arena.width * 0.5
        local origin_y = arena_y + arena.height * 0.5
        if soul then
            origin_x = soul.x
            origin_y = soul.y
        end
        local target = pending.target
        local target_x = (target.x or 0) + (target.width or 0) * 0.5
        local target_y = (target.y or 0) + (target.height or 0) * 0.5
        local UltimateBeam = modRequire("scripts/battle/objects/ultimate_beam")
        local visual = UltimateBeam(origin_x, origin_y, target_x, target_y)
        pending.visual = visual
        local parent = Game.battle.addChild and Game.battle
            or (Game.stage and Game.stage.addChild and Game.stage)
        if parent then
            parent:addChild(visual)
        end
    end

    -- Kris's domain is rendered inside the arena mask, below live projectiles.
    -- The Wave owns this object, so it is removed automatically when the
    -- current defending turn ends. The next Wave recreates it while either
    -- the ordinary Chimera duration or the Fusion Domain upkeep remains active.
    local garden_visual = nil
    local vessel_domain_active = state and state.vessel_domain and state.vessel_domain.active
    if state and state.player_domain.active and arena and arena.mask then
        local GardenVisual = modRequire("scripts/battle/objects/chimera_shadow_garden")
        local opening = state.player_domain.visual_pending == true
            or (state.vessel_domain and state.vessel_domain.visual_pending == true)
        state.player_domain.visual_pending = false
        if state.vessel_domain then state.vessel_domain.visual_pending = false end
        garden_visual = GardenVisual(arena.width, arena.height, opening,
            vessel_domain_active or (state.fusion_domain and state.fusion_domain.active or false))
        self:spawnObjectTo(arena.mask, garden_visual, 0, 0)
    elseif vessel_domain_active and arena and arena.mask then
        local VesselBarrier = modRequire("scripts/battle/objects/vessel_domain_barrier")
        local opening = state.vessel_domain.visual_pending == true
        state.vessel_domain.visual_pending = false
        self:spawnObjectTo(arena.mask, VesselBarrier(arena.width, arena.height, opening), 0, 0)
    end

    -- THE ROARING gets a small animated core marker so the two open spokes
    -- are readable before the radial burst reaches the arena edges.
    local roaring_visual = nil
    if attack and attack.id == "black_flash" and arena and arena.mask then
        local RoaringCoreVisual = modRequire("scripts/battle/objects/roaring_core")
        roaring_visual = RoaringCoreVisual(arena.width, arena.height)
        self:spawnObjectTo(arena.mask, roaring_visual, 0, 0)
    end

    if frozen or not attack then
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

        if roaring_visual then
            for _, shot in ipairs(shots) do
                local marker = shot.mechanic
                if marker and marker.kind == "roaring_shard" then
                    roaring_visual:setSafeWedges(
                        marker.safe_wedge,
                        marker.opposite_wedge,
                        marker.rotation
                    )
                    break
                end
            end
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

    local enemy = getStateOwner()
    local state = enemy and enemy.ten_shadows_state or nil
    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")

    -- Per-enemy statuses (for example Divine Dog exposure) must tick on both
    -- battlers. The runtime helper only advances once-per-encounter timers such
    -- as Mahoraga on the first active enemy, so calling it for each target is safe.
    local battle = Game.battle
    local active_enemies = battle and battle.getActiveEnemies
        and battle:getActiveEnemies() or {}
    for _, active_enemy in ipairs(active_enemies) do
        Shadows.onEnemyTurnEnd(active_enemy)
    end

    if state then
        -- Status durations and Domain upkeep are measured in enemy turns,
        -- not individual volleys. Pull the latest TP after grazes, then tick once.
        if Game and Game.getTension then state.tp = Game:getTension() end
        local effects = state:tickEnemyTurnEffects()
        -- Mirror upkeep into the live tension bar so its value matches the rule state.
        if Game and Game.setTension then Game:setTension(state.tp) end
        local charged_beam = effects and effects.ultimate_beam
        if charged_beam then
            local target = charged_beam.target
            local hit = target and target.hurt
                and (type(target.health) ~= "number" or target.health > 0)
            local damage = 0
            if hit then
                damage = charged_beam.damage or 0
                target:hurt(damage, charged_beam.user)
            end
            if charged_beam.visual and charged_beam.visual.release then
                charged_beam.visual:release(hit == true)
            end
            state.last_ultimate_beam = {
                target = target,
                damage = damage,
                hit = hit == true,
            }
        end
    end
end

return KnightTitanAssault
