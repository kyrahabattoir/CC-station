// SPDX-License-Identifier: CC-BY-NC-SA-3.0


var/list/bioUids = new/list() //Global list of all uids and their respective mobs

var/numbersAndLetters = list("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
"r", "s", "t", "u", "v", "w", "x", "y", "z" , "0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
var/list/datum/bioEffect/bioEffectList = list()

/proc/addBio()
	var/mob/M = input(usr, "Select Mob:") as mob in world
	if(!M) return
	//if(hasvar(M, "bioHolder"))
	var/id = input(usr, "Effect ID:")
	M:bioHolder.AddEffect(id)
	return

/datum/appearanceHolder
	//Holds all the appearance information.
	var/customization_first_color = "#101010"
	var/customization_first = "Trimmed"

	var/customization_second_color = "#101010"
	var/customization_second = "None"

	var/customization_third_color = "#101010"
	var/customization_third = "None"

	var/e_color = "#101010"

	var/s_tone = 0.0

	var/underwear = "No Underwear"
	var/u_color = "#FFFFFF"

	var/mob/owner = null
	var/mob/parentHolder = null

	var/gender = NEUTER

	proc/CopyOther(var/datum/appearanceHolder/toCopy)
		//Copies settings of another given holder. Used for the bioholder copy proc and such things.
		customization_first_color = toCopy.customization_first_color
		customization_first = toCopy.customization_first

		customization_second_color = toCopy.customization_second_color
		customization_second = toCopy.customization_second

		customization_third_color = toCopy.customization_third_color
		customization_third = toCopy.customization_third

		e_color = toCopy.e_color

		s_tone = toCopy.s_tone

		underwear = toCopy.underwear
		u_color = toCopy.u_color

		gender = toCopy.gender
		return

	// Disabling this for now as I have no idea how to fit it into hex strings
	// I'm help -Spy
	proc/StaggeredCopyOther(var/datum/appearanceHolder/toCopy, var/progress = 1)
		var/adjust_denominator = 11 - progress

		//customization_first_color += (toCopy.customization_first_color - customization_first_color) / adjust_denominator
		customization_first_color = StaggeredCopyHex(customization_first_color, toCopy.customization_first_color, adjust_denominator)

		if (progress >= 9 || prob(progress * 10))
			customization_first = toCopy.customization_first
			customization_second = toCopy.customization_second
			customization_third = toCopy.customization_third

		//customization_second_color += (toCopy.customization_second_color - customization_second_color) / adjust_denominator
		customization_second_color = StaggeredCopyHex(customization_second_color, toCopy.customization_second_color, adjust_denominator)
		//customization_third_color += (toCopy.customization_third_color - customization_third_color) / adjust_denominator
		customization_third_color = StaggeredCopyHex(customization_third_color, toCopy.customization_third_color, adjust_denominator)
		//e_color += (toCopy.e_color - e_color) / adjust_denominator
		e_color = StaggeredCopyHex(e_color, toCopy.e_color, adjust_denominator)

		s_tone += (toCopy.s_tone - s_tone) / adjust_denominator

		if (progress > 7 || prob(progress * 10))
			gender = toCopy.gender
		return

	proc/StaggeredCopyHex(var/hex, var/targetHex, var/adjust_denominator)

		. = "#"
		for(var/i = 0, i < 3, i++)
			//Isolate the RGB values
			var/color = copytext(hex, 2 + (2 * i), 4 + (2 * i))
			var/targetColor = copytext(targetHex, 2 + (2 * i), 4 + (2 * i))

			//Turn them into numbers
			color = hex2num(color)
			targetColor = hex2num(targetColor)

			//Do the math and add to the output
			. += num2hex(color + ((targetColor - color) / adjust_denominator))

	proc/UpdateMob() //Rebuild the appearance of the mob from the settings in this holder.
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner

			var/list/hair_list = customization_styles + customization_styles_gimmick
			H.cust_one_state = hair_list[customization_first]

			var/list/beard_list = customization_styles + customization_styles_gimmick
			H.cust_two_state = beard_list[customization_second]

			var/list/detail_list = customization_styles + customization_styles_gimmick
			H.cust_three_state = detail_list[customization_third]

			H.gender = src.gender
			H.update_face()
			H.update_body()
			H.update_clothing()
		// if the owner's not human I don't think this would do anything anyway so fuck it
		return

/datum/bioHolder
	//Holds the apperanceholder aswell as the effects. Controls adding and removing of effects.
	var/list/effects = new/list()
	var/list/effectPool = new/list()

	var/mob/owner = null
	var/ownerName = null

	var/bloodType = "AB+-"
	var/age = 30.0
	var/genetic_stability = 100
	var/clone_generation = 0 //Get this high enough and you can be like Arnold. Maybe. I found that movie fun. Don't judge me.

	var/datum/appearanceHolder/mobAppearance = null


	var/Uid = "not initialized" //Unique id for the mob. Used for fingerprints and whatnot.

	New(var/mob/owneri)
		owner = owneri
		Uid = CreateUid()
		bioUids.Add(Uid)
		bioUids[Uid] = owner
		mobAppearance = new/datum/appearanceHolder()

		mobAppearance.owner = owner
		mobAppearance.parentHolder = src

		if(owner)
			reg_dna[Uid] = owner:real_name
			ownerName = owner:real_name

		BuildEffectPool()
		return ..()

	proc/ActivatePoolEffect(var/datum/bioEffect/E, var/overrideDNA = 0, var/grant_research = 1)
		if(!E || !effectPool[E.id] || (!E.dnaBlocks.sequenceCorrect() && !overrideDNA) || HasEffect(E.id))
			return 0

		var/datum/bioEffect/global_BE = E.get_global_instance()
		if (grant_research)
			if (global_BE.research_level < 2)
				genResearch.mutations_researched++
			global_BE.research_level = max(global_BE.research_level,3)

		//AddEffect(E.id)
		//effectPool.Remove(E)
		// changed this to transfer the instance across rather than add a copy
		// since some bioeffects have unique stuff
		effects[E.id] = E
		effectPool -= E.id
		E.owner = owner
		E.holder = src
		E.activated_from_pool = 1
		E.OnAdd()
		if(lentext(E.msgGain) > 0)
			if (E.isBad)
				boutput(owner, "<span style=\"color:red\">[E.msgGain]</span>")
			else
				boutput(owner, "<span style=\"color:blue\">[E.msgGain]</span>")

		mobAppearance.UpdateMob()
		return E

	proc/AddNewPoolEffect(var/idToAdd)
		if(HasEffect(idToAdd) || HasEffectInPool(idToAdd))
			return 0

		var/datum/bioEffect/newEffect = bioEffectList[idToAdd]
		newEffect = new newEffect.type //New new new york
		if (istype(newEffect))
			effectPool[newEffect.id] = newEffect
			newEffect.holder = src
			newEffect.owner = src.owner
			return 1

		return 0

	proc/AddRandomNewPoolEffect()
		var/list/filteredList = list()

		if (!bioEffectList || !bioEffectList.len)
			logTheThing("debug", null, null, {"<b>Genetics:</b> Tried to add new random effect to pool for
			 [owner ? "\ref[owner] [owner.name]" : "*NULL*"], but bioEffectList is empty!"})
			return 0

		for(var/T in bioEffectList)
			var/datum/bioEffect/instance = bioEffectList[T]
			if(!instance || HasEffect(T) || HasEffectInPool(T) || !instance.occur_in_genepools)
				continue

			filteredList.Add(instance)
			filteredList[instance] = instance.probability

		if(!filteredList.len)
			logTheThing("debug", null, null, {"<b>Genetics:</b> Unable to get effects for new random effect for
			 [owner ? "\ref[owner] [owner.name]" : "*NULL*"]. (filteredList.len = [filteredList.len])"})
			return 0

		var/datum/bioEffect/selectedG = pickweight(filteredList)
		var/datum/bioEffect/selectedNew = selectedG.GetCopy()
		selectedNew.dnaBlocks.ModBlocks() //Corrupt the local copy
		selectedNew.holder = src
		selectedNew.owner = src.owner
		effectPool[selectedNew.id] = selectedNew
		return 1

	proc/RemovePoolEffect(var/datum/bioEffect/E)
		if(!effectPool[E.id]) return 0
		effectPool.Remove(E.id)
		return 1

	proc/BuildEffectPool()
		var/list/filteredGood = new/list()
		var/list/filteredBad = new/list()
		var/list/filteredSecret = new/list()

		effectPool.Cut()

		if (!bioEffectList || !bioEffectList.len)
			logTheThing("debug", null, null, {"<b>Genetics:</b> Tried to build effect pool for
			 [owner ? "\ref[owner] [owner.name]" : "*NULL*"], but bioEffectList is empty!"})

		for(var/T in bioEffectList)
			var/datum/bioEffect/instance = bioEffectList[T]
			if(!instance || HasEffect(T) || !instance.occur_in_genepools) continue
			if(src.owner)
				if (src.owner.type in instance.mob_exclusion)
					continue
				if (instance.mob_exclusive && src.owner.type != instance.mob_exclusive)
					continue
			if(instance.secret)
				filteredSecret.Add(instance)
			else
				if(instance.isBad)
					filteredBad.Add(instance)
					filteredBad[instance] = instance.probability
				else
					filteredGood.Add(instance)
					filteredGood[instance] = instance.probability

		if(!filteredGood.len || !filteredBad.len)
			logTheThing("debug", null, null, {"<b>Genetics:</b> Unable to build effect pool for
			 [owner ? "\ref[owner] [owner.name]" : "*NULL*"]. (filteredGood.len = [filteredGood.len],
			  filteredBad.len = [filteredBad.len])"})
			return

		for(var/g=0, g<5, g++)
			var/datum/bioEffect/selectedG = pickweight(filteredGood)
			if(selectedG)
				var/datum/bioEffect/selectedNew = selectedG.GetCopy()
				selectedNew.dnaBlocks.ModBlocks() //Corrupt the local copy
				selectedNew.holder = src
				selectedNew.owner = src.owner
				effectPool[selectedNew.id] = selectedNew
				filteredGood.Remove(selectedG)
			else
				break

		for(var/b=0, b<5, b++)
			var/datum/bioEffect/selectedB = pickweight(filteredBad)
			if(selectedB)
				var/datum/bioEffect/selectedNew = selectedB.GetCopy()
				selectedNew.dnaBlocks.ModBlocks() //Corrupt the local copy
				selectedNew.holder = src
				selectedNew.owner = src.owner
				effectPool[selectedNew.id] = selectedNew
				filteredBad.Remove(selectedB)
			else
				break

		if (filteredSecret.len)
			var/datum/bioEffect/selectedS = pickweight(filteredSecret)
			var/datum/bioEffect/selectedNew = selectedS.GetCopy()
			selectedNew.dnaBlocks.ModBlocks() //Corrupt the local copy
			selectedNew.holder = src
			selectedNew.owner = src.owner
			effectPool[selectedNew.id] = selectedNew
			filteredBad.Remove(selectedS)

		effectPool = shuffle(effectPool)

	proc/OnLife()
		var/datum/bioEffect/BE
		for(var/curr in effects)
			BE = effects[curr]
			BE.OnLife()
			if(BE.timeLeft != -1)
				BE.timeLeft--
				if(BE.timeLeft <= 0)
					RemoveEffect(BE.id)
		return

	proc/OnMobDraw()
		var/datum/bioEffect/BE
		for(var/curr in effects)
			BE = effects[curr]
			BE.OnMobDraw()
		return

	proc/CreateUid() //Creates a new uid and returns it.
		var/newUid = ""

		do
			for(var/i = 1 to 20)
				newUid += "[pick(numbersAndLetters)]"
		while(bioUids.Find(newUid))

		return newUid

	proc/CopyOther(var/datum/bioHolder/toCopy, var/copyAppearance = 1, var/copyPool = 1, var/copyEffectBlocks = 0, var/copyActiveEffects = 1)
		//Copies the settings of another given holder. Used for syringes, the dna spread virus and such things.
		if(copyAppearance)
			mobAppearance.CopyOther(toCopy.mobAppearance)
			mobAppearance.UpdateMob()

			bloodType = toCopy.bloodType
			age = toCopy.age
			clone_generation = toCopy.clone_generation
		if(copyActiveEffects)
			effects.Cut()
			var/datum/bioEffect/BE
			for(var/curr in toCopy.effects)
				BE = toCopy.effects[curr]
				if (!BE.can_copy)
					continue

				if(HasEffect(BE.id))
					var/datum/bioEffect/newCopy = GetEffect(BE.id)
					if(!newCopy) continue

					newCopy.timeLeft = BE.timeLeft
					newCopy.variant = BE.variant
					newCopy.data = BE.data
				else
					var/datum/bioEffect/newCopy = AddEffect(BE.id)
					if(!newCopy) continue

					newCopy.timeLeft = BE.timeLeft
					newCopy.variant = BE.variant
					newCopy.data = BE.data
		return

	proc/StaggeredCopyOther(var/datum/bioHolder/toCopy, progress = 1)
		if (progress >= 10)
			return CopyOther(toCopy)

		if (mobAppearance)
			mobAppearance.StaggeredCopyOther(toCopy.mobAppearance, progress)
			mobAppearance.UpdateMob()

		if (progress >= 5)
			bloodType = toCopy.bloodType

		age += (toCopy.age - age) / (11 - progress)

	proc/AddEffect(var/idToAdd, var/variant = 0, var/timeleft = 0)
		//Adds an effect to this holder. Returns the newly created effect if succesful else 0.
		if(!owner) return

		if(HasEffect(idToAdd))
			return 0

		var/datum/bioEffect/newEffect = bioEffectList[idToAdd]
		if(!newEffect) return 0

		newEffect = new newEffect.type

		if(istype(newEffect))
			for(var/datum/bioEffect/curr_id in effects)
				var/datum/bioEffect/curr = effects[curr_id]
				if(curr && curr.type == effectTypeMutantRace && newEffect.type == effectTypeMutantRace)
					//Can only have one mutant race.
					RemoveEffect(curr.id)
					break //Since this cleaning is always done we just ousted the only mutantrace in effects

			if(variant) newEffect.variant = variant
			if(timeleft) newEffect.timeLeft = timeleft

			effects[newEffect.id] = newEffect
			newEffect.owner = owner
			newEffect.holder = src
			newEffect.OnAdd()
			src.genetic_stability -= newEffect.stability_loss
			src.genetic_stability = max(0,min(src.genetic_stability,100))
			if(lentext(newEffect.msgGain) > 0)
				if (newEffect.isBad)
					boutput(owner, "<span style=\"color:red\">[newEffect.msgGain]</span>")
				else
					boutput(owner, "<span style=\"color:blue\">[newEffect.msgGain]</span>")
			mobAppearance.UpdateMob()
			return newEffect

		return 0

	proc/AddEffectInstance(var/datum/bioEffect/BE,var/do_delay = 0)
		if (!istype(BE) || !owner || HasEffect(BE.id))
			return null

		if (do_delay && BE.add_delay > 0)
			sleep(BE.add_delay)
		effects[BE.id] = BE
		BE.owner = owner
		BE.holder = src
		BE.OnAdd()
		src.genetic_stability -= BE.stability_loss
		src.genetic_stability = max(0,min(src.genetic_stability,100))
		if(lentext(BE.msgGain) > 0)
			if (BE.isBad)
				boutput(owner, "<span style=\"color:red\">[BE.msgGain]</span>")
			else
				boutput(owner, "<span style=\"color:blue\">[BE.msgGain]</span>")
		mobAppearance.UpdateMob()
		return BE

	proc/RemoveEffect(var/id)
		//Removes an effect from this holder. Returns 1 on success else 0.
		if(!HasEffect(id)) return 0

		var/datum/bioEffect/D = effects[id]
		if(D)
			D.OnRemove()
			if (!D.activated_from_pool)
				src.genetic_stability += D.stability_loss
				src.genetic_stability = max(0,min(src.genetic_stability,100))
			if(owner && lentext(D.msgLose) > 0)
				if (D.isBad)
					boutput(owner, "<span style=\"color:blue\">[D.msgLose]</span>")
				else
					boutput(owner, "<span style=\"color:red\">[D.msgLose]</span>")
			return effects.Remove(D.id)

		return 0

	proc/RemoveAllEffects(var/type = null)
		for(var/D in effects)
			var/datum/bioEffect/BE = effects[D]
			if(BE && (isnull(type) || BE.effectType == type))
				RemoveEffect(BE.id)
		return 1

	proc/RemoveAllPoolEffects(var/type = null)
		for(var/D in effectPool)
			var/datum/bioEffect/BE = effectPool[D]
			if(BE && (isnull(type) || BE.effectType == type))
				effectPool -= BE
				qdel(BE)
		return 1

	proc/HasAnyEffect(var/type = null)
		if(type)
			for(var/D in effects)
				var/datum/bioEffect/BE = effects[D]
				if(BE && BE.effectType == type)
					return 1
		else
			return (effects.len ? 1 : 0)
		return 0

	proc/HasEffect(var/id)
		//Returns variant if this holder has an effect with the given ID else 0.
		//Returns 1 if it has the effect with variant 0, special case for limb tone.
		var/datum/bioEffect/B = effects[id]

		if(!B) return 0

		return B.variant ? B.variant : 1


	proc/HasEffectInPool(var/id)
		return !isnull(effectPool[id])

	proc/HasEffectInEither(var/id)
		var/datum/bioEffect/B = effects[id]
		if(!B)
			B = effectPool[id]
		if (!B)
			return null
		else
			return 1

	proc/HasOneOfTheseEffects() //HasAnyEffect() was already taken :I
		var/list/temp = args & effects
		if(temp.len)
			var/datum/bioEffect/BE = effects[temp[1]]
			if(BE) return BE.variant ? BE.variant : 1
		return 0

	proc/HasAllOfTheseEffects()
		var/tally = 0 //We cannot edit the args list directly, so just keep a count.
		for (var/datum/bioEffect/D in effects)
			if (lowertext(D) in args)
				tally++

		return tally >= args.len

	proc/GetEffect(var/id) //Returns the effect with the given ID if it exists else returns null.
		return effects[id]

	proc/GetEffectFromPool(var/id)
		return effectPool[id]

	proc/RandomEffect(var/type = "either", var/useProbability = 1)
		//Adds a random effect to this holder. Argument controls which type. bad , good, either.
		var/list/filtered = new/list()

		for(var/T in bioEffectList)
			var/datum/bioEffect/instance = bioEffectList[T]
			if(!instance || HasEffect(instance.id) || !instance.occur_in_genepools) continue
			switch(lowertext(type))
				if("good")
					if(instance.isBad)
						continue
				if("bad")
					if(!instance.isBad)
						continue
			filtered.Add(instance)
			filtered[instance] = instance.probability

		if(!filtered.len) return

		var/datum/bioEffect/E = null

		if(useProbability)
			E = pickweight(filtered)
		else
			E = pick(filtered)

		AddEffect(E.id)

		return E.id
/*
proc/GetBioeffectFromGlobalListByType(var/type) //This is bonkers
	if (!ispath(type))
		return null
	var/datum/bioEffect/BE
	for (var/X in bioEffectList)
		BE = bioEffectList[X]
		if (BE.type == type)
			return BE
	return null

proc/GetBioeffectResearchLevelFromGlobalListByType(var/type) //So is this
	if (!ispath(type))
		return 0
	var/datum/bioEffect/BE
	for (var/X in bioEffectList)
		BE = bioEffectList[X]
		if (BE.type == type)
			return BE.research_level
	return 0
*/

proc/GetBioeffectFromGlobalListByID(var/id)
	return bioEffectList[id]

proc/GetBioeffectResearchLevelFromGlobalListByID(var/id)
	if (!istext(id))
		return 0
	var/datum/bioEffect/BE = bioEffectList[id]

	if(istype(BE))
		. = BE.research_level
	else
		. = 0
