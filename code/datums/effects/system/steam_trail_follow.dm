// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/////////////////////////////////////////////
//////// Attach a steam trail to an object (eg. a reacting beaker) that will follow it
// even if it's carried of thrown.
/////////////////////////////////////////////

/datum/effects/system/steam_trail_follow
	var/atom/holder
	var/turf/oldposition
	var/processing = 1
	var/on = 1
	var/number

/datum/effects/system/steam_trail_follow/proc/set_up(atom/atom)
	holder = atom
	oldposition = get_turf(atom)

/datum/effects/system/steam_trail_follow/proc/start()
	if(!src.on)
		src.on = 1
		src.processing = 1
	if(src.processing)
		src.processing = 0
		spawn(0)
			if(src.number < 3)
				var/obj/effects/steam/I = unpool(/obj/effects/steam)
				I.set_loc(src.oldposition)
				src.number++
				src.oldposition = get_turf(holder)
				I.dir = src.holder.dir
				spawn(10)
					if (I && !I.disposed) pool(I)
					src.number--
				spawn(2)
					if(src.on)
						src.processing = 1
						src.start()
			else
				spawn(2)
					if(src.on)
						src.processing = 1
						src.start()

/datum/effects/system/steam_trail_follow/proc/stop()
	src.processing = 0
	src.on = 0