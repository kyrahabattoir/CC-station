// SPDX-License-Identifier: CC-BY-NC-SA-3.0

#define AIRLOCK_WIRE_IDSCAN 1
#define AIRLOCK_WIRE_MAIN_POWER1 2
#define AIRLOCK_WIRE_MAIN_POWER2 3
#define AIRLOCK_WIRE_DOOR_BOLTS 4
#define AIRLOCK_WIRE_BACKUP_POWER1 5
#define AIRLOCK_WIRE_BACKUP_POWER2 6
#define AIRLOCK_WIRE_OPEN_DOOR 7
#define AIRLOCK_WIRE_AI_CONTROL 8
#define AIRLOCK_WIRE_ELECTRIFY 9

/*
	New methods:
	pulse - sends a pulse into a wire for hacking purposes
	cut - cuts a wire and makes any necessary state changes
	mend - mends a wire and makes any necessary state changes
	isWireColorCut - returns 1 if that color wire is cut, or 0 if not
	isWireCut - returns 1 if that wire (e.g. AIRLOCK_WIRE_DOOR_BOLTS) is cut, or 0 if not
	canAIControl - 1 if the AI can control the airlock, 0 if not (then check canAIHack to see if it can hack in)
	canAIHack - 1 if the AI can hack into the airlock to recover control, 0 if not. Also returns 0 if the AI does not *need* to hack it.
	arePowerSystemsOn - 1 if the main or backup power are functioning, 0 if not. Does not check whether the power grid is charged or an APC has equipment on or anything like that. (Check (stat & NOPOWER) for that)
	requiresIDs - 1 if the airlock is requiring IDs, 0 if not
	isAllPowerCut - 1 if the main and backup power both have cut wires.
	regainMainPower - handles the effects of main power coming back on.
	loseMainPower - handles the effects of main power going offline. Usually (if one isn't already running) spawn a thread to count down how long it will be offline - counting down won't happen if main power was completely cut along with backup power, though, the thread will just sleep.
	loseBackupPower - handles the effects of backup power going offline.
	regainBackupPower - handles the effects of main power coming back on.
	shock - has a chance of electrocuting its target.
*/

//This generates the randomized airlock wire assignments for the game.
/proc/RandomAirlockWires()
	//to make this not randomize the wires, just set index to 1 and increment it in the flag for loop (after doing everything else).
	var/list/wires = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockIndexToFlag = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockIndexToWireColor = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	airlockWireColorToIndex = list(0, 0, 0, 0, 0, 0, 0, 0, 0)
	var/flagIndex = 1
	for (var/flag=1, flag<512, flag+=flag)
		var/valid = 0
		while (!valid)
			var/colorIndex = rand(1, 9)
			if (wires[colorIndex]==0)
				valid = 1
				wires[colorIndex] = flag
				airlockIndexToFlag[flagIndex] = flag
				airlockIndexToWireColor[flagIndex] = colorIndex
				airlockWireColorToIndex[colorIndex] = flagIndex
		flagIndex+=1
	return wires

/* Example:
Airlock wires color -> flag are { 64, 128, 256, 2, 16, 4, 8, 32, 1 }.
Airlock wires color -> index are { 7, 8, 9, 2, 5, 3, 4, 6, 1 }.
Airlock index -> flag are { 1, 2, 4, 8, 16, 32, 64, 128, 256 }.
Airlock index -> wire color are { 9, 4, 6, 7, 5, 8, 1, 2, 3 }.
*/

/obj/machinery/door/airlock
	name = "airlock"
	icon = 'icons/obj/doors/doorint.dmi'
	icon_state = "door_closed"

	var/image/panel_image = null
	var/panel_icon_state = "panel_open"

	var/image/welded_image = null
	var/welded_icon_state = "welded"

	explosion_resistance = 2

	var/ai_no_access = 0 //This is the dumbest var.
	var/aiControlDisabled = 0 //If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
	var/secondsMainPowerLost = 0 //The number of seconds until power is restored.
	var/secondsBackupPowerLost = 0 //The number of seconds until power is restored.
	var/spawnPowerRestoreRunning = 0
	var/welded = null
	var/wires = 511
	secondsElectrified = 0 //How many seconds remain until the door is no longer electrified. -1 if it is permanently electrified until someone fixes it.
	var/aiDisabledIdScanner = 0
	var/aiHacking = 0
	var/obj/machinery/door/airlock/closeOther = null
	var/closeOtherId = null
	var/list/signalers[9]
	var/lockdownbyai = 0
	var/last_bump = 0
	var/net_id = null
	var/sound_airlock = 'sound/machines/airlock_swoosh_temp.ogg'
	var/sound_close_airlock = null
	var/sound_deny = 'sound/machines/airlock_deny_temp.ogg'
	var/id = null
	var/radiorange = AIRLOCK_CONTROL_RANGE

	autoclose = 1
	power_usage = 50
	operation_time = 6
	brainloss_stumble = 1

/obj/machinery/door/airlock/command
	icon = 'icons/obj/doors/Doorcom.dmi'
	req_access = list(access_heads)

/obj/machinery/door/airlock/security
	icon = 'icons/obj/doors/Doorsec.dmi'
	req_access = list(access_security)

/obj/machinery/door/airlock/engineering
	name = "Engineering"
	icon = 'icons/obj/doors/Dooreng.dmi'
	req_access = list(access_engineering)
	req_access_txt = "40"

/obj/machinery/door/airlock/medical
	icon = 'icons/obj/doors/doormed.dmi'
	req_access = list(access_medical)

/obj/machinery/door/airlock/maintenance
	name = "Maintenance Access"
	icon = 'icons/obj/doors/Doormaint.dmi'
	req_access = list(access_maint_tunnels)

/obj/machinery/door/airlock/external
	name = "external airlock"
	icon = 'icons/obj/doors/Doorext.dmi'
	sound_airlock = 'sound/machines/airlock.ogg'
	opacity = 0
	visible = 0
	operation_time = 10

/obj/machinery/door/airlock/syndicate // fuck our players for making us (or at least me) need this
	name = "reinforced external airlock"
	desc = "Looks pretty tough. I wouldn't take this door on in a fight."
	icon = 'icons/obj/doors/Doorext.dmi'
	req_access = list(access_syndicate_shuttle)
	cant_emag = 1
	hardened = 1
	aiControlDisabled = 1

	meteorhit()
		return

	ex_act()
		return

/obj/machinery/door/airlock/glass
	name = "glass airlock"
	icon = 'icons/obj/doors/Doorglass.dmi'
	opacity = 0
	visible = 0

/obj/machinery/door/airlock/glass/command
		icon = 'icons/obj/doors/Doorcom-glass.dmi'
		req_access = list(access_heads)

/obj/machinery/door/airlock/glass/engineering
		icon = 'icons/obj/doors/Dooreng-glass.dmi'
		req_access = list(access_engineering)
		req_access_txt = "40"

/obj/machinery/door/airlock/glass/medical
		icon = 'icons/obj/doors/Doormed-glass.dmi'
		req_access = list(access_medical)

/obj/machinery/door/airlock/classic
	icon = 'icons/obj/doors/Doorclassic.dmi'
	sound_airlock = 'sound/machines/airlock.ogg'
	operation_time = 10

/obj/machinery/door/airlock/pyro
	name = "airlock"
	icon = 'icons/obj/doors/SL_doors.dmi'
	icon_state = "generic_closed"
	icon_base = "generic"
	panel_icon_state = "panel_open"
	welded_icon_state = "welded"

/*	New()
		..()
		// a lazy pixel offset
		if(src.dir == 1 || src.dir == 2)
			src.pixel_y -= 3
		return
*/
/obj/machinery/door/airlock/pyro/alt
	icon_state = "generic2_closed"
	icon_base = "generic2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/command
	name = "Command"
	icon_state = "com_closed"
	icon_base = "com"
	req_access = list(access_heads)

/obj/machinery/door/airlock/pyro/command/alt
	icon_state = "com2_closed"
	icon_base = "com2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/security
	name = "Security"
	icon_state = "sec_closed"
	icon_base = "sec"
	req_access = list(access_security)

/obj/machinery/door/airlock/pyro/security/alt
	icon_state = "sec2_closed"
	icon_base = "sec2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/engineering
	name = "Engineering"
	icon_state = "eng_closed"
	icon_base = "eng"
	req_access = list(access_engineering)
	req_access_txt = "40"

/obj/machinery/door/airlock/pyro/engineering/alt
	icon_state = "eng2_closed"
	icon_base = "eng2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/medical
	icon_state = "research_closed"
	icon_base = "research"
	req_access = list(access_medical)

/obj/machinery/door/airlock/pyro/medical/alt
	icon_state = "research2_closed"
	icon_base = "research2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/maintenance
	name = "maintenance access"
	icon_state = "maint_closed"
	icon_base = "maint"
	req_access = list(access_maint_tunnels)

/obj/machinery/door/airlock/pyro/maintenance/alt
	icon_state = "maint2_closed"
	icon_base = "maint2"
	panel_icon_state = "2_panel_open"
	welded_icon_state = "2_welded"

/obj/machinery/door/airlock/pyro/external
	name = "external airlock"
	icon_state = "airlock_closed"
	icon_base = "airlock"
	panel_icon_state = "airlock_panel_open"
	welded_icon_state = "airlock_welded"
	sound_airlock = 'sound/machines/airlock.ogg'
	opacity = 0
	visible = 0
	operation_time = 10

/obj/machinery/door/airlock/pyro/syndicate
	name = "reinforced external airlock"
	desc = "Looks pretty tough. I wouldn't take this door on in a fight."
	icon_state = "airlock_closed"
	icon_base = "airlock"
	panel_icon_state = "airlock_panel_open"
	welded_icon_state = "airlock_welded"
	sound_airlock = 'sound/machines/airlock.ogg'
	operation_time = 10
	req_access = list(access_syndicate_shuttle)
	cant_emag = 1
	hardened = 1
	aiControlDisabled = 1

	meteorhit()
		return
	ex_act()
		return

/obj/machinery/door/airlock/pyro/glass
	name = "glass airlock"
	icon_state = "glass_closed"
	icon_base = "glass"
	panel_icon_state = "glass_panel_open"
	welded_icon_state = "glass_welded"
	opacity = 0
	visible = 0

/obj/machinery/door/airlock/pyro/glass/brig
	req_access = list(access_brig)

/obj/machinery/door/airlock/pyro/glass/command
	icon_state = "com_glass_closed"
	icon_base = "com_glass"
	req_access = list(access_heads)

/obj/machinery/door/airlock/pyro/glass/engineering
	icon_state = "eng_glass_closed"
	icon_base = "eng_glass"
	req_access = list(access_engineering)
	req_access_txt = "40"

/obj/machinery/door/airlock/pyro/classic
	icon_state = "old_closed"
	icon_base = "old"
	panel_icon_state = "old_panel_open"
	welded_icon_state = "old_welded"
	sound_airlock = 'sound/machines/airlock.ogg'
	operation_time = 10

/obj/machinery/door/airlock/gannets
	name = "airlock"
	icon = 'icons/obj/doors/destiny.dmi'
	icon_state = "gen_closed"
	icon_base = "gen"

	command
		icon_state = "com_closed"
		icon_base = "com"
		req_access = list(access_heads)

	command/alt
		icon_state = "fcom_closed"
		icon_base = "fcom"
		welded_icon_state = "fcom_welded"

	security
		icon_state = "sec_closed"
		icon_base = "sec"
		req_access = list(access_security)

	security/alt
		icon_state = "fsec_closed"
		icon_base = "fsec"
		welded_icon_state = "fsec_welded"

	engineering
		icon_state = "eng_closed"
		icon_base = "eng"
		req_access = list(access_engineering)

	engineering/alt
		icon_state = "feng_closed"
		icon_base = "feng"
		welded_icon_state = "feng_welded"

	medical
		icon_state = "med_closed"
		icon_base = "med"
		req_access = list(access_medical)

	chemistry
		icon_state = "chem_closed"
		icon_base = "chem"
		req_access = list(access_research)

	toxins
		icon_state = "tox_closed"
		icon_base = "tox"
		req_access = list(access_research)

	maintenance
		icon_state = "maint_closed"
		icon_base = "maint"
		welded_icon_state = "maint_welded"
		req_access = list(access_maint_tunnels)

/obj/machinery/door/airlock/gannets/glass
	name = "glass airlock"
	icon = 'icons/obj/doors/destiny.dmi'
	icon_state = "tgen_closed"
	icon_base = "tgen"
	opacity = 0
	visible = 0

	command
		icon_state = "tcom_closed"
		icon_base = "tcom"
		req_access = list(access_heads)

	command/alt
		icon_state = "tfcom_closed"
		icon_base = "tfcom"
		welded_icon_state = "fcom_welded"

	security
		icon_state = "tsec_closed"
		icon_base = "tsec"
		req_access = list(access_security)

	security/alt
		icon_state = "tfsec_closed"
		icon_base = "tfsec"
		welded_icon_state = "fsec_welded"

	engineering
		icon_state = "teng_closed"
		icon_base = "teng"
		req_access = list(access_engineering)

	engineering/alt
		icon_state = "tfeng_closed"
		icon_base = "tfeng"
		welded_icon_state = "feng_welded"

	medical
		icon_state = "tmed_closed"
		icon_base = "tmed"
		req_access = list(access_medical)

	chemistry
		icon_state = "tchem_closed"
		icon_base = "tchem"
		req_access = list(access_research)

	toxins
		icon_state = "ttox_closed"
		icon_base = "ttox"
		req_access = list(access_research)

	maintenance
		icon_state = "tmaint_closed"
		icon_base = "tmaint"
		welded_icon_state = "tmaint_welded"
		req_access = list(access_maint_tunnels)

/*
About the new airlock wires panel:
*	An airlock wire dialog can be accessed by the normal way or by using wirecutters or a multitool on the door while the wire-panel is open. This would show the following wires, which you can either wirecut/mend or send a multitool pulse through. There are 9 wires.
*		one wire from the ID scanner. Sending a pulse through this flashes the red light on the door (if the door has power). If you cut this wire, the door will stop recognizing valid IDs. (If the door has 0000 access, it still opens and closes, though)
*		two wires for power. Sending a pulse through either one causes a breaker to trip, disabling the door for 10 seconds if backup power is connected, or 1 minute if not (or until backup power comes back on, whichever is shorter). Cutting either one disables the main door power, but unless backup power is also cut, the backup power re-powers the door in 10 seconds. While unpowered, the door may be red open, but bolts-raising will not work. Cutting these wires may electrocute the user.
*		one wire for door bolts. Sending a pulse through this drops door bolts (whether the door is powered or not) or raises them (if it is). Cutting this wire also drops the door bolts, and mending it does not raise them. If the wire is cut, trying to raise the door bolts will not work.
*		two wires for backup power. Sending a pulse through either one causes a breaker to trip, but this does not disable it unless main power is down too (in which case it is disabled for 1 minute or however long it takes main power to come back, whichever is shorter). Cutting either one disables the backup door power (allowing it to be crowbarred open, but disabling bolts-raising), but may electocute the user.
*		one wire for opening the door. Sending a pulse through this while the door has power makes it open the door if no access is required.
*		one wire for AI control. Sending a pulse through this blocks AI control for a second or so (which is enough to see the AI control light on the panel dialog go off and back on again). Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
*		one wire for electrifying the door. Sending a pulse through this electrifies the door for 30 seconds. Cutting this wire electrifies the door, so that the next person to touch the door without insulated gloves gets electrocuted. (Currently it is also STAYING electrified until someone mends the wire)
*/

/obj/machinery/door/airlock/proc/pulse(var/wireColor)
	//var/wireFlag = airlockWireColorToFlag[wireColor] //not used in this function
	var/wireIndex = airlockWireColorToIndex[wireColor]
	switch(wireIndex)
		if(AIRLOCK_WIRE_IDSCAN)
			//Sending a pulse through this flashes the red light on the door (if the door has power).
			if ((src.arePowerSystemsOn()) && (!(stat & NOPOWER)))
				play_animation("deny")
				playsound(get_turf(src), src.sound_deny, 100, 0)
		if (AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
			//Sending a pulse through either one causes a breaker to trip, disabling the door for 10 seconds if backup power is connected, or 1 minute if not (or until backup power comes back on, whichever is shorter).
			src.loseMainPower()
		if (AIRLOCK_WIRE_DOOR_BOLTS)
			//one wire for door bolts. Sending a pulse through this drops door bolts if they're not down (whether power's on or not),
			//raises them if they are down (only if power's on)
			if (!src.locked)
				src.locked = 1
				boutput(usr, "You hear a click from the bottom of the door.")
				src.updateUsrDialog()
			else
				if(src.arePowerSystemsOn()) //only can raise bolts if power's on
					src.locked = 0
					src.updateUsrDialog()
				boutput(usr, "You hear a click from inside the door.")
			update_icon()

		if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
			//two wires for backup power. Sending a pulse through either one causes a breaker to trip, but this does not disable it unless main power is down too (in which case it is disabled for 1 minute or however long it takes main power to come back, whichever is shorter).
			src.loseBackupPower()
		if (AIRLOCK_WIRE_AI_CONTROL)
			if (src.aiControlDisabled == 0)
				src.aiControlDisabled = 1
			else if (src.aiControlDisabled == -1)
				src.aiControlDisabled = 2
			src.updateDialog()
			spawn(10)
				if (src.aiControlDisabled == 1)
					src.aiControlDisabled = 0
				else if (src.aiControlDisabled == 2)
					src.aiControlDisabled = -1
				src.updateDialog()
		if (AIRLOCK_WIRE_ELECTRIFY)
			//one wire for electrifying the door. Sending a pulse through this electrifies the door for 30 seconds.
			if (src.secondsElectrified==0)
				src.secondsElectrified = 30
				logTheThing("station", usr, null, "temporarily electrified an airlock at [log_loc(src)] with a pulse.")
				spawn(10)
					//TODO: Move this into process() and make pulsing reset secondsElectrified to 30
					while (src.secondsElectrified>0)
						src.secondsElectrified-=1
						if (src.secondsElectrified<0)
							src.secondsElectrified = 0
						src.updateUsrDialog()
						sleep(10)
		if(AIRLOCK_WIRE_OPEN_DOOR)
			//tries to open the door without ID
			//will succeed only if the ID wire is cut or the door requires no access
			if (!src.requiresID() || src.check_access(null))
				if (src.density)
					open()
				else
					close()

/obj/machinery/door/airlock/proc/cut(var/wireColor)
	var/wireFlag = airlockWireColorToFlag[wireColor]
	var/wireIndex = airlockWireColorToIndex[wireColor]
	wires &= ~wireFlag
	switch(wireIndex)
		if(AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
			//Cutting either one disables the main door power, but unless backup power is also cut, the backup power re-powers the door in 10 seconds. While unpowered, the door may be crowbarred open, but bolts-raising will not work. Cutting these wires may electocute the user.
			src.loseMainPower()
			spawn(1)
				src.shock(usr, 50)
			src.updateUsrDialog()
		if (AIRLOCK_WIRE_DOOR_BOLTS)
			//Cutting this wire also drops the door bolts, and mending it does not raise them. (This is what happens now, except there are a lot more wires going to door bolts at present)
			if (src.locked!=1)
				src.locked = 1
			update_icon()
			src.updateUsrDialog()
		if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
			//Cutting either one disables the backup door power (allowing it to be crowbarred open, but disabling bolts-raising), but may electocute the user.
			src.loseBackupPower()
			spawn(1)
				src.shock(usr, 50)
			src.updateUsrDialog()
		if (AIRLOCK_WIRE_AI_CONTROL)
			//one wire for AI control. Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
			//aiControlDisabled: If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
			if (src.aiControlDisabled == 0)
				src.aiControlDisabled = 1
			else if (src.aiControlDisabled == -1)
				src.aiControlDisabled = 2
			src.updateUsrDialog()
		if (AIRLOCK_WIRE_ELECTRIFY)
			//Cutting this wire electrifies the door, so that the next person to touch the door without insulated gloves gets electrocuted.
			if (src.secondsElectrified != -1)
				logTheThing("station", usr, null, "permanently electrified an airlock at [log_loc(src)] by cutting the shock wire.")
				src.secondsElectrified = -1

/obj/machinery/door/airlock/proc/mend(var/wireColor)
	var/wireFlag = airlockWireColorToFlag[wireColor]
	var/wireIndex = airlockWireColorToIndex[wireColor] //not used in this function
	wires |= wireFlag
	switch(wireIndex)
		if(AIRLOCK_WIRE_MAIN_POWER1 || AIRLOCK_WIRE_MAIN_POWER2)
			if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
				src.regainMainPower()
				spawn(1)
					src.shock(usr, 50)
				src.updateUsrDialog()
		if (AIRLOCK_WIRE_BACKUP_POWER1 || AIRLOCK_WIRE_BACKUP_POWER2)
			if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
				src.regainBackupPower()
				spawn(1)
					src.shock(usr, 50)
				src.updateUsrDialog()
		if (AIRLOCK_WIRE_AI_CONTROL)
			//one wire for AI control. Cutting this prevents the AI from controlling the door unless it has hacked the door through the power connection (which takes about a minute). If both main and backup power are cut, as well as this wire, then the AI cannot operate or hack the door at all.
			//aiControlDisabled: If 1, AI control is disabled until the AI hacks back in and disables the lock. If 2, the AI has bypassed the lock. If -1, the control is enabled but the AI had bypassed it earlier, so if it is disabled again the AI would have no trouble getting back in.
			if (src.aiControlDisabled == 1)
				src.aiControlDisabled = 0
			else if (src.aiControlDisabled == 2)
				src.aiControlDisabled = -1
			src.updateUsrDialog()
		if (AIRLOCK_WIRE_ELECTRIFY)
			if (src.secondsElectrified == -1)
				src.secondsElectrified = 0

/obj/machinery/door/airlock/proc/isElectrified()
	return (src.secondsElectrified != 0)

/obj/machinery/door/airlock/proc/isWireColorCut(var/wireColor)
	var/wireFlag = airlockWireColorToFlag[wireColor]
	return ((src.wires & wireFlag) == 0)

/obj/machinery/door/airlock/proc/isWireCut(var/wireIndex)
	var/wireFlag = airlockIndexToFlag[wireIndex]
	return ((src.wires & wireFlag) == 0)

/obj/machinery/door/airlock/proc/canAIControl()
	return ((src.aiControlDisabled!=1) && (!src.isAllPowerCut()) && (src.hardened == 0));

/obj/machinery/door/airlock/proc/canAIHack()
	return ((src.aiControlDisabled==1) && (!src.isAllPowerCut()) && (src.hardened == 0));

/obj/machinery/door/airlock/proc/arePowerSystemsOn()
	return (src.secondsMainPowerLost==0 || src.secondsBackupPowerLost==0)

/obj/machinery/door/airlock/requiresID()
	return !(src.isWireCut(AIRLOCK_WIRE_IDSCAN) || aiDisabledIdScanner)

/obj/machinery/door/airlock/proc/isAllPowerCut()
	var/retval=0
	if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1) || src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2))
		if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1) || src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2))
			retval=1
	return retval

/obj/machinery/door/airlock/proc/regainMainPower()
	if (src.secondsMainPowerLost > 0)
		src.secondsMainPowerLost = 0

/obj/machinery/door/airlock/proc/loseMainPower()
	if (src.secondsMainPowerLost <= 0)
		src.secondsMainPowerLost = 60
		if (src.secondsBackupPowerLost < 10)
			src.secondsBackupPowerLost = 10
	if (!src.spawnPowerRestoreRunning)
		src.spawnPowerRestoreRunning = 1
		spawn(0)
			var/cont = 1
			while (cont)
				sleep(10)
				cont = 0
				if (src.secondsMainPowerLost>0)
					if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
						src.secondsMainPowerLost -= 1
						src.updateDialog()
					cont = 1

				if (src.secondsBackupPowerLost>0)
					if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
						src.secondsBackupPowerLost -= 1
						src.updateDialog()
					cont = 1
			src.spawnPowerRestoreRunning = 0
			src.updateDialog()

/obj/machinery/door/airlock/proc/loseBackupPower()
	if (src.secondsBackupPowerLost < 60)
		src.secondsBackupPowerLost = 60

/obj/machinery/door/airlock/proc/regainBackupPower()
	if (src.secondsBackupPowerLost > 0)
		src.secondsBackupPowerLost = 0

//borrowed from the grille's get_connection
/obj/machinery/door/airlock/proc/get_connection()
	if(stat & NOPOWER)
		return 0

	var/obj/machinery/power/apc/localAPC = get_local_apc(src)
	if (localAPC && localAPC.terminal && localAPC.terminal.powernet)
		return localAPC.terminal.powernet.number

	return 0

// shock user with probability prb (if all connections & power are working)
// returns 1 if shocked, 0 otherwise
// The preceding comment was borrowed from the grille's shock script
/obj/machinery/door/airlock/proc/shock(mob/user, prb)

	if(!prob(prb))
		return 0 //you lucked out, no shock for you

	var/net = get_connection()		// find the powernet of the connected cable

	if(!net)		// cable is unpowered
		return 0


	//if (src.airlockelectrocute(user, net))
		//return 1
	/// cogwerks: unifying this with cabl electrocution
	//var/atom/A = src
	if(src.electrocute(user, prb, net))
		return 1

	else
		return 0

/obj/machinery/door/airlock/proc/airlockelectrocute(mob/user, netnum) // cogwerks - this should be commented out or removed later but i am too tired right now
	//You're probably getting shocked deal w/ it

	if(!netnum)		// unconnected cable is unpowered
		return 0

	var/prot = 1

	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user

		if(H.gloves)
			var/obj/item/clothing/gloves/G = H.gloves

			prot = G.siemens_coefficient
	else if (istype(user, /mob/living/silicon))
		return 0

	if(prot == 0)		// elec insulted gloves protect completely
		return 0

	//ok you're getting shocked now
	var/datum/powernet/PN			// find the powernet
	if(powernets && powernets.len >= netnum)
		PN = powernets[netnum]

	var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
	s.set_up(5, 1, src)
	s.start()

	var/shock_damage = 0
	if(PN.avail > 750000)	//someone juiced up the grid enough, people going to die!
		shock_damage = min(rand(70,145),rand(70,145))*prot
	else if(PN.avail > 100000)
		shock_damage = min(rand(35,110),rand(35,110))*prot
	else if(PN.avail > 75000)
		shock_damage = min(rand(30,100),rand(30,100))*prot
	else if(PN.avail > 50000)
		shock_damage = min(rand(25,90),rand(25,90))*prot
	else if(PN.avail > 25000)
		shock_damage = min(rand(20,80),rand(20,80))*prot
	else if(PN.avail > 10000)
		shock_damage = min(rand(20,65),rand(20,65))*prot
	else
		shock_damage = min(rand(20,45),rand(20,45))*prot

//		message_admins("<span style=\"color:blue\"><B>ADMIN: </B>DEBUG: shock_damage = [shock_damage] PN.avail = [PN.avail] user = [user] netnum = [netnum]</span>")

	if (user.bioHolder.HasEffect("resist_electric") == 2)
		var/healing = 0
		if (shock_damage)
			healing = shock_damage / 3
		user.HealDamage("All", healing, healing)
		user.take_toxin_damage(0 - healing)
		boutput(user, "<span style=\"color:blue\">You absorb the electrical shock, healing your body!</span>")
		return
	else if (user.bioHolder.HasEffect("resist_electric") == 1)
		boutput(user, "<span style=\"color:blue\">You feel electricity course through you harmlessly!</span>")
		return

	user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 0, shock_damage)
	user.updatehealth()
	boutput(user, "<span style=\"color:red\"><B>You feel a powerful shock course through your body!</B></span>")
	user.unlock_medal("HIGH VOLTAGE", 1)
	if (isliving(user))
		var/mob/living/L = user
		L.Virus_ShockCure(33)
		L.shock_cyberheart(33)
	sleep(1)
	if(user.stunned < shock_damage)	user.stunned = shock_damage
	if(user.weakened < 10*prot)	user.weakened = 10*prot
	for(var/mob/M in AIviewers(src))
		if(M == user)	continue
		M.show_message("<span style=\"color:red\">[user.name] was shocked by the [src.name]!</span>", 3, "<span style=\"color:red\">You hear a heavy electrical crack</span>", 2)
	return 1

/obj/machinery/door/airlock/update_icon(var/toggling = 0)
	if(toggling ? !density : density)
		if (locked)
			icon_state = "[icon_base]_locked"
		else
			icon_state = "[icon_base]_closed"
		if (p_open)
			if (!src.panel_image)
				src.panel_image = image(src.icon, src.panel_icon_state)
			src.UpdateOverlays(src.panel_image, "panel")
		else
			src.UpdateOverlays(null, "panel")
		if (welded)
			if (!src.welded_image)
				src.welded_image = image(src.icon, src.welded_icon_state)
			src.UpdateOverlays(src.welded_image, "weld")
		else
			src.UpdateOverlays(null, "weld")
	else
		src.UpdateOverlays(null, "panel")
		src.UpdateOverlays(null, "weld")
		icon_state = "[icon_base]_open"
	return

/obj/machinery/door/airlock/play_animation(animation)
	switch (animation)
		if ("opening")
			src.update_icon()
			if (p_open)
				flick("o_[icon_base]_opening", src) // there's an issue with the panel overlay not being gone by the time the animation is nearly done but I can't make that stop, despite my best efforts
			else
				flick("[icon_base]_opening", src)
		if ("closing")
			src.update_icon()
			if (p_open)
				flick("o_[icon_base]_closing", src)
			else
				flick("[icon_base]_closing", src)
		if ("spark")
			flick("[icon_base]_spark", src)
		if ("deny")
			flick("[icon_base]_deny", src)
	return

/obj/machinery/door/airlock/attack_ai(mob/user as mob)
	if (user.stunned || user.weakened || user.stat)
		return
	if (!src.canAIControl())
		if (src.canAIHack())
			src.hack(user)
			return
//	if(ai_no_access && istype(user, /mob/living/silicon))
//		boutput(user, "You are unable to access this door.")
//		return

	//Separate interface for the AI.
	user.machine = src
	var/t1 = text("<B>Airlock Control</B><br><br>")
	t1 += "The access sensor reports the net identifier for this airlock is <i>[net_id]</i><br><br>"

	//Power
	//Main power
	if (src.secondsMainPowerLost > 0)
		if ((!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2)))
			t1 += text("Main power is offline for [] seconds.", src.secondsMainPowerLost)
		else
			t1 += text("Main power is offline indefinitely.")
	else
		t1 += text("Main power is online.")
	t1 += text("<br>")

	if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER1))
		t1 += text("Main Power Input wire is cut.<br>")
	if (src.isWireCut(AIRLOCK_WIRE_MAIN_POWER2))
		t1 += text("Main Power Output wire is cut.<br>")
	if (src.secondsMainPowerLost == 0)
		t1 += text("<A href='?src=\ref[];aiDisable=2'>Temporarily disrupt main power?</a><br>", src)

	//Backup power
	if (src.secondsBackupPowerLost > 0)
		if ((!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1)) && (!src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2)))
			t1 += text("Backup power is offline for [] seconds.", src.secondsBackupPowerLost)
		else
			t1 += text("Backup power is offline indefinitely.")
	else if (src.secondsMainPowerLost > 0)
		t1 += text("Backup power is online.")
	else
		t1 += text("Backup power is offline, but will turn on if main power fails.")
	t1 += text("<br>")

	if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER1))
		t1 += text("Backup Power Input wire is cut.<br>")
	if (src.isWireCut(AIRLOCK_WIRE_BACKUP_POWER2))
		t1 += text("Backup Power Output wire is cut.<br>")
	if (src.secondsBackupPowerLost == 0)
		t1 += text("<A href='?src=\ref[];aiDisable=3'>Temporarily disrupt backup power?</a><br>", src)
	t1 += text("<br>")

	//IDscan
	if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
		t1 += text("IdScan wire is cut.")
	else if (src.aiDisabledIdScanner)
		t1 += text("IdScan disabled. <A href='?src=\ref[];aiEnable=1'>Enable?</a>", src)
	else
		t1 += text("IdScan enabled. <A href='?src=\ref[];aiDisable=1'>Disable?</a>", src)
	t1 += "<br><br>"

	//Electrify
	if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
		t1 += text("Electrification wire is cut.<br>")
	if (src.secondsElectrified==-1)
		t1 += text("Door is electrified indefinitely. <br><A href='?src=\ref[];aiDisable=5'>Un-electrify it?</a><br>", src)
	else if (src.secondsElectrified>0)
		t1 += text("Door is electrified temporarily. ([] seconds)<br><A href='?src=\ref[];aiDisable=5'>Un-electrify it?</a><br>", src.secondsElectrified, src)
	else
		t1 += text("Door is not electrified.<br><A href='?src=\ref[];aiEnable=5'>Electrify it for 30 seconds?</a><br><A href='?src=\ref[];aiEnable=6'>Electrify it indefinitely until someone cancels the electrification?</a><br>", src, src)
	t1 += text("<br>")

	//Bolt
	if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
		t1 += text("Door bolt drop wire is cut.")
	else if (!src.locked)
		t1 += text("Door bolts are up. <A href='?src=\ref[];aiDisable=4'>Drop them?</a>", src)
	else
		t1 += text("Door bolts are down.")
		if (src.arePowerSystemsOn())
			t1 += text(" <A href='?src=\ref[];aiEnable=4'>Raise?</a>", src)
		else
			t1 += text(" Cannot raise door bolts due to power failure.")
	t1 += text("<br>")

	//Open or close
	if (src.welded)
		t1 += text("Door appears to have been welded shut.")
	else
		if (src.density)
			t1 += text("Door is closed. <A href='?src=\ref[];aiEnable=7'>Open door?</a>", src)
		else
			t1 += text("Door is open. <A href='?src=\ref[];aiDisable=7'>Close door?</a>", src)
	t1 += text("<br><br>")

	t1 += text("<p><a href='?src=\ref[];close=1'>Close Window</a></p>", src)
	user << browse(t1, "window=airlock")
	onclose(user, "airlock")

//aiDisable - 1 idscan, 2 disrupt main power, 3 disrupt backup power, 4 drop door bolts, 5 un-electrify door, 7 close door
//aiEnable - 1 idscan, 4 raise door bolts, 5 electrify door for 30 seconds, 6 electrify door indefinitely, 7 open door


/obj/machinery/door/airlock/proc/hack(mob/user as mob)
	if (src.aiHacking==0)
		src.aiHacking=1
		spawn(20)
			//TODO: Make this take a minute
			boutput(user, "Airlock AI control has been blocked. Beginning fault-detection.")
			sleep(50)
			if (src.canAIControl())
				boutput(user, "Alert cancelled. Airlock control has been restored without our assistance.")
				src.aiHacking=0
				return
			else if (!src.canAIHack())
				boutput(user, "We've lost our connection! Unable to hack airlock.")
				src.aiHacking=0
				return
			boutput(user, "Fault confirmed: airlock control wire disabled or cut.")
			sleep(20)
			boutput(user, "Attempting to hack into airlock. This may take some time.")
			sleep(200)
			if (src.canAIControl())
				boutput(user, "Alert cancelled. Airlock control has been restored without our assistance.")
				src.aiHacking=0
				return
			else if (!src.canAIHack())
				boutput(user, "We've lost our connection! Unable to hack airlock.")
				src.aiHacking=0
				return
			boutput(user, "Upload access confirmed. Loading control program into airlock software.")
			sleep(170)
			if (src.canAIControl())
				boutput(user, "Alert cancelled. Airlock control has been restored without our assistance.")
				src.aiHacking=0
				return
			else if (!src.canAIHack())
				boutput(user, "We've lost our connection! Unable to hack airlock.")
				src.aiHacking=0
				return
			boutput(user, "Transfer complete. Forcing airlock to execute program.")
			sleep(50)
			//disable blocked control
			src.aiControlDisabled = 2
			boutput(user, "Receiving control information from airlock.")
			sleep(10)
			//bring up airlock dialog
			src.aiHacking = 0
			src.attack_ai(user)

/obj/machinery/door/airlock/Bumped(atom/AM)
	if(ismob(AM))
		if(world.time - src.last_bump <= 30)
			return

		if (istype(AM, /mob/living/silicon) && (aiControlDisabled > 0 || cant_emag))
			return

		src.last_bump = world.time
		if (src.isElectrified())
			if(src.shock(AM, 100))
				return
	..()

/obj/machinery/door/airlock/attack_hand(mob/user as mob)
	if (!istype(usr, /mob/living/silicon))
		if (src.isElectrified())
			if(src.shock(user, 100))
				return
	else if (aiControlDisabled > 0 || cant_emag)
		return

	if (ishuman(user) && src.density && src.brainloss_stumble && src.do_brainstumble(user) == 1)
		return

	if (src.p_open)
		user.machine = src
		var/t1 = text("<B>Access Panel</B><br><br>")
		t1 += "An identifier is engraved under the airlock's card sensors: <i>[net_id]</i><br><br>"

		//t1 += text("[]: ", airlockFeatureNames[airlockWireColorToIndex[9]])
		var/list/wires = list(
			"Orange" = 1,
			"Dark red" = 2,
			"White" = 3,
			"Yellow" = 4,
			"Red" = 5,
			"Blue" = 6,
			"Green" = 7,
			"Grey" = 8,
			"Black" = 9
		)
		for(var/wiredesc in wires)
			var/is_uncut = src.wires & airlockWireColorToFlag[wires[wiredesc]]
			t1 += "[wiredesc] wire: "
			if(!is_uncut)
				t1 += "<a href='?src=\ref[src];wires=[wires[wiredesc]]'>Mend</a>"
			else
				t1 += "<a href='?src=\ref[src];wires=[wires[wiredesc]]'>Cut</a> "
				t1 += "<a href='?src=\ref[src];pulse=[wires[wiredesc]]'>Pulse</a> "
				if(src.signalers[wires[wiredesc]])
					t1 += "<a href='?src=\ref[src];remove-signaler=[wires[wiredesc]]'>Detach signaler</a>"
				else
					t1 += "<a href='?src=\ref[src];signaler=[wires[wiredesc]]'>Attach signaler</a>"
			t1 += "<br>"

		t1 += text("<br>[]<br>[]<br>[]", (src.locked ? "The door bolts have fallen!" : "The door bolts look up."), ((src.arePowerSystemsOn() && !(stat & NOPOWER)) ? "The test light is on." : "The test light is off!"), (src.aiControlDisabled==0 ? "The 'AI control allowed' light is on." : "The 'AI control allowed' light is off."))

		t1 += text("<p><a href='?src=\ref[];close=1'>Close</a></p>", src)

		user << browse(t1, "window=airlock")
		onclose(user, "airlock")

	else
		..(user)
	return


/obj/machinery/door/airlock/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() )
		return
	if (href_list["close"])
		usr << browse(null, "window=airlock")
		if (usr.machine==src)
			usr.machine = null
			return
	if (!istype(usr, /mob/living/silicon/ai))
		if (!istype(usr, /mob/living/silicon/robot)&&!istype(usr, /mob/living/silicon/hivebot))
			if(!src.p_open)
				return
		if ((in_range(src, usr) && istype(src.loc, /turf)))
			usr.machine = src
			if (href_list["wires"])
				var/t1 = text2num(href_list["wires"])
				if (!( istype(usr.equipped(), /obj/item/wirecutters) ))
					boutput(usr, "You need wirecutters!")
					return
				if (src.isWireColorCut(t1))
					src.mend(t1)
				else
					src.cut(t1)
			else if (href_list["pulse"])
				var/t1 = text2num(href_list["pulse"])
				if (!istype(usr.equipped(), /obj/item/device/multitool))
					boutput(usr, "You need a multitool!")
					return
				else if (src.isWireColorCut(t1))
					boutput(usr, "You can't pulse a cut wire.")
					return
				else
					src.pulse(t1)
			else if(href_list["signaler"])
				var/wirenum = text2num(href_list["signaler"])
				if(!istype(usr.equipped(), /obj/item/device/radio/signaler))
					boutput(usr, "You need a signaller!")
					return
				if(src.isWireColorCut(wirenum))
					boutput(usr, "You can't attach a signaller to a cut wire.")
					return
				var/obj/item/device/radio/signaler/R = usr.equipped()
				if(!R.b_stat)
					boutput(usr, "This radio can't be attached!")
					return
				var/mob/M = usr
				M.drop_item()
				R.set_loc(src)
				R.airlock_wire = wirenum
				src.signalers[wirenum] = R
			else if(href_list["remove-signaler"])
				var/wirenum = text2num(href_list["remove-signaler"])
				if(!(src.signalers[wirenum]))
					boutput(usr, "There's no signaller attached to that wire!")
					return
				var/obj/item/device/radio/signaler/R = src.signalers[wirenum]
				R.set_loc(usr.loc)
				R.airlock_wire = null
				src.signalers[wirenum] = null

		src.update_icon()
		add_fingerprint(usr)
		src.updateUsrDialog()
	if(istype(usr, /mob/living/silicon/))
		//AI
		if (usr.stunned || usr.weakened || usr.stat)
			return
		if (!src.canAIControl())
			boutput(usr, "Airlock control connection lost!")
			return
		//aiDisable - 1 idscan, 2 disrupt main power, 3 disrupt backup power, 4 drop door bolts, 5 un-electrify door, 7 close door
		//aiEnable - 1 idscan, 4 raise door bolts, 5 electrify door for 30 seconds, 6 electrify door indefinitely, 7 open door
		if (href_list["aiDisable"])
			var/code = text2num(href_list["aiDisable"])
			switch (code)
				if (1)
					//disable idscan
					if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
						boutput(usr, "The IdScan wire has been cut - So, you can't disable it, but it is already disabled anyways.")
					else if (src.aiDisabledIdScanner)
						boutput(usr, "You've already disabled the IdScan feature.")
					else
						src.aiDisabledIdScanner = 1
				if (2)
					//disrupt main power
					if (src.secondsMainPowerLost == 0)
						src.loseMainPower()
					else
						boutput(usr, "Main power is already offline.")
				if (3)
					//disrupt backup power
					if (src.secondsBackupPowerLost == 0)
						src.loseBackupPower()
					else
						boutput(usr, "Backup power is already offline.")
				if (4)
					//drop door bolts
					if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
						boutput(usr, "You can't drop the door bolts - The door bolt dropping wire has been cut.")
					else if (src.locked!=1)
						src.locked = 1
						update_icon()
				if (5)
					//un-electrify door
					if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
						boutput(usr, text("Can't un-electrify the airlock - The electrification wire is cut.<br><br>"))
					else if (src.secondsElectrified!=0)
						src.secondsElectrified = 0
						logTheThing("combat", usr, null, "de-electrified airlock ([src]) at [log_loc(src)].")
						message_admins("[key_name(usr)] de-electrified airlock ([src]) at [log_loc(src)].")

				if (7)
					//close door
					if (src.welded)
						boutput(usr, text("The airlock has been welded shut!<br><br>"))
					else if (src.locked)
						boutput(usr, text("The door bolts are down!<br><br>"))
					else if (!src.density)
						close()
					else
						boutput(usr, text("The airlock is already closed.<br><br>"))

		else if (href_list["aiEnable"])
			var/code = text2num(href_list["aiEnable"])
			switch (code)
				if (1)
					//enable idscan
					if (src.isWireCut(AIRLOCK_WIRE_IDSCAN))
						boutput(usr, "You can't enable IdScan - The IdScan wire has been cut.")
					else if (src.aiDisabledIdScanner)
						src.aiDisabledIdScanner = 0
					else
						boutput(usr, "The IdScan feature is not disabled.")
				if (4)
					//raise door bolts
					if (src.isWireCut(AIRLOCK_WIRE_DOOR_BOLTS))
						boutput(usr, text("The door bolt drop wire is cut - you can't raise the door bolts.<br><br>"))
					else if (!src.locked)
						boutput(usr, text("The door bolts are already up.<br><br>"))
					else
						if (src.arePowerSystemsOn())
							src.locked = 0
							update_icon()
						else
							boutput(usr, text("Cannot raise door bolts due to power failure.<br><br>"))

				if (5)
					//electrify door for 30 seconds
					if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
						boutput(usr, text("The electrification wire has been cut.<br><br>"))
					else if (src.secondsElectrified==-1)
						boutput(usr, text("The door is already indefinitely electrified. You'd have to un-electrify it before you can re-electrify it with a non-forever duration.<br><br>"))
					else if (src.secondsElectrified!=0)
						boutput(usr, text("The door is already electrified. You can't re-electrify it while it's already electrified.<br><br>"))
					else
						if(alert("Are you sure? Electricity might harm a human!",,"Yes","No") == "Yes")
							src.secondsElectrified = 30
							logTheThing("combat", usr, null, "electrified airlock ([src]) at [log_loc(src)] for 30 seconds.")
							message_admins("[key_name(usr)] electrified airlock ([src]) at [log_loc(src)] for 30 seconds.")
							spawn(10)
								while (src.secondsElectrified>0)
									src.secondsElectrified-=1
									if (src.secondsElectrified<0)
										src.secondsElectrified = 0
									src.updateUsrDialog()
									sleep(10)
				if (6)
					//electrify door indefinitely
					if (src.isWireCut(AIRLOCK_WIRE_ELECTRIFY))
						boutput(usr, text("The electrification wire has been cut.<br><br>"))
					else if (src.secondsElectrified==-1)
						boutput(usr, text("The door is already indefinitely electrified.<br><br>"))
					else if (src.secondsElectrified!=0)
						boutput(usr, text("The door is already electrified. You can't re-electrify it while it's already electrified.<br><br>"))
					else
						if(alert("Are you sure? Electricity might harm a human!",,"Yes","No") == "Yes")
							logTheThing("combat", usr, null, "electrified airlock ([src]) at [log_loc(src)] indefinitely.")
							message_admins("[key_name(usr)] electrified airlock ([src]) at [log_loc(src)] indefinitely.")
							src.secondsElectrified = -1
				if (7)
					//open door
					if (src.welded)
						boutput(usr, text("The airlock has been welded shut!<br><br>"))
					else if (src.locked)
						boutput(usr, text("The door bolts are down!<br><br>"))
					else if (src.density)
						open()
	//					close()
					else
						boutput(usr, text("The airlock is already opened.<br><br>"))

		src.update_icon()
		src.updateUsrDialog()

	return

/obj/machinery/door/airlock/attackby(C as obj, mob/user as mob)
	//boutput(world, text("airlock attackby src [] obj [] mob []", src, C, user))

	src.add_fingerprint(user)
	if (istype(C, /obj/item/device/t_scanner) || (istype(C, /obj/item/device/pda2) && istype(C:module, /obj/item/device/pda_module/tray)))
		if(src.isElectrified())
			boutput(usr, "<span style=\"color:red\">[bicon(C)] <b>WARNING</b>: Abnormal electrical response received from access panel.</span>")
		else
			if(stat & NOPOWER)
				boutput(usr, "<span style=\"color:red\">[bicon(C)] No electrical response received from access panel.</span>")
			else
				boutput(usr, "<span style=\"color:blue\">[bicon(C)] Regular electrical response received from access panel.</span>")
		return

	if (!istype(usr, /mob/living/silicon))
		if (src.isElectrified())
			if(src.shock(user, 75))
				return

	if ((istype(C, /obj/item/weldingtool) && !( src.operating ) && src.density))
		var/obj/item/weldingtool/W = C
		if(W.welding)
			if (W.get_fuel() > 2)
				W.use_fuel(2)
				W.eyecheck(user)
			else
				boutput(user, "Need more welding fuel!")
				return
			if (!src.welded)
				src.welded = 1
				logTheThing("station", user, null, "welded [name] shut at [log_loc(user)].")
				user.unlock_medal("Lock Block", 1)
			else
				logTheThing("station", user, null, "un-welded [name] at [log_loc(user)].")
				src.welded = null
			src.update_icon()
			return
	else if (istype(C, /obj/item/screwdriver))
		if (src.hardened == 1)
			boutput(usr, "<span style=\"color:red\">Your screwdriver can't pierce this airlock! Huh.</span>")
			return
		src.p_open = !( src.p_open )
		src.update_icon()
	else if (istype(C, /obj/item/wirecutters))
		return src.attack_hand(user)
	else if (istype(C, /obj/item/device/multitool))
		return src.attack_hand(user)
	else if (istype(C, /obj/item/device/radio/signaler))
		return src.attack_hand(user)
	else if (istype(C, /obj/item/crowbar))
		src.unpowered_open_close()
	else
		..()
	return

/obj/machinery/door/airlock/proc/unpowered_open_close()
	if (!src || !istype(src))
		return

	if ((src.density) && (!( src.welded ) && !( src.operating ) && ((!src.arePowerSystemsOn()) || (stat & NOPOWER)) && !( src.locked )))
		spawn( 0 )
			src.operating = 1
			play_animation("opening")			
			update_icon(1)

			sleep(src.operation_time)

			src.density = 0

			if (!istype(src, /obj/machinery/door/airlock/glass))
				src.RL_SetOpacity(0)
			src.operating = 0

	else
		if ((!src.density) && (!( src.welded ) && !( src.operating ) && !( src.locked )))
			spawn( 0 )
				src.operating = 1
				play_animation("closing")				
				update_icon(1)

				src.density = 1
				sleep(15)

				if (src.visible)
					src.RL_SetOpacity(1)
				src.operating = 0

	return

/obj/machinery/door/airlock/open()
	if (src.welded || src.locked || (!src.arePowerSystemsOn()) || (stat & NOPOWER) || src.isWireCut(AIRLOCK_WIRE_OPEN_DOOR))
		return 0
	use_power(50)
	if (narrator_mode)
		playsound(src.loc, 'sound/vox/door.ogg', 25, 1)
	else
		playsound(src.loc, src.sound_airlock, 25, 1)
	src.current_user = usr
	if (src.closeOther != null && istype(src.closeOther, /obj/machinery/door/airlock/) && !src.closeOther.density)
		src.closeOther.close(1)
	return ..()

/obj/machinery/door/airlock/close()
	if (src.welded || src.locked || (!src.arePowerSystemsOn()) || (stat & NOPOWER) || src.isWireCut(AIRLOCK_WIRE_OPEN_DOOR))
		return
	use_power(50)
	if (narrator_mode)
		playsound(src.loc, 'sound/vox/door.ogg', 25, 1)
	else
		if (src.sound_close_airlock)
			playsound(src.loc, src.sound_close_airlock, 25, 1)
		else
			playsound(src.loc, src.sound_airlock, 25, 1)
	..()
	return

/obj/machinery/door/airlock/New()
	..()
	src.net_id = generate_net_id(src)
	if (src.closeOtherId != null)
		spawn (5)
			for (var/obj/machinery/door/airlock/A)
				if (A.closeOtherId == src.closeOtherId && A != src)
					src.closeOther = A
					break

/obj/machinery/door/airlock/isblocked()
	if(src.density && ((stat & NOPOWER) || src.welded || src.locked || (src.operating == -1) ))
		return 1
	return 0

/obj/machinery/door/airlock/autoclose()
	if(!welded)
		close(0, 1)
	else
		..()
	return

// This code allows for airlocks to be controlled externally by setting an id_tag and comm frequency (disables ID access)
obj/machinery/door/airlock
	var/id_tag
	var/frequency = 1411
	var/last_update_time = 0
	var/last_radio_login = 0
	mats = 18

	var/datum/radio_frequency/radio_connection

	receive_signal(datum/signal/signal)
		if(!signal || signal.encryption)
			return

		if (lowertext(signal.data["address_1"]) != src.net_id)
			if (lowertext(signal.data["address_1"]) == "ping")
				var/datum/signal/pingsignal = get_free_signal()
				pingsignal.source = src
				pingsignal.data["device"] = "DOR_AIRLOCK"
				pingsignal.data["netid"] = src.net_id
				pingsignal.data["sender"] = src.net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.transmission_method = TRANSMISSION_RADIO

				radio_connection.post_signal(src, pingsignal, radiorange)
				return

			else if (!id_tag || id_tag != signal.data["tag"])
				return

		if (aiControlDisabled > 0 || cant_emag)
			var/datum/signal/rejectsignal = get_free_signal()
			rejectsignal.source = src
			rejectsignal.data["address_1"] = signal.data["sender"]
			rejectsignal.data["command"] = "nack"
			rejectsignal.data["data"] = "badpass"
			rejectsignal.data["sender"] = src.net_id

			radio_connection.post_signal(src, rejectsignal, radiorange)
			return

		if (!signal.data["command"])
			return

		var/senderid = signal.data["sender"]
		switch( lowertext(signal.data["command"]) )
			if("open")
				spawn
					open(1)
					send_status(,senderid)

			if("close")
				spawn
					close(1)
					send_status(,senderid)

			if("unlock")
				locked = 0
				update_icon()
				send_status(,senderid)

			if("lock")
				locked = 1
				update_icon()
				send_status()

			if("secure_open")
				spawn
					locked = 0
					update_icon()

					sleep(5)
					open(1)

					locked = 1
					update_icon()
					sleep(src.operation_time)
					send_status(,senderid)

			if("secure_close")
				spawn
					locked = 0
					close(1)

					locked = 1
					sleep(5)
					update_icon()
					sleep(src.operation_time)
					send_status(,senderid)

			else
				return

	proc/send_status(userid,target)
		if(radio_connection)
			var/datum/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio signal
			signal.source = src
			signal.data["tag"] = id_tag
			signal.data["sender"] = net_id
			signal.data["timestamp"] = air_master.current_cycle

			if (userid)
				signal.data["user_id"] = "[userid]"
			if (target)
				signal.data["address_1"] = target
			signal.data["door_status"] = density?("closed"):("open")
			signal.data["lock_status"] = locked?("locked"):("unlocked")

			radio_connection.post_signal(src, signal, radiorange)

	proc/send_packet(userid,target,message) //For unique conditions like a rejection message instead of overall status
		if(radio_connection && message)
			var/datum/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio signal
			signal.source = src
			signal.data["tag"] = id_tag
			signal.data["sender"] = net_id
			signal.data["timestamp"] = air_master.current_cycle

			if (userid)
				signal.data["user_id"] = "[userid]"
			if (target)
				signal.data["address_1"] = target

			signal.data["data"] = "[message]"

			radio_connection.post_signal(src, signal, radiorange)

	open(surpress_send)
		. = ..()
		if(!surpress_send && (src.last_update_time + 100 < ticker.round_elapsed_ticks))
			var/user_name = "???"
			if (issilicon(usr))
				user_name = "AI"
			else if (ishuman(usr))
				var/mob/living/carbon/human/C = usr
				var/obj/item/card/id/card = C.equipped()
				if (istype(card) && card.registered)
					user_name = card.registered

				else if (C.wear_id && C.wear_id:registered)
					user_name = C.wear_id:registered

			send_status(user_name)
			src.last_update_time = ticker.round_elapsed_ticks

	close(surpress_send, is_auto = 0)
		. = ..()
		if(!surpress_send && (src.last_update_time + 100 < ticker.round_elapsed_ticks))
			var/user_name = "???"
			if (issilicon(usr))
				user_name = "AI"
			else if (ishuman(usr))
				var/mob/living/carbon/human/C = usr
				var/obj/item/card/id/card = C.equipped()
				if (istype(card) && card.registered)
					user_name = card.registered

				else if (C.wear_id && C.wear_id:registered)
					user_name = C.wear_id:registered

			send_status(user_name)
			src.last_update_time = ticker.round_elapsed_ticks

	allowed(mob/living/carbon/human/user, req_only_one_required)
		. = ..()
		if (!. && user && (src.last_update_time + 100 < ticker.round_elapsed_ticks))
			var/user_name = "???"
			if (issilicon(user))
				user_name = "AI"
			else if (istype(user))
				var/obj/item/card/id/card = user.equipped()
				if (istype(card) && card.registered)
					user_name = card.registered

				else if (user.wear_id && user.wear_id:registered)
					user_name = user.wear_id:registered

			spawn (0)
				send_packet(user_name, ,"denied")
			src.last_update_time = ticker.round_elapsed_ticks

	proc/set_frequency(new_frequency)
		radio_controller.remove_object(src, "[frequency]")
		if(new_frequency)
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")

	initialize()
		if(frequency)
			set_frequency(frequency)

		update_icon()

	New()
		..()

		if(radio_controller)
			set_frequency(frequency)

/obj/machinery/door/airlock/emp_act()
	..()
	if (prob(20) && (src.density && src.cant_emag != 1 && src.isblocked() != 1))
		src.open()
		src.operating = -1
	if(prob(40))
		if(src.secondsElectrified == 0)
			src.secondsElectrified = -1
			spawn(300)
				src.secondsElectrified = 0
	return

/obj/machinery/door/airlock/proc/isthedoorwirecutfordummies()
	var/wireFlag = airlockIndexToFlag[AIRLOCK_WIRE_DOOR_BOLTS]
	return ((src.wires & wireFlag) == 0)