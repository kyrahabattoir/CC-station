// SPDX-License-Identifier: CC-BY-NC-SA-3.0


/obj/item/seed/
	name = "plant seed"
	desc = "Plant this in soil to grow something."
	icon = 'icons/obj/hydroponics/hydromisc.dmi'
	icon_state = "seeds"
	var/seedcolor = "#000000"
	w_class = 1.0
	var/auxillary_datum = null
	var/datum/plant/planttype = null
	var/datum/plantgenes/plantgenes = null
	var/seeddamage = 0 // This is used mostly for infusions. How likely a seed is to be destroyed.
	var/isstrange = 0  // Seeds cannot be gene scanned if they're strange seeds.
	var/generation = 0 // Keeps track of how many times a plant has been bred from the initial seed.
	stamina_damage = 1
	stamina_cost = 1
	module_research = list("hydroponics" = 1, "efficiency" = 1)
	module_research_type = /obj/item/seed
	rand_pos = 1

	New(var/loc,var/do_color = 1)
		..()
		src.plantgenes = new /datum/plantgenes(src)
		// Set up the base genes. Note we don't need to set up the planttype here - that's because
		// the setup for that is automatically handled during spawning a seed from the vendor or
		// harvesting a plant or what-have-you.
		// Scatter the seed's sprite around a bit so you can make big ol' piles of them.
		if (src.auxillary_datum && !src.planttype)
			src.planttype = new src.auxillary_datum(src)
		if (do_color)
			src.plant_seed_color(src.seedcolor)
		// Colors in the seed packet, if we want to do that. Any seed that doesn't use the
		// standard seed packet sprite shouldn't do this or it'll end up looking stupid.

	proc/generic_seed_setup(var/datum/plant/P)
		// This proc is pretty much entirely for regular seeds you find from the vendor
		// or harvest, stuff like artifact seeds generally shouldn't be calling this.
		if (!P)
			qdel(src)
			return
			// Sanity check. If the seed is of a null species it could cause trouble, so we
			// just get rid of the seed and don't do anything else.
		//var/datum/plant/Pl = new P.type(src)
		var/datum/plant/species = HY_get_species_from_path(P.type)
		if (!src.planttype)
			if (!species)
				if (src.auxillary_datum)
					src.planttype = new src.auxillary_datum(src)
				else
					qdel(src)
					return
			else
				src.planttype = species
		if (src.planttype)
			src.name = "[P.name] seed"
			src.plant_seed_color(P.seedcolor)
			// Calls on a variable in the referenced plant datum to get the seed packet's color.

	proc/plant_seed_color(var/colorRef)
		// A small proc which usually takes the color reference from a plant datum and uses
		// it to color in the seed packet so you can recognise the packets at a glance.
		if (!colorRef) return
		if (!src.artifact)
			var/icon/I = new /icon('icons/obj/hydroponics/hydromisc.dmi',"seeds-ovl")
			I.Blend(colorRef, ICON_ADD)
			src.overlays += I

	proc/HYPinfusionS(var/reagent,var/obj/submachine/seed_manipulator/M)
		// The proc for when the manipulator is infusing seeds with a reagent. This is sort of a
		// framing proc simply to check if the seed is in good enough condition to withstand the
		// infusion or not - the actual gameplay effects are handled in a different proc:
		// proc/HYPinfusionP, /datums/plants.dm, line 115
		// Note that this continues down the chain and checks the proc for individual plant
		// datums after it's finished executing the base plant datum infusion proc.

		if (!src) return 1 // Error code 1 - seed destroyed/lost
		if (!reagent) return 2 // Error code 2 - reagent not found
		if (!M) return 3 // Error code 3 - we don't know what the fuck went wrong tbh
		src.seeddamage += rand(3,7) // Infusing costs a little bit of the seed's health
		if (src.seeddamage > 99 || !src.planttype || !src.plantgenes)
			M.seeds -= src
			qdel(src)
			return 1
			// Whoops, you did it too often and now the seed broke. Good job doofus!!

		var/datum/plant/P = src.planttype
		if (P.HYPinfusionP(src,reagent) == 99)
			// The proc call both executes the infusion on the species AND performs a check -
			// The check is for a return value of 99, basically an error code for "Whoops you
			// destroyed the seed you dumbass".
			M.seeds -= src
			qdel(src)
			return 1 // We'll want to tell the manipulator that so it can inform the user, too.
		else
			return 0 // Passes an "Everything went fine" code to the manipulator.

/obj/item/seed/grass/
	name = "grass seed"
	seedcolor = "#CCFF99"
	auxillary_datum = /datum/plant/grass

/obj/item/seed/maneater/
	name = "strange seed"
	auxillary_datum = /datum/plant/maneater

/obj/item/seed/creeper/
	name = "creeper seed"
	seedcolor = "#CC00FF"
	auxillary_datum = /datum/plant/creeper

/obj/item/seed/crystal/
	name = "crystal seed"
	seedcolor = "#DDFFFF"
	auxillary_datum = /datum/plant/crystal

/obj/item/seed/cannabis/
	name = "cannabis seed"
	seedcolor = "#00FF00"
	auxillary_datum = /datum/plant/cannabis

// weird alien plants

/obj/item/seed/alien
	name = "strange seed"
	isstrange = 1

	New()
		if (src.type == /obj/item/seed/alien)
			// let's make the base seed randomise itself for fun and also for functionality
			switch(rand(1,5))
				if (1) src.planttype = HY_get_species_from_path(/datum/plant/artifact/pukeplant)
				if (2) src.planttype = HY_get_species_from_path(/datum/plant/artifact/dripper)
				if (3) src.planttype = HY_get_species_from_path(/datum/plant/artifact/rocks)
				if (4) src.planttype = HY_get_species_from_path(/datum/plant/artifact/litelotus)
				if (5) src.planttype = HY_get_species_from_path(/datum/plant/artifact/peeker)
		..()

/obj/item/seed/alien/pukeplant
	New()
		..()
		src.planttype = HY_get_species_from_path(/datum/plant/artifact/pukeplant)

/obj/item/seed/alien/dripper
	New()
		..()
		src.planttype = HY_get_species_from_path(/datum/plant/artifact/dripper)

/obj/item/seed/alien/rocks
	New()
		..()
		src.planttype = HY_get_species_from_path(/datum/plant/artifact/rocks)

/obj/item/seed/alien/litelotus
	New()
		..()
		src.planttype = HY_get_species_from_path(/datum/plant/artifact/litelotus)

/obj/item/seed/alien/peeker
	New()
		..()
		src.planttype = HY_get_species_from_path(/datum/plant/artifact/peeker)
