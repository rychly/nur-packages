#!/bin/bash
# requires: app-emulation/virtualbox(-bin)

if [[ "${1}" == "--help" ]]; then
	echo "Usage: ${0} [<state> <vmname>]" >&2
	echo "List of VirtualBox machines and their states if called without arguments, or toggle a given state of a given virtual machine otherwise." >&2
	echo "It can be utilsied by rofi to control VirtualBox machines." >&2
	exit 1
elif [[ -z $@ ]]; then
	listvms=( $(@VBoxManage@ list vms | sed 's/^"\(.*\)" {[^ ]*}$/\1/g') ) #"
	for vmname in ${listvms[@]}; do
		showvminfo=$(@VBoxManage@ showvminfo "${vmname}")
		# print
		echo "${showvminfo}" | grep -m 1 '^State:[[:space:]]' | sed 's/^[^:]*:\s*\([^()]*\)\(\s\+([^()]*)\)\?$/\1/' | tr ' \n' '- '
		echo "${vmname}"
	done
else
	state="${1%% *}"
	vmname="${1#* }"
	case "${state}" in
		powered-off|saved|aborted)
			@VBoxManage@ startvm "${vmname}"
			;;
		running)
			echo "Saving state of ${vmname}" && @VBoxManage@ controlvm "${vmname}" savestate 2>&1
			;;
	esac | @dunstify-stdout@ "<i>vbox</i>\n" computer 5000
fi
