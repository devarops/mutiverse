local file_io = require("file_io")
local mutator = require("mutator")

local function remove_if_exists(path)
    if path then os.remove(path) end
end

describe("is_valid", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(mutator.is_valid({mutations={}}))
    end)

    it("should reject a plan missing the mutations field", function()
        assert.is_falsy(mutator.is_valid({}))
    end)
end)

describe("apply_mutation", function()
    it("should replace original text with replacement text", function()
        local result = mutator.apply_mutation({original="1", replacement="0"}, "return 1")
        assert.equals("return 0", result)
    end)

    it("should replace only at the specified row/col when location fields are provided", function()
        local result = mutator.apply_mutation({start_row=0, end_row=0, start_col=4, end_col=5, original="1", replacement="0"}, "x = 1\ny = 1")
        assert.equals("x = 0\ny = 1", result)
    end)

    it("should report an error when original text does not match at the specified location", function()
        local ok, err = pcall(mutator.apply_mutation, {start_row=0, start_col=0, end_row=0, end_col=1, original="z", replacement="x"}, "abc")
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
        remove_if_exists(input_path)
        remove_if_exists(output_path)
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
