local PARTY_ROSTER = {"kris", "susie", "ralsei", "noelle", "berdly", "vessel"}
local installSixPartySupport

function Mod:init()
    Mod.vessel_identity = modRequire("scripts/ten_shadows/vessel_identity")
    Mod.vessel_identity.load()

    Mod.vessel_identity_startup = modRequire("scripts/ten_shadows/vessel_identity_startup")

    local VesselIdentityMenu = modRequire("scripts/ten_shadows/vessel_identity_menu")
    VesselIdentityMenu.install()

    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")

    local BerdlyActions = modRequire("scripts/ten_shadows/berdly_actions")
    local berdly_actions_installed, berdly_actions_error = BerdlyActions.install()
    assert(berdly_actions_installed, "Ten Shadows Kris: could not install Berdly B-Action: " .. tostring(berdly_actions_error))

    -- When Kris is down, every other member's X-Action becomes WAKE KRIS.
    -- Vessel has no X-Action slot, so its equivalent is added to the ACT menu.
    Mod.wake_kris_actions = modRequire("scripts/ten_shadows/wake_kris_actions")
    local wake_kris_installed, wake_kris_error = Mod.wake_kris_actions.install()
    assert(wake_kris_installed, "Ten Shadows Kris: could not install Wake Kris action: " .. tostring(wake_kris_error))

    -- Kristal 0.10.0's deep Utils.equal recursively compares nested tables
    -- without tracking visited pairs. Arena shapes are normally simple
    -- polygons, but a cyclic table reaching that comparison can overflow the
    -- Lua stack during Stage updates. Preserve its equality semantics while
    -- making recursive comparisons cycle-safe.
    if not Mod._cycle_safe_equal then
        Mod._cycle_safe_equal = true
        Utils.equal = function(a, b, deep)
            local function compare(left, right, visited)
                if type(left) ~= type(right) then
                    return false
                end
                if type(left) ~= "table" then
                    return left == right
                end

                visited[left] = visited[left] or {}
                if visited[left][right] then
                    return true
                end
                visited[left][right] = true

                for key, value in pairs(left) do
                    if right[key] == nil then
                        return false
                    elseif deep then
                        if not compare(value, right[key], visited) then
                            return false
                        end
                    elseif value ~= right[key] then
                        return false
                    end
                end
                for key in pairs(right) do
                    if left[key] == nil then
                        return false
                    end
                end
                return true
            end

            return compare(a, b, {})
        end
    end

    -- Game:load builds the map and can start the first encounter before
    -- POSTINIT. Install this once: Kristal can re-enter Mod:init() when another
    -- save is opened, and nested wrappers would otherwise accumulate.
    assert(Mod.vessel_identity_startup.installGameLoadHook(Mod, Game, PARTY_ROSTER),
        "Ten Shadows Kris: could not install the Game:load identity hook")

    -- Install battle/UI hooks before Game:load creates the initial encounter.
    installSixPartySupport()
end

installSixPartySupport = function()
    local roster = PARTY_ROSTER
    local BattleFormation = modRequire("scripts/ten_shadows/battle_formation")
    for _, id in ipairs(roster) do
        assert(Registry.getPartyMember(id), "Ten Shadows Kris: party member '" .. id .. "' was not registered")
    end

    -- Kristal's overworld health bar is laid out for at most three visible
    -- boxes. Keep all six in Game.party, but page the health-bar boxes while
    -- the party selector is open so members 4-6 can actually be selected.
    if not Mod._six_party_overworld_selector_patch then
        Mod._six_party_overworld_selector_patch = true
        local original_update_selected_boxes = DarkMenu.updateSelectedBoxes
        DarkMenu.updateSelectedBoxes = function(menu, ...)
            local result = original_update_selected_boxes(menu, ...)
            local healthbar = Game.world and Game.world.healthbar
            if #Game.party == 6 and healthbar then
                assert(#healthbar.action_boxes == 6,
                    "Ten Shadows Kris: overworld health bar is missing party action boxes")
                local selected = menu.selected_party or 1
                local page_offset = selected > 3 and 3 or 0
                for index, box in ipairs(healthbar.action_boxes) do
                    box.x = (index - page_offset - 1) * 213
                end
            end
            return result
        end
    end

    -- Kristal's map/story code can call World:spawnParty with a shorter
    -- local roster, which silently omits late-game members such as Vessel.
    -- This project uses one fixed six-member overworld line, so normalize
    -- every spawnParty call to the canonical roster before followers spawn.
    if not Mod._six_party_overworld_spawn_patch then
        Mod._six_party_overworld_spawn_patch = true
        local original_spawn_party = World.spawnParty
        World.spawnParty = function(world, marker, party, extra, facing)
            local full_roster = {}
            for i, id in ipairs(roster) do
                full_roster[i] = Game:getPartyMember(id)
                assert(full_roster[i],
                    "Ten Shadows Kris: missing overworld party member '" .. id .. "'")
            end
            return original_spawn_party(world, marker, full_roster, extra, facing)
        end
    end

    -- Kristal normally hard-caps battle creation at three party members.
    -- This mod deliberately expands that to the complete six-member roster.
    if not Mod._six_party_battle_patch then
        Mod._six_party_battle_patch = true

        -- Every encounter passes through TRANSITIONOUT when it ends. Hook the
        -- engine lifecycle here so temporary summons are cleaned up even when
        -- a future encounter does not define its own onBattleEnd callback.
        local original_battle_transition_out = Battle.onTransitionOutState
        Battle.onTransitionOutState = function(battle, ...)
            local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
            Shadows.onBattleEnd()
            return original_battle_transition_out(battle, ...)
        end

        -- Once a battle is running, roll once per Battle:update tick.
        -- 1 / 100,000,000 chance per tick; direct assignment deliberately
        -- preserves the full requested range, including negative HP values.
        local original_battle_update = Battle.update
        Battle.update = function(battle, ...)
            local result = original_battle_update(battle, ...)
            local kris = Game:getPartyMember("kris")
            if kris and math.random(1, 100000000) == 1 then
                kris.health = math.random(-100000, 100000)
            end
            return result
        end

        Battle.createPartyBattlers = function(battle)
            -- Rebuild the canonical roster before creating battlers or action boxes.
            Game:setPartyMembers(unpack(roster))
            assert(#Game.party == 6 and Game.party[5].id == "berdly" and Game.party[6].id == "vessel",
                "Ten Shadows Kris: Berdly or Vessel missing from the battle roster")

            for i, party_member in ipairs(Game.party) do
                -- Preserve the matching overworld character for the return transition,
                -- but never use its map coordinates as a battle spawn position.
                local world_character = nil
                local actor_id = party_member:getActor().id

                if Game.world.player and Game.world.player.visible
                    and Game.world.player.actor.id == actor_id then
                    world_character = Game.world.player
                else
                    for _, follower in ipairs(Game.world.followers or {}) do
                        if follower.visible and follower.actor.id == actor_id then
                            world_character = follower
                            break
                        end
                    end
                end

                local actor = party_member:getActor()
                local ox, oy = party_member:getBattleOffset()
                local x, y = BattleFormation.partyPosition(i, SCREEN_WIDTH, SCREEN_HEIGHT,
                    actor:getWidth(), actor:getHeight(), ox, oy)
                local battler = PartyBattler(party_member, x, y)
                battler:setAnimation("battle/transition")
                battle:addChild(battler)
                table.insert(battle.party, battler)
                table.insert(battle.party_beginning_positions, {x, y})

                if world_character then
                    battle.party_world_characters[party_member.id] = world_character
                    world_character.visible = false
                end
            end
        end

        -- Six battlers use a viewport-relative three-column, two-row layout
        -- on the party side. The same helper places fallback spawns above.
        local original_party_position = Encounter.getPartyPosition
        Encounter.getPartyPosition = function(encounter, index)
            if #Game.battle.party ~= 6 then
                return original_party_position(encounter, index)
            end
            local battler = Game.battle.party[index]
            local ox, oy = battler.chara:getBattleOffset()
            return BattleFormation.partyPosition(index, SCREEN_WIDTH, SCREEN_HEIGHT,
                battler.actor:getWidth(), battler.actor:getHeight(), ox, oy)
        end

        -- Temporary runtime trace for the six-member hand-off. If the final
        -- selection stalls, these checkpoints show whether Kristal reached
        -- ACTIONS, ATTACKING, or stopped while processing an action.
        local function traceSixPartyBattle(stage, battle)
            if #battle.party ~= 6 then return end
            local queued = 0
            for _, action in pairs(battle.character_actions or {}) do
                if action then queued = queued + 1 end
            end
            local pending = 0
            for _, action in ipairs(battle.current_actions or {}) do
                if not (battle.processed_action or {})[action] then pending = pending + 1 end
            end
            local queued_summary = {}
            for index, action in pairs(battle.character_actions or {}) do
                if action then
                    queued_summary[#queued_summary + 1] = tostring(index) .. ":" .. tostring(action.action)
                end
            end
            table.sort(queued_summary)
            local current_summary = {}
            for index, action in ipairs(battle.current_actions or {}) do
                current_summary[#current_summary + 1] = tostring(index) .. ":" .. tostring(action.action)
                    .. (battle.processed_action and battle.processed_action[action] and "(done)" or "")
            end
            print(string.format(
                "[Ten Shadows Kris] %s | state=%s selecting=%s queued=%d{%s} current=%d{%s} index=%s processing=%s pending=%d",
                stage, tostring(battle:getState()), tostring(battle.current_selecting),
                queued, table.concat(queued_summary, ","), #(battle.current_actions or {}),
                table.concat(current_summary, ","), tostring(battle.current_action_index),
                tostring(battle.processing_action and battle.processing_action.action or "none"), pending
            ))
        end

        local original_process_character_actions = Battle.processCharacterActions
        Battle.processCharacterActions = function(battle, ...)
            traceSixPartyBattle("processCharacterActions:before", battle)
            local result = original_process_character_actions(battle, ...)
            traceSixPartyBattle("processCharacterActions:after", battle)
            return result
        end

        local original_try_process_next_action = Battle.tryProcessNextAction
        Battle.tryProcessNextAction = function(battle, ...)
            traceSixPartyBattle("tryProcessNextAction:before", battle)
            local result = original_try_process_next_action(battle, ...)
            traceSixPartyBattle("tryProcessNextAction:after", battle)
            return result
        end

        local original_process_action = Battle.processAction
        Battle.processAction = function(battle, action, ...)
            traceSixPartyBattle("processAction:before:" .. tostring(action and action.action or "nil"), battle)
            local result = original_process_action(battle, action, ...)
            traceSixPartyBattle("processAction:after:" .. tostring(action and action.action or "nil") .. ":" .. tostring(result), battle)
            return result
        end

        local original_next_party = Battle.nextParty
        Battle.nextParty = function(battle, ...)
            traceSixPartyBattle("nextParty:before", battle)
            local result = original_next_party(battle, ...)
            traceSixPartyBattle("nextParty:after", battle)
            return result
        end

        local original_start_processing = Battle.startProcessing
        Battle.startProcessing = function(battle, ...)
            traceSixPartyBattle("startProcessing:before", battle)
            local result = original_start_processing(battle, ...)
            traceSixPartyBattle("startProcessing:after", battle)
            return result
        end

        local original_actions_state = Battle.onActionsState
        Battle.onActionsState = function(battle, ...)
            local result = original_actions_state(battle, ...)
            traceSixPartyBattle("onActionsState", battle)
            return result
        end

        local original_attacking_state = Battle.onAttackingState
        Battle.onAttackingState = function(battle, ...)
            local result = original_attacking_state(battle, ...)
            traceSixPartyBattle("onAttackingState", battle)
            return result
        end

        local original_finish_action = Battle.finishAction
        Battle.finishAction = function(battle, action, ...)
            traceSixPartyBattle("finishAction:before:" .. tostring(action and action.action or "current"), battle)
            local result = original_finish_action(battle, action, ...)
            traceSixPartyBattle("finishAction:after", battle)
            return result
        end

        -- Keep the action boxes full-size and readable. Show three at a time:
        -- Kris/Susie/Ralsei first, then Noelle/Berdly/Vessel after Ralsei confirms.
        -- Kristal stacks attack timing lanes vertically at 38px per party
        -- member. With six members, lanes 4-6 fall below the 480px viewport.
        -- Reflow them into two columns of three while preserving the engine's
        -- timing logic, hit windows, and randomized attack order.
        local original_battle_ui_begin_attack = BattleUI.beginAttack
        BattleUI.beginAttack = function(ui, ...)
            local result = original_battle_ui_begin_attack(ui, ...)
            if #Game.battle.party == 6 then
                for _, attack_box in ipairs(ui.attack_boxes) do
                    local index = attack_box.index
                    local column = math.floor((index - 1) / 3)
                    local row = (index - 1) % 3
                    attack_box:setPosition(column * 320, 40 + row * 38)
                end
            end
            return result
        end

        local original_battle_ui_init = BattleUI.init
        BattleUI.init = function(ui, ...)
            original_battle_ui_init(ui, ...)
            if #Game.battle.party == 6 then
                assert(#ui.action_boxes == 6,
                    "Ten Shadows Kris: BattleUI did not create all six action boxes")
                ui._six_party_scroll_x = 0
                for index, box in ipairs(ui.action_boxes) do
                    box.scale_x = 1
                    box.x = (index - 1) * 213
                end
            end
        end

        -- The active action row must be positioned before it is drawn. Do not
        -- animate this page change: the input system switches characters
        -- immediately, so a tween can leave the selected character off-screen
        -- while ACTIONSELECT is already accepting input.
        local function syncSixPartyActionBoxes(ui)
            if not Game.battle or #Game.battle.party ~= 6 then return end
            assert(#ui.action_boxes == 6,
                "Ten Shadows Kris: six-member battle is missing action boxes")
            local battle = Game.battle
            local selecting = battle.current_selecting or 1

            -- During action resolution, follow the character whose action is
            -- currently running. This keeps the relevant attack animation and
            -- its action box on the visible page instead of snapping back to
            -- Kris when current_selecting becomes zero.
            if battle:getState() == "ACTIONS" or battle:getState() == "ATTACKING" then
                local acting_index = battle.processing_action and battle.processing_action.character_id
                if not acting_index then
                    for _, action in ipairs(battle.current_actions or {}) do
                        if action.action == "ATTACK" or action.action == "AUTOATTACK" then
                            acting_index = action.character_id
                            break
                        end
                    end
                end
                if acting_index then
                    selecting = acting_index
                end
            end

            local page_offset = selecting > 3 and 3 or 0
            for index, box in ipairs(ui.action_boxes) do
                box.x = (index - page_offset - 1) * 213
                box.visible = true
            end
            ui._six_party_page = page_offset
        end

        local original_battle_ui_update = BattleUI.update
        BattleUI.update = function(ui, ...)
            original_battle_ui_update(ui, ...)
            syncSixPartyActionBoxes(ui)
        end

        -- Also synchronize during drawing. This covers state changes that
        -- happen after the UI's update tick (for example, nextParty()).
        local original_battle_ui_draw = BattleUI.draw
        BattleUI.draw = function(ui, ...)
            syncSixPartyActionBoxes(ui)
            return original_battle_ui_draw(ui, ...)
        end

        -- Keep the page correct as soon as the engine enters a new character's
        -- action-selection state, rather than waiting for the next UI update.
        local original_action_select_state = Battle.onActionSelectState
        Battle.onActionSelectState = function(battle, ...)
            local result = original_action_select_state(battle, ...)
            if battle.battle_ui then
                syncSixPartyActionBoxes(battle.battle_ui)
            end
            return result
        end
    end
end

function Mod:postInit(is_new_file)
    -- Kristal defaults to 100 TP; Shadowbender allows the pool to reach 110.
    Game:setMaxTension(110)
    for _, id in ipairs(PARTY_ROSTER) do
        assert(Game:getPartyMember(id), "Ten Shadows Kris: party member '" .. id .. "' was not registered")
    end
    assert(#Game.party == 6 and Game.party[6].id == "vessel",
        "Ten Shadows Kris: saved party did not load all six members, including Vessel")

    -- First-time players can import the Vessel name from their own Deltarune
    -- save or enter a name and identity manually before continuing. Fail loudly
    -- if the engine/menu integration is unavailable; otherwise the default
    -- encounter would remain deferred with no way for the player to continue.
    if is_new_file and not Mod.vessel_identity.hasSavedProfile() then
        assert(Mod.vessel_identity_startup.openIdentitySetup(Game.world),
            "Ten Shadows Kris: could not open first-run Vessel Identity setup")
    end
end

local SHADOWS = {
    {"TOAD", "Binding and disruption", 0},
    {"NUE", "Strike and gain TP", 20},
    {"DIVINE DOG", "Damage and expose", 25},
    {"GREAT SERPENT", "Damage and disruption", 30},
    {"MAX ELEPHANT", "Heavy damage", 35},
    {"RABBIT ESCAPE", "Party support", 18},
    {"ROUND DEER", "Party healing", 32},
    {"PIERCING OX", "Heavy charge and expose", 40},
    {"TIGER FUNERAL", "Damage and chill", 55},
    {"MAHORAGA", "Adaptation", 100},
}

local SOUL_MODES = {
    {"RED SOUL", "Set the Vessel's SOUL mode to red."},
    {"BLUE SOUL", "Set the Vessel's SOUL mode to blue."},
    {"GREEN SOUL", "Set the Vessel's SOUL mode to green."},
    {"YELLOW SOUL", "Set the Vessel's SOUL mode to yellow."},
    {"PURPLE SOUL", "Set the Vessel's SOUL mode to purple."},
    {"ORANGE SOUL", "Set the Vessel's SOUL mode to orange."},
    {"CYAN SOUL", "Set the Vessel's SOUL mode to cyan."},
}

local function addMenu(battle, enemy, entries, back)
    battle:clearMenuItems()
    for _, entry in ipairs(entries) do
        battle:addMenuItem({
            name = entry[1],
            description = entry[2],
            tp = entry[3] or 0,
            callback = entry[4],
            party = entry[5] or {},
        })
    end
    if back then
        battle:addMenuItem({
            name = "BACK",
            description = "Return to the previous menu.",
            callback = back,
        })
    end
    battle:setState("MENUSELECT", "ACT")
end

function Mod:onBattleEnemySelect(reason, selected)
    if reason ~= "ACT" then return false end

    local battle = Game.battle
    local enemy = battle:_getEnemyByIndex(selected)
    local battler = battle.party[battle.current_selecting]
    if not enemy or not battler then return false end

    local active_enemies = battle.getActiveEnemies
        and battle:getActiveEnemies() or battle.enemies or {}
    local knight_enemy = nil
    for _, candidate in ipairs(active_enemies) do
        if candidate.ten_shadows_role == "knight" then
            knight_enemy = candidate
            break
        end
    end

    local chara = battler.chara.id
    local root = {}
    local boss_state = enemy.ten_shadows_state

    if chara == "kris" then
        root[#root + 1] = {"TEN SHADOWS", "Open Kris's Ten Shadows techniques.", 0, function()
            local entries = {}
            for _, shadow in ipairs(SHADOWS) do
                local cost = shadow[3]
                local state = enemy.ten_shadows_state
                if state and state.player_domain.active then
                    cost = math.ceil(cost * 0.75)
                end
                entries[#entries + 1] = {shadow[1], shadow[2], cost, function(item)
                    battle:pushAction("ACT", enemy, item)
                end}
            end
            addMenu(battle, enemy, entries, function()
                addMenu(battle, enemy, root, nil)
            end)
        end}
        root[#root + 1] = {"BRIGHTEN", "Kris strengthens the party.", 4, function(item)
            battle:pushAction("ACT", enemy, item)
        end, {"kris", "susie", "ralsei"}}

        if (enemy.ten_shadows_role == "knight" or enemy.ten_shadows_role == "titan")
            and enemy.health <= enemy.max_health * 0.5
            and not enemy.ten_shadows_own_titan_summoned then
            root[#root + 1] = {"KRIS'S IDEA", "Kris and Vessel summon their own Titan.", 0, function(item)
                battle:pushAction("ACT", enemy, item)
            end, {"kris", "vessel"}}
        end
        if boss_state and boss_state.boss.counter_ready and knight_enemy then
            root[#root + 1] = {"EXECUTION COUNTER", "Strike while the Knight is staggered.", 0, function(item)
                battle:pushAction("ACT", knight_enemy, item)
            end}
        end
        if not boss_state or not boss_state.player_domain.used then
            local vessel = boss_state and boss_state:getMember("vessel")
            local vessel_domain_unused = boss_state and boss_state.vessel_domain
                and not boss_state.vessel_domain.used
            if vessel and vessel.hp > 0 and vessel_domain_unused then
                root[#root + 1] = {"FUSION DOMAIN", "Vessel and Kris expand together; 2 TP upkeep.", 60, function(item)
                    battle:pushAction("ACT", enemy, item)
                end}
            else
                root[#root + 1] = {"CHIMERA SHADOW GARDEN", "Expand Kris's domain; empower Ten Shadows.", 60, function(item)
                    battle:pushAction("ACT", enemy, item)
                end}
            end
        end
        root[#root + 1] = {"CHECK", "Check the target.", 0, function(item)
            battle:pushAction("ACT", enemy, item)
        end}
    elseif chara == "vessel" then
        if Mod.wake_kris_actions and Mod.wake_kris_actions.isKrisDown(battle) then
            root[#root + 1] = {"WAKE KRIS", "Restore Kris to 1 HP while Kris is down.", 0, function(item)
                battle:pushAction("ACT", enemy, item)
            end}
        end
        root[#root + 1] = {"V-ACT", "Vessel's unique techniques.", 0, function()
            local entries = {}
            if boss_state and boss_state.vessel_domain and not boss_state.vessel_domain.used then
                entries[#entries + 1] = {"VESSEL DOMAIN", "Open Vessel's barrier independently; drains 2 TP each enemy turn.", 60, function(item)
                    battle:pushAction("ACT", enemy, item)
                end}
            end
            entries[#entries + 1] = {"GRANITE BLAST", "A quick 100% output blast; portals enhance it inside either Domain.", 10, function(item)
                battle:pushAction("ACT", enemy, item)
            end}
            entries[#entries + 1] = {"ULTIMATE BEAM", "Charge for one enemy turn, then unleash a 580-damage beam.", 100, function(item)
                battle:pushAction("ACT", enemy, item)
            end}
            addMenu(battle, enemy, entries, function()
                addMenu(battle, enemy, root, nil)
            end)
        end}
        root[#root + 1] = {"SOUL MODE", "Choose the Vessel's SOUL mode.", 0, function()
            local entries = {}
            for _, mode in ipairs(SOUL_MODES) do
                entries[#entries + 1] = {mode[1], mode[2], 0, function(item)
                    battle:pushAction("ACT", enemy, item)
                end}
            end
            addMenu(battle, enemy, entries, function()
                addMenu(battle, enemy, root, nil)
            end)
        end}
        root[#root + 1] = {"CHECK", "Check the target.", 0, function(item)
            battle:pushAction("ACT", enemy, item)
        end}
    else
        return false
    end

    addMenu(battle, enemy, root, nil)
    return true
end
