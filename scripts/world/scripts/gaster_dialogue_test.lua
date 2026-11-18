-- Interactable runs its configured script before starting its own text
-- cutscene. Populate the event text here; do not call startCutscene again.
return function(event)
    event.text = {
        "* You approach the Gaster statue.",
        "* Its expression is impossible to read.",
        "* ...",
        "* A small plaque reads: 'PLEASE DO NOT FEED THE VOID.'",
        "* The statue does not respond.",
        "* Somehow, you feel like you just failed a dialogue test."
    }
end
