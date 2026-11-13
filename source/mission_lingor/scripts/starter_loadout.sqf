/*
	Humanity loadouts + one-time starter kit (client side).
	- Fresh spawns get a better primary weapon the higher their hero/bandit level.
	- "Claim Starter Kit" scroll action, once per player (remembered in your Arma profile):
	  a crate with a plot pole, building materials and a lockbox appears next to you,
	  2000 coins go into your wallet and you get 2 minutes of god mode.
*/
if (isDedicated) exitWith {};
waitUntil {uiSleep 1; !isNil "Dayz_loginCompleted"};

// ---------- humanity loadouts ----------
dzl_hero = [[50000,"Mk48_CCO_DZ",6],[35000,"RSASS_SD_DZ",8],[20000,"M4SPR_DZE",8],[10000,"M4A1_CCO_DZ",8],[5000,"G36C_DZ",7],[2500,"MP5_SD_DZ",6],[1000,"Winchester1866_DZ",6]];
dzl_bandit = [[-50000,"PKM_DZ",4],[-35000,"DMR_Gh_DZE",8],[-20000,"M4SPR_DZE",8],[-10000,"AK74_Kobra_DZ",8],[-5000,"G36C_DZ",7],[-2500,"MP5_DZ",6],[-1000,"Winchester1866_DZ",6]];

dzl_humanityLoadouts = false; // true = fresh spawns get a better gun the higher their hero/bandit level (off: spawn with just a map)
if (dzl_humanityLoadouts && {!isNil "freshSpawn"} && {freshSpawn == 2}) then {
	uiSleep 3;
	local _hum = player getVariable ["humanity", 0];
	local _pick = [];
	local _level = 0;
	if (_hum >= 0) then {
		{if (_hum >= (_x select 0)) exitWith {_pick = _x; _level = (count dzl_hero) - _forEachIndex;};} forEach dzl_hero;
	} else {
		{if (_hum <= (_x select 0)) exitWith {_pick = _x; _level = (count dzl_bandit) - _forEachIndex;};} forEach dzl_bandit;
	};
	if (count _pick > 0) then {
		local _w = _pick select 1;
		local _mags = getArray (configFile >> "CfgWeapons" >> _w >> "magazines");
		if (count _mags > 0) then {
			for "_i" from 1 to (_pick select 2) do {player addMagazine (_mags select 0);};
		};
		player addWeapon _w;
		player selectWeapon _w;
		systemChat format ["[LOADOUT] %1 level %2 - you spawned with a %3.", if (_hum >= 0) then {"Hero"} else {"Bandit"}, _level, getText (configFile >> "CfgWeapons" >> _w >> "displayName")];
	};
};

// ---------- starter kit ----------
local _claimed = false;
try {_claimed = profileNamespace getVariable ["dz_starterKitClaimed_lingor", false];} catch {};
if (!_claimed) then {
	dz_kitAction = player addAction ["<t color='#33CC33'>Claim Starter Kit</t>", "scripts\starter_claim.sqf", [], 6, false, true, "", "_this == _target"];
	systemChat "[STARTER KIT] Use the 'Claim Starter Kit' scroll action when you've picked a spot for your base. One per player!";
};
