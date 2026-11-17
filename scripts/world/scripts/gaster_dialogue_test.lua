return function(event, player, facing)
    Game.world:startCutscene(function(cutscene)
        cutscene:text({
            "* You approach the Gaster statue.",
            "* Its expression is impossible to read.",
            "* ...",
            "* A small plaque reads: 'PLEASE DO NOT FEED THE VOID.'",
            "* The statue does not respond.",
            "* Somehow, you feel like you just failed a dialogue test."
        })
    end)
end
