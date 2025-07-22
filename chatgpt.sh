# Vérification de l'environnement bash
if [ -z "${BASH_VERSION:-}" ]; then
  echo -e "\e[91m❌ Ce script doit être exécuté avec Bash. Utilisez : bash install.sh\e[0m"
  exit 1
fi

# Options de sécurité
set -euo pipefail
IFS=$'\n\t'

#--------------------------------------#
#      Arch Linux Automated Setup      #
#   Hyprland + Dev/Gaming/Arcane UI    #
#            install.sh               #
#--------------------------------------#

# Couleurs & esthétique
GRAY='\e[90m'; BLUE='\e[94m'; GREEN='\e[92m'; YELLOW='\e[93m'; RED='\e[91m'; RESET='\e[0m'

# Prompt pour le nom d'utilisateur
while true; do
  read -rp "${BLUE}Choisissez un nom d'utilisateur (pas d'espaces, pas de caractères spéciaux) : ${RESET}" USERNAME
  if [[ "$USERNAME" =~ ^[a-z][a-z0-9_-]+$ ]]; then break; else echo "${RED}Nom invalide.${RESET}"; fi
done

# Prompt pour le mot de passe
while true; do
  read -rsp "${BLUE}Mot de passe pour $USERNAME : ${RESET}" PASS1; echo
  read -rsp "${BLUE}Confirmez le mot de passe : ${RESET}" PASS2; echo
  [[ "$PASS1" == "$PASS2" ]] && break || echo "${RED}Mots de passe différents.${RESET}";
done

# Configuration des partitions (à adapter selon la machine)
ROOT_PART=/dev/sda3
SWAP_PART=/dev/sda2

mkfs.ext4 -L ROOT "$ROOT_PART"
mkswap "$SWAP_PART"
mount "$ROOT_PART" /mnt
swapon "$SWAP_PART"

# Installation de base
pacstrap /mnt base linux linux-firmware sudo git

# Configuration du système de fichiers
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt /bin/bash - << 'EOF'
set -euo pipefail

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc
sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "arch-hypr" > /etc/hostname

useradd -mG wheel,audio,video,optical,storage "$USERNAME"
echo "$USERNAME:$PASS1" | chpasswd
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# GRUB avec thème Fallout (et autres thèmes commentés)
pacman -S --noconfirm grub efibootmgr os-prober
mkdir -p /boot/grub/themes
# Ex : git clone https://github.com/Example/fallout-grub-theme.git /boot/grub/themes/fallout
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

curl -L -o /usr/share/sounds/boot-beep.mp3 \
  https://raw.githubusercontent.com/Example/boot-beep/main/beep.mp3

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Hyprland et base graphique
pacman -S --noconfirm xorg-server xorg-apps xorg-xinit hyprland waybar swaybg wofi

echo "exec Hyprland" >> /home/$USERNAME/.xinitrc

# Thèmes & effets
pacman -S --noconfirm imagemagick ffmpeg ffplay
curl -L -o /home/$USERNAME/.config/wallpaper.mp4 \
  https://github.com/Example/wallpaper-video/raw/main/arcane.mp4
mkdir -p /home/$USERNAME/.config/waybar
curl -L -o /home/$USERNAME/.config/waybar/config \
  https://raw.githubusercontent.com/Example/waybar-config/dev-gaming-arcane.json

pacman -S --noconfirm fastfetch
sed -i 's/logo="auto"/logo="arch"/' /etc/fastfetch/config.conf

pacman -S --noconfirm pulseaudio-alsa pulsemixer

pacman -S --noconfirm picom
curl -L -o /home/$USERNAME/.config/picom/picom.conf \
  https://raw.githubusercontent.com/Example/picom-config/transparent/dev.conf

pacman -S --noconfirm google-chrome brave
pacman -S --noconfirm netflix-desktop disneyplus
pacman -S --noconfirm spotify spicetify-cli
pacman -S --noconfirm code android-studio jdk-openjdk jdk11-openjdk

runuser -l $USERNAME -c "code --install-extension GitHub.copilot JavaScript.JavaScript C++ Python"
pacman -S --noconfirm nmap wireshark tcpdump docker git-lfs
pacman -S --noconfirm wine wine-mono wine-gecko

pacman -Scc --noconfirm
EOF

echo -e "${GREEN}Installation terminée. Redémarrage...${RESET}"
reboot
