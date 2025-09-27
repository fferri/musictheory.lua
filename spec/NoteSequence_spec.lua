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

describe('TestsForNoteSequence', function()
    it('add_remove_check', function()
        local s = mt.NoteSequence()
        assert.same(s:get_notes(), {})
        s:set_note(2, 'C')
        s:set_note(3, 'D')
        assert.is_nil(s:get_note(3, 'C'))
        assert.is_not_nil(s:get_note(2, 'C'))
        assert.is_not_nil(s:get_note(3, 'D'))
        s:clear_note(3, 'D')
        assert.is_nil(s:get_note(3, 'D'))
        assert.is_not_nil(s:get_note(2, 'C'))
        s:move_note(2, 'C', 2, 'D')
        assert.is_nil(s:get_note(2, 'C'))
        assert.is_not_nil(s:get_note(2, 'D'))
        s:move_note(2, 'D', 3, 'D')
        assert.is_nil(s:get_note(2, 'D'))
        assert.is_not_nil(s:get_note(3, 'D'))
        s:set_note(6, 'F')
        local notes = s:get_notes()
        table.sort(notes, function(a, b) return a.time < b.time end)
        assert.are.same(notes, {{time = 3, note = 'D', duration = 1}, {time = 6, note = 'F', duration = 1}})
    end)
end)
