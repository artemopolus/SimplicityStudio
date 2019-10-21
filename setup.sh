#!/bin/bash

# ------------------------------------------------------------------
#
# must run as root
#

user=`whoami`
if [ "$user" != "root" ]; then
	echo "Please run as root"
	echo sudo $0
	exit 1
fi

# SUDO_USER is the user who ran sudo
if [ "$SUDO_USER" = "" ]; then
	SUDO_USER=`whoami`
fi
# SUDO_HOME is the home folder for the user who ran sudo
SUDO_HOME=$(bash <<< "echo ~$SUDO_USER")

# ------------------------------------------------------------------

cd `dirname $0`
export installDir=`pwd`

# ------------------------------------------------------------------
#
# create Desktop (icon) file
#

function create_desktop_file {
	local folder=$1
	local user=$2
	local mode=$3

	echo create "$folder/studio.desktop"
	cat << EOF > "$folder/studio.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=${installDir}/run_studio.sh
Name=Simplicity Studio
Path=${installDir}
Icon=${installDir}/icon.xpm
EOF
	chown $user "$folder/studio.desktop"
	chmod $mode "$folder/studio.desktop"
}

if [ -d "/usr/share/applications" ]; then
	create_desktop_file "/usr/share/applications" root 644
elif [ -d "$SUDO_HOME/.local/share/applications" ]; then
	create_desktop_file "$SUDO_HOME/.local/share/applications" "$SUDO_USER" 755
elif [ -d "$SUDO_HOME/Desktop" ]; then
	create_desktop_file "$SUDO_HOME/Desktop" "$SUDO_USER" 755
fi

# ------------------------------------------------------------------
#
# Exit if /etc/udev/rules.d does not exist
#

if [ ! -d "/etc/udev/rules.d" ]; then
	echo ERROR /etc/udev/rules.d does not exist
	exit 1
fi

# ------------------------------------------------------------------
#
# Enable USB access for Silab devices.
#

# This will emit an error if no files are found (avoiding hardcoded paths)
rules=`find "$installDir/StudioLinux" -name *.rules`
for rules_path in $rules ;
do
	rules_file=`basename "$rules_path"`
	echo "Installing udev $rules_file...";
	cp "$rules_path" /etc/udev/rules.d
done

# ------------------------------------------------------------------
#
# Install required libraries
#

OS=""
VERSION=""

if [ -f "/etc/ubuntu-release" ]; then
    OS=Ubuntu
elif [ -f "/etc/fedora-release" ]; then
    OS=Fedora
    VERSION=`cat /etc/fedora-release | awk -F release '{print $2}' | awk '{print $1}'`
elif [ -f "/etc/redhat-release" ]; then
    OS=Redhat
elif [ -f "/etc/issue" ]; then
    OS=$(head -1 "/etc/issue" | awk '{ print $1 }')
fi

ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

if [ "$OS" == "Ubuntu" ]; then
    if [ "$ARCH" == "64" ]; then
        sudo apt-get install lib32z1 lib32ncurses6 \
        libstdc++6:i386 libuuid1:i386 libc6-i386 libgtk2.0-0:i386 \
        libxtst6:i386 libusb-1.0-0:i386 libxt6:i386 libasound2:i386 \
        libdbus-glib-1-2:i386 libgl1-mesa-glx:i386 \
        libqtgui4:i386 libqt4-svg:i386 libusb-0.1-4:i386 \
        gtk2-engines-murrine:i386 \
        libelf1:i386 libphysfs1 libopenal1 libsdl-image1.2 \
        libsdl1.2debian libgles2-mesa-dev:i386 qtbase5-dev:i386 \
        openjdk-8-jre libwebkit2gtk-4.0-37 libqt5widgets5 libqt4-network
    else
        : # 32
    fi
fi

exit 0
