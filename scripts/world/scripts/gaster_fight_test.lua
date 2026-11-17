return function(event, player, facing)
    Game.world:startCutscene(function(cutscene)
        cutscene:text({"* Gaster Fight Test", "* This station is ready, but the Gaster encounter has not been implemented yet."})
    end)
end
