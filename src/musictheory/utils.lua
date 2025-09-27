local utils = {}

utils.table = {}
utils.utf8 = {}
utils.set = {}

function utils.table.contains(tbl, item)
    for i, x in ipairs(tbl) do
        if x == item then
            return true
        end
    end
    return false
end

function utils.table.compare(a, b)
    for i = 1, math.min(#a, #b) do
        if a[i] < b[i] then return -1 end
        if a[i] > b[i] then return 1 end
    end
    if #a < #b then return -1 end
    if #a > #b then return 1 end
    return 0
end

function utils.table.tostring(t)
    local s, visited = '', {}
    for i, p in ipairs{{ipairs(t)}, {pairs(t)}} do
        for k, v in table.unpack(p) do
            if not visited[k] then
                s = s .. (s == '' and '' or ', ') .. (i > 1 and (k .. ' = ') or '') .. (type(v) == 'table' and utils.table.tostring(v) or tostring(v))
                visited[k] = true
            end
        end
    end
    return '{' .. s .. '}'
end

function utils.table.map(f, ...)
    assert(type(f) == 'function')
    local tbls, ret = {...}, {}
    local i = 1
    while true do
        local args = {}
        for j, tbl in ipairs(tbls) do
            assert(type(tbl) == 'table')
            if tbl[i] == nil then return ret end
            table.insert(args, tbl[i])
        end
        table.insert(ret, f(table.unpack(args)))
        i = i + 1
    end
    return ret
end

function utils.table.reduce(f, tbl, initial)
    assert(type(f) == 'function')
    assert(type(tbl) == 'table')
    initial = initial or 0
    local y = initial
    for i, x in ipairs(tbl) do y = f(y, x) end
    return y
end

function utils.table.filter(f, tbl)
    assert(type(f) == 'function')
    assert(type(tbl) == 'table')
    local ret = {}
    for i, x in ipairs(tbl) do if f(x) then table.insert(ret, x) end end
    return ret
end

function utils.table.keys(tbl)
    local ret = {}
    for k, v in pairs(tbl) do table.insert(ret, k) end
    return ret
end

function utils.table.slice(tbl, first, last, step)
    local ret = {}
    for i = first or 1, last or #t, step or 1 do table.insert(ret, tbl[i]) end
    return ret
end

function utils.utf8.sub(s, i, j)
    local start_byte = utf8.offset(s, i) or (#s + 1)
    local end_byte = j and (utf8.offset(s, j + 1) or (#s + 1)) - 1 or #s
    return s:sub(start_byte, end_byte)
end

function utils.set.size(t)
    local sz = 0
    for k, v in pairs(t) do sz = sz + 1 end
    return sz
end

return utils
