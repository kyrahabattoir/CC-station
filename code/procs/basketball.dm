// SPDX-License-Identifier: CC-BY-NC-SA-3.0

proc/bball_nova()
	set category = "Spells"
	set name = "B-Ball Nova"
	set desc = "Causes an eruption of explosive basketballs from your location"

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	if(!isturf(M.loc))
		return

	if(!M.bball_spellpower())
		return

	M.verbs -= /proc/bball_nova
	spawn(300)
		M.verbs += /proc/bball_nova

	M.visible_message("<span style=\"color:red\">A swarm of basketballs erupts from [M]!</span>")

	for(var/turf/T in orange(1, M))
		if(!T.density)
			var/target_dir = get_dir(M.loc, T)
			var/turf/U = get_edge_target_turf(M, target_dir)
			new /obj/newmeteor/basketball(my_spawn = T, trg = U)


/obj/newmeteor/basketball
	name = "basketball"
	icon = 'icons/obj/items.dmi'
	icon_state = "bball_spin"
	hits = 6

/proc/showboat_slam(mob/target as mob in oview(6))
	set category = "Spells"
	set name = "Showboat Slam"
	set desc = "Leap up and slam your target for massive damage"

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	if(!isturf(M.loc) || !M.bball_spellpower())
		return

	M.verbs -= /proc/showboat_slam
	spawn(300)
		M.verbs += /proc/showboat_slam

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball2"
	M.set_clothing_icon_dirty()

	M.transforming = 1
	M.layer = EFFECTS_LAYER_BASE

	M.visible_message("<span style=\"color:red\">[M] takes a mighty leap towards the ceiling!</span>")
	playsound(M.loc, "sound/effects/bionic_sound.ogg", 50)

	for(var/i = 0, i < 10, i++)
		M.pixel_y += 4
		step_to(M, target)
		sleep(1)
	sleep(1)
	M.pixel_y = 0
	M.set_loc(target.loc)
	M.transforming = 0
	M.layer = MOB_LAYER

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball"

	playsound(M.loc, "explosion", 50, 1)
	var/obj/overlay/O = new/obj/overlay(get_turf(target))
	O.anchored = 1
	O.name = "Explosion"
	O.layer = NOLIGHT_EFFECTS_LAYER_BASE
	O.pixel_x = -17
	O.icon = 'icons/effects/hugeexplosion.dmi'
	O.icon_state = "explosion"
	spawn(35) qdel(O)

	for(var/mob/N in AIviewers(M, null))
		if(get_dist(N, target) <= 2)
			if(N != M)
				N.weakened = max(N.weakened, 5)
				random_brute_damage(N, 10)
		if(N.client)
			shake_camera(N, 6, 5)
			N.show_message("<span style=\"color:red\">[M] showboat slams [target] to the ground!</span>", 1)
	random_brute_damage(target, 40)

/proc/holy_jam()
	set category = "Spells"
	set name = "Holy Jam"
	set desc = "Powerful jam that blinds surrounding enemies"

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	if(!isturf(M.loc) || !M.bball_spellpower())
		return

	M.verbs -= /proc/holy_jam
	spawn(150)
		M.verbs += /proc/holy_jam

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball2"
	M.set_clothing_icon_dirty()

	M.transforming = 1
	M.layer = EFFECTS_LAYER_BASE

	M.visible_message("<span style=\"color:red\">[M] takes a divine leap towards the ceiling!</span>")

	playsound(M.loc, "sound/effects/heavenly.ogg", 50, 1)

	for(var/i = 0, i < 10, i++)
		M.pixel_y += 4
		sleep(1)
	sleep(1)
	M.pixel_y = 0
	M.transforming = 0
	M.layer = MOB_LAYER

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball"

	for(var/mob/N in AIviewers(M, null))
		if(get_dist(N, M) <= 6)
			if(N != M)
				N.apply_flash(30, 5)
				if(ishuman(N) && istype(N:mutantrace, /datum/mutantrace/zombie))
					N.gib()
		if(N.client)
			shake_camera(N, 6, 4)
			N.show_message("<span style=\"color:red\">[M]'s basketball unleashes a brilliant flash of light!</span>", 1)

	playsound(M.loc, "sound/weapons/flashbang.ogg", 50, 1)

proc/blitz_slam()
	set category = "Spells"
	set name = "Blitz Slam"
	set desc="Teleport randomly to a nearby tile."

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	var/SPrange = 2
	if (M.bball_spellpower()) SPrange = 6

	var/list/turfs = new/list()
	for(var/turf/T in orange(SPrange))
		if(istype(T,/turf/space)) continue
		if(T.density) continue
		if(T.x>world.maxx-4 || T.x<4)	continue	//putting them at the edge is dumb
		if(T.y>world.maxy-4 || T.y<4)	continue
		turfs += T
	if(!turfs.len) turfs += pick(/turf in orange(6))
	var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
	smoke.set_up(10, 0, M.loc)
	smoke.start()
	var/turf/picked = pick(turfs)
	if(!isturf(picked)) return
	M.set_loc(picked)
	M.verbs -= /proc/blitz_slam
	spawn(40)
		M.verbs += /proc/blitz_slam

/proc/clown_jam(mob/living/target as mob in oview(6))
	set category = "Spells"
	set name = "Clown Jam"
	set desc = "Jams the target into a fat cursed clown"

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	var/SPtime = 3000
	if (M.bball_spellpower()) SPtime = 900
	M.verbs -= /proc/clown_jam
	spawn(SPtime)
	M.verbs += /proc/clown_jam

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball2"
	M.set_clothing_icon_dirty()

	M.transforming = 1
	M.layer = EFFECTS_LAYER_BASE

	M.visible_message("<span style=\"color:red\">[M] comically leaps towards the ceiling!</span>")
	playsound(M.loc, "sound/effects/bionic_sound.ogg", 50)

	for(var/i = 0, i < 10, i++)
		M.pixel_y += 4
		M.pixel_x = rand(-4, 4)
		step_to(M, target)
		sleep(1)
	sleep(1)
	M.pixel_x = 0
	M.pixel_y = 0
	M.set_loc(target.loc)
	M.transforming = 0
	M.layer = MOB_LAYER

	for(var/mob/N in AIviewers(M, null))
		if(get_dist(N, target) <= 2)
			if(N != M)
				N.weakened = max(N.weakened, 5)
		if(N.client)
			shake_camera(N, 6, 4)
			N.show_message("<span style=\"color:red\">[M] clown jams [target]!</span>", 1)

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball"

	playsound(target.loc, "explosion", 50, 1)
	playsound(target.loc, "sound/items/bikehorn.ogg", 50, 1)


	var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
	smoke.set_up(5, 0, target.loc)
	smoke.attach(target)
	smoke.start()

	if(target.job != "Clown")
		boutput(target, "<span style=\"color:red\"><B>You HONK painfully!</B></span>")
		target.take_brain_damage(80)
		target.stuttering = 120
		target.job = "Clown"
		target.contract_disease(/datum/ailment/disease/cluwneing_around, null, null, 1) // path, name, strain, bypass resist
		target.contract_disease(/datum/ailment/disability/clumsy, null, null, 1) // path, name, strain, bypass resist
		target.nutrition = 9000
		target.change_misstep_chance(60)

		target.unequip_all()

		if(istype(target, /mob/living/carbon/human))
			var/mob/living/carbon/human/cursed = target
			cursed.equip_if_possible(new /obj/item/clothing/under/gimmick/cursedclown(cursed), cursed.slot_w_uniform)
			cursed.equip_if_possible(new /obj/item/clothing/shoes/cursedclown_shoes(cursed), cursed.slot_shoes)
			cursed.equip_if_possible(new /obj/item/clothing/mask/cursedclown_hat(cursed), cursed.slot_wear_mask)
			cursed.equip_if_possible(new /obj/item/clothing/gloves/cursedclown_gloves(cursed), cursed.slot_gloves)

			target.real_name = "cluwne"

	else //The inverse clown principle
		var/mob/living/carbon/human/H = target
		if(!istype(H))
			return
		boutput(H, "<span style=\"color:red\"><b>You don't feel very funny.</b></span>")
		H.take_brain_damage(-120)
		H.stuttering = 0
		H.job = "Lawyer"
		H.change_misstep_chance(-INFINITY)
		H.nutrition = 0
		for(var/datum/ailment_data/A in H.ailments)
			if(istype(A.master,/datum/ailment/disability/clumsy))
				H.cure_disease(A)
		var/obj/old_uniform = H.w_uniform
		var/obj/item/card/id/the_id = H.wear_id

		if(H.w_uniform && findtext("[H.w_uniform.type]","clown"))
			H.w_uniform = new /obj/item/clothing/under/suit(H)
			qdel(old_uniform)

		if(H.shoes && findtext("[H.shoes.type]","clown"))
			qdel(H.shoes)
			H.shoes = new /obj/item/clothing/shoes/black(H)

		if(the_id && the_id.registered == H.real_name)
			the_id.assignment = "Lawyer"
			the_id.name = "[H.real_name]'s ID Card (Lawyer)"
			H.wear_id = the_id

		for(var/obj/item/W in H)
			if (findtext("[W.type]","clown"))
				H.u_equip(W)
				if (W)
					W.set_loc(target.loc)
					W.dropped(H)
					W.layer = initial(W.layer)

		return

/proc/chaos_dunk()
	set category = "Spells"
	set name = "Chaos Dunk"
	set desc = "Destroy the entire station with the ultimate slam"

	var/mob/M = src

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	var/equipped_thing = M.equipped()
	if(istype(equipped_thing, /obj/item/basketball))
		var/obj/item/basketball/BB = equipped_thing
		if(!BB.payload)
			boutput(M, __red("This b-ball doesn't have the right heft to it!"))
			return
		else //Safety thing to ensure the plutonium core is only good for one dunk
			var/pl = BB.payload
			BB.payload = null
			qdel(pl)
	else
		boutput(M, __red("You can't dunk without a b-ball, yo!"))
		return

	M.verbs -= /proc/chaos_dunk

	logTheThing("combat", M, null, "<b>triggers a chaos dunk in [M.loc.loc] ([showCoords(M.x, M.y, M.z)])!</b>")

	for(var/obj/item/basketball/B in M.contents)
		B.item_state = "bball2"
	M.set_clothing_icon_dirty()

	M.transforming = 1
	M.layer = EFFECTS_LAYER_BASE

	M.visible_message("<span style=\"color:red\">[M] flies through the ceiling!</span>")
	playsound(M.loc, "sound/effects/bionic_sound.ogg", 50)

	for(var/i = 0, i < 50, i++)
		M.pixel_y += 6
		M.dir = turn(M.dir, 90)
		sleep(1)
	M.layer = 0
	var/sound/siren = sound('sound/misc/airraid_loop.ogg')
	siren.repeat = 1
	siren.channel = 5
	world << siren
	command_alert("A massive influx of negative b-ball protons has been detected in [get_area(M)]. A Chaos Dunk is imminent. All personnel currently on [station_name()] have 15 seconds to reach minimum safe distance. This is not a test.")
	for(var/area/A in world)
		spawn(0)
			A.eject = 1
			A.updateicon()
	for(var/mob/N in mobs)
		spawn(0)
			shake_camera(N, 120, 2)
	spawn(0)
		var/thunder = 70
		while(thunder > 0)
			thunder--
			if(prob(15))
				world << sound('sound/effects/thunder.ogg', volume = 80)
				for(var/mob/N in mobs)
					N.flash(30)
			sleep(5)
	sleep(300)
	playsound(M.loc, "sound/effects/bionic_sound.ogg", 50)
	M.layer = EFFECTS_LAYER_BASE
	for(var/i = 0, i < 20, i++)
		M.pixel_y -= 12
		M.dir = turn(M.dir, 90)
		sleep(1)
	sleep(1)
	siren.repeat = 0
	siren.status = SOUND_UPDATE
	siren.channel = 5
	world << siren
	M.visible_message("<span style=\"color:red\">[M] successfully executes a Chaos Dunk!</span>")
	explosion_new(src, get_turf(M), 1500, 22.78)

	for(var/area/A in world)
		spawn(0)
			A.eject = 0
			A.updateicon()

/proc/spin()
	set category = "Spells"
	set name = "360 Spin"
	set desc = "Get fools off your back."

	var/mob/M = src

	if(!M.bball_spellpower())
		return

	if(M.stat)
		boutput(M, "Not when you're incapacitated.")
		return

	M.transforming = 1

	for(var/mob/N in AIviewers(M, null))
		if(N.client)
			N.show_message("<span style=\"color:red\">[M] does a quick spin, knocking you off guard!</span>", 1)
		if(get_dist(N, M) <= 2)
			if(N != M)
				N.stunned = max(N.stunned, 2)

	M.dir = NORTH
	sleep(1)
	M.dir = EAST
	sleep(1)
	M.dir = SOUTH
	sleep(1)
	M.dir = WEST

	M.transforming = 0

	M.verbs -= /proc/spin
	spawn(40)
		M.verbs += /proc/spin

/obj/item/bball_uplink
	name = "station bounced radio"
	icon = 'icons/obj/device.dmi'
	icon_state = "radio"
	var/temp = null
	var/uses = 4.0
	var/selfdestruct = 0.0
	var/traitor_frequency = 0.0
	var/obj/item/device/radio/origradio = null
	flags = FPRINT | TABLEPASS| CONDUCT | ONBELT
	item_state = "radio"
	throwforce = 5
	w_class = 2.0
	throw_speed = 4
	throw_range = 20
	m_amt = 100

/obj/item/bball_uplink/proc/explode()
	var/turf/location = get_turf(src.loc)
	location.hotspot_expose(700, 125)

	explosion(src, location, 0, 0, 2, 4)

	qdel(src.master)
	qdel(src)
	return

/obj/item/bball_uplink/attack_self(mob/user as mob)
	user.machine = src
	var/dat
	if (src.selfdestruct)
		dat = "Self Destructing..."
	else
		if (src.temp)
			dat = "[src.temp]<BR><BR><A href='byond://?src=\ref[src];temp=1'>Clear</A>"
		else
			dat = "<B>ZauberTech Baller Uplink Console:</B><BR>"
			dat += "Tele-Crystals left: [src.uses]<BR>"
			dat += "<HR>"
			dat += "<B>Request item:</B><BR>"
			dat += "<I>Each item costs 1 telecrystal. The number afterwards is the cooldown time.</I><BR>"
			dat += "<A href='byond://?src=\ref[src];spell_nova=1'>B-Ball Nova</A> (30)<BR>"
			dat += "<A href='byond://?src=\ref[src];spell_showboat=1'>Showboat Slam</A> (30)<BR>"
			dat += "<A href='byond://?src=\ref[src];spell_holy=1'>Holy Jam</A> (15)<BR>"
			dat += "<A href='byond://?src=\ref[src];spell_blink=1'>Blitz Slam</A> (2)<BR>"
			dat += "<A href='byond://?src=\ref[src];spell_revengeclown=1'>Clown Jam</A> (90)<BR>"
//			dat += "<A href='byond://?src=\ref[src];spell_summongolem=1'>Summon Basketball Golem</A> (60)<BR>"
			dat += "<A href='byond://?src=\ref[src];spell_spin=1'>Spin (free)</A> (4)<BR>"
			dat += "<HR>"
			if (src.origradio)
				dat += "<A href='byond://?src=\ref[src];lock=1'>Lock</A><BR>"
				dat += "<HR>"
			dat += "<A href='byond://?src=\ref[src];selfdestruct=1'>Self-Destruct</A>"
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

/obj/item/bball_uplink/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	var/mob/living/carbon/human/H = usr
	if (!( istype(H, /mob/living/carbon/human)))
		return 1
	if ((usr.contents.Find(src) || (in_range(src,usr) && istype(src.loc, /turf))))
		usr.machine = src
		if (href_list["spell_nova"])
			if (src.uses >= 1)
				src.uses -= 1
				src.temp = "This jam will cause an eruption of explosive basketballs from your location."
				usr.verbs += /proc/bball_nova
		if (href_list["spell_showboat"])
			if (src.uses >= 1)
				src.uses -= 1
				usr.verbs += /proc/showboat_slam
				src.temp = "Leap up high above your target and slam them for massive damage."
		if (href_list["spell_holy"])
			if (src.uses >= 1)
				src.uses -= 1
				usr.verbs += /proc/holy_jam
				src.temp = "A powerful and sacred jam that blinds surrounding enemies."
		if (href_list["spell_blink"])
			if (src.uses >= 1)
				src.uses -= 1
				usr.verbs += /proc/blitz_slam
				src.temp = "This slam will allow you to teleport randomly at a short distance."
		if (href_list["spell_revengeclown"])
			if (src.uses >= 1)
				src.uses -= 1
				usr.verbs += /proc/clown_jam
				src.temp = "This unspoken jam bamboozles your target to the extent that they will become an obese, idiotic, horrible, and useless clown."
		if (href_list["spell_spin"])
			usr.verbs += /proc/spin
			src.temp = "This spell lets you do a 360 spin, knocking down any fools tailing you."
/*
		if (href_list["spell_summongolem"])
			if (src.uses >= 1)
				src.uses -= 1
				usr.verbs += /proc/summongolem_bball
				src.temp = "This zauber allows you to summon a golem.. made of basketballs."
*/
		else if (href_list["lock"] && src.origradio)
			// presto chango, a regular radio again! (reset the freq too...)
			usr.machine = null
			usr << browse(null, "window=radio")
			var/obj/item/device/radio/T = src.origradio
			var/obj/item/bball_uplink/R = src
			R.set_loc(T)
			T.set_loc(usr)
			// R.layer = initial(R.layer)
			R.layer = 0
			usr.u_equip(R)
			usr.put_in_hand_or_drop(T)
			T.set_frequency(initial(T.frequency))
			T.attack_self(usr)
			return
		else if (href_list["selfdestruct"])
			src.temp = "<A href='byond://?src=\ref[src];selfdestruct2=1'>Self-Destruct</A>"
		else if (href_list["selfdestruct2"])
			src.selfdestruct = 1
			spawn (100)
				explode()
				return
		else
			if (href_list["temp"])
				src.temp = null
		if (istype(src.loc, /mob))
			attack_self(src.loc)
		else
			for(var/mob/M in viewers(1, src))
				if (M.client)
					src.attack_self(M)
	return

/mob/proc/bball_spellpower()
	if(!ishuman(src))
		return 0
	var/mob/living/carbon/human/H = src
	var/magcount = 0
	if (istype(H.w_uniform, /obj/item/clothing/under/jersey))
		magcount += 1
	for (var/obj/item/basketball/B in usr.contents)
		magcount += 2
	if (magcount >= 3)
		return 1
	return 0