// SPDX-License-Identifier: CC-BY-NC-SA-3.0

//node1, air1, network1 correspond to input
//node2, air2, network2 correspond to output
//
/obj/machinery/atmospherics/binary/circulator
	name = "circulator/heat exchanger"
	desc = "A gas circulator pump and heat exchanger."
	icon = 'icons/obj/atmospherics/pipes.dmi'
	icon_state = "circ1-off"

	var/side = 1 // 1=left 2=right
	var/status = 0

	var/last_pressure_delta = 0

	anchored = 1.0
	density = 1

	proc/return_transfer_air()
		var/output_starting_pressure = air2.return_pressure()
		var/input_starting_pressure = air1.return_pressure()

		//Calculate necessary moles to transfer using PV = nRT
		if((air1.total_moles() > 0) && (air1.temperature>0))
			var/pressure_delta = (input_starting_pressure - output_starting_pressure)/2

			var/transfer_moles = pressure_delta*air2.volume/(air1.temperature * R_IDEAL_GAS_EQUATION)

			last_pressure_delta = pressure_delta

			//Actually transfer the gas
			var/datum/gas_mixture/removed = air1.remove(transfer_moles)

			if(network1)
				network1.update = 1

			if(network2)
				network2.update = 1

			return removed

		else
			last_pressure_delta = 0

	process()
		..()
		update_icon()

	update_icon()
		if(stat & (BROKEN|NOPOWER))
			icon_state = "circ[side]-p"
		else if(last_pressure_delta > 0)
			if(last_pressure_delta > ONE_ATMOSPHERE)
				icon_state = "circ[side]-run"
			else
				icon_state = "circ[side]-slow"
		else
			icon_state = "circ[side]-off"

		return 1