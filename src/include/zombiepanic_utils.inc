// #define ITEM_FLAG_SELECTONEMPTY     1
// #define ITEM_FLAG_NOAUTORELOAD      2
// #define ITEM_FLAG_NOAUTOSWITCHEMPTY 4
// #define ITEM_FLAG_LIMITINWORLD      8
// #define ITEM_FLAG_EXHAUSTIBLE       16 // A player can totally exhaust their ammo supply and lose this weapon

stock bool:UTIL_IsPlayer(pEntity) {
    static c_iMaxPlayers;
    if (!c_iMaxPlayers) {
      c_iMaxPlayers = get_maxplayers();
    }

    return (pEntity > 0 && pEntity <= c_iMaxPlayers);
}

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
    static iszWeaponbox = 0;
    static const szAmmoList[15][] = {
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

    if (!iszWeaponbox) {
        iszWeaponbox = engfunc(EngFunc_AllocString, "weaponbox");
    }


    new iWeaponBox = engfunc(EngFunc_CreateNamedEntity, iszWeaponbox);
    dllfunc(DLLFunc_Spawn, iWeaponBox);

    set_member(iWeaponBox, m_WeaponBox_rgiszAmmo, szAmmoList[iAmmoId], 0);
    set_member(iWeaponBox, m_WeaponBox_rgAmmo, iAmount, 0);
    set_member(iWeaponBox, m_WeaponBox_cAmmoTypes, 1);

    return iWeaponBox;
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
    new pMaster = engfunc(EngFunc_FindEntityByString, 0, "targetname", szMaster);

    if (pMaster && (ExecuteHam(Ham_ObjectCaps, pMaster) & FCAP_MASTER)) {
        return !!ExecuteHamB(Ham_IsTriggered, pMaster, pActivator);
    }

    return true;
}

stock UTIL_CalculateWeaponSpread(pWeapon, const Float:vecSpread[3], Float:flMovementFactor, Float:flFirstShotModifier, Float:flDuckFactor, Float:flAirFactor, Float:vecOut[3]) {
  new pPlayer = get_member(pWeapon, m_pPlayer);
  new iShotsFired = get_member(pWeapon, m_Weapon_iShotsFired);
  new iPlayerFlags = pev(pPlayer, pev_flags);

  xs_vec_copy(vecSpread, vecOut);
  
  static Float:vecVelocity[3];
  pev(pPlayer, pev_velocity, vecVelocity);
  if (xs_vec_len(vecVelocity) > 0) {
    if (iShotsFired == 0) {
      flMovementFactor *= flFirstShotModifier;
    }

    xs_vec_mul_scalar(vecOut, flMovementFactor, vecOut);
  }

  if (iPlayerFlags & FL_DUCKING) {
    xs_vec_mul_scalar(vecOut, flDuckFactor, vecOut);
  }

  if (~iPlayerFlags & FL_ONGROUND) {
    xs_vec_mul_scalar(vecOut, flAirFactor, vecOut);
  }
}
