/*
	DZ Living World (server side) - makes the map feel busy.
	  - AI helicopter patrols (Military / Bandits) flying between towns. Shoot one down -> loot crate at the wreck.
	  - Supply plane: a C-130 flies over and parachutes a crate (smoke + marker where it lands).
	  - Faction convoys: armed escort + cargo truck driving between faction territories.
	    Kill the crew and the truck (full of loot) is yours until restart.
	  - Town takeovers: a faction occupies a town. Clear it out for coins and a crate.
	Uses the helpers from dz_factions.sqf / dz_activities.sqf / server_functions.sqf.
*/
waitUntil {uiSleep 5; !isNil "dzf_spawnGroup" && {!isNil "dzf_towns"} && {!isNil "dza_fillCrate"} && {!isNil "WAI_GetTurrets"}};
uiSleep 60;
diag_log "DZ LIVING: starting";

// ---------------- per-map settings ----------------
local _lingor = toLower worldName == "lingor";
dzl_mapSize      = if (_lingor) then {10240} else {15360};
dzl_heliCount    = if (_lingor) then {3} else {4};   // helicopter patrols in the air at once
dzl_convoyCount  = 2;                                 // convoys on the road at once
dzl_heliRespawn  = 900;    // seconds before a lost helicopter is replaced
dzl_convoyRespawn = 1200;  // seconds before a destroyed convoy is replaced
dzl_planeEvery   = [2400, 3600]; // seconds between supply planes [min,max]
dzl_takeoverEvery = [1800, 2700]; // seconds between town takeovers [min,max]
dzl_takeoverReward = 2500;
if (isNil "dzf_onIsland") then {dzf_onIsland = {false};};

// ---------------- helpers ----------------
dzl_dist2D = {[(_this select 0) select 0, (_this select 0) select 1, 0] distance [(_this select 1) select 0, (_this select 1) select 1, 0]};
dzl_randomTown = { // [minPlayerDist, excludeSafe] -> town position or []
	local _res = [];
	for "_t" from 1 to 25 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzf_inSafeZone) && {(_p call dzf_nearestPlayerDist) > (_this select 0)}) exitWith {_res = _p;};
	};
	_res
};
dzl_crewVehicle = { // [faction, vehicle] -> group, crew in driver + all turrets (+ cargo count)
	local _veh = _this select 1;
	local _turrets = (typeOf _veh) call WAI_GetTurrets;
	local _grp = [_this select 0, getPosATL _veh, 1 + count _turrets] call dzf_spawnGroup;
	local _u = units _grp;
	(_u select 0) assignAsDriver _veh; (_u select 0) moveInDriver _veh;
	{
		if (count _u > (_forEachIndex + 1)) then {(_u select (_forEachIndex + 1)) moveInTurret [_veh, _x];};
	} forEach _turrets;
	_grp setVariable ["DoNotFreeze", true];
	_grp allowFleeing 0;
	_grp
};
dzl_popupNear = { // [pos, range, title, text, colour]
	local _pos = _this select 0;
	{if ((_x distance _pos) < (_this select 1)) then {[_x, _this select 2, _this select 3, _this select 4] call dzf_huntPopup;};} forEach (call dzf_players);
};
dzl_lootCrate = { // [pos, weapons, extra items] -> crate
	local _c = createVehicle [WAI_CrateMd call BIS_fnc_selectRandom, _this select 0, [], 4, "NONE"];
	[_c, _this select 1, 4, _this select 2] call dza_fillCrate;
	_c
};

// ======================= HELICOPTER PATROLS =======================
dzl_heliTypes = [
	["Military", ["UH60M_EP1_DZE","UH1Y_DZE","UH1H_DZE"]],
	["Bandits",  ["Mi17_DZE","UH1H_DZE","Mi17_DZE"]]
];
dzl_helis = []; // [group, heli, nextSpawnTime]
for "_i" from 1 to dzl_heliCount do {dzl_helis set [count dzl_helis, [grpNull, objNull, diag_tickTime + 120 + _i * 240]];};
dzl_spawnHeli = {
	local _pick = dzl_heliTypes call BIS_fnc_selectRandom;
	local _fac = _pick select 0;
	local _cls = (_pick select 1) call BIS_fnc_selectRandom;
	if !(isClass (configFile >> "CfgVehicles" >> _cls)) exitWith {diag_log format ["DZ LIVING: heli class %1 missing", _cls]; [grpNull, objNull]};
	local _start = [1500, true] call dzl_randomTown;
	if (count _start == 0) exitWith {[grpNull, objNull]};
	local _heli = createVehicle [_cls, [_start select 0, _start select 1, 150], [], 0, "FLY"];
	dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _heli];
	_heli setFuel 1; _heli setVehicleAmmo 1; _heli engineOn true; _heli lock true;
	_heli flyInHeight (100 + random 60);
	_heli setVariable ["dzl_fac", _fac];
	_heli call dzv_addClaim;
	local _grp = [_fac, _heli] call dzl_crewVehicle;
	_grp setBehaviour "AWARE"; _grp setCombatMode "RED"; _grp setSpeedMode "NORMAL";
	for "_w" from 1 to 7 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if !(_p call dzf_inSafeZone) then {
			local _wp = _grp addWaypoint [_p, 200];
			_wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 300;
		};
	};
	(_grp addWaypoint [_start, 0]) setWaypointType "CYCLE";
	diag_log format ["DZ LIVING: %1 helicopter (%2) patrol up near %3", _fac, _cls, mapGridPosition _start];
	[_grp, _heli]
};
dzl_heliDown = { // [group, heli]
	local _heli = _this select 1;
	local _pos = getPosATL _heli; _pos set [2, 0];
	local _fac = _heli getVariable ["dzl_fac", "Military"];
	if (!surfaceIsWater _pos) then {
		[[(_pos select 0) + 8, (_pos select 1) + 8, 0], 4, [dza_medical call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom, "ItemJerrycan", "PartGeneric"]] call dzl_lootCrate;
		[_pos, "Downed Heli", "ColorOrange", 2400] call dz_eventSpot;
		[_pos, 3500, "HELICOPTER DOWN", format ["A %1 helicopter went down near %2. Its cargo is up for grabs!", _fac, _pos call dz_nearTown], "#FF9933"] call dzl_popupNear;
	};
	diag_log format ["DZ LIVING: %1 helicopter down at %2", _fac, mapGridPosition _pos];
};

// ======================= SUPPLY PLANE =======================
dzl_nextPlane = diag_tickTime + 900 + random 900;
dzl_planeBusy = false;
dzl_supplyPlane = {
	dzl_planeBusy = true;
	local _target = [];
	for "_t" from 1 to 30 do {
		local _p = [[dzl_mapSize / 2, dzl_mapSize / 2, 0], 300, dzl_mapSize * 0.42] call dzf_landPos;
		if (count _p > 0 && {count (_p nearObjects ["House", 40]) == 0}) exitWith {_target = _p;};
	};
	if (count _target == 0) exitWith {dzl_planeBusy = false;};
	local _dir = random 360;
	local _start = [(_target select 0) - 3500 * sin _dir, (_target select 1) - 3500 * cos _dir, 300];
	local _end   = [(_target select 0) + 4000 * sin _dir, (_target select 1) + 4000 * cos _dir, 300];
	local _plane = createVehicle [(if (isClass (configFile >> "CfgVehicles" >> "C130J_US_EP1")) then {"C130J_US_EP1"} else {"C130J"}), _start, [], 0, "FLY"];
	dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _plane];
	_plane setDir _dir; _plane setPosATL _start;
	_plane setVelocity [110 * sin _dir, 110 * cos _dir, 0];
	_plane allowDamage false; _plane lock true; _plane flyInHeight 250;
	local _grp = createGroup WEST;
	local _pilot = _grp createUnit [(if (isClass (configFile >> "CfgVehicles" >> "Pilot_EP1")) then {"Pilot_EP1"} else {"USMC_Soldier_Pilot"}), [0,0,0], [], 0, "NONE"];
	_pilot moveInDriver _plane; _pilot allowDamage false; _pilot setCaptive true;
	_grp setBehaviour "CARELESS"; _grp setCombatMode "BLUE";
	_pilot doMove _target;
	["SUPPLY PLANE", format ["A cargo plane is heading for %1 to drop supplies. Watch the sky!", _target call dz_nearTown], "#66CCFF"] call dz_sendPopup;
	diag_log format ["DZ LIVING: supply plane inbound to %1", mapGridPosition _target];
	local _t0 = diag_tickTime;
	waitUntil {uiSleep 1; ([getPosATL _plane, _target] call dzl_dist2D) < 180 || {diag_tickTime - _t0 > 240} || {!alive _plane}};
	// drop
	local _dp = getPosATL _plane;
	local _crate = createVehicle ["DZ_AmmoBoxBigUS", [_dp select 0, _dp select 1, (_dp select 2) - 15], [], 0, "FLY"];
	local _chute = createVehicle ["ParachuteMediumWest", [_dp select 0, _dp select 1, (_dp select 2) - 15], [], 0, "FLY"];
	_chute setPos [_dp select 0, _dp select 1, (_dp select 2) - 15];
	_crate attachTo [_chute, [0, 0, -1.2]];
	_pilot doMove _end;
	[_crate, 6, 5, [dza_medical call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom, "PartEngine", "PartWheel", "ItemJerrycan", "FoodCanBakedBeans", "ItemWaterbottle"]] call dza_fillCrate;
	local _t1 = diag_tickTime;
	waitUntil {uiSleep 0.5; ((getPosATL _crate) select 2) < 3 || {diag_tickTime - _t1 > 120}};
	detach _crate;
	local _land = getPosATL _crate; _land set [2, 0];
	_crate setPosATL _land;
	"SmokeShellRed" createVehicle [(_land select 0) + 3, (_land select 1), 0];
	_crate addWeaponCargoGlobal ["ItemToolbox", 1];
	[_land, "Air Drop", "ColorBlue", 2700] call dz_eventSpot;
	["AIR DROP LANDED", format ["The supply crate landed near %1 (%2). First come, first served!", _land call dz_nearTown, mapGridPosition _land], "#66CCFF"] call dz_sendPopup;
	uiSleep 15;
	if (!isNull _chute) then {deleteVehicle _chute;};
	// fly away and clean up
	local _t2 = diag_tickTime;
	waitUntil {uiSleep 2; ([getPosATL _plane, _target] call dzl_dist2D) > 3500 || {diag_tickTime - _t2 > 120}};
	{deleteVehicle _x;} forEach (crew _plane);
	deleteVehicle _plane; deleteGroup _grp;
	dzl_planeBusy = false;
	// crate disappears after 45 min if nobody is near
	[_crate] spawn {
		uiSleep 2700;
		local _c = _this select 0;
		waitUntil {uiSleep 30; isNull _c || {((getPosATL _c) call dzf_nearestPlayerDist) > 300}};
		if (!isNull _c) then {deleteVehicle _c;};
	};
};

// ======================= CONVOYS =======================
dzl_truckTypes = ["Ural_TK_CIV_EP1_DZE","V3S_RA_TK_GUE_EP1_DZE","Ural_UN_EP1_DZE"];
dzl_convoys = []; // [group, escort, truck, marker, nextSpawn, faction]
for "_i" from 1 to dzl_convoyCount do {dzl_convoys set [count dzl_convoys, [grpNull, objNull, objNull, "", diag_tickTime + 300 + _i * 300, ""]];};
dzl_roadNear = { // pos -> nearest road pos (or pos)
	local _r = _this nearRoads 400;
	if (count _r > 0) then {getPosATL (_r select 0)} else {_this}
};
dzl_spawnConvoy = {
	local _z = dzf_zones call BIS_fnc_selectRandom;
	local _fac = _z select 0;
	if (_fac == "Stalkers" && {random 1 < 0.5}) then {_fac = "Bandits";};
	local _from = (_z select 1) call dzl_roadNear;
	if (((_from) call dzf_nearestPlayerDist) < 900 || {_from call dzf_onIsland}) exitWith {[]};
	local _dest = [];
	for "_t" from 1 to 20 do {
		local _q = (dzf_zones call BIS_fnc_selectRandom) select 1;
		if ((_q distance _from) > 2500 && {!(_q call dzf_onIsland)}) exitWith {_dest = _q call dzl_roadNear;};
	};
	if (count _dest == 0) exitWith {[]};
	local _vt = [];
	{if ((_x select 0) == _fac) exitWith {_vt = _x select 1;};} forEach dzf_vehTypes;
	if (count _vt == 0) then {_vt = ["HMMWV_M2_DZE"];};
	local _escort = createVehicle [_vt call BIS_fnc_selectRandom, _from, [], 0, "NONE"];
	local _truck = createVehicle [dzl_truckTypes call BIS_fnc_selectRandom, _escort modelToWorld [0, -14, 0], [], 0, "NONE"];
	_truck setDir (getDir _escort);
	{
		dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _x];
		_x setFuel 1; _x lock true;
		_x setVariable ["dzf_patrolVeh", true, true];
		clearWeaponCargoGlobal _x; clearMagazineCargoGlobal _x;
		_x call dzv_addClaim;
	} forEach [_escort, _truck];
	// cargo
	[_truck, 6, 4, ([dza_gems call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom] + [dza_medical call BIS_fnc_selectRandom, "PartEngine", "PartWheel", "PartWheel", "ItemJerrycan", "CinderBlocks", "CinderBlocks", "MortarBucket", "PartPlankPack", "PartPlywoodPack"])] call dza_fillCrate;
	local _grp = [_fac, _escort] call dzl_crewVehicle;
	local _u2 = [_fac, getPosATL _truck, 2] call dzf_spawnGroup;
	{[_x] joinSilent _grp;} forEach (units _u2);
	deleteGroup _u2;
	local _tu = (units _grp) select ((count units _grp) - 2);
	_tu assignAsDriver _truck; _tu moveInDriver _truck;
	((units _grp) select ((count units _grp) - 1)) moveInCargo _truck;
	_grp setBehaviour "SAFE"; _grp setSpeedMode "LIMITED"; _grp setCombatMode "RED"; _grp setFormation "COLUMN";
	local _wp = _grp addWaypoint [_dest, 0]; _wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 40;
	_wp = _grp addWaypoint [_from, 0]; _wp setWaypointType "MOVE"; _wp setWaypointCompletionRadius 40;
	(_grp addWaypoint [_dest, 0]) setWaypointType "CYCLE";
	local _f = _fac call dzf_getFaction;
	local _m = createMarker [format ["dzl_convoy_%1", round (diag_tickTime * 10)], getPosATL _escort];
	_m setMarkerShape "ICON"; _m setMarkerType "mil_arrow"; _m setMarkerColor (_f select 5); _m setMarkerText format ["%1 convoy", _fac];
	["CONVOY SPOTTED", format ["A %1 supply convoy is driving from %2 towards %3. Ambush it - the cargo truck is full of loot!", _fac, _from call dz_nearTown, _dest call dz_nearTown], _f select 7] call dz_sendPopup;
	diag_log format ["DZ LIVING: %1 convoy %2 -> %3", _fac, mapGridPosition _from, mapGridPosition _dest];
	[_grp, _escort, _truck, _m, 0, _fac]
};

// ======================= TOWN TAKEOVERS =======================
dzl_takeover = []; // [groups, pos, markers, start, faction, townName]
dzl_nextTakeover = diag_tickTime + 1200 + random 600;
dzl_startTakeover = {
	local _pos = [];
	for "_t" from 1 to 25 do {
		local _p = [900, true] call dzl_randomTown;
		if (count _p > 0) then {
			local _ok = !(_p call dzf_onIsland);
			{if ((_p distance (_x select 1)) < 700) exitWith {_ok = false;};} forEach dzf_zones;
			if (_ok && {!isNil "dza_warlord"} && {count dza_warlord > 0}) then {if ((_p distance (getPosATL (dza_warlord select 1))) < 800) then {_ok = false;};};
			if (_ok) exitWith {_pos = _p;};
		};
	};
	if (count _pos == 0) exitWith {};
	local _fac = ["Bandits","Military","Stalkers","Bandits"] call BIS_fnc_selectRandom;
	local _f = _fac call dzf_getFaction;
	local _town = _pos call dz_nearTown;
	local _groups = [];
	{
		local _g = [_fac, [(_pos select 0) + (_x select 0), (_pos select 1) + (_x select 1), 0], _x select 2] call dzf_spawnGroup;
		[_g, _pos, 150] call dzf_patrolArea;
		_groups set [count _groups, _g];
	} forEach [[0,0,6],[40,-30,5],[-40,30,4]];
	local _id = round (diag_tickTime * 10);
	local _m = createMarker [format ["dzl_to_%1", _id], _pos];
	_m setMarkerShape "ELLIPSE"; _m setMarkerSize [220,220]; _m setMarkerColor (_f select 5); _m setMarkerBrush "DiagGrid"; _m setMarkerAlpha 0.6;
	local _t = createMarker [format ["dzl_tot_%1", _id], _pos];
	_t setMarkerShape "ICON"; _t setMarkerType "mil_flag"; _t setMarkerColor (_f select 5); _t setMarkerText format ["%1 occupied by %2", _town, _fac];
	dzl_takeover = [_groups, _pos, [_m,_t], diag_tickTime, _fac, _town];
	["TOWN OCCUPIED", format ["The %1 have taken over %2 with 15 men. Clear them out for %3 coins and their stash!", _fac, _town, dzl_takeoverReward], _f select 7] call dz_sendPopup;
	diag_log format ["DZ LIVING: %1 took over %2 (%3)", _fac, _town, mapGridPosition _pos];
};
dzl_checkTakeover = {
	if (count dzl_takeover == 0) exitWith {};
	local _groups = dzl_takeover select 0; local _pos = dzl_takeover select 1;
	local _alive = 0;
	{_alive = _alive + (_x call dzf_aliveCount);} forEach _groups;
	if (_alive == 0) exitWith {
		{deleteMarker _x;} forEach (dzl_takeover select 2);
		{deleteGroup _x;} forEach _groups;
		[_pos, 5, [dza_gems call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom]] call dzl_lootCrate;
		"SmokeShellGreen" createVehicle _pos;
		["TOWN LIBERATED", format ["%1 has been cleared of %2! Their stash is in the middle of town (green smoke).", dzl_takeover select 5, dzl_takeover select 4], "#33CC33"] call dz_sendPopup;
		{if ((_x distance _pos) < 500) then {[_x, dzl_takeoverReward, format ["liberating %1", dzl_takeover select 5]] call dza_pay;};} forEach (call dzf_players);
		dzl_takeover = [];
	};
	if ((diag_tickTime - (dzl_takeover select 3)) > 3000 && {(_pos call dzf_nearestPlayerDist) > 1000}) then {
		{deleteMarker _x;} forEach (dzl_takeover select 2);
		{_x call dzf_deleteGroup;} forEach _groups;
		["OCCUPATION OVER", format ["The %1 have pulled out of %2.", dzl_takeover select 4, dzl_takeover select 5], "#AAAAAA"] call dz_sendPopup;
		dzl_takeover = [];
	};
};

// spawn picker (client): places fresh spawns must stay away from
dzl_publishAvoid = {
	local _a = [];
	{_a set [count _a, [_x select 1, (_x select 2) + 300]];} forEach dzf_zones;
	{if (typeName _x == "ARRAY") then {_a set [count _a, [_x, 500]];};} forEach DZE_MissionPositions;
	if (count dzl_takeover > 0) then {_a set [count _a, [dzl_takeover select 1, 450]];};
	if (!isNil "dza_warlord" && {count dza_warlord > 0}) then {_a set [count _a, [getPosATL (dza_warlord select 1), 450]];};
	// live hostile AI groups (patrols, hunters, skirmishes) - don't spawn players next to them
	{
		if ((side _x == EAST || {side _x == RESISTANCE}) && {count units _x > 0} && {alive (leader _x)}) then {_a set [count _a, [getPosATL (leader _x), 400]];};
	} forEach allGroups;
	{_a set [count _a, [_x select 1, 500]];} forEach dzl_skirmishes;
	if (!isNil "dzw_avoid") then {_a = _a + (call dzw_avoid);};
	if (!isNil "dzp_avoid") then {_a = _a + (call dzp_avoid);};
	dz_spawnAvoid = _a;
	publicVariable "dz_spawnAvoid";
};
dzl_nextAvoid = 0;

// ======================= SKIRMISHES NEAR PLAYERS =======================
// Every few minutes a small fight breaks out in a town 500-1000m from a player, so you hear gunfire
// and see tracers. Join in for loot, or stay away. Leftovers are cleaned up when nobody is near.
dzl_skirmishes = []; // [groups, pos, start, town]
dzl_nextSkirmish = diag_tickTime + 300;
dzl_matchups = [["Bandits","Stalkers"],["Military","Bandits"],["Survivors","Bandits"],["Stalkers","Military"],["Survivors","Hunters"]];
dzl_startSkirmish = {
	local _players = call dzf_players;
	if (count _players == 0) exitWith {};
	local _plr = _players call BIS_fnc_selectRandom;
	local _pp = getPosATL _plr;
	local _pos = [];
	for "_t" from 1 to 40 do {
		local _q = dzf_towns call BIS_fnc_selectRandom;
		local _d = _q distance _pp;
		if (_d > 500 && {_d < 1000} && {!(_q call dzf_inSafeZone)} && {!(_q call dzf_onIsland)} && {(_q call dzf_nearestPlayerDist) > 450} && {isNil "dzs_bad" || {!(_q call dzs_bad)}}) exitWith {_pos = _q;};
	};
	if (count _pos == 0) exitWith {};
	local _m = dzl_matchups call BIS_fnc_selectRandom;
	local _a = random 360;
	local _groups = [];
	{
		local _sp = [(_pos select 0) + (70 + random 40) * sin (_a + _forEachIndex * 180), (_pos select 1) + (70 + random 40) * cos (_a + _forEachIndex * 180), 0];
		if (surfaceIsWater _sp) then {_sp = _pos;};
		local _g = [_x, _sp, 3 + floor random 3] call dzf_spawnGroup;
		_g setBehaviour "AWARE"; _g setCombatMode "RED"; _g setSpeedMode "NORMAL";
		_g move _pos;
		_groups set [count _groups, _g];
	} forEach _m;
	// make sure they find each other
	{local _g = _x; {local _o = _x; if (_o != _g) then {{_x reveal [leader _o, 1.5];} forEach (units _g);};} forEach _groups;} forEach _groups;
	local _town = _pos call dz_nearTown;
	dzl_skirmishes set [count dzl_skirmishes, [_groups, _pos, diag_tickTime, _town]];
	diag_log format ["DZ LIVING: skirmish %1 vs %2 at %3 (%4m from %5)", _m select 0, _m select 1, _town, round (_pos distance _pp), name _plr];
	// sometimes a survivor NPC mentions it in chat
	if (!isNil "dzs_parties" && {count dzs_parties > 0} && {random 1 < 0.4}) then {
		[_town] spawn {
			uiSleep (40 + random 60);
			local _p = dzs_parties call BIS_fnc_selectRandom;
			local _u = leader (_p select 0);
			if (alive _u) then {[_u getVariable ["dzs_name", "Survivor"], ["anyone hear that shooting near " + (_this select 0) + "?", "big fight going on near " + (_this select 0), "lots of gunfire around " + (_this select 0) + ", staying away lol"] call BIS_fnc_selectRandom] call dzs_chat;};
		};
	};
};
dzl_checkSkirmishes = {
	local _keep = [];
	{
		local _s = _x;
		local _alive = 0;
		{_alive = _alive + (_x call dzf_aliveCount);} forEach (_s select 0);
		local _age = diag_tickTime - (_s select 2);
		local _far = ((_s select 1) call dzf_nearestPlayerDist) > 700;
		if ((_alive == 0) || {_age > 1200 && {_far}}) then {
			{_x call dzf_deleteGroup;} forEach (_s select 0); // survivors of the fight leave; bodies stay for looting
		} else {
			_keep set [count _keep, _s];
		};
	} forEach dzl_skirmishes;
	dzl_skirmishes = _keep;
};

// ======================= MAIN LOOP =======================
while {true} do {
	local _now = diag_tickTime;
	if (_now > dzl_nextAvoid) then {dzl_nextAvoid = _now + 60; call dzl_publishAvoid;};

	// helicopters
	{
		local _grp = _x select 0; local _heli = _x select 1;
		if (!isNull _heli) then {
			local _crewAlive = 0;
			if (!isNull _grp) then {_crewAlive = _grp call dzf_aliveCount;};
			if (!alive _heli || {_crewAlive == 0} || {!alive (driver _heli)}) then {
				if (!alive _heli || {((getPosATL _heli) select 2) > 5}) then {
					[_grp, _heli] call dzl_heliDown;
					if (alive _heli) then {_heli setDamage 1;};
				} else {
					_heli lock false; // landed with a dead crew - it's yours (saved when you get in)
				};
				if (!isNull _grp) then {{if (alive _x) then {deleteVehicle _x;};} forEach (units _grp); deleteGroup _grp;};
				_x set [0, grpNull]; _x set [1, objNull]; _x set [2, _now + dzl_heliRespawn];
			} else {
				_heli setFuel 1;
			};
		} else {
			if (_now > (_x select 2)) then {
				local _r = call dzl_spawnHeli;
				_x set [0, _r select 0]; _x set [1, _r select 1]; _x set [2, _now + 120];
			};
		};
	} forEach dzl_helis;

	// supply plane
	if (!dzl_planeBusy && {_now > dzl_nextPlane} && {count (call dzf_players) > 0}) then {
		dzl_nextPlane = _now + (dzl_planeEvery select 0) + random ((dzl_planeEvery select 1) - (dzl_planeEvery select 0));
		[] spawn dzl_supplyPlane;
	};

	// convoys
	{
		local _c = _x;
		local _grp = _c select 0;
		if (isNull _grp) then {
			if (_now > (_c select 4)) then {
				local _r = call dzl_spawnConvoy;
				if (count _r > 0) then {{_c set [_forEachIndex, _x];} forEach _r;} else {_c set [4, _now + 120];};
			};
		} else {
			local _truck = _c select 2; local _escort = _c select 1;
			if (alive _escort) then {(_c select 3) setMarkerPos (getPosATL _escort);} else {if (alive _truck) then {(_c select 3) setMarkerPos (getPosATL _truck);};};
			{if (alive _x) then {_x setFuel 1;};} forEach [_escort, _truck];
			if ((_grp call dzf_aliveCount) == 0) then {
				deleteMarker (_c select 3);
				deleteGroup _grp;
				local _p = if (alive _truck) then {getPosATL _truck} else {getPosATL _escort};
				if (alive _truck) then {_truck lock false;};
				if (alive _escort) then {_escort lock false;};
				[_p, "Convoy Cargo", "ColorOrange", 1800] call dz_eventSpot;
				[_p, 2500, "CONVOY DESTROYED", "The convoy crew is dead - the cargo truck is unlocked. Grab the loot!", "#33CC33"] call dzl_popupNear;
				// clean the wrecks/trucks up later when nobody is around
				[_escort, _truck] spawn {
					uiSleep 2400;
					waitUntil {uiSleep 30; {!isNull _x && {((getPosATL _x) call dzf_nearestPlayerDist) < 300}} count _this == 0};
					{if (!isNull _x && {count (crew _x) == 0} && {!(_x getVariable ["dzv_saved", false])}) then {deleteVehicle _x;};} forEach _this;
				};
				_c set [0, grpNull]; _c set [4, _now + dzl_convoyRespawn];
			};
		};
	} forEach dzl_convoys;

	// town takeovers
	if (count dzl_takeover == 0 && {_now > dzl_nextTakeover} && {count (call dzf_players) > 0}) then {
		call dzl_startTakeover;
		dzl_nextTakeover = _now + (dzl_takeoverEvery select 0) + random ((dzl_takeoverEvery select 1) - (dzl_takeoverEvery select 0));
	};
	call dzl_checkTakeover;

	// skirmishes near players (max 2 at a time, one every 6-10 min)
	call dzl_checkSkirmishes;
	if (count dzl_skirmishes < 3 && {_now > dzl_nextSkirmish} && {count (call dzf_players) > 0}) then {
		dzl_nextSkirmish = _now + 240 + random 180;
		call dzl_startSkirmish;
	};

	uiSleep 10;
};
