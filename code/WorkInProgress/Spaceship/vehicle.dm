// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/vehicle
	name = "Vehicle Pod"
	icon = 'icons/obj/ship.dmi'
	icon_state = "podfire"
	density = 1
	flags = FPRINT | USEDELAY
	anchored = 1.0
	var/datum/effects/system/ion_trail_follow/ion_trail = null
	var/mob/pilot = null //The mob which actually flys the ship
	var/capacity = 3 //How many passengers the ship can hold
	var/passengers = 0 //The number of passengers in the ship
	var/obj/item/tank/atmostank = null // provides the air for the passengers
	var/obj/item/tank/fueltank = null // provides fuel, different mixes affect engine performance
	var/list/components = list() //List of current components in ship
	var/obj/item/shipcomponent/engine/engine = null //without this the ship can't do much
	var/obj/item/shipcomponent/life_support/life_support = null // cleans and extends the life of the atmos tank
	var/obj/item/shipcomponent/communications/com_system = null
	var/obj/item/shipcomponent/mainweapon/m_w_system = null
	var/obj/item/shipcomponent/secondary_system/sec_system = null
	var/obj/item/shipcomponent/sensor/sensors = null
	var/obj/item/shipcomponent/secondary_system/lock/lock = null
	var/uses_weapon_overlays = 0
	var/health = 200
	var/maxhealth = 200
	var/health_percentage = 100 // cogwerks: health percentage check for bigpods
	var/damage_overlays = 0 // cogwerks: 0 = normal, 1 = dented, 2 = on fire
	var/panel_status = 0 //Determines if parts can be added/removed
	var/obj/item/device/radio/intercom/ship/intercom = null //All ships have these is used by communication array
	var/weapon_class = 0 //what weapon class a ship is
	var/powercapacity = 0 //How much power the ship's components can use, set by engine
	var/powercurrent = 0 //How much power the components are using
	var/speed = 2 // base speed, this is the delay in ticks. lower is faster
	var/stall = 0 // slow the ship down when firing
	var/flying = 0 // holds the direction the ship is currently drifting, or 0 if stopped
	var/facing = 0 // holds the direction the ship is currently facing
	var/going_home = 0 // set to 1 when the com system locates the station, next z level crossing will head to 1
	var/fire_delay = 0 // stop people from firing like crazy
	var/image/fire_overlay = null
	var/image/damage_overlay = null
	var/exploding = 0 // don't blow up a bunch of times sheesh
	var/boarding = 0  // bandaid for shit getting ruined by imaginary passengers
	var/locked = 0 // todo: stop people from carjacking pods in flight so easily
	var/owner = null // to use with locked var
	var/cleaning = 0 // another safety check, god knows shit will find a way to go wrong without it
	var/keyed = 0 // Did some jerk key this pod? HUH??
	var/datum/hud/pod/myhud
	var/view_offset_x = 0
	var/view_offset_y = 0

	//////////////////////////////////////////////////////
	///////Life Support Stuff ////////////////////////////
	/////////////////////////////////////////////////////
	remove_air(amount as num)
		if(atmostank && atmostank.air_contents)
			if(life_support && life_support.active && atmostank.air_contents.return_pressure() < 1000)
				life_support.power_used = 5 * passengers + 15
				atmostank.air_contents.oxygen += amount / 5
				atmostank.air_contents.nitrogen += 4 * amount / 5
				if (atmostank.air_contents.carbon_dioxide > 0)
					atmostank.air_contents.carbon_dioxide -= HUMAN_NEEDED_OXYGEN * 2
					atmostank.air_contents.carbon_dioxide = max(atmostank.air_contents.carbon_dioxide, 0)
				if(atmostank.air_contents.temperature > 310)
					atmostank.air_contents.temperature -= max(atmostank.air_contents.temperature - 310, 5)
				if(atmostank.air_contents.temperature < 310)
					atmostank.air_contents.temperature += max(310 - atmostank.air_contents.temperature, 5)

			return atmostank.remove_air(amount)

		else
			life_support.power_used = 0
			var/turf/T = get_turf(src)
			return T.remove_air(amount)

	/////////////////////////////////////////////////////////
	///////Attack Code									////
	////////////////////////////////////////////////////////
	attack_hand(mob/user as mob)
		if(panel_status)
			open_parts_panel(user)
			return
		else if (locked && lock)
			lock.show_lock_panel(user,0)
			return

	attackby(obj/item/W as obj, mob/living/user as mob)
		if (health < maxhealth && istype(W, /obj/item/weldingtool) && W:welding)
			if (W:get_fuel() > 2)
				W:use_fuel(1)
			else
				boutput(user, "Need more welding fuel!")
				return
			src.health += 30
			checkhealth()
			src.add_fingerprint(user)
			src.visible_message("<span style=\"color:red\">[user] has fixed some of the dents on [src]!</span>")
			return

		if (panel_status)
			if (istype(W, /obj/item/shipcomponent))
				Install(W)
				return

			if (istype(W, /obj/item/crowbar))
				panel_status = 0
				boutput(user, "You close the maintenance panel.")
				return

			if (istype(W, /obj/item/ammo/bullets))
				if (W.disposed)
					return
				if (src.m_w_system)
					if (!src.m_w_system.uses_ammunition)
						boutput(user, "<span style=\"color:red\">That weapon does not require ammunition.</span>")
						return
					if (src.m_w_system.remaining_ammunition >= 50)
						boutput(user, "<span style=\"color:red\">The automated loader for the weapon cannot hold any more ammunition.</span>")
						return
					var/obj/item/ammo/bullets/ammo = W
					if (!ammo.amount_left)
						return
					if (src.m_w_system.current_projectile.type != ammo.ammo_type.type)
						boutput(user, "<span style=\"color:red\">The [m_w_system] cannot fire that kind of ammunition.</span>")
						return
					var/may_load = 50 - src.m_w_system.remaining_ammunition
					if (may_load < ammo.amount_left)
						ammo.amount_left -= may_load
						src.m_w_system.remaining_ammunition += may_load
						boutput(user, "<span style=\"color:blue\">You load [may_load] ammunition from [ammo]. [ammo] now contains [ammo.amount_left] ammunition.</span>")
						logTheThing("combat", user, null, "reloads [src]'s [src.m_w_system.name] (<b>Ammo type:</b> <i>[src.m_w_system.current_projectile.type]</i>) at [log_loc(src)].") // Might be useful (Convair880)
						return
					else
						src.m_w_system.remaining_ammunition += ammo.amount_left
						ammo.amount_left = 0
						boutput(user, "<span style=\"color:blue\">You load [ammo] into [m_w_system].</span>")
						logTheThing("combat", user, null, "reloads [src]'s [src.m_w_system.name] (<b>Ammo type:</b> <i>[src.m_w_system.current_projectile.type]</i>) at [log_loc(src)].")
						qdel(ammo)
						return
				else
					boutput(user, "<span style=\"color:red\">No main weapon system installed.</span>")
					return

		if (istype(W, /obj/item/crowbar))
			if (src.lock && src.locked)
				boutput(usr, "<span style=\"color:red\">You can't open the maintenance panel while [src] is locked.</span>")
				lock.show_lock_panel(usr, 0)
				return
			panel_status = 1
			if (src.bound_width > 32 || src.bound_height > 32)
				boutput(user, "You open the maintenance panel. It is on the lower left side of the ship, you must access the components from there.")
			else
				boutput(user, "You open the maintenance panel.")
			return

		if (istype(W, /obj/item/device/key))
			user.visible_message("<span style=\"color:red\"><B>[user] scratches [src] with \the [W]! [prob(75) ? pick_string("descriptors.txt", "jerks") : null]</B></span>", null,"<span style=\"color:red\">You hear a metallic scraping sound!</span>")
			if(!keyed) src.name = "scratched-up [src.name]"
			src.keyed++
			src.add_fingerprint(user)
			return
		..()

		switch(W.damtype)
			if("fire")
				if(src.material)
					src.material.triggerTemp(src, W.force * 1000)
				return /////ships should pretty much be immune to fire
			if("brute")
				src.health -= W.force

		checkhealth()

	Topic(href, href_list)
		if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0 || usr.restrained())
			return
		///////////////////////////////////////
		//////Main Computer Code		//////
		//////////////////////////////////////
		if (usr.loc == src)
			usr.machine = src
			if (href_list["dengine"])
				if (usr != pilot)
					boutput(usr, "[ship_message("Only the pilot may do this!")]")
					return
				engine.deactivate()
				src.updateDialog()

			else if (href_list["aengine"])
				engine.activate()
				src.updateDialog()

			else if (href_list["dlife"])
				life_support.deactivate()
				src.updateDialog()

			else if (href_list["alife"])
				life_support.activate()
				src.updateDialog()

			else if (href_list["acom"])
				com_system.activate()
				src.updateDialog()

			else if (href_list["dcom"])
				com_system.deactivate()
				src.updateDialog()

			else if (href_list["amweapon"])
				m_w_system.activate()
				src.updateDialog()

			else if (href_list["dmweapon"])
				m_w_system.deactivate()
				src.updateDialog()

			else if (href_list["asensors"])
				sensors.activate()
				src.updateDialog()

			else if (href_list["dsensors"])
				sensors.deactivate()
				src.updateDialog()

			else if (href_list["asec_system"])
				sec_system.activate()
				src.updateDialog()

			else if (href_list["dsec_system"])
				sec_system.deactivate()
				src.updateDialog()

			else if (href_list["comcomp"])
				com_system.opencomputer(usr)
				src.updateDialog()

			else if (href_list["mweaponcomp"])
				m_w_system.opencomputer(usr)
				src.updateDialog()

			else if (href_list["enginecomp"])
				engine.opencomputer(usr)
				src.updateDialog()

			else if (href_list["sensorcomp"])
				sensors.opencomputer(usr)
				src.updateDialog()

			else if (href_list["sec_systemcomp"])
				sec_system.opencomputer(usr)
				src.updateDialog()

			src.add_fingerprint(usr)
			for (var/mob/M in src)
				if ((M.client && M.machine == src))
					src.access_computer(M)
			myhud.update_states()
		///////////////////////////////////////
		///////Panel Code//////////////////////
		///////////////////////////////////////
		else if (panel_status && (get_dist(src, usr) <= 1) && isturf(src.loc))
			if (passengers)
				boutput(usr, "<span style=\"color:red\">You can't modify parts with somebody inside.</span>")
				return

			if (src.lock && src.locked)
				boutput(usr, "<span style=\"color:red\">You can't modify parts while [src] is locked.</span>")
				lock.show_lock_panel(usr, 0)
				return

			usr.machine = src
			if (href_list["unengine"])
				if (src.engine)
					engine.deactivate()
					components -= engine
					engine.set_loc(src.loc)
					engine = null
					src.updateDialog()

			else if (href_list["un_lock"])
				if (src.lock)
					if (src.locked)
						lock.show_lock_panel(usr, 0)
					else
						lock.deactivate()
						components -= lock
						lock.set_loc(src.loc)
						lock = null
						src.updateDialog()

			else if (href_list["unlife"])
				if (src.life_support)
					life_support.deactivate()
					components -= life_support
					life_support.set_loc(src.loc)
					life_support = null
					src.updateDialog()

			else if (href_list["uncom"])
				if (src.com_system)
					com_system.deactivate()
					components -= com_system
					com_system.set_loc(src.loc)
					com_system = null
					src.updateDialog()

			else if (href_list["unm_w"])
				if (src.m_w_system)
					m_w_system.deactivate()
					components -= m_w_system
					if (uses_weapon_overlays)
						src.overlays -= image('icons/effects/64x64.dmi', "[m_w_system.appearanceString]")
					m_w_system.set_loc(src.loc)
					m_w_system = null
					src.updateDialog()

			else if (href_list["unsec_system"])
				if (src.sec_system)
					sec_system.deactivate()
					components -= sec_system
					sec_system.set_loc(src.loc)
					sec_system = null
					src.updateDialog()

			else if (href_list["unsensors"])
				if (src.sensors)
					sensors.deactivate()
					components -= sensors
					sensors.set_loc(src.loc)
					sensors = null
					src.updateDialog()

			// Added logs for atmos tanks and such here, because booby-trapping pods is becoming a trend (Convair880).
			else if (href_list["atmostank"])
				if (src.atmostank)
					boutput(usr, "<span style=\"color:red\">There's already a tank in that slot.</span>")
					return
				var/obj/item/tank/W = usr.equipped()
				if (W && istype(W, /obj/item/tank))
					logTheThing("vehicle", usr, null, "replaces [src.name]'s air supply with [W] [log_atmos(W)] at [log_loc(src)].")
					boutput(usr, "<span style=\"color:blue\">You attach the [W.name] to [src.name]'s air supply valve.</span>")
					usr.drop_item()
					W.set_loc(src)
					src.atmostank = W
					src.updateDialog()
				else
					boutput(usr, "<span style=\"color:red\">That doesn't fit there.</span>")

			else if (href_list["takeatmostank"])
				if (src.atmostank)
					logTheThing("vehicle", usr, null, "removes [src.name]'s air supply [log_atmos(atmostank)] at [log_loc(src)].")
					atmostank.set_loc(src.loc)
					atmostank = null
					src.updateDialog()
				else
					boutput(usr, "<span style=\"color:red\">There's no tank in the slot.</span>")
					return

			else if (href_list["fueltank"])
				if (src.fueltank)
					boutput(usr, "<span style=\"color:red\">There's already a tank in that slot.</span>")
					return
				var/obj/item/tank/W = usr.equipped()
				if (W && istype(W, /obj/item/tank))
					logTheThing("vehicle", usr, null, "replaces [src.name]'s engine fuel supply with [W] [log_atmos(W)] at [log_loc(src)].")
					boutput(usr, "<span style=\"color:blue\">You attach the [W.name] to [src.name]'s fuel supply valve.</span>")
					usr.drop_item()
					W.set_loc(src)
					src.fueltank = W
					src.updateDialog()
				else
					boutput(usr, "<span style=\"color:red\">That doesn't fit there.</span>")
					return

			else if (href_list["takefueltank"])
				if (src.fueltank)
					logTheThing("vehicle", usr, null, "removes [src.name]'s engine fuel supply [log_atmos(fueltank)] at [log_loc(src)].")
					fueltank.set_loc(src.loc)
					fueltank = null
					src.updateDialog()
				else
					boutput(usr, "<span style=\"color:red\">There's no tank in the slot.</span>")
					return

			myhud.update_systems()

		else
			if (panel_status)
				usr << browse(null, "window=ship_maint")
				return

			usr << browse(null, "window=ship_main")
			return
		return

	proc/AmmoPerShot()
		return 1

	proc/ShootProjectiles(var/mob/user, var/datum/projectile/PROJ, var/shoot_dir)
		var/obj/projectile/P = shoot_projectile_DIR(src, PROJ, shoot_dir)
		P.mob_shooter = user

	bullet_act(var/obj/projectile/P)
		if(P.shooter == src)
			return
		//Wire: fix for Cannot read null.ks_ratio below
		if (!P.proj_data)
			return

		log_shot(P, src)

		if(src.material) src.material.triggerOnAttacked(src, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))
		for(var/atom/A in src)
			if(A.material)
				A.material.triggerOnAttacked(A, P.shooter, src, (ismob(P.shooter) ? P.shooter:equipped() : P.shooter))

		var/damage = 0
		damage = round((P.power*P.proj_data.ks_ratio), 1.0)
		switch(P.proj_data.damage_type)
			if(D_KINETIC)
				src.health -= damage/2
			if(D_PIERCING)
				src.health -= damage/1
			if(D_ENERGY)
				src.health -= damage/1.7
			if(D_SLASHING)
				src.health -= damage/3
			if(D_BURNING)
				if(src.material)
					src.material.triggerTemp(src, 5000)
				src.health -= damage/3
		checkhealth()
		if(P.proj_data.disruption)
			src.disrupt(P.proj_data.disruption)

	blob_act(var/power)
		src.health -= power * 2
		checkhealth()

	get_desc()
		if (src.keyed > 0)
			var/t = strings("descriptors.txt", "keyed")
			var/t_ind = max(min(round(keyed/10),10),0)
			. += "It has been keyed [keyed] time[s_es(keyed)]! [t_ind ? t[t_ind] : null]"

	proc/paint_pod(var/obj/item/pod/paintjob/P as obj, var/mob/user as mob)
		if (!P || !istype(P))
			return
		if (user)
			user.show_text("You paint [src].", "blue")
			user.u_equip(P)
		src.overlays += image(src.icon, P.pod_skin)
		qdel(P)
		return

	proc/disrupt(var/disruption as num)
		if(disruption)
			spawn(0)
				playsound(src.loc, pick('sound/machines/glitch1.ogg', 'sound/machines/glitch2.ogg', 'sound/machines/glitch3.ogg', 'sound/effects/electric_shock.ogg', 'sound/effects/elec_bzzz.ogg'), 50, 1)
				if(pilot)
					boutput(src.pilot, "[ship_message("WARNING! Electrical system disruption detected!")]")
				var/chance = disruption * 2.5
				for(var/obj/item/shipcomponent/S in src.components)
					var/my_chance = chance
					if (istype(S, /obj/item/shipcomponent/engine))
						my_chance -= 25
					if(prob(my_chance))
						S.deactivate()
						chance -= 25
						if (chance <= 0)
							return
		return

	emp_act()
		src.disrupt(10)
		return

	ex_act(severity)
		if (sec_system)
			if (sec_system.type == /obj/item/shipcomponent/secondary_system/crash)
				if (sec_system:crashable)
					return
		var/sevmod = 0
		sevmod = round(src.explosion_protection / 5)

		severity += sevmod

		switch (severity)
			if (1.0)
				src.health -= 65
				checkhealth()
			if(2.0)
				src.health -= 40
				checkhealth()
			if(3.0)
				src.health -= 25
				checkhealth()

	Bump(var/atom/A)
		//boutput(world, "[src] bumped into [A]")
		if (sec_system)
			if (sec_system.type == /obj/item/shipcomponent/secondary_system/crash)
				if (sec_system:crashable)
					sec_system:crashtime2(A)
		spawn (0)
			..()
			return
		return

	meteorhit(var/obj/O as obj)
		src.health -= 50
		checkhealth()

	Move(NewLoc,Dir=0,step_x=0,step_y=0)
		// set return value to default
		.=..(NewLoc,Dir,step_x,step_y)

		if (flying && facing != flying)
			dir = facing

	relaymove(mob/user as mob, direction)
		if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0)
			return
		if (!engine)
			boutput(usr, "[ship_message("WARNING! No engine detected!")]")
			return
		if (!powercapacity)
			//boutput(usr, "[ship_message("The ship doesn't have enough power!")]")
			return

		if ((user in src) && (user == pilot) && (src.engine.active))
			src.facing = direction
			if (src.dir == direction)
				if(flying == turn(src.dir,180))
					walk(src, 0)
					flying = 0
				else
					walk(src, src.dir, speed+stall)
					flying = src.dir
			else
				src.dir = direction

	disposing()
		myhud.detach_all_clients()
		if (pilot)
			pilot = null
		if (components)
			for(var/obj/S in components)
				S.dispose()
			components.len = 0
			components = null
		atmostank = null
		fueltank = null
		engine = null
		life_support = null
		com_system = null
		m_w_system = null
		sec_system = null
		sensors = null
		intercom = null
		fire_overlay = null
		damage_overlay = null
		ion_trail = null
		..()
	process()
		if(sec_system)
			if(sec_system.active)
				sec_system.run_component()
		return

	proc/checkhealth()
		myhud.update_health()
		if(istype(src, /obj/machinery/vehicle/pod_smooth)) // check to see if it's one of the new pods
			// sanitize values
			if(health > maxhealth)
				health = maxhealth
			if(health < 0)
				health = 0

			// find percentage of total health
			health_percentage = (health / maxhealth) * 100

			switch(health_percentage)

			//add or remove damage overlays, murderize the ship
				if(0)
					shipdeath()
					return
				if(1 to 25)
					if(damage_overlays != 2)
						particleMaster.SpawnSystem(new /datum/particleSystem/areaSmoke("#CCCCCC", 1000, src))
						damage_overlays = 2
						fire_overlay = image('icons/effects/64x64.dmi', "pod_fire")
						src.overlays += fire_overlay
						for(var/mob/living/carbon/human/M in src)
							M.update_burning(35)
							boutput(M, "<span style=\"color:red\"><b>The cabin bursts into flames!</b></span>")
							playsound(M.loc, "sound/machines/engine_alert1.ogg", 35, 0)
				if(26 to 50)
					if(damage_overlays < 1)
						damage_overlays = 1
						damage_overlay = image('icons/effects/64x64.dmi', "pod_damage")
						src.overlays += damage_overlay
				if(51 to INFINITY)
					if (damage_overlays)
						if(damage_overlays == 2)
							src.overlays -= fire_overlay
							src.overlays -= damage_overlay
							fire_overlay = null
						else if(damage_overlays == 1)
							src.overlays -= damage_overlay
						damage_overlays = 0
						damage_overlay = null

// if not a big pod, assume it's an old-style one instead
		else
			if(health<=0)
				shipdeath()
				return
			if(health > maxhealth)
				health = maxhealth

///////////////////////////////////////////////////////////////////////////
////////Install Ship Part////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/proc/Install(obj/item/shipcomponent/S as obj)
	switch(S.system)
		if("Engine")
			if(!src.engine)
				src.engine = S
			else
				boutput(usr, "That system already has a part!")
				return
		if("Communications")
			if(!com_system)
				src.com_system = S
			else
				boutput(usr, "That system already has a part!")
				return
		if("Life Support")
			if(!life_support)
				src.life_support = S
			else
				boutput(usr, "That system already has a part!")
				return
		if("Sensors")
			if(!sensors)
				src.sensors = S
			else
				boutput(usr, "That system already has a part!")
				return
		if("Secondary System")
			if(!sec_system)
				sec_system = S
			else
				boutput(usr, "That system already has a part!")
				return
		if("Main Weapon")
			if(!m_w_system)
				if(weapon_class == 0)
					boutput(usr, "Weapons cannot be installed in this ship!")
					return
				m_w_system = S
				if(uses_weapon_overlays)
					src.overlays += image('icons/effects/64x64.dmi', "[m_w_system.appearanceString]")
			else
				boutput(usr, "That system already has a part!")
				return
		if("Lock")
			if (!lock)
				src.lock = S
			else
				boutput(usr, "That system already has a part!")
				return
	components += S
	S.ship = src
	usr.drop_item(S)
	S.set_loc(src)
	playsound(src.loc, "sound/items/Deconstruct.ogg", 50, 0)
	myhud.update_systems()
	return

/////////////////////////////////////////////////////////////////////////////
////////////// Ship Death									////////////////
////////////////////////////////////////////////////////////////////////////

/obj/machinery/vehicle/proc/shipdeath()
	if(exploding)
		return
	exploding = 1
	spawn(1)
		src.visible_message("<b>[src] is breaking apart!</b>")
		new /obj/effects/explosion (src.loc)
		playsound(src.loc, "explosion", 50, 1)
		sleep(30)
		for(var/mob/living/carbon/human/M in src)
			M.update_burning(35)
			boutput(M, "<span style=\"color:red\"><b>Everything is on fire!</b></span>")
			//playsound(M.loc, "explosion", 50, 1)
			//playsound(M.loc, "sound/machines/engine_alert1.ogg", 40, 0)
			M << sound('sound/machines/engine_alert1.ogg')
		sleep(25)
		//playsound(src.loc, "sound/machines/engine_alert2.ogg", 40, 1)
		playsound(src.loc, "sound/machines/pod_alarm.ogg", 40, 1)
		for(var/mob/living/carbon/human/M in src)
			//playsound(M.loc, "sound/machines/engine_alert2.ogg", 50, 0)
			M << sound('sound/machines/pod_alarm.ogg')
		new /obj/effects/explosion (src.loc)
		playsound(src.loc, "explosion", 50, 1)
		sleep(15)
		handle_occupants_shipdeath()
		playsound(src.loc, "explosion", 50, 1)
		sleep(2)
		var/turf/T = get_turf(src.loc)
		if(T)
			src.visible_message("<b>[src] explodes!</b>")
			explosion_new(src, T, 5)
		for(T in range(src,1))
			new /obj/decal/cleanable/machine_debris (T)
		qdel (src)
///////////////////////////////////////////////////////////////////////////
////////// Exit Ship Code /////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/verb/exit_ship()
	set src in oview(1)
	set category = "Local"

	if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		usr.show_text("Not when you're incapacitated.", "red")
		return

	src.eject(usr)
/*
	if (usr.loc != src)
		return
	src.passengers--
	usr.set_loc(src.loc)
	usr.remove_shipcrewmember_powers(src.weapon_class)
	if (usr.client)
		usr.client.perspective = MOB_PERSPECTIVE
	if(src.pilot == usr)
		src.pilot = null
	if(passengers)
		find_pilot()
	else
		src.ion_trail.stop()
*/
/obj/machinery/vehicle/proc/eject(mob/ejectee as mob)
	if (!ejectee || ejectee.loc != src)
		return

	if (ejectee.client)
		myhud.remove_client(ejectee.client)
	src.passengers--
	ejectee.set_loc(src.loc)
	ejectee.remove_shipcrewmember_powers(src.weapon_class)
	if(src.pilot == ejectee)
		src.pilot = null
	if(passengers)
		find_pilot()
	else
		src.ion_trail.stop()

	for (var/obj/item/I in src)
		if ( (I in src.components) || I == src.atmostank || I == src.fueltank || I == src.intercom)
			continue

		I.set_loc(src.loc)

	logTheThing("vehicle", ejectee, src.name, "exits pod: <b>%target%</b>")

///////////////////////////////////////////////////////////////////////
/////////Board Code 							//////////////////////
//////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/verb/board()
	set src in oview(1)
	set category = "Local"

	src.board_pod(usr)
	return

/obj/machinery/vehicle/proc/board_pod(var/mob/boarder)
	if(!istype(usr, /mob/living) || istype(usr, /mob/living/intangible) || istype(usr, /mob/living/silicon/ghostdrone))
		boutput(boarder, "<span style=\"color:red\">Pods are only for the living, so quit being a smartass!</span>")
		return

	//if(boarding) // stop multiple inputs from ruining shit
		//boutput(usr, "<span style=\"color:red\">The access door is already in use!</span>")
		//return

	if(locked)
		boutput(boarder, "<span style=\"color:red\">[src] is locked!</span>")
		return

	if(panel_status)
		boutput(boarder, "<span style=\"color:red\">Close the maintenance panel first!</span>")
		return

	if (boarder.stunned > 0 || boarder.weakened > 0 || boarder.paralysis > 0 || boarder.stat != 0 || boarder.restrained())
		boutput(boarder, "<span style=\"color:red\">You can't enter a pod while incapacitated or restrained.</span>")
		return

	if (boarder in src) // fuck's sake
		boutput(usr, "<span style=\"color:red\">You're already inside [src]!</span>")
		return

	boarding = 1

	passengers = 0 // reset this shit

	for(var/mob/M in src) // nobody likes losing a pod to a dead pilot
		passengers++

		if(M.stat || !M.client)
			eject(M)
			boutput(boarder, "<span style=\"color:red\">You pull [M] out of [src].</span>")
		else if(!istype(M, /mob/living))
			eject(M)
			boutput(boarder, "<span style=\"color:red\">You scrape [M] out of [src].</span>")

	for(var/obj/decal/cleanable/O in src)
		boutput(boarder, "<span style=\"color:red\">You [pick("scrape","scrub","clean")] [O] out of [src].</span>")
		sleep(2)
		var/floor = get_turf(src)
		O.set_loc(floor)

	if (src.capacity <= src.passengers)
		boutput(boarder, "There is no more room!")
		return
	boarder.make_shipcrewmember(src.weapon_class)
	for(var/obj/item/shipcomponent/S in src.components)
		S.mob_activate(boarder)
	sleep(10) //Make sure the verb gets added

	src.passengers++
	var/mob/M = boarder

	M.set_loc(src, src.view_offset_x, src.view_offset_y)
	if(!src.pilot)
		src.pilot = M
		src.ion_trail.start()
	if (M.client)
		myhud.add_client(M.client)

	spawn(5)
		boarding = 0

	boutput(M, "<span style=\"color:blue\">You can also use the Space Bar to fire!</span>")

	logTheThing("vehicle", M, src.name, "enters vehicle: <b>%target%</b>")


///////////////////////////////////////////////////////////////////////////
///////// Find new pilot									////////////
/////////////////////////////////////////////////////////////////////////

/obj/machinery/vehicle/proc/find_pilot()
	for(var/mob/living/M in src) // fuck's sake stop assigning ghosts and observers to be the pilot
		if(!src.pilot && !M.stat && M.client)
			src.pilot = M
			break

//////////////////////////////////////////////////////////////////////////
////////Ship Message												//////
//////////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/proc/ship_message(var/message as text)
	message = "<font color='green'><b>[bicon(src)]\[[src]\]</b> states, \"[message]\"</font>"
	return message

/////////////////////////////////////////////////////////////////////////
////////What happens to occupants when ship is destroyed ////////////////
////////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/proc/handle_occupants_shipdeath()
	for(var/mob/M in src)
		boutput(M, "<span style=\"color:red\"><b>You are ejected from [src]!</b></span>")
		logTheThing("vehicle", M, src.name, "is ejected from pod: <b>%target%</b> when it blew up!")
		src.eject(M)
		//var/atom/target = get_edge_target_turf(M,pick(alldirs))
		//spawn(0)
		//M.throw_at(target, 10, 2)
		spawn(0)
		step_rand(M, 0)
		step_rand(M, 0)
		step_rand(M, 0)
		step_rand(M, 0)
		step_rand(M, 0)


/////////////////////////////////////////////////////////////////////
////////Open Part Panel									////////////
////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/proc/open_parts_panel(mob/user as mob)
	if (passengers)
		boutput(user, "<span style=\"color:red\">You can't modify parts with somebody inside.</span>")
		return

	if (src.lock && src.locked)
		boutput(usr, "<span style=\"color:red\">You can't modify parts while [src] is locked.</span>")
		lock.show_lock_panel(usr, 0)
		return

	user.machine = src

	var/dat = "<TT><B>[src] Maintenance Panel</B><BR><HR><BR>"
	//Air and Fuel tanks
	dat += "<HR><B>Atmos Tank</B>: "
	if(!isnull(src.atmostank))
		dat += "<A href='?src=\ref[src];takeatmostank=1'>[src.atmostank]</A>"
	else
		dat += "<A href='?src=\ref[src];atmostank=1'>--------</A>"
	dat += "<HR><B>Fuel Tank</B>: "
	if(src.fueltank)
		dat += "<A href='?src=\ref[src];takefueltank=1'>[src.fueltank]</A>"
	else
		dat += "<A href='?src=\ref[src];fueltank=1'>--------</A>"
	dat += "<HR><B>Engine</B>: "
	//Engine
	if(src.engine)
		dat += "<A href='?src=\ref[src];unengine=1'>[src.engine]</A>"
	else
		dat += "None Installed"
	///Life Support
	dat += "<HR><B>Life Support</B>: "
	if(src.life_support)
		dat += "<A href='?src=\ref[src];unlife=1'>[src.life_support]</A>"
	else
		dat += "None Installed"
	//// Com System
	dat += "<HR><B>Com System</B>: "
	if(src.com_system)
		dat += "<A href='?src=\ref[src];uncom=1'>[src.com_system]</A>"
	else
		dat += "None Installed"
	///Main Weapon
	if(weapon_class != 0)
		dat += "<HR><B>Main Weapon</B>: "
		if(src.m_w_system)
			dat += "<A href='?src=\ref[src];unm_w=1'>[src.m_w_system]</A>"
			if (src.m_w_system.uses_ammunition)
				dat += "<br><b>Remaining ammo:</b> [src.m_w_system.remaining_ammunition]"
		else
			dat += "None Installed"
	////Sensors
	dat += "<HR><B>Sensors</B>: "
	if(src.sensors)
		dat += "<A href='?src=\ref[src];unsensors=1'>[src.sensors]</A>"
	else
		dat += "None Installed"
	////Secondary System
	dat += "<HR><B>Secondary System</B>: "
	if(src.sec_system)
		dat += "<A href='?src=\ref[src];unsec_system=1'>[src.sec_system]</A>"
	else
		dat += "None Installed"
	////Locking System
	dat += "<HR><B>Locking System</B>: "
	if(src.lock)
		dat += "<A href='?src=\ref[src];un_lock=1'>[src.lock]</A>"
	else
		dat += "None Installed"

	user << browse(dat, "window=ship_maint")
	onclose(user, "ship_maint")
	return
/////////////////////////////////////////////////////////////////////
////////Main Ship Computer Access 						////////////
/////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/proc/access_computer(mob/user as mob)
	if(user.loc != src)
		return
	user.machine = src

	var/dat = "<TT><B>[src] Control Console</B><BR><HR><BR>"
	dat += "<B>Hull Integrity:</B> [src.health/src.maxhealth * 100]%<BR>"
	dat += "<B>Current Power Usage:</B> [src.powercurrent]/[src.powercapacity]<BR>"
	dat += "<B>Air Status:</B> "
	if(src.atmostank && src.atmostank.air_contents)
		var/pressure = atmostank.air_contents.return_pressure()
		var/total_moles = atmostank.air_contents.total_moles()

		dat += "Pressure: [round(pressure,0.1)] kPa"

		if (total_moles)
			var/o2_level = atmostank.air_contents.oxygen/total_moles
			var/n2_level = atmostank.air_contents.nitrogen/total_moles
			var/co2_level = atmostank.air_contents.carbon_dioxide/total_moles
			var/plasma_level = atmostank.air_contents.toxins/total_moles
			var/unknown_level =  1-(o2_level+n2_level+co2_level+plasma_level)

			dat += " Nitrogen: [round(n2_level*100)]% Oxygen: [round(o2_level*100)]% Carbon Dioxide: [round(co2_level*100)]% Plasma: [round(plasma_level*100)]%"

			if(unknown_level > 0.01)
				dat += " OTHER: [round(unknown_level)]%"

		dat += " Temperature: [round(atmostank.air_contents.temperature-T0C)]&deg;C<br>"
	else
		dat += "<font color=red>No tank installed!</font><BR>"
	dat += "<B>Fuel Status:</B> "
	if(src.fueltank && src.fueltank.air_contents)

		var/pressure = fueltank.air_contents.return_pressure()
		var/total_moles = fueltank.air_contents.total_moles()

		dat += "Pressure: [round(pressure,0.1)] kPa"

		if (total_moles)
			var/o2_level = fueltank.air_contents.oxygen/total_moles
			var/n2_level = fueltank.air_contents.nitrogen/total_moles
			var/co2_level = fueltank.air_contents.carbon_dioxide/total_moles
			var/plasma_level = fueltank.air_contents.toxins/total_moles
			var/unknown_level =  1-(o2_level+n2_level+co2_level+plasma_level)

			dat += " Nitrogen: [round(n2_level*100)]% Oxygen: [round(o2_level*100)]% Carbon Dioxide: [round(co2_level*100)]% Plasma: [round(plasma_level*100)]%"

			if(unknown_level > 0.01)
				dat += " OTHER: [round(unknown_level)]%"

		dat += " Temperature: [round(fueltank.air_contents.temperature-T0C)]&deg;C<br>"
	else
		dat += "<font color=red>No tank installed!</font><BR>"
	if(src.engine)
		if(src.engine.active)
			dat += {"<HR><B>Engine</B>: <I><A href='?src=\ref[src];enginecomp=1'>[src.engine]</A></I>"}
			dat += {"<BR><A href='?src=\ref[src];dengine=1'>(Deactivate)</A>"}
		else
			dat += {"<HR><B>Engine</B>: <I>[src.engine]</I>"}
			dat += {"<BR><A href='?src=\ref[src];aengine=1'>(Activate)</A>"}
	if(src.life_support)
		dat += {"<HR><B>Life Support</B>: <I>[src.life_support]</I>"}
		if(src.life_support.active)
			dat += {"<BR><A href='?src=\ref[src];dlife=1'>(Deactivate)</A>"}
		else
			dat += {"<BR><A href='?src=\ref[src];alife=1'>(Activate)</A>"}
		dat+={"([src.life_support.power_used])<BR>"}
	if(src.com_system)
		if(src.com_system.active)
			dat += {"<HR><B>Com System</B>: <I><A href='?src=\ref[src];comcomp=1'>[src.com_system]</A></I>"}
			dat += {"<BR><A href='?src=\ref[src];dcom=1'>(Deactivate)</A>"}
		else
			dat += {"<HR><B>Com System</B>: <I>[src.com_system]</I>"}
			dat += {"<BR><A href='?src=\ref[src];acom=1'>(Activate)</A>"}
		dat+= {"([src.com_system.power_used])"}
	if(src.m_w_system)
		if(src.m_w_system.active)
			dat += {"<HR><B>Main Weapon</B>: <I><A href='?src=\ref[src];mweaponcomp=1'>[src.m_w_system]</A></I> "}
			dat += {"<BR><A href='?src=\ref[src];dmweapon=1'>(Deactivate)</A>"}
		else
			dat += {"<HR><B>Main Weapon</B>: <I>[src.m_w_system]</I>"}
			dat += {"<BR><A href='?src=\ref[src];amweapon=1'>(Activate)</A>"}
		dat+= {"([src.m_w_system.power_used])"}
	if(src.sensors)
		if(src.sensors.active)
			dat += {"<HR><B>Sensors</B>: <I><A href='?src=\ref[src];sensorcomp=1'>[src.sensors]</A></I> "}
			dat += {"<BR><A href='?src=\ref[src];dsensors=1'>(Deactivate)</A>"}
		else
			dat += {"<HR><B>Sensors</B>: <I>[src.sensors]</I>"}
			dat += {"<BR><A href='?src=\ref[src];asensors=1'>(Activate)</A>"}
		dat+= {"([src.sensors.power_used])"}
	if(src.sec_system)
		if(src.sec_system.active)
			dat += {"<HR><B>Secondary System</B>: <I><A href='?src=\ref[src];sec_systemcomp=1'>[src.sec_system]</A></I> "}
			dat += {"<BR><A href='?src=\ref[src];dsec_system=1'>(Deactivate)</A>"}
		else
			dat += {"<HR><B>Secondary System</B>: <I><A href='?src=\ref[src];sec_systemcomp=1'>[src.sec_system]</A></I> "}
			dat += {"<BR><A href='?src=\ref[src];asec_system=1'>(Activate)</A>"}
		dat+= {"([src.sec_system.power_used])"}
	if(src.lock)
		if(src.locked)
			dat += "<HR><B>Lock</B>:<br><a href='?src=\ref[src.lock];unlock=1'>(Unlock)</a>"
		else
			dat += "<HR><B>Lock</B>:"
			if (src.lock.code)
				dat += "<br><a href='?src=\ref[src.lock];lock=1'>(Lock)</a>"

			dat += " <a href='?src=\ref[src.lock];setcode=1;'>(Set Code)</a>"
	user << browse(dat, "window=ship_main")
	onclose(user, "ship_main")
	return

/////////////////////////////////////////////////////////////////////////////////
/////// New Vehicle Code 	///////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

/obj/machinery/vehicle/proc/setup_ion_trail()
	//////Ion Trail Setup
	src.ion_trail = new /datum/effects/system/ion_trail_follow()
	src.ion_trail.set_up(src)

/obj/machinery/vehicle/New()
	..()
	name += "[pick(rand(1, 999))]"
	setup_ion_trail()

	src.myhud = new /datum/hud/pod(src)
	///Engine Setup
	src.fueltank = new /obj/item/tank/plasma( src )
	src.engine = new /obj/item/shipcomponent/engine( src )
	src.engine.ship = src
	src.components += src.engine
	src.engine.activate()

	/////Life Support Setup
	src.atmostank = new /obj/item/tank/air( src )
	src.life_support = new /obj/item/shipcomponent/life_support( src )
	src.life_support.ship = src
	src.components += src.life_support
	src.life_support.activate()
	/////Com-System Setup
	src.intercom = new /obj/item/device/radio/intercom/ship( src )
	//src.intercom.icon_state = src.icon_state
	src.com_system = new /obj/item/shipcomponent/communications( src )
	src.com_system.ship = src
	src.components += src.com_system
	src.com_system.activate()
	///// Sensor System Setup
	src.sensors = new /obj/item/shipcomponent/sensor( src )
	src.sensors.ship = src
	src.components += src.sensors
	src.sensors.activate()
	myhud.update_systems()
	myhud.update_states()


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////					MouseDrop Crate Loading						////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

/obj/machinery/vehicle/MouseDrop_T(atom/movable/O as mob|obj, mob/user as mob)
	if (!user.client || !istype(user,/mob/living))
		return
	if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0)
		user.show_text("Not when you're incapacitated.", "red")
		return

	if(istype(O,/mob/living/))
		var/inrange = 0
		for (var/turf/T in src.locs)
			if (get_dist(src,user) <= 1)
				inrange = 1
				break
		if (!inrange)
			boutput(user, "<span style=\"color:red\">You are too far away from the pod to board it.</span>")
			return

		if (O == user)
			src.board_pod(O)
		else
			boutput(user, "<span style=\"color:red\">You can't shove someone else into a pod.</span>")

		return

	var/obj/item/shipcomponent/secondary_system/SS = src.sec_system
	if (!SS)
		return
	SS.Clickdrag_ObjectToPod(user,O)
	return

/obj/machinery/vehicle/MouseDrop(over_object, src_location, over_location)
	if (!usr.client || !istype(usr,/mob/living))
		return
	if (usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		usr.show_text("Not when you're incapacitated.", "red")
		return

	var/obj/item/shipcomponent/secondary_system/SS = src.sec_system
	if (!SS)
		return
	SS.Clickdrag_PodToObject(usr,over_object)
	return


////////////////////////////////////////////////////////////////////////
///// Hotkeys //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/obj/machinery/vehicle/hotkey(var/mob/user, var/key)
	if (key != "space")
		return 0
	if (pilot != user)
		return 0
	if (user.stunned > 0 || user.weakened > 0 || user.paralysis > 0 || user.stat != 0)
		user.show_text("Not when you're incapacitated.", "red")
		return 0
	if (stall)
		return 1
	if (!m_w_system)
		boutput(usr, "[ship_message("System not installed in ship!")]")
		return 1
	if (!m_w_system.active)
		boutput(usr, "[ship_message("SYSTEM OFFLINE")]")
		return 1
	if (fire_delay)
		return 1
	if(m_w_system.r_gunner)
		if(usr == m_w_system.gunner)
			stall += 1
			fire_delay += 1
			m_w_system.Fire(usr)
			spawn(15)
				fire_delay -= 1
				if (fire_delay > 0)
					fire_delay = 0
		else
			boutput(usr, "[ship_message("You must be in the gunner seat!")]")
	else
		m_w_system.Fire()

	return 1

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////					Ship Verbs									////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/mob/proc/make_shipcrewmember(weapon_class as num)
	//boutput(world, "Is called for [src.name]")
	src.verbs += /client/proc/access_main_computer
	if(weapon_class)
		src.verbs += /client/proc/fire_main_weapon
	src.verbs += /client/proc/use_external_speaker
	src.verbs += /client/proc/access_sensors
	src.verbs += /client/proc/create_wormhole
	src.verbs += /client/proc/use_secondary_system
	src.verbs += /client/proc/open_hangar
	src.verbs += /client/proc/return_to_station
	return

/mob/proc/remove_shipcrewmember_powers(weapon_class as num)
	src.verbs -= /client/proc/access_main_computer
	if(weapon_class)
		src.verbs -= /client/proc/fire_main_weapon
	src.verbs -= /client/proc/use_external_speaker
	src.verbs -= /client/proc/access_sensors
	src.verbs -= /client/proc/create_wormhole
	src.verbs -= /client/proc/use_secondary_system
	src.verbs -= /client/proc/open_hangar
	src.verbs -= /client/proc/return_to_station
	return


/client/proc/access_main_computer()
	set category = "Ship"
	set name = "Access Main Computer"
	set desc = "Access the ship's main computer"

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		ship.access_computer(usr)
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")

/client/proc/fire_main_weapon()
	set category = "Ship"
	set name = "Fire Main Weapon"
	set desc = "Fires the ship's main weapon."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.stall)
			return
		if(ship.m_w_system)
			if(ship.m_w_system.active && !ship.fire_delay)
				if(ship.m_w_system.r_gunner)
					if(usr == ship.m_w_system.gunner)
						ship.stall += 1
						ship.fire_delay += 1
						ship.m_w_system.Fire(usr)
						spawn(15)
							ship.fire_delay -= 1 // cogwerks: no more spamming lasers until the server dies
							if (ship.fire_delay > 0) ship.fire_delay = 0
					else
						boutput(usr, "[ship.ship_message("You must be in the gunner seat!")]")
				else
					ship.m_w_system.Fire()
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")

/client/proc/use_external_speaker()
	set category = "Ship"
	set name = "Use Comms System"
	set desc = "Use your ship's communications system."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.com_system)
			if(ship.com_system.active)
				ship.com_system.External()
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")

/client/proc/create_wormhole()
	set category = "Ship"
	set name = "Create Wormhole"
	set desc = "Allows warp travel"

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.engine)
			if(ship.engine.active)
				if(ship.engine.ready)
					ship.engine.Wormhole()
				else
					boutput(usr, "[ship.ship_message("Engine recharging wormhole capabilities!")]")
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")


/client/proc/access_sensors()
	set category = "Ship"
	set name = "Use Sensors"
	set desc = "Access your sensor system to scan your surroundings."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.sensors)
			if(ship.sensors.active)
				ship.sensors.opencomputer(usr)

			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")



/client/proc/use_secondary_system()
	set category = "Ship"
	set name = "Use Secondary System"
	set desc = "Allows the use of a secondary systems special function if it exists."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.sec_system)
			if(ship.sec_system.active || ship.sec_system.f_active)
				if(ship.sec_system.ready)
					ship.sec_system.Use(usr)
				else
					boutput(usr, "[ship.ship_message("Secondary System isn't ready for use yet!")]")
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")

/client/proc/open_hangar()
	set category = "Ship"
	set name = "Toggle Hangar Door"
	set desc = "Toggles nearby hangar door controls remotely."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.com_system)
			if(ship.com_system.active)
				ship.com_system.rc_ship.open_hangar(usr)
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")


/client/proc/return_to_station()
	set category = "Ship"
	set name = "Return To Station"
	set desc = "Uses the ship's comm system to locate the station's Space GPS beacon and plot a return course."

	if(usr.stunned > 0 || usr.weakened > 0 || usr.paralysis > 0 || usr.stat != 0)
		boutput(usr, "<span style=\"color:red\">Not when you are incapacitated.</span>")
		return
	if(istype(usr.loc, /obj/machinery/vehicle/))
		var/obj/machinery/vehicle/ship = usr.loc
		if(ship.com_system)
			if(ship.com_system.active)
				ship.going_home = 1
			else
				boutput(usr, "[ship.ship_message("SYSTEM OFFLINE")]")
		else
			boutput(usr, "[ship.ship_message("System not installed in ship!")]")
	else
		boutput(usr, "<span style=\"color:red\">Uh-oh you aren't in a ship! Report this.</span>")

