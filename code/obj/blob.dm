// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/blob
	name = "blob"
	desc = "A mysterious alien blob-like organism."
	icon = 'icons/mob/blob.dmi'
	icon_state = "15"
	color = "#FF0000"
	var/original_color = "#FF0000"
	alpha = 180
	density = 1
	opacity = 0
	anchored = 1
	var/health = 30         // current health of the blob
	var/health_max = 30     // health cap
	var/armor = 1           // how much incoming damage gets divided by unless it bypasses armor
	var/ideal_temp = 310    // what temperature the blob is safe at
	var/mob/living/intangible/blob_overmind/overmind = null // who's the player controlling this blob
	var/gen_rate_value = 0  // how much gen rate upkeep the overmind is paying on this tile
	var/can_spread_from_this = 1
	var/can_attack_from_this = 1
	var/poison = 0
	var/can_absorb = 1
	var/special_icon = 0
	var/spread_type = null
	var/spread_value = 0
	var/movable = 0
	var/in_disposing = 0
	var/datum/action/bar/blob_health/healthbar //Hack.
	var/static/image/poisoned_image
	var/fire_coefficient = 1
	var/poison_coefficient = 1
	var/poison_spread_coefficient = 1
	var/poison_depletion = 1
	var/heat_divisor = 10
	var/temp_tolerance = 40
	mat_changename = 0
	mat_changedesc = 0
	var/runOnLife = 0 //Should this obj run Life?

	New()
		..()
		if (!poisoned_image)
			poisoned_image = image('icons/mob/blob.dmi', "poison")
		src.update_icon()
		update_surrounding_blob_icons(get_turf(src))
		var/datum/controller/process/blob/B = get_master_blob_controller()
		B.blobs += src
		for (var/obj/machinery/camera/C in get_turf(src))
			qdel(C)

		healthbar = new
		healthbar.owner = src
		healthbar.onStart()
		healthbar.onUpdate()

	proc/right_click_action()
		examine()

	Click(location, control, params)
		if (usr != overmind)
			return
		var/list/pa = params2list(params)
		if (pa.Find("right"))
			right_click_action()
		else
			..()

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		. = ..()
		var/obj/projectile/P = mover
		if (istype(P))
			if (P.proj_data.type == /datum/projectile/slime)
				return 1
		if (istype(mover, /obj/decal))
			return 1

	proc/setOvermind(var/mob/living/intangible/blob_overmind/O)
		if (overmind == O)
			return
		if (overmind)
			overmind.blobs -= src
		if (O)
			overmind = O
			setMaterial(copyMaterial(O.my_material))
			color = material.color
			original_color = color
			if (!(src in O.blobs))
				O.blobs += src
			onAttach(O)

	proc/onAttach(var/mob/living/intangible/blob_overmind/new_overmind)
		if (istype(new_overmind))
			if (spread_value)
				new_overmind.spread_mitigation += spread_value

	proc/attack(var/turf/T)
		particleMaster.SpawnSystem(new /datum/particleSystem/blobattack(T,overmind.color))
		if (T.density)
			T.blob_act(overmind.attack_power * 20)
		else
			for (var/mob/M in T.contents)
				M.blob_act(overmind.attack_power * 20)
			for (var/obj/O in T.contents)
				O.blob_act(overmind.attack_power * 20)

	proc/attack_random()
		var/list/allowed = list()
		for (var/D in cardinal)
			var/turf/Q = get_step(get_turf(src), D)
			if (!(locate(/obj/blob) in Q))
				allowed += Q
		if (allowed.len)
			attack(pick(allowed))

	disposing()
		if (disposed || in_disposing)
			return
		in_disposing = 1
		var/datum/controller/process/blob/B = get_master_blob_controller()
		B.blobs -= src
		blobs -= src
		if (istype(overmind))
			overmind.blobs -= src
			if (gen_rate_value > 0)
				overmind.gen_rate_used = max(0,overmind.gen_rate_used - gen_rate_value)
				gen_rate_value = 0
			overmind.spread_mitigation -= spread_value
		var/turf/T = get_turf(src)
		..()
		healthbar.onDelete()
		qdel(healthbar)
		update_surrounding_blob_icons(T)
		in_disposing = 0

	ex_act(severity)
		var/damage = 0
		var/damage_mult = 1
		switch(severity)
			if(1)
				damage = rand(30,50)
				damage_mult = 8
			if(2)
				damage = rand(25,40)
				damage_mult = 4
			if(3)
				damage = rand(10,20)
				damage_mult = 2
				if (prob(5))
					create_chunk(get_turf(src))

		src.take_damage(damage,damage_mult,"mixed")
		return

	bullet_act(var/obj/projectile/P)
		var/damage = round((P.power*P.proj_data.ks_ratio), 1.0)
		var/damage_mult = 1
		var/damtype = "brute"
		if (damage < 1)
			return

		switch(P.proj_data.damage_type)
			if(D_KINETIC)
				damage_mult = 0.5
				damtype = "brute"
			if(D_PIERCING)
				damage_mult = 0.25
				damtype = "brute"
			if(D_ENERGY)
				damage_mult = 1
				damtype = "laser" // a type of burn damage that fire resistant membranes don't protect against
			if(D_BURNING)
				damage_mult = 2
				damtype = "burn"
			if(D_SLASHING)
				damage_mult = 1.5
				damtype = "brute"

		src.take_damage(damage,damage_mult,damtype)
		return

	temperature_expose(datum/gas_mixture/air, temperature, volume)
		var/temp_difference = abs(temperature - src.ideal_temp)

		if (material)
			material.triggerTemp(src, temperature)

		if (src.has_upgrade(/datum/blob_upgrade/fire_resist))
			temp_tolerance *= 3
		if(temp_difference > temp_tolerance)
			temp_difference = abs(temp_difference - temp_tolerance)

			src.take_damage(temp_difference / heat_divisor, 1, "burn")

	attack_hand(var/mob/user)
		var/adj1
		var/adj2 = pick_string("blob.txt", "adj2")
		var/act1
		var/act2 = pick_string("blob.txt", "act2")
		switch(user.a_intent)
			if(INTENT_HELP)
				adj1 = "help"
			if(INTENT_DISARM)
				adj1 = "disarm"
			if(INTENT_GRAB)
				adj1 = "grab"
			if(INTENT_HARM)
				adj1 = "harm"
		act1 = pick_string("blob.txt", "act1_[adj1]")
		adj1 = pick_string("blob.txt", "adj1_[adj1]")
		playsound(src.loc, "sound/effects/attackblob.ogg", 50, 1)
		src.visible_message("<span class='combat'><b>[user.name]</b> [adj1] [act1] [src]! That's [adj2] [act2]!</span>")
		return

	attackby(var/obj/item/W, var/mob/user)
		src.visible_message("<span class='combat'><b>[user.name]</b> attacks [src] with [W]!</span>")
		playsound(src.loc, "sound/effects/attackblob.ogg", 50, 1)
		if (W.hitsound)
			playsound(src.loc, W.hitsound, 50, 1)

		var/damage = W.force
		var/damage_mult = 1
		var/damtype = "brute"
		if (W.damtype == "burn" || W.damtype == "fire")
			damtype = "burn"

		if (damage)
			if (overmind)
				overmind.onBlobHit(src, user)

			if (src.type == /obj/blob && damtype == "brute")
				var/chunk_chance = 2
				if (W.hit_type == DAMAGE_CUT)
					chunk_chance = 8
				if (prob(chunk_chance))
					create_chunk(get_turf(user))

		if (material)
			material.triggerOnAttacked(src, user, src, W)

		src.take_damage(damage,damage_mult,damtype,user)

		if (istype(W, /obj/item/crowbar))
			user.unlock_medal("Is it really that time again?", 1)

		return

	proc/create_chunk(var/turf/T)
		var/obj/item/material_piece/wad/BC = new /obj/item/material_piece/wad(T)
		BC.setMaterial(copyMaterial(material))
		BC.name = "chunk of blob"

	proc/take_damage(var/amount,var/damage_mult = 1,var/damtype = "brute",var/mob/user)
		if (!isnum(amount) || amount <= 0)
			return

		if (damage_mult <= 0)
			damage_mult = 1

		if (damtype == "mixed")
			var/brute = round(amount / 2)
			var/burn = amount - brute
			take_damage(brute, damage_mult, "brute", user)
			take_damage(burn,  damage_mult, "burn",  user)
			return

		var/armor_value = armor
		var/ignore_armor = 0
		switch (damtype)
			if ("burn")
				if (!src.has_upgrade(/datum/blob_upgrade/fire_resist))
					ignore_armor = 1
				else
					amount = min(amount, health_max * 0.8)
				amount *= fire_coefficient
			if ("laser")
				ignore_armor = 1
			if ("poison","self_poison")
				if (!src.has_upgrade(/datum/blob_upgrade/poison_resist))
					ignore_armor = 1
				else
					armor_value = max(2, armor)
				amount *= poison_coefficient
			if ("chaos")
				ignore_armor = 1
		if (!ignore_armor && armor_value > 0)
			amount /= armor_value

		amount *= damage_mult

		if (damtype == "burn")
			for (var/obj/blob/ectothermid/T in range(3, src))
				if (T && amount > 0)
					amount -= T.consume(amount)
		if (!amount)
			return

		if (damtype == "poison")
			src.poison += amount
			updatePoisonOverlay()
			if (!overmind)
				spawn(10)
					while (poison)
						Life()
						sleep(10)

		src.health -= amount
		src.health = max(0,min(src.health_max,src.health))

		if (src.health == 0)
			src.onKilled()
			if (overmind)
				overmind.onBlobDeath(src, user)
			qdel(src)
		else
			src.update_icon()
			healthbar.onUpdate()
		return

	proc/updatePoisonOverlay()
		if (!poison)
			animate(src)
			color = original_color
		else
			animate(src, color="#00FF00", time=10, loop=-1)

	proc/onKilled()
		if (poison)
			poison = poison * poison_spread_coefficient
			var/list/spread = list()
			for (var/d in cardinal)
				var/turf/T = get_step(loc, d)
				if (T)
					var/obj/blob/B = locate() in T
					if (B)
						spread += B
			if (spread.len)
				var/amt = poison / spread.len
				for (var/obj/blob/B in spread)
					B.poison += amt
		for (var/obj/material_deposit/M in src.loc)
			visible_message("<span style=\"color:red\">[M] crumbles into dust!</span>")
			qdel(M)

	proc/heal_damage(var/amount)
		if (!isnum(amount) || amount < 1)
			return
		if (src.poison)
			amount /= 4
		src.health += amount
		src.health = max(0,min(src.health_max,src.health))
		particleMaster.SpawnSystem(new /datum/particleSystem/blobheal(get_turf(src),src.color))
		src.update_icon()
		healthbar.onUpdate()

	proc/update_icon()
		if (!src)
			return

		if (!special_icon)
			var/dirs = 0
			for (var/dir in cardinal)
				var/turf/T = get_step(src, dir)
				if (!T)
					continue

				var/obj/blob/B = T.get_blob_on_this_turf()
				if (B)
					dirs |= dir
			icon_state = num2text(dirs)

		src.setMaterial(src.material)
		var/healthperc = get_x_percentage_of_y(src.health,src.health_max)
		switch(healthperc)
			if (-INFINITY to 33)
				src.alpha *= 0.25
			if (34 to 66)
				src.alpha *= 0.5
			if (66 to 99)
				src.alpha *= 0.75
		src.alpha = max(src.alpha, 32)

	proc/spread(var/turf/T)
		if (!istype(T) || !T.can_blob_spread_here())
			return

		var/blob_type = /obj/blob/
		if (ispath(src.spread_type))
			blob_type = src.spread_type

		var/obj/blob/B = new blob_type(T)
		B.setOvermind(overmind)

		return B

	proc/Life()
		if (disposed)
			return 1
		if (!overmind)
			return 1
		if (overmind.tutorial)
			if (!overmind.tutorial.PerformSilentAction("blob-life", src))
				return 0
		if (src.poison)
			var/damage_taken = min(5, src.poison)
			take_damage(damage_taken, 1, "self_poison")
			src.poison -= damage_taken * poison_depletion
			src.poison = max(src.poison, 0)
			updatePoisonOverlay()

		return 0

	proc/has_upgrade(var/upgrade_path)
		if (!ispath(upgrade_path) && !istype(src.overmind))
			return 0
		if (src.overmind && src.overmind.has_upgrade(upgrade_path))
			return 1
		else
			return 0

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (O == src)
			return
		if (O.disposed)
			return
		if (overmind != user)
			return
		if (istype(O, /obj/item))
			if (get_dist(O, src) > 1)
				return
			var/datum/blob_ability/devour_item/D = overmind.get_ability(/datum/blob_ability/devour_item)
			if (D)
				D.onUse(O)
			return
		if (istype(O, /obj/material_deposit))
			O.set_loc(src.loc)
		if (!istype(O, /obj/blob))
			return
		if (overmind.tutorial)
			if (!overmind.tutorial.PerformAction("mousedrop", list(O, src)))
				return
		if (istype(O, /obj/blob) && src.type == /obj/blob) // I'M LAZY. i'll fix this up if needed
			var/obj/blob/Q = O
			if (Q.movable)
				Q.onMove(src)

	proc/onMove(var/obj/blob/B)
		return

	onMaterialChanged()
		..()
		if (material && material.mat_id != "blob")
			src.name = "[material.name] [initial(src.name)]"

			// ARBITRARY MATH TIME! WOO!
			var/om_tough = overmind.initial_material.getProperty(PROP_TOUGHNESS)
			var/c_tough = material.getProperty(PROP_TOUGHNESS)
			var/hm_orig = initial(health_max)

			if (om_tough)
				var/hm_new = hm_orig * (c_tough / om_tough)
				var/perc_change = hm_new / health_max
				health_max = hm_new
				health *= perc_change

			var/om_mp = overmind.initial_material.getProperty(PROP_MELTING)
			var/c_mp = material.getProperty(PROP_MELTING)
			var/hd_orig = initial(heat_divisor)

			var/mp_diff = max(0, c_mp - om_mp)
			heat_divisor = hd_orig + mp_diff / 300

			var/om_flame = overmind.initial_material.getProperty(PROP_FLAMMABILITY)
			var/c_flame = material.getProperty(PROP_FLAMMABILITY)
			var/fc_orig = initial(fire_coefficient)

			if (om_flame)
				var/t = (100 / om_flame * c_flame) / 100
				fire_coefficient = (0.25 + (t * 0.75)) * fc_orig

			var/om_perme = overmind.initial_material.getProperty(PROP_PERMEABILITY)
			var/c_perme = material.getProperty(PROP_PERMEABILITY)
			var/psc_orig = initial(poison_spread_coefficient)

			if (om_perme)
				var/t = (100 / om_perme * c_perme) / 100
				poison_spread_coefficient = (0.5 + (t * 0.5)) * psc_orig

			var/om_corr = overmind.initial_material.getProperty(PROP_CORROSION)
			var/c_corr = material.getProperty(PROP_CORROSION)
			var/pc_orig = initial(poison_coefficient)

			if (om_corr)
				var/pc_new = pc_orig * (om_corr / c_corr)
				poison_coefficient = pc_new

			if (material.alpha > 210)
				opacity = 1
			else
				opacity = initial(opacity)

		else
			src.name = initial(src.name)
			var/hm_curr = health_max
			health_max = initial(health_max)
			health *= health_max / hm_curr
			heat_divisor = initial(heat_divisor)
			fire_coefficient = initial(fire_coefficient)
			opacity = initial(opacity)
		original_color = color

/obj/blob/nucleus
	name = "blob nucleus"
	icon_state = "nucleus"
	special_icon = 1
	desc = "The core of the blob. Destroying all nuclei effectively stops the organism dead in its tracks."
	armor = 3
	health_max = 250
	health = 250
	temp_tolerance = 1200
	fire_coefficient = 0.5
	poison_coefficient = 0.5
	poison_depletion = 3
	var/lastAttackMsg = null

	onAttach(var/mob/living/intangible/blob_overmind/O)
		..()
		O.nuclei += src

	take_damage(amount, mult, damtype, mob/user)
		var/now = world.timeofday
		if (!lastAttackMsg || now - lastAttackMsg >= 50) //every 5 seconds supposedly
			boutput(overmind, "<span style=\"color:red\"><b>Your nucleus in [get_area(src)] is taking damage!</b></span>")
			lastAttackMsg = now

		return ..()

	onKilled()
		overmind.nuclei -= src
		..()


/obj/blob/mutant
	name = "mutated blob"
	icon_state = "mutant"
	special_icon = 1
	desc = "It's a mutated blob bit. For all intents and purposes, it is useless."
	armor = 0
	can_absorb = 0
	movable = 0

/obj/blob/deposit
	name = "reagent deposit"
	icon_state = "deposit"
	special_icon = 1
	desc = "It's a thick walled cell with reagents entrenched within."
	armor = 1
	gen_rate_value = 0
	can_absorb = 0
	var/static/image/overlay_image = null
	var/last_color = null
	var/building = 0
	movable = 1

	New()
		..()
		if (!overlay_image)
			overlay_image = image('icons/mob/blob.dmi', "deposit-reagent")

	examine()
		if (disposed)
			return
		..()
		if (usr == overmind)
			if (movable)
				boutput(usr, "<span style=\"color:blue\">Clickdrag this onto any standard (not special) blob tile to move the reagent deposit there.</span>")
			boutput(usr, "<span style=\"color:blue\">It contains:</span>")
			for (var/id in src.reagents.reagent_list)
				var/datum/reagent/R = src.reagents.reagent_list[id]
				boutput(usr, "<span style=\"color:blue\">- [R.volume] unit[R.volume != 1 ? "s" : null] of [R.name]</span>")

	proc/update_reagent_overlay()
		if (disposed)
			return
		if (src.reagents.total_volume <= 0)
			overlays.len = 0
			return
		var/curr_color = src.reagents.get_average_rgb()
		if (curr_color != last_color)
			overlays.len = 0
			overlay_image.color = curr_color
			last_color = curr_color
			overlays += overlay_image

	proc/build_reclaimer()
		if (disposed || building)
			return
		building = 1
		var/obj/blob/deposit/reclaimer/B = new(src.loc)
		B.setOvermind(overmind)
		B.reagents = src.reagents
		B.reagents.my_atom = B
		B.update_reagent_overlay()
		src.reagents = null
		B.setMaterial(src.material)
		src.material = null
		qdel(src)

	proc/build_replicator()
		if (disposed || building)
			return
		building = 1
		var/obj/blob/deposit/replicator/B = new(src.loc)
		B.setOvermind(overmind)
		B.reagents = src.reagents
		B.reagents.my_atom = B
		B.set_master_reagent()
		B.update_reagent_overlay()
		src.reagents = null
		B.setMaterial(src.material)
		src.material = null
		qdel(src)

	onKilled()
		if (disposed)
			return
		..()
		if (src.reagents && src.reagents.total_volume)
			visible_message("<span style=\"color:red\">[src] bursts open, releasing the deposited reagents in a cloud!</span>")
			smoke_reaction(reagents, 3, loc)

	onMove(var/obj/blob/B)
		var/turf/T = B.loc
		B.set_loc(loc)
		set_loc(T)
		update_icon()
		B.update_icon()

	replicator
		name = "replicator"
		icon_state = "replicator"
		runOnLife = 1
		var/points_per_unit = 1
		var/max_per_tick = 3

		var/master_reagent_id = null
		var/datum/reagents/converting = null
		var/datum/action/bar/blob_replicator/progress = new

		New()
			..()
			progress.owner = src
			progress.onStart()

		disposing()
			..()
			progress.onDelete()
			qdel(progress)

		proc/set_master_reagent()
			if (master_reagent_id)
				return
			if (src.reagents && src.reagents.total_volume)
				master_reagent_id = src.reagents.get_master_reagent()
				name = "[initial(name)] ([src.reagents.get_master_reagent_name()])"
				src.reagents.clear_reagents()

		Life()
			if (converting)
				var/removed = min(max_per_tick, converting.total_volume)
				reagents.maximum_volume = reagents.total_volume + removed
				reagents.add_reagent(master_reagent_id, removed)
				converting.remove_any(removed)
				if (converting.total_volume < 1)
					converting = null
				update_reagent_overlay()
				progress.onUpdate()

		MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
			if (O.disposed)
				return
			if (overmind.tutorial)
				if (!overmind.tutorial.PerformAction("mousedrop", list(O, src)))
					return
			if (O.type == /obj/blob/deposit)
				if (src.converting)
					boutput(user, "<span style=\"color:red\">Something is already loaded into the replicator.</span>")
					return
				var/obj/blob/deposit/D = O
				if (D.overmind != user)
					return
				var/obj/blob/B = new(O.loc)
				B.setOvermind(overmind)
				converting = O.reagents
				converting.my_atom = src
				converting.maximum_volume = converting.total_volume
				O.reagents = null
				boutput(user, "<span style=\"color:blue\">Reagents transferred to the replicator.</span>")
				qdel(O)
				update_reagent_overlay()
				progress.onUpdate()

		onMove(var/obj/blob/B)
			if (B.disposed)
				return
			if (!isturf(B.loc))
				return
			if (!reagents)
				return
			if (!reagents.total_volume)
				return
			var/obj/blob/deposit/D = new(B.loc)
			D.setOvermind(overmind)
			qdel(B)
			var/trans_amt = src.reagents.total_volume
			D.reagents = new /datum/reagents(trans_amt)
			D.reagents.my_atom = D
			src.reagents.trans_to(D, trans_amt)
			D.update_reagent_overlay()
			boutput(usr, "<span style=\"color:blue\">Transferred [trans_amt] reagents into a deposit.</span>")
			update_reagent_overlay()

	reclaimer
		name = "reclaimer"
		icon_state = "reclaimer"
		runOnLife = 1
		var/reagents_per_point = 5
		var/max_per_tick = 3
		var/may_gain_last = null
		movable = 0

		Life()
			if (..())
				return 1
			var/can_gain = round(reagents.total_volume / reagents_per_point)
			if (can_gain <= 0)
				var/obj/blob/lipid/B = new(loc)
				B.setOvermind(overmind)
				qdel(src)
			var/may_gain = min(max_per_tick, overmind.bio_points_max - overmind.bio_points)
			may_gain_last = may_gain
			if (may_gain)
				particleMaster.SpawnSystem(new /datum/particleSystem/blobheal(get_turf(src),src.color))
				src.reagents.remove_any(reagents_per_point * may_gain)
				overmind.bio_points += may_gain
				reagents.maximum_volume = reagents.total_volume
				update_reagent_overlay()

/obj/blob/launcher
	name = "slime launcher"
	icon_state = "cannon"
	special_icon = 1
	desc = "It's a slime ball launcher. The organic equivalent of a defense turret."
	armor = 0
	gen_rate_value = 0
	can_absorb = 0
	runOnLife = 1
	var/slime_cost = 2
	var/firing_range = 7
	var/last_color = null
	var/datum/projectile/slime/current_projectile = new
	var/static/image/underlay_image = null

	New()
		..()
		if (!underlay_image)
			underlay_image = image('icons/mob/blob.dmi', "deposit-reagent")

	proc/update_reagent_underlay()
		if (disposed)
			return
		if (src.reagents.total_volume <= 0)
			underlays.len = 0
			return
		var/curr_color = src.reagents.get_average_rgb()
		if (curr_color != last_color)
			underlays.len = 0
			underlay_image.color = curr_color
			last_color = curr_color
			underlays += underlay_image

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (O.disposed)
			return
		if (overmind.tutorial)
			if (!overmind.tutorial.PerformAction("mousedrop", list(O, src)))
				return
		if (O.type == /obj/blob/deposit)
			if (src.reagents && src.reagents.total_volume)
				boutput(user, "<span style=\"color:red\">Something is already loaded into the slime launcher.</span>")
				return
			var/obj/blob/deposit/D = O
			if (D.overmind != user)
				return
			var/obj/blob/B = new(O.loc)
			B.setOvermind(overmind)
			reagents = O.reagents
			reagents.my_atom = src
			O.reagents = null
			boutput(user, "<span style=\"color:blue\">Reagents transferred to the slime launcher.</span>")
			qdel(O)
			update_reagent_underlay()

	Life()
		if (..())
			return 1
		var/cost = 2
		if (reagents)
			if (reagents.total_volume)
				cost = 0
		if (cost && !overmind.hasPoints(slime_cost))
			return 1
		var/list/targets_primary = list()
		var/list/targets_secondary = list()
		for (var/mob/living/carbon/human/H in view(firing_range, src))
			if (H.stat != 2)
				if (!H.mutantrace)
					targets_primary += H
				else
					targets_secondary += H
		if (!targets_primary.len && !targets_secondary.len)
			return 1
		var/mob/living/carbon/human/Target = null
		if (targets_primary.len)
			Target = pick(targets_primary)
		else
			Target = pick(targets_secondary)
		if (!Target)
			return 1
		var/obj/projectile/L = initialize_projectile_ST(src, current_projectile, Target)
		if (!L)
			return
		L.setup()
		if (!cost)
			L.reagents = new /datum/reagents(15)
			L.reagents.my_atom = L
			reagents.trans_to(L, 5, 3)
			L.color = L.reagents.get_average_rgb()
			L.name = "[L.reagents.get_master_reagent_name()]-infused slime"
			update_reagent_underlay()
		else
			overmind.usePoints(slime_cost)
			L.color = overmind.color
		visible_message("<span style=\"color:red\"><b>[src] fires slime at [Target]!</b></span>")
		L.launch()

/datum/projectile/slime
	name = "slime"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "slime"
	color_red = 0
	color_green = 0
	color_blue = 0
	color_icon = "#ffffff"
	power = 20
	cost = 0
	dissipation_rate = 25
	dissipation_delay = 8
	ks_ratio = 0.5
	sname = "slime"
	shot_sound = 'sound/effects/attackblob.ogg'
	shot_number = 0
	damage_type = D_SPECIAL
	hit_ground_chance = 50
	window_pass = 0
	override_color = 1

	on_hit(atom/hit, angle, var/obj/projectile/O)
		..()
		if (O.reagents)
			O.reagents.reaction(hit)
			if (ismob(hit))
				O.reagents.trans_to(hit, 15)
		if (ismob(hit))
			var/mob/asshole = hit
			asshole.TakeDamage("All", 8, 0)
			if (ishuman(asshole))
				var/mob/living/carbon/human/literal_asshole = asshole
				literal_asshole.remove_stamina(45)
				if (prob(8))
					literal_asshole.drop_item()

/obj/blob/mitochondria
	name = "mitochondria"
	icon_state = "mitochondria"
	special_icon = 1
	desc = "It's a giant energy converting cell. It seems to be knitting together nearby holes in the blob."
	armor = 0
	gen_rate_value = 0
	can_absorb = 0
	runOnLife = 1
	var/heal_range = 2
	var/heal_amount = 4

	Life()
		if (..())
			return 1
		for (var/obj/blob/B in view(heal_range,src))
			if (B.health < B.health_max)
				B.heal_damage(heal_amount)

/obj/blob/reflective
	name = "reflective membrane"
	icon_state = "reflective"
	special_icon = 1
	desc = "This cell seems to reflect light."
	armor = 0
	gen_rate_value = 0
	can_absorb = 0
	opacity = 1
	health = 45
	health_max = 45

	bullet_act(var/obj/projectile/P)
		if (P.proj_data.damage_type == D_ENERGY)
			shoot_reflected(P, src)
		else
			..()

/obj/blob/ectothermid
	name = "ectothermid"
	icon_state = "ectothermid"
	special_icon = 1
	desc = "It's a giant energy converting cell. It seems to disperse matter using heat energy."
	armor = 0
	gen_rate_value = 1
	can_absorb = 0
	runOnLife = 1
	var/protect_range = 3
	var/damage_per_biopoint = 50
	var/max_biopoints_per_tick = 40
	var/damage_credit = 0
	var/points_used = 0

	proc/consume(var/amt)
		if (amt <= 0)
			return 0
		while (amt)
			if (damage_credit >= amt)
				damage_credit -= amt
				return amt
			else
				if (points_used < max_biopoints_per_tick)
					if (!overmind.hasPoints(1))
						var/turf/T = get_turf(src)
						set_loc(null)
						var/obj/blob/B = new /obj/blob(T)
						B.overmind = overmind
						overmind.blobs += B
						B.color = overmind.color
						qdel(src)
					damage_credit += damage_per_biopoint
					points_used++
					overmind.usePoints(1)
				else
					var/ret = damage_credit
					damage_credit = 0
					return ret
		return 0

	temperature_expose(datum/gas_mixture/air, temperature, volume)
		if (temperature > T20C)
			temperature -= consume(temperature - T20C)
		..(air, temperature, volume)

	Life()
		if (..())
			return 1
		points_used = 0
		damage_credit = 0
		for (var/turf/simulated/floor/T in range(protect_range,src))
			var/datum/gas_mixture/air = T.air
			if (air.temperature > T20C)
				air.temperature -= 200

/obj/blob/plasmaphyll
	name = "plasmaphyll"
	icon_state = "plasmaphyll"
	special_icon = 1
	desc = "It's a giant energy converting cell. It seems to feed on certain gases."
	armor = 0
	gen_rate_value = 1
	can_absorb = 0
	runOnLife = 1
	var/protect_range = 3
	var/consume_per_tick = 5.5
	var/plasma_per_point = 2

	Life()
		if (..())
			return 1
		var/toxins_consumed = 0
		for (var/turf/simulated/floor/T in range(protect_range,src))
			var/datum/gas_mixture/air = T.air
			if (air.toxins > 0)
				if (air.temperature > T20C)
					air.temperature = T20C + (air.temperature - T20C) / 1.25
				toxins_consumed += min(consume_per_tick, air.toxins)
				air.toxins = max(air.toxins - consume_per_tick, 0)
		if (!toxins_consumed)
			return
		overmind.bio_points = min(overmind.bio_points + round(toxins_consumed / plasma_per_point), overmind.bio_points_max)

/obj/blob/lipid
	name = "lipid"
	icon_state = "lipid"
	special_icon = 1
	desc = "It's an energy storage cell. It stores biopoints."
	armor = 0
	can_absorb = 0

	onAttach(var/mob/living/intangible/blob_overmind/O)
		..()
		O.lipids += src

	proc/use()
		overmind.lipids -= src
		overmind.bio_points += 4
		var/turf/T = get_turf(src)
		set_loc(null)
		var/obj/blob/B = new /obj/blob(T)
		B.overmind = overmind
		overmind.blobs += B
		B.color = overmind.color
		qdel(src)

/obj/blob/ribosome
	name = "ribosome"
	icon_state = "ribosome"
	special_icon = 1
	desc = "It's a protein sequencing cell. It enhances the blob's ability to spread."
	armor = 0
	can_absorb = 0
	var/added = 0
	var/list/affected_blobs = list()

	onAttach(var/mob/living/intangible/blob_overmind/O)
		..()
		O.spread_mitigation += 1
		added = 1

	update_icon()
		return

	disposing()
		..()
		if (overmind)
			overmind.spread_mitigation -= added
			added = 0

/obj/blob/wall
	name = "thick membrane"
	desc = "This blob is encased in a tough membrane. It'll be harder to get rid of."
	icon_state = "wall"
	opacity = 1
	special_icon = 1
	armor = 2
	health = 75
	health_max = 75
	can_absorb = 0

	take_damage(var/amount,var/damage_mult = 1,var/damtype,var/mob/user)
		if (damage_mult == 0)
			return
		if (damtype != "mixed")
			if (amount * damage_mult > health_max * 0.6)
				amount = health_max * 0.6 / damage_mult
		..(amount, damage_mult, damtype, user)

	update_icon()
		return

/obj/blob/firewall
	name = "fire-resistant membrane"
	desc = "This blob is encased in a fireproof membrane."
	icon_state = "firewall"
	opacity = 1
	special_icon = 1
	armor = 2
	can_absorb = 0

	take_damage(amount, mult, damtype, mob/user)
		if (damtype == "burn")
			return
		else return ..()

	update_icon()
		return

/obj/material_deposit
	name = "material deposit"
	desc = "A blob-engulfed chunk of materials."
	var/mob/living/intangible/blob_overmind/overmind = null
	icon = 'icons/mob/blob.dmi'
	icon_state = "deposit-material"
	layer = 4

	New(nloc, mat, blob)
		..(nloc)
		src.overmind = blob
		setMaterial(copyMaterial(mat))
		pixel_x = rand(-12, 12)
		pixel_y = rand(-12, 12)

	onMaterialChanged()
		pixel_x = rand(-12, 12)
		pixel_y = rand(-12, 12)

	attackby(var/obj/item/W, var/mob/user)
		var/obj/blob/B = locate() in src.loc
		if (!B)
			qdel(src)
			return
		B.attackby(W, user)

/////////////////////////
/// BLOB RELATED PROCS //
/////////////////////////

/atom/proc/blob_act(var/power)
	return

/turf/proc/get_object_for_blob_to_attack()
	if (!src)
		return null

	if (src.contents.len < 1)
		return null

	for (var/obj/O in src.contents)
		if (O.density)
			return O

	for (var/mob/M in src.contents)
		if (M.stat != 2)
			return M

	return null

/turf/proc/can_blob_spread_here(var/mob/feedback)
	if (!src)
		return 0

	if (istype(src,/turf/space/))
		if (feedback)
			boutput(feedback, "<span style=\"color:red\">You can't spread the blob into space.</span>")
		return 0
	if (istype(src,/turf/unsimulated/))
		if (feedback)
			boutput(feedback, "<span style=\"color:red\">You can't spread the blob onto that kind of tile.</span>")
		return 0
	if (src.density)
		if (feedback)
			boutput(feedback, "<span style=\"color:red\">You can't spread the blob into a wall.</span>")
		return 0

	for (var/obj/O in src.contents)
		if (O.density)
			if (feedback)
				boutput(feedback, "<span style=\"color:red\">That tile is blocked by [O].</span>")
			return 0

	var/turf/checked
	for (var/dir in cardinal)
		checked = get_step(src, dir)
		for (var/obj/blob/B in checked.contents)
			if (B.type != /obj/blob/mutant)
				return B

	if (feedback)
		boutput(feedback, "<span style=\"color:red\">There is no blob adjacent to this tile to spread from.</span>")

	return 0

/turf/proc/is_blob_adjacent()
	if (!src)
		return 0

	var/turf/checked
	for (var/dir in cardinal)
		checked = get_step(src, dir)
		for (var/obj/blob/B in checked.contents)
			return 1

	return 0

/turf/proc/get_blob_on_this_turf()
	if (!src)
		return null

	for (var/obj/blob/B in src.contents)
		return B

	return null

/proc/get_master_blob_controller()
	for (var/datum/controller/process/blob/B in processScheduler.processes)
		return B
	return null

/proc/update_surrounding_blob_icons(var/turf/T)
	if (!istype(T))
		return
	for (var/obj/blob/B in orange(1,T))
		B.update_icon()
