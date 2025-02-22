// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/adventure_submode/emitter
	name = "Invisible Light Emitter"
	var/r = 0
	var/g = 0
	var/b = 0
	var/l = 5

	click_left(atom/object, var/ctrl, var/alt, var/shift)
		if (ctrl && istype(object, /obj/adventurepuzzle/triggerable/light))
			object:toggle()
			return
		var/obj/adventurepuzzle/triggerable/light/L = new(get_turf(object))
		L.on_brig = l
		L.on_cred = r
		L.on_cgreen = g
		L.on_cblue = b
		L.on()
		L.dir = holder.dir
		L.onVarChanged("dir", SOUTH, L.dir)
		blink(L.loc)

	click_right(atom/object, var/ctrl, var/alt, var/shift)
		if (istype(object, /obj/adventurepuzzle/triggerable/light))
			blink(get_turf(object))
			qdel(object)

	selected()
		var/kind = input(usr, "What color of light?", "Light color", "#ffffff") as color
		r = hex2num(copytext(kind, 2, 4)) / 255.0
		g = hex2num(copytext(kind, 4, 6)) / 255.0
		b = hex2num(copytext(kind, 6, 8)) / 255.0
		l = input(usr, "Luminosity?", "Luminosity", 5) as num
		boutput(usr, "<span style=\"color:blue\">Now placing light emitters ([r],[g],[b]:[l]) in single spawn mode. Ctrl+click to toggle light on/off state.</span>")

	settings(var/ctrl, var/alt, var/shift)
		selected()