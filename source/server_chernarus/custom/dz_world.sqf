/*
	DZ World Events (server side) - more things to do, and a world that talks.
	  - DISTRESS CALLS: a survivor is held hostage by bandits in a town. Free them (walk up to them),
	    then lead them to a trader. They follow you on foot and hop in your vehicle. Red smoke / flares mark the spot.
	  - COURIER JOBS: pick up a package and deliver it to a far-away trader. Bandit squads come after the carrier.
	    If the carrier dies the package drops on the ground and anyone can grab it.
	  - CAMP DEFENCE: a survivor camp radios for help. When you arrive, 3 waves of attackers hit it.
	    Keep at least one defender alive for coins + a loot crate.
	  - STASH TIPS: survivor NPCs post in chat about gear they left inside a house (town + grid). No marker - go look.
	  - RADIO INTERCEPTS: carry a Radio and you overhear the AI (convoys, helis, occupied towns, hunters...).
	  - NIGHT FLARES: flares go up over fights, hostages and camps at night, so you can see where the action is.
	Uses helpers from dz_factions.sqf / dz_activities.sqf / dz_living.sqf / dz_survivors.sqf.
*/
waitUntil {uiSleep 5; !isNil "dzf_spawnGroup" && {!isNil "dzf_towns"} && {!isNil "dza_fillCrate"} && {!isNil "dzl_skirmishes"}};
uiSleep 45;
diag_log "DZ WORLD: starting";
if (isNil "dzf_onIsland") then {dzf_onIsland = {false};};

// ---------------- settings ----------------
dzw_rescueReward  = 4000;
dzw_defendReward  = 3000;      // per player who helped, +500 per defender still alive
dzw_rescueEvery   = [1500, 2100];
dzw_courierEvery  = [1800, 2400];
dzw_defendEvery   = [2100, 3000];
dzw_stashEvery    = [720, 1200];
dzw_radioEvery    = [420, 720];

// ---------------- helpers ----------------
dzw_rnd = {(_this select 0) + random ((_this select 1) - (_this select 0))};
dzw_names = ["Marco","Tess","Big_Al","Yuri","Nadia","Sam_the_Medic","Rico","Hannah","Wes","Olga","Duke","Ines"];
dzw_randName = {
	local _l = dzw_names;
	if (!isNil "dzs_names") then {_l = _l + dzs_names;};
	_l call BIS_fnc_selectRandom
};
dzw_chat = {dz_fakeChat = format ["%1: %2", _this select 0, _this select 1]; publicVariable "dz_fakeChat";};
dzw_radio = { // text -> only players carrying a Radio hear it
	dz_fakeChat = "[RADIO] " + _this;
	{if ("ItemRadio" in (items _x)) then {(owner _x) publicVariableClient "dz_fakeChat";};} forEach (call dzf_players);
};
dzw_survivorTalk = { // a live survivor NPC comments (chance)
	if (isNil "dzs_parties" || {random 1 > 0.45}) exitWith {};
	local _l = [];
	{local _g = _x select 0; if (!isNull _g && {alive (leader _g)}) then {_l set [count _l, leader _g];};} forEach dzs_parties;
	if (count _l == 0) exitWith {};
	local _u = _l call BIS_fnc_selectRandom;
	[_this, _u] spawn {uiSleep (20 + random 40); if (alive (_this select 1)) then {[(_this select 1) getVariable ["dzs_name","Survivor"], _this select 0] call dzw_chat;};};
};
dzw_nearestSafe = { // pos -> [centre, radius]
	local _b = DZE_SafeZonePosArray select 0;
	{if ((_this distance (_x select 0)) < (_this distance (_b select 0))) then {_b = _x;};} forEach DZE_SafeZonePosArray;
	_b
};
dzw_activeSpots = { // positions of everything already going on
	local _a = [];
	{_a set [count _a, _x select 1];} forEach dzf_zones;
	if (count dzl_takeover > 0) then {_a set [count _a, dzl_takeover select 1];};
	if (!isNil "dza_warlord" && {count dza_warlord > 0}) then {_a set [count _a, getPosATL (dza_warlord select 1)];};
	{_a set [count _a, _x select 1];} forEach dzl_skirmishes;
	if (count dzw_rescue > 0) then {_a set [count _a, dzw_rescue select 9];};
	if (count dzw_defend > 0) then {_a set [count _a, dzw_defend select 0];};
	if (count dzw_courier > 0) then {_a set [count _a, dzw_courier select 6];};
	_a
};
dzw_pickTown = { // [minPlayerDist, maxPlayerDist] -> town pos or []
	local _res = [];
	local _busy = call dzw_activeSpots;
	for "_t" from 1 to 40 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		local _d = _p call dzf_nearestPlayerDist;
		if (_d > (_this select 0) && {_d < (_this select 1)} && {!(_p call dzf_inSafeZone)} && {!(_p call dzf_onIsland)}) then {
			local _ok = true;
			{if ((_p distance _x) < 700) exitWith {_ok = false;};} forEach _busy;
			if (_ok) exitWith {_res = _p;};
		};
		if (count _res > 0) exitWith {};
	};
	_res
};
dzw_housePos = { // [pos, radius] -> a random position inside a house, or []
	local _l = [];
	{
		local _bp = _x buildingPos 0;
		if ((_bp select 0) != 0 && {!surfaceIsWater _bp}) then {_l set [count _l, _bp];};
		if (count _l > 12) exitWith {};
	} forEach (nearestObjects [_this select 0, ["House"], _this select 1]);
	if (count _l == 0) then {[]} else {_l call BIS_fnc_selectRandom}
};
dzw_cleanGroup = { // [group, radius] spawn -> delete the live units once no player is near them
	local _g = _this select 0; local _r = _this select 1;
	if (isNull _g) exitWith {};
	waitUntil {
		uiSleep 30;
		local _near = false;
		{if (alive _x && {((getPosATL _x) call dzf_nearestPlayerDist) < _r}) exitWith {_near = true;};} forEach (units _g);
		!_near
	};
	{if (alive _x) then {deleteVehicle _x;};} forEach (units _g);
	deleteGroup _g;
};
dzw_flare = { // [pos, colour "White"/"Red"/"Green"/"Yellow"]
	local _p = _this select 0;
	local _f = createVehicle [format ["F_40mm_%1", _this select 1], [_p select 0, _p select 1, 0], [], 0, "CAN_COLLIDE"];
	if (isNull _f) exitWith {};
	_f setPosATL [(_p select 0) + random 60 - 30, (_p select 1) + random 60 - 30, 160 + random 60];
	_f setVelocity [0, 0, -1];
};
dzw_isNight = {sunOrMoon < 0.5};
dzw_marker = { // [pos, type, colour, text] -> marker
	local _m = createMarker [format ["dzw_%1_%2", round diag_tickTime, floor random 99999], _this select 0];
	_m setMarkerShape "ICON"; _m setMarkerType (_this select 1); _m setMarkerColor (_this select 2); _m setMarkerText (_this select 3);
	_m
};
dzw_circle = { // [pos, radius, colour] -> marker
	local _m = createMarker [format ["dzwc_%1_%2", round diag_tickTime, floor random 99999], _this select 0];
	_m setMarkerShape "ELLIPSE"; _m setMarkerSize [_this select 1, _this select 1]; _m setMarkerColor (_this select 2); _m setMarkerBrush "Solid"; _m setMarkerAlpha 0.35;
	_m
};

// ---------------- chasers (squads that hunt a specific player) ----------------
dzw_chasers = []; // [group, target, until, nextOrder]
dzw_addChaser = { // [group, target, lifetime]
	dzw_chasers set [count dzw_chasers, [_this select 0, _this select 1, diag_tickTime + (_this select 2), 0]];
};
dzw_updateChasers = {
	local _keep = [];
	{
		local _g = _x select 0; local _t = _x select 1;
		local _done = isNull _g || {(_g call dzf_aliveCount) == 0} || {isNull _t} || {!alive _t} || {diag_tickTime > (_x select 2)} || {((leader _g) distance _t) > 1800};
		if (_done) then {
			if (!isNull _g) then {[_g, 300] spawn dzw_cleanGroup;};
		} else {
			if (diag_tickTime > (_x select 3)) then {
				while {count (waypoints _g) > 0} do {deleteWaypoint ((waypoints _g) select 0);};
				local _wp = _g addWaypoint [getPosATL _t, 25];
				_wp setWaypointType "SAD";
				_g setSpeedMode "FULL"; _g setBehaviour "AWARE"; _g setCombatMode "RED";
				(leader _g) reveal [_t, 1.5];
				_x set [3, diag_tickTime + 25];
			};
			_keep set [count _keep, _x];
		};
	} forEach dzw_chasers;
	dzw_chasers = _keep;
};

// ======================= DISTRESS CALLS (hostage rescue) =======================
dzw_rescue = []; // [hostage, captors, markers, start, escort, dest, name, freed, lastSignal, pos, lostSince]
dzw_nextRescue = diag_tickTime + 480 + random 300;
dzw_startRescue = {
	local _town = [900, 3000] call dzw_pickTown;
	if (count _town == 0) exitWith {};
	local _spot = [_town, 180] call dzw_housePos;
	if (count _spot == 0) then {_spot = _town findEmptyPosition [5, 80, "SUV_Red"]; if (count _spot > 0) then {_spot set [2, 0];};};
	if (count _spot == 0) exitWith {};
	local _name = call dzw_randName;
	local _hg = createGroup WEST;
	local _h = _hg createUnit [["Survivor2_DZ","Doctor_DZ","Worker1_DZ","Civilian1_DZ","SurvivorW2_DZ","Rocker1_DZ"] call BIS_fnc_selectRandom, _spot, [], 0, "CAN_COLLIDE"];
	_h setPosATL _spot;
	removeAllWeapons _h; removeAllItems _h;
	_h setCaptive true;
	_h allowDamage false; // can't be killed by zombies or stray bullets - the challenge is getting to them
	_h disableAI "MOVE"; _h disableAI "TARGET"; _h disableAI "AUTOTARGET";
	_h setBehaviour "CARELESS";
	_h playMoveNow "AmovPercMstpSnonWnonDnon_AmovPercMstpSsurWnonDnon";
	_h setVariable ["dzs_name", _name];
	_h setVariable ["bodyName", "NPC", false];
	_hg setVariable ["dzb_skip", true]; _hg setVariable ["DoNotFreeze", true];
	_hg allowFleeing 0;
	local _cg = [["Bandits","Bandits","Hunters"] call BIS_fnc_selectRandom, [(_spot select 0) + 12, (_spot select 1) + 12, 0], 3 + floor random 3] call dzf_spawnGroup;
	[_cg, _spot, 60] call dzf_patrolArea;
	local _a = random 360; local _o = random 90;
	local _mp = [(_spot select 0) + _o * sin _a, (_spot select 1) + _o * cos _a, 0];
	local _m1 = [_mp, 150, "ColorOrange"] call dzw_circle;
	local _m2 = [_mp, "mil_triangle", "ColorOrange", format ["RESCUE: %1", _name]] call dzw_marker;
	local _tn = _spot call dz_nearTown;
	dzw_rescue = [_h, _cg, [_m1, _m2], diag_tickTime, objNull, [], _name, false, 0, _spot, 0];
	["DISTRESS CALL", format ["%1 is being held by bandits near %2 (%3). Walk up to them to cut them loose, then lead them to a trader for %4 coins.", _name, _tn, mapGridPosition _mp, dzw_rescueReward], "#FF8800"] call dz_sendPopup;
	[_name, (["they got me tied up in a house near %1, please anyone...","help!! bandits grabbed me at %1, they're going to kill me","if anyone hears this, im a prisoner near %1. please"] call BIS_fnc_selectRandom) call {format [_this, _tn]}] call dzw_chat;
	(format ["anyone going for %1 near %2? I'm too far", _name, _tn]) call dzw_survivorTalk;
	diag_log format ["DZ WORLD: rescue %1 at %2", _name, mapGridPosition _spot];
};
dzw_endRescue = {
	{deleteMarker _x;} forEach (dzw_rescue select 2);
	if (!isNull (dzw_rescue select 4)) then {(dzw_rescue select 4) setVariable ["dz_job", nil, true];};
	[dzw_rescue select 1, 800] spawn dzw_cleanGroup;
	(dzw_rescue select 0) spawn {
		uiSleep 60;
		waitUntil {uiSleep 20; isNull _this || {((getPosATL _this) call dzf_nearestPlayerDist) > 250}};
		if (!isNull _this) then {local _g = group _this; deleteVehicle _this; deleteGroup _g;};
	};
	dzw_rescue = [];
	dzw_nextRescue = diag_tickTime + (dzw_rescueEvery call dzw_rnd);
};
dzw_checkRescue = {
	if (count dzw_rescue == 0) exitWith {};
	local _r = dzw_rescue;
	local _h = _r select 0; local _name = _r select 6; local _now = diag_tickTime;
	if (isNull _h) exitWith {call dzw_endRescue;};
	local _hp = getPosATL _h;
	if ((_now - (_r select 3)) > 3000) exitWith {
		["DISTRESS CALL", format ["%1's radio went silent.", _name], "#AAAAAA"] call dz_sendPopup;
		call dzw_endRescue;
	};
	if (!(_r select 7)) then {
		// signal: red smoke by day, red flare at night, while someone is in range
		if ((_now - (_r select 8)) > 150 && {(_hp call dzf_nearestPlayerDist) < 2200}) then {
			_r set [8, _now];
			if (call dzw_isNight) then {[_hp, "Red"] call dzw_flare;} else {
				"SmokeShellRed" createVehicle [(_hp select 0) + random 30 - 15, (_hp select 1) + random 30 - 15, 0];
			};
		};
		local _p = objNull;
		{if ((_x distance _h) < 4 && {vehicle _x == _x}) exitWith {_p = _x;};} forEach (call dzf_players);
		if (!isNull _p) then {
			local _dest = _hp call dzw_nearestSafe;
			_r set [7, true]; _r set [4, _p]; _r set [5, _dest];
			_h enableAI "MOVE";
			_h playMoveNow "AmovPercMstpSsurWnonDnon_AmovPercMstpSnonWnonDnon";
			_h setUnitPos "UP";
			(group _h) setSpeedMode "FULL";
			deleteMarker ((_r select 2) select 0);
			local _m = (_r select 2) select 1;
			_m setMarkerPos (_dest select 0); _m setMarkerColor "ColorBlue"; _m setMarkerText format ["RESCUE: bring %1 here", _name];
			local _tn = (_dest select 0) call dz_nearTown;
			[_name, format ["oh thank god %1! get me to the traders at %2, I'll stay right behind you", name _p, _tn]] call dzw_chat;
			_p setVariable ["dz_job", format ["Rescue: lead %1 to the trader near %2", _name, (_dest select 0) call dz_nearTown], true];
			[_p, "RESCUE", format ["%1 is following you. Get them to the trader near %2 (blue marker). They'll jump in your vehicle if you stop next to them.", _name, _tn], "#FF8800"] call dzf_huntPopup;
			diag_log format ["DZ WORLD: rescue %1 freed by %2", _name, name _p];
		};
	} else {
		local _dest = _r select 5;
		if ((_hp distance (_dest select 0)) < ((_dest select 1) + 40)) then {
			local _p = _r select 4;
			if (isNull _p || {!alive _p}) then {
				{if ((_x distance _h) < 150) exitWith {_p = _x;};} forEach (call dzf_players);
			};
			if (vehicle _h != _h) then {unassignVehicle _h; _h action ["getOut", vehicle _h];};
			[_name, ["made it!! thank you, I owe you my life","you're a legend. here, take what I had saved","safe... finally. thanks friend"] call BIS_fnc_selectRandom] call dzw_chat;
			if (!isNull _p) then {
				[_p, dzw_rescueReward, format ["rescued %1", _name]] call dza_pay;
				_p setVariable ["humanity", (_p getVariable ["humanity", 0]) + 250, true];
				["RESCUED", format ["%1 brought %2 to safety.", name _p, _name], "#33CC33"] call dz_sendPopup;
			};
			call dzw_endRescue;
		} else {
		local _p = _r select 4;
		if (isNull _p || {!alive _p} || {!isPlayer _p}) then {
			// escort is gone - wait for someone else to come and get them
			if (vehicle _h != _h) then {unassignVehicle _h; _h action ["getOut", vehicle _h];};
			doStop _h;
			local _n = objNull;
			{if ((_x distance _h) < 5) exitWith {_n = _x;};} forEach (call dzf_players);
			if (!isNull _p) then {_p setVariable ["dz_job", nil, true];};
			if (!isNull _n) then {_r set [4, _n]; _n setVariable ["dz_job", format ["Rescue: lead %1 to the trader near %2", _name, ((_r select 5) select 0) call dz_nearTown], true]; [_name, format ["%1! don't leave me out here too", name _n]] call dzw_chat;} else {_r set [4, objNull];};
		} else {
			local _vp = vehicle _p;
			if (vehicle _h != _h) then {
				if (vehicle _h != _vp) then {unassignVehicle _h; _h action ["getOut", vehicle _h];};
			} else {
				if (_vp != _p) then {
					if ((_h distance _vp) < 14 && {(_vp emptyPositions "cargo") > 0} && {(abs (speed _vp)) < 8}) then {
						_h assignAsCargo _vp; _h moveInCargo _vp;
					} else {
						_h doMove (getPosATL _vp);
					};
				} else {
					if ((_h distance _p) > 4) then {_h doMove (getPosATL _p);};
				};
			};
			// left behind?
			if ((_h distance _p) > 400) then {
				if ((_r select 10) == 0) then {_r set [10, _now]; [_p, "RESCUE", format ["You left %1 behind - go back for them.", _name], "#FF8800"] call dzf_huntPopup;};
			} else {_r set [10, 0];};
		};
		};
	};
};

// ======================= COURIER JOBS =======================
dzw_courier = []; // [carried, box, carrier, dest, markers, start, pos, ambushStage, reward, pickupPos, ambushAt, startDist]
dzw_nextCourier = diag_tickTime + 900 + random 300;
dzw_dropPackage = { // pos -> new box
	local _b = createVehicle [WAI_CrateSm call BIS_fnc_selectRandom, _this, [], 2, "NONE"];
	clearWeaponCargoGlobal _b; clearMagazineCargoGlobal _b;
	_b setVariable ["permaLoot", true];
	_b
};
dzw_startCourier = {
	local _town = [700, 2500] call dzw_pickTown;
	if (count _town == 0) exitWith {};
	local _pos = _town findEmptyPosition [10, 120, "SUV_Red"];
	if (count _pos == 0) exitWith {};
	_pos set [2, 0];
	local _box = _pos call dzw_dropPackage;
	local _m = [_pos, "mil_pickup", "ColorBlue", "COURIER: package"] call dzw_marker;
	dzw_courier = [false, _box, objNull, [], [_m], diag_tickTime, _pos, 0, 0, _pos, 0, 0];
	["COURIER JOB", format ["A trader needs a package picked up near %1 (blue marker). Walk up to the box to take it, then deliver it. Bandits want it too.", _pos call dz_nearTown], "#4499FF"] call dz_sendPopup;
	diag_log format ["DZ WORLD: courier package at %1", mapGridPosition _pos];
};
dzw_endCourier = {
	{deleteMarker _x;} forEach (dzw_courier select 4);
	if (!isNull (dzw_courier select 1)) then {deleteVehicle (dzw_courier select 1);};
	local _c = dzw_courier select 2;
	if (!isNull _c) then {_c setVariable ["dz_job", nil, true];};
	dzw_courier = [];
	dzw_nextCourier = diag_tickTime + (dzw_courierEvery call dzw_rnd);
};
dzw_courierAmbush = { // carrier -> spawns a squad between the carrier and the destination
	local _c = _this;
	local _dest = (dzw_courier select 3) select 0;
	local _cp = getPosATL _c;
	local _dir = ((_dest select 0) - (_cp select 0)) atan2 ((_dest select 1) - (_cp select 1));
	local _d = 420 + random 120;
	local _ahead = [(_cp select 0) + _d * sin (_dir + random 60 - 30), (_cp select 1) + _d * cos (_dir + random 60 - 30), 0];
	local _sp = [_ahead, 0, 80] call dzf_landPos;
	if (count _sp == 0) then {_sp = [_cp, 380, 500] call dzf_landPos;};
	if (count _sp == 0) exitWith {};
	local _g = [["Bandits","Bandits","Hunters"] call BIS_fnc_selectRandom, _sp, 3 + floor random 2] call dzf_spawnGroup;
	[_g, _c, 600] call dzw_addChaser;
	[_c, "COURIER", "Somebody tipped off the bandits - they're coming for the package!", "#FF4444"] call dzf_huntPopup;
	diag_log format ["DZ WORLD: courier ambush (%1 men) at %2", count units _g, mapGridPosition _sp];
};
dzw_checkCourier = {
	if (count dzw_courier == 0) exitWith {};
	local _c = dzw_courier; local _now = diag_tickTime;
	if ((_now - (_c select 5)) > 2700) exitWith {
		["COURIER JOB", "The package job has expired.", "#AAAAAA"] call dz_sendPopup;
		call dzw_endCourier;
	};
	if (!(_c select 0)) then {
		local _box = _c select 1;
		if (isNull _box) then {_box = (_c select 6) call dzw_dropPackage; _c set [1, _box];};
		local _p = objNull;
		{if ((_x distance _box) < 3.5 && {vehicle _x == _x}) exitWith {_p = _x;};} forEach (call dzf_players);
		if (!isNull _p) then {
			deleteVehicle _box; _c set [1, objNull];
			_c set [0, true]; _c set [2, _p];
			if (count (_c select 3) == 0) then {
				local _bp = getPosATL _p;
				local _far = [];
				{if ((_bp distance (_x select 0)) > 1800) then {_far set [count _far, _x];};} forEach DZE_SafeZonePosArray;
				local _dest = [];
				if (count _far > 0) then {_dest = _far call BIS_fnc_selectRandom;} else {
					_dest = DZE_SafeZonePosArray select 0;
					{if ((_bp distance (_x select 0)) > (_bp distance (_dest select 0))) then {_dest = _x;};} forEach DZE_SafeZonePosArray;
				};
				_c set [3, _dest];
				_c set [8, 2000 + round ((_bp distance (_dest select 0)) * 0.8)];
			};
			local _dest = _c select 3;
			local _m = (_c select 4) select 0;
			_m setMarkerPos (_dest select 0); _m setMarkerType "mil_end"; _m setMarkerText "COURIER: deliver here";
			local _tn = (_dest select 0) call dz_nearTown;
			_p setVariable ["dz_job", format ["Courier: deliver the package to %1", _tn], true];
			[_p, "COURIER", format ["You have the package. Deliver it to the trader near %1 (blue flag) for %2 coins. If you die, you drop it.", _tn, _c select 8], "#4499FF"] call dzf_huntPopup;
			["COURIER JOB", format ["%1 picked up the package. Word is out...", name _p], "#4499FF"] call dz_sendPopup;
			(format ["Bandits: someone grabbed the package near %1. Find them.", (getPosATL _p) call dz_nearTown]) call dzw_radio;
		};
	} else {
		local _p = _c select 2;
		if (isNull _p || {!alive _p} || {!isPlayer _p}) then {
			local _dp = _c select 6;
			_c set [0, false]; _c set [2, objNull]; _c set [1, _dp call dzw_dropPackage];
			local _m = (_c select 4) select 0;
			_m setMarkerPos _dp; _m setMarkerType "mil_pickup"; _m setMarkerText "COURIER: dropped package";
			if (!isNull _p) then {_p setVariable ["dz_job", nil, true];};
			["COURIER JOB", format ["The package was dropped near %1. It's up for grabs.", _dp call dz_nearTown], "#4499FF"] call dz_sendPopup;
		} else {
			_c set [6, getPosATL _p];
			local _dest = _c select 3;
			local _dd = _p distance (_dest select 0);
			_p setVariable ["dz_job", format ["Courier: deliver the package to %1 (%2m)", (_dest select 0) call dz_nearTown, round _dd], true];
			// ambushes: one shortly after the pickup, one halfway
			local _st = _c select 7;
			if (_st == 0) then {_c set [7, 1]; _c set [10, _now + 45 + random 45]; _c set [11, _dd];};
			if (_st == 1 && {_now > (_c select 10)}) then {_c set [7, 2]; _p call dzw_courierAmbush;};
			if (_st == 2 && {_dd < ((_c select 11) * 0.55)} && {_dd > 700}) then {_c set [7, 3]; _p call dzw_courierAmbush;};
			if (_dd < ((_dest select 1) + 30)) then {
				[_p, _c select 8, "package delivered"] call dza_pay;
				["COURIER JOB", format ["%1 delivered the package.", name _p], "#33CC33"] call dz_sendPopup;
				call dzw_endCourier;
			};
		};
	};
};

// ======================= CAMP DEFENCE =======================
dzw_defend = []; // [pos, defenders, objects, markers, start, wave, attackers, waveStart, name, done]
dzw_nextDefend = diag_tickTime + 1320 + random 300;
dzw_startDefend = {
	local _town = [800, 2600] call dzw_pickTown;
	if (count _town == 0) exitWith {};
	local _pos = [];
	for "_t" from 1 to 10 do {
		local _q = [_town, 90, 220] call dzf_landPos;
		if (count _q > 0) then {
			local _e = _q findEmptyPosition [0, 40, "Land_fort_bagfence_round"];
			if (count _e > 0 && {!surfaceIsWater _e}) exitWith {_pos = _e;};
		};
	};
	if (count _pos == 0) exitWith {};
	_pos set [2, 0];
	local _objs = [];
	local _fire = createVehicle ["Land_Fire_burning", _pos, [], 0, "CAN_COLLIDE"];
	if (!isNull _fire) then {_objs set [count _objs, _fire];};
	for "_i" from 0 to 3 do {
		local _a = _i * 90 + 45;
		local _sb = createVehicle ["Land_fort_bagfence_round", [(_pos select 0) + 8 * sin _a, (_pos select 1) + 8 * cos _a, 0], [], 0, "CAN_COLLIDE"];
		if (!isNull _sb) then {_sb setDir _a; _sb setPosATL [(_pos select 0) + 8 * sin _a, (_pos select 1) + 8 * cos _a, 0]; _objs set [count _objs, _sb];};
	};
	local _g = ["Survivors", _pos, 5] call dzf_spawnGroup;
	{
		local _a = _forEachIndex * 72;
		_x setPosATL [(_pos select 0) + 6 * sin _a, (_pos select 1) + 6 * cos _a, 0];
		_x setDir _a;
		_x setVariable ["dzs_name", call dzw_randName];
		_x setSkill ["aimingAccuracy", 0.45]; _x setSkill ["spotDistance", 0.8];
		_x setUnitPos "MIDDLE";
		doStop _x;
	} forEach (units _g);
	_g setVariable ["dzb_skip", true]; _g setVariable ["DoNotFreeze", true];
	_g allowFleeing 0; _g setBehaviour "AWARE"; _g setCombatMode "RED";
	local _name = format ["%1's camp", (leader _g) getVariable ["dzs_name", "Survivor"]];
	local _m1 = [_pos, 120, "ColorGreen"] call dzw_circle;
	local _m2 = [_pos, "mil_flag", "ColorGreen", format ["DEFEND: %1", _name]] call dzw_marker;
	dzw_defend = [_pos, _g, _objs, [_m1, _m2], diag_tickTime, 0, [], 0, _name, false];
	local _tn = _pos call dz_nearTown;
	["SURVIVOR CAMP", format ["%1 near %2 (%3) is about to be attacked. Get there and help them hold out - +%4 coins each if anyone survives.", _name, _tn, mapGridPosition _pos, dzw_defendReward], "#33CC33"] call dz_sendPopup;
	[(leader _g) getVariable ["dzs_name","Survivor"], format ["we're dug in near %1 and we can see them gathering in the trees. we need guns, anyone?", _tn]] call dzw_chat;
	diag_log format ["DZ WORLD: camp defence at %1", mapGridPosition _pos];
};
dzw_endDefend = { // delay, cleanup
	local _d = dzw_defend;
	{deleteMarker _x;} forEach (_d select 3);
	{[_x, 400] spawn dzw_cleanGroup;} forEach (_d select 6);
	[_d select 1, _d select 2, _d select 0] spawn {
		uiSleep 600;
		[_this select 0, 300] call dzw_cleanGroup;
		waitUntil {uiSleep 30; ((_this select 2) call dzf_nearestPlayerDist) > 300};
		{if (!isNull _x) then {deleteVehicle _x;};} forEach (_this select 1);
	};
	dzw_defend = [];
	dzw_nextDefend = diag_tickTime + (dzw_defendEvery call dzw_rnd);
};
dzw_defendWave = {
	local _d = dzw_defend;
	local _wave = (_d select 5) + 1;
	_d set [5, _wave]; _d set [7, diag_tickTime];
	local _pos = _d select 0;
	local _helpers = {(_x distance _pos) < 600} count (call dzf_players);
	local _size = 2 + _wave + (if (_helpers > 1) then {1} else {0});
	local _fac = ["Bandits","Bandits","Hunters"] select (_wave - 1);
	local _sp = [_pos, 380, 480] call dzf_landPos;
	if (count _sp == 0) exitWith {};
	local _g = [_fac, _sp, _size] call dzf_spawnGroup;
	local _wp = _g addWaypoint [_pos, 15]; _wp setWaypointType "SAD";
	_g setSpeedMode "NORMAL";
	(_d select 6) set [count (_d select 6), _g];
	if (_wave == 1) then {
		[(leader (_d select 1)) getVariable ["dzs_name","Survivor"], "HERE THEY COME!"] call dzw_chat;
	} else {
		[_pos, 1500, "CAMP DEFENCE", format ["Wave %1 of 3 is coming from the %2!", _wave, ["north","north-east","east","south-east","south","south-west","west","north-west"] select (round ((((_sp select 0) - (_pos select 0)) atan2 ((_sp select 1) - (_pos select 1)) + 360) / 45) mod 8)], "#FF4444"] call dzl_popupNear;
	};
	diag_log format ["DZ WORLD: camp defence wave %1 (%2 %3)", _wave, _size, _fac];
};
dzw_checkDefend = {
	if (count dzw_defend == 0) exitWith {};
	local _d = dzw_defend; local _now = diag_tickTime;
	local _pos = _d select 0;
	local _defAlive = (_d select 1) call dzf_aliveCount;
	local _wave = _d select 5;
	local _pd = _pos call dzf_nearestPlayerDist;
	// waiting for help
	if (_wave == 0) exitWith {
		if (_pd < 300 || {(_now - (_d select 4)) > 900 && {_pd < 1500}}) then {call dzw_defendWave;};
		if ((_now - (_d select 4)) > 1200 && {_pd > 1500}) then {
			["SURVIVOR CAMP", format ["%1 went quiet. They packed up and left.", _d select 8], "#AAAAAA"] call dz_sendPopup;
			call dzw_endDefend;
		};
	};
	if (_defAlive == 0) exitWith {
		["CAMP FALLEN", format ["%1 was overrun.", _d select 8], "#FF4444"] call dz_sendPopup;
		call dzw_endDefend;
	};
	local _att = 0;
	{_att = _att + (_x call dzf_aliveCount);} forEach (_d select 6);
	local _cur = (_d select 6) select ((count (_d select 6)) - 1);
	if (_wave < 3) then {
		if ((_cur call dzf_aliveCount) <= 1 || {(_now - (_d select 7)) > 300}) then {call dzw_defendWave;};
	} else {
		if (_att == 0 || {(_now - (_d select 7)) > 540 && {_att <= 1}}) then {
			local _c = createVehicle [WAI_CrateMd call BIS_fnc_selectRandom, _pos, [], 5, "NONE"];
			[_c, 3, 4, [dza_medical call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom]] call dza_fillCrate;
			local _pay = dzw_defendReward + 500 * _defAlive;
			local _who = [];
			{if ((_x distance _pos) < 450) then {[_x, _pay, "camp defended"] call dza_pay; _x setVariable ["humanity", (_x getVariable ["humanity",0]) + 150, true]; _who set [count _who, name _x];};} forEach (call dzf_players);
			[(leader (_d select 1)) getVariable ["dzs_name","Survivor"], ["we held!! thank you, take whatever you need from the crate","that's the last of them. you saved us","they're running! drinks are on us"] call BIS_fnc_selectRandom] call dzw_chat;
			["CAMP HELD", format ["%1 survived the attack%2.", _d select 8, if (count _who > 0) then {" thanks to " + (_who select 0)} else {""}], "#33CC33"] call dz_sendPopup;
			call dzw_endDefend;
		};
	};
	// flares over the camp at night during the fight
	if (call dzw_isNight && {random 1 < 0.12}) then {[_pos, "White"] call dzw_flare;};
};

// ======================= STASH TIPS =======================
dzw_stashes = []; // [crate, start]
dzw_nextStash = diag_tickTime + 600 + random 300;
dzw_makeStash = {
	local _town = [400, 2200] call dzw_pickTown;
	if (count _town == 0) exitWith {};
	local _pos = [_town, 200] call dzw_housePos;
	if (count _pos == 0) exitWith {};
	local _c = createVehicle [WAI_CrateSm call BIS_fnc_selectRandom, _pos, [], 0, "CAN_COLLIDE"];
	_c setPosATL _pos;
	local _extra = [WAI_Food call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom];
	if (random 1 < 0.3) then {_extra set [count _extra, dza_gems call BIS_fnc_selectRandom];};
	[_c, 1 + floor random 2, 3, _extra] call dza_fillCrate;
	if (random 1 < 0.35) then {_c addMagazineCargoGlobal ["ItemGoldBar", 1 + floor random 2];};
	dzw_stashes set [count dzw_stashes, [_c, diag_tickTime]];
	// who's talking: a live survivor NPC if there is one
	local _who = call dzw_randName;
	if (!isNil "dzs_parties") then {
		local _l = [];
		{local _g = _x select 0; if (!isNull _g && {alive (leader _g)}) then {_l set [count _l, (leader _g) getVariable ["dzs_name","Survivor"]];};} forEach dzs_parties;
		if (count _l > 0) then {_who = _l call BIS_fnc_selectRandom;};
	};
	local _tn = _pos call dz_nearTown; local _gr = mapGridPosition _pos;
	[_who, ([
		"stashed some gear inside a house in %1 (grid %2), can't carry it all. first come first served",
		"left a box of stuff in a building at %1, grid %2. don't need it anymore",
		"my buddy didn't make it... his stash is still in a house in %1 (%2). go get it before the bandits do",
		"heads up, there's a crate upstairs in one of the houses in %1, around %2. I'm out of space",
		"found a stash in %1 (%2) but I'm being chased. someone grab it"
	] call BIS_fnc_selectRandom) call {format [_this, _tn, _gr]}] call dzw_chat;
	diag_log format ["DZ WORLD: stash at %1 (%2)", _tn, _gr];
};
dzw_checkStashes = {
	local _keep = [];
	{
		local _c = _x select 0;
		if (!isNull _c) then {
			if ((diag_tickTime - (_x select 1)) > 3000 && {((getPosATL _c) call dzf_nearestPlayerDist) > 250}) then {deleteVehicle _c;} else {_keep set [count _keep, _x];};
		};
	} forEach dzw_stashes;
	dzw_stashes = _keep;
};

// ======================= RADIO INTERCEPTS =======================
dzw_nextRadio = diag_tickTime + 300 + random 120;
dzw_radioChatter = {
	local _l = [];
	{
		local _g = _x select 0; local _e = _x select 1;
		if (!isNull _g && {alive _e}) then {
			local _tn = (getPosATL _e) call dz_nearTown;
			_l set [count _l, format ["%1 convoy: passing %2, keep it tight and watch the treeline.", _x select 5, _tn]];
			_l set [count _l, format ["%1 convoy: anything moves near %2, light it up.", _x select 5, _tn]];
		};
	} forEach dzl_convoys;
	{
		local _h = _x select 1;
		if (!isNull _h && {alive _h}) then {
			local _tn = (getPosATL _h) call dz_nearTown;
			_l set [count _l, format ["Air patrol: over %1 now, low on patience. Anyone on the ground is a target.", _tn]];
		};
	} forEach dzl_helis;
	if (count dzl_takeover > 0) then {
		_l set [count _l, format ["%1: %2 is ours now. Nobody gets in.", dzl_takeover select 4, dzl_takeover select 5]];
	};
	if (!isNil "dza_warlord" && {count dza_warlord > 0}) then {
		_l set [count _l, format ["Bandits: the boss says nobody leaves %1 alive. Double the watch.", (getPosATL (dza_warlord select 1)) call dz_nearTown]];
	};
	{_l set [count _l, format ["Unknown: taking fire in %1! need backup!", _x select 3]];} forEach dzl_skirmishes;
	if (count dzw_rescue > 0 && {!(dzw_rescue select 7)}) then {
		_l set [count _l, format ["Bandits: prisoner's still breathing near %1. If anyone comes for them, shoot both.", (dzw_rescue select 9) call dz_nearTown]];
	};
	if (count dzw_courier > 0 && {dzw_courier select 0}) then {
		_l set [count _l, "Bandits: the courier's on the move. Whoever brings me that package gets a cut."];
	};
	if (!isNil "dzf_hunters" && {count dzf_hunters > 0}) then {
		_l set [count _l, "Hunters: target acquired. Moving in quiet, no radio until it's done."];
	};
	if (count _l == 0) then {
		_l = ["Military: all units, sector check. Report anything that moves.","Stalkers: anyone got antibiotics? trading ammo.","Bandits: road toll is up. Nobody passes for free.","Unknown: ...is anyone out there? ...hello?"];
	};
	(_l call BIS_fnc_selectRandom) call dzw_radio;
};

// ======================= NIGHT FLARES =======================
dzw_nextFlare = 0;
dzw_nightFlare = {
	local _c = [];
	{_c set [count _c, [_x select 1, "White"]];} forEach dzl_skirmishes;
	if (count dzl_takeover > 0) then {_c set [count _c, [dzl_takeover select 1, "Red"]];};
	if (count dzw_rescue > 0 && {!(dzw_rescue select 7)}) then {_c set [count _c, [dzw_rescue select 9, "Red"]];};
	if (count _c == 0 || {random 1 < 0.3}) then {
		local _t = [700, 2500] call dzw_pickTown;
		if (count _t > 0) then {_c set [count _c, [_t, ["White","Green","Yellow"] call BIS_fnc_selectRandom]];};
	};
	if (count _c == 0) exitWith {};
	local _f = _c call BIS_fnc_selectRandom;
	if (((_f select 0) call dzf_nearestPlayerDist) < 3000) then {
		_f call dzw_flare;
		if (random 1 < 0.4) then {[_f, 4 + random 6] spawn {uiSleep (_this select 1); (_this select 0) call dzw_flare;};};
	};
};

// let the spawn picker avoid the new events too (read by dzl_publishAvoid)
dzw_avoid = {
	local _a = [];
	if (count dzw_rescue > 0) then {_a set [count _a, [dzw_rescue select 9, 400]];};
	if (count dzw_defend > 0) then {_a set [count _a, [dzw_defend select 0, 500]];};
	{_a set [count _a, [getPosATL (leader (_x select 0)), 400]];} forEach dzw_chasers;
	_a
};

// ---------------- main loop ----------------
while {true} do {
	local _now = diag_tickTime;
	local _any = count (call dzf_players) > 0;
	if (count dzw_rescue == 0 && {_any} && {_now > dzw_nextRescue}) then {dzw_nextRescue = _now + 300; call dzw_startRescue;};
	if (count dzw_courier == 0 && {_any} && {_now > dzw_nextCourier}) then {dzw_nextCourier = _now + 300; call dzw_startCourier;};
	if (count dzw_defend == 0 && {_any} && {_now > dzw_nextDefend}) then {dzw_nextDefend = _now + 300; call dzw_startDefend;};
	if (count dzw_stashes < 2 && {_any} && {_now > dzw_nextStash}) then {dzw_nextStash = _now + (dzw_stashEvery call dzw_rnd); call dzw_makeStash;};
	if (_any && {_now > dzw_nextRadio}) then {dzw_nextRadio = _now + (dzw_radioEvery call dzw_rnd); call dzw_radioChatter;};
	if (_any && {call dzw_isNight} && {_now > dzw_nextFlare}) then {dzw_nextFlare = _now + 120 + random 90; call dzw_nightFlare;};
	call dzw_checkRescue;
	call dzw_checkCourier;
	call dzw_checkDefend;
	call dzw_checkStashes;
	call dzw_updateChasers;
	uiSleep 5;
};
