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

local PitchClass   = require 'musictheory.PitchClass'
local Note         = require 'musictheory.Note'
local Interval     = require 'musictheory.Interval'
local Chord        = require 'musictheory.Chord'

local Scale = class 'Scale'

Scale.static.scales = {
    major = {'P1', 'M2', 'M3', 'P4', 'P5', 'M6', 'M7'},
    natural_minor = {'P1', 'M2', 'm3', 'P4', 'P5', 'm6', 'm7'},
    harmonic_minor = {'P1', 'M2', 'm3', 'P4', 'P5', 'm6', 'M7'},
    melodic_minor = {'P1', 'M2', 'm3', 'P4', 'P5', 'M6', 'M7'},
    major_pentatonic = {'P1', 'M2', 'M3', 'P5', 'M6'},
    minor_pentatonic = {'P1', 'm3', 'P4', 'P5', 'm7'},
    -- Greek modes
    ionian = {'P1', 'M2', 'M3', 'P4', 'P5', 'M6', 'M7'},
    dorian = {'P1', 'M2', 'm3', 'P4', 'P5', 'M6', 'm7'},
    phrygian = {'P1', 'm2', 'm3', 'P4', 'P5', 'm6', 'm7'},
    lydian = {'P1', 'M2', 'M3', 'A4', 'P5', 'M6', 'M7'},
    mixolydian = {'P1', 'M2', 'M3', 'P4', 'P5', 'M6', 'm7'},
    aeolian = {'P1', 'M2', 'm3', 'P4', 'P5', 'm6', 'm7'},
    locrian = {'P1', 'm2', 'm3', 'P4', 'd5', 'm6', 'm7'},
    -- non-diatonic scales:
    phrygian_dominant = {'P1', 'm2', 'M3', 'P4', 'P5', 'm6', 'm7'},
    ukrainian_dorian = {'P1', 'M2', 'm3', 'A4', 'P5', 'm6', 'm7'},
    hungarian_minor = {'P1', 'M2', 'm3', 'A4', 'P5', 'm6', 'M7'},
    lydian_augmented = {'P1', 'M2', 'M3', 'A4', 'A5', 'M6', 'M7'},
    lydian_dominant = {'P1', 'M2', 'M3', 'A4', 'P5', 'M6', 'm7'},
    enigmatic = {'P1', 'm2', 'M3', 'A4', 'A5', 'A6', 'M7'},
    double_harmonic = {'P1', 'm2', 'M3', 'P4', 'P5', 'm6', 'M7'},
    --double_harmonic_minor = hungarian_minor,
    persian = {'P1', 'm2', 'M3', 'P4', 'd5', 'm6', 'M7'},
    altered_scale = {'P1', 'm2', 'm3', 'M3', 'A4', 'm6', 'm7'},
    oriental = {'P1', 'm2', 'M3', 'P4', 'd5', 'M6', 'm7'},
    ionian_A2A5 = {'P1', 'A2', 'M3', 'P4', 'A5', 'M6', 'M7'},
    locrian_d3d7 = {'P1', 'm2', 'd3', 'P4', 'd5', 'm6', 'd7'},
    lydian_A2A6 = {'P1', 'A2', 'M3', 'A4', 'P5', 'A6', 'M7'},
    ultraphrygian = {'P1', 'm2', 'm3', 'd4', 'P5', 'm6', 'd7'},
}

Scale.static.greek_modes = {
    [1] = 'ionian',
    [2] = 'dorian',
    [3] = 'phrygian',
    [4] = 'lydian',
    [5] = 'mixolydian',
    [6] = 'aeolian',
    [7] = 'locrian',
}

Scale.static.greek_modes_set = {}
for _, name in pairs(Scale.greek_modes) do
    Scale.greek_modes_set[name] = true
end

function Scale.static:all(include_greek_modes)
    local roots = PitchClass:all()
    local scales = {}

    for _, root in ipairs(roots) do
        for name, intervals in pairs(self.scales) do
            if include_greek_modes or not self.greek_modes_set[name] then
                table.insert(scales, Scale(root, name))
            end
        end
    end

    table.sort(scales, function(a, b) return a < b end)
    return scales
end

function Scale:initialize(root, scale_type)
    if type(root) == 'string' then
        root = PitchClass(root)
    end

    if root.class ~= PitchClass then
        error('invalid root type')
    end

    self.root = root
    self.recipe = nil

    if type(scale_type) == 'string' then
        if not Scale.scales[scale_type] then
            error('no such scale: ' .. scale_type)
        end
        self.recipe = scale_type
        scale_type = Scale.scales[scale_type]
    end

    -- Convert string intervals to Interval objects
    local intervals = {}
    for _, interval_str in ipairs(scale_type) do
        table.insert(intervals, Interval(interval_str))
    end

    self.intervals = intervals
end

function Scale:contains(item)
    if item.class == Note then
        return self:contains(item.pitch_class)
    elseif item.class == PitchClass then
        for _, pitch in ipairs(self.pitches) do
            if pitch == item then
                return true
            end
        end
        return false
    elseif item.class == Chord then
        for _, pitch in ipairs(item.pitches) do
            if not self:contains(pitch) then
                return false
            end
        end
        return true
    elseif type(item) == 'table' then
        for _, element in ipairs(item) do
            if not self:contains(element) then
                return false
            end
        end
        return true
    end
    return false
end

function Scale:chord(i, ext)
    local r = self[i]
    local intervals = {Interval 'P1', self[i + 2] - r, self[i + 4] - r}
    if ext == 7 or ext == 9 or ext == 11 or ext == 13 then
        table.insert(intervals, self[i + 6] - r)
    end
    if ext == 9 or ext == 11 or ext == 13 then
        table.insert(intervals, self[i + 8] - r)
    end
    if ext == 11 or ext == 13 then
        table.insert(intervals, self[i + 10] - r)
    end
    if ext == 13 then
        table.insert(intervals, self[i + 12] - r)
    end
    if ext == 4 then
        table.insert(intervals, self[i + 3] - r)
    end
    if ext == 6 then
        table.insert(intervals, self[i + 5] - r)
    end
    return Chord(r.pitch_class, intervals)
end

function Scale:__index(k)
    if type(k) == 'number' then
        local n = #self.intervals
        local octaves = math.floor((k - 1) / n)
        local offset = ((k - 1) % n) + 1

        local base_note = self.root:to_octave(4 + octaves)
        return base_note + self.intervals[offset]
    elseif k == 'pitches' then
        if self._pitches then
            return self._pitches
        end
        self._pitches = {}
        for i = 1, #self.intervals do
            table.insert(self._pitches, self[i].pitch_class)
        end
        return self._pitches
    end
    return rawget(self, k) or rawget(Scale, k)
end

function Scale:__len()
    return #self.intervals
end

function Scale:__tostring()
    if self.recipe then
        return tostring(self.root) .. ' ' .. self.recipe
    else
        local interval_strs = {}
        for _, interval in ipairs(self.intervals) do
            table.insert(interval_strs, tostring(interval))
        end
        return tostring(self.root) .. ' <' .. table.concat(interval_strs, '-') .. '>'
    end
end

function Scale:__repr()
    if self.recipe then
        return 'Scale(' .. tostring(self.root) .. ', ' .. self.recipe .. ')'
    else
        local interval_strs = {}
        for _, interval in ipairs(self.intervals) do
            table.insert(interval_strs, tostring(interval))
        end
        return 'Scale(' .. tostring(self.root) .. ', {' .. table.concat(interval_strs, ', ') .. '})'
    end
end

function Scale:__lt(other)
    if self.root < other.root then
        return true
    elseif self.root == other.root then
        for i = 1, math.min(#self.intervals, #other.intervals) do
            if self.intervals[i] < other.intervals[i] then
                return true
            elseif self.intervals[i] > other.intervals[i] then
                return false
            end
        end
        return #self.intervals < #other.intervals
    end
    return false
end

function Scale:__le(other)
    return self == other or self < other
end

function Scale:__eq(other)
    if self.root ~= other.root then
        return false
    end
    if #self.intervals ~= #other.intervals then
        return false
    end
    for i = 1, #self.intervals do
        if self.intervals[i] ~= other.intervals[i] then
            return false
        end
    end
    return true
end

function Scale:__hash()
    local h = self.root:__hash()
    for _, interval in ipairs(self.intervals) do
        h = h + interval:__hash()
    end
    return h
end

function Scale:is_diatonic()
    if #self.intervals ~= 7 then return false end
    local semitones = {}
    for _, interval in ipairs(self.intervals) do
        table.insert(semitones, interval.semitones)
    end
    table.sort(semitones)
    local intervals = {}
    for i = 1, #semitones do
        local next_i = (i % #semitones) + 1
        intervals[i] = (semitones[next_i] - semitones[i]) % 12
    end
    -- check if intervals match WWHWWWH pattern (or a rotation)
    local pattern = {2,2,1,2,2,2,1}
    for shift = 0, 6 do
        local match = true
        for i = 1, 7 do
            if intervals[i] ~= pattern[((i + shift - 1) % 7) + 1] then
                match = false
                break
            end
        end
        if match then return true end
    end
    return false
end

function Scale:find_similar(max_levenshtein_dist, include_greek_modes)
    if include_greek_modes == nil then
        include_greek_modes = Scale.greek_modes_set[self.recipe] ~= nil
    end

    local similar_scales = {}
    for _, scale in Scale:all(include_greek_modes) do
        if scale ~= self and self:distance(scale) <= max_levenshtein_dist then
            table.insert(similar_scales, scale)
        end
    end

    table.sort(similar_scales, function(a, b) return a < b end)
    return similar_scales
end

function Scale:distance(scale)
    local current_pitches = {}
    for _, pitch in ipairs(self.pitches) do
        current_pitches[tostring(pitch)] = true
    end
    local d = #self.intervals
    for _, pitch in ipairs(scale.pitches) do
        if current_pitches[tostring(pitch)] then
            d = d - 1
        end
    end
    return d
end

function Scale:wpcp_score(weighted_items)
    -- first, expand items to pitches:
    local weighted_pitches_m = {}
    for item, weight in pairs(weighted_items) do
        assert(type(item) == 'table', 'invalid item type: ' .. type(item))
        if item.class == PitchClass then
            weighted_pitches_m[item] = weighted_pitches_m[item] or {}
            table.insert(weighted_pitches_m[item], weight)
        elseif item.class == Note then
            weighted_pitches_m[item.pitch_class] = weighted_pitches_m[item.pitch_class] or {}
            table.insert(weighted_pitches_m[item.pitch_class], weight)
        elseif item.class == Chord or item.class == Scale then
            for _, pitch in ipairs(item.pitches) do
                weighted_pitches_m[pitch] = weighted_pitches_m[pitch] or {}
                table.insert(weighted_pitches_m[pitch], weight)
            end
        else
            error('invalid item class: ' .. tostring(item.class))
        end
    end

    -- then average weight:
    local weighted_pitches = {}
    for pitch, weights in pairs(weighted_pitches_m) do
        weighted_pitches[pitch] = 0.0
        for _, weight in ipairs(weights) do
            weighted_pitches[pitch] = weighted_pitches[pitch] + weight
        end
        weighted_pitches[pitch] = weighted_pitches[pitch] / #weights
    end

    -- compute score:
    local score = 0.0
    if self.recipe == 'natural_minor' then
        -- prefer major
        score = -0.01
    end
    for pitch, weight in pairs(weighted_pitches) do
        if self.root == pitch then
            score = score + 1.05 * weight
        elseif self:contains(pitch) then
            score = score + 1.0 * weight
        else
            score = score - 0.5 * weight
        end
    end
    return score
end

function Scale.static:identify(notes_or_chords, include_greek_modes)
    local matching_scales = {}
    for _, scale in ipairs(Scale:all(include_greek_modes)) do
        if scale:contains(notes_or_chords) then
            table.insert(matching_scales, scale)
        end
    end
    table.sort(matching_scales, function(a, b) return a < b end)
    return matching_scales
end

function Scale.static:identify_wpcp_all(weighted_items, include_greek_modes)
    local scores = {}
    for _, scale in ipairs(Scale:all(include_greek_modes)) do
        table.insert(scores, {scale:wpcp_score(weighted_items), scale})
    end
    table.sort(scores, function(a, b) return a[1] > b[1] end)
    return scores
end

function Scale.static:identify_wpcp(weighted_items, include_greek_modes)
    local scores = self:identify_wpcp_all(weighted_items, include_greek_modes)
    if #scores == 0 then return end
    return scores[1][2], scores[1][1]
end

return Scale
