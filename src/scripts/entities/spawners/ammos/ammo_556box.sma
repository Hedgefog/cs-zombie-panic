#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_internal>

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(AmmoRifleBox), g_szModel, charsmax(g_szModel));

  CE_RegisterClass(ENTITY(RifleAmmoBox), ENTITY(AmmoSpawner));
  CE_ImplementClassMethod(ENTITY(RifleAmmoBox), CE_Method_Create, "@Entity_Create");
  CE_RegisterClassMethod(ENTITY(RifleAmmoBox), BASESPAWNER_METHOD(SpawnWeaponBox), "@Entity_SpawnWeaponBox");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(RifleAmmoBox), ZP_VERSION, "Hedgehog Fog");
}

@Entity_Create(const this) {
  CE_CallBaseMethod();
  CE_SetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), AMMO(Rifle));
  CE_SetMember(this, AMMOSPAWNER_MEMBER(iAmount), CW_Ammo_GetMetadata(AMMO(Rifle), AMMO_METADATA(iPackSize)) * 5);
}

@Entity_SpawnWeaponBox(const this) {
  static pWeaponBox; pWeaponBox = CE_CallBaseMethod();

  engfunc(EngFunc_SetModel, pWeaponBox, g_szModel);
}
