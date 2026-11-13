#include "\z\addons\dayz_server\compile\server_toggle_debug.hpp"

waitUntil {!isNil "bis_fnc_init"};

BIS_MPF_remoteExecutionServer = {
	if ((_this select 1) select 2 == "JIPrequest") then {
		[nil,(_this select 1) select 0,"loc",rJIPEXEC,[any,any,"per","execVM","ca\Modules\Functions\init.sqf"]] call RE;
	};
};

call compile preprocessFileLineNumbers "\z\addons\dayz_code\util\compile.sqf";
call compile preprocessFileLineNumbers "\z\addons\dayz_code\loot\init.sqf";

BIS_Effects_Burn = {};
dayz_disconnectPlayers = [];
dayz_serverKey = [59]; //makes sure client is kicked by publicvariableval.txt if they try to send it
for "_i" from 1 to 12 do {
	dayz_serverKey set [_i, ceil(random 128)];
};
dayz_serverKey = toString dayz_serverKey;
server_playerLogin = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_playerLogin.sqf";
server_playerSetup = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_playerSetup.sqf";
server_onPlayerDisconnect = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_onPlayerDisconnect.sqf";
call compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\updateObject_functions.sqf";
server_updateObject = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_updateObject.sqf";
server_setHitpoints = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_setHitpoints.sqf";
server_playerDied = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_playerDied.sqf";
server_publishObj = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_publishObject.sqf";	//Creates the object in DB
server_deleteObj = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_deleteObj.sqf"; 	//Removes the object from the DB
server_deleteObjDirect = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_deleteObjDirect.sqf"; 	//Removes the object from the DB, NO AUTH, ONLY CALL FROM SERVER, NO PV ACCESS
server_playerSync = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_playerSync.sqf";
zombie_findOwner = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\zombie_findOwner.sqf";
//server_Wildgenerate = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\zombie_Wildgenerate.sqf";
base_fireMonitor = compile preprocessFileLineNumbers "\z\addons\dayz_code\system\fire_monitor.sqf";
spawnComposition = compile preprocessFileLineNumbers "ca\modules\dyno\data\scripts\objectMapper.sqf"; //"\z\addons\dayz_code\compile\object_mapper.sqf";
server_sendToClient = compile preprocessFileLineNumbers "\z\addons\dayz_server\eventHandlers\server_sendToClient.sqf";
server_verifySender = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_verifySender.sqf";

// EPOCH ADDITIONS
server_swapObject = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_swapObject.sqf"; //Used to downgrade and upgrade Epoch buildables
server_publishVeh = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_publishVehicle.sqf"; //Used to spawn random vehicles by server
server_publishVeh2 = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_publishVehicle2.sqf"; //Used to purchase vehicles at traders
if (DZE_VehicleKey_Changer) then {
	server_publishVeh3 = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_publishVehicle3_vkc.sqf"; //Used for car upgrades
} else {
	server_publishVeh3 = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_publishVehicle3.sqf"; //Used for car upgrades
};
server_tradeObj = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_tradeObject.sqf";
server_deaths = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_playerDeaths.sqf";
server_maintainArea = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_maintainArea.sqf";
server_checkIfTowed = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_checkIfTowed.sqf";
server_handleSafeGear = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_handleSafeGear.sqf";
server_spawnTraders = compile preprocessFile "\z\addons\dayz_server\compile\server_spawnTraders.sqf";
server_updateGroup = compile preprocessFileLineNumbers "\z\addons\dayz_code\groups\server_updateGroup.sqf";
server_changeCode = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\server_changeCode.sqf";

spawn_ammosupply = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\spawn_ammosupply.sqf";
spawn_mineveins = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\spawn_mineveins.sqf";
spawn_roadblocks = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\spawn_roadblocks.sqf";
spawn_vehicles = compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\spawn_vehicles.sqf";

if (DZE_Virtual_Garage) then {
	call compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\garage\init.sqf";
};

vehicle_handleServerKilled = {
	local _unit = _this select 0;

	[_unit,"killed",false,false,"SERVER",dayz_serverKey] call server_updateObject;
	_unit removeAllMPEventHandlers "MPKilled";
	_unit removeAllEventHandlers "Killed";
	_unit removeAllEventHandlers "HandleDamage";
	_unit removeAllEventHandlers "GetIn";
	_unit removeAllEventHandlers "GetOut";
};

check_publishobject = {
	local _object = _this select 0;
	local _playername = _this select 1;
	local _allowed = false;	

	#ifdef OBJECT_DEBUG
		diag_log format["DEBUG: Checking if Object: %1 is allowed, published by %2",_object,_playername];
	#endif

	if ((typeOf _object) in DayZ_SafeObjects) then {		
		_allowed = true;
	};

	#ifdef OBJECT_DEBUG
		local _saveObject = "DayZ_SafeObjects";
		diag_log format["DEBUG: Object: %1 published by %2 is allowed by %3",_object,_playername,_saveObject];
	#endif

	_allowed
};

server_hiveWrite = {
	//diag_log ("ATTEMPT WRITE: " + _this);
	local _data = "HiveExt" callExtension _this;
	//diag_log ("WRITE: " +str(_data));
};

server_hiveReadWrite = {
	local _key = _this;
	//diag_log ("ATTEMPT READ/WRITE: " + _key);
	local _data = "HiveExt" callExtension _key;
	//diag_log ("READ/WRITE: " +str(_data));
	local _resultArray = call compile str formatText["%1", _data];
	if (isNil "_resultArray") then {_resultArray = "HIVE CONNECTION ERROR";};
	_resultArray
};

onPlayerDisconnected "[_uid,_name] call server_onPlayerDisconnect;";

server_getStatsDiff = {
	local _player = _this select 0;
	local _playerUID = _this select 1;
	local _result = [];
	local _statsArray = missionNamespace getVariable _playerUID;
	local _new = 0;
	local _old = 0;

	if (isNil "_statsArray") exitWith {
		diag_log format["Server_getStatsDiff error: playerUID %1 not found on server",_playerUID];
		[0,0,0,0,0]
	};

	{
		_new = _player getVariable [_x,0];
		_old = _statsArray select _forEachIndex;
		_result set [_forEachIndex, (_new - _old)];
		_statsArray set [_forEachIndex, _new]; //updates original var too
	} forEach ["humanity","zombieKills","headShots","humanKills","banditKills"];

	#ifdef PLAYER_DEBUG
		diag_log format["Server_getStatsDiff - Object:%1 Diffs:%2 New:%3",_player,_result,_statsArray];
	#endif

	_result
};

//seems max is 19 digits
dayz_objectUID2 = {
	local _dir = _this select 0;
	local _time = round diag_tickTime;
	if (_time > 99999) then {_time = round(random 99999);}; //prevent overflow if server isn't restarted
	local _key = "";
	local _position = _this select 1;
	_key = format["%1%2%3%4", round(_time + abs(_position select 0)), round(_dir), round(abs(_position select 1)), _time];
	_key;
};

dayz_recordLogin = {
	local _key = format["CHILD:103:%1:%2:%3:",_this select 0,_this select 1,_this select 2];
	_key call server_hiveWrite;

	local _status = call {
		if ((_this select 2) == 0) exitwith { "CLIENT LOADED & PLAYING" };
		if ((_this select 2) == 1) exitwith { "LOGIN PUBLISHING, Location " +(_this select 4) };
		if ((_this select 2) == 2) exitwith { "LOGGING IN" };
		if ((_this select 2) == 3) exitwith { "LOGGED OUT, Location " +(_this select 4) };
	};

	local _name = if (typeName (_this select 3) == "ARRAY") then { toString (_this select 3) } else { _this select 3 };
	diag_log format["INFO - Player: %1(UID:%3/CID:%4) Status: %2",_name,_status,(_this select 0),(_this select 1)];
};

generate_new_damage = {
    local _damage = ((random(DynamicVehicleDamageHigh-DynamicVehicleDamageLow))+DynamicVehicleDamageLow) / 100;
	_damage
};

server_hiveReadWriteLarge = {
	local _key = _this;
	local _data = "HiveExt" callExtension _key;
	local _resultArray = call compile _data;
	_resultArray
};

// coor2str: convert position to a GPS coordinates
fa_coor2str = {
	local _pos = +(_this);
	if (count _pos < 1) then {
		_pos = [0,0];
	} else {
		if (count _pos < 2) then { _pos = [_pos select 0,0]; };
	};
	local _nearestCity = nearestLocations [_pos, ["NameCityCapital","NameCity","NameVillage","NameLocal"],1000];
	local _town = "Wilderness";
	if (count _nearestCity > 0) then {_town = text (_nearestCity select 0)};
	local _res = format["%1 [%2]", _town, mapGridPosition _pos];

	_res
};

// print player player PID and name. If name unknown then print UID.
fa_plr2str = {
	local _y = _this;
	local _res = "nobody";	
	if (!isNil "_y") then {
		local _name = _y getVariable ["bodyName", nil];
		if ((isNil "_name" OR {(_name == "")}) AND ({alive _y})) then { _name = name _y; };
		if (isNil "_name" OR {(_name == "")}) then { _name = "UID#"+(getPlayerUID _y); };
		_res = format["PID#%1(%2)", owner _y, _name ];
	};
	_res
};

array_reduceSize = {
	local _array1 = _this select 0;
	local _array = _array1 - ["Hatchet_Swing","Crowbar_Swing","Machete_Swing","Bat_Swing","BatBarbed_Swing","BatNails_Swing","Fishing_Swing","Sledge_Swing","CSGAS"];
	local _count = _this select 1;
	local _num = count _array;
	if (_num > _count) then {
		_array resize _count;
	};
	_array
};

// Precise base building 1.0.5
call compile preprocessFileLineNumbers "\z\addons\dayz_server\compile\kk_functions.sqf";
call compile preprocessFileLineNumbers "\z\addons\dayz_server\eventHandlers\server_eventHandler.sqf";
#include "mission_check.sqf"
call compile preprocessFileLineNumbers "\z\addons\dayz_server\WAI\init.sqf";
call compile preprocessFileLineNumbers "\z\addons\dayz_server\DZMS\DZMSInit.sqf";
call compile preprocessFileLineNumbers "\z\addons\dayz_server\custom\dz_claimveh.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_factions.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_restart.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_activities.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_bunker.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_living.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_survivors.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_killfeed.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_aibrain.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_world.sqf";
[] execVM "\z\addons\dayz_server\custom\dz_populate.sqf";

// ---- Event pop-ups + map markers (custom) ----
dz_activeEvents = [];
publicVariable "dz_activeEvents";
// map areas where the random server events (modules\event_init.sqf) must not spawn
dz_eventBlacklist = call {
	if (toLower worldName == "lingor") exitWith {[[[0,10240],[200,0]],[[0,200],[10240,0]],[[5950,7150],[6450,6600]],[[8700,5700],[10240,3300]],[[7800,9400],[10240,6400]]]};
	if (toLower worldName == "chernarus") exitWith {[[[0,16000],[1000,0]],[[0,16000],[16000,14580]]]};
	[]
};
dz_nearTown = {
	local _l = nearestLocations [_this, ["NameCityCapital","NameCity","NameVillage","NameLocal"], 2500];
	if (count _l > 0) then {text (_l select 0)} else {"the wilderness"}
};
dz_sendPopup = { // [title, message, colour]
	dz_eventPopup = _this;
	publicVariable "dz_eventPopup";
};
dz_eventSpot = { // [position, label, markerColour, lifetimeSeconds] -> returns "label near Town (grid)"
	local _pos = _this select 0;
	local _label = _this select 1;
	local _life = _this select 3;
	local _desc = format ["%1 near %2 (%3)", _label, _pos call dz_nearTown, mapGridPosition _pos];
	local _name = format ["dzEvt_%1_%2", round diag_tickTime, floor random 999999];
	local _m = createMarker [_name, _pos];
	_m setMarkerShape "ICON";
	_m setMarkerType "mil_warning";
	_m setMarkerColor (_this select 2);
	_m setMarkerText _label;
	dz_activeEvents set [count dz_activeEvents, _desc];
	publicVariable "dz_activeEvents";
	[_name, _desc, _life] spawn {
		uiSleep (_this select 2);
		deleteMarker (_this select 0);
		dz_activeEvents = dz_activeEvents - [_this select 1];
		publicVariable "dz_activeEvents";
	};
	_desc
};

// ---- Starter kit (custom) ----
"dz_starterKitReq" addPublicVariableEventHandler {
	local _p = _this select 1;
	if (isNull _p || {!alive _p}) exitWith {};
	local _pos = _p modelToWorld [0, 2.5, 0];
	_pos set [2, 0];
	local _c = createVehicle ["DZ_AmmoBoxMedium1US", _pos, [], 0, "CAN_COLLIDE"];
	clearWeaponCargoGlobal _c; clearMagazineCargoGlobal _c;
	{_c addMagazineCargoGlobal _x;} forEach [
		["plot_pole_kit",1],["ItemWoodFloor",6],["ItemWoodWall",8],["ItemWoodWallWithDoorLg",1],["ItemWoodLadder",1],
		["ItemComboLock",1],["ItemLockbox",1],["PartPlywoodPack",6],["PartPlankPack",6],["CinderBlocks",4],["MortarBucket",2],
		["ItemBandage",4],["ItemBloodbag",1],["FoodCanBakedBeans",2],["ItemWaterbottle",2]
	];
	{_c addWeaponCargoGlobal [_x, 1];} forEach ["ItemHatchet","ItemEtool","ItemCrowbar","ItemSledge"];
	_c setVariable ["permaLoot", true];
	_p setVariable ["cashMoney", (_p getVariable ["cashMoney",0]) + 2000, true];
	dz_eventPopup = ["STARTER KIT", "Plot pole, building materials, a lockbox and tools are in the crate next to you. +2000 coins!", "#33CC33"];
	(owner _p) publicVariableClient "dz_eventPopup";
	diag_log format ["DZ STARTER KIT: given to %1", name _p];
};
