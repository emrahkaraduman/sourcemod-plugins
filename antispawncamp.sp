#pragma semicolon 1

#define DEBUG
#define PLUGIN_AUTHOR "EZR,Sarrus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>

#pragma newdecls required

Handle g_AntiCampDisable = null;
Handle g_hClientTimers[MAXPLAYERS + 1] = { null, ... };
Handle g_hPunishTimers[MAXPLAYERS + 1] = { null, ... };
Handle g_hFreqTimers[MAXPLAYERS + 1] = { null, ... };
Handle g_hCooldownTimers[MAXPLAYERS + 1] = { null, ... };

bool g_anticampdisabled = false;

ConVar g_SlapDamage;
ConVar g_PunishDelay;
ConVar g_PunishFreq;
ConVar g_CooldownDelay;
ConVar g_disabletime;
ConVar cvar_time;

public Plugin myinfo = 
{
   name = "[CS:GO] Doğma Bölgesinde Durmayı Engelleme Eklentisi", 
   author = PLUGIN_AUTHOR, 
   description = "Doğma Bölgesinde Durmayı Engeller.", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming", 
};

public void OnPluginStart()
{
   cvar_time = CreateConVar("sm_anticamp_time", "15", "Oyuncuların bölgeyi terk etmesi veya ölmesi gereken saniye cinsinden süre");
   g_SlapDamage = CreateConVar("sm_anticamp_slapdamage", "5", "Oyuncuya verilecek tokat hasar miktari.", 0, true, 0.0, true, 100.0);
   g_PunishDelay = CreateConVar("sm_anticamp_punishdelay", "5", "Süre bittikten sonra kaç saniye sonra tokat atmaya başlasın.", 0, true, 0.0);
   g_PunishFreq = CreateConVar("sm_anticamp_punishfreq", "3", "Tokat kaç saniye aralıkta atsın.", 0, true, 0.0);
   g_CooldownDelay = CreateConVar("sm_anticamp_cooldown_delay", "5.0", "Süre bittiken sonra oyuncu hala alandan ayrılmadıysa kaç saniye sonra işleme başlasın.", 0, true, 0.0);
   g_disabletime = CreateConVar("sm_anticamp_disabletime", "40", "Sistem round başladıktan sonra kaç saniye sonra kapansın", 0, true, 0.0);
   
   HookEvent("round_start", Event_OnRoundStart);
   HookEvent("round_end", OnRoundEnd, EventHookMode_Post);
   HookEvent("teamplay_round_start", Event_OnRoundStart);
   HookEvent("player_death", OnClientDied, EventHookMode_Post);
   HookEvent("player_team", OnClientChangeTeam, EventHookMode_Pre);
   HookEvent("enter_buyzone", EntryZone, EventHookMode_Post);
   HookEvent("exit_buyzone", LeaveZone, EventHookMode_Post);
   
   AutoExecConfig(true, "antispawncamp", "EZR");
}

public Action Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
   if (GetConVarFloat(g_disabletime) != 0)
   {
      if (IsFreezeTime())
      {
         delete(g_AntiCampDisable);
         g_AntiCampDisable = CreateTimer(GetConVarFloat(g_disabletime) + GetConVarFloat(FindConVar("mp_freezetime")), AntiCamp_Disable);
      }
      else
      {
         delete(g_AntiCampDisable);
         g_AntiCampDisable = CreateTimer(GetConVarFloat(g_disabletime), AntiCamp_Disable);
      }
      g_anticampdisabled = false;
   }
}

public void OnMapStart()
{
   delete(g_AntiCampDisable);
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsClientInGame(iClient))
      {
         ResetTimer(iClient);
      }
   }
}

public void OnMapEnd()
{
   delete(g_AntiCampDisable);
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      if (IsClientInGame(iClient))
      {
         RequestFrame(ResetTimer, iClient);
      }
      
   }
}

public void ResetTimer(int client)
{
   delete(g_hClientTimers[client]);
   delete(g_hPunishTimers[client]);
   delete(g_hCooldownTimers[client]);
   delete(g_hFreqTimers[client]);
}

public void OnClientPutInServer(int client)
{
   ResetTimer(client);
}

public void OnClientDisconnect(int client)
{
   ResetTimer(client);
}

public Action OnClientChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
   int client = GetClientOfUserId(event.GetInt("userid"));
   RequestFrame(ResetTimer, client);
}

public Action OnClientDied(Event event, const char[] name, bool dontBroadcast)
{
   int client = GetClientOfUserId(event.GetInt("userid"));
   RequestFrame(ResetTimer, client);
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
   delete(g_AntiCampDisable);
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      RequestFrame(ResetTimer, iClient);
   }
}

public Action EntryZone(Event event, const char[] name, bool dontBroadcast)
{
   int client = GetClientOfUserId(event.GetInt("userid"));
   
   if (!IsValidClient(client) || IsWarmup() || g_anticampdisabled)
      return;
   
   if (g_hCooldownTimers[client] == null)
   {
      delete(g_hClientTimers[client]);
      if (IsFreezeTime())
      {
         g_hClientTimers[client] = CreateTimer(GetConVarFloat(cvar_time) + GetConVarFloat(FindConVar("mp_freezetime")), Timer_End, GetClientUserId(client));
      }
      else
      {
         g_hClientTimers[client] = CreateTimer(GetConVarFloat(cvar_time), Timer_End, GetClientUserId(client));
      }
   }
   else
   {
      ResetTimer(client);
      //CPrintToChat(client, "{darkred}[VOLITANGAMING] {green}Bekleme süreniz henüz sona ermedi!");
      SlapPlayer(client, GetConVarInt(g_SlapDamage), true);
      g_hFreqTimers[client] = CreateTimer(GetConVarFloat(g_PunishFreq), Repeat_Timer, GetClientUserId(client), TIMER_REPEAT);
   }
}

public Action LeaveZone(Event event, const char[] name, bool dontBroadcast)
{
   int client = GetClientOfUserId(event.GetInt("userid"));
   
   if (!IsValidClient(client) || IsWarmup() || g_anticampdisabled)
      return;
   
   
   ResetTimer(client);
   
   if ((GetConVarInt(g_CooldownDelay) != 0) && ((g_hPunishTimers[client] != null) || (g_hFreqTimers[client] != null)))
   {
      g_hCooldownTimers[client] = CreateTimer(GetConVarFloat(g_CooldownDelay), Cooldown_End, GetClientUserId(client));
   }
}

public Action Cooldown_End(Handle timer, int UserId)
{
   int client = GetClientOfUserId(UserId);
   
   if (!client)
   {
      return;
   }
   //CPrintToChat(client, "{darkred}[VOLITANGAMING] {green}Bekleme sürenizin süresi doldu");
   g_hCooldownTimers[client] = null;
}

public Action Timer_End(Handle timer, int UserId)
{
   int client = GetClientOfUserId(UserId);
   
   if (!client)
   {
      return;
   }
   g_hClientTimers[client] = null;
   if (client && IsClientInGame(client) && IsPlayerAlive(client))
   {
      delete(g_hPunishTimers[client]);
      g_hPunishTimers[client] = CreateTimer(GetConVarFloat(g_PunishDelay), Punish_Timer, GetClientUserId(client));
      PrintCenterText(client, "%i saniye içerisinde alanı terk etmezseniz cezalandırılacaksınız.", GetConVarInt(g_PunishDelay));
      CPrintToChat(client, "{darkred}[VOLITANGAMING] {green}%i {lightgreen}saniye içerisinde bölgeden ayrılmazsanız cezalandırılacaksınız.", GetConVarInt(g_PunishDelay));
   }
}

public Action Punish_Timer(Handle timer, int UserId)
{
   int client = GetClientOfUserId(UserId);
   
   if (!client)
   {
      return;
   }
   g_hPunishTimers[client] = null;
   if (IsClientInGame(client) && IsPlayerAlive(client))
   {
      //CPrintToChatAll("{darkred}[VOLITANGAMING] {green}%N {lightgreen}oyuncusu spawnda bekliyor!", client);
      SlapPlayer(client, GetConVarInt(g_SlapDamage), true);
      delete(g_hFreqTimers[client]);
      g_hFreqTimers[client] = CreateTimer(GetConVarFloat(g_PunishFreq), Repeat_Timer, GetClientUserId(client), TIMER_REPEAT);
   }
}

public Action Repeat_Timer(Handle timer, int UserId)
{
   int client = GetClientOfUserId(UserId);
   
   if (!client)
   {
      return Plugin_Stop;
   }
   if (!IsPlayerAlive(client))
   {
      g_hFreqTimers[client] = null;
      return Plugin_Stop;
   }
   CPrintToChat(client, "{darkred}[VOLITANGAMING] {green}Alandan Ayrılın!");
   SlapPlayer(client, GetConVarInt(g_SlapDamage), true);
   return Plugin_Continue;
}

public Action AntiCamp_Disable(Handle timer)
{
   g_anticampdisabled = true;
   //CPrintToChatAll("{lightred}Turun Geri Kalanında Doğma Bölgesinde Durmayı Engelleme Sistemi Kapatıldı!");
   for (int iClient = 1; iClient <= MaxClients; iClient++)
   {
      ResetTimer(iClient);
   }
   g_AntiCampDisable = null;
}

stock bool IsWarmup()
{
   return (GameRules_GetProp("m_bWarmupPeriod") == 1);
}

stock bool IsFreezeTime()
{
   return (GameRules_GetProp("m_bFreezePeriod") == 1);
}

public bool IsValidClient(int client)
{
   return (client >= 0 && client <= MaxClients && IsClientConnected(client) && IsClientAuthorized(client) && IsClientInGame(client) && !IsFakeClient(client));
} 
