local name_msg = {
	user_info = 1001,
	other_all = 1002,
	weave_card = 1003,
	show_card = 1004,
	chess_user = 1005,
	chess_info = 1006,
	chess_all = 1007,
	record_info = 1008,
	chess_record = 1009,
	record_all = 1010,
	get_club_user_record = 1011,
	club_user_record = 1012,
	get_club_record = 1013,
	club_record = 1014,
	read_club_record = 1015,
	club_info = 1016,
	club_member = 1017,
	club_member_list = 1018,
	update_club_member = 1019,
	club_apply = 1020,
	club_apply_list = 1021,
	update_club_apply = 1022,
	room_user = 1023,
	room_info = 1024,
	room_list = 1025,
	club_all = 1026,
	user_all = 1027,
	info_all = 1028,
	update_user = 1029,
	heart_beat = 1030,
	heart_beat_response = 1031,
	error_code = 1032,
	logout = 1033,
	get_role = 1034,
	role_info = 1035,
	add_room_card = 1036,
	new_chess = 1037,
	join = 1038,
	out_card = 1039,
	chi = 1040,
	hide_gang = 1041,
	reply = 1042,
	dymj_card = 1043,
	jdmj_card = 1044,
	jd13_card = 1045,
	dy13_card = 1046,
	dy4_card = 1047,
	jhbj_card = 1048,
	enter_game = 1049,
	review_record = 1050,
	chat_info = 1051,
	iap = 1052,
	thirteen_out = 1053,
	bj_out = 1054,
	invite_code = 1055,
	charge = 1056,
	charge_ret = 1057,
	location_info = 1058,
	query_club = 1059,
	found_club = 1060,
	apply_club = 1061,
	accept_club_apply = 1062,
	refuse_club_apply = 1063,
	query_club_apply = 1064,
	query_club_member = 1065,
	club_top = 1066,
	club_top_ret = 1067,
	remove_club_member = 1068,
	charge_club = 1069,
	config_club = 1070,
	promote_club_member = 1071,
	demote_club_member = 1072,
	query_club_room = 1073,
	config_quick_start = 1074,
	accept_all_club_apply = 1075,
	refuse_all_club_apply = 1076,
	leave_club = 1077,
	query_club_all = 1078,
	check_agent_ret = 1079,
	invited_user_detail = 1080,
	invite_record = 1081,
	invite_info = 1082,
	reward_award = 1083,
	reward_money = 1084,
	act_pay = 1085,
	update_gzh = 1086,
	p4_out = 1087,
}

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
