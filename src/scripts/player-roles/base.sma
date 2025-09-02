#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

#include <api_assets>
#include <api_custom_events>
#include <api_player_roles>
#include <api_custom_entities>
#include <api_custom_weapons>
#include <api_player_model>
#include <combat_util>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define ROLE PLAYER_ROLE(Base)
#define MEMBER BASE_ROLE_MEMBER
#define METHOD BASE_ROLE_METHOD
#define SOUND BASE_ROLE_SOUND

#define DropFlags ZP_PlayerRole_Base_DropFlags

/*--------------------------------[ Constants ]--------------------------------*/

#define DROP_FORCE 220.0

/*--------------------------------[ Enums ]--------------------------------*/

enum DropMode {
  DropMode_Backpack,
  DropMode_ItemsAndBackpack,
  DropMode_ItemsAndAmmo
};

/*--------------------------------[ Plugin State ]--------------------------------*/

new DropMode:g_iDropInactiveMode = DropMode_ItemsAndBackpack;

/*--------------------------------[ Player State ]--------------------------------*/

new Float:g_rgflPlayerVelocity[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  PlayerRole_Register(ROLE);

  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Assign, "@Role_Assign");
  PlayerRole_ImplementMethod(ROLE, PlayerRole_Method_Unassign, "@Role_Unassign");

  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Equip), "@Role_Equip");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(GetMaxSpeed), "@Role_GetMaxSpeed");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(GetMaxHealth), "@Role_GetMaxHealth");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Think), "@Role_Think");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Spawn), "@Role_Spawn");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(CanPickupItem), "@Role_CanPickupItem");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(CanUseButton), "@Role_CanUseButton");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Killed), "@Role_Killed");

  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropActiveItem), "@Role_DropActiveItem");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropInactiveItems), "@Role_DropInactiveItems");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(PlaySound), "@Role_PlaySound", PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(UpdateModel), "@Role_UpdateModel");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Taunt), "@Role_Taunt");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(Pain), "@Role_Pain");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(UpdateInventoryWeight), "@Role_UpdateInventoryWeight");
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropItem), "@Role_DropItem", PlayerRole_Type_Cell, PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropAmmo), "@Role_DropAmmo", PlayerRole_Type_String, PlayerRole_Type_Cell, PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropAllItems), "@Role_DropAllItems", PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropAllAmmo), "@Role_DropAllAmmo", PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropBackpack), "@Role_DropBackpack", PlayerRole_Type_Cell);
  PlayerRole_RegisterVirtualMethod(ROLE, METHOD(DropWeaponBox), "@Role_DropWeaponBox", PlayerRole_Type_Cell, PlayerRole_Type_Cell);

  CustomEvent_Register(BASE_ROLE_EVENT(UpdateInventoryWeight), CEP_Cell);
  CustomEvent_Register(BASE_ROLE_EVENT(UpdateModel), CEP_Cell);
  CustomEvent_Register(BASE_ROLE_EVENT(PlaySound), CEP_Cell, CEP_Cell);
}

public plugin_init() {
  register_plugin(ROLE_PLUGIN(Base), ZP_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
  RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage_Post", .Post = 1);
  RegisterHamPlayer(Ham_GiveAmmo, "HamHook_Player_GiveAmmo_Post", .Post = 1);
  RegisterHamPlayer(Ham_AddPlayerItem, "HamHook_Player_AddItem_Post", .Post = 1);
  RegisterHamPlayer(Ham_PainSound, "HamHook_Player_PainSound_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  CW_RegisterClassMethodHook(WEAPON(Base), CW_Method_PrimaryAttack, "CWHook_Weapon_Attack_Post", true);
  CW_RegisterClassMethodHook(WEAPON(Base), CW_Method_SecondaryAttack, "CWHook_Weapon_Attack_Post", true);
  CW_RegisterClassMethodHook(WEAPON(Grenade), CW_Method_PrimaryAttack, "CWHook_Weapon_Attack_Post", true);
  CW_RegisterClassMethodHook(WEAPON(Grenade), CW_Method_SecondaryAttack, "CWHook_Weapon_Attack_Post", true);

  CE_RegisterClassMethodHook(ENTITY(Button), CE_Method_Use, "CEHook_Button_Use_Post", true);

  bind_pcvar_num(
    register_cvar(CVAR("player_drop_inactive_mode"), "1"),
    g_iDropInactiveMode
  );
}

/*--------------------------------[ Forwards ]--------------------------------*/


public client_putinserver(pPlayer) {
  if (!is_user_bot(pPlayer)) {
    set_task(5.0, "Task_DisableMinModels", pPlayer);
  }
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_TakeDamage(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return HAM_IGNORED;

  pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]);

  return HAM_HANDLED;
}

public HamHook_Player_TakeDamage_Post(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return HAM_IGNORED;

  // Reset knockback
  set_pev(pPlayer, pev_velocity, g_rgflPlayerVelocity[pPlayer]);

  // Reset painshock
  set_ent_data_float(pPlayer, "CBasePlayer", "m_flVelocityModifier", 1.0);

  return HAM_HANDLED;
}

public HamHook_Player_GiveAmmo_Post(const pPlayer, const pInflictor, const pAttacker, Float:flDamage, iDamageBits) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return HAM_IGNORED;

  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(bShouldUpdateInventoryWeight), true);

  return HAM_HANDLED;
}

public HamHook_Player_AddItem_Post(const pPlayer) {
  if (!PlayerRole_Player_HasRole(pPlayer, ROLE)) return HAM_IGNORED;

  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(bShouldUpdateInventoryWeight), true);

  return HAM_HANDLED;
}

public HamHook_Player_PainSound_Post(const pPlayer) {
  emit_sound(pPlayer, CHAN_VOICE, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

  PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(Pain));
}

public HamHook_Player_Killed_Post(const pPlayer, const pKiller) {
  if (IS_PLAYER(pKiller) && is_user_alive(pKiller) && PlayerRole_Player_HasRole(pKiller, ROLE)) {
    PlayerRole_Player_CallMethod(pKiller, ROLE, METHOD(Taunt));
  }
}

public CWHook_Weapon_Attack_Post(const pWeapon) {
  new pPlayer = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pPlayer");

  PlayerRole_Player_SetMember(pPlayer, ROLE, MEMBER(bShouldUpdateInventoryWeight), true);
}

public CEHook_Button_Use_Post(const pButton, const pActivator) {
  if (IS_PLAYER(pActivator) && PlayerRole_Player_HasRole(pActivator, ROLE)) {
    PlayerRole_Player_CallMethod(pActivator, ROLE, METHOD(PlaySound), SOUND(Press));
  }
}

/*--------------------------------[ Methods ]--------------------------------*/

@Role_Assign(const pPlayer) {
  PlayerRole_This_SetMember(MEMBER(flInventoryWeight), 0.0);
  PlayerRole_This_SetMember(MEMBER(flNextItemPickup), 0.0);
  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), false);
  PlayerRole_This_SetMemberString(MEMBER(szModel), NULL_STRING);
  PlayerRole_This_SetMember(MEMBER(flNextIdleSound), 0.0);
  PlayerRole_This_SetMember(MEMBER(flMinIdleSoundDelay), 20.0);
  PlayerRole_This_SetMember(MEMBER(flMaxIdleSoundDelay), 40.0);
  PlayerRole_This_SetMember(MEMBER(flNextPain), 0.0);
  PlayerRole_This_SetMember(MEMBER(flTauntChance), 0.5);
  PlayerRole_This_SetMember(MEMBER(flNextSound), 0.0);
  PlayerRole_This_SetMember(MEMBER(flSpeedMultiplier), 1.0);
}

@Role_Unassign(const pPlayer) {}

@Role_Equip(const pPlayer) {
  set_pev(pPlayer, pev_max_health, PlayerRole_This_CallMethod(METHOD(GetMaxHealth)));
}

Float:@Role_GetMaxSpeed(const pPlayer) {
  return 250.0;
}

Float:@Role_GetMaxHealth(const pPlayer) {
  return 100.0;
}

@Role_Spawn(const pPlayer) {
  if (get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem") == FM_NULLENT) {
    set_ent_data_string(pPlayer, "CBasePlayer", "m_szAnimExtention", "c4");
  }

  PlayerRole_This_SetMember(MEMBER(flSpeedMultiplier), 1.0);
  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), true);
}

@Role_Think(const pPlayer) {
  if (PlayerRole_This_GetMember(MEMBER(bShouldUpdateInventoryWeight))) {
    PlayerRole_This_CallMethod(METHOD(UpdateInventoryWeight));
    PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), false);
  }

  static Float:flNextIdleSound; flNextIdleSound = PlayerRole_This_GetMember(MEMBER(flNextIdleSound));

  if (flNextIdleSound <= get_gametime()) {
    if (flNextIdleSound) {
      PlayerRole_This_CallMethod(METHOD(PlaySound), SOUND(Idle));
    }

    static Float:flMinIdleSoundDelay; flMinIdleSoundDelay = PlayerRole_This_GetMember(MEMBER(flMinIdleSoundDelay));
    static Float:flMaxIdleSoundDelay; flMaxIdleSoundDelay = PlayerRole_This_GetMember(MEMBER(flMaxIdleSoundDelay));

    PlayerRole_This_SetMember(MEMBER(flNextIdleSound), get_gametime() + random_float(flMinIdleSoundDelay, flMaxIdleSoundDelay));
  }
}

@Role_CanPickupItem(const pPlayer, const pItem) {
  return Float:PlayerRole_This_GetMember(MEMBER(flNextItemPickup)) < get_gametime();
}

@Role_CanUseButton(const pPlayer, const pButton) {
  return true;
}

@Role_Killed(const pPlayer) {
  PlayerRole_This_SetMember(MEMBER(flNextSound), get_gametime());
  PlayerRole_This_CallMethod(METHOD(PlaySound), SOUND(Death));
}

bool:@Role_UpdateModel(const pPlayer) {
  CustomEvent_SetToken(pPlayer);
  if (CustomEvent_Emit(BASE_ROLE_EVENT(UpdateModel), pPlayer) != CER_Continue) {
    return false;
  }

  static szModel[MAX_RESOURCE_PATH_LENGTH]; PlayerRole_This_GetMemberString(MEMBER(szModel), szModel, charsmax(szModel));

  if (equal(szModel, NULL_STRING)) return false;

  PlayerModel_Set(pPlayer, szModel);
  PlayerModel_Update(pPlayer);

  return true;
}

bool:@Role_PlaySound(const pPlayer, ZP_RoleSound:iSound) {
  static Float:flNextSound; flNextSound = PlayerRole_This_GetMember(MEMBER(flNextSound));
  if (flNextSound > get_gametime()) return false;

  CustomEvent_SetToken(pPlayer);
  if (CustomEvent_Emit(BASE_ROLE_EVENT(PlaySound), pPlayer, iSound) != CER_Continue) {
    return false;
  }

  PlayerRole_This_SetMember(MEMBER(flNextSound), get_gametime() + 0.5);

  return true;
}

@Role_Taunt(const pPlayer) {
  static Float:flTauntChance; flTauntChance = PlayerRole_This_GetMember(MEMBER(flTauntChance));

  if (random_float(0.0, 1.0) > flTauntChance) return;

  PlayerRole_This_CallMethod(METHOD(PlaySound), SOUND(Taunt));
}

@Role_Pain(const pPlayer) {
  static Float:flNextPain; flNextPain = PlayerRole_This_GetMember(MEMBER(flNextPain));

  if (flNextPain > get_gametime()) return;

  PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(PlaySound), SOUND(Pain));

  PlayerRole_This_SetMember(MEMBER(flNextPain), get_gametime() + 1.0);
}

/*--------------------------------[ Role Inventory Methods ]--------------------------------*/

Float:@Role_UpdateInventoryWeight(const pPlayer) {
  static Float:flWeight; flWeight = 0.0;

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pWeapon; pWeapon = get_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", iSlot);

    while (pWeapon != FM_NULLENT) {
      if (CW_IsInstanceOf(pWeapon, WEAPON(Base)) || CW_IsInstanceOf(pWeapon, WEAPON(Grenade))) {
        flWeight += Float:CW_GetMember(pWeapon, ZP_Weapon_Base_Member_flWeight);

        static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; CW_GetMemberString(pWeapon, CW_Member_szPrimaryAmmo, szAmmo, charsmax(szAmmo));
        if (!equal(szAmmo, NULL_STRING) && CW_Ammo_IsRegistered(szAmmo)) {
          static iClip; iClip = CW_GetMember(pWeapon, CW_Member_iClip);
          flWeight += iClip * Float:CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(flWeight));
        }
      }

      pWeapon = get_ent_data_entity(pWeapon, "CBasePlayerItem", "m_pNext");
    }
  }

  for (new iAmmoType = 0; iAmmoType < 32; ++iAmmoType) {
    static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);
    if (!iAmmo) continue;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH];
    if (CW_AmmoGroup_GetAmmoByType(AMMO_GROUP, iAmmoType, szAmmo, charsmax(szAmmo)) == -1) {
      continue;
    }

    flWeight += iAmmo * Float:CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(flWeight));
  }

  PlayerRole_This_SetMember(MEMBER(flInventoryWeight), flWeight);

  CustomEvent_SetToken(pPlayer);
  CustomEvent_Emit(BASE_ROLE_EVENT(UpdateInventoryWeight), pPlayer);

  return flWeight;
}

@Role_DropActiveItem(const pPlayer) {
  new pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem == FM_NULLENT) return false;

  new pNextItem = get_ent_data_entity(pActiveItem, "CBasePlayerItem", "m_pNext");
  new pPrevItem = FM_NULLENT;
  new iActiveSlot = -1;

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", iSlot);

    pPrevItem = FM_NULLENT;

    while (pItem != FM_NULLENT) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      if (pItem == pActiveItem) {
        iActiveSlot = iSlot;
        break;
      }

      pPrevItem = pItem;
      pItem = pNextItem;
    }

    if (pItem == pActiveItem) break;
  }

  static pWeaponBox; pWeaponBox = PlayerRole_This_CallMethod(METHOD(DropItem), pActiveItem, BASE_ROLE_DROP_FLAG(UseViewAngles));
  if (pWeaponBox == FM_NULLENT) return false;

  if (pPrevItem != FM_NULLENT) {
    set_ent_data_entity(pPrevItem, "CBasePlayerItem", "m_pNext", pNextItem);
  } else {
    set_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", pNextItem, iActiveSlot);
  }

  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), true);
  
  return true;
}

@Role_DropInactiveItems(const pPlayer) {
  static const DropFlags:iDropBackpackFlags = (
    BASE_ROLE_DROP_FLAG(SkipActive) |
    BASE_ROLE_DROP_FLAG(ReverseDirection) |
    BASE_ROLE_DROP_FLAG(ReverseAngles)
  );

  static const DropFlags:iDropFlags = (
    BASE_ROLE_DROP_FLAG(SkipActive) |
    BASE_ROLE_DROP_FLAG(RandomDirection) |
    BASE_ROLE_DROP_FLAG(RandomAngles) |
    BASE_ROLE_DROP_FLAG(RandomForce)
  );

  switch (g_iDropInactiveMode) {
    case DropMode_Backpack: {
      PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropBackpack), iDropBackpackFlags);
    }
    case DropMode_ItemsAndBackpack: {
      PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropAllItems), iDropFlags);
      PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropBackpack), iDropBackpackFlags);
    }
    case DropMode_ItemsAndAmmo: {
      PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropAllItems), iDropFlags);
      PlayerRole_Player_CallMethod(pPlayer, ROLE, METHOD(DropAllAmmo), iDropFlags);
    }
  }
}

@Role_DropItem(const pPlayer, const pItem, DropFlags:iDropFlags) {
  if (!ExecuteHamB(Ham_CS_Item_CanDrop, pItem)) return FM_NULLENT;

  new pPlayer = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pPlayer");
  if (pPlayer == FM_NULLENT) return FM_NULLENT;
  
  new pWeaponBox = PlayerRole_This_CallMethod(METHOD(DropWeaponBox), DROP_FORCE, iDropFlags);
  if (pWeaponBox == FM_NULLENT) return FM_NULLENT;

  dllfunc(DLLFunc_Spawn, pWeaponBox);

  static iId; iId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");

  if (get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem") == pItem) {
    static pLastItem; pLastItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pLastItem");

    ExecuteHamB(Ham_Item_Holster, pItem, 0);

    if (pLastItem != pItem && pLastItem != FM_NULLENT) {
      set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", pLastItem);
      ExecuteHamB(Ham_Item_Deploy, pLastItem);
      set_ent_data_entity(pPlayer, "CBasePlayer", "m_pLastItem", FM_NULLENT);
    } else {
      set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", FM_NULLENT);
      ExecuteHamB(Ham_Weapon_RetireWeapon, pItem);
      set_ent_data_entity(pPlayer, "CBasePlayer", "m_pLastItem", pLastItem);
    }
  }

  set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) &~ (1<<iId));

  CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackItem), pItem);

  static iPrimaryAmmoType; iPrimaryAmmoType = get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
  static iClip; iClip = get_ent_data(pItem, "CBasePlayerWeapon", "m_iClip");

  if (iClip == -1 && iPrimaryAmmoType > 0) {
    static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; 
    CW_GetMemberString(pItem, CW_Member_szPrimaryAmmo, szAmmo, charsmax(szAmmo));

    if (!equal(szAmmo, NULL_STRING)) {
      static iPrimaryAmmoAmount; iPrimaryAmmoAmount = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoType);
      static iPackSize; iPackSize = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));
      static iAmmoToPack; iAmmoToPack = iPackSize != -1 ? min(iPrimaryAmmoAmount, iPackSize) : iPrimaryAmmoAmount;

      if (iAmmoToPack > 0) {
        CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackAmmo), szAmmo, iAmmoToPack);
        set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iPrimaryAmmoAmount - iAmmoToPack, iPrimaryAmmoType);
      }
    }
  }

  dllfunc(DLLFunc_Spawn, pWeaponBox);

  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), true);

  return pWeaponBox;
}

@Role_DropAmmo(const pPlayer, const szAmmo[], iAmount, DropFlags:iDropFlags) {
  new iAmmoType = CW_Ammo_GetType(szAmmo);
  if (iAmmoType == -1) return 0;

  new iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);
  if (!iAmmo) return 0;
  
  new pWeaponBox = PlayerRole_This_CallMethod(METHOD(DropWeaponBox), DROP_FORCE, iDropFlags);
  if (pWeaponBox == FM_NULLENT) return 0;

  iAmount = min(iAmount, iAmmo);

  CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackAmmo), szAmmo, iAmount);

  static szPackModel[MAX_RESOURCE_PATH_LENGTH]; CW_Ammo_GetMetadataString(szAmmo, AMMO_METADATA(szPackModel), szPackModel, charsmax(szPackModel));

  engfunc(EngFunc_SetModel, pWeaponBox, szPackModel);
  set_pev(pWeaponBox, pev_sequence, CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iSequence)));

  set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmo - iAmount, iAmmoType);

  /*
    This logic allows to correctly handle drop ammo for weapons like satchels.
    After dropping ammo for active weapon like that the weapon will be redeployed.
  */
  new pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  if (pActiveItem != FM_NULLENT) {
    if (iAmmoType == get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType")) {
      new iClip = get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iClip");
      if (iClip == -1) {
        ExecuteHamB(Ham_Item_Deploy, pActiveItem);
      }
    }
  }

  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), true);

  return iAmount;
}

@Role_DropAllItems(const pPlayer, DropFlags:iDropFlags) {
  new pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");

  new pItemToSkip = FM_NULLENT;
  if (iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
    pItemToSkip = pActiveItem;
  }

  if (pActiveItem != FM_NULLENT) {
    if (~iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
      ExecuteHamB(Ham_Item_Holster, pActiveItem, 0);
    }

    set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", FM_NULLENT);
  }

  set_ent_data_entity(pPlayer, "CBasePlayer", "m_pLastItem", FM_NULLENT);

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    static pPrevItem; pPrevItem = FM_NULLENT;

    set_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", FM_NULLENT, iSlot);

    while (pItem != FM_NULLENT) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      set_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext", FM_NULLENT);

      if (
        pItem != pItemToSkip &&
        ExecuteHamB(Ham_CS_Item_CanDrop, pItem) &&
        PlayerRole_This_CallMethod(METHOD(DropItem), pItem, iDropFlags) != FM_NULLENT
      ) {
        static iId; iId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");
        set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) & ~(1 << iId));
        pItem = FM_NULLENT;
      }

      static pItemToLink; pItemToLink = pItem == FM_NULLENT ? pNextItem : pItem;
      
      if (pPrevItem != FM_NULLENT) {
        set_ent_data_entity(pPrevItem, "CBasePlayerItem", "m_pNext", pItemToLink);
      } else {
        set_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", pItemToLink, iSlot);
      }

      if (pItem != FM_NULLENT) {
        pPrevItem = pItem;
      }

      pItem = pNextItem;
    }
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
    set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", pActiveItem);
  }
}

@Role_DropAllAmmo(const pPlayer, DropFlags:iDropFlags) {
  new iAmmoTypesNum = 0;

  static bool:rgbAmmoShouldSkip[32];

  for (new iAmmoType = 0; iAmmoType < 32; ++iAmmoType) {
    rgbAmmoShouldSkip[iAmmoType] = false;
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
      static pItem; pItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", iSlot);

      while (pItem != FM_NULLENT) {
        static iAmmoType; iAmmoType = get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");

        rgbAmmoShouldSkip[iAmmoType] = true;

        pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
      }
    }
  }

  for (new iAmmoType = 0; iAmmoType < 32; ++iAmmoType) {
    if (rgbAmmoShouldSkip[iAmmoType]) continue;

    static iAmmo; iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);
    if (!iAmmo) continue;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH];
    if (CW_AmmoGroup_GetAmmoByType(AMMO_GROUP, iAmmoType, szAmmo, charsmax(szAmmo)) == -1) {
      continue;
    }

    // Can't drop ammo for weapons like grenades
    static iPackSize; iPackSize = CW_Ammo_GetMetadata(szAmmo, AMMO_METADATA(iPackSize));
    if (iPackSize == -1) continue;

    iPackSize = iPackSize ? iPackSize : 1;

    while (iAmmo > 0) {
      iAmmo -= PlayerRole_This_CallMethod(METHOD(DropAmmo), szAmmo, iPackSize, iDropFlags);
    }

    iAmmoTypesNum++;
  }

  return iAmmoTypesNum;
}

@Role_DropBackpack(const pPlayer, DropFlags:iDropFlags) {
  new pWeaponBox = PlayerRole_This_CallMethod(METHOD(DropWeaponBox), DROP_FORCE, iDropFlags | BASE_ROLE_DROP_FLAG(ReverseDirection));
  if (pWeaponBox == FM_NULLENT) return FM_NULLENT;

  new pActiveItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem");
  new iActivePrimaryAmmoType = pActiveItem != FM_NULLENT ? get_ent_data(pActiveItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType") : -1;

  if (pActiveItem != FM_NULLENT) {
    if (~iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
      ExecuteHamB(Ham_Item_Holster, pActiveItem, 0);
    }

    set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", FM_NULLENT);
  }

  set_ent_data_entity(pPlayer, "CBasePlayer", "m_pLastItem", FM_NULLENT);

  new bool:bItemsPacked = false;

  new pItemToSkip = FM_NULLENT;
  if (iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
    pItemToSkip = pActiveItem;
  }

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    static pPrevItem; pPrevItem = FM_NULLENT;

    set_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", FM_NULLENT, iSlot);

    while (pItem != FM_NULLENT) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      set_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext", FM_NULLENT);

      if (
        pItem != pItemToSkip &&
        ExecuteHamB(Ham_CS_Item_CanDrop, pItem) &&
        CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackItem), pItem)
      ) {
        static iId; iId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");
        set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) & ~(1 << iId));
        bItemsPacked = true;
        pItem = FM_NULLENT;
      }

      static pItemToLink; pItemToLink = pItem == FM_NULLENT ? pNextItem : pItem;
      
      if (pPrevItem != FM_NULLENT) {
        set_ent_data_entity(pPrevItem, "CBasePlayerItem", "m_pNext", pItemToLink);
      } else {
        set_ent_data_entity(pPlayer, "CBasePlayer", "m_rgpPlayerItems", pItemToLink, iSlot);
      }

      if (pItem != FM_NULLENT) {
        pPrevItem = pItem;
      }

      pItem = pNextItem;
    }
  }

  for (new iAmmoType = 0; iAmmoType < 32; ++iAmmoType) {
    if ((iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) && iAmmoType == iActivePrimaryAmmoType) continue;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH];
    if (CW_AmmoGroup_GetAmmoByType(AMMO_GROUP, iAmmoType, szAmmo, charsmax(szAmmo)) == -1) {
      continue;
    }

    new iAmmo = get_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", iAmmoType);

    if (iAmmo > 0) {
      CE_CallMethod(pWeaponBox, WEAPONBOX_METHOD(PackAmmo), szAmmo, iAmmo);
      set_ent_data(pPlayer, "CBasePlayer", "m_rgAmmo", 0, iAmmoType);
      bItemsPacked = true;
    }
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(SkipActive)) {
    set_ent_data_entity(pPlayer, "CBasePlayer", "m_pActiveItem", pActiveItem);
  }

  if (!bItemsPacked) {
    engfunc(EngFunc_RemoveEntity, pWeaponBox);
    return FM_NULLENT;
  }

  PlayerRole_This_SetMember(MEMBER(bShouldUpdateInventoryWeight), true);

  return pWeaponBox;
}

@Role_DropWeaponBox(const pPlayer, Float:flMaxForce, DropFlags:iDropFlags) {
  new pWeaponBox = rg_create_entity(ENTITY(WeaponBox), true);
  if (pWeaponBox == FM_NULLENT) return FM_NULLENT;

  static Float:vecOrigin[3]; pev(pPlayer, pev_origin, vecOrigin);
  static Float:vecVelocity[3]; pev(pPlayer, pev_velocity, vecVelocity);
  static Float:vecAngles[3]; pev(pPlayer, pev_angles, vecAngles);

  vecAngles[0] = 0.0;

  static Float:vecDropAngles[3];
  if (iDropFlags & BASE_ROLE_DROP_FLAG(UseViewAngles)) {
    pev(pPlayer, pev_v_angle, vecDropAngles);
  } else {
    xs_vec_copy(vecAngles, vecDropAngles);
  }

  static Float:vecDirection[3];
  if (iDropFlags & BASE_ROLE_DROP_FLAG(RandomDirection)) {
    xs_vec_set(vecDirection, random_float(-1.0, 1.0), random_float(-1.0, 1.0), 0.0);
    xs_vec_normalize(vecDirection, vecDirection);
  } else {
    angle_vector(vecDropAngles, ANGLEVECTOR_FORWARD, vecDirection);
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(RandomAngles)) {
    xs_vec_set(vecDropAngles, 0.0, random_float(-180.0, 180.0), 0.0);
  } else {
    xs_vec_set(vecDropAngles, 0.0, -vecDropAngles[1], 0.0);
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(ReverseDirection)) {
    xs_vec_neg(vecDirection, vecDirection);
  }

  if (iDropFlags & BASE_ROLE_DROP_FLAG(ReverseAngles)) {
    vector_to_angle(vecDirection, vecDropAngles);
    vecAngles[1] = vecAngles[1] + 180.0;
  }

  xs_vec_add_scaled(vecOrigin, vecDirection, 16.0, vecOrigin);

  engfunc(EngFunc_SetOrigin, pWeaponBox, vecOrigin);
  dllfunc(DLLFunc_Spawn, pWeaponBox);

  if (iDropFlags & BASE_ROLE_DROP_FLAG(RandomForce)) {
    xs_vec_add_scaled(vecVelocity, vecDirection, random_float(flMaxForce / 2, flMaxForce), vecVelocity);
  } else {
    xs_vec_add_scaled(vecVelocity, vecDirection, flMaxForce, vecVelocity);
  }

  set_pev(pWeaponBox, pev_angles, vecAngles);
  set_pev(pWeaponBox, pev_velocity, vecVelocity);

  return pWeaponBox;
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_DisableMinModels(const iTaskId) {
  new pPlayer = iTaskId;

  if (!is_user_connected(pPlayer)) return;

  client_cmd(pPlayer, "cl_minmodels %d", 0);
}
