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

local function assert_text_matches(mutation, target_line)
    local actual_text = target_line:sub(mutation.start_col + 1, mutation.end_col)
    assert(
        actual_text == mutation.original,
        "original text does not match at specified location"
    )
end

local function replace_in_line(mutation, target_line)
    assert_text_matches(mutation, target_line)
    local prefix = target_line:sub(1, mutation.start_col)
    local suffix = target_line:sub(mutation.end_col + 1)
    return prefix .. mutation.replacement .. suffix
end

local function replace_at_location(mutation, source)
    local lines = split_lines(source)
    local line_index = mutation.start_row + 1
    local target_line = lines[line_index]
    if target_line then
        lines[line_index] = replace_in_line(mutation, target_line)
    end
    return table.concat(lines, "\n")
end

local function replace_globally(mutation, source)
    return source:gsub(escape_pattern(mutation.original), mutation.replacement)
end

mutator.SURVIVED_MESSAGE = "👾 survived"
mutator.KILLED_MESSAGE = "🏹 killed"

function mutator.validate_plan(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if mutation.start_row ~= nil then
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
    return os.execute(command) ~= 0
end

function mutator.run_test(command)
    if mutator.is_mutation_killed(command) then
        print(mutator.KILLED_MESSAGE)
    else
        print(mutator.SURVIVED_MESSAGE)
    end
end

function mutator.validate_plan_file(file_path)
    local command = "jsonschema -i " .. file_path .. " /workdir/schemas/mutation-plan.schema.json"
    return os.execute(command) == 0
end

return mutator
