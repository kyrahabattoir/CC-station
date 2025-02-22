// SPDX-License-Identifier: CC-BY-NC-SA-3.0

/obj/machinery/computer/cloner/portable
	name = "Port-A-Clone"
	desc = "A mobile cloning vat with a miniature enzymatic reclaimer attached. Requires corpses to be chopped up before they can be reclaimed."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "PAG_0"

	//Cloner vars
	var/obj/machinery/clone_scanner/scanner = null //Built-in scanner.
	var/obj/machinery/clonepod/pod1 = null //Built-in cloning pod.
	var/obj/machinery/computer/cloning/computer = null //Built-in computer for i/o.

	//Portable object vars
	anchored = 0
	var/locked = 0

	New()
		..()
		spawn(0)
			scanner = new /obj/machinery/clone_scanner(src) //Built-in scanner.
			pod1 = new /obj/machinery/clonepod(src) //Built-in cloning pod.
			computer = new /obj/machinery/computer/cloning(src) //Inbuilt computer for i/o.

			if(computer) computer.portable = 1
			if(pod1) pod1.portable = 1
		spawn(10)
			computer.scanner = scanner
			computer.pod1 = pod1

			computer.temp = ""
			if (isnull(computer.scanner))
				computer.temp += " <font color=red>SCNR-ERROR</font>"
			if (isnull(computer.pod1))
				computer.temp += " <font color=red>POD1-ERROR</font>"
			else
				computer.pod1.connected = computer

			if (computer.temp == "")
				computer.temp = "System ready."
			return
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/disk/data/floppy) || istype(W, /obj/item/screwdriver) || istype(W, /obj/item/cloner_upgrade))
			computer.attackby(W,user)
			src.add_fingerprint(user)

		else if (istype(W, /obj/item/grab))
			scanner.attackby(W,user)
			src.add_fingerprint(user)

		else if (istype(W, /obj/item/card/id) || (istype(W, /obj/item/device/pda2) && W:ID_card) || istype(W, /obj/item/card/emag) || istype(W, /obj/item/reagent_containers/glass))
			pod1.attackby(W,user)
			src.add_fingerprint(user)

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		return computer.attack_hand(user)