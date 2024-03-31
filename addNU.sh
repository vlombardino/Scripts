#!/bin/bash

# Ask for a new username
add_usr=$(whiptail --title "Create User" --inputbox "Enter Username:" 10 40 3>&1 1>&2 2>&3)

# Check if the user pressed Cancel or entered an empty username
if [ $? -ne 0 ] || [ -z "$add_usr" ]; then
    whiptail --msgbox "User creation canceled. No changes made." 10 40
    exit 1
fi

# Check if the username already exists
  if id "$add_usr" &>/dev/null; then
     whiptail --title "Create User" --msgbox "Username $add_usr already exists. Choose a different username." 10 40
     return
  fi

# Ask for a password for the new user
  add_pass=$(whiptail --title "Create User" --passwordbox "Enter password for $add_usr:" 10 40 --nocancel 3>&1 1>&2 2>&3)
  if [ -z "$add_pass" ]; then
     whiptail --title "Create User" --msgbox "Password cannot be empty. Try again." 10 40
     return
  fi

# Create the new user with password and with or without home directories
  if whiptail --title "Create User" --yesno "Create default home directories for $add_usr?" 10 40; then
     useradd -m -p $(openssl passwd -1 "$add_pass") "$add_usr"
     usermod -aG sudo "$add_usr"
     sudo -u "$add_usr" xdg-user-dirs-update --force
  else
     useradd -m -p $(openssl passwd -1 "$add_pass") "$add_usr"
     usermod -aG sudo "$add_usr"
  fi

# Affirmation on creating new user
  whiptail --title "Create User" --msgbox "User $add_usr created successfully." 10 40