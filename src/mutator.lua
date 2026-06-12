local mutator = {}

function mutator.read_file(path)
    local file = io.open(path, "r")
    local content = file:read("*a")
    file:close()
    return content
end

function mutator.write_file(path, content)
    local file = io.open(path, "w")
    file:write(content)
    file:close()
end

function mutator.is_valid(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function mutator.apply_mutation(mutation, source)
    return string.gsub(source, escape_pattern(mutation.original), mutation.replacement)
end

function mutator.apply_mutation_to_file(mutation, input_path, output_path)
    local source = mutator.read_file(input_path)
    mutator.write_file(output_path, mutator.apply_mutation(mutation, source))
end

function mutator.apply_plan(plan, source)
    local mutated_source = source
    for _, mutation in ipairs(plan.mutations) do
        mutated_source = mutator.apply_mutation(mutation, mutated_source)
    end
    return mutated_source
end

return mutator
