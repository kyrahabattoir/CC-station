// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/forcefield
	icon = 'icons/obj/doors/forcefield.dmi'
	icon_state = "portal_off"
	name = "Forcefield"
	desc = "An energy barrier with an automated ID-scanner."
	density = 1
	opacity = 0
	anchored = 1
	layer = FLOOR_EQUIP_LAYER1
	var/set_active = 1 		  //Did players (de)activate it?
	var/active = 1	   		  //Actual current status.
	var/overloaded = 0 		  //Did AI/Robots Overload it?

	Topic(href, href_list)
		..()
		if (href_list["close"])
			usr << browse(null, "window=forcefield")
			if (usr.machine == src) usr.machine = null
			src.updateUsrDialog()
			return

		if (href_list["shock_on"])
			overloaded = 1
			if(!overlays.len)
				overlays += icon('icons/obj/doors/forcefield.dmi',"overloaded")

		if (href_list["shock_off"])
			overloaded = 0
			overlays = null

		if (href_list["activate"])
			set_active = 1
			if(powered())
				turn_on()

		if (href_list["deactivate"])
			set_active = 0
			turn_off()

		attack_ai(usr)
		return

	process()
		if(stat & NOPOWER || !active)
			turn_off()
			return

		if(set_active)
			turn_on()
		else
			turn_off()

		use_power(300)
		return

	power_change()
		if(powered())
			if(set_active)
				turn_on()
			else
				turn_off()
			stat &= ~NOPOWER
		else
			turn_off()
			stat |= NOPOWER
		return

	proc/turn_on()
		active = 1
		density = 1
		icon_state = "portal_on"
		if(overloaded && !overlays.len) overlays += icon('icons/obj/doors/forcefield.dmi',"overloaded")
		return

	proc/turn_off()
		active = 0
		density = 0
		icon_state = "portal_off"
		if(overloaded) overlays = null
		return

	attack_ai(mob/user)
		var/html = "<B>Forcefield Control:</B><br><br><br>"

		if(!overloaded)
			html += "<p><a href='?src=\ref[src];shock_on=1'>Overload Forcefield</a></p><br><br>"
		else
			html += "<p><a href='?src=\ref[src];shock_off=1'>Normalize Forcefield</a></p><br><br>"

		if(powered())
			if(set_active)
				html += "<p><a href='?src=\ref[src];deactivate=1'>Deactivate Forcefield</a></p><br><br>"
			else
				html += "<p><a href='?src=\ref[src];activate=1'>Activate Forcefield</a></p><br><br>"
		else
			html += "<p>Can not change state - Forcefield is offline.</p><br><br>"

		html += "<p><a href='?src=\ref[src];close=1'>Close</a></p>"
		user << browse(html, "window=forcefield")

		return

	attackby(obj/item/W as obj, mob/user as mob)
		playsound(src, "sound/effects/shieldhit2.ogg", 40, 1)
		return

	proc/shock(var/mob/A)
		if(!A) return
		for(var/mob/M in view(A))
			boutput(M, "<span style=\"color:red\">[A] was shocked by [src]!</span>")
		boutput(A, "<span style=\"color:red\">[src] shocks you.</span>")
		A.TakeDamage("All", 0, 75)
		if(hasvar(A,"weakened")) A:weakened += 10
		var/dirmob = turn(A.dir,180)
		var/location = get_turf(A)
		var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
		s.set_up(3, 1, location)
		s.start()
		step(A,dirmob)
		spawn(5) step(A,dirmob)
		playsound(src, "sound/effects/shieldhit2.ogg", 40, 1)
		return 0

	attack_hand(mob/user as mob)

		if(overloaded)
			shock(user)
			return

		if(src.allowed(user, req_only_one_required))
			if(set_active)
				set_active = 0
				turn_off()
				boutput(user, "<span style=\"color:blue\">You deactivate the forcefield.</span>")
			else
				set_active = 1
				if(powered())
					turn_on()
					boutput(user, "<span style=\"color:blue\">You activate the forcefield.</span>")
				else
					boutput(user, "<span style=\"color:blue\">You attempt to activate the forcefield but its not powered.</span>")

	CanPass(atom/A, turf/T)
		if (!active) return 1
		if (istype(A, /mob/living))

			if(A:stat == 2) return 1

			if(overloaded)
				shock(A)
				return

			if(src.allowed(A, req_only_one_required))
				return 1
			else
				return 0
		return 0

	meteorhit(var/obj/O as obj)
		playsound(src, "sound/effects/shieldhit2.ogg", 40, 1)
		set_active = 0
		turn_off()
		return