// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/gun/russianrevolver
	desc = "Fun for the whole family!"
	name = "\improper Russian revolver"
	icon_state = "revolver"
	w_class = 3.0
	throw_speed = 2
	throw_range = 10
	m_amt = 2000
	contraband = 0
	var/shotsLeft = 0
	var/shotsMax = 6

	New()
		src.shotsLeft = rand(1,shotsMax)
		..()
		return

	/*
	examine()
		set src in usr
		src.desc = text("Harmless fun")
		..()
		return
	*/

	attack_self(mob/user as mob)
		reload_gun(user)


	attack(mob/M as mob, mob/user as mob)
		fire_gun(user)

	proc/fire_gun(mob/user as mob)
		if(src.shotsLeft > 1)
			src.shotsLeft--
			for(var/mob/O in AIviewers(user, null))
				if (O.client)
					O.show_message("<span style=\"color:red\">[user] points the gun at \his head. Click!</span>", 1, "<span style=\"color:red\">Click!</span>", 2)

			return 0
		else if(src.shotsLeft == 1)
			src.shotsLeft = 0
			playsound(user, "sound/weapons/Gunshot.ogg", 100, 1)
			for(var/mob/O in AIviewers(user, null))
				if (O.client)	O.show_message("<span style=\"color:red\"><B>BOOM!</B> [user]'s head explodes.</span>", 1, "<span style=\"color:red\">You hear someone's head explode.</span>", 2)
				user.TakeDamage("head", 300, 0)
				take_bleeding_damage(user, null, 500, DAMAGE_STAB)
			return 1
		else
			boutput(user, "<span style=\"color:blue\">You need to reload the gun.</span>")
			return 0

	proc/reload_gun(mob/user as mob)
		if(src.shotsLeft <= 0)
			user.visible_message("<span style=\"color:blue\">[user] finds a bullet on the ground and loads it into the gun, spinning the cylinder.</span>", "<span style=\"color:blue\">You find a bullet on the ground and load it into the gun, spinning the cylinder.</span>")
			src.shotsLeft = rand(1, shotsMax)
		else if(src.shotsLeft >= 1)
			user.visible_message("<span style=\"color:blue\">[user] spins the cylinder.</span>", "<span style=\"color:blue\">You spin the cylinder.</span>")
			src.shotsLeft = rand(1, shotsMax)

/obj/item/gun/russianrevolver/fake357
	name = "revolver"
	shotsMax = 1 //griff

	New()
		desc = "There are [rand(2,7)] bullets left! Each shot will currently use 1 bullets!"
		..()

	pixelaction(atom/target, params, mob/user, reach)
		if(target.loc != user)
			if(src.fire_gun(user))
				user.show_text("That gun DID look a bit dodgy, after all!", "red")
				user.playsound_local(user, 'sound/misc/trombone.ogg', 50, 1)

	attack_self(mob/user)
		if(!shotsLeft)
			..()