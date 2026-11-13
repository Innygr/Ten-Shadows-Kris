local KnightTitanPreview, super = Class(Encounter)

local SOUL_MODE_COLORS = {
    red = {1.00, 0.16, 0.20},
    blue = {0.22, 0.43, 1.00},
    green = {0.24, 1.00, 0.42},
    yellow = {1.00, 0.88, 0.18},
    purple = {0.72, 0.34, 1.00},
    orange = {1.00, 0.48, 0.16},
    cyan = {0.20, 0.90, 1.00},
}

function KnightTitanPreview:init()
    super.init(self)

    self.text = "* The Roaring Knight and Titan approach as one."
    self.music = "battle"
    self.background = true

    self:addEnemy("roaring_knight_titan")
end

function KnightTitanPreview:onBattleEnd()
    local Shadows = modRequire("scripts/ten_shadows/runtime_shadows")
    Shadows.onBattleEnd()
end

function KnightTitanPreview:createSoul(x, y, color)
    local battle = Game.battle
    local enemy = battle and battle.enemies and battle.enemies[1] or nil
    local state = enemy and enemy.ten_shadows_state
    local mode = state and state.soul_mode

    if mode and SOUL_MODE_COLORS[mode] then
        if mode == "cyan" then
            local CyanSoul = modRequire("scripts/objects/cyan_soul")
            return CyanSoul(x, y)
        end
        local soul = super.createSoul(self, x, y, SOUL_MODE_COLORS[mode])
        soul.ten_shadows_mode = mode
        return soul
    end

    return super.createSoul(self, x, y, color)
end

return KnightTitanPreview
