// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/global/list/datum/pipe_network/pipe_networks = list()
//
datum/pipe_network
	var/list/datum/gas_mixture/gases = list() //All of the gas_mixtures continuously connected in this network

	var/list/obj/machinery/atmospherics/normal_members = list()
	var/list/datum/pipeline/line_members = list()
		//membership roster to go through for updates and what not

	var/update = 1
	var/datum/gas_mixture/air_transient = null

	New()
		air_transient = unpool(/datum/gas_mixture)

		..()

	disposing()
		update = 0
		pipe_networks -= src
		if (gases)
			gases.len = 0
		gases = null
		if (normal_members)
			for(var/obj/machinery/atmospherics/machine in normal_members)
				machine.network_disposing(src)				
			normal_members.len = 0
		normal_members = 0
		if (line_members)
			for(var/datum/pipeline/member in line_members)
				member.network = null
			line_members.len = 0
		line_members = null
		if (air_transient)
			pool(air_transient)
		air_transient = null
		..()
		
	proc/member_disposing(datum/pipeline/line_member)
		if (gases)
			gases -= line_member.air
		if (line_members)
			line_members -= line_member
			
	proc/air_disposing_hook()
		for(var/datum/gas_mixture/a in args)
			gases -= a

	proc/process()
		//Equalize gases amongst pipe if called for
		if(update)
			update = 0
			reconcile_air() //equalize_gases(gases)

		//Give pipelines their process call for pressure checking and what not
		for(var/datum/pipeline/line_member in line_members)
			line_member.process()

	proc/build_network(obj/machinery/atmospherics/start_normal, obj/machinery/atmospherics/reference)
		//Purpose: Generate membership roster
		//Notes: Assuming that members will add themselves to appropriate roster in network_expand()

		if(!start_normal)
			dispose()

		start_normal.network_expand(src, reference)

		update_network_gases()

		if((normal_members.len>0)||(line_members.len>0))
			pipe_networks += src
		else
			dispose()

	proc/merge(datum/pipe_network/giver)
		if(giver==src) return 0

		normal_members -= giver.normal_members
		normal_members += giver.normal_members

		line_members -= giver.line_members
		line_members += giver.line_members

		for(var/obj/machinery/atmospherics/normal_member in giver.normal_members)
			normal_member.reassign_network(giver, src)

		for(var/datum/pipeline/line_member in giver.line_members)
			line_member.network = src

		giver.dispose()

		update_network_gases()
		return 1

	proc/update_network_gases()
		//Go through membership roster and make sure gases is up to date

		gases.len = 0

		for(var/obj/machinery/atmospherics/normal_member in normal_members)
			var/result = normal_member.return_network_air(src)
			if(result) gases += result

		for(var/datum/pipeline/line_member in line_members)
			gases += line_member.air

	proc/reconcile_air()
		//Perfectly equalize all gases members instantly

		//Calculate totals from individual components
		var/total_thermal_energy = 0
		var/total_heat_capacity = 0
		if (!air_transient)
			air_transient = new()
		air_transient.volume = 0
		air_transient.oxygen = 0
		air_transient.nitrogen = 0
		air_transient.toxins = 0
		air_transient.carbon_dioxide = 0

		air_transient.trace_gases = null

		for(var/datum/gas_mixture/gas in gases)
			air_transient.volume += gas.volume
			total_thermal_energy += gas.thermal_energy()
			total_heat_capacity += gas.heat_capacity()

			air_transient.oxygen += gas.oxygen
			air_transient.nitrogen += gas.nitrogen
			air_transient.toxins += gas.toxins
			air_transient.carbon_dioxide += gas.carbon_dioxide

			if(gas.trace_gases && gas.trace_gases.len)
				for(var/datum/gas/trace_gas in gas.trace_gases)
					var/datum/gas/corresponding
					if(air_transient.trace_gases && air_transient.trace_gases.len)
						corresponding = locate(trace_gas.type) in air_transient.trace_gases
					if(!corresponding)
						corresponding = new trace_gas.type()
						if(!air_transient.trace_gases)
							air_transient.trace_gases = list()
						air_transient.trace_gases += corresponding

					corresponding.moles += trace_gas.moles

		if(air_transient.volume > 0)

			if(total_heat_capacity > 0)
				air_transient.temperature = total_thermal_energy/total_heat_capacity

				//Allow air mixture to react
				if(air_transient.react())
					update = 1

			else
				air_transient.temperature = 0

			//Update individual gas_mixtures by volume ratio
			for(var/datum/gas_mixture/gas in gases)
				gas.oxygen = air_transient.oxygen*gas.volume/air_transient.volume
				gas.nitrogen = air_transient.nitrogen*gas.volume/air_transient.volume
				gas.toxins = air_transient.toxins*gas.volume/air_transient.volume
				gas.carbon_dioxide = air_transient.carbon_dioxide*gas.volume/air_transient.volume

				gas.temperature = air_transient.temperature

				if(air_transient.trace_gases && air_transient.trace_gases.len)
					for(var/datum/gas/trace_gas in air_transient.trace_gases)
						var/datum/gas/corresponding
						if(gas.trace_gases && gas.trace_gases.len)
							corresponding = locate(trace_gas.type) in gas.trace_gases
						if(!corresponding)
							corresponding = new trace_gas.type()
							if(!gas.trace_gases)
								gas.trace_gases = list()
							gas.trace_gases += corresponding

						corresponding.moles = trace_gas.moles*gas.volume/air_transient.volume
		return 1

proc/equalize_gases(datum/gas_mixture/list/gases)
	//Perfectly equalize all gases members instantly

	//Calculate totals from individual components
	var/total_volume = 0
	var/total_thermal_energy = 0
	var/total_heat_capacity = 0

	var/total_oxygen = 0
	var/total_nitrogen = 0
	var/total_toxins = 0
	var/total_carbon_dioxide = 0

	var/list/total_trace_gases

	for(var/datum/gas_mixture/gas in gases)
		total_volume += gas.volume
		total_thermal_energy += gas.thermal_energy()
		total_heat_capacity += gas.heat_capacity()

		total_oxygen += gas.oxygen
		total_nitrogen += gas.nitrogen
		total_toxins += gas.toxins
		total_carbon_dioxide += gas.carbon_dioxide

		if(gas.trace_gases && gas.trace_gases.len)
			for(var/datum/gas/trace_gas in gas.trace_gases)
				var/datum/gas/corresponding
				if(total_trace_gases && total_trace_gases.len)
					corresponding = locate(trace_gas.type) in total_trace_gases
				if(!corresponding)
					corresponding = new trace_gas.type()
					if(!total_trace_gases)
						total_trace_gases = list()
					total_trace_gases += corresponding

				corresponding.moles += trace_gas.moles

	if(total_volume > 0)

		//Calculate temperature
		var/temperature = 0

		if(total_heat_capacity > 0)
			temperature = total_thermal_energy/total_heat_capacity

		//Update individual gas_mixtures by volume ratio
		for(var/datum/gas_mixture/gas in gases)
			gas.oxygen = total_oxygen*gas.volume/total_volume
			gas.nitrogen = total_nitrogen*gas.volume/total_volume
			gas.toxins = total_toxins*gas.volume/total_volume
			gas.carbon_dioxide = total_carbon_dioxide*gas.volume/total_volume

			gas.temperature = temperature

			if(total_trace_gases && total_trace_gases.len)
				for(var/datum/gas/trace_gas in total_trace_gases)
					var/datum/gas/corresponding
					if(gas.trace_gases && gas.trace_gases.len)
						corresponding = locate(trace_gas.type) in gas.trace_gases
					if(!corresponding)
						corresponding = new trace_gas.type()
						if(!gas.trace_gases)
							gas.trace_gases = list()
						gas.trace_gases += corresponding

					corresponding.moles = trace_gas.moles*gas.volume/total_volume

	return 1