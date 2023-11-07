#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <xs>

#include <api_waypoint_markers>

#include <zombiepanic>
#include <zombiepanic_utils>

#define PLUGIN "[Zombie Panic] Objective Marks"
#define AUTHOR "Hedgehog Fog"

#define SPRITE_WIDTH 128.0
#define SPRITE_HEIGHT 128.0
#define SPRITE_AMT 50.0

new g_pCvarEnabled;

new Array:g_irgpMarkers;


public plugin_precache() {
    g_irgpMarkers = ArrayCreate();

    precache_model(ZP_OBJECTIVE_MARK_SPRITE);

    RegisterHam(Ham_Spawn, "func_button", "HamHook_Button_Spawn_Post", .Post = 1);

    g_pCvarEnabled = register_cvar("zp_objective_marks", "1");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    if (!ZP_GameRules_GetObjectiveMode()) {
        for (new i = ArraySize(g_irgpMarkers) - 1; i >= 0; --i) {
            new pMark = ArrayGetCell(g_irgpMarkers, i);
            engfunc(EngFunc_RemoveEntity, pMark);
        }

        return;
    }

    RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);

    set_task(1.0, "Task_UpdateButtonMarkers", 0, _, _, "b");
}

public plugin_end() {
    ArrayDestroy(g_irgpMarkers);
}

public WaypointMarker_Fw_Created(pMarker) {
    ArrayPushCell(g_irgpMarkers, pMarker);
}

public WaypointMarker_Fw_Destroy(pMarker) {
    new iGlobalId = ArrayFindValue(g_irgpMarkers, pMarker);
    if (iGlobalId != -1) {
        ArrayDeleteItem(g_irgpMarkers, iGlobalId);
    }
}

public ZP_Fw_PlayerTransformed(pPlayer) {
    @Player_UpdateMarkersVisibility(pPlayer);
}

public HamHook_Player_Spawn_Post(pPlayer) {
    @Player_UpdateMarkersVisibility(pPlayer);
}

public HamHook_Button_Spawn_Post(pButton) {
    if (~pev(pButton, pev_spawnflags) & ZP_BUTTON_FLAG_HUMAN_ONLY) {
        return;
    }

    if (get_pcvar_bool(g_pCvarEnabled)) {
        static Float:vecOrigin[3]; ExecuteHam(Ham_BodyTarget, pButton, 0, vecOrigin);

        new pMarker = WaypointMarker_Create(ZP_OBJECTIVE_MARK_SPRITE, vecOrigin, 24.0 / SPRITE_WIDTH, Float:{24.0, 24.0});
        set_pev(pMarker, pev_owner, pButton);
        set_pev(pMarker, pev_renderamt, SPRITE_AMT);
    }
}

@Player_UpdateMarkersVisibility(this) {
    static iMarkCount; iMarkCount = ArraySize(g_irgpMarkers);
    for (new iMarker = 0; iMarker < iMarkCount; ++iMarker) {
        static pMarker; pMarker = ArrayGetCell(g_irgpMarkers, iMarker);
        @Player_UpdateMarkerVisibility(this, pMarker);
    }
}

@Player_UpdateMarkerVisibility(this, pMarker) {
    WaypointMarker_SetVisible(pMarker, this, @Player_ShouldSeeMarker(this, pMarker));
}

bool:@Player_ShouldSeeMarker(this, pMarker) {
    if (!get_pcvar_bool(g_pCvarEnabled)) return false;
    if (!is_user_alive(this)) return false;
    if (ZP_Player_IsZombie(this)) return false;

    new pButton = pev(pMarker, pev_owner);
    if (!UTIL_IsUsableButton(pButton, this)) return false;

    return true;
}

public Task_UpdateButtonMarkers() {
    for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
        @Player_UpdateMarkersVisibility(pPlayer);
    }
}
