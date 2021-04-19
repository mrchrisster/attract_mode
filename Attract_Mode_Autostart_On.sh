#!/bin/bash

mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

#Create Startup Script

cat <<\EOF > /etc/init.d/_S93attractauto
#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/media/fat/linux:/media/fat/Scripts:.
trap "" HUP
trap "" TERM
start() 
{

printf "Starting Attract Mode Auto"
# Check if at least one Gamepad is connected
if [ ! -f /dev/input/js0 ]; then
{
cat <<\END > /tmp/joysniff.py
#!/usr/bin/env python

import struct
import time
import glob
import sys

packstring = "iiii"

infile_path = sys.argv[1]
EVENT_SIZE = struct.calcsize(packstring)
while True:
    try:
        file = open(infile_path, "rb")
        event = file.read(EVENT_SIZE)
        (x, button_a, y, button_b) = struct.unpack(packstring, event)
        button_a = button_a %10
        button_b = button_b %10
        if button_a != 4 or button_b != 0:
            f = open("/tmp/Attract_Break", "w")
            f.write("Now the file has more content!")
            f.close()
        time.sleep(0.2)
    except FileNotFoundError:
        print("Joystick disconnected")
        sys.exit(1)
END
sync
chmod +x /tmp/joysniff.py
for f in /dev/input/js*; do
/tmp/joysniff.py "$f" &
done
}
	else
		echo "No Joystick connected"
fi
echo $!>/var/run/attractauto.pid
sleep 30 && touch /tmp/Attract_Break
sleep 30
while true; do
 [ "$(/bin/find /tmp/Attract_Break -mmin +5)" ] && /media/fat/Scripts/Attract_Mode.sh
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
echo "Launching in 5s"
sleep 5 && reboot -f
exit 0

