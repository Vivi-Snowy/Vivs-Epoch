/*
	Black-market bunker (server side).
	Every restart a fortified trader outpost appears at a random spot near one of 10 towns.
	Inside: black market, weapons and ammo traders, protected by its own safe zone.
	The entrance area outside the walls is NOT protected.
*/
waitUntil {uiSleep 5; !isNil "dzf_landPos" && {!isNil "dz_eventSpot"}};
uiSleep 20;

local _sites = [ // Lingor - towns away from traders, faction territories and fortresses
	["Calamar",[3655,1492,0]],["Victorin",[6703,3386,0]],["Negrosa",[4801,2682,0]],["Manteria",[6824,4781,0]],
	["Guayucca",[3788,5980,0]],["Morada",[3075,4658,0]],["Rago",[1084,2310,0]],["Lagosa",[5313,2193,0]],
	["Gatoro",[4081,9238,0]],["Zanjeer",[1361,7457,0]]
];
local _site = _sites call BIS_fnc_selectRandom;
local _pos = [];
for "_i" from 1 to 10 do {
	_pos = [_site select 1, 150, 500] call dzf_landPos;
	if (count _pos > 0) then {
		if (count (_pos nearObjects ["House", 25]) == 0 && {count (_pos nearRoads 15) == 0}) exitWith {};
		_pos = [];
	};
};
if (count _pos == 0) exitWith {diag_log "DZ BUNKER: no free spot found";};

local _dir = random 360;
local _rel = {
	local _dx = _this select 0; local _dy = _this select 1;
	[(_pos select 0) + _dx * cos _dir + _dy * sin _dir, (_pos select 1) - _dx * sin _dir + _dy * cos _dir, 0]
};
local _place = { // [class, [dx,dy], relDir]
	local _o = createVehicle [_this select 0, [0,0,0], [], 0, "CAN_COLLIDE"];
	_o setDir (_dir + (_this select 2));
	_o setPosATL ((_this select 1) call _rel);
	_o allowDamage false;
	_o enableSimulation false;
	dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _o];
};
// walls
{["Land_HBarrier_large", _x select 0, _x select 1] call _place;} forEach [
	[[-9,14],0],[[0,14],0],[[9,14],0],
	[[-14,8],90],[[-14,0],90],[[-14,-8],90],
	[[14,8],90],[[14,0],90],[[14,-8],90],
	[[-9,-14],0],[[9,-14],0]
];
["Land_Mil_Barracks_i", [0,6], 90] call _place;
["Land_fort_bagfence_round", [-5,-11], 180] call _place;
["Land_fort_bagfence_round", [5,-11], 180] call _place;
["Land_Fire_barrel_burning", [0,-4], 0] call _place;

// traders (Epoch trader classes -> their normal trade menus)
local _traders = [["GUE_Woodlander2",[-7,-3],90],["RU_Citizen4",[7,-3],270],["Profiteer1",[0,-8],0]];
{
	local _t = createAgent [_x select 0, ((_x select 1) call _rel), [], 0, "CAN_COLLIDE"];
	{_t removeMagazine _x;} count magazines _t;
	removeAllItems _t; removeAllWeapons _t; removeBackpack _t;
	_t setDir (_dir + (_x select 2));
	_t setPosATL ((_x select 1) call _rel);
	_t setVehicleInit "this disableAI 'ANIM'; this disableAI 'AUTOTARGET'; this disableAI 'FSM'; this disableAI 'MOVE'; this disableAI 'TARGET'; this setBehaviour 'CARELESS'; this forceSpeed 0; this allowDamage false;";
	_t disableAI "ANIM"; _t disableAI "AUTOTARGET"; _t disableAI "FSM"; _t disableAI "MOVE"; _t disableAI "TARGET";
	_t setBehaviour "CARELESS"; _t setCaptive true; _t forceSpeed 0; _t allowDamage false; _t enableSimulation false;
} forEach _traders;
processInitCommands;

// safe zone just around the walls
DZE_SafeZonePosArray set [count DZE_SafeZonePosArray, [_pos, 22]];
publicVariable "DZE_SafeZonePosArray";

local _desc = [_pos, "Black Market Bunker", "ColorPink", 999999] call dz_eventSpot;
["BLACK MARKET BUNKER", format ["The traders have set up near %1 this restart: black market, weapons and ammo. Safe inside the walls only!", _site select 0], "#FF66CC"] call dz_sendPopup;
diag_log format ["DZ BUNKER: set up near %1 at %2", _site select 0, _pos];
