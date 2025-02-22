// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/hud/pod
	var/obj/screen/hud
		engine
		life_support
		comms
		sensors
		sensors_use
		weapon
		secondary
		lock
		set_code
		rts
		wormhole
		use_comms
		leave

	click_check = 0
	var/image/missing
	var/datum/healthBar/health_bar
	var/obj/machinery/vehicle/master

	New(P)
		master = P
		missing = image('icons/mob/hud_pod.dmi', "marker")
		engine = create_screen("engine", "Engine", 'icons/mob/hud_pod.dmi', "engine-off", "NORTH+1,WEST", tooltipTheme = "pod-alt")
		wormhole = create_screen("wormhole", "Create Wormhole", 'icons/mob/hud_pod.dmi', "wormhole", "NORTH+1,WEST+1", tooltipTheme = "pod")
		life_support = create_screen("life_support", "Life Support", 'icons/mob/hud_pod.dmi', "life_support-off", "NORTH+1,WEST+2", tooltipTheme = "pod-alt")
		comms = create_screen("comms", "Comms", 'icons/mob/hud_pod.dmi', "comms-off", "NORTH+1,WEST+3", tooltipTheme = "pod-alt")
		use_comms = create_screen("comms_system", "Use Comms System", 'icons/mob/hud_pod.dmi', "comms_system", "NORTH+1,WEST+4", tooltipTheme = "pod")
		sensors = create_screen("sensors", "Sensors", 'icons/mob/hud_pod.dmi', "sensors-off", "NORTH+1,WEST+5", tooltipTheme = "pod-alt")
		sensors_use = create_screen("sensors_use", "Activate Sensors", 'icons/mob/hud_pod.dmi', "sensors-use", "NORTH+1,WEST+6", tooltipTheme = "pod")
		weapon = create_screen("weapon", "Main Weapon", 'icons/mob/hud_pod.dmi', "weapon-off", "NORTH+1,WEST+7", tooltipTheme = "pod-alt")
		secondary = create_screen("secondary", "Secondary System", 'icons/mob/hud_pod.dmi', "blank", "NORTH+1,WEST+8", tooltipTheme = "pod")
		lock = create_screen("lock", "Lock", 'icons/mob/hud_pod.dmi', "weapon-off", "NORTH+1,WEST+9", tooltipTheme = "pod-alt")
		set_code = create_screen("set_code", "Set Lock code", 'icons/mob/hud_pod.dmi', "set-code", "NORTH+1,WEST+10", tooltipTheme = "pod")
		rts = create_screen("return_to_station", "Return To Station", 'icons/mob/hud_pod.dmi', "return-to-station", "NORTH+1,WEST+11", tooltipTheme = "pod")
		leave = create_screen("leave", "Leave Pod", 'icons/mob/hud_pod.dmi', "leave", "SOUTH,EAST", tooltipTheme = "pod-alt")
		health_bar = new(3)
		health_bar.add_to_hud(src)
		if (master)
			update_health()
			update_systems()
			update_states()

	proc/detach_all_clients()
		for (var/client/C in clients)
			remove_client(C)

	proc/check_clients()
		for (var/client/C in clients)
			var/mob/M = C.mob
			if (M.loc != master)
				remove_client(C)

	proc/update_health()
		check_clients()
		health_bar.update_health_overlay(master.health, master.maxhealth, 0, 0)

	proc/update_states()
		check_clients()
		if (master.engine)
			if (master.engine.active)
				engine.icon_state = "engine-on"
				wormhole.overlays.len = 0
			else
				engine.icon_state = "engine-off"
				if (!wormhole.overlays.len)
					wormhole.overlays += missing

		if (master.life_support)
			if (master.life_support.active)
				life_support.icon_state = "life_support-on"
			else
				life_support.icon_state = "life_support-off"

		if (master.com_system)
			if (master.com_system.active)
				comms.icon_state = "comms-on"
				rts.overlays.len = 0
				use_comms.overlays.len = 0
			else
				comms.icon_state = "comms-off"
				if (!rts.overlays.len)
					rts.overlays += missing
				if (!use_comms.overlays.len)
					use_comms.overlays += missing

		if (master.m_w_system)
			if (master.m_w_system.active)
				weapon.icon_state = "weapon-on"
			else
				weapon.icon_state = "weapon-off"

		if (master.sec_system)
			if (master.sec_system.f_active)
				secondary.icon_state = master.sec_system.hud_state
			else if (master.sec_system.active)
				secondary.icon_state = "[master.sec_system.hud_state]-on"
			else
				secondary.icon_state = "[master.sec_system.hud_state]-off"

		if (master.sensors)
			if (master.sensors.active)
				sensors.icon_state = "sensors-on"
				sensors_use.overlays.len = 0
			else
				sensors.icon_state = "sensors-off"
				if (!sensors_use.overlays.len)
					sensors_use.overlays += missing

		if (master.lock)
			if (master.lock.code && master.locked)
				lock.icon_state = "lock-locked"
			else
				lock.icon_state = "lock-unlocked"

	proc/update_systems()
		check_clients()
		if (master.engine)
			engine.name = master.engine.name
			engine.overlays.len = 0
		else
			engine.name = "Engine"
			if (!engine.overlays.len)
				engine.overlays += missing

		if (master.life_support)
			life_support.name = master.life_support.name
			life_support.overlays.len = 0
		else
			life_support.name = "Life Support"
			if (!life_support.overlays.len)
				life_support.overlays += missing

		if (master.com_system)
			comms.name = master.com_system.name
			comms.overlays.len = 0
			if (!master.com_system.active)
				if (!rts.overlays.len)
					rts.overlays += missing
				if (!use_comms.overlays.len)
					use_comms.overlays += missing
			else
				rts.overlays.len = 0
				use_comms.overlays.len = 0
		else
			comms.name = "Comms"
			if (!comms.overlays.len)
				comms.overlays += missing
			if (!rts.overlays.len)
				rts.overlays += missing
			if (!use_comms.overlays.len)
				use_comms.overlays += missing

		if (master.m_w_system)
			weapon.name = master.m_w_system.name
			weapon.overlays.len = 0
		else
			weapon.name = "Main Weapon"
			if (!weapon.overlays.len)
				weapon.overlays += missing

		if (master.sec_system)
			secondary.name = master.sec_system.name
			secondary.overlays.len = 0
		else
			secondary.name = "Secondary System"
			if (!secondary.overlays.len)
				secondary.overlays += missing
			secondary.icon_state = "blank"

		if (master.sensors)
			sensors.name = master.sensors.name
			sensors.overlays.len = 0
			if (!master.sensors.active)
				sensors_use.overlays.len = 0
			else
				if (!sensors_use.overlays.len)
					sensors_use.overlays += missing
		else
			sensors.name = "Sensors"
			if (!sensors.overlays.len)
				sensors.overlays += missing
			if (!sensors_use.overlays.len)
				sensors_use.overlays += missing

		if (master.lock)
			lock.name = master.lock.name
			lock.overlays.len = 0
			set_code.overlays.len = 0
		else
			lock.name = "Lock"
			if (!lock.overlays.len)
				lock.overlays += missing
			if (!set_code.overlays.len)
				set_code.overlays += missing

	clicked(id, mob/user, list/params)
		if (user.loc != master)
			boutput(user, "<span style=\"color:red\">You're not in the pod doofus. (Call 1-800-CODER.)</span>")
			remove_client(user.client)
			return
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0)
			boutput(user, "<span style=\"color:red\">Not when you are incapacitated.</span>")
			return
		// WHAT THE FUCK PAST MARQUESAS
		// GET IT TOGETHER
		// - Future Marquesas
		// switch ("id")
		switch (id)
			if ("engine")
				if (master.engine)
					if (user != master.pilot)
						boutput(user, "<span style=\"color:red\">Only the pilot may do that!</span>")
						return
					master.engine.toggle()
			if ("life_support")
				if (master.life_support)
					master.life_support.toggle()
			if ("comms")
				if (master.com_system)
					master.com_system.toggle()
					update_systems()
			if ("comms_system")
				if(master.com_system)
					if(master.com_system.active)
						master.com_system.External()
					else
						boutput(usr, "[master.ship_message("SYSTEM OFFLINE")]")
				else
					boutput(usr, "[master.ship_message("System not installed in ship!")]")
			if ("weapon")
				if (master.m_w_system)
					master.m_w_system.toggle()
			if ("secondary")
				if (master.sec_system)
					master.sec_system.toggle()
			if ("sensors")
				if (master.sensors)
					master.sensors.toggle()
			if ("sensors_use")
				if (master.sensors && master.sensors.active)
					master.sensors.opencomputer(usr)
			if ("lock")
				if (master.lock)
					if (!master.lock.code || master.lock.code == "")
						master.lock.configure_mode = 1
						if (master)
							master.locked = 0
						master.lock.code = ""

						boutput(usr, "<span style=\"color:blue\">Code reset.  Please type new code and press enter.</span>")
						master.lock.show_lock_panel(usr)
					else if (!master.locked)
						master.locked = 1
						boutput(usr, "<span style=\"color:red\">The lock mechanism clunks locked.</span>")
					else if (master.locked)
						master.locked = 0
						boutput(usr, "<span style=\"color:red\">The ship mechanism clicks unlocked.</span>")
			if ("set_code")
				if (master.lock)
					master.lock.configure_mode = 1
					if (master)
						master.locked = 0
					master.lock.code = ""
					boutput(usr, "<span style=\"color:blue\">Code reset.  Please type new code and press enter.</span>")
					master.lock.show_lock_panel(usr)
			if ("return_to_station")
				if(master.com_system)
					if(master.com_system.active)
						master.going_home = 1
					else
						boutput(usr, "[master.ship_message("SYSTEM OFFLINE")]")
				else
					boutput(usr, "[master.ship_message("System not installed in ship!")]")
			if ("leave")
				master.eject(usr)
			if ("wormhole")
				if(master.engine)
					if(master.engine.active)
						if(master.engine.ready)
							master.engine.Wormhole()
						else
							boutput(usr, "[master.ship_message("Engine recharging wormhole capabilities!")]")
					else
						boutput(usr, "[master.ship_message("SYSTEM OFFLINE")]")
				else
					boutput(usr, "[master.ship_message("System not installed in ship!")]")

		update_states()
