local validator = {}

function validator.validate(plan)
    return plan.mutations ~= nil
end

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function validator.apply_mutation(mutation, source)
    return string.gsub(source, escape_pattern(mutation.original), mutation.replacement)
end

function validator.apply_plan(plan, source)
    local result = source
    for _, mutation in ipairs(plan.mutations) do
        result = validator.apply_mutation(mutation, result)
    end
    return result
end

return validator
