// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/obj/machinery/noise_switch/attackby(obj/item/W, mob/user as mob)
	if(istype(W, /obj/item/device/detective_scanner))
		return
	return src.attack_hand(user)

/obj/machinery/noise_switch/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	use_power(5)
	for(var/obj/machinery/noise_maker/M in machines)
		if (M.ID == src.ID)
			if(rep == 1)
				M.containment_fail = 1
				M.sound = 3
			M.emittsound()
	src.add_fingerprint(user)

/obj/machinery/noise_switch/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/noise_switch/attackby(obj/item/W, mob/user)
	user.visible_message("<span style=\"color:red\">The [src.name] has been hit with the [W.name] by [user.name]!</span>", "<span style=\"color:red\">You hit the [src.name] with your [W.name]!</span>")


/obj/machinery/noise_switch/process()
//	if(rep == 0)
//		for (var/obj/X in orange(4,src))
//			if(istype(X,/obj/machinery/the_singularity/))
//				for(var/obj/machinery/noise_maker/M in machines)
//					rep = 1
//					M.containment_fail = 1
//					M.sound = 3
//					M.emittsound()
//				for(var/obj/machinery/field_generator/T in machines)
//					T.Varedit_start = 1
	qdel(src)



/obj/machinery/noise_maker/attack_hand(mob/user as mob)
//	playsound(src.loc, "sound/effects/Explosion1.ogg", 100, 1)
	src.add_fingerprint(user)

/obj/machinery/noise_maker/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/wirecutters))
		playsound(src.loc, "sound/items/Wirecutter.ogg", 60, 1)
		if(broken)
			broken = 0
			icon_state = "nm n +o"
			user.visible_message("<span style=\"color:red\">The [src.name] has been connected by [user.name]!</span>", "<span style=\"color:red\">You connect the [src.name]!</span>")
		else
			broken = 1
			icon_state = "nm n -o"
			user.visible_message("<span style=\"color:red\">The [src.name] has been disconnected by [user.name]!</span>", "<span style=\"color:red\">You disconnect the [src.name]!</span>")

	else
		src.add_fingerprint(user)
		user.visible_message("<span style=\"color:red\">The [src.name] has been hit with the [W.name] by [user.name]!</span>", "<span style=\"color:red\">You hit the [src.name] with your [W.name]!</span>")

//Add when it gets emagged it perma shuts it off

/obj/machinery/noise_maker/proc/emittsound()
	if(broken == 0)
//		if(((src.last_shot + src.fire_delay) <= world.time))
//			src.last_shot = world.time
		if(sound == 0)
			playsound(src.loc, "sound/misc/null.ogg", 100, 1)
		else if(sound == 1)
			playsound(src.loc, "sound/effects/screech.ogg", 100, 1)
		else if(sound == 2)
			playsound(src.loc, "sound/misc/burp.ogg", 100, 1)
		else if(sound == 3)
			playsound(src.loc, "sound/effects/screech2.ogg", 100, 5,0)
	if(containment_fail == 1)
		spawn(90)
		emittsound()