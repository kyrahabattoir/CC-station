// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/item/device/camera_viewer
	name = "Camera monitor"
	desc = "A portable video monitor connected to a security camera network."
	icon_state = "monitor"
	item_state = "electronic"
	w_class = 2.0
	var/network = "SS13"
	var/obj/machinery/camera/current = null
	mats = 6

	attack_self(mob/user as mob)
		user.machine = src
		user.unlock_medal("Peeping Tom", 1)

		var/list/L = list()
		for (var/obj/machinery/camera/C in machines)
			L.Add(C)

		L = camera_sort(L)

		var/list/D = list()
		D["Cancel"] = "Cancel"
		for (var/obj/machinery/camera/C in L)
			if (C.network == src.network)
				D[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C

		var/t = input(user, "Which camera should you change to?") as null|anything in D

		if(!t || t == "Cancel")
			user.set_eye(null)
			return 0

		var/obj/machinery/camera/C = D[t]

		if ((!user.contents.Find(src) || !( user.canmove ) || !user.sight_check(1) || !( C.status )) && (!istype(user, /mob/living/silicon)))
			user.set_eye(null)
			return 0
		else
			user.set_eye(C)

			spawn(5)
				attack_self(user)
