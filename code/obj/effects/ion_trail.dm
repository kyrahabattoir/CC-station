// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/////////////////////////////////////////////
//////// Attach an Ion trail to any object, that spawns when it moves (like for the jetpack)
/// just pass in the object to attach it to in set_up
/// Then do start() to start it and stop() to stop it, obviously
/// and don't call start() in a loop that will be repeated otherwise it'll get spammed!
/////////////////////////////////////////////

/obj/effects/ion_trails
	name = "ion trails"
	icon_state = "ion_trails"
	anchored = 1.0

/obj/effects/ion_trails/pooled(var/poolname)
	icon_state = "blank"
	pixel_x = 0
	pixel_y = 0
	..()