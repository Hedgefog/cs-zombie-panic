#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <api_assets>
#include <api_player_roles>
#include <api_custom_weapons>
#include <api_custom_entities>
#include <api_player_model>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define BASE_ROLE PLAYER_ROLE(Base)
#define BASE_METHOD BASE_ROLE_METHOD
#define BASE_MEMBER BASE_ROLE_MEMBER

#define ROLE PLAYER_ROLE(Survivor)
#define MEMBER SURVIVOR_MEMBER
#define METHOD SURVIVOR_METHOD

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szDeathSounds[4][MAX_RESOURCE_PATH_LENGTH];
new g_szScreamSounds[2][MAX_RESOURCE_PATH_LENGTH];

new g_iDeathSoundsNum = 0;
new g_iScreamSoundsNum = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Survivor), g_szModel, charsmax(g_szModel));
  g_iDeathSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(SurvivorDeath), g_szDeathSounds, sizeof(g_szDeathSounds), charsmax(g_szDeathSounds[]));
  g_iScreamSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(SurvivorScream), g_szScreamSounds, sizeof(g_szScreamSounds), charsmax(g_szScreamSounds[]));

  PlayerRole_Register(ROLE, PLAYER_ROLE_GROUP, BASE_ROLE);

  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Assign, "@Role_Assign");
  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Unassign, "@Role_Unassign");

  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(Equip), "@Role_Equip");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxSpeed), "@Role_GetMaxSpeed");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(GetMaxHealth), "@Role_GetMaxHealth");
  PlayerRole_RegisterMethod(ROLE, BASE_METHOD(PlaySound), "@Role_PlaySound", PlayerRole_Type_Cell);

  PlayerRole_RegisterMethod(ROLE, METHOD(SelectNextAmmo), "@Role_SelectNextAmmo", PlayerRole_Type_Cell);
  PlayerRole_RegisterMethod(ROLE, METHOD(DropSelectedAmmo), "@Role_DropSelectedAmmo");
}

public plugin_init() {
  register_plugin(ROLE_PLUGIN(Survivor), ZP_VERSION, "Hedgehog Fog");

  register_clcmd("drop", "Command_Drop");
  register_clcmd("dropammo", "Command_DropAmmo");
  register_clcmd("changeammotype", "Command_ChangeAmmoType");
  register_clcmd("dua", "Command_DropInactiveAmmo");
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_Drop(pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return PLUGIN_HANDLED;

  PlayerRole_Player_CallMethod(pPlayer, BASE_ROLE, BASE_METHOD(DropActiveItem));

  return PLUGIN_HANDLED;
}

public Command_DropAmmo(pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return PLUGIN_HANDLED;

  PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropSelectedAmmo), true);

  return PLUGIN_HANDLED;
}

public Command_ChangeAmmoType(pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return PLUGIN_HANDLED;
  
  PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(SelectNextAmmo), true);

  return PLUGIN_HANDLED;
}

public Command_DropInactiveAmmo(pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return PLUGIN_HANDLED;

  PlayerRole_Player_CallMethod(pPlayer, BASE_ROLE, BASE_METHOD(DropAllAmmo), BASE_ROLE_DROP_FLAG(SkipActive) | BASE_ROLE_DROP_FLAG(RandomDirection));

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Methods ]--------------------------------*/

@Role_Assign(const pPlayer) {
  PlayerRole_This_CallBaseMethod();

  PlayerRole_This_SetMemberString(BASE_MEMBER(szModel), g_szModel);

  PlayerRole_This_SetMember(MEMBER(iSelectedAmmo), -1);
}

@Role_Unassign(const pPlayer) {}

@Role_Equip(const pPlayer) {
  PlayerRole_This_CallBaseMethod();

  CW_Give(pPlayer, WEAPON(Crowbar));
  CW_Give(pPlayer, WEAPON(Pistol));
  CW_GiveAmmo(pPlayer, AMMO(Pistol), 14);

  PlayerRole_This_SetMember(MEMBER(iSelectedAmmo), -1);
}

Float:@Role_GetMaxSpeed(const pPlayer) {
  return 260.0;
}

Float:@Role_GetMaxHealth(const pPlayer) {
  return 100.0;
}

bool:@Role_PlaySound(const pPlayer, ZP_RoleSound:iSound) {
  if (!PlayerRole_This_CallBaseMethod(iSound)) return false;

  switch (iSound) {
    case BASE_ROLE_SOUND(Death): {
      emit_sound(pPlayer, CHAN_VOICE, g_szDeathSounds[random(g_iDeathSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
      return true;
    }
    case BASE_ROLE_SOUND(Scream): {
      emit_sound(pPlayer, CHAN_VOICE, g_szScreamSounds[random(g_iScreamSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
      return true;
    }
  }

  return false;
}

@Role_SelectNextAmmo(const pPlayer, bool:bShowMessage) {
  new iAmmosNum = CW_AmmoGroup_GetSize(AMMO_GROUP);
  if (!iAmmosNum) return;

  new iAmmoIndex = PlayerRole_This_GetMember(MEMBER(iSelectedAmmo));
  if (iAmmoIndex == -1) {
    iAmmoIndex = 0;
  }

  for (new i = 0; i < iAmmosNum; i++) {
    iAmmoIndex = (iAmmoIndex + 1) % iAmmosNum;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_AmmoGroup_GetAmmoId(AMMO_GROUP, iAmmoIndex, szAmmo, charsmax(szAmmo));
    if (equal(szAmmo, NULL_STRING)) continue;

    static iPackSize; iPackSize = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));
    if (iPackSize == -1) continue;
    
    static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", CW_AmmoGroup_GetAmmoType(AMMO_GROUP, iAmmoIndex));
    if (iAmmo) break;
  }

  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", CW_AmmoGroup_GetAmmoType(AMMO_GROUP, iAmmoIndex));
  if (!iAmmo) return;

  PlayerRole_This_SetMember(MEMBER(iSelectedAmmo), iAmmoIndex);

  if (bShowMessage) {
    static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_AmmoGroup_GetAmmoId(AMMO_GROUP, iAmmoIndex, szAmmo, charsmax(szAmmo));
    static szAmmoName[64]; CW_Ammo_GetMetadataString(szAmmo, AMMO_METADATA(szName), szAmmoName, charsmax(szAmmoName));
    client_print(pPlayer, print_chat, "Selected %s ammo [%d/%d]", szAmmoName, iAmmo, CW_Ammo_GetMaxAmount(szAmmo));
  }
}

@Role_DropSelectedAmmo(const pPlayer) {
  new iSelectedAmmoIndex = PlayerRole_This_GetMember(MEMBER(iSelectedAmmo));
  if (iSelectedAmmoIndex == -1) return;

  static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_AmmoGroup_GetAmmoId(AMMO_GROUP, iSelectedAmmoIndex, szAmmo, charsmax(szAmmo));
  static iAmmoType; iAmmoType = CW_Ammo_GetType(szAmmo);
  static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);

  if (!iAmmo) return;
  
  static iPackSize; iPackSize = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));
  if (iPackSize == -1) return;

  PlayerRole_Player_CallMethod(pPlayer, BASE_ROLE, BASE_METHOD(DropAmmo), szAmmo, iPackSize ? iPackSize : 1, BASE_ROLE_DROP_FLAG(UseViewAngles));
}
