// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/targetable/werewolf/werewolf_transform
	name = "Transform"
	desc = "Switch between human and wolf form, Takes a couple seconds to complete."
	targeted = 0
	target_nodamage_check = 0
	max_range = 0
	cooldown = 600
	pointCost = 0
	when_stunned = 1
	not_when_handcuffed = 0
	werewolf_only = 0

	cast(mob/target)
		if (!holder)
			return 1

		var/mob/living/M = holder.owner

		if (!M)
			return 1

		actions.start(new/datum/action/bar/private/icon/werewolf_transform(src), M)
		return 0

/datum/action/bar/private/icon/werewolf_transform
	duration = 50
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_ACTION
	id = "werewolf_transform"
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"
	var/datum/targetable/werewolf/werewolf_transform/transform

	New(Transform)
		transform = Transform
		..()

	onStart()
		..()

		var/mob/living/M = owner

		if (M == null || !ishuman(M) || M.stat != 0 || M.paralysis > 0 || !transform)
			interrupt(INTERRUPT_ALWAYS)
			return

		boutput(M, __red("<B>You feel a strong burning sensation all over your body!</B>"))

	onUpdate()
		..()

		var/mob/living/M = owner

		if (M == null || !ishuman(M) || M.stat != 0 || M.paralysis > 0 || !transform)
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		..()

		var/mob/living/M = owner
		M.werewolf_transform(0, 1)

	onInterrupt()
		..()

		var/mob/living/M = owner
		boutput(M, __red("Your transformation was interrupted!"))