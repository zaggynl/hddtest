FreeNAS HDD torture test by The Gecko modified for Linux by zaggynl  
Original FreeNAS script from: https://forums.freenas.org/index.php?threads/how-to-hard-drive-burn-in-testing.21451/page-5#post-191587  
#added:  
-check if tmux is installed, stop if missing  
-stop if no disk specified  
-confirm start as badblocks runs in destructive mode  
  
#What does it do?  
Switch to bash  
Set save path  
Verify disk exists  
Get and display drive model & serial number  
Warn before starting as badblocks runs in destructive mode  
Verify disk not already in use by mount | grep disk  
Verify disk not already under test  
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
 ./drive_burn_in.sh sda  
#Script will disappear into background while it's running as it might take a long while  
To view status: tmux attach -t sda  
To detach: Ctrl+B,D  
To switch between sessions when running multiple test, attach then press Ctrl+B,S, use arrows keys and enter to switch
