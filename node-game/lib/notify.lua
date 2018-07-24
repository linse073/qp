local skynet = require "skynet"
local share = require "share"

local assert = assert
local string = string

local name_msg
local sproto

local notify = {}

local data
local msg_content = ""

skynet.init(function()
    name_msg = share.name_msg
    sproto = share.sproto
end)

function notify.init(d)
    data = d
end

function notify.send()
    skynet.send(data.gate, "lua", "notify", data.username, msg_content)
    msg_content = ""
end

function notify.add(msg, content)
    if content then
        if sproto:exist_type(msg) then
            content = sproto:pencode(msg, content)
        end
        local id = assert(name_msg[msg], string.format("No protocol %s.", msg))
        content = string.pack(">s2", string.pack(">I2", id) .. content)
        msg_content = msg_content .. content
    else
        msg_content = msg_content .. msg
    end
end

return notify
