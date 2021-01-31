#pragma semicolon 1

#include "amxmodx"
#include <hamsandwich>

#include <zombiepanic>

#define PLUGIN "[Zombie Panic] Music"
#define AUTHOR "Hedgehog Fog"

#define TASKID_PLAY_NEXT_TRACK 100

#define MUSIC_DELAY 3.0

new bool:g_bPlayerMusic[MAX_PLAYERS + 1];

new g_pCvarMusic;
new g_pCvarJoinMusic;

public plugin_precache() {
    precache_generic(ZP_STARTUP_SOUND);

    for (new i = 0; i < sizeof(ZP_MUSIC_LIST); ++i) {
        precache_generic(ZP_MUSIC_LIST[i][ZP_Music_Path]);
    }
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);

    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn_Post", .Post = 1);

    g_pCvarMusic = register_cvar("zp_music", "1");
    g_pCvarJoinMusic = register_cvar("zp_join_music", "1");
}

public client_connect(pPlayer) {
    g_bPlayerMusic[pPlayer] = false;

    if (get_pcvar_num(g_pCvarJoinMusic) > 0) {
        PlayMusic(pPlayer, ZP_STARTUP_SOUND, true);
    }
}

public OnPlayerSpawn_Post(pPlayer) {
    if (get_pcvar_num(g_pCvarMusic)) {
        if (!g_bPlayerMusic[pPlayer]) {
            set_task(MUSIC_DELAY, "Task_Play", TASKID_PLAY_NEXT_TRACK + pPlayer);
            g_bPlayerMusic[pPlayer] = true;
        }
    } else {
        remove_task(TASKID_PLAY_NEXT_TRACK + pPlayer);
        g_bPlayerMusic[pPlayer] = false;
    }
}

public Task_Play(iTaskId) {
    new pPlayer = iTaskId - TASKID_PLAY_NEXT_TRACK;

    new iIndex = random(sizeof(ZP_MUSIC_LIST));
    PlayMusic(pPlayer, ZP_MUSIC_LIST[iIndex][ZP_Music_Path], false);
    set_task(MUSIC_DELAY + (ZP_MUSIC_LIST[iIndex][ZP_Music_Duration] * 60.0), "Task_Play", TASKID_PLAY_NEXT_TRACK + pPlayer);
}

PlayMusic(pPlayer, const szPath[], bool:bLoop) {
    static szCommand[64];
    format(szCommand, charsmax(szCommand), "mp3 %s ^"%s^"", bLoop ? "loop" : "play", szPath);
    client_cmd(pPlayer, szCommand);
}
