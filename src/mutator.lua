local mutator = {}

function mutator.read_file(path)
    local f = io.open(path, "r")
    local content = f:read("*a")
    f:close()
    return content
end

function mutator.write_file(path, content)
    local f = io.open(path, "w")
    f:write(content)
    f:close()
end

function mutator.validate(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function mutator.apply_mutation(mutation, source)
    return string.gsub(source, escape_pattern(mutation.original), mutation.replacement)
end

function mutator.apply_mutation_to_file(mutation, source_path, output_path)
    local source = mutator.read_file(source_path)
    local result = mutator.apply_mutation(mutation, source)
    mutator.write_file(output_path, result)
end

function mutator.apply_plan(plan, source)
    local result = source
    for _, mutation in ipairs(plan.mutations) do
        result = mutator.apply_mutation(mutation, result)
    end
    return result
end

return mutator
