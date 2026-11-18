-- Shared ACT handling for the coordinated Knight + Titan encounter.
-- The selected EnemyBattler remains the target, so attacks always reduce that
-- boss's independent health pool, including when only one survivor remains.
local BossActions = {}

local function isGasterFight(enemy)
    return enemy ~= nil and enemy.ten_shadows_gaster_encounter == true
end

local function addGasterMercy(enemy, amount)
    if not isGasterFight(enemy) or amount <= 0 then
        return
    end
    if enemy.addMercy then
        enemy:addMercy(amount)
    else
        enemy.mercy = math.min(100, math.max(0, (enemy.mercy or 0) + amount))
    end
end

local SOUL_MODE_ACTIONS = {
    ["RED SOUL"] = "red", -- Red restores the ordinary attack pool.
    ["BLUE SOUL"] = "blue",
    ["GREEN SOUL"] = "green",
    ["YELLOW SOUL"] = "yellow",
    ["PURPLE SOUL"] = "purple",
    ["ORANGE SOUL"] = "orange",
    ["CYAN SOUL"] = "cyan",
}

function BossActions.onAct(enemy, battler, name, base_on_act)
    -- Safe no-op used by the character ACT fallback. It intentionally
    -- resolves as a normal ACT so Kristal can advance the six-member queue.
    if name == "Nothing Happens" then
        return "* Nothing happens."
    end

    -- Susie's S-Action is Kristal's default X-Action. The character's
    -- xact_name controls the menu label ("S-Action"), while EnemyBattler's
    -- getXAction supplies the resolved name ("Standard"). Boss enemies route
    -- X-Actions through this handler, so return battle text for both names.
    if battler and battler.chara and battler.chara.id == "susie"
        and (name == "Standard" or name == "S-Action") then
        if isGasterFight(enemy) then
            return "* SUSIE: He looks like he hasn't slept in a thousand years."
        end
        return "* SUSIE swings her axe with all her strength!"
    end

    -- Character X-Actions are shown with custom labels in the party UI,
    -- but custom enemy classes call this handler directly instead of the
    -- base EnemyBattler:onAct implementation. Resolve all three here too.
    local character_id = battler and battler.chara and battler.chara.id
    if character_id == "vessel" and (name == "V-Act" or name == "Standard") then
        if Game and Game.giveTension then Game:giveTension(8) end
        if isGasterFight(enemy) then
            addGasterMercy(enemy, 5)
            return "* VESSEL: Gaster is green! (+5% MERCY, +8 TP)"
        end
        return "* VESSEL steadies the SOUL. (+8 TP)"
    end
    if character_id == "berdly" and (name == "B-Action" or name == "Standard") then
        local BerdlyActions = modRequire("scripts/ten_shadows/berdly_actions")
        local result = BerdlyActions.perform(enemy, battler)
        if isGasterFight(enemy) then
            addGasterMercy(enemy, 15)
            return {
                "* (BERDLY's theory makes a little sense. +15% MERCY)",
                "* BERDLY: I HAVE A THEORY!",
                "* GASTER IS GREEN because... well, look at him!",
                "* BERDLY: I will require further research.",
            }
        end
        return result
    elseif character_id == "ralsei" and (name == "R-Action" or name == "Standard") then
        if Game and Game.giveTension then Game:giveTension(8) end
        if isGasterFight(enemy) then
            addGasterMercy(enemy, 20)
            return "* RALSEI: Perhaps we should ask him why he looks like that. (+20% MERCY, +8 TP)"
        end
        return "* RALSEI offers a reassuring smile. (+8 TP)"
    elseif character_id == "noelle" and (name == "N-Action" or name == "Standard") then
        if enemy then
            enemy.ten_shadows_exposed_turns = math.max(enemy.ten_shadows_exposed_turns or 0, 1)
        end
        if isGasterFight(enemy) then
            addGasterMercy(enemy, 15)
            return "* NOELLE: Is green his natural colour? His guard is exposed. (+15% MERCY)"
        end
        return "* NOELLE focuses her magic. The target's guard is exposed."
    end

    if name == "Inspect" or name == "Check" or name == "CHECK" then
        return enemy:getCheckText(battler)
    end

    if name == "KRIS'S IDEA" then
        if not battler or not battler.chara
            or (battler.chara.id ~= "kris" and battler.chara.id ~= "vessel") then
            return "* This idea needs both Kris and Vessel."
        end
        local kris_battler, vessel_battler = nil, nil
        for _, ally in ipairs(Game and Game.battle and Game.battle.party or {}) do
            local chara = ally and ally.chara
            if chara and chara.id == "kris" then
                kris_battler = ally
            elseif chara and chara.id == "vessel" then
                vessel_battler = ally
            end
        end
        local function isStanding(ally)
            if not ally or ally.is_down then return false end
            local chara = ally.chara
            local hp = chara and (chara.getHealth and chara:getHealth() or chara.health) or 0
            return hp > 0
        end
        if not isStanding(kris_battler) or not isStanding(vessel_battler) then
            return "* Kris and Vessel both need to be standing for this idea."
        end
        if enemy.ten_shadows_own_titan_summoned then
            return "* Their Titan has already answered the call."
        end
        if enemy.health > enemy.max_health * 0.5 then
            return "* Kris is still working on the idea..."
        end
        enemy.ten_shadows_own_titan_summoned = true
        enemy:hurt(1100, kris_battler)
        local battle = Game and Game.battle
        local arena = battle and battle.arena
        if arena and arena.mask then
            local Visual = modRequire("scripts/battle/objects/summoned_titan_visual")
            arena.mask:addChild(Visual(arena.width, arena.height))
        end
        return {
            "* KRIS HAS AN IDEA.",
             "* A Dark World reflects the values of its maker.",
            "* RALSEI: NO, KRIS! DON'T SUMMON A TITAN!",
            "* VESSEL: dw bruh, I will GRANITE BLASTA it when we don't need it anymore.",
            "* Vessel joins Kris, and their own Titan answers the call.",
            "* The shadow Titan strikes for 1,100 damage!",
        }
    end

    if name == "WAKE KRIS" then
        local Effects = modRequire("scripts/ten_shadows/runtime_spells")
        local restored, reason = Effects.wakeKris()
        if not restored then
            return "* " .. tostring(reason or "Kris cannot be woken right now.")
        end
        return {
            "* The party calls Kris back to their feet!",
            "* Kris returns with 1 HP.",
        }
    end

    local battle = Game and Game.battle
    local state = enemy.ten_shadows_state
    local Abilities = nil
    if not state then
        Abilities = modRequire("scripts/ten_shadows/battle_abilities")
        state = Abilities.get(battle)
        if state then Abilities.syncParty(battle, state) end
    end
    if name == "BRIGHTEN" then
        local Effects = modRequire("scripts/ten_shadows/runtime_spells")
        -- The menu has already charged 4 TP and grouped Kris, Susie, and Ralsei
        -- into this ACT. Resolve the buff here; powerAct would queue a second
        -- SPELL action while the current ACT group is still being processed.
        return Effects.brightenAct(state)
    end

    if name == "VESSEL DOMAIN" then
        if not state or not state:expandVesselDomain(true) then
            return "* Vessel cannot form the Domain right now."
        end
        if not enemy.ten_shadows_state then Abilities.refreshDomainVisual(battle, state) end
        return {
            "* DOMAIN EXPANSION — VESSEL'S BARRIER.",
            "* The battlefield is sealed inside Vessel's Domain.",
            "* Its portals can redirect Vessel's Granite Blast.",
        }
    end

    if name == "FUSION DOMAIN" then
        if not state or not state:expandFusionDomain(true) then
            return "* Kris and Vessel cannot complete the Domain right now."
        end
        if not enemy.ten_shadows_state then Abilities.refreshDomainVisual(battle, state) end
        return {
            "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.",
            "* Vessel closes the barrier as Kris floods it with shadows.",
            "* Shadow portals can redirect party spells anywhere inside the Domain.",
            "* Granite Blast can emerge from anywhere within the garden.",
        }
    end

    if name == "CHIMERA SHADOW GARDEN" then
        if not state or not state:expandChimeraDomain(true) then
            return "* The shadows cannot form the domain again."
        end
        if not enemy.ten_shadows_state then Abilities.refreshDomainVisual(battle, state) end
        return {
            "* DOMAIN EXPANSION — CHIMERA SHADOW GARDEN.",
            "* The battlefield sinks into a sea of shadows. Ten Shadows are empowered.",
        }
    end

    if name == "GRANITE BLAST" then
        local battle = Game and Game.battle
        local arena = battle and battle.arena
        if not battler or not battler.chara or battler.chara.id ~= "vessel" then
            return "* Only Vessel can shape Granite Blast."
        end
        if not state then
            return "* Vessel's Granite Blast is unavailable."
        end

        -- Always take the shot. If Kristal has no active arena (or a target
        -- sprite has incomplete bounds), use a safe screen-space fallback
        -- instead of telling the player that no path could be found.
        local soul = battle and battle.soul
        local arena_width = arena and arena.width or 142
        local arena_height = arena and arena.height or 142
        local arena_x, arena_y = arena and arena.x or 0, arena and arena.y or 0
        local origin_x = arena_width * 0.5
        local origin_y = arena_height * 0.5
        if soul then
            origin_x = math.max(8, math.min(arena_width - 8, soul.x - arena_x))
            origin_y = math.max(8, math.min(arena_height - 8, soul.y - arena_y))
        end

        local target = {
            x = ((enemy and enemy.x) or arena_x + arena_width * 0.5)
                - arena_x + ((enemy and enemy.width) or 0) * 0.5,
            y = ((enemy and enemy.y) or arena_y + arena_height * 0.5)
                - arena_y + ((enemy and enemy.height) or 0) * 0.5,
        }
        local descriptor = state:createGraniteBlast(
            {x = origin_x, y = origin_y}, target, 1
        )
        if not descriptor then
            descriptor = {
                kind = "granite_blast", source = "vessel",
                origin_x = origin_x, origin_y = origin_y,
                target_x = target.x, target_y = target.y,
                output = 1, redirected_by_shadow_portal = false,
            }
        end

        local entry = {x = origin_x, y = origin_y}
        local routed = descriptor
        if (state.fusion_domain and state.fusion_domain.active)
            or (state.vessel_domain and state.vessel_domain.active) then
            entry = {
                x = math.max(8, math.min(arena_width - 8, arena_width - origin_x)),
                y = math.max(8, math.min(arena_height - 8, arena_height - origin_y)),
            }
            routed, reason = state:routePartySpell(descriptor, entry, {
                x = origin_x, y = origin_y,
            })
            if not routed then
                return "* " .. tostring(reason or "The shadow portals could not connect.")
            end
        end

        local damage = math.floor(58 * routed.output + 0.5)
        enemy:hurt(damage, battler)

        -- The visual is presentation only; the ACT above applies the hit once.
        if arena then
            local GraniteBlast = modRequire("scripts/battle/objects/granite_blast")
            local visual = GraniteBlast(
                arena_x + entry.x, arena_y + entry.y,
                arena_x + routed.origin_x, arena_y + routed.origin_y,
                arena_x + routed.target_x, arena_y + routed.target_y, routed.output
            )
            local parent = battle.addChild and battle or (Game.stage and Game.stage.addChild and Game.stage)
            if parent then parent:addChild(visual) end
        end

        if routed.redirected_by_shadow_portal then
            return {
                "* VESSEL FIRES GRANITE BLAST THROUGH THE SHADOW PORTALS!",
                "* The 100% output blast deals " .. tostring(damage) .. " damage.",
            }
        end
        return {
            "* VESSEL FIRES GRANITE BLAST!",
            "* The 100% output blast deals " .. tostring(damage) .. " damage.",
        }
    end

    if name == "ULTIMATE BEAM" then
        if not battler or not battler.chara or battler.chara.id ~= "vessel" then
            return "* Only Vessel can charge the ultimate beam."
        end
        if not state then
            return "* Vessel cannot reach the ultimate beam's charge state."
        end
        local started, reason = state:beginUltimateBeam(enemy, battler)
        if not started then
            return "* " .. tostring(reason or "The ultimate beam cannot charge right now.")
        end
        return {
            "* VESSEL BEGINS CHARGING THE ULTIMATE BEAM.",
            "* The beam will release after one full enemy turn.",
        }
    end

    local soul_mode = SOUL_MODE_ACTIONS[name]
    if soul_mode then
        if not state then
            return "* The Vessel's SOUL cannot reach the shared battle state."
        end
        local changed, reason = state:setSoulMode(soul_mode)
        if not changed then return "* " .. tostring(reason) end

        -- Replace the live battle Soul immediately; setting the scheduler flag
        -- alone would leave the old movement/input controller active.
        local battle = Game and Game.battle
        local old_soul = battle and battle.soul
        if battle and old_soul and battle.encounter and battle.swapSoul then
            local x, y = old_soul:getExactPosition()
            local replacement = battle.encounter:createSoul(x, y)
            replacement.inv_flash_timer = old_soul.inv_flash_timer or 0
            replacement.can_move = old_soul.can_move
            battle:swapSoul(replacement)
            -- Battle:swapSoul uses the integer position; restore fractional
            -- movement coordinates so a mode change cannot snap the SOUL.
            if replacement.setExactPosition then
                replacement:setExactPosition(x, y)
            end
        end
        return "* The Vessel shifts to " .. string.upper(soul_mode) .. " SOUL. The Knight and Titan adapt."
    end

    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    local shadow_message = Shadows.use(name, battler, enemy)
    if shadow_message then return shadow_message end

    return base_on_act(enemy, battler, name)
end

return BossActions
