/*
	DZ Survivors v2 (server side) - NPC survivors who play the map like other players.

	  - They come in parties of 1-3 friends (each with their own name). About a third own a car and drive
	    between towns, park on the edge, loot on foot, then drive on. If they die or leave it, the car is
	    up for grabs (it gets saved to the database when you get in).
	  - Real looting: near you (where loot actually spawns) they walk to loot piles and take what's there -
	    better guns, ammo, food, meds - and the pile is gone. Away from you they search buildings.
	  - They avoid faction territories, AI missions, fortresses and occupied towns when picking where to go.
	  - They jog between towns, walk carefully inside them, fight zombies and small threats, but RUN when
	    outnumbered or badly hurt (and shout about it in chat).
	  - Trader visits, campfires at night, bandaging up, chat, connect / disconnect / death lines.
	  - Friendly (your side). Walk up to them: they stop, turn to you, wave and maybe drop you something.
	    Killing one costs 100 humanity, like killing a player survivor. Their body keeps what they found.
*/
waitUntil {uiSleep 5; !isNil "dzf_spawnGroup" && {!isNil "dzf_towns"} && {!isNil "WAI_FindAmmo"} && {!isNil "dzv_addClaim"} && {!isNil "dzb_offset"}};
uiSleep 90;
diag_log "DZ SURVIVORS: starting";

dzs_max = if (toLower worldName == "lingor") then {14} else {16}; // survivors online at once (people, not parties)
if (isNil "dzf_onIsland") then {dzf_onIsland = {false};};

dzs_names = ["Mateo","Dmitri_K","OldManJenkins","Kasia","Ghost_ZA","RiverRat","Pavel","Lena_V","CampfireCarl","Jules",
	"Nomad","Tsukasa","BigJohn","Rookie_Rick","Sasha","DoubleTap","Elena","Brick","LuckyLuke","Viktor",
	"Medic_Mia","SilentBob","Raven","Duke","Marta","Frosty","Kuba","SnackAttack","Ivan_the_Terrible","Zoe",
	"xXNoScopeXx","Bambi_Killer","Hans","Nadia","Tomek","Sgt_Pepper","Moose","Lucia","Kenji","Wolfie"];
dzs_skinsM = ["Survivor2_DZ","Rocker1_DZ","Rocker3_DZ","Priest_DZ","Worker1_DZ","Worker3_DZ","Hunter_DZ","Civilian1_DZ","Civilian3_DZ","Civilian5_DZ","Postman1_DZ","Reporter_DZ","Gardener_DZ","SchoolTeacher_DZ","TK_CIV_Takistani01_EP1_DZ"];
dzs_skinsF = ["SurvivorW2_DZ","SurvivorWcombat_DZ","SurvivorWdesert_DZ","SurvivorWurban_DZ","SurvivorW3_DZ"];
dzs_female = ["Kasia","Lena_V","Jules","Sasha","Elena","Medic_Mia","Raven","Marta","Zoe","Nadia","Lucia"];
dzs_tiers = [
	["Makarov_DZ","M1911_DZ","M9_DZ"],
	["Winchester1866_DZ","Remington870_DZ","MR43_DZ","LeeEnfield_DZ","Mosin_DZ","CZ550_DZ"],
	["AK74_DZ","M16A2_DZ","MP5_DZ","G36C_DZ","AK74_Kobra_DZ","M4A1_CCO_DZ"],
	["M4SPR_DZE","DMR_Gh_DZE","PKM_DZ","M249_DZ","Mk48_CCO_DZ"]
];
dzs_cars = ["Lada2_DZE","car_hatchback_red_DZE","Skoda_DZE","datsun1_civil_1_open_DZE","hilux1_civil_3_open_DZE","UAZ_Unarmed_UN_EP1_DZE","Volha_2_TK_CIV_EP1_DZE","SkodaRed_DZE"];
dzs_lootItems = ["ItemBandage","ItemBandage","FoodCanBakedBeans","ItemSodaCoke","ItemWaterbottle","ItemPainkiller","ItemMorphine","ItemBloodbag","PartGeneric","ItemJerrycan","FoodCanFrankBeans","ItemTinBar","ItemSilverBar"];
dzs_traders = [];
{if (_forEachIndex < 6) then {dzs_traders set [count dzs_traders, _x select 0];};} forEach DZE_SafeZonePosArray;

// ---------------- chat ----------------
dzs_chat = {dz_fakeChat = format ["%1: %2", _this select 0, _this select 1]; publicVariable "dz_fakeChat";};
dzs_sys = {dz_fakeChat = _this; publicVariable "dz_fakeChat";};
dzs_lines = {
	local _t = _this select 0; local _town = _this select 1;
	local _l = call {
		if (_t == "spawn") exitWith {["just spawned, anyone near " + _town + "?","here we go again...","back on. heading inland","fresh spawn, no beans, send help lol","ok who keeps killing me","on with my squad, heading to " + _town]};
		if (_t == "loot") exitWith {["found some decent stuff in " + _town,"finally a real gun!","looting " + _town + ", it's quiet here","got beans and a soda. living the dream","anyone need bandages? got extra","picked " + _town + " clean"]};
		if (_t == "flee") exitWith {["RUN RUN RUN","way too many of them near " + _town + ", pulling out","nope nope, bandits everywhere","we're getting smoked near " + _town + "!!","falling back, they've got us pinned"]};
		if (_t == "danger") exitWith {["zeds everywhere in " + _town + "!!","bandits near " + _town + ", watch out","taking fire near " + _town,"these zombies are fast","contact near " + _town]};
		if (_t == "drive") exitWith {["got the car running, heading out","driving to " + _town + ", anyone need a lift?","car's almost out of fuel lol","parking up near " + _town]};
		if (_t == "trade") exitWith {["heading to the traders to sell","anyone at the traders?","sold my stuff, saving up for a car","bank's looking good tonight"]};
		if (_t == "camp") exitWith {["setting up camp for the night","too dark to loot, making a fire","night time... staying put","anyone else camping out?"]};
		if (_t == "hurt") exitWith {["bleeding, patching up","need a blood bag...","almost died lol","that was close"]};
		["anyone wanna team up?","this server is crazy","how long till restart?","did anyone see that heli?","where's the treasure hunt circle?","nice weather today","gg whoever got that convoy","I hear shooting near " + _town,"anyone got a toolbox?"]
	};
	_l call BIS_fnc_selectRandom
};

// ---------------- helpers ----------------
dzs_usedNames = [];
dzs_pickName = {
	local _n = "";
	for "_i" from 1 to 40 do {local _c = dzs_names call BIS_fnc_selectRandom; if !(_c in dzs_usedNames) exitWith {_n = _c;};};
	if (_n == "") then {_n = format ["Survivor%1", floor random 999];};
	dzs_usedNames set [count dzs_usedNames, _n];
	_n
};
dzs_tierOf = {local _t = 0; {if (_this in _x) exitWith {_t = _forEachIndex;};} forEach dzs_tiers; _t};
dzs_giveWeapon = { // [unit, weapon class] - swaps the rifle (or pistol) for this one, with ammo
	local _u = _this select 0; local _w = _this select 1;
	if !(isClass (configFile >> "CfgWeapons" >> _w)) exitWith {""};
	local _mag = _w call WAI_FindAmmo;
	local _isPistol = (_w call dzs_tierOf) == 0 && {_w in (dzs_tiers select 0)};
	if (!_isPistol && {primaryWeapon _u != ""}) then {_u removeWeapon (primaryWeapon _u);};
	for "_m" from 1 to (2 + floor random 3) do {if (_mag != "") then {_u addMagazine _mag;};};
	_u addWeapon _w; _u selectWeapon _w;
	_w
};
dzs_bad = { // position -> true if it's somewhere survivors shouldn't go
	local _p = _this;
	if (_p call dzf_inSafeZone || {_p call dzf_onIsland}) exitWith {true};
	local _b = false;
	{if ((_p distance (_x select 1)) < ((_x select 2) + 350)) exitWith {_b = true;};} forEach dzf_zones;
	if (!_b) then {{if (typeName _x == "ARRAY" && {(_p distance _x) < 500}) exitWith {_b = true;};} forEach DZE_MissionPositions;};
	if (!_b && {!isNil "dzl_takeover"} && {count dzl_takeover > 0}) then {if ((_p distance (dzl_takeover select 1)) < 500) then {_b = true;};};
	_b
};
dzs_nextTown = { // [from pos, maxDist] -> town position or []
	local _from = _this select 0; local _res = [];
	for "_t" from 1 to 25 do {
		local _q = dzf_towns call BIS_fnc_selectRandom;
		local _d = _q distance _from;
		if (_d > 300 && {_d < (_this select 1)} && {!(_q call dzs_bad)}) exitWith {_res = _q;};
	};
	_res
};
dzs_roadNear = {local _r = _this nearRoads 250; if (count _r > 0) then {getPosATL (_r select 0)} else {_this}};
dzs_houseWithPos = {
	local _list = nearestObjects [_this select 0, ["House"], _this select 1];
	local _res = objNull;
	for "_i" from 1 to 12 do {
		if (count _list == 0) exitWith {};
		local _b = _list call BIS_fnc_selectRandom;
		if (((_b buildingPos 1) select 0) != 0) exitWith {_res = _b;};
	};
	_res
};
dzs_buildingPos = {
	local _n = 0;
	while {((_this buildingPos _n) select 0) != 0 && {_n < 40}} do {_n = _n + 1;};
	_this buildingPos (floor random (_n max 1))
};
dzs_alive = {local _r = []; {if (alive _x) then {_r set [count _r, _x];};} forEach (units _this); _r};
dzs_say = {_this getVariable ["dzs_name", "Survivor"]}; // unit -> name

// ---------------- spawning ----------------
dzs_parties = []; // [group, state, target, building, nextAct, lastChat, lootCount, born, lastTrade, camp, car, fleeUntil, pile]
dzs_makeUnit = { // [group, pos] -> unit
	local _g = _this select 0; local _p = _this select 1;
	local _name = call dzs_pickName;
	local _skin = if (_name in dzs_female) then {dzs_skinsF call BIS_fnc_selectRandom} else {dzs_skinsM call BIS_fnc_selectRandom};
	local _u = _g createUnit [_skin, [(_p select 0) + random 10 - 5, (_p select 1) + random 10 - 5, 0], [], 5, "FORM"];
	[_u] joinSilent _g;
	removeAllWeapons _u; removeAllItems _u;
	{_u addWeapon _x;} forEach ["ItemMap","ItemCompass","ItemWatch","ItemFlashlight"];
	{_u addMagazine _x;} forEach ["ItemBandage","ItemBandage","FoodCanBakedBeans","ItemWaterbottle"];
	[_u, (dzs_tiers select (if (random 1 < 0.6) then {0} else {1})) call BIS_fnc_selectRandom] call dzs_giveWeapon;
	{_u setSkill [_x select 0, _x select 1];} forEach WAI_SkillMedium;
	_u setVariable ["dzf_faction", "Survivors"];
	_u setVariable ["dzf_humanity", -100];
	_u setVariable ["dzs_name", _name];
	_u setVariable ["bodyName", _name, true];
	_u allowFleeing 0;
	_u addEventHandler ["Killed", {_this call dzs_onKilled;}];
	(format ["%1 connected", _name]) call dzs_sys;
	_u
};
dzs_spawnParty = {
	local _start = [];
	for "_t" from 1 to 30 do {
		local _p = dzf_towns call BIS_fnc_selectRandom;
		if (!(_p call dzs_bad) && {(_p call dzf_nearestPlayerDist) > 600}) exitWith {_start = _p;};
	};
	if (count _start == 0) exitWith {};
	local _size = [1,1,2,2,2,3] call BIS_fnc_selectRandom;
	local _g = createGroup WEST;
	for "_i" from 1 to _size do {[_g, _start] call dzs_makeUnit;};
	_g setBehaviour "AWARE"; _g setCombatMode "YELLOW"; _g setSpeedMode "NORMAL"; _g setFormation "FILE";
	_g setVariable ["DoNotFreeze", true];
	// some parties own a car
	local _car = objNull;
	if (random 1 < 0.35) then {
		local _cls = dzs_cars call BIS_fnc_selectRandom;
		if (isClass (configFile >> "CfgVehicles" >> _cls)) then {
			local _rp = _start call dzs_roadNear;
			_car = createVehicle [_cls, _rp, [], 10, "NONE"];
			dayz_serverObjectMonitor set [count dayz_serverObjectMonitor, _car];
			clearWeaponCargoGlobal _car; clearMagazineCargoGlobal _car;
			_car setFuel (0.3 + random 0.5);
			_car setVariable ["dzs_car", true, true];
			_car call dzv_addClaim;
		};
	};
	local _now = diag_tickTime;
	dzs_parties set [count dzs_parties, [_g, "travel", _start, objNull, _now + 20, _now, 0, _now, _now, [], _car, 0, objNull]];
	local _lead = leader _g;
	[_lead] spawn {uiSleep (20 + random 40); local _u = _this select 0; if (alive _u) then {[_u call dzs_say, ["spawn", (getPosATL _u) call dz_nearTown] call dzs_lines] call dzs_chat;};};
	diag_log format ["DZ SURVIVORS: party of %1 (%2)%3 spawned near %4", _size, (units _g) call {local _n = []; {_n set [count _n, _x getVariable ["dzs_name",""]];} forEach _this; _n}, if (isNull _car) then {""} else {format [" with a %1", typeOf _car]}, mapGridPosition _start];
};
dzs_onKilled = {
	local _u = _this select 0; local _k = _this select 1;
	local _name = _u getVariable ["dzs_name", "Survivor"];
	local _by = call {
		if (isNull _k || {_k == _u}) exitWith {"was killed by zombies"};
		if (isPlayer _k) exitWith {format ["was killed by %1", name _k]};
		if (_k isKindOf "zZombie_Base") exitWith {"was killed by zombies"};
		local _f = _k getVariable ["dzf_faction", ""];
		if (_f != "") exitWith {format ["was killed by %1", _f]};
		"was killed by AI"
	};
	(format ["%1 %2", _name, _by]) call dzs_sys;
	dzs_usedNames = dzs_usedNames - [_name];
	_u setVariable ["bodyName", "NPC", false]; // sched_corpses cleans the body up later (gear stays until then)
	if (isPlayer _k) then {
		_k setVariable ["humanity", (_k getVariable ["humanity",0]) - 100, true];
		_k setVariable ["humanKills", (_k getVariable ["humanKills",0]) + 1, true];
	};
};

// ---------------- behaviours ----------------
dzs_takePile = { // [unit, pile] - take what's useful from a loot pile, then remove it
	local _u = _this select 0; local _h = _this select 1;
	local _got = "";
	local _wc = getWeaponCargo _h; local _mc = getMagazineCargo _h;
	local _myTier = (primaryWeapon _u) call dzs_tierOf;
	if (primaryWeapon _u == "") then {_myTier = -1;};
	{
		local _w = _x;
		if (isClass (configFile >> "CfgWeapons" >> _w)) then {
			local _t = _w call dzs_tierOf;
			if ((_w in (dzs_tiers select 1) || {_w in (dzs_tiers select 2)} || {_w in (dzs_tiers select 3)}) && {_t > _myTier}) then {
				[_u, _w] call dzs_giveWeapon; _got = getText (configFile >> "CfgWeapons" >> _w >> "displayName"); _myTier = _t;
			} else {
				local _type = getNumber (configFile >> "CfgWeapons" >> _w >> "type");
				if (_type == 1 && {_myTier < 0}) then {[_u, _w] call dzs_giveWeapon; _got = getText (configFile >> "CfgWeapons" >> _w >> "displayName"); _myTier = 1;}; // any rifle beats no rifle
				if (_type == 131072 && {!(_w in weapons _u)}) then {_u addWeapon _w;}; // tools / binoculars etc.
			};
		};
	} forEach (_wc select 0);
	{if (count (magazines _u) < 20) then {_u addMagazine _x;};} forEach (_mc select 0);
	clearWeaponCargoGlobal _h; clearMagazineCargoGlobal _h;
	deleteVehicle _h;
	_u playMove "AinvPknlMstpSlayWrflDnon";
	_got
};
dzs_campClear = {{deleteVehicle _x;} forEach (_this select 9); _this set [9, []];};
dzs_setDriving = { // [party, destination]
	local _s = _this select 0; local _dest = _this select 1;
	local _g = _s select 0; local _car = _s select 10;
	local _men = _g call dzs_alive;
	if (count _men == 0) exitWith {};
	(_men select 0) assignAsDriver _car;
	{if (_forEachIndex > 0) then {_x assignAsCargo _car;};} forEach _men;
	_men orderGetIn true;
	_g setSpeedMode "NORMAL";
	(_men select 0) doMove (_dest call dzs_roadNear);
};
dzs_dismount = {
	local _g = _this select 0;
	{unassignVehicle _x; doGetOut _x;} forEach (units _g);
	(units _g) orderGetIn false;
};

// ---------------- main loop ----------------
local _nextSpawn = diag_tickTime;
while {true} do {
	local _now = diag_tickTime;
	local _night = (daytime > 20.5 || {daytime < 5});
	local _players = call dzf_players;

	// keep the "server" populated (staggered joins)
	local _alive = 0;
	{_alive = _alive + count ((_x select 0) call dzs_alive);} forEach dzs_parties;
	dz_survivorCount = _alive; publicVariable "dz_survivorCount";
	if (_alive < dzs_max && {_now > _nextSpawn} && {count _players > 0}) then {
		call dzs_spawnParty;
		_nextSpawn = _now + 45 + random 90;
	};

	local _keep = [];
	{
		local _s = _x;
		local _g = _s select 0;
		local _men = _g call dzs_alive;
		local _car = _s select 10;
		if (!isNull _car && {!alive _car || {_car getVariable ["dzv_saved", false]}}) then {_car = objNull; _s set [10, objNull];}; // wrecked, or a player claimed it
		if (count _men == 0) then {
			_s call dzs_campClear;
			if (!isNull _car) then {_car setVariable ["dzs_car", nil, true];}; // abandoned car stays - free to take
			deleteGroup _g;
		} else {
			local _gone = false;
			local _lead = leader _g;
			local _pos = getPosATL _lead;
			local _town = _pos call dz_nearTown;
			local _state = _s select 1;
			local _inCar = !isNull _car && {vehicle _lead == _car};

			// --- danger: fight small threats, run from big ones ---
			local _enemy = _lead findNearestEnemy _lead;
			if (!isNull _enemy && {_enemy isKindOf "zZombie_Base" || {side _enemy == civilian}}) then {_enemy = objNull;};
			if (!isNull _enemy && {(_enemy distance _lead) < 300} && {_state != "flee"}) then {
				local _foes = 0;
				{if (side _x != WEST && {side _x != civilian} && {alive _x} && {(_x distance _lead) < 350} && {(_lead knowsAbout _x) > 0.5}) then {_foes = _foes + 1;};} forEach (_lead nearEntities ["CAManBase", 350]);
				local _hurt = 0; {_hurt = _hurt + damage _x;} forEach _men;
				if (_foes > (count _men) + 1 || {(_hurt / (count _men)) > 0.45}) then {
					// outgunned: break contact and run for it
					local _away = [_pos, (([getPosATL _enemy, _pos] call dzb_dirTo) + random 60 - 30), 350] call dzb_offset;
					if (surfaceIsWater _away || {_away call dzs_bad}) then {_away = [_pos, ([getPosATL _enemy, _pos] call dzb_dirTo) + 90, 300] call dzb_offset;};
					{_x doMove _away; _x setUnitPos "AUTO";} forEach _men;
					_g setSpeedMode "FULL"; _g setCombatMode "GREEN";
					_g setVariable ["dzb_skip", true]; // the AI brain leaves them alone while they run
					_s set [1, "flee"]; _s set [11, _now + 75]; _s set [3, objNull];
					if ((_now - (_s select 5)) > 90) then {[_lead call dzs_say, ["flee", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};
				} else {
					if ((_now - (_s select 5)) > 240 && {random 1 < 0.5}) then {[_lead call dzs_say, ["danger", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};
				};
			};
			if (_state == "flee" && {_now > (_s select 11)}) then {
				_g setCombatMode "YELLOW"; _g setSpeedMode "NORMAL";
				_g setVariable ["dzb_skip", false];
				_s set [1, "travel"]; _s set [2, ([_pos, 1500] call dzs_nextTown)]; _s set [4, _now];
				if (count (_s select 2) == 0) then {_s set [2, _pos];};
			};

			// --- zombies: shoot them; they bite ---
			{
				local _u = _x;
				local _zeds = (getPosATL _u) nearEntities ["zZombie_Base", 50];
				if (count _zeds > 0) then {
					local _z = _zeds select 0;
					if (alive _z) then {_u reveal _z; _u doTarget _z; _u doFire _z;};
					local _close = 0;
					{if (alive _x && {(_x distance _u) < 3}) then {_close = _close + 1;};} forEach _zeds;
					if (_close > 0) then {_u setDamage ((damage _u) + 0.04 * _close);};
				};
				if (damage _u > 0.45 && {"ItemBandage" in magazines _u} && {random 1 < 0.3}) then {
					_u removeMagazine "ItemBandage"; _u setDamage (((damage _u) - 0.3) max 0);
					_u playMove "AinvPknlMstpSlayWrflDnon_medic";
					if ((_now - (_s select 5)) > 200) then {[_u call dzs_say, ["hurt", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};
				};
			} forEach _men;

			// --- what to do next ---
			local _busy = (behaviour _lead == "COMBAT") || {_state == "flee"};
			if (!_busy && {_now > (_s select 4)}) then {
				if (_night && {_state in ["loot","travel"]} && {!_inCar} && {random 1 < 0.5}) then {_state = "camp"; _s set [1, "camp"];};
				if (!_night && {_state == "camp"}) then {_s call dzs_campClear; _state = "loot"; _s set [1, "loot"];};
				// rich enough: trader run
				if (_state == "loot" && {(_s select 6) >= 8} && {(_now - (_s select 8)) > 2400} && {count dzs_traders > 0}) then {
					local _tr = dzs_traders select 0;
					{if ((_x distance _pos) < (_tr distance _pos)) then {_tr = _x;};} forEach dzs_traders;
					_s set [1, "trade"]; _s set [2, _tr]; _state = "trade";
					[_lead call dzs_say, ["trade", _town] call dzs_lines] call dzs_chat; _s set [5, _now];
					if (!isNull _car) then {[_s, _tr] call dzs_setDriving;} else {_g move _tr; _g setSpeedMode "FULL";};
				};
				call {
					if (_state == "camp") exitWith {
						if (count (_s select 9) == 0) then {
							local _cp = _lead modelToWorld [0, 4, 0]; _cp set [2, 0];
							local _fire = createVehicle ["Land_Fire_burning", _cp, [], 0, "CAN_COLLIDE"];
							local _tent = createVehicle ["ACamp", _lead modelToWorld [4, 6, 0], [], 0, "CAN_COLLIDE"];
							_s set [9, [_fire, _tent]];
							{doStop _x; _x playMove "AmovPsitMstpSlowWrflDnon";} forEach _men;
							[_lead call dzs_say, ["camp", _town] call dzs_lines] call dzs_chat; _s set [5, _now];
						};
						_s set [4, _now + 120];
					};
					if (_state == "trade") exitWith {
						local _tr = _s select 2;
						if ((_lead distance _tr) < 80) then {
							if (_inCar) then {[_g] call dzs_dismount;};
							_s set [6, 0]; _s set [8, _now]; _s set [1, "loot"]; _s set [3, objNull];
							_s set [4, _now + 180 + random 180]; // hang around the traders a bit
							{doStop _x;} forEach _men;
						} else {
							if (!isNull _car && {!_inCar} && {(_lead distance _car) < 300}) then {[_s, _tr] call dzs_setDriving;} else {_g move _tr;};
							_s set [4, _now + 30];
						};
					};
					if (_state == "travel") exitWith {
						local _dest = _s select 2;
						if (count _dest == 0) then {_dest = [_pos, if (isNull _car) then {2000} else {4000}] call dzs_nextTown; _s set [2, _dest];};
						if (count _dest == 0) exitWith {_s set [4, _now + 30];};
						if ((_lead distance _dest) < (if (_inCar) then {150} else {120})) then {
							// arrived: park and loot on foot
							if (_inCar) then {[_g] call dzs_dismount; if ((_now - (_s select 5)) > 200 && {random 1 < 0.5}) then {[_lead call dzs_say, ["drive", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};};
							_g setSpeedMode "LIMITED"; _g setFormation "WEDGE";
							_s set [1, "loot"]; _s set [3, objNull]; _s set [4, _now + 10];
						} else {
							if (!isNull _car && {(_lead distance _car) < 400}) then {
								if (!_inCar) then {[_s, _dest] call dzs_setDriving;} else {(driver _car) doMove (_dest call dzs_roadNear); _car setFuel ((fuel _car) max 0.25);};
							} else {
								_g move _dest; _g setSpeedMode (if ((_lead distance _dest) > 500) then {"FULL"} else {"NORMAL"}); _g setFormation "FILE";
							};
							_s set [4, _now + 25];
						};
					};
					// --- looting ---
					local _near = (count _players > 0) && {(_pos call dzf_nearestPlayerDist) < 400};
					local _pile = _s select 12;
					// real loot piles near you
					if (_near && {isNull _pile}) then {
						{
							if (isNull _pile && {!(_x getVariable ["permaLoot", false])} && {(getPosATL _x call dzf_nearestPlayerDist) > 25}) then {_pile = _x;};
						} forEach (nearestObjects [_pos, ["WeaponHolder"], 45]);
						_s set [12, _pile];
						if (!isNull _pile) then {(_men select 0) doMove (getPosATL _pile);};
					};
					if (!isNull _pile) exitWith {
						local _looter = _men select 0;
						if ((_looter distance _pile) < 3) then {
							local _got = [_looter, _pile] call dzs_takePile;
							_s set [6, (_s select 6) + 1]; _s set [12, objNull];
							if (_got != "" && {(_now - (_s select 5)) > 120}) then {[_looter call dzs_say, format ["found a %1 lol", _got]] call dzs_chat; _s set [5, _now];};
							if (_got != "") then {diag_log format ["DZ SURVIVORS: %1 picked up a %2 near %3", _looter call dzs_say, _got, _town];};
							_s set [4, _now + 8 + random 10];
						} else {
							if ((_looter distance _pile) > 60) then {_s set [12, objNull];} else {_looter doMove (getPosATL _pile);};
							_s set [4, _now + 8];
						};
					};
					// otherwise search buildings (simulated loot)
					local _b = _s select 3;
					if (isNull _b) then {
						if ((_s select 6) > 0 && {random 1 < 0.3}) exitWith {_s set [1, "travel"]; _s set [2, []]; _s set [4, _now + 5];};
						_b = [_pos, 180] call dzs_houseWithPos;
						_s set [3, _b];
						if (!isNull _b) then {
							{_x doMove (_b call dzs_buildingPos);} forEach _men;
						} else {_s set [1, "travel"]; _s set [2, []];};
						_s set [4, _now + 30];
					} else {
						if ((_lead distance _b) < 14) then {
							{
								if (random 1 < 0.5) then {_x playMove "AinvPknlMstpSlayWrflDnon";};
								if (random 1 < 0.55) then {_x addMagazine (dzs_lootItems call BIS_fnc_selectRandom);};
								local _tier = (primaryWeapon _x) call dzs_tierOf;
								if (primaryWeapon _x == "") then {_tier = 0;};
								if (_tier < 3 && {random 1 < (0.16 - 0.04 * _tier)}) then {
									local _w = [_x, (dzs_tiers select (_tier + 1)) call BIS_fnc_selectRandom] call dzs_giveWeapon;
									if (_tier + 1 >= 2 && {isNull (unitBackpack _x)}) then {_x addBackpack (["Patrol_Pack_DZE1","Assault_Pack_DZE1","ALICE_Pack_DZE1","CzechBackpack_DZE1"] call BIS_fnc_selectRandom);};
									if ((_now - (_s select 5)) > 240) then {[_x call dzs_say, ["loot", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};
									diag_log format ["DZ SURVIVORS: %1 found a %2", _x call dzs_say, _w];
								};
							} forEach _men;
							_s set [6, (_s select 6) + 1];
							_s set [3, objNull];
							_s set [4, _now + 20 + random 40];
						} else {
							_lead doMove (_b call dzs_buildingPos);
							_s set [4, _now + 25];
						};
					};
				};
			};

			// --- you walk up: they stop, face you, wave, maybe share ---
			{
				local _p = _x;
				if ((_p distance _lead) < 15 && {(_now - (_s select 5)) > 480}) then {
					{doStop _x; _x doWatch _p;} forEach _men;
					_lead playAction "gestureHi";
					[_lead call dzs_say, ["hey " + (name _p) + ", friendly!","don't shoot, we're friendly","hey man, careful around " + _town,"want some beans? here","we're heading out soon, stay safe"] call BIS_fnc_selectRandom] call dzs_chat;
					_s set [5, _now]; _s set [4, _now + 25];
					if (random 1 < 0.35) then {
						local _h = createVehicle ["WeaponHolder", _lead modelToWorld [0, 1, 0], [], 0, "CAN_COLLIDE"];
						_h addMagazineCargoGlobal [["ItemBandage","FoodCanBakedBeans","ItemSodaCoke","ItemPainkiller","ItemWaterbottle"] call BIS_fnc_selectRandom, 1];
						_h setVariable ["permaLoot", true];
					};
				};
			} forEach _players;

			// random chatter
			if ((_now - (_s select 5)) > (900 + random 1800) && {random 1 < 0.15}) then {[_lead call dzs_say, ["chat", _town] call dzs_lines] call dzs_chat; _s set [5, _now];};

			// log off after a long session when nobody is around
			if ((_now - (_s select 7)) > (5400 + random 3600) && {(_pos call dzf_nearestPlayerDist) > 1200}) then {
				_s call dzs_campClear;
				{(format ["%1 disconnected", _x call dzs_say]) call dzs_sys; dzs_usedNames = dzs_usedNames - [_x call dzs_say]; deleteVehicle _x;} forEach _men;
				if (!isNull _car && {count (crew _car) == 0}) then {deleteVehicle _car;};
				deleteGroup _g;
				_gone = true;
			};
			if (!_gone) then {_keep set [count _keep, _s];};
		};
	} forEach dzs_parties;
	dzs_parties = _keep;

	uiSleep 12;
};
