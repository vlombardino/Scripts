#!/bin/bash

############################################################
### FUNCTIONS
############################################################
### Test for root user ###
function ROOTTEST
{
if [ "$(id -u)" != "0" ]; 
   then
   clear
   echo "You must be root to use this script!"
   echo
   echo -e "For example: ${YELLOW}sudo ./crd.sh${NC}"
   echo
   read -p "Press enter to exit! " var
   echo
   exit 1
	
fi
}

### Check if user exist
function USEREXIST
{
read -p "Type in a current user account here: " USERACCOUNT
while grep "$USERACCOUNT" /etc/passwd > /dev/null; do
read -p "No such user. Try again: " USERACCOUNT
done
}

### Change default Gnome to Ubuntu Gnome ###
function USESSION
{
sudo -u "$USERACCOUNT" bash -c 'cat << EOF >> ~/.xsessionrc
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg
EOF'
}

############################################################
### Start Script
############################################################

ROOTTEST

set -eo pipefail

### Add additional software
echo $(printf '#%.0s' {1..50})
echo "Checking and/or installing [openssh-server, vim, wget]"
sudo DEBIAN_FRONTEND=noninteractive \
sudo apt update && sudo apt install openssh-server vim wget -y
echo

### Download and installing CRD
echo $(printf '#%.0s' {1..50})
echo "Downloading and installing Chrome Remote Desktop" 
sudo wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo dpkg -i chrome-remote-desktop_current_amd64.deb
sudo apt install -y --fix-broken || true
sudo rm chrome-remote-desktop_current_amd64.deb
echo

### Download and install Chrome
echo $(printf '#%.0s' {1..50})
echo "Downloading and installing Chrome"
sudo wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | \
sudo gpg --dearmour -o /usr/share/keyrings/google-chrome.gpg
echo deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main | \
sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install google-chrome-stable -y
sudo apt install -y --fix-broken
echo

### Set CRD session to use Gnome
echo $(printf '#%.0s' {1..50})
echo "Setting Chrome Remote Desktop to use Gnome"
sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/gnome-session" > /etc/chrome-remote-desktop-session'
echo

### Disable gdm3 service
echo $(printf '#%.0s' {1..50})
echo "Disabling gdm3. No GUI after boot"
sudo systemctl disable gdm3.service
echo

### Add User
echo $(printf '#%.0s' {1..50})
echo "Change default Gnome to Ubuntu Gnome"
USEREXIST
USESSION
echo

### Check if CRD service is running
echo $(printf '#%.0s' {1..50})
echo "Check if Chrome Remote Desktop is running for $USERACCOUNT"
sudo -u "$USERACCOUNT" systemctl status chrome-remote-desktop@$USER
echo

### Reboot system
echo $(printf '#%.0s' {1..50})
read -p "The system needs to reboot. Press enter to reboot"
sudo reboot