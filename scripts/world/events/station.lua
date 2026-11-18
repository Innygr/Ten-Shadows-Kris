local Station, super = Class(Interactable)

local COLORS = {
    purple = {0.48, 0.20, 0.82},
    red = {0.78, 0.16, 0.22},
    cyan = {0.08, 0.62, 0.78},
    violet = {0.34, 0.18, 0.58},
    gold = {0.82, 0.58, 0.12},
}

local function hasActiveCutscene(world)
    if not world then
        return false
    end

    if type(world.hasCutscene) == "function" and world:hasCutscene() then
        return true
    end

    -- Keep the direct state check as a fallback for event instances whose
    -- world reference is not the canonical Game.world object.
    local cutscene = world.cutscene
    return cutscene ~= nil and cutscene.ended ~= true
end

function Station:init(data)
    data = data or {}
    local properties = data.properties or {}
    super.init(self, data.x or 0, data.y or 0, {data.width or 40, data.height or 40}, properties)
    self.label = properties.label or "TEST STATION"
    self.station_width = data.width or 40
    self.station_height = data.height or 40
    self.station_color = COLORS[properties.color] or COLORS.cyan
    self.solid = false
end

-- Interactable:onInteract always creates a text/script cutscene. Check both
-- the event's world and Game.world so a stale/missing event reference cannot
-- start a second cutscene while the current dialogue is still active.
function Station:onInteract(player, dir)
    local game_world = Game and Game.world or nil
    if hasActiveCutscene(game_world) or hasActiveCutscene(self.world) then
        return false
    end
    return super.onInteract(self, player, dir)
end

function Station:draw()
    love.graphics.push("all")
    local color = self.station_color
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("fill", 0, 0, self.station_width, self.station_height)
    love.graphics.setColor(0.92, 0.96, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", 1.5, 1.5, math.max(0, self.station_width - 3), math.max(0, self.station_height - 3))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.label, 4, math.max(2, self.station_height / 2 - 7), math.max(1, self.station_width - 8), "center")
    love.graphics.pop()
    super.draw(self)
end

return Station
