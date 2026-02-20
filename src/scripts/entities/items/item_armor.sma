#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_assets>
#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_ARMOR_VALUE 100.0

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(ItemArmor), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ItemArmor));

  CE_RegisterClass(ENTITY(Armor), ENTITY(BaseItem));
  CE_ImplementClassMethod(ENTITY(Armor), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(Armor), CE_Method_CanPickup, "@Entity_CanPickup");
  CE_ImplementClassMethod(ENTITY(Armor), CE_Method_Pickup, "@Entity_Pickup");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(Armor), ZP_VERSION, "Hedgehog Fog");
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

  static Float:flArmorValue; pev(pToucher, pev_armorvalue, flArmorValue);
  if (flArmorValue >= MAX_ARMOR_VALUE) return false;

  return true;
}

@Entity_Pickup(const this, const pToucher) {
  CE_CallBaseMethod(pToucher);

  static Float:flArmorValue; pev(pToucher, pev_armorvalue, flArmorValue);

  set_ent_data(pToucher, "CBasePlayer", "m_iKevlar", 1);
  set_pev(pToucher, pev_armorvalue, (flArmorValue = floatmin(flArmorValue + 20.0, MAX_ARMOR_VALUE)));
  Asset_EmitSound(pToucher, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(ItemArmor));

  return true;
}
