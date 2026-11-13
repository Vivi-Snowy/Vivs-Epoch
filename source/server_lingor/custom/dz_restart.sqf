/*
	Scheduled restart countdown (server side).
	Counts down 90 minutes from mission start, warns players in chat at 30/15/5/2/1 minutes,
	saves everyone, then writes DZ_RESTART_NOW to the server log.
	The watcher (setup\server_loop_lingor.ps1) sees that line, closes the server and starts it again.
	It also writes a heartbeat line every 5 minutes; if those stop, the watcher restarts a frozen server.
	Uses diag_tickTime (serverTime does not count properly on an A2 dedicated server - that is why the old
	2-hour countdown never fired).
*/
#define DZR_INTERVAL 5400    // seconds between restarts (1 hour 30 minutes)

dzr_at = diag_tickTime + DZR_INTERVAL;
dzr_publish = {
	dz_restartLeft = round ((dzr_at - diag_tickTime) max 0);
	publicVariable "dz_restartLeft";
};
call dzr_publish;
diag_log format ["DZ RESTART: next restart in %1 minutes", DZR_INTERVAL / 60];

dzr_saveAll = {
	{
		if (isPlayer _x && {alive _x}) then {[_x, nil] call server_playerSync;};
	} forEach playableUnits;
	diag_log "DZ RESTART: all players saved";
};

local _warnings = [30, 15, 5, 2, 1];
local _nextBeat = diag_tickTime + 300;
local _nextPub = diag_tickTime + 30;
while {true} do {
	local _left = dzr_at - diag_tickTime;
	// warnings (if several are due at once, only the latest one is shown)
	local _due = [];
	{if (_left <= (_x * 60)) then {_due set [count _due, _x];};} forEach _warnings;
	if (count _due > 0) then {
		_warnings = _warnings - _due;
		local _min = (ceil (_left / 60)) max 1;
		["SERVER RESTART", format ["The server restarts in %1 minute%2. Get somewhere safe!", _min, if (_min == 1) then {""} else {"s"}], "#FF5555"] call dz_sendPopup;
		diag_log format ["DZ RESTART: warning sent, %1 min left", _min];
		if (_min <= 2) then {call dzr_saveAll;};
	};
	if (diag_tickTime > _nextBeat) then {
		_nextBeat = diag_tickTime + 300;
		diag_log format ["DZ RESTART: heartbeat, %1 min left", round (_left / 60)];
	};
	if (diag_tickTime > _nextPub) then {_nextPub = diag_tickTime + 30; call dzr_publish;};
	if (_left <= 10) exitWith {
		call dzr_saveAll;
		["SERVER RESTARTING", "Saving... rejoin with the DayZ Epoch LINGOR (Local Server) shortcut in about 2 minutes.", "#FF5555"] call dz_sendPopup;
		uiSleep 8;
		diag_log "DZ_RESTART_NOW";
	};
	uiSleep 5;
};
// keep repeating the signal in case the watcher missed it
while {true} do {
	uiSleep 30;
	diag_log "DZ_RESTART_NOW (waiting for the watcher)";
};
