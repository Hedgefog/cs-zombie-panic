#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>
#include <reapi>

#include <api_assets>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define WEAPON_NAME WEAPON(Satchel)
#define MEMBER(%1) WEAPON_SATCHEL_MEMBER(%1)
#define METHOD(%1) WEAPON_SATCHEL_METHOD(%1)

/*--------------------------------[ Assets ]--------------------------------*/

new g_szViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_szRadioViewModel[MAX_RESOURCE_PATH_LENGTH];
new g_szRadioPlayerModel[MAX_RESOURCE_PATH_LENGTH];
new g_szRadioWorldModel[MAX_RESOURCE_PATH_LENGTH];
new g_szBounceSounds[4][MAX_RESOURCE_PATH_LENGTH];

new g_iBounceSoundsNum = 0;

/*--------------------------------[ Players State ]--------------------------------*/

new g_rgpPlayerPickupCharge[MAX_PLAYERS + 1] = { -1, ... };

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pTrace;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SatchelView), g_szViewModel, charsmax(g_szViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SatchelPlayer), g_szPlayerModel, charsmax(g_szPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Satchel), g_szWorldModel, charsmax(g_szWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SatchelRadioView), g_szRadioViewModel, charsmax(g_szRadioViewModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SatchelRadioPlayer), g_szRadioPlayerModel, charsmax(g_szRadioPlayerModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(SatchelRadio), g_szRadioWorldModel, charsmax(g_szRadioWorldModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(SatchelRadioBlip));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(SatchelRadioPress));

  g_iBounceSoundsNum = Asset_PrecacheList(ASSET_LIBRARY, ASSET_SOUND(GrenadeBounce), g_szBounceSounds, sizeof(g_szBounceSounds), charsmax(g_szBounceSounds[]));

  CW_RegisterClass(WEAPON_NAME, WEAPON(Base));
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Create, "@Weapon_Create");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Idle, "@Weapon_Idle");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_SecondaryAttack, "@Weapon_SecondaryAttack");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Deploy, "@Weapon_Deploy");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_CanDrop, "@Weapon_CanDrop");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_Drop, "@Weapon_Drop");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_AddPrimaryAmmo, "@Weapon_AddPrimaryAmmo");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_IsExhausted, "@Weapon_IsExhausted");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_UpdateWeaponBoxModel, "@Weapon_UpdateWeaponBoxModel");
  CW_ImplementClassMethod(WEAPON_NAME, CW_Method_AddToPlayer, "@Weapon_AddToPlayer");

  #if defined ZP_DROPPABLE_SATCHELS
    CW_ImplementClassMethod(WEAPON_NAME, CW_Method_ExtractAmmo, "@Weapon_ExtractAmmo");
    CW_ImplementClassMethod(WEAPON_NAME, CW_Method_AddDuplicate, "@Weapon_AddDuplicate");
  #endif

  CW_RegisterClassMethod(WEAPON_NAME, METHOD(ActivateCharges), "@Weapon_ActivateCharges");
  CW_RegisterClassMethod(WEAPON_NAME, METHOD(ThrowCharge), "@Weapon_ThrowCharge");
  CW_RegisterClassMethod(WEAPON_NAME, METHOD(UpdateRemoteState), "@Weapon_UpdateRemoteState");
  CW_RegisterClassMethod(WEAPON_NAME, METHOD(ShouldUseRemote), "@Weapon_ShouldUseRemote");
}

public plugin_init() {
  register_plugin(WEAPON_PLUGIN(Satchel), ZP_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
  RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);

  CE_RegisterClassNativeMethodHook(ENTITY(SatchelCharge), CE_Method_Spawn, "CEHook_SatchelCharge_Spawn_Post", true);
  CE_RegisterClassNativeMethodHook(ENTITY(SatchelCharge), CE_Method_Killed, "CEHook_SatchelCharge_Killed_Post", true);

  CW_Ammo_RegisterHook(AMMO(Satchel), CW_AmmoHook_GiveToPlayer, "CWHook_SatchelAmmo_GiveToPlayer_Post", true);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Weapon_Create(const this) {
  CW_CallBaseMethod();

  CW_SetMemberString(this, CW_Member_szModel, g_szWorldModel);
  CW_SetMember(this, CW_Member_iId, WEAPON_ID(Satchel));
  CW_SetMember(this, CW_Member_iMaxClip, -1);
  CW_SetMemberString(this, CW_Member_szPrimaryAmmo, AMMO(Satchel));
  CW_SetMember(this, CW_Member_iSlot, 4);
  CW_SetMember(this, CW_Member_iPosition, 5);
  CW_SetMember(this, CW_Member_iDefaultAmmo, 1);
  CW_SetMember(this, CW_Member_iFlags, ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
  CW_SetMemberString(this, CW_Member_szIcon, "satchel");

  #if !defined ZP_DROPPABLE_SATCHELS
    CW_SetMember(this, CW_Member_bExhaustible, true);
  #endif

  CW_SetMember(this, CW_Member_iWeight, 123);

  CW_SetMember(this, WEAPON_BASE_MEMBER(flWeight), 0.0);
  CW_SetMemberString(this, WEAPON_BASE_MEMBER(szBounceSound), g_szBounceSounds[random(g_iBounceSoundsNum)]);

  CW_SetMember(this, MEMBER(bUseRemote), false);
}

@Weapon_Deploy(const this) {
  CW_CallBaseMethod();

  CW_SetMember(this, MEMBER(bUseRemote), CW_CallMethod(this, METHOD(ShouldUseRemote)));

  if (CW_GetMember(this, MEMBER(bUseRemote))) {
    CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szRadioViewModel, g_szRadioPlayerModel, 2, "grenade");
  } else {
    CW_CallNativeMethod(this, CW_Method_DefaultDeploy, g_szViewModel, g_szPlayerModel, 2, "grenade");
  }
}

@Weapon_Idle(const this) {
  CW_CallBaseMethod();

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 0, 5.5);
  CW_CallMethod(this, METHOD(UpdateRemoteState));

  #if !defined ZP_DROPPABLE_SATCHELS
    if (!CW_GetMember(this, MEMBER(iChargesNum)) && CW_CallNativeMethod(this, CW_Method_IsOutOfAmmo)) {
      ExecuteHamB(Ham_Weapon_RetireWeapon, this);
      return false;
    }
  #endif

  return true;
}

@Weapon_PrimaryAttack(const this) {
  CW_CallBaseMethod();

  if (CW_GetMember(this, MEMBER(bUseRemote))) {
    CW_CallMethod(this, METHOD(ActivateCharges));
  } else {
    if (!CW_CallMethod(this, METHOD(ThrowCharge))) return false;
  }

  return true;
}

@Weapon_SecondaryAttack(const this) {
  CW_CallBaseMethod();

  if (CW_GetMember(this, MEMBER(bUseRemote))) {
    if (CW_CallMethod(this, METHOD(ThrowCharge))) {
      static Float:flGameTime; flGameTime = get_gametime();

      CW_SetMember(this, CW_Member_flNextPrimaryAttack, flGameTime + 0.53);
      CW_SetMember(this, CW_Member_flNextSecondaryAttack, flGameTime + 0.53);
    }
  }

  return true;
}

@Weapon_CanDrop(const this) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  if (pPlayer == FM_NULLENT) return false;

  #if !defined ZP_DROPPABLE_SATCHELS
    new iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);

    if (!get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType)) return false;
    if (CW_GetMember(this, MEMBER(iChargesNum))) return false;
  #endif

  return true;
}

@Weapon_Drop(const this) {
  new pEntity;
  while ((pEntity = CE_Find(ENTITY(SatchelCharge), pEntity)) != FM_NULLENT) {
    if (CE_GetMember(pEntity, SATCHELCHARGE_MEMBER(pRemote)) == this) {
      CE_CallMethod(pEntity, SATCHELCHARGE_METHOD(Deactivate));
    }
  }

  CW_CallBaseMethod();
}

@Weapon_AddPrimaryAmmo(const this, iCount) {
  new bool:bResult = CW_CallBaseMethod(iCount);

  CW_CallMethod(this, METHOD(UpdateRemoteState));

  return bResult;
}

@Weapon_UpdateRemoteState(const this) {
  new bool:bUseRemote = CW_CallMethod(this, METHOD(ShouldUseRemote));

  if (bUseRemote != CW_GetMember(this, MEMBER(bUseRemote))) {
    CW_SetMember(this, MEMBER(bUseRemote), bUseRemote);
    CW_CallNativeMethod(this, CW_Method_Deploy);
  }
}

@Weapon_IsExhausted(const this) {
  if (CW_GetMember(this, MEMBER(iChargesNum))) return false;

  return CW_CallBaseMethod();
}

#if defined ZP_DROPPABLE_SATCHELS
  @Weapon_ExtractAmmo(const this, const pOther) {
    if (!CW_CallBaseMethod(pOther)) return false;

    new pOwner = pev(this, pev_owner);
    if (CE_IsInstanceOf(pOwner, ENTITY(WeaponBox))) {
      CW_CallNativeMethod(this, CW_Method_UpdateWeaponBoxModel, pOwner);
    }

    return true;
  }

  @Weapon_AddDuplicate(const this, const pOther) {
    if (!CW_CallBaseMethod(pOther)) return false;

    // Allows to pickup ammo, but never return true, so weaponbox keep the remote
    return false;
  }
#endif

@Weapon_UpdateWeaponBoxModel(const this, const pWeaponBox) {
  new bool:bHasSatchelAmmo = false;

  new iAmmoTypesNum = get_ent_data(pWeaponBox, "CWeaponBox", "m_cAmmoTypes");

  if (!bHasSatchelAmmo) {
    for (new iSlot = 0; iSlot < iAmmoTypesNum; ++iSlot) {
      static iAmount; iAmount = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgAmmo", iSlot);
      if (!iAmount) continue;

      static iszAmmo; iszAmmo = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", iSlot);
      if (!iszAmmo) continue;
      
      static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; engfunc(EngFunc_SzFromIndex, iszAmmo, szAmmo, charsmax(szAmmo));

      if (equal(szAmmo, AMMO(Satchel))) {
        bHasSatchelAmmo = true;
        break;
      }
    }
  }

  if (!bHasSatchelAmmo && !get_ent_data(this, "CBasePlayerWeapon", "m_iDefaultAmmo")) {
    engfunc(EngFunc_SetModel, pWeaponBox, g_szRadioWorldModel);
  } else {
    engfunc(EngFunc_SetModel, pWeaponBox, g_szWorldModel);
  }
}

bool:@Weapon_ThrowCharge(const this) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");
  new iPrimaryAmmoType = CW_GetMember(this, CW_Member_iPrimaryAmmoType);

  new iAmmoAmount = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
  if (iAmmoAmount <= 0) return false;

  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
  static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);

  for (new i = 0; i < 3; ++i) {
    vecVelocity[i] = (vecForward[i] * 274.0) + vecVelocity[i];
  }

  new pSatchelCharge = CE_Create(ENTITY(SatchelCharge), vecOrigin);
  set_pev(pSatchelCharge, pev_owner, pPlayer);
  CE_SetMember(pSatchelCharge, SATCHELCHARGE_MEMBER(pRemote), this);
  dllfunc(DLLFunc_Spawn, pSatchelCharge);
  set_pev(pSatchelCharge, pev_velocity, vecVelocity);
  set_pev(pSatchelCharge, pev_avelocity, Float:{0.0, 100.0, 0.0});
  set_pev(pSatchelCharge, pev_team, get_ent_data(pPlayer, "CBasePlayer", "m_iTeam"));

  set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", (iAmmoAmount -= 1), iPrimaryAmmoType);
  rg_set_animation(pPlayer, PLAYER_ATTACK1);

  static Float:flGameTime; flGameTime = get_gametime();

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, flGameTime + 1.0);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, flGameTime + 0.5);

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3, (61.0 / 30.0));
  CW_CallMethod(this, METHOD(UpdateRemoteState));

  return true;
}

@Weapon_ActivateCharges(const this) {
  new pPlayer = get_ent_data_entity(this, "CBasePlayerItem", "m_pPlayer");

  Asset_EmitSound(pPlayer, CHAN_WEAPON, ASSET_LIBRARY, ASSET_SOUND(SatchelRadioPress));

  if (CW_GetMember(this, MEMBER(iChargesNum))) {
    Asset_EmitSound(pPlayer, CHAN_ITEM, ASSET_LIBRARY, ASSET_SOUND(SatchelRadioBlip), .flVolume = VOL_NORM * 0.125);
  }

  new pEntity;
  while ((pEntity = engfunc(EngFunc_FindEntityByString, pEntity, "classname", ENTITY(SatchelCharge))) != 0) {
    if (CE_GetMember(pEntity, SATCHELCHARGE_MEMBER(pRemote)) == this) {
      ExecuteHamB(Ham_Use, pEntity, pPlayer, pPlayer, USE_ON, 0.0);
    }
  }

  static Float:flGameTime; flGameTime = get_gametime();

  CW_SetMember(this, CW_Member_flNextPrimaryAttack, flGameTime + 0.5);
  CW_SetMember(this, CW_Member_flNextSecondaryAttack, flGameTime + 0.5);

  CW_CallNativeMethod(this, CW_Method_PlayAnimation, 3, (31.0 / 50.0));
  CW_CallMethod(this, METHOD(UpdateRemoteState));
}

bool:@Weapon_ShouldUseRemote(const this) {
  return CW_GetMember(this, MEMBER(iChargesNum)) > 0 || CW_CallNativeMethod(this, CW_Method_IsOutOfAmmo);
}

@Weapon_AddToPlayer(const this, const pPlayer) {
  if (!CW_CallBaseMethod(pPlayer)) return false;

  // No custom bounce sound for remotes
  #if defined ZP_DROPPABLE_SATCHELS
    CW_SetMemberString(this, WEAPON_BASE_MEMBER(szBounceSound), NULL_STRING);
  #else
    CW_SetMemberString(this, WEAPON_BASE_MEMBER(szBounceSound), g_szBounceSounds[random(g_iBounceSoundsNum)]);
  #endif

  return true;
}

/*--------------------------------[ Ammo Hooks ]--------------------------------*/

public CWHook_SatchelAmmo_GiveToPlayer_Post(const pPlayer, const iAmmoAmount) {
  new pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem == FM_NULLENT) return CW_IGNORED;

  if (CW_IsInstanceOf(pActiveItem, WEAPON_NAME)) {
    CW_CallMethod(pActiveItem, METHOD(UpdateRemoteState));
  }

  return CW_HANDLED;
}

/*--------------------------------[ Charges Hooks ]--------------------------------*/

public CEHook_SatchelCharge_Spawn_Post(const pSatchelCharge) {
  static pRemote; pRemote = CE_GetMember(pSatchelCharge, SATCHELCHARGE_MEMBER(pRemote));

  if (pRemote != FM_NULLENT) {
    CW_SetMember(pRemote, WEAPON_SATCHEL_MEMBER(iChargesNum), CW_GetMember(pRemote, WEAPON_SATCHEL_MEMBER(iChargesNum)) + 1);
  }

  return CE_HANDLED;
}

public CEHook_SatchelCharge_Killed_Post(const pSatchelCharge) {
  static pRemote; pRemote = CE_GetMember(pSatchelCharge, SATCHELCHARGE_MEMBER(pRemote));

  if (pRemote != FM_NULLENT) {
    CW_SetMember(pRemote, WEAPON_SATCHEL_MEMBER(iChargesNum), CW_GetMember(pRemote, WEAPON_SATCHEL_MEMBER(iChargesNum)) - 1);
  }

  return CE_HANDLED;
}

/*--------------------------------[ Player Hoooks ]--------------------------------*/

public HamHook_Player_PreThink_Post(const pPlayer) {
  static const Float:flPickupRange = 64.0;

  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  g_rgpPlayerPickupCharge[pPlayer] = FM_NULLENT;
  
  if (~pev(pPlayer, pev_button) & IN_USE || pev(pPlayer, pev_oldbuttons) & IN_USE) return HAM_IGNORED;

  static pRemote; pRemote = CW_PlayerFindWeapon(pPlayer, WEAPON_NAME);
  if (pRemote == FM_NULLENT) return HAM_IGNORED;

  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);
  static Float:vecForward[3]; angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);
  static Float:vecSrc[3]; ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);
  static Float:vecEnd[3]; xs_vec_add_scaled(vecSrc, vecForward, flPickupRange, vecEnd);

  engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, g_pTrace);
  get_tr2(g_pTrace, TR_vecEndPos, vecEnd);

  static pSatchelCharge; pSatchelCharge = FM_NULLENT;
  while ((pSatchelCharge = CE_Find(ENTITY(SatchelCharge), pSatchelCharge)) != FM_NULLENT) {
    if (CE_GetMember(pSatchelCharge, SATCHELCHARGE_MEMBER(pRemote)) != pRemote) continue;

    static Float:vecOrigin[3]; pev(pSatchelCharge, pev_origin, vecOrigin);

    if (!pev(pSatchelCharge, pev_waterlevel)) {
      if (~pev(pSatchelCharge, pev_flags) & FL_ONGROUND) continue;

      if (xs_vec_distance(vecOrigin, vecEnd) < 16.0) {
        g_rgpPlayerPickupCharge[pPlayer] = pSatchelCharge;
        break;
      }
    } else {
      static Float:flTravelDistance; flTravelDistance = xs_vec_distance(vecSrc, vecEnd);
      xs_vec_add_scaled(vecSrc, vecForward, flTravelDistance / 2, vecEnd);

      if (xs_vec_distance(vecOrigin, vecEnd) < flPickupRange / 2) {
        g_rgpPlayerPickupCharge[pPlayer] = pSatchelCharge;
        break;
      }
    }
  }

  return HAM_HANDLED;
}

public HamHook_Player_PostThink_Post(pPlayer) {
  if (g_rgpPlayerPickupCharge[pPlayer] == FM_NULLENT) return HAM_IGNORED;

  static pActiveItem; pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  
  static pSatchelWeapon; pSatchelWeapon = FM_NULLENT;

  if (CW_IsInstanceOf(pActiveItem, WEAPON_NAME)) {
    pSatchelWeapon = pActiveItem;
  }

  if (pSatchelWeapon == FM_NULLENT) {
    pSatchelWeapon = CW_PlayerFindWeapon(pPlayer, WEAPON_NAME);
  }

  if (pSatchelWeapon != FM_NULLENT) {
    if (CW_CallNativeMethod(pSatchelWeapon, CW_Method_AddPrimaryAmmo, 1)) {
      CE_CallMethod(g_rgpPlayerPickupCharge[pPlayer], SATCHELCHARGE_METHOD(Deactivate));

      if (pSatchelWeapon == pActiveItem) {
        CW_CallMethod(pSatchelWeapon, METHOD(UpdateRemoteState));
      }
    }
  }

  g_rgpPlayerPickupCharge[pPlayer] = FM_NULLENT;

  return HAM_HANDLED;
}
