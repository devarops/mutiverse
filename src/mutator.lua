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
    local original_at_location = line:sub(mutation.start_col + 1, mutation.end_col)
    if original_at_location ~= mutation.original then
        error("original text does not match at specified location")
    end
    local before = line:sub(1, mutation.start_col)
    local after = line:sub(mutation.end_col + 1)
    return before .. mutation.replacement .. after
end

local function replace_at_location(mutation, source)
    local lines = split_lines(source)
    local line_index = mutation.start_row + 1
    local line = lines[line_index]
    if line then
        lines[line_index] = replace_in_line(mutation, line)
    end
    return table.concat(lines, "\n")
end

local function replace_globally(mutation, source)
    local escaped_original = escape_pattern(mutation.original)
    return source:gsub(escaped_original, mutation.replacement)
end

function mutator.has_mutations(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if mutation.start_row ~= nil then
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
    local success = exit_code == 0
    if success then
        print("👾 survived")
    else
        print("🏹 killed")
    end
    return not success
end

return mutator
