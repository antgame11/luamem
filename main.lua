local ffi = require("ffi")
local mem = ffi.load("MemoryWrapperDLL.dll")
local helpers = require("libraries.helpers")
local offsets = require("offsets.roblox_offsets")
local ActorLoop = require("libraries.ActorLoop")

local ok = mem.InitMemory("RobloxPlayerBeta.exe", nil)
if not ok then return end

local base = mem.BaseAddress()

local actor = ActorLoop.new(helpers,offsets)



local DataModel = actor:GetDataModel()
print(actor:FindFirstChild(DataModel,"Workspace"))

mem.FreeMemoryDLL()
