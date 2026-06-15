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
    assert(
        target_line:sub(mutation.start_col + 1, mutation.end_col) == mutation.original,
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
    assert(target_line, "start_row is beyond the file")
    lines[line_index] = replace_in_line(mutation, target_line)
    return table.concat(lines, "\n")
end

local function replace_globally(mutation, source)
    return source:gsub(escape_pattern(mutation.original), mutation.replacement)
end

mutator.SURVIVED_MESSAGE = "👾 survived"
mutator.KILLED_MESSAGE = "🏹 killed"
local RECORD_SEPARATOR = "---END---"
local MUTATION_SCHEMA_PATH = "/workdir/schemas/mutation-plan.schema.json"

local FIELD_SPECS = {
    {name = "file_path"},
    {name = "start_row", convert = tonumber},
    {name = "start_col", convert = tonumber},
    {name = "end_col", convert = tonumber},
    {name = "original"},
    {name = "replacement"},
    {name = "operator"},
}

function mutator.validate_plan(plan)
    return plan.mutations ~= nil
end

function mutator.apply_mutation(mutation, source)
    if mutation.start_row ~= nil then
        return replace_at_location(mutation, source)
    end
    return replace_globally(mutation, source)
end

function mutator.apply_plan(plan, source, test_command)
    local results = {}
    for _, mutation in ipairs(plan.mutations) do
        local result = (mutator.apply_mutation(mutation, source))
        table.insert(results, result)
        if test_command then
            mutator.run_test(test_command)
        end
    end
    return results
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
    local killed = mutator.is_mutation_killed(command)
    print(killed and mutator.KILLED_MESSAGE or mutator.SURVIVED_MESSAGE)
    return killed
end

function mutator.validate_plan_file(file_path)
    local command = "jsonschema -i " .. file_path .. " " .. MUTATION_SCHEMA_PATH
    return os.execute(command) == 0
end

local function mutation_extraction_script()
    return [[import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for mutation in data["mutations"]:
    print(mutation["file_path"])
    print(mutation["start_row"])
    print(mutation["start_col"])
    print(mutation["end_col"])
    print(mutation["original"])
    print(mutation["replacement"])
    print(mutation["operator"])
    print("]] .. RECORD_SEPARATOR .. [[")
]]
end

local function parse_mutation_records(line_iterator)
    local results = {}
    local mutation
    local field_index = 0
    for line in line_iterator do
        if line == RECORD_SEPARATOR then
            table.insert(results, mutation)
            mutation = nil
            field_index = 0
        else
            if not mutation then
                mutation = {}
            end
            field_index = field_index + 1
            local spec = FIELD_SPECS[field_index]
            mutation[spec.name] = spec.convert and spec.convert(line) or line
        end
    end
    return results
end

local function parse_json_mutations(plan_path)
    local tmp = os.tmpname() .. ".py"
    local script = mutation_extraction_script()
    file_io.write(tmp, script)
    local handle = io.popen("python3 " .. tmp .. " " .. plan_path)
    local results = parse_mutation_records(handle:lines())
    handle:close()
    os.remove(tmp)
    return results
end

function mutator.apply_mutations_from_plan(plan_path)
    local mutations = parse_json_mutations(plan_path)
    local results = {}
    for _, mutation in ipairs(mutations) do
        local source = file_io.read(mutation.file_path)
        local result = mutator.apply_mutation(mutation, source)
        table.insert(results, result)
    end
    return results
end

return mutator
