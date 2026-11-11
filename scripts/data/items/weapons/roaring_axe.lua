local item, super = Class(Item, "roaring_axe")
function item:init()
    super.init(self)
    self.name = "Roaring Axe"
    self.type = "weapon"
    self.icon = "ui/menu/icon/axe"
    self.description = "A brutal axe made for Susie's overwhelming strikes."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 10}
    self.can_equip = {susie = true}
end
return item