local helpers = require("lib.helpers")
local offsets = require("offsets.roblox_offsets")
local mem = ffi.load("MemoryWrapperDLL.dll")

-- Attach and get base
local ok = mem.InitMemory("RobloxPlayerBeta.exe", nil)
if not ok then return end

local base = mem.BaseAddress()
print(string.format("BaseAddress: 0x%X", tonumber(base)))

-- Get real DataModel
local fakeDM = helpers.read_mem(base + offsets.FakeDataModelPointer, "qword")
print(fakeDM)
local realDM = helpers.read_mem(fakeDM + offsets.FakeDataModelToDataModel, "qword")
if not realDM or realDM == 0 then
    print("DataModel not found")
    return
end

-- Get Workspace
local workspace = helpers.read_mem(realDM + offsets.DataModel.Workspace, "qword")

-- Quick test: find LocalPlayer
local players = helpers.read_mem(realDM + offsets.DataModel.Players, "qword")  -- or navigate from workspace
local localPlayer = helpers.read_mem(realDM + offsets.Player.LocalPlayer, "qword")
local humanoid = helpers.read_mem(localPlayer + offsets.Player.ModelInstance + offsets.Humanoid.Walkspeed, "qword")

print("LocalPlayer pointer:", localPlayer)
print("Humanoid Walkspeed:", humanoid)

-- Set Walkspeed to something noticeable
helpers.write_mem(localPlayer + offsets.Player.ModelInstance + offsets.Humanoid.Walkspeed, "float", 100)
print("Walkspeed set to 100!")