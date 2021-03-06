#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_rounds>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] Weaponbox"
#define AUTHOR "Hedgehog Fog"

#define MAX_AMMO_SLOTS 32

new gmsgAmmoPickup;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    gmsgAmmoPickup = get_user_msgid("AmmoPickup");

    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch", .Post = 0);
    RegisterHookChain(RG_CSGameRules_RemoveGuns, "OnRemoveGuns", .post = 1);
}

public OnWeaponBoxTouch(pWeaponBox, pToucher) {
    if (!pev_valid(pWeaponBox)) {
        return HAM_IGNORED;
    }

    if (~pev(pWeaponBox, pev_flags) & FL_ONGROUND) {
        return HAM_SUPERCEDE;
    }

    if (!UTIL_IsPlayer(pToucher)) {
        return HAM_IGNORED;
    }

    if (!is_user_alive(pToucher)) {
        return HAM_IGNORED;
    }

    if (GetHamReturnStatus() < HAM_SUPERCEDE) {
        if (!get_member_game(m_bFreezePeriod)) {
            PickupWeaponBox(pToucher, pWeaponBox);
        }
    }

    return HAM_SUPERCEDE;
}

public OnRemoveGuns() {
    new pWeaponBox;
    while((pWeaponBox = engfunc(EngFunc_FindEntityByString, pWeaponBox, "classname", "weaponbox")) > 0) {
        Remove(pWeaponBox);
    }
}

PickupWeaponBox(pPlayer, pWeaponBox) {
    if (ZP_Player_IsZombie(pPlayer)) {
        return;
    }
    
    new bDestroy = PickupWeaponBoxItems(pPlayer, pWeaponBox);
    bDestroy = PickupWeaponBoxAmmo(pPlayer, pWeaponBox) && bDestroy;

    if (bDestroy) {
        set_pev(pWeaponBox, pev_flags, FL_KILLME);
    }
}

bool:PickupWeaponBoxItems(pPlayer, pWeaponBox) {
    new bool:bResult = true;

    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot); // get main item
        set_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, -1, iSlot); // reset main item

        new iPrevBoxItem = -1;
        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext); // get next item
            set_member(pItem, m_pNext, -1); // reset next item

            new iId = get_member(pItem, m_iId);
            
            new bAmmoExtracted = ExtractAmmo(pItem, pPlayer);

            new pPlayerItem = FindPlayerItemById(pPlayer, iId);
            if (pPlayerItem != -1) { // return item to weaponbox if player has the item
                if (!bAmmoExtracted) {
                    // if (get_member(pItem, m_Weapon_iClip) != -1 || get_member(pItem, m_Weapon_iPrimaryAmmoType) <= 0) {
                        if (iPrevBoxItem == -1) {
                            set_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, pItem, iSlot); // set main item
                        } else {
                            set_member(iPrevBoxItem, m_pNext, pItem); // add item to the list
                        }

                        iPrevBoxItem = pItem;
                        bResult = false;
                    // }
                }
            } else {
                if (ExecuteHamB(Ham_AddPlayerItem, pPlayer, pItem)) {
                    ExecuteHamB(Ham_Item_AttachToPlayer, pItem, pPlayer); // add item to the player
                    emit_sound(pPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                }
            }

            pItem = pNextItem;
        }
    }

    return bResult;
}

bool:PickupWeaponBoxAmmo(pPlayer, pWeaponBox) {
    new bool:bResult = true;

    for (new iSlot = 0; iSlot < MAX_AMMO_SLOTS; ++iSlot) {
        new iAmount = get_member(pWeaponBox, m_WeaponBox_rgAmmo, iSlot);

        static szAmmoName[16];
        get_member(pWeaponBox, m_WeaponBox_rgiszAmmo, szAmmoName, charsmax(szAmmoName), iSlot);

        if (szAmmoName[0] == '^0') {
            continue;
        }

        new iAmmoId = UTIL_GetAmmoId(szAmmoName);
        new iAmmoHandler = ZP_Ammo_GetHandlerById(iAmmoId);
        if (iAmmoHandler == -1) {
            continue;
        }
        
        iAmount -= AddAmmo(pPlayer, iAmmoHandler, iAmount);
        set_member(pWeaponBox, m_WeaponBox_rgAmmo, iAmount, iSlot);

        if (!iAmount) {
            set_member(pWeaponBox, m_WeaponBox_rgiszAmmo, 0, iSlot);
        } else {
            bResult = false;
        }
    }

    return bResult;
}

bool:ExtractAmmo(pItem, pPlayer) {
    new iAmmoId = get_member(pItem, m_Weapon_iPrimaryAmmoType);
    if (iAmmoId <= 0) {
        return false;
    }

    new iAmmoAmount = get_member(pItem, m_Weapon_iDefaultAmmo);
    if (!iAmmoAmount) {
        return false;
    }

    new iAmmoHandler = ZP_Ammo_GetHandlerById(iAmmoId);
    if (iAmmoHandler == -1) {
        return false;
    }
 
    iAmmoAmount -= AddAmmo(pPlayer, iAmmoHandler, iAmmoAmount);
    set_member(pItem, m_Weapon_iDefaultAmmo, iAmmoAmount);

    return !iAmmoAmount;
}

AddAmmo(pPlayer, iAmmoHandler, iAmount) {
    new iAmmoId = ZP_Ammo_GetId(iAmmoHandler);

    static szAmmo[16];
    ZP_Ammo_GetName(iAmmoHandler, szAmmo, charsmax(szAmmo));

    iAmount = ZP_Player_AddAmmo(pPlayer, szAmmo, iAmount);

    if (iAmount) {
        emessage_begin(MSG_ONE, gmsgAmmoPickup, _, pPlayer);
        ewrite_byte(iAmmoId);
        ewrite_byte(iAmount);
        emessage_end();

        emit_sound(pPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }

    return iAmount;
}

FindPlayerItemById(pPlayer, iId) {
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot);
        
        while (pItem != -1) {
            if (iId == get_member(pItem, m_iId)) {
                return pItem;
            }

            pItem = get_member(pItem, m_pNext);
        }
    }

    return -1;
}

Remove(pWeaponBox) {
    Free(pWeaponBox);
    RemoveEntity(pWeaponBox);
}

Free(pWeaponBox) {
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot);
        set_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, -1, iSlot);

        while (pItem != -1) {
            new pNextItem = get_member(pItem, m_pNext);
            RemoveEntity(pItem);
            pItem = pNextItem;
        }
    }
}

RemoveEntity(pEntity) {
    set_pev(pEntity, pev_flags, FL_KILLME);
    dllfunc(DLLFunc_Think, pEntity);
}
