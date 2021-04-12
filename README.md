# Mister Attract Mode
This script starts a random game from your collection (currently Arcade, SNES, Genesis and PC Engine CD) every 2 minutes on your MiSTer FPGA device. Have your MiSTer running in the background and enjoy the beautiful pixel art of your favorite games! The script is highly customizable through the supplied ini file (see options below). You can play the game that is being displayed, but it will automatically switch to a new game after 2 mins. Unfortunately we don't have control over user inputs yet, so at this point it's really not meant for interaction, just for show. It's also easy to turn the Attract Mode off: When you're done, perform a *cold reboot* of your MiSTer from the OSD (F12) menu - or use the power button!

# Usage
To cycle through supported all MiSTer cores, copy Attract_Mode.sh and Attract_Mode.ini to /media/fat/Scripts Directory.  
Attract_Mode.ini is needed in order to use the script.

# Some notes about cores
Arcade core will work on most systems out of the box while console cores are a bit more tricky to get working.

For Console cores make sure you are using the recommended folder structure, eg /media/fat/Games/SNES/  
The script supports zipped Everdrive packs or unzipped folders  
For MegaCD and Turbografx16 CD your games need to be in CHD format

/media/usb is currently untested and might casue issues due to NTFS being case-sensitive on MiSTer

## Horizontal or Vertical Only
For a list of only horizontal or vertical Arcade Games, change the "orientation" setting in the Attract_Mode.ini file

## Exclude
If you want to exclude certain games, add the games to mraexclude in the Attract_Mode.ini file

Make sure you have your Arcade roms setup correctly. [Update-all](https://github.com/theypsilon/Update_All_MiSTer) script works great for that.

# Feeling Lucky?
Included is FeelLucky_Arcade.sh, which is a fun way to explore your MiSTer arcade library. The script loads a single random arcade game. Play and enjoy!

# Mister Bug
Currently the Menu Core causes issues where games stop changing and new input is not accepted after a certain time (If 20s timer it takes around an hour to fail). Only physically turning the Mister off fixes this atm.
