// SPDX-License-Identifier: CC-BY-NC-SA-3.0

// THIS IS STATIC, I.E. NOTHING WILL BE ABLE TO REMOVE THIS SYSTEM FROM
// THE GAME, IT CAN ONLY BE MODIFIED

// THE REASON I SAY THIS IS BECAUSE WE CAN ADD A DATACORE OR SOMETHING THAT CAN BE BLOWN UP
// AND ALL THE MONEY WILL BE GONE

/datum/wage_system

	// Stations budget
	var/station_budget = 0.0
	var/shipping_budget = 0.0
	var/research_budget = 0.0

	var/list/jobs = new/list()

	var/pay_active = 1
	var/lottery_active = 0		// inactive until someone actually buys a ticket
	var/time_between_paydays = 0.0
	var/time_until_payday = 0.0

	var/time_between_lotto = 0.0
	var/time_until_lotto = 0.0

	// We'll start at 0 credits, and increase it in the lotteryday proc
	var/lotteryJackpot = 0
	// 500 minutes ~ 8.2 hours
	var/list/winningNumbers = new/list(4, 100)
	var/lotteryRound = 1

	var/clones_for_cash = 0
	var/clone_cost = 2500 // I wanted to make this a var on SOMETHING so that it can be changed during rounds

	New()

		// 5 minutes = 3000 milliseconds
		time_between_paydays = 3000
		time_between_lotto = 5000 // this was way too fuckin high

		for(var/occupation in occupations)

			// Skip AI
			if(occupation == "AI" || occupation == "Cyborg")
				continue

			// If its not already in the list add it
			if (!(jobs.Find(occupation)))
				// 0.0 is the default wage
				jobs[occupation] = 0.0

		for(var/occupation in assistant_occupations)
			// If its not already in the list add it
			if (!(jobs.Find(occupation)))
				// 0.0 is the default wage
				jobs[occupation] = 0.0

		// Captain isn't in the occupation list
		jobs["Captain"] = 0.0

		default_wages()


	proc/default_wages()

		station_budget = 100000
		shipping_budget = 30000
		research_budget = 20000

		// This is gonna throw up some crazy errors if it isn't done right!
		// cogwerks - raising all of the paychecks, oh god

		jobs["Engineer"] = 500
		jobs["Miner"] = 550
		jobs["Mechanic"] = 450
//		jobs["Atmospheric Technician"] = 400
		jobs["Security Officer"] = 300
//		jobs["Vice Officer"] = 500
		jobs["Detective"] = 300
		jobs["Geneticist"] = 600
		jobs["Scientist"] = 400
		jobs["Medical Doctor"] = 400
		jobs["Medical Director"] = 750
		jobs["Head of Personnel"] = 750
		jobs["Head of Security"] = 750
//		jobs["Head of Security"] = 1
		jobs["Chief Engineer"] = 750
		jobs["Research Director"] = 750
		jobs["Chaplain"] = 150
		jobs["Roboticist"] = 450
//		jobs["Hangar Mechanic"]= 40
//		jobs["Elite Security"] = 300
		jobs["Barman"] = 250
		jobs["Chef"] = 250
		jobs["Janitor"] = 200
		jobs["Clown"] = 1
//		jobs["Chemist"] = 50
		jobs["Quartermaster"] = 350
		jobs["Botanist"] = 250
//		jobs["Attorney at Space-Law"] = 500
		jobs["Staff Assistant"] = 100
		jobs["Medical Assistant"] = 50
		jobs["Technical Assistant"] = 50
		jobs["Captain"] = 1000

		src.time_until_lotto = ( ticker ? ticker.round_elapsed_ticks : 0 ) + time_between_lotto
		src.time_until_payday = ( ticker ? ticker.round_elapsed_ticks : 0 ) + time_between_paydays

	// This returns the time left in seconds
	proc/timeleft()
		var/timeleft = src.time_until_payday - ticker.round_elapsed_ticks

		spawn(0)
			src.checkLotteryTime()

		if(timeleft <= 0)
			payday()
			src.time_until_payday = ticker.round_elapsed_ticks + time_between_paydays
			return 0

		return timeleft

	//Returns the time, in MM:SS format
	proc/get_banking_timeleft()
		var/timeleft = src.timeleft() / 10
		if(timeleft)
			return "[add_zero(num2text((timeleft / 60) % 60),2)]:[add_zero(num2text(timeleft % 60), 2)]"

	proc/checkLotteryTime()
		if(!lottery_active)	return

		var/timeleft = src.time_until_lotto - ticker.round_elapsed_ticks

		if(timeleft <= 0)
			lotteryDay()
			src.time_until_lotto = ticker.round_elapsed_ticks + time_between_lotto
			return 0


	proc/start_lottery()
		src.time_until_lotto = ( ticker ? ticker.round_elapsed_ticks : 0 ) + time_between_lotto
		lottery_active = 1
		return

	proc/payday()
		// Everyone gets paid into their bank accounts
		if (!wagesystem.pay_active) return // some greedy prick suspended the payroll!
		if (station_budget < 1) return // we don't have any money so don't bother!
		for(var/datum/data/record/t in data_core.bank)
			if(station_budget >= t.fields["wage"])
				t.fields["current_money"] += t.fields["wage"]
				station_budget -= t.fields["wage"]
			else
				command_alert("The station budget appears to have run dry. We regret to inform you that no further wage payments are possible until this situation is rectified.","Payroll Announcement")
				wagesystem.pay_active = 0
				break

	proc/lotteryDay()

		// Increase by 10000 regardless // cogwerks - changed this to be way higher
		lotteryJackpot += 50000

		// Just so its not a mass of text
		var/j = lotteryRound

		var/dat = ""
		// Get the winning numbers
		for(var/i=1, i<5, i++)
			winningNumbers[i][j] = rand(1,3)
			dat += "[winningNumbers[i][j]] "

		for(var/obj/item/lotteryTicket/T in world)
			// If the round associated on the lottery ticked is this round
			if(lotteryRound == T.lotteryRound)
				// Check the nubers
				if(winningNumbers[1][j] == T.numbers[1] && winningNumbers[2][j] == T.numbers[2] && winningNumbers[3][j] == T.numbers[3] && winningNumbers[4][j] == T.numbers[4] )
					// We have a winner
					T.winner = lotteryJackpot
					T.name = "Winning Ticket"

		command_alert("Lottery round [lotteryRound]. I wish you all the best of luck. For an amazing prize of [lotteryJackpot] credits the lottery numbers are: [dat]. If you have these numbers get to an ATM to claim your prize now!", "Lottery")

		// We're in the next round!
		lotteryRound += 1


/*
	proc/update_wage(var/mob/living/carbon/C, var/rank)

		if(!jobs.Find(rank))
			message_admins("Yo dudes [rank] isn't defined as having any wage, this means they won't get paid!! Alert Nannek this is a disaster!!")
			return

		jobs[rank] = C.wage
*/

/obj/machinery/computer/ATM
	name = "ATM"
	icon_state = "atm"

	var/datum/data/record/accessed_record = null
	var/obj/item/card/id/scan = null

	var/state = STATE_LOGGEDOFF
	var/const
		STATE_LOGGEDOFF = 1
		STATE_LOGGEDIN = 2

	var/pin = null

	attackby(var/obj/item/I as obj, user as mob)
		if (istype(I, /obj/item/device/pda2) && I:ID_card)
			I = I:ID_card
		if(istype(I, /obj/item/card/id))
			boutput(user, "<span style=\"color:blue\">You swipe your ID card in the ATM.</span>")
			src.scan = I
		if(istype(I, /obj/item/spacecash/))
			if (src.accessed_record)
				boutput(user, "<span style=\"color:blue\">You insert the cash into the ATM.</span>")
				src.accessed_record.fields["current_money"] += I.amount
				I.amount = 0
				qdel(I)
			else boutput(user, "<span style=\"color:red\">You need to log in before depositing cash!</span>")
		if(istype(I, /obj/item/lotteryTicket))
			if (src.accessed_record)
				boutput(user, "<span style=\"color:blue\">You insert the lottery ticket into the ATM.</span>")
				if(I:winner)
					boutput(user, "<span style=\"color:blue\">Congratulations, this ticket is a winner netting you [I:winner] credits</span>")
					src.accessed_record.fields["current_money"] += I:winner

					if(wagesystem.lotteryJackpot > I:winner)
						wagesystem.lotteryJackpot -= I:winner
					else
						wagesystem.lotteryJackpot = 0


				else
					boutput(user, "<span style=\"color:red\">This ticket isn't a winner. Better luck next time!</span>")
				qdel(I)
			else boutput(user, "<span style=\"color:red\">You need to log in before inserting a ticket!</span>")
		else
			src.attack_hand(user)
		return

	attack_ai(var/mob/user as mob)
		return

	attack_hand(var/mob/user as mob)
		if(..())
			return

		user.machine = src
		var/dat = "<head><title>Automated Teller Machine</title></head><body>"

		switch(src.state)
			if(STATE_LOGGEDOFF)
				if (src.scan)
					dat += "<BR>\[ <A HREF='?src=\ref[src];operation=cancel'>Eject Card</A> \]"
					dat += "<BR><BR>Please Enter Your Pin:"

					dat += "<BR>[src.pin]"

					dat += {"<BR>
					<A HREF='?src=\ref[src];type=1'>1</A>-<A HREF='?src=\ref[src];type=2'>2</A>-<A HREF='?src=\ref[src];type=3'>3</A><BR>
					<A HREF='?src=\ref[src];type=4'>4</A>-<A HREF='?src=\ref[src];type=5'>5</A>-<A HREF='?src=\ref[src];type=6'>6</A><BR>
					<A HREF='?src=\ref[src];type=7'>7</A>-<A HREF='?src=\ref[src];type=8'>8</A>-<A HREF='?src=\ref[src];type=9'>9</A><BR>
					<A HREF='?src=\ref[src];type=R'>R</A>-<A HREF='?src=\ref[src];type=0'>0</A>-<A HREF='?src=\ref[src];type=E'>E</A><BR>"}

				else dat += "Please swipe your card to begin."

			if(STATE_LOGGEDIN)
				if(!src.accessed_record)
					dat += "ERROR, NO RECORD DETECTED. LOGGING OFF."
					src.state = STATE_LOGGEDOFF
					src.updateUsrDialog()

				else
					dat += "<BR>\[ <A HREF='?src=\ref[src];operation=logout'>Logout</A> \]"

					if (src.scan)
						dat += "<BR>Your balance is: $ [src.accessed_record.fields["current_money"]]."
						dat += "<BR>Your balance on your card is: $ [src.scan.money]"
						dat += "<BR><BR><A HREF='?src=\ref[src];operation=withdraw'>Withdraw to Card</A>"
						dat += "<BR><A HREF='?src=\ref[src];operation=withdrawcash'>Withdraw Cash</A>"
						dat += "<BR><A HREF='?src=\ref[src];operation=deposit'>Deposit from Card</A>"

						dat += "<BR><BR><A HREF='?src=\ref[src];operation=buy'>Buy Lottery Ticket (100 credits)</A>"
						dat += "<BR>To claim your winnings you'll need to insert your lottery ticket."
					else
						dat += "<BR>Please swipe your card to continue."


		dat += "<BR>\[ <A HREF='?action=mach_close&window=atm'>Close</A> \]"
		user << browse(dat, "window=atm;size=400x500")
		onclose(user, "atm")


	proc/TryToFindRecord()
		for(var/datum/data/record/B in data_core.bank)
			if(src.scan && (B.fields["name"] == src.scan.registered) )
				src.accessed_record = B
				return 1
		return 0


	Topic(href, href_list)
		if(..())
			return
		usr.machine = src

		if (href_list["type"])
			if (href_list["type"] == "E")
				if (text2num(src.pin) == src.scan.pin)
					if(TryToFindRecord())
						src.state = STATE_LOGGEDIN
						src.pin = null
					else
						src.pin = "RECORD NOT FOUND"
				else
					src.pin = "ERROR PIN NOT CORRECT"
			else
				if (href_list["type"] == "R")
					src.pin = null
				else
					src.pin += href_list["type"]
					if (length(src.pin) > 4)
						src.pin = "ERROR PIN IS ONLY 4 DIGITS"

			src.updateUsrDialog()
			return

		switch(href_list["operation"])

			if("logout")
				src.state = STATE_LOGGEDOFF
				src.accessed_record = null
				src.scan = null

			if("withdraw")
				if (src.scan.registered in FrozenAccounts)
					boutput(usr, "<span style=\"color:red\">Your account cannot currently be liquidated due to active borrows.</span>")
					return
				var/amount = round(input(usr, "How much would you like to withdraw?", "Withdrawal", 0) as null|num)
				if(amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.accessed_record.fields["current_money"])
					boutput(usr, "<span style=\"color:red\">Insufficient funds in account.</span>")
				else
					src.scan.money += amount
					src.accessed_record.fields["current_money"] -= amount

			if("withdrawcash")
				if (src.scan.registered in FrozenAccounts)
					boutput(usr, "<span style=\"color:red\">Your account cannot currently be liquidated due to active borrows.</span>")
					return
				var/amount = round(input(usr, "How much would you like to withdraw?", "Withdrawal", 0) as num)
				if( amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.accessed_record.fields["current_money"])
					boutput(usr, "<span style=\"color:red\">Insufficient funds in account.</span>")
				else
					src.accessed_record.fields["current_money"] -= amount
					new /obj/item/spacecash(src.loc, amount )

			if("deposit")
				var/amount = round(input(usr, "How much would you like to deposit?", "Deposit", 0) as null|num)
				if(amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.scan.money)
					boutput(usr, "<span style=\"color:red\">Insufficient funds on card.</span>")
				else
					src.scan.money -= amount
					src.accessed_record.fields["current_money"] += amount

			if("buy")
				boutput(usr, "<span style=\"color:red\">Buy button clicked</span>")

			if("claim")
				boutput(usr, "<span style=\"color:red\">Claim button clicked</span>")

		src.updateUsrDialog()

/obj/machinery/computer/bank_data
	name = "Bank Records"
	icon_state = "databank"
	req_access = list(access_heads)
	var/obj/item/card/id/scan = null
	var/authenticated = null
	var/rank = null
	var/screen = null
	var/datum/data/record/active1 = null
	var/a_id = null
	var/temp = null
	var/printing = null
	var/can_change_id = 0

	attack_ai(mob/user as mob)
		return src.attack_hand(user)

	attack_hand(mob/user as mob)
		if(..())
			return
		var/dat
		if (src.temp)
			dat = text("<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>")
		else
			dat = text("Confirm Identity: <A href='?src=\ref[];scan=1'>[]</A><HR>", src, (src.scan ? text("[]", src.scan.name) : "----------"))
			if (src.authenticated)
				switch(src.screen)
					if(1.0)
						var/payroll = 0
						var/totalfunds = wagesystem.station_budget + wagesystem.research_budget + wagesystem.shipping_budget
						for(var/datum/data/record/R in data_core.bank)
							payroll += R.fields["wage"]
						dat += {"
						<u><b>Total Station Funds:</b> $[num2text(totalfunds,50)]</u>
						<BR>
						<BR><b>Current Payroll Budget:</b> $[num2text(wagesystem.station_budget,50)]
						<BR><b>Current Research Budget:</b> $[num2text(wagesystem.research_budget,50)]
						<BR><b>Current Shipping Budget:</b> $[num2text(wagesystem.shipping_budget,50)]
						<BR>
						<b>Current Payroll Cost:</b> $[payroll]
						<BR>
						<BR><br><A href='?src=\ref[src];list=1'>List Payroll Records</A>"}
						if (wagesystem.pay_active) dat += "<BR><br><A href='?src=\ref[src];payroll=1'>Suspend Payroll</A>"
						else dat += "<BR><br><A href='?src=\ref[src];payroll=1'>Resume Payroll</A>"
						dat += {"<BR><br><A href='?src=\ref[src];transfer=1'>Transfer Funds Between Budgets</A>
						<BR><br>
						<BR><br><A href='?src=\ref[src];logout=1'>{Log Out}</A>
						<BR><br>"}
					if(2.0)
						dat += "<B>Record List</B>:<HR>"
						for(var/datum/data/record/R in data_core.bank)
							dat += text("<BR><b>Name:</b> <A href='?src=\ref[src];Fname=\ref[R]'>[R.fields["name"]]</A> <b>Job:</b> <A href='?src=\ref[src];Fjob=\ref[R]'>[R.fields["job"]]</A>")
							dat += text("<BR><b>Current Wage:</b> <A href='?src=\ref[src];Fwage=\ref[R]'>[R.fields["wage"]]</A>")
							dat += text("<BR><b>Current Balance:</b> <A href='?src=\ref[src];Fmoney=\ref[R]'>[R.fields["current_money"]]</A><BR>")
						dat += text("<HR><A href='?src=\ref[src];main=1'>Back</A>")
					else
			else
				dat += text("<A href='?src=\ref[];login=1'>{Log In}</A>", src)
		user << browse(text("<HEAD><TITLE>Bank Records</TITLE></HEAD><TT>[]</TT>", dat), "window=secure_bank")
		onclose(user, "secure_bank")
		return

	Topic(href, href_list)
		if(..())
			return
		if (!( data_core.bank.Find(src.active1) ))
			src.active1 = null
		if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
			usr.machine = src
			if (href_list["temp"])
				src.temp = null
			if (href_list["scan"])
				if (src.scan)
					src.scan.set_loc(src.loc)
					src.scan = null
				else
					var/obj/item/I = usr.equipped()
					if (istype(I, /obj/item/card/id))
						usr.drop_item()
						I.set_loc(src)
						src.scan = I
			else
				if (href_list["logout"])
					src.authenticated = null
					src.screen = null
					src.active1 = null
				else
					if (href_list["login"])
						if (issilicon(usr) && !isghostdrone(usr))
							src.active1 = null
							src.authenticated = 1
							src.rank = "AI"
							src.screen = 1
						if (istype(src.scan, /obj/item/card/id))
							src.active1 = null
							if(check_access(src.scan))
								src.authenticated = src.scan.registered
								src.rank = src.scan.assignment
								src.screen = 1
			if (src.authenticated)
				if (href_list["list"])
					src.screen = 2
					src.active1 = null
				else if (href_list["main"])
					src.screen = 1
					src.active1 = null
				else if(href_list["Fname"])
					var/datum/data/record/R = locate(href_list["Fname"])
					var/t1 = input("Please input name:", "Secure. records", R.fields["name"], null)  as null|text
					t1 = copytext(html_encode(t1), 1, MAX_MESSAGE_LEN)
					if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))))) return
					R.fields["name"] = t1
				else if(href_list["Fjob"])
					var/datum/data/record/R = locate(href_list["Fjob"])
					var/t1 = input("Please input name:", "Secure. records", R.fields["job"], null)  as null|text
					t1 = copytext(html_encode(t1), 1, MAX_MESSAGE_LEN)
					if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))))) return
					R.fields["job"] = t1
				else if(href_list["Fwage"])
					var/datum/data/record/R = locate(href_list["Fwage"])
					var/t1 = input("Please input wage:", "Secure. records", R.fields["wage"], null)  as null|num
					if ((!( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))))) return
					if (t1 < 0)
						t1 = 0
						boutput(usr, "<span style=\"color:red\">You cannot set a negative wage.</span>")
					if (!t1) t1 = 0
					if (t1 > 10000)
						t1 = 10000
						boutput(usr, "<span style=\"color:red\">Maximum wage is $10,000.</span>")
					R.fields["wage"] = t1
				else if(href_list["Fmoney"])
					var/datum/data/record/R = locate(href_list["Fmoney"])
					var/avail = null
					var/t2 = input("Withdraw or Deposit?", "Secure Records", null, null) in list("Withdraw", "Deposit")
					var/t1 = input("How much?", "Secure. records", R.fields["current_money"], null)  as null|num
					if ((!( t1 ) || !( src.authenticated ) || usr.stat || usr.restrained() || (!in_range(src, usr) && (!istype(usr, /mob/living/silicon))))) return
					if (t2 == "Withdraw")
						if (R.fields["name"] in FrozenAccounts)
							boutput(usr, "<span style=\"color:red\">This account cannot currently be liquidated due to active borrows.</span>")
							return
						avail = R.fields["current_money"]
						if (t1 > avail) t1 = avail
						if (t1 < 1) return
						R.fields["current_money"] -= t1
						wagesystem.station_budget += t1
						boutput(usr, "<span style=\"color:blue\">$[t1] added to station budget from [R.fields["name"]]'s account.</span>")
					else if (t2 == "Deposit")
						avail = wagesystem.station_budget
						if (t1 > avail) t1 = avail
						if (t1 < 1) return
						R.fields["current_money"] += t1
						wagesystem.station_budget -= t1
						boutput(usr, "<span style=\"color:blue\">$[t1] added to [R.fields["name"]]'s account from station budget.</span>")
					else boutput(usr, "<span style=\"color:red\">Error selecting withdraw/deposit mode.</span>")
				else if(href_list["payroll"])
					if (wagesystem.pay_active)
						wagesystem.pay_active = 0
						command_alert("The payroll has been suspended until further notice. No further wages will be paid until the payroll is resumed.","Payroll Announcement")
					else
						wagesystem.pay_active = 1
						command_alert("The payroll has been resumed. Wages will now be paid into employee accounts normally.","Payroll Announcement")
				else if(href_list["transfer"])
					var/transfrom = input("Transfer from which?", "Budgeting", null, null) in list("Payroll", "Shipping", "Research")
					if (!transfrom)
						boutput(usr, "<span style=\"color:red\">Error selecting budget to transfer from.</span>")
						return
					var/transto = input("Transfer to which?", "Budgeting", null, null) in list("Payroll", "Shipping", "Research")
					if (!transto)
						boutput(usr, "<span style=\"color:red\">Error selecting budget to transfer to.</span>")
						return
					if (transfrom == transto)
						boutput(usr, "<span style=\"color:red\">You can't transfer a budget into itself.</span>")
						return
					var/amount = input(usr, "How much would you like to transfer?", "Budget Transfer", 0) as null|num
					if (!amount) amount = 0
					if (amount < 0) amount = 0

					if (transfrom == "Payroll" && amount > wagesystem.station_budget) amount = wagesystem.station_budget
					if (transfrom == "Shipping" && amount > wagesystem.shipping_budget) amount = wagesystem.shipping_budget
					if (transfrom == "Research" && amount > wagesystem.research_budget) amount = wagesystem.research_budget

					if (transfrom == "Payroll") wagesystem.station_budget -= amount
					if (transfrom == "Shipping") wagesystem.shipping_budget -= amount
					if (transfrom == "Research") wagesystem.research_budget -= amount

					if (transto == "Payroll") wagesystem.station_budget += amount
					if (transto == "Shipping") wagesystem.shipping_budget += amount
					if (transto == "Research") wagesystem.research_budget += amount

		src.add_fingerprint(usr)
		src.updateUsrDialog()

		return

/obj/submachine/ATM
	name = "ATM"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "atm"
	density = 0
	opacity = 0
	anchored = 1

	var/datum/data/record/accessed_record = null
	var/obj/item/card/id/scan = null

	var/state = STATE_LOGGEDOFF
	var/const
		STATE_LOGGEDOFF = 1
		STATE_LOGGEDIN = 2

	attackby(var/obj/item/I as obj, user as mob)
		if (istype(I, /obj/item/device/pda2) && I:ID_card)
			I = I:ID_card
		if(istype(I, /obj/item/card/id))
			boutput(user, "<span style=\"color:blue\">You swipe your ID card in the ATM.</span>")
			src.scan = I
		if(istype(I, /obj/item/spacecash/))
			if (src.accessed_record)
				boutput(user, "<span style=\"color:blue\">You insert the cash into the ATM.</span>")
				src.accessed_record.fields["current_money"] += I.amount
				I.amount = 0
				qdel(I)
			else boutput(user, "<span style=\"color:red\">You need to log in before depositing cash!</span>")
		if(istype(I, /obj/item/lotteryTicket))
			if (src.accessed_record)
				boutput(user, "<span style=\"color:blue\">You insert the lottery ticket into the ATM.</span>")
				if(I:winner)
					boutput(user, "<span style=\"color:blue\">Congratulations, this ticket is a winner netting you [I:winner] credits</span>")
					src.accessed_record.fields["current_money"] += I:winner

					if(wagesystem.lotteryJackpot > I:winner)
						wagesystem.lotteryJackpot -= I:winner
					else
						wagesystem.lotteryJackpot = 0
				else
					boutput(user, "<span style=\"color:red\">This ticket isn't a winner. Better luck next time!</span>")
				qdel(I)
			else boutput(user, "<span style=\"color:red\">You need to log in before inserting a ticket!</span>")
		else
			src.attack_hand(user)
		return

	attack_ai(var/mob/user as mob)
		return

	attack_hand(var/mob/user as mob)
		if(..())
			return

		user.machine = src
		var/dat = "<head><title>Automated Teller Machine</title></head><body>"

		switch(src.state)
			if(STATE_LOGGEDOFF)
				if (src.scan)
					dat += "<BR>\[ <A HREF='?src=\ref[src];operation=logout'>Logout</A> \]"
					dat += "<BR><BR><A HREF='?src=\ref[src];operation=enterpin'>Enter Pin</A>"

				else dat += "Please swipe your card to begin."

			if(STATE_LOGGEDIN)
				if(!src.accessed_record)
					dat += "ERROR, NO RECORD DETECTED. LOGGING OFF."
					src.state = STATE_LOGGEDOFF
					src.updateUsrDialog()

				else
					dat += "<BR>\[ <A HREF='?src=\ref[src];operation=logout'>Logout</A> \]"

					if (src.scan)
						dat += "<BR><BR>Your balance is: $ [src.accessed_record.fields["current_money"]]."
						dat += "<BR>Your balance on your card is: $ [src.scan.money]"
						dat += "<BR><BR><A HREF='?src=\ref[src];operation=withdraw'>Withdraw to Card</A>"
						dat += "<BR><A HREF='?src=\ref[src];operation=withdrawcash'>Withdraw Cash</A>"
						dat += "<BR><A HREF='?src=\ref[src];operation=deposit'>Deposit from Card</A>"

						dat += "<BR><BR><A HREF='?src=\ref[src];operation=buy'>Buy Lottery Ticket (100 credits)</A>"
						dat += "<BR>To claim your winnings you'll need to insert your lottery ticket."
					else
						dat += "<BR>Please swipe your card to continue."

		dat += "<BR><BR>\[ <A HREF='?action=mach_close&window=atm'>Close</A> \]"
		user << browse(dat, "window=atm;size=400x500")
		onclose(user, "atm")


	proc/TryToFindRecord()
		for(var/datum/data/record/B in data_core.bank)
			if(src.scan && (B.fields["name"] == src.scan.registered) )
				src.accessed_record = B
				return 1
		return 0


	Topic(href, href_list)
		if(..())
			return
		usr.machine = src

		switch(href_list["operation"])

			if ("enterpin")
				var/enterpin = input(usr, "Please enter your PIN number.", "ATM", 0) as null|num
				if (enterpin == src.scan.pin)
					if(TryToFindRecord())
						src.state = STATE_LOGGEDIN
					else
						boutput(usr, "<span style=\"color:red\">.Cannot find a bank record for this card.</span>")
				else
					boutput(usr, "<span style=\"color:red\">Incorrect pin number.</span>")

			if("logout")
				src.state = STATE_LOGGEDOFF
				src.accessed_record = null
				src.scan = null

			if("withdraw")
				if (scan.registered in FrozenAccounts)
					boutput(usr, "<span style='color:red'>This account is frozen!</span>")
					return
				var/amount = round(input(usr, "How much would you like to withdraw?", "Withdrawal", 0) as null|num)
				if(amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.accessed_record.fields["current_money"])
					boutput(usr, "<span style=\"color:red\">Insufficient funds in account.</span>")
				else
					src.scan.money += amount
					src.accessed_record.fields["current_money"] -= amount

			if("withdrawcash")
				if (scan.registered in FrozenAccounts)
					boutput(usr, "<span style='color:red'>This account is frozen!</span>")
					return
				var/amount = round(input(usr, "How much would you like to withdraw?", "Withdrawal", 0) as num)
				if( amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.accessed_record.fields["current_money"])
					boutput(usr, "<span style=\"color:red\">Insufficient funds in account.</span>")
				else
					src.accessed_record.fields["current_money"] -= amount
					new /obj/item/spacecash(src.loc, amount )

			if("deposit")
				var/amount = round(input(usr, "How much would you like to deposit?", "Deposit", 0) as null|num)
				if(amount < 1)
					boutput(usr, "<span style=\"color:red\">Invalid amount!</span>")
					return
				if(amount > src.scan.money)
					boutput(usr, "<span style=\"color:red\">Insufficient funds on card.</span>")
				else
					src.scan.money -= amount
					src.accessed_record.fields["current_money"] += amount

			if("buy")
				if(accessed_record.fields["current_money"] >= 100)
					src.accessed_record.fields["current_money"] -= 100
					boutput(usr, "<span style=\"color:red\">Ticket being dispensed. Good luck!</span>")

					new /obj/item/lotteryTicket(src.loc)
					wagesystem.start_lottery()

				else
					boutput(usr, "<span style=\"color:red\">Insufficient Funds</span>")

		src.updateUsrDialog()

/obj/item/lotteryTicket
	name = "Lottery Ticket"
	desc = "A winning lottery ticket perhaps...?"

	icon = 'icons/obj/writing.dmi'
	icon_state = "paper"

	w_class = 1.0

	// 4 numbers between 1 and 3 gives a one in 81 chance of winning. It's 3^4 possible combinations.
	var/list/numbers = new/list(4)
	// Lottery rounds
	var/lotteryRound = 0
	// If this ticket is a winner!
	var/winner = 0

	// Give a random set of numbers
	New()

		lotteryRound = wagesystem.lotteryRound

		name = "Lottery Ticket. Round [lotteryRound]"

		var/dat = ""

		for(var/i=1, i<5, i++)
			numbers[i] = rand(1,3)
			dat += "[numbers[i]] "

		desc = "The numbers on this ticket are: [dat]. This is for round [lotteryRound]."

proc/FindBankAccountByName(var/nametosearch)
	if (!nametosearch) return
	for(var/datum/data/record/B in data_core.bank)
		if(B.fields["name"] == nametosearch)
			return B
	return