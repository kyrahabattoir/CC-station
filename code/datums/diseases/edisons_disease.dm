// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/ailment/disease/edisons_disease
	name = "Edison's Disease"
	max_stages = 8
	spread = "Sight"
	cure = "Phthalocyanine"
	reagentcure = list("phthalocyanine")
	recureprob = 50
	stage_prob = 3
	resistance_prob = 40
	//associated_reagent = ""
	affected_species = list("Human")
	var/list/symptom_list_minor = list("brighter...", "as if it has a colored halo.", "luminescent.", "beautiful and shiny!")
	var/list/symptom_list_moderate = list("You feel hot.", "The light hurts your eyes!", "Your face stings!")
	var/list/symptom_list_severe = list("Your head is pounding!", "Your head feels like it is going to explode!", "You feel like you're about to catch on fire!", "Water... Need water...", "Your skin burns.")

	proc
		cause_blindness(var/mob/living/affected_mob)
			affected_mob.contract_disease(/datum/ailment/disability/blind, null, null, 1)
			boutput(affected_mob, "<span style=\"color:red\">The world goes white!</span>")
		update_light(var/atom/affected, var/luminosity)
			// TODO: port to the new lighting system, I have no fucking idea how I'm meant to store the light datum
			/*affected.sd_SetLuminosity(luminosity)
			affected.sd_SetColor((255 - rand(0, 40))/255, (255 - rand(10,90)) / 255, (255 - rand(15, 110)) / 255)*/

/datum/ailment/disease/edisons_disease/on_infection(var/mob/living/affected_mob,var/datum/ailment_data/D)
	boutput(affected_mob, "<span style=\"color:red\">Your eyes feel strange...</span>")

/datum/ailment/disease/edisons_disease/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return

	if(D.stage >= 2)
		if(prob(50))
			update_light(affected_mob, D.stage)

		if(D.stage < 3)
			if(prob(25))
				boutput(affected_mob, "<span style=\"color:red\">Everything looks... </span>" + pick(symptom_list_minor))
		else if(D.stage < 5)
			if(prob(25))
				boutput(affected_mob, "<span style=\"color:red\"> </span>" + pick(symptom_list_moderate))
			if(prob(5))
				cause_blindness(affected_mob)
			if(prob(5))
				affected_mob.TakeDamage("All", 0, 2, 0, DAMAGE_BURN)
				affected_mob.updatehealth()
				boutput(affected_mob, "<span style=\"color:red\">You feel hot.</span>")
		else if(D.stage < 7)
			if(prob(25))
				boutput(affected_mob, "<span style=\"color:red\"> </span>" + pick(symptom_list_severe))
			if(prob(30))
				cause_blindness(affected_mob)
			if(prob(10))
				affected_mob.TakeDamage("All", 0, 5, 0, DAMAGE_BURN)
				affected_mob.updatehealth()
				boutput(affected_mob, "<span style=\"color:red\">You feel very hot!</span>")
		else
			if(prob(80))
				cause_blindness(affected_mob)
			if(prob(20))
				affected_mob.TakeDamage("All", 0, 10, 0, DAMAGE_BURN)
				affected_mob.updatehealth()
				boutput(affected_mob, "<span style=\"color:red\">It burns!</span>")
			if(prob(50))
				// Stole this shit from GBS
				for(var/mob/O in viewers(affected_mob, null))
					O.show_message(text("<span style=\"color:red\"><B>[]</B> starts convulsing violently!</span>", affected_mob), 1)
				affected_mob.weakened = max(15, affected_mob.weakened)
				affected_mob.make_jittery(1000)
				spawn(rand(20, 100))
					if (affected_mob)
						var/list/gibs = affected_mob.gib()
						for(var/obj/decal/cleanable/gib in gibs)
							update_light(gib, rand(2,6))
				return
	else
		return