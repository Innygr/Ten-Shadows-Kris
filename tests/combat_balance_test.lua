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
expect(#state.party, 6, "all six party members are active")
expect(state.party[1].id, "kris", "Kris is first in party")
expect(state.party[2].id, "susie", "Susie is second in party")
expect(state.party[3].id, "ralsei", "Ralsei is third in party")
expect(state:getMember("kris").max_hp, 290, "Kris late-game HP")
expect(state:getMember("susie").max_hp, 350, "Susie late-game HP")
expect(state:getMember("ralsei").max_hp, 250, "Ralsei late-game HP")
expect(state:getMember("noelle").max_hp, 260, "Noelle late-game HP")
expect(state:getMember("berdly").max_hp, 310, "Berdly late-game HP")
expect(state:getMember("vessel").max_hp, 240, "Vessel HP")
expect(#CombatState.RESERVE_PARTY, 0, "all playable characters are in the active roster")

print("Six-member party balance and equipment blacklist tests passed.")
