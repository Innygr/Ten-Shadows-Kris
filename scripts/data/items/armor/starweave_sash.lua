local item, super = Class(Item, "starweave_sash")
function item:init()
    super.init(self)
    self.name = "Starweave Sash"
    self.type = "armor"
    self.icon = nil
    self.description = "A light sash threaded with restorative starlight."
    self.shop = self.description
    self.bonuses = {defense = 1, magic = 2}
    self.can_equip = {ralsei = true}
    self.price = 0
end
return item
