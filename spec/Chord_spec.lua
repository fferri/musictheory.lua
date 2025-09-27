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
local utils = require 'musictheory.utils'

describe('TestsForChord', function()
    it('chord_creation', function()
        mt.PitchClass.static.unicode_output = false
        local function test1(root, name, strchord)
            assert.equal(tostring(mt.Chord(mt.PitchClass(root), name)), strchord)
            if name then
                assert.equal(tostring(mt.Chord(root, name)), strchord)
            end
        end
        test1('A', 'maj', 'Amaj')
        test1('B', 'min', 'Bmin')
        test1('C', 'dim', 'Cdim')
        test1('D', 'aug', 'Daug')
        test1('A#', 'maj', 'A#maj')
        test1('Bb', 'maj', 'Bbmaj')

        assert.equal(tostring(mt.Chord(mt.PitchClass('A'), 'maj')), 'Amaj')

        local bad_names = {'A$', 'H', 'C#1', 'C#1maj', 'C#maj1'}
        for _, name in ipairs(bad_names) do
            assert.has_error(function() mt.Chord(name) end, nil, 'should error: ' .. name)
        end

        local bad_types = {'nice', '$', 'diminished'}
        for _, t in ipairs(bad_types) do
            assert.has_error(function() mt.Chord(mt.PitchClass('C'), t) end)
        end

        assert.has_error(function() mt.Chord(mt.Note('F#4')) end)
        assert.has_error(function() mt.Chord(mt.PitchClass('F#'), 'locrian') end)
        assert.has_error(function() mt.Chord(mt.PitchClass('F#'), 3.56) end)
        assert.has_error(function() mt.Chord(mt.PitchClass('F#'), {'Z1', mt.Interval('m3')}) end)
        assert.has_error(function() mt.Chord(mt.PitchClass('F#'), {'P1', 'm3', 5.66}) end)
        assert.has_error(function() mt.Chord(mt.PitchClass('F#'), {mt.Interval('m3'), 8.88}) end)
    end)

    it('chord_parsing', function()
        local function test1(name, root, chord_type)
            assert.equal(mt.Chord(name), mt.Chord(mt.PitchClass(root), chord_type))
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
            assert.has_error(function() mt.Chord(v) end)
        end
    end)

    it('chord_invert', function()
        local function test1(chord_name, i, pitch_names)
            local chord = mt.Chord(chord_name):invert(i)
            local pitches = chord.pitches
            assert.equal(#pitch_names, #pitches)
            for i = 1, #pitch_names do assert.equal(pitch_names[i], tostring(pitches[i])) end
        end
        test1('Cmaj', 0, {'C', 'E', 'G'})
        test1('Cmaj', 1, {'E', 'G', 'C'})
        test1('Cmaj', 2, {'G', 'C', 'E'})
        test1('Cmaj7', 0, {'C', 'E', 'G', 'B'})
        test1('Cmaj7', 1, {'E', 'G', 'B', 'C'})
        test1('Cmaj7', 2, {'G', 'B', 'C', 'E'})
        test1('Cmaj7', 3, {'B', 'C', 'E', 'G'})
        local function test2(chord_name, i)
            assert.has_error(function() mt.Chord(chord_name):invert(i) end)
        end
        test2('Cmaj', 3)
        test2('Cmaj7', 4)
        test2('Cmaj7', 10)
        test2('Cmaj7', -4)
    end)

    it('chord_inversion_parsing', function()
        local function test1(chord_name, pitch_names)
            local chord = mt.Chord(chord_name)
            local pitches = chord.pitches
            assert.equal(#pitch_names, #pitches)
            for i = 1, #pitch_names do assert.equal(pitch_names[i], tostring(pitches[i])) end
        end
        test1('Cmin', {'C', 'Eb', 'G'})
        test1('Cmin/Eb', {'Eb', 'G', 'C'})
        test1('Cmin/G', {'G', 'C', 'Eb'})
    end)

    it('chord_inversion_to_string', function()
        local function test1(chord_name, i, s)
            local chord = mt.Chord(chord_name):invert(i or 0)
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
            chord_str = tostring(mt.Chord(chord_str))
            local notes = {}
            for _, note_str in ipairs(notes_str) do
                table.insert(notes, mt.Note(note_str))
            end
            local results = mt.Chord:identify_from_notes(notes)
            assert.is_true(#results > 0, 'no result for ' .. utils.table.tostring(notes_str))
            local results_str = {}
            for _, result in ipairs(results) do
                local result_str = tostring(result)
                if result_str == chord_str then return end
                table.insert(results_str, result_str)
            end
            assert.is_true(false, 'Expected: ' .. chord_str .. ' (not found in results: ' .. utils.table.tostring(results_str) .. ')')
        end
        test1({'C4', 'E4', 'G4'}, 'Cmaj')
        test1({'C4', 'Eb4', 'G4'}, 'Cmin')
        test1({'C4', 'E4', 'G4', 'Bb4'}, 'C7')
        test1({'C2', 'Eb2', 'Gb2'}, 'Cdim')
        test1({'B0', 'D1', 'F1'}, 'Bdim')
        test1({'F#3', 'A3', 'C4', 'E4'}, 'F#min7dim5')
        test1({'C3', 'F#3', 'A3', 'E4'}, 'F#min7dim5/C')
    end)

    it('chord_identify_from_intervals', function()
        local function test1(intervals_str, recipe_name, inv)
            local intervals = {}
            for _, interval_str in ipairs(intervals_str) do
                table.insert(intervals, mt.Interval(interval_str))
            end
            local results = mt.Chord:identify_from_intervals(intervals)
            assert.is_true(#results > 0, 'no result for ' .. utils.table.tostring(intervals_str))
            for _, chord in ipairs(results) do
                if chord.recipe == recipe_name and (chord.inversion or 0) == inv then return end
            end
            assert.is_true(false, 'Expected: ' .. recipe_name .. ' inv=' .. inv .. ' (not found in results: ' .. utils.table.tostring(utils.table.map(tostring, results)) .. ')')
        end
        test1({'P1', 'M3', 'P5'}, 'maj', 0)
        test1({'P1', 'm3', 'P5'}, 'min', 0)
        test1({'P1', 'm3', 'd5', 'm7'}, 'min7dim5', 0)
        test1({'P1', 'm10', 'd5', 'm14'}, 'min7dim5', 0)
    end)
end)
