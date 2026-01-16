#pragma semicolon 1

#include <amxmodx>

#include <api_assets>
#include <api_player_music>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define MAX_TRACKS 16

/*--------------------------------[ Plugin State ]--------------------------------*/

new PlayerMusic_Track:g_iLoadingTrack = PlayerMusic_Track_Invalid;
new PlayerMusic_Track:g_rgiTracks[MAX_TRACKS] = {PlayerMusic_Track_Invalid, ...};
new g_iTracksNum = 0;

new bool:g_bEnabled = false;
new bool:g_bLoadingMusic = false;
new Float:g_flMusicDelay = 0.0;

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  LoadTracks();
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Music"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(create_cvar(CVAR("music"), "1"), g_bEnabled);
  bind_pcvar_num(create_cvar(CVAR("music_loading"), "1"), g_bLoadingMusic);
  bind_pcvar_float(create_cvar(CVAR("music_delay"), "5"), g_flMusicDelay);

  hook_cvar_change(get_cvar_pointer(CVAR("music")), "CvarHook_Enabled");
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  if (g_bLoadingMusic) {
    PlayerMusic_Player_PlayTrack(pPlayer, g_iLoadingTrack, _, true);
  }
}

public client_putinserver(pPlayer) {
  if (PlayerMusic_Player_GetTrack(pPlayer) == g_iLoadingTrack) {
    PlayerMusic_Player_StopTrack(pPlayer);
  }

  @Player_ScheduleTrack(pPlayer);
}

/*--------------------------------[ Music Forwards ]--------------------------------*/

public PlayerMusic_OnTrackEnd(const pPlayer) {
  @Player_ScheduleTrack(pPlayer);
}

/*--------------------------------[ Cvar Hooks ]--------------------------------*/

public CvarHook_Enabled(pCvar, const szOldValue[], const szNewValue[]) {
  new bool:bEnabled = !!get_pcvar_num(pCvar);
  if (bEnabled == !!str_to_num(szOldValue)) return;

  if (!bEnabled) {
    for (new pPlayer = 1; pPlayer <= get_maxplayers(); ++pPlayer) {
      if (PlayerMusic_Player_GetTrack(pPlayer) == PlayerMusic_Track_Invalid) continue;

      PlayerMusic_Player_StopTrack(pPlayer);
    }
  }
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_ScheduleTrack(const &pPlayer) {
  PlayerMusic_Player_PlayTrack(pPlayer, g_rgiTracks[random(g_iTracksNum)], g_flMusicDelay);
}


/*--------------------------------[ Functions ]--------------------------------*/

LoadTracks() {
  new szStartupSound[MAX_RESOURCE_PATH_LENGTH];
  Asset_Precache(ASSET_LIBRARY, ASSET_SOUND(Startup), szStartupSound, charsmax(szStartupSound));

  new rgszMusicList[MAX_TRACKS][MAX_RESOURCE_PATH_LENGTH];
  new iMusicListSize = Asset_PrecacheList(ASSET_LIBRARY, ASSET(Music), rgszMusicList, sizeof(rgszMusicList), charsmax(rgszMusicList[]));

  for (new i = 0; i < iMusicListSize; ++i) {
    g_rgiTracks[i] = PlayerMusic_LoadTrack(rgszMusicList[i]);
  }

  g_iTracksNum = iMusicListSize;

  g_iLoadingTrack = PlayerMusic_LoadTrack(szStartupSound);
}
