local item, super = Class(Item, "storm_halberd")
function item:init()
    super.init(self)
    self.name = "Storm Halberd"
    self.type = "weapon"
    self.icon = "ui/menu/icon/axe"
    self.description = "A balanced halberd charged with focused wind energy."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 8, magic = 2}
    self.can_equip = {berdly = true}
end
return item