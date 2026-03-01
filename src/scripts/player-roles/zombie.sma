#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_player_roles>
#include <api_custom_weapons>
#include <api_player_model>
#include <api_entity_force>

#include <zombiepanic_internal>

#define BASE_ROLE PLAYER_ROLE(Base)
#define BASE_METHOD BASE_ROLE_METHOD
#define BASE_MEMBER BASE_ROLE_MEMBER

#define ROLE PLAYER_ROLE(Zombie)
#define MEMBER ZOMBIE_MEMBER
#define METHOD ZOMBIE_METHOD

#define TASKID_START_REGENERATE 100
#define TASKID_REGENERATE 200

#define REGENERATION_START_DELAY 10.0

new Float:g_flRegenerationRate;
new Float:g_flGameTime = 0.0;

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Zombie), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ZombiePress));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ZombieIdle));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ZombieDeath));

  PlayerRole_Register(ROLE, BASE_ROLE);

  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Assign, "@Role_Assign");
  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Unassign, "@Role_Unassign");

  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Equip), "@Role_Equip");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxSpeed), "@Role_GetMaxSpeed");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxHealth), "@Role_GetMaxHealth");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Update), "@Role_Think");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Spawn), "@Role_Spawn");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(CanPickupItem), "@Role_CanPickupItem");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(PlaySound), "@Role_PlaySound", PlayerRole_Type_Cell);
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(CalculateDamage), "@Role_CalculateDamage", PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell);
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(TakeDamage), "@Role_TakeDamage", PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell);

  PlayerRole_RegisterMethod(ROLE, METHOD(Regenerate), "@Role_Regenerate");
}

public plugin_init() {
  register_plugin(ROLE_PLUGIN(Zombie), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_float(create_cvar(CVAR("zombie_regeneration_rate"), "0.25"), g_flRegenerationRate);
}

public server_frame() {
  g_flGameTime = get_gametime();
}

@Role_Assign(const pPlayer) {
  PlayerRole_This_CallBaseMethod();

  PlayerRole_This_SetMemberString(BASE_MEMBER(szModel), g_szModel);
  PlayerRole_This_SetMember(BASE_MEMBER(flMinIdleSoundDelay), 10.0);
  PlayerRole_This_SetMember(BASE_MEMBER(flMaxIdleSoundDelay), 20.0);

  PlayerRole_This_SetMember(MEMBER(flRegenerationRate), g_flRegenerationRate);
  PlayerRole_This_SetMember(MEMBER(flNextRegeneration), 0.0);
  PlayerRole_This_SetMember(MEMBER(flLastRegeneration), 0.0);
  PlayerRole_This_SetMember(MEMBER(flRegenerationPerSecond), 5.0);
}

@Role_Unassign(const pPlayer) {
  PlayerRole_This_CallBaseMethod();
}

@Role_Equip(const pPlayer) {
  PlayerRole_This_CallBaseMethod();
  CW_Give(pPlayer, WEAPON(Swipe));
}

Float:@Role_GetMaxSpeed(const pPlayer) {
  return 180.0;
}

Float:@Role_GetMaxHealth(const pPlayer) {
  return 200.0;
}

@Role_Think(const pPlayer) {
  PlayerRole_This_CallMethod(METHOD(Regenerate));

  PlayerRole_This_CallBaseMethod();
}

@Role_Regenerate(const pPlayer) {
  static Float:flNextRegeneration; flNextRegeneration = PlayerRole_This_GetMember(MEMBER(flNextRegeneration));

  if (flNextRegeneration > g_flGameTime) return;

  static Float:flRate; flRate = PlayerRole_This_GetMember(MEMBER(flRegenerationRate));
  static Float:flLastRegeneration; flLastRegeneration = PlayerRole_This_GetMember(MEMBER(flLastRegeneration));
  static Float:flTimeDelta; flTimeDelta = flLastRegeneration ? g_flGameTime - flLastRegeneration : flRate;
  static Float:flValue; flValue = PlayerRole_This_GetMember(MEMBER(flRegenerationPerSecond));

  ExecuteHamB(Ham_TakeHealth, pPlayer, flValue * flTimeDelta, 0);

  PlayerRole_This_SetMember(MEMBER(flLastRegeneration), g_flGameTime);
  PlayerRole_This_SetMember(MEMBER(flNextRegeneration), g_flGameTime + flRate);
}

bool:@Role_PlaySound(const pPlayer, ZP_RoleSound:iSound) {
  if (!PlayerRole_This_CallBaseMethod(iSound)) return false;

  switch (iSound) {
    case BASE_ROLE_SOUND(Idle): {
      Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET_SOUND(ZombieIdle));
      return true;
    }
    case BASE_ROLE_SOUND(Death): {
      Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET_SOUND(ZombieDeath));
      return true;
    }
    case BASE_ROLE_SOUND(Scream): {
      Asset_EmitSound(pPlayer, CHAN_VOICE, ASSET_LIBRARY, ASSET_SOUND(ZombieIdle));
      return true;
    }
    case BASE_ROLE_SOUND(Press): {
      // Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(ZombiePress));
      return true;
    }
  }

  return false;
}

@Role_Spawn(const pPlayer) {
  PlayerRole_This_CallBaseMethod();

  emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

bool:@Role_CanPickupItem(const pPlayer, const pItem) {
  return false;
}

Float:@Role_CalculateDamage(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (iDamageBits & DMG_FALL) {
    if (!pAttacker && !pInflictor) return 0.0;
    if (pInflictor == pPlayer && pAttacker == pPlayer) return 0.0;
  }

  return flDamage;
}

@Role_TakeDamage(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (pInflictor && iDamageBits & DMG_BULLET) {
    EntityForce_AddFromEntity(pPlayer, pInflictor, floatmin(flDamage * 2.5, 800.0));
  }

  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(flNextRegeneration), g_flGameTime + 10.0);
  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(flLastRegeneration), 0.0);
}
