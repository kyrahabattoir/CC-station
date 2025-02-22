// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/mass_driver
	name = "mass driver"
	icon = 'icons/obj/stationobjs.dmi'
	desc = "A device that launches objects on it at great velocity when activated."
	icon_state = "mass_driver"
	var/power = 1.0
	var/code = 1.0
	var/id = 1.0
	anchored = 1.0
	layer = 2.6
	var/drive_range = 50 //this is mostly irrelevant since current mass drivers throw into space, but you could make a lower-range mass driver for interstation transport or something I guess.

/obj/machinery/mass_driver/proc/drive(amount)
	if(stat & (BROKEN|NOPOWER))
		return
	use_power(500)
	var/O_limit
	var/atom/target = get_edge_target_turf(src, src.dir)
	for(var/atom/movable/O in src.loc)
		if(!O.anchored)
			O_limit++
			if(O_limit >= 20)
				for(var/mob/M in hearers(src, null))
					boutput(M, "<span style=\"color:blue\">The mass driver lets out a screech, it mustn't be able to handle any more items.</span>")
				break
			use_power(500)
			spawn( 0 )
				O.throw_at(target, drive_range * src.power, src.power)
	flick("mass_driver1", src)
	return

