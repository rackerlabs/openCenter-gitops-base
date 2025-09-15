#!/usr/bin/env bash
# Author: Matty < matty91 at gmail dot com >
# Program: create-restart-flag.sh
# Purpose: create a restart required flag if a new kernel or systemd
#          package was installed. Kured can use this flag to schedule
#          staged reboots of your Kubernetes hosts:
#          https://github.com/weaveworks/kured
# Current Version: 1.0
# Last Updated: 03-01-2018
# Version history:
#   1.0 Initial Release
# License:
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.

DEBUG=0
REBOOT_REQUIRED=0
RESTART_CHECK_COMMAND=$(command -v needs-restarting)
RESTART_REQUIRED_FLAG="/var/run/reboot-required"

current_kernel="kernel-$(uname -r)"
newest_kernel=$(rpm -q --last kernel | awk 'NR==1{print $1}')

debug() {
    if [ ${DEBUG} = 1 ]; then
        echo $1
    fi
}

# Compare the latest kernel installed w/ the kernel we are running.
if [[ "${current_kernel}" != "${newest_kernel}" ]]; then
     debug "There is a new kernel that will be activated when the system restarts"
     debug "Current kernel: ${current_kernel}  New kernel: ${newest_kernel}"
     REBOOT_REQUIRED=1
fi

if [[ -x "${RESTART_CHECK_COMMAND}" ]]; then
     if ${RESTART_CHECK_COMMAND} 2>/dev/null | egrep '^[0-9]+ ' > /dev/null; then
         debug "There are several applications that will be updated to new versions when the system restarts"
         REBOOT_REQUIRED=1
     fi
fi

if [ ${REBOOT_REQUIRED} -eq 1 ]; then
     touch ${RESTART_REQUIRED_FLAG}
fi

exit 0
