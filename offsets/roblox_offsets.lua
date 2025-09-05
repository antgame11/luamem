local request = require("libraries.luajit-request.init")
local json = require("libraries.json")
-- https://gist.github.com/ivan-loh/f14b9ae1f17646a9a81b

local function collect(chunk)
  if chunk ~= nil then
    data = data .. chunk
    end
  return true
end

local response = request.send("https://offsets.ntgetwritewatch.workers.dev/offsets.json").body

local jsonoffsets = json.decode(response)

local t = {}

for i, v in pairs(jsonoffsets) do
    local num = string.sub(v,3)
    local hextodec = tonumber(num,16)
    t[i] = hextodec
end

return t