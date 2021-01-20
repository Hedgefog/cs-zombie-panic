#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Characters"
#define AUTHOR "Hedgehog Fog"

#define CHARACTER_KEY "zp_character"

new g_rgszCharacterModels[ZP_CharacterModels][32] = {
  "human.mdl",
  "zombie.mdl",
  "swipe.mdl"
};

new g_iPlayerCharacter[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    register_forward(FM_SetClientKeyValue, "OnSetClientKeyValue");
}

public plugin_natives() {
  register_native("ZP_Player_GetCharacter", "Native_GetPlayerCharacter");
  register_native("ZP_GetCharacterModelPath", "Native_GetCharacterModelPath");
  register_native("ZP_GetCharacterModel", "Native_GetCharacterModel");
  register_native("ZP_GetCharacterCount", "Native_GetCharacterCount");
}

public Native_GetPlayerCharacter(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  return g_iPlayerCharacter[pPlayer];
}

public Native_GetCharacterModelPath(iPluginId, iArgc) {
  new iCharacter = get_param(1);
  new iLen = get_param(3);

  static szPath[64];
  GetCharacterModelPath(iCharacter, szPath, charsmax(szPath));

  set_string(2, szPath, iLen);
}

public Native_GetCharacterModel(iPluginId, iArgc) {
  new iCharacter = get_param(1);
  new ZP_CharacterModels:iModel = ZP_CharacterModels:get_param(2);
  new iLen = get_param(4);

  static szPath[64];
  GetCharacterModel(iCharacter, iModel, szPath, charsmax(szPath));

  set_string(3, szPath, iLen);
}

public Native_GetCharacterCount(iPluginId, iArgc) {
  return sizeof(ZP_CHARACTERS);
}

public plugin_precache() {
  new szBuffer[64];
  for (new iCharacter = 0; iCharacter < sizeof(ZP_CHARACTERS); ++iCharacter) {
    for (new ZP_CharacterModels:iModel = ZP_CharacterModels:0; _:iModel < sizeof(g_rgszCharacterModels); ++iModel) {
      GetCharacterModel(iCharacter, iModel, szBuffer, charsmax(szBuffer));
      precache_model(szBuffer);
    }
  }
}

public client_connect(pPlayer) {
  UpdatePlayerCharacter(pPlayer, true);
}

public OnPlayerSpawn_Post(pPlayer) {
  UpdatePlayerCharacter(pPlayer);
  UpdatePlayerModel(pPlayer);
}

public OnSetClientKeyValue(pPlayer, const szInfoBuffer[], const szKey[], const szValue[]) {
  if(equal(szKey, "model")) {
    UpdatePlayerModel(pPlayer);
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}

UpdatePlayerModel(pPlayer) {
  new iCharacter = g_iPlayerCharacter[pPlayer];

  static szPlayerModel[64];
  format(
    szPlayerModel,
    charsmax(szPlayerModel),
    "%s/%s/%s",
    ZP_CHARACTER_FOLDER,
    ZP_CHARACTERS[iCharacter],
    g_rgszCharacterModels[ZP_Player_IsZombie(pPlayer) ? CharacterModel_Zombie : CharacterModel_Human]
  );

  new iModelIndex = engfunc(EngFunc_ModelIndex, szPlayerModel);

  set_user_info(pPlayer, "model", "");
  set_pev(pPlayer, pev_modelindex, iModelIndex);
  set_member(pPlayer, m_modelIndexPlayer, iModelIndex);
}

GetCharacterModelPath(iCharacter, szOut[], iLen) {
    format(szOut, iLen, "%s/%s", ZP_CHARACTER_FOLDER, ZP_CHARACTERS[iCharacter]);
}

GetCharacterModel(iCharacter, ZP_CharacterModels:iModel, szOut[], iLen) {
    format(szOut, iLen, "%s/%s/%s", ZP_CHARACTER_FOLDER, ZP_CHARACTERS[iCharacter], g_rgszCharacterModels[iModel]);
}

GetPlayerCharacter(pPlayer) {
  static szCharacter[32];
  get_user_info(pPlayer, CHARACTER_KEY, szCharacter, charsmax(szCharacter));

  return FindCharacterIndex(szCharacter);
}

UpdatePlayerCharacter(pPlayer, bool:bOverride = false) {
  new iCharacter = GetPlayerCharacter(pPlayer);
  if (iCharacter == -1) {
    if (bOverride) {
      iCharacter = random(sizeof(ZP_CHARACTERS));
    } else {
      return;
    }
  }

  g_iPlayerCharacter[pPlayer] = iCharacter;
}

FindCharacterIndex(const szCharacter[]) {
  if (szCharacter[0] == '^0') {
    return -1;
  }

  for (new i = 0; i < sizeof(ZP_CHARACTERS); ++i) {
    if (equal(ZP_CHARACTERS[i], szCharacter)) {
      return i;
    }
  }

  return -1;
}
