#!/usr/bin/env bash

############################################################
### FUNCTIONS
############################################################
### Test for root user ###
function root_test
{
if [ "$(id -u)" != "0" ];
   then
   clear
   echo "You must be root to use this script!"
   echo
   echo "For example: $ sudo ./usrMGT.sh"
   echo
   read -p "Press enter to exit! " var
   echo
   exit 1
fi
}

### List Users ###
function ls_usrs
{
    # Get a list of users with UID >= 1000
    ls_usrs=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "root" && $1 != "daemon" { print $1 }')

    # Check if there are users to display
    if [ -z "$ls_usrs" ]; then
        whiptail --title "List Users" --msgbox "No eligible users found." 10 60
    else
        # Convert the list of users into a newline-separated string
        ls_usrs=$(echo "$ls_usrs" | tr ' ' '\n')

        # Create an array for Whiptail
        ls_usrsA=()
        while IFS= read -r line; do
            ls_usrsA+=("$line" "")
        done <<< "$ls_usrs"

        # Show a menu to select a user from the list
        usr_info=$(whiptail --title "List User" --menu "Select a user from the list below to show more detailed information:" 20 60 10 "${ls_usrsA[@]}" 3>&1 1>&2 2>&3)

        # Users system information
        if [ -n "$usr_info" ]; then
            user_id_O1=$(id "$usr_info" 2>&1)
            user_id_02=$(cat /etc/passwd | grep "$usr_info")
            msg_info=""$user_id_O1"\n\n"$user_id_02""
            if [ $? -eq 0 ]; then
                whiptail --title "User Information" --msgbox "$msg_info" 10 60
            else
                whiptail --title "User Information" --msgbox "Error getting user information for $usr_info." 10 60
            fi
        else
            # The user cancelled the menu
            whiptail --title "List User" --msgbox "No user selected." 10 60
        fi
    fi
}

### Function to create a new user ###
function add_usr
{
    # Ask for a new username
    add_usr=$(whiptail --title "Create User" --inputbox "Enter Username:" 10 40 3>&1 1>&2 2>&3)
    if [ -z "$add_usr" ]; then
        whiptail --msgbox "Username cannot be empty. Try again." 10 40
        return
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
}

### Function to remove a user and home directory ###
function rm_usr
{
    # Get a list of users with UID >= 1000
    rm_user_ls=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "root" && $1 != "daemon" { print $1 }')

    # Check if there are users to display
    if [ -z "$rm_user_ls" ]; then
        whiptail --title "Remove User" --msgbox "No eligible users found." 10 60
    else
        # Convert the list of users into a newline-separated string
        rm_user_ls=$(echo "$rm_user_ls" | tr ' ' '\n')

        # Create an array for Whiptail
        rm_user_array=()
        while IFS= read -r line; do
            rm_user_array+=("$line" "")
        done <<< "$rm_user_ls"

        # Show a menu to select a user from the list
        rm_user=$(whiptail --title "Remove User" --menu "Select a user from the list below:" 20 60 10 "${rm_user_array[@]}" 3>&1 1>&2 2>&3)

        # Ask for confirmation to continue
        if whiptail --title "Remove User" --yesno "Are you sure you want to remove user: $rm_user and their home directory?" 10 40; then
            # Check if the user selected a valid username
            if [ -n "$rm_user" ]; then
                # Ask for confirmation to back up the home folder
                if whiptail --title "Remove User" --yesno "Do you want to back up the home folder of user: $rm_user?" 10 60; then
                    # Ask for the backup location
                    bak_loc=$(whiptail --title "Remove User" --inputbox "Enter the backup location:" 10 60 "/backup/$rm_user" 3>&1 1>&2 2>&3)
                    
                    # Check if the user entered a backup location
                    if [ -n "$bak_loc" ]; then
                        # Create the backup folder if it doesn't exist
                        mkdir -p "$bak_loc"

                        # Backup the user's home folder
                        tar -czvf "$bak_loc/$rm_user.tar.gz" -C /home "$rm_user"

                        # Kill all processes for user then remove the user
                        pkill -KILL -u $rm_user
                        userdel -r $rm_user

                        # Notify the user
                        whiptail --title "Remove User" --msgbox "User $rm_user removed, and their home folder has been backed up to $bak_loc/$rm_user.tar.gz" 10 60
                    else
                        # User didn't provide a backup location
                        whiptail --title "Remove User" --msgbox "No backup location specified. User $rm_user not removed." 10 60
                    fi
                else
                    # User chose not to back up the home folder
                    pkill -KILL -u $rm_user
                    userdel -r $rm_user
                    whiptail --title "Remove User" --msgbox "User $rm_user and their home folder removed." 10 60
                fi
            else
                # The user cancelled the menu
                whiptail --title "Remove User" --msgbox "No user selected." 10 60
            fi
        else
            # User canceled, no action taken
            whiptail --title "Remove User" --msgbox "Returning to main menu." 10 60
        fi
    fi
}

### Function to change a users password ###
function change_password
{
    # Get a list of users with UID >= 1000
    chg_pass=$(getent passwd | awk -F: '$3 >= 1000 && $1 != "root" && $1 != "daemon" { print $1 }')

    # Check if there are users to display
    if [ -z "$chg_pass" ]; then
        whiptail --title "List Users" --msgbox "No eligible users found." 10 60
    else
        # Convert the list of users into a newline-separated string
        chg_pass=$(echo "$chg_pass" | tr ' ' '\n')

        # Create an array for Whiptail
        chg_pass_array=()
        while IFS= read -r line; do
            chg_pass_array+=("$line" "")
        done <<< "$chg_pass"

        # Show a menu to select a user from the list
        chg_usr_pass=$(whiptail --title "List User" --menu "Select a user from the list below to show more detailed information:" 20 60 10 "${chg_passA[@]}" 3>&1 1>&2 2>&3)

        # Check if the username is empty or if the user canceled
        if [ -z "$chg_usr_pass" ]; then
            whiptail --title "Change Password" --msgbox "No username selected. Returning to main menu." 10 40
        return
        fi
    fi

    # Check if the user exists
    if ! id "$chg_usr_pass" &>/dev/null; then
        whiptail --title "Change Password" --msgbox "Username $chg_usr_pass does not exist." 10 40
        return
    fi

    # Prompt for the new password
    new_pass=$(whiptail --title "Change Password" --passwordbox "Enter the new password for $chg_usr_pass:" 10 40 --nocancel 3>&1 1>&2 2>&3)

    # Check if the new password is empty
    if [ -z "$new_pass" ]; then
        whiptail --title "Change Password" --msgbox "Password cannot be empty. Try again." 10 40
        return
    fi

    # Kill all process for user and change the user's password
    pkill -KILL -u $chg_usr_pass
    echo $chg_usr_pass:$new_pass | chpasswd


    whiptail --title "Change Password" --msgbox "Password for user $chg_usr_pass has been changed." 10 40
}

function change_hostname
{
  # Get current hostname
  current_hostname=$(hostname)

  # Prompt for new hostname
  new_hostname=$(whiptail --title "Change Hostname" --inputbox "Enter the new hostname (lowercase, alphanumeric, hyphens only):" 10 40 "$current_hostname")
  
  # Check if user pressed cancel or entered an empty string
  if [ $? -eq 1 ] || [ -z "$new_hostname" ]; then
    whiptail --title "Error" --msgbox "Hostname change cancelled." 10 40
    return 1
  fi

  # Validate hostname format (lowercase, alphanumeric, hyphens only)
  if [[ ! "$new_hostname" =~ ^[a-z0-9-]+$ ]]; then
    whiptail --title "Error" --msgbox "Invalid hostname format. Please use lowercase letters, numbers, and hyphens only." 10 40
    return 1
  fi

  # Set the new hostname using hostnamectl
  sudo hostnamectl set-hostname "$new_hostname"

  # Update the /etc/hostname file (optional, but recommended for persistence)
  echo "$new_hostname" | sudo tee /etc/hostname > /dev/null

  # Inform the user about the successful change
  whiptail --title "Success" --msgbox "Hostname changed to $new_hostname." 10 40

  # Restart network services to apply the new hostname (optional, but recommended)
  sudo systemctl restart networking.service

  return 0
}

############################################################
### Start Script
############################################################
root_test

### Main menu
while true; do
    usr_mgt_ls=$(whiptail --title "User Management" --menu "Select an option" --nocancel 15 40 8 \
        "1)" "List Users" \
        "2)" "Create User" \
        "3)" "Remove User" \
        "4)" "Change User Password" \
        "5)" "Change hostname" \
        "6)" "Exit" 3>&1 1>&2 2>&3)

    case "$usr_mgt_ls" in
    "1)")
        ls_usrs
        ;;
    "2)")
        add_usr
        ;;
    "3)")
        rm_usr
        ;;
    "4)")
        change_password
        ;;
    "5)")
        change_hostname
        ;;
    "6)")
        exit 0
        ;;
    *)
        whiptail --msgbox "Invalid option. Please try again." 10 40
        ;;
    esac
done