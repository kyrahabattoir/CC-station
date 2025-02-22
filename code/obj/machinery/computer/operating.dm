// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/computer/operating
	name = "Operating Computer"
	density = 1
	anchored = 1.0
	icon = 'icons/obj/computer.dmi'
	icon_state = "operating"
	desc = "Shows information on a patient laying on an operating table."
	power_usage = 500

	var/mob/living/carbon/human/victim = null

	var/obj/machinery/optable/table = null
	var/id = 0.0

/obj/machinery/computer/operating/New()
	..()
	spawn(5)
		src.table = locate(/obj/machinery/optable, orange(2,src))

/obj/machinery/computer/operating/attack_ai(mob/user)
	add_fingerprint(user)
	if(stat & (BROKEN|NOPOWER))
		return
	interact(user)

/obj/machinery/computer/operating/attack_hand(mob/user)
	add_fingerprint(user)
	if(stat & (BROKEN|NOPOWER))
		return
	interact(user)

/obj/machinery/computer/operating/attackby(I as obj, user as mob)
	if(istype(I, /obj/item/screwdriver))
		playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
		if(do_after(user, 20))
			if (src.stat & BROKEN)
				boutput(user, "<span style=\"color:blue\">The broken glass falls out.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				new /obj/item/raw_material/shard/glass( src.loc )
				var/obj/item/circuitboard/operating/M = new /obj/item/circuitboard/operating( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 3
				A.icon_state = "3"
				A.anchored = 1
				qdel(src)
			else
				boutput(user, "<span style=\"color:blue\">You disconnect the monitor.</span>")
				var/obj/computerframe/A = new /obj/computerframe( src.loc )
				if(src.material) A.setMaterial(src.material)
				var/obj/item/circuitboard/operating/M = new /obj/item/circuitboard/operating( A )
				for (var/obj/C in src)
					C.set_loc(src.loc)
				A.circuit = M
				A.state = 4
				A.icon_state = "4"
				A.anchored = 1
				qdel(src)
	else
		src.attack_hand(user)
	return

/obj/machinery/computer/operating/proc/interact(mob/user)
	if ( (get_dist(src, user) > 1 ) || (stat & (BROKEN|NOPOWER)) )
		if (!istype(user, /mob/living/silicon))
			user.machine = null
			user << browse(null, "window=op")
			return

	user.machine = src
	var/dat = "<HEAD><TITLE>Operating Computer</TITLE><META HTTP-EQUIV='Refresh' CONTENT='10'></HEAD><BODY><br>"
	dat += "<A HREF='?action=mach_close&window=op'>Close</A><br><br>" //| <A HREF='?src=\ref[user];update=1'>Update</A>"
	if(src.table && (src.table.check_victim()))
		src.victim = src.table.victim
		dat += {"
<B>Patient Information:</B><BR>
<BR>
<B>Name:</B> [src.victim.real_name]<BR>
<B>Age:</B> [src.victim.bioHolder.age]<BR>
<B>Blood Type:</B> [src.victim.bioHolder.bloodType]<BR>
<BR>
<B>Health:</B> [src.victim.health]<BR>
<B>Brute Damage:</B> [src.victim.get_brute_damage()]<BR>
<B>Toxins Damage:</B> [src.victim.get_toxin_damage()]<BR>
<B>Fire Damage:</B> [src.victim.get_burn_damage()]<BR>
<B>Suffocation Damage:</B> [src.victim.get_oxygen_deprivation()]<BR>
<B>Patient Status:</B> [src.victim.stat ? "Non-responsive" : "Stable"]<BR>
"}
	else
		src.victim = null
		dat += {"
<B>Patient Information:</B><BR>
<BR>
<B>No Patient Detected</B>
"}
	user << browse(dat, "window=op")
	onclose(user, "op")

/obj/machinery/computer/operating/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (istype(usr, /mob/living/silicon)))
		usr.machine = src
//		if (href_list["update"])
//			src.interact(usr)
	return

/obj/machinery/computer/operating/process()
	..()
	if (stat & (BROKEN | NOPOWER))
		return
	use_power(250)

	src.updateDialog()
