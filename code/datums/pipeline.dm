// SPDX-License-Identifier: CC-BY-NC-SA-3.0

datum/pipeline
	var/datum/gas_mixture/air
//
	var/list/obj/machinery/atmospherics/pipe/members
	var/list/obj/machinery/atmospherics/pipe/edges //Used for building networks

	var/datum/pipe_network/network

	var/alert_pressure = 0

	disposing()
		if (network)
			network.member_disposing(src)
		network = null

		if(air && air.volume)
			temporarily_store_air()
			pool(air)
		air = null

		if (members)
			for(var/obj/machinery/atmospherics/pipe/member in members)
				member.parent = null
			members.len = 0

		if (edges)
			for(var/obj/machinery/atmospherics/pipe/edge in edges)
				edge.parent = null
			edges.len = 0

		..()

	proc/process()
		if (!air) // null air? oh god!
			var/obj/machinery/atmospherics/member = null
			if (members && members.len > 0)
				member = members[0]
			else if (edges && edges.len > 0)
				member = edges[0]
			logTheThing("debug", null, null, "null air in pipeline([member ? "([showCoords(member.x, member.y, member.z)])" : "detached" ])")
			dispose() // kill this network, something is bad
			return

		//Check to see if pressure is within acceptable limits
		var/pressure = air.return_pressure()
		if(pressure > alert_pressure)
			for(var/obj/machinery/atmospherics/pipe/member in members)
				if(!member.check_pressure(pressure))
					break //Only delete 1 pipe per process

		//Allow for reactions
		//air.react() //Should be handled by pipe_network now

	proc/temporarily_store_air()
		//Update individual gas_mixtures by volume ratio

		for(var/obj/machinery/atmospherics/pipe/member in members)
			if (!member.air_temporary)
				member.air_temporary = new
			else
				member.air_temporary.trace_gases = null
			member.air_temporary.volume = member.volume

			member.air_temporary.oxygen = air.oxygen*member.volume/air.volume
			member.air_temporary.nitrogen = air.nitrogen*member.volume/air.volume
			member.air_temporary.toxins = air.toxins*member.volume/air.volume
			member.air_temporary.carbon_dioxide = air.carbon_dioxide*member.volume/air.volume

			member.air_temporary.temperature = air.temperature

			if(air.trace_gases && air.trace_gases.len)
				for(var/datum/gas/trace_gas in air.trace_gases)
					var/datum/gas/corresponding = new trace_gas.type()
					if(!member.air_temporary.trace_gases)
						member.air_temporary.trace_gases = list()
					member.air_temporary.trace_gases += corresponding

					corresponding.moles = trace_gas.moles*member.volume/air.volume

	proc/build_pipeline(obj/machinery/atmospherics/pipe/base)
		var/list/possible_expansions = list(base)
		if (!members)
			members = list(base)
		else
			members.len = 0
			members += base

		if (!edges)
			edges = list()
		else
			edges.len = 0

		var/volume = base.volume
		base.parent = src

		if(base.air_temporary)
			if(air)
				pool(air)
			air = base.air_temporary
			base.air_temporary = null
		else
			air = unpool(/datum/gas_mixture)

		while(possible_expansions.len>0)
			for(var/obj/machinery/atmospherics/pipe/borderline in possible_expansions)

				var/list/result = borderline.pipeline_expansion()
				var/edge_check = result.len

				if(result.len>0)
					for(var/obj/machinery/atmospherics/pipe/item in result)
						if(!members.Find(item))
							members += item
							possible_expansions += item

							volume += item.volume
							item.parent = src

							if(item.air_temporary)
								air.merge(item.air_temporary)
								item.air_temporary = null

						edge_check--

				if(edge_check>0)
					edges += borderline

				possible_expansions -= borderline

		air.volume = volume

	proc/network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)

		if(new_network.line_members.Find(src))
			return 0

		new_network.line_members += src

		network = new_network

		for(var/obj/machinery/atmospherics/pipe/edge in edges)
			for(var/obj/machinery/atmospherics/result in edge.pipeline_expansion())
				if(!istype(result,/obj/machinery/atmospherics/pipe) && (result!=reference))
					result.network_expand(new_network, edge)

		return 1

	proc/return_network(obj/machinery/atmospherics/reference)
		if(!network)
			network = new /datum/pipe_network()
			network.build_network(src, null)
				//technically passing these parameters should not be allowed
				//however pipe_network.build_network(..) and pipeline.network_extend(...)
				//		were setup to properly handle this case

		return network

	proc/mingle_with_turf(turf/simulated/target, mingle_volume)
		if (!target) return
		var/datum/gas_mixture/air_sample = air.remove_ratio(mingle_volume/air.volume)
		air_sample.volume = mingle_volume

		if(istype(target) && target.parent && target.parent.group_processing)
			//Have to consider preservation of group statuses
			var/datum/gas_mixture/turf_copy = unpool(/datum/gas_mixture)

			turf_copy.copy_from(target.parent.air)
			turf_copy.volume = target.parent.air.volume //Copy a good representation of the turf from parent group

			equalize_gases(list(air_sample, turf_copy))
			air.merge(air_sample)

			if(target.parent.air.compare(turf_copy))
				//The new turf would be an acceptable group member so permit the integration

				turf_copy.subtract(target.parent.air)

				target.parent.air.merge(turf_copy)

			else
				//Comparison failure so dissemble group and copy turf

				target.parent.suspend_group_processing()
				target.air.copy_from(turf_copy)
				pool(turf_copy) // done with this

		else
			var/datum/gas_mixture/turf_air = target.return_air()

			equalize_gases(list(air_sample, turf_air))
			air.merge(air_sample)

			//turf_air already modified by equalize_gases()

		if(istype(target) && !target.processing)
			if(target.air)
				if(target.air.check_tile_graphic())
					target.update_visuals(target.air)

		if(!isnull(network))
			network.update = 1

	proc/temperature_interact(turf/target, share_volume, thermal_conductivity)
		var/total_heat_capacity = air.heat_capacity()
		var/partial_heat_capacity = total_heat_capacity*(share_volume/air.volume)

		if(istype(target, /turf/simulated))
			var/turf/simulated/modeled_location = target

			if(modeled_location.blocks_air || !modeled_location.air)

				if((modeled_location.heat_capacity>0) && (partial_heat_capacity>0))
					var/delta_temperature = air.temperature - modeled_location.temperature

					var/heat = thermal_conductivity*delta_temperature* \
						(partial_heat_capacity*modeled_location.heat_capacity/(partial_heat_capacity+modeled_location.heat_capacity))

					air.temperature -= heat/total_heat_capacity
					modeled_location.temperature += heat/modeled_location.heat_capacity

			else
				var/delta_temperature = 0
				var/sharer_heat_capacity = 0

				if(modeled_location.parent && modeled_location.parent.group_processing)
					delta_temperature = (air.temperature - modeled_location.parent.air.temperature)
					sharer_heat_capacity = modeled_location.parent.air.heat_capacity()
				else
					delta_temperature = (air.temperature - modeled_location.air.temperature)
					sharer_heat_capacity = modeled_location.air.heat_capacity()

				var/self_temperature_delta = 0
				var/sharer_temperature_delta = 0

				if((sharer_heat_capacity>0) && (partial_heat_capacity>0))
					var/heat = thermal_conductivity*delta_temperature* \
						(partial_heat_capacity*sharer_heat_capacity/(partial_heat_capacity+sharer_heat_capacity))

					self_temperature_delta = -heat/total_heat_capacity
					sharer_temperature_delta = heat/sharer_heat_capacity
				else
					return 1

				air.temperature += self_temperature_delta

				if(modeled_location.parent && modeled_location.parent.group_processing)
					if((abs(sharer_temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND) && (abs(sharer_temperature_delta) > MINIMUM_TEMPERATURE_RATIO_TO_SUSPEND*modeled_location.parent.air.temperature))
						modeled_location.parent.suspend_group_processing()

						modeled_location.air.temperature += sharer_temperature_delta

					else
						modeled_location.parent.air.temperature += sharer_temperature_delta/modeled_location.parent.air.group_multiplier
				else
					modeled_location.air.temperature += sharer_temperature_delta


		else
			if((target.heat_capacity>0) && (partial_heat_capacity>0))
				var/delta_temperature = air.temperature - target.temperature

				var/heat = thermal_conductivity*delta_temperature* \
					(partial_heat_capacity*target.heat_capacity/(partial_heat_capacity+target.heat_capacity))

				air.temperature -= heat/total_heat_capacity

		if(!isnull(network))
			network.update = 1