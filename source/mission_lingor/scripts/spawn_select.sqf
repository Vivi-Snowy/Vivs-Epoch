/*
	Spawn picker for fresh characters (replaces the old map-click skydive).
	The map opens with 6 random spawn points right next to towns and cities (2 cities + 4 villages).
	Click a green flag to spawn there, on the ground. A new random set is rolled every time you die.
	Points avoid trader safe zones, faction territories, AI missions/fortresses, occupied towns and
	(on Lingor) the offshore islands. Closing the map or waiting 2 minutes picks one for you.
*/
if (isDedicated) exitWith {};

waitUntil {uiSleep 0.5; !isNil "Dayz_loginCompleted"};
if (isNil "freshSpawn" || {freshSpawn != 2}) exitWith {};

local _lingor = toLower worldName == "lingor";
local _size = if (_lingor) then {10240} else {15360};
local _onIsland = {
	local _px = _this select 0; local _py = _this select 1;
	_lingor && {(_px > 7800 && {_py > 6400}) || {_px > 8750 && {_py > 3300} && {_py < 5800}}}
};
local _avoid = []; // [pos, radius]
{_avoid set [count _avoid, [_x select 0, (_x select 1) + 250]];} forEach DZE_SafeZonePosArray;
if (!isNil "dz_spawnAvoid") then {_avoid = _avoid + dz_spawnAvoid;};
local _blocked = {
	local _p = _this; local _b = false;
	{if ((_p distance (_x select 0)) < (_x select 1)) exitWith {_b = true;};} forEach _avoid;
	_b
};

// candidate towns
local _cities = []; local _villages = [];
{
	local _p = locationPosition _x; _p set [2, 0];
	if ((_p select 0) > 150 && {(_p select 1) > 150} && {(_p select 0) < (_size - 150)} && {(_p select 1) < (_size - 150)} && {!(_p call _onIsland)} && {!(_p call _blocked)}) then {
		if (type _x in ["NameCityCapital","NameCity"]) then {_cities set [count _cities, [_p, text _x]];} else {_villages set [count _villages, [_p, text _x]];};
	};
} forEach (nearestLocations [[_size / 2, _size / 2, 0], ["NameCityCapital","NameCity","NameVillage"], _size]);

local _pickFrom = { // [list, count] -> random picks without repeats
	local _l = +(_this select 0); local _out = [];
	for "_i" from 1 to (_this select 1) do {
		if (count _l == 0) exitWith {};
		local _c = _l call BIS_fnc_selectRandom;
		_out set [count _out, _c]; _l = _l - [_c];
	};
	_out
};
local _towns = ([_cities, 2] call _pickFrom) + ([_villages, 6 - ((count _cities) min 2)] call _pickFrom);

// a safe spot on the edge of each town (on land, not inside a wall)
local _points = [];
{
	local _tp = _x select 0; local _spot = [];
	for "_t" from 1 to 15 do {
		local _a = random 360; local _d = 60 + random 120;
		local _c = [(_tp select 0) + _d * sin _a, (_tp select 1) + _d * cos _a, 0];
		if (!surfaceIsWater _c) then {
			local _e = _c findEmptyPosition [0, 25, "SUV_Red"];
			if (count _e > 0 && {!surfaceIsWater _e}) exitWith {_spot = _e;};
		};
	};
	if (count _spot > 0) then {_points set [count _points, [_spot, _x select 1]];};
} forEach _towns;
if (count _points == 0) exitWith {diag_log "SPAWN SELECT: no spawn points found, keeping the normal spawn";};

// markers
local _markers = [];
{
	local _m = createMarkerLocal [format ["dzsp_%1", _forEachIndex], _x select 0];
	_m setMarkerShapeLocal "ICON"; _m setMarkerTypeLocal "Flag1"; _m setMarkerColorLocal "ColorGreen";
	_m setMarkerTextLocal format ["SPAWN %1: %2", _forEachIndex + 1, _x select 1];
	_markers set [count _markers, _m];
} forEach _points;

uiSleep 1;
dzsp_choice = -1;
dzsp_points = _points;
openMap true;
uiSleep 0.3;
mapAnimAdd [0, 0.6, [_size / 2, _size / 2, 0]]; mapAnimCommit;
systemChat "Pick your spawn: click one of the green flags on the map (closing the map picks one at random).";
onMapSingleClick "
	private ['_best','_bd']; _best = -1; _bd = 600;
	{if (((_x select 0) distance _pos) < _bd) then {_bd = (_x select 0) distance _pos; _best = _forEachIndex;};} forEach dzsp_points;
	if (_best >= 0) then {dzsp_choice = _best;} else {systemChat 'Click closer to one of the green flags.';};
	true";

local _timeout = diag_tickTime + 120;
waitUntil {uiSleep 0.2; dzsp_choice >= 0 || {!visibleMap} || {diag_tickTime > _timeout}};
onMapSingleClick "";
if (dzsp_choice < 0) then {dzsp_choice = floor random (count _points);};
local _sel = _points select dzsp_choice;
openMap false;
{deleteMarkerLocal _x;} forEach _markers;

// move there
cutText ["", "BLACK OUT", 1];
uiSleep 1.2;
local _pos = _sel select 0;
player setVelocity [0, 0, 0];
player setDir random 360;
player setPosATL [_pos select 0, _pos select 1, 0];
dayz_myPosition = getPosATL player;
uiSleep 0.8;
cutText ["", "BLACK IN", 2];
systemChat format ["You wake up on the edge of %1.", _sel select 1];
diag_log format ["SPAWN SELECT: spawned at %1 (%2)", _sel select 1, mapGridPosition player];

// spawn protection: AI ignore you for 3 minutes, or until you fire a shot
player setCaptive true;
systemChat "Spawn protection: AI will ignore you for 3 minutes (ends early if you shoot).";
dzsp_fired = false;
local _eh = player addEventHandler ["Fired", {dzsp_fired = true;}];
local _end = diag_tickTime + 180;
waitUntil {uiSleep 1; dzsp_fired || {diag_tickTime > _end} || {!alive player}};
player removeEventHandler ["Fired", _eh];
player setCaptive false;
if (alive player) then {systemChat "Spawn protection is over - stay sharp.";};
