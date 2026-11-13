# Viv's Epoch: full install guide

*Step by step, from nothing to playing.* Made by **Vivi Snowy** · [Back to the README](../README.md)

This guide walks you through everything slowly. If you've installed mods before, the short version in the [README](../README.md) is enough.

**Time needed:** about 30–60 minutes, mostly waiting for downloads.
**You need:** a Windows PC, Steam, and about **12 GB** of free space.

---

## Contents

1. [Download checklist](#1-download-checklist)
2. [Install Arma 2 and Operation Arrowhead](#2-install-arma-2-and-operation-arrowhead)
3. [Find your game folder](#3-find-your-game-folder)
4. [Add the DayZ Epoch client files](#4-add-the-dayz-epoch-client-files)
5. [Add the DayZ Epoch server files](#5-add-the-dayz-epoch-server-files)
6. [Add Viv's Epoch](#6-add-vivs-epoch)
7. [Lingor only: put the map files in Downloads](#7-lingor-only-put-the-map-files-in-downloads)
8. [Run INSTALL.bat](#8-run-installbat)
9. [Play!](#9-play)
10. [Check it's working](#10-check-its-working)
11. [Updating, moving and uninstalling](#11-updating-moving-and-uninstalling)
12. [Troubleshooting](#12-troubleshooting)
13. [FAQ](#13-faq)

---

## 1. Download checklist

Tick these off as you go. Everything is free except the games.

| ✔ | What | File you'll get | Size | Where to get it |
|---|------|-----------------|------|-----------------|
| ☐ | **Arma 2** | (installed by Steam) | about 9 GB for both games | [Steam store](https://store.steampowered.com/app/33900/) |
| ☐ | **Arma 2: Operation Arrowhead** | (installed by Steam) | | [Steam store](https://store.steampowered.com/app/33930/) |
| ☐ | **DayZ Epoch 1.0.7.1 client** | `DayZ_Epoch_Client_1.0.7.1_Release.7z` | about 4.3 GB | [Epoch release page](https://github.com/EpochModTeam/DayZ-Epoch/releases/tag/1.0.7.1) |
| ☐ | **DayZ Epoch 1.0.7.1 server** | `DayZ_Epoch_Server_1.0.7.1_Release.7z` | about 41 MB | [Epoch release page](https://github.com/EpochModTeam/DayZ-Epoch/releases/tag/1.0.7.1). The password is `123456` |
| ☐ | **Viv's Epoch** | `Vivs-Epoch-v1.0.0-Chernarus.zip` and/or `Vivs-Epoch-v1.0.0-Lingor.zip` | under 1 MB | [Releases](https://github.com/Vivi-Snowy/Vivs-Epoch/releases) |
| ☐ | *Lingor only:* **Lingor Island 1.5** | `lingor-1.5.7z` | 200.6 MB | [ModDB](https://www.moddb.com/games/arma-2/addons/jungle-wars-island-of-lingor) |
| ☐ | *Lingor only:* **IBR Plants 1.5** | `ibr_plants-1.5.7z` | 79.3 MB | [ModDB](https://www.moddb.com/games/arma-2/addons/ibr-plants) |
| ☐ | *Lingor only:* **BRG Africa 1.23** | `brg_africa-1.23.7z` | 30.7 MB | [ModDB](https://www.moddb.com/games/arma-2/addons/african-foliage) |

You **don't** need to download these yourself, because the installer handles them:

- **MariaDB 10.11**, the free database the server saves your progress to. The installer offers to download it, or you can get it from [mariadb.org](https://mariadb.org/download/).
- **7-Zip**, for unpacking files. The installer adds it if you don't have it, or you can get it from [7-zip.org](https://www.7-zip.org/).

> 💡 **ModDB tip:** on a ModDB page, click the big **Download Now** button. On the next page, the download starts by itself. Ignore any "Install Now" adverts.

---

## 2. Install Arma 2 and Operation Arrowhead

1. Install **both** games from Steam into the **same Steam library**, for example both on your D: drive.
2. Start **Arma 2: Operation Arrowhead** once from Steam, let it reach the main menu, then quit.
3. In Steam, open Operation Arrowhead's **Properties → Betas** and make sure it's on **None**. The Epoch team says *not* to use beta builds.

---

## 3. Find your game folder

Everything goes into the Operation Arrowhead folder. To open it:

1. In Steam, right-click **Arma 2: Operation Arrowhead**.
2. Click **Manage → Browse local files**.

It's usually something like `C:\Program Files (x86)\Steam\steamapps\common\Arma 2 Operation Arrowhead`. You'll know you're in the right place when you can see **`ArmA2OA.exe`** and **`arma2oaserver.exe`**.

From now on, "**the game folder**" means this folder.

---

## 4. Add the DayZ Epoch client files

1. Open `DayZ_Epoch_Client_1.0.7.1_Release.7z` with 7-Zip.
2. Extract it into **the game folder**.
3. Check that a folder called **`@DayZ_Epoch`** now sits next to `ArmA2OA.exe`.

---

## 5. Add the DayZ Epoch server files

1. Open `DayZ_Epoch_Server_1.0.7.1_Release.7z` with 7-Zip, and type the password **`123456`** when it asks.
2. Inside you'll find a folder called **`Server Files`**. Open it.
3. Select **everything inside** `Server Files` and copy it into **the game folder**.

You'll now have new folders like `@DayZ_Epoch_Server`, `DZE_Server_Config`, `dlls` and `Keys` in the game folder. You don't need to touch them, because the installer sorts out the rest.

---

## 6. Add Viv's Epoch

1. Open the zip you downloaded from [Releases](https://github.com/Vivi-Snowy/Vivs-Epoch/releases): **Chernarus**, **Lingor**, or both, one after the other.
2. Copy **everything inside it** into **the game folder**.
3. When Windows asks about files that already exist, choose **Replace the files in the destination**. That swaps the stock Epoch server files for Viv's Epoch ones.

You should now see **`INSTALL.bat`** in the game folder.

---

## 7. Lingor only: put the map files in Downloads

Leave these three files in your normal **Downloads** folder. Don't unpack them, because the installer does that for you:

- `lingor-1.5.7z`
- `ibr_plants-1.5.7z`
- `brg_africa-1.23.7z`

---

## 8. Run INSTALL.bat

1. Double-click **`INSTALL.bat`** in the game folder.
2. Windows asks *"Do you want to allow this app to make changes?"* Click **Yes**.
3. A blue window works through **7 steps**:

| Step | What it does |
|------|--------------|
| 1/7 | Checks Arma 2, Operation Arrowhead and DayZ Epoch are in place, and moves the Epoch DLLs where they need to be |
| 2/7 | Installs the Microsoft Visual C++ runtimes the database plugin needs |
| 3/7 | Installs **MariaDB**, if you don't already have it. It asks before downloading |
| 4/7 | Makes **fresh random passwords** for your database and admin login |
| 5/7 | Creates the `dayz_epoch` database and its tables |
| 6/7 | Unpacks the **Lingor** map files from your Downloads folder |
| 7/7 | Adds **START** and **PLAY** shortcuts to your **Steam library** |

4. It may ask you a few things:
   - **"Download and install MariaDB now? (Y/N)"**: type `Y` and press Enter.
   - **"Do you also want the LINGOR map? (Y/N)"**: `Y` if you want Lingor.
   - **"Close Steam now? (Y/N)"**: `Y`. Steam closes for a few seconds so the shortcuts can be added, then opens again.
   - *If you already had MariaDB installed*, it asks for the **root password** you chose back then.
5. When you see **"All done!"**, press Enter to close it.

If it says **"Not finished yet"**, read the list underneath. It tells you exactly what's missing and where to get it. Fix that, then run `INSTALL.bat` again. That's safe to do as often as you like, and steps that are already done get skipped.

---

## 9. Play!

1. Make sure **Steam is open and logged in**.
2. In your **Steam library**, start **"DayZ Lingor - 1 START SERVER"** (or the Chernarus one).
   - A small black **server watcher** window opens. **Leave it open.** It keeps the server running and restarts it every 90 minutes.
3. Wait **1–2 minutes** while the server loads.
4. Start **"DayZ Lingor - 2 PLAY"** from Steam. The game opens and joins your server automatically.
5. Pick a spawn point on the map, and good luck out there. 🌴

**To stop:** close the black **watcher** window first, then the server window.

**Admin login:** your admin password is in **`ADMIN_PASSWORD.txt`** in the game folder. In game, open chat and type `#login yourpassword`.

---

## 10. Check it's working

When everything's right, you'll see:

- **In the server window:** `Connected to Steam servers`, then your name joining.
- **In game:** a welcome message, *"Welcome to Viv's Epoch v1.0.0 by Vivi Snowy"*.
- **On the map:** coloured faction territories, trader markers and, after a few minutes, AI mission markers.
- **Top right:** the debug monitor, showing your stats and "Restart in". Right-click your watch to toggle it.

---

## 11. Updating, moving and uninstalling

**Updating to a new version:**
1. Download the new zip from [Releases](https://github.com/Vivi-Snowy/Vivs-Epoch/releases).
2. Close the server and its watcher window.
3. Copy the new zip's contents into the game folder and choose **Replace**.
4. Run `INSTALL.bat` again. Your passwords and saves are kept.

The [CHANGELOG](../CHANGELOG.md) lists what changed in each version.

**Your saves:** characters, bases and vehicles live in the MariaDB database, not in the game folder, so they survive updates.

**Uninstalling:**
1. Remove the four shortcuts from your Steam library: right-click each one, then **Manage → Remove non-Steam game**.
2. Delete these from the game folder: `@DayZ_Epoch`, `@DayZ_Epoch_Server`, `@DayZ_Epoch_Server_Lingor`, `@lingor`, `@ibr_plants`, `@brg_africa`, `DZE_Server_Config`, `DZE_Server_Config_Lingor`, `setup`, `docs`, and the `.bat` and `.txt` files Viv's Epoch added.
3. If you don't use MariaDB for anything else, uninstall it from Windows **Settings → Apps**.

---

## 12. Troubleshooting

| Problem | Fix |
|---------|-----|
| **Kicked as soon as you join**, with `connected (id=ERROR)` or `Player without identity` in the server window | Steam wasn't ready when the server started. Make sure Steam is **fully open and logged in**, close the watcher and server windows, then start **1 START SERVER** again **from Steam**. |
| **"These files must go inside your Arma 2 Operation Arrowhead folder"** | You ran `INSTALL.bat` from the wrong place. Go back to [step 3](#3-find-your-game-folder) and step 6. |
| **"The DayZ Epoch CLIENT/SERVER files are missing"** | Redo [step 4](#4-add-the-dayz-epoch-client-files) or [step 5](#5-add-the-dayz-epoch-server-files), then run `INSTALL.bat` again. |
| **"Could not log in to MariaDB as root"** | You already had MariaDB installed. Run `INSTALL.bat` again and type the root password you chose when you installed it. |
| **"The Lingor map files are not installed yet"** when starting Lingor | Put the 3 Lingor files in Downloads ([step 7](#7-lingor-only-put-the-map-files-in-downloads)) and run `INSTALL.bat` again. |
| **"Missing addons detected: ibr_lingor"** in the server window | Same as above: the Lingor map isn't unpacked. |
| **"Addon ... requires addon ..."** | One of the Lingor downloads is incomplete. Download it again, then run `INSTALL.bat`. |
| **The server window closes straight away** | Open `DZE_Server_Config\arma2oaserver.RPT` (or `DZE_Server_Config_Lingor\...`) in Notepad and look at the last lines for the error. |
| **"Could not connect to MySQL"** in the server log | MariaDB isn't running. Open Windows **Services**, find **MariaDB** and click **Start**, or run `INSTALL.bat` again. |
| **Windows SmartScreen blocks a .bat file** | Click **More info → Run anyway**. They're plain text scripts, so you can open them in Notepad to see exactly what they do. |
| **Steam shortcuts didn't appear** | Restart Steam. If they're still missing, run `INSTALL.bat` again and answer `Y` to closing Steam. |
| **Something else** | Open an [Issue](https://github.com/Vivi-Snowy/Vivs-Epoch/issues) and paste the end of `INSTALL_LOG.txt` and the `.RPT` log. |

---

## 13. FAQ

**Is this multiplayer?**
It's built for playing on your own, or with friends on your home network (LAN). BattlEye and anti-cheat are switched off, so don't open it to the internet as-is.

**Can I play both maps?**
Yes. Each map has its own characters and bases, but your **bank balance is shared** between them. You can even run both servers at the same time.

**Will it mess up my normal Arma 2 or DayZ?**
No. Everything goes in its own folders, and the vanilla game still starts normally from Steam.

**Do I need to keep the downloads?**
No. Once `INSTALL.bat` says "All done!", you can delete the `.7z` files from Downloads.

**Can I change the settings?**
Yes. See *For tinkerers* in the [README](../README.md) and the *Admin* section of the feature guides: [Lingor](LINGOR_FEATURES.md#admin) · [Chernarus](CHERNARUS_FEATURES.md#admin).

**Is it free?**
Completely. If you enjoy it, you can [buy Vivi a coffee on Ko-fi](https://ko-fi.com/vivienne38). 💜
