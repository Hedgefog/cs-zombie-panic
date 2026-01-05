#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <api_assets>
#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_internal>

/*--------------------------------[ Helpers ]--------------------------------*/

#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_ITEM_TYPES 6
#define MAX_AMMO_SLOTS 32

/*--------------------------------[ Assets ]--------------------------------*/

new g_szModel[MAX_RESOURCE_PATH_LENGTH];
new g_szBounceSound[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_pItemInfo;

new Trie:g_itAmmoNameMap = Invalid_Trie;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  g_itAmmoNameMap = TrieCreate();
  g_pItemInfo = CreateHamItemInfo();

  Asset_Precache(ASSET_LIBRARY, ASSET_MODEL(Weaponbox), g_szModel, charsmax(g_szModel));
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(WeaponBoxBounce), g_szBounceSound, charsmax(g_szBounceSound));

  CE_ExtendClass(ENTITY(WeaponBox));
  CE_ImplementClassMethod(ENTITY(WeaponBox), CE_Method_Create, "@Entity_Create");
  CE_ImplementClassMethod(ENTITY(WeaponBox), CE_Method_Spawn, "@Entity_Spawn");
  CE_ImplementClassMethod(ENTITY(WeaponBox), CE_Method_Touch, "@Entity_Touch");
  CE_RegisterClassMethod(ENTITY(WeaponBox), WEAPONBOX_METHOD(PackItem), "@Entity_PackItem", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY(WeaponBox), WEAPONBOX_METHOD(PackAmmo), "@Entity_PackAmmo", CE_Type_String, CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY(WeaponBox), WEAPONBOX_METHOD(BounceTouch), "@Entity_BounceTouch", CE_Type_Cell);
  CE_RegisterClassMethod(ENTITY(WeaponBox), WEAPONBOX_METHOD(BounceSound), "@Entity_BounceSound");
  CE_RegisterClassMethod(ENTITY(WeaponBox), WEAPONBOX_METHOD(ResetBounceSound), "@Entity_ResetBounceSound");
}

public plugin_init() {
  register_plugin(ENTITY_EXTENSION_PLUGIN(WeaponBox), ZP_VERSION, "Hedgehog Fog");
}

public plugin_end() {
  TrieDestroy(g_itAmmoNameMap);
  FreeHamItemInfo(g_pItemInfo);
}

/*--------------------------------[ Methods ]--------------------------------*/

@Entity_Create(const this) {
  CE_CallBaseMethod();

  CE_SetMemberString(this, CE_Member_szModel, g_szModel);
  CE_SetMemberString(this, WEAPONBOX_MEMBER(szBounceSound), g_szBounceSound);
  CE_SetMember(this, WEAPONBOX_MEMBER(iItemsNum), 0);
  CE_SetMember(this, WEAPONBOX_MEMBER(bDirty), false);
}

@Entity_Spawn(const this) {
  CE_CallBaseMethod();

  static szModel[MAX_RESOURCE_PATH_LENGTH]; pev(this, pev_model, szModel, charsmax(szModel));

  if (equal(szModel, "models/w_weaponbox.mdl")) {
    CE_GetMemberString(this, CE_Member_szModel, szModel, charsmax(szModel));
    engfunc(EngFunc_SetModel, this, szModel);
  }

  set_pev(this, pev_nextthink, get_gametime() + 0.1);
  set_pev(this, pev_movetype, MOVETYPE_BOUNCE);
  set_pev(this, pev_friction, 0.8);
}

@Entity_Touch(const this, const pToucher) {
  if (!pToucher || pev(pToucher, pev_solid) == SOLID_BSP) {
    CE_CallMethod(this, WEAPONBOX_METHOD(BounceTouch), pToucher);
  }

  if (~pev(this, pev_flags) & FL_ONGROUND) return;
  if (!IS_PLAYER(pToucher)) return;
  if (!ZP_GameRules_CanPickupItem(this, pToucher)) return;

  static iItemsNum;
  static bool:bItemsPickedUp; bItemsPickedUp = @Player_PickupWeaponBoxItems(pToucher, this, iItemsNum);

  static iAmmoNum;
  static bool:bAmmosPickedUp; bAmmosPickedUp = @Player_PickupWeaponBoxAmmo(pToucher, this, iAmmoNum);

  if (iItemsNum > 0) {
    emit_sound(pToucher, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  } else if (iAmmoNum > 0) {
    emit_sound(pToucher, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }

  if (bItemsPickedUp && bAmmosPickedUp) {
    set_pev(this, pev_flags, pev(this, pev_flags) | FL_KILLME);
  }
}

@Entity_PackItem(const this, const pItem) {
  static iSlot; iSlot = ExecuteHamB(Ham_Item_ItemSlot, pItem) - 1;
  static pSlotItem; pSlotItem = get_ent_data_entity(this, "CWeaponBox", "m_rgpPlayerItems", iSlot);
  static iItemsNum; iItemsNum = CE_GetMember(this, WEAPONBOX_MEMBER(iItemsNum));

  set_ent_data_entity(pItem, "CBasePlayerItem", "m_pPlayer", FM_NULLENT);
  set_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext", FM_NULLENT);

  if (pSlotItem != FM_NULLENT) {
    static pNextSlotItem; pNextSlotItem = FM_NULLENT;
    
    while ((pNextSlotItem = get_ent_data_entity(pSlotItem, "CBasePlayerItem", "m_pNext")) != FM_NULLENT) {
      pSlotItem = pNextSlotItem;
    }

    set_ent_data_entity(pSlotItem, "CBasePlayerItem", "m_pNext", pItem);
  } else {
    set_ent_data_entity(this, "CWeaponBox", "m_rgpPlayerItems", pItem, iSlot + 1);
  }

  set_pev(pItem, pev_spawnflags, pev(pItem, pev_spawnflags) | SF_NORESPAWN);
  set_pev(pItem, pev_movetype, MOVETYPE_NONE);
  set_pev(pItem, pev_solid, SOLID_NOT);
  set_pev(pItem, pev_effects, EF_NODRAW);
  set_pev(pItem, pev_modelindex, 0);
  set_pev(pItem, pev_model, NULL_STRING);
  set_pev(pItem, pev_owner, this);

  CE_SetMember(this, WEAPONBOX_MEMBER(iItemsNum), iItemsNum += 1);

  if (iItemsNum) {
    if (iItemsNum == 1) {
      static szBounceSound[MAX_RESOURCE_PATH_LENGTH]; copy(szBounceSound, charsmax(szBounceSound), NULL_STRING);
      if (CW_IsInstanceOf(pItem, CW_Class_Base)) {
        CW_GetMemberString(pItem, WEAPON_BASE_MEMBER(szBounceSound), szBounceSound, charsmax(szBounceSound));
      }

      if (!equal(szBounceSound, NULL_STRING)) {
        CE_SetMemberString(this, WEAPONBOX_MEMBER(szBounceSound), szBounceSound);
      }
    } else {
      CE_CallMethod(this, WEAPONBOX_METHOD(ResetBounceSound));
    }
  }
}

@Entity_PackAmmo(const this, const szAmmo[], iAmount) {
  if (!iAmount) return;

  static iAmmoTypesNum; iAmmoTypesNum = get_ent_data(this, "CWeaponBox", "m_cAmmoTypes");

  set_ent_data(this, "CWeaponBox", "m_rgAmmo", iAmount, iAmmoTypesNum);
  set_ent_data(this, "CWeaponBox", "m_rgiszAmmo", GetAmmoNameAllocatedString(szAmmo), iAmmoTypesNum);
  set_ent_data(this, "CWeaponBox", "m_cAmmoTypes", (iAmmoTypesNum += 1));

  if (iAmmoTypesNum) {
    if (iAmmoTypesNum == 1) {
      static szBounceSound[MAX_RESOURCE_PATH_LENGTH]; copy(szBounceSound, charsmax(szBounceSound), NULL_STRING);
      CW_Ammo_GetMetadataString(szAmmo, AMMO_METADATA(szBounceSound), szBounceSound, charsmax(szBounceSound));

      if (!equal(szBounceSound, NULL_STRING)) {
        CE_SetMemberString(this, WEAPONBOX_MEMBER(szBounceSound), szBounceSound);
      }
    } else {
      CE_CallMethod(this, WEAPONBOX_METHOD(ResetBounceSound));
    }
  }
}

@Entity_BounceTouch(const this, const pToucher) {
  if (pev(this, pev_flags) & FL_ONGROUND) {
    static Float:vecVelocity[3]; pev(this, pev_velocity, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
    set_pev(this, pev_velocity, vecVelocity);
  } else {
    CE_CallMethod(this, WEAPONBOX_METHOD(BounceSound));
  }
}

@Entity_BounceSound(const this) {
  static iPitch; iPitch = 95 + random(29);
  static szBounceSound[MAX_RESOURCE_PATH_LENGTH]; CE_GetMemberString(this, WEAPONBOX_MEMBER(szBounceSound), szBounceSound, charsmax(szBounceSound));
  emit_sound(this, CHAN_VOICE, szBounceSound, VOL_NORM, ATTN_NORM, 0, iPitch);
}

@Entity_ResetBounceSound(const this) {  
  CE_SetMemberString(this, WEAPONBOX_MEMBER(szBounceSound), g_szBounceSound);
}

/*--------------------------------[ Player Methods ]--------------------------------*/

bool:@Player_PickupWeaponBoxItems(const &this, const &pWeaponBox, &iItemsNum) {
  new bool:bResult = true;

  iItemsNum = 0;

  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", iSlot);
    if (pItem == FM_NULLENT) continue;

    set_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", FM_NULLENT, iSlot);

    static pPrevItem; pPrevItem = FM_NULLENT;
    while (pItem != FM_NULLENT) {
      static pNextItem; pNextItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");

      set_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext", FM_NULLENT);

      if (@Player_PickupWeaponBoxItem(pWeaponBox, pItem, this)) {
        iItemsNum++;
        pItem = FM_NULLENT;
      }

      static pItemToLink; pItemToLink = pItem == FM_NULLENT ? pNextItem : pItem;
      
      if (pPrevItem != FM_NULLENT) {
        set_ent_data_entity(pPrevItem, "CBasePlayerItem", "m_pNext", pItemToLink);
      } else {
        set_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", pItemToLink, iSlot);
      }

      if (pItem != FM_NULLENT) {
        bResult = false;
        pPrevItem = pItem;
      }

      pItem = pNextItem;
    }
  }

  return bResult;
}

bool:@Player_PickupWeaponBoxItem(const &pWeaponBox, const &pItem, const &pPlayer) {
  new iId = get_ent_data(pItem, "CBasePlayerItem", "m_iId");
  new bool:bResult = false;
  
  new pOriginal = @Player_FindItemById(pPlayer, iId);

  if (pOriginal != FM_NULLENT) {
    if (ExecuteHamB(Ham_Item_AddDuplicate, pItem, pOriginal)) {
      bResult = true;
    }
  } else {
    if (ExecuteHamB(Ham_AddPlayerItem, pPlayer, pItem)) {
      ExecuteHamB(Ham_Item_AttachToPlayer, pItem, pPlayer);
      bResult = true;
    }
  }

  // Mark weaponbox as "dirty" if the weapon is "dirty"
  if (CW_IsInstanceOf(pItem, CW_Class_Base)) {
    if (CW_GetMember(pItem, CW_Member_bDirty)) {
      CE_SetMember(pWeaponBox, WEAPONBOX_MEMBER(bDirty), true);
    }
  }

  return bResult;
}

bool:@Player_PickupWeaponBoxAmmo(const &this, const &pWeaponBox, &iAmmoNum) {
  new bool:bResult = true;

  iAmmoNum = 0;

  for (new iSlot = 0; iSlot < MAX_AMMO_SLOTS; ++iSlot) {
    static iAmount; iAmount = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgAmmo", iSlot);
    if (!iAmount) continue;

    static iszAmmo; iszAmmo = get_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", iSlot);
    if (!iszAmmo) continue;

    static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; engfunc(EngFunc_SzFromIndex, iszAmmo, szAmmo, charsmax(szAmmo));

    if (equal(szAmmo, NULL_STRING)) continue;

    static iAddedAmmo; iAddedAmmo = @Player_AddAmmo(this, szAmmo, iAmount);

    if (iAddedAmmo) {
      set_ent_data(pWeaponBox, "CWeaponBox", "m_rgAmmo", (iAmount -= iAddedAmmo), iSlot);
      CE_SetMember(pWeaponBox, WEAPONBOX_MEMBER(bDirty), true);
      iAmmoNum++;
    }

    if (!iAmount) {
      set_ent_data(pWeaponBox, "CWeaponBox", "m_rgiszAmmo", 0, iSlot);
    } else {
      bResult = false;
    }
  }

  return bResult;
}

@Player_AddAmmo(const &this, const szAmmo[], iAmount) {
  new bool:bIsCustomAmmo = CW_Ammo_IsRegistered(szAmmo);

  new iAmmoType;
  new iMaxAmount; 

  if (bIsCustomAmmo) {
    iAmmoType = CW_Ammo_GetType(szAmmo);
    iMaxAmount = CW_Ammo_GetMaxAmount(szAmmo);
  } else {
    static pItem; pItem = @Player_FindItemByPrimaryAmmo(this, szAmmo);
    ExecuteHamB(Ham_Item_GetItemInfo, pItem, g_pItemInfo);
    iAmmoType = get_ent_data(pItem, "CBasePlayerWeapon", "m_iPrimaryAmmoType");
    iMaxAmount = GetHamItemInfo(g_pItemInfo, Ham_ItemInfo_iMaxAmmo1);
  }

  if (iAmmoType == -1) return 0;

  new iCurrentAmount = get_ent_data(this, "CBasePlayer", "m_rgAmmo", iAmmoType);

  ExecuteHamB(Ham_GiveAmmo, this, iAmount, szAmmo, iMaxAmount);

  return get_ent_data(this, "CBasePlayer", "m_rgAmmo", iAmmoType) - iCurrentAmount;
}

@Player_FindItemById(const &this, iId) {
  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    
    while (pItem != FM_NULLENT) {
      if (iId == get_ent_data(pItem, "CBasePlayerItem", "m_iId")) return pItem;

      pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
    }
  }

  return -1;
}

@Player_FindItemByPrimaryAmmo(const &this, const szAmmo[]) {
  for (new iSlot = 0; iSlot < MAX_ITEM_TYPES; ++iSlot) {
    static pItem; pItem = get_ent_data_entity(this, "CBasePlayer", "m_rgpPlayerItems", iSlot);
    
    while (pItem != FM_NULLENT) {
      ExecuteHamB(Ham_Item_GetItemInfo, pItem, g_pItemInfo);

      static szAmmo[CW_MAX_AMMO_NAME_LENGTH]; GetHamItemInfo(g_pItemInfo, Ham_ItemInfo_pszAmmo1, szAmmo, charsmax(szAmmo));
      if (equal(szAmmo, szAmmo)) return pItem;

      pItem = get_ent_data_entity(pItem, "CBasePlayerItem", "m_pNext");
    }
  }

  return FM_NULLENT;
}

/*--------------------------------[ Functions ]--------------------------------*/

GetAmmoNameAllocatedString(const szName[]) {
  static iszAmmo;
  if (!TrieGetCell(g_itAmmoNameMap, szName, iszAmmo)) {
    TrieSetCell(g_itAmmoNameMap, szName, (iszAmmo = engfunc(EngFunc_AllocString, szName)));
  }

  return iszAmmo;
}
