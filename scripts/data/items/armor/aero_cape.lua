local item, super = Class(Item, "aero_cape")

function item:init()
    super.init(self)
    self.name = "Aero Cape"
    self.type = "armor"
    self.icon = nil
    self.description = "A light cape that helps focus wind techniques."
    self.shop = "A light cape that helps focus wind techniques."
    self.bonuses = {defense = 2,magic = 2}
    self.can_equip = {berdly = true}
    self.price = 0
end

return item
