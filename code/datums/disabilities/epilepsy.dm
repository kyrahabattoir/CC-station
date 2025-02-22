// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/ailment/disability/epilepsy
	name = "Epilepsy"
	max_stages = 1
	cure = "Mutadone"
	reagentcure = list("mutadone")
	recureprob = 7
	affected_species = list("Human","Monkey")

/datum/ailment/disability/epilepsy/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return
	var/mob/living/M = D.affected_mob
	if (prob(3))
		M.visible_message("<span style=\"color:red\"><B>[M.name]</B> has a siezure!</span>")
		M.paralysis = max(3, M.paralysis)
		M.make_jittery(100)