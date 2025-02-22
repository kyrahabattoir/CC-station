// SPDX-License-Identifier: CC-BY-NC-SA-3.0

//Contains base elements / reagents.
datum/reagent/aluminium
	name = "aluminium"
	id = "aluminium"
	description = "A silvery white and ductile member of the boron group of chemical elements."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255


datum/reagent/barium
	name = "barium"
	id = "barium"
	description = "A highly reactive element."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255


datum/reagent/bromine
	name = "bromine"
	id = "bromine"
	description = "A red-brown liquid element."
	fluid_r = 150
	fluid_g = 50
	fluid_b = 50
	transparency = 50


datum/reagent/carbon
	name = "carbon"
	id = "carbon"
	description = "A chemical element critical to organic chemistry."
	fluid_r = 0
	fluid_g = 0
	fluid_b = 0
	hygiene_value = -0.5
	transparency = 255

datum/reagent/carbon/reaction_turf(var/turf/T, var/volume)
	src = null
	if(istype(T, /turf/space))
		return
	if(volume < 5)
		return
	if(locate(/obj/decal/cleanable/dirt) in T)
		return
	new /obj/decal/cleanable/dirt(T)
	return


datum/reagent/chlorine
	name = "chlorine"
	id = "chlorine"
	description = "A chemical element."
	reagent_state = REAGENT_GAS
	fluid_r = 220
	fluid_g = 255
	fluid_b = 160
	transparency = 60
	penetrates_skin = 1

datum/reagent/chlorine/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	M.TakeDamage("chest", 0, 1, 0, DAMAGE_BURN)
	M.updatehealth()
	..(M)
	return

datum/reagent/chlorine/on_plant_life(var/obj/machinery/plantpot/P)
	P.HYPdamageplant("poison",3)
	return

datum/reagent/chromium
	name = "chromium"
	id = "chromium"
	description = "A catalytic chemical element."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255
	penetrates_skin = 0


datum/reagent/copper
	name = "copper"
	id = "copper"
	description = "A chemical element."
	fluid_r = 184
	fluid_g = 115
	fluid_b = 51
	transparency = 255
	penetrates_skin = 0


datum/reagent/fluorine
	name = "fluorine"
	id = "fluorine"
	description = "A highly-reactive chemical element."
	reagent_state = REAGENT_GAS
	fluid_r = 255
	fluid_g = 215
	fluid_b = 160
	transparency = 60
	penetrates_skin = 1

datum/reagent/fluorine/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	M.take_toxin_damage(1) // buffin this because fluorine is horrible - adding a burn effect
	M.TakeDamage("chest", 0, 1, 0, DAMAGE_BURN)
	M.updatehealth()
	..(M)
	return

datum/reagent/fluorine/on_plant_life(var/obj/machinery/plantpot/P)
	P.HYPdamageplant("poison",3)
	return


datum/reagent/ethanol
	name = "ethanol"
	id = "ethanol"
	description = "A well-known alcohol with a variety of applications."
	reagent_state = REAGENT_LIQUID
	fluid_r = 255
	fluid_b = 255
	fluid_g = 255
	transparency = 5
	addiction_prob = 4
	overdose = 100 // ethanol poisoning

datum/reagent/ethanol/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom

	var/mob/living/carbon/human/H = M

	if (!H.bioHolder.HasEffect("resist_alcohol"))
		if (holder.get_reagent_amount(src.id) >= 75)
			if(prob(10)) H.emote(pick("hiccup", "burp", "mumble", "grumble"))
			H.stuttering += 1
			if (H.canmove && isturf(H.loc) && prob(10))
				step(H, pick(cardinal))
			if (prob(20)) H.make_dizzy(rand(3,5))
		if (holder.get_reagent_amount(src.id) >= 125)
			if(prob(10)) H.emote(pick("hiccup", "burp"))
			if (prob(10)) H.stuttering += rand(1,10)
		if (holder.get_reagent_amount(src.id) >= 225)
			if(prob(10))
				H.emote(pick("hiccup", "burp"))
			if (prob(15))
				H.stuttering += rand(1,10)
			if (H.canmove && isturf(H.loc) && prob(8))
				step(H, pick(cardinal))
		if (holder.get_reagent_amount(src.id) >= 275)
			if(prob(10))
				H.emote(pick("hiccup", "fart", "mumble", "grumble"))
			H.stuttering += 1
			if (prob(33))
				H.change_eye_blurry(10, 50)
			if (H.canmove && isturf(H.loc) && prob(15))
				step(H, pick(cardinal))
			if(prob(4))
				H.change_misstep_chance(20)
			if(prob(6))
				H.visible_message("<span style=\"color:red\">[H] pukes all over \himself.</span>")
				playsound(H.loc, 'sound/effects/splat.ogg', 50, 1)
				new /obj/decal/cleanable/vomit(H.loc)
			if(prob(15))
				H.make_dizzy(5)
		if (holder.get_reagent_amount(src.id) >= 300)
			H.change_eye_blurry(10, 50)
			if(prob(6)) H.drowsyness += 5
			if(prob(5)) H.take_toxin_damage(rand(1,2))
		H.updatehealth()
	..(M)
	return

datum/reagent/ethanol/do_overdose(var/severity, var/mob/M)
	if(ishuman(M))
		return
	if(M.bioHolder.HasEffect("resist_alcohol"))//TEST THIS
		return
	..()
	return


datum/reagent/hydrogen
	name = "hydrogen"
	id = "hydrogen"
	description = "A colorless, odorless, nonmetallic, tasteless, highly combustible diatomic gas."
	reagent_state = REAGENT_GAS
	fluid_r = 202
	fluid_g = 254
	fluid_b = 252
	transparency = 20

datum/reagent/iodine
	name = "iodine"
	id = "iodine"
	description = "A purple gaseous element."
	reagent_state = REAGENT_GAS
	fluid_r = 127
	fluid_g = 0
	fluid_b = 255
	transparency = 50


datum/reagent/iron
	name = "iron"
	id = "iron"
	description = "Pure iron is a metal."
	fluid_r = 145
	fluid_g = 135
	fluid_b = 135
	transparency = 255
	pathogen_nutrition = list("iron")


datum/reagent/lithium
	name = "lithium"
	id = "lithium"
	description = "A chemical element."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255

datum/reagent/lithium/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	if(M.canmove && isturf(M.loc))
		step(M, pick(cardinal))
	if(prob(5))
		M.emote(pick("twitch","drool","moan"))
	..(M)
	return


datum/reagent/magnesium
	name = "magnesium"
	id = "magnesium"
	description = "A hot-burning chemical element."
	fluid_r = 255
	fluid_g = 255
	fluid_b = 255
	transparency = 255

datum/reagent/magnesium/reaction_turf(var/turf/T, var/volume)
	src = null
	if (volume < 10)
		return
	if (locate(/obj/decal/cleanable/magnesiumpile) in T)
		return
	new /obj/decal/cleanable/magnesiumpile(T)
	return


datum/reagent/mercury
	name = "mercury"
	id = "mercury"
	description = "A chemical element."
	reagent_state = REAGENT_LIQUID
	fluid_r = 160
	fluid_g = 160
	fluid_b = 160
	transparency = 255
	penetrates_skin = 1
	touch_modifier = 0.2
	depletion_rate = 0.2

datum/reagent/mercury/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	if(prob(70))
		M.take_brain_damage(1)
	..(M)
	return

datum/reagent/mercury/on_plant_life(var/obj/machinery/plantpot/P)
	P.HYPdamageplant("poison",1)
	return


datum/reagent/nickel
	name = "nickel"
	id = "nickel"
	description = "Not actually a coin."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255


datum/reagent/nitrogen
	name = "nitrogen"
	id = "nitrogen"
	description = "A colorless, odorless, tasteless gas."
	reagent_state = REAGENT_GAS
	fluid_r = 202
	fluid_g = 254
	fluid_b = 252
	transparency = 20
	pathogen_nutrition = list("nitrogen")


datum/reagent/oxygen
	name = "oxygen"
	id = "oxygen"
	description = "A colorless, odorless gas."
	reagent_state = REAGENT_GAS
	fluid_r = 202
	fluid_g = 254
	fluid_b = 252
	transparency = 20


datum/reagent/phosphorus
	name = "phosphorus"
	id = "phosphorus"
	description = "A chemical element."
	fluid_r = 150
	fluid_g = 110
	fluid_b = 110
	transparency = 255

datum/reagent/phosphorus/on_plant_life(var/obj/machinery/plantpot/P)
	if (prob(66))
		P.growth++
	return


datum/reagent/plasma
	name = "plasma"
	id = "plasma"
	description = "The liquid phase of an unusual extraterrestrial compound."
	reagent_state = REAGENT_LIQUID

	fluid_r = 130
	fluid_g = 40
	fluid_b = 160
	transparency = 222

datum/reagent/plasma/reaction_temperature(exposed_temperature, exposed_volume)
	if(exposed_temperature < T0C + 100)
		return
	fireflash(get_turf(holder.my_atom), min(max(0,volume/10),8))
	if(holder)
		holder.del_reagent(id)
	return

datum/reagent/plasma/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	if(holder.has_reagent("epinephrine"))
		holder.remove_reagent("epinephrine", 2)
	M.take_toxin_damage(1)
	M.updatehealth()
	..(M)
	return

datum/reagent/plasma/reaction_mob(var/mob/M, var/method=REAC_TOUCH, var/volume)
	src = null
	if(method != REAC_TOUCH)
		return
	var/mob/living/L = M
	if(istype(L) && L.burning)
		L.update_burning(30)
	return

datum/reagent/plasma/reaction_obj(var/obj/O, var/volume)
	src = null
	return

datum/reagent/plasma/reaction_turf(var/turf/T, var/volume)
	src = null
	return

datum/reagent/plasma/on_plant_life(var/obj/machinery/plantpot/P)
	var/datum/plant/growing = P.current
	if (growing.growthmode == "plasmavore")
		return
	P.HYPdamageplant("poison",2)
	return


datum/reagent/platinum
	name = "platinum"
	id = "platinum"
	description = "Shiny."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255


datum/reagent/potassium
	name = "potassium"
	id = "potassium"
	description = "A soft, low-melting solid that can easily be cut with a knife. Reacts violently with water."
	fluid_r = 190
	fluid_g = 190
	fluid_b = 190
	transparency = 255

datum/reagent/potassium/on_plant_life(var/obj/machinery/plantpot/P)
	if (prob(40))
		P.growth++
		P.health++
	return


datum/reagent/silicon
	name = "silicon"
	id = "silicon"
	description = "A tetravalent metalloid, silicon is less reactive than its chemical analog carbon."
	fluid_r = 120
	fluid_g = 140
	fluid_b = 150
	transparency = 255


datum/reagent/silver
	name = "silver"
	id = "silver"
	description = "A lustrous metallic element regarded as one of the precious metals."
	fluid_r = 200
	fluid_g = 200
	fluid_b = 200
	transparency = 255
	taste = "metallic"


datum/reagent/sulfur
	name = "sulfur"
	id = "sulfur"
	description = "A foul smelling chemical element."
	fluid_r = 255
	fluid_g = 255
	fluid_b = 0
	transparency = 255


datum/reagent/sugar
	name = "sugar"
	id = "sugar"
	description = "This white, odorless, crystalline powder has a pleasing, sweet taste."
	fluid_r = 255
	fluid_g = 255
	fluid_b = 255
	transparency = 255
	overdose = 200
	pathogen_nutrition = list("sugar")
	taste = "sweet"
	var/remove_buff = 0

datum/reagent/sugar/pooled()
	..()
	remove_buff = 0
	return

datum/reagent/sugar/on_add()
	if(!istype(holder))
		return
	if(!istype(holder.my_atom))
		return
	if(!hascall(holder.my_atom,"add_stam_mod_regen"))
		return
	remove_buff = holder.my_atom:add_stam_mod_regen("consumable_good", 2)
	return

datum/reagent/sugar/on_remove()
	if(!remove_buff)
		return
	if(!istype(holder))
		return
	if(!istype(holder.my_atom))
		return
	if(!hascall(holder.my_atom,"add_stam_mod_regen"))
		return
	holder.my_atom:remove_stam_mod_regen("consumable_good")
	return

datum/reagent/sugar/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom

	M.make_jittery(2)
	M.drowsyness = max(M.drowsyness-5, 0)
	if(prob(50))
		if(M.paralysis) M.paralysis--
		if(M.stunned) M.stunned--
		if(M.weakened) M.weakened--
	if(prob(4))
		M.reagents.add_reagent("epinephrine", 1.2) // let's not metabolize into meth anymore
	//if(prob(2))
		//M.reagents.add_reagent("cholesterol", rand(1,3))
	..(M)
	return

datum/reagent/sugar/do_overdose(var/severity, var/mob/M)
	if(!M)
		M = holder.my_atom

	if (M:bioHolder && M:bioHolder.HasEffect("bee"))

		var/obj/item/reagent_containers/food/snacks/ingredient/honey/honey = new /obj/item/reagent_containers/food/snacks/ingredient/honey(get_turf(M))
		if (honey.reagents)
			honey.reagents.maximum_volume = 50

		honey.name = "human honey"
		honey.desc = "Uhhhh.  Uhhhhhhhhhhhhhhhhhhhh."
		M.reagents.trans_to(honey, 50)
		M.visible_message("<b>[M]</b> regurgitates a blob of honey! Gross!")
		playsound(M.loc, 'sound/effects/splat.ogg', 50, 1)
		M.reagents.del_reagent(src.id)

		var/beeMax = 15
		for (var/obj/critter/domestic_bee/responseBee in range(7, M))
			if (!responseBee.alive)
				continue

			if (beeMax-- < 0)
				break

			responseBee.visible_message("<b>[responseBee]</b> [ pick("looks confused.", "appears to undergo a metaphysical crisis.  What is human?  What is space bee?<br>Or it might just have gas.", "looks perplexed.", "bumbles in a confused way.", "holds out its forelegs, staring into its little bee-palms and wondering what is real.") ]")
	else
		if (!M.paralysis)
			boutput(M, "<span style=\"color:red\">You pass out from hyperglycemic shock!</span>")
			M.emote("collapse")
			M.paralysis += 3 * severity
			M.weakened += 4 * severity

		if (prob(8))
			M.take_toxin_damage(severity)
			M.updatehealth()
	return


//WHY IS SWEET ***TEA*** A SUBTYPE OF SUGAR?!?!?!?!
//Because it's REALLY sweet
datum/reagent/sugar/sweet_tea
	name = "sweet tea"
	id = "sweet_tea"
	description = "A solution of sugar and tea, popular in the American South.  Some people raise the sugar levels in it to the point of saturation and beyond."
	reagent_state = REAGENT_LIQUID
	fluid_r = 139
	fluid_g = 90
	fluid_b = 54
	transparency = 235
	thirst_value = 1


datum/reagent/helium
	name = "helium"
	id = "helium"
	description = "A chemical element."
	reagent_state = REAGENT_GAS
	fluid_r = 255
	fluid_g = 250
	fluid_b = 160
	transparency = 155
	data = null

datum/reagent/helium/on_add(var/mob/M)
	if(!M)
		M = holder.my_atom
	if(!ishuman(M))
		return

	if(M.bioHolder && M.bioHolder.HasEffect("quiet_voice"))
		data = 1
	else
		data = 0
	if(data == 1)
		return
	else
		M.bioHolder.AddEffect("quiet_voice")
	return

datum/reagent/helium/on_remove(var/mob/M)
	if(!M)
		M = holder.my_atom
	if(!ishuman(M))
		return

	if(M.bioHolder && M.bioHolder.HasEffect("quiet_voice") && data == 1)
		return
	else
		M.bioHolder.RemoveEffect("quiet_voice")
	return


datum/reagent/radium
	name = "radium"
	id = "radium"
	description = "Radium is an alkaline earth metal. It is highly radioactive."
	fluid_r = 220
	fluid_g = 220
	fluid_b = 220
	transparency = 255
	penetrates_skin = 1
	touch_modifier = 0.5 //Half the dose lands on the floor
	blob_damage = 1

datum/reagent/radium/New()
	..()
	if(prob(10))
		description += " Keep away from forums."

datum/reagent/radium/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	M.irradiate(4,1, 80)
	..(M)
	return

datum/reagent/radium/reaction_turf(var/turf/T, var/volume)
	src = null
	if(!istype(T, /turf/space) && !(locate(/obj/decal/cleanable/greenglow) in T))
		new /obj/decal/cleanable/greenglow(T)
	return

datum/reagent/radium/on_plant_life(var/obj/machinery/plantpot/P)
	if (prob(80))
		P.HYPdamageplant("radiation",3)
	if (prob(16))
		P.HYPmutateplant(1)
	return


datum/reagent/sodium
	name = "sodium"
	id = "sodium"
	description = "A soft, silvery-white, highly reactive alkali metal."
	fluid_r = 200
	fluid_g = 200
	fluid_b = 200
	transparency = 255
	pathogen_nutrition = list("sodium")


datum/reagent/uranium
	name = "uranium"
	id = "uranium"
	description = "A radioactive heavy metal commonly used for nuclear fission reactions."
	fluid_r = 40
	fluid_g = 40
	fluid_b = 40
	transparency = 255

datum/reagent/uranium/on_mob_life(var/mob/M)
	if(!M)
		M = holder.my_atom
	M.irradiate(2,1)
	..(M)
	return

datum/reagent/uranium/on_plant_life(var/obj/machinery/plantpot/P)
	P.HYPdamageplant("radiation",2)
	if (prob(24))
		P.HYPmutateplant(1)
	return


datum/reagent/water
	name = "water"
	id = "water"
	description = "A ubiquitous chemical substance that is composed of hydrogen and oxygen."
	reagent_state = REAGENT_LIQUID
	fluid_r = 10
	fluid_g = 254
	fluid_b = 254
	transparency = 50
	pathogen_nutrition = list("water")
	thirst_value = 3
	hygiene_value = 1.33
	taste = "bland"

datum/reagent/water/on_mob_life(var/mob/living/carbon/human/H)
	..()
	if (!istype(H))
		return
	if (H.sims)
		H.sims.affectMotive("bladder", -0.5)

datum/reagent/water/reaction_temperature(exposed_temperature, exposed_volume) //Just an example.
	if(exposed_temperature < T0C)
		var/prev_vol = volume
		volume = 0
		if(holder)
			holder.add_reagent("ice", prev_vol, null, (T0C - 1))
		if(holder)
			holder.del_reagent(id)
	else if (exposed_temperature > T0C && exposed_temperature <= T0C + 100 )
		name = "water"
		description = initial(description)
	else if (exposed_temperature > (T0C + 100) )
		name = "steam"
		description = "Water turned steam."
		if (holder.my_atom && holder.my_atom.is_open_container())
			//boil off
			var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
			smoke.set_up(1, 0, get_turf(holder.my_atom))
			smoke.start()

			holder.my_atom.visible_message("The water boils off.")
			holder.del_reagent(src.id)

	return

datum/reagent/water/reaction_turf(var/turf/target, var/volume)
	var/mytemp = holder.total_temperature
	src = null
	// drsingh attempted fix for undefined variable /turf/space/var/wet
	var/turf/simulated/T = target
	if (volume >= 3 && istype(T))
		if (istext(T.wet))
			T.wet = text2num(T.wet)
		if (T.wet >= 1) return

		if (mytemp <= (T0C - 150)) //Ice
			T.wet = 2
		else if (mytemp > (T0C + 100) )
			return //The steam. It does nothing!!!
		else
			T.wet = 1

		if (!T.wet_overlay)
			T.wet_overlay = image('icons/effects/water.dmi',T,"wet_floor")
		T.UpdateOverlays(T.wet_overlay, "wet_overlay")

		spawn(800)
			if (istype(T))
				T.wet = 0
				T.UpdateOverlays(null, "wet_overlay")

	var/obj/hotspot = (locate(/obj/hotspot) in T)
	if(hotspot && T.air)
		var/datum/gas_mixture/lowertemp = T.remove_air( T.air.total_moles() )
		lowertemp.temperature = max( min(lowertemp.temperature-2000,lowertemp.temperature / 2) ,0)
		lowertemp.react()
		T.assume_air(lowertemp)
		hotspot.disposing() // have to call this now to force the lighting cleanup
		pool(hotspot)
	return

datum/reagent/water/reaction_obj(var/obj/item/O, var/volume)
	src = null
	if(!istype(O))
		return
	if(prob(40))
		if(O.burning)
			O.burning = 0
	return

datum/reagent/water/reaction_mob(var/mob/M, var/method=REAC_TOUCH, var/volume)
	..()
	src = null
	if(!volume)
		volume = 10
	if(method != REAC_TOUCH)
		return
	if(!isliving(M))
		return

	var/mob/living/L = M
	if(istype(L) && L.burning)
		L.update_burning(-volume)
	return


datum/reagent/water/water_holy
	name = "holy water"
	id = "water_holy"
	description = "Blessed water, supposedly effective against evil."
	thirst_value = 2
	hygiene_value = 2
	value = 3 // 1 1 1

datum/reagent/water/water_holy/reaction_mob(var/mob/target, var/method=REAC_TOUCH, var/volume)
	..()
	var/mob/living/carbon/human/M = target
	if(istype(M))
		if (isvampire(M))
			M.emote("scream")
			for(var/mob/O in AIviewers(M, null))
				O.show_message(text("<span style=\"color:red\"><b>[] begins to crisp and burn!</b></span>", M), 1)
			boutput(M, "<span style=\"color:red\">Holy Water! It burns!</span>")
			var/burndmg = volume * 1.25
			M.TakeDamage("chest", 0, burndmg, 0, DAMAGE_BURN)
			M.change_vampire_blood(-burndmg)
			M.updatehealth()
		else if (method == REAC_TOUCH)
			boutput(M, "<span style=\"color:blue\">You feel somewhat purified... but mostly just wet.</span>")
			M.take_brain_damage(-10)
			for (var/datum/ailment_data/disease/V in M.ailments)
				if(prob(1))
					M.cure_disease(V)
	if(method != REAC_TOUCH)
		return
	if(!isliving(target))
		return
	var/mob/living/L = target
	if(istype(L) && L.burning)
		L.update_burning(-25)
	return


datum/reagent/water/tonic
	name = "tonic water"
	id = "tonic"
	description = "Carbonated water with quinine for a bitter flavor. Protects against Space Malaria."
	reagent_state = REAGENT_LIQUID
	thirst_value = 1.5
	hygiene_value = 0.75
	taste = "bitter"

datum/reagent/water/tonic/reaction_temperature(exposed_temperature, exposed_volume) //Just an example.
	if(exposed_temperature <= T0C)
		name = "tonic ice"
		description = "Frozen water with quinine for a bitter flavor. That is, if you eat ice cubes.  Weirdo."
	else if (exposed_temperature > T0C + 100)
		name = "tonic steam"
		description = "Water turned steam. Steam that protects against Space Malaria."
		if (holder.my_atom && holder.my_atom.is_open_container())
			//boil off
			var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
			smoke.set_up(1, 0, get_turf(holder.my_atom))
			smoke.start()

			holder.my_atom.visible_message("The water boils off.")
			holder.del_reagent(src.id)
	else
		name = "Tonic water"
		description = "Carbonated water with quinine for a bitter flavor. Protects against Space Malaria."
	return


datum/reagent/ice
	name = "ice"
	id = "ice"
	description = "It's frozen water. What did you expect?!"
	fluid_r = 200
	fluid_g = 200
	fluid_b = 250
	transparency = 200
	taste = "cold"

datum/reagent/ice/reaction_temperature(exposed_temperature, exposed_volume)
	if(exposed_temperature > T0C)
		var/prev_vol = volume
		volume = 0
		if(holder)
			holder.add_reagent("water", prev_vol, null, T0C + 1)
		if(holder)
			holder.del_reagent(id)
	return

datum/reagent/ice/reaction_obj(var/obj/O, var/volume)
	src = null
	return

datum/reagent/ice/reaction_turf(var/turf/T, var/volume)
	src = null
	if(volume < 5)
		return
	if(locate(/obj/item/raw_material/ice))
		return
	new /obj/item/raw_material/ice(T)
	return


datum/reagent/phenol
	name = "phenol"
	id = "phenol"
	description = "Also known as carbolic acid, this is a useful building block in organic chemistry."
	fluid_r = 180
	fluid_g = 180
	fluid_b = 180
	transparency = 35
	value = 5 // 3c + 1c + 1c
