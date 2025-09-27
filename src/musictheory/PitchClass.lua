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

local PitchClass = class 'PitchClass'

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
        name, accidentals_str = utils.utf8.sub(pitch_class_str, 1, 1), utils.utf8.sub(pitch_class_str, 2)
        if accidentals_str == '' then
        elseif accidentals_str == '𝄫' then
            accidentals = accidentals - 2
        elseif accidentals_str == '𝄪' then
            accidentals = accidentals + 2
        else
            local acc0 = utils.utf8.sub(accidentals_str, 1, 1)
            assert(acc0 == '#' or acc0 == 'b' or acc0 == '♯' or acc0 == '♭', 'invalid pitch class: ' .. pitch_class_str)
            for i = 2, utf8.len(accidentals_str) do
                assert(utils.utf8.sub(accidentals_str, i, i) == acc0, 'inconsistent accidentals')
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
    return utils.table.compare({PitchClass.info[self.name].number, self.accidentals}, {PitchClass.info[other.name].number, other.accidentals})
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
    local Note = require 'musictheory.Note'
    return Note(self, octave)
end

return PitchClass
