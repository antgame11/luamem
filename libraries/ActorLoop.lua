local ActorLoop = {}
ActorLoop.__index = ActorLoop

function ActorLoop.new(memory, offsets)
    assert(memory, "Memory wrapper required")
    assert(offsets, "Offsets table required")

    local self = setmetatable({}, ActorLoop)
    self.memory = memory
    self.offsets = offsets
    self.cache = {}
    self.last_update = {}
    return self
end


function ActorLoop:ReadString(addr)
    if not addr or addr == 0 then
        return "???"
    end
    return self.memory.read_mem(addr, "string", 256) or "???"
end


function ActorLoop:LengthReadString(string_addr)
    if not string_addr or string_addr == 0 then
        return "???"
    end

    local length = self.memory.read_mem(string_addr + self.offsets.StringLength, "dword") or 0

    if length >= 16 then
        local new_addr = self.memory.read_mem(string_addr, "qword")
        return self:ReadString(new_addr)
    else
        return self:ReadString(string_addr)
    end
end


function ActorLoop:GetInstanceName(instance_address)
    local name_ptr = self.memory.read_mem(instance_address + self.offsets.Name, "qword")
    if name_ptr and name_ptr ~= 0 then
        return self:LengthReadString(name_ptr)
    end
    return "???"
end

function ActorLoop:GetDataModel()
    local fakeDM = self.memory.read_mem(base + self.offsets.FakeDataModelPointer, "qword")
    local DataModel = self.memory.read_mem(fakeDM + self.offsets.FakeDataModelToDataModel, "qword")
    return DataModel
end


function ActorLoop:FindFirstChild(instance_address, child_name)
    if not instance_address or instance_address == 0 then
        return 0
    end

    local now = os.clock()
    self.cache[instance_address] = self.cache[instance_address] or {}
    self.last_update[instance_address] = self.last_update[instance_address] or 0

    local children = self.cache[instance_address]
    local update_time = self.last_update[instance_address]

    if #children == 0 or (now - update_time > 1.0) then
        children = {}
        self.cache[instance_address] = children

        local start = self.memory.read_mem(instance_address + self.offsets.Children, "qword")
        if not start or start == 0 then
            return 0
        end

        local end_addr = self.memory.read_mem(start + self.offsets.ChildrenEnd, "qword")
        local childArray = self.memory.read_mem(start, "qword")
        if not childArray or childArray == 0 or childArray >= end_addr then
            return 0
        end

        for current = childArray, end_addr - 1, 16 do
            local child_instance = self.memory.read_mem(current, "qword")
            if child_instance and child_instance ~= 0 then
                local name = self:GetInstanceName(child_instance)
                table.insert(children, { child_instance, name })
            end
        end

        self.last_update[instance_address] = now
    end

    for _, pair in ipairs(children) do
        local child_instance, name = pair[1], pair[2]
        if name == child_name then
            return child_instance
        end
    end

    return 0
end

print("made it!")

return ActorLoop
