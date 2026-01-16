#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>

#include <api_assets>
#include <api_player_roles>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic_internal>

/*--------------------------------[ Forward Pointers ]--------------------------------*/

new g_pFwConfigLoaded;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Library_Load(ASSET_LIBRARY);

  CE_RegisterNullClass("info_map_parameters");
  CE_RegisterNullClass("func_bomb_target");
  CE_RegisterNullClass("func_escapezone");
  CE_RegisterNullClass("func_hostage_rescue");
  CE_RegisterNullClass("hostage_entity");
  CE_RegisterNullClass("info_bomb_target");
  CE_RegisterNullClass("info_vip_start");
  CE_RegisterNullClass("info_hostage_rescue");
  CE_RegisterNullClass("monster_scientist");
  CE_RegisterNullClass("weapon_c4");
  CE_RegisterNullClass("func_buyzone");
  CE_RegisterNullClass("armoury_entity");
  CE_RegisterNullClass("weapon_shield");

  CE_RegisterClassAlias("item_healthkit", ENTITY(HealthKit));
  CE_RegisterClassAlias("item_battery", ENTITY(Armor));
  CE_RegisterClassAlias("func_vip_safetyzone", ENTITY(EndRoundTrigger));

  CW_LoadCustomMaterials("sound/zombiepanic/materials.txt");

  hook_cvar_change(create_cvar("zombiepanic_version", ZP_VERSION, FCVAR_SERVER), "CvarHook_Version");
}

public plugin_init() {
  register_plugin("Zombie Panic", ZP_VERSION, "Hedgehog Fog");

  if (!LibraryExists(LIBRARY(Gamerules), LibType_Library)) {
    set_fail_state("Gamerules library is required!");
  }

  if (!LibraryExists(LIBRARY(Ammo), LibType_Library)) {
    set_fail_state("Ammo library is required!");
  }

  if (!PlayerRole_IsRegistered(PLAYER_ROLE(Base))) {
    set_fail_state("Base player role is required!");
  }

  if (!PlayerRole_IsRegistered(PLAYER_ROLE(Survivor))) {
    set_fail_state("Survivor player role is required!");
  }

  if (!PlayerRole_IsRegistered(PLAYER_ROLE(Zombie))) {
    set_fail_state("Zombie player role is required!");
  }

  register_forward(FM_GetGameDescription, "FMHook_GetGameDescription");

  register_message(get_user_msgid("SendAudio"), "Message_SendAudio");
  register_message(get_user_msgid("TextMsg"), "Message_TextMsg");

  register_clcmd("radio1", "Command_NextAmmo");
  register_clcmd("radio2", "Command_DropAmmo");
  register_clcmd("radio3", "Command_DropUnactiveAmmo");
  register_clcmd("buyequip", "Command_Panic");
  register_clcmd("nightvision", "Command_Unload");

  g_pFwConfigLoaded = CreateMultiForward("ZP_OnConfigLoaded", ET_IGNORE);
}

public plugin_cfg() {
  new szConfigDir[32]; get_configsdir(szConfigDir, charsmax(szConfigDir));
  new szMapName[64]; get_mapname(szMapName, charsmax(szMapName));

  server_cmd("exec %s/zombiepanic.cfg", szConfigDir);
  server_cmd("exec %s/zombiepanic/%s.cfg", szConfigDir, szMapName);
  server_exec();

  ExecuteForward(g_pFwConfigLoaded);
}

public plugin_natives() {
  register_library(LIBRARY(Core));
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_NextAmmo(const pPlayer) {
  amxclient_cmd(pPlayer, "changeammotype");

  return PLUGIN_HANDLED;
}

public Command_DropAmmo(const pPlayer) {
  amxclient_cmd(pPlayer, "dropammo");

  return PLUGIN_HANDLED;
}

public Command_DropUnactiveAmmo(const pPlayer) {
  amxclient_cmd(pPlayer, "dua");

  return PLUGIN_HANDLED;
}

public Command_Panic(const pPlayer) {
  amxclient_cmd(pPlayer, "panic");

  return PLUGIN_HANDLED;
}

public Command_Unload(const pPlayer) {
  amxclient_cmd(pPlayer, "unload");

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public CvarHook_Version(pCvar) {
  set_pcvar_string(pCvar, ZP_VERSION);
}

public FMHook_GetGameDescription() {
  static szGameName[32];
  format(szGameName, charsmax(szGameName), "%s %s", ZP_TITLE, ZP_VERSION);
  forward_return(FMV_STRING, szGameName);

  return FMRES_SUPERCEDE;
}

public Message_SendAudio()  {
  static szAudio[16]; get_msg_arg_string(2, szAudio, charsmax(szAudio));

  if (equal(szAudio[7], "terwin")) return PLUGIN_HANDLED;
  if (equal(szAudio[7], "ctwin")) return PLUGIN_HANDLED;
  if (equal(szAudio[7], "rounddraw")) return PLUGIN_HANDLED;
  if (equal(szAudio, "%!MRAD_", 7)) return PLUGIN_HANDLED;

  return PLUGIN_CONTINUE;
}

public Message_TextMsg() {
  static szMessage[32]; get_msg_arg_string(2, szMessage, charsmax(szMessage));

  if (equal(szMessage, "#Terrorists_Win")) return PLUGIN_HANDLED;
  if (equal(szMessage, "#CTs_Win")) return PLUGIN_HANDLED;
  if (equal(szMessage, "#Round_Draw")) return PLUGIN_HANDLED;

  return PLUGIN_CONTINUE;
}
