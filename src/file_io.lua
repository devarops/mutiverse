local file_io = {}

function file_io.read(path)
    local file = io.open(path, "r")
    local content = file:read("*a")
    file:close()
    return content
end

function file_io.write(path, content)
    local file = io.open(path, "w")
    file:write(content)
    file:close()
end

return file_io
