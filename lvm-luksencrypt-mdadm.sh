#!/bin/bash

usage(){
	cat <<EOF
	usage: ./lvm-luksencrypt-mdadm.sh 

		-h : help section
		-d : Partions or devices to be converted (format: -d /dev/sda /dev/sdb | -d /dev/sda1 /dev/sdb2 )
EOF
}
declare -a devices

getRaidLevel(){
if [[ $noofdevices -eq 1 ]]; then
				echo "No raid for 1 device. Exiting..."
				exit 1 	
			elif [[ $noofdevices -eq 2 ]]; then
				echo "mirroring"
			elif [[ $noofdevices -ge 3 ]]; then
				echo "striping with parity raid5"
			fi

}

mdadmRaidCreation(){
	declare -a devices
	raidlevel=$2
	devices=$1

	echo ${devices[@]}
}

while getopts ":hd:" OPTS; do
	case "$OPTS" in
		d)
			noofdevices=0
			devices+=($OPTARG)
			for device in ${devices[@]}; do
				if [[ -e $device ]]; then
					((noofdevices++))
					devices_list+=(${device})
				else
					echo "Not a device exiting"
					exit 1
				fi
			done
			echo "Number of devices $noofdevices"
			echo ${devices_list[@]}
			
			raidlevel=$(getRaidLevel $noofdevices)
			echo $raidlevel
			
			mdadmRaidCreation ${devices_list[@]} $raidlevel	
			
			
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

if [[ $# -ge 1 ]]; then
	echo "Too many arguments exiting"
	usage
	exit 1
fi
