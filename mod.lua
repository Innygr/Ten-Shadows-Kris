function Mod:init()
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end

function Mod:postInit()
    -- All six characters are present in the encounter party.
    Game:setPartyMembers("kris", "susie", "ralsei", "noelle", "berdly", "vessel")
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
            item.party = {"kris", "susie", "ralsei"}
            battle:pushAction("ACT", enemy, item)
        end}
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
