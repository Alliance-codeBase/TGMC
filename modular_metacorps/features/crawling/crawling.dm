/client/Move(n, direct)
	if(mob && mob.stat == 0 && ishuman(mob))
		var/is_resting = FALSE
		if("resting" in mob.vars)
			if(mob.vars["resting"])
				is_resting = TRUE
		else if("status_traits" in mob.vars)
			var/list/traits = mob.vars["status_traits"]
			if(traits && traits["resting"])
				is_resting = TRUE

		if(is_resting)
			if(!direct || !isnum(direct))
				return FALSE

			if(world.time < src.move_delay)
				return FALSE

			var/old_resting = 0
			if("resting" in mob.vars)
				old_resting = mob.vars["resting"]
				mob.vars["resting"] = 0

			var/old_lying = 0
			if("lying" in mob.vars)
				old_lying = mob.vars["lying"]
				mob.vars["lying"] = 0

			var/old_lying_current = 0
			if("lying_current" in mob.vars)
				old_lying_current = mob.vars["lying_current"]
				mob.vars["lying_current"] = 0

			var/old_body = 1
			if("body_position" in mob.vars)
				old_body = mob.vars["body_position"]
				mob.vars["body_position"] = 1

			var/saved_canmove = mob.canmove
			mob.canmove = TRUE

			var/turf/old_turf = mob.loc

			. = ..(n, direct)

			if("resting" in mob.vars)
				mob.vars["resting"] = old_resting
			if("lying" in mob.vars)
				mob.vars["lying"] = old_lying
			if("lying_current" in mob.vars)
				mob.vars["lying_current"] = old_lying_current
			if("body_position" in mob.vars)
				mob.vars["body_position"] = old_body
			mob.canmove = saved_canmove

			if(. && old_turf && old_turf != mob.loc && istype(old_turf))
				var/is_bleeding = FALSE
				if("brute_loss" in mob.vars)
					if(mob.vars["brute_loss"] > 20)
						is_bleeding = TRUE
				else if("health" in mob.vars)
					var/max_h = 100
					if("max_health" in mob.vars)
						max_h = mob.vars["max_health"]
					if(mob.vars["health"] < (max_h - 20))
						is_bleeding = TRUE

				if(is_bleeding)
					if(hascall(mob, "suppress_blood_splatter"))
						var/proc_call = "suppress_blood_splatter"
						call(mob, proc_call)(old_turf, 1, 1, src)
					else if(hascall(mob, "blood_splatter"))
						var/proc_call = "blood_splatter"
						call(mob, proc_call)(old_turf, src, TRUE)
					else
						var/path = text2path("/obj/effect/decal/cleanable/blood/splatter")
						if(path)
							var/obj/effect/decal/cleanable/blood/splatter/B = new path(old_turf)
							if(B && ("blood_DNA" in mob.vars) && ("blood_DNA" in B.vars))
								B.vars["blood_DNA"] = mob.vars["blood_DNA"]

			src.move_delay = world.time + 10

			if("key_loop" in src.vars)
				var/datum/K = src.vars["key_loop"]
				if(K)
					if("delay" in K.vars)
						K.vars["delay"] = world.time + 10
					if("keys_held" in K.vars)
						var/list/kh = K.vars["keys_held"]
						if(kh)
							kh.Cut()
					if("current_dir" in K.vars)
						K.vars["current_dir"] = 0
					if(hascall(K, "stop"))
						var/proc_call = "stop"
						call(K, proc_call)()
			return TRUE

	return ..()
