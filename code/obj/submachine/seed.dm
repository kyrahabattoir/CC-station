// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/submachine/seed_manipulator/
	name = "PlantMaster Mk3"
	desc = "An advanced machine used for manipulating the genes of plant seeds. It also features an inbuilt seed extractor."
	density = 1
	anchored = 1
	mats = 10
	icon = 'icons/obj/objects.dmi'
	icon_state = "geneman-on"
	flags = NOSPLASH
	var/mode = "overview"
	var/list/seeds = list()
	var/seedfilter = null
	var/seedoutput = 1
	var/dialogue_open = 0
	var/obj/item/seed/splicing1 = null
	var/obj/item/seed/splicing2 = null
	var/list/extractables = list()
	var/obj/item/reagent_containers/glass/inserted = null

	attack_ai(var/mob/user as mob)
		return attack_hand(user)

	attack_hand(var/mob/user as mob)
		user.machine = src

		var/dat = "<B>[src.name]</B><BR><HR>"
		if (src.mode == "overview")
			dat += "<b><u>Overview</u></b><br><br>"

			if (src.inserted)
				dat += "<B>Receptacle:</B> [src.inserted] ([src.inserted.reagents.total_volume]/[src.inserted.reagents.maximum_volume]) <A href='?src=\ref[src];ejectbeaker=1'>(Eject)</A><BR>"
				dat += "<b>Contents:</b> "
				if(src.inserted.reagents.reagent_list.len)
					for(var/current_id in inserted.reagents.reagent_list)
						var/datum/reagent/current_reagent = inserted.reagents.reagent_list[current_id]
						dat += "<BR><i>[current_reagent.volume] units of [current_reagent.name]</i>"
				else
					dat += "Empty"
			else
				dat += "<B>No receptacle inserted!</B>"

			dat += "<br>"

			if(src.seeds.len)
				dat += "<BR><B>[src.seeds.len] Seeds Ready for Experimentation</B>"
			else
				dat += "<BR><B>No Seeds inserted!</B>"

			dat += "<br>"

			if(src.extractables.len)
				dat += "<BR><B>[src.extractables.len] Items Ready for Extraction</B>"
			else
				dat += "<BR><B>No Extractable Produce inserted!</B>"

		else if (src.mode == "extraction")
			dat += "<b><u>Seed Extraction</u></b><br>"
			if (src.seedoutput)
				dat += "<A href='?src=\ref[src];outputmode=1'>Extracted seeds will be ejected from the machine.</A>"
			else
				dat += "<A href='?src=\ref[src];outputmode=1'>Extracted seeds will be retained within the machine.</A>"
			dat += "<br><br>"

			if(src.extractables.len)
				for (var/obj/item/I in src.extractables)
					dat += "* <b>[I.name]</b><br>"
					dat += "> <A href='?src=\ref[src];label=\ref[I]'>(Label)</A> "
					dat += "<A href='?src=\ref[src];analyze=\ref[I]'>(Analyze)</A> "
					dat += "<A href='?src=\ref[src];extract=\ref[I]'>(Extract)</A> "
					dat += "<A href='?src=\ref[src];eject=\ref[I]'>(Eject)</A>"
					dat += "<br>"
			else
				dat += "<B>No Extractable Produce inserted!</B>"

		else if (src.mode == "seedlist")
			dat += "<b><u>Seed List</u></b><br>"
			if (src.seedfilter)
				dat += "<b><A href='?src=\ref[src];filter=1'>Filter:</A></b> \"[src.seedfilter]\"<br>"
			else
				dat += "<b><A href='?src=\ref[src];filter=1'>Filter:</A></b> None<br>"
			dat += "<br>"

			var/allow_infusion = 0
			if (src.inserted)
				if (src.inserted.reagents.total_volume) allow_infusion = 1

			if(src.seeds.len)
				if (src.seedfilter)
					for (var/obj/item/seed/S in src.seeds)
						if (findtext(src.seedfilter, S.name, 1, null))
							dat += "<b>* [S.name]</b> <i>(Damage: [S.seeddamage]%)</i><br>"
							dat += "> <A href='?src=\ref[src];label=\ref[S]'>(Label)</A> "
							dat += "<A href='?src=\ref[src];analyze=\ref[S]'>(Analyze)</A> "
							dat += "<A href='?src=\ref[src];eject=\ref[S]'>(Eject)</A> "
							if (S == src.splicing1)
								dat += " <A href='?src=\ref[src];splice_cancel=1'>(Cancel Splice)</A>"
							else
								dat += " <A href='?src=\ref[src];splice_select=\ref[S]'>(Splice)</A>"
							if (allow_infusion)
								dat += " <A href='?src=\ref[src];infuse=\ref[S]'>(Infuse)</A>"
							dat += "<br>"
						else continue
				else
					for (var/obj/item/seed/S in src.seeds)
						dat += "<b>* [S.name]</b> <i>(Damage: [S.seeddamage]%)</i><br>"
						dat += "> <A href='?src=\ref[src];label=\ref[S]'>(Label)</A> "
						dat += "<A href='?src=\ref[src];analyze=\ref[S]'>(Analyze)</A> "
						dat += "<A href='?src=\ref[src];eject=\ref[S]'>(Eject)</A>"
						if (S == src.splicing1)
							dat += " <A href='?src=\ref[src];splice_cancel=1'>(Cancel Splice)</A>"
						else
							dat += " <A href='?src=\ref[src];splice_select=\ref[S]'>(Splice)</A>"
						if (allow_infusion)
							dat += " <A href='?src=\ref[src];infuse=\ref[S]'>(Infuse)</A>"
						dat += "<br>"
			else
				dat += "<B>No Seeds inserted!</B>"

		else if (src.mode == "splicing")
			if (src.splicing1 && src.splicing2)
				dat += "<b><u>Seed Splicing</u></b><br>"
				dat += "Splicing <A href='?src=\ref[src];analyze=\ref[src.splicing1]'>[src.splicing1]</A> + <A href='?src=\ref[src];analyze=\ref[src.splicing2]'>[src.splicing2]</A><br><br>"

				var/splice_chance = 100
				var/datum/plant/P1 = src.splicing1.planttype
				var/datum/plant/P2 = src.splicing2.planttype

				var/genome_difference = 0
				if (P1.genome > P2.genome)
					genome_difference = P1.genome - P2.genome
				else
					genome_difference = P2.genome - P1.genome
				splice_chance -= genome_difference * 10

				splice_chance -= src.splicing1.seeddamage
				splice_chance -= src.splicing2.seeddamage

				for (var/datum/plant_gene_strain/splicing/S in src.splicing1.plantgenes.commuts)
					if (S.negative)
						splice_chance -= S.splice_mod
					else
						splice_chance += S.splice_mod

				for (var/datum/plant_gene_strain/splicing/S in src.splicing2.plantgenes.commuts)
					if (S.negative)
						splice_chance -= S.splice_mod
					else
						splice_chance += S.splice_mod

				splice_chance = max(0,min(splice_chance,100))

				dat += "<b>Chance of Successful Splice:</b> [splice_chance]%<br>"
				dat += "<A href='?src=\ref[src];splice=1'>(Proceed)</A> <A href='?src=\ref[src];splice_cancel=1'>(Cancel)</A><BR>"
				if (src.seedoutput)
					dat += "<A href='?src=\ref[src];outputmode=1'>New seeds will be ejected from the machine.</A>"
				else
					dat += "<A href='?src=\ref[src];outputmode=1'>New seeds will be retained within the machine.</A>"

			else
				dat += {"<b>Splice Error.</b><br>
				<A href='?src=\ref[src];page=3'>Please click here to return to the Seed List.</A>"}
		else
			dat += {"<b>Software Error.</b><br>
			<A href='?src=\ref[src];page=1'>Please click here to return to the Overview.</A>"}

		dat += "<HR>"
		dat += "<b><u>Mode:</u></b> <A href='?src=\ref[src];page=1'>(Overview)</A> <A href='?src=\ref[src];page=2'>(Extraction)</A> <A href='?src=\ref[src];page=3'>(Seed List)</A>"

		user << browse(dat, "window=plantmaster;size=370x500")
		onclose(user, "rextractor")

	Topic(href, href_list)
		if((get_dist(usr,src) > 1) && !issilicon(usr))
			boutput(usr, "<span style=\"color:red\">You need to be closer to the machine to do that!</span>")
			return
		if(href_list["page"])
			var/ops = text2num(href_list["page"])
			switch(ops)
				if(2) src.mode = "extraction"
				if(3) src.mode = "seedlist"
				else src.mode = "overview"
			src.updateUsrDialog()

		else if(href_list["ejectbeaker"])
			if (!src.inserted) boutput(usr, "<span style=\"color:red\">No receptacle found to eject.</span>")
			else
				src.inserted.set_loc(src.loc)
				src.inserted = null
			src.updateUsrDialog()

		else if(href_list["eject"])
			var/obj/item/I = locate(href_list["eject"]) in src
			if (!istype(I))
				return
			if (istype(I,/obj/item/seed)) src.seeds.Remove(I)
			else src.extractables.Remove(I)
			I.set_loc(src.loc)
			src.updateUsrDialog()

		else if(href_list["label"])
			var/obj/item/I = locate(href_list["label"]) in src
			if (istype(I))
				var/newName = copytext(strip_html(input(usr,"What do you want to label [I.name]?","[src.name]",I.name) ),1, 129)
				if (newName && I && get_dist(src, usr) < 2)
					I.name = newName
			src.updateUsrDialog()

		else if(href_list["filter"])
			src.seedfilter = copytext(strip_html(input(usr,"Search for seeds by name? (Enter nothing to clear filter)","[src.name]",null)), 1, 257)
			src.updateUsrDialog()

		else if(href_list["analyze"])
			var/obj/item/I = locate(href_list["analyze"]) in src

			if (istype(I,/obj/item/seed/))
				var/obj/item/seed/S = I
				if (!istype(S.planttype,/datum/plant/) || !istype(S.plantgenes,/datum/plantgenes/))
					boutput(usr, "<span style=\"color:red\">Genetic structure of seed corrupted. Cannot scan.</span>")
				else
					HYPgeneticanalysis(usr,S,S.planttype,S.plantgenes)

			else if (istype(I,/obj/item/reagent_containers/food/snacks/plant/))
				var/obj/item/reagent_containers/food/snacks/plant/P = I
				if (!istype(P.planttype,/datum/plant/) || !istype(P.plantgenes,/datum/plantgenes/))
					boutput(usr, "<span style=\"color:red\">Genetic structure of item corrupted. Cannot scan.</span>")
				else
					HYPgeneticanalysis(usr,P,P.planttype,P.plantgenes)

			else
				boutput(usr, "<span style=\"color:red\">Item cannot be scanned.</span>")
			src.updateUsrDialog()

		else if(href_list["outputmode"])
			src.seedoutput = !src.seedoutput
			src.updateUsrDialog()

		else if(href_list["extract"])
			var/obj/item/I = locate(href_list["extract"]) in src
			if (istype(I,/obj/item/reagent_containers/food/snacks/plant/))
				var/obj/item/reagent_containers/food/snacks/plant/P = I
				var/datum/plant/stored = P.planttype
				var/datum/plantgenes/DNA = P.plantgenes
				var/give = rand(2,5)

				if (!stored || !DNA)
					give = 0
				if (HYPCheckCommut(DNA,/datum/plant_gene_strain/seedless))
					give = 0
				if (!give)
					boutput(usr, "<span style=\"color:red\">No viable seeds found in [I].</span>")
				else
					boutput(usr, "<span style=\"color:blue\">Extracted [give] seeds from [I].</span>")
					while (give > 0)
						var/obj/item/seed/S
						if (stored.unique_seed) S = new stored.unique_seed(src)
						else S = new /obj/item/seed(src,0)
						var/datum/plantgenes/SDNA = S.plantgenes
						if (!stored.unique_seed && !stored.hybrid)
							S.generic_seed_setup(stored)
						HYPpassplantgenes(DNA,SDNA)

						if (stored.hybrid)
							var/datum/plant/hybrid = new /datum/plant(S)
							for(var/V in stored.vars)
								if (issaved(stored.vars[V]) && V != "holder")
									hybrid.vars[V] = stored.vars[V]
							S.planttype = hybrid
							S.name = "[hybrid.name] seed"
						if (!src.seedoutput) src.seeds.Add(S)
						else S.set_loc(src.loc)
						give -= 1
				src.extractables.Remove(I)
				qdel(I)

			else
				boutput(usr, "<span style=\"color:red\">This item is not viable extraction produce.</span>")
			src.updateUsrDialog()

		else if(href_list["splice_select"])
			var/obj/item/I = locate(href_list["splice_select"]) in src
			if (!istype(I))
				return
			if (src.splicing1)
				if (I == src.splicing1)
					src.splicing1 = null
				else
					src.splicing2 = I
					src.mode = "splicing"
			else
				src.splicing1 = I
			src.updateUsrDialog()

		else if(href_list["splice_cancel"])
			src.splicing1 = null
			src.splicing2 = null
			src.mode = "seedlist"
			src.updateUsrDialog()

		else if(href_list["infuse"])
			if (dialogue_open)
				return
			var/obj/item/seed/S = locate(href_list["infuse"]) in src
			if (!istype(S))
				return
			if (!src.inserted)
				boutput(usr, "<span style=\"color:red\">No reagent container available for infusions.</span>")
			else
				if (src.inserted.reagents.total_volume < 10)
					boutput(usr, "<span style=\"color:red\">You require at least ten units of a reagent to infuse a seed.</span>")
				else
					var/list/usable_reagents = list()
					var/datum/reagent/R = null
					for(var/current_id in src.inserted.reagents.reagent_list)
						var/datum/reagent/current_reagent = src.inserted.reagents.reagent_list[current_id]
						if (current_reagent.volume >= 10) usable_reagents += current_reagent

					if (!usable_reagents.len)
						boutput(usr, "<span style=\"color:red\">You require at least ten units of a reagent to infuse a seed.</span>")
					else
						dialogue_open = 1
						R = input(usr, "Use which reagent to infuse the seed?", "[src.name]", 0) in usable_reagents
						if (!R || !S)
							return
						switch(S.HYPinfusionS(R.id,src))
							if (1) boutput(usr, "<span style=\"color:red\">ERROR: Seed has been destroyed.</span>")
							if (2) boutput(usr, "<span style=\"color:red\">ERROR: Reagent lost.</span>")
							if (3) boutput(usr, "<span style=\"color:red\">ERROR: Unknown error. Please try again.</span>")
							else boutput(usr, "<span style=\"color:blue\">Infusion of [R.name] successful.</span>")
						src.inserted.reagents.remove_reagent(R.id,10)
						dialogue_open = 0

			src.updateUsrDialog()

		else if(href_list["splice"])
			// Get the seeds being spliced first
			var/obj/item/seed/seed1 = src.splicing1
			var/obj/item/seed/seed2 = src.splicing2

			// Now work out whether we fail to splice or not based on species compatability
			// And the health of the two seeds you're using
			var/splice_chance = 100
			var/datum/plant/P1 = seed1.planttype
			var/datum/plant/P2 = seed2.planttype
			// Sanity check - if something's wrong, just fail the splice and be done with it
			if (!P1 || !P2) splice_chance = 0
			else
				// Seeds from different families aren't easy to splice
				var/genome_difference = 0
				if (P1.genome > P2.genome)
					genome_difference = P1.genome - P2.genome
				else
					genome_difference = P2.genome - P1.genome
				splice_chance -= genome_difference * 10

				// Deduct chances if the seeds are damaged from infusing or w/e else
				splice_chance -= seed1.seeddamage
				splice_chance -= seed2.seeddamage

				for (var/datum/plant_gene_strain/splicing/S in seed1.plantgenes.commuts)
					if (S.negative)
						splice_chance -= S.splice_mod
					else
						splice_chance += S.splice_mod

				for (var/datum/plant_gene_strain/splicing/S in seed2.plantgenes.commuts)
					if (S.negative)
						splice_chance -= S.splice_mod
					else
						splice_chance += S.splice_mod

			// Cap probability between 0 and 100
			splice_chance = max(0,min(splice_chance,100))
			if (prob(splice_chance)) // We're good, so start splicing!
				// Create the new seed
				var/obj/item/seed/S = new /obj/item/seed(src)
				var/datum/plant/P = new /datum/plant(S)
				var/datum/plantgenes/DNA = new /datum/plantgenes(S)
				S.planttype = P
				S.plantgenes = DNA
				P.hybrid = 1
				if (seed1.generation > seed2.generation)
					S.generation = seed1.generation + 1
				else
					S.generation = seed2.generation + 2

				var/datum/plantgenes/P1DNA = seed1.plantgenes
				var/datum/plantgenes/P2DNA = seed2.plantgenes

				var/dominance = P1DNA.alleles[1] - P2DNA.alleles[1]
				var/datum/plant/dominantspecies = null
				var/datum/plantgenes/dominantDNA = null

				// Establish which species allele is dominant
				if (dominance > 0)
					dominantspecies = P1
					dominantDNA = P1DNA
				else if (dominance < 0)
					dominantspecies = P2
					dominantDNA = P2DNA
				else
					// If neither, we pick randomly unlike the rest of the allele resolutions
					if (prob(50))
						dominantspecies = P1
						dominantDNA = P1DNA
					else
						dominantspecies = P2
						dominantDNA = P2DNA

				// Set up the base variables first
				if (!dominantspecies.hybrid)
					P.name = "Hybrid [dominantspecies.name]"
				else
					// Just making sure we dont get hybrid hybrid hybrid tomato seed or w/e
					P.name = "[dominantspecies.name]"
				if (dominantspecies.sprite)
					P.sprite = dominantspecies.sprite
				else
					P.sprite = dominantspecies.name
				P.special_icon = dominantspecies.special_icon
				P.special_dmi = dominantspecies.special_dmi
				P.crop = dominantspecies.crop
				P.force_seed_on_harvest = dominantspecies.force_seed_on_harvest
				P.harvestable = dominantspecies.harvestable
				P.harvests = dominantspecies.harvests
				P.isgrass = dominantspecies.isgrass
				P.cantscan = dominantspecies.cantscan
				P.nectarlevel = dominantspecies.nectarlevel
				S.name = "[P.name] seed"

				var/newgenome = P1.genome + P2.genome
				if (newgenome)
					newgenome = round(newgenome / 2)
				P.genome = newgenome

				for (var/datum/plantmutation/MUT in dominantspecies.mutations)
					// Only share the dominant species mutations or else shit might get goofy
					P.mutations += new MUT.type(P)

				if (dominantDNA.mutation)
					DNA.mutation = new dominantDNA.mutation.type(DNA)

				P.commuts = P1.commuts | P2.commuts // We merge these and share them
				DNA.commuts = P1DNA.commuts | P2DNA.commuts
				P.assoc_reagents = P1.assoc_reagents | P2.assoc_reagents

				// Now we start combining genetic traits based on allele dominance
				// If one is dominant and the other recessive, use the dominant value
				// If both are dominant or recessive, average the values out

				P.growtime = SpliceMK2(P1DNA.alleles[2],P2DNA.alleles[2],P1.vars["growtime"],P2.vars["growtime"])
				DNA.growtime = SpliceMK2(P1DNA.alleles[2],P2DNA.alleles[2],P1DNA.vars["growtime"],P2DNA.vars["growtime"])

				P.harvtime = SpliceMK2(P1DNA.alleles[3],P2DNA.alleles[3],P1.vars["harvtime"],P2.vars["harvtime"])
				DNA.harvtime = SpliceMK2(P1DNA.alleles[3],P2DNA.alleles[3],P1DNA.vars["harvtime"],P2DNA.vars["harvtime"])

				P.cropsize = SpliceMK2(P1DNA.alleles[4],P2DNA.alleles[4],P1.vars["cropsize"],P2.vars["cropsize"])
				DNA.cropsize = SpliceMK2(P1DNA.alleles[4],P2DNA.alleles[4],P1DNA.vars["cropsize"],P2DNA.vars["cropsize"])

				P.harvests = SpliceMK2(P1DNA.alleles[5],P2DNA.alleles[5],P1.vars["harvests"],P2.vars["harvests"])
				DNA.harvests = SpliceMK2(P1DNA.alleles[5],P2DNA.alleles[5],P1DNA.vars["harvests"],P2DNA.vars["harvests"])

				DNA.potency = SpliceMK2(P1DNA.alleles[6],P2DNA.alleles[6],P1DNA.vars["potency"],P2DNA.vars["potency"])

				P.endurance = SpliceMK2(P1DNA.alleles[7],P2DNA.alleles[7],P1.vars["endurance"],P2.vars["endurance"])
				DNA.endurance = SpliceMK2(P1DNA.alleles[7],P2DNA.alleles[7],P1DNA.vars["endurance"],P2DNA.vars["endurance"])

				boutput(usr, "<span style=\"color:blue\">Splice successful.</span>")
				if (!src.seedoutput) src.seeds.Add(S)
				else S.set_loc(src.loc)

			else
				// It fucked up - we don't need to do anything else other than tell the user
				boutput(usr, "<span style=\"color:red\">Splice failed.</span>")

			// Now get rid of the old seeds and go back to square one
			src.seeds.Remove(seed1)
			src.seeds.Remove(seed2)
			src.splicing1 = null
			src.splicing2 = null
			qdel(seed1)
			qdel(seed2)
			src.mode = "seedlist"
			src.updateUsrDialog()

		else
			src.updateUsrDialog()

	attackby(var/obj/item/W as obj, var/mob/user as mob)
		if(istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks/))
			if(src.inserted)
				boutput(user, "<span style=\"color:red\">A container is already loaded into the machine.</span>")
				return
			src.inserted =  W
			user.drop_item()
			W.set_loc(src)
			boutput(user, "<span style=\"color:blue\">You add [W] to the machine!</span>")
			src.updateUsrDialog()

		else if(istype(W, /obj/item/reagent_containers/food/snacks/plant/) || istype(W, /obj/item/seed/))
			boutput(user, "<span style=\"color:blue\">You add [W] to the machine!</span>")
			user.u_equip(W)
			W.set_loc(src)
			if (istype(W, /obj/item/seed/)) src.seeds += W
			else src.extractables += W
			W.dropped()
			src.updateUsrDialog()
			return

		else if(istype(W,/obj/item/satchel/hydro))
			var/obj/item/satchel/S = W
			var/select = input(user, "Load what from the satchel?", "[src.name]", 0) in list("Everything","Fruit Only","Seeds Only","Never Mind")
			if (select != "Never Mind")
				var/loadcount = 0
				for (var/obj/item/I in S.contents)
					if (istype(I,/obj/item/seed/) && (select == "Everything" || select == "Seeds Only"))
						I.set_loc(src)
						src.seeds += I
						loadcount++
						continue
					if (istype(I,/obj/item/reagent_containers/food/snacks/plant/) && (select == "Everything" || select == "Fruit Only"))
						I.set_loc(src)
						src.extractables += I
						loadcount++
						continue
				if (loadcount)
					boutput(user, "<span style=\"color:blue\">[loadcount] items were loaded from the satchel!</span>")
				else
					boutput(user, "<span style=\"color:red\">No items were loaded from the satchel!</span>")
				S.satchel_updateicon()
		else ..()

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (!O || !user)
			return
		if (!istype(O,/obj/item/))
			return
		if (istype(O, /obj/item/reagent_containers/glass/) || istype(O, /obj/item/reagent_containers/food/drinks/) || istype(O,/obj/item/satchel/hydro))
			return src.attackby(O, user)
		if (istype(O, /obj/item/reagent_containers/food/snacks/plant/) || istype(O, /obj/item/seed/))
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing [O.name] into [src]!</span>")
			var/staystill = user.loc
			for(var/obj/item/P in view(1,user))
				sleep(2)
				if (user.loc != staystill) break
				if (P.type == O.type)
					if (istype(O, /obj/item/seed/)) src.seeds.Add(P)
					else src.extractables.Add(P)
					P.set_loc(src)
				else continue
			boutput(user, "<span style=\"color:blue\">You finish stuffing items into [src]!</span>")
		else ..()

	proc/SpliceMK2(var/allele1,var/allele2,var/value1,var/value2)
		var/dominance = allele1 - allele2

		if (dominance > 0)
			return value1
		else if (dominance < 0)
			return value2
		else
			var/average = (value1 + value2)
			if (average != 0) average /= 2
			return round(average)

////// Reagent Extractor

/obj/submachine/chem_extractor/
	name = "Reagent Extractor"
	desc = "A machine which can extract reagents from organic matter."
	density = 1
	anchored = 1
	mats = 6
	icon = 'icons/obj/objects.dmi'
	icon_state = "reex-off"
	flags = NOSPLASH
	var/mode = "overview"
	var/autoextract = 0
	var/obj/item/reagent_containers/glass/extract_to = null
	var/obj/item/reagent_containers/glass/inserted = null
	var/obj/item/reagent_containers/glass/storage_tank_1 = null
	var/obj/item/reagent_containers/glass/storage_tank_2 = null
	var/list/ingredients = list()
	var/list/allowed = list(/obj/item/reagent_containers/food/snacks/,/obj/item/plant/)

	New()
		..()
		src.storage_tank_1 = new /obj/item/reagent_containers/glass/beaker/extractor_tank(src)
		src.storage_tank_2 = new /obj/item/reagent_containers/glass/beaker/extractor_tank(src)
		var/count = 1
		for (var/obj/item/reagent_containers/glass/beaker/extractor_tank/ST in src.contents)
			ST.name = "Storage Tank [count]"
			count++

	attack_ai(var/mob/user as mob)
		return attack_hand(user)

	attack_hand(var/mob/user as mob)
		user.machine = src

		var/dat = "<B>Reagent Extractor</B><BR><HR>"
		if (src.mode == "overview")
			dat += "<b><u>Extractor Overview</u></b><br><br>"
			// Overview mode is just a general outline of what's in the machine at the time
			// Internal Storage Tanks
			if (src.storage_tank_1)
				dat += "<b>Storage Tank 1:</b> ([src.storage_tank_1.reagents.total_volume]/[src.storage_tank_1.reagents.maximum_volume])<br>"
				if(src.storage_tank_1.reagents.reagent_list.len)
					for(var/current_id in storage_tank_1.reagents.reagent_list)
						var/datum/reagent/current_reagent = storage_tank_1.reagents.reagent_list[current_id]
						dat += "* <i>[current_reagent.volume] units of [current_reagent.name]</i><br>"
				else dat += "Empty<BR>"
				dat += "<br>"
			else dat += "<b>Storage Tank 1 Missing!</b><br>"
			if (src.storage_tank_2)
				dat += "<b>Storage Tank 2:</b> ([src.storage_tank_2.reagents.total_volume]/[src.storage_tank_2.reagents.maximum_volume])<br>"
				if(src.storage_tank_2.reagents.reagent_list.len)
					for(var/current_id in storage_tank_2.reagents.reagent_list)
						var/datum/reagent/current_reagent = storage_tank_2.reagents.reagent_list[current_id]
						dat += "* <i>[current_reagent.volume] units of [current_reagent.name]</i><br>"
				else dat += "Empty<BR>"
				dat += "<br>"
			else dat += "<b>Storage Tank 2 Missing!</b><br>"
			// Inserted Beaker or whatever
			if (src.inserted)
				dat += "<B>Receptacle:</B> [src.inserted] ([src.inserted.reagents.total_volume]/[src.inserted.reagents.maximum_volume]) <A href='?src=\ref[src];ejectbeaker=1'>(Eject)</A><BR>"
				dat += "<b>Contents:</b> "
				if(src.inserted.reagents.reagent_list.len)
					for(var/current_id in inserted.reagents.reagent_list)
						var/datum/reagent/current_reagent = inserted.reagents.reagent_list[current_id]
						dat += "<BR><i>[current_reagent.volume] units of [current_reagent.name]</i>"
				else dat += "Empty<BR>"
			else dat += "<B>No receptacle inserted!</B><BR>"

			if(src.ingredients.len)
				dat += "<BR><B>[src.ingredients.len] Items Ready for Extraction</B>"
			else
				dat += "<BR><B>No Items inserted!</B>"

		else if (src.mode == "extraction")
			dat += "<b><u>Extraction Management</u></b><br><br>"
			if (src.autoextract)
				dat += "<b>Auto-Extraction:</b> <A href='?src=\ref[src];autoextract=1'>Enabled</A>"
			else
				dat += "<b>Auto-Extraction:</b> <A href='?src=\ref[src];autoextract=1'>Disabled</A>"
			dat += "<br>"
			if (src.extract_to)
				dat += "<b>Extraction Target:</b> <A href='?src=\ref[src];extracttarget=1'>[src.extract_to]</A> ([src.extract_to.reagents.total_volume]/[src.extract_to.reagents.maximum_volume])"
				if (src.extract_to == src.inserted) dat += "<A href='?src=\ref[src];ejectbeaker=1'>(Eject)</A>"
			else dat += "<A href='?src=\ref[src];extracttarget=1'><b>No current extraction target set.</b></A>"

			if(src.ingredients.len)
				dat += "<br><br><B>Extractable Items:</B><br><br>"
				for (var/obj/item/I in src.ingredients)
					dat += "* [I]<br>"
					dat += "<A href='?src=\ref[src];extractingred=\ref[I]'>(Extract)</A> <A href='?src=\ref[src];ejectingred=\ref[I]'>(Eject)</A><br>"
			else dat += "<br><br><B>No Items inserted!</B>"

		else if (src.mode == "transference")
			dat += "<b><u>Transfer Management</u></b><br><br>"

			if (src.inserted)
				dat += "<A href='?src=\ref[src];chemtransfer=\ref[src.inserted]'><b>[src.inserted]:</b></A> ([src.inserted.reagents.total_volume]/[src.inserted.reagents.maximum_volume]) <A href='?src=\ref[src];flush=\ref[src.inserted]'>(Flush)</A> <A href='?src=\ref[src];ejectbeaker=1'>(Eject)</A><br>"
				if(src.inserted.reagents.reagent_list.len)
					for(var/current_id in inserted.reagents.reagent_list)
						var/datum/reagent/current_reagent = inserted.reagents.reagent_list[current_id]
						dat += "* <i>[current_reagent.volume] units of [current_reagent.name]</i><br>"
				else dat += "Empty<BR>"
			else dat += "<b>No receptacle inserted!</b><br>"

			dat += "<br>"

			dat += "<A href='?src=\ref[src];chemtransfer=\ref[src.storage_tank_1]'><b>Storage Tank 1:</b></A> ([src.storage_tank_1.reagents.total_volume]/[src.storage_tank_1.reagents.maximum_volume]) <A href='?src=\ref[src];flush=\ref[src.storage_tank_1]'>(Flush)</A><br>"
			if(src.storage_tank_1.reagents.reagent_list.len)
				for(var/current_id in storage_tank_1.reagents.reagent_list)
					var/datum/reagent/current_reagent = storage_tank_1.reagents.reagent_list[current_id]
					dat += "* <i>[current_reagent.volume] units of [current_reagent.name]</i><br>"
			else dat += "Empty<BR>"

			dat += "<br>"
			dat += "<A href='?src=\ref[src];chemtransfer=\ref[src.storage_tank_2]'><b>Storage Tank 2:</b></A> ([src.storage_tank_2.reagents.total_volume]/[src.storage_tank_2.reagents.maximum_volume]) <A href='?src=\ref[src];flush=\ref[src.storage_tank_2]'>(Flush)</A><br>"
			if(src.storage_tank_2.reagents.reagent_list.len)
				for(var/current_id in storage_tank_2.reagents.reagent_list)
					var/datum/reagent/current_reagent = storage_tank_2.reagents.reagent_list[current_id]
					dat += "* <i>[current_reagent.volume] units of [current_reagent.name]</i><br>"
			else dat += "Empty<BR>"

		else
			dat += {"<b>Software Error.</b><br>
			<A href='?src=\ref[src];page=1'>Please click here to return to the Overview.</A>"}

		dat += "<HR>"
		dat += "<b><u>Mode:</u></b> <A href='?src=\ref[src];page=1'>(Overview)</A> <A href='?src=\ref[src];page=2'>(Extraction)</A> <A href='?src=\ref[src];page=3'>(Transference)</A>"

		user << browse(dat, "window=rextractor;size=370x500")
		onclose(user, "rextractor")

	handle_event(var/event)
		if (event == "reagent_holder_update")
			src.updateUsrDialog()

	Topic(href, href_list)
		if(get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to the extractor to do that!</span>")
			return
		if(href_list["page"])
			var/ops = text2num(href_list["page"])
			switch(ops)
				if(2) src.mode = "extraction"
				if(3) src.mode = "transference"
				else src.mode = "overview"
			src.update_icon()
			src.updateUsrDialog()

		else if(href_list["ejectbeaker"])
			if (!src.inserted) boutput(usr, "<span style=\"color:red\">No receptacle found to eject.</span>")
			else
				if (src.inserted == src.extract_to) src.extract_to = null
				src.inserted.set_loc(src.loc)
				src.inserted = null
			src.updateUsrDialog()

		else if(href_list["ejectingred"])
			var/obj/item/I = locate(href_list["ejectingred"]) in src
			if (istype(I))
				src.ingredients.Remove(I)
				I.set_loc(src.loc)
				boutput(usr, "<span style=\"color:blue\">You eject [I] from the machine!</span>")
				src.update_icon()
			src.updateUsrDialog()

		else if (href_list["autoextract"])
			src.autoextract = !src.autoextract
			src.update_icon()
			src.updateUsrDialog()

		else if (href_list["flush"])
			var/obj/item/reagent_containers/glass/T = locate(href_list["flush"]) in src
			if (istype(T) && T.reagents)
				T.reagents.clear_reagents()
			src.updateUsrDialog()

		else if(href_list["extracttarget"])
			var/list/ext_targets = list(src.storage_tank_1,src.storage_tank_2)
			if (src.inserted) ext_targets.Add(src.inserted)
			var/target = input(usr, "Extract to which target?", "Reagent Extractor", 0) in ext_targets
			if(get_dist(usr, src) > 1) return
			src.extract_to = target
			src.update_icon()
			src.updateUsrDialog()

		else if(href_list["extractingred"])
			if (!src.extract_to)
				boutput(usr, "<span style=\"color:red\">You must first select an extraction target.</span>")
			else
				if (src.extract_to.reagents.total_volume == src.extract_to.reagents.maximum_volume)
					boutput(usr, "<span style=\"color:red\">The extraction target is already full.</span>")
				else
					var/obj/item/I = locate(href_list["extractingred"]) in src
					if (!istype(I) || !I.reagents)
						return

					src.doExtract(I)
					src.ingredients -= I
					qdel(I)
			src.update_icon()
			src.updateUsrDialog()

		else if(href_list["chemtransfer"])
			var/obj/item/reagent_containers/glass/G = locate(href_list["chemtransfer"]) in src
			if (!G)
				boutput(usr, "<span style=\"color:red\">Transfer target not found.</span>")
				src.updateUsrDialog()
				return
			else if (!G.reagents.total_volume)
				boutput(usr, "<span style=\"color:red\">Nothing in container to transfer.</span>")
				src.updateUsrDialog()
				return

			var/list/ext_targets = list(src.storage_tank_1,src.storage_tank_2)
			if (src.inserted) ext_targets.Add(src.inserted)
			ext_targets.Remove(G)
			var/target = input(usr, "Transfer to which target?", "Reagent Extractor", 0) in ext_targets
			if(get_dist(usr, src) > 1) return
			var/obj/item/reagent_containers/glass/T = target

			if (!T) boutput(usr, "<span style=\"color:red\">Transfer target not found.</span>")
			else if (G == T) boutput(usr, "<span style=\"color:red\">Cannot transfer a container's contents to itself.</span>")
			else
				var/amt = input(usr, "Transfer how many units?", "Chemical Transfer", 0) as null|num
				if(get_dist(usr, src) > 1) return
				if (amt < 1) boutput(usr, "<span style=\"color:red\">Invalid transfer quantity.</span>")
				else G.reagents.trans_to(T,amt)

			src.updateUsrDialog()

	attackby(var/obj/item/W as obj, var/mob/user as mob)
		if(istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks/))
			if(src.inserted)
				boutput(user, "<span style=\"color:red\">A container is already loaded into the machine.</span>")
				return
			src.inserted =  W
			user.drop_item()
			W.set_loc(src)
			boutput(user, "<span style=\"color:blue\">You add [W] to the machine!</span>")
			src.updateUsrDialog()

		else if (istype(W,/obj/item/satchel/hydro))
			var/obj/item/satchel/S = W

			var/loadcount = 0
			for (var/obj/item/I in S.contents)
				for(var/check_path in src.allowed)
					if(istype(I, check_path))
						I.set_loc(src)
						src.ingredients += I
						loadcount++
						break

			if (loadcount)
				boutput(user, "<span style=\"color:blue\">[loadcount] items were loaded from the satchel!</span>")
			else
				boutput(user, "<span style=\"color:red\">No items were loaded from the satchel!</span>")
			S.satchel_updateicon()
			src.update_icon()
			src.updateUsrDialog()

		else
			var/proceed = 0
			for(var/check_path in src.allowed)
				if(istype(W, check_path))
					proceed = 1
					break
			if (!proceed)
				boutput(user, "<span style=\"color:red\">The extractor cannot accept that!</span>")
				return

			if (src.autoextract)
				if (!src.extract_to)
					boutput(usr, "<span style=\"color:red\">You must first select an extraction target if you want items to be automatically extracted.</span>")
					return
				if (src.extract_to.reagents.total_volume == src.extract_to.reagents.maximum_volume)
					boutput(usr, "<span style=\"color:red\">The extraction target is full.</span>")
					return

			boutput(user, "<span style=\"color:blue\">You add [W] to the machine!</span>")
			user.u_equip(W)
			W.dropped()

			if (src.autoextract)
				src.doExtract(W)
				qdel(W)
			else
				W.set_loc(src)
				src.ingredients += W
			src.update_icon()
			src.updateUsrDialog()
			return

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (istype(O, /obj/item/reagent_containers/glass/) || istype(O, /obj/item/reagent_containers/food/drinks/) || istype(O, /obj/item/satchel/hydro))
			return src.attackby(O, user)
		var/proceed = 0
		for (var/check_path in src.allowed)
			if (istype(O, check_path))
				proceed = 1
				break
		if (!proceed) ..()
		else
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing [O.name] into [src]!</span>")
			var/staystill = user.loc
			for (var/obj/item/P in view(1,user))
				sleep(2)
				if (user.loc != staystill) break
				if (P.type == O.type)
					src.ingredients.Add(P)
					P.set_loc(src)
				else continue
			boutput(user, "<span style=\"color:blue\">You finish stuffing items into [src]!</span>")
		src.update_icon()

/obj/submachine/chem_extractor/proc/update_icon()
	if (src.ingredients.len)
		src.icon_state = "reex-on"
	else
		src.icon_state = "reex-off"

/obj/submachine/chem_extractor/proc/doExtract(var/obj/item/I)
	// Welp -- we don't want anyone extracting these. They'll probably
	// feed them to monkeys and then exsanguinate them trying to get at the chemicals.
	if (istype(I, /obj/item/reagent_containers/food/snacks/candy/everyflavor))
		src.extract_to.reagents.add_reagent("sugar", 50)
		return

	I.reagents.trans_to(src.extract_to, I.reagents.total_volume)
	src.update_icon()

/obj/submachine/seed_vendor
	name = "Seed Fabricator"
	desc = "Fabricates basic plant seeds."
	icon = 'icons/obj/vending.dmi'
	icon_state = "seeds"
	density = 1
	anchored = 1
	mats = 6
	var/vendamt = 1
	var/hacked = 0
	var/panelopen = 0
	var/malfunction = 0
	var/working = 1
	var/wires = 15
	var/can_vend = 1
	var/seedcount = 0
	var/maxseed = 25
	var/category = null
	var/list/available = list()
	var/const
		WIRE_EXTEND = 1
		WIRE_MALF = 2
		WIRE_POWER = 3
		WIRE_INERT = 4

	New()
		..()
		for (var/A in typesof(/datum/plant)) src.available += new A(src)

		/*for (var/datum/plant/P in src.available)
			if (!P.vending || P.type == /datum/plant)
				del(P)
				continue*/

	attack_ai(mob/user as mob)
		return src.attack_hand(user)

	attack_hand(var/mob/user as mob)
		user.machine = src
		var/dat = "<B>[src.name]</B><BR><HR>"
		dat += "<b>Amount to Vend</b>: <A href='?src=\ref[src];amount=1'>[src.vendamt]</A><br>"
		if (src.category)
			dat += "<b>Filter</b>: [src.category] <A href='?src=\ref[src];category=1'>(Clear)</A><br>"
		else
			dat += "<b>Filter</b>: <A href='?src=\ref[src];category=1'>(Set)</A><br>"
		if (!src.can_vend)
			dat+= "<u>Unit currently out of charge. Please wait.</u><br>"
		dat += "<br>"
		for(var/datum/plant/A in hydro_controls.plant_species)
			if (!A.vending)
				continue
			if (A.vending > 1)
				if (src.hacked)
					if (!src.category || (src.category == A.category))
						dat += "<b>[A.name]</b>: <A href='?src=\ref[src];disp=\ref[A]'>(VEND)</A><br>"
				else
					continue
			else
				if (!src.category || (src.category == A.category))
					dat += "<b>[A.name]</b>: <A href='?src=\ref[src];disp=\ref[A]'>(VEND)</A><br>"

		user << browse(dat, "window=seedfab;size=400x500")
		onclose(user, "seedfab")

		if (src.panelopen)
			var/list/fabwires = list(
			"Puce" = 1,
			"Mauve" = 2,
			"Ochre" = 3,
			"Slate" = 4,
			)
			var/pdat = "<B>[src.name] Maintenance Panel</B><hr>"
			for(var/wiredesc in fabwires)
				var/is_uncut = src.wires & APCWireColorToFlag[fabwires[wiredesc]]
				pdat += "[wiredesc] wire: "
				if(!is_uncut)
					pdat += "<a href='?src=\ref[src];cutwire=[fabwires[wiredesc]]'>Mend</a>"
				else
					pdat += "<a href='?src=\ref[src];cutwire=[fabwires[wiredesc]]'>Cut</a> "
					pdat += "<a href='?src=\ref[src];pulsewire=[fabwires[wiredesc]]'>Pulse</a> "
				pdat += "<br>"

			pdat += "<br>"
			pdat += "The yellow light is [(src.working == 0) ? "off" : "on"].<BR>"
			pdat += "The blue light is [src.malfunction ? "flashing" : "on"].<BR>"
			pdat += "The white light is [src.hacked ? "on" : "off"].<BR>"

			user << browse(pdat, "window=fabpanel")
			onclose(user, "fabpanel")

	Topic(href, href_list)
		if(get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to the vendor to do that!</span>")
			return
		if(href_list["amount"])
			var/amount = input(usr, "How many seeds do you want?", "[src.name]", 0) as null|num
			if(!amount) return
			if(amount < 0) return
			if(amount > 10) amount = 10
			src.vendamt = amount
			src.updateUsrDialog()

		if(href_list["category"])
			if (src.category) src.category = null
			else
				var/filter = input(usr, "Filter by which category?", "[src.name]", 0) in list("Fruit","Vegetable","Herb","Miscellaneous")
				if(!filter) return
				src.category = filter
			src.updateUsrDialog()

		if(href_list["disp"])
			if (src.can_vend == 0)
				boutput(usr, "<span style=\"color:red\">It's charging.</span>")
				return
			//var/getseed = null
			var/datum/plant/I = locate(href_list["disp"])

			if (!src.working || !istype(I))
				boutput(usr, "<span style=\"color:red\">[src.name] fails to dispense anything.</span>")
				return
			var/vend = src.vendamt
			while(vend > 0)
				//new getseed(src.loc)
				var/obj/item/seed/S
				if (I.unique_seed)
					S = new I.unique_seed(src.loc)
				else
					S = new /obj/item/seed(src.loc,0)
				S.generic_seed_setup(I)
				vend--
				src.seedcount++
			spawn(0)
				for(var/obj/item/seed/S in src.contents) S.set_loc(src.loc)
			if(src.seedcount >= src.maxseed)
				src.can_vend = 0
				spawn(100)
					src.can_vend = 1
					src.seedcount = 0
			src.updateUsrDialog()

		if ((href_list["cutwire"]) && (src.panelopen))
			var/twire = text2num(href_list["cutwire"])
			if (!( istype(usr.equipped(), /obj/item/wirecutters) ))
				boutput(usr, "You need wirecutters!")
				return
			else if (src.isWireColorCut(twire)) src.mend(twire)
			else src.cut(twire)
			src.updateUsrDialog()

		if ((href_list["pulsewire"]) && (src.panelopen))
			var/twire = text2num(href_list["pulsewire"])
			if (!istype(usr.equipped(), /obj/item/device/multitool))
				boutput(usr, "You need a multitool!")
				return
			else if (src.isWireColorCut(twire))
				boutput(usr, "You can't pulse a cut wire.")
				return
			else src.pulse(twire)
			src.updateUsrDialog()

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		if (!src.hacked)
			if(user)
				boutput(user, "<span style=\"color:blue\">You disable the [src]'s product locks!</span>")
			src.hacked = 1
			src.name = "Feed Sabricator"
			src.updateUsrDialog()
			return 1
		else
			if(user)
				boutput(user, "The [src] is already unlocked!")
			return 0

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W, /obj/item/screwdriver))
			if (!src.panelopen)
				src.overlays += image('icons/obj/vending.dmi', "grife-panel")
				src.panelopen = 1
			else
				src.overlays = null
				src.panelopen = 0
			boutput(user, "You [src.panelopen ? "open" : "close"] the maintenance panel.")
			src.updateUsrDialog()
		else ..()

	proc/isWireColorCut(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		return ((src.wires & wireFlag) == 0)

	proc/isWireCut(var/wireIndex)
		var/wireFlag = APCIndexToFlag[wireIndex]
		return ((src.wires & wireFlag) == 0)

	proc/cut(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		var/wireIndex = APCWireColorToIndex[wireColor]
		src.wires &= ~wireFlag
		switch(wireIndex)
			if(WIRE_EXTEND)
				src.hacked = 0
				src.name = "Seed Fabricator"
			if(WIRE_MALF) src.malfunction = 1
			if(WIRE_POWER) src.working = 0

	proc/mend(var/wireColor)
		var/wireFlag = APCWireColorToFlag[wireColor]
		var/wireIndex = APCWireColorToIndex[wireColor]
		src.wires |= wireFlag
		switch(wireIndex)
			if(WIRE_MALF) src.malfunction = 0

	proc/pulse(var/wireColor)
		var/wireIndex = APCWireColorToIndex[wireColor]
		switch(wireIndex)
			if(WIRE_EXTEND)
				if (src.hacked)
					src.hacked = 0
					src.name = "Seed Fabricator"
				else
					src.hacked = 1
					src.name = "Feed Sabricator"
			if (WIRE_MALF)
				if (src.malfunction) src.malfunction = 0
				else src.malfunction = 1
			if (WIRE_POWER)
				if (src.working) src.working = 0
				else src.working = 1