--[[
Copyright (C) 2025 Federico Ferri

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 3.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see https://www.gnu.org/licenses/.
--]]

local class = require 'middleclass'

local Interval = class 'Interval'

Interval.static.intervals = {
    d1 = -1, P1 =  0, A1 =  1,
    d2 =  0, m2 =  1, M2 =  2, A2 =  3,
    d3 =  2, m3 =  3, M3 =  4, A3 =  5,
    d4 =  4, P4 =  5, A4 =  6,
    d5 =  6, P5 =  7, A5 =  8,
    d6 =  7, m6 =  8, M6 =  9, A6 = 10,
    d7 =  9, m7 = 10, M7 = 11, A7 = 12,
    d8 = 11, P8 = 12, A8 = 13,
}

Interval.static.quality_inverse = {
    P = 'P', d = 'A', A = 'd', m = 'M', M = 'm'
}

local base_intervals = Interval.intervals
for k = 2, 3 do
    for sz = 1, 8 do
        for dA, mp in pairs({ d = -1, A = 1 }) do
            local key = string.rep(dA, k) .. sz
            base_intervals[key] = base_intervals[dA .. sz] + mp * (k - 1)
        end
    end
end

local qi = Interval.quality_inverse
for k = 2, 3 do
    for dA, Ad in pairs({ d = 'A', A = 'd' }) do
        qi[string.rep(dA, k)] = string.rep(Ad, k)
    end
end

function Interval.static:all(include_atypical)
    local intervals = {}
    for name in pairs(self.intervals) do
        local interval = Interval(name)
        if include_atypical or (interval.semitones >= 0 and interval.semitones <= 12) then
            table.insert(intervals, interval)
        end
    end
    table.sort(intervals, function(a, b) return a < b end)
    return intervals
end

function Interval:initialize(quality, size)
    assert(type(quality) == 'string', 'invalid type for quality: ' .. type(quality))
    if not size then
        local interval_str = quality
        quality, size = interval_str:match('^([dA]+)(%d+)$')
        if not quality then
            quality, size = interval_str:match('^([mPM])(%d+)$')
            if not quality then
                error('could not parse interval: ' .. interval_str)
            end
        end
        size = tonumber(size)
    end
    if not Interval.quality_inverse[quality] then
        error('invalid interval quality: ' .. quality)
    end
    if type(size) ~= 'number' or size <= 0 or math.floor(size) ~= size then
        error('invalid interval size: ' .. size)
    end

    self.quality = quality
    self.size = size
    self.semitones = 0

    local temp_size = size
    while temp_size > 8 do
        temp_size = temp_size - 7
        self.semitones = self.semitones + 12
    end

    local key = quality .. tostring(temp_size)
    if not Interval.intervals[key] then
        error('invalid interval ' .. key)
    end
    self.semitones = self.semitones + Interval.intervals[key]
end

function Interval:__add(other)
    local Note = require 'musictheory.Note'
    if other.class == Interval then
        local n = Note('C0')
        return (n + self + other) - n
    else
        error('cannot add ' .. type(other) .. ' to Interval')
    end
end

function Interval:__sub(other)
    local Note = require 'musictheory.Note'
    if other.class == Interval then
        if other.size > self.size then
            error('cannot subtract a greater interval')
        end
        local n = Note('C0')
        return (n + self) - (n + other)
    else
        error('cannot subtract ' .. type(other) .. ' from Interval')
    end
end

function Interval:__lt(other)
    return (self.size < other.size) or (self.size == other.size and self.semitones < other.semitones)
end

function Interval:__le(other)
    return self == other or self < other
end

function Interval:__eq(other)
    return type(other) == 'table' and
           other.class == Interval and
           self.quality == other.quality and
           self.size == other.size
end

function Interval:__tostring()
    return self.quality .. tostring(self.size)
end

function Interval:is_compound()
    return self.size > 8
end

function Interval:split()
    local parts = {}
    local current = Interval(self.quality, self.size)
    while current:is_compound() do
        table.insert(parts, Interval('P8'))
        current.size = current.size - 7
        current.semitones = current.semitones - 12
    end
    table.insert(parts, current)
    return parts
end

function Interval:complement()
    if self:is_compound() then
        error('Cannot invert a compound interval')
    end
    local new_size = 9 - self.size
    local new_quality = Interval.quality_inverse[self.quality]
    return Interval(new_quality, new_size)
end

function Interval:reduce()
    if self.size < 8 then
        return self
    end
    local reduced = Interval(self.quality, self.size)
    reduced.size = reduced.size - 7 * math.floor((reduced.size - 1) / 7)
    return reduced
end

return Interval
