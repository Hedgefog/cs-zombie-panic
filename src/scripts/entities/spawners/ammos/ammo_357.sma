#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <zombiepanic_internal>

public plugin_precache() {
  CE_RegisterClass(ENTITY(MagnumAmmo), ENTITY(AmmoSpawner));
  CE_ImplementClassMethod(ENTITY(MagnumAmmo), CE_Method_Create, "@Entity_Create");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(MagnumAmmo), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();
  CE_SetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), AMMO(Magnum));
}
