// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/power/furnace
	name = "Furnace"
	desc = "An inefficient method of powering the station. Generates 5000 units of power while active."
	icon_state = "furnace"
	anchored = 1
	density = 1
	var/active = 0
	var/last_active = 0
	var/fuel = 0
	var/last_fuel_state = 0
	var/maxfuel = 1000
	var/genrate = 5000
	var/stoked = 0 // engine ungrump
	mats = 20

	process()
		if(stat & BROKEN) return
		if(src.active)
			if(src.fuel)
				on_burn()
				fuel--
				if(stoked)
					stoked--
			if(!src.fuel)
				src.visible_message("<span style=\"color:red\">[src] runs out of fuel and shuts down!</span>")
				src.active = 0

		//src.overlays = null
		//if (src.active) src.overlays += image('icons/obj/power.dmi', "furn-burn")
		//if (fuelperc >= 20) src.overlays += image('icons/obj/power.dmi', "furn-c1")
		//if (fuelperc >= 40) src.overlays += image('icons/obj/power.dmi', "furn-c2")
		//if (fuelperc >= 60) src.overlays += image('icons/obj/power.dmi', "furn-c3")
		//if (fuelperc >= 80) src.overlays += image('icons/obj/power.dmi', "furn-c4")
		update_icon()

	proc/on_burn()
		add_avail(src.genrate)

	proc/update_icon()
		if(active != last_active)
			last_active = active
			if(src.active)
				var/image/I = GetOverlayImage("active")
				if(!I) I = image('icons/obj/power.dmi', "furn-burn")
				UpdateOverlays(I, "active")
			else
				UpdateOverlays(null, "active", 0, 1) //Keep it in cache for when it's toggled

		var/fuel_state = round(min((src.fuel / src.maxfuel) * 5, 4))
		//At max fuel, the state will be 4, aka all bars, then it will lower / increase as fuel is added
		if(fuel_state != last_fuel_state) //The fuel state has changed and we need to do an update
			last_fuel_state = fuel_state
			for(var/i = 1; i <= 4; i++)
				var/okey = "fuel[i]"
				if(fuel_state >= i) //Add the overlay
					var/image/I = GetOverlayImage(okey)
					if(!I) I = image('icons/obj/power.dmi', "furn-c[i]")
					UpdateOverlays(I, okey)
				else //Clear the overlay
					UpdateOverlays(null, okey, 0, 1)


	attack_hand(var/mob/user as mob)
		if (!src.fuel) boutput(user, "<span style=\"color:red\">There is no fuel in the furnace!</span>")
		else
			src.active = !src.active
			boutput(user, "You switch [src.active ? "on" : "off"] the furnace.")

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/grab))
			if (!src.active)
				boutput(user, "<span style=\"color:red\">It'd probably be easier to dispose of them while the furnace is active...</span>")
				return
			else
				user.visible_message("<span style=\"color:red\">[user] starts to shove [W:affecting] into the furnace!</span>")
				logTheThing("combat", user, W:affecting, "attempted to force %target% into a furnace at [log_loc(src)].")
				message_admins("[key_name(user)] is trying to force [key_name(W:affecting)] into a furnace at [log_loc(src)].")
				src.add_fingerprint(user)
				sleep(50)
				if(W:affecting && src.active)
					user.visible_message("<span style=\"color:red\">[user] stuffs [W:affecting] into the furnace!</span>")
					var/mob/M = W:affecting
					logTheThing("combat", user, M, "forced %target% into a furnace at [log_loc(src)].")
					message_admins("[key_name(user)] forced [key_name(M)] into a furnace at [log_loc(src)].")
					M.death(1)
					if (M.mind)
						M.ghostize()
						qdel(M)
					else
						qdel(M)
					qdel(W)
					src.fuel += 400
					src.stoked += 50
					if(src.fuel >= src.maxfuel)
						src.fuel = src.maxfuel
						boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")
					return
		else if (istype(W, /obj/item/raw_material/char)) src.fuel += 60
		else if (istype(W, /obj/item/raw_material/plasmastone)) src.fuel += 800
		else if (istype(W, /obj/item/paper/)) src.fuel += 6
		else if (istype(W, /obj/item/spacecash/)) src.fuel += 6
		else if (istype(W, /obj/item/clothing/gloves/)) src.fuel += 10
		else if (istype(W, /obj/item/clothing/head/)) src.fuel += 20
		else if (istype(W, /obj/item/clothing/mask/)) src.fuel += 10
		else if (istype(W, /obj/item/clothing/shoes/)) src.fuel += 10
		else if (istype(W, /obj/item/clothing/head/)) src.fuel += 20
		else if (istype(W, /obj/item/clothing/suit/)) src.fuel += 40
		else if (istype(W, /obj/item/clothing/under/)) src.fuel += 30
		else if (istype(W, /obj/item/plank)) src.fuel += 100
		else if (istype(W, /obj/item/plant/herb/cannabis))
			src.fuel += 30
			stoked += 10
		else
			..()
			return
		boutput(user, "<span style=\"color:blue\">You load [W] into [src]!</span>")
		user.u_equip(W)
		W.dropped()
		qdel (W)
		if(src.fuel > src.maxfuel)
			src.fuel = src.maxfuel
			boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")

	MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
		if (get_dist(src,user) > 1)
			boutput(user, "<span style=\"color:red\">You are too far away to do that.</span>")
			return

		if (get_dist(src,O) > 1)
			boutput(user, "<span style=\"color:red\">[O] is too far away to do that.</span>")
			return

		if (istype(O, /obj/storage/crate/))
			if (src.fuel >= src.maxfuel)
				boutput(user, "<span style=\"color:red\">The furnace is already full!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] uses the [src]'s automatic ore loader on [O]!</span>", "<span style=\"color:blue\">You use the [src]'s automatic ore loader on [O].</span>")
			var/amtload = 0
			for (var/obj/item/raw_material/M in O.contents)
				if (istype(M,/obj/item/raw_material/char))
					src.fuel += 60
					amtload++
					qdel (M)
				else if (istype(M,/obj/item/raw_material/plasmastone))
					src.fuel += 800
					amtload++
					qdel (M)
				if (src.fuel >= src.maxfuel)
					src.fuel = src.maxfuel
					boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")
					break
			if (amtload) boutput(user, "<span style=\"color:blue\">[amtload] pieces of ore loaded from [O]!</span>")
			else boutput(user, "<span style=\"color:red\">No ore loaded!</span>")

		else if (istype(O, /obj/item/raw_material/char))
			if (src.fuel >= src.maxfuel)
				boutput(user, "<span style=\"color:red\">The furnace is already full!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing ore into [src]!</span>")
			var/staystill = user.loc
			for(var/obj/item/raw_material/char/M in view(1,user))
				src.fuel += 60
				qdel (M)
				if (src.fuel >= src.maxfuel)
					src.fuel = src.maxfuel
					boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")
					break
				sleep(3)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing ore into [src]!</span>")

		else if (istype(O, /obj/item/plant/herb/cannabis))
			if (src.fuel >= src.maxfuel)
				boutput(user, "<span style=\"color:red\">The furnace is already full!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing weed into [src]!</span>") // four fuckin twenty all day
			var/staystill = user.loc
			for(var/obj/item/plant/herb/cannabis/M in view(1,user))
				src.fuel += 30
				src.stoked += 10
				qdel (M)
				if (src.fuel >= src.maxfuel)
					src.fuel = src.maxfuel
					boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")
					break
				sleep(3)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing weed into [src]!</span>")

		else if (istype(O, /obj/item/raw_material/plasmastone))
			if (src.fuel >= src.maxfuel)
				boutput(user, "<span style=\"color:red\">The furnace is already full!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] begins quickly stuffing ore into [src]!</span>")
			var/staystill = user.loc
			for(var/obj/item/raw_material/plasmastone/M in view(1,user))
				src.fuel += 800
				qdel (M)
				if (src.fuel >= src.maxfuel)
					src.fuel = src.maxfuel
					boutput(user, "<span style=\"color:blue\">The furnace is now full!</span>")
					break
				sleep(3)
				if (user.loc != staystill) break
			boutput(user, "<span style=\"color:blue\">You finish stuffing ore into [src]!</span>")

		else if (istype(O, /obj/critter))
			if (src.fuel >= src.maxfuel)
				boutput(user, "<span style=\"color:red\">The furnace is already full!</span>")
				return
			var/obj/critter/C = O
			if (C.alive)
				boutput(user, "<span style=\"color:red\">This would work a lot better if you killed it first!</span>")
				return
			user.visible_message("<span style=\"color:blue\">[user] [pick("crams", "shoves", "pushes", "forces")] [O] into [src]!</span>")
			src.fuel += initial(C.health) * 8
			src.stoked += max(C.quality / 2, 0)
			qdel(O)
		else ..()
		src.updateUsrDialog()

	suicide(var/mob/user as mob)
		user.visible_message("<span style=\"color:red\"><b>[user] climbs into the furnace!</b></span>")
		user.death(1)
		if (user.mind)
			user.ghostize()
			qdel(user)
		else qdel(user)
		src.fuel += 400
		if(src.fuel >= src.maxfuel)
			src.fuel = src.maxfuel
		return 1