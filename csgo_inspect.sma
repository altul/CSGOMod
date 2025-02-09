#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <hamsandwich>

#define PLUGIN  "CS:GO Inspect"
#define VERSION "1.0"
#define AUTHOR  "O'Zone"

new const weaponsWithoutInspect = (1<<CSW_C4) | (1<<CSW_HEGRENADE) | (1<<CSW_FLASHBANG) | (1<<CSW_SMOKEGRENADE);

new bool:deagleDisable[MAX_PLAYERS + 1];

new inspectAnimation[] = 
{
	0,	//null
	7,	//p228
	0,	//shield
	5,	//scout
	0,	//hegrenade
	7,	//xm1014
	0,	//c4
	6,	//mac10
	6,	//aug
	0,	//smoke grenade
	16,	//elites
	6,	//fiveseven
	6,	//ump45
	5,	//sg550
	6,	//galil
	6,	//famas
	16,	//usp
	13,	//glock
	6,	//awp
	6,	//mp5
	5,	//m249
	7,	//m3
	14,	//m4a1
	6,	//tmp
	5,	//g3sg1
	0,	//flashbang
	6,	//deagle
	6,	//sg552
	6,	//ak47
	8,	//knife
	6	//p90
};

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "deagle_reload");
	RegisterHam(Ham_Item_Deploy, "weapon_deagle", "deagle_override");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "deagle_override");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "knife_override");
	
	register_impulse(100, "inspect_weapon");
}

public deagle_reload(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);
	
	remove_task(id);
	
	if (!is_user_alive(id)) return;
		
	deagleDisable[id] = true;

	set_task(2.5, "deagle_enable", id);
}

public deagle_override(weapon)
{
	static id; id = get_pdata_cbase(weapon, 41, 4);
	
	remove_task(id);
	
	if (!is_user_alive(id)) return;
		
	deagleDisable[id] = true;

	set_task(0.8, "deagle_enable", id);
}

public deagle_enable(id)
	deagleDisable[id] = false;

public knife_override(weapon)
	set_pdata_float(weapon, 48, 0.8, 4);

public inspect_weapon(id)
{
	if (!is_user_alive(id) || cs_get_user_shield(id) || cs_get_user_zoom(id) > 1) return PLUGIN_HANDLED;
	
	new weaponId = get_user_weapon(id);
	static weapon; weapon = get_pdata_cbase(id, 373);
	
	if (weaponsWithoutInspect & (1<<weaponId)) return PLUGIN_HANDLED;
	
	new animation = inspectAnimation[weaponId], currentAnimation = pev(get_pdata_cbase(weapon, 41, 4), pev_weaponanim);
	
	switch(weaponId) {
		case CSW_M4A1: {
			if (!cs_get_weapon_silen(weapon)) animation = 15;
			
			if (!currentAnimation || currentAnimation == 7 || currentAnimation == animation) play_inspect(id, weapon, animation);
		}
		case CSW_USP: {
			if (!cs_get_weapon_silen(weapon)) animation = 17;

			if (!currentAnimation || currentAnimation == 8 || currentAnimation == animation) play_inspect(id, weapon, animation);
		}
		case CSW_DEAGLE: if (!deagleDisable[id]) play_inspect(id, weapon, animation);
		case CSW_GLOCK18: if (!currentAnimation || currentAnimation == 1 || currentAnimation == 2 || currentAnimation == 9 || currentAnimation == 10 || currentAnimation == animation) play_inspect(id, weapon, animation);
		default: if (!currentAnimation || currentAnimation == animation) play_inspect(id, weapon, animation);
	}
	
	return PLUGIN_HANDLED;
}

stock play_inspect(id, weapon, animation)
{
	set_pdata_float(weapon, 48, 7.0, 4);
	set_pev(id, pev_weaponanim, animation);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(animation);
	write_byte(pev(id, pev_body));
	message_end();	
}

stock cmd_execute(id, const text[], any:...)
{
	#pragma unused text

	new message[192];

	format_args(message, charsmax(message), 1);

	message_begin(id == 0 ? MSG_ALL : MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(message) + 2);
	write_byte(10);
	write_string(message);
	message_end();
}
