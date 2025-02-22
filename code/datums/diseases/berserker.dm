// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/ailment/disease/berserker
	name = "Berserker"
	max_stages = 2
	spread = "Non-Contagious"
	cure = "Anti-Psychotics"
	reagentcure = list("haloperidol")
	recureprob = 10
	associated_reagent = "pubbie tears"
	affected_species = list("Human")

/datum/ailment/disease/berserker/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return
	if (affected_mob.reagents.has_reagent("THC"))
		boutput(affected_mob, "<span style=\"color:blue\">You mellow out.</span>")
		affected_mob.cure_disease(D)
		return
	switch(D.stage)
		if(1)
			if (prob(5)) affected_mob.emote(pick("twitch", "grumble"))
			if (prob(5))
				var/speak = pick("Grr...", "Fuck...", "Fucking...", "Fuck this fucking.. fuck..")
				affected_mob.say(speak)
		if(2)
			if (prob(5)) affected_mob.emote(pick("twitch", "scream"))
			if (prob(5))
				var/speak = pick("AAARRGGHHH!!!!", "GRR!!!", "FUCK!! FUUUUUUCK!!!", "FUCKING SHITCOCK!!", "WROOAAAGHHH!!")
				affected_mob.say(speak)
			if (prob(15))
				for(var/mob/O in viewers(affected_mob, null))
					O.show_message(text("<span style=\"color:red\"><B>[] twitches violently!</B></span>", affected_mob), 1)
				var/h = affected_mob.hand
				affected_mob.hand = 0
				affected_mob.drop_item()
				affected_mob.hand = 1
				affected_mob.drop_item()
				affected_mob.hand = h
			if (prob(33))
				if (!affected_mob.canmove)
					for(var/mob/O in viewers(affected_mob, null))
						O.show_message(text("<span style=\"color:red\"><B>[] spasms and twitches!</B></span>", affected_mob), 1)
					return
				for (var/mob/living/carbon/M in range(1,affected_mob))
					for(var/mob/O in viewers(affected_mob, null))
						O.show_message(text("<span style=\"color:red\"><B>[] thrashes around violently!</B></span>", affected_mob), 1)
					if (M == affected_mob) continue
					var/damage = rand(1, 5)
					if (prob(80))
						playsound(affected_mob.loc, "punch", 25, 1, -1)
						for(var/mob/O in viewers(affected_mob, null))
							O.show_message(text("<span style=\"color:red\"><B>[] hits [] with their thrashing!</B></span>", affected_mob, M), 1)
						random_brute_damage(M, damage)
					else
						playsound(affected_mob.loc, "sound/weapons/punchmiss.ogg", 25, 1, -1)
						for(var/mob/O in viewers(affected_mob, null))
							O.show_message(text("<span style=\"color:red\"><B>[] fails to hit [] with their thrashing!</B></span>", affected_mob, M), 1)
						return