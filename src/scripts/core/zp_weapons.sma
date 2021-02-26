#pragma semicolon 1

#include <amxmodx>

#include <zombiepanic>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapons"
#define AUTHOR "Hedgehog Fog"

enum WeaponData {
    Weapon_Weight
}

new Array:g_irgWeapons[WeaponData];
new Trie:g_weaponMap;
new g_iWeaponCount;

public plugin_precache() {
    for (new i  = 0; i < _:WeaponData; ++i) {
        g_irgWeapons[WeaponData:i] = ArrayCreate(1, 8);
    }

    g_weaponMap = TrieCreate();
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public plugin_natives() {
    register_native("ZP_Weapons_Register", "Native_Register");
    register_native("ZP_Weapons_GetWeight", "Native_GetWeight");
}

public plugin_end() {
    for (new i = 0; i < _:WeaponData; ++i) {
        ArrayDestroy(g_irgWeapons[WeaponData:i]);
    }

    TrieDestroy(g_weaponMap);
}

public Native_Register(iPluginId, iArgc) {
    new CW:iCwHandler = CW:get_param(1);
    new Float:flWeight = get_param_f(2);

    Register(iCwHandler, flWeight);
}

public Float:Native_GetWeight(iPluginId, iArgc) {
    new pEntity = get_param(1);

    return GetWeight(pEntity);
}

Register(CW:iCwHandler, Float:flWeight) {
    new iIndex = g_iWeaponCount;
    ArrayPushCell(Array:g_irgWeapons[Weapon_Weight], flWeight);

    new szKey[4];
    format(szKey, charsmax(szKey), "%d", iCwHandler);

    TrieSetCell(g_weaponMap, szKey, iIndex);

    g_iWeaponCount++;
}

Float:GetWeight(pEntity) {
    new CW:iCwHandler = CW_GetHandlerByEntity(pEntity);
    if (iCwHandler == CW_INVALID_HANDLER) {
        return 0.0;
    }

    static szKey[4];
    format(szKey, charsmax(szKey), "%d", iCwHandler);

    new iIndex;
    if (!TrieGetCell(g_weaponMap, szKey, iIndex)) {
        return 0.0;
    }

    return ArrayGetCell(Array:g_irgWeapons[Weapon_Weight], iIndex);
}
