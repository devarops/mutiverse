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

local function replace_at_range(text, start_pos, end_pos, replacement)
    local prefix = text:sub(1, start_pos - 1)
    local suffix = text:sub(end_pos + 1)
    return prefix .. replacement .. suffix
end

local function replace_in_line(mutation, target_line)
    local start_pos, end_pos = mutation.start_col + 1, mutation.end_col
    local text_at_range = target_line:sub(start_pos, end_pos)
    assert(text_at_range == mutation.original, "original text does not match at specified location")
    return replace_at_range(target_line, start_pos, end_pos, mutation.replacement)
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

local function has_location(mutation)
    return mutation.start_row ~= nil
end

function mutator.has_mutations_field(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if has_location(mutation) then
        return replace_at_location(mutation, source)
    end
    return replace_globally(mutation, source)
end

function mutator.apply_plan(plan, source)
    local mutated_content = source
    for _, mutation in ipairs(plan.mutations) do
        mutated_content = mutator.apply_mutation(mutation, mutated_content)
    end
    return mutated_content
end

function mutator.apply_mutation_to_file(mutation, input_path, output_path)
    local source = file_io.read(input_path)
    local mutated_content = mutator.apply_mutation(mutation, source)
    file_io.write(output_path, mutated_content)
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
