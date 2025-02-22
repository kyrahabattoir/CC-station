// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// To add a rev to the list of revolutionaries, make sure it's rev (with if(istype(ticker.mode, /datum/game_mode/revolution))),
// then call ticker.mode:add_revolutionary(_THE_PLAYERS_MIND_)
// nothing else needs to be done, as that proc will check if they are a valid target.
// Just make sure the converter is a head before you call it!
// To remove a rev (from brainwashing or w/e), call ticker.mode:remove_revolutionary(_THE_PLAYERS_MIND_),
// this will also check they're not a head, so it can just be called freely
// If the rev icons start going wrong for some reason, ticker.mode:update_all_rev_icons() can be called to correct them.
// If the game somtimes isn't registering a win properly, then ticker.mode.check_win() isn't being called somewhere.

/datum/game_mode/revolution
	name = "revolution"
	config_tag = "revolution"
	shuttle_available = 0

	var/list/datum/mind/head_revolutionaries = list()
	var/list/datum/mind/revolutionaries = list()
	var/finished = 0
	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)
	var/round_limit = 21000 // 35 minutes (see post_setup)
	var/endthisshit = 0

/datum/game_mode/revolution/extended
	name = "extended revolution"
	config_tag = "revolution_extended"
	round_limit = 0 //Do not end prematurely

/datum/game_mode/revolution/announce()
	boutput(world, "<B>The current game mode is - Revolution!</B>")
	boutput(world, "<B>Some crewmembers are attempting to start a revolution!<BR><br>Revolutionaries - Kill the heads of staff. Convert other crewmembers (excluding synthetics and security) to your cause by flashing them. Protect your leaders.<BR><br>Personnel - Protect the heads of staff. Kill the leaders of the revolution, and brainwash the other revolutionaries (by using an electropack, electric chair or beating them in the head).</B>")

/datum/game_mode/revolution/pre_setup()
	var/list/revs_possible = get_possible_revolutionaries()

	if (!revs_possible.len)
		return 0

	var/rev_number = 0

	if(revs_possible.len >= 3)
		rev_number = 3
	else
		rev_number = revs_possible.len

	while(rev_number > 0)
		var/datum/mind/revP = pick(revs_possible)
		head_revolutionaries += revP
		revs_possible -= revP
		rev_number--

	return 1

/datum/game_mode/revolution/post_setup()

	var/list/heads = get_living_heads()

	if(!head_revolutionaries || !heads)
		boutput(world, "<B><span style=\"color:red\">Not enough players for revolution game mode. Restarting world in 5 seconds.</span></B>")
		sleep(50)
		Reboot_server()
		return

	for(var/datum/mind/rev_mind in head_revolutionaries)
		for(var/datum/mind/head_mind in heads)
			var/datum/objective/regular/assassinate/rev_obj = new
			rev_obj.owner = rev_mind
			rev_obj.find_target_by_role(head_mind.assigned_role)
			rev_mind.objectives += rev_obj

		equip_revolutionary(rev_mind.current)
		rev_mind.current << browse(grabResource("html/traitorTips/revTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
		update_rev_icons_added(rev_mind)

	for(var/datum/mind/rev_mind in head_revolutionaries)
		var/obj_count = 1
		boutput(rev_mind.current, "<span style=\"color:blue\">You are a member of the revolutionaries' leadership!</span>")
		for(var/datum/objective/objective in rev_mind.objectives)
			boutput(rev_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			obj_count++

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

	if(round_limit > 0)
		spawn (round_limit) // this has got to end soon
			command_alert("A revolution has been detected on [station_name()]. All loyal members of the crew are to ensure the revolution is quelled.","Emergency Riot Update")
			spawn(6000) // 10 minutes to clean up shop
				command_alert("Revolution heads have been identified. Please stand by for hostile employee termination.", "Emergency Riot Update")
				spawn(3000) // 5 minutes until everyone dies
					command_alert("You may feel a slight burning sensation.", "Emergency Riot Update")
					spawn(100) // welp
						for(var/mob/living/carbon/M in mobs)
							M.gib()
						endthisshit = 1

/datum/game_mode/revolution/proc/equip_revolutionary(mob/living/carbon/human/rev_mob)
	equip_traitor(rev_mob)

	var/the_slot = ""

	if (!rev_mob.w_uniform)
		var/obj/F = new /obj/item/device/flash(get_turf(rev_mob))
		rev_mob.put_in_hand_or_drop(F)
		the_slot = "hand"
	else
		if (!rev_mob.r_store)
			rev_mob.equip_if_possible(new /obj/item/device/flash(rev_mob), rev_mob.slot_r_store)
			the_slot = "right pocket"
		else if (!rev_mob.l_store)
			rev_mob.equip_if_possible(new /obj/item/device/flash(rev_mob), rev_mob.slot_l_store)
			the_slot = "left pocket"
		else if (istype(rev_mob.back, /obj/item/storage/) && rev_mob.back.contents.len < 7)
			rev_mob.equip_if_possible(new /obj/item/device/flash(rev_mob), rev_mob.slot_in_backpack)
			the_slot = "backpack"
		else
			var/obj/F2 = new /obj/item/device/flash(get_turf(rev_mob))
			rev_mob.put_in_hand_or_drop(F2)
			the_slot = "hand"

	rev_mob.show_text("You've been supplied with a <b>flash</b> in your [the_slot] with which to convert others to the cause!", "blue")
	return

/datum/game_mode/revolution/send_intercept()
	var/intercepttext = "Cent. Com. Update Requested staus information:<BR>"
	intercepttext += " Cent. Com has recently been contacted by the following syndicate affiliated organisations in your area, please investigate any information you may have:"

	var/list/possible_modes = list()
	possible_modes.Add("revolution", "wizard", "nuke", "traitor", "changeling")
	possible_modes -= "[ticker.mode]"
	var/number = pick(2, 3)
	var/i = 0
	for(i = 0, i < number, i++)
		possible_modes.Remove(pick(possible_modes))
	possible_modes.Insert(rand(possible_modes.len), "[ticker.mode]")

	var/datum/intercept_text/i_text = new /datum/intercept_text
	for(var/A in possible_modes)
		intercepttext += i_text.build(A, pick(head_revolutionaries))
/*
	for (var/obj/machinery/computer/communications/comm in machines)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/paper/intercept = new /obj/item/paper( comm.loc )
			intercept.name = "paper- 'Cent. Com. Status Summary'"
			intercept.info = intercepttext

			comm.messagetitle.Add("Cent. Com. Status Summary")
			comm.messagetext.Add(intercepttext)
*/

	for (var/obj/machinery/communications_dish/C in machines)
		C.add_centcom_report("Cent. Com. Status Summary", intercepttext)

	command_alert("Summary downloaded and printed out at all communications consoles.", "Enemy communication intercept. Security Level Elevated.")


/datum/game_mode/revolution/check_win()
	if(check_rev_victory())
		finished = 1
	else if(check_heads_victory())
		finished = 2
	else if(check_centcom_victory())
		finished = 3
	return

/datum/game_mode/revolution/check_finished()
	if(finished != 0)
		return 1
	else
		return 0

/datum/game_mode/revolution/proc/add_revolutionary(datum/mind/rev_mind)
	if (!rev_mind.current || (rev_mind.current && !rev_mind.current.client))
		return

	var/list/uncons = src.get_unconvertables()
	if (!(rev_mind in src.revolutionaries) && !(rev_mind in src.head_revolutionaries) && !(rev_mind in uncons))
		rev_mind.current << browse(grabResource("html/traitorTips/revAdded.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
		rev_mind.current.show_text("<h2><font color=red>You are now a revolutionary! Kill the heads of staff and don't harm your fellow freedom fighters. You can identify your comrades by the R icons (blue = rev leader, red = regular member).</font></h2>")

		src.revolutionaries += rev_mind
		src.update_rev_icons_added(rev_mind)
		logTheThing("combat", rev_mind.current, null, "was made a member of the revolution.")
		. = 1
	return

/datum/game_mode/revolution/proc/remove_revolutionary(datum/mind/rev_mind)
	if (!rev_mind.current)
		return

	if (rev_mind in revolutionaries)
		rev_mind.current << browse(grabResource("html/traitorTips/revRemoved.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
		rev_mind.current.show_text("<h2><font color=red>You are no longer a revolutionary! Protect the heads of staff and help them kill the leaders of the revolution.</font></h2>", "red")

		src.revolutionaries -= rev_mind
		src.update_rev_icons_removed(rev_mind)
		logTheThing("combat", rev_mind.current, null, "is no longer a member of the revolution.")

		for (var/mob/living/M in view(rev_mind.current))
			M.show_text("<b>[rev_mind.current] looks like they just remembered their real allegiance!</b>", "red")

	return

/datum/game_mode/revolution/proc/update_all_rev_icons()
	var/list/update_me = list()
	update_me.Add(src.head_revolutionaries)
	update_me.Add(src.revolutionaries)

	for (var/datum/mind/M in update_me)
		if (M.current)
			M.current.antagonist_overlay_refresh(1, 0)

	return

/datum/game_mode/revolution/proc/update_rev_icons_added(datum/mind/rev_mind)
	var/list/update_me = list()
	update_me.Add(src.head_revolutionaries)
	update_me.Add(src.revolutionaries) // Includes rev_mind.

	for (var/datum/mind/M in update_me)
		if (M.current)
			M.current.antagonist_overlay_refresh(1, 0)

	return

/datum/game_mode/revolution/proc/update_rev_icons_removed(datum/mind/rev_mind)
	if (rev_mind && istype(rev_mind) && rev_mind.current)
		rev_mind.current.antagonist_overlay_refresh(1, 1)

	var/list/update_me = list()
	update_me.Add(src.head_revolutionaries)
	update_me.Add(src.revolutionaries)

	for (var/datum/mind/M in update_me)
		if (M.current)
			M.current.antagonist_overlay_refresh(1, 0)

	return

/datum/game_mode/revolution/proc/get_possible_revolutionaries()
	var/list/candidates = list()

	for(var/mob/new_player/player in mobs)
		if (ishellbanned(player)) continue //No treason for you
		if ((player.client) && (player.ready) && !(player.mind in head_revolutionaries) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if(player.client.preferences.be_misc)
				candidates += player.mind

	if(candidates.len < 1)
		logTheThing("debug", null, null, "<b>Enemy Assignment</b>: Not enough players with be_misc set to yes, so we're adding players who don't want to be rev leaders to the pool.")
		for(var/mob/new_player/player in mobs)
			if (ishellbanned(player)) continue //No treason for you
			if ((player.client) && (player.ready) && !(player.mind in head_revolutionaries) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

	if(candidates.len < 1)
		return list()
	else
		return candidates

/datum/game_mode/revolution/proc/get_living_heads()
	var/list/heads = list()

	for(var/mob/living/carbon/human/player in mobs)
		if(player.mind)
			var/role = player.mind.assigned_role
			if(role in list("Captain", "Head of Security", "Head of Personnel", "Chief Engineer", "Research Director", "Medical Director"))
				heads += player.mind

	if(heads.len < 1)
		return null
	else
		return heads


/datum/game_mode/revolution/proc/get_all_heads()
	var/list/heads = list()

	for(var/mob/player in mobs)
		if(player.mind)
			var/role = player.mind.assigned_role
			if(role in list("Captain", "Head of Security", "Head of Personnel", "Chief Engineer", "Research Director", "Medical Director"))
				heads += player.mind

	return heads

/datum/game_mode/revolution/proc/get_unconvertables()
	var/list/ucs = list()

	for(var/mob/living/silicon/robot/player in mobs)
		if(player.mind)
			var/rol = player.mind.assigned_role
			if(rol in list("Cyborg"))
				ucs += player.mind

	for(var/mob/living/carbon/human/player in mobs)
		if(player.mind)
			var/role = player.mind.assigned_role
			if(role in list("Captain", "Head of Security", "Head of Personnel", "Chief Engineer", "Research Director", "Medical Director", "Head Surgeon", "Head of Mining", "Security Officer", "Vice Officer", "Detective", "AI", "Cyborg"))
				ucs += player.mind
	//for(var/mob/living/carbon/human/player in mobs)

	return ucs

/datum/game_mode/revolution/proc/check_rev_victory()
	var/list/head_check = get_all_heads()

	if(endthisshit == 1) // don't count gibbed dudes on centcom win
		return 0

	// Run through all the heads
	for(var/datum/mind/head_mind in head_check)
		// If they exist, have a mob and aren't dead
		if(head_mind && head_mind.current && head_mind.current.stat != 2)

			// Check to see if they're a robot
			if(istype(head_mind.current, /mob/living/silicon/robot))
				// If they're a robot don't count them
				continue

			// Check if they're on the current z-level
			var/turf/T = get_turf_loc(head_mind.current)
			if(T.z != 1)
				continue
			// If they are then don't end the round
			// This return means that they're alive and on the first z level and are not a robot
			return 0
	score_traitorswon = 1
	return 1
/*
	for(var/datum/mind/rev_mind in head_revolutionaries)
		for(var/datum/objective/objective in rev_mind.objectives)
			#ifdef CREW_OBJECTIVES
			if (istype(objective, /datum/objective/crew)) continue
			#endif
			if(!(objective.check_completion()))
				return 0

		return 1
*/

/datum/game_mode/revolution/proc/check_heads_victory()
	if(endthisshit == 1)
		return 0

	for(var/datum/mind/rev_mind in head_revolutionaries)
		if(rev_mind && rev_mind.current && rev_mind.current.stat != 2)

			// Check to see if they're a robot
			if(istype(rev_mind.current, /mob/living/silicon/robot))
				// If they're a robot don't count them
				continue

			var/turf/T = get_turf_loc(rev_mind.current)
			if(T.z != 1)
				continue

			if(istype(T.loc, /area/station/security/brig) && !rev_mind.current.canmove)
				continue

			return 0
	return 1

/datum/game_mode/revolution/proc/check_centcom_victory()

	if (!endthisshit)
		return 0
	return 1


/datum/game_mode/revolution/declare_completion()

	var/text = ""
	if(finished == 1)
		boutput(world, "<span style=\"color:red\"><FONT size = 3><B> The heads of staff were killed or abandoned the station! The revolutionaries win!</B></FONT></span>")
	else if(finished == 2)
		boutput(world, "<span style=\"color:red\"><FONT size = 3><B> The heads of staff managed to stop the revolution!</B></FONT></span>")
	else if(finished == 3)
		boutput(world, "<span style=\"color:red\"><FONT size = 3><B> Everyone was terminated! CentCom wins!</B></FONT></span>")

#ifdef DATALOGGER
	switch(finished)
		if(1)
			game_stats.Increment("traitorwin")
		if(2)
			game_stats.Increment("traitorloss")
#endif

	boutput(world, "<FONT size = 2><B>The head revolutionaries were: </B></FONT>")
	for(var/datum/mind/rev_mind in head_revolutionaries)
		text = ""
		if(rev_mind.current)
			text += "[rev_mind.current.real_name]"
			var/turf/T = get_turf_loc(rev_mind.current)
			if(rev_mind.current.stat == 2)
				text += " (Dead)"
			else if(T.z == 2)
				text += " (Imprisoned!)"
			else if(T.z != 1)
				text += " (Abandoned the cause!)"
			else
				text += " (Survived!)"
		else
			text += "[rev_mind.key] (character destroyed)"

		boutput(world, text)

	text = ""
	boutput(world, "<FONT size = 2><B>The converted revolutionaries were: </B></FONT>")
	for(var/datum/mind/rev_nh_mind in revolutionaries)
		if(rev_nh_mind.current)
			text += "[rev_nh_mind.current.real_name]"
			var/turf/T = get_turf_loc(rev_nh_mind.current)
			if(T.z == 2)
				text += " (Imprisoned!)"
			else if(rev_nh_mind.current.stat == 2)
				text += " (Dead)"
			else if(T.z != 1)
				text += " (Abandoned the cause!)"
			else
				text += " (Survived!)"
		else
			text += "[rev_nh_mind.key] (character destroyed)"
		text += ", "

	boutput(world, text)

	boutput(world, "<FONT size = 2><B>The heads of staff were: </B></FONT>")
	var/list/heads = list()
	heads = get_all_heads()
	for(var/datum/mind/head_mind in heads)
		text = ""
		if(head_mind.current)
			text += "[head_mind.current.real_name]"
			if(head_mind.current.stat == 2)
				text += " (Dead)"
			else
				var/turf/T = get_turf_loc(head_mind.current)
				if(T.z != 1)
					text += " (Abandoned the station!)"
				else
					text += " (Survived!)"
		else
			text += "[head_mind.key] (character destroyed)"

		boutput(world, text)

	..() // Admin-assigned antagonists or whatever.