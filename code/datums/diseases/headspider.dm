// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/ailment/parasite/headspider
	name = "Unidentified Foreign Body"
	max_stages = 4 // takes too goddamn long
	affected_species = list("Human", "Monkey")
	cure = "Surgery"
	stage_prob = 13
	var/datum/abilityHolder/changeling/changeling = null
//

/datum/ailment/parasite/headspider/surgery(var/mob/living/surgeon, var/mob/living/affected_mob, var/datum/ailment_data/D)
	if (D.disposed)
		return 0
	var/outcome = rand(90)
	if (surgeon.bioHolder.HasEffect("training_medical"))
		outcome += 10
	var/numb = affected_mob.reagents.has_reagent("morphine") || affected_mob.sleeping
	switch (outcome)
		if (0 to 5)
			// im doctor
			surgeon.visible_message("<span style=\"color:red\"><b>[surgeon] cuts open [affected_mob] in all the wrong places!</b></span>", "You dig around in [affected_mob]'s chest and accidentally snip something important looking!")
			affected_mob.show_message("<span style=\"color:red\"><b>You feel a [numb ? "numb" : "sharp"] stabbing pain in your chest!</b></span>")
			affected_mob.TakeDamage("chest", numb ? 37.5 : 75, 0, DAMAGE_CUT)
			affected_mob.updatehealth()
			return 0
		if (6 to 15)
			surgeon.visible_message("<span style=\"color:red\"><b>[surgeon] clumsily cuts open [affected_mob]!</b></span>", "You dig around in [affected_mob]'s chest and accidentally snip something not so important looking!")
			affected_mob.show_message("<span style=\"color:red\"><b>You feel a [numb ? "mild " : " "]stabbing pain in your chest!</b></span>")
			affected_mob.TakeDamage("chest", numb ? 20 : 40, 0, 0, DAMAGE_CUT)
			affected_mob.updatehealth()
			return 0
		if (16 to 60)
			var/around_msg = ""
			var/self_msg = ""
			var/success = 0
			if (prob(50))
				around_msg = "<span style=\"color:blue\"><b>[surgeon] cuts open [affected_mob] and removes a part of the headspider.</b></span>"
				self_msg = "<span style=\"color:blue\">You remove some bits of the headspider from [affected_mob], but it quickly regrows them.</span>"
			else
				around_msg = "<span style=\"color:blue\"><b>[surgeon] cuts open [affected_mob] and removes the entire headspider.</b></span>"
				self_msg = "<span style=\"color:blue\">You remove the remaining headspider from [affected_mob].</span>"
				success = 1
			surgeon.visible_message(around_msg, self_msg)
			if (!numb)
				affected_mob.show_message("<span style=\"color:red\"><b>You feel a mild stabbing pain in your chest!</b></span>")
				affected_mob.TakeDamage("chest", 10, 0, 0, DAMAGE_STAB)
				affected_mob.updatehealth()
			return success
		if (61 to INFINITY)
			surgeon.visible_message("<span style=\"color:blue\"><b>[surgeon] cuts open [affected_mob] and removes all traces of the headspider.</b></span>", "<span style=\"color:blue\">You masterfully remove the headspider from [affected_mob].</span>")
			if (!numb)
				affected_mob.show_message("<span style=\"color:red\"><b>You feel a mild stabbing pain in your chest!</b></span>")
				affected_mob.TakeDamage("chest", 10, 0, 0, DAMAGE_STAB)
				affected_mob.updatehealth()
			return 1

/datum/ailment/parasite/headspider/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/parasite/D,var/datum/mind/changeto)
	if (..())
		return

	if (!istype(changeto, /datum/mind/) || !changeling || !istype(changeling))
		affected_mob.ailments -= D
		qdel(D)
		return

	switch(D.stage)
		if(2)
			if(prob(15))
				if(affected_mob.canmove && isturf(affected_mob.loc))
					step(affected_mob, pick(cardinal))
			if(prob(3))
				affected_mob.emote("twitch")
			if(prob(3))
				affected_mob.emote("twitch_v")
			if(prob(2))
				boutput(affected_mob, "<span style=\"color:red\">You feel strange.</span>")
				affected_mob.change_misstep_chance(5)
		if(3)
			if(prob(50))
				if(affected_mob.canmove && isturf(affected_mob.loc))
					step(affected_mob, pick(cardinal))
			if(prob(5))
				affected_mob.emote("twitch")
			if(prob(5))
				affected_mob.emote("twitch_v")
			if(prob(5))
				boutput(affected_mob, "<span style=\"color:red\">You feel very strange.</span>")
				affected_mob.change_misstep_chance(10)
			if(prob(2))
				boutput(affected_mob, "<span style=\"color:red\">Your stomach hurts.</span>")
				affected_mob.emote("groan")
		if(4)
			boutput(affected_mob, "<span style=\"color:red\">You feel something pushing at your spine...</span>")
			affected_mob.updatehealth()
			if(prob(40))
				if(changeto)
					//Take the mob under the control of the original headspider.
					// Only make a ghost for the other player if they have a client. Otherwise, infinite ghosts.
					if (affected_mob.client)
						var/mob/dead/observer/newmob = affected_mob.ghostize()
						newmob.corpse = null

					// Absorb their DNA. Copies identities and DNA points automatically if victim was another changeling.
					changeling.addDna(affected_mob, 1)

					// Remove changeling AH (if any) and copy our own.
					var/datum/abilityHolder/changeling/absorbed_ling = affected_mob.get_ability_holder(/datum/abilityHolder/changeling)
					if (absorbed_ling && istype(absorbed_ling))
						if (changeto.current)
							changeto.current.show_text("[affected_mob] was a changeling! We have incorporated their entire genetic structure.", "blue")
						affected_mob.remove_ability_holder(/datum/abilityHolder/changeling)
					affected_mob.add_existing_ability_holder(changeling)

					// Transfer player control.
					changeto.transfer_to(affected_mob)
					changeto.is_changeling = changeling
					changeto = null
					affected_mob.change_misstep_chance(-INFINITY)
					affected_mob.show_text("<h3>We have assumed control of the new host.</h3>", "blue")
					logTheThing("combat", affected_mob, null, "'s headspider successfully assumes control of new host at [log_loc(affected_mob)].")

					D.stealth_asymptomatic = 1 //Retain the disease but don't actually do anything with it
					spawn(1200) //Disease stays for two minutes after a complete infection, then it removes itself.
						affected_mob.cure_disease_by_path(/datum/ailment/parasite/headspider)

				return
