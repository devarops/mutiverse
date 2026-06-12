local mutator = require("mutator")

describe("Validate mutation plan", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(mutator.is_valid({mutations={}}))
    end)

    it("should reject a plan missing the mutations field", function()
        assert.is_falsy(mutator.is_valid({}))
    end)
end)

describe("Apply mutation", function()
    it("should replace original text with replacement text", function()
        local result = mutator.apply_mutation({original="1", replacement="0"}, "return 1")
        assert.equals("return 0", result)
    end)

    it("should apply all mutations from a plan to source text", function()
        local plan = {mutations={{original="1", replacement="0"}, {original="2", replacement="3"}}}
        local result = mutator.apply_plan(plan, "1+2")
        assert.equals("0+3", result)
    end)
end)

describe("Apply mutation to file", function()
    it("should read source file, apply mutation, and write mutated content to output file", function()
        local input_path = "/tmp/test_mutation_source.lua"
        local output_path = "/tmp/test_mutation_output.lua"
        mutator.write_file(input_path, "return 1")

        mutator.apply_mutation_to_file({original="1", replacement="0"}, input_path, output_path)

        local result = mutator.read_file(output_path)
        assert.equals("return 0", result)

        os.remove(input_path)
        os.remove(output_path)
    end)
end)
