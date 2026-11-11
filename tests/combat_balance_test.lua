local CombatState = dofile("scripts/ten_shadows/combat_state.lua")

local function expect(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

expect(CombatState.isEquipmentBlacklisted("thornring"), true, "ThornRing denylist")
expect(CombatState.isEquipmentBlacklisted("THORNRING"), true, "denylist is case-insensitive")
expect(CombatState.isEquipmentBlacklisted("snowring"), false, "unlisted equipment remains allowed")

local state = CombatState.new()
expect(state:getMember("noelle").max_hp, 50, "Noelle combat HP")
expect(state:getMember("berdly").max_hp, 54, "Berdly combat HP")

print("Combat balance and equipment blacklist tests passed.")
