#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#include <zombiepanic>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Shotgun"
#define AUTHOR "Hedgehog Fog"

new CW:g_iCwHandler;

public plugin_precache() {
  precache_generic(ZP_WEAPON_SHOTGUN_HUD_TXT);

  precache_model(ZP_WEAPON_SHOTGUN_V_MODEL);
  precache_model(ZP_WEAPON_SHOTGUN_P_MODEL);
  precache_model(ZP_WEAPON_SHOTGUN_W_MODEL);
  precache_model("models/shotgunshell.mdl");

  for (new i = 0; i < sizeof(ZP_WEAPON_SHOTGUN_RELOAD_SOUNDS); ++i) {
    precache_sound(ZP_WEAPON_SHOTGUN_RELOAD_SOUNDS[i]);
  }

  precache_sound(ZP_WEAPON_SHOTGUN_SHOT_SOUND);
  precache_sound(ZP_WEAPON_SHOTGUN_PUMP_SOUND);

  g_iCwHandler = CW_Register(ZP_WEAPON_SHOTGUN, CSW_M3, 6, ZP_Ammo_GetId(ZP_Ammo_GetHandler(ZP_AMMO_SHOTGUN)), 24, _, _, 0, 3, _, "m3");
  CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
  CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
  CW_Bind(g_iCwHandler, CWB_Reload, "@Weapon_Reload");
  CW_Bind(g_iCwHandler, CWB_Pump, "@Weapon_Pump");
  CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
  CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
  CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
  CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
}

public plugin_init() {
  register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public @Weapon_PrimaryAttack(this) {
  if (CW_DefaultShotgunShot(this, 6.0, 1.0, 0.5, Float:{0.0975, 0.0975, 0.0975}, 16)) {
    CW_PlayAnimation(this, 1, 1.5);
    new pPlayer = CW_GetPlayer(this);
    emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_SHOTGUN_SHOT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    
    set_pev(pPlayer, pev_punchangle, Float:{-5.0, 0.0, 0.0});

    CW_EjectWeaponBrass(this, engfunc(EngFunc_ModelIndex, "models/shotgunshell.mdl"), 2);
  }
}

public @Weapon_Reload(this) {
  if (CW_DefaultShotgunReload(this, 5, 3, 0.6, 0.5)) {
    new flInSpecialReload = get_member(this, m_Weapon_fInSpecialReload);

    if (flInSpecialReload == 2) {
      new pPlayer = CW_GetPlayer(this);
      emit_sound(pPlayer, CHAN_WEAPON, ZP_WEAPON_SHOTGUN_RELOAD_SOUNDS[random(sizeof(ZP_WEAPON_SHOTGUN_RELOAD_SOUNDS))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
  }
}

public @Weapon_Idle(this) {
  new Float:flRand = random_float(0.0, 1.0); // UTIL_SharedRandomFloat( m_pPlayer->random_seed, 0, 1 );
  CW_DefaultShotgunIdle(this, flRand > 0.96 ? 0 : 7, 4, (flRand > 0.96 ? (18.0 / 3.0) : (18.0 / 2.0)), 1.5, ZP_WEAPON_SHOTGUN_PUMP_SOUND);
}

public @Weapon_Pump(this) {
  new pPlayer = CW_GetPlayer(this);
  emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SHOTGUN_PUMP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public @Weapon_Deploy(this) {
  new pPlayer = CW_GetPlayer(this);
  CW_DefaultDeploy(this, ZP_WEAPON_SHOTGUN_V_MODEL, ZP_WEAPON_SHOTGUN_P_MODEL, 4, "shotgun");
  emit_sound(pPlayer, CHAN_ITEM, ZP_WEAPON_SHOTGUN_PUMP_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public Float:@Weapon_GetMaxSpeed(this) {
  return ZP_HUMAN_SPEED - 17.0;
}

public @Weapon_Spawn(this) {
  engfunc(EngFunc_SetModel, this, ZP_WEAPON_SHOTGUN_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
  engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_SHOTGUN_W_MODEL);
}

