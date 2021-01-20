// #include <amxmodx>
// #include <amxmisc>
// #include <fakemeta>
// #include <hamsandwich>
// // #include <zi_api_cfg>

// #define PLUGIN "[ZI]Item Spawn Point Manager"
// #define VERSION "0.0.1"
// #define AUTHOR "Zombie Invasion"

// #define CVAR_ZI_ISPM_ENABLE "zi_ispm"
// #define ZI_ISMP_AUTOSAVE_TIME 5.0

// new g_iSprPoint,
// 	Float:g_rgvecPoints[256][3],
// 	g_rgvecPoints_count = 0;

// static map[32], config[32],  filepath[64];
	
// public plugin_precache()
// {
// 	g_iSprPoint = precache_model("sprites/iunknown.spr");
// }

public plugin_init()
{
// 	register_plugin(PLUGIN, VERSION, AUTHOR);
// 	log_amx("%s %s by %s Loaded", PLUGIN, VERSION, AUTHOR);

// 	register_cvar(CVAR_ZI_ISPM_ENABLE, "1");
	
// 	register_clcmd("ispw", "clcmd_ispw");
// 	register_clcmd("say ispw", "clcmd_ispw");
// 	register_clcmd("ispr", "clcmd_ispr");
// 	register_clcmd("say ispr", "clcmd_ispr");
	
// 	RegisterHam(Ham_Player_PreThink, "player", "ham_player_pre_think");
	
// 	get_mapname(map, charsmax(map));
// 	get_configsdir(config, charsmax(config));
// 	format(filepath, 63, "%s\items\%s_items.cfg", config, map);
// 	zi_cfg_load_points(filepath, g_rgvecPoints, g_rgvecPoints_count);
	
// 	set_task(ZI_ISMP_AUTOSAVE_TIME, "timer_isp_autosave", 0, _, _, "b");
}

// public clcmd_ispw(id)
// {
// 	if(!get_cvar_num(CVAR_ZI_ISPM_ENABLE))
// 		return 1;

// 	if(!is_user_connected(id))
// 		return 1;
		
// 	new Float:fOrigin[3];
// 	pev(id, pev_origin, fOrigin);
	
// 	fOrigin[2] -= 16.0;
	
// 	for(new i = 0; i < 3; i++) {
// 		g_rgvecPoints[g_rgvecPoints_count][i] = fOrigin[i];
//   }
		
// 	g_rgvecPoints_count++;
	
// 	client_print(id, print_chat, "Write point %f %f %f", fOrigin[0], fOrigin[1], fOrigin[2]);
	
// 	return 0;
// }

// public clcmd_ispr(id)
// {
// 	if(!get_cvar_num(CVAR_ZI_ISPM_ENABLE))
// 		return 1;

// 	if(!is_user_connected(id))
// 		return 1;
	
// 	if(g_rgvecPoints_count < 1)
// 		return 1;
	
// 	new
// 		Float:fOrigin[3],
// 		Float:dif,
// 		bool:pass;
		
// 	pev(id, pev_origin, fOrigin);
// 	fOrigin[2] -= 16.0;
	
// 	for(new i = 0; i < g_rgvecPoints_count; i++)
// 	{
// 		for(new j = 0; j < 3; j++)
// 		{
// 			dif = g_rgvecPoints[i][j] - fOrigin[j];
		
// 			if(-32.0 <= dif <= 32.0)
// 				pass = true;
// 			else
// 				pass = false;
			
// 			if(!pass)
// 				break;
// 		}
		
// 		if(pass)
// 		{
// 			for(new j = 0; j < 3; j++)
// 			{
// 				if(i < g_rgvecPoints_count)
// 					g_rgvecPoints[i][j] = g_rgvecPoints[g_rgvecPoints_count-1][j];
// 			}
			
// 			g_rgvecPoints_count--;
// 			client_print(id, print_chat, "Remove point %f %f %f", fOrigin[0], fOrigin[1], fOrigin[2]);
			
// 			pass = false;
// 			break;
// 		}
// 	}
	
// 	return 0;
// }

// public ham_player_pre_think(id)
// {
// 	if(!get_cvar_num(CVAR_ZI_ISPM_ENABLE))
// 		return HAM_IGNORED;

// 	if(!is_user_connected(id)) {
// 		return HAM_IGNORED;
//   }

// 	if(g_rgvecPoints_count < 1) {
// 		return HAM_IGNORED;
//   }
		
// 	for(new i = 0; i < g_rgvecPoints_count; i++) {
// 		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, g_rgvecPoints[i], id);
// 		write_byte(TE_SPRITE);
// 		engfunc(EngFunc_WriteCoord, g_rgvecPoints[i][0]);
// 		engfunc(EngFunc_WriteCoord, g_rgvecPoints[i][1]);
// 		engfunc(EngFunc_WriteCoord, g_rgvecPoints[i][2]);
// 		write_short(g_iSprPoint);
// 		write_byte(10);
// 		write_byte(20);
// 		message_end();
// 	}
	
// 	return HAM_HANDLED;
// }

// // public timer_isp_autosave()
// // {
// // 	if(!get_cvar_num(CVAR_ZI_ISPM_ENABLE))
// // 		return 1;

// // 	if(file_exists(filepath))
// // 		delete_file(filepath);
	
// // 	if(!g_rgvecPoints_count)
// // 		return 1;
	
// // 	for(new i = 0; i < g_rgvecPoints_count; i++)
// // 		zi_cfg_write_point(filepath, g_rgvecPoints[i]);
		
// // 	return 0;
// // }