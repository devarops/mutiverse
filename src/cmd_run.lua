package.path = "src/?.lua;" .. package.path
local mutator = require("mutator")

local EXIT_FAILURE = 1
local EXIT_USAGE = 2

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

if not plan_path then
    os.exit(EXIT_USAGE)
end

if fail_mode ~= "fast" and fail_mode ~= "slow" then
    io.stderr:write("Error: --fail must be 'fast' or 'slow'\n")
    os.exit(EXIT_USAGE)
end

local _, killed, survived = mutator.apply_mutations_from_plan(plan_path, test_command, report_path)

if survived > 0 then
    os.exit(EXIT_FAILURE)
end
