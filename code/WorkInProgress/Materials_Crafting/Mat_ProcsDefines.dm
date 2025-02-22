// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/global/list/material_cache = list()
/atom/var/datum/material/material = null

//This contains the names of the trigger lists on materials. Required for copying materials. Remember to keep this updated if you add new triggers.
var/global/list/triggerVars = list("triggersFail", "triggersTemp", "triggersChem", "triggersPickup", "triggersDrop", "triggersExp", "triggersOnAdd", "triggersOnLife", "triggersOnAttack", "triggersOnAttacked", "triggersOnEntered")

//Returns one of the base materials by id.
/proc/getCachedMaterial(var/mat)
	if(!istext(mat) || !length(mat)) return null
	if(!material_cache.len) buildMaterialCache()
	if(material_cache.Find(mat)) return copyMaterial(material_cache[mat])
	return null

/proc/mergeProperties(var/list/l1, var/list/l2, var/bias=0.5)
	if(!l1) CRASH("SOME IDIOT TRIED TO MERGE LISTS WITHOUT PASSING LISTS TO MERGEPROPERTIES")
	var/oBias = 1 - bias

	var/list/merged = list()

	for(var/o in l1)
		merged.Add(o)
		var/datum/material_property/Base = l1[o]
		var/datum/material_property/newProp = new/datum/material_property()
		merged[o] = newProp
		newProp.name = o
		newProp.value_max = Base.value_max
		newProp.value_min = Base.value_min
		newProp.value = Base.value

	if(l2)
		for(var/x in l2)
			if(merged.Find(x))
				var/datum/material_property/Base = l2[x]
				var/datum/material_property/Modded = merged[x]
				Modded.value_min = round(Modded.value_min * oBias + Base.value_min * bias)
				Modded.value_max = round(Modded.value_max * oBias + Base.value_max * bias)
				Modded.value = round(Modded.value * oBias + Base.value * bias)
			else
				var/datum/material_property/Base = l2[x]
				var/datum/material_property/newProp = new/datum/material_property()
				merged[x] = newProp
				newProp.name = x
				newProp.value_max = Base.value_max
				newProp.value_min = Base.value_min
				newProp.value = Base.value
	return merged

//Returns a copy of a given material.
/proc/copyMaterial(var/datum/material/base)
	if(!base || !istype(base, /datum/material))
		var/datum/material/M = new/datum/material()
		return M
	else
		var/datum/material/M = new base.type ()

		var/list/copyProps = mergeProperties(base.properties)
		M.properties = copyProps

		for(var/X in base.vars)
			if(X == "type" || X == "parent_type" || X == "tag" || X == "vars" || X == "properties") continue

			if(X in triggerVars)
				M.vars[X] = getFusedTriggers(base.vars[X], list()) //Pass in an empty list to basically copy the first one.
			else
				if(M.vars.Find(X))
					if(istype(base.vars[X],/list))
						var/list/oldList = base.vars[X]
						M.vars[X] = oldList.Copy()
					else
						M.vars[X] = base.vars[X]
		return M
	return null

//Simply removes a material from an object.
/atom/proc/removeMaterial()
	if(src.mat_changename)
		src.remove_prefixes(99)
		src.remove_suffixes(99)
		src.UpdateName()
		//src.name = initial(src.name)

	if(src.mat_changedesc)
		src.desc = initial(src.desc)

	src.alpha = initial(src.alpha)
	src.color = initial(src.color)

	src.UpdateOverlays(null, "material")

	src.material = null
	return

//Time for some super verbose proc names.
/proc/get_material_trait_desc(var/datum/material/mat1)
	var/string = ""
	var/list/allTriggers = (mat1.triggersFail + mat1.triggersTemp + mat1.triggersChem + mat1.triggersPickup + mat1.triggersDrop + mat1.triggersExp + mat1.triggersOnAdd + mat1.triggersOnLife + mat1.triggersOnAttack + mat1.triggersOnAttacked + mat1.triggersOnEntered)
	for(var/datum/materialProc/P in allTriggers)
		if(length(P.desc))
			if(length(string))
				if(!findtext(string,P.desc))
					string += " " + P.desc
			else
				string = P.desc
	return string

//Sets the material of an object. PLEASE USE THIS TO SET MATERIALS UNLESS YOU KNOW WHAT YOU'RE DOING.
/atom/proc/setMaterial(var/datum/material/mat1)
	if(!mat1 ||!istype(mat1, /datum/material)) return
	var/traitDesc	  = get_material_trait_desc(mat1)
	var/strPrefix = jointext(mat1.prefixes, " ")
	var/strSuffix = jointext(mat1.suffixes, " ")
	// Setting mat_changename/desc == 0 is almost as conspicuous as having "good gold chameleon bombs".
	// Real_desc/name is a substandard implementation, but it will prevent some midas touch exploits (Convair880).
	if (src.mat_changename) // now that I've cleaned up the name prefix/suffix stuff, let's try this, in the hopes that eveything that SHOULD override UpdateName() actually DOES - Haine
		src.remove_prefixes(99) // janky but better than ending up with uhh
		src.remove_suffixes(99) // "This is a good gold good gold good gold good gold good gold good gold good gold good gold good gold good gold bedsheet."
		src.name_prefix(strPrefix ? strPrefix : "")
		src.name_prefix(length(getQualityName(mat1.quality)) ? getQualityName(mat1.quality) : "")
		src.name_prefix(mat1.name ? mat1.name : "")
		src.name_suffix(strSuffix ? "of [strSuffix]" : "")
		src.UpdateName()
/*		if (istype(src, /obj))
			var/obj/O = src
			O.name = "[strPrefix ? strPrefix + " ":""][length(getQualityName(mat1.quality)) ? getQualityName(mat1.quality) + " ":""][mat1.name ? mat1.name + " ":""][!isnull(O.real_name) ? "[O.real_name]" : "[initial(O.name)]"][strSuffix ? (" of " + strSuffix) : ""]"
		else
			src.name = "[strPrefix ? strPrefix + " ":""][length(getQualityName(mat1.quality)) ? getQualityName(mat1.quality) + " ":""][mat1.name ? mat1.name + " ":""][initial(src.name)][strSuffix ? (" of " + strSuffix) : ""]"
*/
	if (src.mat_changedesc)
		if (istype(src, /obj))
			var/obj/O2 = src
			O2.desc = "[!isnull(O2.real_desc) ? "[O2.real_desc]" : "[initial(O2.desc)]"] It is made of [mat1.name].[length(traitDesc) ? " " + traitDesc : ""]"
		else
			src.desc = "[initial(src.desc)] It is made of [mat1.name].[length(traitDesc) ? " " + traitDesc : ""]"
	if(mat1.texture)
		src.setTexture(mat1.texture, mat1.texture_blend, "material")
	src.alpha = mat1.alpha
	src.color = mat1.color
	src.material = mat1
	mat1.owner = src
	mat1.triggerOnAdd(src)
	src.onMaterialChanged()
	return

/proc/getProcessedMaterialForm(var/datum/material/MAT)
	if (!istype(MAT))
		return /obj/item/material_piece // just in case

	// higher on this list means higher priority, be careful with it!
	if (MAT.material_flags & MATERIAL_CRYSTAL)
		return /obj/item/material_piece/block
	if (MAT.material_flags & MATERIAL_METAL)
		return /obj/item/material_piece
	if (MAT.material_flags & MATERIAL_ORGANIC)
		return /obj/item/material_piece/wad
	if (MAT.material_flags & MATERIAL_CLOTH)
		return /obj/item/material_piece/cloth
	if (MAT.material_flags & MATERIAL_RUBBER)
		return /obj/item/material_piece/block
	if (MAT.material_flags & MATERIAL_ENERGY)
		return /obj/item/material_piece/sphere

	return /obj/item/material_piece

//Increases generations on material triggers and handles removal if over the generation cap.
/proc/handleTriggerGenerations(var/list/toDo)
	for(var/datum/materialProc/current in toDo)
		if(current.max_generations != -1 && (toDo[current] + 1) > current.max_generations) toDo.Remove(current)
		else toDo[current] = (toDo[current] + 1)
	return toDo

 //Fuses two material trigger lists.
/proc/getFusedTriggers(var/list/L1 , var/list/L2)
	var/list/newList = list()
	for(var/datum/materialProc/toCopy in L1) //Copy list 1 with new instances of trigger datum.
		var/datum/materialProc/P = new toCopy.type()
		newList.Add(P)	//Add new instance of datum
		newList[P] = L1[toCopy] //Set generation
		for(var/varCopy in toCopy.vars)
			if(varCopy == "type" || varCopy == "id" || varCopy == "parent_type" || varCopy == "tag" || varCopy == "vars") continue
			if(!issaved(toCopy.vars[varCopy])) continue
			P.vars[varCopy] = toCopy.vars[varCopy]

	for(var/datum/materialProc/A in L2) //Go through second list
		if((locate(A.type) in newList))	//We already have that trigger type from the other list
			var/datum/materialProc/existing = (locate(A.type) in newList) //Get the trigger datum from the other list
			if(newList[existing] <= L2[A]) continue	//If the generation of the datum that already exists is lower or equal to the new one, leave it alone.
			else newList[existing] = L2[A]			//Otherwise set the generation to the generation of the second copy because it is lower.
		else	//Trigger type isnt in the list yet.
			var/datum/materialProc/newProc = new A.type()	//Create a new instance
			newList.Add(newProc)	//Add to list
			newList[newProc] = L2[A]	//Set generation
			for(var/varCopy in A.vars)
				if(varCopy == "type" || varCopy == "id" || varCopy == "parent_type" || varCopy == "tag" || varCopy == "vars") continue
				if(!issaved(A.vars[varCopy])) continue
				newProc.vars[varCopy] = A.vars[varCopy]
	return newList

/proc/getFusedMaterial(var/datum/material/mat1,var/datum/material/mat2)
	//Merges two materials and returns result as new material.
	return getInterpolatedMaterial(mat1, mat2, 0.5)

/proc/getInterpolatedMaterial(var/datum/material/mat1,var/datum/material/mat2,var/t)
	var/ot = 1 - t
	var/datum/material/newMat = new()

	newMat.quality = round(mat1.quality * ot + mat2.quality * t)

	newMat.prefixes = (mat1.prefixes | mat2.prefixes)
	newMat.suffixes = (mat1.suffixes | mat2.suffixes)

	//newMat.name = getInterpolatedName(mat1.name, mat2.name, t)
	newMat.name = getInterpolatedName(mat1.name, mat2.name, 0.5)
	newMat.mat_id = "([mat1.mat_id]+[mat2.mat_id])"
	newMat.alpha = round(mat1.alpha * ot + mat2.alpha * t)
	newMat.color = rgb(round(GetRedPart(mat1.color) * ot + GetRedPart(mat2.color) * t), round(GetGreenPart(mat1.color) * ot + GetGreenPart(mat2.color) * t), round(GetBluePart(mat1.color) * ot + GetBluePart(mat2.color) * t))
	newMat.properties = mergeProperties(mat1.properties, mat2.properties, t)
	//--
	newMat.triggersFail = getFusedTriggers(mat1.triggersFail, mat2.triggersFail)
	newMat.triggersTemp = getFusedTriggers(mat1.triggersTemp, mat2.triggersTemp)
	newMat.triggersChem = getFusedTriggers(mat1.triggersChem, mat2.triggersChem)
	newMat.triggersPickup = getFusedTriggers(mat1.triggersPickup, mat2.triggersPickup)
	newMat.triggersDrop = getFusedTriggers(mat1.triggersDrop, mat2.triggersDrop)
	newMat.triggersExp = getFusedTriggers(mat1.triggersExp, mat2.triggersExp)
	newMat.triggersOnAdd = getFusedTriggers(mat1.triggersOnAdd, mat2.triggersOnAdd)
	newMat.triggersOnLife = getFusedTriggers(mat1.triggersOnLife, mat2.triggersOnLife)
	newMat.triggersOnAttack = getFusedTriggers(mat1.triggersOnAttack, mat2.triggersOnAttack)
	newMat.triggersOnAttacked = getFusedTriggers(mat1.triggersOnAttacked, mat2.triggersOnAttacked)
	newMat.triggersOnEntered = getFusedTriggers(mat1.triggersOnEntered, mat2.triggersOnEntered)

	handleTriggerGenerations(newMat.triggersFail)
	handleTriggerGenerations(newMat.triggersTemp)
	handleTriggerGenerations(newMat.triggersChem)
	handleTriggerGenerations(newMat.triggersPickup)
	handleTriggerGenerations(newMat.triggersDrop)
	handleTriggerGenerations(newMat.triggersExp)
	handleTriggerGenerations(newMat.triggersOnAdd)
	handleTriggerGenerations(newMat.triggersOnLife)
	handleTriggerGenerations(newMat.triggersOnAttack)
	handleTriggerGenerations(newMat.triggersOnAttacked)
	handleTriggerGenerations(newMat.triggersOnEntered)
	//--

	//Texture merging. SUPER DUPER UGLY AAAAH
	if(mat2.texture && !mat1.texture)
		newMat.texture = mat2.texture
		newMat.texture_blend = mat2.texture_blend
	else if (mat1.texture && !mat2.texture)
		newMat.texture = mat2.texture
		newMat.texture_blend = mat1.texture_blend
	else if (mat1.texture && mat2.texture)
		if(mat1.generation == mat2.generation)
			//Mat1 has higher priority in this case. Optional: implement some shitty blended texture thing. probably a bad idea.
			newMat.texture = mat1.texture
			newMat.texture_blend = mat1.texture_blend
		else
			if(mat1.generation < mat2.generation)
				newMat.texture = mat1.texture
				newMat.texture_blend = mat1.texture_blend
			else
				newMat.texture = mat2.texture
				newMat.texture_blend = mat2.texture_blend
	//

	//This is sub-optimal and only used because im dumb
	if(mat1.material_flags & MATERIAL_CRYSTAL || mat2.material_flags & MATERIAL_CRYSTAL) newMat.material_flags |= MATERIAL_CRYSTAL
	if(mat1.material_flags & MATERIAL_METAL || mat2.material_flags & MATERIAL_METAL) newMat.material_flags |= MATERIAL_METAL
	if(mat1.material_flags & MATERIAL_CLOTH || mat2.material_flags & MATERIAL_CLOTH) newMat.material_flags |= MATERIAL_CLOTH
	if(mat1.material_flags & MATERIAL_ORGANIC || mat2.material_flags & MATERIAL_ORGANIC) newMat.material_flags |= MATERIAL_ORGANIC
	if(mat1.material_flags & MATERIAL_ENERGY || mat2.material_flags & MATERIAL_ENERGY) newMat.material_flags |= MATERIAL_ENERGY
	if(mat1.material_flags & MATERIAL_RUBBER || mat2.material_flags & MATERIAL_RUBBER) newMat.material_flags |= MATERIAL_RUBBER

	newMat.parent_materials.Add(mat1)
	newMat.parent_materials.Add(mat2)

	return newMat

//Merges two material names into one.
/proc/getInterpolatedName(var/mat1, var/mat2, var/t)
	var/ot = 1 - t
	var/part1 = copytext(mat1, 1, round((length(mat1) * ot) + 0.5))
	var/part2 = copytext(mat2, round((length(mat2) * ot) + 0.5), 0)
	return capitalize(ckey("[part1][part2]"))

//Returns a string for when a material fail or breaks depending on its material flags.
/proc/getMatFailString(var/flag)
	if(flag & MATERIAL_METAL && flag & MATERIAL_CRYSTAL && flag & MATERIAL_CLOTH)
		return "frays apart into worthless dusty fibers"
	if(flag & MATERIAL_METAL && flag & MATERIAL_CRYSTAL)
		return "cracks and shatters into unworkable dust"
	if(flag & MATERIAL_CLOTH && flag & MATERIAL_CRYSTAL)
		return "shatters into useless brittle fibers"
	if(flag & MATERIAL_ENERGY && flag & MATERIAL_CRYSTAL)
		return "violently disintegrates into vapor"
	if(flag & MATERIAL_ENERGY && flag & MATERIAL_METAL)
		return "shines brightly before self-vaporizing"
	if(flag & MATERIAL_ENERGY && flag & MATERIAL_CLOTH)
		return "bursts into flames and is gone almost instantly"
	if(flag & MATERIAL_ENERGY && flag & MATERIAL_ORGANIC)
		return "catches on fire and rapidly burns to ash"
	if(flag & MATERIAL_ORGANIC)
		return "crumbles into worthless slime"
	if(flag & MATERIAL_CRYSTAL)
		return "shatters to dust and blows away"
	if(flag & MATERIAL_METAL)
		return "disintegrates into useless flakes"
	if(flag & MATERIAL_CLOTH)
		return "frays apart into useless strands"
	if(flag & MATERIAL_ENERGY)
		return "suddenly vanishes into nothingness"
	if(flag & MATERIAL_RUBBER)
		return "melts into an unworkable pile of slop"
	return "comes apart"

//Translates a material flag into a string.
/proc/getMatFlagString(var/flag)
	switch(flag)
		if(MATERIAL_CRYSTAL)
			return "Crystal"
		if(MATERIAL_METAL)
			return "Metal"
		if(MATERIAL_CLOTH)
			return "Fabric"
		if(MATERIAL_ORGANIC)
			return "Organic Matter"
		if(MATERIAL_ENERGY)
			return "Energy Source"
		if(MATERIAL_RUBBER)
			return "Rubber"
		else
			return "Unknown"
	return

//Simply returns a string for a given quality. Used as prefix for objects.
/proc/getQualityName(var/quality)
	switch(quality)
		if(-INFINITY to -101)
			return "useless"
		if(-100 to -91)
			return "atrocious"
		if(-90 to -81)
			return "wretched"
		if(-80 to -71)
			return "crap"
		if(-70 to -61)
			return "awful"
		if(-60 to -51)
			return "terrible"
		if(-50 to -41)
			return "bad"
		if(-40 to -31)
			return "shabby"
		if(-30 to -21)
			return "mediocre"
		if(-20 to -11)
			return "low-quality"
		if(-10 to -1)
			return "poor"
		if(0)
			return ""
		if(1 to 10)
			return "decent"
		if(11 to 20)
			return "fine"
		if(21 to 30)
			return "good"
		if(31 to 40)
			return "great"
		if(41 to 50)
			return "high-quality"
		if(51 to 60)
			return "excellent"
		if(61 to 70)
			return "superb"
		if(71 to 80)
			return "incredible"
		if(81 to 90)
			return "amazing"
		if(91 to 100)
			return "supreme"
		if(101 to INFINITY)
			return "perfect"
		else
			return "odd"
	return

//Checks if a material matches a recipe and returns the recipe if a match is found. returns null if nothing matches it.
/proc/matchesMaterialRecipe(var/datum/material/M)
	for(var/datum/material_recipe/R in materialRecipes)
		if(R.validate(M)) return R
	return null

//Searches the parent materials of the given material, up to a given generation, for an id.
//Useful if you want to figure out if a given material was used in the making of another material.
//Keep in mind that this can be expensive so use it only when you have to.
/proc/hasParentMaterial(var/datum/material/M, var/search_id, var/max_generations = 3)
	return searchMatTree(M, search_id, 0, max_generations)

/proc/searchMatTree(var/datum/material/M, var/id, var/current_depth, var/max_depth = 3)
	if(!M || !id) return null
	if(!M.parent_materials.len) return null
	for(var/datum/material/CM in M.parent_materials)
		if(CM.mat_id == id) return CM
		if(current_depth + 1 <= max_depth)
			var/temp = searchMatTree(CM, id, current_depth + 1, max_depth)
			if(temp) return temp
	return null

//Yes hello apparently we need a proc for this because theres a million types of different wires and cables.
/proc/applyCableMaterials(var/atom/C, var/datum/material/insulator, var/datum/material/conductor)
	if(!conductor) return // silly

	if(istype(C, /obj/cable))
		var/obj/cable/cable = C
		cable.insulator = insulator
		cable.conductor = conductor

		if (cable.insulator)
			cable.setMaterial(copyMaterial(cable.insulator))
			cable.name = "[cable.insulator.name]-insulated [cable.conductor.name]-cable"
			cable.color = cable.insulator.color
		else
			cable.setMaterial(copyMaterial(cable.conductor))
			cable.name = "uninsulated [cable.conductor.name]-cable"
			cable.color = cable.conductor.color

	if(istype(C, /obj/item/cable_coil))
		var/obj/item/cable_coil/coil = C

		coil.insulator = insulator
		coil.conductor = conductor

		if (coil.insulator)
			coil.setMaterial(copyMaterial(coil.insulator))
			coil.color = coil.insulator.color
		else
			coil.setMaterial(copyMaterial(coil.conductor))
			coil.color = coil.conductor.color
		coil.updateName()