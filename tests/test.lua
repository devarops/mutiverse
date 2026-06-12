local solution = require("solution")

describe("Validate mutation plan", function()
    it("should accept a valid mutation plan with an empty mutation list", function()
        assert.is_true(solution.validate({mutations={}}))
    end)
end)
