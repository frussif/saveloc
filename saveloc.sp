#include <sourcemod>
#include <sdktools>
#include <adt_array>

#define MAX_SLOTS 500
#define MOVETYPE_NONE 0
#define MOVETYPE_WALK 2

new Handle:savelocData[MAXPLAYERS+1];
new currentIndex[MAXPLAYERS+1];

// Saved velocity for hold/release bind
new Float:savedVel[MAXPLAYERS+1][3];
// Track whether the client is currently "holding" the teleport (to prevent double-freeze)
new bool:isHoldingTeleport[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Saveloc",
    author = "Copilot",
    description = "Multi-slot saveloc system with HUD, instant menu teleport, and true hold/release bind",
    version = "3.3",
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_savelocmenu", Command_OpenMenu);
    RegConsoleCmd("sm_saveloc", Command_SaveLoc);
    RegConsoleCmd("sm_tele", Command_TeleportToSlot);

    // Hold/release commands for keybind
    RegConsoleCmd("+sm_teleport", Command_TeleportHold);
    RegConsoleCmd("-sm_teleport", Command_TeleportRelease);

    for (new i = 1; i <= MAXPLAYERS; i++)
    {
        savelocData[i] = CreateArray(9); // pos[3], ang[3], vel[3]
        currentIndex[i] = -1;
        isHoldingTeleport[i] = false;
        savedVel[i][0] = 0.0;
        savedVel[i][1] = 0.0;
        savedVel[i][2] = 0.0;
    }
}

public OnMapEnd()
{
    for (new i = 1; i <= MAXPLAYERS; i++)
    {
        ClearArray(savelocData[i]);
        currentIndex[i] = -1;
        isHoldingTeleport[i] = false;
        savedVel[i][0] = 0.0;
        savedVel[i][1] = 0.0;
        savedVel[i][2] = 0.0;
    }
}

public Action:Command_OpenMenu(client, args)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
    {
        PrintToChat(client, "You must be alive to use the saveloc menu.");
        return Plugin_Handled;
    }

    ShowSavelocMenu(client);
    return Plugin_Handled;
}

ShowSavelocMenu(client)
{
    new Handle:menu = CreateMenu(MenuHandler_Saveloc);
    SetMenuTitle(menu, "Saveloc HUD");
    AddMenuItem(menu, "save", "Save");
    AddMenuItem(menu, "teleport", "Teleport");
    AddMenuItem(menu, "prev", "Previous");
    AddMenuItem(menu, "next", "Next");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
}

public MenuHandler_Saveloc(Handle:menu, MenuAction:action, client, item)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, item, info, sizeof(info));

        if (StrEqual(info, "save"))
        {
            SaveLocation(client);
        }
        else if (StrEqual(info, "teleport"))
        {
            TeleportInstant(client, currentIndex[client]);
        }
        else if (StrEqual(info, "prev"))
        {
            if (currentIndex[client] > 0)
            {
                currentIndex[client]--;
                TeleportInstant(client, currentIndex[client]);
            }
            else
            {
                PrintToChat(client, "No previous saveloc.");
            }
        }
        else if (StrEqual(info, "next"))
        {
            if (currentIndex[client] < GetArraySize(savelocData[client]) - 1)
            {
                currentIndex[client]++;
                TeleportInstant(client, currentIndex[client]);
            }
            else
            {
                PrintToChat(client, "No next saveloc.");
            }
        }

        Command_OpenMenu(client, 0); // Reopen menu
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Action:Command_SaveLoc(client, args)
{
    SaveLocation(client);
    return Plugin_Handled;
}

public Action:Command_TeleportToSlot(client, args)
{
    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You must be alive to teleport.");
        return Plugin_Handled;
    }

    if (args < 1)
    {
        PrintToChat(client, "Usage: /tele <slot number>");
        return Plugin_Handled;
    }

    decl String:arg[8];
    GetCmdArg(1, arg, sizeof(arg));
    new slot = StringToInt(arg) - 1;

    if (slot < 0 || slot >= GetArraySize(savelocData[client]))
    {
        PrintToChat(client, "Invalid saveloc slot.");
        return Plugin_Handled;
    }

    currentIndex[client] = slot;
    TeleportInstant(client, slot);
    return Plugin_Handled;
}

SaveLocation(client)
{
    if (!IsPlayerAlive(client)) return;

    new Float:pos[3], Float:ang[3], Float:vel[3];
    GetClientAbsOrigin(client, pos);
    GetClientEyeAngles(client, ang);
    GetClientVelocity(client, vel);

    new Float:data[9];
    data[0] = pos[0]; data[1] = pos[1]; data[2] = pos[2];
    data[3] = ang[0]; data[4] = ang[1]; data[5] = ang[2];
    data[6] = vel[0]; data[7] = vel[1]; data[8] = vel[2];

    if (GetArraySize(savelocData[client]) >= MAX_SLOTS)
    {
        RemoveFromArray(savelocData[client], 0);
        if (currentIndex[client] > 0) currentIndex[client]--;
    }
    PushArrayArray(savelocData[client], data, sizeof(data));
    currentIndex[client] = GetArraySize(savelocData[client]) - 1;

    PrintToChat(client, "Saveloc saved! Slot %d", currentIndex[client] + 1);
}

// --- Instant teleport for menu/command ---

TeleportInstant(client, index)
{
    if (!IsPlayerAlive(client)) return;

    if (index < 0 || index >= GetArraySize(savelocData[client]))
    {
        PrintToChat(client, "Invalid saveloc index.");
        return;
    }

    new Float:data[9];
    GetArrayArray(savelocData[client], index, data, sizeof(data));

    new Float:pos[3], Float:ang[3], Float:vel[3];
    pos[0] = data[0]; pos[1] = data[1]; pos[2] = data[2];
    ang[0] = data[3]; ang[1] = data[4]; ang[2] = data[5];
    vel[0] = data[6]; vel[1] = data[7]; vel[2] = data[8];

    // Ensure normal movement and apply velocity immediately
    SetEntityMoveType(client, MOVETYPE_WALK);
    TeleportEntity(client, pos, ang, vel);
}

// --- Hold/Release teleport for keybind ---

public Action:Command_TeleportHold(client, args)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Handled;

    if (isHoldingTeleport[client])
    {
        // Already holding; ignore duplicate + command
        return Plugin_Handled;
    }

    int index = currentIndex[client];
    if (index < 0 || index >= GetArraySize(savelocData[client]))
    {
        PrintToChat(client, "Invalid saveloc index.");
        return Plugin_Handled;
    }

    new Float:data[9];
    GetArrayArray(savelocData[client], index, data, sizeof(data));

    // Save velocity for release
    savedVel[client][0] = data[6];
    savedVel[client][1] = data[7];
    savedVel[client][2] = data[8];

    // Freeze and teleport to position/angles WITHOUT applying velocity yet
    SetEntityMoveType(client, MOVETYPE_NONE);
    new Float:pos[3], Float:ang[3];
    pos[0] = data[0]; pos[1] = data[1]; pos[2] = data[2];
    ang[0] = data[3]; ang[1] = data[4]; ang[2] = data[5];
    TeleportEntity(client, pos, ang, NULL_VECTOR);

    isHoldingTeleport[client] = true;
    return Plugin_Handled;
}

public Action:Command_TeleportRelease(client, args)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Handled;

    if (!isHoldingTeleport[client])
    {
        // Not holding; ignore stray - command
        return Plugin_Handled;
    }

    // Restore movement and apply saved velocity
    SetEntityMoveType(client, MOVETYPE_WALK);
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, savedVel[client]);

    isHoldingTeleport[client] = false;
    return Plugin_Handled;
}

// --- Utility ---

GetClientVelocity(client, Float:vel[3])
{
    vel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    vel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    vel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
}
