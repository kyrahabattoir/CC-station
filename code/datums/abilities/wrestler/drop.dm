// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/wrestler/drop
	name = "Drop (prone)"
	desc = "Smash down onto on an opponent."
	targeted = 1
	target_anything = 0
	target_nodamage_check = 1
	target_selection_check = 1
	max_range = 1
	cooldown = 350
	start_on_cooldown = 1
	pointCost = 0
	when_stunned = 0
	not_when_handcuffed = 1

	cast(mob/target)
		if (!holder)
			return 1

		var/mob/living/M = holder.owner

		if (!M || !target)
			return 1

		if (M == target)
			boutput(M, __red("Why would you want to wrestle yourself?"))
			return 1

		if (get_dist(M, target) > src.max_range)
			boutput(M, __red("[target] is too far away."))
			return 1

		if (!target.lying)
			boutput(M, __red("You can use this move on prone opponents only!"))
			return 1

		var/obj/surface = null
		var/turf/ST = null
		var/falling = 0

		for (var/obj/O in oview(1, M))
			if (O.density == 1 || istype(O, /obj/stool))
				if (O == M) continue
				if (O == target) continue
				if (O.opacity) continue
				if (istype(O, /obj/window) || istype(O, /obj/grille))
					continue
				else
					surface = O
					ST = get_turf(O)
					break

		if (surface && (ST && isturf(ST)))
			M.set_loc(ST)
			M.visible_message("<span style=\"color:red\"><B>[M] climbs onto [surface]!</b></span>")
			M.pixel_y = 10
			falling = 1
			sleep (10)

		if (M && target)
			// These are necessary because of the sleep call.
			if (src.castcheck() != 1)
				M.pixel_y = 0
				return 0

			if ((falling == 0 && get_dist(M, target) > src.max_range) || (falling == 1 && get_dist(M, target) > (src.max_range + 1))) // We climbed onto stuff.
				M.pixel_y = 0
				if (falling == 1)
					M.visible_message("<span style=\"color:red\"><B>...and dives head-first into the ground, ouch!</b></span>")
					random_brute_damage(M, 15)
					M.weakened += 3
				boutput(M, __red("[target] is too far away!"))
				return 0

			if (!isturf(M.loc) || !isturf(target.loc))
				M.pixel_y = 0
				boutput(M, __red("You can't drop onto [target] from here!"))
				return 0

			spawn (0)
				if (M)
					animate(M, transform = matrix(90, MATRIX_ROTATE), time = 1, loop = 0)
				sleep (10)
				if (M)
					animate(transform = null, time = 1, loop = 0)

			M.set_loc(target.loc)

			M.visible_message("<span style=\"color:red\"><B>[M] [pick_string("wrestling_belt.txt", "drop")] [target]!</B></span>")
			playsound(M.loc, "swing_hit", 50, 1)
			M.emote("scream")

			if (falling == 1)
				if (prob(33) || target.stat == 2)
					target.ex_act(3)
				else
					random_brute_damage(target, 25)
			else
				random_brute_damage(target, 15)

			target.weakened++
			target.stunned += 2

			M.pixel_y = 0
			logTheThing("combat", M, target, "uses the drop wrestling move on %target% at [log_loc(M)].")

		else
			if (M)
				M.pixel_y = 0

		return 0




