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

#define WEAPON_NAME WEAPON(Shotgun)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_szShellModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPumpSound[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(ShotgunShell), g_szShellModel, charsmax(g_szShellModel));

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(ShotgunView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(ShotgunPlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Shotgun), g_szWorldModel, charsmax(g_szWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ShotgunShot));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ShotgunPump), g_szPumpSound, charsmax(g_szPumpSound));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(ShotgunReload));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Reload, "@Weapon_Reload");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PumpSound, "@Weapon_PumpSound");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");

  CW_RegisterClassMethod(WEAPON_NAME, WEAPON_BASE_METHOD(Unload), "@Weapon_Unload");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Shotgun), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Shotgun));
  CW_SetMember(this, CW_Member_iMaxClip, 6);
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Shotgun));
  CW_SetMember(this, CW_Member_iMaxPrimaryAmmo, 24);
  CW_SetMember(this, CW_Member_iSlot, 0);
  CW_SetMember(this, CW_Member_iPosition, 2);
  CW_SetMemberString(this, CW_Member_szIcon, "m3");
  CW_SetMember(this, CW_Member_iWeight, 20);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flShotgunWeight)));
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 4, "shotgun");
  Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(ShotgunPump));
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iRandomSeed; iRandomSeed = get_ent_data(pPlayer, "CBasePlayer", "random_seed");
  static Float:flRand; flRand = SharedRandomFloat(iRandomSeed, 0.0, 1.0);

  CW_CallNativeMethod(this, CW_Method_DefaultShotgunIdle, flRand > 0.96 ? 0 : 7, 4, (flRand > 0.96 ? (18.0 / 3.0) : (18.0 / 2.0)), 1.5, g_szPumpSound);
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static iShotsFired; iShotsFired = CW_GetMember(this, CW_Member_iShotsFired);
  if (iShotsFired > 0) return;

  static Float:vecSpread[3]; UTIL_CalculateWeaponSpread(this, UTIL_GetConeVector(8.0), iShotsFired, 1.1125, 1.0, 0.95, 2.0, vecSpread);

  if (CW_CallNativeMethod(this, CW_Method_DefaultShotgunShot, 6.0, 0.9, 0.9, 0.5, vecSpread, 25)) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 1.5);
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
    Asset_EmitSound(pPlayer, CHAN_WEAPON, ASSET_LIBRARY, ASSET_SOUND(ShotgunShot));
    
    set_pev(pPlayer, pev_punchangle, Float:{-5.0, 0.0, 0.0});

    CW_CallNativeMethod(this, CW_Method_EjectBrass, engfunc(EngFunc_ModelIndex, g_szShellModel), 2);
  }
}

@Weapon_Reload(const this) {
  CW_CallBaseMethod();

  if (CW_CallNativeMethod(this, CW_Method_DefaultShotgunReload, 5, 3, 0.6, 0.5)) {
    new flInSpecialReload = CW_GetMember(this, CW_Member_bInSpecialReload);

    if (flInSpecialReload == 2) {
      static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
      Asset_EmitSound(pPlayer, CHAN_WEAPON, ASSET_LIBRARY, ASSET_SOUND(ShotgunReload));
    }
  }
}

@Weapon_Unload(const this) {
  CW_CallBaseMethod();

  CW_CallMethod(this, WEAPON_BASE_METHOD(DefaultUnload), 1, 8, 0.65);
  CW_CallNativeMethod(this, CW_Method_PumpSound);
  CW_SetMember(this, CW_Member_bInReload, false);
}

@Weapon_PumpSound(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(ShotgunPump), .iPitch = 92 + random(0x10));
}
