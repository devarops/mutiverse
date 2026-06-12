local file_io = {}

local function with_open(path, mode, func)
    local file = io.open(path, mode)
    local result = func(file)
    file:close()
    return result
end

function file_io.read(path)
    return with_open(path, "r", function(file) return file:read("*a") end)
end

function file_io.write(path, content)
    with_open(path, "w", function(file) file:write(content) end)
end

return file_io
