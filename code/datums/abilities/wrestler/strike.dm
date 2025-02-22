// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/wrestler/strike
	name = "Strike"
	desc = "Hit a neaby opponent with a quick attack."
	targeted = 1
	target_anything = 0
	target_nodamage_check = 1
	target_selection_check = 1
	max_range = 1
	cooldown = 250
	start_on_cooldown = 1
	pointCost = 0
	when_stunned = 1
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

		var/turf/T = get_turf(M)
		if (T && isturf(T) && target && isturf(target.loc))
			playsound(M.loc, "swing_hit", 50, 1)

			spawn (0)
				for (var/i = 0, i < 4, i++)
					M.dir = turn(M.dir, 90)

				M.set_loc(target.loc)
				spawn (4)
					if (M && (T && isturf(T) && get_dist(M, T) <= 1))
						M.set_loc(T)

			M.visible_message("<span style=\"color:red\"><b>[M] [pick_string("wrestling_belt.txt", "strike")] [target]!</b></span>")
			random_brute_damage(target, 15)
			playsound(M.loc, "sound/effects/fleshbr1.ogg", 75, 1)

			target.paralysis++
			target.change_misstep_chance(25)

			logTheThing("combat", M, target, "uses the strike wrestling move on %target% at [log_loc(M)].")

		else
			boutput(M, __red("You can't wrestle the target here!"))

		return 0