local ActorLoop = {}
ActorLoop.__index = ActorLoop

function ActorLoop.new(memory, offsets, base)
    assert(memory, "Memory wrapper required")
    assert(offsets, "Offsets table required")
    assert(base, "Base value required")

    local self = setmetatable({}, ActorLoop)
    self.memory = memory
    self.offsets = offsets
    self.base = base
    self._cached_children_addresses = {}
    self._last_structure_update = 0
    return self
end

local function is_valid_utf8(s)
    local i = 1
    local len = #s
    while i <= len do
        local c = s:byte(i)
        if c <= 0x7F then
            i = i + 1
        elseif c >= 0xC2 and c <= 0xDF then
            if i + 1 > len then return false end
            local b2 = s:byte(i + 1)
            if b2 < 0x80 or b2 > 0xBF then return false end
            i = i + 2
        elseif c >= 0xE0 and c <= 0xEF then
            if i + 2 > len then return false end
            local b2, b3 = s:byte(i+1, i+2)
            if b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF then return false end
            i = i + 3
        elseif c >= 0xF0 and c <= 0xF4 then
            if i + 3 > len then return false end
            local b2, b3, b4 = s:byte(i+1, i+3)
            if b2 < 0x80 or b2 > 0xBF or b3 < 0x80 or b3 > 0xBF or b4 < 0x80 or b4 > 0xBF then
                return false
            end
            i = i + 4
        else
            return false
        end
    end
    return true
end

function ActorLoop:SetProperty(instance_addr, mtype, value, size)
    if not instance_addr or instance_addr == 0 then
        return false, "Invalid instance address"
    end
    
    if not mtype then
        return false, "Memory type required"
    end
    
    if value == nil then
        return false, "Value cannot be nil"
    end
    
    local target_addr = instance_addr
    
    if mtype == "string" then
        if type(value) ~= "string" then
            return false, "Value must be a string for string type"
        end
        
        local str_size = size or (#value + 1)
        local success = self.memory.write_mem(target_addr, "string", value, str_size)
        return success, success and "Success" or "Failed to write string"
        
    elseif mtype == "string_ptr" then
        if type(value) ~= "string" then
            return false, "Value must be a string for string_ptr type"
        end
        
        local str_addr = self.memory.allocate_memory(#value + 1)
        if not str_addr then
            return false, "Failed to allocate memory for string"
        end
        
        if not self.memory.write_string(str_addr, value) then
            self.memory.free_memory(str_addr, #value + 1)
            return false, "Failed to write string to allocated memory"
        end
        
        if not self:safe_write_qword(target_addr, str_addr) then
            self.memory.free_memory(str_addr, #value + 1)
            return false, "Failed to write string pointer"
        end
        
        return true, "Success", str_addr
        
    elseif mtype == "qword" then
        if type(value) ~= "number" then
            return false, "Value must be a number for qword type"
        end
        local success = self:safe_write_qword(target_addr, value)
        return success, success and "Success" or "Failed to write qword"
        
    elseif mtype == "dword" then
        if type(value) ~= "number" then
            return false, "Value must be a number for dword type"
        end
        local success = self:safe_write_dword(target_addr, value)
        return success, success and "Success" or "Failed to write dword"
        
    elseif mtype == "float" then
        if type(value) ~= "number" then
            return false, "Value must be a number for float type"
        end
        local success = self:safe_write_float(target_addr, value)
        return success, success and "Success" or "Failed to write float"
        
    elseif mtype == "double" then
        if type(value) ~= "number" then
            return false, "Value must be a number for double type"
        end
        local success = self:safe_write_double(target_addr, value)
        return success, success and "Success" or "Failed to write double"
        
    elseif mtype == "bool" then
        if type(value) ~= "boolean" then
            return false, "Value must be a boolean for bool type"
        end
        local success = self:safe_write_bool(target_addr, value)
        return success, success and "Success" or "Failed to write bool"
        
    else
        return false, "Unsupported memory type: " .. tostring(mtype)
    end
end

function ActorLoop:GetProperty(instance_addr, mtype, size)
    if not instance_addr or instance_addr == 0 then
        return nil, "Invalid instance address"
    end
    
    if not mtype then
        return nil, "Memory type required"
    end
    
    local target_addr = instance_addr
    
    if mtype == "string" then
        local value = self.memory.read_mem(target_addr, "string", size or 256)
        return value and value ~= "" and value or nil, value and "Success" or "Failed to read string"
        
    elseif mtype == "string_ptr" then
        local value = self.memory.read_string_from_pointer(target_addr, size)
        return value ~= "" and value or nil, value == "" and "Empty string" or "Success"
        
    elseif mtype == "qword" then
        local value = self:safe_read_qword(target_addr)
        return value, "Success"
        
    elseif mtype == "dword" then
        local value = self:safe_read_dword(target_addr)
        return value, "Success"
        
    elseif mtype == "float" then
        local value = self:safe_read_float(target_addr)
        return value, "Success"
        
    elseif mtype == "double" then
        local value = self:safe_read_double(target_addr)
        return value, "Success"
        
    elseif mtype == "bool" then
        local value = self:safe_read_bool(target_addr)
        return value, "Success"
        
    else
        return nil, "Unsupported memory type: " .. tostring(mtype)
    end
end

-- Safe memory read/write operations
function ActorLoop:safe_read_qword(addr)
    if not addr or addr == 0 then return 0 end
    local ok, result = pcall(function()
        return self.memory.read_mem(addr, "qword")
    end)
    return ok and result or 0
end

function ActorLoop:safe_read_dword(addr)
    if not addr or addr == 0 then return 0 end
    local ok, result = pcall(function()
        return self.memory.read_mem(addr, "dword")
    end)
    return ok and result or 0
end

function ActorLoop:safe_read_float(addr)
    if not addr or addr == 0 then return 0.0 end
    local ok, result = pcall(function()
        return self.memory.read_mem(addr, "float")
    end)
    return ok and result or 0.0
end

function ActorLoop:safe_read_double(addr)
    if not addr or addr == 0 then return 0.0 end
    local ok, result = pcall(function()
        return self.memory.read_mem(addr, "double")
    end)
    return ok and result or 0.0
end

function ActorLoop:safe_read_bool(addr)
    if not addr or addr == 0 then return false end
    local ok, result = pcall(function()
        return self.memory.read_mem(addr, "bool")
    end)
    return ok and result or false
end

function ActorLoop:safe_write_qword(addr, value)
    if not addr or addr == 0 then return false end
    value = value or 0
    local ok, result = pcall(function()
        return self.memory.write_mem(addr, "qword", value)
    end)
    return ok and result == true
end

function ActorLoop:safe_write_dword(addr, value)
    if not addr or addr == 0 then return false end
    value = value or 0
    local ok, result = pcall(function()
        return self.memory.write_mem(addr, "dword", value)
    end)
    return ok and result == true
end

function ActorLoop:safe_write_float(addr, value)
    if not addr or addr == 0 then return false end
    value = value or 0.0
    local ok, result = pcall(function()
        return self.memory.write_mem(addr, "float", value)
    end)
    return ok and result == true
end

function ActorLoop:safe_write_double(addr, value)
    if not addr or addr == 0 then return false end
    value = value or 0.0
    local ok, result = pcall(function()
        return self.memory.write_mem(addr, "double", value)
    end)
    return ok and result == true
end

function ActorLoop:safe_write_bool(addr, value)
    if not addr or addr == 0 then return false end
    value = value == nil and false or value
    local ok, result = pcall(function()
        return self.memory.write_mem(addr, "bool", value)
    end)
    return ok and result == true
end

-- String utilities
function ActorLoop:ReadString(addr)
    if not addr or addr == 0 then return "???" end
    local ok, str = pcall(function()
        return self.memory.read_mem(addr, "string", 256)
    end)
    return ok and str or "???"
end

function ActorLoop:LengthReadString(string_addr)
    if not string_addr or string_addr == 0 then return "???" end
    local length = self:safe_read_dword(string_addr + self.offsets.StringLength)
    if length >= 16 then
        local new_addr = self:safe_read_qword(string_addr)
        return self:ReadString(new_addr)
    else
        return self:ReadString(string_addr)
    end
end

-- Instance operations
function ActorLoop:GetDataModel()
    local fakeDM = self.memory.read_mem(self.base + self.offsets.FakeDataModelPointer, "qword")
    local DataModel = self.memory.read_mem(fakeDM + self.offsets.FakeDataModelToDataModel, "qword")
    return DataModel
end

function ActorLoop:GetInstanceName(instance_address)
    local name_ptr = self:safe_read_qword(instance_address + self.offsets.Name)
    if name_ptr and name_ptr ~= 0 then
        return self:LengthReadString(name_ptr)
    end
    return "???"
end

function ActorLoop:GetChildren(parent_address)
    if not parent_address or parent_address == 0 then return {} end

    local now = os.clock()
    local need_update = (#self._cached_children_addresses == 0) or (now - self._last_structure_update > 2)

    if need_update then
        self._cached_children_addresses = {}

        local start_addr = self:safe_read_qword(parent_address + self.offsets.Children)
        if start_addr == 0 then return {} end

        local end_addr = self:safe_read_qword(start_addr + self.offsets.ChildrenEnd)
        local instance_ptr = self:safe_read_qword(start_addr)
        if instance_ptr == 0 or instance_ptr >= end_addr then return {} end

        for current = instance_ptr, end_addr - 1, 16 do
            if current <= 0 or current >= 0x7FFFFFFFFFFF then break end
            local child_instance = self:safe_read_qword(current)
            if child_instance ~= 0 and is_valid_utf8(self:GetInstanceName(child_instance)) then
                table.insert(self._cached_children_addresses, child_instance)
            end
        end

        self._last_structure_update = now
    end

    return self._cached_children_addresses
end

function ActorLoop:FindFirstChild(instance_address, child_name)
    if not instance_address or instance_address == 0 then return 0 end

    local children = self:GetChildren(instance_address)
    
    for _, child_instance in ipairs(children) do
        local name = self:GetInstanceName(child_instance)
        if name == child_name then
            return child_instance
        end
    end

    return 0
end

return ActorLoop