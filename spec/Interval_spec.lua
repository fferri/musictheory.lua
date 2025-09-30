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

describe('TestsForInterval', function()
    it('interval_creation', function()
        assert.has_error(function() mt.Interval(3.6, 6) end)
        assert.has_error(function() mt.Interval('Q', 6) end)
        assert.has_error(function() mt.Interval('P', 6.5) end)
        assert.has_error(function() mt.Interval('P', -1) end)
        assert.has_error(function() mt.Interval('m', 5) end)
    end)

    it('interval_parsing', function()
        local function test1(interval, semitones, size)
            local i = mt.Interval(interval)
            assert.equal(i.semitones, semitones)
            assert.equal(i.size, size)
        end
        test1('d5', 6, 5)
        test1('P8', 12, 8)
        test1('A8', 13, 8)

        local bad_intervals = {'P3', '<86ygr', {}}
        for _, interval in ipairs(bad_intervals) do
            assert.has_error(function() mt.Interval(interval) end)
        end
    end)

    it('interval_add_sub_cmp', function()
        assert.equal(mt.Interval('P5') + mt.Interval('m3'), mt.Interval('m7'))
        assert.equal(mt.Interval('P5') + mt.Interval('m3') + mt.Interval('M2'), mt.Interval('P8'))
        assert.equal(mt.Interval('P5') + mt.Interval('m3') + mt.Interval('M2') + mt.Interval('P8'), mt.Interval('P15'))
        assert.equal(mt.Interval('P5') + mt.Interval('m3') + mt.Interval('M2') - mt.Interval('P8'), mt.Interval('P1'))
        assert.has_error(function() return mt.Interval('m3') - mt.Interval('P5') end)
        assert.has_error(function() return mt.Interval('m3') + 'P1' end)
        assert.has_error(function() return mt.Interval('m3') + 1 end)
        assert.has_error(function() return mt.Interval('m3') + true end)
        assert.has_error(function() return mt.Interval('m3') - 'P1' end)
        assert.has_error(function() return mt.Interval('m3') - 1 end)
        assert.has_error(function() return mt.Interval('m3') - true end)
        assert.is_true(mt.Interval('m3') < mt.Interval('P4'))
        assert.is_true(mt.Interval('m3') <= mt.Interval('m3'))
    end)

    it('interval_complement', function()
        local function test1(i, c)
            assert.equal(mt.Interval(i):complement(), mt.Interval(c))
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

        assert.has_error(function() mt.Interval('M9'):complement() end)
        assert.has_error(function() mt.Interval('M10'):complement() end)
    end)

    it('interval_complement', function()
        local function test1(i1, i2)
            assert.equal(mt.Interval(i1):reduce(), mt.Interval(i2))
        end
        test1('M3', 'M3')
        test1('M10', 'M3')
    end)
end)
