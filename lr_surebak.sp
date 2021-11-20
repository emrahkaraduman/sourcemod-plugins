#include <sourcemod>
#include <cstrike>
#include <lvl_ranks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1"

public Plugin myinfo = 
{
   name = "[CS:GO] Sürene bak", 
   author = "EZR", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming"
};
public void OnPluginStart()
{
   RegConsoleCmd("sm_surem", SuremBak, "Sunucuda oynama sürene bak");
}
public Action SuremBak(int client, int args)
{
   int OynamaSure = LR_GetClientInfo(client, ST_PLAYTIME);
   int Sure = OynamaSure;
   CPrintToChat(client, " \x10Sunucumuzda oynama süreniz:\x04 %d\x10 Saat\x04 %d\x10 Dakkia", Sure / 3600, Sure / 60 % 60);
   return Plugin_Handled;
} 