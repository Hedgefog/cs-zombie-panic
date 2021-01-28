#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <json>

#include <zombiepanic>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Characters"
#define AUTHOR "Hedgehog Fog"

#define PATH_MAX_LEN 64
#define RESERVED_CHARACTER_COUNT 4
#define RESERVED_SOUND_COUNT 3
#define CHARACTER_KEY "zp_character"
#define DEFAULT_PLAYER_MODEL "models/player/vip/vip.mdl"

#define TASKID_AMBIENT 100

enum _:Character {
  Character_HumanModel,
  Character_ZombieModel,
  Character_SwipeModel,
  Character_HumanDeathSounds,
  Character_PanicSounds,
  Character_ZombieAmbientSounds,
  Character_ZombieDeathSounds
}

new g_szCharacterDir[PATH_MAX_LEN];

new Array:g_irgCharactersData[Character];
new Trie:g_iCharactersMap;
new g_iCharacterCount = 0;

new g_iPlayerCharacter[MAX_PLAYERS + 1] = { -1, ... };

new CW:g_iCwSwipeHandler;

public plugin_precache() {
  precache_model(DEFAULT_PLAYER_MODEL);

  get_configsdir(g_szCharacterDir, charsmax(g_szCharacterDir));
  format(g_szCharacterDir, charsmax(g_szCharacterDir), "%s/zombiepanic/characters", g_szCharacterDir);

  InitializeCharactersStore();
  LoadCharacters();
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "OnKnifeDeploy_Post", .Post = 1);

    register_forward(FM_SetClientKeyValue, "OnSetClientKeyValue");

    g_iCwSwipeHandler = CW_GetHandler(ZP_WEAPON_SWIPE);
}

public plugin_end() {
  DestroyCharactersStore();
}

public client_connect(pPlayer) {
  UpdatePlayerCharacter(pPlayer, true);
}

public ZP_Fw_PlayerPanic(pPlayer) {
  PlayVoiceFromCharacterData(pPlayer, Character_PanicSounds);
}

public ZP_Fw_PlayerZombieVision(pPlayer) {
  PlayAmbient(pPlayer);
}

public OnPlayerSpawn_Post(pPlayer) {
  UpdatePlayerCharacter(pPlayer);
  UpdatePlayerModel(pPlayer);

  remove_task(TASKID_AMBIENT + pPlayer);
  set_task(0.1, "Task_Ambient", TASKID_AMBIENT + pPlayer);

  return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
  PlayVoiceFromCharacterData(pPlayer, ZP_Player_IsZombie(pPlayer) ? Character_ZombieDeathSounds : Character_HumanDeathSounds);
  return HAM_HANDLED;
}

public OnKnifeDeploy_Post(pKnife) {
  if (CW_GetHandlerByEntity(pKnife) == g_iCwSwipeHandler) {
    new pPlayer = CW_GetPlayer(pKnife);
    if (g_iPlayerCharacter[pPlayer] == -1) {
      return HAM_IGNORED;
    }

    static szModel[64];
    ArrayGetString(Array:g_irgCharactersData[Character_SwipeModel], g_iPlayerCharacter[pPlayer], szModel, charsmax(szModel));

    set_pev(pPlayer, pev_viewmodel2, szModel);
  }

  return HAM_HANDLED;
}

public OnSetClientKeyValue(pPlayer, const szInfoBuffer[], const szKey[], const szValue[]) {
  if(equal(szKey, "model")) {
    UpdatePlayerModel(pPlayer);
    return FMRES_SUPERCEDE;
  }

  return FMRES_IGNORED;
}

public Task_Ambient(iTaskId) {
  new pPlayer = iTaskId - TASKID_AMBIENT;
  PlayAmbient(pPlayer);
  set_task(random_float(10.0, 30.0), "Task_Ambient", TASKID_AMBIENT + pPlayer);
}

UpdatePlayerModel(pPlayer) {
  static szPlayerModel[PATH_MAX_LEN];

  if (g_iPlayerCharacter[pPlayer] != -1) {
    ArrayGetString(Array:g_irgCharactersData[ZP_Player_IsZombie(pPlayer) ? Character_ZombieModel : Character_HumanModel], g_iPlayerCharacter[pPlayer], szPlayerModel, charsmax(szPlayerModel));
  } else {
    copy(szPlayerModel, charsmax(szPlayerModel), DEFAULT_PLAYER_MODEL);
  }

  new iModelIndex = engfunc(EngFunc_ModelIndex, szPlayerModel);

  set_user_info(pPlayer, "model", "");
  set_pev(pPlayer, pev_modelindex, iModelIndex);
  set_member(pPlayer, m_modelIndexPlayer, iModelIndex);
}

UpdatePlayerCharacter(pPlayer, bool:bOverride = false) {
  if (!g_iCharacterCount) {
    return;
  }

  static szCharacter[16];
  get_user_info(pPlayer, CHARACTER_KEY, szCharacter, charsmax(szCharacter));

  new iCharacter;
  if (!TrieGetCell(g_iCharactersMap, szCharacter, iCharacter)) {
    if (!bOverride) {
      return;
    }

    iCharacter = random(g_iCharacterCount);
  }

  g_iPlayerCharacter[pPlayer] = iCharacter;
}

PlayAmbient(pPlayer) {
  if (!is_user_alive(pPlayer)) {
    return;
  }

  if (ZP_Player_IsZombie(pPlayer)) {
    PlayVoiceFromCharacterData(pPlayer, Character_ZombieAmbientSounds);
    return;
  }
}

PlayVoiceFromCharacterData(pPlayer, iCharacterData) {
  if (g_iPlayerCharacter[pPlayer] == -1) {
    return;
  }

  new Array:irgSounds = ArrayGetCell(Array:g_irgCharactersData[iCharacterData], g_iPlayerCharacter[pPlayer]);

  static szSound[PATH_MAX_LEN];
  ArrayGetString(irgSounds, random(ArraySize(irgSounds)), szSound, charsmax(szSound));
  emit_sound(pPlayer, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

CreateCharacter() {
  new iCharacter = g_iCharacterCount;

  for (new i = 0; i < sizeof(g_irgCharactersData); ++i)  {
    ArrayPushCell(g_irgCharactersData[i], 0);
  }

  ArraySetCell(Array:g_irgCharactersData[Character_HumanDeathSounds], iCharacter, ArrayCreate(PATH_MAX_LEN, RESERVED_SOUND_COUNT));
  ArraySetCell(Array:g_irgCharactersData[Character_PanicSounds], iCharacter, ArrayCreate(PATH_MAX_LEN, RESERVED_SOUND_COUNT));
  ArraySetCell(Array:g_irgCharactersData[Character_ZombieAmbientSounds], iCharacter, ArrayCreate(PATH_MAX_LEN, RESERVED_SOUND_COUNT));
  ArraySetCell(Array:g_irgCharactersData[Character_ZombieDeathSounds], iCharacter, ArrayCreate(PATH_MAX_LEN, RESERVED_SOUND_COUNT));

  g_iCharacterCount++;

  return iCharacter;
}

DestroyCharacter(iCharacter) {
  new Array:irgHumanDeathSounds = ArrayGetCell(Array:g_irgCharactersData[Character_HumanDeathSounds], iCharacter);
  ArrayDestroy(irgHumanDeathSounds);

  new Array:irgPanicSoundsSounds = ArrayGetCell(Array:g_irgCharactersData[Character_PanicSounds], iCharacter);
  ArrayDestroy(irgPanicSoundsSounds);

  new Array:irgZombieAmbientSounds = ArrayGetCell(Array:g_irgCharactersData[Character_ZombieAmbientSounds], iCharacter);
  ArrayDestroy(irgZombieAmbientSounds);

  new Array:irgZombieDeathSounds = ArrayGetCell(Array:g_irgCharactersData[Character_ZombieDeathSounds], iCharacter);
  ArrayDestroy(irgZombieDeathSounds);
}

LoadCharacters() {
  new szFileName[32];

  new FileType:iFileType;
  new iDir = open_dir(g_szCharacterDir, szFileName, charsmax(szFileName), iFileType);

  if (!iDir) {
    return;
  }

  do {
    if (iFileType != FileType_File) {
      continue;
    }

    new iLen = strlen(szFileName);
    if (iLen > 5 && equal(szFileName[iLen - 5], ".json")) {
      new szName[16];
      copy(szName, iLen - 5, szFileName);
      LoadCharacter(szName);
      log_amx("Character %s loaded.", szName);
    }

  } while (next_file(iDir, szFileName, charsmax(szFileName), iFileType));

  close_dir(iDir);
}

LoadCharacter(const szName[]) {
  new szFilePath[PATH_MAX_LEN];
  format(szFilePath, charsmax(szFilePath), "%s/%s.json", g_szCharacterDir, szName);

  new iCharacter = CreateCharacter();
  TrieSetCell(g_iCharactersMap, szName, iCharacter);

  new JSON:iDoc = json_parse(szFilePath, true);

  new JSON:iModelsDoc = json_object_get_value(iDoc, "models");
  new JSON:iSoundsDoc = json_object_get_value(iDoc, "sounds");

  new JSON:iPanicSoundDoc = json_object_get_value(iSoundsDoc, "human.panic", true);
  new JSON:iHumanDeathSoundsDoc = json_object_get_value(iSoundsDoc, "human.death", true);
  new JSON:iZombieAmbientSoundsDoc = json_object_get_value(iSoundsDoc, "zombie.ambient", true);
  new JSON:iZombieDeathSoundsDoc = json_object_get_value(iSoundsDoc, "zombie.death", true);

  new szBuffer[PATH_MAX_LEN];

  json_object_get_string(iModelsDoc, "human", szBuffer, charsmax(szBuffer));
  ArraySetString(Array:g_irgCharactersData[Character_HumanModel], iCharacter, szBuffer);
  precache_model(szBuffer);

  json_object_get_string(iModelsDoc, "zombie", szBuffer, charsmax(szBuffer));
  ArraySetString(Array:g_irgCharactersData[Character_ZombieModel], iCharacter, szBuffer);
  precache_model(szBuffer);

  json_object_get_string(iModelsDoc, "swipe", szBuffer, charsmax(szBuffer));
  ArraySetString(Array:g_irgCharactersData[Character_SwipeModel], iCharacter, szBuffer);
  precache_model(szBuffer);

  new Array:irgHumanDeathSounds = ArrayGetCell(Array:g_irgCharactersData[Character_HumanDeathSounds], iCharacter);
  for (new i = 0; i < json_array_get_count(iHumanDeathSoundsDoc); ++i) {
    json_array_get_string(iHumanDeathSoundsDoc, i, szBuffer, charsmax(szBuffer));
    ArrayPushString(irgHumanDeathSounds, szBuffer);
    precache_sound(szBuffer);
  }

  new Array:irgPanicSounds = ArrayGetCell(Array:g_irgCharactersData[Character_PanicSounds], iCharacter);
  for (new i = 0; i < json_array_get_count(iPanicSoundDoc); ++i) {
    json_array_get_string(iPanicSoundDoc, i, szBuffer, charsmax(szBuffer));
    ArrayPushString(irgPanicSounds, szBuffer);
    precache_sound(szBuffer);
  }

  new Array:irgAmbientSounds = ArrayGetCell(Array:g_irgCharactersData[Character_ZombieAmbientSounds], iCharacter);
  for (new i = 0; i < json_array_get_count(iZombieAmbientSoundsDoc); ++i) {
    json_array_get_string(iZombieAmbientSoundsDoc, i, szBuffer, charsmax(szBuffer));
    ArrayPushString(irgAmbientSounds, szBuffer);
    precache_sound(szBuffer);
  }

  new Array:irgZombieDeathSounds = ArrayGetCell(Array:g_irgCharactersData[Character_ZombieDeathSounds], iCharacter);
  for (new i = 0; i < json_array_get_count(iZombieDeathSoundsDoc); ++i) {
    json_array_get_string(iZombieDeathSoundsDoc, i, szBuffer, charsmax(szBuffer));
    ArrayPushString(irgZombieDeathSounds, szBuffer);
    precache_sound(szBuffer);
  }

  return iCharacter;
}

InitializeCharactersStore() {
  g_iCharactersMap = TrieCreate();

  g_irgCharactersData[Character_HumanModel] = ArrayCreate(PATH_MAX_LEN, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_ZombieModel] = ArrayCreate(PATH_MAX_LEN, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_SwipeModel] = ArrayCreate(PATH_MAX_LEN, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_HumanDeathSounds] = ArrayCreate(1, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_PanicSounds] = ArrayCreate(1, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_ZombieAmbientSounds] = ArrayCreate(1, RESERVED_CHARACTER_COUNT);
  g_irgCharactersData[Character_ZombieDeathSounds] = ArrayCreate(1, RESERVED_CHARACTER_COUNT);
}

DestroyCharactersStore() {
  for (new iCharacter; iCharacter < g_iCharacterCount; ++iCharacter) {
    DestroyCharacter(iCharacter);
  }

  TrieDestroy(g_iCharactersMap);

  ArrayDestroy(Array:g_irgCharactersData[Character_HumanModel]);
  ArrayDestroy(Array:g_irgCharactersData[Character_ZombieModel]);
  ArrayDestroy(Array:g_irgCharactersData[Character_SwipeModel]);
  ArrayDestroy(Array:g_irgCharactersData[Character_HumanDeathSounds]);
  ArrayDestroy(Array:g_irgCharactersData[Character_PanicSounds]);
  ArrayDestroy(Array:g_irgCharactersData[Character_ZombieAmbientSounds]);
  ArrayDestroy(Array:g_irgCharactersData[Character_ZombieDeathSounds]);
}
