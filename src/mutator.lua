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
        return true
    else
        print(mutator.SURVIVED_MESSAGE)
        return false
    end
end

function mutator.validate_plan_file(file_path)
    local command = "jsonschema -i " .. file_path .. " " .. MUTATION_SCHEMA_PATH
    return os.execute(command) == 0
end

local function mutation_extraction_script()
    return [[import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for m in data["mutations"]:
    print(m["file_path"])
    print(m["start_row"])
    print(m["start_col"])
    print(m["end_col"])
    print(m["original"])
    print(m["replacement"])
    print(m["operator"])
    print("]] .. RECORD_SEPARATOR .. [[")
]]
end

local function parse_json_mutations(plan_path)
    local tmp = os.tmpname() .. ".py"
    local script = mutation_extraction_script()
    local f = assert(io.open(tmp, "w"))
    f:write(script)
    f:close()
    local handle = io.popen("python3 " .. tmp .. " " .. plan_path)
    local results = {}
    local field_specs = {
        {name = "file_path"},
        {name = "start_row", convert = tonumber},
        {name = "start_col", convert = tonumber},
        {name = "end_col", convert = tonumber},
        {name = "original"},
        {name = "replacement"},
        {name = "operator"},
    }
    local mutation = {}
    local field_count = 0
    for line in handle:lines() do
        if line == RECORD_SEPARATOR then
            table.insert(results, mutation)
            mutation = {}
            field_count = 0
        else
            field_count = field_count + 1
            local spec = field_specs[field_count]
            local value = line
            if spec.convert then
                value = spec.convert(value)
            end
            mutation[spec.name] = value
        end
    end
    handle:close()
    os.execute("rm " .. tmp)
    return results
end

function mutator.apply_mutations_from_plan(plan_path)
    local mutations = parse_json_mutations(plan_path)
    local results = {}
    for _, m in ipairs(mutations) do
        local source = file_io.read(m.file_path)
        local result = mutator.apply_mutation(m, source)
        table.insert(results, result)
    end
    return results
end

return mutator
