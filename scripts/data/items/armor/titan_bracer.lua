local item, super = Class(Item, "titan_bracer")
function item:init()
    super.init(self)
    self.name = "Titan Bracer"
    self.type = "armor"
    self.icon = nil
    self.description = "A heavy bracer that steadies powerful swings."
    self.shop = self.description
    self.bonuses = {defense = 2, attack = 1}
    self.can_equip = {susie = true}
    self.price = 0
end
return item
