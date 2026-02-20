#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <api_assets>
#include <api_player_roles>
#include <api_custom_events>
#include <screenfade_util>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define TASKID_FIX_FADE 100
#define TASKID_ACTIVATE_VISION 200

#define VISION_SCREEN_FADE_COLOR 255, 195, 195
#define VISION_EFFECT_TIME 0.5
#define VISION_ALPHA 20
#define MAX_BRIGHTNESS 150

/*--------------------------------[ Assets ]--------------------------------*/

new g_szZombieVisionOnSound[MAX_RESOURCE_PATH_LENGTH];
new g_szZombieVisionOffSound[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Plugin State ]--------------------------------*/

new bool:g_bIgnoreFadeMessage;
new bool:g_bAutoVision;

/*--------------------------------[ Players State ]--------------------------------*/

new bool:g_rgbPlayerVision[MAX_PLAYERS + 1];
new bool:g_rgbPlayerExternalFade[MAX_PLAYERS + 1];
new bool:g_rgbPlayerInfected[MAX_PLAYERS + 1];
new Float:g_rgflPlayerNextToggle[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Sound_ZombieVisionOn), g_szZombieVisionOnSound, charsmax(g_szZombieVisionOnSound));
  Asset_Precache(ASSET_LIBRARY, ASSET(Sound_ZombieVisionOff), g_szZombieVisionOffSound, charsmax(g_szZombieVisionOffSound));
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Zombie Vision"), ZP_VERSION, "Hedgehog Fog");

  bind_pcvar_num(create_cvar(CVAR("zombievision_auto"), "1"), g_bAutoVision);

  register_forward(FM_AddToFullPack, "FMHook_AddToFullPack_Post", 1);

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);

  register_message(get_user_msgid("ScreenFade"), "Message_ScreenFade");

  CustomEvent_Subscribe(INFECTION_EVENT(Set), "EventSubscriber_Infection_Set");
  CustomEvent_Subscribe(INFECTION_EVENT(Reset), "EventSubscriber_Infection_Reset");

  register_clcmd("zp_zombie_vision", "Command_ZombieVision");

  register_impulse(100, "Impulse_100");
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgbPlayerVision[pPlayer] = false;
  g_rgbPlayerExternalFade[pPlayer] = false;
  g_rgbPlayerInfected[pPlayer] = false;
  g_rgflPlayerNextToggle[pPlayer] = 0.0;
}

public client_disconnected(pPlayer) {
  remove_task(TASKID_FIX_FADE + pPlayer);
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_ZombieVision(const pPlayer) {
  if (!@Player_CanUseVision(pPlayer)) return PLUGIN_CONTINUE;

  @Player_ToggleVission(pPlayer);

  return PLUGIN_HANDLED;
}

public Impulse_100(const pPlayer) {
  if (!@Player_CanUseVision(pPlayer)) return PLUGIN_CONTINUE;
  
  @Player_ToggleVission(pPlayer);

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Hooks ]--------------------------------*/

public FMHook_AddToFullPack_Post(const pState, const e, const pEntity, const pHost, const iHostFlags, const bool:bPlayer, const pSet) {
  if (!is_user_alive(pHost)) return FMRES_IGNORED;
  if (!pev_valid(pEntity)) return FMRES_IGNORED;

  static pTargetPlayer; pTargetPlayer = FM_NULLENT;

  if (bPlayer) {
    pTargetPlayer = pEntity;
  } else {
    static pAimEnt; pAimEnt = pev(pEntity, pev_aiment);
    static iRenderMode; iRenderMode = pev(pEntity, pev_rendermode);
    static iRenderFx; iRenderFx = pev(pEntity, pev_renderfx);
    if (IS_PLAYER(pAimEnt) && iRenderMode== kRenderNormal && iRenderFx == kRenderFxNone) {
      pTargetPlayer = pAimEnt;
    }
  }

  if (pTargetPlayer == FM_NULLENT) return FMRES_IGNORED;
  if (!is_user_alive(pTargetPlayer)) return FMRES_IGNORED;

  if (g_rgbPlayerVision[pHost]) {
    set_es(pState, ES_RenderMode, kRenderNormal);
    set_es(pState, ES_RenderFx, kRenderFxGlowShell);
    set_es(pState, ES_RenderAmt, 1);

    static iColor[3];

    if (!PlayerRole_Player_HasRole(pTargetPlayer, PLAYER_ROLE(Zombie))) {
      if (!g_rgbPlayerInfected[pTargetPlayer]) {
        static Float:flMaxHealth; pev(pTargetPlayer, pev_max_health, flMaxHealth);
        static Float:flHealth; pev(pTargetPlayer, pev_health, flHealth);

        iColor[0] = floatround(MAX_BRIGHTNESS * (1.0 - (flHealth / flMaxHealth)));
        iColor[1] = 0;
        iColor[2] = 0;
      } else {
        iColor[0] = 255;
        iColor[1] = 120;
        iColor[2] = 0;
      }

    } else {
      iColor[0] = 0;
      iColor[1] = MAX_BRIGHTNESS;
      iColor[2] = 0;
    }

    set_es(pState, ES_RenderColor, iColor);
  }

  return FMRES_HANDLED;
}

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  @Player_SetVision(pPlayer, false);

  if (!PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return HAM_IGNORED;

  if (g_bAutoVision) {
    set_task(1.0, "Task_ActivateVision", TASKID_ACTIVATE_VISION + pPlayer);
  }

  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  @Player_SetVision(pPlayer, false);
  remove_task(TASKID_ACTIVATE_VISION + pPlayer);

  if (!PlayerRole_Player_HasRole(pPlayer, PLAYER_ROLE(Zombie))) return HAM_IGNORED;

  return HAM_HANDLED;
}

public Message_ScreenFade(const iMsgId, const iMsgDest, const pPlayer) {
  if (g_bIgnoreFadeMessage) return PLUGIN_CONTINUE;

  new Float:flDuration = (float(get_msg_arg_int(1)) / (1<<12)) + (float(get_msg_arg_int(2)) / (1<<12));
  if (flDuration > 0.0) {
    if (pPlayer > 0) {
      @Player_HandleExternalFade(pPlayer, flDuration);
    } else {
      for (new pTargetPlayer = 1; pTargetPlayer <= MaxClients; ++pTargetPlayer) {
        if (!is_user_connected(pTargetPlayer)) {
          continue;
        }

        @Player_HandleExternalFade(pTargetPlayer, flDuration);
      }
    }
  }

  return PLUGIN_CONTINUE;
}

/*--------------------------------[ Event Subscribers ]--------------------------------*/

public EventSubscriber_Infection_Set(const pPlayer, bool:bValue) {
  g_rgbPlayerInfected[pPlayer] = bValue;
}

public EventSubscriber_Infection_Reset(const pPlayer) {
  g_rgbPlayerInfected[pPlayer] = false;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

bool:@Player_ToggleVission(const &this) {
  if (g_rgflPlayerNextToggle[this] <= get_gametime()) {
    @Player_SetVision(this, !g_rgbPlayerVision[this]);
    g_rgflPlayerNextToggle[this] = get_gametime() + 0.5;
  }

  return g_rgbPlayerVision[this];
}

bool:@Player_SetVision(const &this, bool:bValue) {
  if (bValue == g_rgbPlayerVision[this]) return false;
  if (bValue && !@Player_CanUseVision(this)) return false;

  @Player_VisionFadeEffect(this, bValue);
  g_rgbPlayerVision[this] = bValue;

  if (bValue) {
    PlayerRole_Player_CallMethod(this, PLAYER_ROLE(Base), BASE_ROLE_METHOD(PlaySound), BASE_ROLE_SOUND(Idle));
  }

  if (is_user_alive(this)) {
    client_cmd(this, "spk ^"%s^"", bValue ? g_szZombieVisionOnSound : g_szZombieVisionOffSound);
  }

  return true;
}

bool:@Player_CanUseVision(const &this) {
  if (!is_user_alive(this)) return false;
  if (!PlayerRole_Player_HasRole(this, PLAYER_ROLE(Zombie))) return false;

  return true;
}

@Player_VisionFadeEffect(const &this, bool:bValue) {
  if (g_rgbPlayerExternalFade[this]) return;

  g_bIgnoreFadeMessage = true;
  UTIL_ScreenFade(this, {VISION_SCREEN_FADE_COLOR}, VISION_EFFECT_TIME, 0.0, VISION_ALPHA, (bValue ? FFADE_OUT | FFADE_STAYOUT : FFADE_IN), .bExternal = true);
  g_bIgnoreFadeMessage = false;
}

@Player_HandleExternalFade(const &this, Float:flHoldTime) {
  g_rgbPlayerExternalFade[this] = true;
  set_task(flHoldTime, "Task_FixVisionScreenFade", TASKID_FIX_FADE + this);
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_ActivateVision(const iTaskId) {
  new pPlayer = iTaskId - TASKID_ACTIVATE_VISION;

  @Player_SetVision(pPlayer, true);
}

public Task_FixVisionScreenFade(const iTaskId) {
  new pPlayer = iTaskId - TASKID_FIX_FADE;

  if (is_user_connected(pPlayer) && g_rgbPlayerVision[pPlayer]) {
    @Player_VisionFadeEffect(pPlayer, true);
  }

  g_rgbPlayerExternalFade[pPlayer] = false;
}
