-- Shared, viewport-relative layout for the six-member battle party.
-- Coordinates include Kristal's actor battle offset and are returned as
-- target positions for Encounter:getPartyPosition.
local Formation = {}

local PARTY_COLUMNS = 3
local PARTY_ROWS = 2

function Formation.partyPosition(index, screen_width, screen_height,
    actor_width, actor_height, offset_x, offset_y)
    assert(type(index) == "number" and index >= 1 and index <= PARTY_COLUMNS * PARTY_ROWS,
        "party formation index must be between 1 and 6")

    local width = math.max(1, tonumber(screen_width) or 640)
    local height = math.max(1, tonumber(screen_height) or 480)
    local column = (index - 1) % PARTY_COLUMNS
    local row = math.floor((index - 1) / PARTY_COLUMNS)

    -- Three columns by two rows gives the party a broad, centered-left
    -- formation instead of squeezing everyone into the bottom-left corner.
    local anchor_x = width * 0.095 + column * width * 0.155
    local anchor_y = height * 0.18 + row * height * 0.26

    local width_offset = (math.max(0, tonumber(actor_width) or 32) / 2
        + (tonumber(offset_x) or 0)) * 2
    local height_offset = (math.max(0, tonumber(actor_height) or 32)
        + (tonumber(offset_y) or 0)) * 2

    return anchor_x + width_offset, anchor_y + height_offset
end

return Formation
