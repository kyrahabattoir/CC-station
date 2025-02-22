// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// Contains:
//
// - Chainsaw
// - Plant analyzer
// - Portable seed fabricator
// - Watering can
// - Compost bag
// - Plant formulas

//////////////////////////////////////////////// Chainsaw ////////////////////////////////////

/obj/item/saw
	name = "chainsaw"
	desc = "A chainsaw used to chop up harmful plants. Despite its appearance, it's not extremely dangerous to humans."
	icon = 'icons/obj/weapons.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	icon_state = "c_saw_off"
	item_state = "c_saw"
	var/base_state = "c_saw"
	var/active = 0.0
	hit_type = DAMAGE_CUT
	force = 3.0
	var/active_force = 10.0
	var/off_force = 3.0
	var/how_dangerous_is_this_thing = 1
	var/takes_damage = 1
	health = 10.0
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 4.0
	flags = FPRINT | TABLEPASS | CONDUCT
	mats = 12
	var/sawnoise = 'sound/machines/chainsaw_green.ogg'
	arm_icon = "chainsaw0"
	over_clothes = 1
	override_attack_hand = 1
	can_hold_items = 0
	stamina_damage = 10
	stamina_cost = 10
	stamina_crit_chance = 35

	cyborg
		takes_damage = 0

	New()
		..()
		spawn (5)
			if (src)
				src.update_icon()
		return

	proc/check_health()
		if (src.health <= 0 && src.takes_damage)
			spawn (2)
				if (src)
					usr.u_equip(src)
					usr.update_inhands()
					boutput(usr, "<span style=\"color:red\">[src] falls apart!</span>")
					qdel(src)
		return

	proc/damage_health(var/amt)
		src.health -= amt
		src.check_health()
		return

	proc/update_icon()
		icon_state = "[src.base_state][src.active ? null : "_off"]"
		return

	// Fixed a couple of bugs and cleaned code up a little bit (Convair880).
	attack(mob/target as mob, mob/user as mob)
		if (!istype(target))
			return

		if (src.active)

			user.lastattacked = target
			target.lastattacker = user
			target.lastattackertime = world.time

			if (ishuman(target))
				if (ishuman(user) && saw_surgery(target,user))
					src.damage_health(2)
					take_bleeding_damage(target, user, 2, DAMAGE_CUT)
					return
				else if (target.stat != 2)
					take_bleeding_damage(target, user, 5, DAMAGE_CUT)
					if (prob(80))
						target.emote("scream")

			playsound(target, sawnoise, 60, 1)//need a better sound

			if (src.takes_damage)
				if (issilicon(target))
					src.damage_health(4)
				else
					src.damage_health(1)

			switch (src.how_dangerous_is_this_thing)
				if (2) // Red chainsaw.
					if (iscarbon(target))
						var/mob/living/carbon/C = target
						if (C.stat != 2)
							C.stunned += 3
							C.weakened += 3
						else
							logTheThing("combat", user, C, "butchers [C]'s corpse with the [src.name] at [log_loc(C)].")
							var/sourcename = C.real_name
							var/sourcejob = "Stowaway"
							if (C.mind && C.mind.assigned_role)
								sourcejob = C.mind.assigned_role
							else if (C.ghost && C.ghost.mind && C.ghost.mind.assigned_role)
								sourcejob = C.ghost.mind.assigned_role
							for (var/i=0, i<3, i++)
								var/obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat/meat = new /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat(get_turf(C))
								meat.name = sourcename + meat.name
								meat.subjectname = sourcename
								meat.subjectjob = sourcejob
							if (C.mind)
								C.ghostize()
								qdel(C)
								return
							else
								qdel(C)
								return

				if (3) // Elimbinator.
					if (ishuman(target))
						var/mob/living/carbon/human/H = target
						var/list/limbs = list("l_arm","r_arm","l_leg","r_leg")
						var/the_limb = null

						if (user.zone_sel.selecting in limbs)
							the_limb = user.zone_sel.selecting
						else
							the_limb = pick("l_arm","r_arm","l_leg","r_leg")

						if (!the_limb)
							return //who knows

						H.sever_limb(the_limb)
						H.stunned += 3
						bleed(H, 3, 5)
		..()
		return

	attack_self(mob/user as mob)
		if (user.bioHolder.HasEffect("clumsy") && prob(50))
			user.visible_message("<span style=\"color:red\"><b>[user]</b> accidentally grabs the blade of [src].</span>")
			user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 5, 5)
		src.active = !( src.active )
		if (src.active)
			boutput(user, "<span style=\"color:blue\">[src] is now active.</span>")
			src.force = active_force
		else
			boutput(user, "<span style=\"color:blue\">[src] is now off.</span>")
			src.force = off_force
		src.update_icon()
		user.update_inhands()
		src.add_fingerprint(user)
		return

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><b>[user] shoves the chainsaw into \his chest!</b></span>")
		user.u_equip(src)
		src.set_loc(user.loc)
		user.gib()
		return 1

/obj/item/saw/syndie
	name = "chainsaw"
	icon_state = "c_saw_s_off"
	item_state = "c_saw_s"
	base_state = "c_saw_s"
	active = 0.0
	force = 6.0
	active_force = 50.0
	off_force = 6.0
	health = 10
	takes_damage = 0
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 4.0
	is_syndicate = 1
	how_dangerous_is_this_thing = 2
	mats = 14
	desc = "This one is the real deal. Time for a space chainsaw massacre."
	contraband = 4
	sawnoise = 'sound/machines/chainsaw_red.ogg'
	arm_icon = "chainsaw1"
	stamina_damage = 20
	stamina_cost = 20
	stamina_crit_chance = 40

/obj/item/saw/syndie/vr
	icon = 'icons/effects/VR.dmi'

/obj/item/saw/elimbinator
	name = "The Elimbinator"
	desc = "Lops off limbs left and right!"
	icon = 'icons/obj/weapons.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	icon_state = "c_saw_s"
	item_state = "c_saw_s"
	base_state = "c_saw_s"
	hit_type = DAMAGE_CUT
	active = 1.0
	force = 5
	active_force = 10.0
	off_force = 5.0
	health = 10
	how_dangerous_is_this_thing = 3
	takes_damage = 0
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 4.0
	mats = 12
	sawnoise = 'sound/machines/chainsaw_red.ogg'
	arm_icon = "chainsaw1"
	stamina_damage = 20
	stamina_cost = 20
	stamina_crit_chance = 50

////////////////////////////////////// Plant analyzer //////////////////////////////////////

/obj/item/plantanalyzer/
	name = "plant analyzer"
	desc = "A device which examines the genes of plant seeds."
	icon = 'icons/obj/hydroponics/hydromisc.dmi'
	icon_state = "plantanalyzer"
	w_class = 1.0
	flags = ONBELT
	mats = 4
	module_research = list("analysis" = 4, "devices" = 4, "hydroponics" = 2)

	afterattack(atom/A as mob|obj|turf|area, mob/user as mob)
		if (get_dist(A, user) > 1)
			return

		boutput(user, scan_plant(A, user)) // Replaced with global proc (Convair880).
		src.add_fingerprint(user)
		return

/////////////////////////////////////////// Seed fabricator ///////////////////////////////

/obj/item/seedplanter
	name = "Portable Seed Fabricator"
	desc = "A tool for cyborgs used to create plant seeds."
	icon = 'icons/obj/device.dmi'
	icon_state = "forensic0"
	var/list/available = list()
	var/datum/plant/selected = null

	New()
		..()
		for (var/A in typesof(/datum/plant)) src.available += new A(src)

		/*for (var/datum/plant/P in src.available)
			if (!P.vending || P.type == /datum/plant)
				del P
				continue*/

	attack_self(var/mob/user as mob)
/*		var/hacked = 0
		if (istype(user,/mob/living/silicon/robot/))
			var/mob/living/silicon/robot/R = user
			if (R.emagged)
				hacked = 1
*/
		playsound(src.loc, "sound/machines/click.ogg", 100, 1)
		var/list/usable = list()
		for(var/datum/plant/A in hydro_controls.plant_species)
			if (!A.vending/* || (A.vending == 2 && !hacked)*/)
				continue
			usable += A

		var/datum/plant/pick = input(usr, "Which seed do you want?", "Portable Seed Fabricator", null) in usable
		src.selected = pick

	afterattack(atom/target as obj|mob|turf, mob/user as mob, flag)
		if (isturf(target) && selected)
			var/obj/item/seed/S
			if (selected.unique_seed)
				S = new selected.unique_seed(src.loc)
			else
				S = new /obj/item/seed(src.loc,0)
			S.generic_seed_setup(selected)

/obj/item/seedplanter/hidden
	desc = "This is supposed to be a cyborg part. You're not quite sure what it's doing here."

///////////////////////////////////// Watering can ///////////////////////////////////////////////

/obj/item/reagent_containers/glass/wateringcan/
	name = "watering can"
	desc = "Used to water things. Obviously."
	icon = 'icons/obj/hydroponics/hydromisc.dmi'
	icon_state = "watercan"
	amount_per_transfer_from_this = 60
	w_class = 3.0
	rc_flags = RC_FULLNESS | RC_VISIBLE | RC_SPECTRO
	module_research = list("tools" = 2, "hydroponics" = 4)

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(120)
		reagents = R
		R.my_atom = src
		R.add_reagent("water", 120)

/////////////////////////////////////////// Compost bag ////////////////////////////////////////////////

/obj/item/reagent_containers/glass/compostbag/
	name = "compost bag"
	desc = "A big bag of shit."
	icon = 'icons/obj/hydroponics/hydromisc.dmi'
	icon_state = "compost"
	amount_per_transfer_from_this = 10
	w_class = 3.0
	rc_flags = 0
	module_research = list("tools" = 1, "hydroponics" = 1)

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(60)
		reagents = R
		R.my_atom = src
		R.add_reagent("poo", 60)

/////////////////////////////////////////// Plant formulas /////////////////////////////////////

/obj/item/reagent_containers/glass/bottle/weedkiller
	name = "weedkiller"
	desc = "A small bottle filled with Atrazine, an effective weedkiller."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle1"
	amount_per_transfer_from_this = 10
	module_research = list("tools" = 1, "hydroponics" = 1, "science" = 1)
	module_research_type = /obj/item/reagent_containers/glass/bottle/weedkiller

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("weedkiller", 40)

/obj/item/reagent_containers/glass/bottle/mutriant
	name = "Mutagenic Plant Formula"
	desc = "An unstable radioactive mixture that stimulates genetic diversity."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle3"
	amount_per_transfer_from_this = 10

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("mutagen", 40)

/obj/item/reagent_containers/glass/bottle/groboost
	name = "Ammonia Plant Formula"
	desc = "A nutrient-rich plant formula that encourages quick plant growth."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle3"
	amount_per_transfer_from_this = 10

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("ammonia", 40)

/obj/item/reagent_containers/glass/bottle/topcrop
	name = "Potash Plant Formula"
	desc = "A nutrient-rich plant formula that encourages large crop yields."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle3"
	amount_per_transfer_from_this = 10

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("potash", 40)

/obj/item/reagent_containers/glass/bottle/powerplant
	name = "Saltpetre Plant Formula"
	desc = "A nutrient-rich plant formula that encourages more potent crops."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle3"
	amount_per_transfer_from_this = 10

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("saltpetre", 40)

/obj/item/reagent_containers/glass/bottle/fruitful
	name = "Mutadone Plant Formula"
	desc = "A nutrient-rich formula that attempts to rectify genetic problems."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle3"
	amount_per_transfer_from_this = 10

	New()
		..()
		var/datum/reagents/R = new/datum/reagents(40)
		reagents = R
		R.my_atom = src
		R.add_reagent("mutadone", 40)