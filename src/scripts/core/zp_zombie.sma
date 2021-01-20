#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Zombie"
#define AUTHOR "Hedgehog Fog"

#define TASKID_AMBIENT 100

new const g_rgszPickupEntities[][] = {
  "armoury_entity",
  "item_battery",
  "item_healthkit",
  "armoury_entity",
  "weaponbox",
  "weapon_shield",
  "grenade"
};

public plugin_precache() {
    for (new i = 0; i < sizeof(ZP_ZOMBIE_DEATH_SOUNDS); ++i) {
      precache_sound(ZP_ZOMBIE_DEATH_SOUNDS[i]);
    }

    for (new i = 0; i < sizeof(ZP_ZOMBIE_AMBIENT_SOUNDS); ++i) {
      precache_sound(ZP_ZOMBIE_AMBIENT_SOUNDS[i]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Item_PreFrame, "player", "OnPlayerItemPreFrame_Post", .Post = 1);
    RegisterHam(Ham_TakeDamage, "player", "OnPlayerTakeDamage", .Post = 0);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);

    RegisterHam(Ham_Use, "func_button", "OnButtonUse", .Post = 0);

    for (new i = 0; i < sizeof(g_rgszPickupEntities); ++i) {
      RegisterHam(Ham_Touch, g_rgszPickupEntities[i], "OnItemTouch", .Post = 0);
    }
}

public plugin_natives() {
  register_native("ZP_Player_IsZombie", "Native_IsPlayerZombie");
  register_native("ZP_Player_PlayZombieAmbient", "Native_PlayAmbient");
}

public bool:Native_IsPlayerZombie(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  return IsPlayerZombie(pPlayer);
}

public Native_PlayAmbient(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  if (!ZP_Player_IsZombie(pPlayer)) {
    return;
  }

  PlayAmbient(pPlayer);
}

public OnButtonUse(pEntity, pToucher) {
  if (!UTIL_IsPlayer(pToucher)) {
    return HAM_IGNORED;
  }

  if (!ZP_Player_IsZombie(pToucher)) {
    return HAM_IGNORED;
  }

  PlayAmbient(pToucher);

  return HAM_SUPERCEDE;
}

public OnPlayerSpawn_Post(pPlayer) {
  if (!is_user_alive(pPlayer)) {
    return HAM_IGNORED;
  }

  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  SetPlayerZombie(pPlayer);
  emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return HAM_HANDLED;
}

public OnPlayerKilled_Post(pPlayer) {
  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  emit_sound(pPlayer, CHAN_VOICE, ZP_ZOMBIE_DEATH_SOUNDS[random(sizeof(ZP_ZOMBIE_DEATH_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  return HAM_HANDLED;
}

public OnPlayerTakeDamage(pPlayer, iInflictor, iAttacker, Float:flDamage, iDamageBits) {
  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  if (iDamageBits & DMG_FALL) {
    return HAM_SUPERCEDE;
  }

  return HAM_HANDLED;
}

public OnPlayerItemPreFrame_Post(pPlayer) {
  if (!ZP_Player_IsZombie(pPlayer)) {
    return HAM_IGNORED;
  }

  new pActiveItem = get_member(pPlayer, m_pActiveItem);
  if (pActiveItem != -1 && pev_valid(pActiveItem)) {
    if (ExecuteHamB(Ham_CS_Item_CanDrop, pActiveItem)) {
      client_cmd(pPlayer, "drop");
      client_cmd(pPlayer, ZP_WEAPON_SWIPE);
    }
  }

  return HAM_HANDLED;
}

public OnItemTouch(pEntity, pToucher) {
  if (!UTIL_IsPlayer(pToucher)) {
    return HAM_IGNORED;
  }

  if (!ZP_Player_IsZombie(pToucher)) {
    return HAM_IGNORED;
  }

  return HAM_SUPERCEDE;
}

bool:IsPlayerZombie(pPlayer) {
  return get_member(pPlayer, m_iTeam) == ZP_ZOMBIE_TEAM;
}

SetPlayerZombie(pPlayer) {
  set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
  set_task(0.1, "TaskAmbient", TASKID_AMBIENT + pPlayer);
}

public TaskAmbient(iTaskId) {
  new pPlayer = iTaskId - TASKID_AMBIENT;
  
  if (!is_user_alive(pPlayer)) {
    return;
  }

  if (!ZP_Player_IsZombie(pPlayer)) {
    return;
  }

  if (random(100) < 50) {
    PlayAmbient(pPlayer);
  }

  set_task(random_float(10.0, 20.0), "TaskAmbient", TASKID_AMBIENT + pPlayer);
}

PlayAmbient(pPlayer) {
  emit_sound(pPlayer, CHAN_VOICE, ZP_ZOMBIE_AMBIENT_SOUNDS[random(sizeof(ZP_ZOMBIE_AMBIENT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
