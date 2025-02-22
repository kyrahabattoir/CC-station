// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/space_heater
	anchored = 0
	density = 1
	icon = 'icons/obj/atmospherics/atmos.dmi'
	icon_state = "sheater0"
	name = "space heater"
	desc = "Made by Space Amish using traditional space techniques, this heater is guaranteed not to set the station on fire."
	var/obj/item/cell/cell
	var/on = 0
	var/open = 0
	var/set_temperature = 50		// in celcius, add T0C for kelvin
	var/heating_power = 40000
	mats = 8
	flags = FPRINT


	New()
		..()
		cell = new(src)
		cell.charge = 1000
		cell.maxcharge = 1000
		update_icon()
		return

	proc/update_icon()
		if(open)
			icon_state = "sheater-open"
		else
			icon_state = "sheater[on]"
		return

	examine()
		set src in oview(12)
		if (!( usr ))
			return
		boutput(usr, "This is [bicon(src)] \an [src.name].")
		boutput(usr, src.desc)

		boutput(usr, "The heater is [on ? "on" : "off"] and the hatch is [open ? "open" : "closed"].")
		if(open)
			boutput(usr, "The power cell is [cell ? "installed" : "missing"].")
		else
			boutput(usr, "The charge meter reads [cell ? round(cell.percent(),1) : 0]%")
		return


	attackby(obj/item/I, mob/user)
		if(istype(I, /obj/item/cell))
			if(open)
				if(cell)
					boutput(user, "There is already a power cell inside.")
					return
				else
					// insert cell
					var/obj/item/cell/C = usr.equipped()
					if(istype(C))
						user.drop_item()
						cell = C
						C.set_loc(src)
						C.add_fingerprint(usr)

						user.visible_message("<span style=\"color:blue\">[user] inserts a power cell into [src].</span>", "<span style=\"color:blue\">You insert the power cell into [src].</span>")
			else
				boutput(user, "The hatch must be open to insert a power cell.")
				return
		else if(istype(I, /obj/item/screwdriver))
			open = !open
			user.visible_message("<span style=\"color:blue\">[user] [open ? "opens" : "closes"] the hatch on the [src].</span>", "<span style=\"color:blue\">You [open ? "open" : "close"] the hatch on the [src].</span>")
			update_icon()
			if(!open && user.machine == src)
				user << browse(null, "window=spaceheater")
				user.machine = null
		else
			..()
		return

	attack_hand(mob/user as mob)
		src.add_fingerprint(user)
		if(open)

			var/dat
			dat = "Power cell: "
			if(cell)
				dat += "<A href='byond://?src=\ref[src];op=cellremove'>Installed</A><BR>"
			else
				dat += "<A href='byond://?src=\ref[src];op=cellinstall'>Removed</A><BR>"

			dat += "Power Level: [cell ? round(cell.percent(),1) : 0]%<BR><BR>"

			dat += "Set Temperature: "

			dat += "<A href='?src=\ref[src];op=temp;val=-5'>-</A>"

			dat += " [set_temperature]&deg;C "
			dat += "<A href='?src=\ref[src];op=temp;val=5'>+</A><BR>"

			user.machine = src
			user << browse("<HEAD><TITLE>Space Heater Control Panel</TITLE></HEAD><TT>[dat]</TT>", "window=spaceheater")
			onclose(user, "spaceheater")




		else
			on = !on
			user.visible_message("<span style=\"color:blue\">[user] switches [on ? "on" : "off"] the [src].</span>","<span style=\"color:blue\">You switch [on ? "on" : "off"] the [src].</span>")
			update_icon()
		return


	Topic(href, href_list)
		if (usr.stat)
			return
		if ((in_range(src, usr) && istype(src.loc, /turf)) || (istype(usr, /mob/living/silicon)))
			usr.machine = src

			switch(href_list["op"])

				if("temp")
					var/value = text2num(href_list["val"])

					// limit to 20-90 degC
					set_temperature = dd_range(20, 90, set_temperature + value)

				if("cellremove")
					if(open && cell && !usr.equipped())
						usr.put_in_hand_or_drop(cell)
						cell.updateicon()
						cell = null

						usr.visible_message("<span style=\"color:blue\">[usr] removes the power cell from \the [src].</span>", "<span style=\"color:blue\">You remove the power cell from \the [src].</span>")


				if("cellinstall")
					if(open && !cell)
						var/obj/item/cell/C = usr.equipped()
						if(istype(C))
							usr.drop_item()
							cell = C
							C.set_loc(src)
							C.add_fingerprint(usr)

							usr.visible_message("<span style=\"color:blue\">[usr] inserts a power cell into \the [src].</span>", "<span style=\"color:blue\">You insert the power cell into \the [src].</span>")

			updateDialog()
		else
			usr << browse(null, "window=spaceheater")
			usr.machine = null
		return



	process()
		if(on)
			if(cell && cell.charge > 0)

				var/turf/simulated/L = loc
				if(istype(L))
					var/datum/gas_mixture/env = L.return_air()
					if(env.temperature < (set_temperature+T0C))

						var/transfer_moles = 0.25 * env.total_moles()

						var/datum/gas_mixture/removed = env.remove(transfer_moles)

						//boutput(world, "got [transfer_moles] moles at [removed.temperature]")

						if(removed)

							var/heat_capacity = removed.heat_capacity()
							//boutput(world, "heating ([heat_capacity])")
							if(heat_capacity)
								removed.temperature = (removed.temperature*heat_capacity + heating_power)/heat_capacity
							cell.use(heating_power/20000)

							//boutput(world, "now at [removed.temperature]")

						env.merge(removed)

						//boutput(world, "turf now at [env.temperature]")


			else
				on = 0
				update_icon()


		return