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
    ["aimed-test-pattern"] = true,
    ["execution-test-pattern"] = true,
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


-- SOUL-mode attacks use dedicated geometry rather than falling through to
-- one of the six broad Red-mode projectile families. Each descriptor keeps
-- its source styling and carries a stable key for its mode-specific projectile glyph.
local SOUL_MODE_PATTERN_KEYS = {
    ["falling-columns"] = true, ["updraft-sweep"] = true,
    ["gravity-arc"] = true, ["gravity-inversion"] = true, ["gravity-slam"] = true,
    ["timed-laser-grid"] = true, ["shieldbreaker-strike"] = true,
    ["feint-then-lunge"] = true, ["directional-blade-barrage"] = true,
    ["guardbreak-grid"] = true, ["aimed-projectile-volley"] = true,
    ["target-barricade"] = true, ["ricochet-blades"] = true,
    ["armored-artillery"] = true, ["aimed-crossfire"] = true,
    ["closing-thread-grid"] = true, ["severed-thread-lanes"] = true,
    ["thread-lane-snare"] = true, ["crossing-thread-projectiles"] = true,
    ["thread-cage-crosscut"] = true, ["moving-hazard-lanes"] = true,
    ["chasing-embers"] = true, ["moving-target-slashes"] = true,
    ["shifting-safe-zones"] = true, ["chase-and-sweep"] = true,
    ["timed-pulse-rings"] = true, ["dark-interval-pulses"] = true,
    ["pause-then-strike"] = true, ["cyan-parry-window"] = true,
    ["timed-cross-pulse"] = true,
}

local function buildSoulModePattern(attack, phase, volley, arena, target, pace, shots)
    local pattern = attack and attack.pattern
    if not SOUL_MODE_PATTERN_KEYS[pattern] then return nil end

    local source = inferSource(attack)
    local width = arena.right - arena.left
    local height = arena.bottom - arena.top
    local cx = (arena.left + arena.right) / 2
    local cy = (arena.top + arena.bottom) / 2
    local duration = phase == 3 and 0.34 or (phase == 2 and 0.40 or 0.46)
    local function marker(variant, extra)
        local result = {kind = "soul_mode_pattern", pattern = pattern, variant = variant}
        for key, value in pairs(extra or {}) do result[key] = value end
        return result
    end
    local function aim(x, y, tx, ty, speed, spread, variant, extra)
        local dx, dy = tx - x, ty - y
        local distance = math.sqrt(dx * dx + dy * dy)
        local metadata = {target_x = tx, target_y = ty}
        for key, value in pairs(extra or {}) do metadata[key] = value end
        add(shots, source, x, y, atan2(dy, dx) + (spread or 0), speed or pace + 0.35, {
            kind = "target", duration = duration, length = math.max(12, distance),
        }, marker(variant, metadata))
    end
    local function lane(x, y, direction, speed, length, variant, lane_index)
        add(shots, source, x, y, direction, speed or pace + 0.25, {
            kind = "lane", duration = duration, length = length or width + 24,
        }, marker(variant, {lane = lane_index}))
    end
    local function falling(x, y, direction, speed, length, variant, lane_index)
        add(shots, source, x, y, direction, speed or pace + 0.2, {
            kind = "falling", duration = duration, length = length or height + 24,
        }, marker(variant, {lane = lane_index}))
    end
    local side_x = volley % 2 == 0 and arena.right + 14 or arena.left - 14
    local side_dir = volley % 2 == 0 and math.pi or 0
    local lead = target.previous or target
    local lead_x = math.max(arena.left + 10, math.min(arena.right - 10,
        target.x + (target.x - lead.x) * 0.9))
    local lead_y = math.max(arena.top + 10, math.min(arena.bottom - 10,
        target.y + (target.y - lead.y) * 0.9))

    if pattern == "falling-columns" then
        local count, gap = 6, (volley + phase) % 6 + 1
        for i = 1, count do
            if i ~= gap then falling(arena.left + width * i / (count + 1), arena.top - 12,
                math.pi / 2, pace + 0.2 + i * 0.025, height + 24, "gravity_column", i) end
        end
    elseif pattern == "updraft-sweep" then
        for i = -2, 2 do
            local x = arena.left + width * (i + 3) / 6
            local drift = (volley % 2 == 0 and 1 or -1) * 0.22
            add(shots, source, x, arena.bottom + 12, math.pi * (0.5 - drift), pace + 0.35, {
                kind = "falling", duration = duration, length = height + 24,
            }, marker("updraft_column", {column = i + 3}))
        end
        lane(arena.left - 10, cy - height * 0.18, 0, pace + 0.45,
            width + 20, "lifted_sweep", 1)
    elseif pattern == "gravity-arc" then
        for i = -2, 2 do
            local x = side_x
            local y = cy + i * height * 0.12
            aim(x, y, cx + (volley % 2 == 0 and 1 or -1) * width * 0.22,
                cy - i * height * 0.10, pace + 0.35, i * 0.035, "gravity_arc")
        end
    elseif pattern == "gravity-inversion" then
        for i = 1, 5 do
            local x = arena.left + width * i / 6
            local from_bottom = (i + volley) % 2 == 0
            falling(x, from_bottom and arena.bottom + 10 or arena.top - 10,
                from_bottom and -math.pi / 2 or math.pi / 2, pace + 0.3,
                height + 20, "inversion_lane", i)
        end
    elseif pattern == "gravity-slam" then
        local x = cx + (volley % 2 == 0 and 1 or -1) * width * 0.16
        local y = cy + (phase - 2) * height * 0.10
        for i = 0, 3 do
            local angle = i * math.pi / 2 + (volley % 2) * math.pi / 4
            local sx, sy = x + math.cos(angle) * width * 0.55, y + math.sin(angle) * height * 0.55
            aim(sx, sy, x, y, pace + 0.45, 0, "gravity_slam")
        end
    elseif pattern == "timed-laser-grid" then
        local gap = (volley + phase) % 5 + 1
        for i = 1, 5 do
            if i ~= gap then lane(arena.left - 10, arena.top + height * i / 6,
                0, pace + 0.2, width + 20, "laser_grid", i) end
        end
        lane(arena.right + 10, cy, math.pi, pace + 0.2, width + 20, "laser_crossbar", 0)
    elseif pattern == "shieldbreaker-strike" then
        for i = -1, 1 do
            aim(side_x, target.y + i * 22, target.x, target.y, pace + 0.65,
                i * 0.12, "shieldbreaker_heavy")
        end
    elseif pattern == "feint-then-lunge" then
        local feint_y = target.y + (volley % 2 == 0 and -1 or 1) * height * 0.28
        aim(side_x, feint_y, target.x, feint_y, pace + 0.15, 0, "feint")
        aim(side_x, cy, target.x, target.y, pace + 0.72, 0, "lunge")
    elseif pattern == "directional-blade-barrage" then
        for i = 1, 6 do
            local from_left = (i + volley) % 2 == 0
            local x = from_left and arena.left - 12 or arena.right + 12
            local y = arena.top + height * i / 7
            lane(x, y, from_left and 0 or math.pi, pace + 0.28 + i * 0.035,
                width + 24, "directional_blade", i)
        end
    elseif pattern == "guardbreak-grid" then
        local gap_a, gap_b = (volley % 4) + 1, ((volley + 2) % 4) + 1
        for i = 1, 4 do
            local y = cy - height * 0.22 + (i - 1) * height * 0.14
            if i ~= gap_a then lane(arena.left - 12, y, 0, pace + 0.25, width + 24, "upper_guard_grid", i) end
            if i ~= gap_b then lane(arena.right + 12, y, math.pi, pace + 0.25, width + 24, "lower_guard_grid", i) end
        end
    elseif pattern == "aimed-projectile-volley" then
        for i = -1, 1 do aim(side_x, target.y + i * 16, target.x, target.y, pace + 0.38, i * 0.10, "aimed_volley") end
    elseif pattern == "target-barricade" then
        local gap = (volley + phase) % 7 + 1
        for i = 1, 7 do
            if i ~= gap then
                local y = arena.top + height * i / 8
                lane(side_x, y, side_dir, pace + 0.2, width + 28, "target_barricade", i)
            end
        end
    elseif pattern == "ricochet-blades" then
        local ricochet_bounds = {
            left = arena.left + 8, right = arena.right - 8,
            top = arena.top + 8, bottom = arena.bottom - 8,
        }
        for i = 1, 4 do
            local y = arena.top + height * i / 5
            local from_left = (i + volley) % 2 == 0
            local x = from_left and arena.left + 12 or arena.right - 12
            aim(x, y, cx + (from_left and 1 or -1) * width * 0.18,
                arena.bottom - y + arena.top, pace + 0.42, (i % 2 == 0 and 1 or -1) * 0.08,
                "ricochet_blade", {
                    ricochet_bounds = ricochet_bounds,
                    ricochet_bounces = 2,
                })
        end
    elseif pattern == "armored-artillery" then
        for i = -1, 1 do
            aim(side_x, cy + i * height * 0.20, target.x, target.y, pace + 0.3,
                i * 0.05, "armored_artillery")
        end
    elseif pattern == "aimed-crossfire" then
        aim(arena.left - 12, target.y - height * 0.20, target.x, target.y, pace + 0.4, 0, "crossfire_left")
        aim(arena.right + 12, target.y + height * 0.20, target.x, target.y, pace + 0.4, 0, "crossfire_right")
        aim(cx, arena.top - 12, target.x, target.y, pace + 0.5, 0, "crossfire_top")
    elseif pattern == "closing-thread-grid" then
        for i = 1, 4 do
            local y = arena.top + height * i / 5
            lane(arena.left - 12, y, 0, pace + 0.18, width + 24, "closing_thread_left", i)
            lane(arena.right + 12, y, math.pi, pace + 0.18, width + 24, "closing_thread_right", i)
        end
    elseif pattern == "severed-thread-lanes" then
        local safe = (volley + phase) % 6 + 1
        for i = 1, 6 do
            if i ~= safe then
                local x = arena.left + width * i / 7
                falling(x, arena.top - 10, math.pi / 2, pace + 0.24, height + 20, "severed_thread", i)
            end
        end
    elseif pattern == "thread-lane-snare" then
        local y = math.max(arena.top + 12, math.min(arena.bottom - 12, target.y))
        lane(arena.left - 10, y - 14, 0, pace + 0.3, width + 20, "snare_upper", 1)
        lane(arena.right + 10, y + 14, math.pi, pace + 0.3, width + 20, "snare_lower", 2)
    elseif pattern == "crossing-thread-projectiles" then
        for i = 1, 4 do
            local from_left = i % 2 == 0
            local x = from_left and arena.left - 10 or arena.right + 10
            local y = arena.top + height * i / 5
            aim(x, y, from_left and arena.right + 8 or arena.left - 8,
                arena.bottom - (y - arena.top), pace + 0.32, 0, "crossing_thread")
        end
    elseif pattern == "thread-cage-crosscut" then
        local gap = (volley + 1) % 5 + 1
        for i = 1, 5 do
            if i ~= gap then
                lane(arena.left - 10, arena.top + height * i / 6, 0, pace + 0.2, width + 20, "thread_cage", i)
            end
        end
        aim(cx, arena.top - 10, target.x, target.y, pace + 0.52, 0, "thread_crosscut")
    elseif pattern == "moving-hazard-lanes" then
        for i = 1, 5 do
            local offset = math.sin((volley + i) * 0.9) * height * 0.12
            lane(side_x, cy + (i - 3) * height * 0.14 + offset, side_dir,
                pace + 0.22, width + 28, "moving_hazard", i)
        end
    elseif pattern == "chasing-embers" then
        for i = -1, 2 do
            aim(side_x, cy + i * height * 0.16, lead_x, lead_y, pace + 0.4,
                i * 0.07, "chasing_ember")
        end
    elseif pattern == "moving-target-slashes" then
        for i = -1, 1 do
            local tx = math.max(arena.left + 10, math.min(arena.right - 10, target.x + i * width * 0.18))
            local ty = math.max(arena.top + 10, math.min(arena.bottom - 10, target.y + (volley % 2 == 0 and 1 or -1) * height * 0.16))
            aim(side_x, cy + i * height * 0.22, tx, ty, pace + 0.45, 0, "moving_target_slash")
        end
    elseif pattern == "shifting-safe-zones" then
        local gap = (volley * 2 + phase) % 6 + 1
        for i = 1, 6 do
            if i ~= gap then
                local x = arena.left + width * i / 7
                falling(x, arena.top - 10, math.pi / 2, pace + 0.22, height + 20, "shifting_safe_zone", i)
            end
        end
    elseif pattern == "chase-and-sweep" then
        aim(arena.left - 10, target.y - 20, lead_x, lead_y, pace + 0.42, 0, "chase")
        aim(arena.right + 10, target.y + 20, lead_x, lead_y, pace + 0.42, 0, "chase")
        lane(arena.left - 12, cy + (volley % 2 == 0 and 1 or -1) * height * 0.28,
            0, pace + 0.22, width + 24, "sweep", 1)
    elseif pattern == "timed-pulse-rings" then
        local count = 8 + phase * 2
        local rotation = (volley % 2) * math.pi / count
        for i = 0, count - 1 do
            local angle = rotation + i * math.pi * 2 / count
            add(shots, source, cx, cy, angle, pace + 0.28, {
                kind = "target", duration = duration, length = math.min(width, height) * 0.72,
            }, marker("timed_pulse_ring", {spoke = i}))
        end
    elseif pattern == "dark-interval-pulses" then
        local count = volley % 2 == 0 and 6 or 10
        local gap = (volley + phase) % count
        for i = 0, count - 1 do
            if i ~= gap then
                local angle = i * math.pi * 2 / count + (volley % 2) * 0.08
                add(shots, source, cx, cy, angle, pace + 0.35, {
                    kind = "target", duration = duration, length = math.min(width, height) * 0.68,
                }, marker(volley % 2 == 0 and "dark_interval" or "pulse_return", {spoke = i}))
            end
        end
    elseif pattern == "pause-then-strike" then
        aim(side_x, cy, target.x, target.y, pace + 0.78, 0, "pause_then_strike")
    elseif pattern == "cyan-parry-window" then
        local from_right = phase % 2 == 0
        local x = from_right and arena.right + 12 or arena.left - 12
        aim(x, target.y, target.x, target.y, pace + 0.7, 0, "cyan_execution")
    elseif pattern == "timed-cross-pulse" then
        for i = -1, 1 do
            lane(arena.left - 10, cy + i * height * 0.18, 0, pace + 0.3,
                width + 20, "horizontal_pulse", i + 2)
            falling(cx + i * width * 0.18, arena.top - 10, math.pi / 2,
                pace + 0.3, height + 20, "vertical_pulse", i + 2)
        end
    end

    return "soul_mode"
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

    local custom_family = buildSoulModePattern(attack, phase, volley, arena, target, pace, shots)
    if not custom_family then
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
    end
    family = custom_family or family

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
