// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/turf/simulated/floor/engine/attack_hand(var/mob/user as mob)
	if ((!( user.canmove ) || user.restrained() || !( user.pulling )))
		return
	if (user.pulling.anchored)
		return
	if ((user.pulling.loc != user.loc && get_dist(user, user.pulling) > 1))
		return
	if (ismob(user.pulling))
		var/mob/M = user.pulling
		var/mob/t = M.pulling
		M.pulling = null
		step(user.pulling, get_dir(user.pulling.loc, src))
		M.pulling = t
	else
		step(user.pulling, get_dir(user.pulling.loc, src))
	return

/turf/simulated/floor/engine/ex_act(severity)
	switch(severity)
		if(1.0)
			ReplaceWithSpace()
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				ReplaceWithSpace()
				qdel(src)
				return
		else
	return

/turf/simulated/floor/engine/blob_act(var/power)
	if (prob(15))
		ReplaceWithSpace()
		qdel(src)
		return
	return