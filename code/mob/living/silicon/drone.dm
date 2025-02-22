// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/device/drone_control
	name = "drone control handset"
	desc = "Allows the user to remotely operate a drone."
	icon_state = "matanalyzer"
	var/signal_tag = "mining"
	flags = FPRINT | TABLEPASS | CONDUCT
	var/list/drone_list = list()

	attack_self(var/mob/user as mob)
		drone_list = list()
		for (var/mob/living/silicon/drone/D in mobs)
			if (D.signal_tag == src.signal_tag)
				drone_list += D

		if (drone_list.len < 1)
			boutput(user, "<span style=\"color:red\">No usable drones detected.</span>")
			return

		var/mob/living/silicon/drone/which = input("Which drone do you want to control?","Drone Controls") as mob in drone_list
		if (istype(which))
			var/attempt = which.connect_to_drone(user)
			switch(attempt)
				if(1)
					boutput(user, "<span style=\"color:red\">Connection error: Drone not found.</span>")
				if(2)
					boutput(user, "<span style=\"color:red\">Connection error: Drone already in use.</span>")

/mob/living/silicon/drone
	name = "Drone"
	var/base_name = "Drone"
	desc = "A small remote-controlled robot for doing risky work from afar."
	icon = 'icons/mob/drone.dmi'
	icon_state = "base"
	var/health_max = 100
	var/signal_tag = "mining"
	var/datum/hud/drone/hud
	var/mob/controller = null
	var/obj/item/cell/cell = null
	var/obj/item/device/radio/radio = null
	var/obj/item/parts/robot_parts/drone/propulsion/propulsion = null
	var/obj/item/parts/robot_parts/drone/plating/plating = null
	var/list/equipment_slots = list(null, null, null, null, null)
	var/obj/item/active_tool = null
	var/datum/material/mat_chassis = null
	var/datum/material/mat_plating = null
	var/disabled = 0
	var/panelopen = 0
	var/sound_damaged = 'sound/effects/grillehit.ogg'
	var/sound_destroyed = 'sound/effects/robogib.ogg'
	var/list/beeps_n_boops = list('sound/machines/twobeep.ogg','sound/machines/ping.ogg','sound/machines/chime.ogg','sound/machines/buzz-two.ogg','sound/machines/buzz-sigh.ogg')
	var/list/glitchy_noise = list('sound/effects/glitchy1.ogg','sound/effects/glitchy2.ogg','sound/effects/glitchy3.ogg')
	var/list/glitch_con = list("kind of","a little bit","somewhat","a bit","slightly","quite","rather")
	var/list/glitch_adj = list("scary","weird","freaky","crazy","demented","horrible","ghastly","egregious","unnerving")

	New()
		..()
		name = "Drone [rand(1,9)]*[rand(10,99)]"
		base_name = name
		hud = new(src)
		src.attach_hud(hud)

		var/obj/item/cell/CELL = new /obj/item/cell(src)
		CELL.charge = CELL.maxcharge
		src.cell = CELL

		src.radio = new /obj/item/device/radio(src)
		src.ears = src.radio

		var/obj/item/mining_tool/drill/D = new /obj/item/mining_tool/drill(src)
		equipment_slots[1] = D
		var/obj/item/ore_scoop/borg/S = new /obj/item/ore_scoop/borg(src)
		equipment_slots[2] = S
		var/obj/item/oreprospector/O = new /obj/item/oreprospector(src)
		equipment_slots[3] = O

		src.health = src.health_max
		src.botcard.access = get_all_accesses()

	Life(datum/controller/process/mobs/parent)
		set invisibility = 0

		if (..(parent))
			return 1

		if (src.transforming)
			return

		//hud.update_health()
		if (hud)
			hud.update_charge()
			hud.update_tools()

		if(src.observers.len)
			for(var/mob/x in src.observers)
				if(x.client)
					src.updateOverlaysClient(x.client)

	examine()
		..()
		if (src.controller)
			boutput(usr, "It is currently active and being controlled by someone.")
		else
			boutput(usr, "It is currently shut down and not being used.")
		if (src.health < 100)
			if (src.health < 50)
				boutput(usr, "<span style=\"color:red\">It's rather badly damaged. It probably needs some wiring replaced inside.</span>")
			else
				boutput(usr, "<span style=\"color:red\">It's a bit damaged. It looks like it needs some welding done.</span>")

	movement_delay()
		var/tally = 0
		for (var/obj/item/parts/robot_parts/drone/DP in src.contents)
			tally += DP.weight
		if (src.propulsion && istype(src.propulsion))
			tally -= src.propulsion.speed
		return tally

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (user.a_intent == INTENT_HARM)
				if (WELD.welding)
					user.visible_message("<span style=\"color:red\"><b>[user] burns [src] with [W]!</b></span>")
					damage_heat(WELD.force)
				else
					user.visible_message("<span style=\"color:red\"><b>[user] beats [src] with [W]!</b></span>")
					damage_blunt(WELD.force)
			else
				if (src.health >= src.health_max)
					boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
					return
				if (get_x_percentage_of_y(src.health,src.health_max) < 33)
					boutput(user, "<span style=\"color:red\">You need to use wire to fix the cabling first.</span>")
					return
				if (WELD.get_fuel() > 1)
					src.health = max(1,min(src.health + 10,src.health_max))
					WELD.use_fuel(1)
					playsound(src.loc, "sound/items/Welder.ogg", 50, 1)
					user.visible_message("<b>[user]</b> uses [WELD] to repair some of [src]'s damage.")
					if (src.health == src.health_max)
						boutput(user, "<span style=\"color:blue\"><b>[src] looks fully repaired!</b></span>")
				else
					boutput(user, "<span style=\"color:red\">You need more welding fuel!</span>")

		else if (istype(W,/obj/item/cable_coil/))
			if (src.health >= src.health_max)
				boutput(user, "<span style=\"color:red\">It isn't damaged!</span>")
				return
			var/obj/item/cable_coil/C = W
			if (get_x_percentage_of_y(src.health,src.health_max) >= 33)
				boutput(usr, "<span style=\"color:red\">The cabling looks fine. Use a welder to repair the rest of the damage.</span>")
				return
			C.use(1)
			src.health = max(1,min(src.health + 10,src.health_max))
			user.visible_message("<b>[user]</b> uses [C] to repair some of [src]'s cabling.")
			playsound(src.loc, "sound/items/Deconstruct.ogg", 50, 1)
			if (src.health >= 50)
				boutput(user, "<span style=\"color:blue\">The wiring is fully repaired. Now you need to weld the external plating.</span>")

		else
			user.visible_message("<span style=\"color:red\"><b>[user] attacks [src] with [W]!</b></span>")
			damage_blunt(W.force)

	proc/take_damage(var/amount)
		if (!isnum(amount))
			return

		src.health = max(0,min(src.health - amount,100))

		if (amount > 0)
			playsound(src.loc, src.sound_damaged, 50, 2)
			if (src.health == 0)
				src.visible_message("<span style=\"color:red\"><b>[src.name] is destroyed!</b></span>")
				disconnect_user()
				robogibs(src.loc,null)
				playsound(src.loc, src.sound_destroyed, 50, 2)
				qdel(src)
				return

	damage_blunt(var/amount)
		if (!isnum(amount) || amount <= 0)
			return
		take_damage(amount)

	damage_heat(var/amount)
		if (!isnum(amount) || amount <= 0)
			return
		take_damage(amount)

	swap_hand(var/switchto = 0)
		if (!isnum(switchto))
			active_tool = null
		else
			if (src.active_tool && isitem(src.active_tool))
				var/obj/item/I = src.active_tool
				I.dropped(src) // Handle light datums and the like.
			switchto = max(1,min(switchto,5))
			active_tool = equipment_slots[switchto]
			if (isitem(src.active_tool))
				var/obj/item/I2 = src.active_tool
				I2.pickup(src) // Handle light datums and the like.

		hud.set_active_tool(switchto)

	click(atom/target, params)
		if ((!disable_next_click || ismob(target) || (target && target.flags & USEDELAY) || (src.active_tool && src.active_tool.flags & USEDELAY)) && world.time < src.next_click)
			return

		var/inrange = in_range(target, src)
		var/obj/item/W = src.active_tool
		if ((W && (inrange || (W.flags & EXTRADELAY))))
			target.attackby(W, src)
			if (W)
				W.afterattack(target, src, inrange)

		if (get_dist(src, target) > 0)
			dir = get_dir(src, target)

		if (!disable_next_click || ismob(target) || (target && target.flags & USEDELAY) || (W && W.flags & USEDELAY))
			if (world.time < src.next_click)
				return src.next_click - world.time
			src.next_click = world.time + 5

	Bump(atom/movable/AM as mob|obj, yes)
		spawn( 0 )
			if ((!( yes ) || src.now_pushing))
				return
			src.now_pushing = 1
			if(ismob(AM))
				var/mob/tmob = AM
				if(istype(tmob, /mob/living/carbon/human) && tmob.bioHolder && tmob.bioHolder.HasEffect("fat"))
					src.visible_message("<span style=\"color:red\"><b>[src]</b> can't get past [AM.name]'s fat ass!</span>")
					src.now_pushing = 0
					src.unlock_medal("That's no moon, that's a GOURMAND!", 1)
					return
			src.now_pushing = 0
			..()
			if (!istype(AM, /atom/movable))
				return
			if (!src.now_pushing)
				src.now_pushing = 1
				if (!AM.anchored)
					var/t = get_dir(src, AM)
					step(AM, t)
				src.now_pushing = null
			return
		return

	say(var/message)
		if (!message)
			return

		if (src.client && src.client.ismuted())
			boutput(src, "You are currently muted.")
			return

		if (src.stat == 2)
			message = trim(copytext(sanitize(message), 1, MAX_MESSAGE_LEN))
			return src.say_dead(message)

		// wtf?
		if (src.stat)
			return

		if (copytext(message, 1, 2) == "*")
			..()
		else
			src.visible_message("<b>[src]</b> beeps.")
			playsound(src.loc, beeps_n_boops[1], 30, 1)

	emote(var/act)
		//var/param = null
		if (findtext(act, " ", 1, null))
			var/t1 = findtext(act, " ", 1, null)
			//param = copytext(act, t1 + 1, length(act) + 1)
			act = copytext(act, 1, t1)

		var/message
		var/sound/emote_sound = null

		switch(act)
			if ("help")
				boutput(src, "To use emotes, simply enter \"*(emote)\" as the entire content of a say message. Certain emotes can be targeted at other characters - to do this, enter \"*emote (name of character)\" without the brackets.")
				boutput(src, "For a list of basic emotes, use *listbasic. For a list of emotes that can be targeted, use *listtarget.")
			if ("listbasic")
				boutput(src, "ping, chime, madbuzz, sadbuzz")
			if ("listtarget")
				boutput(src, "Drones do not currently have any targeted emotes.")
			if ("ping")
				emote_sound = beeps_n_boops[2]
				message = "<B>[src]</B> pings!"
			if ("chime")
				emote_sound = beeps_n_boops[3]
				message = "<B>[src]</B> emits a pleased chime."
			if ("madbuzz")
				emote_sound = beeps_n_boops[4]
				message = "<B>[src]</B> buzzes angrily!"
			if ("sadbuzz")
				emote_sound = beeps_n_boops[5]
				message = "<B>[src]</B> buzzes dejectedly."
			if ("glitch","malfunction")
				playsound(src.loc, pick(glitchy_noise), 50, 1)
				src.visible_message("<span style=\"color:red\"><B>[src]</B> freaks the fuck out! That's [pick(glitch_con)] [pick(glitch_adj)]!</span>")
				animate_glitchy_freakout(src)
				return

		if (emote_sound)
			playsound(src.loc, emote_sound, 50, 1)
		if (message)
			src.visible_message(message)
		return

	get_equipped_ore_scoop()
		if(src.equipment_slots[1] && istype(src.equipment_slots[1],/obj/item/ore_scoop))
			return equipment_slots[1]
		else if(src.equipment_slots[2] && istype(src.equipment_slots[2],/obj/item/ore_scoop))
			return equipment_slots[2]
		else if(src.equipment_slots[3] && istype(src.equipment_slots[3],/obj/item/ore_scoop))
			return equipment_slots[3]
		else if(src.equipment_slots[4] && istype(src.equipment_slots[4],/obj/item/ore_scoop))
			return equipment_slots[4]
		else if(src.equipment_slots[5] && istype(src.equipment_slots[5],/obj/item/ore_scoop))
			return equipment_slots[5]
		else
			return null

	proc/connect_to_drone(var/mob/living/L)
		if (!L || !src)
			return 1
		if (controller)
			return 2

		boutput(L, "You connect to [src.name].")
		controller = L
		L.mind.transfer_to(src)
		return 0

	proc/disconnect_user()
		if (!controller)
			return

		boutput(controller, "You were disconnected from [src.name].")
		src.mind.transfer_to(controller)
		controller = null

// DRONE ITEM/OBJ STUFF, TRANSFER IT ELSEWHERE LATER

/obj/drone_frame
	name = "drone frame"
	desc = "It's a remote-controlled drone in the middle of being constructed."
	icon = 'icons/mob/drone.dmi'
	icon_state = "frame-0"
	opacity = 0
	density = 0
	anchored = 0
	var/construct_stage = 0
	var/obj/item/device/radio/part_radio = null
	var/obj/item/cell/part_cell = null
	var/obj/item/parts/robot_parts/drone/propulsion/part_propulsion = null
	var/obj/item/parts/robot_parts/drone/plating/part_plating = null
	var/obj/item/cable_coil/cable_type = null

	proc/change_stage(var/change_to,var/mob/user,var/obj/item/item_used)
		if (!isnum(change_to))
			return
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if (user && item_used)
			user.drop_item()
			item_used.set_loc(src)

		icon_state = "frame-" + max(0,min(change_to,6))
		overlays = list()
		if (part_propulsion && part_propulsion.drone_overlay)
			overlays += part_propulsion.drone_overlay

	examine()
		..()
		switch(construct_stage)
			if(0)
				boutput(usr, "It's nothing but a pile of scrap right now. Wrench the parts together to build it up or weld it back down to metal sheets.")
			if(1)
				boutput(usr, "It's still a bit rickety. Weld it to make it more secure or wrench it to take it apart.")
			if(2)
				boutput(usr, "It needs cabling. Add some to build it up or take the circuit board out to deconstruct it.")
			if(3)
				boutput(usr, "A radio needs to be added, or you could take the cabling out to deconstruct it.")
			if(4)
				boutput(usr, "A power cell needs to be added, or you could remove the radio to deconstruct it.")
			if(5)
				boutput(usr, "It needs a propulsion system, or you could remove the power cell to deconstruct it.")
			if(6)
				boutput(usr, "It looks almost finished, all that's left to add is extra optional components.")
				boutput(usr, "Wrench it together to activate it, or remove all parts and the power cell to deconstruct it.")

	attack_hand(var/mob/user as mob)
		switch(construct_stage)
			if(3)
				user.put_in_hand_or_drop(cable_type)
				cable_type = null
				change_stage(2)
			if(4)
				user.put_in_hand_or_drop(part_radio)
				part_radio = null
				change_stage(3)
			if(5)
				user.put_in_hand_or_drop(part_cell)
				part_cell = null
				change_stage(4)
			if(6)
				user.put_in_hand_or_drop(part_propulsion)
				part_propulsion = null
				change_stage(5)
			else
				boutput(usr, "You can't figure out what to do with it. Maybe a closer examination is in order.")

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WELD = W
			if (WELD.get_fuel() > 1)
				switch(construct_stage)
					if(0)
						src.visible_message("<b>[user]</b> welds [src] back down to metal.")
						playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
						var/obj/item/sheet/S = new /obj/item/sheet(src.loc)
						S.amount = 5

						if(src.material)
							S.setMaterial(src.material)
						else
							var/datum/material/M = getCachedMaterial("steel")
							S.setMaterial(M)

						qdel(src)
					if(1)
						src.visible_message("<b>[user]</b> welds [src]'s joints together.")
						src.construct_stage = 2
						WELD.use_fuel(1)
						playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
					if(2)
						src.visible_message("<b>[user]</b> disconnects [src]'s welded joints.")
						src.construct_stage = 1
						WELD.use_fuel(1)
						playsound(src.loc, 'sound/items/Welder.ogg', 50, 1)
					else
						boutput(user, "<span style=\"color:red\">[user.real_name], there's a time and a place for everything! But not now.</span>")
			else
				boutput(user, "<span style=\"color:red\">Need more welding fuel!</span>")

		else if(istype(W, /obj/item/wrench))
			switch(construct_stage)
				if(0)
					change_stage(1)
					playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
					src.visible_message("<b>[user]</b> wrenches together [src]'s parts.")
				if(1)
					change_stage(0)
					playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
					src.visible_message("<b>[user]</b> wrenches [src] apart.")
				if(6)
					var/confirm = alert("Finish and activate the drone?","Drone Assembly","Yes","No")
					if (confirm != "Yes")
						return
					src.visible_message("<b>[user]</b> finishes up and activates [src].")
					playsound(src.loc, 'sound/items/Ratchet.ogg', 50, 1)
					var/mob/living/silicon/drone/D = new /mob/living/silicon/drone(src.loc)
					if (part_cell)
						D.cell = part_cell
						part_cell.loc = D
					if (part_radio)
						D.radio = part_radio
						part_radio.loc = D
					if (part_propulsion)
						D.propulsion = part_propulsion
						part_propulsion.loc = D
					if (part_plating)
						D.plating = part_plating
						part_plating.loc = D
					qdel(src)
				else
					boutput(user, "<span style=\"color:red\">There's lots of good times to use a wrench, but this isn't one of them.</span>")

		else if(istype(W, /obj/item/cable_coil) && construct_stage == 2)
			var/obj/item/cable_coil/C = W
			src.visible_message("<b>[user]</b> adds [C] to [src].")
			cable_type = C.take(1, src)
			change_stage(3)

		else if(istype(W, /obj/item/device/radio) && construct_stage == 3)
			src.visible_message("<b>[user]</b> adds [W] to [src].")
			src.part_radio = W
			change_stage(4,user,W)

		else if(istype(W, /obj/item/cell) && construct_stage == 4)
			src.visible_message("<b>[user]</b> adds [W] to [src].")
			src.part_cell = W
			change_stage(5,user,W)

		else if(istype(W, /obj/item/parts/robot_parts/drone/propulsion) && construct_stage == 5)
			src.visible_message("<b>[user]</b> adds [W] to [src].")
			src.part_propulsion = W
			change_stage(6,user,W)

		else
			..()

// DRONE PARTS

/obj/item/parts/robot_parts/drone
	name = "drone part"
	icon = 'icons/mob/drone.dmi'
	desc = "It's a component intended for remote controlled drones. This one happens to be invisible and unusuable. Some things are like that."
	var/image/drone_overlay = null

/obj/item/parts/robot_parts/drone/propulsion
	name = "drone wheels"
	desc = "The most cost-effective movement available for drones. Won't do very good in space, though!"
	var/speed = 0

	New()
		..()
		drone_overlay = image('icons/mob/drone.dmi',"wheels")

/obj/item/parts/robot_parts/drone/plating
	name = "drone plating"
	desc = "Armor for a remote controlled drone."

	New()
		..()
		drone_overlay = image('icons/mob/drone.dmi',"plating-0")