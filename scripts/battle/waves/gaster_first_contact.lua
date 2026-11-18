local GasterFirstContact, super = Class(Wave)

function GasterFirstContact:init()
    super.init(self)
    self.time = 7.2
end

function GasterFirstContact:onStart()
    local arena = Game.battle.arena
    local volley = 0

    -- Six slow, evenly spaced lines sweep across the arena. The offset changes
    -- each volley so the player has to move through the gaps instead of
    -- standing in one safe lane for the whole attack.
    self.timer:every(0.82, function()
        volley = volley + 1
        local gap = (volley * 2) % 5
        local direction = volley % 2 == 0 and math.rad(180) or 0
        local origin_x = direction == 0 and (arena.left - 14) or (arena.right + 14)
        for lane = 1, 6 do
            if lane ~= gap + 1 then
                local y = arena.top + (arena.height / 7) * lane
                self:spawnBullet(
                    "gaster_bullet",
                    origin_x,
                    y,
                    direction,
                    3.2 + (volley % 3) * 0.35,
                    volley * 0.7 + lane
                )
            end
        end

        if volley >= 6 then
            self.timer:after(1.25, function()
                self:setFinished()
            end)
        end
    end, 6)
end

return GasterFirstContact
