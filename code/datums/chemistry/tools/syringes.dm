// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/* ================================================== */
/* -------------------- Syringes -------------------- */
/* ================================================== */
#define S_DRAW 0
#define S_INJECT 1
/obj/item/reagent_containers/syringe
	name = "Syringe"
	desc = "A syringe."
	icon = 'icons/obj/syringe.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "syringe_0"
	icon_state = "0"
	initial_volume = 15
	amount_per_transfer_from_this = 5
	module_research = list("science" = 1, "medicine" = 1)
	module_research_type = /obj/item/reagent_containers/syringe
	var/mode = S_DRAW
	var/image/fluid_image
	rc_flags = RC_SCALE | RC_VISIBLE | RC_SPECTRO

	New()
		..()
		fluid_image = image('icons/obj/syringe.dmi')

	on_reagent_change()
		if (src.reagents.is_full() && src.mode == S_DRAW)
			src.mode = S_INJECT
		else if (!src.reagents.total_volume && src.mode == S_INJECT)
			src.mode = S_DRAW
		src.update_icon()

	pickup(mob/user)
		..()
		update_icon()

	dropped(mob/user)
		..()
		update_icon()

	attack_self(mob/user as mob)
		switch(mode)
			if (S_DRAW)
				mode = S_INJECT
			if (S_INJECT)
				mode = S_DRAW
		update_icon()

	attack_hand(mob/user as mob)
		..()
		update_icon()

	attackby(obj/item/I as obj, mob/user as mob)
		return

	afterattack(var/atom/target, mob/user, flag)
		if (!target.reagents) return

		switch(mode)
			if (S_DRAW)
				if (istype(target, /mob/living))//Blood!
					var/mob/living/L = target
					if (!L.blood_id)
						return

					if (reagents.total_volume >= reagents.maximum_volume)
						boutput(user, "<span style=\"color:red\">The syringe is full.</span>")
						return

					var/mob/living/carbon/human/H = target
					if (target != user)
						L.visible_message("<span style=\"color:red\"><B>[user] is trying to draw blood from [L]!</B></span>")

						if (!do_mob(user, L))
							if (user && ismob(user))
								user.show_text("You were interrupted!", "red")
							return
						if (!L.blood_id)
							user.show_text("You can't draw blood from this mob.", "red")
							return
						if (reagents.total_volume >= reagents.maximum_volume)
							boutput(user, "<span style=\"color:red\">The syringe is full.</span>")
							return

					// Vampires can't use this trick to inflate their blood count, because they can't get more than ~30% of it back.
					// Also ignore that second container of blood entirely if it's a vampire (Convair880).
					if (istype(H))
						if ((isvampire(H) && (H.get_vampire_blood() <= 0)) || (!isvampire(H) && !H.blood_volume))
							user.show_text("[H]'s veins appear to be completely dry!", "red")
							return
					target.visible_message("<span style=\"color:red\">[user] draws blood from [H]!</span>")

					transfer_blood(target, src)

					boutput(user, "<span style=\"color:blue\">You fill the syringe with 5 units of [target]'s blood.</span>")
					return

				if (!target.reagents.total_volume)
					boutput(user, "<span style=\"color:red\">[target] is empty.</span>")
					return

				if (reagents.total_volume >= reagents.maximum_volume)
					boutput(user, "<span style=\"color:red\">The syringe is full.</span>")
					return

				if (target.is_open_container() != 1 && !istype(target,/obj/reagent_dispensers))
					boutput(user, "<span style=\"color:red\">You cannot directly remove reagents from this object.</span>")
					return

				target.reagents.trans_to(src, 5)

				boutput(user, "<span style=\"color:blue\">You fill the syringe with 5 units of the solution.</span>")

			if (S_INJECT)
				// drsingh for Cannot read null.total_volume
				if (!reagents || !reagents.total_volume)
					boutput(user, "<span style=\"color:red\">The Syringe is empty.</span>")
					return

				if (istype(target, /obj/item/bloodslide))
					var/obj/item/bloodslide/BL = target
					if (BL.reagents.total_volume)
						boutput(user, "<span style=\"color:red\">There is already a pathogen sample on [target].</span>")
						return
					var/transferred = src.reagents.trans_to(target, 5)
					boutput(user, "<span style=\"color:blue\">You fill the blood slide with [transferred] units of the solution.</span>")
					// contingency
					BL.on_reagent_change()
					return

				if (target.reagents.total_volume >= target.reagents.maximum_volume)
					boutput(user, "<span style=\"color:red\">[target] is full.</span>")
					return

				if (target.is_open_container() != 1 && !ismob(target) && !istype(target,/obj/item/reagent_containers/food) && !istype(target,/obj/item/reagent_containers/patch))
					boutput(user, "<span style=\"color:red\">You cannot directly fill this object.</span>")
					return

				if (iscarbon(target) || iscritter(target))
					if (target != user)
						for (var/mob/O in AIviewers(world.view, user))
							O.show_message(text("<span style=\"color:red\"><B>[] is trying to inject []!</B></span>", user, target), 1)
						logTheThing("combat", user, target, "tries to inject %target% with a syringe [log_reagents(src)] at [log_loc(user)].")

						if (!do_mob(user, target))
							if (user && ismob(user))
								user.show_text("You were interrupted!", "red")
							return
						if (!src.reagents || !src.reagents.total_volume)
							user.show_text("[src] doesn't contain any reagents.", "red")
							return

						for (var/mob/O in AIviewers(world.view, user))
							O.show_message(text("<span style=\"color:red\">[] injects [] with the syringe!</span>", user, target), 1)

					src.reagents.reaction(target, REAC_INGEST)

				if (istype(target,/obj/item/reagent_containers/patch))
					var/obj/item/reagent_containers/patch/P = target
					boutput(user, "<span style=\"color:blue\">You fill [P].</span>")
					if (P.medical == 1)
						//break the seal
						boutput(user, "<span style=\"color:red\">You break [P]'s tamper-proof seal!</span>")
						P.medical = 0

				spawn (5)
					if (src && src.reagents && target && target.reagents)
						logTheThing("combat", user, target, "injects %target% with a syringe [log_reagents(src)] at [log_loc(user)].")
						// Convair880: Seems more efficient than separate calls. I believe this shouldn't clutter up the logs, as the number of targets you can inject is limited.
						// Also wraps up injecting food (advertised in the 'Tip of the Day' list) and transferring chems to other containers (i.e. brought in line with beakers and droppers).

						src.reagents.trans_to(target, 5)

						if (istype(target,/obj/item/reagent_containers/patch))
							//patch auto-naming thing
							var/patch_name = ""
							for (var/reagent_id in target.reagents.reagent_list)
								patch_name += "[reagent_id]-"
							patch_name += "patch"
							target.name = patch_name

						boutput(user, "<span style=\"color:blue\">You inject 5 units of the solution. The syringe now contains [src.reagents.total_volume] units.</span>")
		return

	proc/update_icon()
		// drsingh for cannot read null.total_volume
		var/rounded_vol = reagents ? round(reagents.total_volume,5) : 0;
		icon_state = "[rounded_vol]"
		item_state = "syringe_[rounded_vol]"
		src.overlays = null
		src.underlays = null
		if (ismob(loc))
			src.overlays += mode == S_INJECT ? "inject" : "draw"
		src.fluid_image.icon_state = "f[rounded_vol]"
		var/datum/color/average = reagents.get_average_color()
		src.fluid_image.color = average.to_rgba()
		src.underlays += src.fluid_image

#undef S_DRAW
#undef S_INJECT

/* =================================================== */
/* -------------------- Sub-Types -------------------- */
/* =================================================== */

/obj/item/reagent_containers/syringe/robot
	name = "syringe (mixed)"
	desc = "Contains epinephrine & anti-toxins."

	New()
		..()
		reagents.add_reagent("epinephrine", 7)
		reagents.add_reagent("charcoal", 8)
		mode = "i"
		update_icon()

/obj/item/reagent_containers/syringe/epinephrine
	name = "syringe (epinephrine)"
	desc = "Contains epinephrine - used to stabilize patients."

	New()
		..()
		reagents.add_reagent("epinephrine", 15)
		update_icon()

/obj/item/reagent_containers/syringe/insulin
	name = "syringe (insulin)"
	desc = "Contains insulin - used to treat diabetes."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("insulin", 15)
		update_icon()

/obj/item/reagent_containers/syringe/haloperidol
	name = "syringe (anti-psychotic)"
	desc = "Contains haloperidol - used for sedation and to counter violent psychosis."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("haloperidol", 15)
		update_icon()

/obj/item/reagent_containers/syringe/antitoxin
	name = "syringe (anti-toxin)"
	desc = "Contains charcoal - used to treat toxins and damage from toxins."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("charcoal", 15)
		update_icon()

/obj/item/reagent_containers/syringe/antiviral
	name = "syringe (spaceacillin)"
	desc = "Contains antibacterial agents."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("spaceacillin", 15)
		update_icon()

/obj/item/reagent_containers/syringe/atropine
	name = "syringe (atropine)"
	desc = "Contains atropine, a rapid antidote for nerve gas exposure."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("atropine", 15)
		update_icon()

// drugs

/obj/item/reagent_containers/syringe/krokodil
	name = "syringe (krokodil)"
	desc = "Contains krokodil, a sketchy homemade opiate often used by disgruntled Cosmonauts.."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("krokodil", 15)
		update_icon()

/obj/item/reagent_containers/syringe/morphine
	name = "syringe (morphine)"
	desc = "Contains morphine, a strong but highly addictive opiate painkiller with sedative side effects."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("morphine", 15)
		update_icon()

/obj/item/reagent_containers/syringe/calomel
	name = "syringe (calomel)"
	desc = "Contains calomel, which be used to purge impurities, but is highly toxic itself."
	initial_volume = 15

	New()
		..()
		reagents.add_reagent("calomel", 15)
		update_icon()
