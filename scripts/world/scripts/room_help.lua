return function(event, player, facing)
    Game.world:startCutscene(function(cutscene)
        cutscene:text({
            "* FIELD GUIDE",
            "* Welcome to the Shadowbender test room.",
            "* Move around the room and interact with a station to run its test.",
            "* GASTER FIGHT TEST opens the secret-boss encounter.",
            "* FINAL FIGHT TEST opens the Knight + Titan encounter.",
            "* RUNTIME TEST checks that a basic encounter can start and end.",
            "* The Gaster statue is a dialogue-only test.",
            "* The savepoint restores your party before you begin.",
            "* Tests are separate: finishing one will not launch another."
        })
    end)
end
