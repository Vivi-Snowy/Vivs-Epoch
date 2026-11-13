# Viv's Epoch: Chernarus features

*Everything that's in the server, explained.* Made by **Vivi Snowy** · [Back to the README](../README.md)

## How to Play

1. Make sure Steam is open and logged in.
2. Start "DayZ Chernarus - 1 START SERVER" from your Steam library. A "DayZ Epoch server watcher" window opens - it keeps the server running and restarts it. CLOSE THAT WINDOW (then the server window) to stop the server for good.
3. Wait ~1-2 minutes, then start "DayZ Chernarus - 2 PLAY" from Steam.

## Auto-restart

Every 1 hour 30 minutes, counted from when the first player joins. Chat warnings
at 30/15/5/2/1 minutes, everyone is saved,
then the server restarts by itself. Rejoin with "2 PLAY" ~2 minutes later.
Debug monitor shows "Restart in". Crashed servers are restarted automatically too.
The watcher window title shows the minutes left. A frozen server (no heartbeat in the log for
12 min) or a crashed one is restarted automatically. Only one watcher runs at a time: pressing the
SERVER shortcut again while it is running does nothing, and an old server left running after the
watcher window was closed gets closed before a new one starts (no more two servers on one port).

## Spawning

- SPAWN PICKER: every new character gets the map with 6 random green spawn flags right next to towns (2 cities + 4 villages) - click one and you wake up there on the ground. New random set each death. Never inside trader zones, faction territories, AI missions/fortresses, occupied towns or (Lingor) the offshore islands. Closing the map or waiting 2 minutes picks one for you.
- Default player models; you spawn with JUST A MAP - find everything else yourself. (Starting gear is set in configVariables.sqf: DefaultMagazines / DefaultWeapons / DefaultBackpack.)

## HUD

- Debug monitor top right (right-click your WATCH to toggle).
- CLASSIC MESSAGES: no big text on screen - events, hunters, convoys, restarts etc. are short chat lines.
- AI MISSION NEWS comes over the RADIO in chat ("[RADIO] ...") - you need an ItemRadio to hear it.
- KILL FEED top left, classic Epoch style:  Victim <weapon icon> Killer (distance) - your kills, your deaths and the survivor NPCs' fights.
- Event markers on the map.

## PvE

- No player-vs-player damage, indestructible bases, 6 trader safe zones.

## AI

- Factions: Bandits & Hunters (one side) vs Military & Stalkers (other side) - they fight each other.
- 8 faction territories (coloured circles on the map), re-garrison 20 min after you clear them.
- 10 roaming foot patrols + 4 armed vehicle patrols between towns (kill the crew -> the vehicle is yours; it is saved to the database the moment you get in).
- 6 groups of friendly SURVIVORS (blue) scavenging between towns. Killing them = -100 humanity.
- Hunter squads track you constantly (break of 4-8 min between squads).
- WICKED AI missions (3 hero + 3 bandit at once) and DZMS missions (2 + 2): 50+ mission types.
- Skalisty Island Stronghold (static AI base).

## Living World (added later)

- AI HELICOPTER PATROLS: 3 armed Military / Bandit helicopters fly between towns and attack anyone hostile - you, the factions, hunters. Shoot one down: a loot crate drops at the wreck (orange "Downed Heli" marker). If the crew dies and it lands in one piece, the heli is yours (saved when you get in). A new one takes off 15 min later.
- SUPPLY PLANE every 40-60 min: a C-130 flies over a random spot and parachutes a big crate down (red smoke + chemlight, blue "Air Drop" marker). Pop-up tells you where it's headed.
- FACTION CONVOYS: 2 convoys on the road at once - an armed escort + a cargo truck full of loot, driving between faction territories (moving arrow on the map). Kill the crew and the truck unlocks (saved when you get in).
- TOWN TAKEOVERS every 30-45 min: a faction occupies a town with 15 men (striped circle + flag). Clear it for 2500 coins (everyone within 500m) and their stash (green smoke).
- RANDOM SERVER EVENTS at :15 and :45 every hour: construction (IKEA) crate, pirate treasure, special-forces weapons crate, UN supply drop, labyrinth, rubble town, mechanic's truck in a hangar.
- SURVIVOR NPCs: 10-12 named survivors "play" alongside you, in parties of 1-3 friends. About a third own a car: they drive between towns, park on the edge and loot on foot. Near you they really loot - walk to loot piles and take better guns, ammo, food and meds (the pile disappears). They avoid AI territories and missions, jog between towns, fight zombies and small threats but RUN when outnumbered or badly hurt, visit traders, camp at night and chat. Walk up and they stop, face you, wave and may drop you something. Killing one = -100 humanity (murder); their body keeps their gear and their car is free to take. You'll see them connect, disconnect and die in chat; "Players Online: 1 (+10 NPC)".
- SKIRMISHES: every 6-10 min a small fight breaks out in a town 500-1000m from you (factions vs each other, survivors vs bandits or hunters) - you hear the gunfire and can join in for the loot.
- SPAWN PROTECTION: after picking your spawn, AI ignore you for 3 minutes (ends early if you shoot).
- HUNTERS: a new character gets 10 minutes of peace, then a squad of 2-3 every 15-25 minutes.

- SMARTER AI (every AI group near you - factions, hunters, missions, fortresses, convoys, helis, NPCs):
- they tell nearby friendly groups where you are the moment one of them spots you;
  - groups of 4+ split: half get into cover (walls, houses, trees) and pin you down, the other half swing round your flank and assault - into the building next to you if you're hiding inside;
  - a hit soldier dives for cover and his group learns where the shot came from; they pop smoke when a mate goes down; badly wounded men fall back behind smoke and a buddy patches them up;
  - grenades when you're 15-40m away (more likely if you're holed up in a building);
  - snipers keep 250m+ away and go prone;
  - lose two thirds of the group -> they fall back and call in the nearest friendly group;
  - lose sight of you -> they search your last known position for a while instead of forgetting you;
  - vehicle passengers bail out to fight when you're within 250m; wrecked vehicles get abandoned;
  - patrol helicopters drop 4 paratroopers on you (once per heli);
  - mission/fortress AI stay within 250m of their post so missions still work;
  - skills retuned: better spotting, nerve and teamwork, a bit less pin-point aim - they win with tactics now, not laser accuracy. (custom\dz_aibrain.sqf: dzb_retune = false puts the old aim back.)

## Things to Do (rewards paid straight into your coin wallet)

- CONTRACTS: a personal job every few minutes - zombie culls, AI hit jobs or supply runs to a town. Progress shows on your debug monitor. 30 minutes to finish.
- TREASURE HUNTS every 40 min: yellow circle on the map - find the exact spot to dig up a crate (+3000 coins).
- WARLORD BOUNTIES every hour: a named warlord with a 7-man gang takes over a town (red circle). Kill him for 8000 coins and his war chest.
- STARTER KIT (once per player): scroll action "Claim Starter Kit" -> crate with plot pole, walls, floors, door, ladder, combo lock, lockbox, plywood/planks/cinder, tools + 2000 coins + 2 min god mode.
- HUMANITY LOADOUTS (switched OFF - you spawn with just a map): fresh spawns would get a better gun the higher your hero/bandit level. Turn back on with dzl_humanityLoadouts = true in scripts\starter_loadout.sqf.
- BLACK MARKET BUNKER: a walled trader outpost near a random town each restart (pink marker): black market, weapons and ammo traders. Safe inside the walls only.
- ZOMBIE HORDES: every 20-35 min a horde of 12-22 zombies forms 100-140m away and comes for you.
- UN OUTPOST: rogue UN garrison on Green Mountain (blue square) - 28 AI, 3 M2 guns, big loot crate.
- DEPLOY a MOTORBIKE (right-click an engine part; needs engine + 2 scrap metal + toolbox) or a MOZZIE gyrocopter (right-click a rotor; needs rotor + engine + fuel tank + toolbox).
- Service points at fuel stations: refuel, repair and rearm vehicles.
- Bury bodies (+humanity) or butcher them (-humanity).

## World

- Harder zombies: faster (speed 6-9), 1.5x damage, more of them (25 per player).
- Bloodsucker mutants near military buildings and crash sites (a mutant heart protects you).
- EVR storms (blowouts) every 1-2.5 hours: get inside a building or carry an APSI.
- Events: supply drops hourly at :30, heli crashes hourly at :00, random server events at :15 and :45, infected camps at start.
- 150 vehicles, more loot piles, ammo crates and mine veins.

## Economy

- Coins currency, banking at trader cities (money kept on death), zombies & AI drop coins.
- Virtual garage at plot poles, vehicle key changer, remote key actions, locate vehicle by GPS.

## Quality of Life

- Deploy bike (right-click toolbox), self blood bag, groups, death messages in chat.

## Admin

- In-game chat:  #login <your admin password - it is in ADMIN_PASSWORD.txt>
- Logs: DZE_Server_Config\arma2oaserver.RPT
- Server-side settings: @DayZ_Epoch_Server\addons\dayz_server.pbo (WAI\config.sqf, DZMS\DZMSConfig.sqf, custom\dz_factions.sqf, custom\dz_restart.sqf, custom\dz_living.sqf, custom\dz_survivors.sqf)
- Mission settings: MPMissions\DayZ_Epoch_11.Chernarus.pbo (configVariables.sqf)
- BattlEye, signature checks and client anti-cheat are OFF (private LAN server). Turn them on before opening the server to the internet.

Built with: DayZ Epoch 1.0.7.1 (EpochModTeam), WICKED AI 2.3, DZMS 2.1 and Client Side Marker Manager
(worldwidesorrow), deployAnything (oiad), plus custom scripts.

## World Events (more things to do)

New script: dayz_server\custom\dz_world.sqf (both maps). Everything shows in the
top-left chat like the rest, and job progress shows as a "JOB" line on your debug monitor.

### Distress Calls (every ~25-35 min)

A survivor is held by 3-5 bandits in a house in a town 1-3 km from you (orange circle on the map, red smoke by day, red flares at night). Walk right up to them to cut them loose. They follow you on foot, and jump in your vehicle if you stop next to them. Bring them to the nearest trader (blue marker) for 4000 coins + humanity. They can't be killed.

### Courier Jobs (every ~30-40 min)

Pick up the package (small box at the blue marker), then deliver it to a far-away trader for 2000 coins + distance bonus. Bandits get tipped off: a squad comes after you shortly after pickup, and another waits halfway. If you die, the package drops where you died and anyone can pick it up again.

### Camp Defence (every ~35-50 min)

A survivor camp (5 NPCs, sandbags, campfire, green flag on the map) radios for help. When you get within 300m, 3 waves of attackers hit it (Bandits, Bandits, Hunters). Keep at least one defender alive: 3000 coins + 500 per surviving defender, + a loot crate. If nobody shows up the camp packs up after ~20 min.

### Stash Tips (every ~12-20 min, max 2 at once)

A survivor NPC posts in chat that they left gear in a house (town + grid). No marker - you have to search the houses. Weapons, meds, sometimes gems/gold.

### Radio Intercepts (every ~7-12 min)

If you carry a Radio, you overhear the AI talk about what they're doing: convoys passing towns, heli patrols, occupied towns, hunters, the courier...

### Night Flares

At night, flares go up over fights, occupied towns, hostages and camps, so you can see where the action is from far away.

Settings (top of dz_world.sqf): dzw_rescueReward, dzw_defendReward and the
dzw_*Every timers [min,max seconds].

## More AI (dz_populate.sqf)

### AI Freezing

AI groups on foot more than 1.8 km from you are frozen (no CPU used) and wake up at 1.5 km. That keeps the server FPS up so there can be a lot more AI on the map.

### Town Life

Walking into a town (on foot or slow vehicle), there's a 60% chance someone is already there: bandits looting, stalkers passing through, or a military sweep. Max 3 town groups at once, each town rolls again after 20 min. They leave once you're 900m+ away.

### Checkpoints (Lingor 8, Chernarus 12 - triangle markers on the map, faction colour)

Roadblocks on the roads just outside towns: barriers, sandbags, 4-5 guards, a supply crate, 35% chance of an armed vehicle. Clear it: +800 coins, the crate, and the vehicle is yours (saved when you get in). Manned again 45 min later.

### Bandit Camps (Lingor 6, Chernarus 9 - hidden)

Tents and a campfire out in the wilderness, bandits (sometimes Hunters) sitting around a loot crate, plus 1-2 sentries. No marker until you get within 300m. Clear it: +1200 coins + crate. Back 60 min later.

### More of Everything

Roaming patrols 10 -> 14 (Lingor) / 16 (Chernarus), armed vehicle patrols 4 -> 6, survivor NPCs 10 -> 14 / 12 -> 16, helicopter patrols 2 -> 3 / 3 -> 4, skirmishes up to 3 at once, every 4-7 min (was 2, every 6-10 min).

Settings: top of dayz_server\custom\dz_populate.sqf (dzp_aiCap = 160 stops new populate AI
if the server is already busy; counts, chances, rewards, freeze distances).
