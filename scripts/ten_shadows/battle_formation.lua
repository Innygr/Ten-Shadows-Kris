-- Shared, viewport-relative battle formation for the six-member party
-- and the Knight + Titan pair. Coordinates are anchors in battle-screen space.
local Formation = {}

local PARTY_COLUMNS = 2
local PARTY_ROWS = 3

function Formation.partyPosition(index, screen_width, screen_height,
    actor_width, actor_height, offset_x, offset_y)
    assert(type(index) == "number" and index >= 1 and index <= PARTY_COLUMNS * PARTY_ROWS,
        "party formation index must be between 1 and 6")

    local width = math.max(1, tonumber(screen_width) or 640)
    local height = math.max(1, tonumber(screen_height) or 480)
    local column = math.floor((index - 1) / PARTY_ROWS)
    local row = (index - 1) % PARTY_ROWS

    -- Keep a clear left-side staging area while using the whole vertical span.
    local anchor_x = width * 0.16 + column * width * 0.18
    local anchor_y = height * 0.11 + row * height * 0.17

    local width_offset = (math.max(0, tonumber(actor_width) or 32) / 2
        + (tonumber(offset_x) or 0)) * 2
    local height_offset = (math.max(0, tonumber(actor_height) or 32)
        + (tonumber(offset_y) or 0)) * 2

    return anchor_x + width_offset, anchor_y + height_offset
end

function Formation.enemyPositions(screen_width, screen_height)
    local width = math.max(1, tonumber(screen_width) or 640)
    local height = math.max(1, tonumber(screen_height) or 480)

    return {
        titan = {x = width * 0.80, y = height * 0.36},
        knight = {x = width * 0.68, y = height * 0.62},
    }
end

return Formation
