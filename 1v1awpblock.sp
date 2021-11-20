#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "EZR"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>
#include <sdkhooks>

#pragma newdecls required


char Silahlist[][] = 
{
   "weapon_awp"
};
char Cvar_SilahList[][] = 
{
   "awp"
};

public Plugin myinfo = 
{
   name = "[CS:GO] Sunucuda 3 kişiden az kişi olduğunda awp alınmasını engeller", 
   author = PLUGIN_AUTHOR, 
   description = "[CS:GO] Sunucuda 3 kişiden az kişi olduğunda awp alınmasını engeller", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming", 
};
public void OnPluginStart()
{
   for (int i = 1; i <= MaxClients; i++)
   {
      if (IsValidClient(i))
      {
         OnClientPostAdminCheck(i);
      }
   }
}

public void OnClientPostAdminCheck(int client)
{
   SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}
public Action CS_OnBuyCommand(int client, const char[] weapon)
{
   if (IsWarmup())
   {
      return Plugin_Continue;
   }
   int iTSay = 0;
   int iCTSay = 0;
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsClientInGame(iClient) && !IsFakeClient(iClient))
      {
         switch (GetClientTeam(iClient))
         {
            case CS_TEAM_T:iTSay++;
            case CS_TEAM_CT:iCTSay++;
         }
      }
   }
   int Oyuncular = iTSay + iCTSay;
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsValidClient(iClient))
      {
         for (int i; i < sizeof(Cvar_SilahList); i++)
         {
            if (StrEqual(weapon, Cvar_SilahList[i], false))
            {
               if (Oyuncular <= 2)
               {
                  ClientCommand(iClient, "play player/suit_denydevice.wav");
                  CPrintToChat(client, "{darkred}[VOLITANGAMING]{green} 1{default}v{purple}1{default}'de {green}%s{default} alınmasına izin verilmez.", Silahlist[i]);
                  ClientCommand(client, "play player/suit_denydevice.wav");
                  return Plugin_Handled;
               }
            }
         }
      }
   }
   return Plugin_Continue;
}
public Action OnWeaponCanUse(int client, int weapon)
{
   if (IsWarmup())
   {
      return Plugin_Continue;
   }
   int iTSay = 0;
   int iCTSay = 0;
   char classname[32];
   GetEntityClassname(weapon, classname, sizeof(classname));
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsValidClient(iClient))
      {
         switch (GetClientTeam(iClient))
         {
            case CS_TEAM_T:iTSay++;
            case CS_TEAM_CT:iCTSay++;
         }
      }
   }
   int Oyuncular = iTSay + iCTSay;
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsValidClient(iClient))
      {
         for (int i; i < sizeof(Silahlist); i++)
         {
            if (StrEqual(classname, Silahlist[i], false))
            {
               if (Oyuncular <= 2)
               {
                  return Plugin_Handled;
               }
            }
         }
      }
   }
   return Plugin_Continue;
}
stock bool IsValidClient(int ezr_iClient)
{
   return view_as<bool>(ezr_iClient >= 1 && ezr_iClient <= MaxClients && IsClientInGame(ezr_iClient) && !IsFakeClient(ezr_iClient));
}
stock bool IsWarmup()
{
   return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod") == 1);
}
