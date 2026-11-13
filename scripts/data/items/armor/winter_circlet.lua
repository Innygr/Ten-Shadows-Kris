local item, super = Class(Item, "winter_circlet")
function item:init()
    super.init(self)
    self.name = "Winter Circlet"
    self.type = "armor"
    self.icon = nil
    self.description = "A cool circlet that helps channel precise ice magic."
    self.shop = self.description
    self.bonuses = {defense = 1, magic = 2}
    self.can_equip = {noelle = true}
    self.price = 0
end
return item
