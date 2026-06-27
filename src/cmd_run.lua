package.path = "src/?.lua;" .. package.path
local mutator = require("mutator")

local plan_path
local test_command
local report_path
local fail_mode

for i = 1, #arg, 2 do
    local flag = arg[i]
    local value = arg[i + 1]
    if flag == "--plan" then
        plan_path = value
    elseif flag == "--test-command" then
        test_command = value
    elseif flag == "--report" then
        report_path = value
    elseif flag == "--fail" then
        fail_mode = value
    end
end

local _, killed, survived = mutator.apply_mutations_from_plan(plan_path, test_command, report_path)

if survived > 0 then
    os.exit(1)
end
