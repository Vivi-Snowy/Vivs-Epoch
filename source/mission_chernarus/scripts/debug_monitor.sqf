/*
	Debug monitor - top-right stats panel (shown with hintSilent).
	Toggle on/off: right-click your Watch -> "Toggle Debug Monitor".
*/
if (isDedicated) exitWith {};

dbm_on = true;
dbm_serverName = "My Local DayZ Epoch";

waitUntil {uiSleep 1; !isNil "Dayz_loginCompleted"};

while {true} do {
	if (dbm_on && {alive player}) then {
		local _weapon = currentWeapon player;
		local _pic = "";
		if (_weapon != "") then {
			_pic = getText (configFile >> "CfgWeapons" >> _weapon >> "picture");
		};
		if (_weapon == "" || _pic == "") then {
			_pic = getText (configFile >> "CfgVehicles" >> (typeOf player) >> "portrait");
		};
		local _vehicle = vehicle player;
		if (_vehicle != player) then {
			_pic = getText (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "picture");
		};

		local _upTime = round serverTime;
		local _h = floor (_upTime / 3600);
		local _m = floor ((_upTime mod 3600) / 60);

		local _row = {
			format ["<t size='0.95' align='left' color='#FFFFFF'>%1</t><t size='0.95' align='right' color='%3'>%2</t><br/>", _this select 0, _this select 1, _this select 2]
		};

		local _txt = format ["<t size='1.25' font='Bitstream' align='center' color='#FFFFFF'>%1</t><br/>", name player];
		if (_pic != "") then {
			_txt = _txt + format ["<img size='3.5' image='%1'/><br/>", _pic];
		};
		_txt = _txt
			+ (["Players Online:", if (isNil "dz_survivorCount") then {count playableUnits} else {format ["%1 (+%2 NPC)", count playableUnits, dz_survivorCount]}, "#FFFFFF"] call _row)
			+ (["Headshots:", player getVariable ["headShots",0], "#FFFFFF"] call _row)
			+ (["Bandits Killed:", player getVariable ["banditKills",0], "#FFFFFF"] call _row)
			+ (["Friendlies Killed:", player getVariable ["humanKills",0], "#FFFFFF"] call _row)
			+ (["Zombies Killed:", player getVariable ["zombieKills",0], "#FFFFFF"] call _row)
			+ "<br/>"
			+ (["Blood:", round r_player_blood, "#FF3333"] call _row)
			+ (["Humanity:", round (player getVariable ["humanity",0]), "#3399FF"] call _row)
			+ "<br/>"
			+ (["FPS:", round diag_fps, "#FFFFFF"] call _row)
			+ (["Map Grid:", mapGridPosition player, "#FFFFFF"] call _row)
			+ (if (isNil "dz_restartLeft") then {["Server Uptime:", format ["%1h %2min", _h, _m], "#FFFFFF"] call _row} else {local _r = dz_restartLeft max 0; ["Restart in:", format ["%1h %2min", floor (_r / 3600), floor ((_r mod 3600) / 60)], if (_r < 900) then {"#FF5555"} else {"#FFFFFF"}] call _row})
			+ (if (isNil {player getVariable "dz_job"}) then {""} else {format ["<br/><t size='0.85' align='center' color='#FF8800'>JOB</t><br/><t size='0.8' align='center' color='#FFFFFF'>%1</t><br/>", player getVariable "dz_job"]})
			+ (if (isNil {player getVariable "dz_contract"}) then {""} else {format ["<br/><t size='0.85' align='center' color='#4499FF'>CONTRACT</t><br/><t size='0.8' align='center' color='#FFFFFF'>%1</t><br/>", player getVariable "dz_contract"]})
			+ format ["<t size='0.9' align='center' color='#FFFFFF'>%1</t>", dbm_serverName];

		hintSilent parseText _txt;
	};
	uiSleep 1;
};
