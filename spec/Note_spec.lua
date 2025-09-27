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

describe('TestsForNote', function()
    it('note_creation', function()
        local function test1(s, pcn, pca, o)
            local n = mt.Note(mt.PitchClass(pcn, pca), o)
            assert.equal(n.pitch_class.name, pcn)
            assert.equal(n.pitch_class.accidentals, pca)
            assert.equal(n.octave, o)
            assert.equal(n, mt.Note(s))
        end
        test1('C#4', 'C', 1, 4)
        test1('C2', 'C', 0, 2)

        local bad_values = {'C', 1, true, nil, 1.5, {}, function() end}
        for _, v in ipairs(bad_values) do
            assert.has_error(function() mt.Note(v, 0) end)
        end
        for _, v in ipairs{1.5, {}, function() end} do
            assert.has_error(function() mt.Note(mt.PitchClass('C'), v) end)
        end
    end)

    it('note_parsing', function()
        local function test1(note, strnote)
            assert.equal(tostring(mt.Note(note)), strnote)
        end
        mt.PitchClass.static.unicode_output = false
        test1('A4', 'A4')
        test1('Ab6', 'Ab6')
        test1('Dbb4', 'Dbb4')
        test1('G###0', 'G###0')

        local bad_notes = {'A99', 'A#', 'Ab#', 'E#######5'}
        for _, note in ipairs(bad_notes) do
            assert.has_error(function() mt.Note(note) end, nil, 'should error: ' .. note)
        end

        local function test3(note, pitch_class)
            assert.equal(tostring(mt.Note(note).pitch_class), pitch_class)
        end
        mt.PitchClass.static.unicode_output = false
        test3('A4', 'A')
        test3('Ab6', 'Ab')
        test3('Dbb3', 'Dbb')
        test3('G###0', 'G###')

        local function test4(note, pitch_name)
            assert.equal(mt.Note(note).pitch_class.name, pitch_name)
        end
        test4('A4', 'A')
        test4('Ab6', 'A')
        test4('Dbb3', 'D')
        test4('G###0', 'G')

        local function test5(note, acc)
            assert.equal(mt.Note(note).pitch_class.accidentals, acc)
        end
        test5('A4', 0)
        test5('Ab6', -1)
        test5('Dbb3', -2)
        test5('G###0', 3)

        local function test6(note, octave)
            assert.equal(mt.Note(note).octave, octave)
        end
        test6('A4', 4)
        test6('Ab6', 6)
        test6('Dbb3', 3)
        test6('G###0', 0)

        local bad_values = {1, true, nil, 1.5, {}, function() end}
        for _, v in ipairs(bad_values) do
            assert.has_error(function() mt.Note(v) end)
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
        mt.PitchClass.static.unicode_output = false
        for _, n in ipairs(mt.Note:all(4, 5)) do
            table.insert(actual, tostring(n))
        end
        table.sort(actual)
        table.sort(expected)
        assert.same(actual, expected)
    end)

    it('note_oct', function()
        local function test1(n1, oc, n2)
            assert.equal(mt.Note(n1):to_octave(oc), mt.Note(n2))
        end
        test1('C#2', 5, 'C#5')
        test1('B#6', 3, 'B#3')
        test1('Cbbb6', 6, 'Cbbb6')
        test1('Ebb5', 1, 'Ebb1')

        assert.equal(mt.Note('C#4').octave, 4)
        assert.equal(mt.Note('C#4'):to_octave(5).octave, 5)
    end)

    it('note_midi', function()
        local function test1(note, midi)
            assert.equal(mt.Note(note).midi_note, midi)
        end
        test1('C4', 60)
        test1('D5', 74)
    end)

    it('note_add', function()
        local function test1(note, interval, result)
            note = mt.Note(note)
            interval = mt.Interval(interval)
            result = mt.Note(result)
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

        assert.has_error(function() return mt.Note('C4') + {} end)
        assert.has_error(function() return mt.Note('C4') + 'invalid' end)
    end)

    it('note_sub', function()
        local function test1(note1, note2, result)
            assert.equal(mt.Note(note1) - mt.Note(note2), mt.Interval(result))
        end
        test1('E4', 'C4', 'M3')
        test1('G5', 'C5', 'P5')
        test1('C#6', 'C6', 'A1')
        test1('Cb7', 'C7', 'd1')

        assert.has_error(function() return mt.Note('C4') - mt.Note('C5') end)
        assert.has_error(function() return mt.Note('C4') - {} end)
        assert.has_error(function() return mt.Note('C4') - 'invalid' end)
    end)

    it('note_freq', function()
        local function test1(note, freq)
            assert.near(mt.Note(note).frequency, freq, 0.1)
        end
        test1('A4', 440.0)
        test1('A5', 880.0)
        test1('C5', 523.3)
    end)

    it('note_lilypond', function()
        local function test1(n, ln)
            assert.equal(mt.Note(n).lilypond_notation, ln)
        end
        test1('C3', 'c')
        test1('C#4', 'cis\'')
        test1('Cb2', 'ces,')
    end)

    it('note_repr', function()
        mt.PitchClass.static.unicode_output = false
        assert.equal(tostring(mt.Note('C#4')), 'C#4')
    end)

    it('note_ordering', function()
        local function test1(l1, l2)
            local t1 = {}
            for _, s in ipairs(l1) do table.insert(t1, mt.Note(s)) end
            table.sort(t1)
            local t2 = {}
            for _, s in ipairs(l2) do table.insert(t2, mt.Note(s)) end
            assert.same(t1, t2)
        end
        test1({'G#3', 'D3', 'Ab3'}, {'D3', 'G#3', 'Ab3'})

        local function test2(a, b)
            assert.is_true(mt.Note(a) <= mt.Note(b))
        end
        test2('G#3', 'G##3')
        test2('G#3', 'G#3')
        test2('G###3', 'A3')
    end)

    it('note_hashing', function()
        local s = {}
        s[tostring(mt.Note('C#4'))] = true
        s[tostring(mt.Note('C#4'))] = true
        s[tostring(mt.Note('Db4'))] = true
        assert.equal(utils.set.size(s), 2)
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
            local notes_list = mt.Note:from_number(num, allacc)
            local notes_str_list = {}
            for _, n in pairs(notes_list) do
                table.insert(notes_str_list, tostring(n))
            end
            table.sort(notes_str_list)
            table.sort(notes)
            assert.equal(utils.table.tostring(notes), utils.table.tostring(notes_str_list))
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

describe('TestsForUnicodeOutput', function()
    it('unicode_output', function()
        mt.PitchClass.static.unicode_output = true
        local function test1(a, b)
            assert.equal(tostring(mt.Note(a)), b)
        end
        test1('F#3', 'F♯3')
        test1('F##3', 'F𝄪3')
        test1('Gb5', 'G♭5')
        test1('Gbb5', 'G𝄫5')
    end)
end)
