#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "EZR"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>

#pragma newdecls required

bool TeamBlock[MAXPLAYERS + 1] = { false, ... };

public Plugin myinfo = 
{
   name = "[CS:GO] Oyuncunun takım seçmesini engelleme", 
   author = PLUGIN_AUTHOR, 
   description = "Tw yaparken belirttiğiniz oyuncu takım seçemez!", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming", 
};
public void OnPluginStart()
{
   RegAdminCmd("sm_tw", tw, ADMFLAG_BAN, "tw işlemi başladı");
   RegAdminCmd("sm_twok", twok, ADMFLAG_BAN, "tw tamam");
   
   AddCommandListener(Command_JoinTeam, "jointeam");
}
public Action Command_JoinTeam(int iClient, const char[] command, int args)
{
   if (TeamBlock[iClient])
   {
      CPrintToChat(iClient, "{darkred}[VOLITANGAMING] {red}TW{lime} işlemi bitmediği için takıma katılamazsınız!");
      ClientCommand(iClient, "play buttons/weapon_cant_buy.wav");
      return Plugin_Handled;
   }
   return Plugin_Continue;
}
public void OnClientConnected(int iClient)
{
   TeamBlock[iClient] = false;
}
public Action twok(int client, int args)
{
   if (args < 1)
   {
      CReplyToCommand(client, "{darkred}[VOLITANGAMING]{default} Kullanım: {green}!twok{purple} <nick>");
      return Plugin_Handled;
   }
   char sArgs[64];
   char sTargetName[MAX_TARGET_LENGTH];
   int iTargets[MAXPLAYERS];
   int iTargetCount;
   bool bIsML;
   
   GetCmdArg(1, sArgs, sizeof(sArgs));
   
   if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
   {
      ReplyToTargetError(client, iTargetCount);
      return Plugin_Handled;
   }
   for (int i = 0; i < iTargetCount; i++)
   {
      switchPlayerTeam2(client, iTargets[i]);
   }
   return Plugin_Handled;
}
public void switchPlayerTeam2(int client, int sTargetName)
{
   char suspect[256], admin[256];
   GetClientName(sTargetName, suspect, sizeof(suspect));
   GetClientName(client, admin, sizeof(admin));
   int team = GetClientTeam(sTargetName);
   int randomtakim = GetRandomInt(CS_TEAM_T, CS_TEAM_CT);
   
   if (team != CS_TEAM_CT && CS_TEAM_T)
   {
      CPrintToChat(client, "{darkred}[VOLITANGAMING]{green} %s {default}TW işlemi tamamlandı temiz!", suspect);
      CPrintToChatAll("{darkred}[VOLITANGAMING]{green} %s{default} adlı yetkili {orange}%s{default} adlı oyuncusuna TW işlemini tamamladı sonuç: {green}TEMİZ", admin, suspect);
      TeamBlock[sTargetName] = false;
      ChangeClientTeam(sTargetName, randomtakim);
   }
   
}
public Action tw(int client, int args)
{
   if (args < 1)
   {
      CReplyToCommand(client, "{darkred}[VOLITANGAMING]{default} Kullanım: {green}!tw{purple} <nick>");
      return Plugin_Handled;
   }
   char sArgs[64];
   char sTargetName[MAX_TARGET_LENGTH];
   int iTargets[MAXPLAYERS];
   int iTargetCount;
   bool bIsML;
   
   GetCmdArg(1, sArgs, sizeof(sArgs));
   
   if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
   {
      ReplyToTargetError(client, iTargetCount);
      return Plugin_Handled;
   }
   for (int i = 0; i < iTargetCount; i++)
   {
      switchPlayerTeam(client, iTargets[i]);
   }
   return Plugin_Handled;
}
public void switchPlayerTeam(int client, int sTargetName)
{
   CPrintToChat(sTargetName, "{darkred}[VOLITANGAMING]{orange} TW işlemi için spece atıldınız!");
   
   char Suspect[256];
   GetClientName(sTargetName, Suspect, sizeof(Suspect));
   int team = GetClientTeam(sTargetName);
   
   if (team != CS_TEAM_SPECTATOR)
   {
      TeamBlock[sTargetName] = true;
      ChangeClientTeam(sTargetName, CS_TEAM_SPECTATOR);
      CPrintToChatAll("{darkred}[VOLITANGAMING]{default} {lime}%s{green} TW işlemi başladığı için spece atıldı", Suspect);
   }
   DispatchSpawn(sTargetName);
}
