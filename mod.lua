function Mod:init()
    -- Keep initialization independent of optional/global logging APIs.
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end

function Mod:postInit()
    -- Keep existing saves aligned with the current three-member test roster.
    -- Noelle and Berdly remain defined for later recruitment, but are not
    -- starting party members in this build.
    Game:setPartyMembers("kris", "susie", "ralsei")
end
