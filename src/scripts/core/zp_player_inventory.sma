#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Player Inventory"
#define AUTHOR "Hedgehog Fog"

#define AMMO_COUNT 15

new const g_rgszAmmoName[AMMO_COUNT][] = {
    "",
    "338Magnum", 
    "762Nato",
    "556NatoBox", 
    "556Nato",
    "buckshot", 
    "45ACP", 
    "57mm", 
    "50AE", 
    "357SIG",
    "9mm", 
    "Flashbang",
    "HEGrenade", 
    "SmokeGrenade", 
    "C4"
};

new g_pPlayerSelectedAmmo[MAX_PLAYERS + 1];
new g_iszWeaponBox;

public plugin_precache() {
  precache_model(ZP_WEAPONBOX_MODEL);

  g_iszWeaponBox = engfunc(EngFunc_AllocString, "weaponbox");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);
    RegisterHam(Ham_Killed, "player", "OnPlayerKilled", .Post = 0);
}

public plugin_natives() {
  register_native("ZP_Player_DropBackpack", "Native_DropBackpack");
  register_native("ZP_Player_GetAmmo", "Native_GetAmmo");
  register_native("ZP_Player_SetAmmo", "Native_SetAmmo");
  register_native("ZP_Player_AddAmmo", "Native_AddAmmo");
  register_native("ZP_Player_DropAmmo", "Native_DropAmmo");
  register_native("ZP_Player_NextAmmo", "Native_NextAmmo");
}

public Native_DropAmmo(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  DropPlayerSelectedAmmo(pPlayer);
}

public Native_NextAmmo(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  SelectNextPlayerAmmo(pPlayer);
}

public Native_DropBackpack(iPluginId, iArgc) {
  new pPlayer = get_param(1);

  DropBackpack(pPlayer);
}

public Native_GetAmmo(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  static szAmmo[16];
  get_string(2, szAmmo, charsmax(szAmmo));
  
  return GetAmmo(pPlayer, szAmmo);
}

public bool:Native_SetAmmo(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  static szAmmo[16];
  get_string(2, szAmmo, charsmax(szAmmo));
  new iValue = get_param(3);

  return SetAmmo(pPlayer, szAmmo, iValue);
}

public Native_AddAmmo(iPluginId, iArgc) {
  new pPlayer = get_param(1);
  static szAmmo[16];
  get_string(2, szAmmo, charsmax(szAmmo));
  new iValue = get_param(3);

  return AddAmmo(pPlayer, szAmmo, iValue);
}

public OnPlayerKilled(pPlayer) {
  DropBackpack(pPlayer);
}

public OnPlayerSpawn_Post(pPlayer) {
  g_pPlayerSelectedAmmo[pPlayer] = -1;
  SelectNextPlayerAmmo(pPlayer, false);
}

DropBackpack(pPlayer) {
  new pActiveItem = get_member(pPlayer, m_pActiveItem);
  new iActiveSlot;

  if (pActiveItem != -1) {
    // remove active item from player's inventory
    TakePlayerItem(pPlayer, pActiveItem, iActiveSlot);
  }

  // drop unactive items
  new iWeaponBox = DropPlayerWeaponBox(pPlayer);
  // new pItemsCount = PackPlayerItems(pPlayer, iWeaponBox);
  DropPlayerItems(pPlayer);
  new iAmmoTypesCount = PackPlayerAmmo(pPlayer, iWeaponBox);

  if (iAmmoTypesCount) {
    engfunc(EngFunc_SetModel, iWeaponBox, ZP_WEAPONBOX_MODEL);
  } else {
    engfunc(EngFunc_RemoveEntity, iWeaponBox);
  }

  if (pActiveItem != -1) {
    // return the active item to player's inventory for the default drop logic
    set_member(pActiveItem, m_pPlayer, pPlayer);
    set_member(pPlayer, m_pActiveItem, pActiveItem);
    set_member(pPlayer, m_rgpPlayerItems, pActiveItem, iActiveSlot);
  }

  ZP_Player_UpdateSpeed(pPlayer);
}

DropPlayerWeaponBox(pPlayer) {
  new iWeaponBox = engfunc(EngFunc_CreateNamedEntity, g_iszWeaponBox);
  dllfunc(DLLFunc_Spawn, iWeaponBox);

  ThrowPlayerItem(pPlayer, iWeaponBox);

  return iWeaponBox;
}

ThrowPlayerItem(pPlayer, pEntity) {
  static Float:vecAngles[3];
  pev(pPlayer, pev_angles, vecAngles);
  vecAngles[0] = 0.0;
  vecAngles[2] = 0.0;
  set_pev(pEntity, pev_angles, vecAngles);

  static Float:vecOrigin[3];
  pev(pPlayer, pev_origin, vecOrigin);
  engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
}

TakePlayerItem(pPlayer, pItemToDrop, &_iSlot = 0) {
  new pActiveItem = get_member(pPlayer, m_pActiveItem);

  if (pItemToDrop == pActiveItem) {
    set_member(pPlayer, m_pActiveItem, -1);
  }

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);

    new iPrevItem = -1;
    while (pItem != -1) {
      new iNextItem = get_member(pItem, m_pNext);

      if (pItem == pItemToDrop) {
        if (iPrevItem == -1) {
          set_member(pPlayer, m_rgpPlayerItems, iNextItem, iSlot);
        } else {
          set_member(iPrevItem, m_pNext, iNextItem);
        }

        set_member(pItem, m_pNext, -1);
        set_member(pItem, m_pPlayer, -1);
        _iSlot = iSlot;
        return pItem;
      }

      iPrevItem = pItem;
      pItem = iNextItem;
    }
  }

  ZP_Player_UpdateSpeed(pPlayer);

  return -1;
}

DropPlayerItems(pPlayer) {
  set_member(pPlayer, m_pActiveItem, -1);

  for (new iSlot = 0; iSlot < 6; ++iSlot) {
    new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);
    
    set_member(pPlayer, m_rgpPlayerItems, -1, iSlot);

    while (pItem != -1) {
      new iNextItem = get_member(pItem, m_pNext);

      if (ExecuteHamB(Ham_CS_Item_CanDrop, pItem)) {
        new iClip = get_member(pItem, m_Weapon_iClip);
        new iPrimaryAmmoType = get_member(pItem, m_Weapon_iPrimaryAmmoType);

        if (iClip == -1 && iPrimaryAmmoType > 0) {
          new iPrimaryAmmoAmount = get_member(pPlayer, m_rgAmmo, iPrimaryAmmoType);
          if (iPrimaryAmmoAmount > 0) {
            new iWeaponBox = DropPlayerItem(pPlayer, pItem, iSlot);
            set_member(iWeaponBox, m_WeaponBox_rgAmmo, iPrimaryAmmoAmount, iPrimaryAmmoType);
            set_member(iWeaponBox, m_WeaponBox_rgiszAmmo, g_rgszAmmoName[iPrimaryAmmoType], iPrimaryAmmoType);
            set_member(iWeaponBox, m_WeaponBox_cAmmoTypes, 1);
            set_member(pPlayer, m_rgAmmo, 0, iPrimaryAmmoType);
          }
        } else {
          DropPlayerItem(pPlayer, pItem, iSlot);
        }
      } else {
        get_member(pPlayer, m_rgpPlayerItems, iSlot);
        
        new pPlayerItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);
        if (pPlayerItem != -1) {
          set_member(pPlayerItem, m_pNext, pItem);
        } else {
          set_member(pPlayer, m_rgpPlayerItems, pItem, iSlot);
        }
      }

      pItem = iNextItem;
    }
  }

  ZP_Player_UpdateSpeed(pPlayer);
}

DropPlayerItem(pPlayer, pItem, iSlot) {
  new iWeaponBox = DropPlayerWeaponBox(pPlayer);

  set_pev(pItem, pev_spawnflags, pev(pItem, pev_spawnflags) | SF_NORESPAWN);
  set_pev(pItem, pev_effects, EF_NODRAW);
  set_pev(pItem, pev_movetype, MOVETYPE_NONE);
  set_pev(pItem, pev_solid, SOLID_NOT);
  set_pev(pItem, pev_model, 0);
  set_pev(pItem, pev_modelindex, 0);
  set_pev(pItem, pev_owner, iWeaponBox);

  new iWeaponId = get_member(pItem, m_iId);
  set_pev(pPlayer, pev_weapons, pev(pPlayer, pev_weapons) &~ (1<<iWeaponId));

  set_member(pItem, m_pPlayer, -1);
  set_member(pItem, m_pNext, -1);

  set_member(iWeaponBox, m_WeaponBox_rgpPlayerItems, pItem, iSlot);

  static Float:vecVelocity[3];
  vecVelocity[0] = random_float(-350.0, 350.0);
  vecVelocity[1] = random_float(-350.0, 350.0);
  vecVelocity[2] = random_float(0.0, 350.0);

  set_pev(iWeaponBox, pev_velocity, vecVelocity);

  dllfunc(DLLFunc_Spawn, iWeaponBox); // fix model

  ZP_Player_UpdateSpeed(pPlayer);

  return iWeaponBox;
}

PackPlayerAmmo(pPlayer, iWeaponBox) {
  new iWeaponBoxAmmoIndex = 0;
  for (new iAmmoId = 0; iAmmoId < AMMO_COUNT; ++iAmmoId) {
    new iBpAmmo = get_member(pPlayer, m_rgAmmo, iAmmoId);

    if (iBpAmmo > 0) {
      set_member(iWeaponBox, m_WeaponBox_rgiszAmmo, g_rgszAmmoName[iAmmoId], iWeaponBoxAmmoIndex);
      set_member(iWeaponBox, m_WeaponBox_rgAmmo, iBpAmmo, iWeaponBoxAmmoIndex);
      set_member(pPlayer, m_rgAmmo, 0, iAmmoId);
      iWeaponBoxAmmoIndex++;
    }
  }

  return iWeaponBoxAmmoIndex;
}

SelectNextPlayerAmmo(pPlayer, bool:bShowMessage = true) {
  new iAmmoIndex = g_pPlayerSelectedAmmo[pPlayer];
  do {
    iAmmoIndex++;

    if (iAmmoIndex >= ZP_Ammo_GetCount()) {
      iAmmoIndex = 0;
    }
  } while (ZP_Ammo_GetPackSize(iAmmoIndex) == -1 && iAmmoIndex != g_pPlayerSelectedAmmo[pPlayer]);

  g_pPlayerSelectedAmmo[pPlayer] = iAmmoIndex;

  static szAmmoName[32];
  ZP_Ammo_GetName(g_pPlayerSelectedAmmo[pPlayer], szAmmoName, charsmax(szAmmoName));

  if (bShowMessage) {
    client_print(pPlayer, print_chat, "Selected %s ammo", szAmmoName);
  }
}

DropPlayerSelectedAmmo(pPlayer) {
  new iAmmoIndex = g_pPlayerSelectedAmmo[pPlayer];
  new iAmmoId = ZP_Ammo_GetId(iAmmoIndex);
  new iBpAmmo = get_member(pPlayer, m_rgAmmo, iAmmoId);

  if (iBpAmmo <= 0) {
    return;
  }

  new iPackSize = min(ZP_Ammo_GetPackSize(iAmmoIndex), iBpAmmo);
  new iWeaponBox = UTIL_CreateAmmoBox(iAmmoId, iPackSize);
  ThrowPlayerItem(pPlayer, iWeaponBox);

  set_member(pPlayer, m_rgAmmo, iBpAmmo - iPackSize, iAmmoId);

  static szAmmoModel[64];
  ZP_Ammo_GetPackModel(iAmmoIndex, szAmmoModel, charsmax(szAmmoModel));
  engfunc(EngFunc_SetModel, iWeaponBox, szAmmoModel);

  static Float:vecThrowAngle[3];
  pev(pPlayer, pev_v_angle, vecThrowAngle);
  engfunc(EngFunc_MakeVectors, vecThrowAngle); 

  static Float:vecVelocity[3];
  get_global_vector(GL_v_forward, vecVelocity);
  xs_vec_mul_scalar(vecVelocity, random_float(400.0, 450.0), vecVelocity);
  set_pev(iWeaponBox, pev_velocity, vecVelocity);

  ZP_Player_UpdateSpeed(pPlayer);
}

GetAmmo(pPlayer, const szAmmo[]) {
  new iHandler = ZP_Ammo_GetHandler(szAmmo);
  if (iHandler == -1) {
    return 0;
  }

  new iId = ZP_Ammo_GetId(iHandler);

  return get_member(pPlayer, m_rgAmmo, iId);
}

bool:SetAmmo(pPlayer, const szAmmo[], iValue) {
  new iHandler = ZP_Ammo_GetHandler(szAmmo);
  if (iHandler == -1) {
    return false;
  }

  new iId = ZP_Ammo_GetId(iHandler);
  set_member(pPlayer, m_rgAmmo, iValue, iId);

  ZP_Player_UpdateSpeed(pPlayer);

  return true;
}

AddAmmo(pPlayer, const szAmmo[], iValue) {
  new iHandler = ZP_Ammo_GetHandler(szAmmo);
  if (iHandler == -1) {
    return 0;
  }

  new iId = ZP_Ammo_GetId(iHandler);
  new iAmount = get_member(pPlayer, m_rgAmmo, iId);
  new iNewAmount = min(iAmount + iValue, ZP_Ammo_GetMaxAmount(iHandler));
  set_member(pPlayer, m_rgAmmo, iNewAmount, iId);

  ZP_Player_UpdateSpeed(pPlayer);

  return iNewAmount - iAmount;
}
