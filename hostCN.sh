#!/bin/bash

# Get the current hostname
current_hostname=$(hostname)

# Ask user for new hostname using whiptail
new_hostname=$(whiptail --inputbox "Current Hostname: $current_hostname\n\nEnter new hostname:" 10 40 3>&1 1>&2 2>&3)

# Check if the user pressed Cancel or entered an empty hostname
if [ $? -ne 0 ] || [ -z "$new_hostname" ]; then
    whiptail --msgbox "Hostname change canceled. No changes made." 10 40
    exit 1
fi

# Change the hostname
sudo hostnamectl set-hostname "$new_hostname"

# Notify the user about the hostname change
whiptail --msgbox "Hostname successfully changed to: $new_hostname" 10 40

# Display the updated hostname
whiptail --msgbox "Updated Hostname: $(hostname)" 10 40