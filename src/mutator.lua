local mutator = {}
local file_io = require("file_io")

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

local function replace_in_line(mutation, line)
    local start_col = mutation.start_col
    local end_col = mutation.end_col

    if line:sub(start_col + 1, end_col) ~= mutation.original then
        error("original text does not match at specified location")
    end
    return line:sub(1, start_col) .. mutation.replacement .. line:sub(end_col + 1)
end

local function replace_at_location(mutation, source)
    local lines = {}
    for line in source:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    local line_index = mutation.start_row + 1
    local line = lines[line_index]
    if line then
        lines[line_index] = replace_in_line(mutation, line)
    end
    return table.concat(lines, "\n")
end

local SURVIVED_MESSAGE = "👾 survived"
local KILLED_MESSAGE = "🏹 killed"

function mutator.has_mutations(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if mutation.start_row ~= nil then
        return replace_at_location(mutation, source)
    end
    local escaped_original = escape_pattern(mutation.original)
    return source:gsub(escaped_original, mutation.replacement)
end

function mutator.apply_plan(plan, source)
    local result = source
    for _, mutation in ipairs(plan.mutations) do
        result = mutator.apply_mutation(mutation, result)
    end
    return result
end

function mutator.apply_mutation_to_file(mutation, input_path, output_path)
    local source = file_io.read(input_path)
    local result = mutator.apply_mutation(mutation, source)
    file_io.write(output_path, result)
end

function mutator.run_test(command)
    local exit_code = os.execute(command)
    if exit_code == 0 then
        print(SURVIVED_MESSAGE)
    else
        print(KILLED_MESSAGE)
    end
    return exit_code ~= 0
end

return mutator
