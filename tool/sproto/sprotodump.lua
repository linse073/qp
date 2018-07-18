local parser = require "sprotoparser"
local lfs = require "lfs"

local dir = ...

local function search(dir)
	local content = ""
	for file in lfs.dir(dir) do
		local f = dir .. '/' .. file
		local attr = lfs.attributes(f)
		if attr.mode == "file" and file:match("%.sproto$") then
			print(string.format("read file: %s", f))
			local fd = io.open(f, "r")
			local data = fd:read "*a"
			content = content .. data
			fd:close()
		end
	end
	return content
end
local spb_data, proto = parser.parse_1(search(dir .. "/proto"))
local spb_file = dir .. "/proto-gen/proto.spb"
local spb_fd = io.open(spb_file, "w")
spb_fd:write(spb_data)
spb_fd:close()
print(string.format("wirte file: %s", spb_file))
package.path = package.path .. dir .. "/proto-gen/?.lua"
local ok, p = pcall(require, "proto")
local name_msg
if ok then
    name_msg = p.name_msg
else
    name_msg = {}
end
local max_id = 1000
for k, v in pairs(name_msg) do
    if v > max_id then
        max_id = v
    end
end
for _, name in ipairs(proto) do
    if not name_msg[name] then
        max_id = max_id + 1
        name_msg[name] = max_id
    end
end
local proto_file = dir .. "/proto-gen/proto.lua"
local proto_fd = io.open(proto_file, "w+")
proto_fd:write("local name_msg = {\n")
for k, v in ipairs(proto) do
    proto_fd:write("\t" .. v .. " = " .. name_msg[v] .. ",\n")
end
proto_fd:write("}\n")
proto_fd:write([[

local pairs = pairs
local ipairs = ipairs

local msg = {}

for k, v in pairs(name_msg) do
    msg[v] = k
end

local proto = {
    msg = msg,
    name_msg = name_msg,
}

function proto.get_id(name)
    return name_msg[name]
end

function proto.get_name(id)
    return msg[id]
end

return proto
]])
proto_fd:close()
print(string.format("wirte file: %s", proto_file))
