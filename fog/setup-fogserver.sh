#!/usr/bin/bash

# Author: Kon Papazis <koncybernet@gmail.com>
# Purpose: Install and setup FOG Server
# Usage: ./setup-fogserver.sh

DEBUG="false"
[[ "${DEBUG}" == 'true' ]] && set -o xtrace # Enable xtrace if the DEBUG environment variable is set
set -o errexit # abort on nonzero exitstatus
set -o pipefail # don't hide errors within pipes
set -o nounset # abort on unbound variable

# setup FOG Server
function install_fogserver() {

    # Update and upgrade the system
	sudo apt update && sudo apt upgrade -y

	# Install required dependencies
	sudo apt install -y git build-essential wget curl unzip

	# Clone the FOG repository
	git clone https://github.com/FOGProject/fogproject.git

	# Navigate to the FOG directory
	cd ~/fog/fogproject/bin

	# Make the installer executable
	chmod +x installfog.sh 

	# Run the installer
	sudo ./installfog.sh -y

	# Finish
	echo "FOG Server installation complete. Please configure it through the web interface."
}

function install_dnsmasq() {

	echo ""
	echo "Upgrading System"
	echo "****************"
	sudo apt upgrade -y
	
	# install dnsmasq
	echo ""
	echo "Installing dnsmasq"
	echo "******************"
	sudo apt install dnsmasq -y
	
	# change the link of systemd-resolved to avoid conflict on 53
	echo ""
	echo "resolve port 53 conflict"
	echo "************************"
	sudo ln -fs /run/systemd/resolve/resolv.conf /etc/resolv.conf
	sudo systemctl restart dnsmasq systemd-resolved
}

function configure_proxydhcp() {

	OLD_IP='<fog_server_IP>'	# old server ip
	#NEW_IP='127.0.0.1'	# new server ip
	DEST_DIR="/etc"		# search dir 
	INPUT_FILE="$HOME/fog/ltsp.conf"
	
	# Get the IP address of the host
	HOST_IP=$(hostname -I | awk '{print $1}')

	# Check if an IP address was obtained
	if [ -z "$HOST_IP" ]; then
		echo "Error: Unable to obtain host IP address"
		exit 1
	fi

	# Replace <fog_server_IP> with the actual IP address in file
	sed -i'.BACKUP' "s/${OLD_IP}/${HOST_IP}/g" "${INPUT_FILE}"

	#echo "Replacement complete. <fog_server_IP> has been replaced with $HOST_IP in the specified files."
	
	# copy ltsp.conf to /etc directory
	sudo cp  $INPUT_FILE $DEST_DIR
	
	# restart dnsmasq service
	sudo systemctl restart dnsmasq.service
	sudo systemctl enable dnsmasq.service
}

# show main menu
show_menus() {
	clear
	echo "~~~~~~~~~~~~~~~~~~~~~~"	
	echo " FOG Server Menu"
	echo "~~~~~~~~~~~~~~~~~~~~~~"
	PS3=$'\n''Enter Fog Server Menu option: '
	options=("Install FOG Server" "Install dnsmasq" "Configure Proxydhcp" "Exit")
	select opt in "${options[@]}"
	do
		case $opt in
			"Install FOG Server")
				install_fogserver
				show_menus
			;;
			"Install dnsmasq")
				install_dnsmasq
				show_menus
			;;
			"Configure Proxydhcp")
				configure_proxydhcp
				show_menus
			;;		
			"Exit")
				clear
				exit
			;;
			*) echo -e "${RED} Invalid option! $REPLY${STD}";;
		esac
	done
}

show_menus
