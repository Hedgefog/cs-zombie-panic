#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  CE_RegisterClass(ENTITY(BaseSpawner), ENTITY(BaseItem), true);

  CE_ImplementClassMethod(ENTITY(BaseSpawner), CE_Method_Allocate, "@Entity_Allocate");
  CE_ImplementClassMethod(ENTITY(BaseSpawner), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(BaseSpawner), CE_Method_Think, "@Entity_Think");
  CE_ImplementClassMethod(ENTITY(BaseSpawner), CE_Method_CanPickup, "@Entity_CanPickup");

  CE_RegisterClassVirtualMethod(ENTITY(BaseSpawner), BASESPAWNER_METHOD(SpawnWeaponBox), "@Entity_SpawnWeaponBox");
}

public plugin_init() {
  register_plugin(ENTITY_PLUGIN(BaseSpawner), ZP_VERSION, "Hedgehog Fog");

  CE_RegisterClassMethodHook(ENTITY(WeaponBox), CE_Method_Free, "CEHook_WeaponBox_Free");
  CE_RegisterClassMethodHook(ENTITY(WeaponBox), CE_Method_Touch, "CEHook_WeaponBox_Touch_Post", true);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public CEHook_WeaponBox_Free(const pEntity) {
  new pOwner = pev(pEntity, pev_owner);

  if (pOwner && CE_IsInstanceOf(pOwner, ENTITY(BaseSpawner))) {
    if (pev(pOwner, pev_deadflag) == DEAD_NO) {
      ExecuteHamB(Ham_Killed, pOwner, 0, 0);
    }

    CE_SetMember(pOwner, BASESPAWNER_MEMBER(pWeaponBox), FM_NULLENT);
  }
}

public CEHook_WeaponBox_Touch_Post(const pEntity, const pToucher) {
  new pOwner = pev(pEntity, pev_owner);
  if (pOwner && CE_IsInstanceOf(pOwner, ENTITY(BaseSpawner)) && pev(pOwner, pev_deadflag) == DEAD_NO) {
    if (CE_GetMember(pEntity, WEAPONBOX_MEMBER(bDirty))) {
      // WeaponBox is dirty, schedule the respawn
      ExecuteHamB(Ham_Killed, pOwner, 0, 0);
    }
  }
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Allocate(const this) {
  CE_SetMember(this, BASESPAWNER_MEMBER(pWeaponBox), FM_NULLENT);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  /*
    Becase weaponbox cleanup phase is called after respawn, we need to unattach weaponbox from entity.
    Without this fix spawner will be killed at the beginning of a round.

    With this logic we also handle the case when weaponbox is "dirty":
      - If weaponbox became "dirty" after touch, spawner will be killed to schedule the respawn
      - Spawn method will be called on respawn
      - The old weaponbox will be destroyed and a new one will be spawned
  */
  new pWeaponBox = CE_GetMember(this, BASESPAWNER_MEMBER(pWeaponBox));
  if (pWeaponBox != FM_NULLENT) {
    // Unattach weaponbox from the spawner
    CE_SetMember(this, BASESPAWNER_MEMBER(pWeaponBox), FM_NULLENT);
    set_pev(pWeaponBox, pev_owner, 0);

    // Kill the weaponbox
    set_pev(pWeaponBox, pev_flags, pev(pWeaponBox, pev_flags) | FL_KILLME);
    dllfunc(DLLFunc_Think, pWeaponBox);
  }

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

@Entity_Think(const this) {
  new iDeadFlag = pev(this, pev_deadflag);

  CE_CallBaseMethod();

  if (iDeadFlag == DEAD_NO) {
    CE_CallMethod(this, BASESPAWNER_METHOD(SpawnWeaponBox));
  }
}

@Entity_SpawnWeaponBox(const this) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);

  new pWeaponBox = rg_create_entity("weaponbox", true);
  if (pWeaponBox == FM_NULLENT) return FM_NULLENT;

  engfunc(EngFunc_SetOrigin, pWeaponBox, vecOrigin);

  dllfunc(DLLFunc_Spawn, pWeaponBox);

  set_pev(pWeaponBox, pev_angles, vecAngles);
  set_pev(pWeaponBox, pev_owner, this);
  engfunc(EngFunc_DropToFloor, pWeaponBox);

  CE_SetMember(this, BASESPAWNER_MEMBER(pWeaponBox), pWeaponBox);

  return pWeaponBox;
}

@Entity_CanPickup(const this) {
  return false;
}
