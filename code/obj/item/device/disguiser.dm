// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/device/disguiser
	name = "holographic disguiser"
	icon_state = "enshield0"
	desc = "Experimental device that projects a hologram of a randomly generated appearance onto the user, hiding their real identity."
	flags = FPRINT | TABLEPASS| CONDUCT | EXTRADELAY | ONBELT
	item_state = "electronic"
	throwforce = 5
	throw_speed = 1
	throw_range = 5
	w_class = 2
	is_syndicate = 1
	mats = 8
	var/anti_spam = 1 // In relation to world time.
	var/on = 0

	var/customization_first_color = 0
	var/customization_second_color = 0
	var/customization_third_color = 0
	var/e_color = 0
	var/s_tone = 0
	var/cust1 = null
	var/cust2 = null
	var/cust3 = null

	dropped(mob/user)
		..()
		spawn(0) // Ported from cloaking device. Spawn call is necessary for some reason (Convair880).
			if (!src) return
			if (ismob(src.loc) && src.loc == user)
				if (ishuman(user))
					var/mob/living/carbon/human/H = user
					if (H.l_store && H.l_store == src)
						return
					if (H.r_store && H.r_store == src)
						return
					if (H.belt && H.belt == src)
						return
			src.disrupt(user)
			return

	attack_self(mob/user)
		if (!src.on && (src.anti_spam && world.time < src.anti_spam + 100))
			user.show_text("[src] is recharging!", "red")
			return
		if (ishuman(user))
			var/mob/living/carbon/human/H = user
			if (!H.bioHolder || !H.bioHolder.mobAppearance)
				H.show_text("This device is only designed to work on humans!", "red")
				return
			src.toggle(H)
		else
			user.show_text("This device is only designed to work on humans!", "red")
		return

	emp_act()
		if (ishuman(src.loc))
			var/mob/living/carbon/human/H = src.loc
			if (!H.bioHolder || !H.bioHolder.mobAppearance)
				return
			H.visible_message("<span style=\"color:blue\"><b>[H]'s [src.name] is disrupted!</b></span>")
			src.disrupt(H)
		return

	// Added to 1) fix a couple bugs and 2) cut down on duplicate code.
	// Also cleaned up the code a bit in general (Convair880).
	proc/change_appearance(var/mob/living/carbon/human/user, var/reset_to_normal = 0)
		if (!src || !user || !ishuman(user))
			return
		var/datum/appearanceHolder/AH = user.bioHolder.mobAppearance
		if (!AH || !istype(AH, /datum/appearanceHolder))
			return

		// Store current appearance and generate new one.
		if (!reset_to_normal)
			src.real_name = user.real_name
			src.s_tone = AH.s_tone
			src.cust1 = AH.customization_first
			src.cust2 = AH.customization_second
			src.cust3 = AH.customization_third
			src.customization_first_color = AH.customization_first_color
			src.customization_second_color = AH.customization_second_color
			src.customization_third_color = AH.customization_third_color
			src.e_color = AH.e_color

			randomize_look(user, 0, 0, 0, 1, 0, 0) // randomize: gender 0, blood type 0, age 0, name 1, underwear 0, remove effects 0

		// Restore original appearance.
		else
			user.real_name = src.real_name
			AH.s_tone = src.s_tone
			AH.customization_first = src.cust1
			AH.customization_second = src.cust2
			AH.customization_third = src.cust3
			AH.customization_first_color = src.customization_first_color
			AH.customization_second_color = src.customization_second_color
			AH.customization_third_color = src.customization_third_color
			AH.e_color = src.e_color

			AH.UpdateMob()
			if (user.limbs)
				user.limbs.reset_stone()
			user.set_face_icon_dirty()
			user.set_body_icon_dirty()
			user.update_inhands()
			user.update_clothing()

		return

	proc/disrupt(mob/living/carbon/human/user)
		if (!src)
			return
		if (src.on)
			src.icon_state = "enshield0"
			src.on = 0

			if (!user || !ishuman(user))
				return
			var/datum/appearanceHolder/AH = user.bioHolder.mobAppearance
			if (!AH || !istype(AH, /datum/appearanceHolder))
				return

			var/datum/effects/system/spark_spread/spark_system = unpool(/datum/effects/system/spark_spread)
			spark_system.set_up(5, 0, src)
			spark_system.attach(user)
			spark_system.start()

			src.change_appearance(user, 1)
			src.anti_spam = world.time
		return

	proc/toggle(mob/living/carbon/human/user)
		if (!src || !user || !ishuman(user))
			return
		var/datum/appearanceHolder/AH = user.bioHolder.mobAppearance
		if (!AH || !istype(AH, /datum/appearanceHolder))
			return

		if (src.on)
			src.icon_state = "enshield0"
			src.on = 0

			var/datum/effects/system/spark_spread/spark_system = unpool(/datum/effects/system/spark_spread)
			spark_system.set_up(5, 0, src)
			spark_system.attach(user)
			spark_system.start()

			user.show_text("You deactivate the [src.name].", "blue")
			src.change_appearance(user, 1)
			src.anti_spam = world.time

			var/obj/overlay/T = new/obj/overlay(get_turf(src))
			T.icon = 'icons/effects/effects.dmi'
			flick("emppulse",T)
			spawn (8)
				if (T) qdel(T)

		else

			// Multiple active devices can lead to weird effects, okay (Convair880).
			var/list/number_of_devices = list()
			for (var/obj/item/device/disguiser/D in user)
				if (D.on)
					number_of_devices += D
			if (number_of_devices.len > 0)
				user.show_text("You can't have more than one active [src.name] on your person.", "red")
				return

			src.on = 1
			src.icon_state = "enshield1"

			user.show_text("You active the [src.name]", "blue")
			src.change_appearance(user, 0)
			src.anti_spam = world.time

			var/obj/overlay/T = new/obj/overlay(get_turf(src))
			T.icon = 'icons/effects/effects.dmi'
			flick("emppulse",T)
			spawn (8)
				if (T) qdel(T)

		return