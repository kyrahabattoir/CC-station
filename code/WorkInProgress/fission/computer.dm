// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/computer/fission
	name = "Fission Console"
	icon_state = "comm"

//	icon = 'icons/obj/machines/nuclear.dmi'
//	icon_state = "Sing2"

	var/id = 0.0

	req_access = list(access_heads)
	var/authenticated = 0

	var/screen = 1.0

	var/obj/machinery/power/fission/engine/theEngine = null
	var/obj/machinery/fission/reactor/selectedReactor = null

	New()
		..()

	process()
		..()

	attackby(I as obj, user as mob)
		src.attack_hand(user)
		return

	attack_ai(var/mob/user as mob)
		return src.attack_hand(user)

	attack_hand(var/mob/user as mob)
		if(..())
			return
		user.machine = src

		var/dat = "<head><title>Fission Console</title></head><body>"

		if(src.authenticated)
			// If no engine then fuck this
			if(!theEngine || !theEngine.active)
				dat += "<BR>\[ No Engine Detected \]<BR>"
			else
				switch(src.screen)

					// Main engine screen
					if(1.0)

						dat += {"<BR>
						\[ This is where image of power goes \]<BR>
						Power generated: [num2text(theEngine.lastpower,5)]W<BR>
						<BR>
						Please pick a reactor to inspect:<BR>
						"}

						var/i = 1
						for(var/obj/machinery/fission/reactor/R in theEngine.reactors)
							dat += "<BR>\[ <A HREF='?src=\ref[src];reactor=\ref[R]'>Reactor [i++]</A> \]"

					// Screen for individual reactor
					if(2.0)

						dat += {"
						<BR>
						\[ Reactor \] <BR>
						<BR>
						Temperature: [num2text(selectedReactor.temperature,5)] K<BR>
						Pressure: [num2text(selectedReactor.pressure,5)] kPa<BR>
						<BR>
						\[ Fuel Rods \]
						<BR>"}

						var/i = 1
						for(var/obj/item/rod/fuel/F in selectedReactor.fuelRods)
							dat += {"
							<BR>
							[i++]:
							[F.name] -
							[F.amount/F.maxAmount > 0.1 ? "[num2text(( F.amount/F.maxAmount )*100, 4)]%" : "<font color=red>[num2text(( F.amount/F.maxAmount )*100, 4)]%</font>"] -
							[F.lowered ? "<A HREF='?src=\ref[src];raise=\ref[F]'>\[Raise Tube\]</A>" : "<A HREF='?src=\ref[src];low=\ref[F]'>\[Lower Tube\]</A> <A HREF='?src=\ref[src];flush=\ref[F]'>\[Flush Tube\]</A> <A HREF='?src=\ref[src];eject=\ref[F]'>\[Eject Tube\]</A>"]
							"}

						dat += "<BR><BR>\[ Control Rods \]<BR>"

						i = 1
						for(var/obj/item/rod/control/CR in selectedReactor.controlRods)
							dat += {"
							<BR>
							[i++]:
							[CR.name] -
							Condition: [CR.condition < 10 ? "[CR.condition]%" : "<font color=red>[CR.condition]%</font>"]
							[CR.lowered ? "<A HREF='?src=\ref[src];raise=\ref[CR]'>\[Raise Tube\]</A>" : "<A HREF='?src=\ref[src];low=\ref[CR]'>\[Lower Tube\]</A> <A HREF='?src=\ref[src];eject=\ref[CR]'>\[Eject Tube\]</A>"]
							"}

						dat += "<BR><BR>\[ <A HREF='?src=\ref[src];operation=back'>Back</A> \]"

				dat += "<BR><BR>\[ <A HREF='?src=\ref[src];operation=logout'>Log Out</A> \]"
		else
			dat += "<BR>\[ <A HREF='?src=\ref[src];operation=login'>Log In</A> \]"

		dat += "<BR><BR><BR>\[ <A HREF='?action=mach_close&window=fission'>Close</A> \]"
		user << browse(dat, "window=fission;size=500x300")
		onclose(user, "fission")


	Topic(href, href_list)
		if(..())
			return
		usr.machine = src

		if(href_list["reactor"])
			var/obj/machinery/fission/reactor/R = locate(href_list["reactor"])

			selectedReactor = R
			src.screen = 2.0

		else if(href_list["raise"])
			var/obj/item/rod/R = locate(href_list["raise"])
			selectedReactor.rodsLowered = 0
			R.lowered = 0

		else if(href_list["low"])
			var/obj/item/rod/R = locate(href_list["low"])
			selectedReactor.rodsLowered = 1
			R.lowered = 1

		else if(href_list["flush"])
			var/obj/item/rod/fuel/F = locate(href_list["flush"])
			F.amount = 0

		else if(href_list["eject"])
			var/obj/item/rod/R = locate(href_list["eject"])
			if(R in selectedReactor.fuelRods)
				selectedReactor.fuelRods.Remove(R)
				// Keep the list length at 5
				selectedReactor.fuelRods.len = 5
			else if(R in selectedReactor.controlRods)
				selectedReactor.controlRods.Remove(R)
				// Keep the list length at 5
				selectedReactor.controlRods.len = 5
			else
				boutput(world, "Unable to remove [R] from lists")
			R.set_loc(selectedReactor.loc)

		else if(href_list["operation"])
			switch(href_list["operation"])
				if("back")
					src.screen = 1.0

				if("login")
					var/mob/M = usr
					var/obj/item/card/id/I = M.equipped()
					if (I && istype(I))
						if(src.check_access(I))
							authenticated = 1

				if("logout")
					authenticated = 0

		else
			return

		src.updateUsrDialog()