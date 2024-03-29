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

    RegisterHam(Ham_Touch, "weaponbox", "HamHook_WeaponBox_Touch", .Post = 0);
}

public HamHook_WeaponBox_Touch(pWeaponBox, pToucher) {
    if (!pev_valid(pWeaponBox)) {
        return HAM_IGNORED;
    }

    if (~pev(pWeaponBox, pev_flags) & FL_ONGROUND) {
        return HAM_SUPERCEDE;
    }

    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    if (!is_user_alive(pToucher)) {
        return HAM_IGNORED;
    }

    if (GetHamReturnStatus() < HAM_SUPERCEDE) {
        if (!get_member_game(m_bFreezePeriod)) {
            @Player_PickupWeaponBox(pToucher, pWeaponBox);
        }
    }

    return HAM_SUPERCEDE;
}

@Player_PickupWeaponBox(this, pWeaponBox) {
    if (ZP_Player_IsZombie(this)) {
        return;
    }
    
    new bDestroy = PickupWeaponBoxItems(this, pWeaponBox);
    bDestroy = PickupWeaponBoxAmmo(this, pWeaponBox) && bDestroy;

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

            new pPlayerItem = @Player_FindItemById(pPlayer, iId);
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

        if (equal(szAmmoName, NULL_STRING)) {
            continue;
        }

        new iAmmoId = UTIL_GetAmmoId(szAmmoName);
        new iAmmoHandler = ZP_Ammo_GetHandlerById(iAmmoId);
        if (iAmmoHandler == -1) {
            continue;
        }
        
        iAmount -= @Player_AddAmmo(pPlayer, iAmmoHandler, iAmount);
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
 
    iAmmoAmount -= @Player_AddAmmo(pPlayer, iAmmoHandler, iAmmoAmount);
    set_member(pItem, m_Weapon_iDefaultAmmo, iAmmoAmount);

    return !iAmmoAmount;
}

@Player_AddAmmo(this, iAmmoHandler, iAmount) {
    new iAmmoId = ZP_Ammo_GetId(iAmmoHandler);

    static szAmmo[16];
    ZP_Ammo_GetName(iAmmoHandler, szAmmo, charsmax(szAmmo));

    iAmount = ZP_Player_AddAmmo(this, szAmmo, iAmount);

    if (iAmount) {
        emessage_begin(MSG_ONE, gmsgAmmoPickup, _, this);
        ewrite_byte(iAmmoId);
        ewrite_byte(iAmount);
        emessage_end();

        emit_sound(this, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }

    return iAmount;
}

@Player_FindItemById(pPlayer, iId) {
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
