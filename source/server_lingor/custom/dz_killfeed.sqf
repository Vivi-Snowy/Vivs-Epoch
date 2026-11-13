/*
	Classic kill feed (server side).
	Every kill involving a player or a survivor NPC shows up in the top-left kill feed on everyone's screen,
	in the classic Epoch style:  Victim  <weapon icon>  Killer (distance m)  - the same feed Epoch uses for
	player deaths (DZE_DeathMsgDynamicText). Replaces the old centre-screen "AI Kill +50 Humanity" pop-ups.
*/
waitUntil {uiSleep 5; !isNil "dzf_players"};

dzk_name = {
	local _u = _this;
	if (isNull _u) exitWith {"Unknown"};
	if (isPlayer _u) exitWith {name _u};
	local _n = _u getVariable ["dzs_name", ""];
	if (_n != "") exitWith {_n};
	local _f = _u getVariable ["dzf_faction", ""];
	if (_f != "") exitWith {
		call {
			if (_f == "Bandits") exitWith {"Bandit"};
			if (_f == "Military") exitWith {"Soldier"};
			if (_f == "Stalkers") exitWith {"Stalker"};
			if (_f == "Hunters") exitWith {"Hunter"};
			if (_f == "Survivors") exitWith {"Survivor"};
			_f
		}
	};
	if (_u getVariable ["Bandit", false]) exitWith {"Bandit"};
	if (_u getVariable ["Hero", false]) exitWith {"Hero"};
	if (_u isKindOf "zZombie_Base") exitWith {"Zombie"};
	"AI"
};
dzk_onKilled = {
	local _u = _this select 0; local _k = _this select 1;
	if (isNull _k) exitWith {};
	// killed by a vehicle's gun: credit whoever is commanding it
	if !(_k isKindOf "Man") then {local _c = gunner _k; if (isNull _c) then {_c = driver _k;}; if (!isNull _c) then {_k = _c;};};
	if (_k == _u) exitWith {};
	local _npc = {!isNil {_this getVariable "dzs_name"}};
	if !(isPlayer _k || {_u call _npc} || {_k call _npc}) exitWith {};
	local _w = if (vehicle _k != _k) then {typeOf (vehicle _k)} else {currentWeapon _k};
	if (_w == "") then {_w = primaryWeapon _k;};
	if (_w == "") then {_w = "Throw";};
	dz_killFeedPV = [_u call dzk_name, _k call dzk_name, _w, round (_u distance _k)];
	publicVariable "dz_killFeedPV";
};

while {true} do {
	{
		if (!isPlayer _x && {local _x} && {!(_x getVariable ["dzk", false])}) then {
			_x setVariable ["dzk", true];
			_x addEventHandler ["Killed", {_this call dzk_onKilled;}];
		};
	} forEach allUnits;
	uiSleep 5;
};
