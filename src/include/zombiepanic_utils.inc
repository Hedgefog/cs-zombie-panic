#define IS_PLAYER(%1) (%1 >= 1 && %1 <= MaxClients)

// #define ITEM_FLAG_SELECTONEMPTY     1
// #define ITEM_FLAG_NOAUTORELOAD      2
// #define ITEM_FLAG_NOAUTOSWITCHEMPTY 4
// #define ITEM_FLAG_LIMITINWORLD      8
// #define ITEM_FLAG_EXHAUSTIBLE       16 // A player can totally exhaust their ammo supply and lose this weapon

stock const AMMO_LIST[15][] = {
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

stock const ITEMS_LIST[][] = {
    "armoury_entity",
    "item_battery",
    "item_healthkit",
    "armoury_entity",
    "weaponbox",
    "weapon_shield",
    "grenade"
};

stock UTIL_Message_Dlight(
    const Float:vecOrigin[3],
    radius = 16,
    const color[3] = {255, 255, 255},
    lifeTime = 1,
    decayRate = 0
) {
    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
    write_byte(TE_DLIGHT);
    engfunc(EngFunc_WriteCoord, vecOrigin[0]);
    engfunc(EngFunc_WriteCoord, vecOrigin[1]);
    engfunc(EngFunc_WriteCoord, vecOrigin[2]);
    write_byte(radius);
    write_byte(color[0]);
    write_byte(color[1]);
    write_byte(color[2]);
    write_byte(lifeTime);
    write_byte(decayRate);
    message_end();
}

stock UTIL_CreateAmmoBox(iAmmoId, iAmount) {
    new pWeaponBox = rg_create_entity("weaponbox", true);
    dllfunc(DLLFunc_Spawn, pWeaponBox);

    set_member(pWeaponBox, m_WeaponBox_rgiszAmmo, AMMO_LIST[iAmmoId], 0);
    set_member(pWeaponBox, m_WeaponBox_rgAmmo, iAmount, 0);
    set_member(pWeaponBox, m_WeaponBox_cAmmoTypes, 1);

    return pWeaponBox;
}

stock UTIL_CreateZpAmmoBox(iAmmoHandler, iAmount = 0) {
    static szModel[64];
    ZP_Ammo_GetPackModel(iAmmoHandler, szModel, charsmax(szModel));

    if (!iAmount) {
        iAmount = ZP_Ammo_GetPackSize(iAmmoHandler);
    }

    new iAmmoId = ZP_Ammo_GetId(iAmmoHandler);

    new pWeaponBox = UTIL_CreateAmmoBox(iAmmoId, iAmount);
    engfunc(EngFunc_SetModel, pWeaponBox, szModel);

    return pWeaponBox;
}

stock UTIL_BeamPoints(const Float:vecStart[3], const Float:vecEnd[3], const color[3], iLifetime = 30) {
    message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
    write_byte(TE_BEAMPOINTS);
    write_coord(floatround(vecStart[0]));	// start position
    write_coord(floatround(vecStart[1]));
    write_coord(floatround(vecStart[2]));
    write_coord(floatround(vecEnd[0]));	// end position
    write_coord(floatround(vecEnd[1]));
    write_coord(floatround(vecEnd[2]));
    write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"));	// sprite index
    write_byte(0);	// starting frame
    write_byte(10);	// frame rate in 0.1's
    write_byte(iLifetime);	// life in 0.1's
    write_byte(2);	// line width in 0.1's
    write_byte(1);	// noise amplitude in 0.01's
    write_byte(color[0]);	// Red
    write_byte(color[1]);	// Green
    write_byte(color[2]);	// Blue
    write_byte(127);	// brightness
    write_byte(10);	// scroll speed in 0.1's
    message_end();
}

stock bool:UTIL_IsMasterTriggered(const szMaster[], pActivator) {
    if (!equal(szMaster, NULL_STRING)) {
        new pMaster = engfunc(EngFunc_FindEntityByString, 0, "targetname", szMaster);

        if (pMaster && (ExecuteHam(Ham_ObjectCaps, pMaster) & FCAP_MASTER)) {
        return !!ExecuteHamB(Ham_IsTriggered, pMaster, pActivator);
        }
    }

    return true;
}

stock Float:UTIL_CalculateWeaponSpread(pWeapon, const Float:vecSpread[3], Float:flMovementFactor, Float:flFirstShotModifier, Float:flDuckFactor, Float:flAirFactor, Float:vecOut[3]) {
    new pPlayer = get_member(pWeapon, m_pPlayer);
    new iShotsFired = get_member(pWeapon, m_Weapon_iShotsFired);
    new iPlayerFlags = pev(pPlayer, pev_flags);

    new Float:flSpreadRatio = 1.0;
    
    static Float:vecVelocity[3];
    pev(pPlayer, pev_velocity, vecVelocity);
    if (xs_vec_len(vecVelocity) > 0) {
        flSpreadRatio *= flMovementFactor;
    }

    if (iPlayerFlags & FL_DUCKING) {
        flSpreadRatio *= flDuckFactor;
    }

    if (~iPlayerFlags & FL_ONGROUND) {
        flSpreadRatio *= flAirFactor;
    }

    if (!iShotsFired) {
        flSpreadRatio *= flFirstShotModifier;
    }

    xs_vec_mul_scalar(vecSpread, flSpreadRatio, vecOut);

    return flSpreadRatio;
}

stock bool:UTIL_IsPlayerSpectator(pPlayer) {
    new iTeam = get_member(pPlayer, m_iTeam);
    return iTeam < 1 || iTeam > 2;
}

stock UTIL_PlayerKnockback(pVictim, pAttacker, Float:flForce) {
    static Float:vecOrigin[3];
    pev(pVictim, pev_origin, vecOrigin);

    static Float:vecAttackerOrigin[3];
    pev(pAttacker, pev_origin, vecAttackerOrigin);

    static Float:vecDir[3];
    xs_vec_sub(vecOrigin, vecAttackerOrigin, vecDir);

    new Float:flLen = xs_vec_len_2d(vecDir);

    static Float:vecVelocity[3];
    pev(pVictim, pev_velocity, vecVelocity);
    for (new i = 0; i < 2; ++i) {
        vecVelocity[i] = (vecDir[i] / flLen) * flForce;
    }

    set_pev(pVictim, pev_velocity, vecVelocity);
}

stock UTIL_InitWithSpawner(pEntity, pSpawner) {
    new Float:vecOrigin[3];
    pev(pSpawner, pev_origin, vecOrigin);
    engfunc(EngFunc_SetOrigin, pEntity, vecOrigin);
    // log_amx("UTIL_InitWithSpawner %d [%.4f, %.4f, %.4f]", pEntity, vecOrigin[0], vecOrigin[1], vecOrigin[2]);

    new Float:vecAngles[3];
    pev(pSpawner, pev_angles, vecAngles);
    set_pev(pEntity, pev_angles, vecAngles);

    set_pev(pEntity, pev_owner, pSpawner);

    engfunc(EngFunc_DropToFloor, pEntity);
}

stock UTIL_HandleSpawnerItemTouch(pEntity, iCeSpawnerHandler) {
    if (pev(pEntity, pev_flags) & FL_KILLME) {
        new pOwner = pev(pEntity, pev_owner);
        if (pev_valid(pOwner) && CE_GetHandlerByEntity(pOwner) == iCeSpawnerHandler) {
            CE_Kill(pOwner);
        }
    }
}

stock UTIL_GetAmmoId(const szAmmoName[]) {
    new iSize = sizeof(AMMO_LIST);
    for (new iAmmoId = 0; iAmmoId < iSize; ++iAmmoId) {
        if (equal(AMMO_LIST[iAmmoId], szAmmoName)) {
            return iAmmoId;
        }
    }

    return -1;
}

stock bool:UTIL_IsUsableButton(pButton, pPlayer) {
    new iszMaster = get_ent_data(pButton, "CBaseToggle", "m_sMaster");

    if (iszMaster) {
        static szMaster[32];
        engfunc(EngFunc_SzFromIndex, iszMaster, szMaster, charsmax(szMaster));

        if (!UTIL_IsMasterTriggered(szMaster, pPlayer)) {
            return false;
        }
    } 

    if (get_ent_data(pButton, "CBaseToggle", "m_toggle_state") != TS_AT_BOTTOM) {
        return false;
    }

    return true;
}
