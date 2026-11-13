/*
	DZ AI Brain (server side) - smarter tactics for every hostile AI group (factions, hunters, WAI, DZMS,
	convoys, helicopter crews, town takeovers...). Runs on top of the Arma AI, only for groups near players.

	What they do now:
	  - Share what they see: a group that spots you tells every friendly group within 400m.
	  - Split up: part of the group pins you down from cover, the rest flank you from the side and assault.
	  - Use cover: shooters move to the nearest wall/building/tree on the far side from you and crouch.
	  - Grenades when you're 15-40m away (and into buildings), smoke to cover wounded or a retreat.
	  - Wounded fall back behind smoke and a buddy patches them up.
	  - Morale: a group that loses two thirds of its men pulls back and calls the nearest friendly group in.
	  - Hunt you: when they lose sight of you they search your last known position instead of giving up.
	  - Clear buildings: if you hide inside, assaulters push into the building positions next to you.
	  - Vehicles: passengers bail out to fight when you're close; a badly damaged vehicle is abandoned.
	  - Helicopters drop paratroopers on you (once per helicopter).
	  - Snipers keep their distance and go prone.
	  - Skills retuned: better spotting, nerve and teamwork, a bit less laser-accurate (set dzb_retune below).
	  - React when hit: the hit man dives for cover, his group learns where the shot came from, and they
	    pop smoke when a mate goes down.
	  - Mission and fortress AI (WICKED AI) stay on a 250m leash around their post so missions don't fall apart.
	  - Works for AI-vs-AI fights too (factions, hunters, survivor NPCs), not just against you.
*/
waitUntil {uiSleep 5; !isNil "dzf_players" && {!isNil "dzf_spawnGroup"}};
uiSleep 30;
diag_log "DZ AI BRAIN: starting";

dzb_retune = true;      // retune AI skills (smarter, slightly less pin-point accurate). false = leave skills alone.
dzb_range = 900;        // only groups this close to a player get the tactical logic
dzb_leashDist = 250;    // WICKED AI mission/fortress groups never move further than this from their post
dzb_snipers = if (isNil "WAI_Sniper") then {[]} else {WAI_Sniper};

// find the throw muzzles for grenades and smoke
dzb_muzzleFor = {
	local _res = "";
	{
		if (_this in getArray (configFile >> "CfgWeapons" >> "Throw" >> _x >> "magazines")) exitWith {_res = _x;};
	} forEach getArray (configFile >> "CfgWeapons" >> "Throw" >> "muzzles");
	_res
};
dzb_nade = "HandGrenade_West"; dzb_nadeMuzzle = dzb_nade call dzb_muzzleFor;
dzb_smoke = "SmokeShell";      dzb_smokeMuzzle = dzb_smoke call dzb_muzzleFor;
diag_log format ["DZ AI BRAIN: grenade muzzle '%1', smoke muzzle '%2'", dzb_nadeMuzzle, dzb_smokeMuzzle];

// ---------------- helpers ----------------
dzb_dirTo = {((((_this select 1) select 0) - ((_this select 0) select 0)) atan2 (((_this select 1) select 1) - ((_this select 0) select 1)))};
dzb_offset = {[((_this select 0) select 0) + (_this select 2) * sin (_this select 1), ((_this select 0) select 1) + (_this select 2) * cos (_this select 1), 0]};
dzb_onFoot = {local _r = []; {if (alive _x && {vehicle _x == _x}) then {_r set [count _r, _x];};} forEach (units _this); _r};
dzb_knows = { // [group, target] -> best knowsAbout of the first units
	local _k = 0;
	{if (_forEachIndex < 4 && {alive _x}) then {_k = _k max (_x knowsAbout (_this select 1));};} forEach (units (_this select 0));
	_k
};
dzb_inBuilding = {
	local _e = eyePos _this;
	lineIntersects [_e, [_e select 0, _e select 1, (_e select 2) + 12], _this]
};
dzb_leash = { // [group, pos] -> pos pulled back inside the leash if the group has a post
	local _home = (_this select 0) getVariable ["dzb_home", []];
	local _p = _this select 1;
	if (count _home == 0 || {(_p distance _home) <= dzb_leashDist}) exitWith {_p};
	[_home, [_home, _p] call dzb_dirTo, dzb_leashDist] call dzb_offset
};
dzb_popSmoke = { // [group, threat pos] - smoke screen between the group and the threat (max once per 90s)
	local _g = _this select 0;
	if ((diag_tickTime - (_g getVariable ["dzb_smokeT", -999])) < 90) exitWith {};
	_g setVariable ["dzb_smokeT", diag_tickTime];
	local _lp = getPosATL (leader _g);
	local _sp = [_lp, [_lp, _this select 1] call dzb_dirTo, 12 + random 8] call dzb_offset;
	"SmokeShell" createVehicle _sp;
};
dzb_onHit = {
	local _u = _this select 0; local _src = _this select 1;
	if (!alive _u || {isNull _src} || {_src == _u}) exitWith {};
	{_x reveal [_src, 2.5];} forEach (units (group _u));
	if (vehicle _u == _u && {damage _u > 0.25} && {(diag_tickTime - (_u getVariable ["dzb_coverT", -999])) > 20}) then {
		_u setVariable ["dzb_coverT", diag_tickTime];
		local _cp = [_u, _src] call dzb_coverPos;
		if (count _cp > 0) then {_u doMove ([group _u, _cp] call dzb_leash); _u setUnitPos "MIDDLE";} else {_u setUnitPos "DOWN";};
	};
};
dzb_onMateKilled = {
	local _u = _this select 0; local _k = _this select 1;
	local _g = group _u;
	if (isNull _k || {isNull _g}) exitWith {};
	{if (alive _x) then {_x reveal [_k, 3];};} forEach (units _g);
	if (count units _g > 1) then {[_g, getPosATL _k] call dzb_popSmoke;};
};
dzb_initUnit = {
	local _u = _this;
	if (_u getVariable ["dzb_u", false]) exitWith {};
	_u setVariable ["dzb_u", true];
	if (dzb_retune) then {
		local _acc = _u skill "aimingAccuracy";
		_u setSkill ["aimingAccuracy", ((_acc * 0.6) max 0.22) min 0.5];
		_u setSkill ["aimingShake", 0.55];
		_u setSkill ["aimingSpeed", 0.6];
		_u setSkill ["spotDistance", 0.85];
		_u setSkill ["spotTime", 0.8];
		_u setSkill ["courage", 0.9];
		_u setSkill ["commanding", 1];
		_u setSkill ["general", 0.9];
		_u setSkill ["reloadSpeed", 0.8];
	};
	_u addEventHandler ["Hit", {_this call dzb_onHit;}];
	_u addEventHandler ["Killed", {_this call dzb_onMateKilled;}];
	_u allowFleeing 0;
	if (vehicle _u == _u) then {
		if (dzb_nadeMuzzle != "" && {random 1 < 0.6}) then {_u addMagazine dzb_nade;};
		if (dzb_smokeMuzzle != "" && {random 1 < 0.6}) then {_u addMagazine dzb_smoke;};
	};
};
dzb_throw = { // [unit, target pos or object, magazine, muzzle]
	local _u = _this select 0; local _m = _this select 2;
	if (!(_m in magazines _u) || {(_this select 3) == ""}) exitWith {};
	_u doWatch (_this select 1);
	_this spawn {
		uiSleep 1.5;
		local _u = _this select 0;
		if (alive _u && {vehicle _u == _u}) then {_u fire [_this select 3, _this select 3, _this select 2];};
	};
};
dzb_coverPos = { // [unit, threat] -> position behind the nearest cover (or [])
	local _u = _this select 0; local _t = _this select 1;
	local _best = []; local _bd = 999;
	{
		if (_x != _u && {!(_x isKindOf "Man")} && {!(_x isKindOf "AllVehicles")}) then {
			local _bb = boundingBox _x;
			local _size = ((_bb select 1) select 0) - ((_bb select 0) select 0);
			if (_size > 1.2 && {_size < 12}) then { // walls, rocks, trees, sheds - not whole buildings (AI can't path into those)
				local _d = _x distance _u;
				if (_d < _bd) then {_bd = _d; _best = [getPosATL _x, [getPosATL _t, getPosATL _x] call dzb_dirTo, (_size / 2) + 1.5] call dzb_offset;};
			};
		};
	} forEach (nearestObjects [_u, [], 25]);
	_best
};
dzb_shareIntel = { // [group, target]
	local _g = _this select 0; local _p = _this select 1;
	local _l = leader _g;
	{
		if (_x != _g && {side _x == side _g} && {count units _x > 0} && {(leader _x distance _l) < 400}) then {
			{_x reveal [_p, 1.8];} forEach (units _x);
		};
	} forEach allGroups;
};
dzb_restore = { // back to normal patrolling
	local _g = _this;
	{_x setUnitPos "AUTO"; _x doWatch objNull; if (_x != leader _g) then {_x doFollow (leader _g);};} forEach (units _g);
	if (count (waypoints _g) > 0) then {_g setCurrentWaypoint [_g, currentWaypoint _g];};
	local _home = _g getVariable ["dzb_home", []];
	if (count _home > 0) then {_g move _home;};
	_g setSpeedMode "LIMITED";
	_g setVariable ["dzb_state", ""];
	_g setVariable ["dzb_flank", []];
};
dzb_paradrop = { // [heli, target]
	local _h = _this select 0; local _p = _this select 1;
	local _fac = _h getVariable ["dzl_fac", "Bandits"];
	local _hp = getPosATL _h;
	local _g = [_fac, [_hp select 0, _hp select 1, 0], 4] call dzf_spawnGroup;
	{
		local _c = createVehicle ["ParachuteWest", [(_hp select 0) + random 10 - 5, (_hp select 1) + random 10 - 5, (_hp select 2) - 5], [], 0, "FLY"];
		dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _c];
		_c setPos [(_hp select 0) + random 10 - 5, (_hp select 1) + random 10 - 5, ((_hp select 2) - 5) max 60];
		_x moveInDriver _c;
	} forEach (units _g);
	{_x reveal [_p, 2];} forEach (units _g);
	_g setBehaviour "COMBAT"; _g setCombatMode "RED"; _g setSpeedMode "FULL";
	_g move (getPosATL _p);
	if (isPlayer _p) then {[_p, "PARATROOPERS!", format ["A %1 helicopter is dropping troops on you!", _fac], "#FF5555"] call dzf_huntPopup;};
	diag_log format ["DZ AI BRAIN: %1 helicopter dropped paratroopers near %2", _fac, mapGridPosition _hp];
};

// ---------------- engage logic ----------------
dzb_startEngage = { // [group, target, dist]
	local _g = _this select 0; local _p = _this select 1; local _d = _this select 2;
	_g setVariable ["dzb_state", "engage"];
	_g setBehaviour "COMBAT"; _g setCombatMode "RED"; _g setSpeedMode "FULL";
	[_g, _p] call dzb_shareIntel;
	_g setVariable ["dzb_shared", diag_tickTime];
	local _men = _g call dzb_onFoot;
	if (count (_g getVariable ["dzb_size", []]) == 0) then {_g setVariable ["dzb_size", [count units _g]];};
	// split: the furthest half flanks (groups of 4+ and not already in your face)
	local _flank = [];
	if (count _men >= 4 && {_d > 70}) then {
		local _sorted = +_men;
		for "_i" from 0 to (count _sorted) - 2 do { // simple sort by distance to target, furthest first
			for "_j" from 0 to (count _sorted) - 2 - _i do {
				if (((_sorted select _j) distance _p) < ((_sorted select (_j + 1)) distance _p)) then {
					local _tmp = _sorted select _j; _sorted set [_j, _sorted select (_j + 1)]; _sorted set [_j + 1, _tmp];
				};
			};
		};
		for "_i" from 0 to (floor ((count _sorted) / 2)) - 1 do {
			if ((_sorted select _i) != leader _g) then {_flank set [count _flank, _sorted select _i];};
		};
	};
	local _side = if (random 1 < 0.5) then {90} else {-90};
	local _a = ([getPosATL _p, getPosATL (leader _g)] call dzb_dirTo) + _side;
	local _fd = ((_d * 0.6) max 60) min 200;
	local _fp = [getPosATL _p, _a, _fd] call dzb_offset;
	if (surfaceIsWater _fp) then {_fp = [getPosATL _p, _a + 180, _fd] call dzb_offset;};
	_fp = [_g, _fp] call dzb_leash;
	{_x doMove _fp; _x setUnitPos "AUTO";} forEach _flank;
	_g setVariable ["dzb_flank", _flank];
	_g setVariable ["dzb_flankPos", _fp];
	_g setVariable ["dzb_flankT", diag_tickTime];
	// everybody else: into cover and open fire
	{
		if !(_x in _flank) then {
			local _cp = [_x, _p] call dzb_coverPos;
			if (count _cp > 0) then {_x doMove _cp;};
			_x setUnitPos "MIDDLE";
			_x doTarget _p; _x doFire _p;
		};
	} forEach _men;
};
dzb_engage = { // [group, target, dist] - runs every tick while in contact
	local _g = _this select 0; local _p = _this select 1; local _d = _this select 2;
	local _now = diag_tickTime;
	local _men = _g call dzb_onFoot;
	local _pp = getPosATL _p;
	local _inside = _p call dzb_inBuilding;
	// keep sharing intel
	if ((_now - (_g getVariable ["dzb_shared", 0])) > 30) then {[_g, _p] call dzb_shareIntel; _g setVariable ["dzb_shared", _now];};
	// flankers: get into position, then assault (into the building if you're hiding)
	local _flank = _g getVariable ["dzb_flank", []];
	if (count _flank > 0) then {
		local _fp = _g getVariable ["dzb_flankPos", _pp];
		local _there = true;
		{if (alive _x && {(_x distance _fp) > 30}) then {_there = false;};} forEach _flank;
		if (_there || {(_now - (_g getVariable ["dzb_flankT", _now])) > 75}) then {
			local _dest = _pp;
			if (_inside) then {
				local _b = nearestBuilding _p;
				local _best = _pp; local _bd = 999; local _i = 0;
				while {_i < 40 && {((_b buildingPos _i) select 0) != 0}} do {
					local _bp = _b buildingPos _i;
					if ((_bp distance _pp) < _bd && {(_bp distance _pp) > 2}) then {_bd = _bp distance _pp; _best = _bp;};
					_i = _i + 1;
				};
				_dest = _best;
			};
			_dest = [_g, _dest] call dzb_leash;
			{if (alive _x) then {_x doMove _dest; _x setUnitPos "AUTO";};} forEach _flank;
			_g setVariable ["dzb_flankPos", _dest]; _g setVariable ["dzb_flankT", _now + 999];
		};
	};
	{
		local _u = _x;
		local _ud = _u distance _p;
		// close in: stop crouching behind cover, fight
		if (_ud < 35) then {_u setUnitPos "AUTO";};
		// grenades
		if (_ud > 14 && {_ud < 40} && {(_now - (_u getVariable ["dzb_nadeT", 0])) > 25} && {random 1 < (if (_inside) then {0.5} else {0.25})}) then {
			_u setVariable ["dzb_nadeT", _now];
			[_u, _p, dzb_nade, dzb_nadeMuzzle] call dzb_throw;
		};
		// snipers keep their distance and go prone
		if ((primaryWeapon _u) in dzb_snipers) then {
			if (_ud < 130) then {_u doMove ([_g, [_pp, [_pp, getPosATL _u] call dzb_dirTo, 260] call dzb_offset] call dzb_leash); _u setUnitPos "AUTO";} else {_u setUnitPos "DOWN";};
		};
		// wounded: smoke, fall back, get patched up
		if (damage _u > 0.5 && {!(_u getVariable ["dzb_treated", false])}) then {
			_u setVariable ["dzb_treated", true];
			local _buddy = objNull;
			{if (_x != _u && {alive _x}) exitWith {_buddy = _x;};} forEach _men;
			if (!isNull _buddy) then {[_buddy, _pp, dzb_smoke, dzb_smokeMuzzle] call dzb_throw;};
			local _back = [getPosATL _u, [_pp, getPosATL _u] call dzb_dirTo, 45] call dzb_offset;
			_u doMove _back;
			[_u, _buddy, _back] spawn {
				uiSleep 15;
				local _u = _this select 0; local _b = _this select 1;
				if (alive _u && {!isNull _b} && {alive _b}) then {
					_b doMove (getPosATL _u);
					uiSleep 12;
					if (alive _u && {alive _b} && {(_b distance _u) < 6}) then {
						_b playMove "AinvPknlMstpSlayWrflDnon_medic";
						uiSleep 6;
						if (alive _u) then {_u setDamage 0.15;};
					};
				};
			};
		};
		if (!(_u in _flank) && {(_now - (_u getVariable ["dzb_fireT", 0])) > 12}) then {
			_u setVariable ["dzb_fireT", _now];
			_u doTarget _p; _u doFire _p;
		};
	} forEach _men;
	// morale: heavy losses -> fall back and call for help (once)
	local _size = (_g getVariable ["dzb_size", [count units _g]]) select 0;
	local _alive = count _men;
	if (_size >= 3 && {_alive > 0} && {_alive <= ceil (_size / 3)} && {!(_g getVariable ["dzb_retreated", false])}) then {
		_g setVariable ["dzb_retreated", true];
		_g setVariable ["dzb_state", "retreat"];
		_g setVariable ["dzb_retreatEnd", _now + 45];
		local _away = [_g, [_pp, [_pp, getPosATL (leader _g)] call dzb_dirTo, 220] call dzb_offset] call dzb_leash;
		if (count _men > 0) then {[_men select 0, _pp, dzb_smoke, dzb_smokeMuzzle] call dzb_throw;};
		{_x doMove _away; _x setUnitPos "AUTO";} forEach _men;
		// reinforcements: nearest friendly foot group within 900m
		local _rg = grpNull; local _rd = 900;
		{
			if (_x != _g && {side _x == side _g} && {count units _x > 1} && {!isPlayer (leader _x)} && {vehicle (leader _x) == leader _x} && {(_x getVariable ["dzb_state", ""]) != "engage"} && {count (_x getVariable ["dzb_home", []]) == 0}) then {
				local _dd = (leader _x) distance _pp;
				if (_dd < _rd) then {_rd = _dd; _rg = _x;};
			};
		} forEach allGroups;
		if (!isNull _rg) then {
			{_x reveal [_p, 2];} forEach (units _rg);
			_rg setBehaviour "COMBAT"; _rg setSpeedMode "FULL";
			_rg move _pp;
			diag_log format ["DZ AI BRAIN: %1 pulled back and called in %2 (%3m away)", _g, _rg, round _rd];
		};
	};
};

// ---------------- main loop ----------------
while {true} do {
	local _players = call dzf_players;
	local _now = diag_tickTime;
	if (count _players > 0) then {
		{
			local _g = _x;
			if ((side _g == EAST || {side _g == RESISTANCE} || {side _g == WEST}) && {count units _g > 0} && {alive (leader _g)} && {!isPlayer (leader _g)} && {!captive (leader _g)} && {!(_g getVariable ["dzb_skip", false])}) then {
				local _l = leader _g;
				local _np = 999999;
				{_np = _np min (_x distance _l);} forEach _players;
				// who are we fighting? the nearest enemy this group knows about (you, or enemy AI)
				local _p = _l findNearestEnemy _l;
				if (!isNull _p && {_p isKindOf "zZombie_Base" || {side _p == civilian} || {!alive _p}}) then {_p = objNull;};
				if (isNull _p && {side _g != WEST}) then {
					{if ((_x distance _l) <= _np) then {_p = _x;};} forEach _players;
				};
				local _d = if (isNull _p) then {999999} else {_p distance _l};
				if (_np < dzb_range && {!isNull _p}) then {
					if (isNil {_g getVariable "dzb_init"}) then {
						_g setVariable ["dzb_init", true];
						// WICKED AI mission / fortress groups keep a leash around their post
						if (!isNil {_g getVariable "Respawn"}) then {_g setVariable ["dzb_home", getPosATL _l];};
					};
					{_x call dzb_initUnit;} forEach (units _g);
					local _k = [_g, _p] call dzb_knows;
					local _veh = vehicle _l;
					local _state = _g getVariable ["dzb_state", ""];
					call {
						// helicopters: drop paratroopers once when they find you
						if (_veh isKindOf "Air") exitWith {
							if (isPlayer _p && {!isNil {_veh getVariable "dzl_fac"}} && {_k > 1} && {_d < 700} && {!(_veh getVariable ["dzb_para", false])} && {((getPosATL _veh) select 2) > 60} && {(_veh emptyPositions "cargo") >= 4} && {alive _veh}) then {
								_veh setVariable ["dzb_para", true];
								[_veh, _p] call dzb_paradrop;
							};
						};
						// ground vehicles: passengers bail out to fight, wrecked vehicles get abandoned
						if (_veh != _l) then {
							if (_k > 1 && {_d < 250} && {!(_g getVariable ["dzb_dismounted", false])}) then {
								_g setVariable ["dzb_dismounted", true];
								local _armed = count ((typeOf _veh) call WAI_GetTurrets) > 0;
								{
									local _ar = assignedVehicleRole _x;
									local _role = if (count _ar > 0) then {toLower (_ar select 0)} else {""};
									if (_role == "cargo" || {!_armed} || {damage _veh > 0.6}) then {unassignVehicle _x; doGetOut _x;};
								} forEach (crew _veh);
							};
						};
						if (_state == "retreat") exitWith {
							if (_now > (_g getVariable ["dzb_retreatEnd", 0])) then {_g setVariable ["dzb_state", ""];};
						};
						if (_k > 1.5) then {
							_g setVariable ["dzb_lkp", getPosATL _p];
							_g setVariable ["dzb_seen", _now];
							if (_state != "engage") then {[_g, _p, _d] call dzb_startEngage;} else {[_g, _p, _d] call dzb_engage;};
						} else {
							if (_state == "engage" && {(_now - (_g getVariable ["dzb_seen", _now])) > 30}) then {
								// lost you: search your last known position
								local _lkp = _g getVariable ["dzb_lkp", getPosATL _p];
								{_x doMove ([_g, [_lkp, random 360, 10 + random 35] call dzb_offset] call dzb_leash); _x setUnitPos "AUTO";} forEach (_g call dzb_onFoot);
								_g setSpeedMode "NORMAL";
								_g setVariable ["dzb_state", "search"];
								_g setVariable ["dzb_searchEnd", _now + 90];
							};
							if (_state == "search" && {_now > (_g getVariable ["dzb_searchEnd", 0])}) then {_g call dzb_restore;};
						};
					};
				};
			};
		} forEach allGroups;
	};
	uiSleep 4;
};
