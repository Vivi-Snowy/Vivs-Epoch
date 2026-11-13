
waiBlackList = call {
    if (toLower worldName in ["chernarus","chernarus_winter"]) exitWith {[
		[[0,16000,0],[1000,-0,0]],	// Left edge of map
        [[0,16000,0],[16000.0,14580.3,0]] // Top edge of map
    ];};
    if (toLower worldName == "lingor") exitWith {[
		[[0,10240,0],[200,0,0]],          // Left edge of map
		[[0,200,0],[10240,0,0]],          // Bottom edge of map
		[[5950,7150,0],[6450,6600,0]],    // Maruko airport fortress
		[[8700,5700,0],[10240,3300,0]],   // Bantanam island (fortress, boat/heli only)
		[[7800,9400,0],[10240,6400,0]]    // Mariana island (boat/heli only)
	];};
    if (toLower worldName == "panthera2") exitWith {[
		[[235,686,0],[758,160,0]] // Debug Island
	];};
    [];
};

if (count waiBlackList > 0) then {
	diag_log "WAI: blacklist Loaded";
} else {
	diag_log "WAI: You are on an unsupported map! No blacklist available.";
};