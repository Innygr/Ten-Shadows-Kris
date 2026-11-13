local item, super = Class(Item, "healing_sash")

function item:init()
    super.init(self)
    self.name = "Healing Sash"
    self.type = "armor"
    self.icon = nil
    self.description = "A soft sash that steadies restorative magic."
    self.shop = "A soft sash that steadies restorative magic."
    self.bonuses = {defense = 2,magic = 2}
    self.can_equip = {ralsei = true}
    self.price = 0
end

return item
