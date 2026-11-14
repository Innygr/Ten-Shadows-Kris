-- Deterministic, engine-independent spawn plans for the Knight + Titan Wave.
-- The Wave turns these descriptors into Kristal Bullet instances. Keeping the
-- geometry here makes attack coverage and safe-lane rules testable with Lua 5.1.
local AttackWavePatterns = {}

local WALL_IDS = {
    box_splitter = true,
    diagonal_bullet_walls = true,
    sword_tunnel = true,
    sword_tunnel_d1 = true,
    sword_tunnel_d2 = true,
}

local FALLING_IDS = {
    titan_swarm = true,
    titan_big_shots = true,
    titan_big_shots_2 = true,
    titan_big_shots_3 = true,
    titan_desperation = true,
    falling_swords = true,
    roaring_fire = true,
    black_flash = true,
}

local RADIAL_PATTERNS = {
    ["radial-pulse-barrage"] = true,
    ["timed-pulse-rings"] = true,
    ["dark-interval-pulses"] = true,
    ["orbiting-gaps"] = true,
}

local WALL_PATTERNS = {
    ["timed-laser-grid"] = true,
    ["guardbreak-grid"] = true,
    ["closing-thread-grid"] = true,
    ["thread-cage-crosscut"] = true,
    ["moving-hazard-lanes"] = true,
    ["severed-thread-lanes"] = true,
    ["target-barricade"] = true,
    ["thread-lane-snare"] = true,
    ["crossing-thread-projectiles"] = true,
    ["shifting-safe-zones"] = true,
    ["gravity-inversion"] = true,
}

local AIMED_PATTERNS = {
    ["aimed-projectile-volley"] = true,
    ["afterimage-pursuit"] = true,
    ["armored-artillery"] = true,
    ["chasing-embers"] = true,
    ["ricochet-blades"] = true,
    ["cyan-parry-window"] = true,
    ["pause-then-strike"] = true,
}

local CROSS_PATTERNS = {
    ["crosscut-burst"] = true,
    ["gravity-slam"] = true,
    ["feint-then-lunge"] = true,
    ["shieldbreaker-strike"] = true,
    ["directional-blade-barrage"] = true,
    ["moving-target-slashes"] = true,
    ["redline-crash"] = true,
    ["aimed-crossfire"] = true,
    ["chase-and-sweep"] = true,
    ["timed-cross-pulse"] = true,
    ["gravity-arc"] = true,
}

local function has(set, key)
    return set[key] == true
end

local function inferSource(attack)
    if attack and attack.source then return attack.source end
    local id = attack and attack.id or ""
    if id == "titan_knight_combo" then return "combo" end
    if string.sub(id, 1, 6) == "titan_" then return "titan" end
    return "knight"
end

local function classify(attack)
    local id = attack and attack.id or "titan_swarm"
    local pattern = attack and attack.pattern or id
    local source = inferSource(attack)

    if source == "combo" then return "crossfire" end
    if id == "twin_slashes" then return "twin_slash" end
    if has(RADIAL_PATTERNS, pattern) then return "radial" end
    if has(WALL_IDS, id) or has(WALL_PATTERNS, pattern) then return "wall" end
    if has(AIMED_PATTERNS, pattern) then return "aimed" end
    if has(CROSS_PATTERNS, pattern) then return "crossfire" end
    if has(FALLING_IDS, id) or pattern == "falling-columns" or pattern == "updraft-sweep" then
        return "falling"
    end
    if id == "titan_hands" then return "sweep" end
    return "sweep"
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

local function add(shots, kind, x, y, direction, speed, warning, mechanic)
    shots[#shots + 1] = {
        kind = kind,
        x = x,
        y = y,
        direction = direction,
        speed = speed,
        warning = warning,
        mechanic = mechanic,
    }
end

function AttackWavePatterns.classify(attack)
    return classify(attack)
end

-- arena = {left, right, top, bottom}; target = {x, y}
function AttackWavePatterns.build(attack, phase, volley, arena, target, domain_active)
    assert(type(arena) == "table", "arena bounds are required")
    assert(arena.left and arena.right and arena.top and arena.bottom, "arena bounds are incomplete")

    phase = math.max(1, math.min(3, phase or 1))
    volley = math.max(1, volley or 1)
    local width = arena.right - arena.left
    local height = arena.bottom - arena.top
    local center_x = (arena.left + arena.right) / 2
    local center_y = (arena.top + arena.bottom) / 2
    target = target or {x = center_x, y = center_y}

    local family = classify(attack)
    local source = inferSource(attack)
    local kind = source
    local pace = 2.8 + (phase - 1) * 0.42 + (volley - 1) * 0.10
    local shots = {}

    if attack and attack.id == "twin_slashes" then
        -- Two Knight blades enter from opposite sides and cross at a point
        -- that shifts between upper and lower arena space on alternating volleys.
        -- The visible tells make the crossing lanes readable before either blade arms.
        local crossing_x = center_x + (volley % 2 == 0 and 1 or -1) * width * 0.08
        local crossing_y = center_y + (volley % 2 == 0 and 1 or -1) * height * 0.09
        local upper_y = center_y - height * 0.30
        local lower_y = center_y + height * 0.30
        local duration = phase == 1 and 0.48 or (phase == 2 and 0.43 or 0.38)

        local left_x = arena.left - 10
        local left_dx = crossing_x - left_x
        local left_dy = crossing_y + height * 0.12 - upper_y
        local left_distance = math.sqrt(left_dx * left_dx + left_dy * left_dy)
        add(shots, "knight", left_x, upper_y, atan2(left_dy, left_dx), pace + 0.35, {
            kind = "target",
            duration = duration,
            length = left_distance,
        }, {
            kind = "twin_slash",
            lane = "left-to-lower",
        })

        local right_x = arena.right + 10
        local right_dx = crossing_x - right_x
        local right_dy = crossing_y - height * 0.12 - lower_y
        local right_distance = math.sqrt(right_dx * right_dx + right_dy * right_dy)
        add(shots, "knight", right_x, lower_y, atan2(right_dy, right_dx), pace + 0.35, {
            kind = "target",
            duration = duration,
            length = right_distance,
        }, {
            kind = "twin_slash",
            lane = "right-to-upper",
        })
    elseif attack and attack.id == "cyan_knights_execution" and volley == 3 then
        local from_right = phase % 2 == 0
        local x = from_right and (arena.right + 10) or (arena.left - 10)
        local y = math.max(arena.top + 14, math.min(arena.bottom - 14, target.y))
        local dx = target.x - x
        local dy = target.y - y
        local distance = math.sqrt(dx * dx + dy * dy)
        add(shots, "knight", x, y, atan2(dy, dx), pace + 0.65, {
            kind = "target",
            duration = 0.55,
            length = distance,
        }, {
            kind = "execution_slash",
        })
    elseif family == "radial" then
        local count = 8 + phase * 2
        local rotation = (volley - 1) * 0.16
        for i = 1, count do
            local angle = rotation + (math.pi * 2 * (i - 1) / count)
            add(shots, kind, center_x, center_y, angle, pace)
        end
    elseif family == "wall" then
        local lanes = 7
        local safe_lane = ((volley + phase * 2 - 1) % lanes) + 1
        local from_right = volley % 2 == 0
        local x = from_right and (arena.right + 10) or (arena.left - 10)
        local direction = from_right and math.pi or 0
        for lane = 1, lanes do
            if lane ~= safe_lane then
                local y = arena.top + (height * (lane - 1) / (lanes - 1))
                add(shots, kind, x, y, direction, pace + 0.25, {
                    kind = "lane",
                    duration = 0.42,
                    length = width + 20,
                })
            end
        end
    elseif family == "aimed" then
        local from_right = volley % 2 == 0
        local x = from_right and (arena.right + 10) or (arena.left - 10)
        local y = arena.top + height * (0.18 + ((volley * 2) % 5) * 0.14)
        for i = -1, 1 do
            local shot_y = y + i * 12
            local dx = target.x - x
            local dy = target.y - shot_y
            local distance = math.sqrt(dx * dx + dy * dy)
            local angle = atan2(dy, dx) + i * 0.16
            add(shots, kind, x, shot_y, angle, pace + 0.35, {
                kind = "target",
                duration = 0.36,
                length = distance,
            })
        end
    elseif family == "crossfire" then
        local upper = center_y - height * 0.22
        local lower = center_y + height * 0.22
        local left_x = arena.left - 10
        local right_x = arena.right + 10
        local offset = ((volley - 1) % 3) * 8
        for i = 0, 2 do
            local y = upper + (i - 1) * 18 + offset
            add(shots, "knight", left_x, y, 0, pace + 0.15)
        end
        for i = 0, 2 do
            local y = lower + (i - 1) * 18 - offset
            add(shots, "titan", right_x, y, math.pi, pace + 0.15)
        end
        local angle = atan2(target.y - center_y, target.x - center_x)
        add(shots, "combo", center_x, center_y, angle, pace + 0.55)
    elseif family == "falling" then
        local count = phase == 3 and 8 or 5 + phase
        local spacing = width / (count + 1)
        local drift = ((volley - 1) % 3 - 1) * spacing * 0.22
        for i = 1, count do
            local x = arena.left + spacing * i + drift
            add(shots, kind, x, arena.top - 10, math.pi / 2, pace, {
                kind = "falling",
                duration = 0.48,
                length = height + 20,
            })
        end
    else
        local count = phase == 3 and 5 or 3
        local from_right = volley % 2 == 0
        local x = from_right and (arena.right + 10) or (arena.left - 10)
        local direction = from_right and math.pi or 0
        local center = center_y + math.sin(volley * 0.9) * height * 0.16
        for i = 1, count do
            local y = center + (i - (count + 1) / 2) * 19
            add(shots, kind, x, y, direction, pace + 0.18)
        end
        if volley % 2 == 0 then
            add(shots, kind, center_x, arena.top - 10, math.pi / 2, pace - 0.15)
        end
    end

    -- The Knight's phase-three domain layers two diagonal falling blades over
    -- the normal attack. They are sparse enough to preserve the base pattern's
    -- safe route while making the domain state visible through gameplay.
    if domain_active then
        add(shots, "combo", arena.left + width * 0.28, arena.top - 10, math.pi / 3, pace + 0.2, {
            kind = "falling",
            duration = 0.48,
            length = height * 1.25,
        })
        add(shots, "combo", arena.right - width * 0.28, arena.top - 10, 2 * math.pi / 3, pace + 0.2, {
            kind = "falling",
            duration = 0.48,
            length = height * 1.25,
        })
    end

    return shots, family
end

return AttackWavePatterns
