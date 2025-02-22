// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/*********************************
Procs for handling ircbot connectivity and data transfer
*********************************/


var/global/datum/ircbot/ircbot = new /datum/ircbot()

/datum/ircbot
	var/interface = null
	var/apikey = null
	var/loaded = 0
	var/loadTries = 0
	var/list/queue = list()
	var/debugging = 0

	New()
		if (!src.load())
			spawn(10)
				if (!src.loaded)
					src.load()

	proc
		//Load the config variables necessary for connections
		load()
			if (config)
				src.interface = config.irclog_url
				src.apikey = config.ircbot_api
				src.loaded = 1

				if (src.queue && src.queue.len > 0)
					if (src.debugging)
						src.logDebug("Load success, flushing queue: [json_encode(src.queue)]")
					for (var/x = 1, x <= src.queue.len, x++) //Flush queue
						src.export(src.queue[x]["iface"], src.queue[x]["args"])

				src.queue = null
				return 1
			else
				loadTries++
				if (loadTries >= 5)
					logTheThing("debug", null, null, "<b>IRCBOT:</b> Reached 5 failed config load attempts")
					logTheThing("diary", null, null, "<b>IRCBOT:</b> Reached 5 failed config load attempts", "debug")
				return 0


		//Shortcut proc for event-type exports
		event(type, data)
			if (!type) return 0
			var/list/eventArgs = list("type" = type)
			if (data) eventArgs["data"] = data
			return src.export("event", eventArgs)


		//Send a message to an irc bot! Yay!
		export(iface, args)
			if (src.debugging)
				src.logDebug("Export called with <b>iface:</b> [iface]. <b>args:</b> [list2params(args)]. <b>src.interface:</b> [src.interface]. <b>src.loaded:</b> [src.loaded]")

			if (!config || !src.loaded)
				src.queue += list(list("iface" = iface, "args" = args))

				if (src.debugging)
					src.logDebug("Export, message queued due to unloaded config")

				spawn(10)
					if (!src.loaded)
						src.load()
				return "queued"
			else
				if (config.env == "dev") return 0

				args = (args == null ? list() : args)
				args["server_name"] = (config.server_name ? replacetext(config.server_name, "#", "") : null)
				args["server"] = (world.port % 1000) / 100
				args["api_key"] = (src.apikey ? src.apikey : null)

				if (src.debugging)
					src.logDebug("Export, final args: [list2params(args)]. Final route: [src.interface]/[iface]?[list2params(args)]")

				var/http[] = world.Export("[src.interface]/[iface]?[list2params(args)]")
				if (!http || !http["CONTENT"])
					logTheThing("debug", null, null, "<b>IRCBOT:</b> No return data from export. <b>iface:</b> [iface]. <b>args</b> [list2params(args)]")
					return 0

				var/content = file2text(http["CONTENT"])

				if (src.debugging)
					src.logDebug("Export, returned data: [content]")

				//Handle the response
				var/list/contentJson = json_decode(content)
				if (!contentJson["status"])
					logTheThing("debug", null, null, "<b>IRCBOT:</b> Object missing status parameter in export response: [list2params(contentJson)]")
					return 0
				if (contentJson["status"] == "error")
					var/log = ""
					if (contentJson["errormsg"])
						log = "Error returned from export: [contentJson["errormsg"]][(contentJson["error"] ? ". Error code: [contentJson["error"]]": "")]"
					else
						log = "An unknown error was returned from export: [list2params(contentJson)]"
					logTheThing("debug", null, null, "<b>IRCBOT:</b> [log]")
				return 1


		//Format the response to an irc request juuuuust right
		response(args)
			if (src.debugging)
				src.logDebug("Response called with args: [list2params(args)]")

			args = (args == null ? list() : args)
			args["api_key"] = (src.apikey ? src.apikey : null)

			if (config && config.server_name)
				args["server_name"] = replacetext(config.server_name, "#", "")
				args["server"] = replacetext(config.server_name, "#", "") //TEMP FOR BACKWARD COMPAT WITH SHITFORMANT

			if (src.debugging)
				src.logDebug("Response, final args: [list2params(args)]")

			return list2params(args)


		toggleDebug(client/C)
			if (!C) return 0
			src.debugging = !src.debugging
			out(C, "IRCBot Debugging [(src.debugging ? "Enabled" : "Disabled")]")
			if (src.debugging)
				var/log = "Debugging Enabled. Datum variables are: "
				for (var/x = 1, x <= src.vars.len, x++)
					var/theVar = src.vars[x]
					if (theVar == "vars") continue
					var/contents
					if (islist(src.vars[theVar]))
						contents = list2params(src.vars[theVar])
					else
						contents = src.vars[theVar]
					log += "<b>[theVar]:</b> [contents] "
				src.logDebug(log)
			return 1


		logDebug(log)
			if (!log) return 0
			logTheThing("debug", null, null, "<b>IRCBOT DEBUGGING:</b> [log]")
			return 1


/client/proc/toggleIrcbotDebug()
	set name = "Toggle IRCBot Debug"
	set desc = "Enables in-depth logging of all IRC Bot exports and returns"
	set category = "Toggles"

	admin_only

	ircbot.toggleDebug(src)
	return 1


/client/verb/linkNick(ircNick as text)
	set name = "Link IRC"
	set category = "Special Verbs"
	set desc = "Links your Byond username with your IRC nickname"
	set popup_menu = 0

	if (!ircNick)
		ircNick = input(src, "Please enter your IRC nickname", "Link IRC") as null|text

	if (ircbot.debugging)
		ircbot.logDebug("linkNick verb called. <b>src.ckey:</b> [src.ckey]. <b>ircNick:</b> [ircNick]")

	if (!ircNick || !src.ckey) return 0

	var/ircmsg[] = new()
	ircmsg["key"] = src.key
	ircmsg["ckey"] = src.ckey
	ircmsg["nick"] = ircNick
	var/res = ircbot.export("link", ircmsg)

	if (res)
		alert(src, "Linked Byond username: [src.key] with IRC nickname: [ircNick]. Please return to IRC and use !verify in #goonstation to continue.")
		return 1
	else
		alert(src, "An unknown internal error occurred. Please report this.")
		return 0
