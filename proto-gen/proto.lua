local name_msg = {
	user_info = 1001,
	other_all = 1002,
	weave_card = 1003,
	show_card = 1004,
	chess_user = 1005,
	chess_info = 1006,
	chess_all = 1007,
	record_info = 1008,
	test = 1009,
	chess_record = 1010,
	record_all = 1011,
	get_club_user_record = 1012,
	club_user_record = 1013,
	get_club_record = 1014,
	club_record = 1015,
	read_club_record = 1016,
	club_info = 1017,
	club_member = 1018,
	club_member_list = 1019,
	update_club_member = 1020,
	club_apply = 1021,
	club_apply_list = 1022,
	update_club_apply = 1023,
	room_user = 1024,
	room_info = 1025,
	room_list = 1026,
	club_all = 1027,
	user_all = 1028,
	info_all = 1029,
	update_user = 1030,
	heart_beat = 1031,
	heart_beat_response = 1032,
	error_code = 1033,
	logout = 1034,
	get_role = 1035,
	role_info = 1036,
	add_room_card = 1037,
	new_chess = 1038,
	join = 1039,
	out_card = 1040,
	chi = 1041,
	hide_gang = 1042,
	reply = 1043,
	dymj_card = 1044,
	jdmj_card = 1045,
	jd13_card = 1046,
	dy13_card = 1047,
	dy4_card = 1048,
	jhbj_card = 1049,
	enter_game = 1050,
	review_record = 1051,
	chat_info = 1052,
	iap = 1053,
	thirteen_out = 1054,
	bj_out = 1055,
	invite_code = 1056,
	charge = 1057,
	charge_ret = 1058,
	location_info = 1059,
	query_club = 1060,
	found_club = 1061,
	apply_club = 1062,
	accept_club_apply = 1063,
	refuse_club_apply = 1064,
	query_club_apply = 1065,
	query_club_member = 1066,
	club_top = 1067,
	club_top_ret = 1068,
	remove_club_member = 1069,
	charge_club = 1070,
	config_club = 1071,
	promote_club_member = 1072,
	demote_club_member = 1073,
	query_club_room = 1074,
	config_quick_start = 1075,
	accept_all_club_apply = 1076,
	refuse_all_club_apply = 1077,
	leave_club = 1078,
	query_club_all = 1079,
	check_agent_ret = 1080,
	invited_user_detail = 1081,
	invite_record = 1082,
	invite_info = 1083,
	reward_award = 1084,
	reward_money = 1085,
	act_pay = 1086,
	update_gzh = 1087,
	p4_out = 1088,
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
