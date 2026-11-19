-- Battle-wide support for Ten Shadows techniques in ordinary encounters.
local Abilities = {}

function Abilities.get(battle)
    battle = battle or (Game and Game.battle)
    if not battle then return nil end
    if not battle.ten_shadows_ability_state then
        local CombatState = modRequire("scripts/ten_shadows/combat_state")
        battle.ten_shadows_ability_state = CombatState.new()
        battle.ten_shadows_ability_state.ten_shadows_general_battle = true
    end
    return battle.ten_shadows_ability_state
end

function Abilities.syncParty(battle, state)
    battle = battle or (Game and Game.battle)
    state = state or Abilities.get(battle)
    if not battle or not state then return false end
    for _, battler in ipairs(battle.party or {}) do
        local chara = battler and battler.chara
        local member = chara and state:getMember(chara.id)
        if member then
            local hp = chara.getHealth and chara:getHealth() or chara.health
            if type(hp) == "number" then member.hp = math.max(0, hp) end
            local max_hp = chara.getStat and chara:getStat("health") or chara.max_health
            if type(max_hp) == "number" and max_hp > 0 then member.max_hp = max_hp end
        end
    end
    if Game and Game.getTension then state.tp = Game:getTension() end
    return true
end

function Abilities.refreshDomainVisual(battle, state)
    battle = battle or (Game and Game.battle)
    state = state or Abilities.get(battle)
    if not battle or not state then return false end
    local arena = battle.arena
    if not arena or not arena.mask then return false end

    local player_active = state.player_domain and state.player_domain.active == true
    local vessel_active = state.vessel_domain and state.vessel_domain.active == true
    local fusion_active = state.fusion_domain and state.fusion_domain.active == true
    local active = player_active or vessel_active or fusion_active
    local previous = battle.ten_shadows_domain_visual
    local previous_kind = battle.ten_shadows_domain_visual_kind

    if not active then
        if previous and previous.remove then previous:remove() end
        battle.ten_shadows_domain_visual = nil
        battle.ten_shadows_domain_visual_kind = nil
        return true
    end

    -- A Fusion Domain is built on the garden visual; a standalone Vessel
    -- Domain uses the six-gate barrier. Preserve the live object between Wave
    -- ticks so its pulse, rotation, and particle animation never restart.
    local desired_kind = (player_active or fusion_active) and "garden" or "vessel"
    local fusion_barrier = fusion_active or vessel_active
    if previous and previous_kind == desired_kind then
        if desired_kind == "garden" and previous.setFusionBarrier then
            previous:setFusionBarrier(fusion_barrier)
        end
        return true
    end

    if previous and previous.remove then previous:remove() end
    battle.ten_shadows_domain_visual = nil
    battle.ten_shadows_domain_visual_kind = nil

    local visual
    if desired_kind == "garden" then
        local Garden = modRequire("scripts/battle/objects/chimera_shadow_garden")
        local opening = player_active and state.player_domain.visual_pending == true
            or (state.vessel_domain and state.vessel_domain.visual_pending == true)
            or previous_kind == "vessel"
        if state.player_domain then state.player_domain.visual_pending = false end
        if state.vessel_domain then state.vessel_domain.visual_pending = false end
        visual = Garden(arena.width or 142, arena.height or 142, opening, fusion_barrier)
    else
        local Barrier = modRequire("scripts/battle/objects/vessel_domain_barrier")
        local opening = (state.vessel_domain and state.vessel_domain.visual_pending == true)
            or previous_kind == "garden"
        state.vessel_domain.visual_pending = false
        visual = Barrier(arena.width or 142, arena.height or 142, opening)
    end
    arena.mask:addChild(visual)
    battle.ten_shadows_domain_visual = visual
    battle.ten_shadows_domain_visual_kind = desired_kind
    return true
end

function Abilities.tickEnemyTurn(battle)
    battle = battle or (Game and Game.battle)
    local state = battle and battle.ten_shadows_ability_state
    if not state or not state.ten_shadows_general_battle then return false end
    Abilities.syncParty(battle, state)
    local result = state:tickEnemyTurnEffects()
    if Game and Game.setTension then Game:setTension(state.tp) end
    if result and result.ultimate_beam then
        local pending = result.ultimate_beam
        local target = pending.target
        local hit = target and target.hurt
            and (type(target.health) ~= "number" or target.health > 0)
        local damage = 0
        if hit then
            damage = pending.damage or 0
            target:hurt(damage, pending.user)
        end
        local arena = battle.arena
        local soul = battle.soul
        local origin_x = soul and soul.x or ((arena and arena.x or 0) + ((arena and arena.width) or 142) * 0.5)
        local origin_y = soul and soul.y or ((arena and arena.y or 0) + ((arena and arena.height) or 142) * 0.5)
        local target_x = (target and target.x or 0) + (target and target.width or 0) * 0.5
        local target_y = (target and target.y or 0) + (target and target.height or 0) * 0.5
        local parent = battle.addChild and battle
            or (Game.stage and Game.stage.addChild and Game.stage)
        if parent then
            local Beam = modRequire("scripts/battle/objects/ultimate_beam")
            local visual = Beam(origin_x, origin_y, target_x, target_y)
            parent:addChild(visual)
            visual:release(hit == true)
        end
        state.last_ultimate_beam = {target = target, damage = damage, hit = hit == true}
    end
    Abilities.refreshDomainVisual(battle, state)
    return result
end

function Abilities.endBattle(battle)
    battle = battle or (Game and Game.battle)
    if not battle then return end
    local visual = battle.ten_shadows_domain_visual
    if visual and visual.remove then visual:remove() end
    battle.ten_shadows_domain_visual = nil
    battle.ten_shadows_ability_state = nil
end

return Abilities
