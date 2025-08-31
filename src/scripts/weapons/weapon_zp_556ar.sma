#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Rifle)

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

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(RifleView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(RiflePlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Rifle), g_szWorldModel, charsmax(g_szWorldModel));

  g_iShotSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(RifleShot), g_rgszShotSounds, sizeof(g_rgszShotSounds), charsmax(g_rgszShotSounds[]));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Allocate, "@Weapon_Allocate");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Reload, "@Weapon_Reload");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Holster, "@Weapon_Holster");

  CW_RegisterClassMethod(WEAPON_NAME, WEAPON_BASE_METHOD(Unload), "@Weapon_Unload");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Rifle), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Rifle));
  CW_SetMember(this, CW_Member_iMaxClip, 30);
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Rifle));
  CW_SetMember(this, CW_Member_iMaxPrimaryAmmo, 90);
  CW_SetMember(this, CW_Member_iSlot, 0);
  CW_SetMember(this, CW_Member_iPosition, 1);
  CW_SetMemberString(this, CW_Member_szIcon, "m4a1");
  CW_SetMember(this, CW_Member_iWeight, 25);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flRifleWeight)));
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  switch (random(2)) {
    case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 41.0 / 8.0);
    case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 111.0 / 35.0);
  }
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);

  static Float:vecSpread[3]; UTIL_CalculateWeaponSpread(this, UTIL_GetConeVector(4.0), iShotsFired, 1.1125, 0.5, 0.95, 3.5, vecSpread);

  if (CW_CallNativeMethod(this, CW_Method_DefaultShot, 26.0, 0.85, 0.095, vecSpread, 1)) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 5 + random(3), 0.7);
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
    emit_sound(pPlayer, CHAN_WEAPON, g_rgszShotSounds[random(g_iShotSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    static Float:vecPunchAngle[3];
    pev(pPlayer, pev_punchangle, vecPunchAngle);
    xs_vec_add(vecPunchAngle, Float:{-1.75, 0.0, 0.0}, vecPunchAngle);

    if (xs_vec_len(vecPunchAngle) > 0.0) {
      set_pev(pPlayer, pev_punchangle, vecPunchAngle);
    }

    CW_CallNativeMethod(this, CW_Method_EjectBrass, engfunc(EngFunc_ModelIndex, g_szShellModel), 1);
  }
}

@Weapon_Reload(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_DefaultReload, 3, 1.57);
}

@Weapon_Unload(const this) {
  CW_CallBaseMethod();

  CW_CallMethod(this, WEAPON_BASE_METHOD(DefaultUnload), CW_GetMember(this, CW_Member_iClip), 3, 1.57);
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 4, "rifle");
}

@Weapon_Holster(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 8, 12.0 / 30.0);
}
