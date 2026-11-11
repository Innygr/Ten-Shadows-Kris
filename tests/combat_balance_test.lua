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
expect(state:getMember("kris").max_hp, 240, "Kris late-game HP")
expect(state:getMember("susie").max_hp, 290, "Susie late-game HP")
expect(state:getMember("ralsei").max_hp, 210, "Ralsei late-game HP")
expect(state:getMember("noelle").max_hp, 220, "Noelle late-game HP")
expect(state:getMember("berdly").max_hp, 240, "Berdly late-game HP")

print("Late-game party balance and equipment blacklist tests passed.")
