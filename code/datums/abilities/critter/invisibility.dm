// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// ----------------------
// Fade into invisibility
// ----------------------
/datum/action/invisibility
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "invisibility"
	var/icon = 'icons/mob/critter_ui.dmi'
	var/icon_state = "invisible_over"
	var/obj/overlay/iicon = null
	var/datum/targetable/critter/fadeout/ability = null
	var/did_fadein = 0

	onUpdate()
		..()
		if (ability && owner && state == ACTIONSTATE_RUNNING)
			owner.invisibility = ability.inv_level

	onInterrupt(var/flag = 0)
		..()
		if (did_fadein)
			return
		did_fadein = 1
		if (owner)
			owner.attached_objs -= iicon
		if (ability)
			ability.fade_in()
		else if (owner)
			owner.invisibility = initial(owner.invisibility)
		if (iicon)
			del iicon
		qdel(src)

	onStart()
		..()
		state = ACTIONSTATE_INFINITE
		if (!owner || !ability)
			interrupt(INTERRUPT_ALWAYS)
			return
		ability.last_action = src
		if (!iicon)
			iicon = new
			iicon.mouse_opacity = 0
			iicon.name = null
			iicon.icon = icon
			iicon.icon_state = icon_state
			iicon.pixel_y = 5
			owner << iicon

	onDelete()
		..()
		if (iicon)
			del iicon
		return

/datum/targetable/critter/fadeout
	name = "Fade Out"
	desc = "Become invisible until you move. Invisibility lingers for a few seconds after moving or acting."
	var/inv_level = 16
	var/fade_out_icon_state = null
	var/fade_in_icon_state = null
	var/fade_anim_length = 3
	var/linger_time = 30
	var/datum/action/invisibility/last_action
	cooldown = 300
	icon_state = "invisibility"

	cast(atom/target)
		if (disabled)
			return 1
		if (..())
			return 1
		disabled = 1
		boutput(holder.owner, __blue("You fade out of sight."))
		var/datum/action/invisibility/I = new
		I.owner = holder.owner
		I.ability = src
		var/wait = 5
		if (fade_out_icon_state)
			flick(fade_out_icon_state, holder.owner)
			wait = fade_anim_length
		else
			animate(holder.owner, alpha=64, time=5)
		spawn (wait)
			holder.owner.invisibility = inv_level
			holder.owner.alpha = 64
			actions.start(I, holder.owner)
		return 0

	proc/fade_in()
		if (holder.owner)
			boutput(holder.owner, __red("You fade back into sight!"))
			disabled = 0
			doCooldown()
			spawn(linger_time)
				holder.owner.invisibility = 0
				if (fade_in_icon_state)
					flick(fade_in_icon_state, holder.owner)
					holder.owner.alpha = 255
				else
					holder.owner.alpha = 64
					animate(holder.owner, alpha=255, time=5)

	wendigo
		fade_in_icon_state = "wendigo_appear"
		fade_out_icon_state = "wendigo_melt"
		fade_anim_length = 12