// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/mob/living/critter/fire_elemental
	name = "fire elemental"
	real_name = "fire elemental"
	desc = "Oh god."
	density = 1
	icon_state = "fire_elemental"
	icon_state_dead = "fire_elemental-dead"
	custom_gib_handler = /proc/gibs
	hand_count = 3
	can_throw = 1
	can_grab = 1
	can_disarm = 1
	blood_id = "phlogiston"
	burning_suffix = "humanoid"

	specific_emotes(var/act, var/param = null, var/voluntary = 0)
		switch (act)
			if ("scream")
				if (src.emote_check(voluntary, 50))
					return "<b><span style='color:red'>[src] wails!</span></b>"
		return null

	specific_emote_type(var/act)
		switch (act)
			if ("scream")
				return 2
		return ..()

	setup_equipment_slots()
		equipment += new /datum/equipmentHolder/suit(src)
		equipment += new /datum/equipmentHolder/ears(src)
		equipment += new /datum/equipmentHolder/head(src)

	setup_hands()
		..()
		var/datum/handHolder/HH = hands[3]
		HH.name = "control of fire"
		HH.limb = new /datum/limb/gun/fire_elemental
		HH.icon_state = "element-fire"
		HH.icon = 'icons/mob/critter_ui.dmi'
		HH.limb_name = "fire essence"
		HH.can_hold_items = 0
		HH.can_attack = 0
		HH.can_range_attack = 1

	setup_healths()
		add_hh_flesh(-150, 150, 1.15)
		add_health_holder(/datum/healthHolder/brain)

	New()
		..()
		abilityHolder.addAbility(/datum/targetable/critter/cauterize)
		abilityHolder.addAbility(/datum/targetable/critter/flamethrower)
