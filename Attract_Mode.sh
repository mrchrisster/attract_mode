#!/bin/bash

# https://github.com/mrchrisster/mister-arcade-attract/
# Copyright (c) 2021 by mrchrisster and Mellified

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

## Description
# This cycles through arcade and console cores periodically
# Games are randomly pulled from their respective folders

# ======== Credits ========
# Original concept and implementation by: mrchrisster
# Additional development by: Mellified
#
# Thanks for the contributions and support:
# pocomane, kaloun34, RetroDriven, woelper, LamerDeluxe


# ======== DEFAULT VARIABLES ========
# Change these in the INI file
corelist="Arcade,GBA,Genesis,MegaCD,NeoGeo,NES,SNES,TGFX16,TGFX16CD"
timer=120
pathfs=/media/fat

# Path to tools. If you don't want the script to download the tools every time, 
# you can change the Path to ${pathfs}/linux for example
mbcpath=/tmp/mbc
partunpath=/tmp/partun

# ======== ARCADE OPTIONS ========
mralist=/tmp/.Attract_Mode
mrapath=${pathfs}/_Arcade
mrapathvert="${pathfs}/_Arcade/_Organized/_6 Rotation/_Vertical CW 90 Deg"
mrapathhoriz="${pathfs}/_Arcade/_Organized/_6 Rotation/_Horizontal"
orientation=All

# ======== CONSOLE OPTIONS ========
ignorezip="No"
disable_bootrom="Yes"

# ======== CORE CONFIG DATA ========
init_data()
{
	# Core to long name mappings
	declare -gA CORE_PRETTY=( \
		["arcade"]="MiSTer Arcade" \
		["gba"]="Nintendo Game Boy Advance" \
		["genesis"]="Sega Genesis / Megadrive" \
		["megacd"]="Sega CD / Mega CD" \
		["neogeo"]="SNK NeoGeo" \
		["nes"]="Nintendo Entertainment System" \
		["snes"]="Super Nintendo Entertainment System" \
		["tgfx16"]="NEC TurboGrafx-16 / PC Engine" \
		["tgfx16cd"]="NEC TurboGrafx-16 CD / PC Engine CD" \
		)
	
	# Core to file extension mappings
	declare -gA CORE_EXT=( \
		["arcade"]="mra" \
		["gba"]="gba" \
		["genesis"]="md" \
		["megacd"]="chd" \
		["neogeo"]="neo" \
		["nes"]="nes" \
		["snes"]="sfc" \
		["tgfx16"]="pce" \
		["tgfx16cd"]="chd" \
		)
	
	# Core to path mappings
	declare -gA CORE_PATH=( \
		["arcade"]="${mrapath}" \
		["gba"]="${pathfs}/games/GBA" \
		["genesis"]="${pathfs}/games/Genesis" \
		["megacd"]="${pathfs}/games/MegaCD" \
		["neogeo"]="${pathfs}/games/NeoGeo" \
		["nes"]="${pathfs}/games/NES" \
		["snes"]="${pathfs}/games/SNES" \
		["tgfx16"]="${pathfs}/games/TGFX16" \
		["tgfx16cd"]="${pathfs}/games/TGFX16-CD" \
		)
	
	# Can this core use ZIPped ROMs
	declare -gA CORE_ZIPPED=( \
		["arcade"]="No" \
		["gba"]="Yes" \
		["genesis"]="Yes" \
		["megacd"]="No" \
		["neogeo"]="Yes" \
		["nes"]="Yes" \
		["snes"]="Yes" \
		["tgfx16"]="Yes" \
		["tgfx16cd"]="No" \
		)
}


# ======== BASIC FUNCTIONS ========
parse_ini()
{
	basepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	if [ -f ${basepath}/Attract_Mode.ini ]; then
		. ${basepath}/Attract_Mode.ini
		IFS=$'\n'
	fi

	# Remove trailing slash from paths
	for var in pathfs mrapath mrapathvert mrapathhoriz; do
		declare -g ${var}="${!var%/}"
	done

	# Set mrapath based on orientation
	if [ "${orientation,,}" == "vertical" ]; then
		mrapath="${mrapathvert}"
	elif [ "${orientation,,}" == "horizontal" ]; then
		mrapath="${mrapathhoriz}"
	fi
	
	# Setup corelist
	corelist="$(echo ${corelist} | tr ',' ' ')"
}

parse_cmdline()
{
	for arg in "${@}"; do
		case ${arg,,} in
			arcade)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="Arcade"
				;;
			gba)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="GBA"
				;;
			genesis)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="Genesis"
				;;
			megacd)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="MegaCD"
				;;
			neogeo)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="NeoGeo"
				;;
			nes)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="NES"
				;;
			snes)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="SNES"
				;;
			tgfx16cd)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="TGFX16CD"
				;;
			tgfx16)
				echo "${CORE_PRETTY[${arg,,}]} selected!"
				declare -g corelist="TGFX16"
				;;
			lucky) # Load one random core and exit with pause
				gonext="get_lucky"
				;;
			next) # Load one random core and exit
				gonext="next_core"
				;;
		esac
	done

	# If we need to go somewhere special - do it here
	if [ ! -z "${gonext}" ]; then
		${gonext}
		exit 0
	fi
}

there_can_be_only_one() # there_can_be_only_one PID Process
{
	# If another attract process is running kill it
	# This can happen if the script is started multiple times
	if [ ! -z "$(pidof -o ${1} $(basename ${2}))" ]; then
		echo ""
		echo "Removing other running instances of $(basename ${2})..."
		kill -9 $(pidof -o ${1} $(basename ${2})) &>/dev/null
	fi
}


# ======== TOOLS NEEDED FOR CONSOLE CORES ========
curl_check()
{
	ALLOW_INSECURE_SSL="true"
	SSL_SECURITY_OPTION=""
	curl --connect-timeout 15 --max-time 600 --retry 3 --retry-delay 5 \
	 --silent --show-error "https://github.com" > /dev/null 2>&1
	case $? in
		0)
			;;
		60)
			if [[ "${ALLOW_INSECURE_SSL}" == "true" ]]
			then
				declare -g SSL_SECURITY_OPTION="--insecure"
			else
				echo "CA certificates need"
				echo "to be fixed for"
				echo "using SSL certificate"
				echo "verification."
				echo "Please fix them i.e."
				echo "using security_fixes.sh"
				exit 2
			fi
			;;
		*)
			echo "No Internet connection"
			exit 1
			;;
	esac
	set -e
}

curl_download() # curl_download ${filepath} ${URL}
{
		curl \
			--connect-timeout 15 --max-time 600 --retry 3 --retry-delay 5 --silent --show-error \
			${SSL_SECURITY_OPTION} \
			--fail \
			--location \
			-o "${1}" \
			"${2}"
			chmod +x "${1}"
}

get_mbc()
{
	if [ ! -f "${mbcpath}" ] ; then
		REPOSITORY_URL="https://github.com/mrchrisster/MiSTer_Batch_Control"
		echo ""
		echo "Downloading mbc - a tool needed for launching roms"
		echo "Created for MiSTer by Pocomane"
		echo "${REPOSITORY_URL}"
		curl_download "${mbcpath}" "${REPOSITORY_URL}/blob/master/mbc_v02?raw=true"
	else
		echo "Mister Batch Control is installed, continuing..."
	fi
}

get_partun()
{
	if [ ! -f "${partunpath}" ]; then
		REPOSITORY_URL="https://github.com/woelper/partun"
		echo ""
		echo "Downloading partun - needed for unzipping roms from big archives."
		echo "Created for MiSTer by woelper"
		echo "${REPOSITORY_URL}"
		curl_download "${partunpath}" "${REPOSITORY_URL}/releases/download/0.1.5/partun_armv7"
	else
		echo "Partun is installed, continuing..."
	fi
}


# ======== MISTER CORE FUNCTIONS ========
loop_core()
{
	# Remove break trigger file
	#rm -f /tmp/Attract_Break &>/dev/null
	# Kill any leftover break monitoring
	killall -q "cat /dev/input/mice" &
	# Log any mouse activity
	cat /dev/input/mice > /tmp/Attract_Break &
	# Log any joystick activity
	jstest --event /dev/hidraw0 | grep -v "value 3" >  /tmp/Attract_Break &
	
	while :; do
		counter=${timer}
		next_core
		while [ ${counter} -gt 0 ]; do
			sleep 1
			((counter--))
			if [ -s /tmp/Attract_Break ]; then
				echo "Joystick/Mouse activity detected!"
				# Remove break trigger file
				rm -f /tmp/Attract_Break &>/dev/null
				# Kill any leftover break monitoring
				killall -q "cat /dev/input/mice" &
				exit
			fi
		done
	done
}

next_core()
{
	declare -g nextcore=$(echo ${corelist}| xargs shuf -n1 -e)
	
	if [ "${nextcore,,}" == "arcade" ]; then
		load_core_arcade
		return
	elif [ "${CORE_ZIPPED[${nextcore,,}],,}" == "yes" ]; then
		# If not ZIP in game directory OR if ignoring ZIP
		if [ -z "$(find ${CORE_PATH[${nextcore,,}]} -maxdepth 1 -type f \( -iname "*.zip" \))" ] || [ "${ignorezip,,}" == "yes" ]; then
			corerom="$(find ${CORE_PATH[${nextcore,,}]} -type d \( -name *BIOS* -name *Other* -name *VGM* -name *NES2PCE* -name *FDS* -name *SPC* -name Unsupported \) -prune -false -o -name *.${CORE_EXT[${nextcore,,}]} | shuf -n 1)"
		else # Use ZIP
			declare -g coresh=$("${partunpath}" "$(find ${CORE_PATH[${nextcore,,}]} -maxdepth 1 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f ${CORE_EXT[${nextcore,,}]} --rename /tmp/Extracted.${CORE_EXT[${nextcore,,}]})
			corerom="/tmp/Extracted.${CORE_EXT[${nextcore,,}]}"
		fi
	else
		corerom="$(find ${CORE_PATH[${nextcore,,}]} -type f \( -iname *.${CORE_EXT[${nextcore,,}]} \) | shuf -n 1)"
	fi

	if [ -z "${corerom}" ]; then
		core_error "${corerom}"
	else
		if [ -z "${coresh}" ]; then
			load_core "${corerom}" "$(echo $(basename "${corerom}") | sed -e 's/\.[^.]*$//')" "${1}"
		else
			load_core "${corerom}" "$(echo $(basename "${coresh}") | sed -e 's/\.[^.]*$//')" "${1}"
		fi
	fi
}

load_core() 	# load_core /path/to/rom name_of_rom (countdown)
{	
	echo ""
	echo -n "Next up on the "
	echo -ne "\e[4m${CORE_PRETTY[${nextcore,,}]}\e[0m: "
	echo -e "\e[1m${2}\e[0m"
	echo "${2} (${nextcore})" > /tmp/Attract_Game.txt

	if [ "${2}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

	"${mbcpath}" load_rom ${nextcore^^} "${1}" > /dev/null 2>&1
}

core_error() # core_error /path/to/ROM
{
	echo "Something went wrong! No valid game found for core ${nextcore} - rom ${1}."
	return 1
}

disable_bootrom()
{
	if [ "${disable_bootrom}" == "Yes" ]; then
		if [ -d "${pathfs}/Bootrom" ]; then
			mount --bind /mnt "${pathfs}/Bootrom"
			
		else
			echo "Bootrom directory not found"
		fi
	else
		echo "Bootrom directory won't be disabled"
	fi
}

# ======== LUCKY FUNCTION ========
get_lucky()
{
	echo "So you're feeling lucky?"
	echo ""
	next_core countdown
}


# ======== ARCADE MODE ========
build_mralist()
{
	# If no MRAs found - suicide!
	find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) &>/dev/null
	if [ ! ${?} == 0 ]; then
		echo "The path ${mrapath} contains no MRA files!"
		loop_core
	fi
	
	# This prints the list of MRA files in a path,
	# Cuts the string to just the file name,
	# Then saves it to the mralist file.
	
	# If there is an empty exclude list ignore it
	# Otherwise use it to filter the list
	if [ ${#mraexclude[@]} -eq 0 ]; then
		find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) | cut -c $(( $(echo ${#mrapath}) + 2 ))- >"${mralist}"
	else
		find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) | cut -c $(( $(echo ${#mrapath}) + 2 ))- | grep -vFf <(printf '%s\n' ${mraexclude[@]})>"${mralist}"
	fi
}

load_core_arcade()
{
	# Get a random game from the list
	mra="$(shuf -n 1 ${mralist})"

	# If the mra variable is valid this is skipped, but if not we try 10 times
	# Partially protects against typos from manual editing and strange character parsing problems
	for i in {1..10}; do
		if [ ! -f "${mrapath}/${mra}" ]; then
			mra=$(shuf -n 1 ${mralist})
		fi
	done

	# If the MRA is still not valid something is wrong - suicide
	if [ ! -f "${mrapath}/${mra}" ]; then
		echo "There is no valid file at ${mrapath}/${mra}!"
		return
	fi

	echo -n "Next up at the "
	echo -ne "\e[4m${CORE_PRETTY[${nextcore,,}]}\e[0m: "
	echo -e "\e[1m$(echo $(basename "${mra}") | sed -e 's/\.[^.]*$//')\e[0m"
	echo "$(echo $(basename "${mra}") | sed -e 's/\.[^.]*$//') (${nextcore})" > /tmp/Attract_Game.txt

	if [ "${1}" == "countdown" ]; then
		echo "Loading quarters in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  # Tell MiSTer to load the next MRA
  echo "load_core ${mrapath}/${mra}" > /dev/MiSTer_cmd
}


# ======== MAIN ========
echo "Starting up, please wait a minute..."
parse_ini									# Overwrite default values from INI
disable_bootrom									# Disable Bootrom until Reboot 
curl_check									# Check network environment, configure curl
get_partun									# Download ZIP tool
get_mbc											# Download MiSTer control tool
build_mralist								# Generate list of MRAs
init_data										# Setup data arrays
parse_cmdline ${@}					# Parse command line parameters for input
there_can_be_only_one "$$" "${0}"	# Terminate any other running Attract Mode processes
loop_core										# Let Mortal Kombat begin!
exit
