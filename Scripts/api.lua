
-- Convert RGB to HSL
function rgb_to_hsl(rgb)
    local r, g, b = rgb.r, rgb.g, rgb.b
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l = 0, 0, ((max + min) / 2)

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return { h = h, s = s, l = l }
end

-- Convert HSL to RGB
function hsl_to_rgb(hsl)
    local h, s, l = hsl.h, hsl.s, hsl.l
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l -- achromatic
    else
        local function hue_to_rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1/3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1/3)
    end

    return { r = r, g = g, b = b }
end

-- Convert RGB to HWB
function rgb_to_hwb(rgb)
    local r, g, b = rgb.r, rgb.g, rgb.b
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, w, bk = 0, 0, 0

    local function calc_whiteness_blackness()
        local w = 1 - max
        local bk = 1 - min
        return w, bk
    end

    if max == min then
        w, bk = calc_whiteness_blackness()
    else
        local d = max - min
        w = 1 - max
        bk = 1 - min

        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return { h = h, w = w, b = bk }
end

-- Convert HWB to RGB
function hwb_to_rgb(hwb)
    local h, w, bk = hwb.h, hwb.w, hwb.b
    local r, g, b

    if w == 1 and bk == 1 then
        r, g, b = 0, 0, 0
    else
        local ratio = 1 - w - bk
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = 1 - bk
        local q = 1 - (bk * f)
        local t = 1 - (bk * (1 - f))

        if i % 6 == 0 then
            r, g, b = p, t, 1 - bk
        elseif i % 6 == 1 then
            r, g, b = q, 1 - bk, p
        elseif i % 6 == 2 then
            r, g, b = 1 - bk, p, t
        elseif i % 6 == 3 then
            r, g, b = 1 - bk, q, p
        elseif i % 6 == 4 then
            r, g, b = t, 1 - bk, q
        else
            r, g, b = p, 1 - bk, t
        end
    end

    return { r = r, g = g, b = b }
end

local function better_quat_rotation(forward, right, up)
    forward = forward:safeNormalize(sm.vec3.new(1, 0, 0))
    right   = right:safeNormalize(sm.vec3.new(0, 0, 1))
    up      = up:safeNormalize(sm.vec3.new(0, 1, 0))

    local m11 = right.x; local m12 = right.y; local m13 = right.z
    local m21 = forward.x; local m22 = forward.y; local m23 = forward.z
    local m31 = up.x; local m32 = up.y; local m33 = up.z

    local biggestIndex = 0
    local fourBiggestSquaredMinus1 = m11 + m22 + m33

    local fourXSquaredMinus1 = m11 - m22 - m33
    if fourXSquaredMinus1 > fourBiggestSquaredMinus1 then
        fourBiggestSquaredMinus1 = fourXSquaredMinus1
        biggestIndex = 1
    end

    local fourYSquaredMinus1 = m22 - m11 - m33
    if fourYSquaredMinus1 > fourBiggestSquaredMinus1 then
        fourBiggestSquaredMinus1 = fourYSquaredMinus1
        biggestIndex = 2
    end

    local fourZSquaredMinus1 = m33 - m11 - m22
    if fourZSquaredMinus1 > fourBiggestSquaredMinus1 then
        fourBiggestSquaredMinus1 = fourZSquaredMinus1
        biggestIndex = 3
    end

    local biggestVal = math.sqrt(fourBiggestSquaredMinus1 + 1.0) * 0.5
    local mult = 0.25 / biggestVal

    if biggestIndex == 1 then
        return sm.quat.new(biggestVal, (m12 + m21) * mult, (m31 + m13) * mult, (m23 - m32) * mult)
    elseif biggestIndex == 2 then
        return sm.quat.new((m12 + m21) * mult, biggestVal, (m23 + m32) * mult, (m31 - m13) * mult)
    elseif biggestIndex == 3 then
        return sm.quat.new((m31 + m13) * mult, (m23 + m32) * mult, biggestVal, (m12 - m21) * mult)
    end

    return sm.quat.new((m23 - m32) * mult, (m31 - m13) * mult, (m12 - m21) * mult, biggestVal)
end


local g_halfPi = math.pi / 2
local function calculateRightVector(dir)
    local v_angle = math.atan2(dir.y, dir.x) - g_halfPi
    return sm.vec3.new(math.cos(v_angle), math.sin(v_angle), 0)
end

function lineTo(posA, posB, effect)
	posA = posA*4
	posB = posB*4
	local dist = (posA - posB)/2

    local right_vector = calculateRightVector(dist)
    local up_vector = dist:cross(right_vector)

    effect:setRotation(better_quat_rotation(up_vector, right_vector, dist))
    effect:setScale(sm.vec3.new(0.1, 0.1, dist:length()/2))
    effect:setPosition((posA - dist)/4)
end
