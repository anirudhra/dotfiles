#!/bin/sh
# (c) Anirudh Acharya 2024
# Fedora setup and Fedora/Debian dotfiles repo for thinkpad
# Run this script as non-root user
# git config --global user.name "name"
# git config --global user.email "email"
# gh auth login: for browser based git login instead of token

####################################################################################
# Detect Linux Distribution and update repos
####################################################################################
source /etc/os-release
#echo $PRETTY_NAME $ID #debug
# ID will have fedora or debian
#ID="debian" #override for debug

echo
echo ====================================================================================
echo Starting automated installer...
echo ====================================================================================
echo

# check if running from the right directory
install_dir=$(pwd)
if [[ $install_dir != *"/dotfiles/install"* ]]; then
  echo "Script invoked from incorrect directory!"
  echo "The current directory is: $install_dir"
  echo "Please run this script from .../dotfiles/install directory"
  echo
  exit -1
fi

installer="dnf" #default Fedora
if [ $ID == "fedora" ];
then
    echo "Fedora detected!"
    echo
    # don't change installer variable, use default, but keep this block for future use
    
    # add repos and keys
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
    
    #microsoft repos
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[ms-edge]\nname=Microsoft Edge Browser\nbaseurl=https://packages.microsoft.com/yumrepos/edge\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

    sudo dnf group upgrade core -y
elif [ $ID == "debian" ] || [ $ID == "ubuntu" ];
then
    echo "Debian or derivative detected!"
    echo
    echo "Before you run this script, enable non-free and non-free-firmware repos"
    read -p "!!!Press Ctrl-C to quit now to enable and re-run this script!!! If enabled, press Enter" -n1 -s
    echo
    installer="apt"

    # add repos
    sudo add-apt-repository universe -y && sudo add-apt-repository ppa:agornostal/ulauncher -y
    
    # Configure console font and size, esp. usefull for hidpi displays (select Combined Latin, Terminus, 16x32 for legibility
    echo Configuring Console...
    sudo dpkg-reconfigure console-setup
    # Configure timezone and locale for en/UTF-8
    echo Configuring Timezone...
    sudo dpkg-reconfigure tzdata
    echo Configuring Locales...
    sudo dpkg-reconfigure locales
else
    echo "Unknown OS, cannot proceed; exiting"
    exit -1
fi

# refresh again to be sure
sudo $installer update && sudo $installer upgrade

####################################################################################
# Install packages
####################################################################################

# list of core packages
corepackages=(
    'duf'
    'btop'
    'stress'
    'zsh' 
    'gnome-tweaks'
    'gnome-extensions-app'
    'avahi-daemon'
    'lm_sensors'
    'powertop'
    'vainfo'
    'usbutils'
    'pciutils'
    'autofs'
    'neovim'
    'tlp'
    'tlp-rdw'
    'wavemon'
    'smartmontools'
    'intel-gpu-tools'
    'git'
    'gh'
    'stow'
    'fastfetch'
    'papirus-icon-theme'
    'dconf-editor'
    'geary'
    'vlc'
    'gimp'
    'gparted'
    'microsoft-edge-stable'
    'golang'
    'cmake'
    'gcc'
    'inxi'
    'code'
    'gem'
    'luarocks'
    'fzf'
    'fd-find'
    'python3-pip'
    'rdfind'
    'menulibre'
)

# Nerd fonts list to be installed
nerd_font_ver='3.3.0'

fonts=(
	#'BitstreamVeraSansMono'
	#'CodeNewRoman'
	#'DroidSansMono'
	'FiraCode'
	'FiraMono'
	#'Go-Mono'
	#'Hack'
	#'Hermi't
	#'JetBrainsMono'
	'Meslo'
	#'Noto'
	#'Overpass'
	#'ProggyClean'
	'RobotoMono'
	'SourceCodePro'
	#'SpaceMono'
	#'Ubuntu'
	#'UbuntuMono'
)

# OS specific packages are listed in this block
if [ $ID == "fedora" ]; then
    # Fedora specific packages
    ospackages=(
        's-tui'
        'throttled'
        'nfs-utils'
        'intel-media-driver'
        'epapirus-icon-theme'
        'papirus-icon-theme-dark'
        'papirus-icon-theme-light'
        'ulauncher'
        'btrfs-assistant'
        'heif-pixbuf-loader'
        'libheif-freeworld'
        'libheif'
    )

    echo "Fedora installer..."
    sudo dnf remove thermald -y
    sudo dnf copr enable abn/throttled -y
else
    # Debian/Ubuntu specific packages
    echo "Debian installer..."
    ospackages=(
        's-tui'
        'avahi-utils'
        'nfs-common'
        'systemd-resolved'
        'cifs-utils'
        'alsa-utils'
        'intel-media-va-driver-non-free'
    )
fi

# install all packages
sudo $installer install "${corepackages[@]}" "${ospackages[@]}"

####################################################################################
# Install dotfiles with stow under /dotfiles/home directory
####################################################################################
# activate stow
cd $install_dir/../home
stow --target=/home/anirudh --adopt .
git restore .
cd $install_dir

####################################################################################
# Install /etc config files
####################################################################################
source_autofs_share_file="./etc/auto.pveshare"
sys_autofs_share_file="/etc/auto.pveshare"
source_tlp_file="./etc/tlp.conf"
sys_tlp_file="/etc/tlp.conf"
source_throttled_file="./etc/throttled.conf"
sys_throttled_file="/etc/throttled.conf"

# comment out checking files for now, force install the new files to overwrite default ones
#if [ -e "$sys_autofs_share_file" ]; then
#    echo "$sys_autofs_share_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_autofs_share_file to $sys_autofs_share_file"
    sudo cp $source_autofs_share_file $sys_autofs_share_file
    sudo mkdir -p /mnt/share
    sudo chmod 777 /mnt/share
#fi

#if [ -e "$sys_tlp_file" ]; then
#    echo "$sys_tlp_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_tlp_file to $sys_tlp_file"
    sudo cp $source_tlp_file $sys_tlp_file
#fi

#if [ -e "$sys_throttled_file" ]; then
#    echo "$sys_throttled_file /etc config file exists, nothing to do!"
#else
    echo "Installing /etc config file: $source_throttled_file to $sys_throttled_file"
    sudo cp $source_throttled_file $sys_throttled_file
#fi

####################################################################################
# Install UI/Customizations
####################################################################################

echo "Current directory: $install_dir"

# Replace audio alert file
audio_alert_bak_file=/usr/share/sounds/gnome/default/alerts/hum_og.ogg
if [ ! -e $audio_alert_bak_file ]; then
    echo "Installing audio alert file replacement"
    echo
    sudo cp /usr/share/sounds/gnome/default/alerts/hum.ogg /usr/share/sounds/gnome/default/alerts/hum_og.ogg
    sudo cp ./sounds/hum.ogg /usr/share/sounds/gnome/default/alerts/hum.ogg 
fi

# Install GTK and Icon themes
pkg_install_dir="$HOME/packages/install"
mkdir -p $pkg_install_dir
cd $pkg_install_dir
install_ui=0 #default flag, if at least one is pulled, set this below

# check if exists, else pull
if [ ! -d "Tela-icon-theme" ]; then
    git clone https://github.com/vinceliuice/Tela-icon-theme
    install_ui=1
fi
if [ ! -d "Orchis-theme" ]; then
    git clone https://github.com/vinceliuice/Orchis-theme
    install_ui=1
fi
if [ ! -d "Magnetic-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/Magnetic-gtk-theme
    install_ui=1
fi
if [ ! -d "Qogir-theme" ]; then
    git clone https://github.com/vinceliuice/Qogir-theme
    install_ui=1
fi
if [ ! -d "Qogir-icon-theme" ]; then
    git clone https://github.com/vinceliuice/Qogir-icon-theme
    install_ui=1
fi
if [ ! -d "Jasper-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/Jasper-gtk-theme
    install_ui=1
fi
if [ ! -d "Fluent-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/Fluent-gtk-theme
    install_ui=1
fi
if [ ! -d "Fluent-icon-theme" ]; then
    git clone https://github.com/vinceliuice/Fluent-icon-theme
    install_ui=1
fi

# execute install.sh script from each directory for all above, if at least one was sync'd
if [ $install_ui -eq 1 ]; then
    echo "Executing UI installation scripts"
    find . -maxdepth 1 -type d \( ! -name . \) -exec bash -c "cd '{}' && pwd && ./install.sh" \;
fi

# Install Nerd fonts, cleanup and update font cache
cd $pkg_install_dir
mkdir -p ./nerd_font_install
cd ./nerd_font_install

fonts_dir="${HOME}/.local/share/fonts"
if [[ ! -d "$fonts_dir" ]]; then
	mkdir -p "$fonts_dir"
fi

#array defined at the top of the file, change list and version there
for font in "${fonts[@]}"; do
	zip_file="${font}.zip"
	download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${nerd_font_ver}/${zip_file}"
	echo "Downloading $download_url"
	wget "$download_url"
	unzip -o "$zip_file" -d "$fonts_dir"
	rm "$zip_file"
done
find "$fonts_dir" -name '*Windows Compatible*' -delete
fc-cache -fv

# set GTK and icon themes
echo "Setting GTK and Icon themes..."
gsettings set org.gnome.desktop.interface gtk-theme "'Orchis-Dark-Compact'"
# following fails and needs to be manually enabled in GNOME Tweaks
gsettings set org.gnome.shell.extensions user-theme "'Orchis-Dark-Compact'"
gsettings set org.gnome.desktop.interface icon-theme "'Tela-dark'"
gsettings set org.gnome.desktop.interface color-scheme "'prefer-dark'"
gsettings set org.gnome.desktop.interface monospace-font-name "'FiraMono Nerd Font 10'"
gsettings set org.gnome.desktop.interface clock-format "'12h'"
#gsettings set org.gnome.desktop.interface clock-show-weekday 1

# change back to original installation directory
cd $install_dir

####################################################################################
# Lazyvim
####################################################################################
# commenting this ouw now as .config/nvim with lazygit is now backed up and "stowed"
#mv ~/.config/nvim{,.bak}
#git clone https://github.com/LazyVim/starter ~/.config/nvim
#rm -rf ~/.config/nvim/.git

####################################################################################
# Enable various services
####################################################################################

sudo systemctl daemon-reload

sudo systemctl enable tlp
sudo systemctl start tlp
sudo tlp start

sudo systemctl enable autofs
sudo systemctl start autofs

sudo systemctl enable throttled
sudo systemctl start throttled

# Disable services: thermald conflicts with throttled
sudo systemctl disable thermald
sudo systemctl mask thermald

chsh -s $(which zsh)
####################################################################################
# Manual install notice
####################################################################################
sys_auto_master_file="/etc/auto.master"

echo
echo ===========================================================================================
echo "Install the following GNOME Extensions manually from: https://extensions.gnome.org/"
echo "AppIndiator and KStatusNotifierItem Support, ArcMenu, Caffine, Dash to Dock, Linux Update Notifier, Just Perfection, Removable Drive Menu, Transparent Window Moving, User Themes, Vitals, Weather O Clock"
echo
echo Manually install Ulauncher plugins, supersonic audio player
echo
echo Manually set Nerd Font in: Terminal, Gnome Tweaks and VSCode
echo
echo UI customizations have been cloned in $pkg_install_dir, for future git pulls and updates or can be manually removed to save space. Manually set GNOME Shell theme and Hum alert sound
echo
if grep -wq "/- /etc/auto.pveshare" $sys_auto_master_file; then 
  echo "$sys_auto_master_file already has PVE share NFS entry, restart autofs service if server isn't mounted" 
else 
  echo "Add the following line at the end of /etc/auto.mount and restart autofs service"
  echo "/- /etc/auto.pveshare"
fi
echo
echo ===========================================================================================
echo

####################################################################################
# End
####################################################################################

echo
echo "Done! Logout and log back in for changes."
echo

####################################################################################
# ZSH and customizations
####################################################################################
echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> $local_zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo ===========================================================================================
#git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
echo "Run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k manually after configuring oh-my-zsh"
echo ===========================================================================================

