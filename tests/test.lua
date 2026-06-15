local file_io = require("file_io")
local mutator = require("mutator")

local function assert_contains(content, expected)
    assert.truthy(content:find(expected, 1, true))
end

local function run_lua(lua_code)
    local handle = io.popen([[lua -e "package.path = 'src/?.lua;' .. package.path; ]] .. lua_code .. [["]])
    local content = handle:read("*a")
    handle:close()
    return content
end

local function run_mutator_test(command)
    return run_lua(string.format([[local mutator = require('mutator'); mutator.run_test('%s')]], command))
end

describe("apply_mutation", function()
    it("should replace original text with replacement text", function()
        local mutated_content = mutator.apply_mutation({original="1", replacement="0"}, "return 1")
        assert.equals("return 0", mutated_content)
    end)

    it("should replace only at the specified row/col when location fields are provided", function()
        local mutated_content = mutator.apply_mutation({start_row=0, start_col=4, end_col=5, original="1", replacement="0"}, "x = 1\ny = 1")
        assert.equals("x = 0\ny = 1", mutated_content)
    end)

    it("should report an error when original text does not match at the specified location", function()
        local ok = pcall(mutator.apply_mutation, {start_row=0, start_col=0, end_col=1, original="z", replacement="x"}, "abc")
        assert.is_falsy(ok)
    end)

    it("should report an error when start_row is beyond the file", function()
        local ok = pcall(mutator.apply_mutation, {start_row=10, start_col=0, end_col=1, original="a", replacement="z"}, "abc")
        assert.is_falsy(ok)
    end)
end)

describe("apply_plan", function()
    it("should apply all mutations from a plan to source text", function()
        local plan = {mutations={{original="1", replacement="0"}, {original="2", replacement="3"}}}
        local results = mutator.apply_plan(plan, "1+2")
        assert.equals(2, #results)
        assert.equals("0+2", results[1])
        assert.equals("1+3", results[2])
    end)

    it("should apply each mutation individually to the original source", function()
        local plan = {mutations={{original="1", replacement="0"}, {original="1", replacement="2"}}}
        local results = mutator.apply_plan(plan, "1")
        assert.equals(2, #results)
    end)

    it("should run the test command for each mutation and print the outcome", function()
        local content = run_lua([[local m = require('mutator'); m.apply_plan({mutations={{original='1', replacement='2'}}}, 'return 1', 'true')]])
        assert_contains(content, mutator.SURVIVED_MESSAGE)
    end)

    it("should restore source file after mutations when source_path is provided with test_command", function()
        local tmpfile = os.tmpname()
        file_io.write(tmpfile, "return 1")
        local plan = {mutations={{original="1", replacement="0"}}}
        mutator.apply_plan(plan, "return 1", "true", tmpfile)
        local content = file_io.read(tmpfile)
        assert.equals("return 1", content)
        os.remove(tmpfile)
    end)

    it("should write a JSON report to report_path with killed/survived results", function()
        local plan = {mutations={{original="1", replacement="0"}}}
        local report_path = os.tmpname()
        os.remove(report_path)
        mutator.apply_plan(plan, "return 1", nil, nil, report_path)
        local ok = pcall(file_io.read, report_path)
        assert.is_true(ok)
        os.remove(report_path)
    end)

    it("should restore source file to original state after completing all mutations", function()
        local tmpfile = os.tmpname()
        file_io.write(tmpfile, "return 1")
        local plan = {mutations={{original="1", replacement="0"}, {original="1", replacement="2"}}}
        mutator.apply_plan(plan, "return 1", nil, tmpfile)
        local content = file_io.read(tmpfile)
        assert.equals("return 1", content)
        os.remove(tmpfile)
    end)

    it("should restore source file after all mutations when test_command is provided", function()
        local tmpfile = os.tmpname()
        file_io.write(tmpfile, "return 1")
        local plan = {mutations={{original="1", replacement="0"}, {original="1", replacement="2"}}}
        mutator.apply_plan(plan, "return 1", "true", tmpfile)
        local content = file_io.read(tmpfile)
        assert.equals("return 1", content)
        os.remove(tmpfile)
    end)

    it("should revert source file between each mutation using git checkout", function()
        local tmpdir = os.tmpname()
        os.remove(tmpdir)
        os.execute("mkdir -p " .. tmpdir)
        local source_path = tmpdir .. "/source.lua"
        file_io.write(source_path, "return 1")
        os.execute(string.format(
            "cd %s && git init -q && git config user.email x@x.com && git config user.name x && git add source.lua && git commit -q -m init",
            tmpdir))
        local plan = {mutations={{original="1", replacement="0"}, {original="1", replacement="2"}}}
        mutator.apply_plan(plan, "return 1", nil, source_path)
        local handle = io.popen(string.format("cd %s && git reflog --oneline", tmpdir))
        local reflog = handle:read("*a")
        handle:close()
        local _, count = reflog:gsub("checkout", "")
        assert.is_true(count >= 1)
        os.execute("rm -rf " .. tmpdir)
    end)
end)

describe("apply_mutation_to_file", function()
    local input_path
    local output_path

    teardown(function()
        if input_path then os.remove(input_path) end
        if output_path then os.remove(output_path) end
    end)

    it("should read source file, apply mutation, and write mutated content to output file", function()
        input_path = os.tmpname()
        output_path = os.tmpname()
        file_io.write(input_path, "return 1")

        mutator.apply_mutation_to_file({original="1", replacement="0"}, input_path, output_path)

        local mutated_content = file_io.read(output_path)
        assert.equals("return 0", mutated_content)
    end)
end)

describe("is_mutation_killed", function()
    it("should return false when test command exits with 0", function()
        assert.is_false(mutator.is_mutation_killed("echo hello"))
    end)
end)

describe("run_test", function()
    it("should print 👾 survived when test command exits with 0", function()
        local content = run_mutator_test("true")
        assert_contains(content, mutator.SURVIVED_MESSAGE)
    end)

    it("should print 🏹 killed when test command exits non-zero", function()
        local content = run_mutator_test("false")
        assert_contains(content, mutator.KILLED_MESSAGE)
    end)

    it("should return false when test command exits with 0", function()
        assert.is_false(mutator.run_test("true"))
    end)

    it("should return true when test command exits non-zero", function()
        assert.is_true(mutator.run_test("false"))
    end)
end)

describe("validate_plan", function()
    it("should return true for a valid mutation plan", function()
        local plan = {mutations={}}
        assert.is_true(mutator.validate_plan(plan))
    end)

    it("should return false for a plan missing required mutations field", function()
        local plan = {}
        assert.is_false(mutator.validate_plan(plan))
    end)
end)

describe("validate_plan_file", function()
    it("should validate a mutation plan JSON file against the schema", function()
        assert.is_true(mutator.validate_plan_file("tests/data/mutation-plan.json"))
    end)
end)

describe("apply_mutations_from_plan", function()
    it("should apply CONSTANT_NUMERIC_FLIP mutation from plan to Python source file", function()
        local results = mutator.apply_mutations_from_plan("tests/data/mutation-plan.json")
        assert_contains(results[1], "    return 0")
    end)
end)
