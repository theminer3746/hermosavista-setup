#!/bin/bash
#
# Hermosa Vista Client setup script
# (C) 2019 District6 Group. All Rights Reserved.
#

printf "              \n"
printf "    ____  _      __       _      __  _____  \n"
printf "   / __ \(_)____/ /______(_)____/ /_/ ___/  \n"
printf "  / / / / / ___/ __/ ___/ / ___/ __/ __ \   \n"
printf " / /_/ / (__  ) /_/ /  / / /__/ /_/ /_/ /   \n"
printf "/_____/_/____/\__/_/  /_/\___/\__/\____/    \n"
printf "                                            \n"
printf "HermosaVista Client Application Setup\n\n"

# Pre-flight step 1: check for root and existence of files
if [[ $EUID -ne 0 ]]; then
	printf "[FATAL] This script must be run as root!\n\n"
	exit 1
fi

# Check files
if [ -f "wallpaper.jpg" ]; then
	# Wallpaper exists
	printf ""
else
	printf "[FATAL] Wallpaper file missing!\n\n"
	exit 1
fi
if [ -f "ths-new.ttf" ]; then
	printf ""
else
	printf "[FATAL] ths-new.ttf missing!\n\n"
	exit 1
fi
if [ -f "ths-new-bold.ttf" ]; then
	printf ""
else
	printf "[FATAL] ths-new-bold.ttf missing!\n\n"
	exit 1
fi
if [ -f "ths-new-bolditalic.ttf" ]; then
	printf ""
else
	printf "[FATAL] ths-new-bolditalic.ttf missing!\n\n"
	exit 1
fi
if [ -f "ths-new-italic.ttf" ]; then
	printf ""
else
	printf "[FATAL] ths-new-italic.ttf missing!\n\n"
	exit 1
fi
# END check files

# Pre-flight step 2: run apt-get update
printf "==== 00 : Updating base software ==== \n"
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confold" --force-yes
printf "DONE\n\n"

# Make customizations directories and load wallpaper
printf "==== 01 : Creating customization data directory ==== \n"
mkdir -p /opt/hermovista
printf "Loading wallpaper... "
cp ./wallpaper.jpg /opt/hermovista/wallpaper0.jpg
printf "DONE \n"

printf "DONE\n\n"

# Configure basic dconf settings
printf "==== 02 : Configuring dconf settings ==== \n"
mkdir -p /etc/dconf/profile
printf "DONE\n\n"


printf "DB... "
printf "user-db:user
system-db:local" > /etc/dconf/profile/user

printf "ConfDir... "
mkdir -p /etc/dconf/db/local.d

printf "Config... "
printf "
[org/gnome/desktop/lockdown]
disable-user-switching = true
user-administration-disabled = true

[org/gnome/desktop/notifications]
show-in-lock-screen = false
show-banners = false

[org/gnome/desktop/privacy]
remove-old-temp-files = true
report-technical-problems = false
send-software-usage-stats = false

[org/gnome/desktop/screensaver]
idle-activation-enabled = false
user-switch-enabled = false

[org/gnome/desktop/session]
idle-delay = 0

[apps/update-manager]
check-dist-upgrades = false
first-run = false

[org/gnome/shell/extensions/dash-to-dock]
show-apps-at-top = true
dock-position = 'BOTTOM'
autohide = false
dock-fixed = true

[org/gnome/shell]
favorite-apps = ['org.gnome.Nautilus.desktop', 'firefox.desktop', 'libreoffice-writer.desktop', 'libreoffice-calc.desktop', 'libreoffice-impress.desktop']

[org/gnome/desktop/background]
picture-uri = 'file:///opt/hermovista/wallpaper0.jpg'
picture-options = 'zoom'

" > /etc/dconf/db/local.d/00-hermovista-client

printf "Update... "
dconf update

printf "DONE \n"

# Disable user listing and screensaver on login
printf "==== 03: Disabling user list and screensaver on login ==== \n"
printf "
[org/gnome/login-screen]
disable-user-list = true
logo='/opt/hermovista/login-logo.png'
fallback-logo='/opt/hermovista/login-logo.png'

[org/gnome/desktop/screensaver]
idle-activation-enabled = false
user-switch-enabled = false

[org/gnome/desktop/session]
idle-delay = 0
" > /usr/share/gdm/greeter.dconf-defaults
dpkg-reconfigure gdm3
printf "DONE\n\n"

# Disable sleep & hibernate
printf "==== 04: Disabling sleep and hibernate ==== \n"
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
printf "DONE\n\n"

# Disable certain settings panels
printf "==== 05: Disabling certain settings panels  ==== \n"
dpkg-statoverride --update --add root root 640 /usr/share/applications/gnome-user-accounts-panel.desktop
dpkg-statoverride --update --add root root 640 /usr/share/applications/gnome-wifi-panel.desktop
dpkg-statoverride --update --add root root 640 /usr/share/applications/gnome-initial-setup.desktop
dpkg-statoverride --update --add root root 640 /usr/share/applications/org.gnome.Software.desktop
dpkg-statoverride --update --add root root 640 /usr/share/applications/org.gnome.Software.Editor.desktop
printf "DONE\n\n"

# Remove gnome-initial-setup
printf "==== 06: Removing gnome-initial-setup  ==== \n"
apt-get purge -y gnome-initial-setup gnome-software
printf "DONE\n\n"

# Install LibreOffice & other software packages
printf "==== 07: Installing additional packages  ==== \n"
add-apt-repository -y ppa:libreoffice/ppa
apt-get update
apt-get install -y -o Dpkg::Options::="--force-confold" --force-yes libreoffice openssh-server git zip unzip
printf "DONE\n\n"

# Install fonts
printf "==== 08: Installing fonts  ==== \n"
mkdir -p /usr/share/fonts/truetype/custom
cp *.ttf /usr/share/fonts/truetype/custom/
fc-cache -fv
printf "DONE\n\n"

# Lockdown dconf
printf "==== 09: locking down dconf keys ==== \n"
mkdir -p /etc/dconf/db/local.d/locks
printf "
/org/gnome/desktop/lockdown/disable-user-switching
/org/gnome/desktop/lockdown/user-administration-disabled
/org/gnome/desktop/notifications/show-in-lock-screen
/org/gnome/desktop/notifications/show-banners
/org/gnome/desktop/privacy/remove-old-temp-files
/org/gnome/desktop/privacy/report-technical-problems
/org/gnome/desktop/privacy/send-software-usage-stats
/org/gnome/desktop/screensaver/idle-activation-enabled
/org/gnome/desktop/screensaver/user-switch-enabled
/org/gnome/desktop/session/idle-delay
/apps/update-manager/check-dist-upgrades
/org/gnome/desktop/background/picture-uri
/org/gnome/desktop/background/picture-options
" > /etc/dconf/db/local.d/locks/00-hermovista-lockdown
dconf update
printf "DONE\n\n"

printf "\n >>>>> Setup complete! <<<<< \n\n"
