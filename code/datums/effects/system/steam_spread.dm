// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/////////////////////////////////////////////
// GENERIC STEAM SPREAD SYSTEM

//Usage: set_up(number of bits of steam, use North/South/East/West only, spawn location)
// The attach(atom/atom) proc is optional, and can be called to attach the effect
// to something, like a smoking beaker, so then you can just call start() and the steam
// will always spawn at the items location, even if it's moved.

/* Example:
var/datum/effects/system/steam_spread/steam = new /datum/effects/system/steam_spread() -- creates new system
steam.set_up(5, 0, mob.loc) -- sets up variables
OPTIONAL: steam.attach(mob)
steam.start() -- spawns the effect
*/
/////////////////////////////////////////////


/datum/effects/system/steam_spread
	var/number = 3
	var/cardinals = 0
	var/turf/location
	var/atom/holder

/datum/effects/system/steam_spread/pooled()
	..()
	number = initial(number)
	cardinals = initial(cardinals)
	location = null
	holder = null

/datum/effects/system/steam_spread/proc/set_up(n = 3, c = 0, turf/loc)
	if(n > 10)
		n = 10
	number = n
	cardinals = c
	location = loc

/*
/datum/effects/system/steam_spread/Del()
	pool(src)
*/

/datum/effects/system/steam_spread/proc/attach(atom/atom)
	holder = atom

/datum/effects/system/steam_spread/proc/start()
	for(var/i=0, i<src.number, i++)
		spawn(0)
			if(holder)
				src.location = get_turf(holder)
			var/obj/effects/steam/steam = unpool(/obj/effects/steam)
			steam.set_loc(src.location)
			var/direction
			if(src.cardinals)
				direction = pick(cardinal)
			else
				direction = pick(alldirs)
			for(var/j=0, j<pick(1,2,3), j++)
				sleep(5)
				step(steam,direction)
			spawn(20)
				if (steam)
					pool(steam)

