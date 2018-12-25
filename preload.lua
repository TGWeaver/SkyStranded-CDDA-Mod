local ter_warpgate_id = "t_TRS_stabilized_portal_sky"
--the name of the terrain tile being used as a portal. by default this is "t_TRS_stabilized_portal_sky", the new portal-like tile included in the starting island map

local req_power_recall = 2
--this number is the amount of charges required to warp home. charges are set to 0 when warping out, and recharge at 1 per hour (roughly -- recharge is based on minutes left in the hour so it gets complicated but is always accurate within 60 minutes). The ability of the recall stone to hold more power is just so players changing this number don't have to also change max charges; there's no way to 'bank' jumps for later.
--Max is 48, which is about when the inoculation would wear off anyway.

function message(...)
	local s = string.format(...)
	game.add_msg(s)
end

function tri_delta(a, b)
	return tripoint(a.x - b.x, a.y - b.y, a.z - b.z)
end

function standing_on_warpgate()
	local ter_int_id = map:ter(player:pos()):to_i()
	local ter_str_id = game.get_terrain_type(ter_int_id).id:str()
	return (ter_str_id == ter_warpgate_id)
end

function iuse_warpout(item, active)
	local on_warpgate = standing_on_warpgate();
	
	if not on_warpgate then
		message("Couldn't find valid warpgate. You can only make teleports out of your sanctuary while standing on a fully activated warpgate.")
		return
	end
	
	if not game.query_yn("<color_red>Last chance to cancel! After this point, refusing to pick a location will cause a crash.\nReally ready to teleport?</color>") then
		message("Teleport canceled.")
		return
	end
	
	local target = game.omap_choose_point(player:global_omt_location())
	
	item.charges = 0
    
	g:place_player_overmap(target)

	g:reload_npcs()

	message("The safety of your sanctuary streaks away into darkness, and a new world shimmers into being around you, familiar yet different.")

end

function iuse_warpconfig(item, active)
	local on_warpgate = standing_on_warpgate();
	
	if not on_warpgate then
		message("Couldn't find valid warpgate. Please use this item only while standing on a fully activate warpgate.")
		return
	end
	
	local is_linked = item:has_var("gate_name")
	
	if is_linked then
		if not game.query_yn("A gate link has already been established.\nAre you sure you want to override the current link?") then
			message("A gate link was not established.")
			return
		end
	end
	
	local om = player:global_omt_location()
	local gpos = player:global_square_location()
	
	item:set_var("gate_name", "linked")
	item:set_var("gate_omx", tostring(om.x))
	item:set_var("gate_omy", tostring(om.y))
	item:set_var("gate_omz", tostring(om.z))
	item:set_var("gate_gx", tostring(gpos.x))
	item:set_var("gate_gy", tostring(gpos.y))
	item:set_var("gate_gz", tostring(gpos.z))
	
	message("You've bound this gate as your home.")
end

function iuse_warpin(item, active)
	if item.charges < req_power_recall then
		message("Insufficient charge. The transdimensional energies in this artifact need time to recharge.", req_power_gate)
		return
	end

	local is_linked = item:has_var("gate_name")
	if not is_linked then
		message("This artifact isn't bound to a home portal. There's no anchor point to warp home to.")
		return
	end

	local omx = tonumber(item:get_var("gate_omx", "0"))
	local omy = tonumber(item:get_var("gate_omy", "0"))
	local omz = tonumber(item:get_var("gate_omz", "0"))
	local gx = tonumber(item:get_var("gate_gx", "0"))
	local gy = tonumber(item:get_var("gate_gy", "0"))
	local gz = tonumber(item:get_var("gate_gz", "0"))
	local om = tripoint(omx, omy, omz)
	local gpos = tripoint(gx, gy, gz)

	g:place_player_overmap(om)
	local cur_gpos = player:global_square_location()
	local cur_pos = player:pos()

	-- player:pos()で取得できる座標はバッファ上の一時的な座標なので、 [Since the coordinates that can be acquired in the buffer are temporary coordinates on the buffer,]
	-- global_square_locationで絶対座標を取得して補正する  [Get absolute coordinates and correct them]
	local delta = tri_delta(cur_gpos, gpos)
	player:setx(cur_pos.x - delta.x)
	player:sety(cur_pos.y - delta.y)
	player:setz(cur_pos.z - delta.z)
	
	g:reload_npcs()

	message("The transient world vanishes into a distant and infinite horizon, and the familiar bubble of your sanctuary drips soothingly in around you, like wet paint.")
	
	return 0
end

game.register_iuse("IUSE_WARPOUT", iuse_warpout)
game.register_iuse("IUSE_WARPIN", iuse_warpin)
game.register_iuse("IUSE_WARPCONFIG", iuse_warpconfig)
