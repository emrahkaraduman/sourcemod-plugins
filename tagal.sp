#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <clientprefs>
#include <swgm>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

Handle tagl_cookie = INVALID_HANDLE;
Handle cvar_gruptag = INVALID_HANDLE;

bool tagal[MAXPLAYERS + 1];

char sClanTag[64], oyuncununtagi[64];

public Plugin myinfo = 
{
   name = "[CS:GO] Tag Al eklentisi", 
   author = "EZR", 
   description = "Oyuncular !tagal komutuyla grup tagı alabilirler", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming"
};

public void OnPluginStart()
{
   CreateConVar("tagal_eklenti", PLUGIN_VERSION, "Eklenti Sürümü", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
   
   tagl_cookie = RegClientCookie("Tag al", "Tag al [KAYIT]", CookieAccess_Private);
   
   HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
   
   cvar_gruptag = CreateConVar("ezr_gruptag", "VolitanG#", "Steam grubumuzun kısaltması");
   HookConVarChange(cvar_gruptag, OnSettingChanged);
   GetConVarString(cvar_gruptag, sClanTag, sizeof(sClanTag));
   
   RegConsoleCmd("sm_tagal", TagAlKomut);
   
   for (int iClient = MaxClients + 1; --iClient; )
   {
      if (IsClientInGame(iClient))
      {
         OnClientCookiesCached(iClient);
      }
   }
   
   AutoExecConfig(true, "tagalayari", "EZR");
   
   CreateTimer(1.0, view_as<Timer>(TagGuncelle), _, TIMER_REPEAT);
   
   CSetPrefix("{darkred}[VOLITANGAMING]{green}", sClanTag);
}
public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
   if (convar == cvar_gruptag)
   {
      strcopy(sClanTag, sizeof(sClanTag), newValue);
   }
}
public void OnClientConnected(int client)
{
   tagal[client] = false;
}
void TagGuncelle()
{
   for (int i = 1; i < MaxClients; ++i)
   {
      if (IsValidClient(i))
      {
         TagDegis(i);
      }
   }
}
void TagDegis(int client)
{
    if (tagal[client])
    {
       CS_SetClientClanTag(client, sClanTag);
    }
}
public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
   int client = GetClientOfUserId(event.GetInt("userid"));
   
   if (!IsValidClient(client))
   {
      return;
   }
   if (IsValidClient(client))
   {
      if (IsPlayerAlive(client))
      {
         if (!tagal[client])
         {
            if (!IsWarmup()) // Isınma sırasında chat spamı fixi çözmek için
            {
               CPrintToChat(client, "Grup tagınız güncel değil! {green}!tagal{default} yazarak güncelleyebilirsiniz.");
            }
         }
      }
   }
}
public Action TagAlKomut(int client, int args)
{
   if (IsValidClient(client))
   {
      if (!SWGM_InGroup(client))
      {
         CPrintToChat(client, "Tag almak icin steam grubumuza giris yapmış olmalısınız.");
         CPrintToChat(client, "{green}!grup{default} yazarak grup adresimize ulaşabilirsiniz.");
         ClientCommand(client, "play buttons/weapon_cant_buy.wav");
         return Plugin_Handled;
      }
      else
      {
         CS_GetClientClanTag(client, oyuncununtagi, sizeof(oyuncununtagi));
         if (StrEqual(sClanTag, oyuncununtagi, false))
         {
            CPrintToChat(client, "Tagınız zaten {green}%s{default} olarak görünüyor", sClanTag);
            ClientCommand(client, "play buttons/weapon_cant_buy.wav");
            return Plugin_Handled;
         }
         else
         {
            tagal[client] = true;
            char choice[8];
            IntToString(tagal[client], choice, sizeof(choice));
            SetClientCookie(client, tagl_cookie, choice);
            
            CS_SetClientClanTag(client, sClanTag);
            CPrintToChat(client, "Tagınız {green}%s{default} olarak güncellendi.", sClanTag);
            return Plugin_Handled;
         }
      }
   }
   return Plugin_Continue;
}
public void OnClientCookiesCached(int client)
{
   char sCookie[2];
   GetClientCookie(client, tagl_cookie, sCookie, sizeof(sCookie));
   tagal[client] = sCookie[0] == '1';
}

public void OnClientDisconnect(int client)
{
   char sCookie[2];
   sCookie[0] = '0' + view_as<char>(tagal[client]);
   SetClientCookie(client, tagl_cookie, sCookie);
}

public void OnPluginEnd()
{
   for (int client = 1; client <= MaxClients; client++)
   {
      if (IsClientInGame(client))
      {
         OnClientDisconnect(client);
      }
   }
}
stock bool IsValidClient(int ezr_iClient)
{
   return view_as<bool>(ezr_iClient >= 1 && ezr_iClient <= MaxClients && IsClientInGame(ezr_iClient));
}
stock bool IsWarmup()
{
   return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod") == 1);
} 
