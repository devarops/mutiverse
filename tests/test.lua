local mutator = require("mutator")

local function write_file(path, content)
    local f = io.open(path, "w")
    f:write(content)
    f:close()
end

local function read_file(path)
    local f = io.open(path, "r")
    local content = f:read("*a")
    f:close()
    return content
end

describe("Validate mutation plan", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(mutator.validate({mutations={}}))
    end)

    it("should reject a plan missing the mutations field", function()
        assert.is_falsy(mutator.validate({}))
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
        local source_path = "/tmp/test_mutation_source.lua"
        local output_path = "/tmp/test_mutation_output.lua"
        write_file(source_path, "return 1")

        mutator.apply_mutation_to_file({original="1", replacement="0"}, source_path, output_path)

        local result = read_file(output_path)
        assert.equals("return 0", result)

        os.remove(source_path)
        os.remove(output_path)
    end)
end)
