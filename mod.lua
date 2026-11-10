function Mod:init()
    Mod.logger = Logger("Ten Shadows Kris")
    Mod.flavor_text = modRequire("scripts/ten_shadows/flavor_text")
    Mod.logger:info("Ten Shadows Kris runtime initialized.")
    Mod.logger:info("Flavor text registry loaded.")
end
