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
local utils = require 'musictheory.utils'

local PitchClass   = require 'musictheory.PitchClass'
local Note         = require 'musictheory.Note'
local Interval     = require 'musictheory.Interval'

local Chord = class 'Chord'

Chord.static.recipes = {
    ['maj'] = {'P1', 'M3', 'P5'},
    ['min'] = {'P1', 'm3', 'P5'},
    ['aug'] = {'P1', 'M3', 'A5'},
    ['dim'] = {'P1', 'm3', 'd5'},
    ['dom7'] = {'P1', 'M3', 'P5', 'm7'},
    ['min7'] = {'P1', 'm3', 'P5', 'm7'},
    ['maj7'] = {'P1', 'M3', 'P5', 'M7'},
    ['aug7'] = {'P1', 'M3', 'A5', 'm7'},
    ['dim7'] = {'P1', 'm3', 'd5', 'd7'},
    ['min7dim5'] = {'P1', 'm3', 'd5', 'm7'},
    ['sus2'] = {'P1', 'M2', 'P5'},
    ['sus4'] = {'P1', 'P4', 'P5'},
    ['dom7sus4'] = {'P1', 'P4', 'P5', 'm7'},
    ['maj7sus4'] = {'P1', 'P4', 'P5', 'M7'},
    ['open5'] = {'P1', 'P5', 'P8'},
    ['dom9'] = {'P1', 'M3', 'P5', 'm7', 'M9'},
    ['min9'] = {'P1', 'm3', 'P5', 'm7', 'M9'},
    ['maj9'] = {'P1', 'M3', 'P5', 'M7', 'M9'},
    ['aug9'] = {'P1', 'M3', 'A5', 'm7', 'M9'},
    ['dim9'] = {'P1', 'm3', 'd5', 'd7', 'M9'},
    ['dom11'] = {'P1', 'M3', 'P5', 'm7', 'M9', 'P11'},
    ['min11'] = {'P1', 'm3', 'P5', 'm7', 'M9', 'P11'},
    ['maj11'] = {'P1', 'M3', 'P5', 'M7', 'M9', 'P11'},
    ['aug11'] = {'P1', 'M3', 'A5', 'm7', 'M9', 'P11'},
    ['dim11'] = {'P1', 'm3', 'd5', 'd7', 'M9', 'P11'},
    ['dom13'] = {'P1', 'M3', 'P5', 'm7', 'M9', 'P11', 'm13'},
    ['min13'] = {'P1', 'm3', 'P5', 'm7', 'M9', 'P11', 'm13'},
    ['maj13'] = {'P1', 'M3', 'P5', 'M7', 'M9', 'P11', 'M13'},
    ['aug13'] = {'P1', 'M3', 'A5', 'm7', 'M9', 'P11', 'm13'},
    ['maj6'] = {'P1', 'M3', 'P5', 'M6'},
    ['min/min6'] = {'P1', 'm3', 'P5', 'm6'},
    ['dom6'] = {'P1', 'M3', 'P5', 'm6'},
    ['min/maj6'] = {'P1', 'm3', 'P5', 'M6'},
}

Chord.static.aliases = {
    ['M'] = 'maj',
    ['m'] = 'min',
    ['+'] = 'aug',
    ['°'] = 'dim',
    ['sus'] = 'sus4',
    ['7'] = 'dom7',
    ['m7'] = 'min7',
    ['M7'] = 'maj7',
    ['+7'] = 'aug7',
    ['7aug5'] = 'aug7',
    ['7#5'] = 'aug7',
    ['m7dim5'] = 'min7dim5',
    ['°7'] = 'min7dim5',
    ['ø7'] = 'min7dim5',
    ['m7b5'] = 'min7dim5',
    ['7sus'] = 'dom7sus4',
    ['7sus4'] = 'dom7sus4',
    ['maj7sus'] = 'maj7sus4',
    ['9'] = 'dom9',
    ['m9'] = 'min9',
    ['M9'] = 'maj9',
    ['+9'] = 'aug9',
    ['°9'] = 'dim9',
    ['M6'] = 'maj6',
    ['m6'] = 'min/maj6',
    ['m/m6'] = 'min/min6',
    ['6'] = 'dom6',
    ['m/M6'] = 'min/maj6',
}

function Chord.static:all(root)
    local roots
    if not root then
        roots = PitchClass:all()
    elseif type(root) == 'table' and root.class == PitchClass then
        roots = {root}
    elseif type(root) == 'table' then
        roots = root
    else
        error('invalid root type')
    end

    local chords = {}
    for _, r in ipairs(roots) do
        for name in pairs(self.recipes) do
            table.insert(chords, Chord(r, name))
        end
    end
    table.sort(chords, function(a, b) return a < b end)
    return chords
end

function Chord:initialize(root, chord_type)
    --[[
    usages:
        - Chord('Cmaj7'): parse a chord from string
        - Chord(chort_in_root_position, inversion): chord inversion -> chord:invert(inversion)
        - Chord(PitchClass('C'), 'maj7'): construct chord from root (PitchClass) & recipe
    --]]

    if type(root) == 'string' and chord_type == nil then
        local chord_str = root
        if chord_str:find('/') then
            local chord_str, bass_str = chord_str:match('^([^/]+)/(.+)$')
            self.root_chord = Chord(chord_str)
            self.bass = PitchClass(bass_str)
        else
            local suffixes = {}
            for name in pairs(Chord.recipes) do table.insert(suffixes, name) end
            for alias in pairs(Chord.aliases) do table.insert(suffixes, alias) end
            table.sort(suffixes, function(a, b) return #a > #b end)

            for _, suffix in ipairs(suffixes) do
                if #chord_str >= #suffix and chord_str:sub(-#suffix) == suffix then
                    local root_str = chord_str:sub(1, -#suffix - 1)
                    self.root = PitchClass(root_str)
                    self.recipe = Chord.aliases[suffix] or suffix
                    break
                end
            end

            assert(self.root and self.recipe, 'invalid chord: ' .. chord_str)
        end
    elseif Chord.isInstanceOf(root, Chord) then
        self.root_chord = root
        if math.type(chord_type) == 'integer' then
            assert(chord_type > 0 and chord_type < #self.root_chord.pitches, 'invalid inversion number: ' .. chord_type)
            self.bass = self.root_chord.pitches[chord_type + 1]
        elseif PitchClass.isInstanceOf(chord_type, PitchClass) then
            self.bass = chord_type
        else
            error('invalid bass type or inversion number: ' .. type(chord_type))
        end
    else
        self.root = root
        if type(self.root) == 'string' then
            self.root = PitchClass(self.root)
        elseif Note.isInstanceOf(self.root, Note) then
            self.root = self.root.pitch_class
        end
        assert(PitchClass.isInstanceOf(self.root, PitchClass), 'invalid root type')

        if type(chord_type) == 'string' then
            chord_type = self.class.aliases[chord_type] or chord_type
            self.recipe = chord_type
            if not self.class.recipes[chord_type] then
                error('invalid chord_type: ' .. chord_type)
            end
        elseif type(chord_type) == 'table' and chord_type[1].class == Interval then
            self.recipe = '[' .. table.concat(utils.table.map(tostring, chord_type), ',') .. ']'
            self.intervals = chord_type
        else
            error('invalid chord_type type: ' .. type(chord_type))
        end
    end

    if self.root_chord and self.bass then
        self.root = self.root_chord.root

        for i, pc in ipairs(self.root_chord.pitches) do
            if pc == self.bass then
                self.inversion = i - 1
            end
        end
        assert(self.inversion, 'bass note is not part of the chord')

        self.intervals = {}
        local n = #self.root_chord.intervals
        for i = 1, n do
            table.insert(self.intervals, self.root_chord.intervals[(i - 1 + self.inversion) % n + 1])
        end
    end

    if self.intervals == nil then
        assert(self.recipe ~= nil, 'missing recipe')
        assert(Chord.recipes[self.recipe], 'invalid recipe')
        self.intervals = {}
        for _, interval in ipairs(Chord.recipes[self.recipe]) do
            if type(interval) == 'string' then
                table.insert(self.intervals, Interval(interval))
            elseif Interval.isInstanceOf(interval, Interval) then
                table.insert(self.intervals, interval)
            else
                error('invalid interval type: ' .. type(interval))
            end
        end
    end
    table.sort(self.intervals, function(a, b) return a < b end)

    assert(self.root)
end

function Chord:contains(x)
    if Interval.isInstanceOf(x, Interval) then
        for _, i in ipairs(self.intervals) do
            if i == x then return true end
        end
        return false
    elseif PitchClass.isInstanceOf(x, PitchClass) or Note.isInstanceOf(x, Note) then
        if x:isInstanceOf(Note) then
            x = x.pitch_class
        end
        local r = self.root:to_octave(1)
        for _, i in ipairs(self.intervals) do
            if x == (r + i).pitch_class then return true end
        end
        return false
    else
        error 'invalid type'
    end
end

function Chord:__index(k)
    if k == 'pitches' then
        local pitches = {}
        for _, note in ipairs(self:notes()) do
            table.insert(pitches, note.pitch_class)
        end
        return pitches
    end
    return rawget(self, k)
end

function Chord:__lt(other)
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

function Chord:__le(other)
    return self == other or self < other
end

function Chord:__eq(other)
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

function Chord:__tostring()
    if self.root_chord then
        return tostring(self.root_chord) .. '/' .. tostring(self.bass)
    else
        return tostring(self.root) .. self.recipe
    end
end

function Chord:__hash()
    if self.root_chord then
        return self.root_chord:__hash() + self.bass:__hash()
    end
    local h = self.root:__hash()
    for _, interval in ipairs(self.intervals) do
        h = h + interval:__hash()
    end
    return h
end

function Chord:__len()
    return #self.intervals
end

function Chord:notes(base_octave)
    base_octave = base_octave or 4
    local root_note = Note(self.root, base_octave)
    local notes = {}
    for _, interval in ipairs(self.intervals) do
        table.insert(notes, root_note + interval)
    end
    if self.inversion then
        for i = 1, self.inversion do
            table.insert(notes, table.remove(notes, 1) + Interval 'P8')
        end
    end
    return notes
end

function Chord:invert(num_times)
    if PitchClass.isInstanceOf(num_times, PitchClass) then
        local root_chord = self.root_chord or self
        for i, pc in ipairs(root_chord.pitches) do
            if pc == self.bass then return root_chord:invert(i - 1) end
        end
        error('bass note is not part of the chord')
    else
        assert(math.type(num_times) == 'integer', 'incorrect inversion type: ' .. type(num_times))
        if num_times == 0 then
            return self
        else
            if self.root_chord then
                return self.root_chord:invert(self.inversion + num_times)
            else
                return Chord(self, num_times)
            end
        end
    end
end

function Chord.static:identify_from_intervals(intervals)
    local root = Note 'C4'
    local notes = utils.table.map(function(i) return root + i end, intervals)
    return Chord:identify_from_notes(notes)
end

function Chord.static:identify_from_notes(notes)
    local pitches = utils.table.map(function(n) return n.pitch_class end, notes)
    return Chord:identify_from_pitches(pitches)
end

function Chord.static:identify_from_pitches(pitches)
    local function stringKey(pitches1)
        local pitchSet = {}
        for _, p in ipairs(pitches1) do pitchSet[tostring(p)] = 1 end
        local pitchKeys = {}
        for p in pairs(pitchSet) do table.insert(pitchKeys, p) end
        table.sort(pitchKeys, function(a, b) return PitchClass(a) < PitchClass(b) end)
        local s = table.concat(pitchKeys, '|')
        local bass = pitches1[1]
        s = s .. '/' .. tostring(bass)
        return s
    end

    if not Chord.static.by_pitches then
        Chord.static.by_pitches = {}
        for _, pc in ipairs(PitchClass:all()) do
            for recipe_name, intervals in pairs(Chord.recipes) do
                for inv = 0, #intervals - 1 do
                    local chord = Chord(pc, recipe_name):invert(inv)
                    local key = stringKey(chord.pitches)
                    Chord.static.by_pitches[key] = Chord.static.by_pitches[key] or {}
                    Chord.static.by_pitches[key][chord] = 1
                end
            end
        end
    end

    local function score(chord)
        local bass, root = chord.pitches[1].number, chord.root.number
        if bass > root then root = root + 12 end
        local d = root - bass
        local s = 0.0
        return ({
            [0] = 1.0, [1] = 0.1, [2] = 0.4, [3] = 0.7,
            [4] = 0.7, [5] = 0.6, [6] = 0.1, [7] = 0.8,
            [8] = 0.3, [9] = 0.7, [10] = 0.3, [11] = 0.1,
        })[d]
    end

    local k = stringKey(pitches)
    local results = {}
    for chord in pairs(Chord.static.by_pitches[k] or {}) do
        table.insert(results, chord)
    end
    table.sort(results, function(a, b) return score(a) > score(b) end)
    return results
end

return Chord
