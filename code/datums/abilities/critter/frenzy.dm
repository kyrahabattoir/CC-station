// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// --------------------
// Wendigo style frenzy
// --------------------
/datum/targetable/critter/frenzy
	name = "Frenzy"
	desc = "Go into a bloody frenzy on a weakened target and rip them to shreds."
	cooldown = 350
	targeted = 1
	target_anything = 1
	icon_state = "frenzy"

	var/datum/projectile/slam/proj = new

	cast(atom/target)
		if (disabled && world.time > last_cast)
			disabled = 0 // break the deadlock
		if (disabled)
			return 1
		if (..())
			return 1
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			for (var/mob/living/M in target)
				if (M != src && M.weakened)
					target = M
					break
			if (!ismob(target))
				boutput(holder.owner, __red("Nothing to frenzy at there."))
				return 1
		if (target == holder.owner)
			return 1
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("That is too far away to frenzy."))
			return 1
		var/mob/MT = target
		if (!MT.weakened && !MT.paralysis && !MT.stat)
			boutput(holder.owner, __red("That is moving around far too much to pounce."))
			return 1
		playsound(get_turf(holder.owner), "sound/misc/wendigo_roar.ogg", 80, 1)
		disabled = 1
		spawn(0)
			var/frenz = rand(10, 20)
			holder.owner.canmove = 0
			while (frenz > 0 && MT && !MT.disposed)
				MT.weakened = max(MT.weakened, 2)
				MT.canmove = 0
				if (MT.loc)
					holder.owner.set_loc(MT.loc)
				holder.owner.stunned = max(holder.owner.stunned, 1)
				if (holder.owner.stunned > 1 || holder.owner.weakened || holder.owner.paralysis)
					break
				playsound(get_turf(holder.owner), "sound/misc/wendigo_maul.ogg", 80, 1)
				holder.owner.visible_message("<span style=\"color:red\"><b>[holder.owner] [pick("mauls", "claws", "slashes", "tears at", "lacerates", "mangles")] [MT]!</b></span>")
				holder.owner.dir = pick(cardinal)
				holder.owner.pixel_x = rand(-5, 5)
				holder.owner.pixel_y = rand(-5, 5)
				random_brute_damage(MT, 10)
				take_bleeding_damage(MT, null, 5, DAMAGE_CUT, 0, get_turf(MT))
				if(prob(33)) // don't make quite so much mess
					bleed(MT, 5, 5, get_step(get_turf(MT), pick(alldirs)), 1)
				sleep(4)
				frenz--
			if (MT)
				MT.canmove = 1
			doCooldown()
			disabled = 0
			holder.owner.pixel_x = 0
			holder.owner.pixel_y = 0
			holder.owner.canmove = 1

		return 0