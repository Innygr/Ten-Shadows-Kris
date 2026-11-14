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

    if id == "titan_knight_combo" then return "knight_titan_collision" end
    if id == "black_flash" then return "the_roaring" end
    if id == "roaring_fire" then return "roaring_fire" end
    if source == "combo" then return "crossfire" end
    if id == "titan_hands" then return "titan_hands" end
    if id == "titan_desperation" then return "titan_desperation" end
    if id == "crystal_barrage" then return "crystal_barrage" end
    if id == "titan_big_shots" then return "big_shot_one" end
    if id == "titan_big_shots_2" then return "big_shot_two" end
    if id == "titan_big_shots_3" then return "big_shot_three" end
    if id == "twin_slashes" then return "twin_slash" end
    if has(RADIAL_PATTERNS, pattern) then return "radial" end
    if has(WALL_IDS, id) or has(WALL_PATTERNS, pattern) then return "wall" end
    if has(AIMED_PATTERNS, pattern) then return "aimed" end
    if has(CROSS_PATTERNS, pattern) then return "crossfire" end
    if has(FALLING_IDS, id) or pattern == "falling-columns" or pattern == "updraft-sweep" then
        return "falling"
    end
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
function AttackWavePatterns.build(attack, phase, volley, arena, target, knight_domain_active, player_domain_active)
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

    if attack and attack.id == "roaring_fire" then
        -- Roaring Fire sends paired flame streams from both sides of the box.
        -- The same horizontal lane is omitted on both sides, leaving one
        -- moving corridor that the player can cross or hold while the embers pass.
        local lanes = 5
        local safe_lane = ((volley + phase - 2) % lanes) + 1
        local duration = phase == 3 and 0.34 or 0.40
        local left_x = arena.left - 18
        local right_x = arena.right + 18
        local travel = width + 36

        for lane = 1, lanes do
            if lane ~= safe_lane then
                local y = arena.top + height * lane / (lanes + 1)
                local speed = pace + 0.20 + (lane % 2) * 0.12
                add(shots, "knight", left_x, y, 0, speed, {
                    kind = "lane", duration = duration, length = travel,
                }, {
                    kind = "roaring_flame", side = "left", lane = lane,
                    safe_lane = safe_lane,
                })
                add(shots, "knight", right_x, y, math.pi, speed, {
                    kind = "lane", duration = duration, length = travel,
                }, {
                    kind = "roaring_flame", side = "right", lane = lane,
                    safe_lane = safe_lane,
                })
            end
        end
    elseif attack and attack.id == "black_flash" then
        -- The Roaring sends a ten-spoke burst from the arena's centre. Two
        -- opposite spokes are always left open; the safe pair rotates each
        -- volley so the player can read the tell and choose a route.
        local spokes = 10
        local safe_wedge = (volley + phase - 3) % spokes
        local opposite_wedge = (safe_wedge + spokes / 2) % spokes
        local rotation = (volley - 1) * 0.035

        for spoke = 0, spokes - 1 do
            if spoke ~= safe_wedge and spoke ~= opposite_wedge then
                local angle = rotation + spoke * math.pi * 2 / spokes
                local dx, dy = math.cos(angle), math.sin(angle)
                local horizontal = dx > 0 and (arena.right - center_x) / dx
                    or (dx < 0 and (arena.left - center_x) / dx or math.huge)
                local vertical = dy > 0 and (arena.bottom - center_y) / dy
                    or (dy < 0 and (arena.top - center_y) / dy or math.huge)
                local length = math.min(horizontal, vertical) + 18

                add(shots, "knight", center_x, center_y, angle, pace + 0.72, {
                    kind = "target",
                    duration = 0.40,
                    length = length,
                }, {
                    kind = "roaring_shard",
                    spoke = spoke,
                    rotation = rotation,
                    safe_wedge = safe_wedge,
                    opposite_wedge = opposite_wedge,
                })
            end
        end
    elseif attack and attack.id == "titan_knight_combo" then
        -- Knight diagonals and Titan vertical lances converge on one marked
        -- point. Its alternating offset makes the crossing geometry shift.
        local shift = ((volley + phase) % 2 == 0 and 1 or -1)
        local collision_x = center_x + shift * width * (0.10 + phase * 0.025)
        local collision_y = center_y - shift * height * (0.08 + phase * 0.025)
        local duration = phase == 3 and 0.36 or 0.44
        local entries = {
            {"knight", arena.left - 16, arena.top + height * 0.18},
            {"knight", arena.right + 16, arena.bottom - height * 0.18},
            {"titan", center_x, arena.top - 16},
            {"titan", center_x, arena.bottom + 16},
        }
        for index, entry in ipairs(entries) do
            local dx, dy = collision_x - entry[2], collision_y - entry[3]
            local distance = math.sqrt(dx * dx + dy * dy)
            -- Scale speed to path length so every projectile reaches the
            -- shared collision point at the same moment.
            local synchronized_flight_time = 1.15
            add(shots, entry[1], entry[2], entry[3], atan2(dy, dx),
                distance / synchronized_flight_time, {
                    kind = "target", duration = duration, length = distance,
                }, {
                    kind = "knight_titan_collision", source = entry[1],
                    collision_x = collision_x, collision_y = collision_y,
                    flight_time = synchronized_flight_time, path = index,
                })
        end
    elseif attack and attack.id == "crystal_barrage" then
        -- Seven descending crystal lanes leave one rotating opening. The
        -- staggered shard speeds create a flowing curtain rather than a flat wall.
        local lanes = 7
        local safe_lane = ((volley + phase - 2) % lanes) + 1
        local spacing = width / (lanes + 1)
        local drift = ((volley - 1) % 2 == 0 and -1 or 1) * spacing * 0.18
        for lane = 1, lanes do
            if lane ~= safe_lane then
                local x = arena.left + spacing * lane + drift
                local y = arena.top - 14 - ((lane + volley) % 3) * 9
                add(shots, "knight", x, y, math.pi / 2, pace + 0.22 + (lane % 3) * 0.12, {
                    kind = "falling",
                    duration = phase == 3 and 0.36 or 0.44,
                    length = height + 28,
                }, {
                    kind = "crystal_shard",
                    lane = lane,
                    volley = volley,
                })
            end
        end
    elseif attack and attack.id == "titan_desperation" then
        -- Five heavy bolts alternate edges and lead the SOUL's recent movement.
        local previous = target.previous or target
        local lead_x = math.max(arena.left + 12, math.min(arena.right - 12,
            target.x + (target.x - previous.x) * 1.15))
        local lead_y = math.max(arena.top + 12, math.min(arena.bottom - 12,
            target.y + (target.y - previous.y) * 1.15))
        local spacing = height * 0.16
        for i = 1, 5 do
            local from_right = (i + volley) % 2 == 0
            local x = from_right and (arena.right + 16) or (arena.left - 16)
            local lane = i - 3
            local y = center_y + lane * spacing * 0.52
            local dx, dy = lead_x - x, lead_y - y
            add(shots, "titan", x, y, atan2(dy, dx) + lane * 0.035, pace + 0.72, {
                kind = "target",
                duration = phase == 3 and 0.34 or 0.42,
                length = math.sqrt(dx * dx + dy * dy),
            }, {
                kind = "titan_desperation_shot",
                lane = i,
                lead = true,
            })
        end
    elseif attack and attack.id == "titan_big_shots" then
        -- Big Shots 1: three heavy bolts converge on the current SOUL position
        -- with a narrow fan. The center bolt is direct; the outer bolts force
        -- a deliberate lateral dodge instead of a simple vertical retreat.
        local from_right = volley % 2 == 0
        local x = from_right and (arena.right + 18) or (arena.left - 18)
        local base_y = math.max(arena.top + 18, math.min(arena.bottom - 18, target.y))
        local base_angle = atan2(target.y - base_y, target.x - x)
        local direction = from_right and math.pi or 0
        local duration = phase == 2 and 0.48 or 0.42
        for i = -1, 1 do
            local angle = base_angle + i * 0.19
            local length = math.sqrt(width * width + height * height) * 0.85
            add(shots, "titan", x, base_y + i * 17, angle, pace + 0.55, {
                kind = "target",
                duration = duration,
                length = length,
            }, {
                kind = "titan_big_shot",
                tier = 1,
                spread = i,
            })
        end
    elseif attack and attack.id == "titan_big_shots_2" then
        -- Big Shots 2: four corner-fired bolts cross around a shifting point.
        -- Their diagonal paths create two readable crossing pairs with a
        -- central pocket that moves between volleys.
        local shift = ((volley + phase) % 2 == 0 and 1 or -1)
        local cross_x = center_x + shift * width * 0.10
        local cross_y = center_y - shift * height * 0.08
        local corners = {
            {arena.left - 18, arena.top + 12},
            {arena.right + 18, arena.bottom - 12},
            {arena.right + 18, arena.top + 12},
            {arena.left - 18, arena.bottom - 12},
        }
        for i, corner in ipairs(corners) do
            local dx = cross_x - corner[1]
            local dy = cross_y - corner[2]
            local angle = atan2(dy, dx)
            add(shots, "titan", corner[1], corner[2], angle, pace + 0.48, {
                kind = "target",
                duration = phase == 2 and 0.46 or 0.40,
                length = math.sqrt(dx * dx + dy * dy),
            }, {
                kind = "titan_big_shot",
                tier = 2,
                corner = i,
            })
        end
    elseif attack and attack.id == "titan_big_shots_3" then
        -- Big Shots 3: a heavy radial burst with one rotating missing wedge.
        -- The open wedge is the intended escape route; its position changes
        -- every volley so the player must read the tell before moving.
        local count = 8
        local gap = (volley * 2 + phase) % count
        local rotation = (volley - 1) * 0.12 + (phase - 1) * 0.08
        for i = 0, count - 1 do
            if i ~= gap then
                local angle = rotation + (math.pi * 2 * i / count)
                local dx = math.cos(angle)
                local dy = math.sin(angle)
                local edge_x = dx >= 0 and arena.right or arena.left
                local edge_y = dy >= 0 and arena.bottom or arena.top
                local tx = center_x + dx * width * 0.62
                local ty = center_y + dy * height * 0.62
                local distance = math.sqrt((tx - center_x)^2 + (ty - center_y)^2)
                add(shots, "titan", center_x, center_y, angle, pace + 0.58, {
                    kind = "target",
                    duration = phase == 3 and 0.38 or 0.44,
                    length = distance,
                }, {
                    kind = "titan_big_shot",
                    tier = 3,
                    wedge = i,
                })
            end
        end
    elseif attack and attack.id == "titan_hands" then
        -- Each hand sweeps a four-lane band from an opposite side. Three
        -- knuckles travel per hand, leaving one moving gap in each band.
        -- The gaps are offset so the player can choose either lane without
        -- having to cross a fully sealed wall.
        local upper_center = center_y - height * 0.23
        local lower_center = center_y + height * 0.23
        local spacing = height * 0.11
        local left_x = arena.left - 14
        local right_x = arena.right + 14
        local safe_upper = ((volley + phase - 2) % 4) + 1
        local safe_lower = ((volley + phase) % 4) + 1
        local duration = phase == 1 and 0.50 or (phase == 2 and 0.44 or 0.38)
        local hand_speed = pace * 0.82 + 0.25

        for finger = 1, 4 do
            local y = upper_center + (finger - 2.5) * spacing
            if finger ~= safe_upper then
                add(shots, "titan", left_x, y, 0, hand_speed, {
                    kind = "lane",
                    duration = duration,
                    length = width + 28,
                }, {
                    kind = "titan_hand",
                    side = "left",
                    finger = finger,
                })
            end
        end

        for finger = 1, 4 do
            local y = lower_center + (finger - 2.5) * spacing
            if finger ~= safe_lower then
                add(shots, "titan", right_x, y, math.pi, hand_speed, {
                    kind = "lane",
                    duration = duration,
                    length = width + 28,
                }, {
                    kind = "titan_hand",
                    side = "right",
                    finger = finger,
                })
            end
        end
    elseif attack and attack.id == "twin_slashes" then
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
    if knight_domain_active then
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

    -- Kris's Chimera Shadow Garden calls two opposing roots into each
    -- volley. Their pair rotates around all ten petals, so the pressure moves
    -- around the arena rather than repeating the same lower-edge attack.
    if player_domain_active then
        local root_a = ((volley + phase - 2) % 10) + 1
        local root_b = ((root_a + 4) % 10) + 1
        local root_radius = math.min(width, height) * 0.43 * 0.72
        local target_radius = math.min(width, height) * 0.14
        local duration = phase == 3 and 0.36 or 0.44

        local function rootPosition(index)
            local angle = (index - 1) * (math.pi * 2 / 10)
            return center_x + math.cos(angle) * root_radius,
                center_y + math.sin(angle) * root_radius
        end

        local function addRootBlade(index, side)
            local x, y = rootPosition(index)
            local angle = (index - 1) * (math.pi * 2 / 10)
            local perpendicular = angle + math.pi / 2
            local direction = side == "a" and 1 or -1
            local target_x = center_x + math.cos(perpendicular) * target_radius * direction
            local target_y = center_y + math.sin(perpendicular) * target_radius * direction
            local dx, dy = target_x - x, target_y - y
            local length = math.sqrt(dx * dx + dy * dy)

            add(shots, "combo", x, y, atan2(dy, dx), length / 1.05, {
                kind = "target", duration = duration, length = length,
            }, {
                kind = "chimera_domain_blade",
                root = index,
                side = side,
                target_x = target_x,
                target_y = target_y,
            })
        end

        addRootBlade(root_a, "a")
        addRootBlade(root_b, "b")
    end

    return shots, family
end

return AttackWavePatterns
