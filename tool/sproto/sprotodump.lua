local parser = require "sprotoparser"
local lfs = require "lfs"

local dir = ...

local function search(dir)
	local content = ""
	for file in lfs.dir(dir) do
		local f = dir .. '/' .. file
		local attr = lfs.attributes(f)
		if attr.mode == "file" and file:match("%.sproto$") then
			print(string.format("read file: %s", file))
			local fd = io.open(f, "r")
			local data = fd:read "*a"
			content = content .. data
			fd:close()
		end
	end
	return content
end
local sp = parser.parse(search(dir))
local fd = io.open(dir .. "/proto.spb", "w")
fd:write(sp)
fd:close()
print("write file: proto.spb")