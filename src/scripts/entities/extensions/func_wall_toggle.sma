#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(WallToggle));

  CE_ImplementClassMethod(ENTITY(WallToggle), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(WallToggle), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  ExecuteHam(Ham_Spawn, this);
}
