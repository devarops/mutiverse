local file_io = require("file_io")
local mutator = require("mutator")

local function assert_contains(output, expected)
    assert.truthy(output:find(expected, 1, true))
end

local function format_test_command(command)
    return string.format(
        [[lua -e "package.path = 'src/?.lua;' .. package.path; local m = require('mutator'); m.run_test('%s')"]],
        command
    )
end

local function run_mutator_test(command)
    local process = io.popen(format_test_command(command))
    local output = process:read("*a")
    process:close()
    return output
end

describe("has_mutations_field", function()
    it("should accept a plan with mutations even when the list is empty", function()
        assert.is_true(mutator.has_mutations_field({mutations={}}))
    end)

    it("should reject a plan missing mutations", function()
        assert.is_falsy(mutator.has_mutations_field({}))
    end)
end)

describe("apply_mutation", function()
    it("should replace original text with replacement text", function()
        local result = mutator.apply_mutation({original="1", replacement="0"}, "return 1")
        assert.equals("return 0", result)
    end)

    it("should replace only at the specified row/col when location fields are provided", function()
        local result = mutator.apply_mutation({start_row=0, start_col=4, end_col=5, original="1", replacement="0"}, "x = 1\ny = 1")
        assert.equals("x = 0\ny = 1", result)
    end)

    it("should report an error when original text does not match at the specified location", function()
        local ok, err = pcall(mutator.apply_mutation, {start_row=0, start_col=0, end_col=1, original="z", replacement="x"}, "abc")
        assert.is_falsy(ok)
    end)
end)

describe("apply_plan", function()
    it("should apply all mutations from a plan to source text", function()
        local plan = {mutations={{original="1", replacement="0"}, {original="2", replacement="3"}}}
        local result = mutator.apply_plan(plan, "1+2")
        assert.equals("0+3", result)
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

        local result = file_io.read(output_path)
        assert.equals("return 0", result)
    end)
end)

describe("run_test", function()
    it("should return false when test command exits with 0", function()
        assert.is_false(mutator.is_mutation_killed("echo hello"))
    end)

    it("should print 👾 survived when test command exits with 0", function()
        local output = run_mutator_test("true")
        assert_contains(output, mutator.SURVIVED_MESSAGE)
    end)

    it("should print 🏹 killed when test command exits non-zero", function()
        local output = run_mutator_test("false")
        assert_contains(output, mutator.KILLED_MESSAGE)
    end)
end)
