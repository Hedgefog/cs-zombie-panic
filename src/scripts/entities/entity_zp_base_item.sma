#pragma semicolon 1

#include <amxmodx>

#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_RegisterClass(ENTITY(BaseItem), CE_Class_BaseItem, true);

  CE_ImplementClassMethod(ENTITY(BaseItem), CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY(BaseItem), CE_Method_Respawn, "@Entity_Respawn");
  CE_ImplementClassMethod(ENTITY(BaseItem), CE_Method_CanPickup, "@Entity_CanPickup");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(BaseItem), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMemberVec(this, CE_Member_vecMins, Float:{-8.0, -8.0, 0.0});
  CE_SetMemberVec(this, CE_Member_vecMins, Float:{8.0, 8.0, 8.0});
  CE_SetMember(this, CE_Member_flRespawnTime, ZP_ITEMS_RESPAWN_TIME);
}

@Entity_Respawn(const this) {
  if (!ZP_GameRules_CanItemRespawn(this)) return;

  CE_CallBaseMethod();
}

@Entity_CanPickup(const this, const pToucher) {
  if (!ZP_GameRules_CanPickupItem(this, pToucher)) return false;
  if (!CE_CallBaseMethod(pToucher)) return false;

  return true;
}
