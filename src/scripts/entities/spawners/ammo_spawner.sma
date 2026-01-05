#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_RegisterClass(ENTITY(AmmoSpawner), ENTITY(BaseSpawner));

  CE_ImplementClassMethod(ENTITY(AmmoSpawner), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(AmmoSpawner), CE_Method_Spawn, "@Entity_Spawn");

  CE_RegisterClassVirtualMethod(ENTITY(AmmoSpawner), BASESPAWNER_METHOD(SpawnWeaponBox), "@Entity_SpawnWeaponBox");

  CE_RegisterClassKeyMemberBinding(ENTITY(AmmoSpawner), "ammo", AMMOSPAWNER_MEMBER(szAmmo), CEMemberType_String);
  CE_RegisterClassKeyMemberBinding(ENTITY(AmmoSpawner), "amount", AMMOSPAWNER_MEMBER(iAmount), CEMemberType_Cell);
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(AmmoSpawner), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, CE_Member_flRespawnTime, ZP_AMMO_RESPAWN_TIME);

  CE_SetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), NULL_STRING, false);
  CE_SetMember(this, AMMOSPAWNER_MEMBER(iAmount), -1, false);
}

@Entity_Spawn(const this) {
  static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CE_GetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), szAmmo, charsmax(szAmmo));
  if (equal(szAmmo, NULL_STRING)) {
    log_amx("[Error] Cannot spawn ^"%s^" without ^"%s^" member!", ENTITY(AmmoSpawner), AMMOSPAWNER_MEMBER(szAmmo));
    return;
  }

  if (!CW_Ammo_IsRegistered(szAmmo)) {
    log_amx("[Error] Cannot spawn ^"%s^"! Ammo ^"%s^" is not registered.", ENTITY(AmmoSpawner), szAmmo);
    return;
  }

  CE_CallBaseMethod();
}

@Entity_SpawnWeaponBox(const this) {
  static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CE_GetMemberString(this, AMMOSPAWNER_MEMBER(szAmmo), szAmmo, charsmax(szAmmo));
  if (!CW_Ammo_IsRegistered(szAmmo)) return FM_NULLENT;

  static szModel[MAX_RESOURCE_PATH_LENGTH]; CW_Ammo_GetMetadataString(szAmmo, AMMO_METADATA(szPackModel), szModel, charsmax(szModel));
  new iAmount = CE_GetMember(this, AMMOSPAWNER_MEMBER(iAmount));

  if (iAmount == -1) {
    iAmount = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));
  }

  if (!iAmount) return FM_NULLENT;

  if (equal(szAmmo, NULL_STRING)) return FM_NULLENT;
  if (CW_Ammo_GetType(szAmmo) == -1) return FM_NULLENT;

  new pWeaponBox = CE_CallBaseMethod();
  if (pWeaponBox == FM_NULLENT) return FM_NULLENT;

  CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackAmmo), szAmmo, iAmount);
  engfunc(EngFunc_SetModel, pWeaponBox, szModel);

  return pWeaponBox;
}
