// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/computer/shuttle
	name = "Shuttle"
	icon_state = "shuttle"
	var/auth_need = 3.0
	var/list/authorized = list(  )
	desc = "A computer that controls the movement of the nearby shuttle."

/obj/machinery/computer/shuttle/embedded
	icon_state = "shuttle-embed"
	density = 0
	layer = EFFECTS_LAYER_1 // Must appear over cockpit shuttle wall thingy.

	north
		dir = NORTH
		pixel_y = 25

	east
		dir = EAST
		pixel_x = 25

	south
		dir = SOUTH
		pixel_y = -25

	west
		dir = WEST
		pixel_x = -25

/obj/machinery/computer/prison_shuttle
	name = "Prison Shuttle"
	icon_state = "shuttle"
	var/active = 0

/obj/machinery/computer/prison_shuttle/embedded
	icon_state = "shuttle-embed"
	density = 0
	layer = EFFECTS_LAYER_1 // Must appear over cockpit shuttle wall thingy.

	north
		dir = NORTH
		pixel_y = 25

	east
		dir = EAST
		pixel_x = 25

	south
		dir = SOUTH
		pixel_y = -25

	west
		dir = WEST
		pixel_x = -25

/obj/machinery/computer/mining_shuttle
	name = "Shuttle Control"
	icon_state = "shuttle"
	var/active = 0

/obj/machinery/computer/mining_shuttle/embedded
	icon_state = "shuttle-embed"
	density = 0
	layer = EFFECTS_LAYER_1 // Must appear over cockpit shuttle wall thingy.

	north
		dir = NORTH
		pixel_y = 25

	east
		dir = EAST
		pixel_x = 25

	south
		dir = SOUTH
		pixel_y = -25

	west
		dir = WEST
		pixel_x = -25

/obj/machinery/computer/research_shuttle
	name = "Shuttle Control"
	icon_state = "shuttle"
	var/active = 0
	var/net_id = null
	var/obj/machinery/power/data_terminal/link = null

/obj/machinery/computer/research_shuttle/embedded
	icon_state = "shuttle-embed"
	density = 0
	layer = EFFECTS_LAYER_1 // Must appear over cockpit shuttle wall thingy.

	north
		dir = NORTH
		pixel_y = 25

	east
		dir = EAST
		pixel_x = 25

	south
		dir = SOUTH
		pixel_y = -25

	west
		dir = WEST
		pixel_x = -25

/obj/machinery/computer/icebase_elevator
	name = "Elevator Control"
	icon_state = "shuttle"
	var/active = 0
	var/location = 1 // 0 for bottom, 1 for top

/obj/machinery/computer/biodome_elevator
	name = "Elevator Control"
	icon_state = "shuttle"
	var/active = 0
	var/location = 1 // 0 for bottom, 1 for top

/obj/machinery/computer/shuttle/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if(emergency_shuttle.location != 1) return

	if (user)
		var/choice = alert(user, "Would you like to launch the shuttle?","Shuttle control", "Launch", "Cancel")
		if(get_dist(user, src) > 1 || emergency_shuttle.location != 1) return
		switch(choice)
			if("Launch")
				boutput(world, "<span style=\"color:blue\"><B>Alert: Shuttle launch time shortened to 10 seconds!</B></span>")
				emergency_shuttle.settimeleft( 10 )
				return 1
			if("Cancel")
				return 1
	else
		boutput(world, "<span style=\"color:blue\"><B>Alert: Shuttle launch time shortened to 10 seconds!</B></span>")
		emergency_shuttle.settimeleft( 10 )
		return 1
	return 0

/obj/machinery/computer/shuttle/attackby(var/obj/item/W as obj, var/mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return
	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if ((!( istype(W, /obj/item/card) ) || !( ticker ) || emergency_shuttle.location != 1 || !( user )))
		return


	if (istype(W, /obj/item/card/id))

		if (!W:access) //no access
			boutput(user, "The access level of [W:registered]\'s card is not high enough. ")
			return

		var/list/cardaccess = W:access
		if(!istype(cardaccess, /list) || !cardaccess.len) //no access
			boutput(user, "The access level of [W:registered]\'s card is not high enough. ")
			return

		if(!(access_heads in W:access)) //doesn't have this access
			boutput(user, "The access level of [W:registered]\'s card is not high enough. ")
			return 0

		var/choice = alert(user, text("Would you like to (un)authorize a shortened launch time? [] authorization\s are still needed. Use abort to cancel all authorizations.", src.auth_need - src.authorized.len), "Shuttle Launch", "Authorize", "Repeal", "Abort")
		if(emergency_shuttle.location != 1 || get_dist(user, src) > 1) return
		switch(choice)
			if("Authorize")
				if(emergency_shuttle.timeleft() < 60)
					boutput(user, "The shuttle is already leaving in less than 60 seconds!")
					return
				src.authorized -= W:registered
				src.authorized += W:registered
				if (src.auth_need - src.authorized.len > 0)
					boutput(world, text("<span style=\"color:blue\"><B>Alert: [] authorizations needed until shuttle is launched early</B></span>", src.auth_need - src.authorized.len))
				else
					boutput(world, "<span style=\"color:blue\"><B>Alert: Shuttle launch time shortened to 60 seconds!</B></span>")
					emergency_shuttle.settimeleft(60)
					//src.authorized = null
					qdel(src.authorized)
					src.authorized = list(  )

			if("Repeal")
				src.authorized -= W:registered
				boutput(world, text("<span style=\"color:blue\"><B>Alert: [] authorizations needed until shuttle is launched early</B></span>", src.auth_need - src.authorized.len))

			if("Abort")
				boutput(world, "<span style=\"color:blue\"><B>All authorizations to shorting time for shuttle launch have been revoked!</B></span>")
				src.authorized.len = 0
				src.authorized = list(  )
	return

/obj/machinery/computer/mining_shuttle/attack_hand(mob/user as mob)
	if(..())
		return
	var/dat = "<a href='byond://?src=\ref[src];close=1'>Close</a><BR><BR>"

	if(miningshuttle_location)
		dat += "Shuttle Location: Station"
	else
		dat += "Shuttle Location: Mining Outpost"
	dat += "<BR>"
	if(active)
		dat += "Moving"
	else
		dat += "<a href='byond://?src=\ref[src];send=1'>Move Shuttle</a><BR><BR>"

	user << browse(dat, "window=shuttle")
	onclose(user, "shuttle")
	return

/obj/machinery/computer/mining_shuttle/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

		if (href_list["send"])
			if(!active)
				for(var/obj/machinery/computer/mining_shuttle/C in machines)
					active = 1
					C.visible_message("<span style=\"color:red\">The Mining Shuttle has been Called and will leave shortly!</span>")
				spawn(100)
					call_shuttle()

		if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=shuttle")

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/mining_shuttle/proc/call_shuttle()
	if(miningshuttle_location == 0)
		var/area/start_location = locate(/area/shuttle/mining/space)
		var/area/end_location = locate(/area/shuttle/mining/station)
		start_location.move_contents_to(end_location)
		miningshuttle_location = 1
	else
		if(miningshuttle_location == 1)
			var/area/start_location = locate(/area/shuttle/mining/station)
			var/area/end_location = locate(/area/shuttle/mining/space)
			start_location.move_contents_to(end_location)
			miningshuttle_location = 0

	for(var/obj/machinery/computer/mining_shuttle/C in machines)
		active = 0
		C.visible_message("<span style=\"color:red\">The Mining Shuttle has Moved!</span>")

	return

/obj/machinery/computer/prison_shuttle/attack_hand(mob/user as mob)
	if(..())
		return
	var/dat = "<a href='byond://?src=\ref[src];close=1'>Close</a><BR><BR>"

	switch(brigshuttle_location)
		if(0)
			dat += "Shuttle Location: Prison Station"
		if(1)
			dat += "Shuttle Location: Station"
			/*
		if(2)
			dat += "Shuttle Location: Research Outpost"
			*/

	dat += "<BR>"
	if(active)
		dat += "Moving"
	else
		dat += "<a href='byond://?src=\ref[src];send=1'>Move Shuttle</a><BR><BR>"

	user << browse(dat, "window=shuttle")
	onclose(user, "shuttle")
	return

/obj/machinery/computer/prison_shuttle/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

		if (href_list["send"])
			if(!active)
				for(var/obj/machinery/computer/prison_shuttle/C in machines)
					active = 1
					C.visible_message("<span style=\"color:red\">The Prison Shuttle has been Called and will leave shortly!</span>")

				spawn(100)
					call_shuttle()

		else if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=shuttle")

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/prison_shuttle/proc/call_shuttle()
	//Prison -> Station -> Outpost -> Prison.
	//Skip outpost if there's a lockdown there.
	//drsingh took outpost out for cogmap prison shuttle
	switch(brigshuttle_location)
		if(0)
			var/area/start_location = locate(/area/shuttle/brig/prison)
			var/area/end_location = locate(/area/shuttle/brig/station)
			start_location.move_contents_to(end_location)
			brigshuttle_location = 1
		if(1)
			var/area/start_location = locate(/area/shuttle/brig/station)
			var/area/end_location = null
			//if(researchshuttle_lockdown)
			end_location = locate(/area/shuttle/brig/prison)
			//else
				//end_location = locate(/area/shuttle/brig/outpost)

			start_location.move_contents_to(end_location)
			//if(researchshuttle_lockdown)
			brigshuttle_location = 0
			//else
				//brigshuttle_location = 2
		/*
		if(2)
			var/area/start_location = locate(/area/shuttle/brig/outpost)
			var/area/end_location = locate(/area/shuttle/brig/prison)
			start_location.move_contents_to(end_location)
			brigshuttle_location = 0
		*/

	for(var/obj/machinery/computer/prison_shuttle/C in machines)
		active = 0
		C.visible_message("<span style=\"color:red\">The Prison Shuttle has Moved!</span>")

	return

/obj/machinery/computer/research_shuttle/New()
	..()
	spawn(5)
		src.net_id = generate_net_id(src)

		if(!src.link)
			var/turf/T = get_turf(src)
			var/obj/machinery/power/data_terminal/test_link = locate() in T
			if(test_link && !test_link.is_valid_master(test_link.master))
				src.link = test_link
				src.link.master = src

/obj/machinery/computer/research_shuttle/attack_hand(mob/user as mob)
	if(..())
		return
	var/dat = "<a href='byond://?src=\ref[src];close=1'>Close</a><BR><BR>"

	if(researchshuttle_location)
		dat += "Shuttle Location: Station"
	else
		dat += "Shuttle Location: Research Outpost"
	dat += "<BR>"
	if(active)
		dat += "Moving"
	else
		dat += "<a href='byond://?src=\ref[src];send=1'>Move Shuttle</a><BR><BR>"

	user << browse(dat, "window=shuttle")
	onclose(user, "shuttle")
	return

/obj/machinery/computer/research_shuttle/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src
		if (href_list["send"])
			for(var/obj/machinery/shuttle/engine/propulsion/eng in machines) // ehh
				if(eng.stat1 == 0 && eng.stat2 == 0 && eng.id == "zeta")
					boutput(usr, "<span style=\"color:red\">Propulsion thruster damaged. Unable to move shuttle.</span>")
					return
				else
					continue

			if(researchshuttle_lockdown)
				boutput(usr, "<span style=\"color:red\">The shuttle cannot be called during lockdown.</span>")
				return

			if(!active)
				for(var/obj/machinery/computer/research_shuttle/C in machines)
					active = 1
					C.visible_message("<span style=\"color:red\">The Research Shuttle has been Called and will leave shortly!</span>")

				spawn(100)
					call_shuttle()

		else if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=shuttle")

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return

/obj/machinery/computer/research_shuttle/proc/call_shuttle()
	if(researchshuttle_lockdown)
		boutput(usr, "<span style=\"color:red\">This shuttle is currently on lockdown and cannot be used.</span>")
		return

	if(researchshuttle_location == 0)
		var/area/start_location = locate(/area/shuttle/research/outpost)
		var/area/end_location = locate(/area/shuttle/research/station)
		start_location.move_contents_to(end_location)
		researchshuttle_location = 1
	else
		if(researchshuttle_location == 1)
			var/area/start_location = locate(/area/shuttle/research/station)
			var/area/end_location = locate(/area/shuttle/research/outpost)
			start_location.move_contents_to(end_location)
			researchshuttle_location = 0

	for(var/obj/machinery/computer/research_shuttle/C in machines)
		active = 0
		C.visible_message("<span style=\"color:red\">The Research Shuttle has Moved!</span>")

	return



/obj/machinery/computer/icebase_elevator/attack_hand(mob/user as mob)
	if(..())
		return
	var/dat = "<a href='byond://?src=\ref[src];close=1'>Close</a><BR><BR>"

	if(location)
		dat += "Elevator Location: Upper level"
	else
		dat += "Elevator Location: Lower Level"
	dat += "<BR>"
	if(active)
		dat += "Moving"
	else
		dat += "<a href='byond://?src=\ref[src];send=1'>Move Elevator</a><BR><BR>"

	user << browse(dat, "window=ice_elevator")
	onclose(user, "ice_elevator")
	return

/obj/machinery/computer/icebase_elevator/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

		if (href_list["send"])
			if(!active)
				for(var/obj/machinery/computer/icebase_elevator/C in machines)
					active = 1
					C.visible_message("<span style=\"color:red\">The elevator begins to move!</span>")
				spawn(50)
					call_shuttle()

		if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=ice_elevator")

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/icebase_elevator/proc/call_shuttle()

	if(location == 0) // at bottom
		var/area/start_location = locate(/area/shuttle/icebase_elevator/lower)
		var/area/end_location = locate(/area/shuttle/icebase_elevator/upper)
		start_location.move_contents_to(end_location, /turf/simulated/floor/plating)
		location = 1
	else // at top
		var/area/start_location = locate(/area/shuttle/icebase_elevator/upper)
		var/area/end_location = locate(/area/shuttle/icebase_elevator/lower)
		for(var/mob/M in end_location) // oh dear, stay behind the yellow line kids
			spawn(1) M.gib()
		start_location.move_contents_to(end_location, /turf/simulated/floor/arctic_elevator_shaft)
		location = 0

	for(var/obj/machinery/computer/icebase_elevator/C in machines)
		active = 0
		C.visible_message("<span style=\"color:red\">The elevator has moved.</span>")
		C.location = src.location

	return

/obj/machinery/computer/biodome_elevator/attack_hand(mob/user as mob)
	if(..())
		return
	var/dat = "<a href='byond://?src=\ref[src];close=1'>Close</a><BR><BR>"

	if(location)
		dat += "Elevator Location: Upper level"
	else
		dat += "Elevator Location: Lower Level"
	dat += "<BR>"
	if(active)
		dat += "Moving"
	else
		dat += "<a href='byond://?src=\ref[src];send=1'>Move Elevator</a><BR><BR>"

	user << browse(dat, "window=ice_elevator")
	onclose(user, "biodome_elevator")
	return

/obj/machinery/computer/biodome_elevator/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src

		if (href_list["send"])
			if(!active)
				for(var/obj/machinery/computer/icebase_elevator/C in machines)
					active = 1
					C.visible_message("<span style=\"color:red\">The elevator begins to move!</span>")
				spawn(50)
					call_shuttle()

		if (href_list["close"])
			usr.machine = null
			usr << browse(null, "window=biodome_elevator")

	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return


/obj/machinery/computer/biodome_elevator/proc/call_shuttle()

	if(location == 0) // at bottom
		var/area/start_location = locate(/area/shuttle/biodome_elevator/lower)
		var/area/end_location = locate(/area/shuttle/biodome_elevator/upper)
		start_location.move_contents_to(end_location, /turf/simulated/floor/plating)
		location = 1
	else // at top
		var/area/start_location = locate(/area/shuttle/biodome_elevator/upper)
		var/area/end_location = locate(/area/shuttle/biodome_elevator/lower)
		for(var/mob/M in end_location) // oh dear, stay behind the yellow line kids
			spawn(1) M.gib()
		start_location.move_contents_to(end_location, /turf/unsimulated/floor/setpieces/ancient_pit/shaft)
		location = 0

	for(var/obj/machinery/computer/biodome_elevator/C in machines)
		active = 0
		C.visible_message("<span style=\"color:red\">The elevator has moved.</span>")
		C.location = src.location

	return