local item, super = Class(Item, "soul_anchor")

function item:init()
    super.init(self)
    self.name = "SOUL Anchor"
    self.type = "armor"
    self.icon = nil
    self.description = "A muted gray charm that stabilizes the Vessel's SOUL."
    self.shop = "A muted gray charm that stabilizes the Vessel's SOUL."
    self.bonuses = {defense = 3,magic = 1}
    self.can_equip = {vessel = true}
    self.price = 0
end

return item
