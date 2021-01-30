#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Crowbar"
#define AUTHOR "Hedgehog Fog"

#define SWIPE_MODEL "swipe.mdl"
#define PRIMARY_AMMO_ID 13

new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_SWIPE_HUD_TXT);

    for (new i = 0; i < sizeof(ZP_WEAPON_SWIPE_MISS_SOUNDS); ++i) {
      precache_sound(ZP_WEAPON_SWIPE_MISS_SOUNDS[i]);
    }

    for (new i = 0; i < sizeof(ZP_WEAPON_SWIPE_HIT_SOUNDS); ++i) {
      precache_sound(ZP_WEAPON_SWIPE_HIT_SOUNDS[i]);
    }

    g_iCwHandler = CW_Register(ZP_WEAPON_SWIPE, CSW_KNIFE, WEAPON_NOCLIP, PRIMARY_AMMO_ID, -1, _, _, 2, 0);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_TraceAttack, "player", "OnPlayerTraceAttack", .Post = 0);
  RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
  RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
}

public @Weapon_PrimaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);

  if (random(2) == 0) {
    set_member(pPlayer, m_szAnimExtention, "grenade");
  } else {
    set_member(pPlayer, m_szAnimExtention, "shieldgren");
  }

  new pHit = CW_DefaultSwing(this, 25.0, 0.5, 36.0);

  if (pHit < 0) {
    switch (random(3)) {
      case 0: CW_PlayAnimation(this, 4, 11.0 / 22.0);
      case 1: CW_PlayAnimation(this, 5, 14.0 / 22.0);
      case 2: CW_PlayAnimation(this, 7, 19.0 / 24.0);
    }

    emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SWIPE_MISS_SOUNDS[random(sizeof(ZP_WEAPON_SWIPE_MISS_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  } else {
    switch (random(3)) {
      case 0: CW_PlayAnimation(this, 3, 11.0 / 22.0);
      case 1: CW_PlayAnimation(this, 6, 14.0 / 22.0);
      case 2: CW_PlayAnimation(this, 8, 19.0 / 24.0);
    }

    emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SWIPE_HIT_SOUNDS[random(sizeof(ZP_WEAPON_SWIPE_HIT_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }

  set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
}

public @Weapon_SecondaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);
  if (is_user_bot(pPlayer)) {
    CW_PrimaryAttack(this);
  }
}

public @Weapon_Deploy(this) {
  CW_DefaultDeploy(this, NULL_STRING, NULL_STRING, 1, "dualpistols");
}

public @Weapon_Idle(this) {
  new pPlayer = CW_GetPlayer(this);
  set_member(pPlayer, m_szAnimExtention, "dualpistols");

  switch (random(3)) {
    case 0: {
      CW_PlayAnimation(this, 0, 36.0 / 13.0);
    }
    case 1: {
      CW_PlayAnimation(this, 9, 61.0 / 15.0);
    }
    case 2: {
      CW_PlayAnimation(this, 10, 61.0 / 15.0);
    }
  }
}

public Float:@Weapon_GetMaxSpeed(this) {
  return ZP_ZOMBIE_SPEED;
}

public @Weapon_CanDrop(this) {
  return PLUGIN_HANDLED;
}

public OnPlayerKilled_Post() {
  UpdateZombieLives();
  return HAM_HANDLED;
}

public OnPlayerSpawn_Post(pPlayer) {
  UpdateZombieLives();
  UpdatePlayerZombieLives(pPlayer);
  return HAM_HANDLED;
}

public OnPlayerTraceAttack(this, pAttacker, Float:flDamage, Float:vecDir[3], pTr, iDamageBits) {
  if (!UTIL_IsPlayer(pAttacker)) {
    return HAM_IGNORED;
  }

  new pItem = get_member(pAttacker, m_pActiveItem);
  if (CW_GetHandlerByEntity(pItem) != g_iCwHandler) {
    return HAM_IGNORED;
  }

  set_tr2(pTr, TR_iHitgroup, get_tr2(pTr, TR_iHitgroup) & ~HIT_HEAD);

  return HAM_HANDLED;
}

UpdateZombieLives() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) {
      continue;
    }

    if (!is_user_alive(pPlayer)) {
      continue;
    }

    if (!ZP_Player_IsZombie(pPlayer)) {
      continue;
    }

    UpdatePlayerZombieLives(pPlayer);
  }
}

UpdatePlayerZombieLives(pPlayer) {
  message_begin(MSG_ONE, get_user_msgid("AmmoX"), _, pPlayer);
  write_byte(PRIMARY_AMMO_ID);
  write_byte(ZP_GameRules_GetZombieLives());
  message_end();
}

