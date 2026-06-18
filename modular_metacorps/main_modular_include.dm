// All new mod's includes here
// Some modules can be easy excludes from code compile sequence by commenting #define you need to remove in code\__DEFINES\__meta_modpaks_includes.dm
// Keep in mind, that module may not be only in modular folder but also embedded directly in TG code and covered with #ifdef - #endif structure
// Every module should be in alphabetical order

#include "__modpack\assets_modpacks.dm" //Assets for modpacks subsystem, used for TGUI and other things
#include "__modpack\modpack.dm" //Modpack base class, used for all modpacks
#include "__modpack\modpacks_subsystem.dm" //Actually modpacks subsystem + TGUI in "tgui/packages/tgui/interfaces/Modpacks.tsx"


/* --- Features --- */



/* --- Reverts --- */



/* --- Tweaks --- */

#include "tweaks\russian_translation\includes.dme"