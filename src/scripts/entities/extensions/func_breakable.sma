#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Enums ]--------------------------------*/

enum SpawnObject {
  SpawnObject_None = 0,
  SpawnObject_Armor,
  SpawnObject_HealthKit,
  SpawnObject_PistolWeapon,
  SpawnObject_PistolAmmo,
  SpawnObject_RifleWeapon,
  SpawnObject_RifleAmmo,
  SpawnObject_ShotgunWeapon,
  SpawnObject_ShotgunAmmo,
  SpawnObject_MagnumWeapon,
  SpawnObject_MagnumAmmo,
  SpawnObject_GrenadeWeapon,
  SpawnObject_SatchelWeapon
};

/*--------------------------------[ Plugin Initialization ]--------------------------------*/


public plugin_precache() {
  CE_ExtendClass(ENTITY(Breakable));

  CE_ImplementClassMethod(ENTITY(Breakable), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(Breakable), CE_Method_TakeDamage, "@Entity_TakeDamage");

  CE_RegisterClassMethod(ENTITY(Breakable), BREAKABLE_METHOD(SpawnObject), "@Entity_SpawnObject");

  CE_RegisterClassKeyMemberBinding(ENTITY(Breakable), "spawnobject", BREAKABLE_MEMBER(iSpawnObject), CEMemberType_Cell);
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(Breakable), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_TakeDamage(const this, const pInflictor, const pAttacker, const Float:flDamage, const iDamageBits) {
  CE_CallBaseMethod(pInflictor, pAttacker, flDamage, iDamageBits);

  static Float:flHealth; pev(this, pev_health, flHealth);
  if (flHealth <= 0.0) {
    CE_CallMethod(this, BREAKABLE_METHOD(SpawnObject));
  }
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  set_ent_data(this, "CBreakable", "m_iszSpawnObject", 0);
}

@Entity_SpawnObject(const this) {
  static Float:vecOrigin[3]; ExecuteHamB(Ham_BodyTarget, this, 0, vecOrigin);
  static Float:vecAngles[3]; pev(this, pev_angles, vecAngles);
  static iSpawnObject; iSpawnObject = CE_GetMember(this, BREAKABLE_MEMBER(iSpawnObject));

  static pSpawnObject; pSpawnObject = FM_NULLENT;

  switch (iSpawnObject) {
    case SpawnObject_Armor: pSpawnObject = CE_Create(ENTITY(Armor));
    case SpawnObject_HealthKit: pSpawnObject = CE_Create(ENTITY(HealthKit));
    case SpawnObject_PistolWeapon: pSpawnObject = CE_Create(ENTITY(PistolWeapon));
    case SpawnObject_PistolAmmo: pSpawnObject = CE_Create(ENTITY(PistolAmmo));
    case SpawnObject_RifleWeapon: pSpawnObject = CE_Create(ENTITY(RifleWeapon));
    case SpawnObject_RifleAmmo: pSpawnObject = CE_Create(ENTITY(RifleAmmo));
    case SpawnObject_ShotgunWeapon: pSpawnObject = CE_Create(ENTITY(ShotgunWeapon));
    case SpawnObject_ShotgunAmmo: pSpawnObject = CE_Create(ENTITY(ShotgunAmmo));
    case SpawnObject_MagnumWeapon: pSpawnObject = CE_Create(ENTITY(MagnumWeapon));
    case SpawnObject_MagnumAmmo: pSpawnObject = CE_Create(ENTITY(MagnumAmmo));
    case SpawnObject_GrenadeWeapon: pSpawnObject = CE_Create(ENTITY(GrenadeWeapon));
    case SpawnObject_SatchelWeapon: pSpawnObject = CE_Create(ENTITY(SatchelWeapon));
  }

  if (pSpawnObject == FM_NULLENT) return FM_NULLENT;

  dllfunc(DLLFunc_Spawn, pSpawnObject);

  engfunc(EngFunc_SetOrigin, pSpawnObject, vecOrigin);
  set_pev(pSpawnObject, pev_angles, vecAngles);

  if (CE_IsInstanceOf(pSpawnObject, ENTITY(BaseSpawner))) {
    CE_CallMethod(pSpawnObject, BASESPAWNER_METHOD(SpawnWeaponBox));
    ExecuteHamB(Ham_Killed, pSpawnObject, 0, 0);
  }

  return pSpawnObject;
}
