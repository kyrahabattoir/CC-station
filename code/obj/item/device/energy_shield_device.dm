// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/device/energy_shield
	//TO-DO : Bullets. Direct attacks.
	name = "Centcom prototype energy-shield"
	icon_state = "enshield0"
	flags = FPRINT | TABLEPASS| CONDUCT  | ONBELT
	item_state = "electronic"
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 2.0
	mats = 10
	var/active = 0
	var/protection = 25
	var/mob/user = null
	var/image/shield_overlay = null

	New()
		work()

	dropped(mob/user as mob)
		turn_off()
		return

	pickup(mob/user)
		return

	equipped(var/mob/user, var/slot)
		return

	attack_self()
		if(!active)
			boutput(usr, "<span style=\"color:blue\">You activate the shield.</span>")
			turn_on(usr)
		else
			boutput(usr, "<span style=\"color:blue\">You deactivate the shield.</span>")
			turn_off()
		return

	proc

		protect()
			if(!active)
				return 0
			else
				boutput(user, "<span style=\"color:red\">The impact temporarily weakens the shield.</span>")
				var/pre_protect = protection
				protection -= 5
				spawn(300) protection += 5
				return max(pre_protect,0)

		turn_off()
			if(user)
				user.underlays -= shield_overlay
				user.energy_shield = null
				shield_overlay = null
			user = null
			active = 0
			icon_state = "enshield0"

		turn_on(var/mob/user2)

			if(user2.energy_shield)
				boutput(user2, "<span style=\"color:red\">Cannot activate more than one shield.</span>")
				return

			user = user2
			if(!can_use())
				turn_off()
				return
			icon_state = "enshield1"
			user.energy_shield = src
			shield_overlay = image('icons/effects/effects.dmi',user,"enshield",MOB_LAYER+1)
			user.underlays += shield_overlay
			active = 1

		work()
			if(!can_use())
				turn_off()
				return
			spawn(10) work()

		can_use()
			if(!user || !ismob(loc)) return 0
			if(src in user.get_equipped_items())
				return 1
			else
				return 0