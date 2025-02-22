// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/ailment/disease/gbs
	name = "GBS"
	max_stages = 5
	spread = "Non-Contagious"
	cure = "Cryoxadone"
	reagentcure = list("cryoxadone")
	recureprob = 10
	associated_reagent = "gibbis"
	affected_species = list("Human")


/datum/ailment/disease/gbs/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return
	switch(D.stage)
		if(2)
			if(prob(45))
				affected_mob.take_toxin_damage(5)
				affected_mob.updatehealth()
			if(prob(1))
				affected_mob.emote("sneeze")
		if(3)
			if(prob(5))
				affected_mob.emote("cough")
			else if(prob(5))
				affected_mob.emote("gasp")
			if(prob(10))
				boutput(affected_mob, "<span style=\"color:red\">You're starting to feel very weak...</span>")
		if(4)
			if(prob(10))
				affected_mob.emote("cough")
			affected_mob.take_toxin_damage(5)
			affected_mob.updatehealth()
		if(5)
			boutput(affected_mob, "<span style=\"color:red\">Your body feels as if it's trying to rip itself open...</span>")
			if(prob(50))
				for(var/mob/O in viewers(affected_mob, null))
					O.show_message(text("<span style=\"color:red\"><B>[]</B> starts convulsing violently!</span>", affected_mob), 1)
				affected_mob.weakened = max(15, affected_mob.weakened)
				affected_mob.make_jittery(1000)
				spawn(rand(20, 100))
					if (affected_mob) affected_mob.gib()
				return
		else
			return