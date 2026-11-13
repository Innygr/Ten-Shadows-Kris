local item, super = Class(Item, "red_soul_charm")
function item:init()
    super.init(self)
    self.name = "Red SOUL Charm"
    self.type = "armor"
    self.icon = nil
    self.description = "A small charm that steadies the Vessel's red SOUL."
    self.shop = self.description
    self.bonuses = {defense = 2, magic = 1}
    self.can_equip = {vessel = true}
    self.price = 0
end
return item
