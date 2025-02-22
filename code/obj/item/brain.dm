// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/brain
	name = "brain"
	desc = "A human brain, gross."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "brain2"
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "brain2"
	flags = TABLEPASS
	force = 1.0
	w_class = 1.0
	throwforce = 1.0
	throw_speed = 3
	throw_range = 5
	var/datum/mind/owner = null
	stamina_damage = 5
	stamina_cost = 5
	edible = 1

/obj/item/brain/New()
	..()
	spawn(5)
		if(src.donor)
			src.name = "[src.donor]'s brain"
		if (icon_state == "brain2")
			desc = "A human brain. It looks [pick("small", "big", "normal", "rotten", "healthy", "tasty", "like it should be flushed down disposals", "bloody")]."

/obj/item/brain/examine()
	..()
	if (usr.job == "Roboticist" || usr.job == "Medical Doctor" || usr.job == "Geneticist" || usr.job == "Medical Director")
		if (src.owner)
			if (src.owner.current)
				boutput(usr, "<span style=\"color:blue\">This brain is still warm.</span>")
			else
				boutput(usr, "<span style=\"color:red\">This brain has gone cold.</span>")
		else
			boutput(usr, "<span style=\"color:red\">This brain has gone cold.</span>")

/obj/item/brain/throw_impact(var/turf/T)
	playsound(src.loc, "sound/effects/splat.ogg", 100, 1)
	if (T)
		new /obj/decal/cleanable/blood(T)

/obj/item/brain/synth
	name = "synthbrain"
	item_state = "plant"
	desc = "An artificial mass of grey matter. Not actually, as one might assume, very good at thinking."

	New()
		..()
		src.icon_state = pick("plant_brain", "plant_brain_bloom")

/obj/item/brain/ai
	name = "neural net processor"
	desc = "A heavily augmented human brain, upgraded to deal with the large amount of information an AI unit must process."
	icon_state = "ai_brain"
	item_state = "ai_brain"

	New()
		..()
		spawn(10)
			if(src.owner && src.owner.current)
				src.name = "[src.owner.current]'s neural net processor"

/obj/item/brain/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(!istype(M, /mob))
		return

	src.add_fingerprint(user)

	if(!(user.zone_sel.selecting == ("head")) || !istype(M, /mob/living/carbon/human))
		return ..()

	if(!(locate(/obj/machinery/optable, M.loc) && M.lying) && !(locate(/obj/table, M.loc) && (M.paralysis || M.stat)))
		return ..()

	var/mob/living/carbon/human/H = M
	if(istype(M, /mob/living/carbon/human) && ((H.head && H.head.c_flags & COVERSEYES) || (H.wear_mask && H.wear_mask.c_flags & COVERSEYES) || (H.glasses && H.glasses.c_flags & COVERSEYES)))
		// you can't stab someone in the eyes wearing a mask!
		boutput(user, "<span style=\"color:blue\">You're going to need to remove that mask/helmet/glasses first.</span>")
		return

//since these people will be dead M != usr
/*
	if(M:brain_op_stage == 4.0)

		var/fluff = pick("insert[M == user ? "" : "s"]", "shove[M == user ? "" : "s"]", "place[M == user ? "" : "s"]", "drop[M == user ? "" : "s"]", "smooshes[M == user ? "" : "s"]", "squishes[M == user ? "" : "s"]")
		M.visible_message("<span style=\"color:red\"><b>[user]</b> [fluff] [src] into [M == user ? </span>"[M.gender == "male" ? "his" : "her"]" : "[M]'s"] head!", \
		"<span style=\"color:red\">[M == user ? </span>"You" : "<b>[user]</b>"] [fluff] [src] into your head!")

		if(M.client)
			M.client.mob = new/mob/dead/observer(M)
		//a mob can't have two clients so get rid of one

		if(src.owner)
/*
		//if the brain has an owner corpse
			if(src.owner.client)
			//if the player hasn't ghosted
				src.owner.client.mob = M
				//then put them in M
			else
			//if the player HAS ghosted
				for(var/mob/dead/observer/O in mobs)
					if(O.corpse == src.owner && O.client)
					//find their ghost
						O.client.mob = M
						//put their mob in M
						qdel(O)
						//delete thier ghost
*/
			src.owner.transfer_to(M)
		M:brain_op_stage = 3.0

		qdel(src)
	else
		..()
	return

*/