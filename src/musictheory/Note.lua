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

local Note = class 'Note'

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
        if (allowed_accidentals == -1 and utils.table.contains(PitchClass.info[n.pitch_class.name].normal_accidentals, n.pitch_class.accidentals))
                or (allowed_accidentals ~= -1 and utils.table.contains(allowed_accidentals, n.pitch_class.accidentals)) then
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
    local Interval = require 'musictheory.Interval'
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
    local Interval = require 'musictheory.Interval'
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
    return utils.table.compare({self.octave, self.pitch_class}, {other.octave, other.pitch_class})
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

return Note
