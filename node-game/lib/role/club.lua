local skynet = require "skynet"
local share = require "share"
local notify = require "notify"

local table = table

local data

local base
local club_role

local club = {}

skynet.init(function()
    base = share.base
    club_role = skynet.queryservice("club_role")
end)

function club.init(d)
	data = d
end

function club.finish()
	data = nil
end

local function join(info)
    local club_info = data.club_info
    if #club_info < base.MAX_CLUB then
        local index = #club_info + 1
        info.index = index
        club_info[index] = info
        data.id_club[info.id] = info
        data.user.club[index] = info.id
        skynet.send(club_role, "lua", "add", data.id, info.id, info.addr)
        notify.add("update_club", {club=info})
        return true
    end
end
function club.join_club(info)
    return join(info)
end

local function leave(clubid)
    local info = data.id_club[clubid]
    if info then
        local index = info.index
        local club_info = data.club_info
        table.remove(club_info, index)
        table.remove(data.user.club, index)
        for i = index, #club_info do
            club_info[i].index = i
        end
        data.id_club[clubid] = nil
        skynet.send(club_role, "lua", "del", data.id, clubid)
        local u = {id=clubid, del=true}
        notify.add("update_club", {club=u})
    else
        skynet.error(string.format("Role %d not in club %d when leave.", data.id, club.id))
    end
end
function club.leave_club(clubid)
    leave(clubid)
end

function club.club_promote(clubid)
    local info = data.id_club[clubid]
    if info then
        info.pos = base.CLUB_POS_ADMIN
        notify.add("update_club", {club={id=clubid, pos=info.pos}})
    else
        skynet.error(string.format("Role %d not in club %d when promote.", data.id, club.id))
    end
end

function club.club_demote(clubid)
    local info = data.id_club[clubid]
    if info then
        info.pos = base.CLUB_POS_NONE
        notify.add("update_club", {club={id=clubid, pos=info.pos}})
    else
        skynet.error(string.format("Role %d not in club %d when demote.", data.id, club.id))
    end
end

return club
