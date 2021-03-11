#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Bot Fixes"
#define AUTHOR "1.0.0"

#define MELEE_ATTACK_RANGE 128.0
#define TEAMMATE_SEARCH_RANGE 128.0
#define PANIC_RANGE 256.0
#define PICKUP_RANGE 64.0
#define PANIC_CHANCE 30.0

new Float:g_flPlayerNextThink[MAX_PLAYERS + 1];

new CW:g_iCwSwipeHandler;
new CW:g_iCwCrowbarHandler;
new CW:g_iCwGrenadeHandler;
new CW:g_iCwSatchelHandler;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    g_iCwSwipeHandler = CW_GetHandler(ZP_WEAPON_SWIPE);
    g_iCwCrowbarHandler = CW_GetHandler(ZP_WEAPON_CROWBAR);
    g_iCwGrenadeHandler = CW_GetHandler(ZP_WEAPON_GRENADE);
    g_iCwSatchelHandler = CW_GetHandler(ZP_WEAPON_SATCHEL);

    RegisterHam(Ham_Touch, "weaponbox", "OnWeaponBoxTouch", .Post = 0);
    RegisterHam(Ham_Player_PreThink, "player", "OnPlayerPreThink_Post", .Post = 1);
}

public OnWeaponBoxTouch(this, pToucher) {
    if (!UTIL_IsPlayer(pToucher)) {
        return HAM_IGNORED;
    }

    if (!is_user_bot(pToucher)) {
        return HAM_IGNORED;
    }

    if (!is_user_alive(pToucher)) {
        return HAM_IGNORED;
    }

    if (!CanPickupWeaponBox(pToucher, this, true)) {
        return HAM_SUPERCEDE;
    }

    return HAM_HANDLED;
}

public OnPlayerPreThink_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }
    
    if (!is_user_bot(pPlayer)) {
        return HAM_IGNORED;
    }

    if (g_flPlayerNextThink[pPlayer] > get_gametime()) {
        return HAM_IGNORED;
    }

    g_flPlayerNextThink[pPlayer] = get_gametime() + 0.5;

    new pActiveItem = get_member(pPlayer, m_pActiveItem);
    if (pActiveItem == -1) {
        return HAM_IGNORED;
    }

    new CW:iCwHandler = CW_GetHandlerByEntity(pActiveItem);
    if (iCwHandler == g_iCwSwipeHandler || iCwHandler == g_iCwCrowbarHandler) {
        if (ShouldAttackWithMelee(pPlayer)) {
            new pActiveItem = get_member(pPlayer, m_pActiveItem);
            CW_PrimaryAttack(pActiveItem);
            return HAM_HANDLED;
        }
    }

    if (!ZP_Player_IsZombie(pPlayer)) {
        if (ShouldPanic(pPlayer)) {
            ZP_Player_Panic(pPlayer);
            g_flPlayerNextThink[pPlayer] = get_gametime() + 5.0;
            return HAM_HANDLED;
        }

        if (ShouldDropActiveItem(pPlayer)) {
            DropActiveItem(pPlayer);
            g_flPlayerNextThink[pPlayer] = get_gametime() + 0.25;
            return HAM_HANDLED;
        }

        if (PickupNearbyItems(pPlayer)) {
            g_flPlayerNextThink[pPlayer] = get_gametime() + 1.0;
            return HAM_HANDLED;
        }

        new pTeammate = FindPlayerNearby(pPlayer, TEAMMATE_SEARCH_RANGE, ZP_HUMAN_TEAM);
        if (pTeammate != -1) {
            new iAmmoId = FindAmmoForTeammate(pPlayer, pTeammate);
            if (iAmmoId != -1) {
                DropAmmoToTeammate(pPlayer, pTeammate, iAmmoId);
                g_flPlayerNextThink[pPlayer] = get_gametime() + 2.0;
                return HAM_HANDLED;
            }

        }
    }

    return HAM_HANDLED;
}

DropActiveItem(pBot) {
    new pActiveItem = get_member(pBot, m_pActiveItem);

    new szItemName[32];
    pev(pActiveItem, pev_classname, szItemName, charsmax(szItemName));

    rg_drop_item(pBot, szItemName);
}

DropAmmoToTeammate(pBot, pTeammate, iAmmoIndex) {
    static szAmmo[16];
    ZP_Ammo_GetName(iAmmoIndex, szAmmo, charsmax(szAmmo));

    static Float:vecTarget[3];
    pev(pTeammate, pev_origin, vecTarget);
    TurnTo(pBot, vecTarget);

    ZP_Player_SetSelectedAmmo(pBot, szAmmo);
    ZP_Player_DropAmmo(pBot);
}

bool:PickupNearbyItems(pBot) {
    static Float:vecOrigin[3];
    pev(pBot, pev_origin, vecOrigin);

    new pEntity;
    new iPrevEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, PICKUP_RANGE)) != 0) {
        if (iPrevEntity >= pEntity) {
            break;
        }

        if (!pev_valid(pEntity)) {
            continue;
        }

        static szClassname[16];
        pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

        if (equal(szClassname, "weaponbox")) {
            if (CanPickupWeaponBox(pBot, pEntity, false)) {
                PickupWeaponBox(pBot, pEntity);
                return true;
            }
        }
    }

    return false;
}

PickupWeaponBox(pBot, pWeaponBox) {
    static Float:vecTarget[3];
    pev(pWeaponBox, pev_origin, vecTarget);
    TurnTo(pBot, vecTarget);

    ExecuteHamB(Ham_Touch, pWeaponBox, pBot);
}

bool:CanPickupWeaponBox(pBot, pWeaponBox, bool:bTouched) {
    if (!bTouched) {
        static Float:vecOrigin[3];
        pev(pBot, pev_origin, vecOrigin);

        static Float:vecTarget[3];
        pev(pWeaponBox, pev_origin, vecTarget);

        new pTr = create_tr2();
        engfunc(EngFunc_TraceLine, vecOrigin, vecTarget, DONT_IGNORE_MONSTERS, pBot, pTr);
        static Float:flFraction;
        get_tr2(pTr, TR_flFraction, flFraction);
        free_tr2(pTr);

        if (flFraction < 1.0) {
            return false;
        }
    }

    new bool:bContainsWeapon = false;
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot);
        if (pItem == -1) {
            continue;
        }

        if (get_member(pBot, m_rgpPlayerItems, iSlot) != -1) {
            return false;
        }

        new CW:iCwHandler = CW_GetHandlerByEntity(pItem);
        if (iCwHandler == g_iCwGrenadeHandler) {
            return false;
        }

        if (iCwHandler == g_iCwSatchelHandler) {
            return false;
        }

        new iClip = get_member(pItem, m_Weapon_iClip);
        new iPrimaryAmmoId = get_member(pItem, m_Weapon_iPrimaryAmmoType);
        new iBpAmmo = get_member(pBot, m_rgAmmo, iPrimaryAmmoId);

        if (!iClip && !iBpAmmo) {
            return false;
        }

        bContainsWeapon = true;
    }

    if (!bContainsWeapon && !bTouched) {
        for (new iSlot = 0; iSlot < 32; ++iSlot) {
            static szAmmoName[16];
            get_member(pWeaponBox, m_WeaponBox_rgiszAmmo, szAmmoName, charsmax(szAmmoName), iSlot);
            if (szAmmoName[0] == '^0') {
                continue;
            }

            new iAmmoId = UTIL_GetAmmoId(szAmmoName);

            if (ZP_Ammo_GetHandlerById(iAmmoId) == ZP_Ammo_GetHandler(ZP_AMMO_PISTOL)) {
                return true;
            }

            if (FindWeaponByAmmoId(pBot, iAmmoId)) {
                return true;
            }
        }

        return false;
    }

    return true;
}

bool:ShouldAttackWithMelee(pBot) {
    new pEnemy = FindPlayerNearby(pBot, MELEE_ATTACK_RANGE, ZP_Player_IsZombie(pBot) ? ZP_HUMAN_TEAM : ZP_ZOMBIE_TEAM);
    if (pEnemy == -1) {
        return false;
    }

    static Float:vecTarget[3];
    pev(pEnemy, pev_origin, vecTarget);
    if (!is_in_viewcone(pBot, vecTarget)) {
        return false;
    }

    return true;
}


bool:ShouldPanic(pBot) {
    static Float:flMaxSpeed;
    pev(pBot, pev_maxspeed, flMaxSpeed);

    if (flMaxSpeed > ZP_ZOMBIE_SPEED) {
        return false;
    }

    if (FindPlayerNearby(pBot, PANIC_RANGE, ZP_ZOMBIE_TEAM) == -1) {
        return false;
    }

    return random(100) < PANIC_CHANCE;
}

bool:ShouldDropActiveItem(pBot) {
    new pActiveItem = get_member(pBot, m_pActiveItem);
    if (pActiveItem == -1) {
        return false;
    }

    new iClip = get_member(pActiveItem, m_Weapon_iClip);
    if (iClip) {
        return false;
    }

    new iPrimaryAmmoId = get_member(pActiveItem, m_Weapon_iPrimaryAmmoType);
    new iBpAmmo = get_member(pBot, m_rgAmmo, iPrimaryAmmoId);
    if (iBpAmmo) {
        return false;
    }

    return true;
}

FindAmmoForTeammate(pBot, pTeammate) {
    new pTeammateActiveItem = get_member(pTeammate, m_pActiveItem);
    if (pTeammateActiveItem == -1) {
        return -1;
    }

    new iTeammateAmmoId = get_member(pTeammateActiveItem, m_Weapon_iPrimaryAmmoType);
    if (iTeammateAmmoId <= 0) {
        return -1;
    }

    new iAmmoIndex = ZP_Ammo_GetHandlerById(iTeammateAmmoId);

    static szAmmo[16];
    ZP_Ammo_GetName(iAmmoIndex, szAmmo, charsmax(szAmmo));

    if (!ZP_Player_GetAmmo(pBot, szAmmo)) {
        return -1;
    }

    if (FindWeaponByAmmoId(pBot, iTeammateAmmoId) != -1) {
        new iBpAmmo = get_member(pBot, m_rgAmmo, iTeammateAmmoId);
        new iAmmoIndex = ZP_Ammo_GetHandlerById(iTeammateAmmoId);
        new iPackSize = ZP_Ammo_GetPackSize(iAmmoIndex);
        if (iBpAmmo / iPackSize < 3) {
            return -1;
        }
    }

    return iAmmoIndex;
}

FindPlayerNearby(pBot, Float:flRange, iTeam = -1) {
    static Float:vecOrigin[3];
    pev(pBot, pev_origin, vecOrigin);

    for (new pTarget = 1; pTarget <= MaxClients; ++pTarget) {
        if (pTarget == pBot) {
            continue;
        }

        if (!is_user_connected(pTarget)) {
            continue;
        }

        if (!is_user_alive(pTarget)) {
            continue;
        }

        new iPlayerTeam = get_member(pTarget, m_iTeam);
        if (iTeam != -1 && iTeam != iPlayerTeam) {
            continue;
        }

        static Float:vecPlayerOrigin[3];
        pev(pTarget, pev_origin, vecPlayerOrigin);

        if (xs_vec_distance(vecOrigin, vecPlayerOrigin) <= flRange) {
            return pTarget;
        }
    }

    return -1;
}

FindWeaponByAmmoId(pBot, iAmmoId) {
    for (new iSlot = 0; iSlot < 6; ++iSlot) {
        new pItem = get_member(pBot, m_rgpPlayerItems, iSlot);
        while (pItem != -1) {
            if (get_member(pItem, m_Weapon_iPrimaryAmmoType) == iAmmoId) {
                return pItem;
            }

            pItem = get_member(pItem, m_pNext);
        }
    }

    return -1;
}

TurnTo(pBot, const Float:vecTarget[3]) {
    static Float:vecOrigin[3];
    pev(pBot, pev_origin, vecOrigin);

    static Float:vecViewOfs[3];
    pev(pBot, pev_view_ofs, vecViewOfs);
    vecOrigin[2] += vecViewOfs[2];

    static Float:vecDir[3];
    xs_vec_sub(vecTarget, vecOrigin, vecDir);

    static Float:vecAngles[3];
    engfunc(EngFunc_VecToAngles, vecDir, vecAngles);
    vecAngles[0] = -NormalizeAngle(vecAngles[0]);
    vecAngles[1] = NormalizeAngle(vecAngles[1]);
    vecAngles[2] = 0.0;

    set_pev(pBot, pev_angles, vecAngles);
    set_pev(pBot, pev_v_angle, vecAngles);
    set_pev(pBot, pev_fixangle, 1);
}

Float:NormalizeAngle(Float:flAngle) {
    new iDirection = flAngle > 0 ? 1 : -1;
    new Float:flAbsAngle = flAngle * iDirection;

    new Float:flFixedAngle = (flAbsAngle - (360.0 * floatround(flAbsAngle / 360.0, floatround_floor)));
    if (flFixedAngle > 180.0) {
      flFixedAngle -= 360.0;
    }

    flFixedAngle *= iDirection;

    return flFixedAngle;
}
