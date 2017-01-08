#!/bin/bash
# FreeNAS HDD torture test modified for Linux by zaggynl
# Original FreeNAS script from: https://forums.freenas.org/index.php?threads/how-to-hard-drive-burn-in-testing.21451/page-5#post-191587
# added:
# -check if tmux is installed, break if doesn't
# -stop if no disk specified
# -warning before starting
# exec bash

#check if tmux is installed
command -v tmux >/dev/null 2>&1 || { echo >&2 "I require tmux but it's not installed.  Aborting."; exit 1; }

#check if smartctl(smartmontools) is installed
command -v smartctl >/dev/null 2>&1 || { echo >&2 "I require smartctl but it's not installed.  Aborting."; exit 1; }

#confirm function from https://stackoverflow.com/a/3232082
confirm () {
    # call with a prompt string or use a default
    read -r -p "${1:-THIS WILL WIPE DISK /dev/"$Drive", CONTINUE? [y/N]} " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

#stop if no disk specified
if [ $# -eq 0 ]
  then
    echo "Please specify disk to check, example: sda"
    exit -1
fi

#disk specified, we're starting!

# User Editable Variables
Drive=$1 #use first argument to specify disk
Save_Path=/root #path to save progress and result files

# Test if $Drive exists
if [ $(ls -R /dev/$Drive 2>/dev/null) ]; then
	echo "Found /dev/$Drive!"
else
	echo "Drive /dev/$Drive is not found."
	echo "Exiting..."
	exit -1
fi

# Is disk mounted?
mounted=$(mount | grep /dev/$Drive | wc -l)
if [ $mounted -gt 0 ]; then
        echo "Drive /dev/"$Drive" appears to be mounted, please unmount!"
        exit -1
fi

# Get Drive Details
Drive_Model=$(smartctl -a /dev/$Drive | grep "Device Model" | awk '{print $4}')
Drive_Serial_Number=$(smartctl -a /dev/$Drive | grep "Serial" | awk '{print $3}')
echo Drive_Model=$Drive_Model
echo Drive_Serial_Number=$Drive_Serial_Number


#don't show wipe warning when entering TMUX
if ! [ -n "$TMUX" ]; then
	#badblocks test will wipe the specified disk, warn user!
	if ! confirm; then exit
	fi
fi

# Test if the "In-Progress" file already exists
File_Count=$(ls -lR *$Drive_Serial_Number*In-Progress 2>/dev/null | wc -l)
if [ $File_Count -gt 0 ]; then
	echo "Cannot begin new test on $1.  Test already in progress"
	exit -1
fi

# Test if inside TMUX already
if [ -n "$TMUX" ]; then 
	echo "Inside TMUX.  Continuing Execution..."; 
else
	echo "Spinning up new TMUX Session '$1' and exiting."
	Command="$(readlink -nf $0) $1"
	echo "Parameters: tmux new-session -s $1 -d '$Command'"
	tmux new-session -s $1 -d "$Command"
	tmux ls
	exit
fi

# Create "In-Progress" Status File
In_Progress_File_Name=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_In-Progress"
touch $In_Progress_File_Name


# Cancel previous test
echo Canceling any running smartctl tests for drive /dev/$Drive
smartctl -X /dev/$Drive 2>/dev/null -q silent

# Save SMART Details to Disk
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive
touch $Save_File"_SMART_Details.txt"
smartctl -a /dev/$Drive > $Save_File"_SMART_Details.txt"


# Start short self-test
CompleteDate="$(smartctl -t short /dev/$Drive | grep after)"
CompleteDate=${CompleteDate#*after*}
echo Performing Short Self-Test on $Drive_Model S/N:$Drive_Serial_Number
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_SMART_Test_Short"
echo $CompleteDate > $Save_File
# Sleep during self-test
echo SMART Short Self-test will finish at: $CompleteDate
current_epoch=$(date +%s)
target_epoch=`date -d"$CompleteDate" +%s`
sleep_seconds=$(( $target_epoch - $current_epoch + 2))
sleep $sleep_seconds
echo SMART short test completed
echo
echo 


# Start conveyance self-test
# Sleep during self-test
CompleteDate=$(smartctl -t conveyance /dev/$Drive | grep after | cut -c 25-100)
echo Performing Conveyance Self-Test on $Drive_Model S/N:$Drive_Serial_Number
echo SMART Conveyance Self-test will finish at: $CompleteDate
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_SMART_Test_Conveyance"
echo $CompleteDate > $Save_File
current_epoch=$(date +%s)
target_epoch=`date -d"$CompleteDate" +%s`
sleep_seconds=$(( $target_epoch - $current_epoch + 2))
#smartctl -X /dev/$Drive
sleep $sleep_seconds
echo SMART conveyance test completed
echo
echo

# Start long self-test
# Sleep during self-test
#clear
CompleteDate=$(smartctl -t long /dev/$Drive | grep after | cut -c 25-100)
echo Performing Long Self-Test on $Drive_Model S/N:$Drive_Serial_Number
echo SMART Long Self-test will finish at: $CompleteDate
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_SMART_Test_Long"
echo $CompleteDate > $Save_File
current_epoch=$(date +%s)
target_epoch=`date -d"$CompleteDate" +%s`
sleep_seconds=$(( $target_epoch - $current_epoch + 2))
sleep $sleep_seconds
echo SMART long test completed
echo
echo

# Start Destructive BadBlocks test
# NOTE:  This is a blocking command.  Additional commands
#        will not run until this command is finished.
#        No need to use a sleep command.
echo Performing Destructive BadBlocks Test on $Drive_Model S/N:$Drive_Serial_Number
echo This test may take days to complete.
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_BadBlocks"
echo "tmux attach -t $Drive" > $Save_File
badblocks -wsv /dev/$Drive >> $Save_File
echo
echo

# Start long self-test
# Sleep during self-test
CompleteDate=$(smartctl -t long /dev/$Drive | grep after | cut -c 25-100)
echo Performing Long Self-Test \#2 on $Drive_Model S/N:$Drive_Serial_Number
echo SMART Long Self-Test \#2 will be finished at: $CompleteDate
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_SMART_Test_Long"
echo $CompleteDate > $Save_File
current_epoch=$(date +%s)
target_epoch=`date -d"$CompleteDate" +%s`
sleep_seconds=$(( $target_epoch - $current_epoch + 2))
sleep $sleep_seconds
echo SMART long test 2 completed
echo
echo

# Save SMART Details to Disk
Save_File=$Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive
touch $Save_File"_SMART_Details.txt"
smartctl -a /dev/$Drive > $Save_File"_SMART_Details.txt"

# Remove "In-Progress" Status File
rm $In_Progress_File_Name

# Create "Completed" Status File
touch $Save_Path/$Drive_Model"_"$Drive_Serial_Number"_"$(date -u +"%Y-%m-%dT%H.%M.%SZ")"_"$Drive"_Completed"
#fi from yes/no at top
fi
