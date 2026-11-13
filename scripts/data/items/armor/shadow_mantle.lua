local item, super = Class(Item, "shadow_mantle")
function item:init()
    super.init(self)
    self.name = "Shadow Mantle"
    self.type = "armor"
    self.icon = nil
    self.description = "A mantle woven from quiet shadows. Balances defense and focus."
    self.shop = self.description
    self.bonuses = {defense = 2, magic = 2}
    self.can_equip = {kris = true}
    self.price = 0
end
return item
