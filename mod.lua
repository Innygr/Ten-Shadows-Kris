function Mod:init()
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end

function Mod:postInit()
    -- All six characters are present in the encounter party.
    Game:setPartyMembers("kris", "susie", "ralsei", "noelle", "berdly", "vessel")

    -- Kristal normally hard-caps battle creation at three party members.
    -- This mod deliberately expands that to the complete six-member roster.
    if not Mod._six_party_battle_patch then
        Mod._six_party_battle_patch = true

        Battle.createPartyBattlers = function(battle)
            for i = 1, #Game.party do
                local party_member = Game.party[i]
                local created = false

                if Game.world.player and Game.world.player.visible
                    and Game.world.player.actor.id == party_member:getActor().id then
                    local x, y = Game.world.player:getScreenPos()
                    local battler = PartyBattler(party_member, x, y)
                    battler:setAnimation("battle/transition")
                    battle:addChild(battler)
                    table.insert(battle.party, battler)
                    table.insert(battle.party_beginning_positions, {x, y})
                    battle.party_world_characters[party_member.id] = Game.world.player
                    Game.world.player.visible = false
                    created = true
                else
                    for _, follower in ipairs(Game.world.followers) do
                        if follower.visible and follower.actor.id == party_member:getActor().id then
                            local x, y = follower:getScreenPos()
                            local battler = PartyBattler(party_member, x, y)
                            battler:setAnimation("battle/transition")
                            battle:addChild(battler)
                            table.insert(battle.party, battler)
                            table.insert(battle.party_beginning_positions, {x, y})
                            battle.party_world_characters[party_member.id] = follower
                            follower.visible = false
                            created = true
                            break
                        end
                    end
                end

                if not created then
                    local battler = PartyBattler(party_member, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
                    battler:setAnimation("battle/transition")
                    battle:addChild(battler)
                    table.insert(battle.party, battler)
                    table.insert(battle.party_beginning_positions, {battler.x, battler.y})
                end
            end
        end

        -- Six battlers use a compact two-column formation on the party side.
        local original_party_position = Encounter.getPartyPosition
        Encounter.getPartyPosition = function(encounter, index)
            if #Game.battle.party ~= 6 then
                return original_party_position(encounter, index)
            end
            local column = index > 3 and 1 or 0
            local row = (index - 1) % 3
            local battler = Game.battle.party[index]
            local ox, oy = battler.chara:getBattleOffset()
            local x = 36 + (column * 34) + (battler.actor:getWidth() / 2 + ox) * 2
            local y = 30 + (row * 48) + (battler.actor:getHeight() + oy) * 2
            return x, y
        end

        -- Fit all six action boxes across the 640px battle strip.
        local original_battle_ui_init = BattleUI.init
        BattleUI.init = function(ui, ...)
            original_battle_ui_init(ui, ...)
            if #Game.battle.party == 6 then
                local compact_width = 640 / 6
                for index, box in ipairs(ui.action_boxes) do
                    box.scale_x = 0.5
                    box.x = (index - 1) * compact_width
                end
            end
        end
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

    local chara = battler.chara.id
    local root = {}

    if chara == "kris" then
        root[#root + 1] = {"TEN SHADOWS", "Open Kris's Ten Shadows techniques.", 0, function()
            local entries = {}
            for _, shadow in ipairs(SHADOWS) do
                entries[#entries + 1] = {shadow[1], shadow[2], shadow[3], function(item)
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
        root[#root + 1] = {"CHECK", "Check the target.", 0, function(item)
            battle:pushAction("ACT", enemy, item)
        end}
    elseif chara == "vessel" then
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
