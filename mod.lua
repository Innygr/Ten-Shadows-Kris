function Mod:init()
    -- Keep initialization independent of optional/global logging APIs.
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end

function Mod:postInit()
    -- This event runs after Game:load and before the player can enter an encounter.
    -- Set the full five-member test roster here: Battle:createPartyBattlers()
    -- copies Game.party before Encounter:onBattleInit() is called.
    Game:setPartyMembers("kris", "susie", "ralsei", "noelle", "berdly")
end
