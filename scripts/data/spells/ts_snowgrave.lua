local spell, super = Class(Spell, "ts_snowgrave")

function spell:init()
    super.init(self)
    self.name = "SnowGrave"
    self.effect = "SPECIAL ICE"
    self.description = "A route-specific spell. Only available in its intended encounter."
    self.cost = 200
    self.target = "enemy"
    self.tags = {"ice", "route_gated"}
end

function spell:onCast(user, target)
    -- Deliberately inert until the Weird Route and Berdly encounter gates exist.
    -- This keeps the spell entry represented without enabling it in normal play.
    if not Game:getFlag("weird_route", false) then
        return
    end
    if not target or string.lower(target.name or "") ~= "berdly" then
        return
    end
end

return spell
