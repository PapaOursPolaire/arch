# Couleurs pour l'interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
USERNAME=""
PASSWORD=""
EFI_PARTITION="/dev/sda1" # À modifier selon votre configuration
ROOT_PARTITION="/dev/sda2" # À modifier selon votre configuration
TIMEZONE="Europe/Paris"
LANG="fr_FR.UTF-8"
KEYMAP="fr-latin9"
HOSTNAME="arch-hyprland"

# Vérification root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root!${NC}"
    exit 1
fi

# Interface esthétique
function header() {
    clear
    echo -e "${BLUE}"
    echo "   _    _           _       _      _   "
    echo "  / \  | |__   __ _| |_ ___| | __ | |_ "
    echo " / _ \ | '_ \ / _\` | __/ __| |/ / | __|"
    echo "/ ___ \| | | | (_| | |_\__ \   <  | |_ "
    echo "/_/   \_\_| |_|\__,_|\__|___/_|\_\  \__|"
    echo -e "${NC}"
    echo -e "${YELLOW}=== Script d'installation Arch Linux Hyprland Edition ===${NC}"
    echo "=================================================="
}

# Partitionnement (commenté pour sécurité)
function setup_disks() {
    echo -e "${YELLOW}[INFO] Montage des partitions existantes...${NC}"
    # mkfs.vfat -F32 $EFI_PARTITION
    # mkfs.ext4 $ROOT_PARTITION
    # mount $ROOT_PARTITION /mnt
    # mkdir /mnt/boot
    # mount $EFI_PARTITION /mnt/boot
}

# Installation de base
function install_base() {
    header
    echo -e "${GREEN}[ÉTAPE] Installation du système de base${NC}"
    
    # Mise à jour miroirs
    echo -e "${YELLOW}[INFO] Synchronisation des paquets...${NC}"
    pacman -Syy --noconfirm
    pacman -S reflector --noconfirm
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # Installation base
    pacstrap /mnt base base-devel linux linux-firmware git nano
    
    # Génération fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configuration système
function configure_system() {
    header
    echo -e "${GREEN}[ÉTAPE] Configuration système${NC}"
    
    # Timezone
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    # Localisation
    echo "LANG=$LANG" > /mnt/etc/locale.conf
    sed -i "s/#$LANG/$LANG/" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    
    # Clavier
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    
    # Hostname
    echo $HOSTNAME > /mnt/etc/hostname
    
    # Utilisateur
    read -p "Nom d'utilisateur (sans espaces/caractères spéciaux): " USERNAME
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
    
    while true; do
        read -sp "Mot de passe pour $USERNAME: " PASSWORD
        echo
        read -sp "Confirmation: " PASSWORD2
        echo
        [ "$PASSWORD" = "$PASSWORD2" ] && break
        echo -e "${RED}Les mots de passe ne correspondent pas!${NC}"
    done
    echo "$USERNAME:$PASSWORD" | chpasswd --root /mnt
}

# Installation Hyprland et logiciels
function install_hyprland() {
    header
    echo -e "${GREEN}[ÉTAPE] Installation de l'environnement graphique${NC}"
    
    # Pilotes et dépendances
    arch-chroot /mnt pacman -S --noconfirm \
        xdg-desktop-portal-hyprland \
        mesa libva-mesa-driver \
        nvidia nvidia-utils nvidia-settings \
        pipewire pipewire-alsa pipewire-pulse wireplumber \
        noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-font-awesome
    
    # Hyprland
    arch-chroot /mnt pacman -S --noconfirm hyprland
    
    # Logiciels demandés
    arch-chroot /mnt pacman -S --noconfirm \
        brave-browser google-chrome \
        spotify-launcher spicetify-cli \
        android-studio code \
        wine-staging \
        nmap wireshark-qt burpsuite \
        jdk-openjdk python nodejs go rust \
        blender gimp libreoffice-fresh \
        vlc mpv
    
    # Extensions VS Code
    arch-chroot /mnt su - $USERNAME -c "code --install-extension ms-python.python"
    arch-chroot /mnt su - $USERNAME -c "code --install-extension ms-vscode.cpptools"
    arch-chroot /mnt su - $USERNAME -c "code --install-extension GitHub.copilot"
    arch-chroot /mnt su - $USERNAME -c "code --install-extension redhat.java"
}

# Personnalisations
function customizations() {
    header
    echo -e "${GREEN}[ÉTAPE] Personnalisations${NC}"
    
    # FastFetch
    arch-chroot /mnt pacman -S --noconfirm fastfetch
    echo "fastfetch --logo arch --logo-color-1 blue --logo-color-2 0xff --logo-color-3 0xff" >> /mnt/home/$USERNAME/.bashrc
    
    # Thème GRUB (Fallout par défaut)
    git clone https://github.com/ChrisTitusTech/f fallout-grub-theme
    cp -r fallout-grub-theme /mnt/boot/grub/themes/
    echo "GRUB_THEME=\"/boot/grub/themes/fallout-grub-theme/theme.txt\"" >> /mnt/etc/default/grub
    
    # Autres thèmes GRUB (liste complète dans README)
    themes=(
        "https://github.com/mateosss/grub2-theme-bsol"
        "https://github.com/Patato777/dark_matter"
        "https://github.com/AdisonCavani/Arc-GRUB"
    )
    for theme in "${themes[@]}"; do
        git clone $theme "/mnt/boot/grub/themes/$(basename $theme)"
    done
    
    # SDDM avec thème Arcane
    arch-chroot /mnt pacman -S --noconfirm sddm
    git clone https://github.com/arc-design/sddm-arcane-theme
    cp -r sddm-arcane-theme /mnt/usr/share/sddm/themes/
    echo "[Theme]" > /mnt/etc/sddm.conf
    echo "Current=arcane" >> /mnt/etc/sddm.conf
    
    # Wallpaper animé
    wget https://github.com/ArcDesignResources/AnimatedBackgrounds/raw/main/arcane-loop.mp4 -P /mnt/usr/share/backgrounds/
    
    # Bip de démarrage
    wget https://github.com/ArcDesignResources/SoundEffects/raw/main/boot_sound.mp3 -P /mnt/usr/share/sounds/
    echo "aplay /usr/share/sounds/boot_sound.mp3" >> /mnt/etc/profile
    
    # Configuration Hyprland
    mkdir -p /mnt/home/$USERNAME/.config/hypr/
    cat > /mnt/home/$USERNAME/.config/hypr/hyprland.conf << EOF
exec-once = swww init
exec-once = swww img /usr/share/backgrounds/arcane-loop.mp4

# Barre Waybar transparente
exec-once = waybar -c ~/.config/waybar/config.json

# Transparence applications
windowrulev2 = opacity 0.95, class:^(kitty)$
windowrulev2 = opacity 0.90, class:^(Code)$
EOF

    # Waybar personnalisée
    git clone https://github.com/Alexays/Waybar /mnt/home/$USERNAME/.config/waybar
}

# Finalisation
function finalize() {
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    arch-chroot /mnt systemctl enable sddm
    echo -e "${GREEN}[SUCCÈS] Installation terminée!${NC}"
    echo -e "Redémarrez avec : ${YELLOW}umount -R /mnt && reboot${NC}"
}

# Exécution
setup_disks
install_base
configure_system
install_hyprland
customizations
finalize