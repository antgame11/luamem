local Vector3 = require("Vector3")

local CFrame = {}
CFrame.__index = CFrame

-- Constructor
function CFrame.new(right, up, back, pos)
    return setmetatable({
        right_vector = right or Vector3.UnitX,
        up_vector    = up or Vector3.UnitY,
        back_vector  = back or Vector3.UnitZ,
        position     = pos or Vector3.new(0, 0, 0)
    }, CFrame)
end

-- From position only
function CFrame.fromPosition(pos)
    return CFrame.new(Vector3.UnitX, Vector3.UnitY, Vector3.UnitZ, pos)
end

-- Look-at (mutates)
function CFrame:look_at_locked(point)
    local look_vector = (self.position - point):normalize()

    self.right_vector = Vector3.UnitY:cross(look_vector):normalize()
    self.up_vector    = look_vector:cross(self.right_vector):normalize()
    self.back_vector  = look_vector * Vector3.new(-1, -1, -1)
end

-- Look-at (returns new CFrame)
function CFrame:look_at(point)
    local look_vector = (self.position - point):normalize()

    local right_vector = Vector3.UnitY:cross(look_vector):normalize()
    local up_vector    = look_vector:cross(right_vector):normalize()

    return CFrame.new(right_vector, up_vector, look_vector, self.position)
end

-- Multiply CFrame * CFrame
function CFrame.__mul(a, b)
    if getmetatable(b) == CFrame then
        local result = CFrame.new()

        result.right_vector = a.right_vector * b.right_vector
        result.up_vector    = a.up_vector * b.up_vector
        result.back_vector  = a.back_vector * b.back_vector
        result.position     = a.right_vector * b.position + a.position

        return result
    elseif getmetatable(b) == Vector3 then
        return Vector3.new(
            a.right_vector.x * b.x + a.right_vector.y * b.y + a.right_vector.z * b.z + a.position.x,
            a.up_vector.x    * b.x + a.up_vector.y    * b.y + a.up_vector.z    * b.z + a.position.y,
            a.back_vector.x  * b.x + a.back_vector.y  * b.y + a.back_vector.z  * b.z + a.position.z
        )
    else
        error("CFrame can only be multiplied with CFrame or Vector3")
    end
end

return CFrame
