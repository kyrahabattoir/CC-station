// SPDX-License-Identifier: CC-BY-NC-SA-3.0

#define chem_building_precaution if(!total_chem_reactions || !total_chem_reactions.len) build_chem_structure()
//initialize the thing when the world starts
/proc/build_chem_structure()
	var/startTime = world.timeofday

	total_chem_reactions.Cut()
	for(var/R in (typesof(/datum/chemical_reaction) - /datum/chemical_reaction))
		var/datum/chemical_reaction/CR = new R

		if(CR.id)
			chem_reactions_by_id[CR.id] = CR

		CR.required_reagents = sortList(CR.required_reagents)
		for(var/reagent in CR.required_reagents)
			if(!total_chem_reactions[reagent]) total_chem_reactions[reagent] = list()
			total_chem_reactions[reagent] += CR

	total_chem_reactions = sortList(total_chem_reactions)

	logTheThing("debug", null, null, "<B>SpyGuy/chem_struct</B> Finished building reaction structure. Took [(world.timeofday - startTime)/10] seconds.")

/proc/build_reagent_cache()
	var/startTime = world.timeofday
	reagents_cache.Cut()
	for(var/R in (typesof(/datum/reagent) - /datum/reagent))
		var/datum/reagent/Rinstance = new R()
		//If R is not a datum/reagent then I don't think anything I can do will help here.
		reagents_cache[Rinstance.id] = Rinstance

	logTheThing("debug", null, null, "<B>SpyGuy/reagents_cache</B> Finished building reagents cache. Took [(world.timeofday - startTime)/10] seconds.")

//Things that will handle the possible options in reagents
/datum/reagents
	proc/rebuild_possible_reactions()
		chem_building_precaution
		possible_reactions.Cut()
		if(reagent_list.len)
			for(var/R in reagent_list)
				possible_reactions |= total_chem_reactions[R]

	proc/append_possible_reactions(var/reagent_id)
		chem_building_precaution
		if(total_chem_reactions[reagent_id])
			possible_reactions |= total_chem_reactions[reagent_id]
			. = 1

	proc/remove_possible_reactions(var/reagent_id)
		chem_building_precaution
		if(total_chem_reactions[reagent_id])
			possible_reactions -= total_chem_reactions[reagent_id]
			. = 1

#undef chem_building_precaution