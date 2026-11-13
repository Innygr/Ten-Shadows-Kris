local item, super = Class(Item, "frost_guard")

function item:init()
    super.init(self)
    self.name = "Frost Guard"
    self.type = "armor"
    self.icon = nil
    self.description = "A pale guard woven to keep cold magic stable."
    self.shop = "A pale guard woven to keep cold magic stable."
    self.bonuses = {defense = 2,magic = 3}
    self.can_equip = {noelle = true}
    self.price = 0
end

return item
