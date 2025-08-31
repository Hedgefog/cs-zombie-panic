#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_RegisterClass(ENTITY(WeaponSpawner), ENTITY(BaseSpawner));

  CE_ImplementClassMethod(ENTITY(WeaponSpawner), CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY(WeaponSpawner), CE_Method_Spawn, "@Entity_Spawn");
  
  CE_RegisterClassMethod(ENTITY(WeaponSpawner), BASESPAWNER_METHOD(SpawnWeaponBox), "@Entity_SpawnWeaponBox");
  CE_RegisterClassMethod(ENTITY(WeaponSpawner), WEAPONSPAWNER_METHOD(SpawnItem), "@Entity_SpawnItem");

  CE_RegisterClassKeyMemberBinding(ENTITY(WeaponSpawner), "weapon", WEAPONSPAWNER_MEMBER(szWeapon), CEMemberType_String);
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(WeaponSpawner), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Allocate(const this) {
  CE_CallBaseMethod();

  CE_SetMember(this, CE_Member_flRespawnTime, ZP_WEAPONS_RESPAWN_TIME);
  CE_SetMemberString(this, WEAPONSPAWNER_MEMBER(szWeapon), NULL_STRING, false);
}

@Entity_Spawn(const this) {
  static szWeapon[CW_MAX_NAME_LENGTH]; CE_GetMemberString(this, WEAPONSPAWNER_MEMBER(szWeapon), szWeapon, charsmax(szWeapon));
  if (equal(szWeapon, NULL_STRING)) {
    log_amx("[Error] Cannot spawn ^"%s^" without ^"%s^" member!", ENTITY(WeaponSpawner), WEAPONSPAWNER_MEMBER(szWeapon));
    return;
  }

  if (!CW_IsClassRegistered(szWeapon)) {
    log_amx("[Error] Cannot spawn ^"%s^"! Weapon class ^"%s^" is not registered.", ENTITY(WeaponSpawner), szWeapon);
    return;
  }

  CE_CallBaseMethod();
}

@Entity_SpawnWeaponBox(const this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);

  new pItem = CE_CallMethod(this, WEAPONSPAWNER_METHOD(SpawnItem));
  if (pItem == FM_NULLENT) return FM_NULLENT;

  new pWeaponBox = CE_CallBaseMethod();
  if (pWeaponBox == FM_NULLENT) {
    set_pev(pItem, pev_flags, FL_KILLME);
    dllfunc(DLLFunc_Think, pItem);
    return FM_NULLENT;
  }

  CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackItem), pItem);
  CW_CallNativeMethod(pItem, CW_Method_UpdateWeaponBoxModel, pWeaponBox);

  return pWeaponBox;
}

@Entity_SpawnItem(const this) {
  static szWeapon[CW_MAX_NAME_LENGTH]; CE_GetMemberString(this, WEAPONSPAWNER_MEMBER(szWeapon), szWeapon, charsmax(szWeapon));
  if (equal(szWeapon, NULL_STRING)) return FM_NULLENT;

  new pItem = CW_Create(szWeapon);
  if (pItem == FM_NULLENT) return FM_NULLENT;

  dllfunc(DLLFunc_Spawn, pItem);

  return pItem;
}
