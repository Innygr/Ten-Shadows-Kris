-- Shared Knight + Titan phase progression.
-- Kept pure so thresholds can be tested without booting Kristal.

local BossPhase = {}

BossPhase.THRESHOLDS = {
    [2] = 175,
    [3] = 78,
}

BossPhase.TEXT = {
    [1] = "* The Knight and Titan stand together. The Roaring begins.",
    [2] = "* The Titan's shape shifts. The Knight presses forward.",
    [3] = "* THE ROARING. The Knight and Titan unleash their final phase.",
}

function BossPhase.advance(health, phase)
    phase = phase or 1
    local threshold = BossPhase.THRESHOLDS[phase + 1]
    if threshold and health <= threshold then
        return phase + 1, BossPhase.TEXT[phase + 1]
    end
    return phase, nil
end

function BossPhase.checkText(phase)
    phase = phase or 1
    if phase == 3 then
        return "AT 1 DF 0\n* Shared HP: 78 or less.\n* The final phase has begun."
    elseif phase == 2 then
        return "AT 1 DF 0\n* Shared HP: 175 or less.\n* The second phase has begun."
    end
    return "AT 1 DF 0\n* One shared health pool.\n* The Knight and Titan fight as one."
end

return BossPhase
