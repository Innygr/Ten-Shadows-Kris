local item, super = Class(Item, "verdant_staff")
function item:init()
    super.init(self)
    self.name = "Verdant Staff"
    self.type = "weapon"
    self.icon = "ui/menu/icon/sword"
    self.description = "A gentle staff that strengthens restorative magic."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 2, magic = 5}
    self.can_equip = {ralsei = true}
end
return item