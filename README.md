
# MiSTer Attract Mode
**Enjoy the wonderful pixel art and sounds from the games in your MiSTer library - automatically!**

## Usage
Attract Mode is a script which starts a random game on the MiSTer FPGA. The script is highly customizable through the included ini file (details below). Games can be played in Attract Mode, but the next game loads automatically after 2 minutes *unless you wiggle the mouse!* If you don't have a mouse connected you'll need to ***cold reboot*** your MiSTer from the OSD (F12) menu, or use the power button.

## Installation
To cycle through the supported MiSTer cores, copy `Attract_Mode.sh` and `Attract_Mode.ini` to `/media/fat/Scripts` Directory. The INI is optional, but strongly recommended if you want to customize behavior.

## Supported Systems
Currently supported MiSTer cores:
* Arcade
* Game Boy Advance
* Genesis
* MegaCD AKA SegaCD
* NeoGeo
* NES
* SNES
* TurboGrafx-16 AKA PC Engine
* TurboGrafx-16 CD AKA PC Engine CD

## MiSTer Configuration
The [Update-all](https://github.com/theypsilon/Update_All_MiSTer) script works great for putting system files in the right places.

## Attract Mode Configuration
### Optional features
Included in `/Optional/` are several additional scripts. These require `Attract_Mode.sh` to run.

Each Attract_Mode_*system*.sh script cycles games from just that one system - not all of them.

Also included is `Lucky_Mode.sh` and corresponding system-specific Lucky_Mode_*system*.sh scripts. Lucky mode picks a random game and loads it - no timer to worry about! This is a great way to explore and play your collection.

To use these options just copy the optional script(s) you want into the same location as Attract_mode.sh - by default `/media/fat/Scripts/`.

### Arcade Horizontal or Vertical Only
Change the "orientation" setting in the `Attract_Mode.ini` file to choose from only horizontal or vertical arcade games.

### Exclude
Want to exclude certain arcade games? Just add them to `mraexclude` in the `Attract_Mode.ini` file.

## How it works
MiSTer arcade cores are launched via a MiSTer command. For console games there is no official way to load individual games programmatically. Attract Mode automates the process by sending simulated button presses to the MiSTer. This is done with a modified version of [pocomane's MiSTer Batch Control](https://github.com/pocomane/MiSTer_Batch_Control). 
  
If you would like to know what game is currently playing, you can either run the script through SSH or check the file `/tmp/Attract_Game.txt`  
  
## Troubleshooting
**- Core is loaded but just hangs on the menu**  
Make sure you are using the recommended folder structure, such as /media/fat/Games/SNES/. The script supports zipped Everdrive packs or unzipped folders. For MegaCD and Turbografx16 CD games must be in CHD format. We noticed that some MegaCD games that the script is trying to load also won't work when loaded through the MiSTer interface.
  
**- Problem with controller not accepting input after running the script for a long time**  
Currently the Menu Core causes issues where games stop changing and new input is not accepted after a certain time (If 20s timer it takes around an hour to fail). Unfortunately, only physically turning the Mister off fixes this. The issue is [under investigation](https://github.com/MiSTer-devel/Main_MiSTer/issues/379).  
  
**- Sometimes NeoGeo doesn't load a rom and hangs on the menu**   
Still investigating why this is happening.
  
**- USB Storage**  
/media/usb is not well tested. NTFS formatted drives may experience issues because NTFS is case-sensitive on MiSTer.

**- Turbografx16 CD just showing Run button but not starting into the game**  
Make sure you use a bios that auto launches the game  

**- Can I use a CIFS mount for my games?**  
CIFS is supported.
Here is an example of some values in `cifs_mount.sh` that should get you started:  
```
SERVER="192.168.1.10"  
SHARE="Games/Mister/Games"  
LOCAL_DIR="*"  
BASE_PATH="/media/fat/Games" 
```
