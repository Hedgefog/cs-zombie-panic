#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_weapons>
#include <api_custom_entities>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Assets ]--------------------------------*/

#define SMOKEPUFF_SPRITE "sprites/smokepuff.spr"

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  precache_model(SMOKEPUFF_SPRITE);

  CW_RegisterClass(WEAPON(Base), _, true);
  CW_ImplementClassMethod(WEAPON(Base), CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON(Base), CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON(Base), CW_Method_Holster, "@Weapon_Holster");
  CW_ImplementClassMethod(WEAPON(Base), CW_Method_ExtractClipAmmo, "@Weapon_ExtractClipAmmo");
  CW_ImplementClassMethod(WEAPON(Base), CW_Method_HitTexture, "@Weapon_HitTexture");

  CW_RegisterClassMethod(WEAPON(Base), WEAPON_BASE_METHOD(DefaultUnload), "@Weapon_DefaultUnload", CW_Type_Cell, CW_Type_Cell, CW_Type_Cell);

  CW_RegisterClassVirtualMethod(WEAPON(Base), WEAPON_BASE_METHOD(CanUnload), "@Weapon_CanUnload");
  CW_RegisterClassVirtualMethod(WEAPON(Base), WEAPON_BASE_METHOD(Unload), "@Weapon_Unload");
  CW_RegisterClassVirtualMethod(WEAPON(Base), WEAPON_BASE_METHOD(CompleteUnload), "@Weapon_CompleteUnload");
  CW_RegisterClassVirtualMethod(WEAPON(Base), WEAPON_BASE_METHOD(HitTextureEffect), "@Weapon_HitTextureEffect", CW_Type_Cell);
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Base), ZP_VERSION, "Hedgehog Fog");

  register_clcmd("unload", "Command_Unload");
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_Unload(const pPlayer) {
  static pActiveItem; pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem == FM_NULLENT) return PLUGIN_HANDLED;

  if (!CW_IsInstanceOf(pActiveItem, WEAPON(Base))) return PLUGIN_HANDLED;

  static Float:flNextPrimaryAttack; flNextPrimaryAttack = CW_GetMember(pActiveItem, CW_Member_flNextPrimaryAttack);
  if (flNextPrimaryAttack > get_gametime()) return PLUGIN_HANDLED;

  if (CW_CallMethod(pActiveItem, WEAPON_BASE_METHOD(CanUnload))) {
    CW_CallMethod(pActiveItem, WEAPON_BASE_METHOD(Unload));
  }

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_NOAUTORELOAD);

  CW_SetMember(this, ZP_Weapon_Base_Member_flWeight, 0.0);
}

@Weapon_Idle(const this) {
  if (CW_GetMember(this, WEAPON_BASE_MEMBER(bInUnload))) {
    CW_CallMethod(this, WEAPON_BASE_METHOD(CompleteUnload));
    return;
  }

  CW_CallBaseMethod();
}

@Weapon_Holster(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, WEAPON_BASE_MEMBER(bInUnload), false);
}

@Weapon_ExtractClipAmmo(const this, const pOther) {
  return false;
}

@Weapon_HitTexture(const this, const chTextureType, const pTrace) {
  CW_CallBaseMethod(chTextureType, pTrace);

  CW_CallMethod(this, WEAPON_BASE_METHOD(HitTextureEffect), pTrace);
}

bool:@Weapon_CanUnload(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static Float:flNextAttack; flNextAttack = get_ent_data_float(pPlayer, "CBaseMonster", "m_flNextAttack");
  if (flNextAttack > 0.0) return false;

  static iClip; iClip = CW_GetMember(this, CW_Member_iClip);
  if (iClip <= 0) return false;

  if (CW_GetMember(this, CW_Member_bInReload)) return false;
  if (CW_GetMember(this, CW_Member_iSpecialReload)) return false;

  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iPrimaryAmmo; iPrimaryAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
  static szPrimaryAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_GetMemberString(this, CW_Member_szPrimaryAmmo, szPrimaryAmmo, charsmax(szPrimaryAmmo));
  static iMaxPrimaryAmmo; iMaxPrimaryAmmo = CW_Ammo_GetMaxAmount(szPrimaryAmmo);

  if (iPrimaryAmmo >= iMaxPrimaryAmmo) return false;

  return true;
}

bool:@Weapon_Unload(const this) {
  return true;
}

@Weapon_CompleteUnload(const this) {
  CW_SetMember(this, WEAPON_BASE_MEMBER(bInUnload), false);

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  static iClip; iClip = CW_GetMember(this, CW_Member_iClip);
  static iUnloadAmount; iUnloadAmount = CW_GetMember(this, WEAPON_BASE_MEMBER(iUnloadAmount));
  static iPrimaryAmmoType; iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);
  static iPrimaryAmmo; iPrimaryAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
  static szPrimaryAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_GetMemberString(this, CW_Member_szPrimaryAmmo, szPrimaryAmmo, charsmax(szPrimaryAmmo));
  static iMaxPrimaryAmmo; iMaxPrimaryAmmo = CW_Ammo_GetMaxAmount(szPrimaryAmmo);

  iUnloadAmount = min(iPrimaryAmmo + min(iUnloadAmount, iClip), iMaxPrimaryAmmo) - iPrimaryAmmo;

  if (iUnloadAmount <= 0) return false;

  if (CW_CallNativeMethod(this, CW_Method_AddPrimaryAmmo, iUnloadAmount)) {
    CW_SetMember(this, CW_Member_iClip, iClip - iUnloadAmount);
  }

  return true;
}

bool:@Weapon_DefaultUnload(const this, iAmount, iAnim, Float:flDelay) {
  if (CW_GetMember(this, WEAPON_BASE_MEMBER(bInUnload))) return false;

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  set_ent_data_float(pPlayer, "CBaseMonster", "m_flNextAttack", flDelay);
  CW_SetMember(this, WEAPON_BASE_MEMBER(bInUnload), true);
  CW_SetMember(this, WEAPON_BASE_MEMBER(iUnloadAmount), iAmount);

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, iAnim, flDelay);
  rg_set_animation(pPlayer, PLAYER_RELOAD);

  return true;
}

@Weapon_HitTextureEffect(const this, const pTrace) {
  static chTextureType; chTextureType = CW_GetMember(this, CW_Member_chHitTextureType);
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);
  static Float:vecEnd[3]; get_tr2(pTrace, TR_vecEndPos, vecEnd);

  static Float:vecDirection[3];
  xs_vec_sub(vecEnd, vecSrc, vecDirection);
  xs_vec_normalize(vecDirection, vecDirection);

  switch (chTextureType) {
    case CHAR_TEX_METAL, CHAR_TEX_VENT, CHAR_TEX_GRATE: {
      UTIL_Sparks(vecEnd);
      UTIL_ArmorRicochet(vecEnd, 5 + random(5));
    }
    case CHAR_TEX_CONCRETE: {
      static Float:vecDustOrigin[3]; xs_vec_sub_scaled(vecEnd, vecDirection, 16.0, vecDustOrigin);

      if (random(10) == 0) {
        UTIL_Sparks(vecEnd);
      }

      static iModelIndex = 0;
      if (!iModelIndex) {
        iModelIndex = engfunc(EngFunc_ModelIndex, SMOKEPUFF_SPRITE);
      }

      static Float:flHitDamage; flHitDamage = CW_GetMember(this, CW_Member_flHitDamage);
      static iTransparency; iTransparency = min(floatround(flHitDamage / 15.0 * 30.0), 30);

      if (iTransparency) {
        engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecDustOrigin, 0);
        write_byte(TE_SPRITE);
        engfunc(EngFunc_WriteCoord, vecDustOrigin[0]);
        engfunc(EngFunc_WriteCoord, vecDustOrigin[1]);
        engfunc(EngFunc_WriteCoord, vecDustOrigin[2]);
        write_short(iModelIndex);
        write_byte(15);
        write_byte(iTransparency);
        message_end();
      }
    }
  }
}
