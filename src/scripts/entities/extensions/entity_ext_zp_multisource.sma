#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_MS_TARGETS 32 

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_ExtendClass(ENTITY(MultiSource));

  CE_ImplementClassMethod(ENTITY(MultiSource), CE_Method_Restart, "@Entity_Restart");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(MultiSource), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Restart(const this) {
  for (new i = 0; i < MAX_MS_TARGETS; i++) {
    set_ent_data(this, "CMultiSource", "m_rgTriggered", 0, i);
  }

  ExecuteHam(Ham_Spawn, this);
}
