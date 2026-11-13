/*
	DZ Factions - territory AI, roaming patrols and hunter squads.
	Server-side. Uses WICKED AI's weapon/skin/skill lists.

	Sides: EAST and RESISTANCE are hostile to players (WEST) AND to each other,
	so Bandits/Hunters (EAST) and Military/Stalkers (RESISTANCE) fight when they meet.
*/
#define DZF_ZONE_ACTIVATE 1200      // spawn a territory group when a player is this close
#define DZF_ZONE_DEACTIVATE 1800    // despawn it when no player is this close (after grace period)
#define DZF_ZONE_RESPAWN 1200       // seconds before a wiped-out territory is re-garrisoned
#define DZF_ROAMERS 14              // number of roaming patrol groups on the map (was 10; far-away ones are frozen by dz_populate)
#define DZF_VEHPATROLS 6            // armed vehicle patrols driving between towns (was 4)
#define DZF_SURVIVORS 6             // friendly survivor groups wandering the map
#define DZF_ROAM_RESPAWN 600        // seconds before a killed roaming group is replaced
#define DZF_HUNT_FIRST 600          // seconds after (re)spawning before the first hunters come
#define DZF_HUNT_COOLDOWN [900,1500] // seconds between hunter squads [min,max] (was 4-8 min)
#define DZF_HUNT_DIST [450,700]     // hunters spawn this far from you [min,max]
#define DZF_HUNT_GIVEUP 1600        // hunters give up if you get this far away
#define DZF_HUNT_MAXTIME 1200       // hunters give up after this many seconds

waitUntil {uiSleep 5; !isNil "WAIconfigloaded" && {WAIconfigloaded}};
uiSleep 60;
diag_log "DZ FACTIONS: starting";

// ---------- factions ----------
// [name, side, skins, weapons, skill, markerColour, humanityChange, chatColour]
dzf_factions = [
	["Bandits",  EAST,       WAI_BanditSkin,                 WAI_AK + WAI_RK95 + WAI_SMG,                    "medium", "ColorRed",    50,  "#FF4444"],
	["Military", RESISTANCE, WAI_HeroSkin + WAI_AcrSkin,     WAI_M4 + WAI_HK416 + WAI_Scar + WAI_G36,        "hard",   "ColorGreen",  0,   "#44CC44"],
	["Stalkers", RESISTANCE, WAI_StalkerSkin + WAI_ApocalypticSkin, WAI_AK + WAI_SteyrAug + WAI_HK53,       "medium", "ColorYellow", 0,   "#DDDD33"],
	["Hunters",  EAST,       WAI_GhillieSkin + WAI_GruSkin,  WAI_Sniper + WAI_M4 + WAI_HK416,               "hard",   "ColorBlack",  50,  "#AA66FF"],
	["Survivors", WEST, ["Survivor2_DZ","Rocker1_DZ","Rocker3_DZ","Priest_DZ","Doctor_DZ","Worker1_DZ","Hunter_DZ","Civilian1_DZ","Civilian3_DZ","Prisoner1_DZ","SurvivorW2_DZ","SurvivorWcombat_DZ","SurvivorWurban_DZ"],
		["Winchester1866_DZ","LeeEnfield_DZ","Remington870_DZ","MR43_DZ","CZ550_DZ","Mosin_DZ","AK74_DZ","M16A2_DZ","M1911_DZ"], "easy", "ColorBlue", -100, "#4499FF"]
];
dzf_getFaction = {
	local _f = [];
	{if ((_x select 0) == _this) exitWith {_f = _x;};} forEach dzf_factions;
	_f
};

// ---------- territories (faction, centre, radius, group size, label) ----------
dzf_zones = [ // Lingor
	["Military", [4460,1720,0], 250, 8, "Sargento Airfield Garrison"],
	["Military", [1190,5810,0], 220, 6, "Pista Airstrip Guard"],
	["Military", [3060,8060,0], 200, 5, "Prison Guard Post"],
	["Bandits",  [3570,2740,0], 250, 6, "Montehofo ARL Rebels"],
	["Bandits",  [5620,3190,0], 250, 6, "Prospero Raiders"],
	["Bandits",  [5890,4740,0], 300, 6, "Corazon Cartel"],
	["Stalkers", [4418,6732,0], 220, 5, "Research Lab 101 Stalkers"],
	["Stalkers", [3518,3746,0], 220, 5, "Research Lab 102 Stalkers"]
];
dzf_zoneState = []; // per zone: [group or grpNull, lastSeenPlayerTime, respawnAt]
{dzf_zoneState set [_forEachIndex, [grpNull, 0, 0]];} forEach dzf_zones;

// ---------- helpers ----------
dzf_players = {
	local _p = [];
	{if (isPlayer _x && {alive _x}) then {_p set [count _p, _x];};} forEach playableUnits;
	_p
};
dzf_nearestPlayerDist = {
	local _d = 999999;
	{_d = _d min (_x distance _this);} forEach (call dzf_players);
	_d
};
dzf_inSafeZone = {
	local _in = false;
	{if ((_this distance (_x select 0)) < ((_x select 1) + 150)) exitWith {_in = true;};} forEach DZE_SafeZonePosArray;
	_in
};
dzf_onIsland = { // Lingor: Mariana (NE) and Bantanam (E) islands - foot/vehicle patrols can't walk there
	local _px = _this select 0; local _py = _this select 1;
	(_px > 7800 && {_py > 6400}) || {_px > 8750 && {_py > 3300} && {_py < 5800}}
};
dzf_landPos = { // [centre, minDist, maxDist] -> position on land or []
	local _c = _this select 0;
	local _res = [];
	for "_i" from 1 to 25 do {
		local _d = (_this select 1) + random ((_this select 2) - (_this select 1));
		local _a = random 360;
		local _p = [(_c select 0) + _d * sin _a, (_c select 1) + _d * cos _a, 0];
		if (!surfaceIsWater _p && {!(_p call dzf_inSafeZone)} && {(_p select 0) > 200} && {(_p select 1) > 200} && {(_p select 0) < 10000} && {(_p select 1) < 10000} && {!(_p call dzf_onIsland)}) exitWith {_res = _p;};
	};
	_res
};
dzf_onKill = {
	local _unit = _this select 0;
	local _killer = _this select 1;
	_unit setVariable ["bodyName","NPC",false]; // cleaned up by sched_corpses
	if (WAI_HasMoney && Z_singleCurrency) then {_unit setVariable ["cashMoney", (round (random WAI_MoneyMultiplier) * 50), true];};
	if (isPlayer _killer) then {
		local _hum = _unit getVariable ["dzf_humanity", 0];
		if (_hum != 0) then {_killer setVariable ["humanity", (_killer getVariable ["humanity",0]) + _hum, true];};
		if ((_unit getVariable ["dzf_faction",""]) == "Survivors") then {
			_killer setVariable ["humanKills", (_killer getVariable ["humanKills",0]) + 1, true];
		} else {
			_killer setVariable ["banditKills", (_killer getVariable ["banditKills",0]) + 1, true];
		};
		local _f = (_unit getVariable ["dzf_faction","Bandits"]) call dzf_getFaction;
		{if ((_x distance _unit) < 300) then {_x reveal [_killer, 4];};} forEach allUnits;
	};
};
dzf_spawnGroup = { // [factionName, position, count] -> group
	local _f = (_this select 0) call dzf_getFaction;
	local _pos = _this select 1;
	local _grp = createGroup (_f select 1);
	for "_i" from 1 to (_this select 2) do {
		local _skin = (_f select 2) call BIS_fnc_selectRandom;
		if (typeName _skin == "ARRAY") then {_skin = _skin call BIS_fnc_selectRandom;};
		local _u = _grp createUnit [_skin, [(_pos select 0) + random 10 - 5, (_pos select 1) + random 10 - 5, 0], [], 0, "FORM"];
		[_u] joinSilent _grp;
		removeAllWeapons _u;
		removeAllItems _u;
		local _w = (_f select 3) call BIS_fnc_selectRandom;
		if (typeName _w == "ARRAY") then {_w = _w call BIS_fnc_selectRandom;};
		if !(isClass (configFile >> "CfgWeapons" >> _w)) then {_w = "M16A2_DZ";};
		local _mag = _w call WAI_FindAmmo;
		for "_m" from 1 to (3 + floor random 3) do {_u addMagazine _mag;};
		_u addWeapon _w;
		_u selectWeapon _w;
		_u addMagazine (WAI_Food call BIS_fnc_selectRandom);
		_u addMagazine (WAI_Medical call BIS_fnc_selectRandom);
		if (sunOrMoon != 1) then {_u addWeapon "NVGoggles";};
		local _sk = call {
			if ((_f select 4) == "medium") exitWith {WAI_SkillMedium};
			if ((_f select 4) == "hard") exitWith {WAI_SkillHard};
			WAI_SkillEasy
		};
		{_u setSkill [_x select 0, _x select 1];} forEach _sk;
		_u setVariable ["dzf_faction", _f select 0];
		_u setVariable ["dzf_humanity", _f select 6];
		if ((_f select 1) == EAST) then {_u setVariable ["Bandit",true,false];};
		_u addEventHandler ["Killed", {_this call dzf_onKill;}];
	};
	_grp setCombatMode "RED";
	_grp setBehaviour "AWARE";
	_grp setSpeedMode "LIMITED";
	_grp
};
dzf_patrolArea = { // [group, centre, radius]
	local _grp = _this select 0;
	local _c = _this select 1;
	local _r = _this select 2;
	while {count (waypoints _grp) > 0} do {deleteWaypoint ((waypoints _grp) select 0);};
	for "_i" from 1 to 5 do {
		local _a = random 360; local _d = random _r;
		local _wp = _grp addWaypoint [[(_c select 0) + _d * sin _a, (_c select 1) + _d * cos _a, 0], 0];
		_wp setWaypointType "MOVE";
		_wp setWaypointCompletionRadius 20;
	};
	(_grp addWaypoint [_c, 0]) setWaypointType "CYCLE";
};
dzf_deleteGroup = {
	{deleteVehicle _x;} forEach (units _this);
	deleteGroup _this;
};
dzf_aliveCount = {
	local _n = 0;
	{if (alive _x) then {_n = _n + 1;};} forEach (units _this);
	_n
};

// ---------- territory markers ----------
{
	local _f = (_x select 0) call dzf_getFaction;
	local _m = createMarker [format ["dzf_zone_%1", _forEachIndex], _x select 1];
	_m setMarkerShape "ELLIPSE";
	_m setMarkerSize [_x select 2, _x select 2];
	_m setMarkerColor (_f select 5);
	_m setMarkerBrush "Border";
	local _t = createMarker [format ["dzf_zonet_%1", _forEachIndex], _x select 1];
	_t setMarkerShape "ICON";
	_t setMarkerType "mil_dot";
	_t setMarkerColor (_f select 5);
	_t setMarkerText format ["%1 (%2)", _x select 4, _x select 0];
} forEach dzf_zones;

// ---------- roaming patrols ----------
dzf_towns = [];
{
	local _p = locationPosition _x;
	if !(_p call dzf_onIsland) then {dzf_towns set [count dzf_towns, _p];}; // mainland towns only
} forEach (nearestLocations [getMarkerPos "center", ["NameCityCapital","NameCity","NameVillage"], 7500]);
dzf_roamers = [];
for "_i" from 1 to DZF_ROAMERS do {dzf_roamers set [count dzf_roamers, [grpNull, 0]];};

dzf_spawnRoamer = {
	local _fac = ["Bandits","Military","Stalkers","Bandits"] call BIS_fnc_selectRandom;
	local _start = [];
	for "_t" from 1 to 20 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzf_inSafeZone) && {(_p call dzf_nearestPlayerDist) > 800}) exitWith {_start = _p;};
	};
	if (count _start == 0) exitWith {grpNull};
	local _grp = [_fac, _start, 4 + floor random 3] call dzf_spawnGroup;
	_grp setBehaviour "SAFE";
	for "_w" from 1 to 6 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if !(_p call dzf_inSafeZone) then {
			local _wp = _grp addWaypoint [_p, 50];
			_wp setWaypointType "MOVE";
			_wp setWaypointCompletionRadius 40;
		};
	};
	(_grp addWaypoint [_start, 0]) setWaypointType "CYCLE";
	diag_log format ["DZ FACTIONS: roaming %1 patrol spawned near %2", _fac, mapGridPosition _start];
	_grp
};

// ---------- armed vehicle patrols ----------
dzf_vehTypes = [
	["Bandits",  ["Offroad_DSHKM_Gue_DZE","UAZ_MG_TK_EP1_DZE"]],
	["Military", ["BAF_Jackal2_L2A1_W_DZE","HMMWV_M2_DZE"]],
	["Stalkers", ["UAZ_MG_TK_EP1_DZE","Offroad_DSHKM_Gue_DZE"]]
];
dzf_vehPatrols = [];
for "_i" from 1 to DZF_VEHPATROLS do {dzf_vehPatrols set [count dzf_vehPatrols, [grpNull, objNull, 0]];};
dzf_spawnVehPatrol = { // returns [group, vehicle]
	local _pick = dzf_vehTypes call BIS_fnc_selectRandom;
	local _fac = _pick select 0;
	local _cls = (_pick select 1) call BIS_fnc_selectRandom;
	local _start = [];
	for "_t" from 1 to 20 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzf_inSafeZone) && {(_p call dzf_nearestPlayerDist) > 1000}) exitWith {_start = _p;};
	};
	if (count _start == 0) exitWith {[grpNull, objNull]};
	local _road = (_start nearRoads 300);
	if (count _road > 0) then {_start = getPosATL (_road select 0);};
	local _veh = createVehicle [_cls, _start, [], 0, "NONE"];
	dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _veh];
	_veh setFuel 1;
	_veh lock true;
	_veh call dzv_addClaim; // saved to the database when a player first gets in
	_veh setVariable ["dzf_patrolVeh", true, true];
	_veh addEventHandler ["Killed", {(_this select 0) setVariable ["dzf_dead", true];}];
	local _grp = [_fac, _start, 3] call dzf_spawnGroup;
	local _u = units _grp;
	(_u select 0) moveInDriver _veh;
	if (count _u > 1) then {(_u select 1) moveInGunner _veh;};
	if (count _u > 2) then {(_u select 2) moveInCargo _veh;};
	_grp setBehaviour "SAFE";
	_grp setSpeedMode "NORMAL";
	for "_w" from 1 to 8 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if !(_p call dzf_inSafeZone) then {
			local _wp = _grp addWaypoint [_p, 30];
			_wp setWaypointType "MOVE";
			_wp setWaypointCompletionRadius 60;
		};
	};
	(_grp addWaypoint [_start, 0]) setWaypointType "CYCLE";
	diag_log format ["DZ FACTIONS: %1 vehicle patrol (%2) spawned near %3", _fac, _cls, mapGridPosition _start];
	[_grp, _veh]
};

// ---------- friendly survivors ----------
dzf_survivors = [];
for "_i" from 1 to DZF_SURVIVORS do {dzf_survivors set [count dzf_survivors, [grpNull, 0]];};
dzf_spawnSurvivors = {
	local _start = [];
	for "_t" from 1 to 20 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzf_inSafeZone) && {(_p call dzf_nearestPlayerDist) > 600}) exitWith {_start = _p;};
	};
	if (count _start == 0) exitWith {grpNull};
	local _grp = ["Survivors", _start, 2 + floor random 3] call dzf_spawnGroup;
	_grp setBehaviour "AWARE";
	_grp setCombatMode "YELLOW";
	_grp setSpeedMode "LIMITED";
	{_x addMagazine "ItemBandage"; _x addMagazine "ItemWaterbottle";} forEach (units _grp);
	for "_w" from 1 to 5 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if ((_p distance _start) < 3000 && {!(_p call dzf_inSafeZone)}) then {
			local _wp = _grp addWaypoint [_p, 80];
			_wp setWaypointType "MOVE";
			_wp setWaypointCompletionRadius 50;
			_wp setWaypointTimeout [60, 120, 240]; // stop and "scavenge" for a while
		};
	};
	(_grp addWaypoint [_start, 0]) setWaypointType "CYCLE";
	diag_log format ["DZ FACTIONS: survivor group spawned near %1", mapGridPosition _start];
	_grp
};

// ---------- hunters ----------
dzf_hunters = []; // [player, group, startTime]
dzf_nextHunt = []; // [player, time]
dzf_huntPopup = {
	dz_eventPopup = [_this select 1, _this select 2, _this select 3];
	(owner (_this select 0)) publicVariableClient "dz_eventPopup";
};

// ---------- main loop ----------
while {true} do {
	local _now = diag_tickTime;
	local _players = call dzf_players;

	// territories
	{
		local _zone = _x;
		local _st = dzf_zoneState select _forEachIndex;
		local _grp = _st select 0;
		local _d = (_zone select 1) call dzf_nearestPlayerDist;
		if (isNull _grp) then {
			if (_d < DZF_ZONE_ACTIVATE && {_now > (_st select 2)}) then {
				_grp = [_zone select 0, _zone select 1, _zone select 3] call dzf_spawnGroup;
				[_grp, _zone select 1, _zone select 2] call dzf_patrolArea;
				_st set [0, _grp]; _st set [1, _now];
				diag_log format ["DZ FACTIONS: %1 garrisoned", _zone select 4];
			};
		} else {
			if (_d < DZF_ZONE_DEACTIVATE) then {_st set [1, _now];};
			if ((_grp call dzf_aliveCount) == 0) then {
				deleteGroup _grp; _st set [0, grpNull]; _st set [2, _now + DZF_ZONE_RESPAWN];
				{if ((_x distance (_zone select 1)) < 1500) then {[_x, "TERRITORY CLEARED", format ["You wiped out the %1. They will be back in %2 minutes.", _zone select 4, round (DZF_ZONE_RESPAWN / 60)], "#33CC33"] call dzf_huntPopup;};} forEach _players;
			} else {
				if ((_now - (_st select 1)) > 180) then {_grp call dzf_deleteGroup; _st set [0, grpNull];};
			};
		};
	} forEach dzf_zones;

	// roaming patrols
	{
		local _grp = _x select 0;
		if (isNull _grp || {(_grp call dzf_aliveCount) == 0}) then {
			if (!isNull _grp) then {deleteGroup _grp; _x set [0, grpNull]; _x set [1, _now + DZF_ROAM_RESPAWN];};
			if (_now > (_x select 1)) then {_x set [0, call dzf_spawnRoamer]; _x set [1, _now + 60];};
		};
	} forEach dzf_roamers;

	// vehicle patrols
	{
		local _grp = _x select 0; local _veh = _x select 1;
		local _gone = isNull _grp || {(_grp call dzf_aliveCount) == 0} || {isNull _veh} || {!alive _veh};
		if (_gone) then {
			if (!isNull _grp) then {
				{if (alive _x) then {deleteVehicle _x;};} forEach (units _grp);
				deleteGroup _grp;
				if (!isNull _veh && {alive _veh}) then {_veh lock false;}; // crew dead: the vehicle is yours (saved when you get in)
				_x set [0, grpNull]; _x set [2, _now + DZF_ROAM_RESPAWN];
			};
			if (_now > (_x select 2)) then {
				local _r = call dzf_spawnVehPatrol;
				_x set [0, _r select 0]; _x set [1, _r select 1]; _x set [2, _now + 60];
			};
		};
	} forEach dzf_vehPatrols;

	// friendly survivors
	{
		local _grp = _x select 0;
		if (isNull _grp || {(_grp call dzf_aliveCount) == 0}) then {
			if (!isNull _grp) then {deleteGroup _grp; _x set [0, grpNull]; _x set [1, _now + DZF_ROAM_RESPAWN];};
			if (_now > (_x select 1)) then {_x set [0, call dzf_spawnSurvivors]; _x set [1, _now + 60];};
		};
	} forEach dzf_survivors;

	// hunters: one squad per player, always coming back
	{
		local _plr = _x;
		local _uid = getPlayerUID _plr;
		local _entry = []; local _ei = -1;
		{if ((_x select 0) == _uid) exitWith {_entry = _x; _ei = _forEachIndex;};} forEach dzf_hunters;
		if (_ei == -1) then {
			local _next = -1;
			{
				if ((_x select 0) == _uid) exitWith {
					// a new character (after a death) gets a fresh grace period
					if ((count _x < 3) || {(_x select 2) != _plr}) then {_x set [1, _now + DZF_HUNT_FIRST]; _x set [2, _plr];};
					_next = _x select 1;
				};
			} forEach dzf_nextHunt;
			if (_next == -1) then {dzf_nextHunt set [count dzf_nextHunt, [_uid, _now + DZF_HUNT_FIRST, _plr]];};
			if (_next != -1 && {_now > _next} && {!((getPosATL _plr) call dzf_inSafeZone)} && {!((vehicle _plr) isKindOf "Air")}) then {
				local _sp = [getPosATL _plr, DZF_HUNT_DIST select 0, DZF_HUNT_DIST select 1] call dzf_landPos;
				if (count _sp > 0) then {
					local _fac = ["Hunters","Hunters","Bandits","Military"] call BIS_fnc_selectRandom;
					local _grp = [_fac, _sp, 2 + floor random 2] call dzf_spawnGroup;
					_grp setSpeedMode "FULL";
					_grp setBehaviour "AWARE";
					{_x reveal [_plr, 1.5];} forEach (units _grp);
					dzf_hunters set [count dzf_hunters, [_uid, _grp, _now, _plr]];
					[_plr, "YOU ARE BEING HUNTED", format ["A %1 squad has picked up your trail near %2. Watch your back!", _fac, mapGridPosition _sp], "#AA66FF"] call dzf_huntPopup;
					diag_log format ["DZ FACTIONS: %1 hunters sent after %2", _fac, name _plr];
				};
			};
		};
	} forEach _players;

	// update / end hunts
	local _keep = [];
	{
		local _uid = _x select 0; local _grp = _x select 1; local _start = _x select 2; local _plr = _x select 3;
		local _alive = _grp call dzf_aliveCount;
		local _end = "";
		if (_alive == 0) then {_end = "killed";};
		if (_end == "" && {isNull _plr || {!alive _plr} || {!isPlayer _plr}}) then {_end = "lost";};
		if (_end == "" && {(_now - _start) > DZF_HUNT_MAXTIME}) then {_end = "timeout";};
		if (_end == "" && {((getPosATL _plr) call dzf_inSafeZone)}) then {_end = "safe";};
		if (_end == "" && {(leader _grp) distance _plr > DZF_HUNT_GIVEUP}) then {_end = "escaped";};
		if (_end == "") then {
			_grp move (getPosATL _plr);
			if (random 1 < 0.3) then {{_x reveal [_plr, 1.5];} forEach (units _grp);};
			_keep set [count _keep, _x];
		} else {
			local _cool = (DZF_HUNT_COOLDOWN select 0) + random ((DZF_HUNT_COOLDOWN select 1) - (DZF_HUNT_COOLDOWN select 0));
			{if ((_x select 0) == _uid) then {_x set [1, _now + _cool];};} forEach dzf_nextHunt;
			if (!isNull _plr && {alive _plr}) then {
				call {
					if (_end == "killed") exitWith {[_plr, "HUNTERS ELIMINATED", "You took out the squad tracking you. More will come...", "#33CC33"] call dzf_huntPopup;};
					if (_end in ["escaped","safe","timeout"]) exitWith {[_plr, "TRAIL LOST", "The hunters lost your trail - for now.", "#FFCC33"] call dzf_huntPopup;};
				};
			};
			if (_end != "killed") then {_grp call dzf_deleteGroup;} else {deleteGroup _grp;};
		};
	} forEach dzf_hunters;
	dzf_hunters = _keep;

	uiSleep 20;
};
