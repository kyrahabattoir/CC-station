// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// virtual disposal object
// travels through pipes in lieu of actual items
// contents will be items flushed by the disposal
// this allows the gas flushed to be tracked

/obj/disposalholder
	invisibility = 101
	var/datum/gas_mixture/gas = null	// gas used to flush, will appear at exit point
	var/active = 0	// true if the holder is moving, otherwise inactive
	dir = 0
	var/count = 1000	//*** can travel 1000 steps before going inactive (in case of loops)
	var/has_fat_guy = 0	// true if contains a fat person

	var/mail_tag = null //Switching junctions with the same tag will pass it out the secondary instead of primary

	// initialize a holder from the contents of a disposal unit
	proc/init(var/obj/machinery/disposal/D)
		gas = D.air_contents.remove_ratio(1)	// transfer gas resv. into holder object


		// now everything inside the disposal gets put into the holder
		// note AM since can contain mobs or objs
		for(var/atom/movable/AM in D)
			AM.set_loc(src)
			if(istype(AM, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = AM
				H.unlock_medal("It'sa me, Mario", 1)
				if(H.bioHolder.HasEffect("fat"))		// is a human and fat?
					has_fat_guy = 1			// set flag on holder



	// start the movement process
	// argument is the disposal unit the holder started in
	proc/start(var/obj/machinery/disposal/D)
		if(!D.trunk || D.trunk.loc != D.loc)
			D.expel(src)	// no trunk connected, so expel immediately
			return

		loc = D.trunk
		active = 1
		dir = DOWN
		spawn(1)
			process()		// spawn off the movement process

		return

	// movement process, persists while holder is moving through pipes
	proc/process()
		var/obj/disposalpipe/last
		while(active)
			if(has_fat_guy && prob(2)) // chance of becoming stuck per segment if contains a fat guy
				active = 0
				// find the fat guys
				for(var/mob/living/carbon/human/H in src)
					if(H.bioHolder.HasEffect("fat"))
						H.unlock_medal("Try jiggling the handle",1)

				break
			sleep(1)		// was 1
			if (!loc)
				return
			var/obj/disposalpipe/curr = loc
			last = curr
			curr = curr.transfer(src)
			if(!curr)
				last.expel(src, loc, dir)

			//
			if(!(count--))
				active = 0
		return

	// find the turf which should contain the next pipe
	proc/nextloc()
		return get_step(loc,dir)

	// find a matching pipe on a turf
	proc/findpipe(var/turf/T)

		if(!T)
			return null

		var/fdir = turn(dir, 180)	// flip the movement direction
		for(var/obj/disposalpipe/P in T)
			if(fdir & P.dpdir)		// find pipe direction mask that matches flipped dir
				return P
		// if no matching pipe, return null
		return null

	// merge two holder objects
	// used when a a holder meets a stuck holder
	proc/merge(var/obj/disposalholder/other)
		for(var/atom/movable/AM in other)
			AM.set_loc(src)	// move everything in other holder to this one
		if(other.has_fat_guy)
			has_fat_guy = 1
		if(other.mail_tag && !src.mail_tag)
			src.mail_tag = other.mail_tag
		qdel(other)


	// called when player tries to move while in a pipe
	relaymove(mob/user as mob)
		if (user.stat)
			return

		// drsingh: attempted fix for Cannot read null.loc
		if (src == null || src.loc == null || src.loc.loc == null)
			return

		for (var/mob/M in hearers(src.loc.loc))
			boutput(M, "<FONT size=[max(0, 5 - get_dist(src, M))]>CLONG, clong!</FONT>")

		playsound(src.loc, "sound/effects/clang.ogg", 50, 0, 0)

	// called to vent all gas in holder to a location
	proc/vent_gas(var/atom/location)
		location.assume_air(gas)  // vent all gas to turf
		gas = null
		return

// Disposal pipes

/obj/disposalpipe
	icon = 'icons/obj/disposal.dmi'
	name = "disposal pipe"
	desc = "An underfloor disposal pipe."
	anchored = 1
	density = 0

	level = 1			// underfloor only
	var/dpdir = 0		// bitmask of pipe directions
	dir = 0				// dir will contain dominant direction for junction pipes
	var/health = 10 	// health points 0-10
	layer = DISPOSAL_PIPE_LAYER
	var/base_icon_state	// initial icon state on map
	var/list/mail_tag = null // Tag of mail group for switching pipes

	var/image/pipeimg = null

	// new pipe, set the icon_state as on map
	New()
		..()
		base_icon_state = icon_state
		pipeimg = image(src.icon, src.loc, src.icon_state, 3, dir)
		pipeimg.layer = OBJ_LAYER
		pipeimg.dir = dir
		return

	// pipe is deleted
	// ensure if holder is present, it is expelled
	disposing()
		var/obj/disposalholder/H = locate() in src
		if(H)
			// holder was present
			H.active = 0
			var/turf/T = get_turf(src)
			if(T && T.density)
				// deleting pipe is inside a dense turf (wall)
				// this is unlikely, but just dump out everything into the turf in case

				for(var/atom/movable/AM in H)
					AM.set_loc(T)
					AM.pipe_eject(0)
				H.dispose()
				..()
				return

			// otherswise, do normal expel from turf
			expel(H, T, 0)
		..()

	// returns the direction of the next pipe object, given the entrance dir
	// by default, returns the bitmask of remaining directions
	proc/nextdir(var/fromdir)
		return dpdir & (~turn(fromdir, 180))

	// transfer the holder through this pipe segment
	// overriden for special behaviour
	//
	proc/transfer(var/obj/disposalholder/H)
		var/nextdir = nextdir(H.dir)
		H.dir = nextdir
		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P


	// update the icon_state to reflect hidden status
	proc/update()
		var/turf/T = src.loc
		if (T) hide(T.intact && !istype(T,/turf/space))	// space never hides pipes

	// hide called by levelupdate if turf intact status changes
	// change visibility status and force update of icon
	hide(var/intact)
		invisibility = intact ? 101: 0	// hide if floor is intact
		updateicon()

	// update actual icon_state depending on visibility
	// if invisible, append "f" to icon_state to show faded version
	// this will be revealed if a T-scanner is used
	// if visible, use regular icon_state
	proc/updateicon()
		if(invisibility)
			icon_state = "[base_icon_state]f"
		else
			icon_state = base_icon_state
		return


	// expel the held objects into a turf
	// called when there is a break in the pipe
	//

	proc/expel(var/obj/disposalholder/H, var/turf/T, var/direction)
		// oh dear, please stop ruining the machine loop with your invalid loc
		if (!T)
			return

		var/turf/target

		if(T.density)		// dense ouput turf, so stop holder
			H.active = 0
			H.set_loc(src)
			return
		if(T.intact && istype(T,/turf/simulated/floor)) //intact floor, pop the tile
			var/turf/simulated/floor/F = T
			//F.health	= 100
			F.burnt	= 1
			F.intact	= 0
			F.levelupdate()
			new /obj/item/tile/steel(H)	// add to holder so it will be thrown with other stuff
			F.icon_state = "Floor[F.burnt ? "1" : ""]"

		if(direction)		// direction is specified
			if(istype(T, /turf/space)) // if ended in space, then range is unlimited
				target = get_edge_target_turf(T, direction)
			else						// otherwise limit to 10 tiles
				target = get_ranged_target_turf(T, direction, 10)

			playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)
			for(var/atom/movable/AM in H)
				AM.set_loc(T)
				AM.pipe_eject(direction)
				spawn(1)
					if(AM)
						AM.throw_at(target, 100, 1)
			H.vent_gas(T)
			qdel(H)

		else	// no specified direction, so throw in random direction

			playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)
			for(var/atom/movable/AM in H)
				target = get_offset_target_turf(T, rand(5)-rand(5), rand(5)-rand(5))

				AM.set_loc(T)
				AM.pipe_eject(0)
				spawn(1)
					if(AM)
						AM.throw_at(target, 5, 1)

			H.vent_gas(T)	// all gas vent to turf
			qdel(H)

		return

	// call to break the pipe
	// will expel any holder inside at the time
	// then delete the pipe
	// remains : set to leave broken pipe pieces in place
	proc/broken(var/remains = 0)
		if(isrestrictedz(z))
			return
		if(remains)
			for(var/D in cardinal)
				if(D & dpdir)
					var/obj/disposalpipe/broken/P = new(src.loc)
					P.dir = D

		src.invisibility = 101	// make invisible (since we won't delete the pipe immediately)
		var/obj/disposalholder/H = locate() in src
		if(H)
			// holder was present
			H.active = 0
			var/turf/T = src.loc
			if(T.density)
				// broken pipe is inside a dense turf (wall)
				// this is unlikely, but just dump out everything into the turf in case

				for(var/atom/movable/AM in H)
					AM.set_loc(T)
					AM.pipe_eject(0)
				qdel(H)
				return

			// otherswise, do normal expel from turf
			expel(H, T, 0)

		spawn(2)	// delete pipe after 2 ticks to ensure expel proc finished
			qdel(src)


	// pipe affected by explosion
	ex_act(severity)

		switch(severity)
			if(1.0)
				broken(0)
				return
			if(2.0)
				health -= rand(5,15)
				healthcheck()
				return
			if(3.0)
				health -= rand(0,15)
				healthcheck()
				return


	// test health for brokenness
	proc/healthcheck()
		if(isrestrictedz(z))
			return
		if(health < -2)
			broken(0)
		else if(health<1)
			broken(1)
		return

	//attack by item
	//weldingtool: unfasten and convert to obj/disposalconstruct

	attackby(var/obj/item/I, var/mob/user)
		if (isrestrictedz(z))
			return
		var/turf/T = src.loc
		if (T.intact)
			return		// prevent interaction with T-scanner revealed pipes

		if (istype(I, /obj/item/weldingtool))
			var/obj/item/weldingtool/W = I

			if (W.welding)
				if (W.get_fuel() > 3)
					W.use_fuel(3)
					playsound(src.loc, "sound/items/Welder2.ogg", 100, 1)

					// check if anything changed over 2 seconds
					var/turf/uloc = user.loc
					var/atom/wloc = W.loc
					boutput(user, "You begin slicing [src].")
					sleep(30)
					if (user.loc == uloc && wloc == W.loc)
						welded(user)
					else
						boutput(user, "You must stay still while welding the pipe.")
						return
				else
					boutput(user, "You need more welding fuel to cut the pipe.")
					return

	// called when pipe is cut with welder
	proc/welded(var/user)

		var/obj/disposalconstruct/C = new (src.loc)
		switch(base_icon_state)
			if("pipe-s")
				C.ptype = 0
			if("pipe-c")
				C.ptype = 1
			if("pipe-j1")
				C.ptype = 2
			if("pipe-j2")
				C.ptype = 3
			if("pipe-y")
				C.ptype = 4
			if("pipe-t")
				C.ptype = 5
			if("pipe-sj1")
				C.ptype = 6
			if("pipe-sj2")
				C.ptype = 7

		if (user)
			boutput(user, "You finish slicing [C].")

		C.dir = dir
		C.mail_tag = src.mail_tag
		C.update()

		qdel(src)

// a straight or bent segment
/obj/disposalpipe/segment
	icon_state = "pipe-s"

	horizontal
		dir = EAST
	vertical
		dir = NORTH
	bent
		icon_state = "pipe-c"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	mail
		name = "mail pipe"

		horizontal
			dir = EAST
		vertical
			dir = NORTH
		bent
			icon_state = "pipe-c"

			north
				dir = NORTH
			east
				dir = EAST
			south
				dir = SOUTH
			west
				dir = WEST

	New()
		..()
		if(icon_state == "pipe-s")
			dpdir = dir | turn(dir, 180)
		else
			dpdir = dir | turn(dir, -90)

		update()
		return

//a three-way junction with dir being the dominant direction
/obj/disposalpipe/junction
	icon_state = "pipe-j1"

	left
		name = "pipe junction"
		icon_state = "pipe-j1"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	right
		name = "pipe junction"
		icon_state = "pipe-j2"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	middle
		name = "pipe junction"
		icon_state = "pipe-y"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	New()
		..()
		if(icon_state == "pipe-j1")
			dpdir = dir | turn(dir, -90) | turn(dir,180)
		else if(icon_state == "pipe-j2")
			dpdir = dir | turn(dir, 90) | turn(dir,180)
		else // pipe-y
			dpdir = dir | turn(dir,90) | turn(dir, -90)
		update()
		return


	// next direction to move
	// if coming in from secondary dirs, then next is primary dir
	// if coming in from primary dir, then next is equal chance of other dirs

	nextdir(var/fromdir)
		var/flipdir = turn(fromdir, 180)
		if(flipdir != dir)	// came from secondary dir
			return dir		// so exit through primary
		else				// came from primary
							// so need to choose either secondary exit
			var/mask = ..(fromdir)

			// find a bit which is set
			var/setbit = 0
			if(mask & NORTH)
				setbit = NORTH
			else if(mask & SOUTH)
				setbit = SOUTH
			else if(mask & EAST)
				setbit = EAST
			else
				setbit = WEST

			if(prob(50))	// 50% chance to choose the found bit or the other one
				return setbit
			else
				return mask & (~setbit)

//A junction capable of switching output direction
/obj/disposalpipe/switch_junction
	name = "switching pipe"
	icon_state = "pipe-sj1"

	var/redirect_chance = 50
	var/switch_dir = 0 //Direction of secondary port
					//Same-tag holders are sent out this one.

	left
		name = "mail junction"
		icon_state = "pipe-sj1"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	right
		name = "mail junction"
		icon_state = "pipe-sj2"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	New()
		..()
		if(icon_state == "pipe-sj1")
			switch_dir = turn(dir, -90)
			dpdir = dir | switch_dir | turn(dir,180)
		else if(icon_state == "pipe-sj2")
			switch_dir = turn(dir, 90)
			dpdir = dir | turn(dir, 90) | turn(dir,180)
		else
			switch_dir = turn(dir, 90)
			dpdir = dir | turn(dir,90) | turn(dir, -90)
		update()

		if (src.mail_tag)
			if (islist(src.mail_tag))
				src.name = "mail junction (multiple destinations)"
			else
				src.name = "mail junction ([src.mail_tag])"
				src.mail_tag = params2list(src.mail_tag)
		return


	// next direction to move

	transfer(var/obj/disposalholder/H)
		var/same_group = 0
		if(src.mail_tag && (H.mail_tag in src.mail_tag))
			same_group = 1

		var/nextdir = nextdir(H.dir, same_group)
		H.dir = nextdir
		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P

	nextdir(var/fromdir, var/use_secondary)
		var/flipdir = turn(fromdir, 180)
		if(flipdir != dir)	// came from secondary or tertiary
			var/senddir = dir	//Do we send this out the primary or secondary?
			if(use_secondary && flipdir != switch_dir) //Oh, we're set to sort this out our side secondary
				flick("[base_icon_state]-on", src)
				senddir = switch_dir
			return senddir
		else				// came from primary
							// so need to choose either secondary exit
			var/mask = ..(fromdir)

			// find a bit which is set
			var/setbit = 0
			if(mask & NORTH)
				setbit = NORTH
			else if(mask & SOUTH)
				setbit = SOUTH
			else if(mask & EAST)
				setbit = EAST
			else
				setbit = WEST

			if(prob(redirect_chance))	// Adjustable chance to choose the found bit or the other one
				return setbit
			else
				return mask & (~setbit)

/obj/disposalpipe/switch_junction/biofilter
	name = "biofilter pipe"
	desc = "A pipe junction designed to redirect living organic tissue."
	redirect_chance = 0

	left
		icon_state = "pipe-sj1"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	right
		icon_state = "pipe-sj2"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	transfer(var/obj/disposalholder/H)
		var/redirect = 0
		for (var/mob/living/carbon/C in H)
			if (C.stat != 2)
				redirect = 1
				break

		var/nextdir = nextdir(H.dir, redirect)
		H.dir = nextdir
		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P

	welded()

		var/obj/disposalconstruct/C = new (src.loc)
		C.ptype = (src.icon_state == "pipe-sj1" ? 8 : 9)
		C.dir = dir
		C.mail_tag = src.mail_tag
		C.update()

		qdel(src)

/obj/disposalpipe/loafer
	name = "disciplinary loaf processor"
	desc = "A pipe segment designed to convert detritus into a nutritionally-complete meal for inmates."
	icon_state = "pipe-loaf0"
	var/nugget_mode = 0

	horizontal
		dir = EAST
	vertical
		dir = NORTH

	New()
		..()

		dpdir = dir | turn(dir, 180)
		update()

	transfer(var/obj/disposalholder/H)

		if (H.contents.len)
			playsound(src.loc, "sound/machines/mixer.ogg", 50, 1)
			//src.visible_message("<b>[src] activates!</b>") // Processor + loop = SPAM
			src.icon_state = "pipe-loaf1"

			var/doSuperLoaf = 0
			for (var/atom/movable/O in H)
				if(O.name == "strangelet loaf")
					doSuperLoaf = 1
					break

			if(doSuperLoaf)
				for (var/atom/movable/O2 in H)
					qdel(O2)

				var/obj/item/reagent_containers/food/snacks/einstein_loaf/estein = new /obj/item/reagent_containers/food/snacks/einstein_loaf(src)
				estein.set_loc(H)
				goto StopLoafing

			if (nugget_mode)
				var/obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/nugget/current_nugget
				var/list/new_nuggets = list()
				for (var/atom/movable/newIngredient in H)
					if (!current_nugget)
						current_nugget = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/nugget(src)
						new_nuggets += current_nugget

					current_nugget.name = "[newIngredient] nugget"
					current_nugget.desc = "A breaded wad of [newIngredient.name], far too processed to have a more specific label than 'nugget.'"

					if (istype(newIngredient, /mob/living))
						playsound(src.loc, pick("sound/effects/splat.ogg","sound/effects/slosh.ogg","sound/effects/zhit.ogg","sound/effects/attackblob.ogg","sound/effects/blobattack.ogg","sound/effects/bloody_stab.ogg"), 50, 1)
						var/mob/living/poorSoul = newIngredient
						if (issilicon(poorSoul))
							current_nugget.reagents.add_reagent("oil",10)
							current_nugget.reagents.add_reagent("silicon",10)
							current_nugget.reagents.add_reagent("iron",10)
						else
							current_nugget.reagents.add_reagent("bloodc",10) // heh
							current_nugget.reagents.add_reagent("ectoplasm",10)

						if(poorSoul.stat != 2)
							poorSoul:emote("scream")
						sleep(5)
						poorSoul.ghostize()

					if (newIngredient.reagents)
						var/anItem = istype(newIngredient, /obj/item)
						while (newIngredient.reagents.total_volume > 0 || (anItem && newIngredient:w_class--))
							newIngredient.reagents.trans_to(current_nugget, current_nugget.reagents.maximum_volume)
							if (current_nugget.reagents.total_volume >= current_nugget.reagents.maximum_volume)
								current_nugget = new /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat/nugget(src)

								current_nugget.name = "[newIngredient] nugget"
								current_nugget.desc = "A breaded wad of [newIngredient.name], far too processed to have a more specific label than 'nugget.'"

								new_nuggets += current_nugget

					qdel(newIngredient)
					LAGCHECK(50)

					for (var/obj/O in new_nuggets)
						O.set_loc(H)
						LAGCHECK(50)

			else
				var/obj/item/reagent_containers/food/snacks/prison_loaf/newLoaf = new /obj/item/reagent_containers/food/snacks/prison_loaf(src)
				for (var/atom/movable/newIngredient in H)
					if (newIngredient.reagents)
						newIngredient.reagents.trans_to(newLoaf, 1000)

					if (istype(newIngredient, /obj/item/reagent_containers/food/snacks/prison_loaf))
						var/obj/item/reagent_containers/food/snacks/prison_loaf/otherLoaf = newIngredient
						newLoaf.loaf_factor += otherLoaf.loaf_factor * 1.2
						newLoaf.loaf_recursion = otherLoaf.loaf_recursion + 1

					else if (istype(newIngredient, /mob/living))
						playsound(src.loc, pick("sound/effects/splat.ogg","sound/effects/slosh.ogg","sound/effects/zhit.ogg","sound/effects/attackblob.ogg","sound/effects/blobattack.ogg","sound/effects/bloody_stab.ogg"), 50, 1)
						var/mob/living/poorSoul = newIngredient
						if (issilicon(poorSoul))
							newLoaf.reagents.add_reagent("oil",10)
							newLoaf.reagents.add_reagent("silicon",10)
							newLoaf.reagents.add_reagent("iron",10)
						else
							newLoaf.reagents.add_reagent("bloodc",10) // heh
							newLoaf.reagents.add_reagent("ectoplasm",10)

						if(ishuman(newIngredient))
							newLoaf.loaf_factor += (newLoaf.loaf_factor / 5) + 50 // good god this is a weird value
						else
							newLoaf.loaf_factor += (newLoaf.loaf_factor / 10) + 50
						if(poorSoul.stat != 2)
							poorSoul:emote("scream")
						sleep(5)
						poorSoul.ghostize()
					else if (istype(newIngredient, /obj/item))
						var/obj/item/I = newIngredient
						newLoaf.loaf_factor += I.w_class * 5
					else
						newLoaf.loaf_factor++
					qdel(newIngredient)
					LAGCHECK(50)

				newLoaf.update()
				newLoaf.set_loc(H)

			StopLoafing

			sleep(3)	//make a bunch of ongoing noise i guess?
			playsound(src.loc, pick("sound/machines/mixer.ogg","sound/machines/mixer.ogg","sound/machines/mixer.ogg","sound/machines/hiss.ogg","sound/machines/ding.ogg","sound/machines/buzz-sigh.ogg","sound/effects/robogib.ogg","sound/effects/pop.ogg","sound/machines/warning-buzzer.ogg","sound/effects/Glassbr1.ogg","sound/effects/gib.ogg","sound/effects/spring.ogg","sound/machines/engine_grump1.ogg","sound/machines/engine_grump2.ogg","sound/machines/engine_grump3.ogg","sound/effects/Glasshit.ogg","sound/effects/bubbles.ogg","sound/effects/brrp.ogg"), 50, 1)
			sleep(3)

			playsound(src.loc, "sound/machines/engine_grump1.ogg", 50, 1)
			sleep(30)
			src.icon_state = "pipe-loaf0"
			//src.visible_message("<b>[src] deactivates!</b>") // Processor + loop = SPAM

		var/nextdir = nextdir(H.dir)
		H.dir = nextdir
		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P

	welded()

		/*var/obj/disposalconstruct/C = new (src.loc)
		C.ptype = 10
		C.dir = dir
		C.update()

		qdel(src)*/

		src.visible_message("<span style=\"color:red\">[src] emits a weird noise!</span>")

		src.nugget_mode = !src.nugget_mode
		src.update()
		return

	update()
		..()
		if (nugget_mode)
			src.name = "disciplinary nugget processor"
		else
			src.name = initial(src.name)

#define MAXIMUM_LOAF_STATE_VALUE 10

/obj/item/reagent_containers/food/snacks/einstein_loaf
	name = "einstein-rosen loaf"
	desc = "A hypothetical feature of loaf-spacetime. It could in theory be used to open a bridge between one point in space-time to another point in loaf-spacetime, if one had the machine required ..."
	icon = 'icons/obj/foodNdrink/food_meals.dmi'
	icon_state = "eloaf"
	force = 0
	throwforce = 0

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(1000)
		reagents = R
		R.my_atom = src
		src.reagents.add_reagent("liquid spacetime",11)

/obj/item/reagent_containers/food/snacks/prison_loaf
	name = "prison loaf"
	desc = "A rather slapdash loaf designed to feed prisoners.  Technically nutritionally complete and edible in the same sense that potted meat product is edible."
	icon = 'icons/obj/foodNdrink/food_meals.dmi'
	icon_state = "ploaf0"
	force = 0
	throwforce = 0
	var/loaf_factor = 1
	var/loaf_recursion = 1
	var/processing = 0

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(1000)
		reagents = R
		R.my_atom = src
		src.reagents.add_reagent("gravy",10)
		src.reagents.add_reagent("refried_beans",10)
		src.reagents.add_reagent("fakecheese",10)
		src.reagents.add_reagent("silicate",10)
		src.reagents.add_reagent("space_fungus",3)
		src.reagents.add_reagent("synthflesh",10)

	proc/update()
		var/orderOfLoafitude = max( 0, min( round( log(8, loaf_factor)), MAXIMUM_LOAF_STATE_VALUE ) )
		//src.icon_state = "ploaf[orderOfLoafitude]"

		src.w_class = min(orderOfLoafitude+1, 4)

		switch ( orderOfLoafitude )

			if (1)
				src.name = "prison loaf"
				src.desc = "A rather slapdash loaf designed to feed prisoners.  Technically nutritionally complete and edible in the same sense that potted meat product is edible."
				src.icon_state = "ploaf0"
				src.force = 0
				src.throwforce = 0

			if (2)
				src.name = "dense prison loaf"
				src.desc = "The chef must be really packing a lot of junk into these things today."
				src.icon_state = "ploaf0"
				src.force = 3
				src.throwforce = 3
				src.reagents.add_reagent("beff",25)

			if (3)
				src.name = "extra dense prison loaf"
				src.desc = "Good lord, this thing feels almost like a brick. A brick made of kitchen scraps and god knows what else."
				src.icon_state = "ploaf0"
				src.force = 6
				src.throwforce = 6
				src.reagents.add_reagent("porktonium",25)

			if (4)
				src.name = "super-compressed prison loaf"
				src.desc = "Hard enough to scratch a diamond, yet still somehow edible, this loaf seems to be emitting decay heat. Dear god."
				src.icon_state = "ploaf1"
				src.force = 11
				src.throwforce = 11
				src.throw_range = 6
				src.reagents.add_reagent("thalmerite",25)

			if (5)
				src.name = "fissile loaf"
				src.desc = "There's so much junk packed into this loaf, the flavor atoms are starting to go fissile. This might make a decent engine fuel, but it definitely wouldn't be good for you to eat."
				src.icon_state = "ploaf2"
				src.force = 22
				src.throwforce = 22
				src.throw_range = 5
				src.reagents.add_reagent("uranium",25)

			if (6)
				src.name = "fusion loaf"
				src.desc = "Forget fission, the flavor atoms in this loaf are so densely packed now that they are undergoing atomic fusion. What terrifying new flavor atoms might lurk within?"
				src.icon_state = "ploaf3"
				src.force = 44
				src.throwforce = 44
				src.throw_range = 4
				src.reagents.add_reagent("radium",25)

			if (7)
				src.name = "neutron loaf"
				src.desc = "Oh good, the flavor atoms in this prison loaf have collapsed down to a a solid lump of neutrons."
				src.icon_state = "ploaf4"
				src.force = 66
				src.throwforce = 66
				src.throw_range = 3
				src.reagents.add_reagent("polonium",25)

			if (8)
				src.name = "quark loaf"
				src.desc = "This nutritional loaf is collapsing into subatomic flavor particles. It is unfathmomably heavy."
				src.icon_state = "ploaf5"
				src.force = 88
				src.throwforce = 88
				src.throw_range = 2
				src.reagents.add_reagent("george_melonium",25)

			if (9)
				src.name = "degenerate loaf"
				src.desc = "You should probably call a physicist."
				src.icon_state = "ploaf6"
				src.force = 110
				src.throwforce = 110
				src.throw_range = 1
				src.reagents.add_reagent("george_melonium",50)

			if (10)
				src.name = "strangelet loaf"
				src.desc = "You should probably call a priest."
				src.icon_state = "ploaf7"
				src.force = 220
				src.throwforce = 220
				src.throw_range = 0
				src.reagents.add_reagent("george_melonium",100)

				if (!src.processing)
					src.processing++
					if (!(src in processing_items))
						processing_items.Add(src)

				/*spawn(rand(100,1000))
					if(src)
						src.visible_message("<span style=\"color:red\"><b>[src] collapses into a black hole! Holy fuck!</b></span>")
						world << sound("sound/effects/kaboom.ogg")
						new /obj/bhole(get_turf(src.loc))*/


		return

	process()
		if(src.loc == get_turf(src))
			var/edge = get_edge_target_turf(src, pick(alldirs))
			spawn
				src.throw_at(edge, 100, 1)

#undef MAXIMUM_LOAF_STATE_VALUE

/obj/disposalpipe/mechanics_switch
	icon_state = "pipe-mech0"
	var/active = 0
	var/switch_dir = 0

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	New()
		..()

		mechanics = new(src)
		mechanics.master = src
		mechanics.addInput("toggle", "toggleactivation")
		mechanics.addInput("on", "activate")
		mechanics.addInput("off", "deactivate")

		spawn (10)
			switch_dir = turn(dir, 90)
			dpdir = dir | switch_dir | turn(dir,180)

		update()

	nextdir(var/fromdir)
		//var/flipdir = turn(fromdir, 180)
		if(fromdir & turn(switch_dir, 180))	// came in the wrong way
			return dpdir & (prob(50) ? dir : turn(dir, 180))//turn(switch_dir, prob(50) ? -90 : 90)

		else
			if (active)
				return switch_dir

			else
				return fromdir

	updateicon()
		icon_state = "pipe-mech[active][invisibility ? "f" : null]"
		return

	proc/toggleactivation()
		src.active = !src.active
		updateicon()

	proc/activate()
		src.active = 1
		updateicon()

	proc/deactivate()
		src.active = 0
		updateicon()

	welded()
		var/obj/disposalconstruct/C = new (src.loc)
		C.ptype = 11
		C.dir = dir
		C.update()

		if (src.mechanics)
			src.mechanics.wipeIncoming()
			src.mechanics.wipeOutgoing()

		qdel(src)

//<Jewel>:
//Tried to rework biofilter to create a new disposalholder and send bio one way and normal objects the other. It doesn't work.
//Check back on the pipe code later. It needs some kinda revamp in the future.

/*/obj/disposalpipe/switch_junction/biofilter
	name = "biofilter pipe"
	desc = "A pipe junction designed to redirect living organic tissue."
	redirect_chance = 0

	var/obj/disposalholder/bioHolder = new()

	transfer(var/obj/disposalholder/origHolder)
		for (var/mob/living/carbon/C in origHolder)
			if (C.stat != 2)
				C.set_loc(bioHolder)

		var/otherdir = nextdir(origHolder.dir, 0)
		var/biodir = nextdir(origHolder.dir, 1)

		origHolder.dir = otherdir
		bioHolder.dir = biodir

		var/turf/nonBioTurf = origHolder.nextloc()
		var/turf/bioTurf = bioHolder.nextloc()

		var/obj/disposalpipe/nonBioPipe = origHolder.findpipe(nonBioTurf)
		var/obj/disposalpipe/bioPipe = bioHolder.findpipe(bioTurf)

		if (nonBioPipe)
			var/obj/disposalholder/newHolder = locate() in nonBioPipe
			if(newHolder && !newHolder.active)
				origHolder.merge(newHolder)

			origHolder.set_loc(nonBioPipe)

			boutput(world, "I found a non bio pipe at [nonBioPipe.loc] with [origHolder.loc]")

		if (bioPipe)
			var/obj/disposalholder/newHolderBio = locate() in bioPipe
			if (newHolderBio && !newHolderBio.active)
				bioHolder.merge(newHolderBio)

			bioHolder.set_loc(bioPipe)

			boutput(world, "I found a bio pipe at [bioPipe.loc] with [bioHolder.loc]")

		bioHolder.active = 1
		bioHolder.dir = biodir
		spawn(1)
			bioHolder.process()

		return nonBioPipe

	welded()
		var/obj/disposalconstruct/C = new (src.loc)
		C.ptype = (src.icon_state == "pipe-sj1" ? 8 : 9)
		C.dir = dir
		C.mail_tag = src.mail_tag
		C.update()

		qdel(src)*/

/obj/disposalpipe/block_sensing_outlet
	name = "smart disposal outlet"
	desc = "A disposal outlet with a little sonar sensor on the front, so it only dumps contents if it is unblocked."
	icon_state = "unblockoutlet"
	anchored = 1
	density = 1
	var/turf/stuff_chucking_target

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	New()
		..()

		dpdir = dir | turn(dir, 270) | turn(dir, 90)
		spawn (1)
			stuff_chucking_target = get_ranged_target_turf(src, dir, 1)

	welded()
		return

	transfer(var/obj/disposalholder/H)
		var/allowDump = 1

		for (var/atom/movable/blockingJerk in get_step(src, src.dir))
			if (blockingJerk.density)
				allowDump = 0
				break

		if (allowDump)
			flick("unblockoutlet-open", src)
			playsound(src, "sound/machines/warning-buzzer.ogg", 50, 0, 0)

			sleep(20)	//wait until correct animation frame
			playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)


			for(var/atom/movable/AM in H)
				AM.set_loc(src.loc)
				AM.pipe_eject(dir)
				spawn(1)
					AM.throw_at(stuff_chucking_target, 3, 1)
			H.vent_gas(src.loc)
			qdel(H)

			return null

		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P

/obj/disposalpipe/type_sensing_outlet
	name = "filter disposal outlet"
	desc = "A disposal outlet with a little sensor in it, to allow it to filter out unwanted things from the system."
	icon_state = "unblockoutlet"
	var/turf/stuff_chucking_target
	var/list/allowed_types = list()

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	New()
		..()

		dpdir = dir | turn(dir, 270) | turn(dir, 90)
		spawn (1)
			stuff_chucking_target = get_ranged_target_turf(src, dir, 1)

	welded()
		return

	transfer(var/obj/disposalholder/H)
		var/list/things_to_dump = list()

		for (var/atom/movable/A in H)
			var/dump_this = 1
			for (var/thing in src.allowed_types)
				if (ispath(thing) && istype(A, thing))
					dump_this = 0
					break
			if (dump_this)
				things_to_dump += A

		if (things_to_dump.len)
			flick("unblockoutlet-open", src)
			playsound(src, "sound/machines/warning-buzzer.ogg", 50, 0, 0)

			sleep(20)	//wait until correct animation frame
			playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)

			for (var/atom/movable/AM in things_to_dump)
				AM.set_loc(src.loc)
				AM.pipe_eject(dir)
				spawn(1)
					AM.throw_at(stuff_chucking_target, 3, 1)
			if (H.contents.len < 1)
				H.vent_gas(src.loc)
				qdel(H)
				return null

		var/turf/T = H.nextloc()
		var/obj/disposalpipe/P = H.findpipe(T)

		if(P)
			// find other holder in next loc, if inactive merge it with current
			var/obj/disposalholder/H2 = locate() in P
			if(H2 && !H2.active)
				H.merge(H2)

			H.set_loc(P)
		else			// if wasn't a pipe, then set loc to turf
			H.set_loc(T)
			return null

		return P

/obj/disposalpipe/type_sensing_outlet/drone_factory
	allowed_types = list(/obj/item/ghostdrone_assembly)

#define SENSE_LIVING 1
#define SENSE_OBJECT 2
#define SENSE_TAG 3

/obj/disposalpipe/mechanics_sensor
	name = "Sensor pipe"
	icon_state = "pipe-mechsense"
	var/sense_mode = SENSE_OBJECT
	var/sense_tag_filter = ""

	horizontal
		dir = EAST
	vertical
		dir = NORTH

	New()
		..()

		mechanics = new(src)
		mechanics.master = src

		dpdir = dir | turn(dir, 180)

		update()

	MouseDrop(obj/O, null, var/src_location, var/control_orig, var/control_new, var/params)

		if(!istype(usr, /mob/living))
			return

		if(istype(O, /obj/item/mechanics) && O.level == 2)
			boutput(usr, "<span style=\"color:red\">[O] needs to be secured into place before it can be connected.</span>")
			return

		if(usr.stat)
			return

		if(!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		mechanics.dropConnect(O, null, src_location, control_orig, control_new, params)
		return ..()

	verb/set_sense_mode()
		set src in view(1)
		set name = "\[Set Mode\]"
		set desc = "Sets the sensing mode of the pipe.."

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		. = alert(usr, "What should trigger the sensor?","Disposal Sensor", "Creatures", "Anything", "A mail tag")
		if (.)
			if (get_dist(usr, src) > 1 || usr.stat)
				return

			switch (.)
				if ("Creatures")
					sense_mode = SENSE_LIVING

				if ("Anything")
					sense_mode = SENSE_OBJECT

				if ("A mail tag")
					. = copytext(ckeyEx(input(usr, "What should the tag be?", "What?")), 1, 33)
					if (. && get_dist(usr, src) < 2 && !usr.stat)
						sense_mode = SENSE_TAG
						sense_tag_filter = .


	transfer(var/obj/disposalholder/H)
		if (sense_mode == SENSE_TAG)
			if (cmptext(H.mail_tag, sense_tag_filter))
				mechanics.fireOutgoing(mechanics.newSignal(ckey(H.mail_tag)))
				flick("pipe-mechsense-detect", src)

		else if (sense_mode == SENSE_OBJECT)
			if (H.contents.len)
				mechanics.fireOutgoing(mechanics.newSignal("1"))
				flick("pipe-mechsense-detect", src)

		else
			for (var/atom/aThing in H)
				if (sense_mode == SENSE_LIVING)
					if ((istype(aThing, /obj/critter) || (istype(aThing, /mob/living) && aThing:stat != 2)))
						mechanics.fireOutgoing(mechanics.newSignal("1"))
						flick("pipe-mechsense-detect", src)
						break

		return ..()

	welded()
		var/obj/disposalconstruct/C = new (src.loc)
		C.ptype = 12
		C.dir = dir
		C.update()

		if (src.mechanics)
			src.mechanics.wipeIncoming()
			src.mechanics.wipeOutgoing()

		qdel(src)

#undef SENSE_LIVING
#undef SENSE_OBJECT
#undef SENSE_TAG

//a trunk joining to a disposal bin or outlet on the same turf
/obj/disposalpipe/trunk
	icon_state = "pipe-t"
	var/obj/linked 	// the linked obj/machinery/disposal or obj/disposaloutlet

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	mail
		name = "mail pipe"

		north
			dir = NORTH
		east
			dir = EAST
		south
			dir = SOUTH
		west
			dir = WEST

	New()
		..()
		dpdir = dir
		spawn(1)
			getlinked()

		update()
		return

	proc/getlinked()
		linked = null
		var/obj/machinery/disposal/D = locate() in src.loc
		if(D)
			linked = D

		var/obj/disposaloutlet/O = locate() in src.loc
		if(O)
			linked = O

		update()
		return

	// would transfer to next pipe segment, but we are in a trunk
	// if not entering from disposal bin,
	// transfer to linked object (outlet or bin)

	transfer(var/obj/disposalholder/H)

		if(H.dir == DOWN)		// we just entered from a disposer
			return ..()		// so do base transfer proc
		// otherwise, go to the linked object
		if(linked)
			var/obj/disposaloutlet/O = linked
			if(istype(O))
				O.expel(H)	// expel at outlet
			else
				var/obj/machinery/disposal/D = linked
				D.expel(H)	// expel at disposal
		else
			src.expel(H, src.loc, 0)	// expel at turf
		return null

	// nextdir

	nextdir(var/fromdir)
		if(fromdir == DOWN)
			return dir
		else
			return 0

// a broken pipe
/obj/disposalpipe/broken
	icon_state = "pipe-b"
	dpdir = 0		// broken pipes have dpdir=0 so they're not found as 'real' pipes
					// i.e. will be treated as an empty turf
	desc = "A broken piece of disposal pipe."

	New()
		..()
		update()
		return

	// called when welded
	// for broken pipe, remove and turn into scrap

	welded()
		var/obj/item/scrap/S = new(src.loc)
		S.set_components(200,0,0)
		qdel(src)

// the disposal outlet machine

/obj/disposaloutlet
	name = "disposal outlet"
	desc = "An outlet for the pneumatic disposal system."
	icon = 'icons/obj/disposal.dmi'
	icon_state = "outlet"
	density = 1
	anchored = 1
	var/active = 0
	var/turf/target	// this will be where the output objects are 'thrown' to.
	mats = 12

	var/message = null
	var/mailgroup = null
	var/mailgroup2 = null
	var/net_id = null
	var/frequency = 1149
	var/datum/radio_frequency/radio_connection

	north
		dir = NORTH
	east
		dir = EAST
	south
		dir = SOUTH
	west
		dir = WEST

	New()
		..()

		spawn(1)
			target = get_ranged_target_turf(src, dir, 10)
		spawn(8)
			if(radio_controller)
				radio_connection = radio_controller.add_object(src, "[frequency]")
			if(!src.net_id)
				src.net_id = generate_net_id(src)

	// expel the contents of the holder object, then delete it
	// called when the holder exits the outlet
	proc/expel(var/obj/disposalholder/H)
		if (message && mailgroup && radio_connection)
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "CHUTE-MAILBOT"
			newsignal.data["message"] = "[message]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup
			newsignal.data["sender"] = src.net_id

			radio_connection.post_signal(src, newsignal)

		if (message && mailgroup2 && radio_connection)
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "CHUTE-MAILBOT"
			newsignal.data["message"] = "[message]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup2
			newsignal.data["sender"] = src.net_id

			radio_connection.post_signal(src, newsignal)

		flick("outlet-open", src)
		playsound(src, "sound/machines/warning-buzzer.ogg", 50, 0, 0)

		sleep(20)	//wait until correct animation frame
		playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)


		for(var/atom/movable/AM in H)
			AM.set_loc(src.loc)
			AM.pipe_eject(dir)
			spawn(1)
				AM.throw_at(target, 3, 1)
		H.vent_gas(src.loc)
		qdel(H)

		return

// called when movable is expelled from a disposal pipe or outlet
// by default does nothing, override for special behaviour

/atom/movable/proc/pipe_eject(var/direction)
	return

// check if mob has client, if so restore client view on eject
/mob/pipe_eject(var/direction)
	src.weakened = max(src.weakened, 2)
	return

/obj/decal/cleanable/blood/gibs/pipe_eject(var/direction)
	var/list/dirs
	if(direction)
		dirs = list( direction, turn(direction, -45), turn(direction, 45))
	else
		dirs = alldirs.Copy()

	src.streak(dirs)

/obj/decal/cleanable/robot_debris/gib/pipe_eject(var/direction)
	var/list/dirs
	if(direction)
		dirs = list( direction, turn(direction, -45), turn(direction, 45))
	else
		dirs = alldirs.Copy()

	src.streak(dirs)

// -------------------- VR --------------------
/obj/disposaloutlet/virtual
	name = "gauntlet outlet"
	desc = "For disposing of pixel junk, one would suppose."
	icon = 'icons/effects/VR.dmi'
// --------------------------------------------