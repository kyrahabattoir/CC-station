// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/effects/system/ion_trail_follow
	var/atom/holder
	var/turf/oldposition
	var/processing = 1
	var/on = 1
	var/offset = 0
	var/istate = "ion_fade"

/datum/effects/system/ion_trail_follow/proc/set_up(atom/atom, pixel_offset = 0, state = 0)
	holder = atom
	oldposition = get_turf(atom)
	if (pixel_offset)
		offset = pixel_offset
	if (state)
		istate = state

/datum/effects/system/ion_trail_follow/proc/start()
	if(!src.on)
		src.on = 1
		src.processing = 1
	if(src.processing)
		src.processing = 0
		spawn(0)
			var/turf/T = get_turf(src.holder)
			if(T != src.oldposition)
				if(istype(T, /turf/space) || (istype(holder, /obj/machinery/vehicle) && (istype(T, /turf/simulated) && T:allows_vehicles)) )
					if (istext(istate) && istate != "blank")
						var/obj/effects/ion_trails/I = unpool(/obj/effects/ion_trails)
						I.set_loc(src.oldposition)
						src.oldposition = T
						I.dir = src.holder.dir
						flick(istate, I)
						I.icon_state = "blank"
						I.pixel_x = offset
						I.pixel_y = offset
						spawn( 20 )
							if (I && !I.disposed) pool(I)
				spawn(2)
					if(src.on)
						src.processing = 1
						src.start()
			else
				spawn(2)
					if(src.on)
						src.processing = 1
						src.start()

/datum/effects/system/ion_trail_follow/proc/stop()
	src.processing = 0
	src.on = 0