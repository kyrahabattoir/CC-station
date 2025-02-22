// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// ------------------------------------------------------------
// Experimental: charge-slam using a projectile as a line mover
// ------------------------------------------------------------
/datum/projectile/slam
	name = "slam"
	icon = null
	icon_state = null
	power = 1
	ks_ratio = 0
	damage_type = D_SPECIAL
	hit_ground_chance = 0
	dissipation_delay = 3
	projectile_speed = 32
	dissipation_rate = 1
	shot_sound = null


	on_launch(var/obj/projectile/O)
		if (!("owner" in O.special_data))
			O.die()
			return
		O.special_data["valid_loc"] = get_turf(O)
		O.special_data["orig_turf"] = get_turf(O)
		var/datum/targetable/critter/slam/owner = O.special_data["owner"]
		var/mob/charger = owner.holder.owner
		O.special_data["charger"] = charger
		charger.transforming = 1
		charger.canmove = 0
		charger.loc = O
		O.dir = angleToDir(O.angle)
		O.name = charger.name
		O.icon = null
		O.overlays += charger
		O.transform = null

	tick(var/obj/projectile/O)
		if (O.disposed)
			return
		var/mob/charger = O.special_data["charger"]
		var/obj/overlay/dummy = new(get_turf(O))
		dummy.mouse_opacity = 0
		dummy.name = null
		dummy.density = 0
		dummy.anchored = 1
		dummy.opacity = 0
		dummy.icon = null
		dummy.overlays += charger
		dummy.alpha = 255
		dummy.pixel_x = O.pixel_x
		dummy.pixel_y = O.pixel_y
		dummy.dir = O.dir
		animate(dummy, alpha=0, time=3)
		spawn(3)
			qdel(dummy)

	on_hit(atom/hit, angle, var/obj/projectile/O)
		O.special_data["valid_loc"] = get_turf(hit)
		var/mob/charger = O.special_data["charger"]
		if (isturf(hit))
			hit.visible_message(__red("[charger] slams into [hit]!"), "You hear something slam!")
			boutput(charger, __red("You slam into [hit]! Ouch!"))
			charger.stunned = max(charger.stunned, 3)
			playsound(get_turf(hit), "sound/weapons/genhit1.ogg", 50, 1, -1)
		else if (isobj(hit))
			var/obj/H = hit
			if (H.anchored)
				hit.visible_message(__red("[charger] slams into [hit]!"), "You hear something slam!")
				boutput(charger, __red("You slam into [hit]! Ouch!"))
				charger.stunned = max(charger.stunned, 3)
				playsound(get_turf(hit), "sound/weapons/genhit1.ogg", 50, 1, -1)
			else
				hit.visible_message(__red("[charger] slams into [hit]!"), "You hear something slam!")
				playsound(get_turf(hit), "sound/weapons/genhit1.ogg", 50, 1, -1)
				boutput(charger, __red("You slam into [hit]!"))
				var/kbdir = angleToDir(angle)
				step(H, kbdir, 2)
				if (prob(10))
					spawn(2)
						step(H, kbdir, 2)
		else if (ismob(hit))
			var/mob/M = hit
			playsound(get_turf(hit), "sound/weapons/genhit1.ogg", 50, 1, -1)
			hit.visible_message(__red("[charger] slams into [hit]!"), "You hear something slam!")
			boutput(charger, __red("You slam into [hit]!"))
			boutput(M, __red("<b>[charger] slams into you!</b>"))
			logTheThing("combat", charger, M, "slams %target%.")
			var/kbdir = angleToDir(angle)
			step(M, kbdir, 2)
			M.weakened = max(M.weakened, 4)

	on_end(var/obj/projectile/O)
		var/keys = ""
		for (var/dp in O.special_data)
			keys = "[keys][dp], "
		var/mob/charger = O.special_data["charger"]
		charger.transforming = 0
		charger.canmove = 1
		charger.loc = get_turf(O)
		charger.dir = get_dir(O.special_data["orig_turf"], charger.loc)
		if (!charger.loc)
			charger.loc = O.special_data["valid_loc"]

/datum/targetable/critter/slam
	name = "Slam"
	desc = "Charge over a short distance, until you hit a mob or an object. Knocks down mobs."
	cooldown = 100
	targeted = 1
	target_anything = 1

	var/datum/projectile/slam/proj = new

	cast(atom/target)
		if (..())
			return 1
		var/turf/T = get_turf(target)
		if (!T)
			return 1
		var/mob/M = holder.owner
		var/turf/S = get_turf(M)
		var/obj/projectile/O = initialize_projectile_ST(S, proj, T)
		if (!O)
			return 1
		if (!O.was_setup)
			O.setup()
		O.special_data["owner"] = src
		O.launch()
		return 0