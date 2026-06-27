package.path = "src/?.lua;" .. package.path
local mutator = require("mutator")

local plan_path
for i = 1, #arg, 2 do
    if arg[i] == "--plan" then
        plan_path = arg[i + 1]
    end
end

mutator.validate_plan_file(plan_path)
