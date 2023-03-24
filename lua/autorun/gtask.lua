--[[
MIT License

Copyright (c) 2020 Aleksandrs Filipovskis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local VERSION = 114

if gtask and (not gtask.version or gtask.version <= VERSION) then
    return
end

local CurTime, remove, unpack, assert, isnumber, isstring, isfunction, max_table_number = CurTime, table.remove, unpack, assert, isnumber, isstring, isfunction, table.maxn

local task = {version = VERSION}
local stored = {}

local function NewTask(data)
    local index = max_table_number(stored) + 1

    data.started = CurTime()
    data.paused = false
    data.index = index

    stored[index] = data

    return index
end

local function CallTask(index, curtime)
    local data = stored[index]
    if not data or data.paused then return end

    local diff = curtime - data.started
    if diff < data.time then return end

    local repeats = data.repeats
    if not data.infinite then
        if repeats == 1 then
            remove(stored, index)
            goto done
        end

        data.repeats = repeats - 1
    end

    data.started = curtime

    ::done::

    data.func( unpack(data.args) )
end

--- Create simple task
---@param time number
---@param func function
function task.Simple(time, func, ...)
    assert(isnumber(time))
    assert(isfunction(func))

    return NewTask({
        time = time,
        func = func,
        args = {...},
        repeats = 1
    })
end

--- Create advanced task
---@param name string
---@param time number
---@param repeats number
---@param func function
function task.Create(name, time, repeats, func, ...)
    assert(isstring(name))
    assert(isnumber(time))
    assert(isfunction(func))

    if task.Exists(name) then
        task.Kill(name)
    end

    local infinite = (repeats == 0)

    return NewTask({
        name = name,
        time = time,
        func = func,
        args = {...},
        repeats = repeats,
        infinite = infinite
    })
end

--- Get task's data by its name
---@param name string
---@return table
function task.Get(name)
    local length = max_table_number(stored)
    for index = 1, length do
        local data = stored[index]
        if data and data.name == name then
            return data, index
        end
    end
end

--- Get all tasks
---@return table
function task.GetTable()
    return table.Copy(stored)
end

--- Check if task with given name exists
---@param name string
---@return boolean
function task.Exists(name)
    return task.Get(name) ~= nil
end

--- Delete task
--- *Alias: task.Remove*
---@param name string
function task.Kill(name)
    local _, index = task.Get(name)
    if index then
        remove(stored, index)
    end
end

--- Get how many repetitions left
---@param name string
---@return number
function task.RepsLeft(name)
    local obj = task.Get(name)

    return obj.repeats
end

--- Get how much **not rounded** time left
---@param name string
---@return number
function task.TimeLeft(name)
    local obj = task.Get(name)
    local diff = (CurTime() - obj.started)

    return obj.time - diff
end

--- Get task delay
---@param name string
---@return number
function task.GetDelay(name)
    local obj = task.Get(name)

    return obj.time
end

--- Pause or unpause task
---@param name string
---@param bool boolean
function task.Pause(name, bool)
    local obj = task.Get(name)

    obj.paused = bool
end

--- Toggle task (pause or unpause)
---@param name string
function task.Toggle(name)
    local obj = task.Get(name)

    obj.paused = not obj.paused
end

--- Adjust task's delay
---@param name string
---@param time number
function task.Adjust(name, time)
    local obj = task.Get(name)

    obj.time = time
    obj.started = CurTime()
end

--- Do one repeat for task
---@param name string
function task.Complete(name)
    local obj = task.Get(name)
    obj.time = 0
end

task.Remove = task.Kill

local run_timers = function()
    local curtime = CurTime()
    local length = max_table_number(stored)
    if length > 1000 and length > #stored then --Rebase if we surpass 1000 "timers" and our length is greater than the actual table length, if what you're working on has more than 1000 real timers then idk what you're doing
        local dummy_table = {}
        for index, data in pairs(stored) do
            dummy_table[#dummy_table + 1] = data
        end

        stored = {}
        for index = 1, #dummy_table do
            local data = dummy_table[index]
            stored[index] = data
        end

        length = #stored
    end

    for index = 1, length do
        CallTask(index, curtime)
    end
end

hook.Add("Tick", "gtask.Tick", run_timers)

_G.gtask = task