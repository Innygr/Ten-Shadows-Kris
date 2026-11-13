local item, super = Class(Item, "storm_guard")
function item:init()
    super.init(self)
    self.name = "Storm Guard"
    self.type = "armor"
    self.icon = nil
    self.description = "A compact guard that steadies wind-charged equipment."
    self.shop = self.description
    self.bonuses = {defense = 1, magic = 2}
    self.can_equip = {berdly = true}
    self.price = 0
end
return item
