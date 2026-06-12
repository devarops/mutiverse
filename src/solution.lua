local solution = {}

function solution.validate(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function solution.apply_mutation(mutation, source)
    return string.gsub(source, escape_pattern(mutation.original), mutation.replacement)
end

function solution.apply_mutation_to_file(mutation, source_path, output_path)
    local f = io.open(source_path, "r")
    local source = f:read("*a")
    f:close()

    local result = solution.apply_mutation(mutation, source)

    f = io.open(output_path, "w")
    f:write(result)
    f:close()
end

function solution.apply_plan(plan, source)
    local result = source
    for _, mutation in ipairs(plan.mutations) do
        result = solution.apply_mutation(mutation, result)
    end
    return result
end

return solution
