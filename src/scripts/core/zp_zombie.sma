#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_rounds>

#define PLUGIN "[Zombie Panic] Zombie"
#define AUTHOR "Hedgehog Fog"

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
    RegisterHamPlayer(Ham_Item_PreFrame, "HamHook_Player_ItemPreFrame_Post", .Post = 1);
    RegisterHamPlayer(Ham_TakeDamage, "HamHook_Player_TakeDamage", .Post = 0);
    RegisterHam(Ham_Use, "func_button", "HamHook_Button_Use", .Post = 0);

    for (new i = 0; i < sizeof(ITEMS_LIST); ++i) {
        RegisterHam(Ham_Touch, ITEMS_LIST[i], "HamHook_Item_Touch", .Post = 0);
    }
}

public plugin_natives() {
    register_native("ZP_Player_IsZombie", "Native_IsPlayerZombie");
}

public bool:Native_IsPlayerZombie(iPluginId, iArgc) {
    new pPlayer = get_param(1);

    return IsPlayerZombie(pPlayer);
}

public HamHook_Button_Use(pEntity, pToucher) {
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    if (!ZP_Player_IsZombie(pToucher)) {
        return HAM_IGNORED;
    }

    if (pev(pEntity, pev_spawnflags) & ZP_BUTTON_FLAG_HUMAN_ONLY) {
        return HAM_SUPERCEDE;
    }

    return HAM_HANDLED;
}

public HamHook_Player_Spawn_Post(pPlayer) {
    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }

    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    set_member(pPlayer, m_iTeam, ZP_ZOMBIE_TEAM);
    emit_sound(pPlayer, CHAN_ITEM, "common/null.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return HAM_HANDLED;
}

public HamHook_Player_TakeDamage(pPlayer, iInflictor, pAttacker, Float:flDamage, iDamageBits) {
    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (iDamageBits & DMG_FALL) {
        return HAM_SUPERCEDE;
    }

    return HAM_HANDLED;
}

public HamHook_Player_ItemPreFrame_Post(pPlayer) {
    if (!ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    new pActiveItem = get_member(pPlayer, m_pActiveItem);
    if (pActiveItem != -1 && pev_valid(pActiveItem)) {
        if (ExecuteHamB(Ham_CS_Item_CanDrop, pActiveItem)) {
            client_cmd(pPlayer, "drop");
            client_cmd(pPlayer, ZP_WEAPON_SWIPE);
        }
    }

    return HAM_HANDLED;
}

public HamHook_Item_Touch(pEntity, pToucher) {
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    if (!ZP_Player_IsZombie(pToucher)) {
        return HAM_IGNORED;
    }

    return HAM_SUPERCEDE;
}

bool:IsPlayerZombie(pPlayer) {
    if (!Round_IsRoundStarted()) {
        return false;
    }

    return get_member(pPlayer, m_iTeam) == ZP_ZOMBIE_TEAM;
}
