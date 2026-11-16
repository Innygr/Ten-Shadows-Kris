-- Shared Knight + Titan phase progression.
-- Kept pure so thresholds can be tested without booting Kristal.

local BossPhase = {}

local function formatHP(value)
    local digits = tostring(math.max(0, math.floor(tonumber(value) or 0)))
    local grouped = digits:reverse():gsub("(%d%d%d)", "%1,")
    return grouped:reverse():gsub("^,", "")
end

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

function BossPhase.checkText(phase, health, max_health)
    phase = phase or 1
    max_health = max_health or 21000
    health = health == nil and max_health or health

    local phase_description
    if phase == 3 then
        phase_description = "The final phase has begun."
    elseif phase == 2 then
        phase_description = "The second phase has begun."
    else
        phase_description = "The Knight has a separate 1,460 HP pool."
    end

    return {
        "AT 40 DF 800",
        "* HP: " .. formatHP(health) .. " / " .. formatHP(max_health) .. ".",
        "* " .. phase_description,
    }
end

return BossPhase
