// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/*
/mob/proc/jack_in()
	set category = "Local"
	set name="Enter V-space"

	if (!ismob(usr)) return
	if (!usr.client) return
	if (!usr.network_device) return

	if (usr.stat != 0 || usr.stunned !=0)
		return

	var/mob/living/user = usr
	if (user.network_device)
		var/datum/v_space/V
		V.Enter_Vspace(user, user.network_device)
	return

/mob/proc/jack_out()
	set category = "Local"
	set name="Exit V-space"

	if (!ismob(usr)) return
	if (!usr.client) return
	if (!istype(usr, /mob/living/carbon/human/virtual/)) return

	var/datum/v_space/V
	V.Leave_Vspace(usr)
	return*/

// Logout buttons were discontinued because...?? Well, here they are again (Convair880).
/obj/death_button/VR_logout_button
	name = "Leave VR"
	desc = "Press this button to log out of virtual reality."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "party"

	attack_hand(mob/user as mob)
		if (!ismob(user) || !user.client || !istype(user, /mob/living/carbon/human/virtual/))
			return
		src.add_fingerprint(user)

		// Won't delete the VR character otherwise, which can be confusing (detective's goggles sending you to the existing body in the bomb VR etc).
		user.stat = 2

		Station_VNet.Leave_Vspace(user)
		return

var/global/datum/v_space/v_space_network/Station_VNet

datum/v_space
	var
		active = 0
		list/users = list()			  //Who is in V-space
		list/inactive_bodies = list() //Spare virtual bodies. waste not want not


	v_space_network
		active = 1


	proc/Enter_Vspace(var/mob/user as mob, var/network_device, var/network)
	//Who is entering, What they are using to enter, Which network are they entering
		if(!active)
			boutput(user, "<span style=\"color:red\">Unable to connect to the Net!</span>")
			return
		if(!network_device)
			boutput(user, "<span style=\"color:red\">You lack a device able to connect to the net!</span>")
			return
		if(!user:client)
			return
		if(isnull(user:mind))
			boutput(user, "<span style=\"color:red\">You don't have a mind!</span>")
			return

//		var/range_check = In_Network(user, network_device, network)
//		if(!range_check)
//			boutput(user, "<span style=\"color:red\">Out of network range!</span>")
//			return

		var/obj/landmark/B = null
		for (var/obj/landmark/A in world)
			if (A.name == network)
				B = A
				break
		if(!B)//no entry landmark
			boutput(user, "<span style=\"color:red\">Invalid network!</span>")
			return

		var/mob/living/carbon/human/character
		if (user.mind.virtual)
			var/mob/living/carbon/human/virtual/V = user.mind.virtual
			V.body = user
			user.mind.transfer_to(V)
			character = V
			user.visible_message("<span style=\"color:blue\"><b>[user] logs in!</b></span>")
		else
			character = create_Vcharacter(user, network_device, network)
			character.set_loc(B.loc)
			user.visible_message("<span style=\"color:blue\"><b>[user] logs in!</b></span>")
		users.Add(character)
		// Made much more prominent due to frequent a- and mhelps (Convair880).
		character.show_text("<h2><font color=red><B>Death in virtual reality will result in a log-out. You can also press one of the logout buttons to leave.</B></font></h2>", "red")
		alert(character, "Death in virtual reality will result in a log-out, and you can also press one of the logout buttons to leave. Enjoy your stay.", "Now entering V-space")
		return


	proc/Leave_Vspace(var/mob/living/carbon/human/virtual/user)
		if (user.client)
			user.client.view = 7
		for(var/mob/O in oviewers())
			boutput(O, "<span style=\"color:red\"><b>[user] logs out!</b></span>")
		if (istype(user.loc,/obj/racing_clowncar/kart))
			var/obj/racing_clowncar/kart/car = user.loc
			car.reset()
		if (user.stat == 2)
			for (var/obj/item/I in user)
				// Stop littering the place with VR skulls and organs, aaahh (Convair880).
				if (istype(I,/obj/item/clothing/glasses/vr_fake) || istype(I, /obj/item/parts) || istype(I, /obj/item/organ) || istype(I, /obj/item/skull) || istype(I, /obj/item/clothing/head/butt))
					continue
				if (I != user.w_uniform && I != user.shoes)
					user.u_equip(I)
					if (I) //I don't know of any items that delete themselves on drop BUT HEY
						I.set_loc(user.loc)
						I.layer = initial(I.layer)
		users.Remove(user)
		if (user.mind && user.body)
			user.mind.transfer_to(user.body)
			user.body = null
		else
			user.ghostize()

		if (user.stat == 2)
			del(user)
/*
		if(!user.client)
			inactive_bodies += user
			user.body = null
			user.set_loc(null)
			return 0
*/
		return 1


	proc/In_Network(var/mob/user, var/networkdevice)
		for(var/obj/machinery/sim/transmitter/T in orange(10,networkdevice))
			if(T.active == 1)
				return 1
		return 0


	proc/create_Vcharacter(var/mob/user, var/network_device, var/network)
		var/mob/living/carbon/human/virtual/virtual_character

		if (inactive_bodies.len)
			virtual_character = inactive_bodies[1]
			inactive_bodies -= virtual_character
			virtual_character.full_heal()
		else
			virtual_character = new(src)

		virtual_character.network_device = network_device
		virtual_character.body = user
		virtual_character.Vnetwork = network

		if(istype(user,/mob/living/carbon/human))
			copy_to(virtual_character, user)
			var/clothing_color = pick("#FF0000","#FFFF00","#00FF00","#00FFFF","#0000FF","#FF00FF")
			var/obj/item/clothing/under/virtual/C = new
			var/obj/item/clothing/shoes/virtual/S = new
			C.set_loc(virtual_character)
			S.set_loc(virtual_character)
			C.color = clothing_color
			S.color = clothing_color
			virtual_character.equip_if_possible( C, virtual_character.slot_w_uniform )
			virtual_character.equip_if_possible( S, virtual_character.slot_shoes)
		virtual_character.real_name = "Virtual [user.real_name]"
		user.mind.virtual = virtual_character
		user.mind.transfer_to(virtual_character)
		spawn (8)
			virtual_character.update_face()
			virtual_character.update_body()
			virtual_character.update_clothing()
		return virtual_character


	proc/copy_to(var/mob/living/carbon/human/virtual/character, var/mob/living/carbon/human/user )
//		character.real_name = "Virtual [user.real_name]"
		character.bioHolder.mobAppearance.gender = user.gender
		character.gender = user.gender
		character.bioHolder.age = user.bioHolder.age
		character.pin = user.pin
		character.bioHolder.bloodType = user.bioHolder.bloodType
		character.bioHolder.mobAppearance.e_color = user.bioHolder.mobAppearance.e_color
		character.bioHolder.mobAppearance.customization_first_color = user.bioHolder.mobAppearance.customization_first_color
		character.bioHolder.mobAppearance.customization_second_color = user.bioHolder.mobAppearance.customization_second_color
		character.bioHolder.mobAppearance.customization_third_color = user.bioHolder.mobAppearance.customization_third_color
		character.bioHolder.mobAppearance.s_tone = user.bioHolder.mobAppearance.s_tone
		character.bioHolder.mobAppearance.customization_first = user.bioHolder.mobAppearance.customization_first
		character.bioHolder.mobAppearance.customization_second = user.bioHolder.mobAppearance.customization_second
		character.bioHolder.mobAppearance.customization_third = user.bioHolder.mobAppearance.customization_third
		if(user.bioHolder.mobAppearance.customization_first in customization_styles)
			character.cust_one_state = customization_styles[user.bioHolder.mobAppearance.customization_first]
		else
			character.cust_one_state = "None"

		if(user.bioHolder.mobAppearance.customization_second in customization_styles)
			character.cust_two_state = customization_styles[user.bioHolder.mobAppearance.customization_second]
		else
			character.cust_two_state = "None"

		if(user.bioHolder.mobAppearance.customization_third in customization_styles)
			character.cust_two_state = customization_styles[user.bioHolder.mobAppearance.customization_third]
		else
			character.cust_two_state = "none"

		character.bioHolder.mobAppearance.underwear = user.bioHolder.mobAppearance.underwear
		character.bioHolder.mobAppearance.u_color = user.bioHolder.mobAppearance.u_color

		character.bioHolder.mobAppearance.UpdateMob()


		return








