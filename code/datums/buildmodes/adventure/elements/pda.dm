// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/datum/puzzlewizard/pda
	var/html_content = null
	var/list/actions = list()
	var/action_slots = 0
	var/stage = 1

	proc/show_html_help()
		var/help_text = {"<b>If you don't know what HTML is, you probably should read up on it on w3schools.com.</b><br><br>
The HTML source for the interface of handheld computers must match the following criteria:<br>
<ul><li>No tags taking a href attribute are allowed. This includes a and link.</li>
<li>Javascript is not allowed in any format. This includes script tags and inline (onclick, etc) events.</li>
<li>The HTML source must define at least one action slot</li></ul><br><br>
<b>Action slots</b> are defined by the placeholders in the form of &lt;index&gt;, where index is a number greater than or equal to 1.<br>
The number of action slots on the device will be the highest index in the sequence from 1 to that index.<br>
So if the document contains &lt;1&gt; &lt;2&gt; &lt;3&gt; then the number of action slots will be 3.<br>
But if the document contains &lt;1&gt; &lt;2&gt; &lt;4&gt; then the number of action slots will be 2 instead of 4 due to the missing &lt;3&gt;."}
		usr << browse(help_text, "window=pda_help;size=300x300")

	initialize()
		var/is_custom = alert("Use custom HTML?",,"Yes", "What is this?", "No")
		if (is_custom == "What is this?")
			show_html_help()
			is_custom = alert("Use custom HTML?",,"Yes", "No")
		if (is_custom == "Yes")
			// Prediction: someone will stumble upon this, facepalm, then link the stackoverflow answer with the regex html matching.
			// [placeholder comment for where that will happen in the future]
			// ------
			var/html_file = input("Select HTML source file.", "HTML Source", null) as file|null
			if (!html_file)
				boutput(usr, "<span style=\"color:blue\">File loading cancelled. Not using custom HTML.</span>")
				is_custom = "No"
			else
				html_content = file2text(html_file)
				if (!html_content)
					boutput(usr, "<span style=\"color:red\">Error loading file. Not using custom HTML.</span>")
					is_custom = "No"
				else
					boutput(usr, "<span style=\"color:blue\">Verifying file sanity.</span>")
					if (findtext(html_content, "href"))
						boutput(usr, "<span style=\"color:red\">Sorry, the HTML content file cannot contain additional links.</span>")
						html_content = null
						is_custom = "No"
					var/regex/jsep = new("on[a-zA-Z]+\\s*=", "i")
					else if (findtext(html_content, "script") || jsep.Find(html_content))
						boutput(usr, "<span style=\"color:red\">Sorry, the HTML content file cannot contain javascript.</span>")
						html_content = null
						is_custom = "No"
					else
						var/id = 1
						var/finding = "<[id]>"
						while (findtext(html_content, finding))
							id++
							finding = "<[id]>"
						action_slots = id - 1
						if (!action_slots)
							boutput(usr, "<span style=\"color:red\">No action slots found in the HTML template.</span>")
							html_content = null
							is_custom = "No"
						else
							boutput(usr, "<span style=\"color:blue\">File is probably sanitary. Allowed. Goodbye universe.</span>")
			boutput(usr, "<span style=\"color:blue\">STAGE 1: Select triggerables and associate actions with left click. Right Click to associate a name with this action group and start a new action group.</span>")
			boutput(usr, "<span style=\"color:blue\">All actions in a single group will be executed at once by the associated named button.</span>")
			boutput(usr, "<span style=\"color:blue\">CTRL+Right Click to end the action assignment phase and place handheld computers.</span>")
			boutput(usr, "<span style=\"color:blue\">You will not be able to assign new actions after you end this stage.</span>")
			boutput(usr, "<span style=\"color:blue\">If you loaded custom HTML, the number of action groups must match the amount of action slots defined by the HTML.</span>")

	build_click(var/mob/user, var/datum/buildmode_holder/holder, var/list/pa, var/atom/object)
		switch (stage)
			if (1)

			if (2)