local RuntimeSmoke, super = Class(Wave)

function RuntimeSmoke:init()
    super.init(self)
    self.time = 1.5
end

function RuntimeSmoke:onStart()
    self.timer:after(self.time, function()
        self:setFinished()
    end)
end

return RuntimeSmoke
