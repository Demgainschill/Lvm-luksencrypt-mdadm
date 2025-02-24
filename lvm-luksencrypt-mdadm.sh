#!/bin/bash

usage(){
	cat <<EOF
	usage: ./lvm-luksencrypt-mdadm.sh 

		-h : help section
		-d : Partions or devices to be converted (format: -d /dev/sda /dev/sdb | -d /dev/sda1 /dev/sdb2 )
EOF
}
declare -a devices

deviceChecker(){
	device=$1

	if [[ -e $device ]]; then
		return 0
	else
		echo "Not a file. Rerun with existing block devices"
		exit 1
	fi
}

while getopts ":hd:" OPTS; do
	case "$OPTS" in
		d)	
			
			devices+=("${OPTARG}")
			if [[ ! -n "$devices" ]]; then 
				echo "No devices specified"
				exit 1
				
			fi
			for device in ${devices[@]}; do
				echo $device
				deviceChecker $device
				if [[ $? -eq 0 ]]; then
					echo "Executing next step..."
					
				fi
			done
			;;
		h)
			usage
			exit 0
			;;
		\?)
			echo "Invalid option"
			exit 1
			usage
			;;
		:)
			echo "Requires argument"
			usage
			exit 1
			;;
	esac
done

if [[ ! -n $1 ]]; then
	echo "No options provided exiting"
	usage
	exit 1
fi

shift $((OPTIND-1))

#if [[ $# -ge 1 ]]; then
#	echo "Too many arguments exiting"
#	usage
#	exit 1
#fi
