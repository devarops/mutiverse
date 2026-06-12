local file_io = require("file_io")

local mutator = {}

function mutator.is_valid(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function mutator.apply_mutation(mutation, source)
    return source:gsub(escape_pattern(mutation.original), mutation.replacement)
end

function mutator.apply_mutation_to_file(mutation, input_path, output_path)
    local source = file_io.read(input_path)
    local mutated_source = mutator.apply_mutation(mutation, source)
    file_io.write(output_path, mutated_source)
end

function mutator.apply_plan(plan, source)
    local mutated_source = source
    for _, mutation in ipairs(plan.mutations) do
        mutated_source = mutator.apply_mutation(mutation, mutated_source)
    end
    return mutated_source
end

return mutator
