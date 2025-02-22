// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/hud
	name = "hud"
	anchored = 1
	var/mob/mymob = null
	var/list/adding = null
	var/list/other = null
	var/list/intents = null
	var/list/mov_int = null
	var/list/mon_blo = null
	var/list/m_ints = null
	var/list/darkMask = null

	var/h_type = /obj/screen

obj/hud/New(var/type = 0)
	src.instantiate(type)
	..()
	return

/obj/hud/var/show_otherinventory = 1
/obj/hud/var/obj/screen/action_intent
/obj/hud/var/obj/screen/move_intent

/obj/hud/proc/instantiate(var/type = 0)

	mymob = src.loc
	ASSERT(istype(mymob, /mob))

	if(istype(mymob, /mob/living/silicon/hivebot))
		src.hivebot_hud()
		return

	if (istype(mymob, /mob/living/object))
		src.object_hud()
		return