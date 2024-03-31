#!/bin/bash

### Check if ed25519 key exists, if not generate one
if [[ ! -f /root/.ssh/id_ed25519 ]]; then
    ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""
fi

### Remote server IP or NAME
while [[ -z $SERVADD ]]; do
    read -p "Please enter the remote server name or IP: " SERVADD
done

### Remote server USER
while [[ -z $SERVUSER ]]; do
    read -p "Please enter the remote server username: " SERVUSER
done

### Check if keys have previously been exchanged
if ssh -o BatchMode=yes -o ConnectTimeout=5 $SERVUSER@$SERVADD true 2>/dev/null; then
    echo "Keys have already been exchanged. Exiting."
    exit 1
fi

### Exchange keys
ssh-copy-id -f -o StrictHostKeyChecking=no -i /root/.ssh/id_ed25519.pub $SERVUSER@$SERVADD

### Update known_hosts file
ssh-keyscan -H $SERVADD >> ~/.ssh/known_hosts

echo "Keys successfully exchanged and known_hosts file updated."