-- Ten Shadows Kris: Kristal-native shared Knight + Titan combat state.
-- Pure Lua 5.1 module: no browser APIs and no HTML prototype dependencies.
-- Battle/Encounter/Wave scripts should call this module rather than duplicating
-- TP, status, phase, and scheduler rules.

local CombatState = {}

CombatState.PARTY = {
    {id = "kris",   name = "Kris",   max_hp = 48, role = "TEN SHADOWS"},
    {id = "susie",  name = "Susie",  max_hp = 62, role = "HEAVY HITTER"},
    {id = "ralsei", name = "Ralsei", max_hp = 44, role = "SUPPORT"},
    {id = "noelle", name = "Noelle", max_hp = 50, role = "ICE / CONTROL"},
    {id = "berdly", name = "Berdly", max_hp = 54, role = "TECH SUPPORT"},
}

CombatState.BASIC_ATTACKS = {
    kris = {damage = 17},
    susie = {damage = 24},
    ralsei = {damage = 10},
    noelle = {damage = 15},
    berdly = {damage = 18},
}

CombatState.SHADOWS = {
    {id="toad", name="TOAD", cost=0, effect="disrupt"},
    {id="nue", name="NUE", cost=20, damage=24, effect="tp", gain=5},
    {id="divine_dog", name="DIVINE DOG", cost=25, damage=31, effect="expose", turns=1},
    {id="great_serpent", name="GREAT SERPENT", cost=30, damage=27, effect="disrupt"},
    {id="max_elephant", name="MAX ELEPHANT", cost=35, damage=42, effect="damage"},
    {id="rabbit_escape", name="RABBIT ESCAPE", cost=18, effect="support", heal=8, tp=8},
    {id="round_deer", name="ROUND DEER", cost=32, effect="heal", heal=18},
    {id="piercing_ox", name="PIERCING OX", cost=40, damage=50, effect="expose", turns=2},
    {id="tiger_funeral", name="TIGER FUNERAL", cost=55, damage=64, effect="chill", chill=1},
    {id="mahoraga", name="MAHORAGA", cost=100, damage=95, effect="adapt"},
}

CombatState.KNIGHT_ATTACKS = {
    {id="titan_swarm", name="TITAN · SWARM", phases={1,2,3}, weight=1},
    {id="titan_hands", name="TITAN · THE HANDS", phases={1,2,3}, weight=1},
    {id="titan_big_shots", name="TITAN · BIG SHOTS 1", phases={2}, weight=1},
    {id="titan_big_shots_2", name="TITAN · BIG SHOTS 2", phases={2,3}, weight=1},
    {id="titan_big_shots_3", name="TITAN · BIG SHOTS 3", phases={3}, weight=1},
    {id="titan_desperation", name="TITAN · DESPERATION SHOTS", phases={3}, weight=2},
    {id="titan_knight_combo", name="TITAN + KNIGHT · COLLISION", phases={1,2,3}, weight=1},
    {id="crystal_barrage", name="CRYSTAL BARRAGE", phases={1,2,3}, weight=1},
    {id="twin_slashes", name="TWIN SLASHES", phases={1,2,3}, weight=1},
    {id="knight_combo", name="KNIGHT COMBO", phases={1,2,3}, weight=1},
    {id="sanguine_slash", name="SANGUINE SLASH", phases={1,2,3}, weight=1},
    {id="sanguine_slash_d2", name="SANGUINE SLASH II", phases={2,3}, weight=1},
    {id="tracking_swords", name="TRACKING SWORDS", phases={1,2,3}, weight=3},
    {id="box_splitter", name="BOX SPLITTER", phases={1,2,3}, weight=2},
    {id="sword_tunnel", name="SWORD TUNNEL", phases={1,2,3}, weight=2},
    {id="rotating_slash", name="ROTATING SLASH", phases={1,2,3}, weight=2},
    {id="crescent_slashes_v1", name="CRESCENT SLASHES V1", phases={1,2,3}, weight=1},
    {id="crescent_slashes_v2", name="CRESCENT SLASHES V2", phases={1,2,3}, weight=1},
    {id="sticking_stars", name="STICKING STARS", phases={1,2,3}, weight=1},
    {id="tracking_swords_d1", name="TRACKING SWORDS · DIFFICULTY 1", phases={2,3}, weight=1},
    {id="tracking_swords_d2", name="TRACKING SWORDS · DIFFICULTY 2", phases={2,3}, weight=1},
    {id="rotating_slash_tracking_swords", name="ROTATING SLASH + TRACKING SWORDS", phases={2,3}, weight=1},
    {id="diagonal_bullet_walls", name="DIAGONAL BULLET WALLS", phases={2,3}, weight=1},
    {id="sword_tunnel_d1", name="SWORD TUNNEL · DIFFICULTY 1", phases={2,3}, weight=1},
    {id="sword_tunnel_d2", name="SWORD TUNNEL · DIFFICULTY 2", phases={2,3}, weight=1},
    {id="sword_vortex_base", name="SWORD VORTEX", phases={2,3}, weight=1},
    {id="sword_vortex_d1", name="SWORD VORTEX · DIFFICULTY 1", phases={2,3}, weight=1},
    {id="sword_vortex_d2", name="SWORD VORTEX · DIFFICULTY 2", phases={3}, weight=1},
    {id="revolver", name="REVOLVER", phases={1,2,3}, weight=1},
    {id="cross_attack", name="CROSS ATTACK", phases={1,2,3}, weight=1},
    {id="combination", name="COMBINATION", phases={2,3}, weight=1},
    {id="bottom_shadows", name="BOTTOM SHADOWS", phases={2,3}, weight=1},
    {id="falling_swords", name="FALLING SWORDS", phases={2,3}, weight=2},
    {id="sword_vortex", name="SWORD VORTEX", phases={2,3}, weight=1},
    {id="quick_slashes", name="QUICK SLASHES", phases={2,3}, weight=1},
    {id="roaring_fire", name="ROARING FIRE", phases={3}, weight=1},
    {id="black_flash", name="THE ROARING", phases={3}, weight=1},
}

local function copyParty()
    local party = {}
    for _, member in ipairs(CombatState.PARTY) do
        party[#party + 1] = {
            id = member.id, name = member.name, max_hp = member.max_hp,
            hp = member.max_hp, guard = false, role = member.role,
        }
    end
    return party
end

function CombatState.new()
    local state = {
        party = copyParty(),
        boss = {
            hp = 260, max_hp = 260, phase = 1, exposed = 0,
            chill = 0, frozen_turns = 0, tired_immune = true,
            mercy_immune = true, status = "Normal",
        },
        tp = 35,
        dark_candy = 3,
        turn = 1,
        knight_disrupted = 0,
        player_domain = {active = false, turns = 0, used = false},
        knight_domain = {active = false, turns = 0},
        titan = {light_radius = 38, base_light_radius = 38, brighten_turns = 0},
        encounter = {
            phase = 1, last_class = "", last_source = "",
            last_attack = "", turns = 0, phase_counts = {[1]=0,[2]=0,[3]=0},
        },
    }

    function state:getMember(id)
        for _, member in ipairs(self.party) do
            if member.id == id then return member end
        end
    end

    function state:getLiving()
        local living = {}
        for _, member in ipairs(self.party) do
            if member.hp > 0 then living[#living + 1] = member end
        end
        return living
    end

    function state:addTP(amount)
        self.tp = math.min(100, math.max(0, self.tp + amount))
        return self.tp
    end

    function state:spendTP(amount)
        if self.tp < amount then return false end
        self.tp = self.tp - amount
        return true
    end

    function state:damageBoss(amount)
        local multiplier = self.boss.exposed > 0 and 1.4 or 1
        local dealt = math.floor(amount * multiplier + 0.5)
        self.boss.hp = math.max(0, self.boss.hp - dealt)
        local phase_changed = false
        if self.boss.phase == 1 and self.boss.hp <= 175 then
            self.boss.phase = 2
            phase_changed = true
        elseif self.boss.phase == 2 and self.boss.hp <= 78 then
            self.boss.phase = 3
            phase_changed = true
        end
        if phase_changed then
            self.encounter.phase = self.boss.phase
            self.encounter.last_class = ""
            self.encounter.last_source = ""
            self.encounter.last_attack = ""
            self.encounter.turns = 0
            self.encounter.phase_counts[self.boss.phase] = 0
        end
        return dealt, phase_changed
    end

    function state:applyChill(amount)
        self.boss.chill = math.min(3, self.boss.chill + amount)
        if self.boss.chill >= 3 then
            self.boss.chill = 0
            self.boss.frozen_turns = 1
            self.boss.exposed = math.max(self.boss.exposed, 1)
            return true
        end
        return false
    end

    function state:expose(turns)
        self.boss.exposed = math.max(self.boss.exposed, turns or 1)
    end

    function state:disruptKnight()
        self.knight_disrupted = 1
    end

    function state:consumeKnightDisruption(knight_is_frozen)
        if knight_is_frozen or self.knight_disrupted <= 0 then return false end
        self.knight_disrupted = self.knight_disrupted - 1
        return true
    end

    function state:defend(member)
        member.guard = true
        self:addTP(14)
    end

    function state:heal(member, amount)
        if member.hp <= 0 then return 0 end
        local before = member.hp
        member.hp = math.min(member.max_hp, member.hp + amount)
        return member.hp - before
    end

    function state:useDarkCandy(member)
        if self.dark_candy <= 0 or member.hp <= 0 or member.hp >= member.max_hp then return false end
        self.dark_candy = self.dark_candy - 1
        self:heal(member, 18)
        return true
    end

    function state:wakeKris()
        local kris = self:getMember("kris")
        if not kris or kris.hp > 0 then return false end
        kris.hp = 1
        return true
    end

    function state:brighten()
        local susie = self:getMember("susie")
        local ralsei = self:getMember("ralsei")
        if not susie or susie.hp <= 0 or not ralsei or ralsei.hp <= 0 then return false end
        if self.titan.brighten_turns > 0 or not self:spendTP(4) then return false end
        self.titan.light_radius = 58
        self.titan.brighten_turns = 1
        return true
    end

    function state:checkBoss()
        local gained = 0
        if self.boss.exposed <= 0 then
            gained = 8
            self:addTP(gained)
        end
        return gained
    end

    function state:distractKnight()
        self:expose(2)
        self:addTP(12)
    end

    function state:rushWithSusie()
        if not self:getMember("susie") or self:getMember("susie").hp <= 0 then return false end
        return self:damageBoss(34)
    end

    function state:castIceShock()
        if not self:spendTP(16) then return false end
        local dealt = self:damageBoss(18)
        local frozen = self:applyChill(1)
        return true, dealt, frozen
    end

    function state:castIceWave()
        if not self:spendTP(28) then return false end
        local dealt = self:damageBoss(30)
        local frozen = self:applyChill(2)
        return true, dealt, frozen
    end

    function state:castTornado()
        if not self:spendTP(20) then return false end
        local dealt = self:damageBoss(16)
        self:disruptKnight()
        return true, dealt
    end

    function state:castHeal(target)
        if not target or target.hp <= 0 or target.hp >= target.max_hp or not self:spendTP(16) then return false end
        return self:heal(target, 22)
    end

    function state:castReviveSong(target)
        if not target or (target.hp > 0 and target.hp >= target.max_hp) or not self:spendTP(84) then return false end
        if target.hp <= 0 then
            target.hp = math.ceil(target.max_hp / 2)
            return true, "revived"
        end
        self:heal(target, math.ceil(target.max_hp / 2))
        return true, "healed"
    end

    function state:expandChimeraDomain()
        local domain = self.player_domain
        if domain.used or domain.active or not self:spendTP(60) then return false end
        domain.active = true
        domain.turns = 3
        domain.used = true
        return true
    end

    function state:startKnightDomain()
        if self.boss.phase ~= 3 or self.knight_domain.active then return false end
        self.knight_domain.active = true
        self.knight_domain.turns = 3
        return true
    end

    function state:tickEnemyTurnEffects()
        if self.boss.exposed > 0 then self.boss.exposed = self.boss.exposed - 1 end
        if self.titan.brighten_turns > 0 then
            self.titan.brighten_turns = self.titan.brighten_turns - 1
            if self.titan.brighten_turns == 0 then
                self.titan.light_radius = self.titan.base_light_radius
            end
        end
        if self.player_domain.active then
            self.player_domain.turns = self.player_domain.turns - 1
            if self.player_domain.turns <= 0 then
                self.player_domain.active = false
                self.player_domain.turns = 0
            end
        end
        if self.knight_domain.active then
            self.knight_domain.turns = self.knight_domain.turns - 1
            if self.knight_domain.turns <= 0 then
                self.knight_domain.active = false
                self.knight_domain.turns = 0
            end
        end
    end

    function state:getShadowCost(shadow)
        if self.player_domain.active then return math.ceil(shadow.cost * 0.75) end
        return shadow.cost
    end

    function state:useShadow(id)
        local shadow
        for _, entry in ipairs(CombatState.SHADOWS) do
            if entry.id == id then shadow = entry break end
        end
        if not shadow then return false, "Unknown shadow." end
        local cost = self:getShadowCost(shadow)
        if not self:spendTP(cost) then return false, "Not enough TP." end

        local dealt = 0
        if shadow.damage then dealt = self:damageBoss(shadow.damage * (self.player_domain.active and 1.35 or 1)) end
        if shadow.effect == "disrupt" then self:disruptKnight() end
        if shadow.effect == "expose" then self:expose(shadow.turns) end
        if shadow.effect == "tp" then self:addTP(shadow.gain) end
        if shadow.effect == "support" then
            for _, member in ipairs(self:getLiving()) do self:heal(member, shadow.heal) end
            self:addTP(shadow.tp)
        elseif shadow.effect == "heal" then
            for _, member in ipairs(self:getLiving()) do self:heal(member, shadow.heal) end
        elseif shadow.effect == "chill" then
            self:applyChill(shadow.chill)
        elseif shadow.effect == "adapt" then
            self:expose(2)
            self:disruptKnight()
        end
        return true, shadow, dealt
    end

    function state:getActionsFor(member_id)
        local actions = {"CHECK", "DISTRACT"}
        if member_id ~= "kris" then
            table.insert(actions, 1, "WAKE KRIS")
        else
            actions[#actions + 1] = "SHADOWS"
            if not self.player_domain.used then actions[#actions + 1] = "CHIMERA SHADOW GARDEN" end
        end
        if member_id == "susie" then
            actions[#actions + 1] = "RUSH"
            actions[#actions + 1] = "BRIGHTEN"
        elseif member_id == "ralsei" then
            actions[#actions + 1] = "HEAL"
            actions[#actions + 1] = "REVIVESONG"
        elseif member_id == "noelle" then
            actions[#actions + 1] = "ICE SHOCK"
            actions[#actions + 1] = "ICE WAVE"
        elseif member_id == "berdly" then
            actions[#actions + 1] = "TORNADO"
        end
        return actions
    end

    function state:chooseEnemyAttack()
        local encounter = self.encounter
        local phase = self.boss.phase
        if encounter.phase ~= phase then
            encounter.phase = phase
            encounter.last_class = ""
            encounter.last_source = ""
            encounter.last_attack = ""
            encounter.turns = 0
            encounter.phase_counts[phase] = 0
        end
        encounter.turns = encounter.turns + 1

        local frozen = self.boss.frozen_turns > 0
        if frozen then self.boss.frozen_turns = self.boss.frozen_turns - 1 end

        local eligible, titan, knight, combo = {}, {}, {}, nil
        for _, attack in ipairs(CombatState.KNIGHT_ATTACKS) do
            if attack.phases[1] == phase or attack.phases[2] == phase or attack.phases[3] == phase then
                eligible[#eligible + 1] = attack
                if attack.id == "titan_knight_combo" then
                    combo = attack
                elseif string.sub(attack.id, 1, 6) == "titan_" then
                    titan[#titan + 1] = attack
                else
                    knight[#knight + 1] = attack
                end
            end
        end

        local source
        if frozen then
            source = "titan"
        elseif combo and encounter.turns % (phase == 3 and 3 or 4) == 0 then
            source = "combo"
        elseif #titan > 0 and #knight > 0 then
            source = encounter.last_source == "titan" and "knight" or "titan"
        else
            source = #titan > 0 and "titan" or "knight"
        end

        local pool = source == "combo" and {combo} or (source == "titan" and titan or knight)
        if #pool == 0 then pool = eligible end
        if source == "titan" and #pool > 1 then
            local alternate = {}
            for _, attack in ipairs(pool) do
                local shield_class = (attack.id == "titan_swarm" or attack.id == "titan_hands") and "shield-up" or "shield-down"
                if shield_class ~= encounter.last_class then alternate[#alternate + 1] = attack end
            end
            if #alternate > 0 then pool = alternate end
        end
        if #pool > 1 then
            local fresh = {}
            for _, attack in ipairs(pool) do
                if attack.id ~= encounter.last_attack then fresh[#fresh + 1] = attack end
            end
            if #fresh > 0 then pool = fresh end
        end

        local total = 0
        for _, attack in ipairs(pool) do total = total + (attack.weight or 1) end
        local roll = math.random() * total
        local picked = pool[1]
        for _, attack in ipairs(pool) do
            roll = roll - (attack.weight or 1)
            if roll <= 0 then picked = attack break end
        end

        if picked then
            if string.sub(picked.id, 1, 6) == "titan_" and picked.id ~= "titan_knight_combo" then
                encounter.last_source = "titan"
                encounter.last_class = (picked.id == "titan_swarm" or picked.id == "titan_hands") and "shield-up" or "shield-down"
                encounter.phase_counts[phase] = encounter.phase_counts[phase] + 1
            elseif picked.id ~= "titan_knight_combo" then
                encounter.last_source = "knight"
            end
            encounter.last_attack = picked.id
        end

        local domain_started = false
        if not frozen and phase == 3 and not self.knight_domain.active and math.random() < 0.45 then
            domain_started = self:startKnightDomain()
        end

        return picked, frozen, domain_started
    end

    function state:canSpare()
        return false
    end

    function state:canBecomeTired()
        return false
    end

    return state
end

return CombatState
