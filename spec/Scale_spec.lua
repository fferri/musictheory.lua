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

local mt = require 'musictheory'

describe('TestsForScale', function()
    it('note_scales', function()
        local function test1(root, name, pitches)
            local scale = mt.Scale(root, name)
            local expected = {}
            for _, p in ipairs(pitches) do
                table.insert(expected, mt.PitchClass(p))
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
