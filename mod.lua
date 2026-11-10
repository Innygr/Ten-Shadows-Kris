function Mod:init()
    -- Keep initialization independent of optional/global logging APIs.
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end

function Mod:postInit()
    -- mod.json supplies the default party for new saves. Saved games retain
    -- their saved party, so force the full roster here for this runtime test.
    -- Game:load has created Game.world by this point, and battle battlers are
    -- created later from Game.party when an encounter begins.
    Game:setPartyMembers("kris", "susie", "ralsei", "noelle", "berdly")
end
