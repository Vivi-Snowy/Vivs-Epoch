/*
	DZ Populate (server side) - a lot more AI on the map, without killing server FPS.
	  - AI FREEZING: AI groups on foot more than 1.8 km from every player are frozen (no simulation, no CPU)
	    and wake up again when someone comes within 1.5 km. This is what pays for all the extra AI below.
	  - TOWN LIFE: walk into a town and there's a good chance somebody is already there - bandits looting,
	    a military sweep or stalkers passing through. They leave when you're gone.
	  - CHECKPOINTS: faction roadblocks on the roads just outside towns (triangle markers on the map).
	    Barriers, a sandbag nest, 4-5 guards, sometimes an armed vehicle. Clear one for coins and a crate,
	    and the vehicle is yours. They're manned again after 45 minutes.
	  - BANDIT CAMPS: hidden camps in the wilderness - tents, a campfire, bandits sitting around a loot crate.
	    No marker until you get within 300m. Smoke by day / firelight at night gives them away.
	Uses helpers from dz_factions.sqf / dz_activities.sqf / dz_claimveh.sqf.
*/
waitUntil {uiSleep 5; !isNil "dzf_spawnGroup" && {!isNil "dzf_towns"} && {!isNil "dza_fillCrate"} && {!isNil "dzv_addClaim"} && {!isNil "dzf_vehTypes"}};
uiSleep 40;
diag_log "DZ POPULATE: starting";
if (isNil "dzf_onIsland") then {dzf_onIsland = {false};};

// ---------------- settings ----------------
local _lingor = toLower worldName == "lingor";
dzp_aiCap          = 160;                              // no new populate AI while this many AI are alive
dzp_checkpointCount = if (_lingor) then {8} else {12};
dzp_campCount      = if (_lingor) then {6} else {9};
dzp_townMax        = 3;                                // town groups at once
dzp_townChance     = 0.6;                              // chance a town has company when you walk in
dzp_townCooldown   = 1200;                             // per town, seconds before it can roll again
dzp_checkpointReward = 800;
dzp_campReward     = 1200;
dzp_freezeAt       = 1800;
dzp_wakeAt         = 1500;

// ---------------- helpers ----------------
dzp_aiCount = {{alive _x && {!isPlayer _x}} count allUnits};
dzp_badSpot = {
	local _p = _this;
	if (surfaceIsWater _p || {_p call dzf_onIsland}) exitWith {true};
	local _b = false;
	{if ((_p distance (_x select 0)) < ((_x select 1) + 500)) exitWith {_b = true;};} forEach DZE_SafeZonePosArray;
	if (!_b) then {{if ((_p distance (_x select 1)) < ((_x select 2) + 400)) exitWith {_b = true;};} forEach dzf_zones;};
	_b
};
dzp_near = { // [pos, list (first element of each entry is a pos), dist] -> true if any is closer
	local _p = _this select 0; local _d = _this select 2; local _b = false;
	{if ((_p distance (_x select 0)) < _d) exitWith {_b = true;};} forEach (_this select 1);
	_b
};
dzp_offset = { // [pos, dir, right, forward] -> pos
	local _p = _this select 0; local _d = _this select 1;
	[(_p select 0) + (_this select 2) * cos _d + (_this select 3) * sin _d, (_p select 1) - (_this select 2) * sin _d + (_this select 3) * cos _d, 0]
};
dzp_object = { // [class, pos, dir] -> object (or objNull)
	local _o = createVehicle [_this select 0, [0, 0, 0], [], 0, "CAN_COLLIDE"];
	if (isNull _o) exitWith {objNull};
	_o setDir (_this select 2);
	_o setPosATL (_this select 1);
	_o
};
dzp_payNear = { // [pos, range, coins, reason, title, text]
	local _pos = _this select 0;
	{
		if ((_x distance _pos) < (_this select 1)) then {
			[_x, _this select 4, _this select 5, "#33CC33"] call dzf_huntPopup;
			[_x, _this select 2, _this select 3] call dza_pay;
		};
	} forEach (call dzf_players);
};
dzp_despawn = { // [groups, objects, vehicle] - delete what's left (bodies stay for sched_corpses)
	{if (!isNull _x) then {{if (alive _x) then {deleteVehicle _x;};} forEach (units _x); deleteGroup _x;};} forEach (_this select 0);
	{if (!isNull _x) then {deleteVehicle _x;};} forEach (_this select 1);
	local _v = _this select 2;
	if (!isNull _v && {!(_v getVariable ["dzv_saved", false])}) then {
		{deleteVehicle _x;} forEach (crew _v);
		deleteVehicle _v;
	};
};
dzp_cleanLater = { // [objects, pos] spawn - remove props once nobody is around
	uiSleep 600;
	waitUntil {uiSleep 30; ((_this select 1) call dzf_nearestPlayerDist) > 500};
	{if (!isNull _x) then {deleteVehicle _x;};} forEach (_this select 0);
};

// ======================= AI FREEZING =======================
dzp_freezeTick = {
	local _n = 0;
	{
		local _g = _x;
		if (!isNull _g && {count (units _g) > 0} && {!(_g getVariable ["DoNotFreeze", false])}) then {
			local _l = leader _g;
			if (alive _l && {!isPlayer _l} && {vehicle _l == _l}) then {
				local _pd = (getPosATL _l) call dzf_nearestPlayerDist;
				local _fz = _g getVariable ["dzp_frozen", false];
				if (!_fz && {_pd > dzp_freezeAt}) then {
					{if (alive _x && {vehicle _x == _x}) then {_x enableSimulation false;};} forEach (units _g);
					_g setVariable ["dzp_frozen", true];
				};
				if (_fz && {_pd < dzp_wakeAt}) then {
					{_x enableSimulation true;} forEach (units _g);
					_g setVariable ["dzp_frozen", false];
				};
				if (_g getVariable ["dzp_frozen", false]) then {_n = _n + 1;};
			};
		};
	} forEach allGroups;
	dzp_frozenGroups = _n;
};

// ======================= TOWN LIFE =======================
dzp_townNext = [];
{dzp_townNext set [count dzp_townNext, 0];} forEach dzf_towns;
dzp_townGroups = []; // [group, townPos, lastNear]
dzp_townTick = {
	local _now = diag_tickTime;
	// clean up
	local _keep = [];
	{
		local _g = _x select 0;
		if (isNull _g || {(_g call dzf_aliveCount) == 0}) then {
			if (!isNull _g) then {deleteGroup _g;};
		} else {
			if (((getPosATL (leader _g)) call dzf_nearestPlayerDist) < 900) then {_x set [2, _now];};
			if ((_now - (_x select 2)) > 120) then {[[_g], [], objNull] call dzp_despawn;} else {_keep set [count _keep, _x];};
		};
	} forEach dzp_townGroups;
	dzp_townGroups = _keep;
	// players walking into towns
	{
		local _p = _x;
		if (vehicle _p == _p || {(abs (speed (vehicle _p))) < 30}) then {
			{
				local _t = _x; local _i = _forEachIndex;
				if ((_p distance _t) < 450 && {_now > (dzp_townNext select _i)}) then {
					dzp_townNext set [_i, _now + dzp_townCooldown];
					if (random 1 < dzp_townChance && {count dzp_townGroups < dzp_townMax} && {(call dzp_aiCount) < dzp_aiCap} && {!(_t call dzf_inSafeZone)} && {!([_t, dzp_checkpoints, 300] call dzp_near)}) then {
						// come in from the far side of town
						local _pp = getPosATL _p;
						local _dir = ((_t select 0) - (_pp select 0)) atan2 ((_t select 1) - (_pp select 1));
						local _sp = [(_t select 0) + 170 * sin _dir, (_t select 1) + 170 * cos _dir, 0];
						if (surfaceIsWater _sp || {(_sp distance _pp) < 200}) then {_sp = [_t, 150, 260] call dzf_landPos;};
						if (count _sp > 0 && {(_sp distance _pp) > 150}) then {
							local _fac = ["Bandits","Bandits","Bandits","Stalkers","Stalkers","Military"] call BIS_fnc_selectRandom;
							local _g = [_fac, _sp, 3 + floor random 2] call dzf_spawnGroup;
							[_g, _t, 150] call dzf_patrolArea;
							_g setBehaviour "SAFE"; _g setSpeedMode "LIMITED";
							dzp_townGroups set [count dzp_townGroups, [_g, _t, _now]];
							diag_log format ["DZ POPULATE: %1 in %2 (%3 men)", _fac, _t call dz_nearTown, count (units _g)];
						};
					};
				};
			} forEach dzf_towns;
		};
	} forEach (call dzf_players);
};

// ======================= CHECKPOINTS =======================
dzp_checkpoints = []; // [pos, dir, faction, state 0 idle/1 manned/2 cleared, groups, objects, lastNear, respawnAt, marker, vehicle, crate]
local _tries = 0;
while {count dzp_checkpoints < dzp_checkpointCount && {_tries < 400}} do {
	_tries = _tries + 1;
	local _t = dzf_towns call BIS_fnc_selectRandom;
	local _roads = _t nearRoads 650;
	if (count _roads > 0) then {
		local _r = _roads call BIS_fnc_selectRandom;
		local _p = getPosATL _r; _p set [2, 0];
		if ((_p distance _t) > 280 && {!(_p call dzp_badSpot)} && {!([_p, dzp_checkpoints, 1200] call dzp_near)} && {count (nearestObjects [_p, ["House"], 25]) == 0}) then {
			local _dir = random 360;
			local _n = (_p nearRoads 30) - [_r];
			if (count _n > 0) then {local _q = getPosATL (_n select 0); _dir = ((_q select 0) - (_p select 0)) atan2 ((_q select 1) - (_p select 1));};
			local _fac = ["Bandits","Bandits","Military","Stalkers"] call BIS_fnc_selectRandom;
			local _m = createMarker [format ["dzp_cp_%1", count dzp_checkpoints], _p];
			_m setMarkerShape "ICON"; _m setMarkerType "mil_triangle"; _m setMarkerColor ((_fac call dzf_getFaction) select 5);
			_m setMarkerText format ["%1 checkpoint", _fac];
			dzp_checkpoints set [count dzp_checkpoints, [_p, _dir, _fac, 0, [], [], 0, 0, _m, objNull, objNull]];
		};
	};
};
diag_log format ["DZ POPULATE: %1 checkpoints placed", count dzp_checkpoints];

dzp_spawnCheckpoint = {
	local _c = _this;
	local _p = _c select 0; local _d = _c select 1; local _fac = _c select 2;
	local _objs = [];
	{
		local _o = [_x select 0, [_p, _d, _x select 1, _x select 2] call dzp_offset, _d + (_x select 3)] call dzp_object;
		if (!isNull _o) then {_objs set [count _objs, _o];};
	} forEach [
		["Land_HBarrier_large", -8, 0, 90], ["Land_HBarrier_large", 8, 0, 90],
		["Hhedgehog_concreteBig", -2.5, 9, 0], ["Hhedgehog_concreteBig", 2.5, -9, 0],
		["Land_fort_bagfence_round", -7, 7, 180], ["Land_Fire_barrel_burning", 7, -5, 0],
		["Land_CamoNetVar_EAST", 13, 2, 90]
	];
	local _crate = createVehicle [WAI_CrateSm call BIS_fnc_selectRandom, [_p, _d, 12, -3] call dzp_offset, [], 0, "CAN_COLLIDE"];
	[_crate, 1 + floor random 2, 3, [dza_medical call BIS_fnc_selectRandom, WAI_Food call BIS_fnc_selectRandom]] call dza_fillCrate;
	local _g = [_fac, [_p, _d, 6, 0] call dzp_offset, 4 + floor random 2] call dzf_spawnGroup;
	{
		_x setPosATL ([_p, _d, (random 16) - 8, (random 16) - 8] call dzp_offset);
		_x setDir (_d + (if (random 1 < 0.5) then {0} else {180}));
	} forEach (units _g);
	[_g, _p, 30] call dzf_patrolArea;
	_g setBehaviour "SAFE"; _g setSpeedMode "LIMITED";
	local _groups = [_g];
	local _veh = objNull;
	if (random 1 < 0.35) then {
		local _vt = [];
		{if ((_x select 0) == _fac) then {_vt = _x select 1;};} forEach dzf_vehTypes;
		if (count _vt == 0) then {_vt = (dzf_vehTypes select 0) select 1;};
		local _vp = [_p, _d, 12, 8] call dzp_offset;
		_veh = createVehicle [_vt call BIS_fnc_selectRandom, _vp, [], 0, "NONE"];
		_veh setDir _d;
		dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _veh];
		clearWeaponCargoGlobal _veh; clearMagazineCargoGlobal _veh;
		_veh setFuel (0.3 + random 0.4);
		_veh lock true;
		_veh call dzv_addClaim;
		local _gg = [_fac, _vp, 1] call dzf_spawnGroup;
		(leader _gg) moveInGunner _veh;
		_gg setBehaviour "AWARE"; _gg setVariable ["DoNotFreeze", true];
		_groups set [count _groups, _gg];
	};
	_c set [3, 1]; _c set [4, _groups]; _c set [5, _objs]; _c set [6, diag_tickTime]; _c set [9, _veh]; _c set [10, _crate];
	diag_log format ["DZ POPULATE: %1 checkpoint manned at %2%3", _fac, mapGridPosition _p, if (isNull _veh) then {""} else {format [" with a %1", typeOf _veh]}];
};
dzp_checkpointTick = {
	local _now = diag_tickTime;
	{
		local _c = _x; local _p = _c select 0; local _st = _c select 3;
		local _pd = _p call dzf_nearestPlayerDist;
		if (_st == 0 && {_pd < 900} && {_pd > 150} && {_now > (_c select 7)} && {(call dzp_aiCount) < dzp_aiCap}) then {_c call dzp_spawnCheckpoint;};
		if (_st == 1) then {
			if (_pd < 1400) then {_c set [6, _now];};
			local _alive = 0;
			{_alive = _alive + (_x call dzf_aliveCount);} forEach (_c select 4);
			if (_alive == 0) then {
				{deleteGroup _x;} forEach (_c select 4);
				local _v = _c select 9;
				if (!isNull _v && {alive _v}) then {_v lock false;};
				[_p, 600, dzp_checkpointReward, "checkpoint cleared", "CHECKPOINT CLEARED", format ["You took the %1 checkpoint. Their supplies are in the crate%2.", _c select 2, if (!isNull _v && {alive _v}) then {" - and the vehicle is yours"} else {""}]] call dzp_payNear;
				(_c select 8) setMarkerColor "ColorBlack"; (_c select 8) setMarkerText format ["%1 checkpoint (cleared)", _c select 2];
				[(_c select 5) + [_c select 10], _p] spawn dzp_cleanLater;
				_c set [3, 2]; _c set [4, []]; _c set [5, []]; _c set [9, objNull]; _c set [10, objNull]; _c set [7, _now + 2700];
				diag_log format ["DZ POPULATE: checkpoint at %1 cleared", mapGridPosition _p];
			} else {
				if ((_now - (_c select 6)) > 180) then {
					[_c select 4, (_c select 5) + [_c select 10], _c select 9] call dzp_despawn;
					_c set [3, 0]; _c set [4, []]; _c set [5, []]; _c set [9, objNull]; _c set [10, objNull];
				};
			};
		};
		if (_st == 2 && {_now > (_c select 7)} && {_pd > 1200}) then {
			_c set [3, 0];
			(_c select 8) setMarkerColor (((_c select 2) call dzf_getFaction) select 5); (_c select 8) setMarkerText format ["%1 checkpoint", _c select 2];
		};
	} forEach dzp_checkpoints;
};

// ======================= BANDIT CAMPS =======================
dzp_camps = []; // [pos, state 0 idle/1 manned/2 cleared, groups, objects, lastNear, respawnAt, marker, crate, found]
local _centre = getMarkerPos "center";
local _radius = if (_lingor) then {4600} else {7000};
_tries = 0;
while {count dzp_camps < dzp_campCount && {_tries < 600}} do {
	_tries = _tries + 1;
	local _p = [_centre, 300, _radius] call dzf_landPos;
	if (count _p > 0) then {
		local _ok = !(_p call dzp_badSpot) && {!([_p, dzp_camps, 1500] call dzp_near)} && {!([_p, dzp_checkpoints, 800] call dzp_near)};
		if (_ok) then {{if ((_p distance _x) < 500) exitWith {_ok = false;};} forEach dzf_towns;};
		if (_ok && {count (_p isFlatEmpty [10, 0, 0.4, 12, 0, false, objNull]) > 0} && {count (nearestObjects [_p, ["House"], 80]) == 0} && {count (_p nearRoads 80) == 0}) then {
			dzp_camps set [count dzp_camps, [_p, 0, [], [], 0, 0, "", objNull, false]];
		};
	};
};
diag_log format ["DZ POPULATE: %1 bandit camps hidden", count dzp_camps];

dzp_spawnCamp = {
	local _c = _this; local _p = _c select 0;
	local _d = random 360;
	local _objs = [];
	{
		local _o = [_x select 0, [_p, _d, _x select 1, _x select 2] call dzp_offset, _d + (_x select 3)] call dzp_object;
		if (!isNull _o) then {_objs set [count _objs, _o];};
	} forEach [
		["Land_Fire_burning", 0, 0, 0], ["Land_tent_east", -9, 3, 90], ["ACamp", 7, 5, 200], ["ACamp", 6, -6, 300],
		["Land_CamoNetVar_EAST", -2, -10, 0], ["Barrel5", -6, -6, 0]
	];
	local _crate = createVehicle [WAI_CrateMd call BIS_fnc_selectRandom, [_p, _d, -3, -9] call dzp_offset, [], 0, "CAN_COLLIDE"];
	local _extra = [dza_medical call BIS_fnc_selectRandom, WAI_Food call BIS_fnc_selectRandom];
	if (random 1 < 0.35) then {_extra set [count _extra, dza_gems call BIS_fnc_selectRandom];};
	[_crate, 2 + floor random 2, 4, _extra] call dza_fillCrate;
	local _fac = if (random 1 < 0.25) then {"Hunters"} else {"Bandits"};
	local _g = [_fac, _p, 3 + floor random 3] call dzf_spawnGroup;
	{
		local _a = _forEachIndex * (360 / (count (units _g)));
		_x setPosATL ([_p, _a, 3.5, 0] call dzp_offset);
		_x setDir (_a + 270);
		doStop _x;
		_x action ["SitDown", _x];
	} forEach (units _g);
	_g setBehaviour "SAFE";
	local _s = [_fac, [_p, _d, 0, 40] call dzp_offset, 1 + floor random 2] call dzf_spawnGroup; // sentries walking the perimeter
	[_s, _p, 70] call dzf_patrolArea;
	_s setBehaviour "SAFE"; _s setSpeedMode "LIMITED";
	_c set [1, 1]; _c set [2, [_g, _s]]; _c set [3, _objs]; _c set [4, diag_tickTime]; _c set [7, _crate];
	diag_log format ["DZ POPULATE: %1 camp manned at %2", _fac, mapGridPosition _p];
};
dzp_campTick = {
	local _now = diag_tickTime;
	{
		local _c = _x; local _p = _c select 0; local _st = _c select 1;
		local _pd = _p call dzf_nearestPlayerDist;
		if (_st == 0 && {_pd < 800} && {_now > (_c select 5)} && {(call dzp_aiCount) < dzp_aiCap}) then {_c call dzp_spawnCamp;};
		if (_st == 1) then {
			if (_pd < 1200) then {_c set [4, _now];};
			if (_pd < 300 && {!(_c select 8)}) then {
				_c set [8, true];
				local _m = createMarker [format ["dzp_camp_%1", _forEachIndex], _p];
				_m setMarkerShape "ICON"; _m setMarkerType "mil_dot"; _m setMarkerColor "ColorRed"; _m setMarkerText "Bandit camp";
				_c set [6, _m];
				{if ((_x distance _p) < 400) then {[_x, "BANDIT CAMP", "You spotted a bandit camp. They have a loot crate by the fire.", "#FF4444"] call dzf_huntPopup;};} forEach (call dzf_players);
			};
			local _alive = 0;
			{_alive = _alive + (_x call dzf_aliveCount);} forEach (_c select 2);
			if (_alive == 0) then {
				{deleteGroup _x;} forEach (_c select 2);
				[_p, 600, dzp_campReward, "bandit camp cleared", "CAMP CLEARED", "The bandit camp is wiped out - help yourself to their crate."] call dzp_payNear;
				if ((_c select 6) != "") then {deleteMarker (_c select 6); _c set [6, ""];};
				[(_c select 3) + [_c select 7], _p] spawn dzp_cleanLater;
				_c set [1, 2]; _c set [2, []]; _c set [3, []]; _c set [7, objNull]; _c set [5, _now + 3600]; _c set [8, false];
				diag_log format ["DZ POPULATE: camp at %1 cleared", mapGridPosition _p];
			} else {
				if ((_now - (_c select 4)) > 180) then {
					[_c select 2, (_c select 3) + [_c select 7], objNull] call dzp_despawn;
					if ((_c select 6) != "") then {deleteMarker (_c select 6); _c set [6, ""];};
					_c set [1, 0]; _c set [2, []]; _c set [3, []]; _c set [7, objNull]; _c set [8, false];
				};
			};
		};
		if (_st == 2 && {_now > (_c select 5)} && {_pd > 1200}) then {_c set [1, 0];};
	} forEach dzp_camps;
};

// spawn picker: don't drop players right next to a checkpoint or camp (read by dzl_publishAvoid)
dzp_avoid = {
	local _a = [];
	{_a set [count _a, [_x select 0, 450]];} forEach dzp_checkpoints;
	{_a set [count _a, [_x select 0, 450]];} forEach dzp_camps;
	_a
};

// ---------------- main loop ----------------
local _nextLog = diag_tickTime + 300;
while {true} do {
	call dzp_freezeTick;
	if (count (call dzf_players) > 0) then {
		call dzp_townTick;
		call dzp_checkpointTick;
		call dzp_campTick;
	};
	if (diag_tickTime > _nextLog) then {
		_nextLog = diag_tickTime + 600;
		diag_log format ["DZ POPULATE: %1 AI alive, %2 groups frozen, %3 town groups", call dzp_aiCount, dzp_frozenGroups, count dzp_townGroups];
	};
	uiSleep 10;
};
