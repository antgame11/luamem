local ffi = require("ffi")
local mem = ffi.load("MemoryWrapperDLL.dll")
local helpers = require("libraries.helpers")
local offsets = require("offsets.roblox_offsets")
local ActorLoop = require("libraries.ActorLoop")

ffi.cdef[[
    void Sleep(int ms);
    int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]

local ok = mem.InitMemory("RobloxPlayerBeta.exe", nil)

local base = tonumber(mem.BaseAddress())
local actor = ActorLoop.new(helpers,offsets,base)

wait = function(sec)
    ffi.C.Sleep(sec * 1000)
end


local DataModel = actor:GetDataModel()
local Workspace = actor:FindFirstChild(DataModel,"Workspace")



for i,v in pairs(actor:GetChildren(Workspace)) do
    actor:SetProperty(v + offsets.Name, "string_ptr", "crazy",6)
    print(actor:GetInstanceName(v))
end
    wait(0.01)

mem.FreeMemoryDLL()
