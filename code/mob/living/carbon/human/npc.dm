// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/mob/living/carbon/human/npc
	name = "human"
	is_npc = 1
	ai_attacknpc = 0
	New()
		..()
		spawn(0)
			src.mind = new(src)
			if (src.name == "human")
				randomize_look(src, 1, 1, 1, 1, 1, 0) // change gender/bloodtype/age/name/underwear, keep bioeffects
		spawn(10)
			set_clothing_icon_dirty()
		spawn(20)
			ai_init()

/mob/living/carbon/human/npc/assistant
	ai_aggressive = 1
	var/just_got_griefed = 0
	New()
		..()
		spawn(0)
			JobEquipSpawned("Staff Assistant")
	ai_findtarget_new()
		if((world.timeofday - ai_threatened) < 600)
			..()
	proc
		cry_grief(mob/M)
			if(!M)
				return
			src.target = M
			src.ai_state = 2
			src.ai_threatened = world.timeofday
			var/tmp/target_name = M.name
			//var/area/current_loc = get_area(src)
			//var/tmp/loc_name = lowertext(current_loc.name) // removing this because nobody believes it
			var/tmp/complaint = pick("[target_name] [pick("is killing","is griefing","is trying to kill","just fucking tried to kill")] me",\
			"getting griefed, help",\
			"security!!!",\
			"[target_name] just fucking attacked me",\
			"SOMEONE [prob(40) ? "FUCKING " : ""]ARREST [uppertext(target_name)]",\
			"need help",\
			"[pick("HLEP","HELP")] ME [uppertext(target_name)] IS [prob(40) ? "FUCKING " : ""]KILLING ME")
			if(prob(60))
				complaint = uppertext(complaint)
			var/tmp/max_excl = rand(-2,4)
			for(var/i = 0, i < max_excl, i++)
				complaint += "!"
			src.say(";[complaint]")
	attack_hand(mob/M)
		..()
		if(!just_got_griefed && (M.a_intent in list(INTENT_HARM,INTENT_DISARM,INTENT_GRAB)))
			just_got_griefed = 1
			spawn(rand(10,30))
				src.cry_grief(M)
				just_got_griefed = 0
	attackby(obj/item/W, mob/M)
		var/tmp/oldbloss = get_brute_damage()
		var/tmp/oldfloss = get_burn_damage()
		..()
		var/tmp/damage = ((get_brute_damage() - oldbloss) + (get_burn_damage() - oldfloss))
		if((damage > 0) || W.force)
			if(!just_got_griefed)
				just_got_griefed = 1
				spawn(rand(10,30))
					src.cry_grief(M)
					just_got_griefed = 0



//// rest in peace NPC classic-retards, you were shit ////


/mob/living/carbon/human/npc/syndicate
	ai_aggressive = 1
	New()
		..()
		spawn(0)
			if(ticker && ticker.mode && istype(ticker.mode, /datum/game_mode/nuclear))
				src.real_name = "[syndicate_name()] Operative #[ticker.mode:agent_number]"
				ticker.mode:agent_number++
			else
				src.real_name = "Syndicate Agent"
			JobEquipSpawned("Syndicate")

// npc ai procs

//NOTE TO SELF: BYONDS TIMING FUNCTIONS ARE INACCURATE AS FUCK
//ADD HELP INTEND.

//0 = Pasive, 1 = Getting angry, 2 = Attacking , 3 = Helping, 4 = Idle , 5 = Fleeing(??)

/mob/living/carbon/human/proc/ai_init()
	ai_active = 1
	ai_laststep = 0
	ai_state = 0
	ai_target = null
	ai_threatened = 0
	ai_movedelay = 3
	ai_attacked = 0

/mob/living/carbon/human/proc/ai_stop()
	ai_active = 0
	ai_laststep = 0
	ai_state = 0
	ai_target = null
	ai_threatened = 0
	ai_movedelay = 3
	ai_attacked = 0

/mob/living/carbon/human/proc/ai_process()
	if(!ai_active) return
	if(world.time < ai_lastaction + ai_actiondelay) return

	var/action_delay = 0
	resting = 0
	if(hud) hud.update_resting()

	if (stat == 2)
		ai_active = 0
		ai_target = null
		walk_towards(src, null)
		return

	//Moving this up because apparently beds were tripping the AI up.
	if(src.buckled && !src.handcuffed)
		src.buckled.attack_hand(src)
		if(src.buckled) //WE'RE STUCKED :C
			return

		action_delay += 5

	if(ai_incapacitated())
		action_delay = 10
		ai_lastaction = world.time
		walk_towards(src, null)
		return

//			var/turf/T = get_turf(src)
//			if((T.poison > 100000.0 || T.firelevel || T.oxygen < 560000 || T.co2 > 7500.0) && !istype(get_turf(src), /turf/space) )
//				ai_avoid(T)
//			else ai_move()



	if(istype(src.loc, /obj/storage/closet) || istype(src.loc, /obj/machinery/disposal))
		ai_freeself()
		action_delay += 5



	if(!src.restrained() && !src.lying && !src.buckled)
		ai_action()
	if(ai_busy && !src.handcuffed)
		ai_busy = 0
	if(src.handcuffed)
		ai_target = null
		ai_state = 0
		if(src.canmove && !ai_busy)
			ai_busy = 1
			src.visible_message("<span style=\"color:red\"><B>[src] attempts to remove the handcuffs!</B></span>")
			spawn(1200)
				ai_busy = 0
				if(src.handcuffed && !ai_incapacitated())
					src.visible_message("<span style=\"color:red\"><B>[src] manages to remove the handcuffs!</B></span>")
					src.handcuffed:set_loc(src.loc)
					src.handcuffed = null
					src.set_clothing_icon_dirty()
	ai_move()

	if(ai_target)
		spawn(1)
			ai_move()
		action_delay += 10
	else
		action_delay += 40

	ai_lastaction = world.time
	ai_actiondelay = action_delay


/*
/mob/living/carbon/human/proc/ai_findtarget()
	var/tempmob
	for (var/mob/living/carbon/M in view(7,src))
		if (M.stat > 0 || !M.client || M == src || M.is_npc) continue
		if (!tempmob) tempmob = M
		for(var/mob/living/carbon/human/L in oview(7,src))
			if (L.ai_target == tempmob && prob(50)) continue
		if (M.health < tempmob:health) tempmob = M
	if(tempmob)
		ai_target = tempmob
		ai_state = 1
		ai_threatened = world.timeofday
*/

/mob/living/carbon/human/proc/ai_findtarget_new()
	//Priority-based target finding
	var/mob/T
	var/lastRating = -INFINITY
	for (var/mob/living/carbon/M in view(7,src))
		//Any reason we do not want to take this target into account AT ALL?
		if((M == src && !ai_suicidal) || M.stat == 2 || (M.is_npc && !ai_attacknpc)) continue //Let's not fight ourselves (unless we're real crazy) or a dead person... or NPCs, unless we're allowed to.

		var/rating = 100 //Base rating


		//Why do we WANT to go after this jerk?
		//if(!T) rating += 10 //We don't have a target, this one will do
		if(M.client) rating += 20 //We'd rather go after actual non-braindead players
		if(src.lastattacker == M && M != src) rating += 10 //Hey, you're a jerk! (but I'm not a jerk)


		//Why do we NOT want to go after this jerk
		if(M.stat == 1) rating-=8 //This one's unconscious
		for(var/mob/living/carbon/human/H in oview(7,src))
			if(H.ai_target == M) rating -= 4 //I'd rather fight my own fight
		if(M.is_npc) rating -= 5 //I don't want to go after my fellow NPCs unless there is no other option
		if(M == src) rating -= 14 //I don't want to go after myself
		if(M in ai_target_old) rating -= 15 //I definitely don't want to go after my old target; chances are I still can't get to them.


		//Any reasons that could go either way when dealing with this bum?
		rating += 5*(M.health/M.max_health) //I'd rather fight things with a lot of health because I AIN'T NO COWARD!

		rating = max(rating,0) //Clamp the rating

		//Do we like this target better than the last one?
		if(rating > lastRating || (rating == lastRating && prob(50)))
			T = M
			lastRating = rating
	//Did we find anyone to fight?
	if(T)
		ai_target = T
		ai_state = 1
		ai_threatened = world.timeofday
	else
		ai_state = 0

/mob/living/carbon/human/proc/ai_action()
	switch(ai_state)
		if(0) //Life is good.

			src.a_intent = src.ai_default_intent

			ai_pickupweapon()
			ai_obstacle(1)
			ai_openclosets()
			//ai_findtarget()
			if (ai_calm_down && ai_aggressive && prob(20))
				ai_aggressive = 0
			if (ai_aggressive)
				ai_findtarget_new()
		if(1)	//WHATS THAT?

			if (get_dist(src,ai_target) > 6)
				ai_target = null
				ai_state = 0
				ai_threatened = 0
				return

			if ( (world.timeofday - ai_threatened) > 20 ) //Oh, it is on now! >:C
				ai_state = 2
				return

		if(2)	//Gonna kick your ass.

			src.a_intent = INTENT_HARM

			var/mob/living/carbon/target = ai_target

			if(!target || (ai_target == src && !ai_suicidal))
				ai_frustration = 0
				ai_target = null
				ai_state = 0
				return

			var/valid = ai_validpath()
			var/distance = get_dist(src,ai_target)

			ai_obstacle(0)
			ai_openclosets()

			if(ai_target == src && prob(10)) //If we're fighting ourselves we wanna look for other targets periodically
				src.ai_findtarget_new()

			if (ai_frustration >= 100)
				ai_target_old += ai_target //Can't get to this dork
				ai_frustration = 0
				ai_target = null
				ai_state = 0
				walk_towards(src,null)

			if(target.stat == 2 || distance > 7 || (!src.see_invisible && target.invisibility) || (target.stat == 1 && prob(25)))
				ai_target = null
				ai_state = 0
				if(src.get_brain_damage() >= 60)
					src.visible_message("<b>[src]</b> [pick("stares off into space momentarily.","loses track of what they were doing.")]")
				return

			if((target.weakened || target.stunned || target.paralysis) && istype(target.wear_mask, /obj/item/clothing/mask) && distance <= 1 && prob(10) && !ai_incapacitated())
				var/mask = target.wear_mask
				src.visible_message("<span style=\"color:red\"><b>[src] is trying to take off [mask] from [ai_target]'s head!</b></span>")
				target.u_equip(mask)
				if (mask)
					mask:set_loc(target:loc)
					mask:dropped(target)
					mask:layer = initial(mask:layer)

			else if ((target.weakened || target.stunned || target.paralysis) && target:wear_suit && distance <= 1 && prob(5) && !src.r_hand && !ai_incapacitated())
				var/suit = target:wear_suit
				src.visible_message("<span style=\"color:red\"><b>[src] is trying to take off [suit] from [ai_target]'s body!</b></span>")
				target.u_equip(suit)
				if (suit)
					suit:set_loc(target:loc)
					suit:dropped(target)
					suit:layer = initial(suit:layer)

			if(prob(75) && distance > 1 && (world.timeofday - ai_attacked) > 100 && ai_validpath() && (istype(src.r_hand,/obj/item/gun) && src.r_hand:canshoot()))
				//I can attack someone! =D
				ai_target_old.Cut()
				var/obj/item/gun/W = src.r_hand
				W.shoot(get_turf(target), get_turf(src), src, 0, 0)
				if(src.get_brain_damage() >= 60 && prob(10))
					switch(pick(1,2))
						if(1)
							hearers(src) << "<B>[src.name]</B> makes machine-gun noises with \his mouth."
						if(2)
							src.say(pick("BANG!", "POW!", "Eat lead, [target.name]!", "Suck it down, [target.name]!"))

			if((prob(33) || ai_throw) && distance > 1 && ai_validpath() && src.r_hand && !(istype(src.r_hand,/obj/item/gun) && src.r_hand:canshoot()))
				//I can attack someone! =D
				ai_target_old.Cut()
				var/obj/item/temp = src.r_hand
				temp.set_loc(src.loc)
				src.u_equip(temp)
				src.visible_message("<span style=\"color:red\">[src] throws [temp].</span>")
				temp.throw_at(target, 7, 1)

			if(distance <= 1 && (world.timeofday - ai_attacked) > 100 && !ai_incapacitated() && ai_meleecheck())
				//I can attack someone! =D
				ai_target_old.Cut()
				if(src.get_brain_damage() >= 60 && prob(10)) //Combat Trash Talk
					src.say(pick("Fuck you, [target.name]!", "You're [prob(10) ? "fucking " : ""]dead, [target.name]!", "I will kill you, [target.name]!!"))
				if(!src.r_hand)
					// need to restore this at some point i guess, the "monkeys bite" code is commented out right now
					//if(src.get_brain_damage() >= 60 && prob(25))
					//	target.attack_paw(src) // retards bite
					//else
					target.attack_hand(src) //We're a human!
				else
					if(istype(src.r_hand, /obj/item/gun) && !src.r_hand:canshoot())
						src.a_intent = INTENT_HELP
					src.r_hand:attack(target, src, ran_zone("chest")) //With a weapon ...
					src.a_intent = INTENT_HARM

			ai_pickupweapon()

			if((src.get_brain_damage() >= 60) && (distance == 3) && (world.timeofday - ai_pounced) > 180 && ai_validpath())
				if(valid)
					ai_pounced = world.timeofday
					src.visible_message("<span style=\"color:red\">[src] lunges at [ai_target]!</span>")
					if(ai_target:weakened < 2) ai_target:weakened += 2
					spawn(0)
						step_towards(src,ai_target)
						step_towards(src,ai_target)

/mob/living/carbon/human/proc/ai_move()
	if(ai_incapacitated() || !ai_canmove() || ai_busy)
		walk_towards(src, null)
		return
	if( ai_state == 0 && ai_canmove() ) step_rand(src)
	if( ai_state == 2 && ai_canmove() )
		if(!ai_validpath() && get_dist(src,ai_target) <= 1)
			dir = get_step_towards(src,ai_target)
			ai_obstacle() //Remove.
		else
			//step_towards(src, ai_target)
			var/dist = get_dist(src,ai_target)
			if(ai_target && dist > 2) //We're in fast approach mode
				walk_towards(src,ai_target, ai_movedelay)
			else if (dist > 1)
				walk_towards(src, null)
				step_towards(src, ai_target) //Take a step and hit the shite (but only if you won't push them out of the way by doing so)

/mob/living/carbon/human/proc/ai_pickupweapon()

	if(istype(src.r_hand,/obj/item/gun) && src.r_hand:canshoot())
		return

	if(istype(src.r_hand,/obj/item/gun/kinetic) && !src.r_hand:canshoot())
		var/obj/item/gun/kinetic/GN = src.r_hand
		for(var/obj/item/ammo/bullets/BB in src.contents)
			src.l_hand = BB
			GN:attackby(BB,src)
			src.u_equip(BB)
			src.l_hand = null
			if (BB)
				BB.set_loc(src.loc)
				BB.dropped(src)
				BB.layer = initial(BB.layer)
			return
		if(!GN:canshoot())
			src.drop_item()
			if(src.w_uniform && !src.belt)
				GN:set_loc(src)
				src.belt = GN
				GN:layer = HUD_LAYER
			else if(src.back && istype(src.back,/obj/item/storage/backpack))
				var/obj/item/storage/backpack/B = src.back
				if(B.contents.len < 7)
					B.attackby(GN,src)

	if(istype(src.r_hand, /obj/item/gun/energy) && !src.r_hand:canshoot())
		var/obj/item/gun/energy/GN = src.r_hand
		src.drop_item()
		if(src.w_uniform && !src.belt)
			GN:set_loc(src)
			src.belt = GN
			GN:layer = HUD_LAYER
		else if(src.back && istype(src.back,/obj/item/storage/backpack))
			var/obj/item/storage/backpack/B = src.back
			if(B.contents.len < 7)
				B.attackby(GN,src)

	var/obj/item/pickup

	for(var/obj/item/G in src.contents)
		if((istype(G,/obj/item/gun) && G:canshoot()) && src.r_hand != G)
			pickup = G
			src.u_equip(G)
			break

	if(!pickup)
		for (var/obj/item/G in view(1,src))
			if(!istype(G.loc, /turf) || G.anchored) continue
			if((istype(G,/obj/item/gun) && G:canshoot()))
				pickup = G
				break
			else if(!src.r_hand && !pickup && G.force > 3)
				pickup = G
			else if(!src.r_hand && pickup && G.force > 3)
				if(G.force > pickup.force) pickup = G
			else if(src.r_hand && !pickup && G.force > 3)
				if(src:r_hand:force < G.force) pickup = G
			else if(src.r_hand && pickup && G.force > 3)
				if(pickup.force < G.force) pickup = G

	if(src.r_hand && pickup)
		var/RHITM = src.r_hand
		src.u_equip(RHITM)
		RHITM:set_loc(get_turf(src))
		RHITM:dropped(src)
		RHITM:layer = initial(RHITM:layer)

	if(pickup && !src.r_hand)
		pickup.set_loc(src)
		src.r_hand = pickup

	src.set_clothing_icon_dirty()


/mob/living/carbon/human/proc/ai_avoid(var/turf/T)
	return
/*
	if(ai_incapacitated()) return
	var/turf/tempturf = T
	var/tempdir = null
	var/turf/testturf = null

	//Extremely simple. EXTREMELY.

	if(T.firelevel)
		for (var/dir1 in list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST))
			testturf = get_step(T,dir1)
			if (testturf.firelevel < tempturf.firelevel)
				tempdir = dir1
				tempturf = testturf
	else if(T.poison > 100000.0)
		for (var/dir1 in list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST))
			testturf = get_step(T,dir1)
			if (testturf.poison < tempturf.poison)
				tempdir = dir1
				tempturf = testturf
	else if(T.co2 > 7500.0)
		for (var/dir1 in list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST))
			testturf = get_step(T,dir1)
			if (testturf.co2 < tempturf.co2)
				tempdir = dir1
				tempturf = testturf
	else if (T.oxygen < 560000)
		for (var/dir1 in list(NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST))
			testturf = get_step(T,dir1)
			if (testturf.oxygen > tempturf.oxygen)
				tempdir = dir1
				tempturf = testturf

	step(src,tempdir)
*/

/mob/living/carbon/human/proc/ai_canmove()
	if(!istype(src.loc,/turf)) return 0
	if(src.restrained())
		for(var/mob/M in range(src, 1))
			if (((M.pulling == src && (!( M.restrained() ) && M.stat == 0)) || locate(/obj/item/grab, src.grabbed_by.len)))
				return 0
	var/speed = (5 * ai_movedelay)
	if (!ai_laststep) ai_laststep = (world.timeofday - 5)
	if ((world.timeofday - ai_laststep) >= speed) return 1
	else return 0

/mob/living/carbon/human/proc/ai_incapacitated()
	if(stat || stunned || paralysis || !sight_check(1) || weakened) return 1
	else return 0

/mob/living/carbon/human/proc/ai_validpath()

	var/list/L = new/list()

	var/mob/living/target = ai_target

	if(!istype(src.loc,/turf)) return 0

	if(!target) return 0 //WTF

	L = getline(src,target)

	for (var/turf/T in L)
		if (T.density)
			ai_frustration += 3
			return 0
		for (var/obj/D in T)
			if (D.density && !istype(D, /obj/storage/closet) && D.anchored)
				ai_frustration += 3
				return 0
			else if (istype(D, /obj/storage/closet))
				var/obj/storage/closet/closet = D
				if (closet.open == 0)
					return 0

	return 1

/mob/living/carbon/human/proc/ai_meleecheck() //Simple right now.
	var/targetturf = get_turf(ai_target)
	var/myturf = get_turf(src)

	if(!istype(src.loc,/turf)) return 0

	if(locate(/obj/machinery/door/window) in myturf)
		for (var/obj/machinery/door/window/W in myturf)
			if(!W.CheckExit(src,targetturf)) return 0

	if(locate(/obj/machinery/door/window) in targetturf)
		for (var/obj/machinery/door/window/W in targetturf)
			if(!W.CanPass(src,targetturf)) return 0

	return 1



/mob/living/carbon/human/proc/ai_freeself()
	if(istype(src.loc, /obj/machinery/disposal))
		var/obj/machinery/disposal/C = src.loc
		src.set_loc(C.loc)
		src.weakened += 2

	if(istype(src.loc, /obj/storage/closet))
		var/obj/storage/closet/C = src.loc
		if (C.open)
			C.close()
			C.open()
		else
			C.open()

/mob/living/carbon/human/proc/ai_obstacle(var/doorsonly)

	var/acted = 0

	if(ai_incapacitated()) return

	if(src.r_hand && !doorsonly) //So they dont smash windows while wandering around.

		if((locate(/obj/window) in get_step(src,dir))  && !acted)
			var/obj/window/W = (locate(/obj/window) in get_step(src,dir))
			W.attackby(src.r_hand, src)
			acted = 1
		else if((locate(/obj/window) in get_turf(src.loc))  && !acted)
			var/obj/window/W = (locate(/obj/window) in get_turf(src.loc))
			W.attackby(src.r_hand, src)
			acted = 1

		if((locate(/obj/grille) in get_step(src,dir))  && !acted)
			var/obj/grille/G = (locate(/obj/grille) in get_step(src,dir))
			if(!G.ruined)
				G.attackby(src.r_hand, src)
				acted = 1

	if((locate(/obj/machinery/door) in get_step(src,dir)))
		var/obj/machinery/door/W = (locate(/obj/machinery/door) in get_step(src,dir))
		if(W.density) W.attack_hand(src)
	else if((locate(/obj/machinery/door) in get_turf(src.loc)))
		var/obj/machinery/door/W = (locate(/obj/machinery/door) in get_turf(src.loc))
		if(W.density) W.attack_hand(src)

/mob/living/carbon/human/proc/ai_openclosets()
	if (ai_incapacitated())
		return
	for (var/obj/storage/closet/C in view(1,src))
		if (!C.open)
			C.open()
	for (var/obj/storage/secure/closet/S in view(1,src))
		if (!S.open && !S.locked)
			S.open()

