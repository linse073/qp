local skynet = require "skynet"
local timer = require "timer"
local share = require "share"
local notify = require "notify"
local util = require "util"
local cjson = require "cjson"
local func = require "func"
local option = require "logic.option"
local md5 = require "md5"

local pairs = pairs
local ipairs = ipairs
local assert = assert
local error = error
local string = string
local math = math
local floor = math.floor
local tonumber = tonumber
local tostring = tostring
local pcall = pcall
local table = table

local game

local proc = {}
local role = {proc = proc}

local update_user = util.update_user
local error_code
local base
local rand
local define
local game_day
local role_mgr
local offline_mgr
local club_mgr
local club_role
local table_mgr
local chess_mgr
local webclient
local gm_level = tonumber(skynet.getenv("gm_level"))
local start_utc_time = tonumber(skynet.getenv("start_utc_time"))
local user_db
local info_db
local user_record_db
local record_info_db
local record_detail_db
local iap_log_db
local charge_log_db
local invite_info_db
local invite_user_detail_db
local activity_mgr

local web_sign = skynet.getenv("web_sign")
local debug = (skynet.getenv("debug")=="true")

skynet.init(function()
    error_code = share.error_code
    base = share.base
    rand = share.rand
    define = share.define
    game_day = func.game_day
    role_mgr = skynet.queryservice("role_mgr")
    offline_mgr = skynet.queryservice("offline_mgr")
    club_mgr = skynet.queryservice("club_mgr")
    club_role = skynet.queryservice("club_role")
    table_mgr = skynet.queryservice("table_mgr")
    chess_mgr = skynet.queryservice("chess_mgr")
    webclient = skynet.queryservice("webclient")

    activity_mgr = skynet.queryservice("activity_mgr")

	local master = skynet.queryservice("mongo_master")
    user_db = skynet.call(master, "lua", "get", "user")
    info_db = skynet.call(master, "lua", "get", "info")
    user_record_db = skynet.call(master, "lua", "get", "user_record")
    record_info_db = skynet.call(master, "lua", "get", "record_info")
    record_detail_db = skynet.call(master, "lua", "get", "record_detail")
    iap_log_db = skynet.call(master, "lua", "get", "iap_log")
    charge_log_db = skynet.call(master, "lua", "get", "charge_log")
    
    invite_info_db = skynet.call(master, "lua", "get", "invite_info")
    invite_user_detail_db = skynet.call(master, "lua", "get", "invite_user_detail")
end)

local role = {}

local function sort_club(l, r)
    return l.index < r.index
end

function role:get_user()
    if not self.user then
        if not self.sex or self.sex == 0 then
            self.sex = rand.randi(1, 2)
        end
        local id = self.id
		local user = skynet.call(user_db, "lua", "findOne", {id=id})
		if user then
			user.nick_name = self.nick_name
			user.head_img = self.head_img
			user.ip = self.ip
            user.sex = self.sex
            user.openid = self.openid
            user.unionid = self.unionid
			self.user = user
			self.info = {
				account = user.account,
				id = id,
				sex = user.sex,
				nick_name = user.nick_name,
				head_img = user.head_img,
                openid = user.openid,
                unionid = user.unionid,
				ip = user.ip,
			}
            self.offline = skynet.call(offline_mgr, "lua", "get", id)
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
                self.club_info = club_info
                self.id_club = id_club
                self.club_found = club_found
            else
                user.club = {}
                self.club_info = {}
                self.id_club = {}
                self.club_found = 0
            end
		else
			local now = floor(skynet.time())
			local user = {
				account = self.uid,
				id = self.id,
				sex = self.sex,
				login_time = 0,
				last_login_time = 0,
				logout_time = 0,
				gm_level = gm_level,
				create_time = now,
				room_card = define.init_card,
				nick_name = self.nick_name,
				head_img = self.head_img,
                openid = self.openid,
                unionid = self.unionid,
				ip = self.ip,
                day_card = false,
                invite_code = 0,
                first_charge = {},
                club = {},
			}
			skynet.call(user_db, "lua", "safe_insert", user)
			self.user = user
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
			skynet.call(info_db, "lua", "safe_insert", info)
            self.info = info
            self.club_info = {}
            self.id_club = {}
            self.club_found = 0
            
            skynet.send(activity_mgr, "lua", "reg_invite_user", info)
		end
    end
end

function role:init()
    self.heart_beat = 0
    timer.add_routine("heart_beat", function()
		self:heart_beat()
	end, 86400)
    local server_mgr = skynet.queryservice("server_mgr")
    self.server = skynet.call(server_mgr, "lua", "get", self.serverid)
	local now = floor(skynet.time())
    rand.init(now)
	-- you may load user data from database
	skynet.fork(get_user)
end

function role:exit()
    timer.del_routine("save_role")
    timer.del_day_routine("update_day")
    timer.del_routine("heart_beat")
    local user = self.user
    if user then
        skynet.call(role_mgr, "lua", "logout", user.id)
        user.logout_time = floor(skynet.time())
        self:save_user()
    end
    notify.exit()
    local chess_table = self.chess_table
    if chess_table then
        skynet.call(chess_table, "lua", "status", self.id, base.USER_STATUS_LOGOUT)
    end
end

local function update_day(user, od, nd)
    user.day_card = false
end

function role:update_day(od, nd)
    local user = self.user
    update_day(user, od, nd)
    notify.add("update_day", "")
end

function role:test_update_day()
    local user = self.user
    local now = floor(skynet.time())
    local nd = game_day(now)
    update_user(user, nd, nd)
    return "update_day", ""
end

function role:save_user()
    local id = self.id
    skynet.call(user_db, "lua", "update", {id=id}, self.user, true)
    skynet.call(info_db, "lua", "update", {id=id}, self.info, true)
end

function role:save_routine()
    self:save_user()
end

function role:heart_beat()
    if self.heart_beat == 0 then
        skynet.error(string.format("heart beat kick user %d.", self.id))
        skynet.call(self.gate, "lua", "kick", self.id) -- data is nil
    else
        self.heart_beat = 0
    end
end

function role:afk()
    local chess_table = self.chess_table
    local id = self.id
    if chess_table then
        skynet.call(chess_table, "lua", "status", id, base.USER_STATUS_LOST)
    end
    for k, v in ipairs(self.club_info) do
        skynet.call(v.addr, "lua", "online", id, false)
    end
end

local function btk(self, addr)
    local chess_table = self.chess_table
    if chess_table then
        skynet.call(chess_table, "lua", "status", self.id, base.USER_STATUS_ONLINE, addr)
    else
        local p = update_user()
        p.user.ip = addr
        notify.add("update_user", {update=p})
    end
end
function role:btk(addr)
    self.ip = addr
    self.user.ip = addr
    self.info.ip = addr
    if self.enter then
        -- skynet.fork(btk, addr)
        btk(addr)
    end
    local id = self.id
    for k, v in ipairs(self.club_info) do
        skynet.call(v.addr, "lua", "online", id, true)
    end
end

function role:repair(now)
	local user = self.user
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

function role:add_room_card(p, inform, num)
    local user = self.user
    user.room_card = user.room_card + num
    p.user.room_card = user.room_card
    if inform then
        notify.add("update_user", {update=p})
    end
end

function role:unlink(p, inform)
    local user = self.user
    if user.invite_code > 0 then
        user.invite_code = 0
        p.user.invite_code = 0
        if inform then
            notify.add("update_user", {update=p})
        end
    end
end

function role:charge(p, inform, ret)
    if ret.retCode == "SUCCESS" then
        local trade_id = tonumber(ret.tradeNO)
        local r = skynet.call(charge_log_db, "lua", "findAndModify", 
            {query={id=trade_id, status=false}, update={["$set"]={status=true}}})
        if r.lastErrorObject.updatedExisting then
            local cashFee = r.value.num
            local user = self.user
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
            self:add_room_card(p, inform, num)
        else
            skynet.error(string.format("No unfinished trade: %d.", trade_id))
        end
    else
        skynet.error(string.format("Trade %s fail: %s.", ret.tradeNO, ret.retMsg))
    end
end

function role:bind_gzh(inform, ret)
    if inform and ret then
        notify.add("update_gzh", {bind_gzh=true})
    end
end

function role:leave()
    assert(self.chess_table, string.format("user %d not in chess.", self.id))
    skynet.error(string.format("user %d leave chess.", self.id))
    self.chess_table = nil
end

return role
