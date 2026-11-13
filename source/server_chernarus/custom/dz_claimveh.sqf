/*
	Captured AI vehicles become real, saved vehicles (server side).
	Faction patrol vehicles, convoy trucks and landed patrol helicopters are spawned outside the database.
	The first time a player gets in one, it is written to the database (like WICKED AI mission vehicles),
	so it survives restarts and anything stored in it - gear or coins - is saved too.
	Before this, coins put into such a vehicle were lost at the next restart.
*/
dzv_addClaim = { // vehicle
	_this addEventHandler ["GetIn", {_this call dzv_onGetIn;}];
};
dzv_onGetIn = {
	local _veh = _this select 0; local _unit = _this select 2;
	if (!isPlayer _unit || {_veh getVariable ["dzv_saved", false]}) exitWith {};
	_veh setVariable ["dzv_saved", true, true];
	local _class = typeOf _veh;
	local _worldspace = [getDir _veh, getPosATL _veh];
	local _uid = _worldspace call dayz_objectUID2;
	local _hits = [];
	{
		local _hit = ([_veh, _x] call object_getHit) select 0;
		local _sel = getText (configFile >> "CfgVehicles" >> _class >> "HitPoints" >> _x >> "name");
		if (_hit > 0) then {_hits set [count _hits, [_sel, _hit]];};
	} count (_veh call vehicle_getHitpoints);
	format ["CHILD:308:%1:%2:%3:%4:%5:%6:%7:%8:%9:", dayZ_instance, _class, damage _veh, "0", _worldspace, [getWeaponCargo _veh, getMagazineCargo _veh, getBackpackCargo _veh], _hits, fuel _veh, _uid] call server_hiveWrite;
	local _result = (format ["CHILD:388:%1:", _uid]) call server_hiveReadWrite;
	if ((_result select 0) != "PASS") exitWith {
		_veh setVariable ["dzv_saved", false, true];
		diag_log format ["DZ CLAIM: could not save %1 (UID %2) to the database", _class, _uid];
	};
	_veh setVariable ["ObjectID", (_result select 1), true];
	_veh setVariable ["ObjectUID", _uid, true];
	_veh setVariable ["CharacterID", "0", true];
	_veh setVariable ["lastUpdate", diag_tickTime];
	_veh setVariable ["dzf_patrolVeh", nil, true];
	_veh call fnc_veh_ResetEH;
	PVDZE_veh_Init = _veh;
	publicVariable "PVDZE_veh_Init";
	dz_eventPopup = ["VEHICLE CLAIMED", format ["This %1 is yours now - it's saved, so it (and anything you store in it) survives restarts.", getText (configFile >> "CfgVehicles" >> _class >> "displayName")], "#33CC33"];
	(owner _unit) publicVariableClient "dz_eventPopup";
	diag_log format ["DZ CLAIM: %1 claimed %2, saved with ID %3", name _unit, _class, _result select 1];
};
