local solution = require("solution")

describe("Validate mutation plan", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(solution.validate({mutations={}}))
    end)

    it("should reject a plan missing the mutations field", function()
        assert.is_falsy(solution.validate({}))
    end)
end)

describe("Apply mutation", function()
    it("should replace original text with replacement text", function()
        local result = solution.apply_mutation({original="1", replacement="0"}, "return 1")
        assert.equals("return 0", result)
    end)
end)
