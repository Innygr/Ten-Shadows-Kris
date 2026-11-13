local KnightTitanPreview, super = Class(Encounter)

function KnightTitanPreview:init()
    super.init(self)

    self.text = "* The Roaring Knight and Titan approach as one."
    self.music = "battle"
    self.background = true

    self:addEnemy("roaring_knight_titan")
end

return KnightTitanPreview
