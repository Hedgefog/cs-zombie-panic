#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <zombiepanic_internal>

public plugin_precache() {
  CE_RegisterClass(ENTITY(RifleWeapon), ENTITY(WeaponSpawner));
  CE_ImplementClassMethod(ENTITY(RifleWeapon), CE_Method_Allocate, "@Entity_Allocate");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(RifleWeapon), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Allocate(const this) {
  CE_CallBaseMethod();
  CE_SetMemberString(this, WEAPONSPAWNER_MEMBER(szWeapon), WEAPON(Rifle));
}
