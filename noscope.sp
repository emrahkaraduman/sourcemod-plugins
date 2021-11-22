#include <sourcemod>
#include <cstrike>
#include <multicolors>
#include <smlib>

#pragma semicolon 1
#pragma newdecls required

#define DEBUG

enum struct durbunsuzbilgi
{
   char Attacker[20];
   char Client_Died[20];
   char Weapon[20];
   float Distance;
}
enum struct oldurmeler
{
   int kackisi;
   int kackisihs;
}

durbunsuzbilgi Oyuncu[MAXPLAYERS + 1];
oldurmeler kiils[MAXPLAYERS + 1];

public Plugin myinfo = 
{
   name = "[CS:GO] Dürbünsüz Algılayıcı", 
   author = "EZR", 
   description = "Dürbünsüz Algılayıcı", 
   version = "1.0", 
   url = "https://steamcommunity.com/groups/volitangaming", 
};

public void OnPluginStart()
{
   HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
   HookEvent("round_end", Event_MatchOver, EventHookMode_PostNoCopy);
   
   for (int i = 1; i <= MaxClients; i++)
   {
      if (IsClientConnected(i))
      {
         OnClientConnected(i);
      }
   }
}
public void OnClientConnected(int client)
{
   if (!IsFakeClient(client))
   {
      kiils[client].kackisi = 0;
      kiils[client].kackisihs = 0;
   }
}
public void OnClientDisconnect(int client)
{
   if (!IsFakeClient(client))
   {
      kiils[client].kackisi = 0;
      kiils[client].kackisihs = 0;
   }
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
   int attacker = GetClientOfUserId(event.GetInt("attacker"));
   int client_died = GetClientOfUserId(event.GetInt("userid"));
   
   if (!IsValidClient(client_died) || !IsValidClient(attacker))
   {
      return;
   }
   
   char weapons[32];
   GetEventString(event, "weapon", weapons, sizeof(weapons));
   
   if (!GetEntProp(attacker, Prop_Send, "m_bIsScoped") && (StrEqual(weapons, "awp") || StrEqual(weapons, "ssg08")))
   {
      GetClientName(attacker, Oyuncu[attacker].Attacker, 20);
      GetClientName(client_died, Oyuncu[attacker].Client_Died, 20);
      
      float distance = Entity_GetDistance(client_died, attacker);
      distance = Math_UnitsToMeters(distance);
      Oyuncu[attacker].Distance = distance;
      
      FormatEx(Oyuncu[attacker].Weapon, 20, "%s", weapons);
      if (event.GetBool("headshot"))
      {
         kiils[attacker].kackisihs++;
         CPrintToChatAll("{green}✯ {lightred}%s {orange}%s {default}ile Dürbünsüz HS Vurdu ({darkblue}%.1fmt{default})", Oyuncu[attacker].Attacker, Oyuncu[attacker].Weapon, Oyuncu[attacker].Distance);
         CPrintToChat(attacker, "{darkred}[VOLITANGAMING] {orange}Toplam Dürbünsüz Kafadan Vurma Sayınız: {green}%i", kiils[attacker].kackisihs);
      }
      else
      {
         kiils[attacker].kackisi++;
         CPrintToChatAll("{green}✯ {lightred}%s {orange}%s {default}ile Dürbünsüz Vurdu ({darkblue}%.1fmt{default})", Oyuncu[attacker].Attacker, Oyuncu[attacker].Weapon, Oyuncu[attacker].Distance);
         CPrintToChat(attacker, "{darkred}[VOLITANGAMING] {orange}Toplam Dürbünsüz Vurma Sayınız: {green}%i", kiils[attacker].kackisi);
      }
   }
}
public void Event_MatchOver(Event event, const char[] name, bool dontBroadcast)
{
   int enfazla, enfazlakafadan = 0;
   for (int i = 1; i <= MaxClients; i++)
   {
      if (!IsValidClient(i))
      {
         return;
      }
      if (IsValidClient(i) && kiils[i].kackisi && kiils[i].kackisihs > 0)
      {
         if (kiils[i].kackisi > kiils[enfazla].kackisi)
         {
            enfazla = i;
         }
         if (kiils[i].kackisihs > kiils[enfazlakafadan].kackisihs)
         {
            enfazlakafadan = i;
         }
         if (enfazla && enfazlakafadan > 0)
         {
            char birinci[MAX_NAME_LENGTH], enfazlabirincihs[MAX_NAME_LENGTH];
            GetClientName(enfazla, birinci, sizeof(birinci));
            GetClientName(enfazlakafadan, enfazlabirincihs, sizeof(enfazlabirincihs));
            
            CPrintToChatAll("{lightred}-----------------------------------------------");
            CPrintToChatAll("En Çok Dürbünsüz Vuran {orange}%s{default} ({green}%i{default})", birinci, kiils[enfazla].kackisi);
            CPrintToChatAll("En Çok Dürbünsüz HS Vuran {orange}%s{default} ({green}%i{default})", enfazlabirincihs, kiils[enfazlakafadan].kackisi);
            CPrintToChatAll("{lightred}-----------------------------------------------");
         }
      }
   }
}
stock bool IsValidClient(int client)
{
   return view_as<bool>(client >= 1 && client <= MaxClients && IsClientInGame(client));
}
