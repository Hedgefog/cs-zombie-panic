#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#include <api_assets>
#include <api_custom_entities>
#include <api_player_roles>

#include <zombiepanic_internal>

/*--------------------------------[ Constants ]--------------------------------*/

#define FLASHLIGHT_MAX_BRIGHTNESS 160.0
#define FLASHLIGHT_UPDATE_RATE 0.125
#define FLASHLIGHT_MAX_DISTANCE 768.0
#define FLASHLIGHT_MAX_CHARGE 100.0
#define FLASHLIGHT_MIN_CHARGE 0.0
#define FLASHLIGHT_DEF_CHARGE FLASHLIGHT_MAX_CHARGE
#define FLASHLIGHT_MIN_CHARGE_TO_ACTIVATE 10.0

/*--------------------------------[ Global Variables ]--------------------------------*/

new gmsgFlashlight;

/*--------------------------------[ Cvar Pointers ]--------------------------------*/

new g_pCvarConsumptionRate;
new g_pCvarRecoveryRate;

/*--------------------------------[ Assets ]--------------------------------*/

new g_szFlashlightSound[MAX_RESOURCE_PATH_LENGTH];

/*--------------------------------[ Players State ]--------------------------------*/

new g_rgpPlayerLightCone[MAX_PLAYERS + 1];
new bool:g_rgbPlayerFlashlightEnabled[MAX_PLAYERS + 1];
new Float:g_rgflPlayerFlashlightCharge[MAX_PLAYERS + 1];
new Float:g_rgflPlayerFlashlightLastThink[MAX_PLAYERS + 1];
new Float:g_rgflPlayerNextToggle[MAX_PLAYERS + 1];

/*--------------------------------[ Plugin Initialization ]--------------------------------*/

public plugin_precache() {
  Asset_Precache(ASSET_LIBRARY, ASSET(Sound_Flashlight), g_szFlashlightSound, charsmax(g_szFlashlightSound));
}

public plugin_init() {
  register_plugin(PLUGIN_NAME("Flashlight"), ZP_VERSION, "Hedgehog Fog");

  gmsgFlashlight = get_user_msgid("Flashlight");

  g_pCvarConsumptionRate = register_cvar(CVAR("flashlight_consumption_rate"), "1.0");
  g_pCvarRecoveryRate = register_cvar(CVAR("flashlight_recovery_rate"), "0.5");

  RegisterHamPlayer(Ham_Spawn, "HamHook_Player_Spawn_Post", .Post = 1);
  RegisterHamPlayer(Ham_Killed, "HamHook_Player_Killed_Post", .Post = 1);
  RegisterHamPlayer(Ham_Player_PreThink, "HamHook_Player_PreThink_Post", .Post = 1);

  register_clcmd("zp_flashlight", "Command_Flashlight");
  register_impulse(100, "Impulse_100");
}

/*--------------------------------[ Commands ]--------------------------------*/

public Command_Flashlight(const pPlayer) {
  if (!@Player_CanUseFlashlight(pPlayer)) return PLUGIN_CONTINUE;
  
  @Player_ToggleFlashlight(pPlayer);

  return PLUGIN_HANDLED;
}

public Impulse_100(const pPlayer) {
  if (!@Player_CanUseFlashlight(pPlayer)) return PLUGIN_CONTINUE;
  
  @Player_ToggleFlashlight(pPlayer);

  return PLUGIN_HANDLED;
}

/*--------------------------------[ Client Forwards ]--------------------------------*/

public client_connect(pPlayer) {
  g_rgpPlayerLightCone[pPlayer] = FM_NULLENT;
  g_rgflPlayerNextToggle[pPlayer] = 0.0;
}

public client_disconnected(pPlayer) {
  @Player_SetFlashlight(pPlayer, false);
  // @Player_DestroyLightConeEntity(pPlayer);
}

/*--------------------------------[ Hooks ]--------------------------------*/

public HamHook_Player_Spawn_Post(const pPlayer) {
  if (!is_user_alive(pPlayer)) return HAM_IGNORED;

  @Player_SetFlashlight(pPlayer, false);
  g_rgflPlayerFlashlightCharge[pPlayer] = FLASHLIGHT_DEF_CHARGE;
  set_pev(pPlayer, pev_framerate, 1.0);
  
  return HAM_HANDLED;
}

public HamHook_Player_Killed_Post(const pPlayer) {
  @Player_SetFlashlight(pPlayer, false);

  return HAM_HANDLED;
}

public HamHook_Player_PreThink_Post(const pPlayer) {
  @Player_FlashlightThink(pPlayer);

  return HAM_HANDLED;
}

/*--------------------------------[ Player Methods ]--------------------------------*/

@Player_FlashlightThink(const &this) {
  static Float:flGameTime; flGameTime = get_gametime();
  static Float:flDelta; flDelta = flGameTime - g_rgflPlayerFlashlightLastThink[this];
  if (flDelta < FLASHLIGHT_UPDATE_RATE) return;

  if (g_rgbPlayerFlashlightEnabled[this]) {
    if (g_rgflPlayerFlashlightCharge[this] > FLASHLIGHT_MIN_CHARGE) {
      g_rgflPlayerFlashlightCharge[this] -= (get_pcvar_float(g_pCvarConsumptionRate) * flDelta);
      g_rgflPlayerFlashlightCharge[this] = floatmax(g_rgflPlayerFlashlightCharge[this], FLASHLIGHT_MIN_CHARGE);
      set_pev(this, pev_framerate, 0.5);
    } else {
      @Player_SetFlashlight(this, false);
    }
  } else if (g_rgflPlayerFlashlightCharge[this] < FLASHLIGHT_MAX_CHARGE) {
    g_rgflPlayerFlashlightCharge[this] += (get_pcvar_float(g_pCvarRecoveryRate) * flDelta);
    g_rgflPlayerFlashlightCharge[this] = floatmin(g_rgflPlayerFlashlightCharge[this], FLASHLIGHT_MAX_CHARGE);
  }

  g_rgflPlayerFlashlightLastThink[this] = flGameTime;
}

bool:@Player_ToggleFlashlight(const &this) {
  if (g_rgflPlayerNextToggle[this] <= get_gametime()) {
    @Player_SetFlashlight(this, !g_rgbPlayerFlashlightEnabled[this]);
    g_rgflPlayerNextToggle[this] = get_gametime() + 0.15;
  }

  return g_rgbPlayerFlashlightEnabled[this];
}

bool:@Player_SetFlashlight(const &this, bool:bValue) {   
  if (bValue == g_rgbPlayerFlashlightEnabled[this]) return false;

  if (bValue) {
    if (!@Player_CanUseFlashlight(this)) return false;
    if (g_rgflPlayerFlashlightCharge[this] < FLASHLIGHT_MIN_CHARGE_TO_ACTIVATE) return false;
  }

  g_rgbPlayerFlashlightEnabled[this] = bValue;

  remove_task(this);

  if (bValue) {
    @Player_ShowLightConeEntity(this);
    set_task(1.0, "Task_FlashlightHud", this, _, _, "b");
  } else {
    // @Player_HideLightConeEntity(this);
    @Player_DestroyLightConeEntity(this);
  }

  if (is_user_alive(this)) {
    @Player_UpdateFlashlightHud(this);
    emit_sound(this, CHAN_ITEM, g_szFlashlightSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
  }

  return true;
}

bool:@Player_CanUseFlashlight(const &this) {
  if (!is_user_alive(this)) return false;
  if (!PlayerRole_Player_HasRole(this, PLAYER_ROLE(Survivor))) return false;

  return true;
}

@Player_CreateLightConeEntity(const &this) {
  new pEntity = CE_Create(ENTITY(LightCone), _, false);
  dllfunc(DLLFunc_Spawn, pEntity);
  set_pev(pEntity, pev_movetype, MOVETYPE_FOLLOW);
  set_pev(pEntity, pev_aiment, this);
  set_pev(pEntity, pev_owner, this);

  g_rgpPlayerLightCone[this] = pEntity;

  return pEntity;
}

@Player_ShowLightConeEntity(const &this) {
  static pLightcone; pLightcone = g_rgpPlayerLightCone[this];

  if (pLightcone == FM_NULLENT) {
    pLightcone = @Player_CreateLightConeEntity(this);
  }

  set_pev(pLightcone, pev_effects, pev(pLightcone, pev_effects) & ~EF_NODRAW);
  set_pev(this, pev_framerate, 0.5);

  g_rgpPlayerLightCone[this] = pLightcone;
}

@Player_HideLightConeEntity(const &this) {
  static pLightcone; pLightcone = g_rgpPlayerLightCone[this];

  if (pLightcone != FM_NULLENT) {
    set_pev(pLightcone, pev_effects, pev(pLightcone, pev_effects) | EF_NODRAW);
    set_pev(this, pev_framerate, 1.0);
  }
}

@Player_DestroyLightConeEntity(const &this) {
  static pLightcone; pLightcone = g_rgpPlayerLightCone[this];

  if (pLightcone == FM_NULLENT) return;

  engfunc(EngFunc_RemoveEntity, g_rgpPlayerLightCone[this]);
  g_rgpPlayerLightCone[this] = FM_NULLENT;
}

@Player_UpdateFlashlightHud(const &this) {
  message_begin(MSG_ONE, gmsgFlashlight, _, this);
  write_byte(g_rgbPlayerFlashlightEnabled[this]);
  write_byte(floatround(g_rgflPlayerFlashlightCharge[this]));
  message_end();
}

/*--------------------------------[ Tasks ]--------------------------------*/

public Task_FlashlightHud(const iTaskId) {
  new pPlayer = iTaskId;

  @Player_UpdateFlashlightHud(pPlayer);
}
