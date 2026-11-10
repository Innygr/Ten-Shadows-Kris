function Mod:init()
    -- Keep initialization independent of optional/global logging APIs.
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
end
