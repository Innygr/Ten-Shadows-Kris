local RuntimeSmoke, super = Class(Wave)

function RuntimeSmoke:init()
    super.init(self)
    self.time = 4.5
end

function RuntimeSmoke:onStart()
    local shots = 0

    -- A short stream of slow, visible bullets tests spawning, movement,
    -- collision, grazing, and the player's dodge controls.
    self.timer:every(0.75, function()
        shots = shots + 1
        local arena = Game.battle.arena
        local y = MathUtils.random(arena.top + 8, arena.bottom - 8)
        self:spawnBullet("runtime_test_bullet", SCREEN_WIDTH + 12, y, math.rad(180), 4)

        if shots >= 5 then
            self.timer:after(1.25, function()
                self:setFinished()
            end)
        end
    end, 5)
end

return RuntimeSmoke
