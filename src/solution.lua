local validator = {}

function validator.validate(plan)
    return plan.mutations ~= nil
end

return validator
