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

new g_rgpPlayerSelectedAmmo[MAX_PLAYERS + 1];

public plugin_precache() {
    precache_model(ZP_WEAPONBOX_MODEL);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed", .Post = 0);
}

public plugin_natives() {
    register_native("ZP_Player_DropUnactiveWeapons", "Native_DropUnactiveWeapons");
    register_native("ZP_Player_DropUnactiveAmmo", "Native_DropUnactiveAmmo");
    register_native("ZP_Player_GetAmmo", "Native_GetAmmo");
    register_native("ZP_Player_SetAmmo", "Native_SetAmmo");
    register_native("ZP_Player_AddAmmo", "Native_AddAmmo");
    register_native("ZP_Player_DropAmmo", "Native_DropAmmo");
    register_native("ZP_Player_NextAmmo", "Native_NextAmmo");
    register_native("ZP_Player_GetSelectedAmmo", "Native_GetSelectedAmmo");
    register_native("ZP_Player_SetSelectedAmmo", "Native_SetSelectedAmmo");
}

public Native_DropAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    @Player_DropSelectedAmmo(pPlayer);
}

public Native_NextAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    @Player_SelectNextAmmo(pPlayer, true);
}

public Native_DropUnactiveWeapons(iPluginid, iArgc) {
    new pPlayer = get_param(1);

    @Player_DropUnactiveWeapons(pPlayer);
}
public Native_DropUnactiveAmmo(iPluginid, iArgc) {
    new pPlayer = get_param(1);

    @Player_DropAmmo(pPlayer, true);
}

public Native_GetAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    static szAmmo[16];
    get_string(2, szAmmo, charsmax(szAmmo));
    
    return @Player_GetAmmo(pPlayer, szAmmo);
}

public bool:Native_SetAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    static szAmmo[16];
    get_string(2, szAmmo, charsmax(szAmmo));
    new iValue = get_param(3);

    return @Player_SetAmmo(pPlayer, szAmmo, iValue);
}

public Native_AddAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    static szAmmo[16];
    get_string(2, szAmmo, charsmax(szAmmo));
    new iValue = get_param(3);

    return @Player_AddAmmo(pPlayer, szAmmo, iValue);
}

public Native_GetSelectedAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return g_rgpPlayerSelectedAmmo[pPlayer];
}

public Native_SetSelectedAmmo(iPluginId, iArgc) {
    new pPlayer = get_param(1);
    
    static szAmmo[16];
    get_string(2, szAmmo, charsmax(szAmmo));

    new iAmmoHandler = ZP_Ammo_GetHandler(szAmmo);
    if (iAmmoHandler == -1) {
        return;
    }

    g_rgpPlayerSelectedAmmo[pPlayer] = iAmmoHandler;
}

public HamHook_Player_Killed(pPlayer) {
    @Player_DropUnactiveWeapons(pPlayer);
    @Player_DropAmmo(pPlayer, false);
}

public HamHook_Player_Spawn_Post(pPlayer) {
    g_rgpPlayerSelectedAmmo[pPlayer] = 0;
    @Player_SelectNextAmmo(pPlayer, false);
}

@Player_DropAmmo(this, bool:bUnactiveOnly) {
    new pWeaponBox = @Player_DropWeaponBox(this);
    new iAmmoTypesCount = @Player_PackAmmo(this, pWeaponBox, bUnactiveOnly);

    if (!iAmmoTypesCount) {
        engfunc(EngFunc_RemoveEntity, pWeaponBox);
        return;
    }

    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPONBOX_MODEL);

    static Float:vecThrowAngle[3];
    pev(this, pev_v_angle, vecThrowAngle);
    engfunc(EngFunc_MakeVectors, vecThrowAngle); 

    static Float:vecVelocity[3];
    get_global_vector(GL_v_forward, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, -125.0, vecVelocity);
    set_pev(pWeaponBox, pev_velocity, vecVelocity);

    static Float:vecAngles[3];
    vector_to_angle(vecVelocity, vecAngles);
    vecAngles[0] = 0.0;
    vecAngles[1] = vecThrowAngle[1] - 180.0;
    vecAngles[2] = 0.0;

    set_pev(pWeaponBox, pev_angles, vecAngles);

    ZP_Player_UpdateSpeed(this);
}

@Player_DropUnactiveWeapons(this) {
    new pActiveItem = get_member(this, m_pActiveItem);
    new iActiveSlot;

    if (pActiveItem != -1) {
        // remove active item from player's inventory
        @Player_TakeItem(this, pActiveItem, iActiveSlot);
    }

    @Player_DropItems(this);

    if (pActiveItem != -1) {
        // return the active item to player's inventory for the default drop logic
        set_member(pActiveItem, m_pPlayer, this);
        set_member(this, m_pActiveItem, pActiveItem);
        set_member(this, m_rgpPlayerItems, pActiveItem, iActiveSlot);
    }

    ZP_Player_UpdateSpeed(this);
}

@Player_DropWeaponBox(this) {
    new pWeaponBox = rg_create_entity("weaponbox", true);
    dllfunc(DLLFunc_Spawn, pWeaponBox);

    @Player_ThrowItem(this, pWeaponBox);

    return pWeaponBox;
}

@Player_ThrowItem(this, pEntity) {
    static Float:vecAngles[3];
    pev(this, pev_angles, vecAngles);
    vecAngles[0] = 0.0;
    vecAngles[2] = 0.0;
    set_pev(pEntity, pev_angles, vecAngles);

    static Float:vecOrigin[3];
    pev(this, pev_origin, vecOrigin);
    engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
}

@Player_TakeItem(this, pItemToDrop, &_iSlot) {
    new pActiveItem = get_member(this, m_pActiveItem);

    if (pItemToDrop == pActiveItem) {
        set_member(this, m_pActiveItem, -1);
    }

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(this, m_rgpPlayerItems, iSlot);

        new pPrevItem = -1;
        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext);

            if (pItem == pItemToDrop) {
                if (pPrevItem == -1) {
                    set_member(this, m_rgpPlayerItems, pNextItem, iSlot);
                } else {
                    set_member(pPrevItem, m_pNext, pNextItem);
                }

                set_member(pItem, m_pNext, -1);
                set_member(pItem, m_pPlayer, -1);
                _iSlot = iSlot;
                ZP_Player_UpdateSpeed(this);
                return pItem;
            }

            pPrevItem = pItem;
            pItem = pNextItem;
        }
    }

    return -1;
}

@Player_DropItems(this) {
    set_member(this, m_pActiveItem, -1);

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(this, m_rgpPlayerItems, iSlot);
        
        set_member(this, m_rgpPlayerItems, -1, iSlot);

        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext);

            if (ExecuteHamB(Ham_CS_Item_CanDrop, pItem)) {
                new iClip = get_member(pItem, m_Weapon_iClip);
                new iPrimaryAmmoType = get_member(pItem, m_Weapon_iPrimaryAmmoType);

                if (iClip == -1 && iPrimaryAmmoType > 0) {
                    new iPrimaryAmmoAmount = get_member(this, m_rgAmmo, iPrimaryAmmoType);
                    if (iPrimaryAmmoAmount > 0) {
                        new pWeaponBox = @Player_DropItem(this, pItem, iSlot);
                        set_member(pWeaponBox, m_WeaponBox_rgAmmo, iPrimaryAmmoAmount, iPrimaryAmmoType);
                        set_member(pWeaponBox, m_WeaponBox_rgiszAmmo, AMMO_LIST[iPrimaryAmmoType], iPrimaryAmmoType);
                        set_member(pWeaponBox, m_WeaponBox_cAmmoTypes, 1);
                        set_member(this, m_rgAmmo, 0, iPrimaryAmmoType);
                    }
                } else {
                    @Player_DropItem(this, pItem, iSlot);
                }
            } else {
                get_member(this, m_rgpPlayerItems, iSlot);
                
                new pPlayerItem = get_member(this, m_rgpPlayerItems, iSlot);
                if (pPlayerItem != -1) {
                    set_member(pPlayerItem, m_pNext, pItem);
                } else {
                    set_member(this, m_rgpPlayerItems, pItem, iSlot);
                }
            }

            pItem = pNextItem;
        }
    }

    set_member(this, m_pLastItem, -1);

    ZP_Player_UpdateSpeed(this);
}

@Player_DropItem(this, pItem, iSlot) {
    new pWeaponBox = @Player_DropWeaponBox(this);

    set_pev(pItem, pev_spawnflags, pev(pItem, pev_spawnflags) | SF_NORESPAWN);
    set_pev(pItem, pev_effects, EF_NODRAW);
    set_pev(pItem, pev_movetype, MOVETYPE_NONE);
    set_pev(pItem, pev_solid, SOLID_NOT);
    set_pev(pItem, pev_model, 0);
    set_pev(pItem, pev_modelindex, 0);
    set_pev(pItem, pev_owner, pWeaponBox);

    new iWeaponId = get_member(pItem, m_iId);
    set_pev(this, pev_weapons, pev(this, pev_weapons) &~ (1<<iWeaponId));

    set_member(pItem, m_pPlayer, -1);
    set_member(pItem, m_pNext, -1);

    set_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, pItem, iSlot);

    static Float:vecVelocity[3];
    vecVelocity[0] = random_float(-250.0, 250.0);
    vecVelocity[1] = random_float(-250.0, 250.0);
    vecVelocity[2] = random_float(0.0, 250.0);

    set_pev(pWeaponBox, pev_velocity, vecVelocity);

    dllfunc(DLLFunc_Spawn, pWeaponBox); // fix model

    ZP_Player_UpdateSpeed(this);

    return pWeaponBox;
}

@Player_PackAmmo(this, pWeaponBox, bool:bUnactiveOnly) {
    new iWeaponBoxAmmoIndex = 0;

    new iSize = sizeof(AMMO_LIST);
    for (new iAmmoId = 0; iAmmoId < iSize; ++iAmmoId) {
        if (bUnactiveOnly) {
            new bool:bSkip = false;

            for (new iSlot = 0; iSlot < 6; ++iSlot) {
                new pItem = get_member(this, m_rgpPlayerItems, iSlot);

                while (pItem != -1) {
                    if (iAmmoId == get_member(pItem, m_Weapon_iPrimaryAmmoType)) {
                        bSkip = true;
                        break;
                    }

                    pItem = get_member(pItem, m_pNext);
                }
            }

            if (bSkip) {
                continue;
            }
        }

        new iBpAmmo = get_member(this, m_rgAmmo, iAmmoId);

        if (iBpAmmo > 0) {
            set_member(pWeaponBox, m_WeaponBox_rgiszAmmo, AMMO_LIST[iAmmoId], iWeaponBoxAmmoIndex);
            set_member(pWeaponBox, m_WeaponBox_rgAmmo, iBpAmmo, iWeaponBoxAmmoIndex);
            set_member(this, m_rgAmmo, 0, iAmmoId);
            iWeaponBoxAmmoIndex++;
        }
    }

    return iWeaponBoxAmmoIndex;
}

@Player_SelectNextAmmo(this, bool:bShowMessage) {
    new iAmmoId;
    new iAmmoIndex = g_rgpPlayerSelectedAmmo[this];

    do {
        iAmmoIndex++;

        if (iAmmoIndex >= ZP_Ammo_GetCount()) {
            iAmmoIndex = 0;
        }

        iAmmoId = ZP_Ammo_GetId(iAmmoIndex);

        if (ZP_Ammo_GetPackSize(iAmmoIndex) != -1 && get_member(this, m_rgAmmo, iAmmoId) > 0) {
            break;
        }
    } while (iAmmoIndex != g_rgpPlayerSelectedAmmo[this]);

    new iAmmoAmount = get_member(this, m_rgAmmo, iAmmoId);
    if (g_rgpPlayerSelectedAmmo[this] == iAmmoIndex && !iAmmoAmount) {
        return;
    }

    g_rgpPlayerSelectedAmmo[this] = iAmmoIndex;

    if (bShowMessage) {
        static szAmmoName[32];
        ZP_Ammo_GetName(g_rgpPlayerSelectedAmmo[this], szAmmoName, charsmax(szAmmoName));

        new iMaxAmmo = ZP_Ammo_GetMaxAmount(iAmmoIndex);

        client_print(this, print_chat, "Selected %s ammo [%d/%d]", szAmmoName, iAmmoAmount, iMaxAmmo);
    }
}

@Player_DropSelectedAmmo(this) {
    new iAmmoIndex = g_rgpPlayerSelectedAmmo[this];
    new iAmmoId = ZP_Ammo_GetId(iAmmoIndex);
    new iBpAmmo = get_member(this, m_rgAmmo, iAmmoId);

    if (iBpAmmo <= 0) {
        return;
    }

    new iPackSize = min(ZP_Ammo_GetPackSize(iAmmoIndex), iBpAmmo);
    new pWeaponBox = UTIL_CreateAmmoBox(iAmmoId, iPackSize);
    @Player_ThrowItem(this, pWeaponBox);

    set_member(this, m_rgAmmo, iBpAmmo - iPackSize, iAmmoId);

    static szAmmoModel[64];
    ZP_Ammo_GetPackModel(iAmmoIndex, szAmmoModel, charsmax(szAmmoModel));
    engfunc(EngFunc_SetModel, pWeaponBox, szAmmoModel);

    static Float:vecThrowAngle[3];
    pev(this, pev_v_angle, vecThrowAngle);
    engfunc(EngFunc_MakeVectors, vecThrowAngle); 

    static Float:vecVelocity[3];
    get_global_vector(GL_v_forward, vecVelocity);
    xs_vec_mul_scalar(vecVelocity, random_float(400.0, 450.0), vecVelocity);
    set_pev(pWeaponBox, pev_velocity, vecVelocity);

    ZP_Player_UpdateSpeed(this);
}

@Player_GetAmmo(this, const szAmmo[]) {
    new iAmmoHandler = ZP_Ammo_GetHandler(szAmmo);
    if (iAmmoHandler == -1) {
        return 0;
    }

    new iId = ZP_Ammo_GetId(iAmmoHandler);

    return get_member(this, m_rgAmmo, iId);
}

bool:@Player_SetAmmo(this, const szAmmo[], iValue) {
    new iAmmoHandler = ZP_Ammo_GetHandler(szAmmo);
    if (iAmmoHandler == -1) {
        return false;
    }

    new iId = ZP_Ammo_GetId(iAmmoHandler);
    set_member(this, m_rgAmmo, iValue, iId);

    ZP_Player_UpdateSpeed(this);

    return true;
}

@Player_AddAmmo(this, const szAmmo[], iValue) {
    new iAmmoHandler = ZP_Ammo_GetHandler(szAmmo);
    if (iAmmoHandler == -1) {
        return 0;
    }

    new iId = ZP_Ammo_GetId(iAmmoHandler);
    new iAmount = get_member(this, m_rgAmmo, iId);
    new iNewAmount = min(iAmount + iValue, ZP_Ammo_GetMaxAmount(iAmmoHandler));
    set_member(this, m_rgAmmo, iNewAmount, iId);

    ZP_Player_UpdateSpeed(this);

    return iNewAmount - iAmount;
}
