#!/bin/bash
pathfs=/media/fat
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

printf "Starting Attract Mode Auto"
# Check if at least one Gamepad is connected
if [ ! -f /dev/input/js0 ]; then
{
cat <<\END > /tmp/joysniff.sh
#!/bin/bash
while true; do
	if [[ $(xxd -l 128 -c 8 ${1} | awk '{ print $4 }' |grep 0100) == "0100" ]]; then
		echo "Button pushed" > /tmp/.Attract_Break
	fi
	sleep 0.2 
done

END
sync
chmod +x /tmp/joysniff.sh
for f in /dev/input/js*; do
/tmp/joysniff.sh "$f" &
done
}
	else
		echo "No Joystick connected"
fi
echo $!>/var/run/attractauto.pid
sleep 30 && touch /tmp/.Attract_Break
sleep 30
while true; do
 [ "$(/bin/find /tmp/.Attract_Break -mmin +3)" ] && /media/fat/Scripts/Attract_Mode.sh
 sleep 3
done
}

stop() 
{
        printf "Stopping Attract Mode Auto"
        kill -9 `attractauto.pid`
        rm /var/run/attractauto.pid
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
#/etc/init.d/S93attractauto start

echo "Attract Mode Auto is on and"
echo "will restart now."
echo ""
echo "Attract Mode Auto starts"
echo "after 2 minutes of inactivity"
echo ""
/etc/init.d/S93attractauto start
echo "Done"

exit 0
