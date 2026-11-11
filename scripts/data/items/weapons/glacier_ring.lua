local item, super = Class(Item, "glacier_ring")
function item:init()
    super.init(self)
    self.name = "Glacier Ring"
    self.type = "weapon"
    self.icon = "ui/menu/icon/ring"
    self.description = "A cold, clear ring that sharpens Noelle's ice magic."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 2, magic = 5}
    self.can_equip = {noelle = true}
end
return item