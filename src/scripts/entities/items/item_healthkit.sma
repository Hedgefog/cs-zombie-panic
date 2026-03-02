#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(ItemMedkit), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ItemMedkit));

  CE_RegisterClass(ENTITY(HealthKit), ENTITY(BaseItem));
  CE_ImplementClassMethod(ENTITY(HealthKit), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(HealthKit), CE_Method_CanPickup, "@Entity_CanPickup");
  CE_ImplementClassMethod(ENTITY(HealthKit), CE_Method_Pickup, "@Entity_Pickup");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(HealthKit), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, CE_Member_flRespawnTime, ZP_ITEMS_RESPAWN_TIME);
  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-16.0, -16.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMaxs, Float:{16.0, 16.0, 16.0});
}

@Entity_CanPickup(const this, const pToucher) {
  if (!CE_CallBaseMethod(pToucher)) return false;

  static Float:flMaxHealth; pev(pToucher, pev_max_health, flMaxHealth);
  static Float:flHealth; pev(pToucher, pev_health, flHealth);

  if (flHealth >= flMaxHealth) return false;

  return true;
}

@Entity_Pickup(const this, const pToucher) {
  CE_CallBaseMethod(pToucher);

  static Float:flMaxHealth; pev(pToucher, pev_max_health, flMaxHealth);
  static Float:flHealth; pev(pToucher, pev_health, flHealth);

  set_pev(pToucher, pev_health, (flHealth = floatmin(flHealth + 25.0, flMaxHealth)));
  Asset_EmitSound(pToucher, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(ItemMedkit));

  return true;
}
