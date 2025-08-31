#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Pistol)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_szShotSound[MAX_RESOURCE_PATH_LENGTH];
new g_szShellModel[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Shell), g_szShellModel, charsmax(g_szShellModel));

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(PistolView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(PistolPlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Pistol), g_szWorldModel, charsmax(g_szWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(PistolShot), g_szShotSound, charsmax(g_szShotSound));

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
  register_plugin(WEAPON_PLUGIN(Pistol), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Allocate(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Pistol));
  CW_SetMember(this, CW_Member_iMaxClip, 7);
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Pistol));
  CW_SetMember(this, CW_Member_iSlot, 1);
  CW_SetMember(this, CW_Member_iPosition, 0);
  CW_SetMemberString(this, CW_Member_szIcon, "fiveseven");
  CW_SetMember(this, CW_Member_iWeight, 5);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flPistolWeight)));
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  switch (random(3)) {
    case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 61.0 / 16.0);
    case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 61.0 / 16.0);
    case 2: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 61.0 / 14.0);
  }
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return;

  static Float:vecSpread[3]; UTIL_CalculateWeaponSpread(this, UTIL_GetConeVector(3.0), iShotsFired, 3.0, 0.1, 0.95, 3.5, vecSpread);

  if (CW_CallNativeMethod(this, CW_Method_DefaultShot, 30.0, 0.75, 0.125, vecSpread, 1)) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3, 0.71);
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
    emit_sound(pPlayer, CHAN_WEAPON, g_szShotSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    static Float:vecPunchAngle[3];
    pev(pPlayer, pev_punchangle, vecPunchAngle);
    xs_vec_add(vecPunchAngle, Float:{-2.5, 0.0, 0.0}, vecPunchAngle);

    if (xs_vec_len(vecPunchAngle) > 0.0) {
      set_pev(pPlayer, pev_punchangle, vecPunchAngle);
    }

    CW_CallNativeMethod(this, CW_Method_EjectBrass, engfunc(EngFunc_ModelIndex, g_szShellModel), 1);
  }
}

@Weapon_Reload(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_DefaultReload, 5, 1.68);
}

@Weapon_Unload(const this) {
  CW_CallBaseMethod();

  CW_CallMethod(this, WEAPON_BASE_METHOD(DefaultUnload), CW_GetMember(this, CW_Member_iClip), 5, 1.68);
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 7, "onehanded");
}

@Weapon_Holster(const this) {
  CW_CallBaseMethod();
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 8, 16.0 / 20.0);
}
