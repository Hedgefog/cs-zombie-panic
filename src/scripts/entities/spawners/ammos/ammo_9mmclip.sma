#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <zombiepanic_internal>

public plugin_precache() {
  CE_RegisterClass(ENTITY(PistolAmmo), ENTITY(AmmoSpawner));
  CE_ImplementClassMethod(ENTITY(PistolAmmo), CE_Method_Create, "@Entity_Create");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(PistolAmmo), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();
  CE_SetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), AMMO(Pistol));
}
