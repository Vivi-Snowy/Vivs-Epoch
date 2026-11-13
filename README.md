# Viv's Epoch

*A DayZ Epoch server pack for Chernarus and Lingor* · **v1.0.0**

**Made by Vivi Snowy** · [GitHub](https://github.com/Vivi-Snowy) · [Support me on Ko-fi ☕](https://ko-fi.com/vivienne38)

Play **DayZ Epoch** on your own PC, offline, with a world full of life. You get two ready-made private servers for Arma 2, **Chernarus** and **Lingor Island**, packed with AI factions, missions, convoys, helicopters, survivor NPCs, events and jobs. It's PvE, it saves your progress, and a one-click installer does the hard part.

> Free to use. If you enjoy it, a coffee on [Ko-fi](https://ko-fi.com/vivienne38) helps me keep making things like this. 💜

---

## ✨ What's in it

- **A living world:** factions fight each other, there are roaming patrols, armed vehicle and helicopter patrols, convoys, town takeovers and checkpoints, and survivor NPCs who loot, drive and chat like real players.
- **Smarter AI** that takes cover, flanks, throws grenades, pops smoke and calls for help.
- **Lots to do:** WICKED AI and DZMS missions, AI fortresses, contracts, treasure hunts, warlord bounties, distress calls, courier jobs, camp defence, supply drops, zombie hordes and EVR storms.
- **Coins, banking and traders.** Your money stays in the bank when you die.
- **Spawn picker**, a once-per-player **starter kit** with base building materials, **deployable** bikes, motorbikes and gyrocopters, and a black-market bunker.
- **PvE:** players can't hurt each other and bases can't be destroyed.
- **Auto-restart** every 90 minutes, with warnings, and it brings the server back after crashes.
- **Both maps can run side by side.** Characters are kept separate per map, and your bank balance is shared.

📖 **Everything in the servers, explained:** [Lingor features](docs/LINGOR_FEATURES.md) · [Chernarus features](docs/CHERNARUS_FEATURES.md). These cover every AI faction, fortress, event, job, reward and setting. (The same guides come as `.txt` files in the download's `docs` folder.)

---

## 📥 What you need (download these first)

These are made by other people, so they aren't included here. Get them from the official places:

| # | What | Why | Where |
|---|------|-----|-------|
| 1 | **Arma 2** and **Arma 2: Operation Arrowhead** | The game. You need both, installed in the **same Steam library**. | Steam: [Arma 2](https://store.steampowered.com/app/33900/) · [Operation Arrowhead](https://store.steampowered.com/app/33930/) |
| 2 | **DayZ Epoch 1.0.7.1**, client **and** server files | The DayZ Epoch mod itself | [Official release page](https://github.com/EpochModTeam/DayZ-Epoch/releases/tag/1.0.7.1). The server archive's password is `123456` |
| 3 | **MariaDB 10.11** | The free database the server saves to | The installer downloads it for you, or get it at [mariadb.org](https://mariadb.org/download/) |

**Only for Lingor**, put these 3 files in your **Downloads** folder (the installer unpacks them):

| File | What | Where |
|------|------|-------|
| `lingor-1.5.7z` | Jungle Wars: Island of Lingor 1.5 (IceBreakr) | [ModDB](https://www.moddb.com/games/arma-2/addons/jungle-wars-island-of-lingor) |
| `ibr_plants-1.5.7z` | IBR Plants 1.5 (IceBreakr) | [ModDB](https://www.moddb.com/games/arma-2/addons/ibr-plants) |
| `brg_africa-1.23.7z` | BRG Africa foliage 1.23 (Berghoff) | [ModDB](https://www.moddb.com/games/arma-2/addons/african-foliage) |

You'll also need **7-Zip** to unpack things. The installer installs it if it's missing, or you can get it at [7-zip.org](https://www.7-zip.org/).

---

## 🛠️ How to install (step by step)

> 📘 **New to modding?** Follow the **[full install guide](docs/INSTALL_GUIDE.md)**. It has a download checklist, every step explained, how to check it worked, and a big troubleshooting section.

1. **Install Arma 2 and Operation Arrowhead** from Steam, and start Operation Arrowhead once, then close it.
2. **Find your game folder.** In Steam, right-click *Arma 2: Operation Arrowhead* → **Manage** → **Browse local files**. This is the folder everything goes into, and it's the one with `ArmA2OA.exe` in it.
3. **Add the DayZ Epoch client files.** Extract the Epoch client download into that folder, so a `@DayZ_Epoch` folder appears next to `ArmA2OA.exe`.
4. **Add the DayZ Epoch server files.** Extract the Epoch server download (password `123456`), open its **Server Files** folder, and copy everything inside it into the game folder. (Don't worry about its `dlls` folder, the installer moves those files into place for you.)
5. **Add my files.** Download the latest release zip from the [Releases](https://github.com/Vivi-Snowy/Vivs-Epoch/releases) page, open it, and copy everything inside it into the game folder. When Windows asks, choose **Replace the files**.
6. **(Lingor only)** Put the 3 Lingor files from the table above in your **Downloads** folder.
7. **Double-click `INSTALL.bat`** in the game folder and click **Yes** when Windows asks for permission. It sets up the database, makes your passwords, unpacks Lingor and adds **START** and **PLAY** shortcuts to your **Steam library**. (Steam closes for a few seconds while it does that, then opens again.)

That's it! 🎉

## 🎮 How to play

1. Make sure **Steam is running**.
2. In your **Steam library**, start **"DayZ Chernarus - 1 START SERVER"** (or the Lingor one). A small *server watcher* window opens. Leave it open.
3. Wait **1–2 minutes**, then start **"DayZ Chernarus - 2 PLAY"** from Steam.
4. To stop the server, close the **watcher** window first, then the server window.

Your **admin password** is in `ADMIN_PASSWORD.txt` in the game folder. In game, open chat and type `#login yourpassword`.

---

## 🆘 Something went wrong?

| Problem | Fix |
|---------|-----|
| The installer says files are missing | Read what it lists. It tells you exactly what to download and where to put it. Then run `INSTALL.bat` again. |
| "Could not log in to MariaDB as root" | You already had MariaDB installed. Run `INSTALL.bat` again and type the root password you chose back then. |
| I join and get kicked straight away (`id=ERROR` in the server window) | Start both shortcuts **from your Steam library**, with Steam fully open and logged in. Steam has to be running before the server starts. |
| The game opens but I can't join / it keeps waiting | The server is still loading. Give it 2 minutes after starting, then try **2 PLAY** again. |
| The server closes straight away | Open `DZE_Server_Config\arma2oaserver.RPT` (or `DZE_Server_Config_Lingor\...` for Lingor) and look near the end for the error. Usually a file from step 3 or 4 is missing. |
| "Addon ... requires addon ..." on Lingor | One of the 3 Lingor files didn't unpack. Check it's fully downloaded in Downloads, then run `INSTALL.bat` again. |
| Windows SmartScreen blocks a .bat file | Click **More info** → **Run anyway**. These are plain text scripts, so you can open them in Notepad to see what they do. |
| Something else | Open an [Issue](https://github.com/Vivi-Snowy/Vivs-Epoch/issues) and paste the end of `INSTALL_LOG.txt` or the `.RPT` log. |

---

## ⚙️ For tinkerers

- `game-files/`: the files that go into the game folder.
- `source/`: the unpacked scripts inside the four `.pbo` files, so you can read and change them. The server-side settings are in `custom\`, `WAI\config.sqf` and `DZMS\DZMSConfig.sqf`. The mission settings are in `configVariables.sqf`.
- **Updating a server file:** put the new file next to the old one with `.new` on the end (for example `dayz_server.pbo.new`), and the watcher installs it at the next restart.
- **Ports:** Chernarus uses 2302 and Lingor uses 2402, and the database uses 3316 (or whatever your MariaDB already uses).
- **BattlEye, signature checks and client anti-cheat are OFF**, because this is meant for private/LAN play. Turn them on before you open a server to the internet.

---

## 💜 Credits

Made by **Vivi Snowy**. This project stands on the shoulders of the DayZ and Arma modding community. See [CREDITS.md](CREDITS.md) for everyone whose work makes it possible.

If you like it, you can [buy me a coffee on Ko-fi](https://ko-fi.com/vivienne38). Thank you for playing! 💜
