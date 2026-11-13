/*
	Event pop-ups (client side).
	Shows a banner at the top of the screen when the server starts an event
	(supply drops, heli crashes, infected camps), and a summary of active events when you log in.
	Event locations are also marked on your map with a warning triangle.
*/
if (isDedicated) exitWith {};

dz_showPopup = {
	local _title = _this select 0;
	local _msg = _this select 1;
	local _color = _this select 2;
	// classic: just a chat line, no big text on screen
	systemChat format ["[%1] %2", _title, _msg];
};

"dz_eventPopup" addPublicVariableEventHandler {(_this select 1) spawn dz_showPopup;};
"dz_fakeChat" addPublicVariableEventHandler {systemChat (_this select 1);}; // survivor NPC chat / connect / death lines
// classic top-left kill feed for AI / survivor NPC kills: [victim, killer, weapon class, distance]
"dz_killFeedPV" addPublicVariableEventHandler {
	local _m = _this select 1;
	local _w = _m select 2;
	local _root = call {
		if (isClass (configFile >> "CfgWeapons" >> _w)) exitWith {"CfgWeapons"};
		if (isClass (configFile >> "CfgVehicles" >> _w)) exitWith {"CfgVehicles"};
		if (isClass (configFile >> "CfgMagazines" >> _w)) exitWith {"CfgMagazines"};
		""
	};
	local _icon = if (_root == "") then {""} else {getText (configFile >> _root >> _w >> "picture")};
	if (_icon == "") then {_icon = getText (configFile >> "CfgWeapons" >> "M9_DZ" >> "picture");};
	["killed", _m select 0, _m select 1, _w, _m select 3, _icon] call dayz_killFeed;
};

// Summary of what's already going on when you join
waitUntil {uiSleep 1; !isNil "Dayz_loginCompleted"};
uiSleep 12;
if (!isNil "dz_activeEvents" && {count dz_activeEvents > 0}) then {
	local _list = "";
	{
		if (_forEachIndex < 4) then {_list = _list + _x + "<br/>";};
	} forEach dz_activeEvents;
	if (count dz_activeEvents > 4) then {_list = _list + format ["...and %1 more - check your map", (count dz_activeEvents) - 4];};
	[format ["%1 ACTIVE EVENTS", count dz_activeEvents], _list, "#FFCC33", false] spawn dz_showPopup;
	{systemChat format ["[EVENT] %1", _x];} forEach dz_activeEvents;
};
