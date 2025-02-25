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
				echo "1"
			elif [[ $noofdevices -ge 3 ]]; then
				echo "5"
			fi

}

raid_array="/dev/md0"

lvmthinvolCreation(){
	luksDevice=$1
	read -p "Name of the vg :" vgname
	vgcreate $vgname $luksDevice
	if [[ $? -eq 0 ]]; then
		if [[ $? -eq 0 ]]; then
			echo "Finally creating thin lvs"
				
		fi
	else
		echo "Vg already exists errors. Exiting..."
		exit 1
	fi
}
luksEncryption(){
	raid_array=$1
	until [[ $(mdadm --detail ${raid_array} | grep -Ei 'Resync Status' | cut -d ':' -f 2 | cut -d '%' -f 1  | sed -r 's/\s//g' | sed -r '/^$/d') -eq 3 ]]; do
	       echo "Syncing drives in progress..."
	       sleep 3
	       echo $(mdadm --detail ${raid_array} | grep -Ei 'Resync Status' | cut -d ':' -f 2 | cut -d '%' -f 1 | sed -r 's/\s//g' | sed -r '/^$/d')
       	done
	cryptsetup luksFormat $raid_array
	read -p "Name of LuksFormatted volume: " luksname
	if [[ -n $luksname ]]; then
		cryptsetup open $raid_array $luksname
		if [[ $? -eq 0 ]]; then
			lvmthinvolCreation "/dev/mapper/$luksname"
		else
		       echo "Error opening $raid_array.Exiting..."
		       exit 1	       
		fi
	fi
}
mdadmRaidCreation(){
	echo "Raid arrays in use $(cat /proc/mdstat | cut -d ':' -f 1 | grep -Ei '^[a-z][A-Z]' | grep -Ei '[0-9]' | sed -r '/^$/d')"	
	read -p "Raid device to be called in mdadm (/dev/md0 /dev/md1) :" raid_array
	raidlevel=$1
	noofdevices=$2
	echo ${devices_list[@]}
	mdadm --create "$raid_array" --level="$raidlevel" --force --raid-devices="$noofdevices" ${devices_list[@]} 2>&1 
	if [[ $? -eq 0 ]]; then
		mdadm --detail $raid_array

		echo "encrypting raid array $raid_array"
	     	
		luksEncryption $raid_array	
	else
		if [[ -n $(mdadm --detail $raid_array | head -n 1 | cut -d ':' -f 1 ) ]]; then
			mdadm --stop $raid_array
			if [[ $? -eq 0 ]]; then
				mdadmRaidCreation $raidlevel $noofdevices
			fi
		else 
			echo "Raid array already exists. Checking /proc/mdstat..."
			echo "Raid arrays in use 	$(cat /proc/mdstat | cut -d ':' -f 1 | grep -Ei '^[a-z][A-Z]' | grep -Ei '[0-9]' | sed -r '/^$/d')"	
		exit 1
		fi
		exit 1
	fi
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
			
			raidlevel=$(getRaidLevel $noofdevices)
			echo $raidlevel
			
			mdadmRaidCreation $raidlevel $noofdevices
			
				
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
