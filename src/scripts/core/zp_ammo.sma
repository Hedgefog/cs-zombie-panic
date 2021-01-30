#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Ammo"
#define AUTHOR "Hedgehog Fog"

enum AmmoData {
    Ammo_Name,
    Ammo_Id,
    Ammo_PackSize,
    Ammo_PackModel,
    Ammo_MaxAmount
}

new Array:g_rgAmmo[AmmoData];
new Trie:g_iAmmoMap;
new g_rgAmmoMap[15] = { -1, ... };
new g_iAmmoCount = 0;

public plugin_precache() {
    InitStorage();
    RegisterAmmo(ZP_AMMO_PISTOL, 10, 7, ZP_AMMO_PISTOL_MODEL, 70);
    RegisterAmmo(ZP_AMMO_RIFLE, 4, 30, ZP_AMMO_RIFLE_MODEL, 240);
    RegisterAmmo(ZP_AMMO_SHOTGUN, 5, 6, ZP_AMMO_SHOTGUN_MODEL, 60);
    RegisterAmmo(ZP_AMMO_MAGNUM, 1, 6, ZP_AMMO_MAGNUM_MODEL, 36);
    RegisterAmmo(ZP_AMMO_SATCHEL, 14, -1, NULL_STRING, 1);
    RegisterAmmo(ZP_AMMO_GRENADE, 12, -1, NULL_STRING, 1);
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_natives() {
    register_native("ZP_Ammo_GetHandler", "Native_GetHandler");
    register_native("ZP_Ammo_GetHandlerById", "Native_GetHandlerById");
    register_native("ZP_Ammo_GetName", "Native_GetName");
    register_native("ZP_Ammo_GetId", "Native_GetId");
    register_native("ZP_Ammo_GetPackSize", "Native_GetPackSize");
    register_native("ZP_Ammo_GetPackModel", "Native_GetPackModel");
    register_native("ZP_Ammo_GetCount", "Native_GetCount");
    register_native("ZP_Ammo_GetMaxAmount", "Native_GetMaxAmount");
}

public plugin_end() {
    for (new i = 0; i < _:AmmoData; ++i) {
        new Array:irgData = Array:g_rgAmmo[AmmoData:i];

        if (irgData != Invalid_Array) {
            ArrayDestroy(irgData);
        }
    }

    TrieDestroy(g_iAmmoMap);
}

public Native_GetHandler(iPluginId, iArgc) {
    static szName[32];
    get_string(1, szName, charsmax(szName));

    new iAmmoIndex;
    if (TrieGetCell(g_iAmmoMap, szName, iAmmoIndex)) {
        return iAmmoIndex;
    }

    return -1;
}

public Native_GetHandlerById(iPluginId, iArgc) {
    new iAmmoId = get_param(1);

    return GetHandlerById(iAmmoId);
}

public Native_GetName(iPluginId, iArgc) {
    new iHandler = get_param(1);
    new iLen = get_param(3);

    static szName[64];
    ArrayGetString(Array:g_rgAmmo[Ammo_Name], iHandler, szName, charsmax(szName));

    set_string(2, szName, iLen);
}

public Native_GetId(iPluginId, iArgc) {
    new iHandler = get_param(1);

    return ArrayGetCell(Array:g_rgAmmo[Ammo_Id], iHandler);
}

public Native_GetPackSize(iPluginId, iArgc) {
    new iHandler = get_param(1);

    return ArrayGetCell(Array:g_rgAmmo[Ammo_PackSize], iHandler);
}

public Native_GetPackModel(iPluginId, iArgc) {
    new iHandler = get_param(1);
    new iLen = get_param(3);

    static szPackModel[64];
    ArrayGetString(Array:g_rgAmmo[Ammo_PackModel], iHandler, szPackModel, charsmax(szPackModel));

    set_string(2, szPackModel, iLen);
}

public Native_GetCount(iPluginId, iArgc) {
    return g_iAmmoCount;
}

public Native_GetMaxAmount(iPluginId, iArgc) {
    new iHandler = get_param(1);

    return ArrayGetCell(Array:g_rgAmmo[Ammo_MaxAmount], iHandler);
}

InitStorage() {
    g_rgAmmo[Ammo_Name] = ArrayCreate(32, 1);
    g_rgAmmo[Ammo_Id] = ArrayCreate(1, 1);
    g_rgAmmo[Ammo_PackSize] = ArrayCreate(1, 1);
    g_rgAmmo[Ammo_PackModel] = ArrayCreate(64, 1);
    g_rgAmmo[Ammo_MaxAmount] = ArrayCreate(1, 1);
    g_iAmmoMap = TrieCreate();
}

RegisterAmmo(const szName[], iAmmoId, iPackSize, const szModel[], iMaxAmount) {
    if (szModel[0] != '^0') {
        precache_model(szModel);
    }

    ArrayPushCell(Array:g_rgAmmo[Ammo_Id], iAmmoId);
    ArrayPushString(Array:g_rgAmmo[Ammo_Name], szName);
    ArrayPushCell(Array:g_rgAmmo[Ammo_PackSize], iPackSize);
    ArrayPushString(Array:g_rgAmmo[Ammo_PackModel], szModel);
    ArrayPushCell(Array:g_rgAmmo[Ammo_MaxAmount], iMaxAmount);
    TrieSetCell(g_iAmmoMap, szName, g_iAmmoCount);

    g_rgAmmoMap[iAmmoId] = g_iAmmoCount;
    g_iAmmoCount++;
}

GetHandlerById(iAmmoId) {
    return g_rgAmmoMap[iAmmoId];
}
