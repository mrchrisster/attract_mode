#!/bin/bash

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
# This cycles through arcade cores periodically
# Games are randomly pulled from all MRAs or a user-provided list


# ======== Credits ========
# Original concept and implementation by: mrchrisster
# Additional development by: Mellified
# And thanks to kaloun34 & woelper for contributing!
# https://github.com/mrchrisster/mister-arcade-attract/


## Default Variables
cores=All
timer=120
pathfs=/media/fat
mbcpath=/tmp/mbc
partunpath=/tmp/partun


# ========= ARCADE OPTIONS =========
mralist=/tmp/.Attract_Mode
mrapath=${pathfs}/_Arcade
mrapathvert="${pathfs}/_Arcade/_Organized/_6 Rotation/_Vertical CW 90 Deg"
mrapathhoriz="${pathfs}/_Arcade/_Organized/_6 Rotation/_Horizontal"
orientation=All


## Internal Variables - DO NOT CHANGE
count=1


## Basic Functions
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
	if [ "${orientation}" == "Vertical" ]; then
		mrapath="${mrapathvert}"
	elif [ "${orientation}" == "Horizontal" ]; then
		mrapath="${mrapathhoriz}"
	fi
	
	# Setup corelist
	corelist="$(echo $cores | tr ',' ' ')"
}

mister_clean()
{
	# echo "Restarting MiSTer Menu core, helps with keeping things working"
	killall MiSTer > /dev/null 2> /dev/null || :
	/media/fat/MiSTer > /dev/null 2>&1 &
	disown
}

parse_cmdline()
{
	case "${1}" in
		lucky) # Load one random core and exit with pause
			get_lucky
			exit 0
			;;
		next) # Load one random core and exit
			next_core
			exit 0
			;;
	esac
}

there_can_be_only_one()
{
	# If another attract process is running kill it
	# This can happen if the script is started multiple times
	if [ -f /var/run/attract.pid ]; then
		kill -9 $(cat /var/run/attract.pid) &>/dev/null
	fi
	# Save our PID
	echo "$(pidof $(basename ${1}))" > /var/run/attract.pid
}

loop_core()
{
	while :; do
		next_core
		sleep ${timer}
	done
}

next_core()
{
	next=$(echo ${corelist}| xargs shuf -n1 -e)
	next_core_${next} ${1}
}


# Restart MiSTer Menu core every time (bug in MiSTer menu core)
loop_core_reset()
{
	while [ 1 ]; do
		next=$(echo ${corelist}| xargs shuf -n1 -e)
		${next}
		sleep ${timer}
		((count++))
		if [ "${count}" == "1" ]; then
			mister_clean
			count=1
		fi
	done
}


# ========= TOOLS NEEDED FOR CONSOLE CORES =========
get_mbc()
{
	# Downloading Mister Batch Command - launching roms from shell
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
				SSL_SECURITY_OPTION="--insecure"
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

	if [ ! -f "${mbcpath}" ] ; then
		REPOSITORY_URL="https://github.com/mrchrisster/MiSTer_Batch_Control"
		echo "Downloading mbc - a tool needed for launching roms"
		echo "Created for MiSTer by Pocomane"
		echo "${REPOSITORY_URL}"
		echo ""

		curl \
			--connect-timeout 15 --max-time 600 --retry 3 --retry-delay 5 --silent --show-error \
			${SSL_SECURITY_OPTION} \
			--fail \
			--location \
			-o "${mbcpath}" \
			"${REPOSITORY_URL}/blob/feature-rom-mount/mbc?raw=true"
			chmod +x "${mbcpath}"

	else
		echo "Mister Batch Control is installed, continuing..."
	fi
}


get_partun()
{
	# Downloading partun - unzip tool for large zip archives
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
				SSL_SECURITY_OPTION="--insecure"
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

		REPOSITORY_URL="https://github.com/woelper/partun"
		echo "Downloading partun - needed for unzipping roms from big archives."
		echo "Created for MiSTer by woelper"
		echo "${REPOSITORY_URL}"
		echo ""

		curl \
			--connect-timeout 15 --max-time 600 --retry 3 --retry-delay 5 --silent --show-error \
			${SSL_SECURITY_OPTION} \
			--fail \
			--location \
			-o "${partunpath}" \
			"${REPOSITORY_URL}/releases/download/0.1.5/partun_armv7"
			chmod +x "${partunpath}"
}


# ========= ARCADE MODE =========
build_mralist()
{
	# If no MRAs found - suicide!
	find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) &>/dev/null
	if [ ! ${?} == 0 ]; then
		echo "The path ${mrapath} contains no MRA files!"
		exit 1
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

next_core_arcade()
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
		exit 1
	fi

	echo "Next up at the arcade:"
	# Bold the MRA name - remove trailing .mra
	echo -e "\e[1m $(echo $(basename "${mra}") | sed -e 's/\.[^.]*$//') \e[0m"

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


get_lucky()
{
	echo "So you're feeling lucky?"
	echo ""
	
	next_core countdown
}

	
# ========= SNES MODE =========
next_core_snes()
{
	# Check if roms are zipped
	if [ -z "$(find $pathfs/games/snes -maxdepth 1 -type f \( -iname "*.zip" \))" ] 
	then 
		#echo "Your rom archive seems to be unzipped" 
		snesrom="$(find /media/fat/games/snes -type d \( -name *Eu* -o -name *BIOS* -o -name *Other* -o -name *SPC* \) -prune -false -o -name '*.sfc' | shuf -n 1)"
	else 
		#echo "Need to use partun for unpacking random roms"
		if [ -f "${partunpath}" ]; then
			#echo "Partun installed. Launching now"
			snesrom=$("${partunpath}" "$(ls $pathfs/games/snes/\@SN*.zip | shuf -n 1)" -i -r -f sfc --rename $pathfs/games/snes/snestmp.sfc)
		else
			get_partun
			snesrom=$("${partunpath}" "$(ls $pathfs/games/snes/\@SN*.zip | shuf -n 1)" -i -r -f sfc --rename $pathfs/games/snes/snestmp.sfc)
		fi
	fi


	if [ -z "$snesrom" ]; then
		echo "Something went wrong. There is no valid file in snesrom variable."
		exit 1
	fi
	

	echo "Next up on the Super Nintendo Entertainment System:"
	echo -e "\e[1m $(echo $(basename "${snesrom}") | sed -e 's/\.[^.]*$//') \e[0m"

	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  if [ -f "${mbcpath}" ] ; then
	
	"${mbcpath}" load_rom SNES "$snesrom" > /dev/null 2>&1
	
  else
	get_mbc
	"${mbcpath}" load_rom SNES "$snesrom" > /dev/null 2>&1
  fi
}


# ========= GENESIS MODE =========
next_core_genesis()
{
	# Check if roms are zipped
	if [ -z "$(find $pathfs/games/genesis -maxdepth 1 -type f \( -iname "*.zip" \))" ] 
	then 
		#echo "Your rom archive seems to be unzipped" 
		genesisrom="$(find /media/fat/games/genesis -type d \( -name *Eu* -o -name *BIOS* -o -name *Other* -o -name *VGM* \) -prune -false -o -name '*.md' | shuf -n 1)"
	else 
		#echo "Need to use partun for unpacking random roms"
		if [ -f ${partunpath} ] ; then
			#echo "Partun installed. Launching now"
			genesisrom=$(${partunpath} "$(ls $pathfs/games/genesis/\@Ge*.zip | shuf -n 1)" -i -r -f md --rename $pathfs/games/genesis/genesistmp.md)
		else
			get_partun
			genesisrom=$(${partunpath} "$(ls $pathfs/games/genesis/\@Ge*.zip | shuf -n 1)" -i -r -f md --rename $pathfs/games/genesis/genesistmp.md)
		fi

	fi


	if [ -z "$genesisrom" ]; then
		echo "Something went wrong. There is no valid file in genesisrom variable."
		exit 1
	fi
	

	echo "Next up on the Sega Genesis:"
	echo -e "\e[1m $(echo $(basename "${genesisrom}") | sed -e 's/\.[^.]*$//') \e[0m"


	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi


  # Tell MiSTer to load the next Genesis ROM
  if [ -f "${mbcpath}" ] ; then
	#echo "MBC installed. Launching now"
	"${mbcpath}" load_rom GENESIS "$genesisrom" > /dev/null 2>&1
	
  else
	get_mbc
	"${mbcpath}" load_rom GENESIS "$genesisrom" > /dev/null 2>&1		
  fi
}

	
# ========= TGFX16-CD MODE =========
next_core_tgfx16cd()
{
	# Check if roms are cue or chd
	if [ -z "$(find $pathfs/games/tgfx16-cd -type f \( -iname "*.chd" \))" ] 
	then 
		echo "TGFX16-CD: Roms are cue - Not supported yet"
		loop_core_all
		
	else 
		#echo "Roms are chd" 
		tgfx16cdrom="$(find /media/fat/games/TGFX16-CD -name '*.chd' | shuf -n 1)"
		#echo $tgfx16cdrom

	fi


	if [ -z "$tgfx16cdrom" ]; then
		echo "Something went wrong. There is no valid file in tgfx16cdrom variable."
		exit 1
	fi
	

	echo "Next up on the TurboGrafx-16 CD - AKA PC Engine CD:"
	echo -e "\e[1m $(echo $(basename "${tgfx16cdrom}") | sed -e 's/\.[^.]*$//') \e[0m"


	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  # Tell MiSTer to load the next Genesis ROM
  if [ -f "${mbcpath}" ] ; then
		#echo "MBC installed. Launching now"
		"${mbcpath}" load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1
  else
		get_mbc
		"${mbcpath}" load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1
  fi
}


# ========= GENERAL EXECUTION =========
echo "Starting up, please wait a moment"
parse_ini
#	mister_clean
build_mralist
parse_cmdline ${1}
there_can_be_only_one ${0}

# Let Mortal Kombat begin!
loop_core

exit 0
