local ffi = require("ffi")

ffi.cdef[[
    typedef enum { MEM_QWORD, MEM_DWORD, MEM_FLOAT, MEM_DOUBLE, MEM_BOOL, MEM_STRING } MemoryType;
    bool InitMemory(const char* processName, const char* windowName);
    void FreeMemoryDLL();
    bool WriteMemory(uint64_t address, MemoryType type, const void* value, size_t stringSize);
    bool ReadMemory(uint64_t address, MemoryType type, void* outBuffer, size_t stringSize);
    unsigned long long BaseAddress();
]]

local mem = ffi.load("C:/Users/andre/luamem/MemoryWrapperDLL.dll")

local function read_dword(addr)
    local out = ffi.new("unsigned int[1]")
    if mem.ReadMemory(addr, ffi.C.MEM_DWORD, out, 0) then
        return tonumber(out[0])
    end
end

local function read_float(addr)
    local out = ffi.new("float[1]")
    if mem.ReadMemory(addr, ffi.C.MEM_FLOAT, out, 0) then
        return tonumber(out[0])
    end
end

local function read_bool(addr)
    local out = ffi.new("bool[1]")
    if mem.ReadMemory(addr, ffi.C.MEM_BOOL, out, 0) then
        return out[0] ~= 0
    end
end

local function read_string(addr, size)
    local buf = ffi.new("char[?]", size)
    if mem.ReadMemory(addr, ffi.C.MEM_STRING, buf, size) then
        return ffi.string(buf)
    end
end


local process_name = "RobloxPlayerBeta.exe"
if mem.InitMemory(process_name, nil) then
    local base = mem.BaseAddress()
    print(string.format("Base: 0x%X", tonumber(base)))
    mem.FreeMemoryDLL()
end

