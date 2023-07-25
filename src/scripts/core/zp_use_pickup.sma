#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Use Pickup"
#define AUTHOR "Hedgehog Fog"

#define HIGHLIGHT_COLOR 96, 64, 16

new bool:g_bBlockTouch = true;
new Float:g_flPlayerLastFind[MAX_PLAYERS + 1] = { 0.0, ... };
new g_pPlayerAimItem[MAX_PLAYERS + 1] = { -1, ... };
new g_bPlayerPickup[MAX_PLAYERS + 1] = { false, ... };

new g_pFwAimItem;
new g_iFwResult;

new g_pCvarUsePickup;
new g_pCvarUsePickupHighlight;

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);
    RegisterHamPlayer(Ham_Player_PostThink, "HamHook_Player_PostThink_Post", .Post = 1);

    for (new i = 0; i < sizeof(ITEMS_LIST); ++i) {
        RegisterHam(Ham_Touch, ITEMS_LIST[i], "HamHook_Item_Touch", .Post = 0);
    }

    register_forward(FM_AddToFullPack, "FMHook_AddToFullPack_Post", 1);

    g_pCvarUsePickup = register_cvar("zp_use_pickup", "1");
    g_pCvarUsePickupHighlight = register_cvar("zp_use_pickup_highlight", "1");
    g_pFwAimItem = CreateMultiForward("ZP_Fw_PlayerAimItem", ET_IGNORE, FP_CELL, FP_CELL);
}

public HamHook_Item_Touch(pEntity, pToucher) {
    if (!IS_PLAYER(pToucher)) {
        return HAM_IGNORED;
    }

    return get_pcvar_num(g_pCvarUsePickup) && g_bBlockTouch && !is_user_bot(pToucher) ? HAM_SUPERCEDE : HAM_HANDLED;
}

public FMHook_AddToFullPack_Post(es, e, pEntity, pHost, pHostFlags, pPlayer, pSet) {
    if (!get_pcvar_num(g_pCvarUsePickup)) {
        return FMRES_IGNORED;
    }

    if (!get_pcvar_num(g_pCvarUsePickupHighlight)) {
        return FMRES_IGNORED;
    }

    if (!IS_PLAYER(pHost)) {
        return FMRES_IGNORED;
    }

    if (!is_user_alive(pHost)) {
        return FMRES_IGNORED;
    }

    if (!pev_valid(pEntity)) {
        return FMRES_IGNORED;
    }

    if (pEntity == g_pPlayerAimItem[pHost]) {
        set_es(es, ES_RenderMode, kRenderNormal);
        set_es(es, ES_RenderFx, kRenderFxGlowShell);
        set_es(es, ES_RenderAmt, 1);
        set_es(es, ES_RenderColor, {HIGHLIGHT_COLOR});
    }

    return FMRES_HANDLED;
}

public HamHook_Player_PreThink_Post(pPlayer) {
    g_bPlayerPickup[pPlayer] = pev(pPlayer, pev_button) & IN_USE && ~pev(pPlayer, pev_oldbuttons) & IN_USE;

    if (get_gametime() - g_flPlayerLastFind[pPlayer] < 0.1) {
        return HAM_IGNORED;
    }

    new pPrevAimItem = g_pPlayerAimItem[pPlayer];
    g_pPlayerAimItem[pPlayer] = -1;

    if (!is_user_alive(pPlayer)) {
        return HAM_IGNORED;
    }
    
    if (ZP_Player_IsZombie(pPlayer)) {
        return HAM_IGNORED;
    }

    if (get_member_game(m_bFreezePeriod)) {
        return HAM_IGNORED;
    }

    static Float:vecSrc[3];
    ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

    static Float:vecEnd[3];
    pev(pPlayer, pev_v_angle, vecEnd);
    engfunc(EngFunc_MakeVectors, vecEnd);
    get_global_vector(GL_v_forward, vecEnd);

    for (new i = 0; i < 3; ++i) {
        vecEnd[i] = vecSrc[i] + (vecEnd[i] * 64.0);
    }

    new pTr = create_tr2();
    engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pPlayer, pTr);
    get_tr2(pTr, TR_vecEndPos, vecEnd);
    free_tr2(pTr);

    new pEntity;
    new pPrevEntity;
    while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecEnd, 1.0)) != 0) {
        if (pPrevEntity >= pEntity) {
            break;
        }

        pPrevEntity = pEntity;

        if (pev(pEntity, pev_solid) == SOLID_NOT) {
            continue;
        }

        if (~pev(pEntity, pev_flags) & FL_ONGROUND) {
            continue;
        }

        static szClassname[32];
        pev(pEntity, pev_classname, szClassname, charsmax(szClassname));

        if (equal(szClassname, "weaponbox") || equali(szClassname, "item_", 5)) {
            g_pPlayerAimItem[pPlayer] = pEntity;

            if (pEntity != pPrevAimItem) {
                ExecuteForward(g_pFwAimItem, g_iFwResult, pPlayer, pEntity);
            }

            break;
        }
    }

    g_flPlayerLastFind[pPlayer] = get_gametime();

    return HAM_HANDLED;
}

public HamHook_Player_PostThink_Post(pPlayer) {
    if (!g_bPlayerPickup[pPlayer]) {
        return HAM_IGNORED;
    }

    if (g_pPlayerAimItem[pPlayer] == -1) {
        return HAM_IGNORED;
    }

    if (!pev_valid(g_pPlayerAimItem[pPlayer])) {
        return HAM_IGNORED;
    }

    g_bBlockTouch = false;
    ExecuteHamB(Ham_Touch, g_pPlayerAimItem[pPlayer], pPlayer);
    g_bBlockTouch = true;

    g_bPlayerPickup[pPlayer] = false;
    g_pPlayerAimItem[pPlayer] = -1;

    return HAM_HANDLED;
}
