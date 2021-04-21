#!/bin/bash
/etc/init.d/S93attractauto stop
mount | grep -q "on / .*[(,]ro[,$]" && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
mv /etc/init.d/S93attractauto /etc/init.d/_S93attractauto > /dev/null 2>&1
sync
[ "$RO_ROOT" == "true" ] && mount / -o remount,ro

echo "Screensaver is off and"
echo "inactive at startup."
echo "Done!"
sync
exit 0