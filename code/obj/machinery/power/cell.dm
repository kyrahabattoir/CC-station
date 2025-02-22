// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/cell
	name = "power cell"
	desc = "A rechargable electrochemical power cell."
	icon = 'icons/obj/power.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "cell"
	item_state = "cell"
	flags = FPRINT|TABLEPASS
	force = 5.0
	throwforce = 5.0
	throw_speed = 3
	throw_range = 5
	w_class = 3.0
	pressure_resistance = 80
	var/charge = 0	// note %age conveted to actual charge in New
	var/maxcharge = 7500
	m_amt = 700
	var/rigged = 0		// true if rigged to explode
	var/mob/rigger = null // mob responsible for the explosion
	var/genrate = 0		// how much power the cell generates by itself per process tick
	var/specialicon = 0	// used for autoprocess shit
	stamina_damage = 10
	stamina_cost = 10
	stamina_crit_chance = 10
	module_research = list("energy" = 8, "engineering" = 1, "miniaturization" = 3)
	module_research_type = /obj/item/cell

	onMaterialChanged()
		..()
		if (istype(src.material))
			genrate = round(material.getProperty(PROP_ENERGY) / 2)
			maxcharge = ((15000 * src.material.getProperty(PROP_ELECTRICAL)) + (src.material.getProperty(PROP_DIELECTRIC) * 750)) //should be 0 to 20000
			charge = maxcharge
		return

/obj/item/cell/supercell
	maxcharge = 15000

/obj/item/cell/erebite
	name = "erebite power cell"
	desc = "A small battery/generator unit powered by the unstable mineral Erebite. Do not expose to high temperatures or fire."
	icon_state = "erebcell"
	maxcharge = 15000
	genrate = 10
	specialicon = 1

/obj/item/cell/cerenkite
	name = "cerenkite power cell"
	desc = "A small battery/generator unit powered by the radioactive mineral Cerenkite."
	icon_state = "cerecell"
	maxcharge = 15000
	genrate = 2
	specialicon = 1

/obj/item/cell/shell_cell
	name = "AI shell power cell"
	desc = "A rechargable electrochemical power cell. It's made for AI shells."
	maxcharge = 4000

/obj/item/cell/charged
	charge = 7500

/obj/item/cell/supercell/charged
	charge = 15000

/obj/item/cell/erebite/charged
	charge = 15000

/obj/item/cell/cerenkite/charged
	charge = 15000

/obj/item/cell/shell_cell/charged
	charge = 4000

/obj/item/cell/New()
	..()

// I think this relic of a by-gone age is only used by APCs (in New()). Did result in absurd numbers for these
// pre-charged power cells, though. How did this go unnoticed for many years?
// 1) Power cell descs aren't dynamic. 2) Self-charging cells are in the item loop and capped.
// 3) The majority of charged power cells placed in the map editor were var-editied to use this formula (Convair880).

//	charge = charge * maxcharge/100.0		// map obj has charge as percentage, convert to real value here

	spawn(5)
		updateicon()

	if (genrate && !(src in processing_items))
		processing_items.Add(src)

/obj/item/cell/disposing()
	if (src in processing_items)
		processing_items.Remove(src)
	..()

/obj/item/cell/proc/updateicon()

	if(src.specialicon) return

	if(maxcharge <= 2500) icon_state = "cell"
	else icon_state = "hpcell"

	var/image/I = GetOverlayImage("charge_indicator")
	if(!I) I = image('icons/obj/power.dmi', "cell-o2")

	if(charge < 0.01)
		UpdateOverlays(null, "charge_indicator", 0, 1)
	else if(charge/maxcharge >=0.995)
		I.icon_state = "cell-o2"
		UpdateOverlays(I, "charge_indicator")
	else
		I.icon_state = "cell-o1"
		UpdateOverlays(I, "charge_indicator")

/obj/item/cell/proc/percent()		// return % charge of cell
	return 100.0*charge/maxcharge

// use power from a cell
/obj/item/cell/proc/use(var/amount)
	charge = max(0, charge-amount)
	if(rigged && amount > 0)
		if (rigger)
			message_admins("[key_name(rigger)]'s rigged cell exploded at [log_loc(src)].")
			logTheThing("combat", rigger, null, "'s rigged cell exploded at [log_loc(src)].")
		explode()

// recharge the cell
/obj/item/cell/proc/give(var/amount)
	charge = min(maxcharge, charge+amount)
	if(rigged && amount > 0)
		if (rigger)
			message_admins("[key_name(rigger)]'s rigged cell exploded at [log_loc(src)].")
			logTheThing("combat", rigger, null, "'s rigged cell exploded at [log_loc(src)].")
		explode()

/obj/item/cell/process()
	// Negative charge isn't an uncommon occurrence, but it appeared too expensive to keep an additional
	// ~270 power cells in the item loop just for this check (simple as it may be) (Convair880).
	src.charge = max(0, src.charge)
	if (genrate > 0) give(genrate)
	if (!genrate) ..()

/obj/item/cell/examine()
	set src in view(1)
	set category = "Local"
	if (src.artifact)
		..()
		return
	if(usr && !usr.stat)
		if(maxcharge <= 2500)
			boutput(usr, "[desc]<br>The manufacturer's label states this cell has a power rating of [maxcharge], and that you should not swallow it.<br>The charge meter reads [round(src.percent() )]%.")
		else
			boutput(usr, "This power cell has an exciting chrome finish, as it is an uber-capacity cell type! It has a power rating of [maxcharge]!!!<br>The charge meter reads [round(src.percent() )]%.")

/obj/item/cell/attackby(obj/item/W, mob/user) // Moved the stungloves stuff to gloves.dm (Convair880).
	if (istype(W, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = W
		boutput(user, "You inject the solution into the power cell.")

		if (S.reagents.has_reagent("plasma", 1))
			if (istype(src,/obj/item/cell/erebite))
				message_admins("[key_name(user)] injected [src] with plasma, causing an explosion at [log_loc(user)].")
				logTheThing("combat", user, null, "injected [src] with plasma, causing an explosion at [log_loc(user)].")
				boutput(user, "<span style=\"color:red\">The plasma reacts with the erebite and explodes violently!</span>")
				src.explode()
			else
				message_admins("[key_name(user)] rigged [src] to explode at [log_loc(user)].")
				logTheThing("combat", user, null, "rigged [src] to explode at [log_loc(user)].")
				rigged = 1
				rigger = user
		S.reagents.clear_reagents()

/*	else if (istype(W, /obj/item/cable_coil))
		var/obj/item/cable_coil/C = W
		if (C.amount < 4)
			user.show_text("You need at least 4 pieces of cable to attach it to [src].", "red")
		else if (src.zap(user))
			return
		else
			C.use(4)
			user.show_text("You attach some of the cable to [src].[prob(20) ? " That seems safe." : null]", "blue")
			new /obj/item/robodefibrilator/makeshift(get_turf(src), src)
			user.u_equip(src)
*/
	else
		return ..()

/obj/item/cell/proc/explode()
	if(src in bible_contents)
		for(var/obj/item/storage/bible/B in world)
			var/turf/T = get_turf(B.loc)
			if(T)
				T.hotspot_expose(700,125)
				explosion(src, T, -1, -1, 2, 3)
		bible_contents.Remove(src)
		qdel(src)
		return
	var/turf/T = get_turf(src.loc)

	explosion(src, T, 0, 1, 2, 2)

	spawn(1)
		qdel(src)


/obj/item/cell/proc/zap(mob/user as mob, var/ignores_gloves = 0)
	if (user.shock(src, src.charge, user.hand == 1 ? "l_arm" : "r_arm", 1, ignores_gloves))
		boutput(user, "<span style=\"color:red\">[src] shocks you!</span>")

		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span style=\"color:red\">[user:name] was shocked by the [src:name]!</span>", 3, "<span style=\"color:red\">You hear an electrical crack</span>", 2)
		return 1

/obj/item/cell/ex_act(severity)
	if (istype(src,/obj/item/cell/erebite)) src.explode()
	else ..()

/obj/item/cell/temperature_expose(null, temp, volume)
	if (istype(src,/obj/item/cell/erebite))
		src.visible_message("<span style=\"color:red\">[src] violently detonates!</span>")
		src.explode()
	else ..()

/obj/item/cell/is_detonator_attachment()
	return 1

/obj/item/cell/detonator_act(event, var/obj/item/assembly/detonator/det)
	switch (event)
		if ("pulse")
			if (det.part_fs.time > 10)
				det.part_fs.time = 10 //Oh no!
				det.attachedTo.visible_message("<span class='bold' style='color: #B7410E;'>The timer flashes ominously and decreases to [det.part_fs.time] seconds.</span>")
			else
				det.attachedTo.visible_message("<span class='bold' style='color: #B7410E;'>The timer flashes ominously.</span>")
		if ("cut")
			src.visible_message("<span class='bold' style='color: #B7410E;'>The failsafe timer buzzes refusingly before going quiet forever.</span>")
			spawn(0)
				det.detonate()