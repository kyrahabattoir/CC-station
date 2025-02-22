// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/puzzlewizard/wall
	name = "AB CREATE: Sliding wall"
	var/wall_name = ""
	var/wall_icon = 'icons/turf/walls.dmi'
	var/wall_icon_state = ""
	var/static/list/icons = list("ancient wall" = 'icons/misc/worlds.dmi')
	var/static/list/states = list("ancient wall" = "ancientwall", "cave wall" = "cave-dark", "normal wall" = null, "reinforced wall" = "r_wall")

	initialize()
		var/wall_type = input("Wall type", "Wall type", "normal wall") in states
		wall_icon_state = states[wall_type]
		if (wall_type in icons)
			wall_icon = icons[wall_type]
		wall_name = input("Wall name", "Wall name", "strange wall") as text
		boutput(usr, "<span style=\"color:blue\">Left click to place walls. Ctrl+click anywhere to finish.</span>")

	build_click(var/mob/user, var/datum/buildmode_holder/holder, var/list/pa, var/atom/object)
		if (pa.Find("left"))
			var/turf/T = get_turf(object)
			if (pa.Find("ctrl"))
				finished = 1
				return
			if (T)
				var/obj/adventurepuzzle/triggerable/wall/wall = new /obj/adventurepuzzle/triggerable/wall(T)
				wall.name = wall_name
				wall.icon = wall_icon
				wall.icon_state = wall_icon_state

/obj/adventurepuzzle/triggerable/wall
	name = "wall"
	desc = "A wall. Something seems off about it."
	density = 1
	opacity = 1
	anchored = 1
	icon_state = "door_normal_closed"
	var/sliding = 0

	var/static/list/triggeracts = list("Do nothing" = "nop", "Slide down" = SOUTH, "Slide left" = WEST, "Slide right" = EAST, "Slide up" = NORTH)

	trigger_actions()
		return triggeracts

	trigger(var/act)
		if (isnum(act))
			src.slide(act)

	proc/slide(var/slide_dir)
		if (sliding)
			return
		sliding = 1
		var/obj/adventurepuzzle/triggerable/wall/waiting = null
		var/turf/target = get_step(src, slide_dir)
		if (!target || target.density)
			sliding = 0
			return
		for (var/atom/A in target)
			if (!istype(A, /obj/adventurepuzzle/triggerable/wall) && A.density)
				sliding = 0
				return
		waiting = locate() in target
		if (!waiting)
			set_loc(target)
			sliding = 0
			return
		else
			spawn(0)
				var/waited = 0
				while (waiting && waiting.sliding)
					waited++
					if (waited == 5)
						break
					sleep(1)
				if (waiting.loc != target)
					set_loc(target)
				sliding = 0
				return

	attack_hand(mob/user as mob)
		usr.show_message("<span style=\"color:red\">[src] seems to be movable, but you cannot muster the strength to displace it.</span>")