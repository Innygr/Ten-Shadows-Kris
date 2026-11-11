local item, super = Class(Item, "ten_shadow_blade")
function item:init()
    super.init(self)
    self.name = "Ten Shadow Blade"
    self.type = "weapon"
    self.icon = "ui/menu/icon/sword"
    self.description = "A dark blade tuned to the rhythm of the Ten Shadows."
    self.effect = ""
    self.shop = self.description
    self.price = 0
    self.can_sell = false
    self.target = "none"
    self.usable_in = "all"
    self.instant = false
    self.bonuses = {attack = 7, magic = 2}
    self.can_equip = {kris = true}
end
return item