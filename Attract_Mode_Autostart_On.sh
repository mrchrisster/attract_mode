#!/bin/bash

# Find the ini file
basepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	if [ -f ${basepath}/Attract_Mode.ini ]; then
		. ${basepath}/Attract_Mode.ini
		IFS=$'\n'
	fi

# Remount root as read-write if read-only so we can add our daemon
mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

# Summon daemon
cat <<\EOF > /etc/init.d/_S93mistersam
#!/bin/bash
trap "" HUP
trap "" TERM

start()
{
#========= VARIABLES =========
timeoutmins=1

#======== Start ========
echo -n "Starting MiSTer SAM... "

# Kill running process
if [ ! -z "$(pidof -o $$ $(basename ${0}))" ]; then
	echo ""
	echo "Removing other running instances of daemon..."
	kill -9 $(pidof -o $$ $(basename ${0})) &>/dev/null
fi

# Kill old activity processes
killall -q -9 .SAM_Joy.sh
killall -q -9 .SAM_Mouse.sh
killall -q -9 .SAM_Keyboard.sh

# Joystick activity detection script creation
cat <<\END > /tmp/.SAM_Joy.sh
#!/bin/bash
while true; do
	if [[ $(xxd -l 128 -c 8 ${1} | awk '{ print $4 }' | grep 0100) == "0100" ]]; then
		echo "Button pushed" >| /tmp/.SAM_Joy_Activity
	fi
	sleep 0.2 
done
END
# End of joystick script

# Keyboard activity detection script creation
cat <<\END > /tmp/.SAM_Keyboard.sh
#!/bin/bash
while true; do
	if [[ $(xxd -l 8 -c32 "/dev/${1}" | cut -c1) == "0" ]]; then
		echo "Keyboard used" >| /tmp/.SAM_Keyboard_Activity
	fi
	sleep 0.2
done
END
# End of keyboard script

# Mouse activity detection script creation
cat <<\END > /tmp/.SAM_Mouse.sh
#!/bin/bash
while true; do
	if [[ $(xxd -l 8 -c32 /dev/input/mice | cut -c1) == "0" ]]; then
		echo "Mouse moved" >| /tmp/.SAM_Mouse_Activity
	fi
	sleep 0.2
done
END
# End of mouse script

# Scripts done
sync

# Set execute flag
chmod +x /tmp/.SAM_Joy.sh
chmod +x /tmp/.SAM_Mouse.sh
chmod +x /tmp/.SAM_Keyboard.sh

# Reset activity logs
rm -f /tmp/.SAM_Joy_Activity /tmp/.SAM_Mouse_Activity /tmp/.SAM_Keyboard_Activity
touch /tmp/.SAM_Joy_Activity /tmp/.SAM_Mouse_Activity /tmp/.SAM_Keyboard_Activity

# Spawn Joystick monitoring process per detected joystick device
for joystick in /dev/input/js*; do
	/tmp/.SAM_Joy.sh "${joystick}" &
done

# Spawn Mouse monitoring process
/tmp/.SAM_Mouse.sh &

# Spawn Keyboard monitoring per detected keyboard device
for keyboard in $(dmesg --decode --level info --kernel --color=never --notime --nopager | grep -e 'Keyboard' | grep -Eo 'hidraw[0-9]+'); do
	/tmp/.SAM_Keyboard.sh "${keyboard}" &
done

# Setup done
echo "OK"
echo ""

# Wait for system to fully startup
#sleep 60

# Try to find script in the path, use default otherwise
SAMpath=$(which Attract_Mode.sh)
if [ ! -f $(which Attract_Mode.sh) ]; then
	SAMpath="/media/fat/Scripts/Attract_Mode.sh"
fi
	
# Check if system is idle for ${timeoutmins} - start Attract Mode if we are
while :; do
	if [ "$(/bin/find /tmp/.SAM_Joy_Activity -mmin +${timeoutmins})" ] && [ "$(/bin/find /tmp/.SAM_Mouse_Activity -mmin +${timeoutmins})" ] && [ "$(/bin/find /tmp/.SAM_Keyboard_Activity -mmin +${timeoutmins})" ]; then
		# Reset activity triggers
		echo "" |>/tmp/.SAM_Joy_Activity
		echo "" |>/tmp/.SAM_Mouse_Activity
		echo "" |>/tmp/.SAM_Keyboard_Activity
		"${SAMpath}"
		# Reset activity triggers
		echo "" |>/tmp/.SAM_Joy_Activity
		echo "" |>/tmp/.SAM_Mouse_Activity
		echo "" |>/tmp/.SAM_Keyboard_Activity
	fi
	sleep 3
done
}

stop() 
{
        echo -n "Stopping MiSTer SAM... "
        # Kill old activity processes
				killall -q -9 .SAM_Joy.sh &>/dev/null
				killall -q -9 .SAM_Mouse.sh &>/dev/null
				killall -q -9 .SAM_Keyboard.sh &>/dev/null
				
				# Kill running process
				kill -9 $(pidof -o $$ $(basename ${0})) &>/dev/null

        echo "OK"
        echo ""
}
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: /etc/init.d/S93mistersam {start|stop|restart}"
        exit 1
        ;;
esac
exit 0
EOF
# Daemon is in this etheral plane

# Awaken daemon
mv /etc/init.d/_S93mistersam /etc/init.d/S93mistersam > /dev/null 2>&1
chmod +x /etc/init.d/S93mistersam

# Remove read-write if we were read-only
sync
[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
sync

# Gentlemen... start your engines!
/etc/init.d/S93mistersam start &
exit 0
