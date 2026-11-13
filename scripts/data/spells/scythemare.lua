local spell, super = Class(Spell, "scythemare")

function spell:init()
    super.init(self)
    self.name = "Scythemare"
    self.effect = "SPARE TIRED foes"
    self.description = "Susie scares all TIRED enemies into surrendering."
    self.cost = 40
    self.target = "enemies"
    self.tags = {"spare_tired"}
end

function spell:onCast(user, targets)
    for _, enemy in ipairs(targets) do
        if enemy.tired and enemy.done_state == nil then
            enemy:spare(true)
        end
    end
end

return spell
