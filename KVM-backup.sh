#!/bin/bash

####################
##### Variables ####
# Define temporary backup directory
### Workstation
#backup_dir_temp="/mnt/data/backup"
### Server
backup_dir_temp="/srv/data/backup"

# Define system user to move files
### Workstation
#backup_user="local_admin"
### Server
backup_user="admin"

# Define if default storage pool has alternative location 
#image_dir="/mnt/data/share/libvirt/images"

# Define final backup location
backup_dir_final="/srv/Backup/vm"

# Define log file location
log_file="/var/log/kvm-backup.log"
####################

####################
##### Functions ####
# Function to do a sudo test
sudo_test()
{
    if [ "$(id -u)" != "0" ];
       then
       clear
       echo "You must be root to use this script!"
       echo
       echo "For example: $ sudo bash /opt/scripts/kvm-backup.sh"
       echo
       read -p "Press enter to exit! " var
       echo
       exit 1
    fi
}

# Function to log messages to both the console and the log file
log_message()
{
    local message="$1"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $message" | tee -a "$log_file"
}
####################

####################
### Start Script ###
sudo_test

# Check if backup_dir_final exists using backup_user
if su - "$backup_user" -c "[ -d '$backup_dir_final' ]"; then
    log_message "$backup_dir_final exists. Proceeding with the backup process."
else
    log_message "Error: $backup_dir_final does not exist. Exiting script."
    exit 1
fi

# Get a list of all VMs
all_vm_list=$(virsh list --all --name)

log_message "Starting VM backup process..."

# Create the temporary backup directory
mkdir -p "$backup_dir_temp"

# Loop through each VM and perform backup
for vm_name in $all_vm_list; do
    # Get name of source file with correct extension
    vm_source=$(virsh domblklist "$vm_name" --details | awk '/disk/{print $4}')

    log_message "VM Source for $vm_name: $vm_source"
    log_message "Backing up VM: $vm_name"

    # Check if the VM is running
    is_running=$(virsh domstate "$vm_name" | grep -c "running")
    log_message "$vm_name is running"

    # Stop the VM if it's running
    if [ "$is_running" -gt 0 ]; then
        log_message "Stopping $vm_name"
        virsh shutdown "$vm_name"
        sleep 10  # Wait for the VM to stop gracefully
    fi

    # Backup the VM image to the temporary directory
    log_message "Copying $vm_name to $backup_dir_temp/$vm_name"
    rsync -a --info=progress2 "$image_dir/$vm_source" "$backup_dir_temp/$vm_name/"

    # Dump the configuration information.
    log_message "Backup up config [xml] file for $vm_name to $backup_dir_temp/$vm_name"
    virsh dumpxml "$vm_name" > "$backup_dir_temp/$vm_name/$vm_name.xml"

    # Start the VM only if it was running
    if [ "$is_running" -gt 0 ]; then
        log_message "Starting $vm_name"
        virsh start "$vm_name"
    fi

    # Create a tar archive of the entire VM backup folder as backup_user
    log_message "Archiving $vm_name"
    tar_file="$backup_dir_temp/${vm_name}_$(date "+%Y%m%d").tar.gz"
    tar -czvf "$tar_file" -C "$backup_dir_temp" "$vm_name"

    # Change file ownership to backup_user
    log_message "Changing ownership for [$backup_dir_temp] to user:$backup_user"
    chown -R "$backup_user:$backup_user" "$backup_dir_temp"

    # Rsync the compressed archive to the final backup directory using defined user and show progress
    log_message "Moving $vm_name to [$backup_dir_final]"
    su - "$backup_user" -c "rsync -a --info=progress2 '$tar_file' '$backup_dir_final/'"

    # Cleanup: Remove the temporary backup directory and archived
    log_message "Removing temporary backup directory and archive for $vm_name."
    rm -rf "$backup_dir_temp/$vm_name/"
    rm -rf "$tar_file"
    
    # Message for completion
    log_message "Backup for VM $vm_name completed."
done

# Cleanup: Remove the temporary backup directory
log_message "Removing temporary backup directory."
rm -rf "$backup_dir_temp"
####################