-- Vector3 implementation in Lua
local Vector3 = {}
Vector3.__index = Vector3

-- Constructor
function Vector3.new(x, y, z)
    return setmetatable({
        x = x or 0,
        y = y or 0,
        z = z or 0
    }, Vector3)
end

-- Index access (vec[i])
function Vector3:__index(i)
    if type(i) == "number" then
        if i == 1 then return rawget(self, "x")
        elseif i == 2 then return rawget(self, "y")
        elseif i == 3 then return rawget(self, "z")
        else error("Index out of range: " .. tostring(i)) end
    end
    return rawget(Vector3, i)
end

-- Vector + Vector
function Vector3.__add(a, b)
    return Vector3.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

-- Vector - Vector
function Vector3.__sub(a, b)
    return Vector3.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- Vector * scalar or Vector * Vector
function Vector3.__mul(a, b)
    if type(a) == "number" then
        return Vector3.new(a * b.x, a * b.y, a * b.z)
    elseif type(b) == "number" then
        return Vector3.new(a.x * b, a.y * b, a.z * b)
    else
        return Vector3.new(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

-- Vector / scalar or Vector / Vector
function Vector3.__div(a, b)
    if type(b) == "number" then
        return Vector3.new(a.x / b, a.y / b, a.z / b)
    else
        return Vector3.new(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

-- Equality
function Vector3.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

-- Inequality
function Vector3.__ne(a, b)
    return a.x ~= b.x or a.y ~= b.y or a.z ~= b.z
end

-- Dot product
function Vector3:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

-- Cross product
function Vector3:cross(v)
    return Vector3.new(
        self.y * v.z - self.z * v.y,
        self.z * v.x - self.x * v.z,
        self.x * v.y - self.y * v.x
    )
end

-- Magnitude
function Vector3:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

-- Squared magnitude
function Vector3:squared()
    return self.x * self.x + self.y * self.y + self.z * self.z
end

-- Normalize
function Vector3:normalize()
    local mag = self:magnitude()
    if mag == 0 then
        return Vector3.new(0, 0, 0)
    end
    return Vector3.new(self.x / mag, self.y / mag, self.z / mag)
end

-- Direction (same as normalize)
function Vector3:direction()
    return self:normalize()
end

-- Distance
function Vector3:distance(v)
    return math.sqrt((v.x - self.x)^2 + (v.y - self.y)^2 + (v.z - self.z)^2)
end

-- Static constants
Vector3.One   = Vector3.new(1, 1, 1)
Vector3.UnitX = Vector3.new(1, 0, 0)
Vector3.UnitY = Vector3.new(0, 1, 0)
Vector3.UnitZ = Vector3.new(0, 0, 1)

return Vector3
