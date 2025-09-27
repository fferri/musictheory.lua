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

describe('TestsForPitchClass', function()
    it('pitchclass_creation', function()
        local function test1(pc, n, a)
            local p = mt.PitchClass(pc)
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
            assert.has_error(function() mt.PitchClass(v, 0) end)
        end
        assert.has_error(function() mt.PitchClass('Z', 0) end)
        for _, v in ipairs({'1', 1.5, {}, function() end}) do
            assert.has_error(function() mt.PitchClass('C', v) end)
        end
        assert.has_error(function() mt.PitchClass('C', 2000) end)
    end)

    it('pitchclass_parsing', function()
        local function test1(s, name, accidentals)
            assert.equal(mt.PitchClass(s), mt.PitchClass(name, accidentals))
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
            assert.has_error(function() mt.PitchClass(name) end)
        end

        local function test3(a, b)
            assert.equal(mt.PitchClass(a), mt.PitchClass(b))
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
            assert.has_error(function() mt.PitchClass(v) end)
        end
    end)

    it('pitchclass_gen', function()
        local function test1(s)
            local p = mt.PitchClass(s)
            local found = false
            for _, x in ipairs(mt.PitchClass:all()) do
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
        assert.has_error(function() mt.PitchClass:all('') end)
    end)

    it('pitchclass_repr', function()
        mt.PitchClass.static.unicode_output = false
        assert.equal(tostring(mt.PitchClass('C')), 'C')
        assert.equal(tostring(mt.PitchClass('C#')), 'C#')
        assert.equal(tostring(mt.PitchClass('Cb')), 'Cb')
        assert.equal(tostring(mt.PitchClass('C', -1)), 'Cb')
    end)

    it('pitchclass_flat_sharp', function()
        assert.equal(mt.PitchClass('C'):sharp(), mt.PitchClass('C#'))
        assert.equal(mt.PitchClass('C'):sharp():sharp(), mt.PitchClass('C##'))
        assert.equal(mt.PitchClass('C#'):sharp(), mt.PitchClass('C##'))
        assert.equal(mt.PitchClass('C#'):flat(), mt.PitchClass('C'))
        assert.equal(mt.PitchClass('B'):flat(), mt.PitchClass('Bb'))
        assert.equal(mt.PitchClass('C#'):natural(), mt.PitchClass('C'))
        assert.equal(mt.PitchClass('C##'):natural(), mt.PitchClass('C'))
        assert.equal(mt.PitchClass('Eb'):natural(), mt.PitchClass('E'))
    end)

    it('pitchclass_tooct', function()
        assert.equal(mt.PitchClass('Eb'):to_octave(5), mt.Note('Eb5'))
    end)

    it('pitchclass_hashing', function()
        local s = {}
        s[tostring(mt.Chord('Cmin'))] = true
        s[tostring(mt.Chord('Dmaj7'))] = true
        assert.is_true(s[tostring(mt.Chord('Cmin'))] ~= nil)
        assert.is_true(s[tostring(mt.Chord('Emin'))] == nil)
        assert.is_true(s[tostring(mt.Chord('Cmin'))] ~= nil)
    end)

    it('pitchclass_ordering', function()
        local function test1(a, b)
            local pa = mt.PitchClass(a)
            local pb = mt.PitchClass(b)
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
            for _, s in ipairs(l1) do table.insert(t1, mt.PitchClass(s)) end
            table.sort(t1)
            local t2 = {}
            for _, s in ipairs(l2) do table.insert(t2, mt.PitchClass(s)) end
            assert.same(t1, t2)
        end
        test2({'C', 'D', 'E', 'F', 'G', 'A', 'B'}, {'C', 'D', 'E', 'F', 'G', 'A', 'B'})
        test2({'A', 'C'}, {'C', 'A'})
        test2({'C#', 'Db', 'Cb', 'Dbb', 'C'}, {'Cb', 'C', 'C#', 'Dbb', 'Db'})
    end)
end)
