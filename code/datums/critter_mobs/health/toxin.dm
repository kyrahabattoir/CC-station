// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/healthHolder/toxin
	name = "toxic"
	associated_damage_type = "toxin"

	maximum_value = 0
	value = 0
	minimum_value = -200
	depletion_threshold = -200

	on_life()
		if (!holder.does_it_metabolize())
			return
		if (holder.bodytemperature < T0C - 45 && holder.reagents.has_reagent("cryoxadone"))
			HealDamage(3)