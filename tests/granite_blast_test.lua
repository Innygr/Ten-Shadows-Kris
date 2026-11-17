-- Test the live Granite Blast ACT route and its charge/launch effect.
local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

local graphics
graphics = {lines = 0, circles = 0}
love = {
    graphics = {
        push = function() end,
        pop = function() end,
        setColor = function() end,
        setLineWidth = function() end,
        line = function() graphics.lines = graphics.lines + 1 end,
        circle = function() graphics.circles = graphics.circles + 1 end,
    },
}

Object = {}
function Object:init(x, y) self.x, self.y = x or 0, y or 0 end
function Object:update() end
function Object:remove() self.removed = true end
function Object:draw() self.base_draws = (self.base_draws or 0) + 1 end

function Class(base)
    local class = {}
    class.__index = class
    setmetatable(class, {
        __index = base,
        __call = function(ctor, ...)
            local instance = setmetatable({}, ctor)
            instance:init(...)
            return instance
        end,
    })
    return class, base
end

DT = 0.31
local GraniteBlast = dofile("scripts/battle/objects/granite_blast.lua")

local CombatState = dofile("scripts/ten_shadows/combat_state.lua")
local state = CombatState.new()
expect(state:expandFusionDomain(true), true, "test setup activates the Fusion Domain")

local spawned = {}
local battle = {
    arena = {x = 100, y = 200, width = 140, height = 120},
    soul = {x = 124, y = 248},
    addChild = function(self, child)
        spawned[#spawned + 1] = child
        child.parent = self
    end,
}
local target = {
    x = 400, y = 80, width = 20, height = 30,
    hurt = function(self, amount, user)
        self.damage = (self.damage or 0) + amount
        self.last_user = user
    end,
}
local user = {chara = {id = "vessel"}}
Game = {battle = battle}
modRequire = function(path)
    expect(path, "scripts/battle/objects/granite_blast",
        "live Granite Blast loads its presentation object")
    return GraniteBlast
end

target.ten_shadows_state = state
local BossActions = dofile("scripts/ten_shadows/boss_actions.lua")
local result = BossActions.onAct(target, user, "GRANITE BLAST", function()
    error("Granite Blast must not fall through to the engine ACT handler")
end)

expect(type(result), "table", "successful Granite Blast returns battle dialogue")
expect(target.damage, 58, "100% Granite Blast deals 58 damage once")
expect(target.last_user, user, "Granite Blast records Vessel as the attacker")
expect(state.fusion_domain.portal_routes, 1, "live V-ACT increments the real portal route counter")
expect(#spawned, 1, "live V-ACT spawns exactly one visual effect")

local visual = spawned[1]
expect(visual.entry.x, 216, "entry portal is placed opposite the exit")
expect(visual.entry.y, 272, "entry portal uses the mirrored y position")
expect(visual.exit.x, 124, "exit portal follows the active SOUL x position")
expect(visual.exit.y, 248, "exit portal follows the active SOUL y position")
expect(visual.target.x, 410, "blast targets the selected enemy's horizontal centre")
expect(visual.target.y, 95, "blast targets the selected enemy's vertical centre")
visual:update()
expect(visual.fired, true, "the blast enters its launch phase after charging")
visual:draw()
assert(graphics.lines > 0, "the launch phase draws a beam through the exit portal")
assert(graphics.circles > 0, "the blast draws entry, exit, and impact rings")
expect(visual.base_draws, 1, "the visual preserves the base Object draw")
DT = 0.5
visual:update()
expect(visual.removed, true, "the temporary V-ACT visual cleans itself up")

-- Granite Blast remains a direct attack when the Fusion Domain is inactive.
local inactive_state = CombatState.new()
local inactive_target = {
    x = 10, y = 20, width = 20, height = 20,
    hurt = function(self, amount, source) self.damage = (self.damage or 0) + amount; self.last_user = source end,
    ten_shadows_state = inactive_state,
}
local before_spawn = #spawned
local direct = BossActions.onAct(inactive_target, user, "GRANITE BLAST", function()
    error("Granite Blast must not fall through to the engine ACT handler")
end)
expect(type(direct), "table", "Granite Blast succeeds outside the Fusion Domain")
expect(inactive_target.damage, 58, "direct Granite Blast deals its normal 58 damage")
expect(#spawned, before_spawn + 1, "direct Granite Blast still creates its launch visual")
expect(inactive_state.fusion_domain.portal_routes, 0,
    "direct Granite Blast does not consume a portal route")
expect(spawned[#spawned].entry.x, spawned[#spawned].exit.x,
    "direct Granite Blast has no separate portal entry")
expect(spawned[#spawned].entry.y, spawned[#spawned].exit.y,
    "direct Granite Blast launches from its own origin")

-- Exercise the real Vessel ACT menu builder: V-ACT is always present and
-- contains both the 50-TP normal blast and 100-TP one-turn ultimate beam.
local mod_file = assert(io.open("mod.lua", "r"))
local mod_source = mod_file:read("*a")
mod_file:close()
assert(mod_source:find('{"V-ACT"', 1, true),
    "Vessel's V-ACT submenu is always registered")
assert(mod_source:find('{"ULTIMATE BEAM"', 1, true),
    "Vessel's V-ACT submenu contains the ultimate beam")
Mod = {}
dofile("mod.lua")

local function buildVesselMenu(domain_active)
    local target_enemy = {
        ten_shadows_state = {
            fusion_domain = {active = domain_active == true},
            vessel_domain = {active = false, used = false},
            player_domain = {active = false, used = false},
        },
    }
    local battle = {
        party = {{chara = {id = "vessel"}}},
        current_selecting = 1,
        menu_items = {},
        _getEnemyByIndex = function(self, index)
            expect(index, 1, "Vessel ACT targets the selected enemy")
            return target_enemy
        end,
        getActiveEnemies = function()
            return {target_enemy}
        end,
        clearMenuItems = function(self)
            self.menu_items = {}
        end,
        addMenuItem = function(self, item)
            self.menu_items[#self.menu_items + 1] = item
        end,
        setState = function(self, state, menu)
            self.menu_state, self.menu_kind = state, menu
        end,
        pushAction = function(self, action, target, item)
            self.pushed_action = {action = action, target = target, item = item}
        end,
    }
    Game = {battle = battle}
    expect(Mod:onBattleEnemySelect("ACT", 1), true,
        "Vessel ACT menu opens for the selected enemy")
    return battle, target_enemy
end

local function checkVesselMenu(domain_active)
    local battle, target_enemy = buildVesselMenu(domain_active)
    local vact
    for _, item in ipairs(battle.menu_items) do
        if item.name == "V-ACT" then vact = item end
    end
    assert(vact, "V-ACT appears regardless of Fusion Domain state")
    vact.callback()
    local actions = {}
    for _, item in ipairs(battle.menu_items) do actions[item.name] = item end
    assert(actions["VESSEL DOMAIN"], "V-ACT submenu contains independent VESSEL DOMAIN")
    expect(actions["VESSEL DOMAIN"].tp, 60, "Vessel Domain costs 60 TP")
    assert(actions["GRANITE BLAST"], "V-ACT submenu contains GRANITE BLAST")
    assert(actions["ULTIMATE BEAM"], "V-ACT submenu contains ULTIMATE BEAM")
    expect(actions["GRANITE BLAST"].tp, 10, "Granite Blast costs 10 TP")
    expect(actions["ULTIMATE BEAM"].tp, 100, "Ultimate Beam costs 100 TP")
    actions["GRANITE BLAST"].callback(actions["GRANITE BLAST"])
    expect(battle.pushed_action.action, "ACT", "Granite Blast queues an ACT")
    expect(battle.pushed_action.target, target_enemy, "Granite Blast targets the selected boss")
    actions["ULTIMATE BEAM"].callback(actions["ULTIMATE BEAM"])
    expect(battle.pushed_action.item, actions["ULTIMATE BEAM"],
        "Ultimate Beam queues its selected action")
end

checkVesselMenu(false)
checkVesselMenu(true)


print("Granite Blast live routing, damage, visual, and Domain gating tests passed.")
