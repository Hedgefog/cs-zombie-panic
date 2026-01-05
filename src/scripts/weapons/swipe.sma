#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <api_assets>
#include <api_custom_events>
#include <api_custom_weapons>
#include <api_player_roles>
#include <combat_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define WEAPON_NAME WEAPON(Swipe)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_rgszMissSounds[4][MAX_RESOURCE_PATH_LENGTH];
new g_rgszHitSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iMissSoundsNum = 0;
new g_iHitSoundsNum = 0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SwipeView), g_szViewModel, charsmax(g_szViewModel));

  g_iMissSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(SwipeMiss), g_rgszMissSounds, sizeof(g_rgszMissSounds), charsmax(g_rgszMissSounds[]));
  g_iHitSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(SwipeHit), g_rgszHitSounds, sizeof(g_rgszHitSounds), charsmax(g_rgszHitSounds[]));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_SecondaryAttack, "@Weapon_SecondaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_CanDrop, "@Weapon_CanDrop");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_MakeDecal, "@Weapon_MakeDecal");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_BulletSmoke, "@Weapon_BulletSmoke");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Smack, "@Weapon_Smack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_SmackTraceAttack, "@Weapon_SmackTraceAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PlayTextureSound, "@Weapon_PlayTextureSound");

  CW_RegisterClassMethod(WEAPON_NAME, WEAPON_BASE_METHOD(HitTextureEffect), "@Weapon_HitTextureEffect", CW_Type_Cell);
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Swipe), ZP_VERSION, "Hedgehog Fog");
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  if (random(2) == 0) {
    set_ent_data_string(pPlayer, "CBasePlayer", "m_szAnimExtention", "grenade");
  } else {
    set_ent_data_string(pPlayer, "CBasePlayer", "m_szAnimExtention", "shieldgren");
  }

  new pHit = CW_CallNativeMethod(this, CW_Method_DefaultSwing, 25.0, 0.5, 32.0, 0.125);
  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 4, 0.25);

  if (pHit == FM_NULLENT) {
    switch (random(3)) {
      case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 4, 11.0 / 22.0);
      case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 5, 14.0 / 22.0);
      case 2: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 7, 19.0 / 24.0);
    }
  } else {
    switch (random(3)) {
      case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3, 11.0 / 22.0);
      case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 6, 14.0 / 22.0);
      case 2: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 8, 19.0 / 24.0);
    }
  }
}

@Weapon_SecondaryAttack(const this) {
  CW_CallBaseMethod();
}

@Weapon_Deploy(const this) {
  CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, NULL_STRING, 1, "dualpistols");
}

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Swipe));
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(ZombiesValue));
  CW_SetMemberString(this, CW_Member_szIcon, "swipe");
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  set_ent_data_string(pPlayer, "CBasePlayer", "m_szAnimExtention", "dualpistols");

  switch (random(3)) {
    case 0: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 36.0 / 13.0);
    case 1: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 9, 61.0 / 15.0);
    case 2: CW_CallNativeMethod(this, CW_Method_PlayAnimation, 10, 61.0 / 15.0);
  }
}

@Weapon_CanDrop(const this) {
  return false;
}

@Weapon_PlayTextureSound(const this, const pTrace) {
  static chTextureType; chTextureType = CW_GetMember(this, CW_Member_chHitTextureType);

  if (chTextureType == CHAR_TEX_METAL) return;
  if (chTextureType == CHAR_TEX_VENT) return;
  if (chTextureType == CHAR_TEX_GRATE) return;

  CW_CallBaseMethod(pTrace);
}

@Weapon_HitTextureEffect(const this, const pTrace) {
  static chTextureType; chTextureType = CW_GetMember(this, CW_Member_chHitTextureType);

  if (chTextureType == CHAR_TEX_METAL) return;
  if (chTextureType == CHAR_TEX_VENT) return;
  if (chTextureType == CHAR_TEX_GRATE) return;
  if (chTextureType == CHAR_TEX_CONCRETE) return;

  CW_CallBaseMethod(pTrace);
}

@Weapon_MakeDecal(const this, pHit, pTrace, bool:bGunShot) {
  if (pHit == FM_NULLENT) return;

  static iDecal = -1;

  switch (random(3)) {
    case 0: iDecal = engfunc(EngFunc_DecalIndex, "{blood6");
    case 1: iDecal = engfunc(EngFunc_DecalIndex, "{blood7");
    case 2: iDecal = engfunc(EngFunc_DecalIndex, "{blood8");
  }

  UTIL_MakeDecal(pTrace, pHit, iDecal, bGunShot);
}

@Weapon_BulletSmoke(const this, pHit, pTrace, bool:bGunShot) {}

@Weapon_Smack(const this) {
  static pPlayer; pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  static pHit; pHit = CW_CallBaseMethod();

  if (pHit != FM_NULLENT) {
    emit_sound(pPlayer, CHAN_ITEM, g_rgszHitSounds[random(g_iHitSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  } else {
    emit_sound(pPlayer, CHAN_ITEM, g_rgszMissSounds[random(g_iMissSoundsNum)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }
}

@Weapon_SmackTraceAttack(const this) {
  static pTrace; pTrace = CW_GetMember(this, CW_Member_pSwingTrace);
  static pHit; pHit = CW_GetMember(this, CW_Member_pSwingHit);

  if (IS_PLAYER(pHit)) {
    set_tr2(pTrace, TR_iHitgroup, get_tr2(pTrace, TR_iHitgroup) & ~HIT_HEAD);
  }

  CW_CallBaseMethod();
}
