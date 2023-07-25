#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <api_custom_entities>
#include <api_custom_weapons>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Entity] func_breakable"
#define AUTHOR "Hedgehog Fog"

new Trie:g_iSpawnObjectMap;

public plugin_precache() {
    g_iSpawnObjectMap = TrieCreate();

    TrieSetCell(g_iSpawnObjectMap, "3", engfunc(EngFunc_AllocString, ZP_WEAPON_PISTOL));
    TrieSetCell(g_iSpawnObjectMap, "4", engfunc(EngFunc_AllocString, ZP_AMMO_PISTOL));
    TrieSetCell(g_iSpawnObjectMap, "5", engfunc(EngFunc_AllocString, ZP_WEAPON_RIFLE));
    TrieSetCell(g_iSpawnObjectMap, "6", engfunc(EngFunc_AllocString, ZP_AMMO_RIFLE));
    TrieSetCell(g_iSpawnObjectMap, "7", engfunc(EngFunc_AllocString, ZP_WEAPON_SHOTGUN));
    TrieSetCell(g_iSpawnObjectMap, "8", engfunc(EngFunc_AllocString, ZP_AMMO_SHOTGUN));
    TrieSetCell(g_iSpawnObjectMap, "9", engfunc(EngFunc_AllocString, ZP_WEAPON_MAGNUM));
    TrieSetCell(g_iSpawnObjectMap, "10", engfunc(EngFunc_AllocString, ZP_AMMO_MAGNUM));
    TrieSetCell(g_iSpawnObjectMap, "11", engfunc(EngFunc_AllocString, ZP_WEAPON_GRENADE));
    TrieSetCell(g_iSpawnObjectMap, "12", engfunc(EngFunc_AllocString, ZP_WEAPON_SATCHEL));

    RegisterHam(Ham_Keyvalue, "func_breakable", "HamHook_Breakable_KeyValue_Post", .Post = 1);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_TakeDamage, "func_breakable", "HamHook_Breakable_TakeDamage_Post", .Post = 1);
}

public plugin_end() {
    TrieDestroy(g_iSpawnObjectMap);
}

public HamHook_Breakable_KeyValue_Post(pEntity, pKvdHandle) {
    new szKey[32];
    get_kvd(pKvdHandle, KV_KeyName, szKey, charsmax(szKey));

    if (!equal(szKey, "spawnobject")) {
        return HAM_IGNORED;
    }

    new szValue[32];
    get_kvd(pKvdHandle, KV_Value, szValue, charsmax(szValue));

    if (equal(szValue, NULL_STRING)) {
        return HAM_IGNORED;
    }

    new iszSpawnObject;
    if (!TrieGetCell(g_iSpawnObjectMap, szValue, iszSpawnObject)) {
        return HAM_IGNORED;
    }

    set_ent_data(pEntity, "CBreakable", "m_iszSpawnObject", iszSpawnObject);

    return HAM_HANDLED;
}

public HamHook_Breakable_TakeDamage_Post(pEntity) {
    new Float:flHealth;
    pev(pEntity, pev_health, flHealth);

    if (flHealth > 0.0) {
        return HAM_IGNORED;
    }

    static Float:vecOrigin[3];
    ExecuteHamB(Ham_BodyTarget, pEntity, 0, vecOrigin);

    static Float:vecAngles[3];
    pev(pEntity, pev_angles, vecAngles);

    new iszSpawnObject = get_ent_data(pEntity, "CBreakable", "m_iszSpawnObject");

    static szSpawnObject[64];
    engfunc(EngFunc_SzFromIndex, iszSpawnObject, szSpawnObject, charsmax(szSpawnObject));

    new CW:iCwHandler = CW_GetHandler(szSpawnObject);
    new iAmmoHandler = ZP_Ammo_GetHandler(szSpawnObject);

    new pSpawnObject = -1;
    if (iCwHandler != CW_INVALID_HANDLER) {
        pSpawnObject = CW_SpawnWeaponBox(iCwHandler);
    } else if (iAmmoHandler != -1) {
        pSpawnObject = UTIL_CreateAmmoBox(ZP_Ammo_GetId(iAmmoHandler), ZP_Ammo_GetPackSize(iAmmoHandler));

        static szModel[64];
        ZP_Ammo_GetPackModel(iAmmoHandler, szModel, charsmax(szModel));
        engfunc(EngFunc_SetModel, pSpawnObject, szModel);
    }

    if (pSpawnObject == -1) {
        return HAM_IGNORED;
    }

    engfunc(EngFunc_SetOrigin, pSpawnObject, vecOrigin);
    set_pev(pSpawnObject, pev_angles, vecAngles);

    return HAM_HANDLED;
}
