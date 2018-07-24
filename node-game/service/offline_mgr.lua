local skynet = require "skynet"
local queue = require "skynet.queue"

local assert = assert
local table = table

local offline_db
local user_db
local role_mgr
local cs = queue()

local CMD = {}

local function add(id, func, ...)
    local agent = skynet.call(role_mgr, "lua", "get", id)
    if agent then
        skynet.send(agent, "lua", "action", func, true, ...)
    else
        skynet.send(offline_db, "lua", "update", {id=id}, {["$push"]={data={func, false, ...}}}, true)
    end
end

local function offline(id, func, ...)
    skynet.send(offline_db, "lua", "update", {id=id}, {["$push"]={data={func, false, ...}}}, true)
end

local function get(id)
    local m = skynet.call(offline_db, "lua", "findOne", {id=id})
    if m then
        skynet.send(offline_db, "lua", "delete", {id=id})
        return m.data
    end
end

function CMD.broadcast(func, ...)
    local arg = table.pack(...)
    util.mongo_find(user_db, function(r)
        cs(add, r.id, func, table.unpack(arg))
    end, nil, {id=true, _id=false})
end

function CMD.add(id, func, ...)
    cs(add, id, func, ...)
end

function CMD.offline(id, func, ...)
    cs(offline, id, func, ...)
end

function CMD.get(id)
    return cs(get, id)
end

skynet.start(function()
    local master = skynet.queryservice("mongo_master")
    offline_db = skynet.call(master, "lua", "get", "offline")
    user_db = skynet.call(master, "lua", "get", "user")
    role_mgr = skynet.queryservice("role_mgr")

	skynet.dispatch("lua", function(session, source, command, ...)
		local f = assert(CMD[command])
        if session == 0 then
            f(...)
        else
            skynet.retpack(f(...))
        end
	end)
end)
