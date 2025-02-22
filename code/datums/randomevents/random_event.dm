// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/random_event
	var/name = null                      // What is this event called?
	var/centcom_headline = null          // The title of the displayed message.
	var/centcom_message = null           // A message displayed to the crew.
	var/message_delay = 0                // How long it takes after the event's effect for the message to arrive.
	var/required_elapsed_round_time = 0  // Round elapsed ticks must be this or higher for the event to trigger naturally.
	var/wont_occur_past_this_time = -1   // Event will no longer occur naturally after this many ticks have elapsed.
	var/disabled = 0                     // Event won't occur if this is true.
	var/announce_to_admins = 1
	var/customization_available = 0

	proc/event_effect(var/source)
		if (!source)
			source = "random"
		if (announce_to_admins)
			message_admins("<span style=\"color:blue\">Beginning [src.name] event (Source: [source]).</span>")
			logTheThing("admin", null, null, "Random event [src.name] was triggered. Source: [source]")

		if (centcom_headline && centcom_message && random_events.announce_events)
			spawn(message_delay)
				command_alert("[centcom_message]", "[centcom_headline]")

	proc/admin_call(var/source)
		if (!istext(source))
			return 1
		return 0

	proc/is_event_available()
		var/timer = ticker.round_elapsed_ticks

		if (timer < src.required_elapsed_round_time && random_events.time_lock)
			return 0

		if (src.wont_occur_past_this_time > -1)
			if (timer > src.wont_occur_past_this_time && random_events.time_lock)
				return 0

		if (src.disabled)
			return 0

		return 1

/datum/random_event/minor
	announce_to_admins = 0