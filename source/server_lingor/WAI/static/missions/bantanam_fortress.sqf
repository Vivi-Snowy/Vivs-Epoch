local _mission = count WAI_MissionData - 1; // DO NOT CHANGE THIS LINE.

/*
	Bantanam Island Fortress (custom, Lingor).
	ARL rebels have taken over the abandoned GAL army base on Bantanam island (east). Bring a boat or a heli.
	The exact spot is chosen at server start: the flattest open ground near the anchor point.
*/
if (isNil "dzfort_layout") then {call compile preprocessFileLineNumbers "\z\addons\dayz_server\WAI\static\compile\dz_fortress.sqf";};

local _center = [[9325,5025], 300, []] call dzfort_findCenter;
local _fdir = 0;
([_center, _fdir, 45] call dzfort_layout) call WAI_SpawnStaticObjects;
local _rp = {[_center, _fdir, _this] call dzfort_rel}; // relative [dx,dy] -> world position

local _aiType = "Bandit"; // "Bandit" or "Hero" - determines the humanity and kill rewards.
local _position = [_center select 0, _center select 1]; // Select a position on the map for your mission. This should be the mission center. Just use the X and Y coordinates.
local _name = "Bantanam Island Fortress (ARL)"; // Used in marker text. If you know how to make localized strings and add them to a mission side string table then you can do it.
local _autoClaim = false; // Enable the auto-claim feature for this static location. Markers must also be enabled.
local _borderMarker = true; // This places a border marker on the perimeter defined by the _triggerDistance variable. It is also enabled with auto-claim.
local _triggerDistance = 1000; // This is how close in meters a player must be to spawn the AI. Also used for the auto-claim.
local _enableRespawn = true; // Allow an AI group to respawn after all members have been killed.
local _respawnTimer = 30; // The amount of time in minutes before an AI group is allowed to respawn.
local _aiCaching = false; // If players are not near then the behavioral FSM, targeting, and movement is disabled and the AI objects are hidden. Known to improve server performance.
local _enableMarkers = true; // Define the parameters below to place a custom JIP compatible marker on your mission.
local _markerColor = "ColorPink"; // Color of the mission marker. https://community.bistudio.com/wiki/Arma_3:_CfgMarkerColors
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
	([0,0] call _rp), 6, "hard", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	([-20,15] call _rp), 5, "hard", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	([20,-15] call _rp), 5, "medium", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	([0,-57] call _rp), 4, "hard", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	([0,57] call _rp), 4, "medium", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;
[
	([-65,0] call _rp), 4, "medium", "Random", "", "Random", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], "Random", _aiType, _mission
] call WAI_SpawnGroup;

[
	[([0,55] call _rp),([0,-55] call _rp),([0,-2] call _rp)],
	"M2StaticMG", "hard", ["Ins_Soldier_GL_DZ","TK_INS_Soldier_EP1_DZ","TK_INS_Warlord_EP1_DZ"], _aiType, "Random", "Random", "Random", _mission
] call WAI_SpawnStatic;

[
	[[12,WAI_Sniper + WAI_M4],10,[4,wai_gems],6,[3,WAI_PacksLg]],
	WAI_CrateLg,
	[[([-10,-12] call _rp),0]],
	_mission
] call WAI_SpawnStaticCrate;
[
	[6,6,[2,wai_gems],3,1],
	WAI_CrateMd,
	[[([10,-12] call _rp),0]],
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
