/*
	Lingor fortress helpers (custom).
	The fortress layout is built around a centre found at runtime: the flattest open spot near the
	anchor point, so walls don't end up inside buildings, trees or water. Pieces that would land on
	top of an existing map building are skipped.
*/

// [anchor, maxDistance, [[x1,y1,x2,y2],...] forbidden boxes] -> centre position [x,y,0]
dzfort_findCenter = {
	local _anchor = _this select 0;
	local _max = _this select 1;
	local _boxes = _this select 2;
	local _best = [_anchor select 0, _anchor select 1, 0];
	local _found = false;
	for "_r" from 0 to _max step 15 do {
		if (_found) exitWith {};
		local _steps = if (_r == 0) then {1} else {round (_r / 10) max 6};
		for "_i" from 0 to (_steps - 1) do {
			local _a = _i * (360 / _steps);
			local _p = [(_anchor select 0) + _r * sin _a, (_anchor select 1) + _r * cos _a, 0];
			local _inBox = false;
			{if ((_p select 0) > (_x select 0) && {(_p select 0) < (_x select 2)} && {(_p select 1) > (_x select 1)} && {(_p select 1) < (_x select 3)}) exitWith {_inBox = true;};} forEach _boxes;
			if (!_inBox && {!surfaceIsWater _p} && {count (_p isFlatEmpty [12, 0, 0.45, 25, 0, false, objNull]) > 0} && {count (nearestObjects [_p, ["House"], 25]) == 0}) exitWith {
				_best = _p; _found = true;
			};
		};
	};
	diag_log format ["DZ FORTRESS: centre %1 chosen for anchor %2 (flat spot found: %3)", _best, _anchor, _found];
	_best
};

// relative [dx,dy] (rotated by _dir) -> world position
dzfort_rel = {
	local _c = _this select 0; local _d = _this select 1; local _dx = (_this select 2) select 0; local _dy = (_this select 2) select 1;
	[(_c select 0) + _dx * cos _d + _dy * sin _d, (_c select 1) - _dx * sin _d + _dy * cos _d, 0]
};

// [centre, dir, radius] -> object array for WAI_SpawnStaticObjects (walls, towers, nests, barracks)
dzfort_layout = {
	local _c = _this select 0;
	local _dir = _this select 1;
	local _R = _this select 2;
	local _objs = [];
	local _add = { // [class, [dx,dy], relDir, clearance]
		local _p = [_c, _dir, _this select 1] call dzfort_rel;
		if (!surfaceIsWater _p && {count (nearestObjects [_p, ["House"], _this select 3]) == 0}) then {
			_objs set [count _objs, [_this select 0, _p, _dir + (_this select 2), [0,0,1]]];
		};
	};
	// H-barrier ring with gates north and south
	local _n = round (2 * 3.14159 * _R / 8.6);
	for "_i" from 0 to (_n - 1) do {
		local _a = _i * (360 / _n);
		local _gate = (abs (((_a + 180) mod 360) - 180) < 12) || {abs (_a - 180) < 12};
		if (!_gate) then {["Land_HBarrier_large", [_R * sin _a, _R * cos _a], _a + 90, 5] call _add;};
	};
	// watchtowers on the diagonals, facing out
	{["Land_Fort_Watchtower", [(_R - 9) * sin _x, (_R - 9) * cos _x], _x + 180, 6] call _add;} forEach [45,135,225,315];
	// gun nests outside both gates
	["land_fortified_nest_big", [0, _R + 10], 0, 7] call _add;
	["land_fortified_nest_big", [0, -(_R + 10)], 180, 7] call _add;
	// barracks, sandbags, hedgehogs, wire
	["Land_Mil_Barracks_i", [-18, 4], 90, 9] call _add;
	["Land_Mil_Barracks_i", [18, 4], 270, 9] call _add;
	["Land_fort_bagfence_round", [0, 14], 0, 3] call _add;
	["Land_fort_bagfence_round", [0, -14], 180, 3] call _add;
	["Land_fort_artillery_nest", [0, -2], 0, 8] call _add;
	{["Hhedgehog_concreteBig", [_x, _R + 22], 0, 3] call _add; ["Hhedgehog_concreteBig", [_x, -(_R + 22)], 0, 3] call _add;} forEach [-8,0,8];
	{["MAP_Barbedwire", [_x, _R + 5], 0, 3] call _add; ["MAP_Barbedwire", [_x, -(_R + 5)], 0, 3] call _add;} forEach [-20,20];
	_objs
};
