-- Domain visuals should be persistent objects, not recreated every Wave tick.
local created = {garden = 0, vessel = 0}
local function makeVisual(kind)
    return function(width, height, opening, fusion)
        created[kind] = created[kind] + 1
        local visual = {
            kind = kind, width = width, height = height,
            opening = opening == true, fusion_barrier = fusion == true,
            removed = false, remove_count = 0,
        }
        function visual:remove()
            self.removed = true
            self.remove_count = self.remove_count + 1
        end
        function visual:setFusionBarrier(active)
            self.fusion_barrier = active == true
        end
        return visual
    end
end
modRequire = function(path)
    if path == "scripts/battle/objects/chimera_shadow_garden" then
        return makeVisual("garden")
    elseif path == "scripts/battle/objects/vessel_domain_barrier" then
        return makeVisual("vessel")
    end
    error("Unexpected Domain visual module: " .. tostring(path))
end
local added = {}
local battle = {
    arena = {
        width = 180, height = 142,
        mask = {addChild = function(_, child) added[#added + 1] = child end},
    },
}
local state = {
    player_domain = {active = true, visual_pending = true},
    vessel_domain = {active = false, visual_pending = false},
    fusion_domain = {active = false},
}
local Abilities = dofile("scripts/ten_shadows/battle_abilities.lua")
assert(Abilities.refreshDomainVisual(battle, state), "initial garden should spawn")
local garden = battle.ten_shadows_domain_visual
assert(garden and garden.kind == "garden" and garden.opening,
    "the initial garden should consume its one-time opening flag")
assert(Abilities.refreshDomainVisual(battle, state), "active garden should refresh")
assert(battle.ten_shadows_domain_visual == garden and not garden.removed,
    "Wave refreshes must preserve the live garden animation")
assert(created.garden == 1 and #added == 1,
    "repeated refreshes must not spawn duplicate garden objects")

state.fusion_domain.active = true
state.vessel_domain.active = true
assert(Abilities.refreshDomainVisual(battle, state), "Fusion Domain should refresh")
assert(battle.ten_shadows_domain_visual == garden and garden.fusion_barrier,
    "Fusion should update the existing garden with Vessel's enclosing barrier")
assert(created.garden == 1,
    "Fusion activation must not replace and restart the garden")

state.player_domain.active = false
state.fusion_domain.active = false
state.vessel_domain.visual_pending = false
assert(Abilities.refreshDomainVisual(battle, state), "remaining Vessel barrier should refresh")
local barrier = battle.ten_shadows_domain_visual
assert(barrier and barrier.kind == "vessel" and barrier.opening,
    "switching to the standalone barrier should show its transition")
assert(garden.removed and garden.remove_count == 1,
    "switching visual types should remove the old garden exactly once")
assert(Abilities.refreshDomainVisual(battle, state), "standalone barrier should refresh")
assert(battle.ten_shadows_domain_visual == barrier and not barrier.removed,
    "Wave refreshes must preserve the standalone barrier animation")
assert(created.vessel == 1, "repeated refreshes must not duplicate barrier objects")

state.vessel_domain.active = false
assert(Abilities.refreshDomainVisual(battle, state), "Domain cleanup should refresh")
assert(barrier.removed and battle.ten_shadows_domain_visual == nil
    and battle.ten_shadows_domain_visual_kind == nil,
    "ending every Domain should remove and forget the active visual")
print("Domain visual lifecycle and persistent animation tests passed.")
