local mutator = {}
local file_io = require("file_io")

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

local function split_lines(text)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    return lines
end

local function replace_in_line(mutation, line)
    local start_col = mutation.start_col
    local end_col = mutation.end_col
    local original = mutation.original
    local replacement = mutation.replacement

    local original_at_location = line:sub(start_col + 1, end_col)
    if original_at_location ~= original then
        error("original text does not match at specified location")
    end
    local before = line:sub(1, start_col)
    local after = line:sub(end_col + 1)
    return before .. replacement .. after
end

local function replace_at_location(mutation, source)
    local lines = split_lines(source)
    local start_row = mutation.start_row
    local line_index = start_row + 1
    local line = lines[line_index]
    if line then
        lines[line_index] = replace_in_line(mutation, line)
    end
    return table.concat(lines, "\n")
end

local function replace_globally(mutation, source)
    local original = mutation.original
    local replacement = mutation.replacement
    local escaped_original = escape_pattern(original)
    return source:gsub(escaped_original, replacement)
end

local function has_location(mutation)
    return mutation.start_row ~= nil
end

local SURVIVED_MESSAGE = "👾 survived"
local KILLED_MESSAGE = "🏹 killed"

local function report_mutation_outcome(exit_code)
    if exit_code == 0 then
        print(SURVIVED_MESSAGE)
    else
        print(KILLED_MESSAGE)
    end
end

function mutator.has_mutations(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if has_location(mutation) then
        return replace_at_location(mutation, source)
    end
    return replace_globally(mutation, source)
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
    report_mutation_outcome(exit_code)
    return exit_code ~= 0
end

return mutator
