local item, super = Class(Item, "ironhide_vest")

function item:init()
    super.init(self)
    self.name = "Ironhide Vest"
    self.type = "armor"
    self.icon = nil
    self.description = "A sturdy vest built for the front line."
    self.shop = "A sturdy vest built for the front line."
    self.bonuses = {defense = 4}
    self.can_equip = {susie = true}
    self.price = 0
end

return item
