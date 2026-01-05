#pragma semicolon 1

#include <amxmodx>

#include <api_custom_weapons>
#include <weapon_base_throwable_const>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(BaseGrenade)

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CW_ForkClass(WEAPON_NAME, WEAPON_BASE_THROWABLE, WEAPON(Base));
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(BaseGrenade), ZP_VERSION, "Hedgehog Fog");
}
