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

local PitchClass = mt.PitchClass
local Note = mt.Note
local Interval = mt.Interval
local Chord = mt.Chord
local Scale = mt.Scale

local set = {}

function set.size(t)
    local sz = 0
    for k, v in pairs(t) do sz = sz + 1 end
    return sz
end

describe('TestsForPitchClass', function()
    it('pitchclass_creation', function()
        local function test1(pc, n, a)
            local p = PitchClass(pc)
            assert.are.same({p.name, p.accidentals}, {n, a})
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
            assert.equal(PitchClass(s), PitchClass(name, accidentals))
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
            assert.has_error(function() PitchClass(name) end)
        end

        local function test3(a, b)
            assert.equal(PitchClass(a), PitchClass(b))
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
            assert.has_error(function() PitchClass(v) end)
        end
    end)

    it('pitchclass_gen', function()
        local function test1(s)
            local p = PitchClass(s)
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
            local pa = PitchClass(a)
            local pb = PitchClass(b)
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
            for _, s in ipairs(l1) do table.insert(t1, PitchClass(s)) end
            table.sort(t1)
            local t2 = {}
            for _, s in ipairs(l2) do table.insert(t2, PitchClass(s)) end
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
            assert.has_error(function() Note(note) end, nil, 'should error: ' .. note)
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
            assert.has_error(function() Note(v) end)
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
            interval = Interval(interval)
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
            assert.equal(Note(note1) - Note(note2), Interval(result))
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
            local i = Interval(interval)
            assert.equal(i.semitones, semitones)
            assert.equal(i.size, size)
        end
        test1('d5', 6, 5)
        test1('P8', 12, 8)
        test1('A8', 13, 8)

        local bad_intervals = {'P3', '<86ygr', {}}
        for _, interval in ipairs(bad_intervals) do
            assert.has_error(function() Interval(interval) end)
        end
    end)

    it('interval_add_sub', function()
        assert.equal(Interval('P5') + Interval('m3'), Interval('m7'))
        assert.equal(Interval('P5') + Interval('m3') + Interval('M2'), Interval('P8'))
        assert.equal(Interval('P5') + Interval('m3') + Interval('M2') + Interval('P8'), Interval('P15'))
        assert.equal(Interval('P5') + Interval('m3') + Interval('M2') - Interval('P8'), Interval('P1'))
        assert.has_error(function() return Interval('m3') - Interval('P5') end)
    end)

    it('interval_complement', function()
        local function test1(i, c)
            assert.equal(Interval(i):complement(), Interval(c))
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

        assert.has_error(function() Interval('M9'):complement() end)
        assert.has_error(function() Interval('M10'):complement() end)
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
        test1('B', 'min', 'Bmin')
        test1('C', 'dim', 'Cdim')
        test1('D', 'aug', 'Daug')
        test1('A#', 'maj', 'A#maj')
        test1('Bb', 'maj', 'Bbmaj')

        assert.equal(tostring(Chord(PitchClass('A'), 'maj')), 'Amaj')

        local bad_names = {'A$', 'H', 'C#1', 'C#1maj', 'C#maj1'}
        for _, name in ipairs(bad_names) do
            assert.has_error(function() Chord(name) end, nil, 'should error: ' .. name)
        end

        local bad_types = {'nice', '$', 'diminished'}
        for _, t in ipairs(bad_types) do
            assert.has_error(function() Chord(PitchClass('C'), t) end)
        end

        assert.has_error(function() Chord(Note('F#4')) end)
        assert.has_error(function() Chord(PitchClass('F#'), 'locrian') end)
        assert.has_error(function() Chord(PitchClass('F#'), 3.56) end)
        assert.has_error(function() Chord(PitchClass('F#'), {'Z1', Interval('m3')}) end)
        assert.has_error(function() Chord(PitchClass('F#'), {'P1', 'm3', 5.66}) end)
        assert.has_error(function() Chord(PitchClass('F#'), {Interval('m3'), 8.88}) end)
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
            assert.has_error(function() Chord(v) end)
        end
    end)

    it('chord_invert', function()
        local function test1(chord_name, i, pitch_names)
            local chord = Chord(chord_name):invert(i)
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
            assert.has_error(function() Chord(chord_name):invert(i) end)
        end
        test2('Cmaj', 3)
        test2('Cmaj7', 4)
        test2('Cmaj7', 10)
        test2('Cmaj7', -4)
    end)

    it('chord_inversion_parsing', function()
        local function test1(chord_name, pitch_names)
            local chord = Chord(chord_name)
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
            assert.is_true(#results > 0, 'no result for ' .. table.tostring(notes_str))
            local results_str = {}
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
        test1({'F#3', 'A3', 'C4', 'E4'}, 'F#min7dim5')
        test1({'C3', 'F#3', 'A3', 'E4'}, 'F#min7dim5/C')
    end)

    it('chord_identify_from_intervals', function()
        local function test1(intervals_str, recipe_name, inv)
            local intervals = {}
            for _, interval_str in ipairs(intervals_str) do
                table.insert(intervals, Interval(interval_str))
            end
            local results = Chord:identify_from_intervals(intervals)
            assert.is_true(#results > 0, 'no result for ' .. table.tostring(intervals_str))
            for _, chord in ipairs(results) do
                if chord.recipe == recipe_name and (chord.inversion or 0) == inv then return end
            end
            assert.is_true(false, 'Expected: ' .. recipe_name .. ' inv=' .. inv .. ' (not found in results: ' .. table.tostring(table.map(tostring, results)) .. ')')
        end
        test1({'P1', 'M3', 'P5'}, 'maj', 0)
        test1({'P1', 'm3', 'P5'}, 'min', 0)
        test1({'P1', 'm3', 'd5', 'm7'}, 'min7dim5', 0)
        test1({'P1', 'm10', 'd5', 'm14'}, 'min7dim5', 0)
    end)
end)

describe('TestsForScale', function()
    it('note_scales', function()
        local function test1(root, name, pitches)
            local scale = Scale(root, name)
            local expected = {}
            for _, p in ipairs(pitches) do
                table.insert(expected, PitchClass(p))
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
