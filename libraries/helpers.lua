local ffi = require("ffi")
local mem = ffi.load("MemoryWrapperDLL.dll")

ffi.cdef[[
typedef enum {
    MEM_QWORD  = 0,
    MEM_DWORD  = 1,
    MEM_FLOAT  = 2,
    MEM_DOUBLE = 3,
    MEM_BOOL   = 4,
    MEM_STRING = 5
} MemoryType;

bool InitMemory(const char* processName, const char* windowName);
void FreeMemoryDLL();
bool WriteMemory(uint64_t address, MemoryType type, const void* value, size_t stringSize);
bool ReadMemory(uint64_t address, MemoryType type, void* outBuffer, size_t stringSize);
unsigned long long BaseAddress();
unsigned long long AllocateMemory(size_t size, unsigned long allocType, unsigned long protect);
bool FreeMemory(unsigned long long address, size_t size, unsigned long freeType);
bool ProtectMemory(unsigned long long address, size_t size, unsigned long newProtect, unsigned long* oldProtectOut);
bool WriteString(unsigned long long address, const char* str);
bool ReadString(unsigned long long address, char* outBuffer, size_t maxSize);
bool IsMemoryValid();
]]

-- Windows memory constants
local MEM_COMMIT = 0x1000
local MEM_RESERVE = 0x2000
local MEM_RELEASE = 0x8000
local PAGE_READWRITE = 0x04

local type_map = {
    qword  = { ctype = "uint64_t[1]", enum = ffi.C.MEM_QWORD },
    dword  = { ctype = "unsigned int[1]", enum = ffi.C.MEM_DWORD },
    float  = { ctype = "float[1]", enum = ffi.C.MEM_FLOAT },
    double = { ctype = "double[1]", enum = ffi.C.MEM_DOUBLE },
    bool   = { ctype = "bool[1]", enum = ffi.C.MEM_BOOL },
    string = { ctype = "char[?]", enum = ffi.C.MEM_STRING },
}

local M = {}

-- Initialize memory connection
function M.init(process_name, window_name)
    return mem.InitMemory(process_name, window_name or "")
end

-- Free memory connection
function M.free()
    mem.FreeMemoryDLL()
end

-- Check if memory connection is valid
function M.is_valid()
    return mem.IsMemoryValid()
end

-- Get base address
function M.base_address()
    return mem.BaseAddress()
end

-- Read memory
function M.read_mem(addr, mtype, size)
    local t = type_map[mtype]
    assert(t, "Invalid memory type: " .. tostring(mtype))

    if mtype == "string" then
        local buf = ffi.new(t.ctype, size or 256)
        if mem.ReadMemory(addr, t.enum, buf, size or 256) then
            return ffi.string(buf)
        end
    else
        local out = ffi.new(t.ctype)
        if mem.ReadMemory(addr, t.enum, out, 0) then
            return tonumber(out[0])
        end
    end
end

-- Write memory
function M.write_mem(addr, mtype, value, size)
    local t = type_map[mtype]
    assert(t, "Invalid memory type: " .. tostring(mtype))

    if mtype == "string" then
        local str_size = size or (#value + 1) 
        local buf = ffi.new(t.ctype, str_size)
        ffi.copy(buf, value, math.min(#value, str_size - 1)) 
        buf[str_size - 1] = 0
        return mem.WriteMemory(addr, t.enum, buf, str_size)
    else
        local buf = ffi.new(t.ctype)
        buf[0] = value
        return mem.WriteMemory(addr, t.enum, buf, 0)
    end
end

-- Memory allocation and management
function M.allocate_memory(size, alloc_type, protect)
    alloc_type = alloc_type or (MEM_COMMIT + MEM_RESERVE)
    protect = protect or PAGE_READWRITE
    local addr = mem.AllocateMemory(size, alloc_type, protect)
    return addr ~= 0 and addr or nil
end

function M.free_memory(address, size, free_type)
    free_type = free_type or MEM_RELEASE
    return mem.FreeMemory(address, size, free_type)
end

function M.protect_memory(address, size, new_protect, old_protect_out)
    return mem.ProtectMemory(address, size, new_protect, old_protect_out)
end

-- Convenient string functions using the DLL's utility functions
function M.write_string(addr, str)
    return mem.WriteString(addr, str)
end

function M.read_string(addr, max_size)
    max_size = max_size or 256
    local buf = ffi.new("char[?]", max_size)
    if mem.ReadString(addr, buf, max_size) then
        return ffi.string(buf)
    end
    return ""
end

-- High-level string writing with automatic memory management
function M.write_string_with_alloc(addr, str)
    -- Allocate memory for the string
    local str_addr = M.allocate_memory(#str + 1)
    if not str_addr then
        return false, "Failed to allocate memory"
    end
    
    -- Write the string to allocated memory
    if not M.write_string(str_addr, str) then
        M.free_memory(str_addr, #str + 1)
        return false, "Failed to write string"
    end
    
    -- Write the pointer to the target address
    if not M.write_mem(addr, "qword", str_addr) then
        M.free_memory(str_addr, #str + 1)
        return false, "Failed to write pointer"
    end
    
    return true, str_addr -- Return success and the allocated address for later cleanup
end

-- Read a string through a pointer
function M.read_string_from_pointer(addr, max_size)
    max_size = max_size or 256
    local ptr = M.read_mem(addr, "qword")
    if ptr and ptr ~= 0 then
        return M.read_string(ptr, max_size)
    end
    return ""
end

-- Batch operations for better performance
function M.batch_read(addresses)
    local results = {}
    for i, entry in ipairs(addresses) do
        local addr = entry.addr or entry[1]
        local mtype = entry.type or entry[2]
        local size = entry.size or entry[3]
        
        results[i] = M.read_mem(addr, mtype, size)
    end
    return results
end

function M.batch_write(writes)
    local results = {}
    for i, entry in ipairs(writes) do
        local addr = entry.addr or entry[1]
        local mtype = entry.type or entry[2]
        local value = entry.value or entry[3]
        local size = entry.size or entry[4]
        
        results[i] = M.write_mem(addr, mtype, value, size)
    end
    return results
end

-- Memory pattern scanning (if you want to add pattern scanning later)
function M.scan_pattern(start_addr, size, pattern, mask)
    -- This would need to be implemented in the C++ DLL
    -- For now, return nil to indicate not implemented
    return nil
end

-- Utility functions for common operations
function M.read_pointer_chain(base_addr, offsets)
    local current_addr = base_addr
    for i, offset in ipairs(offsets) do
        if i == #offsets then
            -- Last offset, return the final address
            return current_addr + offset
        else
            -- Read the pointer and add offset
            current_addr = M.read_mem(current_addr + offset, "qword")
            if not current_addr or current_addr == 0 then
                return 0
            end
        end
    end
    return current_addr
end

-- Safe memory operations with error handling
function M.safe_read(addr, mtype, size)
    if not addr or addr == 0 then return nil end
    local ok, result = pcall(M.read_mem, addr, mtype, size)
    return ok and result or nil
end

function M.safe_write(addr, mtype, value, size)
    if not addr or addr == 0 then return false end
    local ok, result = pcall(M.write_mem, addr, mtype, value, size)
    return ok and result
end

-- Memory tracking for cleanup
local allocated_memory = {}

function M.tracked_allocate(size, alloc_type, protect)
    local addr = M.allocate_memory(size, alloc_type, protect)
    if addr then
        allocated_memory[addr] = size
    end
    return addr
end

function M.tracked_free(address)
    local size = allocated_memory[address]
    if size then
        local success = M.free_memory(address, size)
        if success then
            allocated_memory[address] = nil
        end
        return success
    end
    return false
end

function M.cleanup_all_tracked()
    local freed_count = 0
    for addr, size in pairs(allocated_memory) do
        if M.free_memory(addr, size) then
            freed_count = freed_count + 1
        end
    end
    allocated_memory = {}
    return freed_count
end

return M