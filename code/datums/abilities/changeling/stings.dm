// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/changeling/sting
	name = "Sting"
	desc = "Transfer some toxins into your target."
	var/stealthy = 1
	var/venom_id = "toxin"
	var/inject_amount = 50
	cooldown = 900
	targeted = 1
	target_anything = 1
	sticky = 1

	cast(atom/target)
		if (..())
			return 1
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("We cannot sting without a target."))
				return 1
		if (target == holder.owner)
			return 1
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("We cannot reach that target with our stinger."))
			return 1
		var/mob/MT = target
		if (!MT.reagents)
			boutput(holder.owner, __red("That does not hold reagents, apparently."))
		if (!stealthy)
			holder.owner.visible_message(__red("<b>[holder.owner] stings [target]!</b>"))
		else
			holder.owner.show_message(__blue("We stealthily sting [target]."))
		MT.reagents.add_reagent(venom_id, inject_amount)
		logTheThing("combat", holder.owner, MT, "stings %target% with [name] as a changeling [log_loc(holder.owner)].")

	neurotoxin
		name = "Neurotoxic Sting"
		desc = "Transfer some neurotoxin into your target."
		icon_state = "stingneuro"
		venom_id = "neurotoxin"

	lsd
		name = "Hallucinogenic Sting"
		desc = "Transfer some LSD into your target."
		icon_state = "stinglsd"
		venom_id = "LSD"
		inject_amount = 30

	dna
		name = "DNA Sting"
		desc = "Injects stable mutagen and the blood of the selected victim into your target."
		icon_state = "stingdna"
		venom_id = "dna_mutagen"
		inject_amount = 15
		pointCost = 4
		var/datum/targetable/changeling/dna_target_select/targeting = null

		New()
			..()

		onAttach(var/datum/abilityHolder/H)
			targeting = H.addAbility(/datum/targetable/changeling/dna_target_select)
			targeting.sting = src
			if (H.owner)
				object.suffix = "\[[holder.owner.name]\]"

		cast(atom/target)
			if (..())
				return 1
			var/mob/MT = target
			MT.reagents.add_reagent("blood", 15, targeting.dna_sting_target)
			return 0

/datum/targetable/changeling/dna_target_select
	name = "Select DNA Sting target"
	desc = "Select target for DNA sting"
	icon_state = "stingdna"
	cooldown = 0
	targeted = 0
	target_anything = 0
	copiable = 0
	dont_lock_holder = 1
	ignore_holder_lock = 1
	var/datum/bioHolder/dna_sting_target = null
	var/datum/targetable/changeling/sting = null
	sticky = 1

	onAttach(var/datum/abilityHolder/G)
		var/datum/abilityHolder/changeling/H = G
		if (istype(H))
			dna_sting_target = H.absorbed_dna[H.absorbed_dna[1]]

	cast(atom/target)
		if (..())
			return 1

		var/datum/abilityHolder/changeling/H = holder
		if (!istype(H))
			boutput(holder.owner, __red("That ability is incompatible with our abilities. We should report this to a coder."))
			return 1

		var/target_name = input("Select new DNA sting target!", "DNA Sting Target", null) as null|anything in H.absorbed_dna
		if (!target_name)
			boutput(holder.owner, __blue("We change our mind."))
			return 1

		dna_sting_target = H.absorbed_dna[target_name]
		if (sting)
			sting.object.suffix = "\[[target_name]\]"

		return 0
