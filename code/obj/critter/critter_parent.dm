// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// p much straight up copied from secbot code =I

/obj/critter/
	name = "critter"
	desc = "you shouldnt be able to see this"
	icon = 'icons/misc/critter.dmi'
	var/living_state = null
	var/dead_state = null
	layer = 5.0
	density = 1
	anchored = 0
	flags = FPRINT | CONDUCT | USEDELAY
	var/is_template = 0
	var/alive = 1
	var/health = 10

	// "sleeping" is a special state that sleeps for 10 cycles, wakes up, sleeps again unless someone is found
	// "hibernating" is another special state where it does nothing unless explicitly woken up
	var/task = "thinking"

	var/list/followed_path = null
	var/followed_path_retries = 0
	var/followed_path_retry_target = null
	var/follow_path_blindly = 0

	var/report_state = 0
	var/quality_name = null
	var/mobile = 1
	var/aggressive = 0
	var/defensive = 0
	var/wanderer = 1
	var/opensdoors = 0
	var/frustration = 0
	var/last_found = null
	var/target = null
	var/oldtarget_name = null
	var/target_lastloc = null
	var/atkcarbon = 0
	var/atksilicon = 0
	var/atcritter = 0
	var/atkintangible = 0
	var/attack = 0
	var/attacking = 0
	var/steps = 0
	var/firevuln = 1
	var/brutevuln = 1
	var/miscvuln = 0.2
	var/attack_range = 1 // how many tiles away it will attack from
	var/seekrange = 7 // how many tiles away it will look for a target
	var/list/friends = list() // used for tracking hydro-grown monsters's creator
	var/attacker = null // used for defensive tracking
	var/angertext = "charges at" // comes between critter name and target name
	var/pet_text = "pets"
	var/death_text = "%src% dies!"
	var/hitsound = null
	var/flying = 0
	//flags = OPENCONTAINER
	var/sleeping = 0 //countdown, when hits 0 does a wake check
	var/sleep_check = 10 //countdown, when hits 0 does a sleep check
	var/hibernate_check = 2
	var/sleeping_icon_state = null
	var/mob/living/wrangler = null

	var/butcherable = 0
	var/meat_type = /obj/item/reagent_containers/food/snacks/ingredient/meat/mysterymeat
	var/name_the_meat = 1

	var/generic = 1 // if yes, critter can be randomized a bit
	var/max_quality = 100
	var/min_quality = -100

	var/can_revive = 1 // resurrectable with strange reagent

	var/skinresult = null //type path of hide/leather item from skinning
	var/max_skins = 1	  //How many skins you can get at most from this critter. It's 1 to the max amound defined here. random.
	var/muted = 0 // shut UP

	var/chases_food = 0
	var/health_gain_from_food = 0
	var/obj/item/reagent_containers/food/snacks/food_target = null
	var/eat_text = "nibbles at"
	var/feed_text = null

	var/area/registered_area = null //the area this critter is registered in

	proc/tokenized_message(var/message, var/target)
		if (!message || !length(message))
			return
		var/msg = replacetext(message, "%src%", "<b>[src]</b>")
		msg = replacetext(msg, "%target%", "[target]")
		src.visible_message("<span style=\"color:red\">[msg]</span>")

	proc/report_spawn()
		if (!report_state)
			report_state = 1
			if (src in gauntlet_controller.gauntlet)
				gauntlet_controller.increaseCritters(src)
			if (src in colosseum_controller.colosseum)
				colosseum_controller.increaseCritters(src)

	proc/report_death()
		if (report_state == 1)
			report_state = 0
			if (src in gauntlet_controller.gauntlet)
				gauntlet_controller.decreaseCritters(src)
			if (src in colosseum_controller.colosseum)
				colosseum_controller.decreaseCritters(src)

	serialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		..()
		F["[path].aggressive"] << src.aggressive
		F["[path].atkcarbon"] << src.atkcarbon
		F["[path].atksilicon"] << src.atksilicon
		F["[path].health"] << src.health
		F["[path].opensdoors"] << src.opensdoors
		F["[path].wanderer"] << src.wanderer
		F["[path].mobile"] << src.mobile
		F["[path].brutevuln"] << src.brutevuln
		F["[path].firevuln"] << src.firevuln

	deserialize(var/savefile/F, var/path, var/datum/sandbox/sandbox)
		. = ..()
		F["[path].aggressive"] >> src.aggressive
		F["[path].atkcarbon"] >> src.atkcarbon
		F["[path].atksilicon"] >> src.atksilicon
		F["[path].health"] >> src.health
		F["[path].opensdoors"] >> src.opensdoors
		F["[path].wanderer"] >> src.wanderer
		F["[path].mobile"] >> src.mobile
		F["[path].brutevuln"] >> src.brutevuln
		F["[path].firevuln"] >> src.firevuln

	clone()
		var/obj/critter/C = ..()
		C.mobile = mobile
		C.aggressive = aggressive
		C.defensive = defensive
		C.atkcarbon = atkcarbon
		C.atksilicon = atksilicon
		C.health = health
		C.wanderer = wanderer
		C.brutevuln = brutevuln
		C.firevuln = firevuln
		return C

	proc/wake_from_hibernation()
		if(task != "hibernating") return
		//DEBUG_MESSAGE("[src] woke from hibernation at [showCoords(src.x, src.y, src.z)] in [registered_area ? registered_area.name : "nowhere"] due to [usr ? usr : "some mysterious fucking reason"]")
		//Ok, now we look to see if we should get murdlin'
		task = "sleeping"
		hibernate_check = 20 //20 sleep_checks
		do_wake_check(1)

		if(registered_area)
			registered_area.registered_critters -= src
			registered_area = null

		anchored = initial(anchored)
		//critters |= src //Resume processing this critter


	proc/hibernate()
		registered_area = get_area(src)
		hibernate_check = 20 //Reset this counter in case of failure
		if(registered_area)
			task = "hibernating"
			registered_area.registered_critters |= src
			anchored = 1
			//DEBUG_MESSAGE("[src] started hibernating at [showCoords(src.x, src.y, src.z)] in [registered_area ? registered_area.name : "nowhere"].")
			//critters -= src //Stop processing this critter


	HasProximity(atom/movable/AM as mob|obj)
		if(task == "hibernating" && istype(AM, /mob))
			var/mob/M = AM
			if(M.client) wake_from_hibernation()

		..()

	set_loc(var/atom/newloc)
		..()
		wake_from_hibernation() //Critters hibernate lightly enough to wake up when moved

	proc/on_revive()
		return

	proc/on_sleep()

	proc/on_wake()
		var/area/A = get_area(src)
		if(A) A.wake_critters() //HLEP!

	proc/on_grump()

	attackby(obj/item/W as obj, mob/living/user as mob)
		..()
		if (!src.alive)
			if (src.skinresult && max_skins)
				if (istype(W, /obj/item/circular_saw) || istype(W, /obj/item/kitchen/utensil/knife) || istype(W, /obj/item/scalpel) || istype(W, /obj/item/raw_material/shard) || istype(W, /obj/item/sword) || istype(W, /obj/item/saw) || istype(W, /obj/item/wirecutters))

					for(var/i, i<rand(1, max_skins), i++)
						new src.skinresult (src.loc)

					src.skinresult = null

					user.visible_message("<span style=\"color:red\">[user] skins [src].</span>","You skin [src].")

			if (src.butcherable && (istype(W, /obj/item/kitchen/utensil/knife) || istype(W, /obj/item/knife_butcher)))
				user.visible_message("<span style=\"color:red\">[user] butchers [src].[src.butcherable == 2 ? "<b>WHAT A MONSTER</b>" : null]","You butcher [src].</span>")

				var/i = rand(2,4)
				var/transfer = src.reagents.total_volume / i

				while (i-- > 0)
					var/obj/item/reagent_containers/food/newmeat = new meat_type
					newmeat.set_loc(src.loc)
					src.reagents.trans_to(newmeat, transfer)
					if (name_the_meat)
						newmeat.name = "[src.name] meat"
						newmeat.real_name = newmeat.name
				qdel (src)
				return
			..()
			return

		if (src.health_gain_from_food && (istype(W, /obj/item/reagent_containers/food/snacks) || istype(W, /obj/item/seed)))
			user.visible_message("<b>[user]</b> feeds [W] to [src]!","You feed [W] to [src].")
			if (src.feed_text)
				src.visible_message("[src] [src.feed_text]")
			src.health += src.health_gain_from_food
			qdel(W)
			return

		var/attack_force = 0
		var/damage_type = "brute"
		if (istype(W, /obj/item/artifact/melee_weapon))
			var/datum/artifact/melee/ME = W.artifact
			attack_force = ME.dmg_amount
			damage_type = ME.damtype
		else
			attack_force = W.force
			damage_type = W.damtype

		if (!attack_force)
			return

		if (src.sleeping)
			sleeping = 0
			on_wake()

		switch(damage_type)
			if("fire")
				src.health -= attack_force * src.firevuln
			if("brute")
				src.health -= attack_force * src.brutevuln
			else
				src.health -= attack_force * src.miscvuln
		if (hitsound)
			playsound(src, hitsound, 50, 1)
		if (src.alive && src.health <= 0) src.CritterDeath()
		if (src.alive)
			on_damaged(user)
		if (src.defensive)
			if (src.target == user && src.task == "attacking")
				if (prob(50 - attack_force))
					return
				else
					src.visible_message("<span style=\"color:red\"><b>[src]</b> flinches!</span>")
			src.target = user
			src.oldtarget_name = user.name
			src.visible_message("<span style=\"color:red\"><b>[src]</b> [src.angertext] [user.name]!</span>")
			src.task = "chasing"
			on_grump()

	proc/on_damaged(mob/user)
		if(registered_area) //In case some butt fiddles with a hibernating critter
			registered_area.wake_critters()
		return

	proc/on_pet()
		if(registered_area) //In case some nice person fiddles with a hibernating critter
			registered_area.wake_critters()
		return

	attack_hand(var/mob/user as mob)
		..()
		if (!src.alive)
			..()
			return

		if (src.sleeping)
			sleeping = 0
			on_wake()

		if (user.a_intent == INTENT_HARM)
			src.health -= rand(1,2) * src.brutevuln
			src.visible_message("<span style=\"color:red\"><b>[user]</b> punches [src]!</span>")
			playsound(src.loc, pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg'), 100, 1)
			if (hitsound)
				playsound(src, hitsound, 50, 1)
			if (src.alive && src.health <= 0) src.CritterDeath()
			if (src.alive)
				on_damaged(user)
			if (src.defensive)
				if (src.target == user && src.task == "attacking")
					if (prob(50))
						return
					else
						src.visible_message("<span style=\"color:red\"><b>[src]</b> flinches!</span>")
				src.target = user
				src.oldtarget_name = user.name
				src.visible_message("<span style=\"color:red\"><b>[src]</b> [src.angertext] [user.name]!</span>")
				src.task = "chasing"
				on_grump()
		else
			var/pet_verb = islist(src.pet_text) ? pick(src.pet_text) : src.pet_text
			src.visible_message("<span style=\"color:blue\"><b>[user]</b> [pet_verb] [src]!</span>", 1)
			on_pet()

	proc/patrol_step()
		if (!mobile)
			return
		var/turf/moveto = locate(src.x + rand(-1,1),src.y + rand(-1, 1),src.z)
		if(isturf(moveto) && !moveto.density) step_towards(src, moveto)
		if(src.aggressive) seek_target()
		steps += 1
		if (steps == rand(5,20)) src.task = "thinking"

	Bump(M as mob|obj)
		spawn(0)
			if (istype(M, /obj/machinery/door/))
				var/obj/machinery/door/D = M
				D.Bumped(src) // Doesn't call that automatically for some inexplicable reason.
			else if ((istype(M, /mob/living/)) && (!src.anchored))
				src.set_loc(M:loc)
				src.frustration = 0
			return
		return

	bullet_act(var/obj/projectile/P)
		var/damage = 0
		damage = round((P.power*P.proj_data.ks_ratio), 1.0)

		if (src.sleeping)
			sleeping = 0
			on_wake()

		if(src.material) src.material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter) )
		for(var/atom/A in src)
			if(A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter) )

		switch(P.proj_data.damage_type)
			if(D_KINETIC,D_PIERCING,D_SLASHING)
				src.health -= (damage*brutevuln)
			if(D_ENERGY)
				src.health -= damage
			if(D_BURNING)
				src.health -= (damage*firevuln)
			if(D_RADIOACTIVE)
				src.health -= 1
			if(D_TOXIC)
				src.health -= 1

		on_damaged(usr)
		if (src.health <= 0)
			src.CritterDeath()

	ex_act(severity)
		if (src.sleeping)
			sleeping = 0
			on_wake()

		on_damaged()

		switch(severity)
			if(1.0)
				src.health -= 200
				if (src.health <= 0)
					src.CritterDeath()
				return
			if(2.0)
				src.health -= 75
				if (src.health <= 0)
					src.CritterDeath()
				return
			else
				src.health -= 25
				if (src.health <= 0)
					src.CritterDeath()
				return
		return

	meteorhit()
		src.health -= 150 // no more instakill
		on_damaged()
		if (src.health <= 0)
			src.CritterDeath()
		return

	proc/check_health()
		if (src.health <= 0)
			src.CritterDeath()

	blob_act(var/power)
		src.health -= power
		on_damaged()
		if (src.health <= 0)
			src.CritterDeath()
		return

	proc/follow_path()
		if (!mobile)
			task = "thinking"
			return
		if (src.loc == followed_path_retry_target)
			logTheThing("debug", null, null, "<B>Marquesas/Critter Astar:</b> Critter arrived at target location.")
			task = "thinking"
			followed_path = null
			followed_path_retries = 0
			followed_path_retry_target = null
		else if (!followed_path)
			logTheThing("debug", null, null, "<B>Marquesas/Critter Astar:</b> Critter following empty path.")
			task = "thinking"
		else if (!followed_path.len)
			logTheThing("debug", null, null, "<B>Marquesas/Critter Astar:</b> Critter path ran out.")
			task = "thinking"
		else
			var/turf/nextturf = followed_path[1]
			var/retry = 0
			if (nextturf.density)
				retry = 1
			if (!retry)
				for (var/obj/O in nextturf)
					if (O.density)
						retry = 1
						break
			if (retry)
				if (!followed_path_retry_target)
					task = "thinking"
				else if (followed_path_retries > 10)
					logTheThing("debug", null, null, "<B>Marquesas/Critter Astar:</b> Critter out of retries.")
					task = "thinking"
				else
					logTheThing("debug", null, null, "<B>Marquesas/Critter Astar:</b> Hit a wall, retrying.")
					followed_path = findPath(src.loc, followed_path_retry_target)
					return
			else
				set_loc(nextturf)
				followed_path -= nextturf
		if (!follow_path_blindly)
			seek_target()

	proc/do_wake_check(var/force = 0)
		if(!force && sleeping-- > 0) return

		var/waking = 0
		for(var/mob/M in range(10, src))
			if(M.client)
				waking = 1
				break
		if (!waking)
			if (get_area(src) == colosseum_controller.colosseum)
				waking = 1

		if(waking)
			hibernate_check = 20
			sleeping = 0
			task = "thinking"
			on_wake()
			if (sleeping_icon_state)
				src.icon_state = initial(src.icon_state)
			return 1
		else
			sleeping = 10
			if(--hibernate_check <= 0)
				src.hibernate()
			return 0

	proc/do_sleep_check(var/force = 0)
		if(!force && sleep_check-- > 0) return

		var/stay_awake = 0
		for(var/mob/M in range(10, src))
			if(M.client)
				stay_awake = 1
				break

		if(!stay_awake)
			sleeping = 10
			on_sleep()
			if (sleeping_icon_state)
				src.icon_state = sleeping_icon_state
			task = "sleeping"
			return 0
		else
			sleep_check = 10

	proc/process()
		if (is_template || task == "hibernating")
			return 0
		if (!src.alive) return 0

		if(sleeping > 0)
			sleeping--
			return 0

		check_health()

		if(task == "following path")
			follow_path()
			spawn(10)
				follow_path()
		else if(task == "sleeping")
			do_wake_check()
		else
			do_sleep_check()

		return ai_think()

	proc/ai_think()
		switch(task)
			if ("thinking")
				src.attack = 0
				src.target = null

				walk_to(src,0)

				if (src.aggressive) seek_target()
				if (src.wanderer && src.mobile && !src.target) src.task = "wandering"
			if ("chasing")
				if (src.frustration >= 8)
					src.target = null
					src.last_found = world.time
					src.frustration = 0
					src.task = "thinking"
					if (mobile)
						walk_to(src,0)
				if (target)
					if (get_dist(src, src.target) <= src.attack_range)
						var/mob/living/carbon/M = src.target
						if (M)
							ChaseAttack(M)
							src.task = "attacking"
							src.anchored = 1
							src.target_lastloc = M.loc
					else
						if (mobile)
							var/turf/olddist = get_dist(src, src.target)
							walk_to(src, src.target,1,4)
							if ((get_dist(src, src.target)) >= (olddist))
								src.frustration++
							else
								src.frustration = 0
						else
							if (get_dist(src, src.target) > attack_range)
								src.frustration++
							else
								src.frustration = 0
				else src.task = "thinking"

			if ("chasing food")
				if (!src.chases_food || src.food_target == null)
					src.task = "thinking"
				else if (get_dist(src, src.food_target) <= src.attack_range)
					src.task = "eating"
				else
					walk_to(src, src.food_target,1,4)

			if ("eating")
				if (get_dist(src, src.food_target) > src.attack_range)
					src.task = "chasing food"
				else
					src.visible_message("<b>[src]</b> [src.eat_text] [src.food_target].")
					playsound(src.loc,"sound/items/eatfood.ogg", rand(10,50), 1)
					if (food_target.reagents.total_volume > 0 && src.reagents.total_volume < 30)
						food_target.reagents.trans_to(src, 5)
					src.food_target.amount--
					spawn(rand(20,30))
						if (src.food_target != null && src.food_target.amount <= 0)
							qdel(src.food_target)
							src.task = "thinking"
							src.food_target = null
							src.health += src.health_gain_from_food

			if ("attacking")
				// see if he got away
				if ((get_dist(src, src.target) > src.attack_range) || ((src.target:loc != src.target_lastloc)))
					src.anchored = initial(src.anchored)
					src.task = "chasing"
				else
					if (get_dist(src, src.target) <= src.attack_range)
						var/mob/living/carbon/M = src.target
						if (!src.attacking) CritterAttack(src.target)
						if (!src.aggressive)
							src.task = "thinking"
							src.target = null
							src.anchored = initial(src.anchored)
							src.last_found = world.time
							src.frustration = 0
							src.attacking = 0
						else
							if(M!=null)
								if (M.health < 0)
									src.task = "thinking"
									src.target = null
									src.anchored = initial(src.anchored)
									src.last_found = world.time
									src.frustration = 0
									src.attacking = 0
					else
						src.anchored = initial(src.anchored)
						src.attacking = 0
						src.task = "chasing"
			if ("wandering")
				patrol_step()
		return 1


	New()
		if(!src.reagents) src.create_reagents(100)
		critters += src
		report_spawn()
		if(generic)
			src.quality = rand(min_quality,max_quality)
			var/nickname = getCritterQuality(src.quality)
			if(nickname)
				src.quality_name = nickname
				src.name = "[nickname] [src.name]"
		..()

	proc/seek_target()
		src.anchored = initial(src.anchored)
		if (src.target)
			src.task = "chasing"
			return

		if (src.chases_food)
			var/list/visible = new()
			for (var/obj/item/reagent_containers/food/snacks/S in view(src.seekrange,src))
				visible.Add(S)
			if (src.food_target && visible.Find(src.food_target))
				src.task = "chasing food"
				return
			else
				src.task = "thinking"
			if (visible.len)
				src.food_target = visible[1]
				src.task = "chasing food"

		for (var/mob/living/C in hearers(src.seekrange,src))
			//if (src.target)
			//	src.task = "chasing"
			//	break
			if ((C.name == src.oldtarget_name) && (world.time < src.last_found + 100)) continue
			if (iscarbon(C) && !src.atkcarbon) continue
			if (istype(C, /mob/living/silicon/) && !src.atksilicon) continue
			if (istype(C, /mob/living/intangible/) && !src.atkintangible) continue
			if (C.health < 0) continue
			if(!filter_target(C)) continue
			if (C in src.friends) continue
			if (ishuman(C))
				if (C:bioHolder && C:bioHolder.HasEffect("revenant"))
					continue
			if (C.name == src.attacker) src.attack = 1
			if (iscarbon(C) && src.atkcarbon) src.attack = 1
			if (istype(C, /mob/living/silicon/) && src.atksilicon) src.attack = 1

			if (src.attack)
				src.target = C
				src.oldtarget_name = C.name
				src.visible_message("<span class='combat'><b>[src]</b> [src.angertext] [C.name]!</span>")
				src.task = "chasing"
				on_grump()
				break
			else
				continue

	proc/filter_target(var/mob/living/M) //Better to have specialized filters in it's own proc rather than overriding the main seek_target thing imo
		return 1

	proc/CritterDeath()
		if (!src.alive) return
		if (!dead_state)
			src.icon_state = "[initial(src.icon_state)]-dead"
		else
			src.icon_state = dead_state
		src.alive = 0
		src.anchored = 0
		src.density = 0
		walk_to(src,0)
		report_death()
		src.tokenized_message(death_text)

	proc/ChaseAttack(mob/M)
		src.visible_message("<span class='combat'><B>[src]</B> leaps at [src.target]!</span>")
		//playsound(src.loc, "sound/weapons/genhit1.ogg", 50, 1, -1)

	proc/CritterAttack(mob/M)
		src.attacking = 1
		src.visible_message("<span class='combat'><B>[src]</B> bites [src.target]!</span>")
		random_brute_damage(src.target, 1)
		spawn(25)
			src.attacking = 0

	proc/getCritterQuality(var/quality)
		switch(quality)
			if(-INFINITY to -100)
				return "abysmal"
			if(-100 to -99)
				return "worst"
			if(-98 to -91)
				return pick("shameful", "hideous", "grotesque", "vile", "misshapen", "garbage", "illegal", "dreadful", "god-awful")
			if(-90 to -75)
				return pick("ugly", "grody", "stinky", "awful", "diseased", "filthy", "lousy", "overweight", "broken", "unfortunate", "unacceptable", "sad", "slipshod", "crappy", "faulty", "fraudulent")
			if(-74 to -50)
				return pick("shabby", "mangy", "dented", "dusty", "sub-par", "slightly less nice", "weird", "crummy", "busted", "funky", "bad news", "deficient", "cruddy", "icky", "not good")
			if(-49 to 50)
				return ""
			if(51 to 64)
				return pick("nice", "cute", "healthy", "buff", "strong")
			if(65 to 74)
				return pick("suave", "buff", "robust", "handsome", "fine", "slightly nicer", "pretty good")
			if(75 to 85)
				return pick("high-class", "great", "burly", "superb", "excellent", "admirable")
			if(86 to 90)
				return pick("majestic", "fantastic", "high-quality", "marvelous", "deluxe")
			if(91 to 94)
				return pick("show-quality", "finest", "superb")
			if(95 to 97)
				return "champion"
			if(98 to 99)
				src.material = getCachedMaterial("gold")
				if (src.material)
					src.material.owner = src
					src.material.triggerOnAdd(src)
				return "best"
			if(100 to INFINITY)
				src.material = getCachedMaterial("gold")
				if (src.material)
					src.material.owner = src
					src.material.triggerOnAdd(src)
				return "mystical"
			else
				return "odd"
		return

	proc/Shoot(var/target, var/start, var/user, var/bullet = 0)
		if(target == start)
			return
	//	playsound(user, "mp5gunshot.ogg", 100, 1)
	/*	if(bullet == 0)
			A = new /obj/bullet/mpbullet( user:loc )
		else if(bullet == 1)
			playsound(user, "sound/weapons/shotgunshot.ogg", 100, 1)
			A = new /obj/bullet/slug( user:loc )
		else if(bullet == 2)
			playsound(user, "fivegunshot.ogg", 100, 1)
			A = new /obj/bullet/medbullet( user:loc )*/
		if (!isturf(target))
			return
		// FUCK YOU WHOEVER IS USING THIS
		// FUCK YOU
		shoot_projectile_ST(src,  new/datum/projectile/bullet/revolver_38(), target)
		return


/obj/item/reagent_containers/food/snacks/ingredient/egg/critter
	name = "egg"
	desc = "Looks like this could hatch into something."
	icon_state = "critter_egg"
	var/critter_name = null
	var/hatched = 0
	var/critter_type = null
	var/warm_count = 10 // how many times you gotta warm it before it hatches
	var/critter_reagent = null
	rand_pos = 1

	New()
		..()
		var/amt_to_mod = round(src.warm_count / 10, 1)
		src.warm_count += rand(-amt_to_mod,amt_to_mod)
		src.color = random_saturated_hex_color(1)
		if (src.reagents && src.critter_reagent)
			src.reagents.add_reagent(src.critter_reagent, 10)

	attack_hand(mob/user as mob)
		if (src.anchored)
			return
		else
			..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/pen))
			var/t = input(user, "Enter new name", src.name, src.critter_name) as null|text
			logTheThing("debug", user, null, "names a critter egg \"[t]\"")
			if (!t)
				return
			t = strip_html(replacetext(t, "'",""))
			t = copytext(t, 1, 65)
			if (!t)
				return
			if (!in_range(src, usr) && src.loc != usr)
				return

			src.critter_name = t

		else if ((istype(W, /obj/item/weldingtool) && W:welding) || (istype(W, /obj/item/clothing/head/cakehat) && W:on) || istype(W, /obj/item/device/igniter) || ((istype(W, /obj/item/zippo) || istype(W, /obj/item/match) || istype(W, /obj/item/device/candle)) && W:lit) || W.burning || W.hit_type == DAMAGE_BURN) // jesus motherfucking christ
			user.visible_message("<span style=\"color:red\"><b>[user]</b> warms [src] with [W].</span>",\
			"<span style=\"color:red\">You warm [src] with [W].</span>")
			src.warm_count -= 2
			src.warm_count = max(src.warm_count, 0)
			src.hatch_check(0, user)
		else
			return ..()

	attack_self(mob/user as mob)
		if (src.anchored)
			return
		user.visible_message("[user] warms [src] with [his_or_her(user)] hands.",\
		"You warm [src] with your hands.")
		src.warm_count --
		src.warm_count = max(src.warm_count, 0)
		src.hatch_check(0, user)

	throw_impact(var/turf/T)
		//..() <- Fuck off mom, I'm 25 and I do what I want =I
		src.hatch_check(1, null, T)

	proc/hatch_check(var/shouldThrow = 0, var/mob/user, var/turf/T)
		if (hatched || anchored)
			return
		if (src.warm_count <= 0 || shouldThrow)
			if (shouldThrow && T)
				new /obj/decal/cleanable/eggsplat(T)
				src.set_loc(T)
			else
				src.anchored = 1
				src.layer = initial(src.layer)
				if (user)
					user.u_equip(src)
				src.set_loc(get_turf(src))

			spawn(0)
				if (shouldThrow && T)
					src.visible_message("<span style=\"color:red\">[src] splats onto the floor messily!</span>")
					playsound(T, "sound/effects/splat.ogg", 100, 1)
				else
					var/hatch_wiggle_counter = rand(3,8)
					while (hatch_wiggle_counter-- > 0)
						src.pixel_x++
						sleep(2)
						src.pixel_x--
						sleep(10)
					src.visible_message("[src] hatches!")

				if (!ispath(critter_type))
					if (istext(critter_type))
						critter_type = text2path(critter_type)
					else
						logTheThing("debug", null, null, "EGG: [src] has invalid critter path!")
						src.visible_message("Looks like there wasn't anything inside of [src]!")
						qdel(src)
						return

				var/obj/critter/newCritter = new critter_type(T ? T : get_turf(src))

				if (critter_name)
					newCritter.name = critter_name

				if (shouldThrow && T)
					newCritter.throw_at(get_edge_target_turf(src, src.dir), 2, 1)

				sleep(1)
				qdel(src)
				return
		else
			return
