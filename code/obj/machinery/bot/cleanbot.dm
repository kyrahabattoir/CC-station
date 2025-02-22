// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// WIP bot improvements (Convair880).

////////////////////////////////////////////// Cleanbot assembly ///////////////////////////////////////
/obj/item/bucket_sensor
	desc = "It's a bucket. With a sensor attached."
	name = "proxy bucket"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "bucket_proxy"
	force = 3.0
	throwforce = 10.0
	throw_speed = 2
	throw_range = 5
	w_class = 3.0
	flags = TABLEPASS

	attackby(var/obj/item/parts/robot_parts/P, mob/user as mob)
		if (!istype(P, /obj/item/parts/robot_parts/arm/))
			return

		var/obj/machinery/bot/cleanbot/A = new /obj/machinery/bot/cleanbot
		if (user.r_hand == src || user.l_hand == src)
			A.set_loc(get_turf(user))
		else
			A.set_loc(get_turf(src))

		boutput(user, "You add the robot arm to the bucket and sensor assembly! Beep boop!")
		qdel(P)
		qdel(src)
		return

///////////////////////////////////////////////// Cleanbot ///////////////////////////////////////
/obj/machinery/bot/cleanbot
	name = "cleanbot"
	desc = "A little cleaning robot, he looks so excited!"
	icon = 'icons/obj/aibots.dmi'
	icon_state = "cleanbot0"
	layer = 5
	density = 0
	anchored = 0

	on = 1
	locked = 1
	health = 25
	no_camera = 1
	access_lookup = "Janitor"

	var/target // Current target.
	var/list/path = null // Path to current target.
	var/list/targets_invalid = list() // Targets we weren't able to reach.
	var/clear_invalid_targets = 1 // In relation to world time. Clear list periodically.
	var/clear_invalid_targets_interval = 1800 // How frequently?
	var/frustration = 0 // Simple counter. Bot selects new target if current one is too far away.

	var/idle = 1 // In relation to world time. In case there aren't any valid targets nearby.
	var/idle_delay = 300 // For how long?

	var/cleaning = 0 // Are we currently cleaning something?
	var/reagent_normal = "cleaner"
	var/reagent_emagged = "lube"
	var/list/lubed_turfs = list() // So we don't lube the same turf ad infinitum.
	var/datum/light/light

	New()
		..()
		light = new /datum/light/point
		light.attach(src)
		light.set_brightness(0.4)

		spawn (5)
			if (src)
				src.botcard = new /obj/item/card/id(src)
				src.botcard.access = get_access(src.access_lookup)
				src.clear_invalid_targets = world.time

				var/datum/reagents/R = new /datum/reagents(50)
				src.reagents = R
				R.my_atom = src

				if (src.emagged)
					R.add_reagent(src.reagent_emagged, 50)
				else
					R.add_reagent(src.reagent_normal, 50)

				src.toggle_power(1)
		return

	examine()
		set src in view()
		..()

		if (src.health < initial(health))
			if (src.health > (initial(src.health) / 2))
				boutput(usr, text("<span style=\"color:red\">[src]'s parts look loose.</span>"))
			else
				boutput(usr, text("<span style=\"color:red\"><B>[src]'s parts look very loose!</B></span>"))
		return

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!src.emagged)
			if (user && ismob(user))
				src.emagger = user
				src.add_fingerprint(user)
				user.show_text("You short out [src]'s waste disposal circuits.", "red")
				for (var/mob/O in hearers(src, null))
					O.show_message("<span style=\"color:red\"><B>[src] buzzes oddly!</B></span>", 1)

			src.emagged = 1
			src.toggle_power(1)

			if (src.reagents)
				src.reagents.clear_reagents()
				src.reagents.add_reagent(src.reagent_emagged, 50)

			logTheThing("station", src.emagger, null, "emagged a [src.name], setting it to spread [src.reagent_emagged] at [log_loc(src)].")
			return 1

		return 0

	demag(var/mob/user)
		if (!src.emagged)
			return 0
		if (user)
			user.show_text("You repair [src]'s waste disposal circuits.", "blue")
		src.emagged = 0
		return 1

	emp_act()
		..()
		if (!src.emagged && prob(75))
			src.emag_act(usr && ismob(usr) ? usr : null, null)
		else
			src.explode()
		return

	proc/toggle_power(var/force_on = 0)
		if (!src)
			return

		if (force_on == 1)
			src.on = 1
		else
			src.on = !src.on

		src.anchored = 0
		src.target = null
		src.icon_state = "cleanbot[src.on]"
		src.path = null
		src.targets_invalid = list() // Turf vs decal when emagged, so we gotta clear it.
		src.lubed_turfs = list()
		src.clear_invalid_targets = world.time

		if (src.on)
			light.enable()
		else
			light.disable()

		return

	attack_hand(user as mob)
		src.add_fingerprint(user)
		var/dat = ""

		dat += "<tt><b>Automatic Station Cleaner v1.1</b></tt>"
		dat += "<br>"
		dat += "Status: <A href='?src=\ref[src];start=1'>[src.on ? "On" : "Off"]</A><br>"

		user << browse(dat, "window=autocleaner")
		onclose(user, "autocleaner")
		return

	attack_ai(mob/user as mob)
		if (src.on && src.emagged)
			boutput(user, "[src] refuses your authority!", "red")
			return

		src.toggle_power(0)
		return

	Topic(href, href_list)
		if (..()) return
		if (usr.stunned || usr.weakened || usr.stat || usr.restrained()) return
		if (!issilicon(usr) && !in_range(src, usr)) return

		src.add_fingerprint(usr)
		usr.machine = src

		if (href_list["start"])
			src.toggle_power(0)

		src.updateUsrDialog()
		return

	attackby(obj/item/W, mob/user as mob)
		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WT = W
			if (!WT.welding)
				return
			if (src.health < initial(src.health))
				if (WT.get_fuel() > 2)
					WT.use_fuel(1)
					src.health = initial(src.health)
					src.visible_message("<span style=\"color:red\"><b>[user]</b> repairs the damage on [src].</span>")
				else
					user.show_text("Need more welding fuel!", "red")
					return

		else
			..()
			switch(W.damtype)
				if("fire")
					src.health -= W.force * 0.75
				if("brute")
					src.health -= W.force * 0.5
			if (src.health <= 0)
				src.explode()

		return

	process()
		if (!src.on)
			return

		if (src.cleaning)
			return

		// We're still idling.
		if (src.idle && world.time < src.idle + src.idle_delay)
			//DEBUG_MESSAGE("Sleeping. [log_loc(src)]")
			return

		// Invalid targets may not be unreachable anymore. Clear list periodically.
		if (src.clear_invalid_targets && world.time > src.clear_invalid_targets + src.clear_invalid_targets_interval)
			src.targets_invalid = list()
			src.lubed_turfs = list()
			src.clear_invalid_targets = world.time
			//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Cleared target_invalid. [log_loc(src)]")

		if (src.frustration >= 8)
			//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Selecting new target (frustration). [log_loc(src)]")
			if (src.target && !(src.target in src.targets_invalid))
				src.targets_invalid += src.target
			src.frustration = 0
			src.target = null

		// So nearby bots don't go after the same mess.
		var/list/cleanbottargets = list()
		if (!src.target || src.target == null)
			for (var/obj/machinery/bot/cleanbot/bot in machines)
				if (bot != src)
					if (bot.target && !(bot.target in cleanbottargets))
						cleanbottargets += bot.target

		// Let's find us something to clean.
		if (!src.target || src.target == null)
			if (src.emagged)
				for (var/turf/simulated/floor/F in view(7, src))
					if (F in targets_invalid)
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (target_invalid). [F] [log_loc(F)]")
						continue
					if (F in cleanbottargets)
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (other bot target). [F] [log_loc(F)]")
						continue
					if (F in src.lubed_turfs)
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (lubed). [F] [log_loc(F)]")
						continue
					for (var/atom/A in F.contents)
						if (A.density && !(A.flags & ON_BORDER) && !istype(A, /obj/machinery/door) && !ismob(A))
							if (!(F in src.targets_invalid))
								//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (density). [F] [log_loc(F)]")
								src.targets_invalid += F
							continue

					src.target = F
					//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Target acquired. [F] [log_loc(F)]")
					break
			else
				for (var/obj/decal/cleanable/D in view(7, src))
					if (D in targets_invalid)
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (target_invalid). [D] [log_loc(D)]")
						continue
					if (D in cleanbottargets)
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (other bot target). [D] [log_loc(D)]")
						continue

					src.target = D
					//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Target acquired. [D] [log_loc(D)]")
					break

		// Still couldn't find one? Abort and retry later.
		if (!src.target || src.target == null)
			//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (no valid targets). [log_loc(src)]")
			src.idle = world.time
			return

		// Let's find us a path to the target.
		if (src.target && (!src.path || !src.path.len))
			spawn(0)
				if (!src)
					return

				var/turf/T = get_turf(src.target)
				if (!isturf(src.loc) || !T || !isturf(T) || T.density)
					if (!(src.target in src.targets_invalid))
						src.targets_invalid += src.target
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (target density). [T] [log_loc(T)]")
					src.target = null
					return

				if (istype(T, /turf/space))
					if (!(src.target in src.targets_invalid))
						src.targets_invalid += src.target
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (space tile). [T] [log_loc(T)]")
					src.target = null
					return

				for (var/atom/A in T.contents)
					if (A.density && !(A.flags & ON_BORDER) && !istype(A, /obj/machinery/door) && !ismob(A))
						if (!(src.target in src.targets_invalid))
							src.targets_invalid += src.target
							//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Acquiring target failed (obstruction). [T] [log_loc(T)]")
						src.target = null
						return

				src.path = AStar(get_turf(src), get_turf(src.target), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, adjacent_param = botcard)

				if (!src.path) // Woops, couldn't find a path.
					if (!(src.target in src.targets_invalid))
						src.targets_invalid += src.target
						//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Pathfinding failed. [T] [log_loc(T)]")
					src.target = null
					return

		// Move towards the target.
		if (src.path && src.path.len && src.target && (src.target != null))
			if (src.path.len > 8)
				src.frustration++
			step_to(src, src.path[1])
			if (src.loc == src.path[1])
				src.path -= src.path[1]
			else
				src.frustration++
				sleep (10)

			spawn (3)
				if (src && src.path && src.path.len)
					if (src.path.len > 8)
						src.frustration++
					step_to(src, src.path[1])
					if (src.loc == src.path[1])
						src.path -= src.path[1]
					else
						src.frustration++
			//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Moving towards target. [src.target] [log_loc(src.target)]")

		if (src.target)
			if (src.loc == get_turf(src.target))
				clean(src.target)
				src.path = null
				src.target = null
				return

		return

	proc/clean(var/obj/target)
		if (!src || !target)
			return
		var/turf/T = get_turf(target)
		if (!T || !isturf(T))
			return

		src.anchored = 1
		src.icon_state = "cleanbot-c"
		src.visible_message("<span style=\"color:red\">[src] begins to clean the [target.name].</span>")
		src.cleaning = 1
		//DEBUG_MESSAGE("[src.emagged ? "(E) " : ""]Cleaning target. [src.target] [log_loc(src.target)]")

		spawn(50)
			if (src)
				src.reagents.reaction(T, 1, 10)

				if (src.emagged)
					if (!(T in src.lubed_turfs))
						src.lubed_turfs += T
					src.reagents.remove_reagent(src.reagent_emagged, 10)
					if (src.reagents.get_reagent_amount(src.reagent_emagged) <= 0)
						src.reagents.add_reagent(src.reagent_emagged, 50)
				else
					src.reagents.remove_reagent(src.reagent_normal, 10)
					if (src.reagents.get_reagent_amount(src.reagent_normal) <= 0)
						src.reagents.add_reagent(src.reagent_normal, 50)

				src.cleaning = 0
				src.icon_state = "cleanbot[src.on]"
				src.anchored = 0
				src.target = null
				src.frustration = 0
		return

	ex_act(severity)
		switch (severity)
			if (1.0)
				src.explode()
				return
			if (2.0)
				src.health -= 15
				if (src.health <= 0)
					src.explode()
				return
		return

	meteorhit()
		src.explode()
		return

	blob_act(var/power)
		if (prob(25 * power / 20))
			src.explode()
		return

	explode()
		if (!src)
			return

		src.on = 0
		for(var/mob/O in hearers(src, null))
			O.show_message("<span style=\"color:red\"><B>[src] blows apart!</B></span>", 1)

		var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
		s.set_up(3, 1, src)
		s.start()

		var/turf/T = get_turf(src)
		if (T && isturf(T))
			new /obj/item/reagent_containers/glass/bucket(T)
			new /obj/item/device/prox_sensor(T)
			if (prob(50))
				new /obj/item/parts/robot_parts/arm/left(T)

		qdel(src)
		return
