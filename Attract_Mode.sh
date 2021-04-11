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


## Credits
# Original concept and implementation by: mrchrisster
# Additional development by: Mellified
# And thanks to kaloun34 & woelper for contributing!
# https://github.com/mrchrisster/mister-arcade-attract/



## Functions


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

}

mister_clean()
{
			#echo "Restarting MiSTer Menu core, helps with keeping things working"
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

		if [ ! -f "$pathfs"/linux/mbc ] ; then
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
				-o $pathfs/linux/mbc \
				"${REPOSITORY_URL}/blob/feature-rom-mount/mbc?raw=true"
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
				-o $pathfs/linux/partun \
				"${REPOSITORY_URL}/releases/download/0.1.1/partun_armv7"


	}


# ========= ARCADE MODE =========

arcade_exec()
{
	
	parse_cmdline()
	{

		# Load the next core and exit - for testing via ssh
		# Won't reset the timer!
		case "${1}" in
				next)
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

	build_mralist()
	{

		# If the file does not exist make one in /tmp/
		if [ ! -f ${mralist} ]; then
			mralist="/tmp/Attract_Arcade.txt"
		fi
		
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
			find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) | cut -c $(( $(echo ${#mrapath}) + 1 ))- >"${mralist}"
		else
			find "${mrapath}" -maxdepth 1 -type f \( -iname "*.mra" \) | cut -c $(( $(echo ${#mrapath}) + 1 ))- | grep -vFf <(printf '%s\n' ${mraexclude[@]})>"${mralist}"
		fi

	}

	next_core()
	{

		# Get a random game from the list
		mra="$(shuf -n 1 ${mralist})"


		# If the mra variable is valid this is skipped, but if not it'll try 10 times
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

		echo "You'll be playing on Arcade:"
		# Bold the MRA name - remove trailing .mra
		echo -e "\e[1m $(echo $(basename "${mra}") | sed -e 's/\.[^.]*$//') \e[0m"

		if [ "${1}" == "quarters" ]; then
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
		
		next_core quarters
		
	}
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
			if [ -f "$pathfs"/linux/partun ] ; then
				#echo "Partun installed. Launching now"
				snesrom=$($pathfs/linux/partun "$(ls $pathfs/games/snes/\@SN*.zip | shuf -n 1)" -i -r -f sfc --rename $pathfs/games/snes/snestmp.sfc)
			else
				get_partun
				snesrom=$($pathfs/linux/partun "$(ls $pathfs/games/snes/\@SN*.zip | shuf -n 1)" -i -r -f sfc --rename $pathfs/games/snes/snestmp.sfc)
			fi
		fi


		if [ -z "$snesrom" ]; then
			echo "Something went wrong. There is no valid file in snesrom variable."
			exit 1
		fi
		

		echo "You'll be playing on SNES: (currently only shows rom name when archive is unzipped)"
		echo -e "\e[1m $(echo $(basename "${snesrom}") | sed -e 's/\.[^.]*$//') \e[0m"

		if [ "${1}" == "quarters" ]; then
			echo "Loading quarters in..."
			for i in {5..1}; do
				echo "${i} seconds"
				sleep 1
			done
		fi

	  if [ -f "$pathfs"/linux/mbc ] ; then
		
		$pathfs/linux/mbc load_rom SNES "$snesrom" > /dev/null 2>&1
		
	  else
		get_mbc
		$pathfs/linux/mbc load_rom SNES "$snesrom" > /dev/null 2>&1
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
			if [ -f "$pathfs"/linux/partun ] ; then
				#echo "Partun installed. Launching now"
				genesisrom=$($pathfs/linux/partun "$(ls $pathfs/games/genesis/\@Ge*.zip | shuf -n 1)" -i -r -f md --rename $pathfs/games/genesis/genesistmp.md)
			else
				get_partun
				genesisrom=$($pathfs/linux/partun "$(ls $pathfs/games/genesis/\@Ge*.zip | shuf -n 1)" -i -r -f md --rename $pathfs/games/genesis/genesistmp.md)
			fi

		fi


		if [ -z "$genesisrom" ]; then
			echo "Something went wrong. There is no valid file in genesisrom variable."
			exit 1
		fi
		

		echo "You'll be playing on Genesis: (currently only shows rom name when archive is unzipped)"
		echo -e "\e[1m $(echo $(basename "${genesisrom}") | sed -e 's/\.[^.]*$//') \e[0m"


		if [ "${1}" == "quarters" ]; then
			echo "Loading quarters in..."
			for i in {5..1}; do
				echo "${i} seconds"
				sleep 1
			done
		fi

	  # Tell MiSTer to load the next Genesis ROM
	  if [ -f "$pathfs"/linux/mbc ] ; then
		#echo "MBC installed. Launching now"
		$pathfs/linux/mbc load_rom GENESIS "$genesisrom" > /dev/null 2>&1
		
	  else
		get_mbc
		$pathfs/linux/mbc load_rom GENESIS "$genesisrom" > /dev/null 2>&1		
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
			echo "Something went wrong. There is no valid file in genesisrom variable."
			exit 1
		fi
		

		echo "You'll be playing on PC Engine CD"
		echo -e "\e[1m $(echo $(basename "${tgfx16cdrom}") | sed -e 's/\.[^.]*$//') \e[0m"


		if [ "${1}" == "quarters" ]; then
			echo "Loading quarters in..."
			for i in {5..1}; do
				echo "${i} seconds"
				sleep 1
			done
		fi

	  # Tell MiSTer to load the next Genesis ROM
	  if [ -f "$pathfs"/linux/mbc ] ; then
		#echo "MBC installed. Launching now"
		$pathfs/linux/mbc load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1
		
	  else
		get_mbc
		$pathfs/linux/mbc load_rom TURBOCD "$tgfx16cdrom" > /dev/null 2>&1		
	  fi
	}



# ========= GENERAL PREP =========
	
	#Restart MiSTer Menu core every time (bug in MiSTer menu core)
	count=1
	loop_core()
	{
		while [ 1 ]; do
			next_core
			sleep ${timer}
			((count++))
		if [ "$count" == "1" ]; then
			mister_clean
			count=1
		fi
		done
	}
	
	loop_core_all()
	{
		while [ 1 ]; do
			next=$(echo next_core_snes next_core_genesis next_core_tgfx16cd next_core| xargs shuf -n1 -e)
			$next
		sleep ${timer}
		((count++))
		if [ "$count" == "1" ]; then
			mister_clean
			count=1
		fi
		done
	}



# ========= GENERAL EXECUTION =========

	echo "Starting up, please wait a moment"
	parse_ini
	mister_clean
	arcade_exec
	build_mralist
	parse_cmdline ${1}
	there_can_be_only_one ${0}

#Determine if multiple Systems will be included

if [[ $cores == Arcade ]]; then 
	loop_core
	
else
	loop_core_all

fi

exit 0
