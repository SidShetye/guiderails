#!/bin/sh

# Guiderails licensed under the MIT license
# Copyright (c) 2020 Sid Shetye - All Rights Reserved

DOWNLOAD_BASE_URL="https://raw.githubusercontent.com/SidShetye/guiderails"
RELEASE_VERSION="1.0.0"
INSTALL_PATH="/opt/share/guiderails"
NAME="Guiderails"

# Validates an IPv4 address. 
# Function modified but original licensed under CC BY-SA 4.0 from https://stackoverflow.com/a/13778973/862563
ipvalid() {
  ip=$1
  if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
    for i in 1 2 3 4;
      do if [ $(echo "$ip" | cut -d. -f$i) -gt 255 ]; then
        return 1
      fi
    done
    return 0
  else
    return 1
  fi
}

# Sanity check dependencies
if [ ! -f /usr/sbin/curl ]; then
	echo "
 Sorry, but $NAME requires curl for installation to continue.
 Try installing manually from https://github.com/SidShetye/guiderails
 "	
	exit 1
fi

echo "
Starting $NAME installation ...
"

# Create the installation folder
if [ ! -d "$INSTALL_PATH" ]; then 
	mkdir -p $INSTALL_PATH
fi

# Download the required files
orig_dir=$(pwd)
cd "$INSTALL_PATH"
for file in "guiderails.sh" "guiderails.conf"
do
	echo "Downloading $DOWNLOAD_BASE_URL/$RELEASE_VERSION/$file ..."
	curl -sOL "$DOWNLOAD_BASE_URL/$RELEASE_VERSION/$file"
done

# Ask user for the reserved IP address for Guiderails
CONF_FILE="$INSTALL_PATH/guiderails.conf"
echo "
What IP address should Guiderails start it's auxillary DNS service? 

This *CANNOT* be the router's default IP address (e.g. 192.168.1.1) or 
any other clients' IP address, so increase the DHCP start as needed 
under LAN -> DHCP -> IP Pool Starting Address. See the project's README.md
at https://github.com/SidShetye/guiderails for more information.

TIP: You can change this later in the $CONF_FILE file under the 
\"listen-address=192.168.1.2\" setting.
"
default_ip="192.168.1.2"
while true; do
  read -p "Enter Guiderails' auxillary IPv4 [$default_ip]: " ip
  if [ -z "$ip" ]; then
    ip=$default_ip
  fi
  $(ipvalid $ip) && break
  echo "Invalid IPv4 address, please try again"
done
echo "Saving $ip into $CONF_FILE ..."
sed -i -E "s/^listen-address=(.+)/listen-address=$ip/" $CONF_FILE

# Setup auto-starting Guiderails by using an appropriate
# user-script entry point provided by Merlin
merlinEntryPoint="/jffs/scripts/dnsmasq.postconf"
# Check for and create the entry point file 
if [ ! -f $merlinEntryPoint ]; then
	echo "Creating $merlinEntryPoint ..."
	touch $merlinEntryPoint
	echo '#!/bin/sh' > $merlinEntryPoint
	chmod a+x $merlinEntryPoint
fi

# Add the entrypoint command if it doesn't already exist
entryCmd=". $INSTALL_PATH/guiderails.sh restart"
if grep -q $entryCmd $merlinEntryPoint; then 
	echo "Auto-start for $NAME already exists !"
else 
	echo "Enabling auto-start for $NAME ..."
	echo $entryCmd >> $merlinEntryPoint
fi

echo "Starting Guiderails ..."
service restart_dnsmasq

echo "
 Installation completed !

 Feel free to change the whitelists by \"nano $INSTALL_PATH/guiderails.conf\" 
 followed by a \"service restart_dnsmasq\" to restart. 
 
 Enjoy!
 
 "
# remove the installation script 
cd $orig_dir 
rm -f "$0"