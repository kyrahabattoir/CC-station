// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/microwave
	name = "Microwave"
	icon = 'icons/obj/kitchen.dmi'
	desc = "The automatic chef of the future!"
	icon_state = "mw"
	density = 1
	anchored = 1
	var/egg_amount = 0 //Current number of eggs inside
	var/flour_amount = 0 //Current amount of flour inside
	var/water_amount = 0 //Current amount of water inside
	var/monkeymeat_amount = 0
	var/synthmeat_amount = 0
	var/humanmeat_amount = 0
	var/donkpocket_amount = 0
	var/humanmeat_name = ""
	var/humanmeat_job = ""
	var/operating = 0 // Is it on?
	var/dirty = 0 // Does it need cleaning?
	var/broken = 0 // How broken is it???
	var/list/available_recipes = list() // List of the recipes you can use
	var/obj/item/reagent_containers/food/snacks/being_cooked = null // The item being cooked
	var/obj/item/extra_item // One non food item that can be added
	mats = 12

/obj/machinery/microwave/New() // *** After making the recipe in datums\recipes.dm, add it in here! ***
	..()
	src.available_recipes += new /datum/recipe/donut(src)
	src.available_recipes += new /datum/recipe/synthburger(src)
	src.available_recipes += new /datum/recipe/monkeyburger(src)
	src.available_recipes += new /datum/recipe/humanburger(src)
	src.available_recipes += new /datum/recipe/waffles(src)
	src.available_recipes += new /datum/recipe/brainburger(src)
	src.available_recipes += new /datum/recipe/meatball(src)
	src.available_recipes += new /datum/recipe/assburger(src)
	src.available_recipes += new /datum/recipe/roburger(src)
	src.available_recipes += new /datum/recipe/heartburger(src)
	src.available_recipes += new /datum/recipe/donkpocket(src)
	src.available_recipes += new /datum/recipe/donkpocket_warm(src)
	src.available_recipes += new /datum/recipe/pie(src)
	src.available_recipes += new /datum/recipe/popcorn(src)


/*******************
*   Item Adding
********************/

obj/machinery/microwave/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(src.broken > 0)
		if(src.broken == 2 && istype(O, /obj/item/screwdriver)) // If it's broken and they're using a screwdriver
			src.visible_message("<span style=\"color:blue\">[user] starts to fix part of the microwave.</span>")
			sleep(20)
			src.visible_message("<span style=\"color:blue\">[user] fixes part of the microwave.</span>")
			src.broken = 1 // Fix it a bit
		else if(src.broken == 1 && istype(O, /obj/item/wrench)) // If it's broken and they're doing the wrench
			src.visible_message("<span style=\"color:blue\">[user] starts to fix part of the microwave.</span>")
			sleep(20)
			src.visible_message("<span style=\"color:blue\">[user] fixes the microwave!</span>")
			src.icon_state = "mw"
			src.broken = 0 // Fix it!
		else
			boutput(user, "It's broken!")
	else if(src.dirty) // The microwave is all dirty so can't be used!
		if(istype(O, /obj/item/spraybottle)) // If they're trying to clean it then let them
			src.visible_message("<span style=\"color:blue\">[user] starts to clean the microwave.</span>")
			sleep(20)
			src.visible_message("<span style=\"color:blue\">[user] has cleaned the microwave!</span>")
			src.dirty = 0 // It's cleaned!
			src.icon_state = "mw"
		else //Otherwise bad luck!!
			return
	else if(istype(O, /obj/item/reagent_containers/food/snacks/ingredient/egg)) // If an egg is used, add it
		if(src.egg_amount < 5)
			src.visible_message("<span style=\"color:blue\">[user] adds an egg to the microwave.</span>")
			src.egg_amount++
			qdel(O)
	else if(istype(O, /obj/item/reagent_containers/food/snacks/ingredient/flour)) // If flour is used, add it
		if(src.flour_amount < 5)
			src.visible_message("<span style=\"color:blue\">[user] adds some flour to the microwave.</span>")
			src.flour_amount++
			qdel(O)
	else if(istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/monkeymeat))
		if(src.monkeymeat_amount < 5)
			src.visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			src.monkeymeat_amount++
			qdel(O)
	else if(istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/synthmeat))
		if(src.synthmeat_amount < 5)
			src.visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			src.synthmeat_amount++
			qdel(O)
	else if(istype(O, /obj/item/reagent_containers/food/snacks/ingredient/meat/humanmeat/))
		if(src.humanmeat_amount < 5)
			src.visible_message("<span style=\"color:blue\">[user] adds some meat to the microwave.</span>")
			src.humanmeat_name = O:subjectname
			src.humanmeat_job = O:subjectjob
			src.humanmeat_amount++
			qdel(O)
	else if (istype(O, /obj/item/reagent_containers/food/snacks/donkpocket_w))
		// Band-aid fix. The microwave code could really use an overhaul (Convair880).
		user.show_text("Syndicate donk pockets don't have to be heated.", "red")
		return
	else if(istype(O, /obj/item/reagent_containers/food/snacks/donkpocket))
		if(src.donkpocket_amount < 2)
			src.visible_message("<span style=\"color:blue\">[user] adds a donk-pocket to the microwave.</span>")
			src.donkpocket_amount++
			qdel(O)
	else
		if(!istype(extra_item, /obj/item)) //Allow one non food item to be added!
			user.u_equip(O)
			extra_item = O
			O.set_loc(src)
			O.dropped(user)
			src.visible_message("<span style=\"color:blue\">[user] adds [O] to the microwave.</span>")
		else
			boutput(user, "There already seems to be an unusual item inside, so you don't add this one too.") //Let them know it failed for a reason though

/*******************
*   Microwave Menu
********************/

/obj/machinery/microwave/attack_hand(user as mob) // The microwave Menu
	var/dat
	if(src.broken > 0)
		dat = {"
<TT>Bzzzzttttt</TT>
		"}
	else if(src.operating)
		dat = {"
<TT>Microwaving in progress!<BR>
Please wait...!</TT><BR>
<BR>
"}
	else if(src.dirty)
		dat = {"
<TT>This microwave is dirty!<BR>
Please clean it before use!</TT><BR>
<BR>
"}
	else
		dat = {"
<B>Eggs:</B>[src.egg_amount] eggs<BR>
<B>Flour:</B>[src.flour_amount] cups of flour<BR>
<B>Monkey Meat:</B>[src.monkeymeat_amount] slabs of meat<BR>
<B>Synth-Meat:</B>[src.synthmeat_amount] slabs of meat<BR>
<B>Meat Turnovers:</B>[src.donkpocket_amount] turnovers<BR>
<B>Other Meat:</B>[src.humanmeat_amount] slabs of meat<BR><HR>
<BR>
<A href='?src=\ref[src];cook=1'>Turn on!<BR>
<A href='?src=\ref[src];cook=2'>Dispose contents!<BR>
"}

	user << browse("<HEAD><TITLE>Microwave Controls</TITLE></HEAD><TT>[dat]</TT>", "window=microwave")
	onclose(user, "microwave")
	return



/***********************************
*   Microwave Menu Handling/Cooking
************************************/

/obj/machinery/microwave/Topic(href, href_list)
	if(..())
		return

	usr.machine = src
	src.add_fingerprint(usr)

	if(href_list["cook"])
		if(!src.operating)
			var/operation = text2num(href_list["cook"])

			var/cook_time = 200 // The time to wait before spawning the item
			var/cooked_item = ""

			if(operation == 1) // If cook was pressed
				src.visible_message("<span style=\"color:blue\">The microwave turns on.</span>")
				for(var/datum/recipe/R in src.available_recipes) //Look through the recipe list we made above
					if(src.egg_amount == R.egg_amount && src.flour_amount == R.flour_amount && src.monkeymeat_amount == R.monkeymeat_amount && src.synthmeat_amount == R.synthmeat_amount && src.humanmeat_amount == R.humanmeat_amount && src.donkpocket_amount == R.donkpocket_amount) // Check if it's an accepted recipe
						if(R.extra_item == null || (src.extra_item && src.extra_item.type == R.extra_item)) // Just in case the recipe doesn't have an extra item in it
							src.egg_amount = 0 // If so remove all the eggs
							src.flour_amount = 0 // And the flour
							src.water_amount = 0 //And the water
							src.monkeymeat_amount = 0
							src.synthmeat_amount = 0
							src.humanmeat_amount = 0
							src.donkpocket_amount = 0
							src.extra_item = null // And the extra item
							cooked_item = R.creates // Store the item that will be created

				if(cooked_item == "") //Oops that wasn't a recipe dummy!!!
					if(src.egg_amount > 0 || src.flour_amount > 0 || src.water_amount > 0 || src.monkeymeat_amount > 0 || src.synthmeat_amount > 0 || src.humanmeat_amount > 0 || src.donkpocket_amount > 0 && src.extra_item == null) //Make sure there's something inside though to dirty it
						src.operating = 1 // Turn it on
						src.icon_state = "mw1"
						src.updateUsrDialog()
						src.egg_amount = 0 //Clear all the values as this crap is what makes the mess inside!!
						src.flour_amount = 0
						src.water_amount = 0
						src.humanmeat_amount = 0
						src.monkeymeat_amount = 0
						src.synthmeat_amount = 0
						src.donkpocket_amount = 0
						sleep(40) // Half way through
						playsound(src.loc, "sound/effects/splat.ogg", 50, 1) // Play a splat sound
						icon_state = "mwbloody1" // Make it look dirty!!
						sleep(40) // Then at the end let it finish normally
						playsound(src.loc, "sound/machines/ding.ogg", 50, 1)
						src.visible_message("<span style=\"color:red\">The microwave gets covered in muck!</span>")
						src.dirty = 1 // Make it dirty so it can't be used util cleaned
						src.icon_state = "mwbloody" // Make it look dirty too
						src.operating = 0 // Turn it off again aferwards
						// Don't clear the extra item though so important stuff can't be deleted this way and
						// it prolly wouldn't make a mess anyway

					else if(src.extra_item != null) // However if there's a weird item inside we want to break it, not dirty it
						src.operating = 1 // Turn it on
						src.icon_state = "mw1"
						src.updateUsrDialog()
						src.egg_amount = 0 //Clear all the values as this crap is gone when it breaks!!
						src.flour_amount = 0
						src.water_amount = 0
						src.humanmeat_amount = 0
						src.synthmeat_amount = 0
						src.monkeymeat_amount = 0
						src.donkpocket_amount = 0
						sleep(60) // Wait a while
						var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
						s.set_up(2, 1, src)
						s.start()
						icon_state = "mwb" // Make it look all busted up and shit
						src.visible_message("<span style=\"color:red\">The microwave breaks!</span>") //Let them know they're stupid
						src.broken = 2 // Make it broken so it can't be used util fixed
						src.operating = 0 // Turn it off again aferwards
						src.extra_item.set_loc(get_turf(src)) // Eject the extra item so important shit like the disk can't be destroyed in there
						src.extra_item = null

					else //Otherwise it was empty, so just turn it on then off again with nothing happening
						src.operating = 1
						src.icon_state = "mw1"
						src.updateUsrDialog()
						sleep(80)
						src.icon_state = "mw"
						playsound(src.loc, "sound/machines/ding.ogg", 50, 1)
						src.operating = 0

			if(operation == 2) // If dispose was pressed, empty the microwave
				src.egg_amount = 0
				src.flour_amount = 0
				src.water_amount = 0
				src.humanmeat_amount = 0
				src.monkeymeat_amount = 0
				src.synthmeat_amount = 0
				src.donkpocket_amount = 0
				if(src.extra_item != null)
					src.extra_item.set_loc(get_turf(src)) // Eject the extra item so important shit like the disk can't be destroyed in there
					src.extra_item = null
				boutput(usr, "You dispose of the microwave contents.")

			var/cooking = text2path(cooked_item) // Get the item that needs to be spanwed
			if(!isnull(cooking))
				src.visible_message("<span style=\"color:blue\">The microwave begins cooking something!</span>")
				src.operating = 1 // Turn it on so it can't be used again while it's cooking
				src.icon_state = "mw1" //Make it look on too
				src.updateUsrDialog()
				src.being_cooked = new cooking(src)

				spawn(cook_time) //After the cooking time
					if(!isnull(src.being_cooked))
						playsound(src.loc, "sound/machines/ding.ogg", 50, 1)
						if(istype(src.being_cooked, /obj/item/reagent_containers/food/snacks/burger/humanburger))
							src.being_cooked.name = "[humanmeat_name] [src.being_cooked.name]"
						if(istype(src.being_cooked, /obj/item/reagent_containers/food/snacks/donkpocket))
							src.being_cooked:warm = 1
							src.being_cooked.name = "warm " + src.being_cooked.name
							src.being_cooked:cooltime()
						src.being_cooked.set_loc(get_turf(src)) // Create the new item
						src.being_cooked = null // We're done!

					src.operating = 0 // Turn the microwave back off
					src.icon_state = "mw"
			else
				return