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
]]

local type_map = {
    qword  = { ctype = "uint64_t[1]", enum = ffi.C.MEM_QWORD },
    dword  = { ctype = "unsigned int[1]", enum = ffi.C.MEM_DWORD },
    float  = { ctype = "float[1]", enum = ffi.C.MEM_FLOAT },
    double = { ctype = "double[1]", enum = ffi.C.MEM_DOUBLE },
    bool   = { ctype = "bool[1]", enum = ffi.C.MEM_BOOL },
    string = { ctype = "char[?]", enum = ffi.C.MEM_STRING },
}

local M = {}

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

function M.write_mem(addr, mtype, value, size)
    local t = type_map[mtype]
    assert(t, "Invalid memory type: " .. tostring(mtype))

    if mtype == "string" then
        local buf = ffi.new(t.ctype, size or (#value + 1), value)
        return mem.WriteMemory(addr, t.enum, buf, size or (#value + 1))
    else
        local buf = ffi.new(t.ctype, 1)
        buf[0] = value
        return mem.WriteMemory(addr, t.enum, buf, 0)
    end
end

return M
