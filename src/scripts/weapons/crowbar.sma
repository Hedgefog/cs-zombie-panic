#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

#include <api_assets>
#include <api_custom_weapons>
#include <api_entity_force>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Crowbar)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(CrowbarView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(CrowbarPlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Crowbar), g_szWorldModel, charsmax(g_szWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(CrowbarMiss));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(CrowbarHitbody));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(CrowbarHit));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(CrowbarHitSoft));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_CanDrop, "@Weapon_CanDrop");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Smack, "@Weapon_Smack");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Crowbar), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Crowbar));
  CW_SetMember(this, CW_Member_iSlot, 2);
  CW_SetMember(this, CW_Member_iPosition, 0);
  CW_SetMemberString(this, CW_Member_szIcon, "crowbar");
  CW_SetMember(this, CW_Member_iWeight, 1);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, Asset_GetFloat(ASSET_LIBRARY, ASSET_VARIABLE(flCrowbarWeight)));
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 1, "grenade");
}

@Weapon_CanDrop(const this) {
  return false;
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();
  
  switch (random(3)) {
    case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 36.0 / 13.0);
    case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 9, 81.0 / 15.0);
    case 2: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 10, 81.0 / 15.0);
  }
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  new pHit = CW_CallNativeMethod(this, CW_Method_DefaultSwing, 25.0, 0.5, 32.0, 0.125);

  static pTrace; pTrace = CW_GetMember(this, CW_Member_pSwingTrace);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);
  static Float:vecEnd[3]; get_tr2(pTrace, TR_vecEndPos, vecEnd);
  
  static Float:vecHitDir[3];
  xs_vec_sub(vecEnd, vecSrc, vecHitDir);
  xs_vec_normalize(vecHitDir, vecHitDir);

  static Float:vecRight[3];
  pev(pPlayer, pev_v_angle, vecRight);
  angle_vector(vecRight, ANGLEVECTOR_FORWARD, vecRight);
  xs_vec_cross(Float:{0.0, 0.0, 1.0}, vecRight, vecRight);
  xs_vec_normalize(vecRight, vecRight);

  static Float:flDot; flDot = xs_vec_dot(vecRight, vecHitDir);

  if (floatabs(flDot) > 0.2) {
    if (flDot > 0.0) {
      if (pHit != FM_NULLENT) {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 8, 19.0 / 24.0);
      } else {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 7, 19.0 / 24.0);
      }
    } else {
      if (pHit != FM_NULLENT) {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 6, 14.0 / 22.0);
      } else {
        CW_CallNativeMethod(this, CW_Method_PlayAnimation, 5, 14.0 / 22.0);
      }
    }
  } else {
    if (pHit != FM_NULLENT) {
      CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3, 11.0 / 22.0);
    } else {
      CW_CallNativeMethod(this, CW_Method_PlayAnimation, 4, 11.0 / 22.0);
    }
  }
}

@Weapon_Smack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static pHit; pHit = CW_CallBaseMethod();

  static chHitTextureType; chHitTextureType = CW_GetMember(this, CW_Member_chHitTextureType);

  if (pHit != FM_NULLENT) {     
    if (IS_PLAYER(pHit)) {
      if (rg_is_player_can_takedamage(pHit, pPlayer)) {
        static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
        EntityForce_AddFromOrigin(pHit, vecOrigin, 150.0);
      }

      Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitbody));
    } else {
      switch (chHitTextureType) {
        case CHAR_TEX_DIRT: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitSoft));
        case CHAR_TEX_GRASS: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitSoft));
        case CHAR_TEX_SNOW: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitSoft));
        case CHAR_TEX_SLOSH: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitSoft));
        case CHAR_TEX_FLESH: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHitbody));
        default: Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarHit));
      }
    }
  } else {
    Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(CrowbarMiss));
  }

  return pHit;
}
