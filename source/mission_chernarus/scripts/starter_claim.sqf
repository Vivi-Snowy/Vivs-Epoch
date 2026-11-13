// Called by the "Claim Starter Kit" scroll action.
if (!isNil "dz_kitAction") then {player removeAction dz_kitAction; dz_kitAction = nil;};
profileNamespace setVariable ["dz_starterKitClaimed", true];
saveProfileNamespace;

dz_starterKitReq = player;
publicVariableServer "dz_starterKitReq";

player allowDamage false;
systemChat "[STARTER KIT] Delivered next to you - 2 minutes of god mode!";
uiSleep 120;
player allowDamage true;
systemChat "[STARTER KIT] God mode has ended.";
