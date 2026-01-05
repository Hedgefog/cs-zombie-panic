#pragma semicolon 1

#include <amxmodx>

#include <api_custom_events>

#include <function_pointer>

#include <zombiepanic>
#include <zombiepanic_gamemodes_const>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_GAMEMODE_STATE_STRING_LENGTH 128
#define MAX_GAMEMODE_ID_LENGTH 32
#define MAX_GAMEMODES 32

/*--------------------------------[ Plugin State ]--------------------------------*/

new Trie:g_itGameModeIds;
new g_rgszGameModeId[MAX_GAMEMODES][MAX_GAMEMODE_ID_LENGTH];
new Function:g_rgGameModeCallbacks[MAX_GAMEMODES][ZP_GameModes_Callback];
new g_iGameModesNum = 0;

new g_iDefaultGameMode = -1;
new g_iCurrentGameMode = -1;
new g_iPendingGameMode = -1;
new g_bGameInitialized = false;

new Trie:g_itCurrentGameModeState;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_itGameModeIds = TrieCreate();
  g_itCurrentGameModeState = TrieCreate();

  CustomEvent_Register(GAMEMODE_EVENT(Activated), CEP_String);
  CustomEvent_Register(GAMEMODE_EVENT(Deactivated), CEP_String);
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Game Modes"), ZP_VERSION, "Hedgehog Fog");

  CustomEvent_Subscribe(GAMERULES_EVENT(GameInit), "EventSubscriber_GameInit");
  CustomEvent_Subscribe(GAMERULES_EVENT(GameStart), "EventSubscriber_GameStart");
  CustomEvent_Subscribe(GAMERULES_EVENT(GameEnd), "EventSubscriber_GameEnd");
  CustomEvent_Subscribe(GAMERULES_EVENT(CheckWinConditions), "EventSubscriber_CheckWinConditions");
  CustomEvent_Subscribe(GAMERULES_EVENT(PlayerRespawn), "EventSubscriber_PlayerRespawn");
  CustomEvent_Subscribe(GAMERULES_EVENT(PlayerRespawned), "EventSubscriber_PlayerRespawned");
}

public plugin_end() {
  TrieDestroy(g_itGameModeIds);
  TrieDestroy(g_itCurrentGameModeState);
}

public plugin_natives() {
  register_library("zombiepanic_gamemodes");
  register_native("ZP_GameMode_Register", "Native_RegisterGameMode");
  register_native("ZP_GameMode_SetCallback", "Native_SetCallback");
  register_native("ZP_GameMode_Activate", "Native_Activate");
  register_native("ZP_GameMode_IsActive", "Native_IsActive");
  register_native("ZP_GameMode_SetState", "Native_SetState");
  register_native("ZP_GameMode_GetState", "Native_GetState");
  register_native("ZP_GameMode_SetStateString", "Native_SetStateString");
  register_native("ZP_GameMode_GetStateString", "Native_GetStateString");
  register_native("ZP_GameMode_SetStateVector", "Native_SetStateVector");
  register_native("ZP_GameMode_GetStateVector", "Native_GetStateVector");
  register_native("ZP_GameMode_SetDefault", "Native_SetDefault");
  register_native("ZP_GameMode_GetDefault", "Native_GetDefault");
}

/*--------------------------------[ Natives ]--------------------------------*/

public Native_RegisterGameMode(const iPluginId, const iArgc) {
  new szId[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szId, charsmax(szId));

  GameMode_Register(szId);
}

public Native_SetCallback(const iPluginId, const iArgc) {
  new szId[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szId, charsmax(szId));
  new ZP_GameModes_Callback:callback = ZP_GameModes_Callback:get_param(2);
  new szCallback[64]; get_string(3, szCallback, charsmax(szCallback));

  new iId = GameMode_GetId(szId);
  if (iId == -1) {
    log_amx("Cannot set callback for ^"%s^" gamemode. GameMode ^"%s^" is not registered!", szId, szId);
    return;
  }

  new Function:fnCallback = get_func_pointer(szCallback, iPluginId);
  if (fnCallback == Invalid_FunctionPointer) {
    log_amx("Cannot set callback for ^"%s^" gamemode. Callback ^"%s^" is not a valid function!", szId, szCallback);
    return;
  }

  GameMode_RegisterCallback(iId, callback, fnCallback);
}

public Native_Activate(const iPluginId, const iArgc) {
  new szId[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szId, charsmax(szId));

  new iId = GameMode_GetId(szId);
  if (iId == -1) {
    log_amx("Cannot activate ^"%s^" gamemode. GameMode ^"%s^" is not registered!", szId, szId);
    return;
  }

  if (g_bGameInitialized) {
    GameMode_Activate(iId);
  } else {
    g_iPendingGameMode = iId;
  }
}

public bool:Native_IsActive(const iPluginId, const iArgc) {
  new szId[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szId, charsmax(szId));

  new iId = GameMode_GetId(szId);
  if (iId == -1) {
    log_amx("Cannot check if ^"%s^" gamemode is active. GameMode ^"%s^" is not registered!", szId, szId);
    return false;
  }

  return GameMode_IsActive(iId);
}

public Native_SetState(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));
  static any:value; value = any:get_param(2);

  TrieSetCell(g_itCurrentGameModeState, szState, value);
}

public Native_GetState(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));

  static any:value;
  if (!TrieGetCell(g_itCurrentGameModeState, szState, value)) return 0;

  return value;
}

public Native_SetStateString(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));
  static szValue[MAX_GAMEMODE_STATE_STRING_LENGTH]; get_string(2, szValue, charsmax(szValue));

  TrieSetString(g_itCurrentGameModeState, szState, szValue);
}

public Native_GetStateString(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));

  static szValue[MAX_GAMEMODE_STATE_STRING_LENGTH];
  if (!TrieGetString(g_itCurrentGameModeState, szState, szValue, charsmax(szValue))) {
    set_string(2, "", get_param(3));
    return false;
  }

  set_string(2, szValue, get_param(3));

  return true;
}

public Native_SetStateVector(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));
  static Float:vecValue[3]; get_array_f(2, vecValue, 3);

  TrieSetArray(g_itCurrentGameModeState, szState, vecValue, 3);
}

public Native_GetStateVector(const iPluginId, const iArgc) {
  static szState[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szState, charsmax(szState));

  static Float:vecValue[3];
  if (!TrieGetArray(g_itCurrentGameModeState, szState, vecValue, 3)) {
    set_array_f(2, Float:{0.0, 0.0, 0.0}, 3);
    return false;
  }

  set_array_f(2, vecValue, 3);

  return true;
}

public Native_SetDefault(const iPluginId, const iArgc) {
  new szId[MAX_GAMEMODE_ID_LENGTH]; get_string(1, szId, charsmax(szId));

  new iId = GameMode_GetId(szId);
  if (iId == -1) {
    log_amx("Cannot set default gamemode. GameMode ^"%s^" is not registered!", szId);
    return false;
  }

  if (g_iDefaultGameMode != -1) return false;

  g_iDefaultGameMode = iId;

  return true;
}

public Native_GetDefault(const iPluginId, const iArgc) {
  if (g_iDefaultGameMode == -1) {
    set_string(2, "", get_param(3));
    return;
  }

  set_string(2, g_rgszGameModeId[g_iDefaultGameMode], get_param(3));
}

/*--------------------------------[ Events Subscribers ]--------------------------------*/

public EventSubscriber_GameInit() {
  if (g_bGameInitialized) return;

  if (g_iPendingGameMode == -1) {
    GameMode_Activate(g_iDefaultGameMode);
  } else {
    GameMode_Activate(g_iPendingGameMode);
  }

  g_bGameInitialized = true;
}

public EventSubscriber_GameStart() {
  if (g_iCurrentGameMode == -1) return;

  GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(GameStart));
}

public EventSubscriber_GameEnd(const iWinnerTeam) {
  if (g_iCurrentGameMode == -1) return;

  GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(GameEnd), iWinnerTeam);
}

public EventSubscriber_CheckWinConditions() {
  if (g_iCurrentGameMode == -1) return CER_Continue;

  GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(CheckWinConditions));

  return CER_Supercede;
}

public EventSubscriber_PlayerRespawn(const pPlayer) {
  if (g_iCurrentGameMode == -1) return CER_Continue;

  if (!GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(CanPlayerRespawn), pPlayer)) {
    return CER_Supercede;
  }

  GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(PlayerRespawn), pPlayer);

  return CER_Continue;
}

public EventSubscriber_PlayerRespawned(const pPlayer) {
  if (g_iCurrentGameMode == -1) return;

  GameMode_CallCallback(g_iCurrentGameMode, GAMEMODE_CALLBACK(PlayerRespawned), pPlayer);
}


/*--------------------------------[ Methods ]--------------------------------*/

GameMode_GetId(const szId[]) {
  static iId;
  if (!TrieGetCell(g_itGameModeIds, szId, iId)) return -1;

  return iId;
}

GameMode_Register(const szId[]) {
  if (TrieKeyExists(g_itGameModeIds, szId)) {
    log_amx("Cannot register ^"%s^" gamemode. GameMode ^"%s^" is already registered!", szId, szId);
    return -1;
  }

  new iId = g_iGameModesNum;

  copy(g_rgszGameModeId[iId], charsmax(g_rgszGameModeId[]), szId);

  for (new ZP_GameModes_Callback:callback = ZP_GameModes_Callback:0; callback < ZP_GameModes_Callback; callback++) {
    g_rgGameModeCallbacks[iId][callback] = Invalid_FunctionPointer;
  }

  TrieSetCell(g_itGameModeIds, szId, iId);

  g_iGameModesNum++;
  
  return iId;
}

GameMode_RegisterCallback(const iId, const ZP_GameModes_Callback:callback, const &Function:fnCallback) {
  if (g_rgGameModeCallbacks[iId][callback] != Invalid_FunctionPointer) {
    log_amx("Cannot register callback for ^"%s^" gamemode. Callback ^"%s^" is already registered!", g_rgszGameModeId[iId], callback);
    return;
  }

  g_rgGameModeCallbacks[iId][callback] = fnCallback;
}

any:GameMode_CallCallback(const iId, const ZP_GameModes_Callback:callback, any:...) {
  new Function:fnCallback = g_rgGameModeCallbacks[iId][callback];
  if (fnCallback == Invalid_FunctionPointer) {
    switch (callback) {
      case GAMEMODE_CALLBACK(CanPlayerRespawn): return true;
    }

    return 0;
  }

  callfunc_begin_p(fnCallback);

  switch (callback) {
    case GAMEMODE_CALLBACK(CanPlayerRespawn): {
      callfunc_push_int(getarg(2));
    }
    case GAMEMODE_CALLBACK(PlayerRespawn): {
      callfunc_push_int(getarg(2));
    }
    case GAMEMODE_CALLBACK(PlayerRespawned): {
      callfunc_push_int(getarg(2));
    }
    case GAMEMODE_CALLBACK(GameEnd): {
      callfunc_push_int(getarg(2));
    }
  }

  new any:result = callfunc_end();

  return result;
}

GameMode_Activate(const iId) {
  if (g_iCurrentGameMode == iId) return;

  if (g_iCurrentGameMode != -1) {
    DeactivateCurrentGameMode();
  }

  g_iCurrentGameMode = iId;
  GameMode_CallCallback(iId, GAMEMODE_CALLBACK(Activate));

  CustomEvent_Emit(GAMEMODE_EVENT(Activated), g_rgszGameModeId[iId]);

  log_amx("[Zombie Panic Game Modes] Gamemode ^"%s^" is activated", g_rgszGameModeId[iId]);
}

bool:GameMode_IsActive(const iId) {
  return g_iCurrentGameMode == iId;
}

/*--------------------------------[ Functions ]--------------------------------*/

DeactivateCurrentGameMode() {
  new iCurrentGameMode = g_iCurrentGameMode;

  g_iCurrentGameMode = -1;
  GameMode_CallCallback(iCurrentGameMode, GAMEMODE_CALLBACK(Deactivate));

  ZP_GameRules_ResetVariables();

  CustomEvent_Emit(GAMEMODE_EVENT(Deactivated), g_rgszGameModeId[iCurrentGameMode]);
}
