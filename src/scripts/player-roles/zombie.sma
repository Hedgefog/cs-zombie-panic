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

new g_pCvarRegenerationRate;

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPressSound[MAX_RESOURCE_PATH_LENGTH];

new g_szIdleSounds[15][MAX_RESOURCE_PATH_LENGTH];
new g_szDeathSounds[3][MAX_RESOURCE_PATH_LENGTH];

new g_iIdleSoundsNum = 0;
new g_iDeathSoundsNum = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Zombie), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ZombiePress), g_szPressSound, charsmax(g_szPressSound));

  g_iIdleSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(ZombieIdle), g_szIdleSounds, sizeof(g_szIdleSounds), charsmax(g_szIdleSounds[]));
  g_iDeathSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(ZombieDeath), g_szDeathSounds, sizeof(g_szDeathSounds), charsmax(g_szDeathSounds[]));

  PlayerRole_Register(ROLE, BASE_ROLE);

  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Assign, "@Role_Assign");
  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Unassign, "@Role_Unassign");

  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Equip), "@Role_Equip");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxSpeed), "@Role_GetMaxSpeed");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxHealth), "@Role_GetMaxHealth");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Think), "@Role_Think");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Spawn), "@Role_Spawn");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(CanPickupItem), "@Role_CanPickupItem");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(PlaySound), "@Role_PlaySound", PlayerRole_Type_Cell);
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(CalculateDamage), "@Role_CalculateDamage", PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell);
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(TakeDamage), "@Role_TakeDamage", PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell, PlayerRole_Type_Cell);

  PlayerRole_RegisterMethod(ROLE, METHOD(Regenerate), "@Role_Regenerate");
}

public plugin_init() {
  register_plugin(ROLE_PLUGIN(Zombie), ZP_VERSION, "Hedgehog Fog");

  g_pCvarRegenerationRate = create_cvar(CVAR("zombie_regeneration_rate"), "0.25");
}

@Role_Assign(const pPlayer) {
  PlayerRole_This_CallBaseMethod();

  PlayerRole_This_SetMemberString(BASE_MEMBER(szModel), g_szModel);
  PlayerRole_This_SetMember(BASE_MEMBER(flMinIdleSoundDelay), 10.0);
  PlayerRole_This_SetMember(BASE_MEMBER(flMaxIdleSoundDelay), 20.0);

  PlayerRole_This_SetMember(MEMBER(flRegenerationRate), get_pcvar_float(g_pCvarRegenerationRate));
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
  static Float:flGameTime; flGameTime = get_gametime();
  static Float:flNextRegeneration; flNextRegeneration = PlayerRole_This_GetMember(MEMBER(flNextRegeneration));

  if (flNextRegeneration > flGameTime) return;

  static Float:flRate; flRate = PlayerRole_This_GetMember(MEMBER(flRegenerationRate));
  static Float:flLastRegeneration; flLastRegeneration = PlayerRole_This_GetMember(MEMBER(flLastRegeneration));
  static Float:flTimeDelta; flTimeDelta = flLastRegeneration ? flGameTime - flLastRegeneration : flRate;
  static Float:flValue; flValue = PlayerRole_This_GetMember(MEMBER(flRegenerationPerSecond));

  ExecuteHamB(Ham_TakeHealth, pPlayer, flValue * flTimeDelta, 0);

  PlayerRole_This_SetMember(MEMBER(flLastRegeneration), flGameTime);
  PlayerRole_This_SetMember(MEMBER(flNextRegeneration), flGameTime + flRate);
}

bool:@Role_PlaySound(const pPlayer, ZP_RoleSound:iSound) {
  if (!PlayerRole_This_CallBaseMethod(iSound)) return false;

  switch (iSound) {
    case BASE_ROLE_SOUND(Idle): {
      emit_sound(pPlayer, CHAN_VOICE, g_szIdleSounds[random(g_iIdleSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
      return true;
    }
    case BASE_ROLE_SOUND(Death): {
      emit_sound(pPlayer, CHAN_VOICE, g_szDeathSounds[random(g_iDeathSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
      return true;
    }
    case BASE_ROLE_SOUND(Scream): {
      emit_sound(pPlayer, CHAN_VOICE, g_szIdleSounds[random(g_iIdleSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
      return true;
    }
    case BASE_ROLE_SOUND(Press): {
      // emit_sound(pPlayer, CHAN_ITEM, g_szPressSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
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

  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(flNextRegeneration), get_gametime() + 10.0);
  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(flLastRegeneration), 0.0);
}
