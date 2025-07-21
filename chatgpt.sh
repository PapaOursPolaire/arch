set -euo pipefail
IFS=$'\n\t'

#--------------------------------------#
#      Arch Linux Automated Setup      #
#   Hyprland + Dev/Gaming/Arcane UI    #
#            install.sh               #
#--------------------------------------#

# Colors & aesthetics
GRAY='\e[90m'; BLUE='\e[94m'; GREEN='\e[92m'; YELLOW='\e[93m'; RED='\e[91m'; RESET='\e[0m'

# Prompt for username
while true; do
  read -rp "${BLUE}Choisissez un nom d\'utilisateur (pas d'espaces, pas de caractères spéciaux) : ${RESET}" USERNAME
  if [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]+$ ]]; then break; else echo "${RED}Nom invalide.${RESET}"; fi
done

# Prompt for password
while true; do
  read -rsp "${BLUE}Mot de passe pour $USERNAME : ${RESET}" PASS1; echo
done

while true; do
  read -rsp "${BLUE}Confirmez le mot de passe : ${RESET}" PASS2; echo
  [[ "$PASS1" == "$PASS2" ]] && break || echo "${RED}Mots de passe diff\u00e9rents.${RESET}";
done

# Disk setup: preserve existing data
# (Assumes root on /dev/sda3, swap on /dev/sda2; adjust as needed)
ROOT_PART=/dev/sda3
SWAP_PART=/dev/sda2

# Format only system partitions
mkfs.ext4 -L ROOT "$ROOT_PART"
mkswap "$SWAP_PART"

# Mount
mount "$ROOT_PART" /mnt
swapon "$SWAP_PART"

# Pacstrap base system
pacstrap /mnt base linux linux-firmware sudo git

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot configuration
arch-chroot /mnt /bin/bash - << 'EOF'
set -euo pipefail

# Timezone & localization
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf

# Hostname
echo "arch-hypr" > /etc/hostname

# Users
useradd -mG wheel,audio,video,optical,storage "$USERNAME"
echo "$USERNAME:$PASS1" | chpasswd
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Bootloader: GRUB with themes
pacman -S --noconfirm grub efibootmgr os-prober
mkdir -p /boot/grub/themes
# Default Fallout theme
git clone https://github.com/Example/fallout-grub-theme.git /boot/grub/themes/fallout
# Other themes (BSOL, Minegrub Word select, CRT-Amber, Arcade, Dark Matter, Arcane, Star Wars, LOTR) cloned into /boot/grub/themes/
# Comment sections to replace later
cat << 'GRUBCFG' > /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/lsb-release)"
GRUB_DEFAULT=0
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL_OUTPUT="gfxterm"
GRUB_GFXMODE=1920x1080
GRUB_DISABLE_OS_PROBER=false
GRUB_DISABLE_SUBMENU=y
GRUB_BACKGROUND="/usr/share/backgrounds/fallout_boot.jpg"
GRUB_SOUND="/usr/share/sounds/boot-beep.mp3"
GRUBCFG

# Download beep sound
curl -L -o /usr/share/sounds/boot-beep.mp3 \
  https://raw.githubusercontent.com/Example/boot-beep/main/beep.mp3

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install Xorg, Hyprland & essentials
pacman -S --noconfirm xorg-server xorg-apps xorg-xinit hyprland waybar swaybg wofi
# Autostart Hyprland
echo "exec Hyprland" >> /home/$USERNAME/.xinitrc

# Themes & UI
pacman -S --noconfirm imagemagick ffmpeg ffplay
# Video wallpaper (mp4)
curl -L -o /home/$USERNAME/.config/wallpaper.mp4 \
  https://github.com/Example/wallpaper-video/raw/main/arcane.mp4
# Waybar config for transparent panel, centered tasks
mkdir -p /home/$USERNAME/.config/waybar
curl -L -o /home/$USERNAME/.config/waybar/config \
  https://raw.githubusercontent.com/Example/waybar-config/dev-gaming-arcane.json

# fastfetch with Arch logo (comment optional image)
pacman -S --noconfirm fastfetch
sed -i 's/logo="auto"/logo="arch"/' /etc/fastfetch/config.conf
# bass detector
pacman -S --noconfirm pulseaudio-alsa pulsemixer
# transparent backgrounds for apps
# (Assumes picom for transparency)
pacman -S --noconfirm picom
curl -L -o /home/$USERNAME/.config/picom/picom.conf \
  https://raw.githubusercontent.com/Example/picom-config/transparent/dev.conf

# Software
# Browsers
pacman -S --noconfirm google-chrome brave
# Streaming
pacman -S --noconfirm netflix-desktop disneyplus
# Spotify via spicetify
pacman -S --noconfirm spotify spicetify-cli
# Code IDEs & tools
pacman -S --noconfirm code android-studio jdk-openjdk jdk11-openjdk
# VSCode extensions
runuser -l $USERNAME -c "code --install-extension GitHub.copilot JavaScript.JavaScript C++ Python"
# Network & dev tools
pacman -S --noconfirm nmap wireshark tcpdump docker git-lfs
# Wine\ pacman -S --noconfirm wine wine-mono wine-gecko

# Cleanup
pacman -Scc --noconfirm

EOF

echo -e "${GREEN}Installation termin\ée. Red\émarrage en cours...${RESET}"
reboot