local file_io = require("file_io")

local mutator = {}

function mutator.is_valid(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function mutator.apply_mutation(mutation, source)
    local pattern = escape_pattern(mutation.original)
    return source:gsub(pattern, mutation.replacement)
end

function mutator.apply_mutation_to_file(mutation, input_path, output_path)
    local source = file_io.read(input_path)
    local result = mutator.apply_mutation(mutation, source)
    file_io.write(output_path, result)
end

function mutator.apply_plan(plan, source)
    local result = source
    for _, mutation in ipairs(plan.mutations) do
        result = mutator.apply_mutation(mutation, result)
    end
    return result
end

return mutator
