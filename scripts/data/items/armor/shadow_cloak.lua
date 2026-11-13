local item, super = Class(Item, "shadow_cloak")

function item:init()
    super.init(self)
    self.name = "Shadow Cloak"
    self.type = "armor"
    self.icon = nil
    self.description = "A quiet cloak threaded with protective shadow."
    self.shop = "A quiet cloak threaded with protective shadow."
    self.bonuses = {defense = 3,magic = 1}
    self.can_equip = {kris = true}
    self.price = 0
end

return item
