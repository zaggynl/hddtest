FreeNAS HDD torture test by The Gecko modified for Linux by zaggynl  
Original FreeNAS script from: https://forums.freenas.org/index.php?threads/how-to-hard-drive-burn-in-testing.21451/page-5#post-191587  

#Why are you torturing your disks??  
When you receive a bunch of new disks you want to make sure they are all OK _before_ you put data on them.  
This script runs all SMART tests and then runs badblocks in destructive mode (bye existing data) to test for bad sectors.  

#How do I know if a disk is bad?   
Errors, lots of errors, check the SMART status with hdparm -H /dev/sda (where /dev/sda is the correct device) and check the output of badblocks.   

#Things I changed in the original script:      
-added check if tmux is installed, stop if missing    
-added check if smartctl is installed, stop if missing     
-stop if no disk specified  
-confirm start as badblocks runs in destructive mode 
-removed raw debug setting, not used in Linux?
-removed some commented code that was unused
  
#What does it do?   
Test if tmux and smartctl are installed  
Check if a disk was specified
Set save path  
Verify disk exists  
Save and display drive model & serial number  
Confirm start as badblocks runs in destructive mode  
Check if disk is mounted
Check if this script is not already running for this disk  
Spawn tmux session.  Name tmux session after disk device designation (ie. "sda")  
Create"In-Progress" status file  
Forcibly cancel previous SMART test  
Save SMART details to disk  
Start SMART short test.  Write time stamp of completion to log file.  Sleep until complete.  
Start SMART conveyance test.  Write time stamp of completion to log file.  Sleep until complete.    
Start SMART long test.  Write time stamp of completion to log file.  Sleep until complete.    
Run destructive badblocks test (default settings)  
Start SMART long test.  Write time stamp of completion to log file.  Sleep until complete.   
Save SMART details to disk  
Remove "In-Progress" Status File  
Create "Completed" Status File  
Done  
  
#How to run it?  
Give your pc a drive to hold files.  I mounted a USB drive and set it up as a standard volume with this path: /mnt/SystemDataset  
Put the script in /mnt/SystemDataset  
Open the script and edit the variable 'Save_Path' to fit your environment  
Set the script to be executable\  
Check which disk you want to test:  
hwinfo --disk  
or  
lshw --class disk --class storage  
Run it like this:  
 ./hddtest.sh sda  
#Script will disappear into background while it's running as it might take a long while  
To view status: tmux attach -t sda  
To detach: Ctrl+B,D  
To switch between sessions when running multiple test, attach then press Ctrl+B,S, use arrows keys and enter to switch

#I've canceled the script and now I can't restart it as it says it's already running, what do I do?   
Remove the files it created, they start with the disk model   
