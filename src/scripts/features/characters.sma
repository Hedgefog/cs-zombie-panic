#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <json>

#include <api_custom_weapons>
#include <api_player_model>
#include <api_player_roles>
#include <api_custom_events>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_CHARACTER_ID_LENGTH 32
#define MAX_CHARACTERS 16
#define MAX_SOUNDS_PER_TYPE 16
#define MAX_RESOURCE_KEY_LENGTH 32
#define MAX_SOUNDS (MAX_CHARACTERS * MAX_SOUNDS_PER_TYPE * _:ZP_PlayerRole_Base_Sound)

#define DOCUMENT_VERSION 2
#define CHARACTER_USERINFO_KEY "zp_character"

/*--------------------------------[ Enums ]--------------------------------*/

enum CharacterModel {
  CharacterModel_Human,
  CharacterModel_Zombie,
  CharacterModel_Swipe
}

/*--------------------------------[ Forward Pointers ]--------------------------------*/

new g_pfwPlayerCharacterUpdated;
new g_pfwPlayerModelUpdated;

/*--------------------------------[ Sound Data ]--------------------------------*/

new g_rgszSounds[MAX_SOUNDS][MAX_RESOURCE_PATH_LENGTH];
new g_iSoundsNum;

/*--------------------------------[ Character Data ]--------------------------------*/

new Trie:g_itCharacterIds = Invalid_Trie;
new bool:g_rgrgbCharacterIsSelectable[MAX_CHARACTERS];
new g_rgrgiCharacterBodyIndex[MAX_CHARACTERS];
new g_rgrgszCharacterModels[MAX_CHARACTERS][CharacterModel][MAX_RESOURCE_PATH_LENGTH];
new g_rgrgrgiCharacterSurvivorSounds[MAX_CHARACTERS][ZP_PlayerRole_Base_Sound][MAX_SOUNDS_PER_TYPE];
new g_rgrgiCharacterSurvivorSoundsNum[MAX_CHARACTERS][ZP_PlayerRole_Base_Sound];
new g_rgrgrgiCharacterZombieSounds[MAX_CHARACTERS][ZP_PlayerRole_Base_Sound][MAX_SOUNDS_PER_TYPE];
new g_rgrgiCharacterZombieSoundsNum[MAX_CHARACTERS][ZP_PlayerRole_Base_Sound];
new g_iCharactersNum = 0;

new Array:g_iSelectableCharacters;

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_szCharacterDir[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Players State ]--------------------------------*/

new g_rgiPlayerCharacter[MAX_PLAYERS + 1] = { -1, ... };

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_itCharacterIds = TrieCreate();
  g_iSelectableCharacters = ArrayCreate();

  get_configsdir(g_szCharacterDir, charsmax(g_szCharacterDir));
  format(g_szCharacterDir, charsmax(g_szCharacterDir), "%s/zombiepanic/characters", g_szCharacterDir);

  LoadCharacters();
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Characters"), ZP_VERSION, "Hedgehog Fog");

  CW_RegisterClassMethodHook(WEAPON(Swipe), CW_Method_Deploy, "CWHook_Swipe_Deploy_Post", true);

  g_pfwPlayerCharacterUpdated = CreateMultiForward("ZP_Characters_OnPlayerCharacterUpdated", ET_IGNORE, FP_CELL);
  g_pfwPlayerModelUpdated = CreateMultiForward("ZP_Characters_OnPlayerModelUpdated", ET_IGNORE, FP_CELL);

  CustomEvent_Subscribe(BASE_ROLE_EVENT(UpdateModel), "EventSubscriber_UpdateModel");
  CustomEvent_Subscribe(BASE_ROLE_EVENT(PlaySound), "EventSubscriber_PlaySound");
}

public plugin_end() {
  TrieDestroy(g_itCharacterIds);
  ArrayDestroy(g_iSelectableCharacters);
}

public plugin_natives() {
  register_library("zombiepanic_characters");
  register_native("ZP_Player_SetCharacter", "Native_SetCharacter");
}

/*--------------------------------[ Natives ]--------------------------------*/

public bool:Native_SetCharacter(const iPluginId, const iArgc) {
  new pPlayer = get_param(1);

  new szCharacter[MAX_CHARACTER_ID_LENGTH]; get_string(2, szCharacter, charsmax(szCharacter));

  return @Player_SetCharacter(pPlayer, szCharacter);
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  @Player_UpdateCharacter(pPlayer, true);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public CWHook_Swipe_Deploy_Post(const pWeapon) {
  static pPlayer; pPlayer = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pPlayer");
  static iCharacterId; iCharacterId = g_rgiPlayerCharacter[pPlayer];

  if (iCharacterId == -1) return CW_IGNORED;

  if (!equal(g_rgrgszCharacterModels[iCharacterId][CharacterModel_Swipe], NULL_STRING)) {
    set_pev(pPlayer, pev_viewmodel2, g_rgrgszCharacterModels[iCharacterId][CharacterModel_Swipe]);
  }

  return CW_HANDLED;
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_UpdateModel(const pPlayer) {
  @Player_UpdateCharacter(pPlayer, false);
  @Player_UpdateModel(pPlayer);

  return CER_Supercede;
}

public EventSubscriber_PlaySound(const pPlayer, ZP_PlayerRole_Base_Sound:iSound) {
  new iCharacterId = g_rgiPlayerCharacter[pPlayer];

  new bool:bIsZombie = PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie));

  new iSoundId = -1;

  if (bIsZombie) {
    new iSoundsNum = g_rgrgiCharacterZombieSoundsNum[iCharacterId][iSound]; 
    if (iSoundsNum) {
      iSoundId = g_rgrgrgiCharacterZombieSounds[iCharacterId][iSound][random(iSoundsNum)];
    }
  } else {
    new iSoundsNum = g_rgrgiCharacterSurvivorSoundsNum[iCharacterId][iSound];
    if (iSoundsNum) {
      iSoundId = g_rgrgrgiCharacterSurvivorSounds[iCharacterId][iSound][random(iSoundsNum)];
    }
  }

  if (iSoundId == -1) return CER_Continue;
  if (equal(g_rgszSounds[iSoundId], NULL_STRING)) return CER_Continue;

  emit_sound(pPlayer, CHAN_VOICE, g_rgszSounds[iSoundId], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return CER_Supercede;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

bool:@Player_SetCharacter(const &this, const szCharacter[]) {
  static iId;
  if (!TrieGetCell(g_itCharacterIds, szCharacter, iId)) return false;

  g_rgiPlayerCharacter[this] = iId;

  return true;
}

@Player_UpdateModel(const &this) {
  static iId; iId = g_rgiPlayerCharacter[this];

  static szPlayerModel[MAX_RESOURCE_PATH_LENGTH]; copy(szPlayerModel, charsmax(szPlayerModel), NULL_STRING);

  if (g_rgiPlayerCharacter[this] != -1) {
    if (PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
      copy(szPlayerModel, charsmax(szPlayerModel), g_rgrgszCharacterModels[iId][CharacterModel_Zombie]);
    } else {
      copy(szPlayerModel, charsmax(szPlayerModel), g_rgrgszCharacterModels[iId][CharacterModel_Human]);
    }
  }

  if (equal(szPlayerModel, NULL_STRING)) return;

  PlayerModel_Set(this, szPlayerModel);
  PlayerModel_Update(this);

  set_pev(this, pev_body, g_rgrgiCharacterBodyIndex[iId]);

  ExecuteForward(g_pfwPlayerModelUpdated, _, this);
}

@Player_UpdateCharacter(const &this, bool:bOverride) {
  if (!g_iCharactersNum) return;

  static iId; iId = -1;

  static szCharacter[16]; get_user_info(this, CHARACTER_USERINFO_KEY, szCharacter, charsmax(szCharacter));
  if (!equal(szCharacter, NULL_STRING)) {
    if (!TrieGetCell(g_itCharacterIds, szCharacter, iId)) {
      if (!bOverride) return;
    }
  } else {
    if (!bOverride) return;
  }

  if (iId != -1 && !g_rgrgbCharacterIsSelectable[iId]) {
    if (!bOverride) return;
  }

  if (iId == -1) {
    iId = ArrayGetCell(g_iSelectableCharacters, random(ArraySize(g_iSelectableCharacters)));
  }

  g_rgiPlayerCharacter[this] = iId;
  ExecuteForward(g_pfwPlayerCharacterUpdated, _, this);
}

/*--------------------------------[ Functions ]--------------------------------*/

LoadCharacters() {
  new szFileName[MAX_CHARACTER_ID_LENGTH + 8];
  new FileType:iFileType;

  new iDir = open_dir(g_szCharacterDir, szFileName, charsmax(szFileName), iFileType);
  if (!iDir) return;

  do {
    if (iFileType != FileType_File) continue;

    new iLen = strlen(szFileName);
    if (iLen > 5 && equal(szFileName[iLen - 5], ".json")) {
      new szId[16];
      copy(szId, iLen - 5, szFileName);
      if (!TrieKeyExists(g_itCharacterIds, szId)) {
        LoadCharacter(szId);
      }
    }

  } while (next_file(iDir, szFileName, charsmax(szFileName), iFileType));

  close_dir(iDir);
}

LoadCharacter(const szId[]) {
  new szFilePath[MAX_RESOURCE_PATH_LENGTH];
  format(szFilePath, charsmax(szFilePath), "%s/%s.json", g_szCharacterDir, szId);

  new JSON:iDoc = json_parse(szFilePath, true);
  new iVersion = json_object_get_number(iDoc, "_version");
  if (iVersion > DOCUMENT_VERSION) {
    log_amx("Cannot load character %s. Character version should be less than or equal to %d.", szId, DOCUMENT_VERSION);
    return -1;
  }

  new iBaseId = -1;
  if (json_object_has_value(iDoc, "inherit")) {
    new szBase[MAX_CHARACTER_ID_LENGTH]; json_object_get_string(iDoc, "inherit", szBase, charsmax(szBase));

    if (!TrieGetCell(g_itCharacterIds, szBase, iBaseId)) {
      iBaseId = LoadCharacter(szBase);
    }
  }

  new iId = g_iCharactersNum;
  TrieSetCell(g_itCharacterIds, szId, iId);

  new JSON:iModelsDoc = json_object_get_value(iDoc, "models");
  for (new CharacterModel:iModel = CharacterModel:0; iModel < CharacterModel; iModel++) {
    if (iModelsDoc == Invalid_JSON || !LoadCharacterModel(iId, iModelsDoc, iModel) && iBaseId != -1) {
      copy(g_rgrgszCharacterModels[iId][iModel], charsmax(g_rgrgszCharacterModels[][]), g_rgrgszCharacterModels[iBaseId][iModel]);
    }
  }

  if (iModelsDoc != Invalid_JSON) {
    json_free(iModelsDoc);
  }

  new JSON:iSoundsDoc = json_object_get_value(iDoc, "sounds");
  for (new ZP_PlayerRole_Base_Sound:iSound = ZP_PlayerRole_Base_Sound:0; iSound < ZP_PlayerRole_Base_Sound; iSound++) {
    if (iSoundsDoc == Invalid_JSON || !LoadCharacterSounds(iId, iSoundsDoc, iSound, TEAM(Zombies), iVersion) && iBaseId != -1) {
      new iSoundsNum = g_rgrgiCharacterZombieSoundsNum[iBaseId][iSound];  

      for (new i = 0; i < iSoundsNum; i++) {
        g_rgrgrgiCharacterZombieSounds[iId][iSound][i] = g_rgrgrgiCharacterZombieSounds[iBaseId][iSound][i];
      }

      g_rgrgiCharacterZombieSoundsNum[iId][iSound] = iSoundsNum;
    }
    if (iSoundsDoc == Invalid_JSON || !LoadCharacterSounds(iId, iSoundsDoc, iSound, TEAM(Survivors), iVersion) && iBaseId != -1) {
      new iSoundsNum = g_rgrgiCharacterSurvivorSoundsNum[iBaseId][iSound];

      for (new i = 0; i < iSoundsNum; i++) {
        g_rgrgrgiCharacterSurvivorSounds[iId][iSound][i] = g_rgrgrgiCharacterSurvivorSounds[iBaseId][iSound][i];
      }

      g_rgrgiCharacterSurvivorSoundsNum[iId][iSound] = iSoundsNum;
    }
  }

  if (iSoundsDoc != Invalid_JSON) {
    json_free(iSoundsDoc);
  }

  if (json_object_has_value(iDoc, "selectable")) {
    g_rgrgbCharacterIsSelectable[iId] = json_object_get_bool(iDoc, "selectable");
  } else {
    g_rgrgbCharacterIsSelectable[iId] = iBaseId == -1 ? true : g_rgrgbCharacterIsSelectable[iBaseId];
  }

  if (json_object_has_value(iDoc, "bodyindex")) {
    g_rgrgiCharacterBodyIndex[iId] = json_object_get_number(iDoc, "bodyindex");
  } else {
    g_rgrgiCharacterBodyIndex[iId] = iBaseId == -1 ? 0 : g_rgrgiCharacterBodyIndex[iBaseId];
  }

  g_iCharactersNum++;

  if (g_rgrgbCharacterIsSelectable[iId]) {
    ArrayPushCell(g_iSelectableCharacters, iId);
  }

  log_amx("Character %s loaded.", szId);

  return iId;
}

LoadCharacterModel(const iId, const &JSON:jsonModelsDoc, CharacterModel:iModel) {
  new szModelKey[MAX_RESOURCE_KEY_LENGTH];

  switch (iModel) {
    case CharacterModel_Human: ResolveTeamKey(TEAM(Survivors), szModelKey, charsmax(szModelKey));
    case CharacterModel_Zombie: ResolveTeamKey(TEAM(Zombies), szModelKey, charsmax(szModelKey));
    case CharacterModel_Swipe: copy(szModelKey, charsmax(szModelKey), "swipe");
  }

  if (equal(szModelKey, NULL_STRING)) return false;
  if (!json_object_has_value(jsonModelsDoc, szModelKey)) return false;

  json_object_get_string(jsonModelsDoc, szModelKey, g_rgrgszCharacterModels[iId][iModel], charsmax(g_rgrgszCharacterModels[][]));

  if (equal(g_rgrgszCharacterModels[iId][iModel], NULL_STRING)) return false;

  precache_model(g_rgrgszCharacterModels[iId][iModel]);

  return true;
}

LoadCharacterSounds(const iId, const &JSON:jsonSoundDoc, ZP_PlayerRole_Base_Sound:iSound, iTeam, iDocVersion) {  
  new szTeamKey[16]; ResolveTeamKey(iTeam, szTeamKey, charsmax(szTeamKey));
  if (equal(szTeamKey, NULL_STRING)) return false;

  new szSoundKey[MAX_RESOURCE_KEY_LENGTH];

  switch (iDocVersion) {
    case 1: {
      switch (iSound) {
        case BASE_ROLE_SOUND(Idle): copy(szSoundKey, charsmax(szSoundKey), "ambient");
        case BASE_ROLE_SOUND(Scream): copy(szSoundKey, charsmax(szSoundKey), "panic");
        case BASE_ROLE_SOUND(Death): copy(szSoundKey, charsmax(szSoundKey), "death");
      }
    }
    case 2: {
      switch (iSound) {
        case BASE_ROLE_SOUND(Idle): copy(szSoundKey, charsmax(szSoundKey), "idle");
        case BASE_ROLE_SOUND(Pain): copy(szSoundKey, charsmax(szSoundKey), "pain");
        case BASE_ROLE_SOUND(Scream): copy(szSoundKey, charsmax(szSoundKey), "scream");
        case BASE_ROLE_SOUND(Death): copy(szSoundKey, charsmax(szSoundKey), "death");
        case BASE_ROLE_SOUND(Taunt): copy(szSoundKey, charsmax(szSoundKey), "taunt");
        case BASE_ROLE_SOUND(Press): copy(szSoundKey, charsmax(szSoundKey), "press");
      }
    }
  }

  if (equal(szSoundKey, NULL_STRING)) return false;

  new szKey[(MAX_RESOURCE_KEY_LENGTH * 2) + 1]; format(szKey, charsmax(szKey), "%s.%s", szTeamKey, szSoundKey);
  if (!json_object_has_value(jsonSoundDoc, szKey, _, true)) return false;

  new JSON:iValue = json_object_get_value(jsonSoundDoc, szKey, true);
  new szPath[MAX_RESOURCE_PATH_LENGTH];
  new bool:bHasSound = false;

  if (json_is_array(iValue)) {
    new iSize = json_array_get_count(iValue);

    for (new i = 0; i < iSize; i++) {
      json_array_get_string(iValue, i, szPath, charsmax(szPath));
      AddCharacterSound(iId, iSound, iTeam, szPath);
    }

    bHasSound = iSize > 0;
  }

  if (json_is_string(iValue)) {
    json_get_string(iValue, szPath, charsmax(szPath));
    AddCharacterSound(iId, iSound, iTeam, szPath);

    bHasSound = !equal(szPath, NULL_STRING);
  }

  json_free(iValue);

  return bHasSound;
}

AddCharacterSound(const iId, ZP_PlayerRole_Base_Sound:iSound, iTeam, const szSound[]) {
  new iSoundId = g_iSoundsNum;

  copy(g_rgszSounds[iSoundId], charsmax(g_rgszSounds[]), szSound);

  switch (iTeam) {
    case TEAM(Zombies): {
      new iIndex = g_rgrgiCharacterZombieSoundsNum[iId][iSound];
      if (iIndex >= MAX_SOUNDS_PER_TYPE) return;

      g_rgrgrgiCharacterZombieSounds[iId][iSound][iIndex] = iSoundId;
      g_rgrgiCharacterZombieSoundsNum[iId][iSound]++;
    }
    case TEAM(Survivors): {
      new iIndex = g_rgrgiCharacterSurvivorSoundsNum[iId][iSound];
      if (iIndex >= MAX_SOUNDS_PER_TYPE) return;

      g_rgrgrgiCharacterSurvivorSounds[iId][iSound][iIndex] = iSoundId;
      g_rgrgiCharacterSurvivorSoundsNum[iId][iSound]++;
    }
  }

  precache_sound(szSound);

  g_iSoundsNum++;
}

ResolveTeamKey(const iTeam, szOut[], iMaxLen) {
  switch (iTeam) {
    case TEAM(Zombies): copy(szOut, iMaxLen, "zombie");
    case TEAM(Survivors): copy(szOut, iMaxLen, "human");
  }
}
