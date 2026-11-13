local _mission = count WAI_MissionData - 1; // DO NOT CHANGE THIS LINE.

/*
	UN Outpost - rogue UN garrison on Green Mountain (custom).
*/

// Spawn the mission objects
[
	["Land_HBarrier_large",[3695.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3695.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3705.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3705.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3760.0,5965.0,0],90.0,[0,0,1]],
	["Land_HBarrier_large",[3690.0,5965.0,0],270.0,[0,0,1]],
	["Land_HBarrier_large",[3715.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3715.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3760.0,5975.0,0],90.0,[0,0,1]],
	["Land_HBarrier_large",[3690.0,5975.0,0],270.0,[0,0,1]],
	["Land_HBarrier_large",[3725.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3725.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3760.0,5985.0,0],90.0,[0,0,1]],
	["Land_HBarrier_large",[3690.0,5985.0,0],270.0,[0,0,1]],
	["Land_HBarrier_large",[3735.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3735.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3760.0,5995.0,0],90.0,[0,0,1]],
	["Land_HBarrier_large",[3690.0,5995.0,0],270.0,[0,0,1]],
	["Land_HBarrier_large",[3745.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3745.0,5950.0,0],180.0,[0,0,1]],
	["Land_HBarrier_large",[3760.0,6005.0,0],90.0,[0,0,1]],
	["Land_HBarrier_large",[3690.0,6005.0,0],270.0,[0,0,1]],
	["Land_HBarrier_large",[3755.0,6020.0,0],0.0,[0,0,1]],
	["Land_HBarrier_large",[3755.0,5950.0,0],180.0,[0,0,1]],
	["Land_Fort_Watchtower",[3755.0,6015.0,0],45.0,[0,0,1]],
	["Land_Fort_Watchtower",[3695.0,6015.0,0],-45.0,[0,0,1]],
	["Land_Fort_Watchtower",[3755.0,5955.0,0],135.0,[0,0,1]],
	["Land_Fort_Watchtower",[3695.0,5955.0,0],-135.0,[0,0,1]],
	["land_fortified_nest_big",[3725.0,5937.0,0],180.0,[0,0,1]],
	["land_fortified_nest_big",[3725.0,6033.0,0],0.0,[0,0,1]],
	["Land_fort_artillery_nest",[3737.0,5985.0,0],90.0,[0,0,1]],
	["Land_fort_bagfence_round",[3713.0,5993.0,0],0.0,[0,0,1]],
	["Land_fort_bagfence_round",[3713.0,5977.0,0],180.0,[0,0,1]],
	["Land_Mil_Barracks_i",[3707.0,6000.0,0],90.0,[0,0,1]],
	["Land_Mil_Barracks_i",[3707.0,5970.0,0],90.0,[0,0,1]],
	["Hhedgehog_concreteBig",[3725.0,5925.0,0],0.0,[0,0,1]],
	["Hhedgehog_concreteBig",[3733.0,5925.0,0],0.0,[0,0,1]],
	["Hhedgehog_concreteBig",[3717.0,5925.0,0],0.0,[0,0,1]],
	["MAP_Barbedwire",[3745.0,5943.0,0],0.0,[0,0,1]],
	["MAP_Barbedwire",[3705.0,5943.0,0],0.0,[0,0,1]],
	["MAP_Barbedwire",[3745.0,6027.0,0],0.0,[0,0,1]],
	["MAP_Barbedwire",[3705.0,6027.0,0],0.0,[0,0,1]]
] call WAI_SpawnStaticObjects;

local _aiType = "Bandit"; // "Bandit" or "Hero" - determines the humanity and kill rewards.
local _position = [3725.0,5985.0]; // Select a position on the map for your mission. This should be the mission center. Just use the X and Y coordinates.
local _name = "UN Outpost (rogue peacekeepers)"; // Used in marker text. If you know how to make localized strings and add them to a mission side string table then you can do it.
local _autoClaim = false; // Enable the auto-claim feature for this static location. Markers must also be enabled.
local _borderMarker = true; // This places a border marker on the perimeter defined by the _triggerDistance variable. It is also enabled with auto-claim.
local _triggerDistance = 900; // This is how close in meters a player must be to spawn the AI. Also used for the auto-claim.
local _enableRespawn = true; // Allow an AI group to respawn after all members have been killed.
local _respawnTimer = 30; // The amount of time in minutes before an AI group is allowed to respawn.
local _aiCaching = false; // If players are not near then the behavioral FSM, targeting, and movement is disabled and the AI objects are hidden. Known to improve server performance.
local _enableMarkers = true; // Define the parameters below to place a custom JIP compatible marker on your mission.
local _markerColor = "ColorBlue"; // Color of the mission marker. https://community.bistudio.com/wiki/Arma_3:_CfgMarkerColors
local _markerSize = [150,150]; // Sets the size of the marker. https://community.bistudio.com/wiki/setMarkerSize
local _markerShape = "RECTANGLE"; // https://community.bistudio.com/wiki/setMarkerShape
local _markerBrush = "Solid"; // Fill texture for the marker. https://community.bistudio.com/wiki/setMarkerBrush
local _markerAlpha = 0.4; // From 0 to 1. Sets the marker transparency. https://community.bistudio.com/wiki/setMarkerAlpha
local _showMarkerText = true; // Show the name of the mission in the center of the marker. Needed for AI counter.
local _showAiCount = false; // Show the AI count in the mission marker.
local _markWhenClear = true; // If all AI are dead, place a marker that says that the mission has been cleared. Respawns must be disabled.
local _killPercent = 95; // The percentage of AI that must be killed for the mission to be marked "clear". Because the AI counts can be slightly off for some reason, I recommend not using 100%.
local _lootWhenClear = true; // Wait until the mission is cleared to spawn the loot. True or false.
//End Config

////////////////////// Do not edit this section ///////////////////////////
local _markers = [1,1,1,1];
local _markerIndex = -1;
if (_enableMarkers) then {
	_markers set [0,[_position,"WAI" + str(_mission),_markerColor,"",_markerShape,_markerBrush,_markerSize,[],_markerAlpha]];
	if (_showMarkerText) then {_markers set [1,[_position,"WAI" + str(_mission) + "dot","ColorBlack","mil_dot","","",[],[_name],0]];};
	if (_autoClaim || _borderMarker) then {_markers set [2, [_position, "WAI" + str(_mission) + "auto", "ColorRed", "", "ELLIPSE", "Border", [_triggerDistance,_triggerDistance], [], 0]];};
	DZE_ServerMarkerArray set [count DZE_ServerMarkerArray, _markers];
	_markerIndex = count DZE_ServerMarkerArray - 1;
	PVDZ_ServerMarkerSend = ["start",_markers];
	publicVariable "PVDZ_ServerMarkerSend";
};

WAI_StaticMarkerReady = true;

// Add the mission's position to the global array so that other missions do not spawn near it.
DZE_MissionPositions set [count DZE_MissionPositions, _position];

// Wait until a player is within range.
local _claimPlayer = objNull;
while {isNull _claimPlayer} do {
	_claimPlayer = [_position, _triggerDistance] call isClosestPlayer;
	uiSleep 1;
};
//////////////////////////////// End //////////////////////////////////////

[
	[3725.0,5985.0,0], 6, "hard", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	[3705.0,6000.0,0], 5, "hard", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	[3745.0,5970.0,0], 5, "medium", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	[3725.0,5940.0,0], 4, "hard", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	[3725.0,6030.0,0], 4, "medium", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	[3665.0,5985.0,0], 4, "medium", "Random", "", "Random", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], "Random", _aiType, _mission
] call WAI_SpawnGroup;

[
	[[3725.0,5937.0,0],[3725.0,6033.0,0],[3737.0,5985.0,0]],
	"M2StaticMG", "hard", ["UN_CDF_Soldier_Guard_EP1_DZ","UN_CDF_Soldier_EP1","UN_CDF_Soldier_MG_EP1","UN_CDF_Soldier_AT_EP1","UN_CDF_Soldier_Officer_EP1"], _aiType, "Random", "Random", "Random", _mission
] call WAI_SpawnStatic;

[
	[[12,WAI_Sniper + WAI_M4],10,[4,wai_gems],6,[3,WAI_PacksLg]],
	WAI_CrateLg,
	[[[3707.0,5985.0,0],0]],
	_mission
] call WAI_SpawnStaticCrate;
[
	[6,6,[2,wai_gems],3,1],
	WAI_CrateMd,
	[[[3730.0,5990.0,0],0]],
	_mission
] call WAI_SpawnStaticCrate;

// Begin the mission monitoring thread.
[
	_mission, // Mission number
	_position, // Position of mission
	_name, // Name of Mission
	_triggerDistance, // used for AI caching
	_aiType, // "Bandit" or "Hero"
	_aiCaching, // true or false
	_autoClaim, // true or false
	_killPercent, // Percentage of AI killed to clear the mission
	_lootWhenClear, // Wait to spawn loot in crates until mission cleared
	_claimPlayer,
	[_enableRespawn,_respawnTimer], // Respawn options
	[_enableMarkers,_markerIndex,_showMarkerText,_showAiCount,_markWhenClear] // Marker parameters
] execVM "\z\addons\dayz_server\WAI\static\compile\staticMissionMonitor.sqf";

diag_log format ["WAI: static mission %1 started.",_name];
