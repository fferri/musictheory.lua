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

local NoteSequence = class 'NoteSequence'

function NoteSequence.static:get_time(time, var_name)
    var_name = var_name or 'time'
    assert(type(time) == 'number', 'invalid type for ' .. var_name)
    if math.type(time) ~= 'integer' then
        assert(math.abs(time - math.floor(time)) < 1e-5, 'time must be integer')
        time = math.floor(time)
    end
    return time
end

function NoteSequence.static:get_note(note, var_name)
    var_name = var_name or 'note'
    assert(type(note) ~= 'nil' and type(note) ~= 'table', 'invalid type for note')
    return note
end

function NoteSequence.static:get_time_note(time, note, time_var_name, note_var_name)
    return NoteSequence:get_time(time, time_var_name), NoteSequence:get_note(note, note_var_name)
end

function NoteSequence.static:pack_note(time, note, info)
    time, note = NoteSequence:get_time_note(time, note)
    local note_info = {}
    for k, v in pairs(info) do
        note_info[k] = v
    end
    note_info.time = time
    note_info.note = note
    return note_info
end

function NoteSequence:initialize()
    self.listeners = {}
    self.data = {} -- time -> note -> info (duration + user fields)
end

function NoteSequence:clear(opts)
    opts = opts or {}
    for _, note_info in ipairs(self:get_notes()) do
        if opts.notify ~= false then
            self:notify_listeners('removed', note_info)
        end
    end
    self.data = {}
end

function NoteSequence:get_notes(pred)
    local ret = {}
    for time, notes in pairs(self.data) do
        for note, info in pairs(notes) do
            local note_info = NoteSequence:pack_note(time, note, info)
            if pred == nil or pred(note_info) then
                table.insert(ret, note_info)
            end
        end
    end
    return ret
end

function NoteSequence:get_notes_in_range(time_min, time_max, note_min, note_max)
    if note_min and note_max then
        time_min, note_min = NoteSequence:get_time_note(time_min, note_min, 'time_min', 'note_min')
        time_max, note_max = NoteSequence:get_time_note(time_max, note_max, 'time_max', 'note_max')
        return self:get_notes(function(n)
            return time_min < (n.time + n.duration) and time_max >= n.time and note_min <= n.note and n.note <= note_max
        end)
    else
        time_min = NoteSequence:get_time(time_min, 'time_min')
        time_max = NoteSequence:get_time_note(time_max, 'time_max')
        return self:get_notes(function(n)
            return time_min < (n.time + n.duration) and time_max >= n.time
        end)
    end
end

function NoteSequence:get_notes_starting_at(time)
    time = NoteSequence:get_time(time)
    local ret = {}
    for note, info in pairs(self.data[time] or {}) do
        local note_info = NoteSequence:pack_note(time, note, info)
        table.insert(ret, note_info)
    end
    return ret
end

function NoteSequence:get_note(time, note)
    time, note = NoteSequence:get_time_note(time, note)
    if not self.data[time] or not self.data[time][note] then return end
    local note_info = NoteSequence:pack_note(time, note, self.data[time][note])
    return note_info
end

function NoteSequence:set_note(time, note, info, opts)
    opts = opts or {}
    time, note = NoteSequence:get_time_note(time, note)
    assert(type(info) == 'table' or info == nil, 'invalid type for note info')
    info = info or {}
    if not self.data[time] then self.data[time] = {} end
    local added = false
    if not self.data[time][note] then
        self.data[time][note] = {}
        added = true
    end
    local old_info = self:get_note(time, note)
    local changed = false
    -- duration is the only special value handled here
    self.data[time][note].duration = NoteSequence:get_time(info.duration or old_info.duration or 1, 'duration')
    if self.data[time][note].duration ~= old_info.duration then
        changed = true
    end
    -- the user can add as many values as he wants:
    local reserved = {time = true, note = true, duration = true}
    for k, v in pairs(info) do
        if not reserved[k] then
            if self.data[time][note][k] ~= v then
                changed = true
            end
            self.data[time][note][k] = v
        end
    end
    if opts.notify ~= false and (added or changed) then
        self:notify_listeners(added and 'added' or 'changed', self:get_note(time, note))
    end
end

function NoteSequence:clear_note(time, note, opts)
    opts = opts or {}
    time, note = NoteSequence:get_time_note(time, note)
    if self.data[time] then
        if self.data[time][note] then
            if opts.notify ~= false then
                self:notify_listeners('removed', self:get_note(time, note))
            end
            self.data[time][note] = nil
            if next(self.data[time]) == nil then
                self.data[time] = nil
            end
        end
    end
end

function NoteSequence:move_note(time, note, new_time, new_note, opts)
    opts = opts or {}
    time, note = NoteSequence:get_time_note(time, note)
    local note_info = self:get_note(time, note)
    assert(note_info ~= nil, 'note does not exist')
    new_time, new_note = NoteSequence:get_time_note(new_time, new_note, 'new_time', 'new_note')
    if note == new_note and time == new_time then return end
    self:clear_note(note_info.time, note_info.note, {notify = false})
    self:set_note(new_time, new_note, note_info, {notify = false})
    if opts.notify ~= false then
        local note_info = self:get_note(new_time, new_note)
        note_info.old_time = time
        note_info.old_note = note
        self:notify_listeners('changed', note_info)
    end
end

function NoteSequence:add_listener(f)
    self.listeners[f] = {}
end

function NoteSequence:remove_listener(f)
    self.listeners[f] = nil
end

function NoteSequence:notify_listeners(...)
    for listener in pairs(self.listeners) do
        listener(...)
    end
end

return NoteSequence
