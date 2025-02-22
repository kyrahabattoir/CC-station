// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/datum/event_controller/random_events

/datum/event_controller
	var/list/events = list()
	var/events_begin = 18000 // 30m
	var/time_between_events_lower = 6600  // 11m
	var/time_between_events_upper = 12000 // 20m
	var/events_enabled = 1
	var/announce_events = 1
	var/next_event = 0
	var/event_cycle_count = 0

	var/list/minor_events = list()
	var/minor_events_begin = 6000 // 10m
	var/time_between_minor_events_lower = 4000 // roughly 8m
	var/time_between_minor_events_upper = 8000 // roughly 14m
	var/minor_events_enabled = 1
	var/next_minor_event = 0
	var/minor_event_cycle_count = 0

	var/time_lock = 1
	var/list/special_events = list()
	var/minimum_population = 15 // Minimum amount of players connected for event to occur

	New()
		for (var/X in typesof(/datum/random_event/major) - /datum/random_event/major)
			var/datum/random_event/RE = new X
			events += RE

		for (var/X in typesof(/datum/random_event/minor) - /datum/random_event/minor)
			var/datum/random_event/RE = new X
			minor_events += RE

		for (var/X in typesof(/datum/random_event/special) - /datum/random_event/special)
			var/datum/random_event/RE = new X
			special_events += RE

	proc/event_cycle()
		event_cycle_count++
		var/num_players = 0
		for(var/mob/players in mobs)
			if(players.client) num_players++

		if (events_enabled && (num_players >= minimum_population))
			do_random_event(events)
		else
			message_admins("<span style=\"color:blue\">A random event would have happened now, but they are disabled!</span>")
		var/event_timer = rand(time_between_events_lower,time_between_events_upper)
		next_event = ticker.round_elapsed_ticks + event_timer
		message_admins("<span style=\"color:blue\">Next event will occur at [round(next_event / 600)] minutes into the round.</span>")
		spawn(event_timer)
			event_cycle()

	proc/minor_event_cycle()
		minor_event_cycle_count++
		if (minor_events_enabled)
			do_random_event(minor_events)
		var/event_timer = rand(time_between_minor_events_lower,time_between_minor_events_upper)
		next_minor_event = ticker.round_elapsed_ticks + event_timer
		spawn(event_timer)
			minor_event_cycle()

	proc/do_random_event(var/list/event_bank)
		if (!event_bank || event_bank.len < 1)
			logTheThing("debug", null, null, "<b>Random Events:</b> do_random_event proc was passed a bad event bank")
			return
		var/list/eligible = list()
		for (var/datum/random_event/RE in event_bank)
			if (!RE.is_event_available())
				continue
			eligible += RE
		if (eligible.len > 0)
			var/datum/random_event/this = pick(eligible)
			this.event_effect()
		else
			logTheThing("debug", null, null, "<b>Random Events:</b> do_random_event couldn't find any eligible events")

	proc/force_event(var/string,var/reason)
		if (!string)
			return
		if (!reason)
			reason = "coded instance (undefined)"

		var/list/allevents = events | minor_events | special_events
		for (var/datum/random_event/RE in allevents)
			if (RE.name == string)
				RE.event_effect(string,reason)
				break

	///////////////////
	// CONFIGURATION //
	///////////////////

	proc/event_config()
		var/dat = "<html><body><title>Random Events Controller</title>"
		dat += "<b><u>Random Event Controls</u></b><HR>"

		if (ticker.current_state == GAME_STATE_PREGAME)
			dat += "<b>Random Events begin at: <a href='byond://?src=\ref[src];EventBegin=1'>[round(events_begin / 600)] minutes</a><br>"
			dat += "<b>Minor Events begin at: <a href='byond://?src=\ref[src];MEventBegin=1'>[round(minor_events_begin / 600)] minutes</a><br>"
		else
			dat += "Next random event at [round(next_event / 600)] minutes into the round.<br>"
			dat += "Next minor event at [round(next_minor_event / 600)] minutes into the round.<br>"
		dat += "<b><a href='byond://?src=\ref[src];EnableEvents=1'>Random Events Enabled:</a></b> [events_enabled ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];EnableMEvents=1'>Minor Events Enabled:</a></b> [minor_events_enabled ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];AnnounceEvents=1'>Announce Events to Station:</a></b> [announce_events ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];TimeLocks=1'>Time Locking:</a></b> [time_lock ? "Yes" : "No"]<br>"
		dat += "<b>Minimum Population for Events: <a href='byond://?src=\ref[src];MinPop=1'>[minimum_population] players</a><br>"
		dat += "<b>Time Between Events:</b> <a href='byond://?src=\ref[src];TimeLower=1'>[round(time_between_events_lower / 600)]m</a> /"
		dat += " <a href='byond://?src=\ref[src];TimeUpper=1'>[round(time_between_events_upper / 600)]m</a><br>"
		dat += "<b>Time Between Minor Events:</b> <a href='byond://?src=\ref[src];MTimeLower=1'>[round(time_between_minor_events_lower / 600)]m</a> /"
		dat += " <a href='byond://?src=\ref[src];MTimeUpper=1'>[round(time_between_minor_events_upper / 600)]m</a>"
		dat += "<HR>"

		dat += "<b><u>Normal Random Events</u></b><BR>"
		for(var/datum/random_event/RE in events)
			dat += "<a href='byond://?src=\ref[src];TriggerEvent=\ref[RE]'><b>[RE.name]</b></a>"
			dat += " <small><a href='byond://?src=\ref[src];DisableEvent=\ref[RE]'>([RE.disabled ? "Disabled" : "Enabled"])</a>"
			if (RE.is_event_available())
				dat += " (Active)"
			dat += "<br></small>"
		dat += "<BR>"

		dat += "<b><u>Minor Random Events</u></b><BR>"
		for(var/datum/random_event/RE in minor_events)
			dat += "<a href='byond://?src=\ref[src];TriggerMEvent=\ref[RE]'><b>[RE.name]</b></a>"
			dat += " <small><a href='byond://?src=\ref[src];DisableMEvent=\ref[RE]'>([RE.disabled ? "Disabled" : "Enabled"])</a>"
			if (RE.is_event_available())
				dat += " (Active)"
			dat += "<br></small>"
		dat += "<BR>"

		dat += "<b><u>Gimmick Events</u></b><BR>"
		for(var/datum/random_event/RE in special_events)
			dat += "<a href='byond://?src=\ref[src];TriggerSEvent=\ref[RE]'><b>[RE.name]</b></a><br>"

		dat += "<HR>"
		dat += "</body></html>"
		usr << browse(dat,"window=reconfig;size=450x450")

	Topic(href, href_list[])

		if(href_list["TriggerEvent"])
			var/datum/random_event/RE = locate(href_list["TriggerEvent"]) in events
			if (!istype(RE,/datum/random_event/))
				return
			var/choice = alert("Trigger a [RE.name] event?","Random Events","Yes","No")
			if (choice == "Yes")
				if (RE.customization_available)
					var/choice2 = alert("Random or custom variables?","[RE.name]","Random","Custom")
					if (choice2 == "Custom")
						RE.admin_call(key_name(usr, 1))
					else
						RE.event_effect("Triggered by [key_name(usr)]")
				else
					RE.event_effect("Triggered by [key_name(usr)]")

		else if(href_list["TriggerMEvent"])
			var/datum/random_event/RE = locate(href_list["TriggerMEvent"]) in minor_events
			if (!istype(RE,/datum/random_event/))
				return
			var/choice = alert("Trigger a [RE.name] event?","Random Events","Yes","No")
			if (choice == "Yes")
				RE.event_effect("Triggered by [key_name(usr)]")

		else if(href_list["TriggerSEvent"])
			var/datum/random_event/RE = locate(href_list["TriggerSEvent"]) in special_events
			if (!istype(RE,/datum/random_event/))
				return
			var/choice = alert("Trigger a [RE.name] event?","Random Events","Yes","No")
			if (choice == "Yes")
				if (RE.customization_available)
					var/choice2 = alert("Random or custom variables?","[RE.name]","Random","Custom")
					if (choice2 == "Custom")
						RE.admin_call(key_name(usr, 1))
					else
						RE.event_effect("Triggered by [key_name(usr)]")
				else
					RE.event_effect("Triggered by [key_name(usr)]")

		else if(href_list["DisableEvent"])
			var/datum/random_event/RE = locate(href_list["DisableEvent"]) in events
			if (!istype(RE,/datum/random_event/))
				return
			RE.disabled = !RE.disabled
			message_admins("Admin [key_name(usr)] switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing("admin", usr, null, "switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing("diary", usr, null, "switched [RE.name] event [RE.disabled ? "Off" : "On"]", "admin")

		else if(href_list["DisableMEvent"])
			var/datum/random_event/RE = locate(href_list["DisableMEvent"]) in minor_events
			if (!istype(RE,/datum/random_event/))
				return
			RE.disabled = !RE.disabled
			message_admins("Admin [key_name(usr)] switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing("admin", usr, null, "switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing("diary", usr, null, "switched [RE.name] event [RE.disabled ? "Off" : "On"]", "admin")

		else if(href_list["MinPop"])
			var/new_min = input("How many players need to be connected before events will occur?","Random Events",minimum_population) as num
			if (new_min == minimum_population) return
			
			if (new_min < 1) 
				boutput(usr, "<span style=\"color:red\">Well that doesn't even make sense.</span>")
				return
			else
				minimum_population = new_min

			message_admins("Admin [key_name(usr)] set the minimum population for events to [minimum_population]")
			logTheThing("admin", usr, null, "set the minimum population for events to [minimum_population]")
			logTheThing("diary", usr, null, "set the minimum population for events to [minimum_population]", "admin")		
		
		else if(href_list["EventBegin"])
			var/time = input("How many minutes into the round until events begin?","Random Events") as num
			events_begin = time * 600

			message_admins("Admin [key_name(usr)] set random events to begin at [time] minutes")
			logTheThing("admin", usr, null, "set random events to begin at [time] minutes")
			logTheThing("diary", usr, null, "set random events to begin at [time] minutes", "admin")

		else if(href_list["MEventBegin"])
			var/time = input("How many minutes into the round until minor events begin?","Random Events") as num
			minor_events_begin = time * 600

			message_admins("Admin [key_name(usr)] set minor events to begin at [time] minutes")
			logTheThing("admin", usr, null, "set minor events to begin at [time] minutes")
			logTheThing("diary", usr, null, "set minor events to begin at [time] minutes", "admin")

		else if(href_list["EnableEvents"])
			events_enabled = !events_enabled
			message_admins("Admin [key_name(usr)] [events_enabled ? "enabled" : "disabled"] random events")
			logTheThing("admin", usr, null, "[events_enabled ? "enabled" : "disabled"] random events")
			logTheThing("diary", usr, null, "[events_enabled ? "enabled" : "disabled"] random events", "admin")

		else if(href_list["EnableMEvents"])
			minor_events_enabled = !minor_events_enabled
			message_admins("Admin [key_name(usr)] [minor_events_enabled ? "enabled" : "disabled"] minor events")
			logTheThing("admin", usr, null, "[minor_events_enabled ? "enabled" : "disabled"] minor events")
			logTheThing("diary", usr, null, "[minor_events_enabled ? "enabled" : "disabled"] minor events", "admin")

		else if(href_list["AnnounceEvents"])
			announce_events = !announce_events
			message_admins("Admin [key_name(usr)] [announce_events ? "enabled" : "disabled"] random event announcements")
			logTheThing("admin", usr, null, "[announce_events ? "enabled" : "disabled"] random event announcements")
			logTheThing("diary", usr, null, "[announce_events ? "enabled" : "disabled"] random event announcements", "admin")

		else if(href_list["TimeLocks"])
			time_lock = !time_lock
			message_admins("Admin [key_name(usr)] [time_lock ? "enabled" : "disabled"] random event time locks")
			logTheThing("admin", usr, null, "[time_lock ? "enabled" : "disabled"] random event time locks")
			logTheThing("diary", usr, null, "[time_lock ? "enabled" : "disabled"] random event time locks", "admin")

		else if(href_list["TimeLower"])
			var/time = input("Set the lower bound to how many minutes?","Random Events") as num
			if (time < 1)
				boutput(usr, "<span style=\"color:red\">The fuck is that supposed to mean???? Knock it off!</span>")
				return

			time *= 600
			if (time > time_between_events_upper)
				boutput(usr, "<span style=\"color:red\">You cannot set the lower bound higher than the upper bound.</span>")
			else
				time_between_events_lower = time
				message_admins("Admin [key_name(usr)] set event lower interval bound to [time_between_events_lower / 600] minutes")
				logTheThing("admin", usr, null, "set event lower interval bound to [time_between_events_lower / 600] minutes")
				logTheThing("diary", usr, null, "set event lower interval bound to [time_between_events_lower / 600] minutes", "admin")

		else if(href_list["TimeUpper"])
			var/time = input("Set the upper bound to how many minutes?","Random Events") as num
			if (time > 100)
				boutput(usr, "<span style=\"color:red\">That's a bit much.</span>")
				return

			time *= 600
			if (time < time_between_events_lower)
				boutput(usr, "<span style=\"color:red\">You cannot set the upper bound lower than the lower bound.</span>")
			else
				time_between_events_upper = time
			message_admins("Admin [key_name(usr)] set event upper interval bound to [time_between_events_upper / 600] minutes")
			logTheThing("admin", usr, null, "set event upper interval bound to [time_between_events_upper / 600] minutes")
			logTheThing("diary", usr, null, "set event upper interval bound to [time_between_events_upper / 600] minutes", "admin")

		else if(href_list["MTimeLower"])
			var/time = input("Set the lower bound to how many minutes?","Random Events") as num
			if (time < 1)
				boutput(usr, "<span style=\"color:red\">The fuck is that supposed to mean???? Knock it off!</span>")
				return

			time *= 600
			if (time > time_between_minor_events_upper)
				boutput(usr, "<span style=\"color:red\">You cannot set the lower bound higher than the upper bound.</span>")
			else
				time_between_minor_events_lower = time
			message_admins("Admin [key_name(usr)] set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes")
			logTheThing("admin", usr, null, "set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes")
			logTheThing("diary", usr, null, "set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes", "admin")

		else if(href_list["MTimeUpper"])
			var/time = input("Set the upper bound to how many minutes?","Random Events") as num
			if (time > 100)
				boutput(usr, "<span style=\"color:red\">That's a bit much.</span>")
				return

			time *= 600
			if (time < time_between_events_lower)
				boutput(usr, "<span style=\"color:red\">You cannot set the upper bound lower than the lower bound.</span>")
			else
				time_between_minor_events_upper = time
			message_admins("Admin [key_name(usr)] set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes")
			logTheThing("admin", usr, null, "set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes")
			logTheThing("diary", usr, null, "set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes", "admin")

		src.event_config()