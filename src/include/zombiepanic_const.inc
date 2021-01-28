#define ZP_TITLE "Zombie Panic Beta"
#define ZP_VERSION "0.9.6"

#define ZP_HUMAN_TEAM 2
#define ZP_ZOMBIE_TEAM 1
#define ZP_ZOMBIE_WIN_MESSAGE "#Terrorists_Win"
#define ZP_HUMAN_WIN_MESSAGE "#CTs_Win"
#define ZP_ZOMBIE_TEAM_NAME "Zombies"
#define ZP_HUMAN_TEAM_NAME "Survivors"
#define ZP_HUMAN_SPEED 200.0
#define ZP_ZOMBIE_SPEED (ZP_HUMAN_SPEED * 0.85875)
#define ZP_HUMAN_HEALTH 100.0
#define ZP_ZOMBIE_HEALTH 200.0
#define ZP_NEW_ROUND_DELAY 5.0
#define ZP_AMMO_RESPAWN_TIME 150.0
#define ZP_BUTTON_FLAG_HUMAN_ONLY BIT(9)

enum ZP_Music {
  ZP_Music_Path[64],
  Float:ZP_Music_Duration
}

stock const ZP_WEAPON_PISTOL[] = "zombiepanic/b2/weapon_9mmhandgun";
stock const ZP_WEAPON_RIFLE[] = "zombiepanic/b2/weapon_556AR";
stock const ZP_WEAPON_SHOTGUN[] = "zombiepanic/b2/weapon_shotgun";
stock const ZP_WEAPON_MAGNUM[] = "zombiepanic/b2/weapon_357";
stock const ZP_WEAPON_SATCHEL[] = "zombiepanic/b1/weapon_satchel";
stock const ZP_WEAPON_GRENADE[] = "zombiepanic/b1/weapon_handgrenade";
stock const ZP_WEAPON_SWIPE[] = "zombiepanic/b1/weapon_swipe";
stock const ZP_WEAPON_CROWBAR[] = "zombiepanic/b1/weapon_crowbar";

stock const ZP_AMMO_PISTOL[] = "pistol";
stock const ZP_AMMO_RIFLE[] = "rifle";
stock const ZP_AMMO_SHOTGUN[] = "shotgun";
stock const ZP_AMMO_MAGNUM[] = "magnum";
stock const ZP_AMMO_GRENADE[] = "grenade";
stock const ZP_AMMO_SATCHEL[] = "satchel";

stock const ZP_FLASHLIGHT_LIGHTCONE_MODEL[] = "models/zombiepanic/b1/lightcone.mdl";
stock const ZP_FLASHLIGHT_SOUND[] = "items/flashlight1.wav";

stock const ZP_WEAPONBOX_MODEL[] = "models/zombiepanic/b1/items/w_weaponbox.mdl";

stock const ZP_WEAPON_PISTOL_V_MODEL[] = "models/zombiepanic/b1/items/v_9mmhandgun.mdl";
stock const ZP_WEAPON_PISTOL_P_MODEL[] = "models/zombiepanic/b1/items/p_9mmhandgun.mdl";
stock const ZP_WEAPON_PISTOL_W_MODEL[] = "models/zombiepanic/b1/items/w_9mmhandgun.mdl";

stock const ZP_WEAPON_MAGNUM_V_MODEL[] = "models/zombiepanic/b1/items/v_357.mdl";
stock const ZP_WEAPON_MAGNUM_P_MODEL[] = "models/zombiepanic/b1/items/p_357.mdl";
stock const ZP_WEAPON_MAGNUM_W_MODEL[] = "models/zombiepanic/b1/items/w_357.mdl";

stock const ZP_WEAPON_RIFLE_V_MODEL[] = "models/zombiepanic/b1/items/v_556ar.mdl";
stock const ZP_WEAPON_RIFLE_P_MODEL[] = "models/zombiepanic/b1/items/p_556ar.mdl";
stock const ZP_WEAPON_RIFLE_W_MODEL[] = "models/zombiepanic/b1/items/w_556ar.mdl";

stock const ZP_WEAPON_SHOTGUN_V_MODEL[] = "models/zombiepanic/b1/items/v_shotgun.mdl";
stock const ZP_WEAPON_SHOTGUN_P_MODEL[] = "models/zombiepanic/b1/items/p_shotgun.mdl";
stock const ZP_WEAPON_SHOTGUN_W_MODEL[] = "models/zombiepanic/b1/items/w_shotgun.mdl";

stock const ZP_WEAPON_CROWBAR_V_MODEL[] = "models/zombiepanic/b2/items/v_crowbar.mdl";
stock const ZP_WEAPON_CROWBAR_P_MODEL[] = "models/zombiepanic/b1/items/p_crowbar.mdl";
stock const ZP_WEAPON_CROWBAR_W_MODEL[] = "models/w_crowbar.mdl";

stock const ZP_WEAPON_GRENADE_V_MODEL[] = "models/zombiepanic/b1/items/v_grenade.mdl";
stock const ZP_WEAPON_GRENADE_P_MODEL[] = "models/zombiepanic/b1/items/p_grenade.mdl";
stock const ZP_WEAPON_GRENADE_W_MODEL[] = "models/zombiepanic/b1/items/w_grenade.mdl";

stock const ZP_WEAPON_SATCHEL_V_MODEL[] = "models/zombiepanic/b1/items/v_satchel.mdl";
stock const ZP_WEAPON_SATCHEL_P_MODEL[] = "models/zombiepanic/b1/items/p_satchel.mdl";
stock const ZP_WEAPON_SATCHEL_W_MODEL[] = "models/zombiepanic/b1/items/w_satchel.mdl";

stock const ZP_WEAPON_SATCHELRADIO_V_MODEL[] = "models/zombiepanic/b1/items/v_satchel_radio.mdl";
stock const ZP_WEAPON_SATCHELRADIO_P_MODEL[] = "models/zombiepanic/b1/items/p_satchel_radio.mdl";

stock const ZP_ITEM_MEDKIT_MODEL[] = "models/zombiepanic/b1/items/w_medkit.mdl";
stock const ZP_ITEM_BATTERY_MODEL[] = "models/zombiepanic/b1/items/w_battery.mdl";

stock const ZP_AMMO_PISTOL_MODEL[] = "models/zombiepanic/b1/items/w_9mmclip.mdl";
stock const ZP_AMMO_RIFLE_MODEL[] = "models/zombiepanic/b1/items/w_556ARclip.mdl";
stock const ZP_AMMO_SHOTGUN_MODEL[] = "models/zombiepanic/b1/items/w_shotbox.mdl";
stock const ZP_AMMO_MAGNUM_MODEL[] = "models/zombiepanic/b1/items/w_357ammobox.mdl";

stock const ZP_STARTUP_SOUND[] = "sound/zombiepanic/b1/music/gamestartup.mp3";

stock const ZP_MUSIC_LIST[][ZP_Music] = {
  { "sound/zombiepanic/b1/music/KM_CityOfSouls.mp3", 3.32},
  { "sound/zombiepanic/b1/music/KM_CloudOfSorrow.mp3", 4.07},
  { "sound/zombiepanic/b1/music/KM_Descent.mp3", 4.18},
  { "sound/zombiepanic/b1/music/KM_ForgottenKingdom.mp3", 2.56},
  { "sound/zombiepanic/b1/music/KM_FrozenWasteland.mp3", 4.54},
  { "sound/zombiepanic/b1/music/KM_Horde.mp3", 4.56},
  { "sound/zombiepanic/b1/music/KM_Nightmare.mp3", 4.53},
  { "sound/zombiepanic/b1/music/KM_Orphanage.mp3", 3.27},
  { "sound/zombiepanic/b1/music/KM_Plague.mp3", 3.10},
};

stock const ZP_WEAPON_PISTOL_HUD_TXT[] = "sprites/zombiepanic/b2/weapon_9mmhandgun.txt";
stock const ZP_WEAPON_MAGNUM_HUD_TXT[] = "sprites/zombiepanic/b2/weapon_357.txt";
stock const ZP_WEAPON_RIFLE_HUD_TXT[] = "sprites/zombiepanic/b2/weapon_556ar.txt";
stock const ZP_WEAPON_SHOTGUN_HUD_TXT[] = "sprites/zombiepanic/b2/weapon_shotgun.txt";
stock const ZP_WEAPON_CROWBAR_HUD_TXT[] = "sprites/zombiepanic/b1/weapon_crowbar.txt";
stock const ZP_WEAPON_SWIPE_HUD_TXT[] = "sprites/zombiepanic/b1/weapon_swipe.txt";
stock const ZP_WEAPON_GRENADE_HUD_TXT[] = "sprites/zombiepanic/b1/weapon_handgrenade.txt";
stock const ZP_WEAPON_SATCHEL_HUD_TXT[] = "sprites/zombiepanic/b1/weapon_satchel.txt";

stock const ZP_HUD_SPRITES[][] = {
  "sprites/zombiepanic/b1/640hud1.spr",
  "sprites/zombiepanic/b1/640hud3.spr",
  "sprites/zombiepanic/b1/640hud4.spr",
  "sprites/zombiepanic/b1/640hud6.spr",
  "sprites/zombiepanic/b1/640hud7.spr",
  "sprites/zombiepanic/b1/640hudz.spr",
  "sprites/zombiepanic/b1/640zombiehead.spr",
  "sprites/zombiepanic/b2/pistol_xhair.spr",
  "sprites/zombiepanic/b2/magnum_xhair.spr",
  "sprites/zombiepanic/b2/colt_xhair.spr",
  "sprites/zombiepanic/b2/shotgun_xhair.spr"
};

stock const ZP_WEAPON_SWIPE_MISS_SOUNDS[][] = {
  "zombiepanic/b1/weapons/claw_miss1.wav",
  "zombiepanic/b1/weapons/claw_miss1.wav"
};

stock const ZP_WEAPON_SWIPE_HIT_SOUNDS[][] = {
  "zombiepanic/b1/weapons/claw_strike1.wav",
  "zombiepanic/b1/weapons/claw_strike2.wav",
  "zombiepanic/b1/weapons/claw_strike3.wav"
};

stock const ZP_WEAPON_SHOTGUN_RELOAD_SOUNDS[][] = {
  "zombiepanic/b1/weapons/reload1.wav",
  "zombiepanic/b1/weapons/reload3.wav"
};

stock const ZP_WEAPON_SHOTGUN_SHOT_SOUND[] = "zombiepanic/b1/weapons/sbarrel1.wav";
stock const ZP_WEAPON_SHOTGUN_PUMP_SOUND[] = "zombiepanic/b1/weapons/scock1.wav";

stock const ZP_WEAPON_CROWBAR_HITBODY_SOUNDS[][] = {
  "weapons/cbar_hitbod1.wav",
  "weapons/cbar_hitbod2.wav",
  "weapons/cbar_hitbod1.wav"
};

stock const ZP_WEAPON_CROWBAR_HIT_SOUNDS[][] = {
  "weapons/cbar_hit1.wav",
  "weapons/cbar_hit2.wav"
};

stock const ZP_WEAPON_CROWBAR_MISS_SOUND[] = "weapons/cbar_miss1.wav";

stock const ZP_WEAPON_RIFLE_SHOT_SOUNDS[][] = {
  "zombiepanic/b1/weapons/hks1.wav",
  "zombiepanic/b1/weapons/hks2.wav",
  "zombiepanic/b1/weapons/hks3.wav"
};

stock const ZP_WEAPON_RIFLE_RELOAD_START_SOUND[] = "items/cliprelease1.wav";
stock const ZP_WEAPON_RIFLE_RELOAD_END_SOUND[] = "items/clipinsert1.wav";

stock const ZP_WEAPON_MAGNUM_SHOT_SOUNDS[][] = {
  "weapons/357_shot1.wav",
  "weapons/357_shot2.wav"
};

stock const ZP_WEAPON_PISTOL_SHOT_SOUND[] = "zombiepanic/b1/weapons/pl_gun3.wav";
stock const ZP_WEAPON_PISTOL_RELOAD_START_SOUND[] = "items/9mmclip1.wav";
stock const ZP_WEAPON_PISTOL_RELOAD_END_SOUND[] = "items/9mmclip2.wav";

stock const ZP_OBJECTIVE_MARK_SPRITE[] = "sprites/zombiepanic/b2/objective_mark.spr";
