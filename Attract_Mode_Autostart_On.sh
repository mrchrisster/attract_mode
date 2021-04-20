#!/bin/bash
basepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	if [ -f ${basepath}/Attract_Mode.ini ]; then
		. ${basepath}/Attract_Mode.ini
		IFS=$'\n'
	fi

mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

#Create Startup Script

cat <<\EOF > /etc/init.d/_S93attractauto
#!/bin/bash
trap "" HUP
trap "" TERM
start() 
{
if [ -f /var/run/attractauto.pid ]; then
	echo "Attract Mode Auto already running"
	exit 1
fi

echo $$>/var/run/attractauto.pid

echo "Started Attract Mode Auto"

# Kill old activity processes
killall -q -9 .SAM_Joy.sh &>/dev/null
killall -q -9 .SAM_Mouse.sh &>/dev/null
killall -q -9 .SAM_Keyboard.sh &>/dev/null

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

# Keyboard activity detection script creation
cat <<\END > /tmp/.SAM_Keyboard.sh
#!/bin/bash
cat /dev/${1} >| /tmp/.SAM_Keyboard_Activity

END

# Mouse activity detection script creation
cat <<\END > /tmp/.SAM_Mouse.sh
#!/bin/bash
cat /dev/input/mice >| /tmp/.SAM_Mouse_Activity

END

sync

# Set execute flag
chmod +x /tmp/.SAM_Joy.sh
chmod +x /tmp/.SAM_Mouse.sh
chmod +x /tmp/.SAM_Keyboard.sh

# Spawn Joystick monitoring processes
rm -f /tmp/.SAM_Joy_Activity
touch /tmp/.SAM_Joy_Activity
for joystick in /dev/input/js*; do
	/tmp/.SAM_Joy.sh "${joystick}" 2>/dev/null &
done

# Spawn Mouse monitoring process
/tmp/.SAM_Mouse.sh 2>/dev/null &

# Spawn Keyboard monitoring process
for keyboard in $(dmesg --decode --level info --kernel --color=never --notime --nopager | grep -e 'Keyboard' | grep -Eo 'hidraw[0-9]+'); do
	/tmp/.SAM_Keyboard.sh "${keyboard}" 2>/dev/null &
done

# Wait for system to fully startup
sleep 60

# Try to find script in the path, use default otherwise
SAMpath=$(which Attract_Mode.sh)
if [ ! -f $(which Attract_Mode.sh) ]; then
	SAMpath="/media/fat/Scripts/Attract_Mode.sh"
fi
	
# Check if we're idle - start Attract Mode if we are
while true; do
 [ "$(/bin/find /tmp/.SAM_Joy_Activity -mmin +5)" ] && ${SAMpath}
 [ "$(/bin/find /tmp/.SAM_Mouse_Activity -mmin +5)" ] && ${SAMpath}
 [ "$(/bin/find /tmp/.SAM_Keyboard_Activity -mmin +5)" ] && ${SAMpath}
 sleep 3
done
}

stop() 
{
        printf "Stopping Attract Mode Auto"
        # Kill old activity processes
				killall -q -9 .SAM_Joy.sh &>/dev/null
				killall -q -9 .SAM_Mouse.sh &>/dev/null
				killall -q -9 .SAM_Keyboard.sh &>/dev/null
				
				# Kill running process
        if [ -f /var/run/attractauto.pid ]; then
        	kill -9 $(cat /var/run/attractauto.pid)
	        rm -f /var/run/attractauto.pid
        fi
        echo "OK"
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
        echo "Usage: /etc/init.d/S93attractauto {start|stop|restart}"
        exit 1
        ;;
esac
exit 0
EOF


mv /etc/init.d/_S93attractauto /etc/init.d/S93attractauto > /dev/null 2>&1
chmod +x /etc/init.d/S93attractauto
sync
[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
sync

/etc/init.d/S93attractauto start &
echo "Attract Mode Auto is now on!"

exit 0
