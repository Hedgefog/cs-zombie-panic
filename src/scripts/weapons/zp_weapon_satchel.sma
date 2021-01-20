#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <api_rounds>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Crowbar"
#define AUTHOR "Hedgehog Fog"

new const g_rgszBounceSounds[][] = {
  "weapons/g_bounce1.wav",
  "weapons/g_bounce2.wav",
  "weapons/g_bounce3.wav"
};

new bool:g_bPlayerChargeReady[MAX_PLAYERS + 1];
new bool:g_bPlayerRedeploy[MAX_PLAYERS + 1];
new g_iAmmoId;

new CW:g_iCwHandler;

public plugin_precache() {
  precache_generic(ZP_WEAPON_SATCHEL_HUD_TXT);

  precache_model(ZP_WEAPON_SATCHEL_V_MODEL);
  precache_model(ZP_WEAPON_SATCHEL_P_MODEL);
  precache_model(ZP_WEAPON_SATCHEL_W_MODEL);
  precache_model(ZP_WEAPON_SATCHELRADIO_V_MODEL);
  precache_model(ZP_WEAPON_SATCHELRADIO_P_MODEL);

  for (new i = 0; i < sizeof(g_rgszBounceSounds); ++i) {
    precache_sound(g_rgszBounceSounds[i]);
  }

  g_iAmmoId = ZP_Ammo_GetId(ZP_Ammo_GetHandler("satchel"));

  g_iCwHandler = CW_Register(ZP_WEAPON_SATCHEL, CSW_C4, WEAPON_NOCLIP, g_iAmmoId, -1, 0, -1, 4, 5);
  CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
  CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_Bind(g_iCwHandler, CWB_SecondaryAttack, "@Weapon_SecondaryAttack");
  CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
  CW_Bind(g_iCwHandler, CWB_Holster, "@Weapon_Holster");
  CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
  CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
  CW_Bind(g_iCwHandler, CWB_CanDrop, "@Weapon_CanDrop");
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

  RegisterHam(Ham_Killed, "player", "OnPlayerKilled_Post", .Post = 1);
}

public @Weapon_PrimaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);

  if (g_bPlayerChargeReady[pPlayer]) {
      Detonate(this);
  } else {
      if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
        return;
      }

      Throw(this);
  }

  CW_PlayAnimation(this, 3, 0.53);
  set_member(this, m_Weapon_flNextPrimaryAttack, 0.53);
  set_member(this, m_Weapon_flNextSecondaryAttack, 0.53);
  g_bPlayerRedeploy[pPlayer] = true;
}

public @Weapon_SecondaryAttack(this) {
  new pPlayer = CW_GetPlayer(this);

  if (!g_bPlayerChargeReady[pPlayer]) {
    return;
  }

  if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
    return;
  }

  Throw(this);
  set_member(this, m_Weapon_flNextPrimaryAttack, 0.53);
  set_member(this, m_Weapon_flNextSecondaryAttack, 0.53);
}

public @Weapon_Deploy(this) {
  new pPlayer = CW_GetPlayer(this);

  if (g_bPlayerChargeReady[pPlayer] || get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0) {
    CW_DefaultDeploy(this, ZP_WEAPON_SATCHELRADIO_V_MODEL, ZP_WEAPON_SATCHELRADIO_P_MODEL, 1, "grenade");
  } else {
    CW_DefaultDeploy(this, ZP_WEAPON_SATCHEL_V_MODEL, ZP_WEAPON_SATCHEL_P_MODEL, 1, "grenade");
  }
}

public @Weapon_Holster(this) {
  new pPlayer = CW_GetPlayer(this);
  if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0 && !g_bPlayerChargeReady[pPlayer]) {
    SetThink(this, "RemovePlayerItem");
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
  }
}

public RemovePlayerItem(this) {
  CW_RemovePlayerItem(this);
}

public Float:@Weapon_GetMaxSpeed(this) {
  return ZP_HUMAN_SPEED - 10.0;
}

public @Weapon_Idle(this) {
  new pPlayer = CW_GetPlayer(this);
  if (g_bPlayerRedeploy[pPlayer]) {
    ExecuteHamB(Ham_Item_Deploy, this);
    g_bPlayerRedeploy[pPlayer] = false;
  } else {
    CW_PlayAnimation(this, 0, 5.5);

    if (get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0 && !g_bPlayerChargeReady[pPlayer]) {
      CW_RemovePlayerItem(this);
    }
  }
}

public @Weapon_Spawn(this) {
  set_member(this, m_Weapon_iDefaultAmmo, 1);
  engfunc(EngFunc_SetModel, this, ZP_WEAPON_SATCHEL_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_SATCHEL_W_MODEL);
}

public @Weapon_CanDrop(this) {
  new pPlayer = CW_GetPlayer(this);
  return get_member(pPlayer, m_rgAmmo, g_iAmmoId) <= 0 ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

Throw(this) {
  new pPlayer = CW_GetPlayer(this);
  new iAmmoAmount = get_member(pPlayer, m_rgAmmo, g_iAmmoId);

  if (iAmmoAmount > 0) {
    static Float:vecOrigin[3];
    pev(pPlayer, pev_origin, vecOrigin);

    static Float:vecAngles[3];
    pev(pPlayer, pev_v_angle, vecAngles);
  
    static Float:vecForward[3];
    angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

    static Float:vecVelocity[3];
    pev(pPlayer, pev_velocity, vecVelocity);
    for (new i = 0; i < 3; ++i) {
      vecVelocity[i] = (vecForward[i] * 274.0) + vecVelocity[i];
    }


    new pSatchelCharge = SpawnSatchelCharge();
    // new pSatchelCharge = CE_Create("zp_satchel_charge", vecOrigin);
    engfunc(EngFunc_SetOrigin, pSatchelCharge, vecOrigin);
    set_pev(pSatchelCharge, pev_velocity, vecVelocity);
    set_pev(pSatchelCharge, pev_avelocity, Float:{0.0, 100.0, 0.0});
    set_pev(pSatchelCharge, pev_owner, pPlayer);
    set_pev(pSatchelCharge, pev_team, pPlayer);

    set_member(pPlayer, m_rgAmmo, iAmmoAmount - 1, g_iAmmoId);
    rg_set_animation(pPlayer, PLAYER_ATTACK1);

    g_bPlayerChargeReady[pPlayer] = true;
  }

  ZP_Player_UpdateSpeed(pPlayer);
}

Detonate(this) {
  new pPlayer = CW_GetPlayer(this);

  new pEntity;
  while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "zp_satchel_charge")) != 0) {
    if (pev(pEntity, pev_owner) == pPlayer) {
      ExecuteHamB(Ham_Use, pEntity, pPlayer, pPlayer, USE_ON, 0.0);
      g_bPlayerChargeReady[pPlayer] = false;
    }
  }
}

SpawnSatchelCharge() {
  new pEntity = rg_create_entity("info_target");
  dllfunc(DLLFunc_Spawn, pEntity);
  
  set_pev(pEntity, pev_classname, "zp_satchel_charge");

  set_pev(pEntity, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(pEntity, pev_solid, SOLID_BBOX);

  engfunc(EngFunc_SetModel, pEntity, ZP_WEAPON_SATCHEL_W_MODEL);
  // engfunc(EngFunc_SetSize, pEntity, Float:{-8.0, -8.0, 0.0}, Float:{8.0, 8.0, 16.0});

  SetTouch(pEntity, "SatchelChargeSlide");
  SetUse(pEntity, "GrenadeDetonateUse");
  SetThink(pEntity, "SatchelChargeThink");

  set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);

  set_pev(pEntity, pev_gravity, 0.5);
  set_pev(pEntity, pev_friction, 0.8);

  set_pev(pEntity, pev_dmg, 500.0);
  set_pev(pEntity, pev_sequence, 1);
  set_pev(pEntity, pev_spawnflags, SF_DETONATE);

  return pEntity;
}

Deactivate(this) {
  set_pev(this, pev_solid, SOLID_NOT);
  set_pev(this, pev_flags, pev(this, pev_flags) | FL_KILLME);
}

DeactivateSatchels(pOwner) {
  new pEntity;
  while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", "zp_satchel_charge")) != 0) {
    if (pev(pEntity, pev_owner) == pOwner) {
      Deactivate(pEntity);
    }
  }

  g_bPlayerChargeReady[pOwner] = false;
}

public SatchelChargeSlide(pEntity) {
  set_pev(pEntity, pev_gravity, 1.0);

  static Float:vecOrigin[3];
  pev(pEntity, pev_origin, vecOrigin);

  static Float:vecVelocity[3];
  pev(pEntity, pev_velocity, vecVelocity);

  static Float:vecDown[3];
  xs_vec_copy(vecOrigin, vecDown);
  vecDown[2] -= 10.0;

  new pTr = create_tr2();
  engfunc(EngFunc_TraceLine, vecOrigin, vecDown, IGNORE_MONSTERS, pEntity, pTr);

  static Float:flFraction;
  get_tr2(pTr, TR_flFraction, flFraction);

  free_tr2(pTr);

  if (flFraction < 1.0) {
    xs_vec_mul_scalar(vecVelocity, 0.95, vecVelocity);
    set_pev(pEntity, pev_velocity, vecVelocity);

    // static Float:vecAVelocity[3];
    // pev(pEntity, pev_velocity, vecAVelocity);
    // xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
    // set_pev(pEntity, pev_avelocity, vecAVelocity);
  }

  if ((~pev(pEntity, pev_flags) & FL_ONGROUND) && xs_vec_len(vecVelocity) > 10.0) {
    emit_sound(pEntity, CHAN_VOICE, g_rgszBounceSounds[random(sizeof(g_rgszBounceSounds))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }
}

public SatchelChargeThink(pEntity) {
  if (!ExecuteHam(Ham_IsInWorld, pEntity)) {
    engfunc(EngFunc_RemoveEntity, pEntity);
    return;
  }

  static Float:vecVelocity[3];
  pev(pEntity, pev_velocity, vecVelocity);

  new iWaterLevel = pev(pEntity, pev_waterlevel);
  if (iWaterLevel == 3) {
    set_pev(pEntity, pev_movetype, MOVETYPE_FLY);

    xs_vec_mul_scalar(vecVelocity, 0.8, vecVelocity);
    vecVelocity[2] += 8.0;
    set_pev(pEntity, pev_velocity, vecVelocity);

    static Float:vecAVelocity[3];
    pev(pEntity, pev_avelocity, vecAVelocity);
    xs_vec_mul_scalar(vecAVelocity, 0.9, vecAVelocity);
    set_pev(pEntity, pev_avelocity, vecAVelocity);
  } else if (iWaterLevel == 0) {
    set_pev(pEntity, pev_movetype, MOVETYPE_BOUNCE);
  } else {
    vecVelocity[2] -= 8.0;
    set_pev(pEntity, pev_velocity, vecVelocity);
  }

  // if (!xs_vec_len_2d(vecVelocity) && (iWaterLevel || pev(pEntity, pev_flags) & FL_ONGROUND)) {
  //   set_pev(pEntity, pev_solid, SOLID_NOT);
  // }

  set_pev(pEntity, pev_nextthink, get_gametime() + 0.1);
}

public GrenadeDetonateUse(const pEntity) {
  SetThink(pEntity, "GrenadeDetonate");
  set_pev(pEntity, pev_nextthink, get_gametime());
}

public GrenadeDetonate(this) {
  new Float:flDamage;
  pev(this, pev_dmg, flDamage);

  CW_GrenadeDetonate(this, flDamage, flDamage * 0.125);
  SetThink(this, "GrenadeSmoke");
  set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public GrenadeSmoke(this) {
  CW_GrenadeSmoke(this);
  engfunc(EngFunc_RemoveEntity, this);
}

public Round_Fw_NewRound() {
  for (new pPlayer = 1; pPlayer <= MAX_PLAYERS; ++pPlayer) {
    DeactivateSatchels(pPlayer);
  }
}

public OnPlayerKilled_Post(pPlayer) {
  DeactivateSatchels(pPlayer);
}
