// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/coin
	name = "coin"
	desc = "A small gold coin with an alien head on one side and a monkey buttocks on the other."
	icon = 'icons/obj/items.dmi'
	icon_state = "coin"
	item_state = "coin"
	w_class = 1.0
	stamina_damage = 1
	stamina_cost = 1
	module_research = list("vice" = 3, "efficiency" = 1)
	module_research_type = /obj/item/coin

/obj/item/coin/attack_self(mob/user as mob)
	boutput(user, "<span style=\"color:blue\">You flip the coin</span>")
	spawn(10)
		if(prob(49))
			boutput(user, "<span style=\"color:blue\">It comes up heads</span>")
		else if(prob(49))
			boutput(user, "<span style=\"color:blue\">It comes up tails</span>")
		else
			boutput(user, "<span style=\"color:red\">It lands on its side, fuck</span>")


/obj/item/coin/throw_impact(atom/hit_atom)
	..(hit_atom)
	if(prob(49))
		src.visible_message("<span style=\"color:blue\">The coin comes up heads</span>")

	else if(prob(49))
		src.visible_message("<span style=\"color:blue\">The coin comes up tails</span>")
	else
		src.visible_message("<span style=\"color:blue\">The coin lands on its side</span>")

/obj/item/coin_bot
	name = "Probability Disc"
	desc = "A small golden disk of some sort. Possibly used in highly complex quantum experiments."
	icon = 'icons/obj/items.dmi'
	icon_state = "coin"
	item_state = "coin"
	w_class = 1.0

	attack_self(var/mob/user as mob)
		playsound(src.loc, "sound/misc/coindrop.ogg", 100, 1)
		if (prob(50))
			user.visible_message("[src] shows Heads.")
		else
			user.visible_message("[src] shows Tails.")

/obj/item/coin/suicide(var/mob/user as mob)
	user.visible_message("<span style=\"color:red\"><b>[user] swallows the [src.name] and begins to choke!</b></span>")
	user.take_oxygen_deprivation(175)
	user.updatehealth()
	spawn(100)
		if (user)
			user.suiciding = 0
	qdel(src)
	return 1