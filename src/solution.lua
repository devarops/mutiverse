local validator = {}

function validator.validate(plan)
    return plan.mutations ~= nil
end

function validator.apply_mutation(mutation, source)
    return string.gsub(source, mutation.original, mutation.replacement)
end

return validator
