// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/global/meteor_shower_active = 0

/datum/random_event/major/meteor_shower
	name = "Meteor Shower"
	// centcom message handled modularly here
	required_elapsed_round_time = 32000 // 60m
	customization_available = 1
	var/wave_direction = 1
	var/meteors_in_wave = 20
	var/delay_between_meteors = 5
	var/tile_inaccuracy = 3
	var/map_boundary = 25
	var/warning_delay = 3000
	var/meteor_speed = 8
	var/meteor_speed_variance = 4

	event_effect(var/source, var/amount, var/direction, var/delay, var/warning_time, var/speed)
		..()
		//var/timer = ticker.round_elapsed_ticks / 600

		if (!isnum(direction) || direction < 1 || direction > 4)
			direction = rand(1,4)
		wave_direction = direction

		if (!isnum(amount))
			amount = rand(10,50)
		meteors_in_wave = amount

		if (!isnum(delay) || delay < 1)
			delay = rand(2,20)
		delay_between_meteors = delay

		if (!isnum(warning_time) || warning_time < 1)
			warning_time = 3000
		warning_delay = warning_time

		if (!isnum(speed) || speed < 1)
			speed = rand(1,15)
		meteor_speed = speed

		var/comdir = "unknown direction"
		switch(direction)
			if(1)
				comdir = "the [map_setting == "DESTINY" ? "fore of the ship" : "north"]"
			if(2)
				comdir = "the [map_setting == "DESTINY" ? "aft of the ship" : "south"]"
			if(3)
				comdir = "the [map_setting == "DESTINY" ? "starboard side of the ship" : "east"]"
			if(4)
				comdir = "the [map_setting == "DESTINY" ? "port side of the ship" : "west"]"

		var/comsev = "Indeterminable"
		switch(amount)
			if(50 to INFINITY) comsev = "Catastrophic"
			if(25 to 49) comsev = "Major"
			if(11 to 24) comsev = "Significant"
			if(0 to 10) comsev = "Minor"

		var/commins = round((ticker.round_elapsed_ticks + warning_delay - ticker.round_elapsed_ticks)/10 ,1)
		commins = max(0,commins)
		if (random_events.announce_events)
			command_alert("[comsev] meteor shower approaching from [comdir]. Impact in [commins] seconds.", "Meteor Alert")
			world << 'sound/machines/engine_alert2.ogg'
			meteor_shower_active = direction
			if (map_setting == "DESTINY")
				for (var/obj/machinery/shield_generator/S in machines)
					S.update_icon()

		spawn(warning_delay)
			if (random_events.announce_events)
				command_alert("The meteor shower has reached the station. Brace for impact.", "Meteor Alert")
				world << 'sound/machines/engine_alert1.ogg'

			var/start_x
			var/start_y
			var/targ_x
			var/targ_y

			while(meteors_in_wave > 0)
				meteors_in_wave--

				switch(src.wave_direction)
					if(1) // north
						start_y = world.maxy-map_boundary
						targ_y = map_boundary
						start_x = rand(map_boundary, world.maxx-map_boundary)
						targ_x = start_x
					if(2) // south
						start_y = map_boundary
						targ_y = world.maxy-map_boundary
						start_x = rand(map_boundary, world.maxx-map_boundary)
						targ_x = start_x
					if(3) // east
						start_y = rand(map_boundary,world.maxy-map_boundary)
						targ_y = start_y
						start_x = world.maxx-map_boundary
						targ_x = map_boundary
					if(4) // west
						start_y = rand(map_boundary, world.maxy-map_boundary)
						targ_y = start_y
						start_x = map_boundary
						targ_x = world.maxx-map_boundary
					else // anywhere
						if(prob(50))
							start_y = pick(map_boundary,world.maxy-map_boundary)
							start_x = rand(map_boundary, world.maxx-map_boundary)
						else
							start_y = rand(map_boundary, world.maxy-map_boundary)
							start_x = pick(map_boundary,world.maxx-map_boundary)

				targ_x += rand(0 - tile_inaccuracy, tile_inaccuracy)
				targ_y += rand(0 - tile_inaccuracy, tile_inaccuracy)

				var/turf/pickedstart = locate(start_x, start_y, 1)
				var/target = locate(targ_x, targ_y, 1)
				var/obj/newmeteor/massive/M = new /obj/newmeteor/massive(pickedstart,target)
				M.pix_speed = meteor_speed + rand(0 - meteor_speed_variance,meteor_speed_variance)
				sleep(delay_between_meteors)

			meteor_shower_active = 0
			if (map_setting == "DESTINY")
				for (var/obj/machinery/shield_generator/S in machines)
					S.update_icon()

	admin_call(var/source)
		if (..())
			return

		var/amtinput = input(usr,"How many meteors?",src.name) as num|null
		if (!isnum(amtinput) || amtinput < 1)
			return
		var/delinput = input(usr,"Tick delay between meteors? (10 = 1 second)",src.name) as num|null
		if (!isnum(delinput) || delinput < 1)
			return
		var/dirinput = input(usr,"Which direction should the meteors come from?",src.name) as null|anything in list("north","south","east","west")
		if (!dirinput || !istext(dirinput))
			return
		switch(dirinput)
			if ("north") dirinput = 1
			if ("south") dirinput = 2
			if ("east") dirinput = 3
			if ("west") dirinput = 4
		var/timinput = input(usr,"How many ticks between the warning and the event? (10 = 1 second)",src.name) as num|null
		if (!isnum(timinput) || timinput < 1)
			return
		var/spdinput = input(usr,"How fast do the meteors move?",src.name) as num|null
		if (!isnum(spdinput) || spdinput < 1)
			return

		src.event_effect(source,amtinput,dirinput,delinput,timinput,spdinput)
		return

////////////////////////////////////////
// Defines for the meteors themselves //
////////////////////////////////////////

/obj/newmeteor
	name = "meteor"
	icon = 'icons/obj/meteor.dmi'
	icon_state = "flaming"
	desc = "A chunk of space debris. You might want to stop staring at it and run."
	density = 1
	anchored = 1.0
	var/speed = 1
	var/pix_speed = 8
	var/hit_object = 0 //If we hit something we skip the next step (we dont move)
	var/time_to_die = 250
	var/hits = 16
	var/atom/target = null
	var/last_tile = null
	var/explodes = 0
	var/exp_dev = 0
	var/exp_hvy = 0
	var/exp_lit = 0
	var/exp_fsh = 0
	var/sound_impact = 'sound/misc/meteorimpact.ogg'
	var/sound_explode = 'sound/effects/exlow.ogg'
	var/list/oredrops = list(/obj/item/raw_material/rock)
	var/list/oredrops_rare = list(/obj/item/raw_material/rock)

	small
		name = "small meteor"
		icon_state = "smallf"
		hits = 9

	New(var/atom/my_spawn, var/atom/trg)
		if(!my_spawn || !trg)
			..()
			return

		var/matrix/o = matrix()
		var/matrix/turn = turn(o, 120)
		animate(src, transform = o * turn, time = 8/3, loop = -1)
		animate(transform = o * turn * turn, time = 8/3, loop = -1)
		animate(transform = o, time = 8/3, loop = -1)
		//animate_spin(src, dir = "R", T = 1, looping = -1)
		src.set_loc(my_spawn)
		target = get_turf(trg)
		spawn(time_to_die)
			qdel(src)
		walk_towards(src, target, speed, pix_speed)
		process()
		..()

	disposing()
		target = null
		last_tile = null
		..()

	Bump(atom/A)
		spawn(0)
			if (A)
				A.meteorhit(src)
				if (sound_impact)
					playsound(src.loc, sound_impact, 40, 1)
			if (--src.hits <= 0)
				if(istype(A, /obj/forcefield)) src.explodes = 0
				shatter()

		return

	Move(atom/NewLoc,Dir)
		if(src.x == world.maxx || src.y == world.maxy || src.x == 1 || src.y == 1)
			qdel(src)
		if(src.loc == target)
			shatter()
			return
		if(src.loc == last_tile)
			walk_towards(src, target, speed, pix_speed)
		if(!hit_object)
			last_tile = src.loc
			src.loc.Exit()
			if(NewLoc.Enter())
				src.set_loc(NewLoc)
				src.dir = Dir
		else
			hit_object = 0
		check_hits()

	ex_act(severity)
		shatter()

	meteorhit(var/obj/O as obj)
		if(O == src)
			return
		shatter()

	proc/process()
		if(src.x == world.maxx || src.y == world.maxy || src.x == 1 || src.y == 1)
			qdel(src)
		if(src.loc == target)
			shatter()
			return
		if (src.loc == last_tile)
			walk_towards(src, target, speed, pix_speed)
		last_tile = src.loc
		spawn(10)
			process()

	proc/check_hits()
		for(var/turf/simulated/S in range(1,src))
			if(!S.density) continue
			hit_object = 1
			S.meteorhit(src)

		for(var/mob/M in range(1,src))
			if(M == src) continue //Just to make sure
			if(istype(M, /mob/dead)) continue
			if(!M.density) continue
			hit_object = 1
			hits -= 5
			step(M,get_dir(src,M))
			M.meteorhit(src)

		for(var/obj/O in range(1,src))
			if (O == src) continue
			if (!O.density) continue
			hit_object = 1
			hits--
			O.meteorhit(src)
			if (O && !O.anchored)
				step(O,get_dir(src,O))

		if(hit_object)
			hits--
			playsound(src.loc, sound_impact, 40, 1)

		if(hits <= 0)
			if(prob(20))
				shatter()
			else
				dump_ore()

	proc/shatter()
		playsound(src.loc, sound_explode, 50, 1)
		if (explodes)
			spawn(1)
				explosion(src, get_turf(src), exp_dev, exp_hvy, exp_lit, exp_fsh)
		var/atom/source = src
		src = null
		qdel(source)

	proc/dump_ore()
		playsound(src.loc, sound_explode, 50, 1)
		for(var/turf/T in range(src,1))
			var/type
			if (prob(1)) type = pick(oredrops_rare)
			else type = pick(oredrops)
			var/atom/A = new type (T)
			A.name = "meteor chunk"

		var/atom/source = src
		src = null
		qdel(source)

/////////////////////////HUGE

/obj/newmeteor/massive
	name = "huge asteroid"
	icon = 'icons/obj/meteor96x96.dmi'
	icon_state = "flaming"
	density = 1
	anchored = 1.0
	layer = EFFECTS_LAYER_UNDER_1
	//bound_width = 96
	//bound_height = 96
	pixel_x = -32
	pixel_y = -32
	hits = 10
	explodes = 1
	exp_dev = 0
	exp_hvy = 1
	exp_lit = 2
	exp_fsh = 3
	oredrops = list(/obj/item/raw_material/char, /obj/item/raw_material/molitz, /obj/item/raw_material/rock)
	oredrops_rare = list(/obj/item/raw_material/starstone, /obj/item/raw_material/syreline)

	shatter()
		playsound(src.loc, sound_explode, 50, 1)
		if (explodes)
			spawn(1)
				explosion(src, get_turf(src), exp_dev, exp_hvy, exp_lit, exp_fsh)
		for(var/A in alldirs)
			if(prob(15))
				continue
			var/type = pick(/obj/newmeteor, /obj/newmeteor/small)
			var/atom/trg = get_step(src, A)
			new type(src.loc, trg)
		var/atom/source = src
		src = null
		qdel(source)