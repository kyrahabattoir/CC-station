// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/effects/harmless_smoke
	name = "smoke"
	icon_state = "smoke"
	opacity = 1
	anchored = 0.0
	mouse_opacity = 0
	var/amount = 6.0
	//Remove this bit to use the old smoke
	icon = 'icons/effects/96x96.dmi'
	pixel_x = -32
	pixel_y = -32

	pooled()
		..()

/*
/obj/effects/harmless_smoke/New()
	..()
	spawn (100)
		pool(src)
	return
*/
/obj/effects/harmless_smoke/proc/kill(var/time)
	spawn(time)
		pool(src)

/obj/effects/harmless_smoke/Move()
	..()
	return


proc/harmless_smoke_puff(var/turf/location, var/duration = 100)
	if(!istype(location)) return
	var/obj/effects/harmless_smoke/smoke = unpool(/obj/effects/harmless_smoke)
	smoke.set_loc(location)
	smoke.kill(100)