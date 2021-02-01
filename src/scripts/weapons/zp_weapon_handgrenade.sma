#pragma semicolon 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>

#include <zombiepanic>
#include <zombiepanic_utils>
#include <api_custom_weapons>

#define PLUGIN "[Zombie Panic] Weapon Grenade"
#define AUTHOR "Hedgehog Fog"

new const g_rgszBounceSounds[][] = {
    "weapons/g_bounce1.wav",
    "weapons/g_bounce2.wav",
    "weapons/g_bounce3.wav"
};

new g_iAmmoId;
new CW:g_iCwHandler;

public plugin_precache() {
    precache_generic(ZP_WEAPON_GRENADE_HUD_TXT);

    precache_model(ZP_WEAPON_GRENADE_V_MODEL);
    precache_model(ZP_WEAPON_GRENADE_P_MODEL);
    precache_model(ZP_WEAPON_GRENADE_W_MODEL);
    
    for (new i = 0; i < sizeof(g_rgszBounceSounds); ++i) {
        precache_sound(g_rgszBounceSounds[i]);
    }

    g_iAmmoId = ZP_Ammo_GetId(ZP_Ammo_GetHandler("grenade"));
    g_iCwHandler = CW_Register(ZP_WEAPON_GRENADE, CSW_HEGRENADE, WEAPON_NOCLIP, g_iAmmoId, -1, 0, -1, 3, 6);
    CW_Bind(g_iCwHandler, CWB_Idle, "@Weapon_Idle");
    CW_Bind(g_iCwHandler, CWB_PrimaryAttack, "@Weapon_PrimaryAttack");
    CW_Bind(g_iCwHandler, CWB_Deploy, "@Weapon_Deploy");
    CW_Bind(g_iCwHandler, CWB_GetMaxSpeed, "@Weapon_GetMaxSpeed");
    CW_Bind(g_iCwHandler, CWB_Spawn, "@Weapon_Spawn");
    CW_Bind(g_iCwHandler, CWB_WeaponBoxModelUpdate, "@Weapon_WeaponBoxSpawn");
}

public plugin_init() {
    register_plugin(PLUGIN, ZP_VERSION, AUTHOR);
}

public @Weapon_PrimaryAttack(this) {
    new pPlayer = CW_GetPlayer(this);
    if (!get_member(this, m_flStartThrow) && get_member(pPlayer, m_rgAmmo, g_iAmmoId) > 0) {
        set_member(this, m_flStartThrow, get_gametime());
        set_member(this, m_flReleaseThrow, 0.0);
        CW_PlayAnimation(this, 2, 0.5);
    }
}

public @Weapon_Idle(this) {
    new pPlayer = CW_GetPlayer(this);

    if (!get_member(this, m_flReleaseThrow) && get_member(this, m_flStartThrow)) {
            set_member(this, m_flReleaseThrow, get_gametime());
    }

    if (get_member(this, m_Weapon_flTimeWeaponIdle) > 0.0) {
        return;
    }

    if (get_member(this, m_flStartThrow)) {
        static Float:vecThrowAngle[3];
        pev(pPlayer, pev_v_angle, vecThrowAngle);

        if (vecThrowAngle[0] < 0.0) {
            vecThrowAngle[0] = -10.0 + vecThrowAngle[0] * ((90.0 - 10.0) / 90.0);
        } else {
            vecThrowAngle[0] = -10.0 + vecThrowAngle[0] * ((90.0 + 10.0) / 90.0);
        }

        new Float:flVel = (90.0 - vecThrowAngle[0]) * 4;
        if (flVel > 500.0) {
            flVel = 500.0;
        }

        engfunc(EngFunc_MakeVectors, vecThrowAngle); 

        static Float:vecSrc[3];
        ExecuteHam(Ham_Player_GetGunPosition, pPlayer, vecSrc);

        static Float:vecThrow[3];
        pev(pPlayer, pev_velocity, vecThrow);

        static Float:vecForward[3];
        get_global_vector(GL_v_forward, vecForward);

        for (new i = 0; i < 3; ++i) {
            vecSrc[i] += vecForward[i] * 16.0;
            vecThrow[i] += vecForward[i] * flVel;
        }

        // alway explode 3 seconds after the pin was pulled
        new Float:flTime = get_member(this, m_flStartThrow) - get_gametime() + 3.0;
        if (flTime < 0.0) {
            flTime = 0.0;
        }

        ShootTimed(pPlayer, vecSrc, vecThrow, flTime);

        if ( flVel < 500 ) {
        	CW_PlayAnimation(this, 3);
        } else if ( flVel < 1000 ) {
        	CW_PlayAnimation(this, 4);
        } else {
        	CW_PlayAnimation(this, 5);
        }

        // player "shoot" animation
        rg_set_animation(pPlayer, PLAYER_ATTACK1);

        set_member(this, m_flReleaseThrow, 0.0);
        set_member(this, m_flStartThrow, 0.0);
        set_member(this, m_Weapon_flNextPrimaryAttack, 0.5); // m_flNextPrimaryAttack = GetNextAttackDelay(0.5)
        set_member(this, m_Weapon_flTimeWeaponIdle, 0.5);

        set_member(pPlayer, m_rgAmmo, get_member(pPlayer, m_rgAmmo, g_iAmmoId) - 1, g_iAmmoId);

        if (get_member(pPlayer, m_rgAmmo, g_iAmmoId)) {
            // just threw last grenade
            // set attack times in the future, and weapon idle in the future so we can see the whole throw
            // animation, weapon idle will automatically retire the weapon for us.
            // m_flTimeWeaponIdle = m_flNextSecondaryAttack = m_flNextPrimaryAttack = GetNextAttackDelay(0.5);// ensure that the animation can finish playing
            set_member(this, m_Weapon_flTimeWeaponIdle, 0.5);
            set_member(this, m_Weapon_flNextSecondaryAttack, 0.5);
            set_member(this, m_Weapon_flNextPrimaryAttack, 0.5);
        }

        ZP_Player_UpdateSpeed(pPlayer);

        return;
    } else if (get_member(this, m_flReleaseThrow) > 0.0) {
        // we've finished the throw, restart.
        set_member(this, m_flStartThrow, 0.0);

        if (get_member(pPlayer, m_rgAmmo, g_iAmmoId > 0)) {
            CW_PlayAnimation(this, 7, 16.0 / 30.0);
        } else {
            CW_RemovePlayerItem(this);
            return;
        }

        set_member(this, m_flReleaseThrow, -1.0);
        return;
    }

    if (get_member(pPlayer, m_rgAmmo, g_iAmmoId)) {
        if (random_float(0.0, 1.0) <= 0.75) {
            CW_PlayAnimation(this, 0, 91.0 / 30.0);
        } else {
            CW_PlayAnimation(this, 1, 76.0 / 30.0);
        }
    } else {
        CW_RemovePlayerItem(this);
    }
}

public @Weapon_Deploy(this) {
    set_member(this, m_flReleaseThrow, -1.0);
    CW_DefaultDeploy(this, ZP_WEAPON_GRENADE_V_MODEL, ZP_WEAPON_GRENADE_P_MODEL, 7, "grenade");
}

public Float:@Weapon_GetMaxSpeed(this) {
    return ZP_HUMAN_SPEED;
}

public @Weapon_Spawn(this) {
    set_member(this, m_Weapon_iDefaultAmmo, 1);
    engfunc(EngFunc_SetModel, this, ZP_WEAPON_GRENADE_W_MODEL);
}

public @Weapon_WeaponBoxSpawn(this, pWeaponBox) {
    engfunc(EngFunc_SetModel, pWeaponBox, ZP_WEAPON_GRENADE_W_MODEL);
}

ShootTimed(pOwner, const Float:vecStart[3], const Float:vecVelocity[3], Float:flTime) {
    new pGrenade = rg_create_entity("grenade");
    dllfunc(DLLFunc_Spawn, pGrenade);
    engfunc(EngFunc_SetOrigin, pGrenade, vecStart);
    set_pev(pGrenade, pev_velocity, vecVelocity);

    static Float:vecAngles[3];
    vector_to_angle(vecVelocity, vecAngles);
    set_pev(pGrenade, pev_angles, vecAngles);
    set_pev(pGrenade, pev_owner, pOwner);

    SetTouch(pGrenade, "BounceTouch"); // Bounce if touched

    // Take one second off of the desired detonation time and set the think to PreDetonate. PreDetonate
    // will insert a DANGER sound into the world sound list and delay detonation for one second so that 
    // the grenade explodes after the exact amount of time specified in the call to ShootTimed(). 

    set_pev(pGrenade, pev_dmgtime, get_gametime() + flTime);
    SetThink(pGrenade, "TumbleThink");
    set_pev(pGrenade, pev_nextthink, get_gametime() + 0.1);

    if (flTime < 0.1) {
        set_pev(pGrenade, pev_nextthink, get_gametime());
        set_pev(pGrenade, pev_velocity, NULL_VECTOR);
    }

    set_pev(pGrenade, pev_sequence, random_num(3, 7));
    set_pev(pGrenade, pev_framerate, 1.0);

    // Tumble through the air
    // pGrenade->pev->avelocity.x = -400;

    set_pev(pGrenade, pev_gravity, 0.5);
    set_pev(pGrenade, pev_friction, 0.8);

    engfunc(EngFunc_SetModel, pGrenade, ZP_WEAPON_GRENADE_W_MODEL);
    set_pev(pGrenade, pev_dmg, 300.0);

    return pGrenade;
}

public BounceTouch(this, pOther) {
    new pOwner = pev(this, pev_owner);

    // don't hit the guy that launched this grenade
    if (pOther == pOwner) {
        return;
    }

    static Float:vecVelocity[3];
    pev(this, pev_velocity, vecVelocity);

    // only do damage if we're moving fairly fast
    if (get_member(this, m_flNextAttack) < get_gametime() && xs_vec_len(vecVelocity) > 100.0) {
        if (UTIL_IsPlayer(pOwner) && UTIL_IsPlayer(pOther) && rg_is_player_can_takedamage(pOther, pOwner)) {
            new tr = create_tr2();
            rg_multidmg_clear();
            static Float:vecForward[3];
            get_global_vector(GL_v_forward, vecForward);
            ExecuteHamB(Ham_TraceAttack, pOther, pOwner, 1.0, vecForward, tr, DMG_CLUB); 
            rg_multidmg_apply(this, pOwner);
            free_tr2(tr);
        }

        set_member(this, m_flNextAttack, get_gametime() + 1.0); // debounce
    }

    // Vector vecTestVelocity;
    // // pev->avelocity = Vector (300, 300, 300);

    // // this is my heuristic for modulating the grenade velocity because grenades dropped purely vertical
    // // or thrown very far tend to slow down too quickly for me to always catch just by testing velocity. 
    // // trimming the Z velocity a bit seems to help quite a bit.
    // vecTestVelocity = pev->velocity; 
    // vecTestVelocity.z *= 0.45;

    // if ( !m_fRegisteredSound && vecTestVelocity.Length() <= 60 )
    // {
    // 	//ALERT( at_console, "Grenade Registered!: %f\n", vecTestVelocity.Length() );

    // 	// grenade is moving really slow. It's probably very close to where it will ultimately stop moving. 
    // 	// go ahead and emit the danger sound.
        
    // 	// register a radius louder than the explosion, so we make sure everyone gets out of the way
    // 	CSoundEnt::InsertSound ( bits_SOUND_DANGER, pev->origin, static_cast<int>(pev->dmg / 0.4), 0.3 );
    // 	m_fRegisteredSound = TRUE;
    // }

    if (pev(this, pev_flags) & FL_ONGROUND) {
        // add a bit of static friction
        xs_vec_mul_scalar(vecVelocity, 0.8, vecVelocity);
        set_pev(this, pev_velocity, vecVelocity);
        set_pev(this, pev_sequence, 1);
    } else {
        // play bounce sound
        emit_sound(this, CHAN_VOICE, g_rgszBounceSounds[random(sizeof(g_rgszBounceSounds))], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
    
    new Float:flFramerate = xs_vec_len(vecVelocity) / 200.0;
    if (flFramerate > 1.0) {
        flFramerate = 1.0;
    } else if (flFramerate < 0.5) {
        flFramerate = 0.0;
    }

    set_pev(this, pev_framerate, flFramerate);
}

public TumbleThink(this) {
    if (!ExecuteHam(Ham_IsInWorld, this)) {
        engfunc(EngFunc_RemoveEntity, this);
        return;
    }

    // StudioFrameAdvance( );
    set_pev(this, pev_nextthink, get_gametime() + 0.1);

    new Float:flDmgTime;
    pev(this, pev_dmgtime, flDmgTime);

    // if (flDmgTime - 1.0 < get_gametime()) {
        // CSoundEnt::InsertSound ( bits_SOUND_DANGER, pev->origin + pev->velocity * (flDmgTime - get_gametime()), 400, 0.1 );
    // }

    if (flDmgTime <= get_gametime()) {
        SetThink(this, "Detonate");
    }

    static Float:vecVelocity[3];
    pev(this, pev_velocity, vecVelocity);

    if (pev(this, pev_waterlevel) != 0) {
        xs_vec_mul_scalar(vecVelocity, 0.5, vecVelocity);
        set_pev(this, pev_velocity, vecVelocity);
        set_pev(this, pev_framerate, 0.2);
    }
}

public Detonate(this) {
    new Float:flDamage;
    pev(this, pev_dmg, flDamage);

    CW_GrenadeDetonate(this, flDamage, flDamage * 0.125);
    SetThink(this, "GrenadeSmoke");
    set_pev(this, pev_nextthink, get_gametime() + 0.1);
}

public GrenadeSmoke(this) {
    CW_GrenadeSmoke(this);
    engfunc(EngFunc_RemoveEntity, this);
}
