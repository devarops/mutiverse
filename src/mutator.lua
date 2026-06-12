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

local function join_lines(lines)
    return table.concat(lines, "\n")
end

local function column_range(mutation)
    return mutation.start_col + 1, mutation.end_col
end

local function assert_original_matches_at_location(mutation, target_line)
    local col_start, col_end = column_range(mutation)
    local existing_text = target_line:sub(col_start, col_end)
    if existing_text ~= mutation.original then
        error("original text does not match at specified location")
    end
end

local function replace_in_line(mutation, target_line)
    local col_start, col_end = column_range(mutation)
    local prefix = target_line:sub(1, col_start - 1)
    local suffix = target_line:sub(col_end + 1)
    return prefix .. mutation.replacement .. suffix
end

local function replace_at_location(mutation, source)
    local lines = split_lines(source)
    local target_line_index = mutation.start_row + 1
    local target_line = lines[target_line_index]
    if target_line then
        assert_original_matches_at_location(mutation, target_line)
        lines[target_line_index] = replace_in_line(mutation, target_line)
    end
    return join_lines(lines)
end

local function replace_globally(mutation, source)
    return source:gsub(escape_pattern(mutation.original), mutation.replacement)
end

local SURVIVED_MESSAGE = "👾 survived"
local KILLED_MESSAGE = "🏹 killed"
mutator.SURVIVED_MESSAGE = SURVIVED_MESSAGE
mutator.KILLED_MESSAGE = KILLED_MESSAGE

function mutator.has_mutations_field(plan)
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
    local is_killed = exit_code ~= 0
    if is_killed then
        print(KILLED_MESSAGE)
    else
        print(SURVIVED_MESSAGE)
    end
    return is_killed
end

return mutator
