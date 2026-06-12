local kata = {}

function kata.validate(plan)
    return plan.mutations ~= nil
end

return kata
