// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/tutorial
	var/name = "Tutorial"
	var/mob/owner = null
	var/list/steps = list()
	var/current_step = 0
	var/finished = 0

	New(var/mob/M)
		..()
		owner = M

	proc
		AddStep(var/datum/tutorialStep/T)
			steps += T
			T.tutorial = src

		ShowStep()
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><b>Invalid tutorial state, please notify `An Admin`.</b></span>")
				qdel(src)
				return
			var/datum/tutorialStep/T = steps[current_step]
			boutput(owner, "<span style=\"color:blue\"><b>Tutorial step #[current_step]: [T.name]</b></span>")
			boutput(owner, "<span style=\"color:blue\">[T.instructions]</span>")

		Start()
			if (!owner)
				return 0
			if (current_step > 0)
				return 0
			current_step = 1
			var/datum/tutorialStep/T = steps[current_step]
			ShowStep()
			T.SetUp()
			return 1

		Advance()
			if (current_step > steps.len)
				return
			var/datum/tutorialStep/T = steps[current_step]
			T.TearDown()
			current_step++
			if (current_step > steps.len)
				Finish()
				return
			T = steps[current_step]
			ShowStep()
			T.SetUp()

		Finish()
			if (finished)
				return 0
			finished = 1
			if (current_step <= steps.len)
				var/datum/tutorialStep/T = steps[current_step]
				T.TearDown()
			boutput(owner, "<span style=\"color:blue\"><b>The tutorial is finished!</b></span>")
			return 1

		CheckAdvance()
			if (!current_step || current_step > steps.len)
				return
			var/datum/tutorialStep/T = steps[current_step]
			if (T.MayAdvance())
				if (T == steps[current_step])
					Advance()

		PerformAction(var/action, var/context)
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><b>Invalid tutorial state, please notify `An Admin`.</b></span>")
				qdel(src)
				return 1
			var/datum/tutorialStep/T = steps[current_step]
			if (T.PerformAction(action, context))
				spawn(0)
					CheckAdvance()
				return 1
			else
				ShowStep()
				boutput(owner, "<span style=\"color:red\"><b>You cannot do that currently.</b></span>")
				return 0

		PerformSilentAction(var/action, var/context)
			if (!current_step || current_step > steps.len)
				boutput(owner, "<span style=\"color:red\"><b>Invalid tutorial state, please notify `An Admin`.</b></span>")
				qdel(src)
				return 1
			var/datum/tutorialStep/T = steps[current_step]
			if (T.PerformSilentAction(action, context))
				spawn(0)
					CheckAdvance()
				return 1
			else
				return 0

/datum/tutorialStep
	var/name = "Tutorial Step"
	var/instructions = "Do something"
	var/datum/tutorial/tutorial = null

	proc
		SetUp()
		TearDown()
		PerformAction(var/action, var/context)
			return 1
		PerformSilentAction(var/action, var/context)
			return 0
		MayAdvance()
			return 1
