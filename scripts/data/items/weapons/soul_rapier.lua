local item, super = Class(Item, "soul_rapier")
function item:init()
    super.init(self)
    self.name = "SOUL Rapier"
    self.type = "weapon"
    self.icon = "ui/menu/icon/sword"
    self.description = "A precise rapier attuned to the Vessel's red SOUL."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 7, magic = 2}
    self.can_equip = {vessel = true}
end
return item