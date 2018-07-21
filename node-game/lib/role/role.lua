local skynet = require "skynet"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local func = require "func"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local string = string
local floor = math.floor
local tonumber = tonumber
local tostring = tostring
local table = table

local data

local role = {}

local base
local rand
local define
local game_day
local role_mgr
local offline_mgr
local club_mgr
local club_role
local gm_level = tonumber(skynet.getenv("gm_level"))
local user_db
local info_db
local charge_log_db
local activity_mgr

skynet.init(function()
    base = share.base
    rand = share.rand
    define = share.define
    game_day = func.game_day
    role_mgr = skynet.queryservice("role_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")
    club_mgr = skynet.queryservice("club_mgr")
    club_role = skynet.queryservice("club_role")

    activity_mgr = skynet.queryservice("activity_mgr")

	local master = skynet.queryservice("mongo_master")
    user_db = skynet.call(master, "lua", "get", "user")
    info_db = skynet.call(master, "lua", "get", "info")
    charge_log_db = skynet.call(master, "lua", "get", "charge_log")
end)

local function sort_club(l, r)
    return l.index < r.index
end

local function get_user()
    if not data.user then
        if not data.sex or data.sex == 0 then
            data.sex = rand.randi(1, 2)
        end
        local id = data.id
		local user = skynet.call(user_db, "lua", "findOne", {id=id})
		if user then
			user.nick_name = data.nick_name
			user.head_img = data.head_img
			user.ip = data.ip
            user.sex = data.sex
            user.openid = data.openid
            user.unionid = data.unionid
			data.user = user
			data.info = {
				account = user.account,
				id = id,
				sex = user.sex,
				nick_name = user.nick_name,
				head_img = user.head_img,
                openid = user.openid,
                unionid = user.unionid,
				ip = user.ip,
			}
            data.offline = skynet.call(offline_mgr, "lua", "get", id)
            local rc = skynet.call(club_role, "lua", "get", id)
            if rc then
                local id_club = {}
                local club_info = {}
                local club_found = 0
                for k, v in pairs(rc) do
                    local ci = skynet.call(v, "lua", "login", id)
                    if ci then
                        ci.index = base.MAX_CLUB
                        id_club[ci.id] = ci
                        club_info[#club_info+1] = ci
                        if ci.pos == base.CLUB_POS_CHIEF then
                            club_found = club_found + 1
                        end
                    end
                end
                for k, v in ipairs(user.club) do
                    local ci = id_club[v]
                    if ci then
                        ci.index = k
                    end
                end
                table.sort(club_info, sort_club)
                local club = {}
                for k, v in ipairs(club_info) do
                    v.index = k
                    club[k] = v.id
                end
                user.club = club
                data.club_info = club_info
                data.id_club = id_club
                data.club_found = club_found
            else
                user.club = {}
                data.club_info = {}
                data.id_club = {}
                data.club_found = 0
            end
		else
			local now = floor(skynet.time())
			local user = {
				account = data.uid,
				id = data.id,
				sex = data.sex,
				login_time = 0,
				last_login_time = 0,
				logout_time = 0,
				gm_level = gm_level,
				create_time = now,
				room_card = define.init_card,
				nick_name = data.nick_name,
				head_img = data.head_img,
                openid = data.openid,
                unionid = data.unionid,
				ip = data.ip,
                day_card = false,
                invite_code = 0,
                first_charge = {},
                club = {},
			}
			skynet.send(user_db, "lua", "safe_insert", user)
			data.user = user
			local info = {
				account = user.account,
				id = user.id,
				sex = user.sex,
				nick_name = user.nick_name,
				head_img = user.head_img,
                openid = user.openid,
                unionid = user.unionid,
				ip = user.ip,
			}
			skynet.send(info_db, "lua", "safe_insert", info)
            data.info = info
            data.club_info = {}
            data.id_club = {}
            data.club_found = 0
            
            skynet.send(activity_mgr, "lua", "reg_invite_user", info)
		end
    end
end

function role.init(d)
	data = d
    data.heart_beat = 0
    timer.add_routine("heart_beat", function()
		role.heart_beat(data)
	end, 86400)
    local server_mgr = skynet.queryservice("server_mgr")
    data.server = skynet.call(server_mgr, "lua", "get", data.serverid)
	local now = floor(skynet.time())
    rand.init(now)
	-- you may load user data from database
	skynet.fork(get_user)
end

function role.finish()
    timer.del_routine("save_role")
    timer.del_day_routine("update_day")
    timer.del_routine("heart_beat")
    local user = data.user
    if user then
        skynet.send(role_mgr, "lua", "logout", user.id)
        user.logout_time = floor(skynet.time())
        role.save_user()
    end
    local chess_table = data.chess_table
    if chess_table then
        skynet.send(chess_table, "lua", "status", data.id, base.USER_STATUS_LOGOUT)
    end
	notify.add("logout", {})
	data = nil
end

local function update_day(od, nd)
	local user = data.user
    user.day_card = false
end

function role.update_day(od, nd)
    update_day(od, nd)
    notify.add("update_day", {})
end

function role.test_update_day()
    local now = floor(skynet.time())
    local nd = game_day(now)
	role.update_day(nd, nd)
end

function role.save_user()
    local id = data.id
    skynet.send(user_db, "lua", "update", {id=id}, data.user, true)
    skynet.send(info_db, "lua", "update", {id=id}, data.info, true)
end

function role.save_routine()
    role.save_user()
end

function role.heart_beat()
    if data.heart_beat == 0 then
        skynet.error(string.format("heart beat kick user %d.", data.id))
        skynet.send(data.gate, "lua", "kick", data.id) -- data is nil
    else
        data.heart_beat = 0
    end
end

function role.afk()
    local chess_table = data.chess_table
    local id = data.id
    if chess_table then
        skynet.send(chess_table, "lua", "status", id, base.USER_STATUS_LOST)
    end
    for k, v in ipairs(data.club_info) do
        skynet.send(v.addr, "lua", "online", id, false)
    end
end

local function btk(addr)
    local chess_table = data.chess_table
    if chess_table then
        skynet.send(chess_table, "lua", "status", data.id, base.USER_STATUS_ONLINE, addr)
    else
        notify.add("user_info", {ip=addr})
    end
end
function role.btk(addr)
    data.ip = addr
    data.user.ip = addr
    data.info.ip = addr
    if data.enter then
        -- skynet.fork(btk, addr)
        btk(addr)
    end
    local id = data.id
    for k, v in ipairs(data.club_info) do
        skynet.send(v.addr, "lua", "online", id, true)
    end
end

function role.repair(now)
	local user = data.user
    if user.day_card == nil then
        user.day_card = false
    end
    if not user.invite_code then
        user.invite_code = 0
    end
    if not user.first_charge then
        user.first_charge = {}
    end
    if not user.club then
        user.club = {}
    end
end

function role.add_room_card(inform, num)
    local user = data.user
    user.room_card = user.room_card + num
    if inform then
        notify.add("user_info", {room_card=user.room_card})
    end
end

function role.unlink(inform)
    local user = data.user
    if user.invite_code > 0 then
        user.invite_code = 0
        if inform then
            notify.add("user_info", {invite_code=user.invite_code})
        end
    end
end

function role.charge(p, inform, ret)
    if ret.retCode == "SUCCESS" then
        local trade_id = tonumber(ret.tradeNO)
        local r = skynet.call(charge_log_db, "lua", "findAndModify", 
            {query={id=trade_id, status=false}, update={["$set"]={status=true}}})
        if r.lastErrorObject.updatedExisting then
            local cashFee = r.value.num
            local user = data.user
            local num
            if user.invite_code > 0 then
                num = define.shop_item_2[cashFee]
                local first_charge = user.first_charge
                local feeStr = tostring(cashFee)
                if not first_charge[feeStr] then
                    first_charge[feeStr] = true
                    p.first_charge = {cashFee}
                    if cashFee == 600 then
                        num = num * 2
                    end
                end
            else
                num = define.shop_item[cashFee]
            end
            role.add_room_card(p, inform, num)
        else
            skynet.error(string.format("No unfinished trade: %d.", trade_id))
        end
    else
        skynet.error(string.format("Trade %s fail: %s.", ret.tradeNO, ret.retMsg))
    end
end

function role.bind_gzh(inform, ret)
    if inform and ret then
        notify.add("update_gzh", {bind_gzh=true})
    end
end

function role.leave_chess()
    assert(data.chess_table, string.format("user %d not in chess.", data.id))
    skynet.error(string.format("user %d leave chess.", data.id))
    data.chess_table = nil
end

return role
