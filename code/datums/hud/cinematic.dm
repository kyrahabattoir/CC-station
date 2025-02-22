// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/hud/cinematic
	click_check = 0

	proc/play(name)
		create_screen("bg", "", 'icons/mob/hud_common.dmi', "cinematic_bg", "1, 1 to NORTH, EAST", 98)
		switch (name)
			if ("nuke")
				var/obj/screen/hud/anim = create_screen("cinematic", "", 'icons/effects/station_explosion.dmi', "start_nuke", "1:6, 1:50", 99)
				clients << sound('sound/misc/airraid_loop.ogg')
				spawn(35)//45)
					anim.icon_state = "explode"
					sleep(10)
					clients << sound('sound/effects/kaboom.ogg')
					/*sleep(70)
					del(src)*/
			if ("malf")
				var/obj/screen/hud/anim = create_screen("cinematic", "", 'icons/effects/station_explosion.dmi', "start_malf", "1:6, 1:50", 99)
				spawn(35)//45)
					anim.icon_state = "explode"
					sleep(10)
					clients << sound('sound/effects/kaboom.ogg')
					sleep(70)
					anim.icon_state = "loss_malf"
			if ("sadbuddy")
				create_screen("cinematic", "", 'icons/effects/160x160.dmi', "sadbuddy", "CENTER-2,CENTER-2")
				clients << sound('sound/misc/sad_server_death.ogg')
