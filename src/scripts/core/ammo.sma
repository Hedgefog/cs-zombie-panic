#pragma semicolon 1

#include <amxmodx>

#include <api_assets>
#include <api_custom_weapons>

#include <zombiepanic_internal>

new g_szPistolAmmoModel[MAX_RESOURCE_PATH_LENGTH];
new g_szRifleAmmoModel[MAX_RESOURCE_PATH_LENGTH];
new g_szShotgunAmmoModel[MAX_RESOURCE_PATH_LENGTH];
new g_szMagnumAmmoModel[MAX_RESOURCE_PATH_LENGTH];
new g_szSatchelAmmoModel[MAX_RESOURCE_PATH_LENGTH];
new g_szGrenadeAmmoModel[MAX_RESOURCE_PATH_LENGTH];

new g_szGrenadeBounceSound[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(AmmoPistol), g_szPistolAmmoModel, charsmax(g_szPistolAmmoModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(AmmoRifle), g_szRifleAmmoModel, charsmax(g_szRifleAmmoModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(AmmoShotgun), g_szShotgunAmmoModel, charsmax(g_szShotgunAmmoModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(AmmoMagnum), g_szMagnumAmmoModel, charsmax(g_szMagnumAmmoModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Satchel), g_szSatchelAmmoModel, charsmax(g_szSatchelAmmoModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Grenade), g_szGrenadeAmmoModel, charsmax(g_szGrenadeAmmoModel));

  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(GrenadeBounce), g_szGrenadeBounceSound, charsmax(g_szGrenadeBounceSound));

  RegisterAmmo(AMMO(Pistol), 10, 7, "pistol", g_szPistolAmmoModel, 70, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flPistolAmmoWeight)));
  RegisterAmmo(AMMO(Rifle), 4, 30, "rifle", g_szRifleAmmoModel, 240, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flRifleAmmoWeight)));
  RegisterAmmo(AMMO(Shotgun), 5, 6, "shotgun", g_szShotgunAmmoModel, 60, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flShotgunAmmoWeight)));
  RegisterAmmo(AMMO(Magnum), 1, 6, "magnum", g_szMagnumAmmoModel, 36, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flMagnumAmmoWeight)));

  #if defined ZP_DROPPABLE_SATCHELS
    RegisterAmmo(AMMO(Satchel), 14, 0, "satchel", g_szSatchelAmmoModel, 5, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flSatchelWeight)));
    CW_Ammo_SetMetadata(AMMO(Satchel), AMMO_METADATA(iSequence), 1);
  #else
    RegisterAmmo(AMMO(Satchel), 14, _, _, g_szSatchelAmmoModel, 1, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flSatchelWeight)));
  #endif

  RegisterAmmo(AMMO(Grenade), 12, _, _, g_szGrenadeAmmoModel, 1, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flGrenadeWeight)));
  RegisterAmmo(AMMO(ZombiesValue), 13);

  CW_Ammo_SetMetadataString(AMMO(Satchel), AMMO_METADATA(szBounceSound), g_szGrenadeBounceSound);
  CW_Ammo_SetMetadataString(AMMO(Grenade), AMMO_METADATA(szBounceSound), g_szGrenadeBounceSound);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Ammo"), ZP_VERSION, "Hedgehog Fog");
}

public plugin_natives() {
  register_library(LIBRARY(Ammo));
}

/*
  iPackSize = -1 - can't drop ammo for this weapon
  iPackSize = 0 - drop weapon without ammo, drop 1 ammo
  iPackSize > 0 - drop iPackSize amount of ammo
*/
RegisterAmmo(const szId[], iAmmoType = -1, iPackSize = -1, const szName[] = "", const szModel[] = "", iMaxAmount = -1, Float:flWeight = 0.0) {
  if (!equal(szModel, NULL_STRING)) {
    precache_model(szModel);
  }

  CW_Ammo_Register(szId, iAmmoType, iMaxAmount, AMMO_GROUP);
  CW_Ammo_SetMetadataString(szId, AMMO_METADATA(szName), szName);
  CW_Ammo_SetMetadata(szId, AMMO_METADATA(iPackSize), iPackSize);
  CW_Ammo_SetMetadata(szId, AMMO_METADATA(flWeight), flWeight);
  CW_Ammo_SetMetadataString(szId, AMMO_METADATA(szPackModel), szModel);
  CW_Ammo_SetMetadata(szId, AMMO_METADATA(iSequence), 0);
}
