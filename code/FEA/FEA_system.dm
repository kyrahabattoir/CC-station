// SPDX-License-Identifier: CC-BY-NC-SA-3.0

var/atmos_suspend = 0
/*
Overview:
	The air_master global variable is the workhorse for the system.

Why are you archiving data before modifying it?
	The general concept with archiving data and having each tile keep track of when they were last updated is to keep everything symmetric
		and totally independent of the order they are read in an update cycle.
	This prevents abnormalities like air/fire spreading rapidly in one direction and super slowly in the other.

Why not just archive everything and then calculate?
	Efficiency. While a for-loop that goes through all tils and groups to archive their information before doing any calculations seems simple, it is
		slightly less efficient than the archive-before-modify/read method.

Why is there a cycle check for calculating data as well?
	This ensures that every connection between group-tile, tile-tile, and group-group is only evaluated once per loop.

//


Important variables:
	air_master.groups_to_rebuild (list)
		A list of air groups that have had their geometry occluded and thus may need to be split in half.
		A set of adjacent groups put in here will join together if validly connected.
		This is done before air system calculations for a cycle.
	air_master.tiles_to_update (list)
		Turfs that are in this list have their border data updated before the next air calculations for a cycle.
		Place turfs in this list rather than call the proc directly to prevent race conditions

	turf/simulated.archive() and datum/air_group.archive()
		This stores all data for.
		If you modify, make sure to update the archived_cycle to prevent race conditions and maintain symmetry

	atom/CanPass(atom/movable/mover, turf/target, height, air_group)
		returns 1 for allow pass and 0 for deny pass
		Turfs automatically call this for all objects/mobs in its turf.
		This is called both as source.CanPass(target, height, air_group)
			and  target.CanPass(source, height, air_group)

		Cases for the parameters
		1. This is called with args (mover, location, height>0, air_group=0) for normal objects.
		2. This is called with args (null, location, height=0, air_group=0) for flowing air.
		3. This is called with args (null, location, height=?, air_group=1) for determining group boundaries.

		Cases 2 and 3 would be different for doors or other objects open and close fairly often.
			(Case 3 would return 0 always while Case 2 would return 0 only when the door is open)
			This prevents the necessity of re-evaluating group geometry every time a door opens/closes.


Important Procedures
	air_master.process()
		This first processes the air_master update/rebuild lists then processes all groups and tiles for air calculations


*/

atom/proc/CanPass(atom/movable/mover, turf/target, height=1.5, air_group = 0)
	return (!density || !height || air_group)

turf
	CanPass(atom/movable/mover, turf/target, height=1.5,air_group=0)
		if(!target) return 0

		if(istype(mover)) // turf/Enter(...) will perform more advanced checks
			return !density

		else // Now, doing more detailed checks for air movement and air group formation
			if(target.blocks_air||blocks_air)
				return 0

			for(var/obj/obstacle in src)
				if(!obstacle.CanPass(mover, target, height, air_group))
					return 0
			for(var/obj/obstacle in target)
				if(!obstacle.CanPass(mover, src, height, air_group))
					return 0

			return 1


var/global/datum/controller/air_system/air_master
var/global/total_gas_mixtures = 0

datum
	controller
		air_system
			//Geoemetry lists
			var/list/datum/air_group/air_groups = list()
			var/list/turf/simulated/active_singletons = list()

			//Special functions lists
			var/list/turf/simulated/active_super_conductivity = list()
			var/list/turf/simulated/high_pressure_delta = list()

			//Geometry updates lists
			var/list/turf/simulated/tiles_to_update = list()
			var/list/turf/simulated/groups_to_rebuild = list()

			var/current_cycle = 0
			var/datum/controller/process/air_system/parent_controller = null


			proc
				setup(datum/controller/process/air_system/controller)
					//Call this at the start to setup air groups geometry
					//Warning: Very processor intensive but only must be done once per round

				assemble_group_turf(turf/simulated/base)
					//Call this to try to construct a group starting from base and merging with neighboring unparented tiles
					//Expands the group until all valid borders explored

//				assemble_group_object(obj/movable/floor/base)

				process()
					//Call this to process air movements for a cycle

				process_groups()
					//Used by process()
					//Warning: Do not call this

				process_singletons()
					//Used by process()
					//Warning: Do not call this

				process_high_pressure_delta()
					//Used by process()
					//Warning: Do not call this

				process_super_conductivity()
					//Used by process()
					//Warning: Do not call this

				process_update_tiles()
					//Used by process()
					//Warning: Do not call this

				process_rebuild_select_groups()
					//Used by process()
					//Warning: Do not call this

				rebuild_group(datum/air_group)
					//Used by process_rebuild_select_groups()
					//Warning: Do not call this, add the group to air_master.groups_to_rebuild instead

				add_singleton(turf/simulated/T)
					if(!active_singletons.Find(T))
						active_singletons += T
						
				set_controller(datum/controller/process/air_system/controller)
					parent_controller = controller
					
				queue_update_tile(turf/simulated/T)
					if (!(T in tiles_to_update))
						tiles_to_update += T
						
				queue_update_group(datum/air_group)
					if (!(air_group in groups_to_rebuild))
						groups_to_rebuild += air_group

			setup(datum/controller/process/air_system/controller)
				set_controller(controller)

				boutput(world, "<span style=\"color:red\">Processing Geometry...</span>")

				var/start_time = world.timeofday

				for(var/turf/simulated/S in world)
					if(!S.blocks_air && !S.parent)
						assemble_group_turf(S)						
				//for(var/turf/simulated/S in world) //Update all pathing and border information as well
					S.update_air_properties()
					LAGCHECK(50)
/*
				for(var/obj/movable/floor/S in world)
					if(!S.parent)
						assemble_group_object(S)
				for(var/obj/movable/floor/S in world) //Update all pathing and border information as well
					S.update_air_properties()
*/
				boutput(world, "<span style=\"color:red\">Geometry processed in [(world.timeofday-start_time)/10] seconds!</span>")

			assemble_group_turf(turf/simulated/base)
				var/list/turf/simulated/members = list(base) //Confirmed group members
				var/list/turf/simulated/possible_members = list(base) //Possible places for group expansion
				var/list/turf/simulated/possible_borders
				var/list/turf/simulated/possible_space_borders
				var/possible_space_length = 0

				while(possible_members.len>0) //Keep expanding, looking for new members
					for(var/turf/simulated/test in possible_members)
						test.length_space_border = 0
						for(var/direction in cardinal)
							var/turf/T = get_step(test,direction)
							if(T && !members.Find(T) && test.CanPass(null, T, null,1))
								if(istype(T,/turf/simulated) && !T:parent)
									possible_members += T
									members += T
								else if(istype(T,/turf/space))
									if(!possible_space_borders)
										possible_space_borders = list()
									if(!possible_space_borders.Find(test))
										possible_space_borders += test
									test.length_space_border++
								else
									if(!possible_borders)
										possible_borders = list()
									if(!possible_borders.Find(test))
										possible_borders += test
						if(test.length_space_border > 0)
							possible_space_length += test.length_space_border
						possible_members -= test
						LAGCHECK(50)

				if(members.len > 1)
					var/datum/air_group/group = new
					if(possible_borders && possible_borders.len>0)
						group.borders = possible_borders
					if(possible_space_borders && possible_space_borders.len>0)
						group.space_borders = possible_space_borders
						group.length_space_border = possible_space_length

					for(var/turf/simulated/test in members)
						test.parent = group
						test.processing = 0
						active_singletons -= test
						LAGCHECK(50)

					group.members = members
					air_groups += group

					group.update_group_from_tiles() //Initialize air group variables
					return group
				else
					base.processing = 0 //singletons at startup are technically unconnected anyway
					base.parent = null

					if(base.air && base.air.check_tile_graphic())
						base.update_visuals(base.air)

				return null
/*
			assemble_group_object(obj/movable/floor/base)

				var/list/obj/movable/floor/members = list(base) //Confirmed group members
				var/list/obj/movable/floor/possible_members = list(base) //Possible places for group expansion
				var/list/obj/movable/floor/possible_borders = list()

				while(possible_members.len>0) //Keep expanding, looking for new members
					for(var/obj/movable/floor/test in possible_members)
						for(var/direction in list(NORTH, SOUTH, EAST, WEST))
							var/turf/T = get_step(test.loc,direction)
							if(T && test.loc.CanPass(null, T, null, 1))
								var/obj/movable/floor/O = locate(/obj/movable/floor) in T
								if(istype(O) && !O.parent)
									if(!members.Find(O))
										possible_members += O
										members += O
								else
									possible_borders -= test
									possible_borders += test
						possible_members -= test

				if(members.len > 1)
					var/datum/air_group/object/group = new
					if(possible_borders.len>0)
						group.borders = possible_borders

					for(var/obj/movable/floor/test in members)
						test.parent = group
						test.processing = 0
						active_singletons -= test

					group.members = members
					air_groups += group

					group.update_group_from_tiles() //Initialize air group variables
					return group
				else
					base.processing = 0 //singletons at startup are technically unconnected anyway
					base.parent = null

				return null
*/
			process()
				current_cycle++
				if(groups_to_rebuild.len > 0)
					process_rebuild_select_groups()

				if(tiles_to_update.len > 0)
					process_update_tiles()

				process_groups()

				process_singletons()

				process_super_conductivity()

				process_high_pressure_delta()

				if(current_cycle%10==5) //Check for groups of tiles to resume group processing every 10 cycles

					for(var/datum/air_group/AG in air_groups)
						AG.check_regroup()
						LAGCHECK(90)

				return 1

			process_update_tiles()
				for(var/turf/simulated/T in tiles_to_update)
					T.update_air_properties()
					LAGCHECK(90)

/*
				for(var/obj/movable/floor/O in tiles_to_update)
					O.update_air_properties()
*/
				tiles_to_update.len = 0

			process_rebuild_select_groups()
				var/turf/list/turfs = list()

				for(var/datum/air_group/turf_AG in groups_to_rebuild) //Deconstruct groups, gathering their old members
					for(var/turf/simulated/T in turf_AG.members)
						T.parent = null
						turfs += T
					air_master.air_groups -= turf_AG
					turf_AG.members.len = 0
					LAGCHECK(90)

				for(var/turf/simulated/S in turfs) //Have old members try to form new groups
					if(!S.parent)
						assemble_group_turf(S)
						LAGCHECK(90)

				//for(var/turf/simulated/S in turfs)
					S.update_air_properties()

//				var/obj/movable/list/movable_objects = list()
/*
				for(var/datum/air_group/object/object_AG in groups_to_rebuild) //Deconstruct groups, gathering their old members

					for(var/obj/movable/floor/OM in object_AG.members)
						OM.parent = null
						movable_objects += OM
					qdel(object_AG)

				for(var/obj/movable/floor/OM in movable_objects) //Have old members try to form new groups
					if(!OM.parent)
						assemble_group_object(OM)
				for(var/obj/movable/floor/OM in movable_objects)
					OM.update_air_properties()
*/
				groups_to_rebuild.len = 0

			process_groups()
				for(var/datum/air_group/AG in air_groups)
					AG.process_group(parent_controller)
					LAGCHECK(90)

			process_singletons()
				for(var/item in active_singletons)
					item:process_cell()
					LAGCHECK(90)

			process_super_conductivity()
				for(var/turf/simulated/hot_potato in active_super_conductivity)
					hot_potato.super_conduct()
					LAGCHECK(90)

			process_high_pressure_delta()
				for(var/turf/pressurized in high_pressure_delta)
					pressurized.high_pressure_movements()
					LAGCHECK(90)

				high_pressure_delta.len = 0
