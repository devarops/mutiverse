local solution = require("solution")

describe("Validate mutation plan", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(solution.validate({mutations={}}))
    end)

    it("should reject a plan missing the mutations field", function()
        assert.is_falsy(solution.validate({}))
    end)
end)
