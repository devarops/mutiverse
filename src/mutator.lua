local mutator = {}
local file_io = require("file_io")

local function escape_pattern(text)
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

local function split_lines(text)
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    return lines
end

local function replace_in_line(mutation, target_line)
    local column_start, column_end = mutation.start_col + 1, mutation.end_col
    local existing_text = target_line:sub(column_start, column_end)
    assert(existing_text == mutation.original, "original text does not match at specified location")
    local prefix = target_line:sub(1, column_start - 1)
    local suffix = target_line:sub(column_end + 1)
    return prefix .. mutation.replacement .. suffix
end

local function replace_at_location(mutation, source)
    local lines = split_lines(source)
    local target_line_number = mutation.start_row + 1
    local target_line = lines[target_line_number]
    if target_line then
        lines[target_line_number] = replace_in_line(mutation, target_line)
    end
    return table.concat(lines, "\n")
end

local function replace_globally(mutation, source)
    return source:gsub(escape_pattern(mutation.original), mutation.replacement)
end

mutator.SURVIVED_MESSAGE = "👾 survived"
mutator.KILLED_MESSAGE = "🏹 killed"

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

function mutator.is_mutation_killed(command)
    local exit_code = os.execute(command)
    return exit_code ~= 0
end

function mutator.run_test(command)
    if mutator.is_mutation_killed(command) then
        print(mutator.KILLED_MESSAGE)
    else
        print(mutator.SURVIVED_MESSAGE)
    end
end

return mutator
