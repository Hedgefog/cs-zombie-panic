#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>
#include <shared_random>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Grenade)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_rgszBounceSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iBounceSoundsNum = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Grenade), g_szWorldModel, charsmax(g_szWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(GrenadeView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(GrenadePlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(GrenadeFuse));

  g_iBounceSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(GrenadeBounce), g_rgszBounceSounds, sizeof(g_rgszBounceSounds), charsmax(g_rgszBounceSounds[]));

  CW_RegisterClass(WEAPON_NAME, WEAPON(BaseGrenade));

  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_AddToPlayer, "@Weapon_AddToPlayer");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Holster, "@Weapon_Holster");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_CanDrop, "@Weapon_CanDrop");

  CW_RegisterClassMethod(WEAPON_NAME, BASEGRENADE_METHOD(Throw), "@Weapon_Throw");
  CW_RegisterClassMethod(WEAPON_NAME, BASEGRENADE_METHOD(SpawnProjectile), "@Weapon_SpawnProjectile");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Grenade), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Grenade));
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Grenade));
  CW_SetMember(this, CW_Member_iSlot, 3);
  CW_SetMember(this, CW_Member_iPosition, 0);
  CW_SetMemberString(this, CW_Member_szIcon, "handgrenade");
  CW_SetMember(this, Weapon_BaseThrowable_Member_bThrowOnHolster, true);
  CW_SetMemberString(this, WEAPON_BASE_MEMBER(szBounceSound), g_rgszBounceSounds[random(g_iBounceSoundsNum)]);
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 7, "grenade");
}

@Weapon_Holster(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  if (is_user_connected(pPlayer)) {
    emit_sound(pPlayer, CHAN_WEAPON, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }

  CW_CallBaseMethod();
}

@Weapon_Idle(const this) {
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, BASEGRENADE_MEMBER(flStartThrow));
  static Float:flReleaseThrow; flReleaseThrow = CW_GetMember(this, BASEGRENADE_MEMBER(flReleaseThrow));
  static bool:bRedeploy; bRedeploy = CW_GetMember(this, BASEGRENADE_MEMBER(bRedeploy));

  CW_CallBaseMethod();

  if (!flStartThrow && flReleaseThrow == -1.0 && !bRedeploy) {
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
    static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
    static iPrimaryAmmo; iPrimaryAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
    static iRandomSeed; iRandomSeed = get_ent_data(pPlayer, "CBasePlayer", "random_seed");

    if (iPrimaryAmmo > 0) {
      if (SharedRandomFloat(iRandomSeed, 0.0, 1.0) <= 0.75) {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 91.0 / 30.0);
      } else {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 1, 76.0 / 30.0);
      }
    }
  }
}

@Weapon_PrimaryAttack(const this) {
  if (CW_CallBaseMethod()) {
    static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 2, 0.5);
    Asset_EmitSound(pPlayer, CHAN_WEAPON, ASSET_LIBRARY, ASSET_SOUND(GrenadeFuse));
  }
}

@Weapon_CanDrop(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);

  if (pPlayer == -1) return true;
  
  static Float:flStartThrow; flStartThrow = CW_GetMember(this, BASEGRENADE_MEMBER(flStartThrow));
  if (flStartThrow) return false;

  if (!get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType)) return false;

  return true;
}

@Weapon_Throw(const this) {
  static pProjectile; pProjectile = CW_CallBaseMethod();
  static Float:vecVelocity[3]; pev(pProjectile, pev_velocity, vecVelocity);
  static Float:flForce; flForce = xs_vec_len(vecVelocity);

  if (flForce < 500) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3);
  } else if (flForce < 1000) {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 4);
  } else {
    CW_CallNativeMethod(this, CW_Method_PlayAnimation, 5);
  }
}

@Weapon_SpawnProjectile(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

  xs_vec_add_scaled(vecSrc, vecForward, 16.0, vecSrc);

  new pGrenade = CE_Create(ENTITY(Grenade), vecSrc);
  if (pGrenade == FM_NULLENT) return FM_NULLENT;

  dllfunc(DLLFunc_Spawn, pGrenade);

  set_pev(pGrenade, pev_owner, pPlayer);

  return pGrenade;
}

@Weapon_AddToPlayer(const this, const pPlayer) {
  if (!CW_CallBaseMethod(pPlayer)) return false;

  CW_SetMemberString(this, WEAPON_BASE_MEMBER(szBounceSound), g_rgszBounceSounds[random(g_iBounceSoundsNum)]);

  return true;
}
