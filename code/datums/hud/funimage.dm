// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/hud/funimage
	click_check = 0

	New(I)
		create_screen("image", "Fun Image (click to remove)", I, "", "1, 1", HUD_LAYER_3)
		..()

	clicked(id, mob/user)
		if (id == "image")
			remove_client(user.client)
