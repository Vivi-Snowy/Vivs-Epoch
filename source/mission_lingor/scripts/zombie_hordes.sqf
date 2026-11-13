/*
	Zombie hordes (client side).
	Every 20-35 minutes a horde of 12-22 zombies forms 100-140m away from you and comes your way.
	Not while you're in a safe zone, in a vehicle or inside the first 10 minutes after spawning.
*/
if (isDedicated) exitWith {};
waitUntil {uiSleep 2; !isNil "Dayz_loginCompleted"};

dzh_inSafe = {
	local _in = false;
	{if ((player distance (_x select 0)) < ((_x select 1) + 100)) exitWith {_in = true;};} forEach DZE_SafeZonePosArray;
	_in
};
dzh_dirName = {
	local _d = _this;
	if (_d < 0) then {_d = _d + 360;};
	["north","north-east","east","south-east","south","south-west","west","north-west"] select (round (_d / 45) mod 8)
};

uiSleep 600;
while {true} do {
	if (alive player && {vehicle player == player} && {!(call dzh_inSafe)} && {!dayz_inside || {random 1 < 0.5}}) then {
		local _dir = random 360;
		local _dist = 100 + random 40;
		local _center = [(getPosATL player select 0) + _dist * sin _dir, (getPosATL player select 1) + _dist * cos _dir, 0];
		if (!surfaceIsWater _center) then {
			local _count = 12 + floor random 11;
			for "_i" from 1 to _count do {
				local _p = [(_center select 0) + random 24 - 12, (_center select 1) + random 24 - 12, 0];
				if (!surfaceIsWater _p) then {[_p, true, [], true] call zombie_generate;};
			};
			uiSleep 1;
			local _horde = _center nearEntities ["zZombie_Base", 35];
			{_x moveTo (getPosATL player);} forEach _horde;
			local _m = createMarkerLocal [format ["dzh_%1", round diag_tickTime], _center];
			_m setMarkerShapeLocal "ICON"; _m setMarkerTypeLocal "mil_warning"; _m setMarkerColorLocal "ColorRed"; _m setMarkerTextLocal "Zombie horde";
			[ "ZOMBIE HORDE", format ["A horde of %1 infected is closing in from the %2!", count _horde, _dir call dzh_dirName], "#CC3333"] spawn dz_showPopup;
			// keep pushing them towards you for a while
			for "_t" from 1 to 12 do {
				uiSleep 10;
				{if (alive _x) then {_x moveTo (getPosATL player);};} forEach _horde;
			};
			deleteMarkerLocal _m;
		};
	};
	uiSleep (1200 + random 900);
};
