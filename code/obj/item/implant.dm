// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/*
CONTAINS:

IMPLANTS
IMPLANTER
IMPLANT CASE
IMPLANT PAD
IMPLANT GUN
*/
/* ================================================================== */
/* ------------------------- Implant Parent ------------------------- */
/* ================================================================== */

/obj/item/implant
	name = "implant"
	icon = 'icons/obj/surgery.dmi'
	icon_state = "implant-g"
	var/implanted = null
	var/impcolor = "g"
	var/owner = null
	var/mob/former_implantee = null
	var/image/implant_overlay = null

	proc/can_implant(mob/target, mob/user)
		return 1

	proc/trigger(emote, source as mob)
		return

	// called when an implant is implanted into M by I
	proc/implanted(mob/M, mob/I)
		logTheThing("combat", I, M, "has implanted %target% with a [src] implant ([src.type]) at [log_loc(M)].")
		if (implant_overlay)
			M.update_clothing()
		return

	// called when an implant is removed from M
	proc/on_remove(var/mob/M)
		if (ishuman(src.owner))
			var/mob/living/carbon/human/H = owner
			H.implant -= src
		src.owner = null
		return

	attackby(obj/item/I as obj, mob/user as mob)
		if (!istype(src, /obj/item/implant/projectile))
			if (istype(I, /obj/item/pen))
				var/t = input(user, "What would you like the label to be?", null, "[src.name]") as null|text
				if (!t)
					return
				if (user.equipped() != I)
					return
				if ((!in_range(src, usr) && src.loc != user))
					return
				t = copytext(adminscrub(t),1,128)
				if (t)
					src.name = "implant - '[t]'"
				return
			else if (istype(I, /obj/item/implanter))
				var/obj/item/implanter/Imp = I
				if (Imp.imp)
					return
				else
					user.u_equip(src)
					src.set_loc(Imp)
					Imp.imp = src
					Imp.update()
					user.show_text("You insert [src] into [Imp].")
				return
			else if (istype(I, /obj/item/implantcase))
				var/obj/item/implantcase/Imp = I
				if (Imp.imp)
					return
				else
					user.u_equip(src)
					src.set_loc(Imp)
					Imp.imp = src
					Imp.update()
					user.show_text("You insert [src] into [Imp].")
				return
			else
				return ..()
		else
			return ..()

/* ============================================================ */
/* ------------------------- Implants ------------------------- */
/* ============================================================ */

/obj/item/implant/health
	name = "health implant"
	icon_state = "implant-b"
	impcolor = "b"
	var/healthstring = ""

	var/message = null
	var/mailgroup = "medbay"
	var/mailgroup2 = "medresearch"
	var/net_id = null
	var/frequency = 1149
	var/datum/radio_frequency/radio_connection
	var/reported_health = 0
	var/reported_death = 0

	New()
		..()
		spawn(100)
			if (radio_controller)
				radio_connection = radio_controller.add_object(src, "[frequency]")
			if (!src.net_id)
				src.net_id = generate_net_id(src)

	proc/sensehealth()
		if (!src.implanted)
			return "ERROR"
		else
			var/mob/living/L
			if (ishuman(src.owner))
				L = src.owner
				src.healthstring = "[round(L.get_oxygen_deprivation())] - [round(L.get_toxin_damage())] - [round(L.get_burn_damage())] - [round(L.get_brute_damage())] | OXY-TOX-BURN-BRUTE"
			if (!src.healthstring)
				src.healthstring = "ERROR"
			return src.healthstring

	// add gps info proc here if tracker exists

	implanted(var/mob/M, var/mob/I)
		..()
		if (!ishuman(M))
			return
		var/mob/living/carbon/human/H = M
		H.mini_health_hud = 1
		H.show_text("You feel more in-tune with your body.", "blue")

	on_remove(var/mob/living/carbon/human/H)
		..()
		src.reported_health = 0
		src.reported_death = 0

	proc/health_alert()
		if (!src.owner)
			return
		if (src.reported_health)
			return
		var/myarea = get_area(src)
		src.message = "HEALTH ALERT: [src.owner] in [myarea]: [src.sensehealth()]"
		//DEBUG_MESSAGE("implant reporting crit")
		src.send_message()
		src.reported_health = 1

	proc/death_alert()
		if (!src.owner)
			return
		if (src.reported_death)
			return
		var/myarea = get_area(src)
		src.message = "DEATH ALERT: [src.owner] in [myarea]"
		//DEBUG_MESSAGE("implant reporting death")
		src.send_message()
		src.reported_death = 1

	proc/send_message()
		DEBUG_MESSAGE("sending message: [src.message]")
		if (message && mailgroup && radio_connection)
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "HEALTH-MAILBOT"
			newsignal.data["message"] = "[src.message]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup
			newsignal.data["sender"] = src.net_id

			radio_connection.post_signal(src, newsignal)
			//DEBUG_MESSAGE("message sent to [src.mailgroup]")

		if (message && mailgroup2 && radio_connection)
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "text_message"
			newsignal.data["sender_name"] = "HEALTH-MAILBOT"
			newsignal.data["message"] = "[src.message]"

			newsignal.data["address_1"] = "00000000"
			newsignal.data["group"] = mailgroup2
			newsignal.data["sender"] = src.net_id

			radio_connection.post_signal(src, newsignal)
			//DEBUG_MESSAGE("message sent to [src.mailgroup2]")

/obj/item/implant/freedom
	name = "freedom implant"
	icon_state = "implant-r"
	var/uses = 1.0
	impcolor = "r"
	var/activation_emote = "chuckle"

	New()
		src.activation_emote = pick("blink", "blink_r", "eyebrow", "chuckle", "twitch_s", "frown", "nod", "blush", "giggle", "grin", "groan", "shrug", "smile", "pale", "sniff", "whimper", "wink")
		src.uses = rand(1, 5)
		..()
		return

	trigger(emote, mob/source as mob)
		if (src.uses < 1)
			return 0

		if (emote == src.activation_emote)
			src.uses--
			boutput(source, "You feel a faint click.")

			if (source.handcuffed)
				var/obj/item/W = source.handcuffed
				source.handcuffed = null
				if (W)
					source.u_equip(W)
					W.set_loc(source.loc)
					source.update_clothing()
					if (W)
						W.layer = initial(W.layer)

			// Added shackles here (Convair880).
			if (ishuman(source))
				var/mob/living/carbon/human/H = source
				if (H.shoes && H.shoes.chained)
					var/obj/item/clothing/shoes/SH = H.shoes
					H.u_equip(SH)
					SH.set_loc(H.loc)
					H.update_clothing()
					if (SH)
						SH.layer = initial(SH.layer)

	implanted(mob/source as mob)
		..()
		source.mind.store_memory("Freedom implant can be activated by using the [src.activation_emote] emote, <B>say *[src.activation_emote]</B> to attempt to activate.", 0, 0)
		boutput(source, "The implanted freedom implant can be activated by using the [src.activation_emote] emote, <B>say *[src.activation_emote]</B> to attempt to activate.")

/obj/item/implant/tracking
	name = "tracking implant"
	var/frequency = 1451
	var/id = 1.0

/obj/item/implant/syn
	name = "syndicate implant"
	icon_state = "implant-r"
	impcolor = "r"

/obj/item/implant/robust
	name = "\improper Robusttec implant"
	icon_state = "implant-r"
	impcolor = "r"
	var/inactive = 0

/obj/item/implant/antirev
	name = "loyalty implant"
	icon_state = "implant-b"
	impcolor = "b"

/obj/item/implant/sec
	name = "security implant"
	icon_state = "implant-b"
	impcolor = "b"

/obj/item/implant/microbomb
	name = "microbomb implant"
	icon_state = "implant-r"
	impcolor = "r"
	var/activation_emote = "deathgasp"
	var/active = 0
	var/explosionPower = 1

	implanted(mob/source as mob)
		..()
		if(source.mind)
			source.mind.store_memory("Your [(explosionPower > 5) ? "macrobomb" : "microbomb"] implant will detonate upon death.", 0, 0)
		boutput(source, "The implanted [(explosionPower > 5) ? "macrobomb" : "microbomb"] implant will detonate upon unintentional death.")

	trigger(emote, mob/source as mob)
		if (!source || (source != src.loc) || (source.stat != 2 && prob(99)) || src.active)
			return
		if (emote == src.activation_emote)
			if(source.suiciding && prob(60)) //Probably won't trigger on suicide though
				source.visible_message("[source] emits a somber buzzing noise.")
				return
			. = 0
			for (var/obj/item/implant/microbomb/other_bomb in src.loc)
				other_bomb.active = 1 //This actually should include us, ok.
				.+= other_bomb.explosionPower //tally the total power we're dealing with here

			if (istype(src, /obj/item/implant/microbomb/macrobomb))
				source.visible_message("<span style=\"color:red\"><b>[source] emits a loud clunk!</b></span>")
			else source.visible_message("[source] emits a small clicking noise.")
			logTheThing("bombing", source, null, "triggered a micro-/macrobomb implant on death.")
			var/turf/T = get_turf(src)
			src.set_loc(null) //so we don't get deleted prematurely by the blast.

			source.transforming = 1

			var/obj/overlay/Ov = new/obj/overlay(T)
			Ov.anchored = 1 //Create a big bomb explosion overlay.
			Ov.name = "Explosion"
			Ov.layer = NOLIGHT_EFFECTS_LAYER_BASE
			Ov.pixel_x = -17
			Ov.icon = 'icons/effects/hugeexplosion.dmi'
			Ov.icon_state = "explosion"

			var/list/throwjunk = list() //List of stuff to throw as if the explosion knocked it around.
			var/cutoff = 0 //So we don't freak out and throw more than ~25 things and act like the old mass driver bug.
			for(var/obj/item/I in source)
				cutoff++
				I.set_loc(T)
				if(cutoff <= 25)
					throwjunk += I

			spawn(0) //Delete the overlay when finished with it.
				if(source)
					source.gib()

				for(var/obj/O in throwjunk) //Throw this junk around
					var/edge = get_edge_target_turf(T, pick(alldirs))
					O.throw_at(edge, 80, 4)

				sleep(15)
				qdel(Ov)
				qdel(src)

			T.hotspot_expose(800,125)
			//explosion(src, T, -1, -1, 2*explosionPower, 3*explosionPower)
			explosion_new(src, T, 1.7 * ( . + 1 ), 2) //The . is the tally of explosionPower in this poor slob.
			return

/obj/item/implant/microbomb/predator
	explosionPower = 2

/obj/item/implant/microbomb/macrobomb
	name = "macrobomb implant"
	explosionPower = 10

/obj/item/implant/robotalk
	name = "machine translator"
	icon_state = "implant-b"
	var/active = 0

	on_remove(var/mob/living/carbon/human/H)
		..()
		if(istype(H))
			H.robot_talk_understand = 0

		return

/obj/item/implant/bloodmonitor
	name = "blood monitor implant"
	icon_state = "implant-b"
	impcolor = "b"

/obj/item/implant/mindslave
	name = "mindslave implant"
	icon_state = "implant-r"
	impcolor = "r"
	var/uses = 1
	var/expire = 1
	var/expired = 0
	var/suppress_mindslave_popup = 0
	var/mob/implant_master = null // who is the person mindslaving the implanted person
	var/custom_orders = null // ex: kill the captain, dance constantly, don't speak, etc

	can_implant(var/mob/living/carbon/human/target, var/mob/user)
		if (!istype(target))
			return 0
		if (!implant_master)
			if (ismob(user))
				implant_master = user
			else
				return 0
		// all the stuff in here was added by Convair880, I just adjusted it to work with this can_implant() proc thing - haine
		var/mob/living/carbon/human/H = target
		if (!H.mind || !H.client)
			if (ismob(user)) user.show_text("[H] is braindead!", "red")
			return 0
		if (src.uses <= 0)
			if (ismob(user)) user.show_text("[src] has been used up!", "red")
			return 0
		// It might happen, okay. I don't want to have to adapt the override code to take every possible scenario (no matter how unlikely) into considertion.
		if (H.mind && ((H.mind.special_role == "vampthrall") || (H.mind.special_role == "spyslave")))
			if (ismob(user)) user.show_text("<b>[H] seems to be immune to being enslaved!</b>", "red")
			H.show_text("<b>You resist [implant_master]'s attempt to enslave you!</b>", "red")
			logTheThing("combat", H, implant_master, "resists %target%'s attempt to mindslave them at [log_loc(H)].")
			return 0
		// Necessary to get those expiration messages to trigger properly if the same mob is implanted again,
		// since mindslave implants have spawn()s  going on.
		if (src.former_implantee == H)
			if (istype(src.loc, /obj/item/implanter))
				var/obj/item/implanter/I = src.loc
				var/obj/item/implant/mindslave/MSnew = new src.type(I)
				I.imp = MSnew
				qdel(src)
			else if (istype(src.loc, /obj/item/gun/implanter))
				var/obj/item/gun/implanter/I = src.loc
				var/obj/item/implant/mindslave/MSnew = new src.type(src)
				I.my_implant = MSnew
				qdel(src)
		// Same here, basically. Multiple active implants is just asking for trouble.
		for (var/obj/item/implant/mindslave/MS in H.implant)
			if (!istype(MS))
				continue
			if (!MS.expire || (MS.expire && (MS.expired != 1)))
				if (H.mind && (H.mind.special_role == "mindslave"))
					remove_mindslave_status(H, "mslave", "override")
				else if (H.mind && H.mind.master)
					remove_mindslave_status(H, "otherslave", "override")
				var/obj/item/implant/mindslave/Inew = new MS.type(H)
				H.implant += Inew
				qdel(MS)
				src.suppress_mindslave_popup = 1
		return 1

	implanted(var/mob/M, var/mob/I)
		..()
		if (!ishuman(M) || (src.uses == 0))
			return

		if (src.expire && src.expired)
			src.expired = 0

/*
		for(var/obj/item/implant/IMP in M:implant)
			if(IMP.check_access_imp(5))
				boutput(I, "<span style=\"color:red\"><b>[M] seems immune to being enslaved!</b></span>")
				boutput(M, "<span style=\"color:red\"><b>Your security implant prevents you from being enslaved!</b></span>")
				return
*/
		boutput(M, "<span style=\"color:red\">A stunning pain shoots through your brain!</span>")
		M.stunned = 10
		M.weakened = 3

		if(M == I)
			boutput(M, "<span style=\"color:red\">You feel utterly strengthened in your resolve! You are the most important person in the universe!</span>")
			alert(M, "You feel utterly strengthened in your resolve! You are the most important person in the universe!", "YOU ARE REALY GREAT!!")
			return

		if (M.mind && ticker.mode)
			if (!M.mind.special_role)
				M.mind.special_role = "mindslave"
			if (!(M.mind in ticker.mode.Agimmicks))
				ticker.mode.Agimmicks += M.mind
			M.mind.master = I.ckey

		if (src.suppress_mindslave_popup)
			boutput(M, "<h2><span style=\"color:red\">You feel an unwavering loyalty to your new master, [I.real_name]! Do not tell anyone about this unless your new master tells you to!</span></h2>")
		else
			boutput(M, "<h2><span style=\"color:red\">You feel an unwavering loyalty to [I.real_name]! You feel you must obey \his every order! Do not tell anyone about this unless your master tells you to!</span></h2>")
			M << browse(grabResource("html/mindslave/implanted.html"),"window=antagTips;titlebar=1;size=600x400;can_minimize=0;can_resize=0")
		if (src.custom_orders)
			boutput(M, "<h2><span style=\"color:red\">[I.real_name]'s will consumes your mind! <b>\"[src.custom_orders]\"</b> It <b>must</b> be done!</span></h2>")

		if (expire)
			//25 minutes +/- 5
			spawn(600 * (25 + rand(-5,5)) )
				if (src && !ishuman(src.loc)) // Drop-all, gibbed etc (Convair880).
					if (src.expire && (src.expired != 1)) src.expired = 1
					return
				if (!src || !owner || (M != owner) || src.expired)
					return
				boutput(M, "<span style=\"color:red\">Your will begins to return. What is this strange compulsion [I.real_name] has over you? Yet you must obey.</span>")

				// 1 minute left
				spawn(600)
					if (src && !ishuman(src.loc))
						if (src.expire && (src.expired != 1)) src.expired = 1
						return
					if (!src || !owner || (M != owner) || src.expired)
						return
					// There's a proc for this now (Convair880).
					if (M.mind && M.mind.special_role == "mindslave")
						remove_mindslave_status(M, "mslave", "expired")
					else if (M.mind && M.mind.master)
						remove_mindslave_status(M, "otherslave", "expired")
					src.expired = 1
		return

	on_remove(var/mob/M)
		..()
		src.former_implantee = M
		if (src.expire) src.expired = 1
		return

	trigger(emote, mob/source as mob)
		if (!source || (source != src.loc) || (source.stat != 2 ))
			return

		if(emote == "deathgasp") //The neural shock of some jerk dying wears the implant down. Or some shit.
			src.uses = max(src.uses - 1, 0)

	proc/add_orders(var/orders)
		if (!orders || !istext(orders))
			return
		src.custom_orders = copytext(sanitize(html_encode(orders)), 1, MAX_MESSAGE_LEN)
		if (!(copytext(src.custom_orders, -1) in list(".", "?", "!")))
			src.custom_orders += "!"

/obj/item/implant/mindslave/super
	name = "mindslave DELUXE implant"
	expire = 0
	uses = 2

/obj/item/implant/projectile
	name = "bullet"
	w_class = 1.0
	icon = 'icons/obj/scrap.dmi'
	icon_state = "bullet"
	desc = "A spent bullet."
	var/bleed_timer = 0
	var/forensic_ID = null // match a bullet to a gun holy heckkkkk

	bullet_357
		name = ".357 round"
		desc = "A powerful revolver bullet, likely of criminal origin."

	bullet_357AP
		name = ".357 AP round"
		desc = "A highly illegal armor-piercing variant of the common .357 round."

	bullet_38
		name = ".38 round"
		desc = "An outdated police-issue bullet. Some anachronistic detectives still like to use these, for style."

	bullet_38AP
		name = ".38 AP round"
		desc = "A more powerful armor-piercing .38 round. Huh. Aren't these illegal?"

	bullet_308
		name = ".308 round"
		desc = "An old but very powerful rifle bullet."

	bullet_22
		name = ".22 round"
		desc = "A cheap, small bullet, often used for recreational shooting and small-game hunting."

	bullet_41
		name = ".41 round"
		desc = ".41? What the heck? Who even uses these anymore?"

	bullet_12ga
		name = "buckshot"
		desc = "A commonly-used load for shotguns."

	staple
		name = "staple"
		desc = "Well that's not very nice."

	shrapnel
		name = "shrapnel"
		icon = 'icons/obj/scrap.dmi'
		desc = "A bunch of jagged shards of metal."
		icon_state = "2metal2"

	dart
		name = "dart"
		icon = 'icons/obj/chemical.dmi'
		desc = "A small hollow dart."
		icon_state = "syringeproj"

/obj/item/implant/projectile/implanted(mob/living/carbon/C, var/mob/I, var/bleed_time = 60)
	if (!istype(C) || !isnull(I)) //Don't make non-organics bleed and don't act like a launched bullet if some doofus is just injecting it somehow.
		return

	if (C != src.owner)
		src.owner = C

	for (var/obj/item/implant/projectile/P in C)
		if (P.bleed_timer)
			P.bleed_timer = max(bleed_time, P.bleed_timer)
			return

	src.bleed_timer = bleed_time
	spawn(5)
//		boutput(C, "<span style=\"color:red\">You start bleeding!</span>") // the blood system takes care of this bit now
		src.bleed_loop()

/obj/item/implant/projectile/proc/bleed_loop() // okay it doesn't actually cause bleeding now but um w/e
	if (src.bleed_timer-- < 0)
		return

	if (!iscarbon(src.owner) || (src.loc != src.owner) || (src.owner:stat == 2))
		src.owner = null
		return

	var/mob/living/carbon/C = src.owner
	if (istype(C.loc, /turf/simulated))
		if(prob(35))
			random_brute_damage(C, 1)
		if(prob(1))
			C.emote("faint")
		if(prob(4))
			C.emote(pick("pale", "shiver"))
		if(prob(4))
			boutput(C, "<span style=\"color:red\">You feel a [pick("sharp", "stabbing", "startling", "worrying")] pain in your chest![pick("", " It feels like there's something lodged in there!", " There's gotta be something stuck in there!", " You feel something shift around painfully!")]</span>")

	spawn(rand(40,70))
		src.bleed_loop()
	return

/* ============================================================= */
/* ------------------------- Implanter ------------------------- */
/* ============================================================= */

/obj/item/implanter
	name = "implanter"
	desc = "An implanting tool, used to implant people or animals with various implants."
	icon = 'icons/obj/surgery.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	icon_state = "implanter0"
	var/obj/item/implant/imp = null
	item_state = "syringe_0"
	throw_speed = 1
	throw_range = 5
	w_class = 2.0

	New()
		..()
		src.update()
		return

	get_desc(dist)
		if (dist <= 1 && src.imp)
			. += "It appears to contain \a [src.imp.name]."

	proc/update()
		if (src.imp)
			src.icon_state = src.imp.impcolor ? "implanter1-[imp.impcolor]" : "implanter1-g"
		else
			src.icon_state = "implanter0"
		return

	attack(mob/M as mob, mob/user as mob)
		if (!ishuman(M))
			return ..()

		if (src.imp && !src.imp.can_implant(M, user))
			return

		if (user && src.imp)
			M.tri_message("<span style=\"color:red\">[M] has been implanted by [user].</span>",\
			M, "<span style=\"color:red\">You have been implanted by [user].</span>",\
			user, "<span style=\"color:red\">You implanted the implant into [M].</span>")

			if (ishuman(M))
				var/mob/living/carbon/human/H = M
				H.implant.Add(src.imp)
				if (istype(src.imp, /obj/item/implant/robotalk))
					H.robot_talk_understand = 1

				if (ticker && ticker.mode && istype(ticker.mode, /datum/game_mode/revolution))
					if (istype(src.imp, /obj/item/implant/antirev))
						if (H.mind in ticker.mode:head_revolutionaries)
							H.visible_message("<span style=\"color:red\">[H] seems to resist the implant.</span>")
						else if (H.mind in ticker.mode:revolutionaries)
							ticker.mode:remove_revolutionary(H.mind)

			src.imp.set_loc(M)
			src.imp.implanted = 1
			src.imp.owner = M
			src.imp.implanted(M, user)

			src.imp = null
			src.update()
			return

/obj/item/implanter/sec
	icon_state = "implanter1-g"
	name = "Security Implanter"

	New()
		src.imp = new /obj/item/implant/sec( src )
		..()
		return

/obj/item/implanter/freedom
	icon_state = "implanter1-g"
	New()
		src.imp = new /obj/item/implant/freedom( src )
		..()
		return

/obj/item/implanter/mindslave
	icon_state = "implanter1-g"
	New()
		src.imp = new /obj/item/implant/mindslave( src )
		..()
		return

/obj/item/implanter/super_mindslave
	icon_state = "implanter1-g"
	New()
		src.imp = new /obj/item/implant/mindslave/super( src )
		..()
		return

/obj/item/implanter/microbomb
	name = "microbomb implanter"
	icon_state = "implanter1-g"
	New()
		src.imp = new /obj/item/implant/microbomb( src )

		..()
		return

/obj/item/implanter/macrobomb
	name = "macrobomb implanter"
	icon_state = "implanter1-g"
	New()
		src.imp = new /obj/item/implant/microbomb/macrobomb( src )
		..()
		return

/obj/item/implanter/uplink_macrobomb
	name = "macrobomb implanter"
	icon_state = "implanter1-g"
	New()
		var/obj/item/implant/microbomb/macrobomb/newbomb = new/obj/item/implant/microbomb/macrobomb( src )
		newbomb.explosionPower = rand(20,30)
		src.imp = newbomb
		..()
		return

/obj/item/implanter/uplink_microbomb
	name = "microbomb implanter"
	icon_state = "implanter1-g"
	New()
		var/obj/item/implant/microbomb/newbomb = new/obj/item/implant/microbomb( src )
		newbomb.explosionPower = prob(75) ? 2 : 3
		src.imp = newbomb
		..()
		return

/* ================================================================ */
/* ------------------------- Implant Case ------------------------- */
/* ================================================================ */

/obj/item/implantcase
	name = "glass case"
	desc = "A glass case containing the labelled implant. An implanting tool is used to extract the implant from this case, and then into a person."
	icon = 'icons/obj/surgery.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	icon_state = "implantcase-b"
	var/obj/item/implant/imp = null
	item_state = "implantcase"
	throw_speed = 1
	throw_range = 5
	w_class = 1.0
	var/implant_type = /obj/item/implant/tracking

/obj/item/implantcase/tracking
	name = "glass case - 'Tracking'"

/obj/item/implantcase/health
	name = "glass case - 'Health'"
	implant_type = "/obj/item/implant/health"

/obj/item/implantcase/sec
	name = "glass case - 'Security Access'"
	implant_type = "/obj/item/implant/sec"
/*
/obj/item/implantcase/nt
	name = "glass case - 'Weapon Auth 2'"
	implant_type = "/obj/item/implant/nt"

/obj/item/implantcase/ntc
	name = "glass case - 'Weapon Auth 3'"
	implant_type = "/obj/item/implant/ntc"
*/
/obj/item/implantcase/freedom
	name = "glass case - 'Freedom'"
	implant_type = "/obj/item/implant/freedom"

/obj/item/implantcase/antirev
	name = "glass case - 'Loyalty'"
	implant_type = "/obj/item/implant/antirev"

/obj/item/implantcase/microbomb
	name = "glass case - 'Microbomb'"
	implant_type = "/obj/item/implant/microbomb"

/obj/item/implantcase/microbomb/macrobomb
	name = "glass case - 'Macrobomb'"
	implant_type = "/obj/item/implant/microbomb/macrobomb"

/obj/item/implantcase/robotalk
	name = "glass case - 'Machine Translator'"
	implant_type = "/obj/item/implant/robotalk"

/obj/item/implantcase/bloodmonitor
	name = "glass case - 'Blood Monitor'"
	implant_type = "/obj/item/implant/bloodmonitor"

/obj/item/implantcase/mindslave
	name = "glass case - 'Mindslave'"
	implant_type = "/obj/item/implant/mindslave"

/obj/item/implantcase/super_mindslave
	name = "glass case - 'Mindslave DELUXE'"
	implant_type = "/obj/item/implant/mindslave/super"

/obj/item/implantcase/robust
	name = "glass case - 'Robusttec'"
	implant_type = "/obj/item/implant/robust"

/obj/item/implantcase/New()
	src.imp = new implant_type(src)
	..()
	return

/obj/item/implantcase/get_desc(dist)
	if (dist <= 1 && src.imp)
		. += "It appears to contain \a [src.imp.name]."

/obj/item/implantcase/proc/update()
	if (src.imp)
		src.icon_state = src.imp.impcolor ? "implantcase-[imp.impcolor]" : "implantcase-g"
	else
		src.icon_state = "implantcase-0"
	return

/obj/item/implantcase/attackby(obj/item/I as obj, mob/user as mob)
	if (istype(I, /obj/item/pen))
		var/t = input(user, "What would you like the label to be?", null, "[src.name]") as null|text
		if (user.equipped() != I)
			return
		if ((!in_range(src, usr) && src.loc != user))
			return
		t = copytext(adminscrub(t),1,128)
		if (t)
			src.name = "glass case - '[t]'"
		else
			src.name = "glass case"
		return
	else if (istype(I, /obj/item/implanter))
		var/obj/item/implanter/Imp = I
		if (Imp.imp)
			if (src.imp || Imp.imp.implanted)
				return
			Imp.imp.set_loc(src)
			src.imp = Imp.imp
			Imp.imp = null
			src.update()
			Imp.update()
			user.show_text("You insert [Imp]'s implant into [src].")
		else
			if (src.imp)
				if (Imp.imp)
					return
				src.imp.set_loc(I)
				Imp.imp = src.imp
				src.imp = null
				update()
				Imp.update()
				user.show_text("You insert [src]'s implant into [Imp].")
		return
	else if (istype(I, /obj/item/implant))
		if (src.imp)
			return
		user.u_equip(I)
		I.set_loc(src)
		src.imp = I
		src.update()
		user.show_text("You insert [I] into [src].")
		return
	else
		return ..()

/* =============================================================== */
/* ------------------------- Implant Pad ------------------------- */
/* =============================================================== */

/obj/item/implantpad
	name = "implantpad"
	icon = 'icons/obj/items.dmi'
	icon_state = "implantpad-0"
	var/obj/item/implantcase/case = null
	var/broadcasting = null
	var/listening = 1.0
	item_state = "electronic"
	throw_speed = 1
	throw_range = 5
	w_class = 2.0
	mats = 5
	desc = "A small device for analyzing implants."

/obj/item/implantpad/proc/update()

	if (src.case)
		src.icon_state = "implantpad-1"
	else
		src.icon_state = "implantpad-0"
	return

/obj/item/implantpad/attack_hand(mob/user as mob)

	if ((src.case && (user.l_hand == src || user.r_hand == src)))
		user.put_in_hand_or_drop(src.case)
		src.case = null
		src.add_fingerprint(user)
		update()
	else
		if (user.contents.Find(src))
			spawn( 0 )
				src.attack_self(user)
				return
		else
			return ..()
	return

/obj/item/implantpad/attackby(obj/item/implantcase/C as obj, mob/user as mob)

	if (istype(C, /obj/item/implantcase))
		if (!( src.case ))
			user.drop_item()
			C.set_loc(src)
			src.case = C
	else
		return
	src.update()
	return

/obj/item/implantpad/attack_self(mob/user as mob)

	user.machine = src
	var/dat = "<B>Implant Mini-Computer:</B><HR>"
	if (src.case)
		if (src.case.imp)
			if (istype(src.case.imp, /obj/item/implant/tracking ))
				var/obj/item/implant/tracking/T = src.case.imp
				dat += {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Tracking Beacon<BR>
<b>Zone:</b> Spinal Column> 2-5 vertebrae<BR>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<BR>
<b>Life:</b> 10 minutes after death of host<BR>
<b>Important Notes:</b> None<BR>
<HR>
<b>Implant Details:</b> <BR>
<b>Function:</b> Continuously transmits low power signal on frequency- Useful for tracking.<BR>
<b>Special Features:</b><BR>
<i>Neuro-Safe</i>- Specialized shell absorbs excess voltages self-destructing the chip if
a malfunction occurs thereby securing safety of subject. The implant will melt and
disintegrate into bio-safe elements.<BR>
<b>Integrity:</b> Gradient creates slight risk of being overcharged and frying the
circuitry. As a result neurotoxins can cause massive damage.<HR>
Implant Specifics:
Frequency (144.1-148.9):
<A href='byond://?src=\ref[src];freq=-10'>-</A>
<A href='byond://?src=\ref[src];freq=-2'>-</A> [format_frequency(T.frequency)]
<A href='byond://?src=\ref[src];freq=2'>+</A>
<A href='byond://?src=\ref[src];freq=10'>+</A><BR>

ID (1-100):
<A href='byond://?src=\ref[src];id=-10'>-</A>
<A href='byond://?src=\ref[src];id=-1'>-</A> [T.id]
<A href='byond://?src=\ref[src];id=1'>+</A>
<A href='byond://?src=\ref[src];id=10'>+</A><BR>"}
			else if (istype(src.case.imp, /obj/item/implant/freedom))
				dat += {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Freedom Beacon<BR>
<b>Zone:</b> Right Hand> Near wrist<BR>
<b>Power Source:</b> Lithium Ion Battery<BR>
<b>Life:</b> optimum 5 uses<BR>
<b>Important Notes: <font color='red'>Illegal</font></b><BR>
<HR>
<b>Implant Details:</b> <BR>
<b>Function:</b> Transmits a specialized cluster of signals to override handcuff locking
mechanisms<BR>
<b>Special Features:</b><BR>
<i>Neuro-Scan</i>- Analyzes certain shadow signals in the nervous system
<BR>
<b>Integrity:</b> The battery is extremely weak and commonly after injection its
life can drive down to only 1 use.<HR>
No Implant Specifics"}
			else if (istype(src.case.imp, /obj/item/implant/sec))
				dat += {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> T.U.R.D.S. Weapon Auth Implant<BR>
<b>Zone:</b> Spinal Column> 2-5 vertebrae<BR>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<BR>
<b>Life:</b> 10 minutes after death of host<BR>
<b>Important Notes:</b> Allows access to weapons equip with M.W.L. (Martian Weapon Lock) devices<BR>
<HR>
<b>Implant Details:</b> <BR>
<b>Function:</b> Continuously transmits low power signal which communicates with M.W.L. systems.<BR>
Range: 35-40 meters<BR>
<b>Special Features:</b><BR>
<i>Neuro-Safe</i>- Specialized shell absorbs excess voltages self-destructing the chip if
a malfunction occurs thereby securing safety of subject. The implant will melt and
disintegrate into bio-safe elements.<BR>
<b>Integrity:</b> Gradient creates slight risk of being overcharged and frying the
circuitry. As a result neurotoxins can cause massive damage.<BR>
<i>Self-Destruct</i>- This implant will self terminate upon request from an authorized Command Implant <HR>
<b>Level: 1 Auth</b>"}
			else if (istype(src.case.imp, /obj/item/implant/antirev))
				dat += {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Loyalty Implant<BR>
<b>Zone:</b> Spinal Column> 5-7 vertebrae<BR>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<BR>
<b>Important Notes:</b> Will make the crewmember loyal to the command staff and prevent thoughts of rebelling.<BR>"}
			else if (istype(src.case.imp, /obj/item/implant/microbomb))
				dat += {"
<b>Implant Specifications:</b><br>
<b>Name:</b> Microbomb Implant<br>
<b>Zone:</b> Base of Skull<br>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<br>
<b>Important Notes: <font color='red'>Illegal</font></b><BR><HR>"}
			else if (istype(src.case.imp, /obj/item/implant/robotalk))
				dat += {"
<b>Implant Specifications:</b><br>
<b>Name:</b> Machine Language Translator<br>
<b>Zone:</b> Cerebral Cortex<br>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<br>
<b>Important Notes:</b> Enables the host to transmit, recieve and understand digital transmissions used by most mechanoids.<BR>"}
			else if (istype(src.case.imp, /obj/item/implant/bloodmonitor))
				dat += {"
<b>Implant Specifications:</b><br>
<b>Name:</b> Blood Monitor<br>
<b>Zone:</b> Jugular Vein<br>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<br>
<b>Important Notes:</b> Warns the host of any detected infections or foreign substances in the bloodstream.<BR>"}
			else if (istype(src.case.imp, /obj/item/implant/mindslave))
				dat += {"
<b>Implant Specifications:</b><br>
<b>Name:</b> Mind Slave<br>
<b>Zone:</b> Brain Stem<br>
<b>Power Source:</b> Nervous System Ion Withdrawl Gradient<br>
<b>Important Notes:</b> Injects an electrical signal directly into the brain that compels obedience in human subjects for a short time. Most minds fight off the effects after approx. 25 minutes.<BR>"}
			else
				dat += "Implant ID not in database"
		else
			dat += "The implant casing is empty."
	else
		dat += "Please insert an implant casing!"
	user << browse(dat, "window=implantpad")
	onclose(user, "implantpad")
	return

/obj/item/implantpad/Topic(href, href_list)
	..()
	if (usr.stat)
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))))
		usr.machine = src
		if (href_list["freq"])
			if ((istype(src.case, /obj/item/implantcase) && istype(src.case.imp, /obj/item/implant/tracking)))
				var/obj/item/implant/tracking/T = src.case.imp
				T.frequency += text2num(href_list["freq"])
				T.frequency = sanitize_frequency(T.frequency)
		if (href_list["id"])
			if ((istype(src.case, /obj/item/implantcase) && istype(src.case.imp, /obj/item/implant/tracking)))
				var/obj/item/implant/tracking/T = src.case.imp
				T.id += text2num(href_list["id"])
				T.id = min(100, T.id)
				T.id = max(1, T.id)
		if (istype(src.loc, /mob))
			attack_self(src.loc)
		else
			for(var/mob/M in viewers(1, src))
				if (M.client)
					src.attack_self(M)
				//Foreach goto(290)
		src.add_fingerprint(usr)
	else
		usr << browse(null, "window=implantpad")
		return
	return

/* =============================================================== */
/* ------------------------- Implant Gun ------------------------- */
/* =============================================================== */

/obj/item/gun/implanter
	name = "implant gun"
	desc = "A gun that accepts an implant, that you can then shoot into other people! Or a wall, which certainly wouldn't be too big of a waste, since you'd only be using this to shoot people with things like health monitor implants or machine translators. Right?"
	icon = 'icons/misc/HaineSpriteDump.dmi'
	icon_state = "GUN-BY-HAINE-AGE-24"
	var/obj/item/implant/my_implant = null

	New()
		current_projectile = new/datum/projectile/implanter
		..()

	get_desc()
		. += "There is [my_implant ? "\a [my_implant]" : "currently no implant"] loaded into it."

	attackby(var/obj/item/W as obj, var/mob/user as mob)
		var/obj/item/implant/I = null
		if (istype(W, /obj/item/implant))
			I = W
		else if (istype(W, /obj/item/implanter))
			var/obj/item/implanter/implanter = W
			if (implanter.imp)
				I = implanter.imp
		else if (istype(W, /obj/item/implantcase))
			var/obj/item/implantcase/case = W
			if (case.imp)
				I = case.imp
		else
			return ..()
		if (I)
			if (my_implant)
				user.show_text("\The [src] already has an implant in it!", "red")
				return

			my_implant = I

			if (istype(W, /obj/item/implant))
				user.u_equip(W)
			else if (istype(W, /obj/item/implanter))
				var/obj/item/implanter/implanter = W
				implanter.imp = null
				implanter.update()
			else if (istype(W, /obj/item/implantcase))
				var/obj/item/implantcase/case = W
				case.imp = null
				case.update()

			I.set_loc(src)
			user.show_text("You load [I] into [src].", "blue")

			if (!current_projectile)
				current_projectile = new/datum/projectile/implanter
			var/datum/projectile/implanter/my_datum = current_projectile
			my_datum.my_implant = my_implant
			my_datum.implant_master = user

		else
			return ..()

	canshoot()
		if (!my_implant)
			return 0
		return 1

	process_ammo(var/mob/user)
		if (!my_implant)
			return 0
		if (!current_projectile)
			current_projectile = new/datum/projectile/implanter
		var/datum/projectile/implanter/my_datum = current_projectile
		if (ismob(user) && my_datum.implant_master != user)
			my_datum.implant_master = user
		return 1

	alter_projectile(var/obj/projectile/P)
		if (!P || !my_implant)
			return ..()
		my_implant.set_loc(P)
		my_implant = null

/datum/projectile/implanter
	name = "implant bullet"
	power = 5
	shot_sound = 'sound/machines/click.ogg'
	damage_type = D_KINETIC
	hit_type = DAMAGE_STAB
	casing = /obj/item/casing/small
	icon_turf_hit = "bhole-small"
	//silentshot = 1
	var/obj/item/implant/my_implant = null
	var/mob/implant_master = null

	on_hit(atom/hit, angle, var/obj/projectile/O)
		if (!my_implant || !ishuman(hit))
			return
		var/mob/living/carbon/human/H = hit
		if (my_implant.can_implant(H, implant_master))
			my_implant.set_loc(H)
			my_implant.implanted = 1
			my_implant.owner = H
			my_implant.implanted(H, implant_master)
			H.implant.Add(my_implant)
		else
			my_implant.set_loc(get_turf(H))
