#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Panic"
#define AUTHOR "Hedgehog Fog"

#define PANIC_DURATION 5.0
#define PANIC_DELAY 60.0

new bool:g_bPlayerPanic[MAX_PLAYERS + 1];
new Float:g_flPlayerLastPanic[MAX_PLAYERS + 1];

public plugin_precache() {
  for (new i = 0; i < sizeof(ZP_PANIC_SOUNDS); ++i) {
    precache_sound(ZP_PANIC_SOUNDS[i]);
  }
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_Touch, "weaponbox", "OnItemTouch", .Post = 0);
  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
}

public plugin_natives() {
  register_native("ZP_Player_Panic", "Native_Panic");
  register_native("ZP_Player_InPanic", "Native_InPanic");
}

public bool:Native_Panic(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  return Panic(pPlayer);
}

public bool:Native_InPanic(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  return g_bPlayerPanic[pPlayer];
}

public OnItemTouch(pItem, pToucher) {
  if (!UTIL_IsPlayer(pToucher)) {
    return HAM_IGNORED;
  }

  if (!g_bPlayerPanic[pToucher]) {
    return HAM_IGNORED;
  }

  return HAM_SUPERCEDE;
}

public OnPlayerSpawn_Post(pPlayer) {
  g_flPlayerLastPanic[pPlayer] = -PANIC_DELAY;
}

bool:Panic(pPlayer) {
  if (g_bPlayerPanic[pPlayer]) {
    return false;
  }
  
  if (get_gametime() - g_flPlayerLastPanic[pPlayer] < PANIC_DELAY) {
    return false;
  }

  ZP_Player_DropBackpack(pPlayer);
  emit_sound(pPlayer, CHAN_VOICE, ZP_PANIC_SOUNDS[random(sizeof(ZP_PANIC_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  g_bPlayerPanic[pPlayer] = true;

  set_task(PANIC_DURATION, "TaskEndPanic", pPlayer);
  ZP_Player_UpdateSpeed(pPlayer);

  return true;
}

public TaskEndPanic(iTaskId) {
  new pPlayer = iTaskId;

  g_bPlayerPanic[pPlayer] = false;
  g_flPlayerLastPanic[pPlayer] = get_gametime();
  ZP_Player_UpdateSpeed(pPlayer);
}
