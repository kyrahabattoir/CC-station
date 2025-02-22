// SPDX-License-Identifier: CC-BY-NC-SA-3.0

//If i somehow could add something that sets the temp of all reagents to the average and calls their temp reactions
//in the update_total_temp , without causing an endless loop - i could have the reagents cool each other down etc.
//Right now only cryostylane does that kinda stuff because its coded that way. So yup. Right now you have to code it.

// Exadv1: reagent_list is now an ASSOCIATIVE LIST for performance reasons

//SpyGuy: Testing out a possibility-based reaction list

var/list/datum/reagents/active_reagent_holders = list()

proc/chem_helmet_check(mob/living/carbon/human/H)
	if(H.wear_mask)
		boutput(H, "<span style=\"color:red\">Your mask protects you from the hot liquid!</span>")
		return 0
	else if(H.head)
		boutput(H, "<span style=\"color:red\">Your helmet protects you from the hot liquid!</span>")
		return 0
	return 1


datum/reagents
	var/list/reagent_list = new/list()
	var/maximum_volume = 100
	var/atom/my_atom = null
	var/last_basic_explosion = 0

	var/last_temp = T20C
	var/total_temperature = T20C
	var/total_volume = 0

	var/defer_reactions = 0 //Set internally to prevent reactions inside reactions.
	var/deferred_reaction_checks = 0
	var/processing_reactions = 0
	var/desc = null		//(Inexact) description of the reagents. If null, needs refreshing.
	var/inert = 0 //Do not react. At all. Do not pass go, do not collect $200. Halt. Stop right there, son.


	var/list/datum/chemical_reaction/possible_reactions = list()
	var/list/datum/chemical_reaction/active_reactions = list()

datum/reagents/New(maximum=100)
	maximum_volume = maximum


datum/reagents/disposing()
	if (reagent_list)
		for(var/reagent_id in reagent_list)
			var/datum/reagent/current_reagent = reagent_list[reagent_id]
			if(current_reagent)
				pool(current_reagent)
		reagent_list.len = 0
		reagent_list = null
	my_atom = null
	total_volume = 0
	..()


datum/reagents/proc/copy_to(var/datum/reagents/target, var/multiplier = 1, var/do_not_react = 0)
	if(!target || target == src)
		return

	for(var/reagent_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[reagent_id]
		if(current_reagent)
			target.add_reagent(reagent=reagent_id, amount=max(current_reagent.volume * multiplier, 1),donotreact=do_not_react)

		if(!target)
			return

	return target


datum/reagents/proc/set_reagent_temp(var/new_temp = T0C, var/react = 0)
	src.last_temp = total_temperature
	src.total_temperature = new_temp
	if (react)
		temperature_react()


datum/reagents/proc/temperature_react() //Calls the temperature reaction procs without changing the temp.
	for(var/reagent_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[reagent_id]
		if(current_reagent)
			current_reagent.reaction_temperature(src.total_temperature, 100)


//This is what you use to change the temp of a reagent holder.
//Do not manually change the reagent unless you know what youre doing.
datum/reagents/proc/temperature_reagents(exposed_temperature, exposed_volume, divisor = 35, change_cap = 15)
	last_temp = total_temperature
	var/difference = abs(total_temperature - exposed_temperature)
	var/change = min(max((difference / divisor), 1), change_cap)
	if(exposed_temperature > total_temperature)
		total_temperature += change
	else if (exposed_temperature < total_temperature)
		total_temperature -= change

	total_temperature = max(min(total_temperature, 10000), 0) //Cap for the moment.
	temperature_react()

	handle_reactions()


datum/reagents/proc/remove_any(var/amount=1)
	if(amount > total_volume)
		amount = total_volume
	if(amount <= 0)
		return

	var/remove_ratio = amount/total_volume

	for(var/reagent_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[reagent_id]
		if(current_reagent)
			var/transfer_amt = current_reagent.volume*remove_ratio
			src.remove_reagent(reagent_id, transfer_amt)

	src.update_total()
	return amount


datum/reagents/proc/remove_any_except(var/amount=1, var/exception)
	if(amount > total_volume)
		amount = total_volume
	if(amount <= 0)
		return

	var/remove_ratio = amount/total_volume

	for(var/reagent_id in reagent_list)
		if (reagent_id == exception)
			continue

		var/datum/reagent/current_reagent = reagent_list[reagent_id]
		if(current_reagent)
			var/transfer_amt = current_reagent.volume*remove_ratio
			src.remove_reagent(reagent_id, transfer_amt)

	src.update_total()
	return amount


datum/reagents/proc/get_master_reagent_name()
	var/largest_name = null
	var/largest_volume = 0

	for(var/reagent_id in reagent_list)
		if(reagent_id == "smokepowder")
			continue
		var/datum/reagent/current = reagent_list[reagent_id]
		if(current.volume > largest_volume)
			largest_name = current.name
			largest_volume = current.volume

	return largest_name


datum/reagents/proc/get_master_color(var/ignore_smokepowder = 0)
	var/largest_volume = 0
	var/the_color = rgb(255,255,255,255)

	for(var/reagent_id in reagent_list)
		if(reagent_id == "smokepowder" && ignore_smokepowder)
			continue
		var/datum/reagent/current = reagent_list[reagent_id]
		if(current.volume > largest_volume)
			largest_volume = current.volume
			the_color = rgb(current.fluid_r, current.fluid_g, current.fluid_b, max(current.transparency,255))

	return the_color


datum/reagents/proc/get_master_reagent()
	var/largest_id = ""
	var/largest_volume = 0

	for(var/reagent_id in reagent_list)
		if(reagent_id == "smokepowder")
			continue
		var/datum/reagent/current = reagent_list[reagent_id]
		if(current.volume > largest_volume)
			largest_volume = current.volume
			largest_id = reagent_id

	return largest_id


datum/reagents/proc/trans_to(var/obj/target, var/amount=1, var/multiplier=1)
	if(amount > total_volume) amount = total_volume
	if(amount <= 0)
		return

	if (isnull(target.reagents))
		target.reagents = new

	var/datum/reagents/target_reagents = target.reagents
	return trans_to_direct(target_reagents, amount, multiplier)


datum/reagents/proc/trans_to_direct(var/datum/reagents/target_reagents, var/amount=1, var/multiplier=1)
	if (!target_reagents) //Wire: Fix for Division by zero
		return

	var/transfer_ratio = amount/total_volume
	for(var/reagent_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[reagent_id]

		if (isnull(current_reagent))
			continue

		var/transfer_amt = current_reagent.volume*transfer_ratio
		var/receive_amt = transfer_amt * multiplier

		//if(istype(current_reagent, /datum/reagent/disease))
		//	target_reagents.add_reagent_disease(current_reagent, (transfer_amt * multiplier), current_reagent.data, current_reagent.temperature)
		//else
		target_reagents.add_reagent(reagent_id, receive_amt, current_reagent.data, src.total_temperature)
		current_reagent.on_transfer(src, target_reagents, receive_amt)
		src.remove_reagent(reagent_id, transfer_amt)

	src.update_total()
	src.handle_reactions()
	// this was missing. why was this missing? i might be breaking the shit out of something here
	reagents_changed()

	if (!target_reagents) // on_transfer may murder the target, see: nitroglycerin
		return amount

	target_reagents.update_total()
	target_reagents.handle_reactions()
	return amount


datum/reagents/proc/aggregate_pathogens()
	var/list/ret = list()
	for (var/reagent_id in pathogen_controller.pathogen_affected_reagents)
		if (src.has_reagent(reagent_id))
			var/datum/reagent/blood/B = src.get_reagent(reagent_id)
			if (!istype(B))
				continue
			for (var/uid in B.pathogens)
				if (!(uid in ret))
					ret += uid
					ret[uid] = B.pathogens[uid]
	return ret


datum/reagents/proc/metabolize(var/mob/target)
	for(var/current_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[current_id]
		if(current_reagent)
			current_reagent.on_mob_life(target)
	update_total()


datum/reagents/proc/handle_reactions()
	if(src.inert) //We magically prevent all reactions inside ourselves.
		return

	//if(ismob(my_atom)) return //No reactions inside mobs :I
	if(defer_reactions)
		deferred_reaction_checks++
		return

	var/list/old_reactions = active_reactions
	active_reactions = list()
	reaction_loop:
		for(var/datum/chemical_reaction/C in src.possible_reactions)
			if (!islist(C.required_reagents)) //This shouldn't happen but when practice meets theory...they beat the shit out of one another I guess
				continue

			if(C.required_temperature != -1)
				if(C.required_temperature < 0) //total_temperature needs to be lower than absolute value of this temp
					if(abs(C.required_temperature) < total_temperature) //Not the right temp.
						continue
				else if(C.required_temperature > total_temperature)
					continue
				//Min / max temp intervals
				if(total_temperature < C.min_temperature)
					continue
				else if(total_temperature > C.max_temperature)
					continue

				// TODO: CONSIDER: reactions should probably occur if temp >= req temp not within bound of it
				// Monkeys: Did this, just put a required_temperature as negative to make the reaction happen below a temp rather than above.

			var/total_matching_reagents = 0
			var/created_volume = src.maximum_volume
			for(var/B in C.required_reagents)
				var/B_required_volume = max(1, C.required_reagents[B])
				var/amount = get_reagent_amount(B)
				if(amount >= B_required_volume) //This will mean you can have < 1 stuff not react. This is fine.
					total_matching_reagents++
					created_volume = min(created_volume, amount * (C.result_amount ? C.result_amount : 1) / B_required_volume)
				else
					break
			if(total_matching_reagents == C.required_reagents.len)
				for (var/inhibitor in C.inhibitors)
					if (src.has_reagent(inhibitor))
						continue reaction_loop

				if(!old_reactions.Find(C))
					var/turf/T = 0
					if(my_atom)
						for(var/mob/living/M in AIviewers(4, get_turf(my_atom)) )	//Fuck you, ghosts
							if(C.mix_phrase)
								boutput(M, "<span style=\"color:blue\">[bicon(my_atom)] [C.mix_phrase]</span>")
						if(C.mix_sound)
							playsound(get_turf(my_atom), C.mix_sound, 80, 1)
						T = get_turf(my_atom.loc)

					// Ideally, we'd like to know the contents of chemical smoke and foam (Convair880).
					if(C.special_log_handling)
						logTheThing("combat", usr, null, "[C.name] chemical reaction [log_reagents(my_atom)] at [T ? "[log_loc(T)]" : "null"].")
					else
						logTheThing("combat", usr, null, "[C.name] chemical reaction at [T ? "[log_loc(T)]" : "null"].")

				if(C.drinkrecipe)
					score_meals++
				if(C.instant)
					if(C.consume_all)
						for(var/B in C.required_reagents)
							src.del_reagent(B)
					else
						for(var/B in C.required_reagents)
							src.remove_reagent(B, C.required_reagents[B] * created_volume / (C.result_amount ? C.result_amount : 1))
					src.add_reagent(C.result, created_volume)
					C.on_reaction(src, created_volume)
					continue
				active_reactions += C

	if(!active_reactions.len)
		if(processing_reactions)
			processing_reactions = 0
			active_reagent_holders -= src
	else if(!processing_reactions)
		processing_reactions = 1
		active_reagent_holders += src
	return 1


datum/reagents/proc/process_reactions()
	defer_reactions = 1
	deferred_reaction_checks = 0
	for(var/datum/chemical_reaction/C in src.active_reactions)
		if (C.result_amount <= 0)
			src.active_reactions -= C
			continue
		var/speed = C.reaction_speed
		for (var/reagent in C.required_reagents)
			var/required_amount = C.required_reagents[reagent] * speed / C.result_amount
			var/amount = get_reagent_amount(reagent)
			if (amount < required_amount)
				speed *= amount / required_amount
		if (speed <= 0) // don't add anything that modifies the speed before this check
			src.active_reactions -= C
			continue

		C.on_reaction(src, speed)
		for (var/reagent in C.required_reagents)
			src.remove_reagent(reagent, C.required_reagents[reagent] * speed / C.result_amount)
		if (C.result)
			src.add_reagent(C.result, speed,, src.total_temperature)

		if(my_atom && my_atom.loc) //We might be inside a thing, let's tell it we updated our reagents.
			my_atom.loc.handle_event("reagent_holder_update")

	defer_reactions = 0
	if (deferred_reaction_checks)
		src.handle_reactions()
	else if (!active_reactions.len && processing_reactions)
		processing_reactions = 0
		active_reagent_holders -= src


datum/reagents/proc/isolate_reagent(var/reagent)
	for(var/current_id in reagent_list)
		if (current_id != reagent)
			del_reagent(current_id)
			update_total()


datum/reagents/proc/del_reagent(var/reagent)
	var/datum/reagent/current_reagent = reagent_list[reagent]

	if (current_reagent)
		current_reagent.on_remove()
		remove_possible_reactions(current_reagent.id) //Experimental structure
		reagent_list.Remove(reagent)
		update_total()
		reagents_changed()
		pool(current_reagent)
		return 0

	src.handle_reactions() // trigger inhibited reactions
	return 1


datum/reagents/proc/update_total()
	total_volume = 0

	for(var/current_id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[current_id]
		if(current_reagent)
			if(current_reagent.volume <= 0)
				del_reagent(current_id)
			else
				total_volume += current_reagent.volume
	return 0


datum/reagents/proc/clear_reagents()
	for(var/current_id in reagent_list)
		del_reagent(current_id)
	return 0


datum/reagents/proc/grenade_effects(var/obj/grenade, var/atom/A)
	for (var/id in src.reagent_list)
		var/datum/reagent/R = src.reagent_list[id]
		R.grenade_effects(grenade, A)


datum/reagents/proc/reaction(var/atom/A, var/method=REAC_TOUCH, var/react_volume)
	if (src.total_volume <= 0)
		return
	if (isobserver(A)) // errrr
		return

	if (!react_volume)
		react_volume = src.total_volume
	var/volume_fraction = react_volume / src.total_volume

	if (ismob(A))
		var/mob/M = A
		M.on_reagent_react(src, method, react_volume)
	switch(method)
		if(REAC_TOUCH)
			var/mob/living/carbon/human/H = A
			if(istype(H))
				if(total_temperature > H.base_body_temp + (H.temp_tolerance * 4) && !H.is_heat_resistant())
					if (chem_helmet_check(H))
						boutput(H, "<span style=\"color:red\">You are scalded by the hot chemicals!</span>")
						H.TakeDamage("head", 0, round(log(total_temperature / 50) * 10), 0, DAMAGE_BURN) // lol this caused brute damage
						H.emote("scream")
						H.bodytemperature += min(max((total_temperature - T0C) - 20, 5),500)
				else if(total_temperature < H.base_body_temp - (H.temp_tolerance * 4) && !H.is_cold_resistant())
					if (chem_helmet_check(H))
						boutput(H, "<span style=\"color:red\">You are frostbitten by the freezing cold chemicals!</span>")
						H.TakeDamage("head", 0, round(log(T0C - total_temperature / 50) * 10), 0, DAMAGE_BURN)
						H.emote("scream")
						H.bodytemperature -= min(max(T0C - total_temperature - 20, 5), 500)

			for(var/current_id in reagent_list)
				var/datum/reagent/current_reagent = reagent_list[current_id]
				// drsingh attempted fix for Cannot read null.volume, but this one makes no sense. should have been protected already
				if(current_reagent != null) // Don't put spawn(0) in the below three lines it breaks foam! - IM
					if(ismob(A) && !isobserver(A))
						current_reagent.reaction_mob(A, REAC_TOUCH, current_reagent.volume*volume_fraction)
					if(isturf(A))
						current_reagent.reaction_turf(A, current_reagent.volume*volume_fraction)
					if(isobj(A))
						// use current_reagent.reaction_obj for stuff that affects all objects
						// and reagent_act for stuff that affects specific objects
						current_reagent.reaction_obj(A, current_reagent.volume*volume_fraction)
						if(A)
							// we want to make sure its still there after the initial reaction
							A.reagent_act(current_reagent.id,current_reagent.volume*volume_fraction)
						if (istype(A, /obj/blob))
							current_reagent.reaction_blob(A, current_reagent.volume*volume_fraction)

		if(REAC_INGEST)
			if(ismob(A) && !isobserver(A))
				if(istype(A,/mob/living/carbon/))
					var/mob/living/carbon/C = A
					if(C.bioHolder)
						if(total_temperature > C.base_body_temp + (C.temp_tolerance * 4) && !C.is_heat_resistant())
							boutput(C, "<span style=\"color:red\">You scald yourself trying to consume the boiling hot substance!</span>")
							C.TakeDamage("chest", 0, 7, 0, DAMAGE_BURN)
							C.bodytemperature += min(max((total_temperature - T0C) - 20, 5),700)
						else if(total_temperature < C.base_body_temp - (C.temp_tolerance * 4) && !C.is_cold_resistant())
							boutput(C, "<span style=\"color:red\">You frostburn yourself trying to consume the freezing cold substance!</span>")
							C.TakeDamage("chest", 0, 7, 0, DAMAGE_BURN)
							C.bodytemperature -= min(max((total_temperature - T0C) - 20, 5),700)

			// These spawn() calls were breaking stuff elsewhere. Since they didn't appear to be necessary and
			// I didn't come across problems in local testing, I've commented them out as an experiment. If you've come
			// here while investigating INGEST-related bugs, feel free to revert my change (Convair880).
			for(var/current_id in reagent_list)
				var/datum/reagent/current_reagent = reagent_list[current_id]
				if(current_reagent)
					if(ismob(A) && !isobserver(A))
						//spawn(0)
							//if (current_reagent) //This is in a spawn. Between our first check and the execution, this may be bad.
						current_reagent.reaction_mob(A, REAC_INGEST, current_reagent.volume*volume_fraction)
					if(isturf(A))
						//spawn(0)
							//if (current_reagent)
						current_reagent.reaction_turf(A, current_reagent.volume*volume_fraction)
					if(isobj(A))
						//spawn(0)
							//if (current_reagent)
						current_reagent.reaction_obj(A, current_reagent.volume*volume_fraction)
	return


datum/reagents/proc/add_reagent(var/reagent, var/amount, var/sdata, var/temp_new=T20C, var/donotreact = 0)
	if(!isnum(amount) || amount <= 0)
		return 1

	var/added_new = 0
	update_total()
	if(total_volume + amount > maximum_volume) //Doesnt fit in. Make it disappear. Shouldnt happen. Will happen.
		amount = (maximum_volume - total_volume)

	var/datum/reagent/current_reagent = reagent_list[reagent]

	if(!current_reagent)
		if (reagents_cache.len <= 0)
			build_reagent_cache()

		current_reagent = reagents_cache[reagent]

		if(current_reagent)
			current_reagent = unpool(current_reagent.type)
			reagent_list[reagent] = current_reagent
			current_reagent.holder = src
			current_reagent.volume = 0
			current_reagent.data = sdata
			added_new = 1
		else
			return 0

	var/tmp/new_amount = (current_reagent.volume + amount)
	current_reagent.volume = new_amount

	if(!current_reagent.data)
		current_reagent.data = sdata

	src.last_temp = src.total_temperature
	src.total_temperature = (src.total_temperature * src.total_volume + temp_new*new_amount) / (src.total_volume + new_amount)
	update_total()

	if(!donotreact)
		temperature_react()

	reagents_changed(1)

	if(added_new)
		append_possible_reactions(current_reagent.id) //Experimental reaction possibilities
		current_reagent.on_add()
		if (!donotreact)
			src.handle_reactions()
	return 1


datum/reagents/proc/remove_reagent(var/reagent, var/amount)
	if(!isnum(amount))
		return 1

	var/datum/reagent/current_reagent = reagent_list[reagent]

	if(current_reagent)
		current_reagent.volume -= amount
		if(current_reagent.volume <= 0)
			del_reagent(reagent)

		update_total()
		reagents_changed()

	return 1

datum/reagents/proc/has_reagent(var/reagent, var/amount=0)
	// I removed a check if reagent_list existed here in the interest of performance
	// if this happens again try to figure out why the fuck reagent_list would go null
	var/datum/reagent/current_reagent = reagent_list[reagent]
	return current_reagent && current_reagent.volume >= amount


datum/reagents/proc/get_reagent(var/reagent_id)
	return reagent_list[reagent_id]


datum/reagents/proc/get_reagent_amount(var/reagent)
	var/datum/reagent/current_reagent = reagent_list[reagent]
	return current_reagent ? current_reagent.volume : 0


datum/reagents/proc/get_dispersal()
	if (!total_volume)
		return 0
	var/dispersal = 9999
	for (var/id in reagent_list)
		var/datum/reagent/R = reagent_list[id]
		if (R.dispersal < dispersal)
			dispersal = R.dispersal
	return dispersal


// redirect my_atom.on_reagent_change() through this function
datum/reagents/proc/reagents_changed(var/add = 0) // add will be 1 if reagents were just added
	if (my_atom)
		my_atom.on_reagent_change(add)
	desc = null			// mark the description as needing refresh

datum/reagents/proc/is_full() // li'l tiny helper thing vOv
	if (src.total_volume >= src.maximum_volume)
		return 1
	else
		return 0

/////////////////////////////////////////////////////////////////
// procs for description and color of this collection of reagents
// returns text description of reagent(s)
// plus exact text of reagents if using correct equipment
datum/reagents/proc/get_description(mob/user, rc_flags=0)
	if(rc_flags == 0)	// Report nothing about the reagents in this case
		return null

	if(reagent_list.len)
		. += get_inexact_description(rc_flags)
		if(rc_flags & RC_SPECTRO)
			. += get_exact_description(user)

	else
		. += "<span style=\"color:blue\">Nothing in it.</span>"
	return


datum/reagents/proc/get_exact_description(mob/user)

	if(!reagent_list.len)
		return

	// check to see if user wearing the spectoscope glasses
	// or is a chem-borg
	// if so give exact readout on what reagents are present
	var/spectro = 0
	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		if (istype(H.glasses, /obj/item/clothing/glasses/spectro))
			spectro = 1
		else if (H.eye_istype(/obj/item/organ/eye/cyber/spectro))
			spectro = 1
	else if (isrobot(user))
		var/mob/living/silicon/robot/R = user
		if (istype(R.module, /obj/item/robot_module/chemistry))
			spectro = 1

	if (spectro)
		. += "<br><span style=\"color:red\">Spectroscopic analysis:</span>"

		for(var/current_id in reagent_list)
			var/datum/reagent/current_reagent = reagent_list[current_id]
			. += "<br><span style=\"color:red\">[current_reagent.volume] units of [current_reagent.name]</span>"
	return


datum/reagents/proc/get_inexact_description(var/rc_flags=0)
	if(desc)
		return desc
	if(rc_flags == 0)
		return null

	// rebuild description
	var/full_text = get_fullness(total_volume / maximum_volume * 100)

	if(full_text == "empty")
		if(rc_flags & (RC_SCALE | RC_VISIBLE | RC_FULLNESS) )
			desc = "<span style=\"color:blue\">It is empty.</span>"
		return desc

	var/datum/color/c = get_average_color()

	//desc+= "([c.r],[c.g],[c.b];[c.a])"

	var/nearest_color_text = get_nearest_color(c)
	var/opaque_text = get_opaqueness(c.a)
	var/state_text = get_state_description()

	if(state_text == "solid")	// if only have solids present, don't include opacity text
		opaque_text = null

	if(opaque_text)
		opaque_text += ", "

	var/t = "[opaque_text][nearest_color_text]"

	if(rc_flags & RC_VISIBLE)
		if(rc_flags & RC_SCALE)
			desc += "<span style=\"color:blue\">It contains [total_volume] units of \a [t]-colored [state_text].</span>"
		else
			desc += "<span style=\"color:blue\">It is [full_text] of \a [t]-colored [state_text].</span>"
	else
		if(rc_flags & RC_SCALE)
			desc += "<span style=\"color:blue\">It contains [total_volume] units.</span>"
		else
			if(rc_flags & RC_FULLNESS)
				desc += "<span style=\"color:blue\">It is [full_text].</span>"
	return desc


// returns the average color of the reagents
// taking into account concentration and transparency
datum/reagents/proc/get_average_color()
	var/datum/color/average = new(0,0,0,0)
	var/total_weight = 0

	for(var/id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[id]

		// weigh contribution of each reagent to the average color by amount present and it's transparency
		var/weight = current_reagent.volume * current_reagent.transparency / 255.0
		total_weight += weight

		average.r += weight * current_reagent.fluid_r
		average.g += weight * current_reagent.fluid_g
		average.b += weight * current_reagent.fluid_b
		average.a += weight * current_reagent.transparency

	// now divide by total weight to get average color
	if(total_weight > 0)
		average.r /= total_weight
		average.g /= total_weight
		average.b /= total_weight
		average.a /= total_weight
	return average


datum/reagents/proc/get_average_rgb()
	var/datum/color/average = get_average_color()
	return rgb(average.r, average.g, average.b)


//returns whether reagents are solid, liquid, gas, or mixture
datum/reagents/proc/get_state_description()
	var/has_solid = 0
	var/has_liquid = 0
	var/has_gas = 0

	for(var/id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[id]
		if(current_reagent.is_gas())
			has_gas = 1
		else if(current_reagent.is_liquid())
			has_liquid = 1
		else
			has_solid = 1

	if( (has_liquid+has_solid+has_gas)>1 )
		return "mixture"
	if(has_liquid)
		return "liquid"
	if(has_solid)
		return "solid"
	return "gas"


datum/reagents/proc/physical_shock(var/force)
	for (var/id in reagent_list)
		var/datum/reagent/current_reagent = reagent_list[id]
		current_reagent.physical_shock(force)


datum/reagents/proc/move_trigger(var/mob/M, kindof)
	var/shock = 0
	switch (kindof)
		if ("run")
			shock = rand(5, 12)
		if ("walk", "swap")
			if (prob(5))
				shock = 1
		if ("bump")
			shock = rand(3, 8)
		if ("pushdown")
			shock = rand(8, 16)
	if (shock)
		physical_shock(shock)

///////////////////////////////////////////////////////////////////////////////////


// Convenience proc to create a reagents holder for an atom
// Max vol is maximum volume of holder
atom/proc/create_reagents(var/max_vol)
	reagents = new/datum/reagents(max_vol)
	reagents.my_atom = src
