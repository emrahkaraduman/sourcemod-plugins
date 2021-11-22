#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

char sClanTag[64], izinverilenler[255];

Handle izinlitaglar;

public Plugin myinfo = 
{
   name = "[CS:GO] Grup Tagı kısıtlama eklentisi!", 
   author = "shanapu,EZR", 
   description = "Ayara girilen taglar harici tagların gösterilmesine izin verilmez!", 
   version = PLUGIN_VERSION, 
   url = "https://steamcommunity.com/groups/volitangaming"
};
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   EngineVersion g_engineversion = GetEngineVersion();
   if (g_engineversion != Engine_CSGO)
   {
      SetFailState("Bu eklenti sadece CS:GO içindir");
   }
}
public void OnPluginStart()
{
   CreateConVar("sm_tagkontrol_version", PLUGIN_VERSION, "Eklenti Sürümü", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
   
   CreateTimer(1.0, view_as<Timer>(TagUpdate), _, TIMER_REPEAT);
   
   izinlitag_dosyasi();
}
void izinlitag_dosyasi()
{
   char DosyaAdi[PLATFORM_MAX_PATH];
   BuildPath(Path_SM, DosyaAdi, sizeof(DosyaAdi), "configs/EZR/izinlitaglar.ini");
   
   Handle dosya = OpenFile(DosyaAdi, "rt");
   
   if (dosya == null)
   {
      LogMessage("Dosya Açılamadı");
      return;
   }
   
   izinlitaglar = CreateArray(255);
   
   while (!IsEndOfFile(dosya))
   {
      char satir[255];
      if (!ReadFileLine(dosya, satir, sizeof(satir)))
      {
         break;
      }
      
      TrimString(satir);
      
      if (!satir[0])
      {
         continue;
      }
      
      PushArrayString(izinlitaglar, satir);
   }
   CloseHandle(dosya);
   
}
void TagUpdate()
{
   for (int client = 1; client < MaxClients; ++client)
   {
      if (!IsValidClient(client))
      {
         return;
      }
      
      CS_GetClientClanTag(client, sClanTag, sizeof(sClanTag));
      
      if (!sClanTag[0])
      {
         return;
      }
      
      for (int i = 0; i < GetArraySize(izinlitaglar); i++)
      {
         GetArrayString(izinlitaglar, i, izinverilenler, sizeof(izinverilenler));
      }
      if (!StrContains(sClanTag, izinverilenler, false))
      {
         CS_SetClientClanTag(client, "");
         break;
      }
      
   }
}
stock bool IsValidClient(int client)
{
   if ((1 <= client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
   {
      return true;
   }
   return false;
} 