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


## Default Variables, change in ini
corelist="snes,genesis,tgfx16cd,arcade,megacd"
timer=120
pathfs=/media/fat

# Path to tools. If you don't want the script to download the tools every time, 
# you can change the Path to ${pathfs}/linux for example
mbcpath=/tmp/mbc
partunpath=/tmp/partun
# Match files case-insensitive
#shopt -s nocasematch

# ========= ARCADE OPTIONS =========
mralist=/tmp/.Attract_Mode
mrapath=${pathfs}/_Arcade
mrapathvert="${pathfs}/_Arcade/_Organized/_6 Rotation/_Vertical CW 90 Deg"
mrapathhoriz="${pathfs}/_Arcade/_Organized/_6 Rotation/_Horizontal"
orientation=All


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
	corelist="$(echo ${corelist} | tr ',' ' ')"
}


parse_cmdline()
{
	for argument in "${@}"; do
		case ${argument} in
			snes)
				echo "Super Nintendo Entertainment System selected!"
				declare -g corelist="snes"
				;;
			genesis)
				echo "Sega Genesis selected!"
				declare -g corelist="genesis"
				;;
			tgfx16cd)
				echo "TurboGrafx-16 CD selected!"
				declare -g corelist="tgfx16cd"
				;;
			megacd)
				echo "Sega MegaCD selected!"
				declare -g corelist="megacd"
				;;
			tgfx16)
				echo "TurboGRAFX16 selected!"
				declare -g corelist="tgfx16"
				;;
			arcade)
				echo "MiSTer Arcade selected!"
				declare -g corelist="arcade"
				;;
			neogeo)
				echo "SNK NeoGeo selected!"
				declare -g corelist="neogeo"
				;;
			lucky) # Load one random core and exit with pause
				gonext="get_lucky"
				;;
			next) # Load one random core and exit
				gonext="next_core"
				;;
		esac
	done

	# If we need to go somewhere special next do it here
	if [ ! -z "${gonext}" ]; then
		${gonext}
		exit 0
	fi
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

mister_clean()
{
	# echo "Restarting MiSTer Menu core, helps with keeping things working"
	killall MiSTer > /dev/null 2> /dev/null || :
	/media/fat/MiSTer > /dev/null 2>&1 &
	disown
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
			"${REPOSITORY_URL}/blob/master/mbc?raw=true"
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
		loop_core
	fi

	echo "Next up at the Arcade:"
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
	if [ -z "$(find $pathfs/Games/SNES -maxdepth 1 -type f \( -iname "*.zip" \))" ] 
	then 
		#echo "Your rom archive seems to be unzipped" 
		SNESrom="$(find $pathfs/Games/SNES -type d \( -name *Eu* -o -name *BIOS* -o -name *Other* -o -name *SPC* \) -prune -false -o -name '*.sfc' | shuf -n 1)"
		SNESsh="${SNESrom}"
	else 
		#echo "Need to use partun for unpacking random roms"
		if [ -f "${partunpath}" ]; then
			#echo "Partun installed. Launching now"
			SNESsh=$("${partunpath}" "$(find $pathfs/Games/SNES -maxdepth 1 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f sfc --rename /tmp/SNEStmp.sfc)
			SNESrom=/tmp/SNEStmp.sfc
		else
			get_partun
			SNESsh=$("${partunpath}" "$(find $pathfs/Games/SNES -maxdepth 1 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f sfc --rename /tmp/SNEStmp.sfc)
			SNESrom=/tmp/SNEStmp.sfc
		fi
	fi


	if [ -z "$SNESrom" ]; then
		echo "Something went wrong. There is no valid file in SNESrom variable."
		loop_core
	fi
	
	echo "Next up on the Super Nintendo Entertainment System:"
	echo -e "\e[1m $(echo $(basename "${SNESsh}") | sed -e 's/\.[^.]*$//') \e[0m"


	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  if [ -f "${mbcpath}" ] ; then
	
	"${mbcpath}" load_rom SNES "$SNESrom" > /dev/null 2>&1
	
  else
	get_mbc
	"${mbcpath}" load_rom SNES "$SNESrom" > /dev/null 2>&1
  fi
}


# ========= Genesis MODE =========
next_core_genesis()
{
	# Check if roms are zipped
	if [ -z "$(find $pathfs/Games/Genesis -maxdepth 1 -type f \( -iname "*.zip" \))" ] 
	then 
		#echo "Your rom archive seems to be unzipped" 
		Genesisrom="$(find $pathfs/Games/Genesis -type d \( -name *Eu* -o -name *BIOS* -o -name *Other* -o -name *VGM* \) -prune -false -o -name '*.md' | shuf -n 1)"
		Genesissh="${Genesisrom}"
	else 
		#echo "Need to use partun for unpacking random roms"
		if [ -f ${partunpath} ] ; then
			#echo "Partun installed. Launching now"
			Genesissh=$(${partunpath} "$(find $pathfs/Games/Genesis -maxdepth 1 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f md --rename /tmp/Genesistmp.md)
			Genesisrom=/tmp/Genesistmp.md
		else
			get_partun
			Genesissh=$(${partunpath} "$(find $pathfs/Games/Genesis -maxdepth 1 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f md --rename /tmp/Genesistmp.md)
			Genesisrom=/tmp/Genesistmp.md
		fi

	fi


	if [ -z "$Genesisrom" ]; then
		echo "Something went wrong. There is no valid file in Genesisrom variable."
		loop_core
	fi
	
	echo "Next up on the Sega Genesis:"
	echo -e "\e[1m $(echo $(basename "${Genesissh}") | sed -e 's/\.[^.]*$//') \e[0m"



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
	"${mbcpath}" load_rom GENESIS "$Genesisrom" > /dev/null 2>&1
	
  else
	get_mbc
	"${mbcpath}" load_rom GENESIS "$Genesisrom" > /dev/null 2>&1		
  fi
}

# ========= TGFX16 MODE =========
next_core_tgfx16()
{
	# Check if roms are zipped
	if [ -z "$(find $pathfs/Games/TGFX16 -maxdepth 1 -type f \( -iname "*.zip" \))" ] 
	then 
		#echo "Your rom archive seems to be unzipped" 
		TGFX16rom="$(find $pathfs/Games/TGFX16 -type d \( -name *Eu* -o -name *Bios* -o -name *Music* -o -name *NES2PCE* \) -prune -false -o -name '*.pce' | shuf -n 1)"
		TGFX16sh="${TGFX16rom}"
	else 
		#echo "Need to use partun for unpacking random roms"
		if [ -f ${partunpath} ] ; then
			#echo "Partun installed. Launching now"
			TGFX16sh=$(${partunpath} "$(find $pathfs/Games/TGFX16 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f pce --rename /tmp/TGFX16tmp.pce)
			TGFX16rom=/tmp/TGFX16tmp.pce
		else
			get_partun
			TGFX16sh=$(${partunpath} "$(find $pathfs/Games/TGFX16 -type f \( -iname "*.zip" \) | shuf -n 1)" -i -r -f pce --rename /tmp/TGFX16tmp.pce)
			TGFX16rom=/tmp/TGFX16tmp.pce
		fi

	fi


	if [ -z "$TGFX16rom" ]; then
		echo "Something went wrong. There is no valid file in tgfx16rom variable."
		loop_core
	fi
	
	echo "Next up on the TurboGrafx-16 - AKA PC Engine:"
	echo -e "\e[1m $(echo $(basename "${TGFX16sh}") | sed -e 's/\.[^.]*$//') \e[0m"



	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi


  # Tell MiSTer to load the next TGFX16 ROM
  if [ -f "${mbcpath}" ] ; then
	#echo "MBC installed. Launching now"
	"${mbcpath}" load_rom TURBOGRAFX16 "$TGFX16rom" > /dev/null 2>&1
	
  else
	get_mbc
	"${mbcpath}" load_rom TURBOGRAFX16 "$TGFX16rom" > /dev/null 2>&1		
  fi
}

	
	
# ========= TGFX16-CD MODE =========
next_core_tgfx16cd()
{
	# Check if roms are cue or chd
	if [ -z "$(find $pathfs/Games/TGFX16-CD -type f \( -iname "*.chd" \))" ] 
	then 
		echo "TGFX16-CD: Roms are cue - Not supported yet"
		loop_core
		
	else 
		#echo "Roms are chd" 
		tgfx16cdrom="$(find $pathfs/Games/TGFX16-CD -name '*.chd' | shuf -n 1)"
		#echo $tgfx16cdrom

	fi


	if [ -z "$tgfx16cdrom" ]; then
		echo "Something went wrong. There is no valid file in tgfx16cdrom variable."
		loop_core
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

  # Tell MiSTer to load the next game
  if [ -f "${mbcpath}" ] ; then
		#echo "MBC installed. Launching now"
		"${mbcpath}" load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1
  else
		get_mbc
		"${mbcpath}" load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1
  fi
}

# ========= NEOGEO MODE =========
next_core_neogeo()
{
	# Check if roms are cue or chd
	if [ -z "$(find $pathfs/Games/NEOGEO -type f \( -iname "*.neo" \))" ] 
	then 
		echo "NEOGEO: Not supported format, please use .neo"
		loop_core
		
	else  
		neogeo="$(find $pathfs/Games/NEOGEO -name '*.neo' | shuf -n 1)"

	fi


	if [ -z "$neogeo" ]; then
		echo "Something went wrong. There is no valid file in neogeo variable."
		loop_core
	fi
	

	echo "Next up on the NEO GEO:"
	echo -e "\e[1m $(echo $(basename "${neogeo}") | sed -e 's/\.[^.]*$//') \e[0m"


	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  # Tell MiSTer to load the next game
  if [ -f "${mbcpath}" ] ; then
		#echo "MBC installed. Launching now"
		"${mbcpath}" load_rom NEOGEO "$neogeo" > /dev/null 2>&1
  else
		get_mbc
		"${mbcpath}" load_rom NEOGEO "$neogeo" > /dev/null 2>&1
  fi
}

# ========= MEGA-CD MODE =========

next_core_megacd()
{
	# Check if roms are cue or chd
	if [ -z "$(find $pathfs/Games/megacd -type f \( -iname "*.chd" \))" ] 
	then 
		echo "MegaCD: Roms are cue - Not supported yet"
		loop_core
		
	else 
		#echo "Roms are chd" 
		megacd="$(find $pathfs/Games/MegaCD -name '*.chd' | shuf -n 1)"

	fi


	if [ -z "$megacd" ]; then
		echo "Something went wrong. There is no valid file in megacd variable."
		loop_core
	fi
	

	echo "Next up on the Sega Mega CD"
	echo -e "\e[1m $(echo $(basename "${megacd}") | sed -e 's/\.[^.]*$//') \e[0m"


	if [ "${1}" == "countdown" ]; then
		echo "Loading in..."
		for i in {5..1}; do
			echo "${i} seconds"
			sleep 1
		done
	fi

  # Tell MiSTer to load the next game
  if [ -f "${mbcpath}" ] ; then
		#echo "MBC installed. Launching now"
		"${mbcpath}" load_rom MEGACD "$megacd" > /dev/null 2>&1
  else
		get_mbc
		"${mbcpath}" load_rom MEGACD "$megacd" > /dev/null 2>&1
  fi
}


# ========= GENERAL EXECUTION =========
echo "Starting up, please wait a moment"
parse_ini
build_mralist
parse_cmdline ${@}
there_can_be_only_one ${0}

# Let Mortal Kombat begin!
loop_core

exit 0
