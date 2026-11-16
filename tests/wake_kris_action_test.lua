local Effects = dofile("scripts/ten_shadows/runtime_spells.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local function character(id, health, xact_name)
    local chara = {id = id, health = health, xact_name = xact_name}
    function chara:getHealth() return self.health end
    function chara:setHealth(value) self.health = value end
    return chara
end

local kris_chara = character("kris", 0, "K-Action")
local kris_battler = {
    chara = kris_chara,
    is_down = true,
    checkHealth = function(self)
        self.is_down = self.chara:getHealth() <= 0
        self.health_checked = true
    end,
    statusMessage = function(self, kind, status, _, force)
        self.status = {kind, status, force}
    end,
}
local susie = {chara = character("susie", 350, "S-Action")}
local ralsei = {chara = character("ralsei", 250, "R-Action")}
local noelle = {chara = character("noelle", 260, "N-Action")}
local berdly = {chara = character("berdly", 310, "B-Action")}
local vessel = {chara = character("vessel", 240, nil)}

Game = {battle = {party = {kris_battler, susie, ralsei, noelle, berdly, vessel}}}

local Actions = dofile("scripts/ten_shadows/wake_kris_actions.lua")
EnemyBattler = {
    getXAction = function(_, battler)
        return battler.chara.xact_name
    end,
}
expect(Actions.install(), true, "Wake Kris X-Action hook installs")
expect(Actions.install(), true, "Wake Kris X-Action hook installs idempotently")

for _, battler in ipairs({susie, ralsei, noelle, berdly, vessel}) do
    expect(EnemyBattler.getXAction({}, battler), "WAKE KRIS",
        battler.chara.id .. " receives Wake Kris while Kris is down")
end
expect(EnemyBattler.getXAction({}, kris_battler), "K-Action",
    "Kris keeps their own X-Action")

-- The original per-character X-Actions return as soon as Kris is standing.
kris_chara.health = 290
kris_battler.is_down = false
expect(EnemyBattler.getXAction({}, susie), "S-Action", "Susie's X-Action is restored")
expect(EnemyBattler.getXAction({}, ralsei), "R-Action", "Ralsei's X-Action is restored")
expect(EnemyBattler.getXAction({}, noelle), "N-Action", "Noelle's X-Action is restored")
expect(EnemyBattler.getXAction({}, berdly), "B-Action", "Berdly's X-Action is restored")

-- The actual battle effect restores Kris at one HP and asks Kristal to refresh
-- the downed battler state and its status message.
kris_chara.health = 0
kris_battler.is_down = true
local restored, reason = Effects.wakeKris()
expect(restored, true, "Wake Kris succeeds while Kris is down")
expect(kris_chara.health, 1, "Wake Kris restores exactly one HP")
expect(kris_battler.is_down, false, "Kristal down state is cleared")
expect(kris_battler.health_checked, true, "Kristal health is refreshed")
expect(kris_battler.status[1], "msg", "Wake Kris status message category")
expect(kris_battler.status[2], "up", "Wake Kris status message")

local already_up, already_up_reason = Effects.wakeKris()
expect(already_up, false, "Wake Kris cannot be spent on a standing Kris")
assert(already_up_reason:find("already standing", 1, true), "standing Kris receives a useful message")
expect(kris_chara.health, 1, "a second Wake Kris cannot add extra HP")

-- The shared boss ACT handler is the live resolution path for both bosses.
modRequire = function(path)
    if path == "scripts/ten_shadows/runtime_spells" then return Effects end
    error("Unexpected Wake Kris dependency: " .. tostring(path))
end
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
kris_chara.health = 0
kris_battler.is_down = true
local act_result = BossActions.onAct({}, susie, "WAKE KRIS", function()
    error("WAKE KRIS must not fall through to the base boss ACT handler")
end)
expect(type(act_result), "table", "WAKE KRIS returns boss ACT dialogue")
expect(kris_chara.health, 1, "boss ACT handler revives the live Kris character")

-- Vessel has no X-Action slot, so the mod supplies the action in its ACT menu.
Mod = {wake_kris_actions = Actions}
dofile("mod.lua")
local target = {}
local battle = {
    party = {kris_battler, vessel},
    current_selecting = 2,
    enemies = {target},
    menu_items = {},
    _getEnemyByIndex = function(_, index)
        expect(index, 1, "Vessel ACT selected enemy index")
        return target
    end,
    clearMenuItems = function(self) self.menu_items = {} end,
    addMenuItem = function(self, item) self.menu_items[#self.menu_items + 1] = item end,
    setState = function(self, state, reason)
        self.state = state
        self.state_reason = reason
    end,
    pushAction = function(self, action, enemy, item)
        self.pushed = {action = action, enemy = enemy, item = item}
    end,
}
Game.battle = battle
kris_chara.health = 0
kris_battler.is_down = true
expect(Mod:onBattleEnemySelect("ACT", 1), true, "Vessel ACT menu is intercepted")
local wake_item
for _, item in ipairs(battle.menu_items) do
    if item.name == "WAKE KRIS" then wake_item = item end
end
assert(wake_item, "Vessel ACT menu must include WAKE KRIS while Kris is down")
wake_item.callback(wake_item)
expect(battle.pushed.action, "ACT", "Vessel queues the Wake Kris ACT")
expect(battle.pushed.enemy, target, "Vessel queues Wake Kris against the selected boss")
expect(battle.pushed.item.name, "WAKE KRIS", "Vessel queues the correct ACT name")

kris_chara.health = 1
kris_battler.is_down = false
battle.menu_items = {}
expect(Mod:onBattleEnemySelect("ACT", 1), true, "Vessel ACT menu remains available")
for _, item in ipairs(battle.menu_items) do
    expect(item.name == "WAKE KRIS", false, "Vessel cannot use Wake Kris while Kris is standing")
end

-- No Kris battler in the party means there is nobody this action can restore.
Game.battle.party = {vessel}
local missing, missing_reason = Effects.wakeKris()
expect(missing, false, "Wake Kris fails safely when Kris is absent")
assert(missing_reason:find("cannot be reached", 1, true), "missing Kris receives a useful message")

print("Wake Kris X-Action replacement, live revival, boss ACT, and Vessel menu tests passed.")
