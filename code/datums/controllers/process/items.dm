// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// handles items
datum/controller/process/items
	var/tmp/list/detailed_count
	var/tmp/tick_counter
	var/tmp/list/processing_items

	setup()
		name = "Item"
		schedule_interval = 29

		for(var/obj/object in world)
			object.initialize()

		detailed_count = new
		
		src.processing_items = global.processing_items

	doWork()
		var/c
		for(var/datum/i in global.processing_items)
			i:process()
			if (!(c++ % 20))
				scheck()

		/*for(var/obj/item/item in processing_items)
			tick_counter = world.timeofday

			item.process()

			tick_counter = world.timeofday - tick_counter
			if (item && tick_counter > 0)
				detailed_count["[item.type]"] += tick_counter

			scheck(currentTick)
*/
	tickDetail()
		if (detailed_count && detailed_count.len)
			var/stats = "<b>[name] ticks:</b><br>"
			var/count
			for (var/thing in detailed_count)
				count = detailed_count[thing]
				if (count > 4)
					stats += "[thing] used [count] ticks.<br>"
			boutput(usr, "<br>[stats]")