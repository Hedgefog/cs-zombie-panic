#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <zombiepanic_internal>

public plugin_precache() {
  CE_RegisterClass(ENTITY(MagnumWeapon), ENTITY(WeaponSpawner));
  CE_ImplementClassMethod(ENTITY(MagnumWeapon), CE_Method_Create, "@Entity_Create");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(MagnumWeapon), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();
  CE_SetMemberString(this, WEAPONSPAWNER_MEMBER(szWeapon), WEAPON(Magnum));
}
