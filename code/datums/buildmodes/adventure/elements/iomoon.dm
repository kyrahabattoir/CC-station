// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/list/iomoon_puzzle_options = list("Ancient Robot Door" = /obj/iomoon_puzzle/ancient_robot_door, "Energy Field Door" = /obj/iomoon_puzzle/ancient_robot_door/energy,
		"Meat Jaw Door" = /obj/iomoon_puzzle/ancient_robot_door/meat, "Ganglion Button" = /obj/iomoon_puzzle/meat_ganglion,
		"Floor Pad Button" = /obj/iomoon_puzzle/floor_pad, "Ancient Robot Button" = /obj/iomoon_puzzle/button, "(Cancel)")

/datum/puzzlewizard/iomoon_puzzle
	name = "IOMOON: Doors and Buttons"
	var/obj/iomoon_puzzle/activator_object
	var/element_spawn_type

	initialize()
		boutput(usr, "<span style=\"color:blue\">Right click to select puzzle element, left click a turf to place the element, left click two elements to link them (activator -> target), ctrl+click anywhere to finish.</span>")

	build_click(var/mob/user, var/datum/buildmode_holder/holder, var/list/pa, var/atom/object)
		var/turf/T = get_turf(object)
		if (pa.Find("left"))
			if (pa.Find("ctrl"))
				finished = 1
				return

			if (istype(object, /obj/iomoon_puzzle))
				if (activator_object)
					if (activator_object == object)
						activator_object = null
						boutput(usr, "Activator object cleared.")
						return

					if (islist(activator_object.id))
						activator_object.id += "\ref[object]"

					else
						if (activator_object.id)
							activator_object.id = list(activator_object.id, "\ref[object]")
						else
							activator_object.id = list("\ref[object]")


					boutput(usr, "Paired: [activator_object] -> [object]")
				else
					activator_object = object
					boutput(usr, "Activator object selected: [activator_object]")

			else if (T && element_spawn_type)
				new element_spawn_type (T)

		else if (pa.Find("right"))
			. = input("Puzzle Element to Spawn", "Element Select") in iomoon_puzzle_options
			if (. != "(Cancel)")
				element_spawn_type = iomoon_puzzle_options[.]
				boutput(usr, "Spawned element set to [.] ([element_spawn_type]).")