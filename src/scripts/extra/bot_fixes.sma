#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_custom_events>
#include <api_player_roles>
#include <api_custom_weapons>
#include <api_custom_entities>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define USE_BUTTON_RANGE 64.0
#define MELEE_ATTACK_BREAKABLE_RANGE 54.0
#define MELEE_ATTACK_RANGE 128.0
#define TEAMMATE_SEARCH_RANGE 128.0
#define PANIC_RANGE 256.0
#define PICKUP_RANGE 64.0
#define PANIC_CHANCE 30.0
#define THROW_GRENADE_MIN_RANGE 256.0
#define THROW_GRENADE_MAX_RANGE 768.0
#define PICKUP_HEALTHKIT_MIN_DAMAGE 10.0

new const m_iOriginalId[] = "__iOriginalId";

/*--------------------------------[ Plugin State ]--------------------------------*/

new bool:g_bFixMeleeAttack;
new bool:g_bFixPickup;
new bool:g_bPickupHealthkit;
new bool:g_bDropUnloadedGun;
new bool:g_bDropAmmo;
new bool:g_bDestroyBreakables;
new bool:g_bFixGrenadeThrow;
new bool:g_bPanic;
new bool:g_bActivateObjectives;

new g_pTrace;

/*--------------------------------[ Players State ]--------------------------------*/

new Float:g_rgflPlayerNextThink[MAX_PLAYERS + 1];
new Float:g_rgflPlayerNextPickup[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_pTrace = create_tr2();
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Bot Fixes"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(register_cvar(CVAR("bot_fix_melee_attack"), "1"), g_bFixMeleeAttack);
  bind_pcvar_num(register_cvar(CVAR("bot_fix_pickup"), "1"), g_bFixPickup);
  bind_pcvar_num(register_cvar(CVAR("bot_pickup_healthkit"), "1"), g_bPickupHealthkit);
  bind_pcvar_num(register_cvar(CVAR("bot_drop_unloaded_gun"), "1"), g_bDropUnloadedGun);
  bind_pcvar_num(register_cvar(CVAR("bot_drop_ammo"), "1"), g_bDropAmmo);
  bind_pcvar_num(register_cvar(CVAR("bot_fix_destroy_breakables"), "1"), g_bDestroyBreakables);
  bind_pcvar_num(register_cvar(CVAR("bot_fix_grenade_throw"), "1"), g_bFixGrenadeThrow);
  bind_pcvar_num(register_cvar(CVAR("bot_panic"), "1"), g_bPanic);
  bind_pcvar_num(register_cvar(CVAR("bot_activate_objectives"), "1"), g_bActivateObjectives);

  RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
  RegisterHam(Ham_Use, "func_door", "HamHook_Door_Use", .Post = 0);

  CE_RegisterClassNativeMethodHook(ENTITY(WeaponBox), CE_Method_Touch, "CEHook_WeaponBox_Touch");

  CW_RegisterClassMethodHook(WEAPON(Base), CW_Method_Deploy, "CWHook_Weapon_Deploy_Post", true);
  CW_RegisterClassMethodHook(WEAPON(Base), CW_Method_Holster, "CWHook_Base_Holster");
  CW_RegisterClassMethodHook(WEAPON(Crowbar), CW_Method_SecondaryAttack, "CWHook_Melee_SecondaryAttack_Post", true);
  CW_RegisterClassMethodHook(WEAPON(Swipe), CW_Method_SecondaryAttack, "CWHook_Melee_SecondaryAttack_Post", true);
}

public plugin_end() {
  free_tr2(g_pTrace);
}

/*--------------------------------[ Weapon Hooks ]--------------------------------*/

public CWHook_Weapon_Deploy_Post(const pWeapon) {
  new pPlayer = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pPlayer");
  if (!is_user_bot(pPlayer)) return;

  static iId; iId = CW_GetMember(pWeapon, CW_Member_iId);

  /*
    Mod weapons have ids different from the Counter-Strike ones,
    so we need to set the Counter-Strike ids to make bots use weapons correctly
  */
  if (!CW_HasMember(pWeapon, m_iOriginalId)) {
    CW_SetMember(pWeapon, m_iOriginalId, iId);

    switch (iId) {
      case WEAPON_ID(Crowbar), WEAPON_ID(Swipe): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_KNIFE);
      }
      case WEAPON_ID(Pistol): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_FIVESEVEN);
      }
      case WEAPON_ID(Rifle): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_M4A1);
      }
      case WEAPON_ID(Shotgun): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_M3);
      }
      case WEAPON_ID(Grenade): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_HEGRENADE);
      }
      case WEAPON_ID(Satchel): {
        CW_SetMember(pWeapon, CW_Member_iId, CSW_SMOKEGRENADE);
      }
    }

    set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) | (1 << CW_GetMember(pWeapon, CW_Member_iId)) & ~(1 << iId));
  }
}

public CWHook_Base_Holster(const pWeapon) {
  new pPlayer = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pPlayer");
  if (!is_user_bot(pPlayer)) return;

  if (CW_HasMember(pWeapon, m_iOriginalId)) {
    CW_SetMember(pWeapon, CW_Member_iId, CW_GetMember(pWeapon, m_iOriginalId));
    set_ent_data(pWeapon, "CBasePlayerItem", "m_iId", CW_GetMember(pWeapon, m_iOriginalId));
    CW_DeleteMember(pWeapon, m_iOriginalId);
  }
}

public CWHook_Melee_SecondaryAttack_Post(const pWeapon) {
  new pPlayer = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pPlayer");
  if (!is_user_bot(pPlayer)) return;

  set_pev(pPlayer, pev_button, pev(pPlayer, pev_button) | IN_ATTACK & ~IN_ATTACK2);
}

/*--------------------------------[ Weapon Box Hooks ]--------------------------------*/

public CEHook_WeaponBox_Touch(const this, const pToucher) {
  if (!IS_PLAYER(pToucher)) return CE_IGNORED;
  if (!is_user_bot(pToucher)) return CE_IGNORED;
  if (!is_user_alive(pToucher)) return CE_IGNORED;

  if (g_rgflPlayerNextPickup[pToucher] < get_gametime()) {
    g_rgflPlayerNextPickup[pToucher] = get_gametime() + 0.25;
    if (!@Bot_ShouldPickupWeaponBox(pToucher, this, true)) return CE_SUPERCEDE;
  } else {
    return CE_SUPERCEDE;
  }


  return CE_HANDLED;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_PreThink_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;
  if (!is_user_bot(pPlayer)) return HAM_IGNORED;

  @Bot_Think(pPlayer);

  return HAM_HANDLED;
}

public HamHook_Door_Use(const pDoor, const pCaller, const pActivator) {
  if (!IS_PLAYER(pActivator)) return HAM_IGNORED;
  if (!is_user_bot(pActivator)) return HAM_IGNORED;

  static szTargetname[32]; pev(pDoor, pev_targetname, szTargetname, charsmax(szTargetname));
  if (equal(szTargetname, NULL_STRING)) return HAM_IGNORED;

  return HAM_SUPERCEDE;
}

/*--------------------------------[ Bot Methods ]--------------------------------*/

@Bot_Think(const &this) {
  static Float:flGametime; flGametime = get_gametime();

  if (g_rgflPlayerNextThink[this] > flGametime) return;

  g_rgflPlayerNextThink[this] = flGametime + 0.5;

  new pActiveItem = get_ent_data_entity(this, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem == FM_NULLENT) return;

  static iWeaponId; iWeaponId = get_ent_data(pActiveItem, "CBasePlayerItem", "m_iId");

  switch (iWeaponId) {
    case CSW_KNIFE: {
      if (@Bot_LookupEnemyToStub(this)) {
        g_rgflPlayerNextThink[this] = flGametime + 0.5;
        return;
      }

      if (@Bot_LookupBreakable(this)) {
        g_rgflPlayerNextThink[this] = flGametime + 1.0;
        return;
      }
    }
    case CSW_HEGRENADE: {
      if (@Bot_LookupEnemyToThrowGrenade(this)) {
        g_rgflPlayerNextThink[this] = flGametime + 0.5;
        return;
      }
    }
    default: {
      static iClip; iClip = get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iClip");
      static iPrimaryAmmoType; iPrimaryAmmoType = get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
      if (iPrimaryAmmoType != -1) {
        static iAmmo; iAmmo = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);

        if (!iClip && iAmmo) {
          set_pev(this, pev_button, pev(this, pev_button) | IN_RELOAD);
          g_rgflPlayerNextThink[this] = flGametime + 0.25;
          return;
        }
      }
    }
  }

  if (!PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) {
    if (@Bot_LookupObjectiveButton(this)) {
      g_rgflPlayerNextThink[this] = flGametime + 1.5;
      return;
    }

    if (@Bot_ShouldDropActiveItem(this)) {
      amxclient_cmd(this, "drop");
      g_rgflPlayerNextThink[this] = flGametime + 0.25;
      return;
    }

    if (@Bot_LookupNearbyItems(this)) {
      g_rgflPlayerNextThink[this] = flGametime + 1.0;
      return;
    }

    if (@Bot_LookupTeammateToSupport(this)) {
      g_rgflPlayerNextThink[this] = flGametime + 2.0;
      return;
    }

    if (@Bot_ShouldPanic(this)) {
      client_cmd(this, "panic");
      g_rgflPlayerNextThink[this] = flGametime + 5.0;
      return;
    }
  }
}

@Bot_DropAmmoToTeammate(const &this, const &pTeammate, iAmmoIndex) {
  @Bot_TurnToEntity(this, pTeammate);

  new iGroupSize = CW_AmmoGroup_GetSize(AMMO_GROUP);

  for (new i = 0; i < iGroupSize; ++i) {
    static iSelectedAmmo; iSelectedAmmo = PlayerRole_Player_GetMember(this, PLAYER_ROLE(Survivor), SURVIVOR_MEMBER(iSelectedAmmo));

    if (iAmmoIndex == iSelectedAmmo) {
      amxclient_cmd(this, "dropammo");
      break;
    }

    amxclient_cmd(this, "changeammotype");
  }
}

bool:@Bot_LookupObjectiveButton(const &this) {
  if (!g_bActivateObjectives) return false;

  new pObjectiveButton = @Bot_FindObjectiveButtonNearby(this, USE_BUTTON_RANGE);
  if (pObjectiveButton == FM_NULLENT) return false;

  @Bot_TurnToEntity(this, pObjectiveButton);
  ExecuteHamB(Ham_Use, pObjectiveButton, this, this, USE_ON, 0.0);

  return true;
}

bool:@Bot_LookupEnemyToStub(const &this) {
  if (!@Bot_ShouldAttackWithMelee(this)) return false;

  set_pev(this, pev_button, pev(this, pev_button) | IN_ATTACK);

  return true;
}

bool:@Bot_LookupEnemyToThrowGrenade(const &this) {
  if (!@Bot_ShouldThrowGrenade(this)) return false;

  set_pev(this, pev_button, pev(this, pev_button) | IN_ATTACK);

  return true;
}

bool:@Bot_LookupBreakable(const &this) {
  if (!g_bDestroyBreakables) return false;

  new pBreakable = @Bot_FindBreakableNearby(this, MELEE_ATTACK_BREAKABLE_RANGE);
  if (pBreakable == FM_NULLENT) return false;

  if (!ExecuteHamB(Ham_FInViewCone, this, pBreakable)) {
    @Bot_TurnToEntity(this, pBreakable);
  }

  set_pev(this, pev_button, pev(this, pev_button) | IN_ATTACK);

  return true;
}

bool:@Bot_LookupTeammateToSupport(const &this) {
  if (!g_bDropAmmo) return false;

  new pTeammate = @Bot_FindPlayerNearby(this, TEAMMATE_SEARCH_RANGE, TEAM(Survivors), false);
  if (pTeammate == FM_NULLENT) return false;

  new iAmmoIndex = @Bot_FindAmmoForTeammate(this, pTeammate);
  if (iAmmoIndex != -1) {
    @Bot_DropAmmoToTeammate(this, pTeammate, iAmmoIndex);
    return true;
  }

  return false;
}

bool:@Bot_LookupNearbyItems(const &this) {
  if (!g_bFixPickup) return false;

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  new pEntity;
  while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, PICKUP_RANGE)) != 0) {
    if (CE_IsInstanceOf(pEntity, ENTITY(WeaponBox))) {
      if (@Bot_ShouldPickupWeaponBox(this, pEntity, false)) {
        @Bot_PickupItem(this, pEntity);
        return true;
      }
    }
    
    if (CE_IsInstanceOf(pEntity, ENTITY(HealthKit))) {
      if (@Bot_ShouldPickupHealthKit(this, pEntity)) {
        @Bot_PickupItem(this, pEntity);
        return true;
      }
    }
  }

  return false;
}

@Bot_PickupItem(const &this, const &pItem) {
  @Bot_TurnToEntity(this, pItem);
  ExecuteHamB(Ham_Touch, pItem, this);
}

bool:@Bot_ShouldPickupWeaponBox(const &this, const &pWeaponBox, bool:bTouched) {
  if (~pev(pWeaponBox, pev_flags) & FL_ONGROUND) return false;

  if (!bTouched) {
    if (!@Bot_IsEntityReachable(this, pWeaponBox)) return false;
  }

  new bool:bContainsWeapon = false;

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", iSlot);
    if (pItem == FM_NULLENT) continue;

    static iItemId; iItemId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");

    static pSlotItem; pSlotItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    if (pSlotItem != FM_NULLENT) {
      static iSlotItemId; iSlotItemId = get_ent_data(pSlotItem, "CBasePlayerItem", "m_iId");

      if (iItemId == iSlotItemId) return false;
      if (!CE_IsInstanceOf(pSlotItem, WEAPON(Pistol))) return false;
    }

    // if (iItemId == CSW_HEGRENADE) return false;
    if (iItemId == CSW_SMOKEGRENADE) return false;

    if (iItemId != CSW_HEGRENADE) {
      static iPrimaryAmmoType; iPrimaryAmmoType = get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
      if (iPrimaryAmmoType != -1) {
        static iClip; iClip = get_ent_data(pItem, "CBasePlayerWeapon", "m_iClip");
        static iAmmo; iAmmo = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
        if (!iClip && !iAmmo) return false;
      }
    }

    bContainsWeapon = true;
  }

  if (!bContainsWeapon && !bTouched) {
    new iAmmoTypesNum; iAmmoTypesNum = get_ent_data(pWeaponBox, "CWeaponBox", "m_cAmmoTypes");

    for (new iSlot = 0; iSlot < iAmmoTypesNum; ++iSlot) {
      static iszAmmo; iszAmmo = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", iSlot);
      if (!iszAmmo) continue;

      static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; engfunc(EngFunc_SzFromIndex, iszAmmo, szAmmo, charsmax(szAmmo));
      if (equal(szAmmo, NULL_STRING)) continue;

      if (equal(szAmmo, AMMO(Pistol))) return true;
      if (@Bot_FindWeaponByAmmoType(this, CW_Ammo_GetType(szAmmo)) != -1) return true;
    }

    return false;
  }

  return true;
}

bool:@Bot_ShouldPickupHealthKit(const &this, const &pHealthKit) {
  if (!g_bPickupHealthkit) return false;

  if (pev(pHealthKit, pev_solid) == SOLID_NOT) return false;

  static Float:flMaxHealth; pev(this, pev_max_health, flMaxHealth);
  static Float:flHealth; pev(this, pev_health, flHealth);

  if (flMaxHealth - flHealth < PICKUP_HEALTHKIT_MIN_DAMAGE) return false;

  return true;
}

bool:@Bot_ShouldAttackWithMelee(const &this) {
  if (!g_bFixMeleeAttack) return false;

  new pAimEntity = @Bot_GetAimEntity(this, MELEE_ATTACK_RANGE);
  if (pAimEntity != FM_NULLENT) {
    if (IS_PLAYER(pAimEntity)) {
      if (@Bot_IsEnemy(this, pAimEntity)) return true;
    } else {
      static szClassname[32]; pev(pAimEntity, pev_classname, szClassname, charsmax(szClassname));
      if (equal(szClassname, "func_breakable")) return true;
    }
  }

  static iEnemyTeam; iEnemyTeam = get_ent_data(this, "CBasePlayer", "m_iTeam") == TEAM(Zombies) ? TEAM(Survivors) : TEAM(Zombies);
  static pEnemy; pEnemy = @Bot_FindPlayerNearby(this, MELEE_ATTACK_RANGE, iEnemyTeam, true);
  if (pEnemy == FM_NULLENT) return false;

  return true;
}

bool:@Bot_ShouldThrowGrenade(const &this) {
  if (!g_bFixGrenadeThrow) return false;

  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static Float:vecAimOrigin[3];
  UTIL_GetAimDirection(this, vecAimOrigin);
  xs_vec_mul_scalar(vecAimOrigin, THROW_GRENADE_MIN_RANGE, vecAimOrigin);
  xs_vec_add(vecOrigin, vecAimOrigin, vecAimOrigin);

  engfunc(EngFunc_TraceLine, vecOrigin, vecAimOrigin, DONT_IGNORE_MONSTERS, this, g_pTrace);

  static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);
  if (flFraction < 1.0) return false;

  for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
    if (pTarget == this) continue;
    if (!is_user_connected(pTarget)) continue;
    if (!@Bot_IsEnemy(this, pTarget)) continue;

    static Float:vecTarget[3]; pev(pTarget, pev_origin, vecTarget);
    if (xs_vec_distance_2d(vecOrigin, vecTarget) > THROW_GRENADE_MAX_RANGE) continue;

    if (!ExecuteHamB(Ham_FInViewCone, this, pTarget)) continue;

    return true;
  }

  return false;
}

bool:@Bot_ShouldPanic(const &this) {
  if (!g_bPanic) return false;

  static Float:flMaxSpeed; pev(this, pev_maxspeed, flMaxSpeed);
  if (flMaxSpeed > 190.0) return false;

  if (@Bot_FindPlayerNearby(this, PANIC_RANGE, TEAM(Zombies), false) == FM_NULLENT) return false;

  return random(100) < PANIC_CHANCE;
}

bool:@Bot_ShouldDropActiveItem(const &this) {
  if (!g_bDropUnloadedGun) return false;

  new pActiveItem = get_ent_data_entity(this, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem == FM_NULLENT) return false;

  new iClip = get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iClip");
  if (iClip) return false;

  new iPrimaryAmmoType = get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
  new iBpAmmo = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
  if (iBpAmmo) return false;

  return true;
}

@Bot_FindAmmoForTeammate(const &this, const &pTeammate) {
  new pTeammateActiveItem = get_ent_data_entity(pTeammate, "CBasePlayer", "m_pActiveItem");
  if (pTeammateActiveItem == FM_NULLENT) return -1;

  new iAmmoType = get_ent_data(pTeammateActiveItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
  if (iAmmoType <= 0) return -1;

  new iAmmo = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iAmmoType);
  if (!iAmmo) return -1;

  static szAmmo[CW_MAX_AMMO_NAME_LENGTH];
  static iAmmoIndex; iAmmoIndex = CW_AmmoGroup_GetAmmoByType(AMMO_GROUP, iAmmoType, szAmmo, charsmax(szAmmo));
  static iPackSize; iPackSize = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));

  if (iPackSize == -1) return -1;

  if (@Bot_FindWeaponByAmmoType(this, iAmmoType) != -1) {
    if (!iPackSize) {
      if (iAmmo < 2) return -1;
    } else {
      if (iAmmo / iPackSize < 3) return -1;
    }
  }

  return iAmmoIndex;
}

@Bot_FindBreakableNearby(const &this, Float:flRange) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static Float:vecViewOfs[3];
  pev(this, pev_view_ofs, vecViewOfs);
  vecOrigin[2] += vecViewOfs[2];

  new Float:flMinDistance;
  new pBreakable = FM_NULLENT;

  static pEntity; pEntity = FM_NULLENT;
  while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0) {
    if (!pev_valid(pEntity)) continue;

    static szClassname[16]; pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

    if (!equal(szClassname, "func_breakable")) continue;
    if (pev(pEntity, pev_solid) == SOLID_NOT) continue;

    static Float:flHealth; pev(pEntity, pev_health, flHealth);
    if (flHealth > 20.0) continue;

    static Float:vecTarget[3]; UTIL_GetEntityOrigin(pEntity, vecTarget);

    static Float:flDistance; flDistance = get_distance_f(vecOrigin, vecTarget);
    if (pBreakable != FM_NULLENT && flDistance > flMinDistance) continue;

    static Float:vecEnd[3];
    for (new i = 0; i < 3; ++i) {
      vecEnd[i] = vecOrigin[i] + ((vecTarget[i] - vecOrigin[i]) / flDistance * flRange);
    }

    engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, DONT_IGNORE_MONSTERS, this, g_pTrace);
    static pHit; pHit = get_tr2(g_pTrace, TR_pHit);

    if (pHit == pEntity) {
      flMinDistance = flDistance;
      pBreakable = pEntity;
    }
  }

  return pBreakable;
}

@Bot_FindObjectiveButtonNearby(const &this, Float:flRange) {
  static Float:vecOrigin[3]; ExecuteHamB(Ham_EyePosition, this, vecOrigin);

  static Float:flMinDistance; flMinDistance = 0.0;
  static pBreakable; pBreakable = FM_NULLENT;

  static pEntity; pEntity = FM_NULLENT;
  while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0) {
    if (!pev_valid(pEntity)) continue;
    if (!CE_IsInstanceOf(pEntity, ENTITY(Button))) continue;
    if (!CE_CallMethod(pEntity, BUTTON_METHOD(IsUsable), this)) continue;

    static Float:vecTarget[3]; UTIL_GetEntityOrigin(pEntity, vecTarget);

    static Float:flDistance; flDistance = get_distance_f(vecOrigin, vecTarget);
    if (pBreakable == FM_NULLENT || !flMinDistance || flDistance < flMinDistance) {
      flMinDistance = flDistance;
      pBreakable = pEntity;
    }
  }

  return pBreakable;
}

@Bot_FindPlayerNearby(const &this, Float:flRange, iTeam, bool:bInViewCone) {
  for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
    if (pTarget == this) continue;
    if (!is_user_alive(pTarget)) continue;

    if (iTeam != -1) {
      if (get_ent_data(pTarget, "CBasePlayer", "m_iTeam") != iTeam) continue;
    }

    if (!@Bot_IsEntityReachable(this, pTarget)) continue;
    if (bInViewCone && !ExecuteHamB(Ham_FInViewCone, this, pTarget)) continue;

    if (entity_range(this, pTarget) <= flRange) return pTarget;
  }

  return FM_NULLENT;
}

@Bot_FindWeaponByAmmoType(const &this, iAmmoType) {
  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);

    while (pItem != FM_NULLENT) {
      if (get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType") == iAmmoType) {
        return pItem;
      }

      pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
    }
  }

  return FM_NULLENT;
}

@Bot_TurnToEntity(const &this, const &pTarget) {
  static Float:vecTarget[3]; UTIL_GetEntityOrigin(pTarget, vecTarget);

  @Bot_TurnToPoint(this, vecTarget);
}

@Bot_TurnToPoint(const &this, const Float:vecTarget[3]) {
  static Float:vecOrigin[3]; ExecuteHamB(Ham_EyePosition, this, vecOrigin);
  static Float:vecDir[3]; xs_vec_sub(vecTarget, vecOrigin, vecDir);

  static Float:vecAngles[3];
  engfunc(EngFunc_VecToAngles, vecDir, vecAngles);
  vecAngles[0] = -UTIL_NormalizeAngle(vecAngles[0]);
  vecAngles[1] = UTIL_NormalizeAngle(vecAngles[1]);
  vecAngles[2] = 0.0;

  set_pev(this, pev_angles, vecAngles);
  set_pev(this, pev_v_angle, vecAngles);
  set_pev(this, pev_fixangle, 1);
}

@Bot_IsEntityReachable(const &this, const &pTarget) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);
  static Float:vecTarget[3]; UTIL_GetEntityOrigin(pTarget, vecTarget);

  engfunc(EngFunc_TraceLine, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);
  static pHit; pHit = get_tr2(g_pTrace, TR_pHit);

  return flFraction == 1.0 || (pTarget != FM_NULLENT && pHit == pTarget);
}

@Bot_GetAimEntity(const &this, Float:flRange) {
  static Float:vecOrigin[3]; pev(this, pev_origin, vecOrigin);

  static Float:vecTarget[3];
  UTIL_GetAimDirection(this, vecTarget);
  xs_vec_mul_scalar(vecTarget, flRange, vecTarget);
  xs_vec_add(vecOrigin, vecTarget, vecTarget);

  engfunc(EngFunc_TraceLine, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, this, g_pTrace);
  static Float:flFraction; get_tr2(g_pTrace, TR_flFraction, flFraction);
  static pHit; pHit = get_tr2(g_pTrace, TR_pHit);

  return pHit;
}

@Bot_IsEnemy(const &this, const &pTarget) {
  if (!is_user_alive(pTarget)) return false;

  return get_ent_data(this, "CBasePlayer", "m_iTeam") != get_ent_data(pTarget, "CBasePlayer", "m_iTeam");
}

/*--------------------------------[ Utils ]--------------------------------*/

stock Float:UTIL_NormalizeAngle(Float:flAngle) {
  new iDirection = flAngle > 0 ? 1 : -1;
  new Float:flAbsAngle = flAngle * iDirection;

  new Float:flFixedAngle = (flAbsAngle - (360.0 * floatround(flAbsAngle / 360.0, floatround_floor)));
  if (flFixedAngle > 180.0) {
    flFixedAngle -= 360.0;
  }

  flFixedAngle *= iDirection;

  return flFixedAngle;
}

stock UTIL_GetAimDirection(const &pPlayer, Float:vecOut[3]) {
  static Float:vecAngles[3]; pev(pPlayer, pev_v_angle, vecAngles);

  angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecOut);
}

stock UTIL_GetEntityOrigin(const &pEntity, Float:vecOut[3]) {
  if (ExecuteHam(Ham_IsBSPModel, pEntity)) {
    ExecuteHamB(Ham_Center, pEntity, vecOut);
  } else {
    pev(pEntity, pev_origin, vecOut);
  }
}
