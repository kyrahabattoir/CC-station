// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/puzzlewizard/pressurepad
	name = "AB CREATE: Pressure pad"
	var/color_rgb = ""
	var/button_type
	var/button_name
	var/button_density = ""
	var/list/selected_triggerable = list()
	var/list/selected_triggerable_untrigger = list()
	var/selection

	initialize()
		selection = unpool(/obj/adventurepuzzle/marker)
		button_type = input("Pad type", "Pad type", "ancient") in list("ancient", "runes")
		color_rgb = input("Color", "Color", "#ffffff") as color
		button_name = input("Pressure pad name", "Pressure pad name", "pressure pad") as text
		boutput(usr, "<span style=\"color:blue\">Left click to place pressure pads, right click triggerables to (de)select them for automatic assignment to the pressure pads. Ctrl+click anywhere to finish.</span>")
		boutput(usr, "<span style=\"color:blue\">NOTE: Select stuff first, then make pressure pads for extra comfort!</span>")

	proc/clear_selections()
		for (var/obj/O in selected_triggerable)
			O.overlays -= selection
		selected_triggerable.len = 0

	disposing()
		clear_selections()
		pool(selection)

	build_click(var/mob/user, var/datum/buildmode_holder/holder, var/list/pa, var/atom/object)
		if (pa.Find("left"))
			var/turf/T = get_turf(object)
			if (pa.Find("ctrl"))
				finished = 1
				clear_selections()
				return
			if (T)
				var/obj/adventurepuzzle/triggerer/twostate/pressurepad/button = new /obj/adventurepuzzle/triggerer/twostate/pressurepad(T)
				button.name = button_name
				button.icon_state = "pressure_[button_type]_unpressed"
				button.pad_type = button_type
				button.triggered = selected_triggerable.Copy()
				button.triggered_unpress = selected_triggerable_untrigger.Copy()
				spawn(10)
					button.color = color_rgb
		else if (pa.Find("right"))
			if (istype(object, /obj/adventurepuzzle/triggerable))
				if (object in selected_triggerable)
					object.overlays -= selection
					selected_triggerable -= object
					selected_triggerable_untrigger -= object
				else
					var/list/actions = object:trigger_actions()
					if (islist(actions) && actions.len)
						var/act_name = input("Do what on press?", "Do what?", actions[1]) in actions
						var/act = actions[act_name]
						var/unact_name = input("Do what on unpress?", "Do what?", actions[1]) in actions
						var/unact = actions[unact_name]
						object.overlays += selection
						selected_triggerable += object
						selected_triggerable[object] = act
						selected_triggerable_untrigger += object
						selected_triggerable_untrigger[object] = unact
					else
						boutput(usr, "<span style=\"color:red\">ERROR: Missing actions definition for triggerable [object].</span>")

/obj/adventurepuzzle/triggerer/twostate/pressurepad
	icon = 'icons/obj/randompuzzles.dmi'
	name = "pressure pad"
	desc = "A pressure pad. Ominous."
	icon_state = "pressure_ancient_unpressed"
	density = 0
	opacity = 0
	anchored = 1
	var/pad_type
	var/pressed = 0
	var/list/pressing = list()

	Crossed(atom/movable/O)
		if (istype(O, /mob/living) && !(O in pressing) && O.loc == loc)
			pressing += O
			press()
		else if (istype(O, /obj) && !(O in pressing) && O.loc == loc)
			if (O.density || istype(O, /obj/critter) || istype(O, /obj/machinery/bot))
				pressing += O
				press()

	Uncrossed(atom/movable/O)
		if (O in pressing)
			pressing -= O
			for (var/atom/movable/Q in pressing)
				if (Q.loc != src.loc)
					pressing -= Q
			if (pressing.len == 0)
				unpress()

	proc/press()
		if (pressed)
			return
		pressed = 1
		flick("pressure_[pad_type]_pressing", src)
		spawn(5)
			icon_state = "pressure_[pad_type]_pressed"
			post_trigger()

	proc/unpress()
		if (!pressed)
			return
		pressed = 0
		flick("pressure_[pad_type]_unpressing", src)
		spawn(5)
			icon_state = "pressure_[pad_type]_unpressed"
			post_untrigger()

	serialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		..()
		F["[path].pad_type"] << pad_type

	deserialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		. = ..()
		F["[path].pad_type"] >> pad_type
		return . | DESERIALIZE_NEED_POSTPROCESS

	deserialize_postprocess()
		..()
		for (var/atom/A as obj|mob in src.loc)
			if (A == src)
				continue
			if (istype(A, /mob/living) && A.density)
				src.pressing += A
			else if (isobj(A) && A.density)
				src.pressing += A
		if (src.pressing.len)
			icon_state = "pressure_[pad_type]_pressed"