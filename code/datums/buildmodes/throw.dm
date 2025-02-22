// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/buildmode/throw
	name = "Throw"
	desc = {"***********************************************************<br>
Left Mouse Button on mob/obj      = Select thrown object<br>
Right Mouse Button                = Throw object<br>
***********************************************************"}
	icon_state = "buildmode4"
	var/throwing = null

	click_left(atom/object, var/ctrl, var/alt, var/shift)
		if (istype(object, /atom/movable))
			throwing = object

	click_right(atom/object, var/ctrl, var/alt, var/shift)
		var/atom/movable/M = throwing
		if (istype(M))
			M.throw_at(get_turf(object), 10, 1)