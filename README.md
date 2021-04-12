
# MiSTer Attract Mode
**Have your MiSTer running in the background and enjoy the beautiful pixel art of random games from your library!**  
This script starts a random game from your collection every 2 minutes on your MiSTer FPGA device. Currently Arcade, SNES, Genesis, Neo Geo, Mega CD and PC Engine CD are supported. The script is highly customizable through the supplied ini file (see options below). You can play the game that is being displayed, but it will automatically switch to a new game after 2 mins. Unfortunately we don't have control over user inputs yet, so at this point it's really not meant for interaction, just for show. It's also easy to turn the Attract Mode off: When you're done, perform a *cold reboot* of your MiSTer from the OSD (F12) menu - or use the power button!

## Usage
To cycle through supported all MiSTer cores, copy Attract_Mode.sh and Attract_Mode.ini to /media/fat/Scripts Directory.  

## MiSTer Configuration
The [Update-all](https://github.com/theypsilon/Update_All_MiSTer) script works great for putting your files in the right places.

### USB Storage
/media/usb is may casue issues due to NTFS being case-sensitive on MiSTer.

### Console Cores
Make sure you are using the recommended folder structure, eg /media/fat/Games/SNES/  
The script supports zipped Everdrive packs or unzipped folders  
For MegaCD and Turbografx16 CD your games need to be in CHD format

## Attract Mode Configuration
## Optional features
Included in /Optional/ are several additional scripts. These use Attract_Mode.sh to run but allow you to cycle games from a single system. 

Also included is Lucky_Mode.sh and core-specific scripts. Lucky mode picks a random game and loads it. Great for exploring your collection!

To use these optional features just copy the script(s) you want into the same location as Attract_mode.sh - by default /media/fat/Scripts/.

### Arcade Horizontal or Vertical Only
For a list of only horizontal or vertical Arcade Games, change the "orientation" setting in the Attract_Mode.ini file

### Exclude
If you want to exclude certain games, add the games to mraexclude in the Attract_Mode.ini file

## How it works
Some MiSTer cores like Arcade cores, can be launched from the command line which this script automates. For console games there is no way of loading individual games through the shell at the moment so we need to automate the process by sending button pushes to the MiSTer. This is handled by [pocomane's MiSTer Batch Control](https://github.com/pocomane/MiSTer_Batch_Control). 

## Mister Bug
Currently the Menu Core causes issues where games stop changing and new input is not accepted after a certain time (If 20s timer it takes around an hour to fail). Only physically turning the Mister off fixes this atm.
