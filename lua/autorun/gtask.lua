--[[

Task

Author: tochnonement
Email: tochnonement@gmail.com
Steam: steamcommunity.com/profiles/76561198086200873

08.12.2020

--]]

local remove, CurTime, unpack, isstring, isnumber, isfunction = table.remove, CurTime, unpack, isstring, isnumber, isfunction

local task = {}
local stored = {}

local function NewTask(data)
    local index = #stored + 1

    data.started = CurTime()
    data.index = index

    stored[index] = data
end

local function CallTask(index)
    local curtime = CurTime()
    local data = stored[index]
    local time = data.time
    local started = data.started
    local difference = curtime - started
    local repeats = data.repeats or 1
    local done = false

    if difference >= time then
        if not data.infinite then
            if repeats > 0 then
                data.started = curtime
                repeats = repeats - 1
            end

            if repeats < 1 then
                done = true
            end
        else
            data.started = curtime
        end

        data.func( unpack(data.args) )

        if done then
            remove(stored, index)
        end

        data.repeats = repeats

        return true
    end

    return false
end

--- Create a simple task
---@param time number
---@param func function
function task.Simple(time, func, ...)
    assert(time, "<time> cannot be empty")
    assert(func, "<func> cannot be empty")
    assert(isnumber(time), "<time> should be a number")
    assert(isfunction(func), "<func> must be a function")

    NewTask({
        time = time,
        func = func,
        args = {...}
    })
end

--- Create a task with identifier
--- Feature to set repetitions
---@param name string
---@param time number
---@param repeats number
---@param func function
function task.Create(name, time, repeats, func, ...)
    assert(name, "<name> cannot be empty")
    assert(time, "<time> cannot be empty")
    assert(func, "<func> cannot be empty")
    assert(isstring(name), "<name> should be a string")
    assert(isnumber(time), "<time> should be a number")
    assert(isfunction(func), "<func> must be a function")

    NewTask({
        time = time,
        func = func,
        repeats = repeats,
        infinite = (repeats == 0),
        name = name,
        args = {...}
    })
end

--- Remove task by identifier
---@param name string
function task.Remove(name)
    local timer_name
    for index, data in ipairs(stored) do
        timer_name = data.name or ""
        if (timer_name == name) then
            remove(stored, index)
        end
    end
end

--- Return all tasks
---@return table
function task.GetTable()
    return stored
end

hook.Add("Think", "Task.Think", function()
    for index in ipairs(stored) do
        CallTask(index)
    end
end)

_G["task"] = task