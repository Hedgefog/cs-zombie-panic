#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_events>
#include <api_custom_entities>
#include <api_waypoint_markers>

#include <zombiepanic_gamemodes>
#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_MARKERS 128
#define SPRITE_WIDTH 128.0
#define SPRITE_HEIGHT 128.0
#define SPRITE_AMT 50.0

/*--------------------------------[ Assets ]--------------------------------*/

new g_szSprite[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin State ]--------------------------------*/

new g_rgpMarkers[MAX_MARKERS];
new g_iMarkersNum = 0;

new bool:g_bEnabled = false;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  bind_pcvar_num(create_cvar(CVAR("objective_marks"), "1"), g_bEnabled);

  Asset_Precache(ASSET_LIBRARY, ASSET_SPRITE(ObjectiveMark), g_szSprite, charsmax(g_szSprite));
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Objective Marks"), ZP_VERSION, "Hedgehog Fog");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);

  CustomEvent_Subscribe(GAMEMODE_EVENT(Activated), "EventSubscriber_GameMode_Activated");
  CustomEvent_Subscribe(GAMEMODE_EVENT(Deactivated), "EventSubscriber_GameMode_Deactivated");

  set_task(1.0, "Task_UpdateButtonMarkers", 0, _, _, "b");
}

/*--------------------------------[ Player Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  @Player_UpdateMarkersVisibility(pPlayer);

  return HAM_HANDLED;
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_GameMode_Activated(const szGameModeId[]) {
  if (equal(szGameModeId, GAMEMODE(Objective))) {
    CreateMarkers();
  }
}

public EventSubscriber_GameMode_Deactivated(const szGameModeId[]) {
  if (equal(szGameModeId, GAMEMODE(Objective))) {
    DestroyMarkers();
  }
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_UpdateMarkersVisibility(const &this) {
  for (new iMarker = 0; iMarker < g_iMarkersNum; ++iMarker) {
    @Player_UpdateMarkerVisibility(this, g_rgpMarkers[iMarker]);
  }
}

@Player_UpdateMarkerVisibility(const &this, const &pMarker) {
  WaypointMarker_SetVisible(pMarker, this, @Player_ShouldSeeMarker(this, pMarker));
}

bool:@Player_ShouldSeeMarker(const &this, const &pMarker) {
  if (!g_bEnabled) return false;
  if (!is_user_alive(this)) return false;

  static iTeam; iTeam = get_ent_data(this, "CBasePlayer", "m_iTeam");
  if (iTeam != TEAM(Survivors)) return false;

  static pButton; pButton = pev(pMarker, pev_owner);
  if (!CE_CallMethod(pButton, BUTTON_METHOD(IsUsable), this)) return false;

  return true;
}

/*--------------------------------[ Marker Functions ]--------------------------------*/

bool:AddMarker(const &pMarker) {
  if (g_iMarkersNum >= MAX_MARKERS) return false;

  g_rgpMarkers[g_iMarkersNum++] = pMarker;

  return true;
}

bool:DeleteMarker(const &pMarker) {
  new iIndex = FindMarkerIndex(pMarker);
  if (iIndex == -1) return false;

  g_rgpMarkers[iIndex] = g_rgpMarkers[g_iMarkersNum - 1];
  
  g_iMarkersNum--;

  return true;
}

FindMarkerIndex(const &pMarker) {
  for (new i = 0; i < g_iMarkersNum; ++i) {
    if (g_rgpMarkers[i] == pMarker) return i;
  }

  return -1;
}

/*--------------------------------[ Functions ]--------------------------------*/

CreateMarkers() {
  new pButton = FM_NULLENT;
  while ((pButton = CE_Find(ENTITY(Button), pButton)) != FM_NULLENT) {
    if (!CE_GetMember(pButton, BUTTON_MEMBER(bHumanOnly))) continue;

    new Float:vecOrigin[3]; ExecuteHam(Ham_BodyTarget, pButton, 0, vecOrigin);

    new pMarker = WaypointMarker_Create(g_szSprite, vecOrigin, 24.0 / SPRITE_WIDTH, Float:{24.0, 24.0});
    set_pev(pMarker, pev_owner, pButton);
    set_pev(pMarker, pev_renderamt, SPRITE_AMT);

    AddMarker(pMarker);
  }
}

DestroyMarkers() {
  for (new i = 0; i < g_iMarkersNum; ++i) {
    engfunc(EngFunc_RemoveEntity, g_rgpMarkers[i]);
    DeleteMarker(g_rgpMarkers[i]);
  }
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_UpdateButtonMarkers() {
  for (new pPlayer = 1; pPlayer <= MaxClients; ++pPlayer) {
    if (!is_user_connected(pPlayer)) continue;

    @Player_UpdateMarkersVisibility(pPlayer);
  }
}
