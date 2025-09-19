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

local PitchClass = class 'PitchClass'
local Note = class 'Note'
local Interval = class 'Interval'
local Chord = class 'Chord'
local Scale = class 'Scale'

table.contains = table.contains or function(tbl, item)
    for i, x in ipairs(tbl) do
        if x == item then
            return true
        end
    end
    return false
end

table.compare = table.compare or function(a, b)
    for i = 1, math.min(#a, #b) do
        if a[i] < b[i] then return -1 end
        if a[i] > b[i] then return 1 end
    end
    if #a < #b then return -1 end
    if #a > #b then return 1 end
    return 0
end

table.tostring = table.tostring or function(t)
    local s, visited = '', {}
    for i, p in ipairs{{ipairs(t)}, {pairs(t)}} do
        for k, v in table.unpack(p) do
            if not visited[k] then
                s = s .. (s == '' and '' or ', ') .. (i > 1 and (k .. ' = ') or '') .. (type(v) == 'table' and table.tostring(v) or tostring(v))
                visited[k] = true
            end
        end
    end
    return '{' .. s .. '}'
end

table.map = table.map or function (f, ...)
    assert(type(f) == 'function')
    local tbls, ret = {...}, {}
    local i = 1
    while true do
        local args = {}
        for j, tbl in ipairs(tbls) do
            assert(type(tbl) == 'table')
            if tbl[i] == nil then return ret end
            table.insert(args, tbl[i])
        end
        table.insert(ret, f(table.unpack(args)))
        i = i + 1
    end
    return ret
end

table.reduce = table.reduce or function(f, tbl, initial)
    assert(type(f) == 'function')
    assert(type(tbl) == 'table')
    initial = initial or 0
    local y = initial
    for i, x in ipairs(tbl) do y = f(y, x) end
    return y
end

table.filter = table.filter or function(f, tbl)
    assert(type(f) == 'function')
    assert(type(tbl) == 'table')
    local ret = {}
    for i, x in ipairs(tbl) do if f(x) then table.insert(ret, x) end end
    return ret
end

table.keys = table.keys or function(tbl)
    local ret = {}
    for k, v in pairs(tbl) do table.insert(ret, k) end
    return ret
end

table.slice = table.slice or function(tbl, first, last, step)
    local ret = {}
    for i = first or 1, last or #t, step or 1 do table.insert(ret, tbl[i]) end
    return ret
end

utf8.sub = utf8.sub or function(s, i, j)
    local start_byte = utf8.offset(s, i) or (#s + 1)
    local end_byte = j and (utf8.offset(s, j + 1) or (#s + 1)) - 1 or #s
    return s:sub(start_byte, end_byte)
end

PitchClass.static.max_accidentals = 6
PitchClass.static.unicode_output = true

PitchClass.static.info = {
    C = {name = 'C', index = 0, number = 0,  normal_accidentals =     {0, 1}},
    D = {name = 'D', index = 1, number = 2,  normal_accidentals = {-1, 0, 1}},
    E = {name = 'E', index = 2, number = 4,  normal_accidentals = {-1, 0}},
    F = {name = 'F', index = 3, number = 5,  normal_accidentals =     {0, 1}},
    G = {name = 'G', index = 4, number = 7,  normal_accidentals = {-1, 0, 1}},
    A = {name = 'A', index = 5, number = 9,  normal_accidentals = {-1, 0, 1}},
    B = {name = 'B', index = 6, number = 11, normal_accidentals = {-1, 0}},
}

PitchClass.static.names = {'C', 'D', 'E', 'F', 'G', 'A', 'B'}

function PitchClass.static:all(max_accidentals)
    local result = {}
    if max_accidentals == nil then
        for name, info in pairs(PitchClass.info) do
            for _, acc in ipairs(info.normal_accidentals) do
                table.insert(result, PitchClass(name, acc))
            end
        end
    else
        assert(math.type(max_accidentals) == 'integer')
        for _, name in ipairs(PitchClass.names) do
            table.insert(result, PitchClass(name, 0))
            for acc = 1, max_accidentals do
                table.insert(result, PitchClass(name, acc))
                table.insert(result, PitchClass(name, -acc))
            end
        end
    end
    return result
end

function PitchClass:initialize(name, accidentals)
    assert(type(name) == 'string')
    if accidentals == nil then
        accidentals = 0
        local pitch_class_str = name
        assert(utf8.len(pitch_class_str) >= 1, 'invalid pitch class: "' .. pitch_class_str .. '"')
        name, accidentals_str = utf8.sub(pitch_class_str, 1, 1), utf8.sub(pitch_class_str, 2)
        if accidentals_str == '' then
        elseif accidentals_str == '𝄫' then
            accidentals = accidentals - 2
        elseif accidentals_str == '𝄪' then
            accidentals = accidentals + 2
        else
            local acc0 = utf8.sub(accidentals_str, 1, 1)
            assert(acc0 == '#' or acc0 == 'b' or acc0 == '♯' or acc0 == '♭', 'invalid pitch class: ' .. pitch_class_str)
            for i = 2, utf8.len(accidentals_str) do
                assert(utf8.sub(accidentals_str, i, i) == acc0, 'inconsistent accidentals')
            end
            local s = (acc0 == '#' or acc0 == '♯') and 1 or -1
            accidentals = accidentals + utf8.len(accidentals_str) * s
        end
    end
    assert(PitchClass.info[name] ~= nil, 'invalid pitch name: ' .. name)
    assert(math.type(accidentals) == 'integer')
    assert(math.abs(accidentals) <= PitchClass.max_accidentals, 'too many accidentals: ' .. accidentals)
    self.name = name
    self.accidentals = accidentals
end

function PitchClass:__cmp(other)
    return table.compare({PitchClass.info[self.name].number, self.accidentals}, {PitchClass.info[other.name].number, other.accidentals})
end

function PitchClass:__lt(other)
    return self:__cmp(other) < 0
end

function PitchClass:__le(other)
    return self:__cmp(other) <= 0
end

function PitchClass:__eq(other)
    return self:__cmp(other) == 0
end

function PitchClass:__tostring()
    return self.name .. self.accidentals_str
end

function PitchClass:__index(k)
    if k == 'index' then
        return PitchClass.info[self.name].index
    elseif k == 'number' then
        return PitchClass.info[self.name].number + self.accidentals
    elseif k == 'accidentals_str' then
        if self.accidentals == 0 then return '' end
        if PitchClass.static.unicode_output then
            if self.accidentals == -2 then return '𝄫'
            elseif self.accidentals == 2 then return '𝄪'
            else
                local s = self.accidentals < 0 and '♭' or '♯'
                return string.rep(s, math.abs(self.accidentals))
            end
        else
            local s = self.accidentals < 0 and 'b' or '#'
            return string.rep(s, math.abs(self.accidentals))
        end
    elseif k == 'lilypond_notation' then
        local s = self.name:lower()
        for i = 1, -self.accidentals do
            s = s .. 'es'
        end
        for i = 1, self.accidentals do
            s = s .. 'is'
        end
        return s
    end
    return rawget(self, k)
end

function PitchClass:flat()
    return PitchClass(self.name, self.accidentals - 1)
end

function PitchClass:sharp()
    return PitchClass(self.name, self.accidentals + 1)
end

function PitchClass:natural()
    return PitchClass(self.name, 0)
end

function PitchClass:to_octave(octave)
    return Note(self, octave)
end

function Note.static:all(min_octave, max_octave, max_accidentals)
    min_octave = min_octave or 4
    max_octave = max_octave or 4
    local notes = {}
    for octave = min_octave, max_octave do
        for _, pc in ipairs(PitchClass:all(max_accidentals)) do
            table.insert(notes, Note(pc, octave))
        end
    end
    return notes
end

function Note.static:from_number(number, allowed_accidentals)
    allowed_accidentals = allowed_accidentals or {-2, -1, 0, 1, 2}
    if not Note.number_inv_mapping then
        Note.number_inv_mapping = {}
        for _, n in ipairs(Note:all(0, 9, PitchClass.max_accidentals)) do
            if not Note.number_inv_mapping[n.number] then
                Note.number_inv_mapping[n.number] = {}
            end
            table.insert(Note.number_inv_mapping[n.number], n)
        end
    end

    local r = {}
    for _, n in ipairs(Note.number_inv_mapping[number] or {}) do
        if (allowed_accidentals == -1 and table.contains(PitchClass.info[n.pitch_class.name].normal_accidentals, n.pitch_class.accidentals))
                or (allowed_accidentals ~= -1 and table.contains(allowed_accidentals, n.pitch_class.accidentals)) then
            table.insert(r, n)
        end
    end
    return r
end

function Note.static:from_midi_note(midi_note, allowed_accidentals)
    return Note:from_number(midi_note - 12, allowed_accidentals)
end

function Note:initialize(pitch_class, octave)
    if type(pitch_class) == 'string' and octave == nil then
        local note_str = pitch_class
        assert(note_str ~= '', 'invalid note format: empty string')
        local pitch_name, octave_str = note_str:match("^(%D+)(%d+)$")
        assert(octave_str, 'invalid note format: missing octave number: ' .. note_str)
        assert(pitch_name, 'invalid note format: missing pitch class: ' .. note_str)
        self.pitch_class = PitchClass(pitch_name)
        self.octave = tonumber(octave_str)
    else
        self.pitch_class = pitch_class
        self.octave = octave
    end
    assert(type(self.pitch_class) == 'table', 'invalid pitch_class type: ' .. type(self.pitch_class))
    assert(PitchClass.isInstanceOf(self.pitch_class, PitchClass), 'invalid pitch_class class: ' .. tostring(self.pitch_class.class))
    assert(type(self.octave) == 'number', 'invalid octave type: ' .. type(self.octave))
    assert(math.type(self.octave) == 'integer', 'invalid octave type: ' .. math.type(self.octave))
    assert(self.octave >= 0 and self.octave <= 9, 'invalid octave value: ' .. self.octave)
end

function Note:to_octave(new_octave)
    return Note(self.pitch_class, new_octave)
end

function Note:__add(other)
    if Interval.isInstanceOf(other, Interval) then
        if other:is_compound() then
            local current = self
            for _, interval in ipairs(other:split()) do
                current = current + interval
            end
            return current
        end

        assert(other.size ~= 0)
        local new_index = self.pitch_class.index + other.size
        if other.size > 0 then
            new_index = new_index - 1
        else
            new_index = new_index + 1
        end
        new_index = new_index % 7
        local new_pitch_name = PitchClass.names[new_index + 1]

        local new_number = self.number + other.semitones

        local octave_incr = 0
        for i = 8 - other.size + 1, 7 do
            if self.pitch_class.name == PitchClass.names[i] then
                octave_incr = 1
                break
            end
        end
        local new_note_octave = self.octave + octave_incr

        local difference = (new_number % 12) - PitchClass.info[new_pitch_name].number
        if difference < -PitchClass.max_accidentals then
            difference = difference + 12
        elseif difference > PitchClass.max_accidentals then
            difference = difference - 12
        end

        return Note(PitchClass(new_pitch_name, difference), new_note_octave)
    end
    error('unsupported operand type for addition')
end

function Note:__sub(other)
    if Interval.isInstanceOf(other, Interval) then
        if other:is_compound() then
            local current = self
            for _, interval in ipairs(other:split()) do
                current = current - interval
            end
            return current
        end
        return self:to_octave(self.octave - 1) + other:complement()
    elseif Note.isInstanceOf(other, Note) then
        local semitones = self.number - other.number
        if semitones < -1 then
            error('interval smaller than diminished unison')
        end

        local octaves = 0
        while semitones >= 12 do
            semitones = semitones - 12
            octaves = octaves + 1
        end

        local size = self.pitch_class.index - other.pitch_class.index
        if size >= 0 then
            size = size + 1
        else
            size = size - 1
        end
        size = (size + (size < 0 and 1 or -1)) % 7 + 1

        for _, i in ipairs(Interval:all(true)) do
            if i.size == size and i.semitones == semitones then
                return Interval(i.quality, octaves * 7 + size)
            end
        end
        error('no matching interval found')
    end
    error('unsupported operand type for subtraction')
end

function Note:__cmp(other)
    return table.compare({self.octave, self.pitch_class}, {other.octave, other.pitch_class})
end

function Note:__lt(other)
    return self:__cmp(other) < 0
end

function Note:__le(other)
    return self:__cmp(other) <= 0
end

function Note:__eq(other)
    return self:__cmp(other) == 0
end

function Note:__tostring()
    return tostring(self.pitch_class) .. tostring(self.octave)
end

function Note:__repr()
    return 'Note(\'' .. tostring(self) .. '\')'
end

function Note:__index(k)
    if k == 'number' then
        return self.pitch_class.number + self.octave * 12
    elseif k == 'midi_note' then
        return self.number + 12
    elseif k == 'frequency' then
        local A4 = Note(PitchClass('A'), 4)
        return 440.0 * math.pow(2, (self.number - A4.number) / 12.0)
    elseif k == 'lilypond_notation' then
        local s = self.pitch_class.lilypond_notation
        if self.octave < 3 then
            s = s .. string.rep(',', 3 - self.octave)
        elseif self.octave > 3 then
            s = s .. string.rep('\'', self.octave - 3)
        end
        return s
    end
    return rawget(self, k)
end

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
    if other.class == Interval then
        local n = Note('C0')
        return (n + self + other) - n
    else
        error('cannot add ' .. type(other) .. ' to Interval')
    end
end

function Interval:__sub(other)
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
            self.recipe = '[' .. table.concat(table.map(tostring, chord_type), ',') .. ']'
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
    local notes = table.map(function(i) return root + i end, intervals)
    return Chord:identify_from_notes(notes)
end

function Chord.static:identify_from_notes(notes)
    local pitches = table.map(function(n) return n.pitch_class end, notes)
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

return {
    PitchClass = PitchClass,
    Note = Note,
    Interval = Interval,
    Chord = Chord,
    Scale = Scale,
}
