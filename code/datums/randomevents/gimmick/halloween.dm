// SPDX-License-Identifier: CC-BY-NC-SA-3.0

#ifdef HALLOWEEN
/datum/random_event/major/halloween
#else
/datum/random_event/special/halloween
#endif
	name = "Spooky!"

	event_effect()
		..()
		if(halloween_mode)
			return
		if(emergency_shuttle && emergency_shuttle.location) //it's too late!
			return
		halloween_mode = 1
		var/sound/siren = sound('sound/misc/airraid_loop.ogg')
		siren.repeat = 1
		siren.channel = 5
		boutput(world, siren)
		spawn(rand(300,600))
			siren.repeat = 0
			siren.status = SOUND_UPDATE
			siren.channel = 5
			world << siren

		bust_lights()

		//List of major spooky things (only one is spawned)
		var/list/spooky_major = list(/obj/item/storage/toolbox/memetic,
		/obj/item/unkill_shield,
		/obj/submachine/mind_switcher,
		/*/obj/item/camera_test/haunted,*/ // This thing is broken.
		/obj/item/relic,
		/obj/item/clothing/head/void_crown,
		/obj/haunted_television)

		//List of minor spooky things (several are spawned)
		var/list/spooky_minor = list(/obj/item/storage/goodybag,
		/obj/critter/zombie/security,
		/obj/critter/spirit,
		/obj/critter/blobman,
		/obj/critter/bloodling,
		/obj/critter/spider/spacerachnid,
		/obj/critter/lion, //Okay, this one isn't very "spooky"
		/obj/item/clothing/glasses/regular/ecto,
		/obj/item/device/key/haunted,
		/obj/item/book_kinginyellow)

		var/list/halloweenspawn_temp = halloweenspawn.Copy()
		var/turf/majorspawn = pick(halloweenspawn_temp)
		halloweenspawn_temp.Remove(majorspawn)

		var/major_path = pick(spooky_major)
		var/obj/major_obj = new major_path
		major_obj.set_loc(majorspawn)

		message_admins("Event: [major_path] spawned at \[[showCoords(majorspawn.x,majorspawn.y,majorspawn.z)]]")

		for(var/turf/T in halloweenspawn_temp)
			if(prob(60))
				var/minor_path = pick(spooky_minor)
				var/obj/minor_obj = new minor_path
				minor_obj.set_loc(T)
				blink(minor_obj)

		return