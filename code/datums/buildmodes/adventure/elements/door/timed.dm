// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/puzzlewizard/door/timed
	name = "AB CREATE: Door (timed)"
	var/door_delay

	initialize()
		door_delay = input("How many 1/10th seconds should the door stay open?", "Seconds to close", 100) as num
		..()

	build_click(var/mob/user, var/datum/buildmode_holder/holder, var/list/pa, var/atom/object)
		if (pa.Find("left"))
			var/turf/T = get_turf(object)
			if (pa.Find("ctrl"))
				finished = 1
				return
			if (T)
				var/obj/adventurepuzzle/triggerable/door/timed/door = new /obj/adventurepuzzle/triggerable/door/timed(T)
				door.name = door_name
				door.icon_state = "door_[door_type]_closed"
				door.door_type = door_type
				door.time_limit = door_delay
				if (door_type == "glass" || door_type == "runes")
					door.opacity = 0
				spawn(10)
					door.color = color_rgb
		else if (pa.Find("right"))
			if (istype(object, /obj/adventurepuzzle/triggerable/door))
				object:toggle()

/obj/adventurepuzzle/triggerable/door/timed
	var/time_limit = 100
	var/openid = 1

	open()
		if (!density)
			return
		if (opening == 1)
			return
		..()
		var/myid = openid
		openid++
		spawn(time_limit + 10)
			if (myid == openid)
				close()

	serialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		..()
		F["[path].time_limit"] << time_limit

	deserialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		. = ..()
		F["[path].time_limit"] >> time_limit
