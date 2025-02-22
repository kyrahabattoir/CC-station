// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/game_mode/nuclear
	name = "nuclear emergency"
	config_tag = "nuclear"
	shuttle_available = 2
	var/target_location_name = null // The name of our target area. Used for text output.
	var/list/target_location_type = list() // Our area.type, which can be multiple (e.g. medbay).

	var/list/datum/mind/syndicates = list()
	var/finished = 0
	var/nuke_detonated = 0 //Has the nuke gone off?
	var/agent_radiofreq = 0 //:h for syndies, randomized per round
	var/agent_number = 1
	var/obj/machinery/nuclearbomb/the_bomb = null
	var/bomb_check_timestamp = 0 // See check_finished().
	var/const/agents_possible = 6 //If we ever need more syndicate agents. cogwerks - raised from 5

	var/const/waittime_l = 600 //lower bound on time before intercept arrives (in tenths of seconds)
	var/const/waittime_h = 1800 //upper bound on time before intercept arrives (in tenths of seconds)
	var/token_players_assigned = 0

/datum/game_mode/nuclear/announce()
	boutput(world, "<B>The current game mode is - Nuclear Emergency!</B>")
	boutput(world, "<B>[syndicate_name()] operatives are approaching [map_setting == "DESTINY" ? "the " : null][station_name()]! They intend to destroy the [map_setting == "DESTINY" ? "ship" : "station"] with a nuclear warhead.</B>")

/datum/game_mode/nuclear/pre_setup()
	var/the_spawn = syndicatestart && islist(syndicatestart) && syndicatestart.len ? pick(syndicatestart) : null
	var/list/possible_syndicates = list()

	if (!the_spawn)
		boutput(world, "<span style='color:red'><b>ERROR: couldn't find Syndicate spawn landmark, aborting nuke round pre-setup.</b></span>")
		return 0

	var/num_players = 0
	for (var/mob/new_player/player in mobs)
		if (player.client && player.ready)
			num_players++

	var/num_synds = max(1, min(round(num_players / 4), agents_possible))

	possible_syndicates = get_possible_syndicates(num_synds)

	if (!islist(possible_syndicates) || possible_syndicates.len < 1)
		boutput(world, "<span style='color:red'><b>ERROR: couldn't assign any players as Syndicate operatives, aborting nuke round pre-setup.</b></span>")
		return 0

	// I wandered in and made things hopefully a bit easier to work with since we have multiple maps now - Haine
	var/list/target_locations = null

	if (map_setting == "COG2")
		target_locations = list("the main security room" = list(/area/station/security/main),
		"the central research sector hub" = list(/area/station/science),
		"the cargo bay (QM)" = list(/area/station/quartermaster/office),
		"the thermo-electric generator room" = list(/area/station/engine/core),
		"the refinery (arc smelter)" = list(/area/station/quartermaster/refinery),
		"the medbay" = list(/area/station/medical/medbay, /area/station/medical/medbay/surgery),
		"the station's cafeteria" = list(/area/station/crew_quarters/cafeteria),
		"the net cafe" = list(/area/station/crew_quarters/info),
		"the artifact lab" = list(/area/station/artifact),
		"the genetics lab" = list(/area/station/medical/research))

	else if (map_setting == "DESTINY")
		target_locations = list("the main security room" = list(/area/station/security/main),
		"the central research sector hub" = list(/area/station/science),
		"the cargo bay (QM)" = list(/area/station/quartermaster/office),
		"the thermo-electric generator room" = list(/area/station/engine/core),
		"the refinery (arc smelter)" = list(/area/station/mining/refinery),
		"the courtroom" = list(/area/station/crew_quarters/courtroom),
		"the medbay" = list(/area/station/medical/medbay, /area/station/medical/medbay/lobby),
		"the bar" = list(/area/station/crew_quarters/bar),
		"the EVA storage" = list(/area/station/ai_monitored/storage/eva),
		"the artifact lab" = list(/area/station/artifact),
		"the robotics lab" = list(/area/station/medical/robotics))

	else // COG1
		target_locations = list("the main security room" = list(/area/station/security/main),
		"the central research sector hub" = list(/area/station/science),
		"the cargo bay (QM)" = list(/area/station/quartermaster/office),
		"the engineering control room" = list(/area/station/engine/engineering, /area/station/engine/power),
		"the central warehouse" = list(/area/station/storage/warehouse),
		"the courtroom" = list(/area/station/crew_quarters/courtroom, /area/station/crew_quarters/juryroom),
		"the medbay" = list(/area/station/medical/medbay, /area/station/medical/medbay/surgery, /area/station/medical/medbay/lobby),
		"the station's cafeteria" = list(/area/station/crew_quarters/cafeteria),
		"the EVA storage" = list(/area/station/ai_monitored/storage/eva),
		"the robotics lab" = list(/area/station/medical/robotics),
		"the public pool" = list(/area/station/crew_quarters/pool)) // Don't ask, it just fits all criteria. Deathstar weakness or something.

	if (!target_locations.len)
		target_locations = list("the station (anywhere)" = list(/area/station))
		message_admins("<span style ='color:red'><b>CRITICAL BUG:</b> nuke mode setup encountered an error while trying to choose a target location for the bomb and the target has defaulted to anywhere on the station! The round will be able to be played like this but it will be unbalanced! Please inform a coder!")
		logTheThing("debug", null, null, "<b>CRITICAL BUG:</b> nuke mode setup encountered an error while trying to choose a target location for the bomb and the target has defaulted to anywhere on the station.")

	target_location_name = pick(target_locations)
	if (!target_location_name)
		boutput(world, "<span style='color:red'><b>ERROR: couldn't assign target location for bomb, aborting nuke round pre-setup.</b></span>")
		message_admins("<span style ='color:red'><b>CRITICAL BUG:</b> nuke mode setup encountered an error while trying to choose a target location for the bomb (could not select area name)!")
		return 0

	target_location_type = target_locations[target_location_name]
	if (!target_location_type)
		boutput(world, "<span style='color:red'><b>ERROR: couldn't assign target location for bomb, aborting nuke round pre-setup.</b></span>")
		message_admins("<span style ='color:red'><b>CRITICAL BUG:</b> nuke mode setup encountered an error while trying to choose a target location for the bomb (could not select area type)!")
		return 0

	// now that we've done everything that could cause the round to fail to start (in this proc, at least), we can deal with antag tokens
	token_players = antag_token_list()
	for (var/datum/mind/tplayer in token_players)
		if (!token_players.len)
			break
		syndicates += tplayer
		token_players.Remove(tplayer)
		num_synds--
		num_synds = max(num_synds, 0)
		logTheThing("admin", tplayer.current, null, "successfully redeemed an antag token.")
		message_admins("[key_name(tplayer.current)] successfully redeemed an antag token.")

	for (var/j = 0, j < num_synds, j++)
		var/datum/mind/syndicate = pick(possible_syndicates)
		syndicates += syndicate
		possible_syndicates.Remove(syndicate)

	for (var/datum/mind/synd_mind in syndicates)
		synd_mind.assigned_role = "MODE" //So they aren't chosen for other jobs.
		synd_mind.special_role = "nukeop"

	agent_radiofreq = random_radio_frequency()

	return 1

/datum/game_mode/nuclear/post_setup()
	var/synd_spawn = pick(syndicatestart)
	var/obj/landmark/nuke_spawn = locate("landmark*Nuclear-Bomb")
	var/obj/landmark/closet_spawn = locate("landmark*Nuclear-Closet")

	var/leader_title = pick("Czar", "Boss", "Commander", "Chief", "Kingpin", "Director", "Overlord", "General", "Warlord")
	var/leader_selected = 0

	for(var/datum/mind/synd_mind in syndicates)
		synd_spawn = pick(syndicatestart) // So they don't all spawn on the same tile.
		synd_mind.current.set_loc(synd_spawn)

		bestow_objective(synd_mind,/datum/objective/specialist/nuclear)

		var/obj_count = 1
		boutput(synd_mind.current, "<span style=\"color:blue\">You are a [syndicate_name()] agent!</span>")
		for(var/datum/objective/objective in synd_mind.objectives)
			boutput(synd_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			obj_count++

		synd_mind.store_memory("The bomb must be armed in <B>[src.target_location_name]</B>.", 0, 0)
		boutput(synd_mind.current, "We have identified a major structural weakness in the [map_setting == "DESTINY" ? "ship" : "station"]'s design. Arm the bomb in <B>[src.target_location_name]</B> to obliterate [map_setting == "DESTINY" ? "the " : null][station_name()].")

		equip_syndicate(synd_mind.current)

		if(!leader_selected)
			synd_mind.current.real_name = "[syndicate_name()] [leader_title]"
			new /obj/item/device/audio_log/nuke_briefing(synd_mind.current.loc, target_location_name)
			if (ishuman(synd_mind.current))
				var/mob/living/carbon/human/M = synd_mind.current
				M.equip_if_possible(new /obj/item/pinpointer/disk(M), M.slot_in_backpack)
			else
				new /obj/item/pinpointer/disk(synd_mind.current.loc)
			leader_selected = 1
		else
			synd_mind.current.real_name = "[syndicate_name()] Operative #[agent_number]"
			agent_number++
		boutput(synd_mind.current, "<span style=\"color:red\">Your headset allows you to communicate on the syndicate radio channel by prefacing messages with :h, as (say \":h Agent reporting in!\").</span>")

		synd_mind.current.antagonist_overlay_refresh(1, 0)
		synd_mind.current << browse(grabResource("html/traitorTips/syndiTips.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")

	if(nuke_spawn)
		the_bomb = new /obj/machinery/nuclearbomb(nuke_spawn.loc)

	if(closet_spawn)
		new /obj/storage/closet/syndicate/nuclear(closet_spawn.loc)

	for (var/obj/landmark/A in world)
		if (A.name == "Syndicate-Gear-Closet")
			new /obj/storage/closet/syndicate/personal(A.loc)
			qdel(A)
			continue

		if (A.name == "Syndicate-Bomb")
			new /obj/spawner/newbomb/timer/syndicate(A.loc)
			qdel(A)
			continue

		if (A.name == "Breaching-Charges")
			new /obj/item/breaching_charge/thermite(A.loc)
			new /obj/item/breaching_charge/thermite(A.loc)
			new /obj/item/breaching_charge/thermite(A.loc)
			new /obj/item/breaching_charge/thermite(A.loc)
			new /obj/item/breaching_charge/thermite(A.loc)
			qdel(A)
			continue

	spawn (rand(waittime_l, waittime_h))
		send_intercept()

	return

/datum/game_mode/nuclear/check_finished()
	// First ticker.process() call runs before the bomb is actually spawned.
	if (src.bomb_check_timestamp == 0)
		src.bomb_check_timestamp = world.time

	if (src.finished)
		return 1

	if (src.nuke_detonated)
		finished = -2
		return 1

	if (emergency_shuttle.location == 2)
		if (the_bomb && the_bomb.armed)
			// Minor Syndicate Victory - crew escaped but bomb was armed and counting down
			finished = -1
			return 1
		if ((!the_bomb || (the_bomb && !the_bomb.armed)))
			if (all_operatives_dead())
				// Major Station Victory - bombing averted, all operatives dead/captured
				finished = 2
				return 1
			else
				// Minor Station Victory - bombing averted, but operatives escaped
				finished = 1
				return 1

	if (no_automatic_ending)
		return 0

	if (the_bomb && the_bomb.armed && the_bomb.det_time)
		// don't end the game if the bomb is armed and counting, even if the ops are all dead
		return 0

	if (all_operatives_dead())
		finished = 2
		// Major Station Victory - bombing averted, all operatives dead/captured
		return 1

	// Minor or major Station Victory - bombing averted in any case.
	if (src.bomb_check_timestamp && world.time > src.bomb_check_timestamp + 300)
		if (!src.the_bomb || !istype(src.the_bomb, /obj/machinery/nuclearbomb))
			if (src.all_operatives_dead())
				finished = 2
			else
				finished = 1
			return 1

	return 0

/datum/game_mode/nuclear/declare_completion()
	switch(finished)
		if(-2) // Major Synd Victory - nuke successfully detonated
			boutput(world, "<FONT size = 3><B>Total Syndicate Victory</B></FONT>")
			boutput(world, "The operatives have destroyed [map_setting == "DESTINY" ? "the " : null][station_name()]!")
			score_nuked = 1
#ifdef DATALOGGER
			game_stats.Increment("traitorwin")
			score_traitorswon += 1
#endif
		if(-1) // Minor Synd Victory - station abandoned while nuke armed
			boutput(world, "<FONT size = 3><B>Syndicate Victory</B></FONT>")
			boutput(world, "The crew of [map_setting == "DESTINY" ? "the " : null][station_name()] abandoned the station while the bomb was armed! [map_setting == "DESTINY" ? "The " : null][station_name()] will surely be destroyed!")
			score_nuked = 1
#ifdef DATALOGGER
			game_stats.Increment("traitorwin")
			score_traitorswon += 1
#endif
		if(0) // Uhhhhhh
			boutput(world, "<FONT size = 3><B>Stalemate</B></FONT>")
			boutput(world, "Everybody loses!")
		if(1) // Minor Crew Victory - station evacuated, bombing averted, operatives survived
			boutput(world, "<FONT size = 3><B>Crew Victory</B></FONT>")
			boutput(world, "The crew of [map_setting == "DESTINY" ? "the " : null][station_name()] averted the bombing! However, some of the operatives survived.")
#ifdef DATALOGGER
			game_stats.Increment("traitorloss")
#endif
		if(2) // Major Crew Victory - bombing averted, all ops dead/captured
			boutput(world, "<FONT size = 3><B>Total Crew Victory</B></FONT>")
			boutput(world, "The crew of [map_setting == "DESTINY" ? "the " : null][station_name()] averted the bombing and eliminated all Syndicate operatives!")
#ifdef DATALOGGER
			game_stats.Increment("traitorloss")
#endif

	for(var/datum/mind/M in syndicates)
		var/syndtext = ""
		if(M.current) syndtext += "<B>[M.key] played [M.current.real_name].</B> "
		else syndtext += "<B>[M.key] played an operative.</B> "
		if (!M.current) syndtext += "(Destroyed)"
		else if (M.current.stat == 2) syndtext += "(Killed)"
		else if (M.current.z != 1) syndtext += "(Missing)"
		else syndtext += "(Survived)"
		boutput(world, syndtext)

		for (var/datum/objective/objective in M.objectives)
#ifdef CREW_OBJECTIVES
			if (istype(objective, /datum/objective/crew)) continue
#endif
			if (istype(objective, /datum/objective/miscreant)) continue

			if (objective.check_completion())
				if (!isnull(objective.medal_name) && !isnull(M.current))
					M.current.unlock_medal(objective.medal_name, objective.medal_announce)

	..() //Listing custom antagonists.

/datum/game_mode/nuclear/proc/all_operatives_dead()
	var/opcount = 0
	var/opdeathcount = 0
	for(var/datum/mind/M in syndicates)
		opcount++
		if(!M.current || M.current.stat == 2)
			opdeathcount++ // If they're dead
			continue
		else if(istype(M.current, /mob/living/silicon/robot))
			opdeathcount++
			continue

		var/turf/T = get_turf(M.current)
		if (!T)
			continue
		if (istype(T.loc, /area/station/security/brig))
			if(M.current.handcuffed != null)
				opdeathcount++
				// If they're in a brig cell and cuffed

	if (opcount == opdeathcount) return 1
	else return 0

/datum/game_mode/nuclear/proc/get_possible_syndicates(minimum_syndicates=1)
	var/list/candidates = list()

	for(var/mob/new_player/player in mobs)
		if (ishellbanned(player)) continue //No treason for you
		if ((player.client) && (player.ready) && !(player.mind in syndicates) && !(player.mind in token_players) && !candidates.Find(player.mind))
			if(player.client.preferences.be_syndicate)
				candidates += player.mind

	if(candidates.len < minimum_syndicates)
		logTheThing("debug", null, null, "<b>Enemy Assignment</b>: Not enough players with be_syndicate set to yes, including players who don't want to be syndicates in the pool.")
		for(var/mob/new_player/player in mobs)
			if (ishellbanned(player)) continue //No treason for you
			if ((player.client) && (player.ready) && !(player.mind in syndicates) && !(player.mind in token_players) && !candidates.Find(player.mind))
				candidates += player.mind

				if ((minimum_syndicates > 1) && (candidates.len >= minimum_syndicates))
					break

	if(candidates.len < 1)
		return list()
	else
		return candidates

/datum/game_mode/nuclear/send_intercept()
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
		intercepttext += i_text.build(A, pick(ticker.minds))

	for (var/obj/machinery/communications_dish/C in machines)
		C.add_centcom_report("Cent. Com. Status Summary", intercepttext)

	command_alert("Summary downloaded and printed out at all communications consoles.", "Enemy communication intercept. Security Level Elevated.")


/datum/game_mode/nuclear/proc/random_radio_frequency()
	var/f = 0
	var/list/blacklisted = list(0, 1451, 1457) // The old blacklist was rather incomplete and thus ineffective (Convair880).
	blacklisted.Add(R_FREQ_BLACKLIST_HEADSET)
	blacklisted.Add(R_FREQ_BLACKLIST_INTERCOM)

	do
		f = rand(1352, 1439)

	while (blacklisted.Find(f))

	return f

/datum/game_mode/nuclear/process()
	set background = 1
	..()
	return

var/syndicate_name = null
/proc/syndicate_name()
	if (syndicate_name)
		return syndicate_name

	var/name = ""

	// Prefix
#ifdef XMAS
	name += pick("Merry", "Jingle", "Holiday", "Santa", "Gift", "Elf", "Jolly")
#else
	name += pick("Clandestine", "Prima", "Blue", "Zero-G", "Max", "Blasto", "Waffle", "North", "Omni", "Newton", "Cyber", "Bonk", "Gene", "Gib", "Funk", "Joint")
#endif
	// Suffix
	if (prob(80))
		name += " "

		// Full
		if (prob(60))
			name += pick("Syndicate", "Consortium", "Collective", "Corporation", "Consolidated", "Group", "Holdings", "Biotech", "Industries", "Systems", "Products", "Chemicals", "Enterprises", "Family", "Creations", "International", "Intergalactic", "Interplanetary", "Foundation", "Positronics", "Hive", "Cartel")
		// Broken
		else
			name += pick("Syndi", "Corp", "Bio", "System", "Prod", "Chem", "Inter", "Hive")
			name += pick("", "-")
			name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Code")
	// Small
	else
		name += pick("-", "*", "")
		name += pick("Tech", "Sun", "Co", "Tek", "X", "Inc", "Gen", "Star", "Dyne", "Code", "Hive")

	syndicate_name = name
	return name