/*
	Random server event picker (Epoch Server Events by JasonTM, trimmed for this server).
	Runs one random event each time EpochEvents calls it; all of them run before any repeats.
	(fuelstationbomb is left out - Chernarus-only gas stations and known bugs; abandoned_vaults needs abandoned 0000 safes.)
*/
if (isNil "Server_Events_Array") then {
	Server_Events_Array = ["building_supplies","pirate_treasure","special_forces","un_supply","labyrinth","rubble_town","mechanics_truck"];
};
local _event = Server_Events_Array call BIS_fnc_selectRandom;
Server_Events_Array = Server_Events_Array - [_event];
if (count Server_Events_Array == 0) then {Server_Events_Array = nil;};
diag_log format ["SERVER EVENTS: starting %1", _event];
execVM format ["\z\addons\dayz_server\modules\%1.sqf", _event];
