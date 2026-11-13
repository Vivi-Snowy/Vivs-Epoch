/*
	DZ Activities (server side): treasure hunts, warlord bounties and personal contracts.
	Rewards are paid in coins straight to your wallet. Uses helpers from dz_factions.sqf.
*/
#define DZA_TREASURE_FIRST 600       // seconds after start before the first treasure hunt
#define DZA_TREASURE_EVERY 2400      // seconds between treasure hunts
#define DZA_TREASURE_TIMEOUT 2400    // a hunt expires after this long
#define DZA_TREASURE_REWARD 3000     // coins for the finder
#define DZA_WARLORD_FIRST 1200
#define DZA_WARLORD_EVERY 3600
#define DZA_WARLORD_TIMEOUT 3000
#define DZA_WARLORD_REWARD 8000
#define DZA_CONTRACT_TIME 1800       // seconds to finish a contract
#define DZA_CONTRACT_GAP 120         // seconds between contracts

waitUntil {uiSleep 5; !isNil "dzf_spawnGroup" && {!isNil "dzf_towns"}};
uiSleep 30;
diag_log "DZ ACTIVITIES: starting";

dza_pay = { // [player, coins, reason]
	local _p = _this select 0;
	if (isNull _p || {!alive _p}) exitWith {};
	_p setVariable ["cashMoney", (_p getVariable ["cashMoney",0]) + (_this select 1), true];
	[_p, "REWARD", format ["+%1 coins - %2", _this select 1, _this select 2], "#FFD700"] call dzf_huntPopup;
};
dza_flatWeapons = [];
{if (typeName _x == "ARRAY") then {dza_flatWeapons = dza_flatWeapons + _x;} else {dza_flatWeapons set [count dza_flatWeapons, _x];};} forEach WAI_RandomWeapon;
dza_fillCrate = { // [crate, weapons, mags per weapon, extra items]
	local _c = _this select 0;
	clearWeaponCargoGlobal _c; clearMagazineCargoGlobal _c;
	for "_i" from 1 to (_this select 1) do {
		local _w = dza_flatWeapons call BIS_fnc_selectRandom;
		if (isClass (configFile >> "CfgWeapons" >> _w)) then {
			_c addWeaponCargoGlobal [_w, 1];
			local _m = _w call WAI_FindAmmo;
			if (_m != "") then {_c addMagazineCargoGlobal [_m, _this select 2];};
		};
	};
	{_c addMagazineCargoGlobal [_x, 1];} forEach (_this select 3);
	_c setVariable ["permaLoot", true];
};
dza_gems = ["ItemTopaz","ItemObsidian","ItemSapphire","ItemAmethyst","ItemEmerald","ItemCitrine","ItemRuby"];
dza_medical = ["ItemBloodbag","ItemMorphine","ItemEpinephrine","ItemAntibiotic","ItemPainkiller","ItemBandage","ItemBandage"];

// ---------------- treasure hunts ----------------
dza_treasure = []; // [pos, marker, start]
dza_nextTreasure = diag_tickTime + DZA_TREASURE_FIRST;
dza_startTreasure = {
	local _pos = [[4600,4800,0], 300, 4300] call dzf_landPos; // Lingor: anywhere on the mainland
	if (count _pos == 0) exitWith {};
	local _a = random 360; local _off = random 200;
	local _mpos = [(_pos select 0) + _off * sin _a, (_pos select 1) + _off * cos _a, 0];
	local _m = createMarker [format ["dza_treasure_%1", round diag_tickTime], _mpos];
	_m setMarkerShape "ELLIPSE"; _m setMarkerSize [280,280]; _m setMarkerColor "ColorYellow"; _m setMarkerBrush "Solid"; _m setMarkerAlpha 0.35;
	local _t = createMarker [format ["dza_treasuret_%1", round diag_tickTime], _mpos];
	_t setMarkerShape "ICON"; _t setMarkerType "mil_unknown"; _t setMarkerColor "ColorYellow"; _t setMarkerText "Treasure Hunt";
	dza_treasure = [_pos, [_m,_t], diag_tickTime];
	["TREASURE HUNT", format ["A stash is buried somewhere inside the yellow circle near %1. Walk over the exact spot to dig it up! (+%2 coins)", _mpos call dz_nearTown, DZA_TREASURE_REWARD], "#FFD700"] call dz_sendPopup;
	diag_log format ["DZ ACTIVITIES: treasure buried at %1", _pos];
};
dza_checkTreasure = {
	if (count dza_treasure == 0) exitWith {};
	local _pos = dza_treasure select 0;
	local _finder = objNull;
	{if ((_x distance _pos) < 12 && {vehicle _x == _x}) exitWith {_finder = _x;};} forEach (call dzf_players);
	if (!isNull _finder) exitWith {
		local _c = createVehicle [WAI_CrateMd call BIS_fnc_selectRandom, _pos, [], 0, "CAN_COLLIDE"];
		[_c, 3, 4, [dza_gems call BIS_fnc_selectRandom, dza_gems call BIS_fnc_selectRandom] + [dza_medical call BIS_fnc_selectRandom, dza_medical call BIS_fnc_selectRandom]] call dza_fillCrate;
		"SmokeShellYellow" createVehicle [(_pos select 0), (_pos select 1) + 2, 0];
		{deleteMarker _x;} forEach (dza_treasure select 1);
		dza_treasure = [];
		["TREASURE FOUND", format ["%1 dug up the stash!", name _finder], "#FFD700"] call dz_sendPopup;
		[_finder, DZA_TREASURE_REWARD, "treasure hunt"] call dza_pay;
	};
	if ((diag_tickTime - (dza_treasure select 2)) > DZA_TREASURE_TIMEOUT) then {
		{deleteMarker _x;} forEach (dza_treasure select 1);
		dza_treasure = [];
		["TREASURE LOST", "Nobody found the stash in time. Another one will be buried soon.", "#AAAAAA"] call dz_sendPopup;
	};
};

// ---------------- warlord bounty ----------------
dza_warlord = []; // [group, boss, markers, start]
dza_nextWarlord = diag_tickTime + DZA_WARLORD_FIRST;
dza_warlordNames = ["Ramon 'El Carnicero' Vega","Mad Dog Ortega","Diego 'Fantasma' Cruz","Big Hector","The Priest of San Arulco","Rojo Rabante","Baron Zelaya"];
dza_startWarlord = {
	local _town = [];
	for "_t" from 1 to 20 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzf_inSafeZone) && {(_p call dzf_nearestPlayerDist) > 700}) exitWith {_town = _p;};
	};
	if (count _town == 0) exitWith {};
	local _name = dza_warlordNames call BIS_fnc_selectRandom;
	local _grp = ["Bandits", _town, 7] call dzf_spawnGroup;
	[_grp, _town, 120] call dzf_patrolArea;
	local _boss = leader _grp;
	removeAllWeapons _boss;
	_boss addMagazine "100Rnd_762x54_PK"; _boss addMagazine "100Rnd_762x54_PK"; _boss addMagazine "100Rnd_762x54_PK";
	_boss addWeapon "PKM_DZ"; _boss selectWeapon "PKM_DZ";
	{_boss setSkill [_x select 0, _x select 1];} forEach WAI_SkillExtreme;
	_boss setVariable ["dzf_humanity", 200];
	_boss setVariable ["dza_name", _name];
	_boss addMagazine (dza_gems call BIS_fnc_selectRandom);
	_boss addMagazine (dza_gems call BIS_fnc_selectRandom);
	_boss addEventHandler ["Killed", {
		local _b = _this select 0; local _k = _this select 1;
		dza_warlordKilledBy = if (isPlayer _k) then {_k} else {objNull};
		dza_warlordDeadAt = getPosATL _b;
	}];
	local _m = createMarker [format ["dza_warlord_%1", round diag_tickTime], _town];
	_m setMarkerShape "ELLIPSE"; _m setMarkerSize [180,180]; _m setMarkerColor "ColorRed"; _m setMarkerBrush "Solid"; _m setMarkerAlpha 0.35;
	local _t = createMarker [format ["dza_warlordt_%1", round diag_tickTime], _town];
	_t setMarkerShape "ICON"; _t setMarkerType "mil_objective"; _t setMarkerColor "ColorRed"; _t setMarkerText format ["BOUNTY: %1", _name];
	dza_warlordDeadAt = nil; dza_warlordKilledBy = nil;
	dza_warlord = [_grp, _boss, [_m,_t], diag_tickTime, _name];
	["BOUNTY POSTED", format ["Warlord %1 and his gang have taken %2. Kill him for %3 coins!", _name, _town call dz_nearTown, DZA_WARLORD_REWARD], "#FF3333"] call dz_sendPopup;
	diag_log format ["DZ ACTIVITIES: warlord %1 at %2", _name, mapGridPosition _town];
};
dza_checkWarlord = {
	if (count dza_warlord == 0) exitWith {};
	local _name = dza_warlord select 4;
	if (!isNil "dza_warlordDeadAt") exitWith {
		{deleteMarker _x;} forEach (dza_warlord select 2);
		local _k = dza_warlordKilledBy;
		local _c = createVehicle [WAI_CrateLg call BIS_fnc_selectRandom, dza_warlordDeadAt, [], 3, "NONE"];
		[_c, 5, 5, dza_gems + [dza_medical call BIS_fnc_selectRandom]] call dza_fillCrate;
		if (!isNull _k) then {
			["BOUNTY CLAIMED", format ["%1 killed the warlord %2! His war chest is by his body.", name _k, _name], "#33CC33"] call dz_sendPopup;
			[_k, DZA_WARLORD_REWARD, "warlord bounty"] call dza_pay;
		} else {
			["WARLORD DEAD", format ["%1 is dead - his war chest is up for grabs.", _name], "#33CC33"] call dz_sendPopup;
		};
		dza_warlord = []; dza_warlordDeadAt = nil;
	};
	if ((diag_tickTime - (dza_warlord select 3)) > DZA_WARLORD_TIMEOUT && {((getPosATL (dza_warlord select 1)) call dzf_nearestPlayerDist) > 800}) then {
		{deleteMarker _x;} forEach (dza_warlord select 2);
		(dza_warlord select 0) call dzf_deleteGroup;
		dza_warlord = [];
		["BOUNTY EXPIRED", format ["%1 has moved on. A new bounty will be posted soon.", _name], "#AAAAAA"] call dz_sendPopup;
	};
};

// ---------------- personal contracts ----------------
dza_contracts = []; // [uid, player, type, target, baseline, reward, start, text, marker]
dza_contractGap = []; // [uid, nextTime]
dza_newContract = {
	local _p = _this;
	local _type = ["zombies","zombies","bandits","delivery"] call BIS_fnc_selectRandom;
	local _c = [];
	call {
		if (_type == "zombies") exitWith {
			local _n = 15 + (floor random 4) * 5;
			_c = [getPlayerUID _p, _p, "zombies", _n, _p getVariable ["zombieKills",0], _n * 120, diag_tickTime, format ["Zombie cull: kill %1 zombies", _n], ""];
		};
		if (_type == "bandits") exitWith {
			local _n = 3 + floor random 4;
			_c = [getPlayerUID _p, _p, "bandits", _n, _p getVariable ["banditKills",0], _n * 800, diag_tickTime, format ["Hit job: kill %1 hostile AI", _n], ""];
		};
		local _dest = [];
		for "_t" from 1 to 20 do {
			local _q = dzf_towns call BIS_fnc_selectRandom;
			local _d = _q distance _p;
			if (_d > 1200 && {_d < 4500} && {!(_q call dzf_inSafeZone)}) exitWith {_dest = _q;};
		};
		if (count _dest == 0) exitWith {};
		local _m = createMarker [format ["dza_contract_%1", round diag_tickTime], _dest];
		_m setMarkerShape "ICON"; _m setMarkerType "mil_pickup"; _m setMarkerColor "ColorBlue"; _m setMarkerText "Contract: supply run";
		_c = [getPlayerUID _p, _p, "delivery", _dest, 0, 1500 + round ((_dest distance _p) / 2), diag_tickTime, format ["Supply run: reach %1 (blue marker)", _dest call dz_nearTown], _m];
	};
	if (count _c == 0) exitWith {};
	dza_contracts set [count dza_contracts, _c];
	_p setVariable ["dz_contract", (_c select 7), true];
	[_p, "NEW CONTRACT", format ["%1 within %2 minutes. Reward: %3 coins.", _c select 7, DZA_CONTRACT_TIME / 60, _c select 5], "#4499FF"] call dzf_huntPopup;
};
dza_checkContracts = {
	// hand out contracts
	{
		local _p = _x; local _uid = getPlayerUID _p;
		local _has = false;
		{if ((_x select 0) == _uid) exitWith {_has = true;};} forEach dza_contracts;
		if (!_has) then {
			local _gi = -1;
			{if ((_x select 0) == _uid) exitWith {_gi = _forEachIndex;};} forEach dza_contractGap;
			if (_gi == -1) then {dza_contractGap set [count dza_contractGap, [_uid, diag_tickTime + DZA_CONTRACT_GAP]];} else {
				if (diag_tickTime > ((dza_contractGap select _gi) select 1) && {!((getPosATL _p) call dzf_inSafeZone) || {true}}) then {
					_p call dza_newContract;
					(dza_contractGap select _gi) set [1, diag_tickTime + DZA_CONTRACT_GAP];
				};
			};
		};
	} forEach (call dzf_players);
	// progress
	local _keep = [];
	{
		local _c = _x; local _p = _c select 1; local _done = false; local _fail = false; local _prog = "";
		if (isNull _p || {!alive _p} || {!isPlayer _p}) then {_fail = true;} else {
			call {
				if ((_c select 2) == "zombies") exitWith {
					local _have = (_p getVariable ["zombieKills",0]) - (_c select 4);
					_prog = format ["%1 (%2/%3)", _c select 7, _have min (_c select 3), _c select 3];
					if (_have >= (_c select 3)) then {_done = true;};
				};
				if ((_c select 2) == "bandits") exitWith {
					local _have = (_p getVariable ["banditKills",0]) - (_c select 4);
					_prog = format ["%1 (%2/%3)", _c select 7, _have min (_c select 3), _c select 3];
					if (_have >= (_c select 3)) then {_done = true;};
				};
				local _d = round (_p distance (_c select 3));
				_prog = format ["%1 (%2m)", _c select 7, _d];
				if (_d < 60) then {_done = true;};
			};
			if ((diag_tickTime - (_c select 6)) > DZA_CONTRACT_TIME) then {_fail = true;};
		};
		if (_done) then {
			[_p, _c select 5, "contract complete"] call dza_pay;
			_p setVariable ["dz_contract", nil, true];
		} else {
			if (_fail) then {
				if (!isNull _p && {alive _p}) then {[_p, "CONTRACT FAILED", "Out of time. A new contract is on its way.", "#AAAAAA"] call dzf_huntPopup; _p setVariable ["dz_contract", nil, true];};
			} else {
				_p setVariable ["dz_contract", _prog, true];
				_keep set [count _keep, _c];
			};
		};
		if ((_done || _fail) && {(_c select 8) != ""}) then {deleteMarker (_c select 8);};
	} forEach dza_contracts;
	dza_contracts = _keep;
};

// ---------------- loop ----------------
while {true} do {
	if (count dza_treasure == 0 && {diag_tickTime > dza_nextTreasure}) then {call dza_startTreasure; dza_nextTreasure = diag_tickTime + DZA_TREASURE_EVERY;};
	if (count dza_warlord == 0 && {diag_tickTime > dza_nextWarlord}) then {call dza_startWarlord; dza_nextWarlord = diag_tickTime + DZA_WARLORD_EVERY;};
	call dza_checkTreasure;
	call dza_checkWarlord;
	call dza_checkContracts;
	uiSleep 5;
};
