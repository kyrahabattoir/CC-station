// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/spell/magshield
	name = "Spell Shield"
	desc = "Temporarily shield yourself from melee attacks and projectiles. It also absorbs some of the blast of explosions."
	icon_state = "spellshield"
	targeted = 0
	cooldown = 300
	requires_robes = 1

	cast()
		if(!holder)
			return
		if(holder.owner.spellshield)
			boutput(holder.owner, "<span style=\"color:red\">You already have a Spell Shield active!</span>")
			return

		holder.owner.say("XYZZYX")
		playsound(holder.owner.loc, "sound/voice/wizard/MagicshieldLoud.ogg", 50, 0, -1)

		var/image/shield_overlay = null

		holder.owner.spellshield = 1
		shield_overlay = image('icons/effects/effects.dmi', holder.owner, "enshield", MOB_LAYER+1)
		holder.owner.underlays += shield_overlay
		boutput(holder.owner, "<span style=\"color:blue\"><b>You are surrounded by a magical barrier!</b></span>")
		holder.owner.visible_message("<span style=\"color:red\">[holder.owner] is encased in a protective shield.</span>")
		playsound(holder.owner,"sound/effects/MagShieldUp.ogg",50,1)
		spawn(100)
			if(holder.owner && holder.owner.spellshield)
				holder.owner.spellshield = 0
				holder.owner.underlays -= shield_overlay
				shield_overlay = null
				boutput(holder.owner, "<span style=\"color:blue\"><b>Your magical barrier fades away!</b></span>")
				holder.owner.visible_message("<span style=\"color:red\">The shield protecting [holder.owner] fades away.</span>")
				playsound(usr,"sound/effects/MagShieldDown.ogg", 50, 1)
