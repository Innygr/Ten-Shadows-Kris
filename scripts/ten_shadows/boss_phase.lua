-- Shared Knight + Titan phase progression.
-- Kept pure so thresholds can be tested without booting Kristal.

local BossPhase = {}

BossPhase.THRESHOLDS = {
    [2] = 14000,
    [3] = 7000,
}

BossPhase.TEXT = {
    [1] = "* The Knight and Titan stand together. The Roaring begins.",
    [2] = "* The Titan's shape shifts. The Knight presses forward.",
    [3] = "* THE ROARING. The Knight and Titan unleash their final phase.",
}

function BossPhase.advance(health, phase)
    phase = phase or 1
    local previous_phase = phase

    -- A single large hit can cross more than one threshold. Resolve all
    -- crossed thresholds immediately so the shared boss never remains in an
    -- outdated phase merely because no later hit arrives.
    while BossPhase.THRESHOLDS[phase + 1]
        and health <= BossPhase.THRESHOLDS[phase + 1] do
        phase = phase + 1
    end

    if phase ~= previous_phase then
        return phase, BossPhase.TEXT[phase]
    end
    return phase, nil
end

function BossPhase.checkText(phase)
    phase = phase or 1
    if phase == 3 then
        return "AT 40 DF 800\n* Titan HP: 7,000 or less.\n* The final phase has begun."
    elseif phase == 2 then
        return "AT 40 DF 800\n* Titan HP: 14,000 or less.\n* The second phase has begun."
    end
    return "AT 40 DF 800\n* Titan HP: 21,000.\n* The Knight has a separate 1,460 HP."
end

return BossPhase
