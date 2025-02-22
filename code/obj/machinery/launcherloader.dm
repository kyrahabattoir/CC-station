// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/launcher_loader
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "launcher_loader_0"
	name = "Automatic mass-driver loader (AMDL)"
	desc = "An automated, hydraulic mass-driver loader."
	density = 0
	opacity = 0
	layer = 2.6
	anchored = 1

	var/obj/machinery/mass_driver/driver = null

	var/id = "null"
	var/operating = 0
	var/driver_operating = 0
	var/trash = 0

	New()
		..()
		spawn(5)
			var/list/drivers = new/list()
			for(var/obj/machinery/mass_driver/D in range(1,src))
				drivers += D
			if(drivers.len)
				if(drivers.len > 1)
					for(var/obj/machinery/mass_driver/D2 in drivers)
						if(D2.id == src.id)
							driver = D2
							break
					if(!driver) driver = pick(drivers)
				else
					driver = pick(drivers)

				src.dir = get_dir(src,driver)

	proc/activate()
		if(operating || !isturf(src.loc)) return
		operating = 1
		flick("launcher_loader_1",src)
		playsound(src, "sound/effects/pump.ogg",50, 1)
		sleep(3)
		for(var/atom/movable/AM in src.loc)
			if(AM.anchored || AM == src) continue
			if(trash && AM.delivery_destination != "Disposals")
				AM.delivery_destination = "Disposals"
			step(AM,src.dir)
		operating = 0
		handle_driver()

	proc/handle_driver()
		if(driver && !driver_operating)
			driver_operating = 1

			spawn(0)
				var/obj/machinery/door/poddoor/door = null
				for(var/obj/machinery/door/poddoor/P)
					if (P.id == driver.id)
						door = P
						spawn(0)
							if (door)
								door.open()
						spawn(100)
							if (door)
								door.close() //this may need some adjusting still

				spawn(door ? 55 : 20) driver_operating = 0

				spawn(door ? 20 : 10)
					if (driver)
						for(var/obj/machinery/mass_driver/D in machines)
							if(D.id == driver.id)
								D.drive()
	process()
		if(!operating && !driver_operating)
			var/drive = 0
			for(var/atom/movable/M in src.loc)
				if(M == src || M.anchored) continue
				drive = 1
				break
			if(drive) activate()

	HasEntered(atom/A)
		if (isobserver(A) || isintangible(A) || iswraith(A)) return
		if (istype(A, /obj/overlay)) return
		activate()


/obj/machinery/launcher_loader/north
	dir = NORTH
/obj/machinery/launcher_loader/east
	dir = EAST
/obj/machinery/launcher_loader/south
	dir = SOUTH
/obj/machinery/launcher_loader/west
	dir = WEST

/atom/movable
	var/delivery_destination = null

/obj/machinery/cargo_router
	icon = 'icons/obj/delivery.dmi'
	icon_state = "amdl_0"
	name = "Cargo Router"
	desc = "Scans the barcode on objects and reroutes them accordingly."
	density = 0
	opacity = 0
	anchored = 1

	var/default_direction = NORTH //The direction things get sent into when the router does not have a destination for the given barcode or when there is none attached.
	var/list/destinations = new/list() //List of tags and the associated directions.

	var/obj/machinery/mass_driver/driver = null
	var/operating = 0
	var/driver_operating = 0

	proc/activate()
		if(operating || !isturf(src.loc)) return
		operating = 1

		var/next_dest = null

		for(var/atom/movable/AM in src.loc)
			if(AM.anchored || AM == src) continue
			if(AM.delivery_destination && !next_dest)
				if(destinations.Find(AM.delivery_destination))
					next_dest = destinations[AM.delivery_destination]
					break

		if(next_dest) src.dir = next_dest
		else src.dir = default_direction

		flick("amdl_1",src)
		playsound(src, "sound/effects/pump.ogg",50, 1)
		sleep(3)

		for(var/atom/movable/AM2 in src.loc)
			if(AM2.anchored || AM2 == src) continue
			step(AM2,src.dir)

		driver = (locate(/obj/machinery/mass_driver) in get_step(src,src.dir))

		operating = 0
		handle_driver()

	proc/handle_driver()
		if(driver && !driver_operating)
			driver_operating = 1

			spawn(0)
				spawn(20)
					driver_operating = 0
					driver = null

				spawn(10)
					if (driver)
						driver.drive()

	process()
		if(!operating && !driver_operating)
			var/drive = 0
			for(var/atom/movable/M in src.loc)
				if(M == src || M.anchored) continue
				drive = 1
				break
			if(drive) activate()

	HasEntered(atom/A)
		if (isobserver(A) || isintangible(A) || iswraith(A)) return
		if (istype(A, /obj/overlay)) return
		activate()

/obj/machinery/cargo_router/exampleRouter
	New()
		destinations = list("Medical-Science Dock" = SOUTH, "Catering Dock" = NORTH, "EVA Dock" = WEST, "Disposals" = EAST)
		default_direction = EAST //By default send things to disposals, for this example, if they dont have a code or we don't have a destination.
		//You could leave one direction open and use that as default to send things with invalid destinations back to QM or something.
		//Or if QM is already in the list of destinations , use that direction as default. I don't know.
		..()

// cogwerks notes: I'm starting with the first router from QM and moving sorta clockwise.
/obj/machinery/cargo_router/Router1
	New()
		destinations = list("Airbridge" = WEST, "Cafeteria" = NORTH, "EVA" = WEST, "Disposals" = NORTH, "QM" = NORTH, "Engine" = NORTH, "Catering" = NORTH, "MedSci" = NORTH, "Security" = NORTH)
		default_direction = NORTH
		..()

/obj/machinery/cargo_router/Router2 //airbridge loader
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = WEST, "EVA" = WEST, "Disposals" = WEST, "QM" = WEST, "Engine" = WEST, "Catering" = WEST, "MedSci" = WEST, "Security" = WEST)
		default_direction = WEST
		..()

/obj/machinery/cargo_router/Router3 //eva loader
	New()
		destinations = list("Airbridge" = EAST, "Cafeteria" = EAST, "EVA" = NORTH, "Disposals" = EAST, "QM" = EAST, "Engine" = EAST, "Catering" = EAST, "MedSci" = EAST, "Security" = EAST)
		default_direction = EAST
		..()

/obj/machinery/cargo_router/Router4 //cafeteria
	New()
		destinations = list("Airbridge" = EAST, "Cafeteria" = NORTH, "EVA" = EAST, "Disposals" = EAST, "QM" = EAST, "Engine" = EAST, "Catering" = EAST, "MedSci" = EAST, "Security" = EAST)
		default_direction = EAST
		..()

/obj/machinery/cargo_router/Router5 //disposals
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = SOUTH, "EVA" = SOUTH, "Disposals" = EAST, "QM" = EAST, "Engine" = SOUTH, "Catering" = EAST, "MedSci" = EAST, "Security" = EAST)
		default_direction = EAST
		..()

/obj/machinery/cargo_router/Router6 //crusher or QM?
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = SOUTH, "EVA" = SOUTH, "Disposals" = EAST, "QM" = SOUTH, "Engine" = SOUTH, "Catering" = SOUTH, "MedSci" = SOUTH, "Security" = SOUTH)
		default_direction = SOUTH
		..()

/obj/machinery/cargo_router/Router7 // shortcut - bypasses the central hub
	New()
		destinations = list("Airbridge" = WEST, "Cafeteria" = WEST, "EVA" = WEST, "Disposals" = NORTH, "QM" = NORTH, "Engine" = WEST, "Catering" = NORTH, "MedSci" = NORTH, "Security" = NORTH)
		default_direction = NORTH
		..()

/obj/machinery/cargo_router/Router8 // engine dock
	New()
		destinations = list("Airbridge" = WEST, "Cafeteria" = WEST, "EVA" = WEST, "Disposals" = WEST, "QM" = WEST, "Engine" = SOUTH, "Catering" = WEST, "MedSci" = WEST, "Security" = WEST)
		default_direction = WEST
		..()

/obj/machinery/cargo_router/Router9 // to outer router -> out
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = SOUTH, "EVA" = SOUTH, "Disposals" = SOUTH, "QM" = SOUTH, "Engine" = SOUTH, "Catering" = EAST, "MedSci" = EAST, "Security" = EAST)
		default_direction = SOUTH
		..()

/obj/machinery/cargo_router/Router10 // to outer router -> in
	New()
		destinations = list("Airbridge" = WEST, "Cafeteria" = WEST, "EVA" = WEST, "Disposals" = WEST, "QM" = SOUTH, "Engine" = WEST, "Catering" = WEST, "MedSci" = WEST, "Security" = WEST)
		default_direction = SOUTH
		..()

/obj/machinery/cargo_router/Router11 // outer router -> up
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = SOUTH, "EVA" = SOUTH, "Disposals" = SOUTH, "QM" = SOUTH, "Engine" = SOUTH, "Catering" = NORTH, "MedSci" = SOUTH, "Security" = NORTH)
		default_direction = SOUTH
		..()

/obj/machinery/cargo_router/Router12 // outer router -> down
	New()
		destinations = list("Airbridge" = WEST, "Cafeteria" = WEST, "EVA" = SOUTH, "Disposals" = WEST, "QM" = WEST, "Engine" = WEST, "Catering" = NORTH, "MedSci" = SOUTH, "Security" = NORTH)
		default_direction = WEST
		..()

/obj/machinery/cargo_router/Router13 // catering outer router -> east-west
	New()
		destinations = list("Airbridge" = SOUTH, "Cafeteria" = SOUTH, "EVA" = SOUTH, "Disposals" = SOUTH, "QM" = SOUTH, "Engine" = SOUTH, "Catering" = SOUTH, "MedSci" = SOUTH, "Security" = WEST)
		default_direction = SOUTH
		..()

/obj/machinery/cargo_router/Router14 // catering outer router -> west-east
	New()
		destinations = list("Airbridge" = EAST, "Cafeteria" = EAST, "EVA" = EAST, "Disposals" = EAST, "QM" = EAST, "Engine" = EAST, "Catering" = SOUTH, "MedSci" = EAST, "Security" = EAST)
		default_direction = EAST
		..()

/obj/machinery/computer/barcode
	name = "Barcode Computer"
	desc = "Used to print barcode stickers for the cargo routing system."

	icon = 'icons/obj/delivery.dmi'
	icon_state = "barcode_comp"
	var/printing = 0

	// log account information for QM sales
	var/obj/item/card/id/scan = null
	var/datum/data/record/account = null


	var/list/destinations = list("Airbridge", "Cafeteria", "EVA", "Engine", "Disposals", "QM", "Catering", "MedSci", "Security") //These have to match the ones on the cargo routers for the routers to work.

	attack_hand(var/mob/user as mob)
		if (..(user))
			return

		var/dat = ""
		dat += "<b>Available Destinations:</b><BR>"
		for(var/I in destinations)
			dat += "<b><A href='?src=\ref[src];print=[I]'>[I]</A></b><BR>"

		dat += "<BR><b><A href='?src=\ref[src];add=1'>Add Tag</A></b>"

		user.machine = src
		user << browse("<TITLE>Barcode Computer</TITLE><BR>[dat]", "window=bc_computer;size=400x300")
		onclose(user, "bc_computer")
		return


	attackby(var/obj/item/I as obj, user as mob)
		if (istype(I, /obj/item/device/pda2) && I:ID_card)
			I = I:ID_card
		if (istype(I, /obj/item/card/id))
			boutput(user, "<span style=\"color:blue\">You swipe the ID card.</span>")
			account = FindBankAccountByName(I:registered)
			if(account)
				var/enterpin = input(user, "Please enter your PIN number.", "Order Console", 0) as null|num
				if (enterpin == I:pin)
					boutput(user, "<span style=\"color:blue\">Card authorized.</span>")
					src.scan = I
				else
					boutput(user, "<span style=\"color:red\">Pin number incorrect.</span>")
					src.scan = null
			else
				boutput(user, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
				src.scan = null
		else src.attack_hand(user)
		return


	Topic(href, href_list)
		if (..(href, href_list))
			return

		if (href_list["print"] && !printing)
			printing = 1
			playsound(src.loc, "sound/machines/printer_thermal.ogg", 50, 0)
			sleep(28)
			var/obj/item/barcodesticker/B = new/obj/item/barcodesticker(src.loc)
			B.name = "Barcode Sticker ([href_list["print"]])"
			B.destination = href_list["print"]
			B.scan = src.scan
			B.account = src.account
			printing = 0
		// cogwerks - uncomment this stuff if/when custom locations are ready
		/*else if (href_list["remove"])
			if(destinations.Find(href_list["remove"]))
				destinations.Remove(href_list["remove"])

		else if (href_list["add"])
			var/input = input(usr,"Enter new tag:","Tag","") as text
			if(length(input) && !destinations.Find(input))
				destinations.Add(input)*/

		usr << browse(null, "window=bc_computer")
		src.updateUsrDialog()
		return

/obj/machinery/computer/barcode/qm //has trader tags if there is one
	name = "QM Barcode Computer"
	desc = "Used to print barcode stickers for the cargo routing system, and to mark crates for sale to traders."
	icon_state = "qm_barcode_comp"

	attack_hand(var/mob/user as mob)
		if (..(user))
			return

		var/dat = ""
		dat += "<b>Available Destinations:</b><BR>"
		for(var/I in destinations)
			dat += "<b><A href='?src=\ref[src];print=[I]'>[I]</A></b><BR><BR>"

		dat += "<b>Available Traders:</b><BR>"
		for(var/datum/trader/T in shippingmarket.active_traders)
			if (!T.hidden)
				dat += "<br><b><A href='?src=\ref[src];print=[T.crate_tag]'>Sell to [T.name]</A></b><BR>"

		dat += "<BR><b><A href='?src=\ref[src];add=1'>Add Tag</A></b>"

		user.machine = src
		user << browse("<TITLE>Barcode Computer</TITLE><BR>[dat]", "window=bc_computer;size=400x300")
		onclose(user, "bc_computer")
		return

/obj/item/barcodesticker
	name = "Barcode Sticker"
	desc = "A barcode sticker used in the cargo routing system."
	icon = 'icons/obj/delivery.dmi'
	icon_state = "barcodesticker"
	item_state = "paper"

	var/destination = "QM Dock"

	// log account information for QM sales
	var/obj/item/card/id/scan = null
	var/datum/data/record/account = null

	proc/attachTo(atom/target)
		if(get_dist(get_turf(target), get_turf(src)) <= 1 && istype(target, /atom/movable))
			if(target==loc && target != usr) return //Backpack or something
			target:delivery_destination = destination
			usr.visible_message("<span style=\"color:blue\">[usr] puts a [src.name] on [target].</span>")
			if(istype(target, /obj/storage/crate) && scan && account)
				var/obj/storage/crate/C = target
				C.scan = src.scan
				C.account = src.account
				boutput(usr, "<span style=\"color:blue\">[target] has been marked with your account routing information.</span>")
				C.desc = "[C] belongs to [scan.registered]."
			qdel(src)
		return

	attack(mob/M as mob, mob/user as mob, def_zone)
		src.attachTo(M)
		return

	afterattack(atom/target as mob|obj|turf, mob/user as mob)
		src.attachTo(target)
		return

	MouseDrop(over_object, src_location, over_location)
		src.attachTo(over_object)
		return