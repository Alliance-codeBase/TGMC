#define MODPACKS_SET 'modular_metacorps/__modpack/mods_icon_placeholder.dmi'

/datum/asset/spritesheet/modpacks
	name = "modpacks"

/datum/asset/spritesheet/modpacks/create_spritesheets()
	// catch all modpack's previews which are pulling icons from preview.dmi files
	// not from .png due of special work Insert() with icon()
	for(var/datum/modpack/this_modpack as anything in subtypesof(/datum/modpack))
		if(!this_modpack.visible)
			continue

		var/icon = initial(this_modpack.icon)
		var/modpack_id = initial(this_modpack.id)

		if(icon == MODPACKS_SET)
			Insert("modpack-[modpack_id]", icon(icon, "no-preview"))
		else
			Insert("modpack-[modpack_id]", icon(icon, "preview"))

#undef MODPACKS_SET
