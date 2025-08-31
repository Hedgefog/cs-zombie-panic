#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <combat_util>
#include <shared_random>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Magnum)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_szShellModel[MAX_RESOURCE_PATH_LENGTH];
new g_rgszShotSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iShotSoundsNum = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Shell), g_szShellModel, charsmax(g_szShellModel));

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(MagnumView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(MagnumPlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Magnum), g_szWorldModel, charsmax(g_szWorldModel));

  g_iShotSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(MagnumShot), g_rgszShotSounds, sizeof(g_rgszShotSounds), charsmax(g_rgszShotSounds[]));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Allocate, "@Weapon_Allocate");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Reload, "@Weapon_Reload");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Holster, "@Weapon_Holster");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_CompleteReload, "@Weapon_CompleteReload");

  CW_RegisterClassMethod(WEAPON_NAME, WEAPON_BASE_METHOD(Unload), "@Weapon_Unload");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Magnum), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Magnum));
  CW_SetMember(this, CW_Member_iMaxClip, 6);
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Magnum));
  CW_SetMember(this, CW_Member_iMaxPrimaryAmmo, 24);
  CW_SetMember(this, CW_Member_iSlot, 1);
  CW_SetMember(this, CW_Member_iPosition, 1);
  CW_SetMemberString(this, CW_Member_szIcon, "fiveseven");
  CW_SetMember(this, CW_Member_iWeight, 10);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flMagnumWeight)));
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 5, "onehanded");
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iRandomSeed; iRandomSeed = get_ent_data(pPlayer, "CBasePlayer", "random_seed");
  static Float:flRand; flRand = SharedRandomFloat(iRandomSeed, 0.0, 1.0);
  
  if (flRand < 0.5) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 71.0 / 30.0);
  } else if (flRand < 0.7) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 6, 71.0 / 30.0);
  } else if (flRand < 0.9) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 7, 89.0 / 30.0);
  } else {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 171.0 / 30.0);
  }
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return;

  static Float:vecSpread[3]; UTIL_CalculateWeaponSpread(this, UTIL_GetConeVector(1.0), iShotsFired, 2.5, 1.0, 0.95, 7.5, vecSpread);

  if (CW_CallNativeMethod(this, CW_Method_DefaultShot, 80.0, 0.9, 0.5, vecSpread, 1)) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 1.03);
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
    emit_sound(pPlayer, CHAN_WEAPON, g_rgszShotSounds[random(g_iShotSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    static Float:vecPunchAngle[3];
    pev(pPlayer, pev_punchangle, vecPunchAngle);
    xs_vec_add(vecPunchAngle, Float:{-8.0, 0.0, 0.0}, vecPunchAngle);

    if (xs_vec_len(vecPunchAngle) > 0.0) {
      set_pev(pPlayer, pev_punchangle, vecPunchAngle);
    }
  }
}

@Weapon_Reload(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_DefaultReload, 3, 2.5);
}

@Weapon_Unload(const this) {
  CW_CallBaseMethod();

  CW_CallMethod(this, WEAPON_BASE_METHOD(DefaultUnload), CW_GetMember(this, CW_Member_iClip), 3, 2.5);
}

@Weapon_Holster(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 4, 16.0 / 30.0);
}

@Weapon_CompleteReload(const this) {
  static const iLifeTime = 100;

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iClip; iClip = CW_GetMember(this, CW_Member_iClip);
  static iModelIndex; iModelIndex = engfunc(EngFunc_ModelIndex, g_szShellModel);
  static iRandomSeed; iRandomSeed = get_ent_data(pPlayer, "CBasePlayer", "random_seed");

  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);

  for (new i = 0; i < CW_GetMember(this, CW_Member_iMaxClip) - iClip; ++i) {
    engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_MODEL);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    engfunc(EngFunc_WriteCoord, SharedRandomFloat(iRandomSeed, 8.0, 32.0));
    engfunc(EngFunc_WriteCoord, SharedRandomFloat(iRandomSeed, 8.0, 32.0));
    engfunc(EngFunc_WriteCoord, 0.0);
    write_angle(0);
    write_short(iModelIndex);
    write_byte(1);
    write_byte(iLifeTime);
    message_end();
  }
  
  CW_CallBaseMethod();
}
