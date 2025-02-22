// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/spell/golem
	name = "Summon Golem"
	desc = "Summons a Golem made of the reagent you currently hold."
	icon_state = "golem"
	targeted = 0
	cooldown = 500
	requires_robes = 1
	offensive = 1
	cooldown_staff = 1

	cast()
		if(!holder)
			return
		var/obj/item/AnItem = null //temp item holder for processing
		var/datum/reagents/TheReagents = null //reagent holder

		//get reagent container if there is one, and check to see it has some reagents
		if (holder.owner.r_hand != null)
			AnItem = holder.owner.r_hand
			if(istype(AnItem, /obj/item/reagent_containers/))
				if(AnItem.reagents.total_volume)
					TheReagents = AnItem.reagents
			else
				AnItem = null



		if (holder.owner.l_hand != null && !AnItem)
			AnItem = holder.owner.l_hand
			if(istype(AnItem, /obj/item/reagent_containers/))
				if(AnItem.reagents.total_volume)
					TheReagents = AnItem.reagents
			else
				AnItem = null


		if(!AnItem)
			boutput(holder.owner, "<span style=\"color:red\">You must be holding a container in your hand.</span>")
			return 1 // No cooldown when it fails.

		if(!TheReagents)
			boutput(holder.owner, "<span style=\"color:red\">You have no material to convert into a golem.</span>")
			return 1


		holder.owner.say("CLAE MASHON")
		playsound(holder.owner.loc, "sound/voice/wizard/GolemLoud.ogg", 50, 0, -1)

		var/obj/critter/golem/TheGolem
		if (istype(AnItem, /obj/item/reagent_containers/food/snacks/ingredient/egg/bee))
			TheGolem = new /obj/critter/domestic_bee(get_turf(holder.owner))
			TheGolem.name = "Bee Golem"
			TheGolem.desc = "A greater domestic space bee that has been created with magic, but is otherwise completely identical to any other member of its species."
		else
			TheGolem = new /obj/critter/golem(get_turf(holder.owner))
			TheGolem.CustomizeGolem(TheReagents)

		qdel(TheReagents)
		qdel(AnItem)
		boutput(holder.owner, "<span style=\"color:blue\">You conjure up [TheGolem]!</span>")
		holder.owner.visible_message("<span style=\"color:red\">[holder.owner] conjures up [TheGolem]!</span>")
		playsound(holder.owner.loc, "sound/effects/mag_golem.ogg", 25, 1, -1)
