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

local set = {}

function set.size(t)
    local sz = 0
    for k, v in pairs(t) do sz = sz + 1 end
    return sz
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

function PitchClass.static:parse(s)
    assert(type(s) == 'string')
    assert(utf8.len(s) >= 1, 'invalid pitch class: "' .. s .. '"')
    local name, accidentals = utf8.sub(s, 1, 1), utf8.sub(s, 2)
    if accidentals == '' then
        accidentals = 0
    elseif accidentals == '𝄫' then
        accidentals = -2
    elseif accidentals == '𝄪' then
        accidentals = 2
    else
        local acc0 = utf8.sub(accidentals, 1, 1)
        assert(acc0 == '#' or acc0 == 'b' or acc0 == '♯' or acc0 == '♭', 'invalid pitch class: ' .. s)
        for i = 2, utf8.len(accidentals) do
            assert(utf8.sub(accidentals, i, i) == acc0, 'inconsistent accidentals')
        end
        local s = (acc0 == '#' or acc0 == '♯') and 1 or -1
        accidentals = utf8.len(accidentals) * s
    end
    return PitchClass(name, accidentals)
end

function PitchClass:initialize(name, accidentals)
    assert(type(name) == 'string')
    if accidentals == nil then
        local pc = PitchClass:parse(name)
        self.name = pc.name
        self.accidentals = pc.accidentals
        return
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

function Note.static:parse(s)
    if type(s) == 'string' then
        assert(s ~= '', 'invalid note format: empty string')
        local pitch_name, octave_str = s:match("^(%D+)(%d+)$")
        assert(octave_str, 'invalid note format: missing octave number: "' .. s .. '"')
        assert(pitch_name, 'invalid note format: missing pitch class: "' .. s .. '"')
        local octave = tonumber(octave_str)
        local pc = PitchClass:parse(pitch_name)
        return Note(pc, octave)
    end
    error('invalid input type for Note.parse')
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
        local n = Note:parse(pitch_class)
        self.pitch_class = n.pitch_class
        self.octave = n.octave
        self.number = n.number
        return
    end

    if not pitch_class:isInstanceOf(PitchClass) then
        error('invalid pitch_class type')
    end
    if math.type(octave) ~= 'integer' or octave < 0 or octave > 9 then
        error('invalid octave value')
    end

    self.pitch_class = pitch_class
    self.octave = octave
    self.number = pitch_class.number + octave * 12
end

function Note:to_octave(new_octave)
    return Note(self.pitch_class, new_octave)
end

function Note:__add(other)
    if other:isInstanceOf(Interval) then
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
    if other:isInstanceOf(Interval) then
        if other:is_compound() then
            local current = self
            for _, interval in ipairs(other:split()) do
                current = current - interval
            end
            return current
        end
        return self:to_octave(self.octave - 1) + other:complement()
    elseif other:isInstanceOf(Note) then
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
    if k == 'midi_note' then
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

function Interval.static:parse(s)
    if type(s) == 'table' and s.class == Interval then
        return s
    end
    if type(s) ~= 'string' then
        error('invalid input type')
    end

    local quality, size = s:match('^([dA]+)(%d+)$')
    if not quality then
        quality, size = s:match('^([mPM])(%d+)$')
        if not quality then
            error('could not parse Interval: ' .. s)
        end
    end

    return Interval(quality, tonumber(size))
end

function Interval:initialize(quality, size)
    if not size then
        local parsed = Interval:parse(quality)
        self.quality = parsed.quality
        self.size = parsed.size
        self.semitones = parsed.semitones
        return
    end

    if type(quality) ~= 'string' then
        error('invalid quality type')
    end
    if not Interval.quality_inverse[quality] then
        error('invalid interval quality')
    end
    if type(size) ~= 'number' or size <= 0 or math.floor(size) ~= size then
        error('invalid interval size')
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
    ['maj6'] = {'P1', 'M3', 'P5', 'M6'},
    ['min6'] = {'P1', 'm3', 'P5', 'm6'},
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
    ['m6'] = 'min6',
    ['6'] = 'dom6',
    ['m/M6'] = 'min/maj6',
}

Chord.static.recipes_inv = {}
for name, intervals in pairs(Chord.recipes) do
    local key = {}
    for _, s in ipairs(intervals) do
        table.insert(key, s)
    end
    table.sort(key)
    Chord.recipes_inv[table.concat(key, '|')] = name
end

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

function Chord.static:parse(s)
    if type(s) == 'table' and s.class == Chord then
        return s
    end
    if type(s) ~= 'string' then
        error('invalid input type')
    end

    -- Handle inversions
    if s:find('/') then
        local chord_str, root_str = s:match('^([^/]+)/(.+)$')
        local chord = self:parse(chord_str)
        local root = PitchClass:parse(root_str)
        local inversion = 0
        for i, pitch in ipairs(chord:pitches()) do
            if pitch == root then
                inversion = i - 1
                break
            end
        end
        return chord:invert(inversion)
    end

    -- Find matching suffix
    local suffixes = {}
    for name in pairs(self.recipes) do
        table.insert(suffixes, name)
    end
    for alias in pairs(self.aliases) do
        table.insert(suffixes, alias)
    end

    -- Sort by descending length to match longest first
    table.sort(suffixes, function(a, b) return #a > #b end)

    for _, suffix in ipairs(suffixes) do
        if #s >= #suffix and s:sub(-#suffix) == suffix then
            local root_str = s:sub(1, -#suffix - 1)
            local root = PitchClass:parse(root_str)
            local chord_type = self.aliases[suffix] or suffix
            return Chord(root, chord_type)
        end
    end

    error('invalid chord: ' .. s)
end

function Chord:initialize(root, chord_type)
    if type(root) == 'string' and not chord_type then
        local parsed = Chord:parse(root)
        self.root = parsed.root
        self.intervals = parsed.intervals
        return
    end

    if type(root) == 'string' then
        root = PitchClass:parse(root)
    end
    if root.class ~= PitchClass then
        error('invalid root type')
    end

    if not chord_type then
        chord_type = 'maj'
    end

    if type(chord_type) == 'string' then
        chord_type = self.class.aliases[chord_type] or chord_type
        if not self.class.recipes[chord_type] then
            error('invalid chord_type: ' .. chord_type)
        end
        chord_type = self.class.recipes[chord_type]
    end

    if type(chord_type) ~= 'table' then
        error('invalid chord_type type')
    end

    -- Convert string intervals to Interval objects
    local intervals = {}
    for _, interval in ipairs(chord_type) do
        if type(interval) == 'string' then
            table.insert(intervals, Interval:parse(interval))
        elseif interval.class == Interval then
            table.insert(intervals, interval)
        else
            error('invalid interval type')
        end
    end

    self.root = root
    table.sort(intervals, function(a, b) return a < b end)
    self.intervals = intervals
end

function Chord:contains(x)
    if x:isInstanceOf(Interval) then
        for _, i in ipairs(self.intervals) do
            if i == x then return true end
        end
        return false
    elseif x:isInstanceOf(PitchClass) or x:isInstanceOf(Note) then
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
    return self:recipe().full_name
end

function Chord:__hash()
    local h = self.root:__hash()
    for _, interval in ipairs(self.intervals) do
        h = h + interval:__hash()
    end
    return h
end

function Chord:__len()
    return #self.intervals
end

function Chord:recipe()
    if self._recipe then
        return self._recipe
    end

    for _, result in ipairs(Chord:identify_from_intervals(self.intervals)) do
        local recipe_name, inversion = result.name, result.inversion
        local root_str = tostring(self.root)
        local full_name = root_str .. recipe_name
        if inversion > 0 then
            local base_note = Note(self.root, 4)
            local inv_note = base_note + self.intervals[1]
            full_name = full_name .. '/' .. tostring(inv_note.pitch_class)
        end
        self._recipe = {
            known = true,
            name = recipe_name,
            inversion = inversion,
            full_name = full_name
        }
        return self._recipe
    end

    local interval_strs = {}
    for _, interval in ipairs(self.intervals) do
        table.insert(interval_strs, tostring(interval))
    end
    self._recipe = {
        known = false,
        name = '',
        inversion = 0,
        full_name = table.concat(interval_strs, '-')
    }
    return self._recipe
end

function Chord:pitches()
    local pitches = {}
    for _, note in ipairs(self:notes()) do
        table.insert(pitches, note.pitch_class)
    end
    return pitches
end

function Chord:notes(base_octave)
    base_octave = base_octave or 4
    local root_note = Note(self.root, base_octave)
    local notes = {}
    for _, interval in ipairs(self.intervals) do
        table.insert(notes, root_note + interval)
    end
    return notes
end

function Chord:invert(num_times)
    if num_times == 0 then
        return self
    end

    local new_intervals = {}
    for i = 2, #self.intervals do
        table.insert(new_intervals, self.intervals[i])
    end
    table.insert(new_intervals, self.intervals[1] + Interval:parse('P8'))

    local new_chord = Chord(self.root, new_intervals)
    return new_chord:invert(num_times - 1)
end

function Chord.static:identify_from_notes(notes)
    table.sort(notes, function(a, b) return a < b end)

    local n = #notes

    local results = {}
    for mask = 0, (1 << n) - 1 do
        local new_notes = {}
        for i, note in ipairs(notes) do
            if mask & (1 << (i-1)) ~= 0 then
                table.insert(new_notes, note + Interval:parse('P8'))
            else
                table.insert(new_notes, note)
            end
        end
        table.sort(new_notes, function(a, b) return a < b end)

        local lowest_note = new_notes[1]
        local intervals = {}
        for _, note in ipairs(new_notes) do
            table.insert(intervals, note - lowest_note)
        end

        for _, recipe_info in ipairs(self:identify_from_intervals(intervals)) do
            for inversion = 0, n-1 do
                for _, root in ipairs(notes) do
                    local c = Chord(root.pitch_class, recipe_info.name)
                    local inv_c = c:invert(inversion)
                    local c_notes = inv_c:notes()
                    table.sort(c_notes, function(a, b) return a < b end)

                    local match = true
                    for j = 1, n do
                        if c_notes[j].pitch_class ~= notes[j].pitch_class then
                            match = false
                            break
                        end
                    end

                    if match then
                        table.insert(results, inv_c)
                    end
                end
            end
        end
    end

    return results
end

function Chord.static:identify_from_intervals(intervals)
    table.sort(intervals, function(a, b) return a < b end)

    local function flip(interval)
        if interval:is_compound() or interval == Interval('P8') then
            return interval:reduce()
        else
            return interval + Interval:parse('P8')
        end
    end

    local n = #intervals

    local results = {}
    for mask = 0, (1 << n) - 1 do
        local new_intervals = {}
        for i, interval in ipairs(intervals) do
            if mask & (1 << (i-1)) ~= 0 then
                table.insert(new_intervals, flip(interval))
            else
                table.insert(new_intervals, interval)
            end
        end
        table.sort(new_intervals, function(a, b) return a < b end)

        local key_parts = {}
        for _, ival in ipairs(new_intervals) do
            table.insert(key_parts, tostring(ival))
        end
        table.sort(key_parts)
        local key = table.concat(key_parts, '|')

        if self.recipes_inv[key] then
            local recipe_name = self.recipes_inv[key]
            local c = Chord(PitchClass:parse('C'), recipe_name)
            for inversion = 0, n-1 do
                local inv_chord = c:invert(inversion)
                if #inv_chord.intervals == #intervals then
                    local match = true
                    for j = 1, #intervals do
                        if inv_chord.intervals[j] ~= intervals[j] then
                            match = false
                            break
                        end
                    end
                    if match then
                        table.insert(results, {
                            name = recipe_name,
                            inversion = inversion
                        })
                    end
                end
            end
        end
    end

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
        root = PitchClass:parse(root)
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
        table.insert(intervals, Interval:parse(interval_str))
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
        for _, pitch in ipairs(item:pitches()) do
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

local function test()
    require 'busted.runner'()
    --local busted = require 'busted'
    --local describe = busted.describe
    --local it = busted.it
    --local assert = busted.assert
    --local before_each = busted.before_each
    --local after_each = busted.after_each
    --local require = require

    describe('TestsForPitchClass', function()
        it('pitchclass_creation', function()
            local function test1(pc, n, a)
                local p = PitchClass(pc)
                assert.equal(p.name, n)
                assert.equal(p.accidentals, a)
            end
            test1('C', 'C', 0)
            test1('C#', 'C', 1)
            test1('C##', 'C', 2)
            test1('Cb', 'C', -1)
            test1('Cbb', 'C', -2)
            test1('D', 'D', 0)
            test1('Bbbb', 'B', -3)

            local bad_values = {1, true, nil, 1.5, {}, function() end}
            for _, v in ipairs(bad_values) do
                assert.has_error(function() PitchClass(v, 0) end)
            end
            assert.has_error(function() PitchClass('Z', 0) end)
            for _, v in ipairs({'1', 1.5, {}, function() end}) do
                assert.has_error(function() PitchClass('C', v) end)
            end
            assert.has_error(function() PitchClass('C', 2000) end)
        end)

        it('pitchclass_parsing', function()
            local function test1(s, name, accidentals)
                assert.equal(PitchClass:parse(s), PitchClass(name, accidentals))
            end
            for _, n in ipairs{'C','D','E','F','G','A','B'} do
                for acc = -3, 3 do
                    if acc < 0 then
                        test1(n .. string.rep('b', -acc), n, acc)
                    else
                        test1(n .. string.rep('#', acc), n, acc)
                    end
                end
            end

            local bad_names = {'C#######', 'Dbbbbbbb', 'H', '$'}
            for _, name in ipairs(bad_names) do
                assert.has_error(function() PitchClass:parse(name) end)
            end

            local function test3(a, b)
                assert.equal(PitchClass:parse(a), PitchClass:parse(b))
            end
            test3('B♭', 'Bb')
            test3('B𝄫', 'Bbb')
            test3('B♭♭', 'Bbb')
            test3('B♭♭♭', 'Bbbb')
            test3('B♭♭♭♭', 'Bbbbb')
            test3('C♯', 'C#')
            test3('C𝄪', 'C##')
            test3('C♯♯', 'C##')
            test3('C♯♯♯', 'C###')
            test3('C♯♯♯♯', 'C####')

            local bad_values = {1, true, nil, 1.5, {}, function() end}
            for _, v in ipairs(bad_values) do
                assert.has_error(function() PitchClass:parse(v) end)
            end
        end)

        it('pitchclass_gen', function()
            local function test1(s)
                local p = PitchClass:parse(s)
                local found = false
                for _, x in ipairs(PitchClass:all()) do
                    if x == p then
                        found = true
                        break
                    end
                end
                assert.is_true(found)
            end
            for _, n in ipairs{'A','C','D','F','G'} do test1(n .. '#') end
            for _, n in ipairs{'A','B','D','E','G'} do test1(n .. 'b') end
            for _, n in ipairs{'A','B','C','D','E','F','G'} do test1(n) end
            assert.has_error(function() PitchClass:all('') end)
        end)

        it('pitchclass_repr', function()
            PitchClass.static.unicode_output = false
            assert.equal(tostring(PitchClass('C')), 'C')
            assert.equal(tostring(PitchClass('C#')), 'C#')
            assert.equal(tostring(PitchClass('Cb')), 'Cb')
            assert.equal(tostring(PitchClass('C', -1)), 'Cb')
        end)

        it('pitchclass_flat_sharp', function()
            assert.equal(PitchClass('C'):sharp(), PitchClass('C#'))
            assert.equal(PitchClass('C'):sharp():sharp(), PitchClass('C##'))
            assert.equal(PitchClass('C#'):sharp(), PitchClass('C##'))
            assert.equal(PitchClass('C#'):flat(), PitchClass('C'))
            assert.equal(PitchClass('B'):flat(), PitchClass('Bb'))
            assert.equal(PitchClass('C#'):natural(), PitchClass('C'))
            assert.equal(PitchClass('C##'):natural(), PitchClass('C'))
            assert.equal(PitchClass('Eb'):natural(), PitchClass('E'))
        end)

        it('pitchclass_tooct', function()
            assert.equal(PitchClass('Eb'):to_octave(5), Note('Eb5'))
        end)

        it('pitchclass_hashing', function()
            local s = {}
            s[tostring(Chord('Cmin'))] = true
            s[tostring(Chord('Dmaj7'))] = true
            assert.is_true(s[tostring(Chord('Cmin'))] ~= nil)
            assert.is_true(s[tostring(Chord('Emin'))] == nil)
            assert.is_true(s[tostring(Chord('Cmin'))] ~= nil)
        end)

        it('pitchclass_ordering', function()
            local function test1(a, b)
                local pa = PitchClass:parse(a)
                local pb = PitchClass:parse(b)
                assert.is_true(pa <= pb)
                assert.is_true(pb >= pa)
            end
            test1('C', 'C')
            test1('C', 'D')
            test1('C', 'Dbbb')
            test1('C###', 'Dbbb')
            test1('C', 'A')

            local function test2(l1, l2)
                local t1 = {}
                for _, s in ipairs(l1) do table.insert(t1, PitchClass:parse(s)) end
                table.sort(t1)
                local t2 = {}
                for _, s in ipairs(l2) do table.insert(t2, PitchClass:parse(s)) end
                assert.same(t1, t2)
            end
            test2({'C', 'D', 'E', 'F', 'G', 'A', 'B'}, {'C', 'D', 'E', 'F', 'G', 'A', 'B'})
            test2({'A', 'C'}, {'C', 'A'})
            test2({'C#', 'Db', 'Cb', 'Dbb', 'C'}, {'Cb', 'C', 'C#', 'Dbb', 'Db'})
        end)
    end)

    describe('TestsForNote', function()
        it('note_creation', function()
            local function test1(s, pcn, pca, o)
                local n = Note(PitchClass(pcn, pca), o)
                assert.equal(n.pitch_class.name, pcn)
                assert.equal(n.pitch_class.accidentals, pca)
                assert.equal(n.octave, o)
                assert.equal(n, Note(s))
            end
            test1('C#4', 'C', 1, 4)
            test1('C2', 'C', 0, 2)

            local bad_values = {'C', 1, true, nil, 1.5, {}, function() end}
            for _, v in ipairs(bad_values) do
                assert.has_error(function() Note(v, 0) end)
            end
            for _, v in ipairs{1.5, {}, function() end} do
                assert.has_error(function() Note(PitchClass('C'), v) end)
            end
        end)

        it('note_parsing', function()
            local function test1(note, strnote)
                assert.equal(tostring(Note(note)), strnote)
            end
            PitchClass.static.unicode_output = false
            test1('A4', 'A4')
            test1('Ab6', 'Ab6')
            test1('Dbb4', 'Dbb4')
            test1('G###0', 'G###0')

            local bad_notes = {'A99', 'A#', 'Ab#', 'E#######5'}
            for _, note in ipairs(bad_notes) do
                assert.has_error(function() Note(note) end)
            end

            local function test3(note, pitch_class)
                assert.equal(tostring(Note(note).pitch_class), pitch_class)
            end
            PitchClass.static.unicode_output = false
            test3('A4', 'A')
            test3('Ab6', 'Ab')
            test3('Dbb3', 'Dbb')
            test3('G###0', 'G###')

            local function test4(note, pitch_name)
                assert.equal(Note(note).pitch_class.name, pitch_name)
            end
            test4('A4', 'A')
            test4('Ab6', 'A')
            test4('Dbb3', 'D')
            test4('G###0', 'G')

            local function test5(note, acc)
                assert.equal(Note(note).pitch_class.accidentals, acc)
            end
            test5('A4', 0)
            test5('Ab6', -1)
            test5('Dbb3', -2)
            test5('G###0', 3)

            local function test6(note, octave)
                assert.equal(Note(note).octave, octave)
            end
            test6('A4', 4)
            test6('Ab6', 6)
            test6('Dbb3', 3)
            test6('G###0', 0)

            local bad_values = {1, true, nil, 1.5, {}, function() end}
            for _, v in ipairs(bad_values) do
                assert.has_error(function() Note:parse(v) end)
            end
        end)

        it('note_gen', function()
            local expected = {
                'C4', 'C#4', 'Db4', 'D4', 'D#4', 'Eb4', 'E4', 'F4', 'F#4',
                'Gb4', 'G4', 'G#4', 'Ab4', 'A4', 'A#4', 'Bb4', 'B4', 'C5',
                'C#5', 'Db5', 'D5', 'D#5', 'Eb5', 'E5', 'F5', 'F#5', 'Gb5',
                'G5', 'G#5', 'Ab5', 'A5', 'A#5', 'Bb5', 'B5'
            }
            local actual = {}
            PitchClass.static.unicode_output = false
            for _, n in ipairs(Note:all(4, 5)) do
                table.insert(actual, tostring(n))
            end
            table.sort(actual)
            table.sort(expected)
            assert.same(actual, expected)
        end)

        it('note_oct', function()
            local function test1(n1, oc, n2)
                assert.equal(Note(n1):to_octave(oc), Note(n2))
            end
            test1('C#2', 5, 'C#5')
            test1('B#6', 3, 'B#3')
            test1('Cbbb6', 6, 'Cbbb6')
            test1('Ebb5', 1, 'Ebb1')

            assert.equal(Note('C#4').octave, 4)
            assert.equal(Note('C#4'):to_octave(5).octave, 5)
        end)

        it('note_midi', function()
            local function test1(note, midi)
                assert.equal(Note(note).midi_note, midi)
            end
            test1('C4', 60)
            test1('D5', 74)
        end)

        it('note_add', function()
            local function test1(note, interval, result)
                note = Note(note)
                interval = Interval:parse(interval)
                result = Note(result)
                assert.equal(note + interval, result)
                assert.equal(result - interval, note)
                assert.equal(result - note, interval)
            end
            test1('A4', 'd5', 'Eb5')
            test1('A4', 'P1', 'A4')
            test1('G##4', 'm3', 'B#4')
            test1('F3', 'P5', 'C4')
            test1('B#4', 'd2', 'C5')
            test1('C4', 'd1', 'Cb4')
            test1('B4', 'd1', 'Bb4')
            test1('C#4', 'd1', 'C4')
            -- compound intervals:
            test1('C4', 'M10', 'E5')
            test1('Cb4', 'A10', 'E5')
            test1('Cb4', 'm10', 'Ebb5')
            test1('B3', 'm10', 'D5')
            test1('B3', 'M17', 'D#6')

            assert.has_error(function() return Note('C4') + {} end)
            assert.has_error(function() return Note('C4') + 'invalid' end)
        end)

        it('note_sub', function()
            local function test1(note1, note2, result)
                assert.equal(Note(note1) - Note(note2), Interval:parse(result))
            end
            test1('E4', 'C4', 'M3')
            test1('G5', 'C5', 'P5')
            test1('C#6', 'C6', 'A1')
            test1('Cb7', 'C7', 'd1')

            assert.has_error(function() return Note('C4') - Note('C5') end)
            assert.has_error(function() return Note('C4') - {} end)
            assert.has_error(function() return Note('C4') - 'invalid' end)
        end)

        it('note_freq', function()
            local function test1(note, freq)
                assert.near(Note(note).frequency, freq, 0.1)
            end
            test1('A4', 440.0)
            test1('A5', 880.0)
            test1('C5', 523.3)
        end)

        it('note_lilypond', function()
            local function test1(n, ln)
                assert.equal(Note(n).lilypond_notation, ln)
            end
            test1('C3', 'c')
            test1('C#4', 'cis\'')
            test1('Cb2', 'ces,')
        end)

        it('note_repr', function()
            PitchClass.static.unicode_output = false
            assert.equal(tostring(Note('C#4')), 'C#4')
        end)

        it('note_ordering', function()
            local function test1(l1, l2)
                local t1 = {}
                for _, s in ipairs(l1) do table.insert(t1, Note(s)) end
                table.sort(t1)
                local t2 = {}
                for _, s in ipairs(l2) do table.insert(t2, Note(s)) end
                assert.same(t1, t2)
            end
            test1({'G#3', 'D3', 'Ab3'}, {'D3', 'G#3', 'Ab3'})

            local function test2(a, b)
                assert.is_true(Note(a) <= Note(b))
            end
            test2('G#3', 'G##3')
            test2('G#3', 'G#3')
            test2('G###3', 'A3')
        end)

        it('note_hashing', function()
            local s = {}
            s[tostring(Note('C#4'))] = true
            s[tostring(Note('C#4'))] = true
            s[tostring(Note('Db4'))] = true
            assert.equal(set.size(s), 2)
        end)

        it('note_from_number', function()
            local function test1(num, maxacc, notes)
                local allacc
                if type(maxacc) == 'number' and maxacc ~= -1 then
                    allacc = {}
                    for i = -maxacc, maxacc do table.insert(allacc, i) end
                else
                    allacc = maxacc
                end
                local notes_list = Note:from_number(num, allacc)
                local notes_str_list = {}
                for _, n in pairs(notes_list) do
                    table.insert(notes_str_list, tostring(n))
                end
                table.sort(notes_str_list)
                table.sort(notes)
                assert.equal(table.tostring(notes), table.tostring(notes_str_list))
            end
            test1(59, -1, {'B4'})
            test1(59, 0, {'B4'})
            test1(59, 1, {'B4', 'Cb5'})
            test1(59, 2, {'A##4', 'B4', 'Cb5'})
            test1(59, 3, {'A##4', 'B4', 'Cb5', 'Dbbb5'})
            test1(60, -1, {'C5'})
            test1(60, 0, {'C5'})
            test1(60, 1, {'B#4', 'C5'})
            test1(60, 2, {'B#4', 'C5', 'Dbb5'})
            test1(60, 3, {'A###4', 'B#4', 'C5', 'Dbb5'})
            test1(61, 0, {})
            test1(61, 1, {'C#5', 'Db5'})
            test1(61, 2, {'B##4', 'C#5', 'Db5'})
            test1(61, 3, {'B##4', 'C#5', 'Db5', 'Ebbb5'})
        end)
    end)

    describe('TestsForInterval', function()
        it('interval_creation', function()
            assert.has_error(function() Interval(3.6, 6) end)
            assert.has_error(function() Interval('Q', 6) end)
            assert.has_error(function() Interval('P', 6.5) end)
            assert.has_error(function() Interval('P', -1) end)
            assert.has_error(function() Interval('m', 5) end)
        end)

        it('interval_parsing', function()
            local function test1(interval, semitones, size)
                local i = Interval:parse(interval)
                assert.equal(i.semitones, semitones)
                assert.equal(i.size, size)
            end
            test1('d5', 6, 5)
            test1('P8', 12, 8)
            test1('A8', 13, 8)

            local bad_intervals = {'P3', '<86ygr', {}}
            for _, interval in ipairs(bad_intervals) do
                assert.has_error(function() Interval:parse(interval) end)
            end
        end)

        it('interval_add_sub', function()
            assert.equal(Interval:parse('P5') + Interval:parse('m3'), Interval:parse('m7'))
            assert.equal(Interval:parse('P5') + Interval:parse('m3') + Interval:parse('M2'), Interval:parse('P8'))
            assert.equal(Interval:parse('P5') + Interval:parse('m3') + Interval:parse('M2') + Interval:parse('P8'), Interval:parse('P15'))
            assert.equal(Interval:parse('P5') + Interval:parse('m3') + Interval:parse('M2') - Interval:parse('P8'), Interval:parse('P1'))
            assert.has_error(function() return Interval:parse('m3') - Interval:parse('P5') end)
        end)

        it('interval_complement', function()
            local function test1(i, c)
                assert.equal(Interval:parse(i):complement(), Interval:parse(c))
            end
            test1('P1', 'P8')
            test1('A1', 'd8')
            test1('d2', 'A7')
            test1('m2', 'M7')
            test1('M2', 'm7')
            test1('A2', 'd7')
            test1('d3', 'A6')
            test1('m3', 'M6')
            test1('M3', 'm6')
            test1('A3', 'd6')
            test1('d4', 'A5')
            test1('P4', 'P5')
            test1('A4', 'd5')
            test1('d5', 'A4')
            test1('P5', 'P4')
            test1('A5', 'd4')
            test1('d6', 'A3')
            test1('m6', 'M3')
            test1('M6', 'm3')
            test1('A6', 'd3')
            test1('d7', 'A2')
            test1('m7', 'M2')
            test1('M7', 'm2')
            test1('A7', 'd2')
            test1('d8', 'A1')
            test1('P8', 'P1')
            test1('A8', 'd1')

            assert.has_error(function() Interval:parse('M9'):complement() end)
            assert.has_error(function() Interval:parse('M10'):complement() end)
        end)
    end)

    describe('TestsForChord', function()
        it('chord_creation', function()
            PitchClass.static.unicode_output = false
            local function test1(root, name, strchord)
                assert.equal(tostring(Chord(PitchClass(root), name)), strchord)
                if name then
                    assert.equal(tostring(Chord(root, name)), strchord)
                end
            end
            test1('A', 'maj', 'Amaj')
            test1('A', nil, 'Amaj')
            assert.equal(tostring(Chord(PitchClass('A'))), 'Amaj')
            test1('B', 'min', 'Bmin')
            test1('C', 'dim', 'Cdim')
            test1('D', 'aug', 'Daug')
            test1('A#', 'maj', 'A#maj')
            test1('Bb', 'maj', 'Bbmaj')

            local bad_names = {'A$', 'H', 'C#1', 'C#1maj', 'C#maj1'}
            for _, name in ipairs(bad_names) do
                assert.has_error(function() Chord(name) end)
            end

            local bad_types = {'nice', '$', 'diminished'}
            for _, t in ipairs(bad_types) do
                assert.has_error(function() Chord(PitchClass('C'), t) end)
            end

            assert.has_error(function() Chord(Note('F#4')) end)
            assert.has_error(function() Chord(PitchClass('F#'), 'locrian') end)
            assert.has_error(function() Chord(PitchClass('F#'), 3.56) end)
            assert.has_error(function() Chord(PitchClass('F#'), {'Z1', Interval:parse('m3')}) end)
            assert.has_error(function() Chord(PitchClass('F#'), {'P1', 'm3', 5.66}) end)
            assert.has_error(function() Chord(PitchClass('F#'), {Interval:parse('m3'), 8.88}) end)
        end)

        it('chord_parsing', function()
            local function test1(name, root, chord_type)
                assert.equal(Chord(name), Chord(PitchClass(root), chord_type))
            end
            test1('CM', 'C', 'maj')
            test1('Cmaj', 'C', 'maj')
            test1('Cmaj', 'C', 'M')
            test1('Cmaj7', 'C', 'M7')
            test1('D#aug7', 'D#', 'aug7')
            test1('Cbdim', 'Cb', 'dim')
            test1('Eb9', 'Eb', 'dom9')

            local bad_values = {1, true, nil, 1.5, {}, function() end}
            for _, v in ipairs(bad_values) do
                assert.has_error(function() Chord:parse(v) end)
            end
        end)

        it('chord_invert', function()
            local function test1(chord_name, i, pitch_names)
                local chord = Chord(chord_name):invert(i)
                local pitches = chord:pitches()
                assert.equal(#pitch_names, #pitches)
                for i = 1, #pitch_names do assert.equal(pitch_names[i], tostring(pitches[i])) end
            end
            test1('Cmaj', 0, {'C', 'E', 'G'})
            test1('Cmaj', 1, {'E', 'G', 'C'})
            test1('Cmaj', 2, {'G', 'C', 'E'})
            test1('Cmaj', 3, {'C', 'E', 'G'})
            test1('Cmaj7', 0, {'C', 'E', 'G', 'B'})
            test1('Cmaj7', 1, {'E', 'G', 'B', 'C'})
            test1('Cmaj7', 2, {'G', 'B', 'C', 'E'})
            test1('Cmaj7', 3, {'B', 'C', 'E', 'G'})
            test1('Cmaj7', 4, {'C', 'E', 'G', 'B'})
        end)

        it('chord_inversion_parsing', function()
            local function test1(chord_name, pitch_names)
                local chord = Chord(chord_name)
                local pitches = chord:pitches(oct)
                assert.equal(#pitch_names, #pitches)
                for i = 1, #pitch_names do assert.equal(pitch_names[i], tostring(pitches[i])) end
            end
            test1('Cmin', {'C', 'Eb', 'G'})
            test1('Cmin/Eb', {'Eb', 'G', 'C'})
            test1('Cmin/G', {'G', 'C', 'Eb'})
        end)

        it('chord_inversion_to_string', function()
            local function test1(chord_name, i, s)
                local chord = Chord(chord_name):invert(i or 0)
                assert.equal(s or chord_name, tostring(chord))
            end
            test1('Cmin')
            test1('Cmin7')
            test1('Cmin', 1, 'Cmin/Eb')
            test1('Cmin', 2, 'Cmin/G')
            test1('Cmin/Eb')
            test1('Cmin/G')
        end)

        it('chord_identify_from_notes', function()
            local function test1(notes_str, chord_str)
                chord_str = tostring(Chord(chord_str))
                local notes = {}
                for _, note_str in ipairs(notes_str) do
                    table.insert(notes, Note(note_str))
                end
                local results = Chord:identify_from_notes(notes)
                assert.is_true(#results > 0, 'no result')
                for _, result in ipairs(results) do
                    local result_str = tostring(result)
                    if result_str == chord_str then return end
                    table.insert(results_str, result_str)
                end
                assert.is_true(false, 'Expected: ' .. chord_str .. ' (not found in results: ' .. table.tostring(results_str) .. ')')
            end
            test1({'C4', 'E4', 'G4'}, 'Cmaj')
            test1({'C4', 'Eb4', 'G4'}, 'Cmin')
            test1({'C4', 'E4', 'G4', 'Bb4'}, 'C7')
            test1({'C2', 'Eb2', 'Gb2'}, 'Cdim')
            test1({'B0', 'D1', 'F1'}, 'Bdim')
        end)

        it('chord_identify_from_intervals', function()
            local function test1(intervals_str, recipe_name, inv)
                local intervals = {}
                for _, interval_str in ipairs(intervals_str) do
                    table.insert(intervals, Interval(interval_str))
                end
                local results = Chord:identify_from_intervals(intervals)
                assert.is_true(#results > 0, 'no result')
                for _, result in ipairs(results) do
                    if result.name == recipe_name and result.inversion == inv then return end
                end
                assert.is_true(false, 'Expected: ' .. recipe_name .. ' inv=' .. inv .. ' (not found in results: ' .. table.tostring(results) .. ')')
            end
            test1({'P1', 'M3', 'P5'}, 'maj', 0)
            test1({'P1', 'm3', 'P5'}, 'min', 0)
        end)
    end)

    describe('TestsForScale', function()
        it('note_scales', function()
            local function test1(root, name, pitches)
                local scale = Scale(root, name)
                local expected = {}
                for _, p in ipairs(pitches) do
                    table.insert(expected, PitchClass:parse(p))
                end
                assert.same(scale.pitches, expected)
            end
            test1('C', 'major', {'C', 'D', 'E', 'F', 'G', 'A', 'B'})
            test1('C', 'natural_minor', {'C', 'D', 'Eb', 'F', 'G', 'Ab', 'Bb'})
            test1('C', 'harmonic_minor', {'C', 'D', 'Eb', 'F', 'G', 'Ab', 'B'})
            test1('C', 'melodic_minor', {'C', 'D', 'Eb', 'F', 'G', 'A', 'B'})
            test1('C', 'dorian', {'C', 'D', 'Eb', 'F', 'G', 'A', 'Bb'})
            test1('C', 'locrian', {'C', 'Db', 'Eb', 'F', 'Gb', 'Ab', 'Bb'})
            test1('C', 'lydian', {'C', 'D', 'E', 'F#', 'G', 'A', 'B'})
            test1('C', 'mixolydian', {'C', 'D', 'E', 'F', 'G', 'A', 'Bb'})
            test1('C', 'phrygian', {'C', 'Db', 'Eb', 'F', 'G', 'Ab', 'Bb'})
            test1('C', 'major_pentatonic', {'C', 'D', 'E', 'G', 'A'})
            test1('C', 'minor_pentatonic', {'C', 'Eb', 'F', 'G', 'Bb'})
            test1('Db', 'natural_minor', {'Db', 'Eb', 'Fb', 'Gb', 'Ab', 'Bbb', 'Cb'})
        end)
    end)

    describe('TestsForUnicodeOutput', function()
        it('unicode_output', function()
            PitchClass.static.unicode_output = true
            local function test1(a, b)
                assert.equal(tostring(Note(a)), b)
            end
            test1('F#3', 'F♯3')
            test1('F##3', 'F𝄪3')
            test1('Gb5', 'G♭5')
            test1('Gbb5', 'G𝄫5')
        end)
    end)
end

if arg[1] == 'test' then
    arg = {}
    test()
else
    return {
        PitchClass = PitchClass,
        Note = Note,
        Interval = Interval,
        Chord = Chord,
        Scale = Scale,
        test = test,
    }
end
