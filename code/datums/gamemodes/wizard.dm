// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/game_mode/wizard
	name = "wizard"
	config_tag = "wizard"
	shuttle_available = 2
	latejoin_antag_compatible = 1
	latejoin_only_if_all_antags_dead = 1
	latejoin_antag_roles = list("changeling", "vampire")

	var/const/wizards_possible = 5
	var/finished = 0

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)

/datum/game_mode/wizard/announce()
	boutput(world, "<B>The current game mode is - Wizard!</B>")
	boutput(world, "<B>There is a <span style=\"color:red\">SPACE WIZARD</span> on the station. You can't let him achieve his objective!</B>")

/datum/game_mode/wizard/pre_setup()

	var/num_players = 0
	for(var/mob/new_player/player in mobs)
		if(player.client && player.ready) num_players++

	var/num_wizards = max(1, min(round(num_players / 12), wizards_possible))

	var/list/possible_wizards = get_possible_wizards(num_wizards)

	if (!possible_wizards.len)
		return 0

	token_players = antag_token_list()
	for(var/datum/mind/tplayer in token_players)
		if (!token_players.len)
			break
		src.traitors += tplayer
		token_players.Remove(tplayer)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")
		/*--num_wizards
		num_wizards = max(num_wizards, 0)*/

	for(var/j = 0, j < num_wizards, j++)
		var/datum/mind/wizard = pick(possible_wizards)
		src.traitors += wizard
		possible_wizards.Remove(wizard)

	for(var/datum/mind/wiz_mind in src.traitors)
		wiz_mind.assigned_role = "MODE"
	return 1

/datum/game_mode/wizard/post_setup()

	for(var/datum/mind/wizard in src.traitors)
		if(!wizard || !istype(wizard))
			src.traitors.Remove(wizard)
			continue
		if(istype(wizard))
			wizard.special_role = "wizard"
			if(wizardstart.len == 0)
				boutput(wizard.current, "<B><span style=\"color:red\">A starting location for you could not be found, please report this bug!</span></B>")
			else
				var/starting_loc = pick(wizardstart)
				wizard.current.set_loc(starting_loc)
			bestow_objective(wizard,/datum/objective/regular/assassinate)
			bestow_objective(wizard,/datum/objective/regular/assassinate)
			bestow_objective(wizard,/datum/objective/regular/assassinate)

			wizard.current.antagonist_overlay_refresh(1, 0)

			equip_wizard(wizard.current)
			boutput(wizard.current, "<B><span style=\"color:red\">You are a Wizard!</span></B>")
			boutput(wizard.current, "<B>The Space Wizards Federation has sent you to perform a ritual on the station:</B>")

			var/obj_count = 1
			for(var/datum/objective/objective in wizard.objectives)
				boutput(wizard.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
				obj_count++
			boutput(wizard.current, "<B>Complete all steps of the ritual, and the Dark Gods shall have the station! Work together with any partner you may have!</B>")

	for(var/datum/mind/wizard in src.traitors)
		var/randomname
		if (wizard.current.gender == "female") randomname = pick(wiz_female)
		else randomname = pick(wiz_male)
		spawn(0)
			var/newname = adminscrub(input(wizard.current,"You are a Wizard. Would you like to change your name to something else?", "Name change",randomname) as text)

			if (length(ckey(newname)) == 0)
				newname = randomname

			if (newname)
				if (length(newname) >= 26) newname = copytext(newname, 1, 26)
				newname = replacetext(newname, ">", "'")
				wizard.current.real_name = newname
				wizard.current.name = newname

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

/datum/game_mode/wizard/proc/get_possible_wizards(minimum_wizards=1)

	var/list/candidates = list()

	for(var/mob/new_player/player in mobs)
		if (ishellbanned(player)) continue //No treason for you
		if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if(player.client.preferences.be_wizard)
				candidates += player.mind

	if(candidates.len < minimum_wizards)
		logTheThing("debug", null, null, "<b>Enemy Assignment</b>: Only [candidates.len] players with be_wizard set to yes. We need [minimum_wizards], so including players who don't want to be wizards in the pool.")
		for(var/mob/new_player/player in mobs)
			if (ishellbanned(player)) continue //No treason for you
			if ((player.client) && (player.ready) && !(player.mind in traitors) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_wizards > 1) && (candidates.len >= minimum_wizards))
					break

	if(candidates.len < 1)
		return list()
	else
		return candidates

/datum/game_mode/wizard/send_intercept()
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
		intercepttext += i_text.build(A, pick(src.traitors))
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

/datum/game_mode/wizard/proc/get_mob_list()
	var/list/mobs = list()
	for(var/mob/living/player in mobs)
		if (player.client)
			mobs += player
	return mobs

/datum/game_mode/wizard/proc/pick_human_name_except(excluded_name)
	var/list/names = list()
	for(var/mob/living/player in mobs)
		if (player.client && (player.real_name != excluded_name))
			names += player.real_name
	if(!names.len)
		return null
	return pick(names)

datum/game_mode/wizard/check_finished()

	if(emergency_shuttle.location == 2)
		return 1

	if (no_automatic_ending)
		return 0

	return 0

//	OK fuck this shit
/*	//Latejoin bad guys come now if all the wizards are dead rather than the round ending.

	var/wizcount = 0
	//var/wizdeathcount = 0
	var/wincount = 0

	if(ticker.mode.Agimmicks.len > 0)
		for(var/datum/mind/W in ticker.mode.Agimmicks)
			if(!(W in src.traitors))
				wizards += W

	for (var/datum/mind/W in wizards)
		wizcount++
		var/objectives_completed = 0
		for(var/datum/objective/objective in W.objectives)
			if(objective.check_completion()) objectives_completed++
		if(objectives_completed == W.objectives.len) wincount++
		//if(!W.current || W.current.stat == 2) wizdeathcount++

	//if (wizcount == wizdeathcount) return 1
	if (wizcount == wincount)
		boutput(world, "wizcount [wizcount], wincount [wincount], ending round")
		return 1

	else return 0*/