# Couleurs pour l'interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
USERNAME=""
PASSWORD=""
EFI_PARTITION=""
ROOT_PARTITION=""
HOME_PARTITION=""
SWAP_PARTITION=""
TIMEZONE="Europe/Paris"
LANG="fr_FR.UTF-8"
KEYMAP="fr-latin9"
HOSTNAME="arch-hyprland"

# Vérification root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}✗ Ce script doit être exécuté en tant que root!${NC}"
    exit 1
fi

# Interface esthétique
function header() {
    clear
    echo -e "${CYAN}"
    echo "   █████╗ ██████╗  ██████╗██╗  ██╗     ██╗  ██╗██╗   ██╗██████╗ ██╗      █████╗ ███╗   ██╗██████╗ "
    echo "  ██╔══██╗██╔══██╗██╔════╝██║  ██║     ██║  ██║╚██╗ ██╔╝██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗"
    echo "  ███████║██████╔╝██║     ███████║     ███████║ ╚████╔╝ ██████╔╝██║     ███████║██╔██╗ ██║██║  ██║"
    echo "  ██╔══██║██╔══██╗██║     ██╔══██║     ██╔══██║  ╚██╔╝  ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██║  ██║"
    echo "  ██║  ██║██║  ██║╚██████╗██║  ██║     ██║  ██║   ██║   ██║     ███████╗██║  ██║██║ ╚████║██████╔╝"
    echo "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ "
    echo -e "${NC}"
    echo -e "${YELLOW}========================================================================================"
    echo -e "=== Script d'installation Arch Linux Hyprland Edition - Thème Arcane/Fallout ==="
    echo -e "========================================================================================${NC}"
    echo
}

# Fonction pour afficher les disques disponibles
function list_disks() {
    echo -e "${GREEN}Disques disponibles:${NC}"
    lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT | grep -v 'loop' | awk 'NR>1 {print NR-1")",$0}'
}

# Fonction pour afficher les partitions d'un disque
function list_partitions() {
    local disk=$1
    echo -e "${GREEN}Partitions sur ${disk}:${NC}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT /dev/$disk | awk 'NR>1 && /part/ {print NR-1")",$0}'
}

# Partitionnement semi-automatique
function setup_disks() {
    header
    echo -e "${GREEN}▶ Configuration des disques${NC}"
    
    # Liste des disques
    list_disks
    echo
    read -p "Sélectionnez le numéro du disque à utiliser: " disk_num
    DISK=$(lsblk -d -o NAME | grep -v 'NAME' | sed -n "${disk_num}p")
    
    # Vérification
    if [ -z "$DISK" ]; then
        echo -e "${RED}✗ Disque invalide!${NC}"
        exit 1
    fi
    
    # Partitionnement
    echo -e "${YELLOW}Options de partitionnement pour /dev/${DISK}:${NC}"
    echo "1) Utiliser partitions existantes"
    echo "2) Créer nouveau schéma de partitionnement (GPT)"
    read -p "Votre choix [1-2]: " part_choice
    
    case $part_choice in
        1)
            # Utiliser partitions existantes
            list_partitions $DISK
            echo
            read -p "Sélectionnez la partition EFI (boot): " efi_num
            EFI_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "${efi_num}p")"
            
            read -p "Sélectionnez la partition root (/): " root_num
            ROOT_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "${root_num}p")"
            
            read -p "Sélectionnez la partition home (/home) [optionnel, Entrée pour ignorer]: " home_num
            if [ -n "$home_num" ]; then
                HOME_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "${home_num}p")"
            fi
            
            read -p "Sélectionnez la partition swap [optionnel, Entrée pour ignorer]: " swap_num
            if [ -n "$swap_num" ]; then
                SWAP_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "${swap_num}p")"
            fi
            ;;
            
        2)
            # Créer nouveau schéma
            echo -e "${YELLOW}Taille recommandée:"
            echo -e "- EFI: 550M (minimum 300M)"
            echo -e "- Root: 50G (minimum 30G)"
            echo -e "- Swap: égale à la RAM (4G recommandé)"
            echo -e "- Home: reste de l'espace${NC}"
            
            # Taille EFI
            read -p "Taille de la partition EFI (ex: 550M): " efi_size
            efi_size=${efi_size:-550M}
            
            # Taille root
            read -p "Taille de la partition root (ex: 50G): " root_size
            root_size=${root_size:-50G}
            
            # Taille swap
            read -p "Taille de la partition swap (ex: 4G): " swap_size
            swap_size=${swap_size:-4G}
            
            # Création des partitions
            echo -e "${MAGENTA}● Création des partitions...${NC}"
            parted -s /dev/$DISK mklabel gpt
            parted -s /dev/$DISK mkpart primary fat32 1MiB ${efi_size}
            parted -s /dev/$DISK set 1 esp on
            parted -s /dev/$DISK mkpart primary ext4 ${efi_size} $(echo $efi_size | sed 's/M//;s/G//')+${root_size}
            parted -s /dev/$DISK mkpart primary linux-swap $(echo $efi_size $root_size | awk '{print $1 + $2}')+${swap_size}
            parted -s /dev/$DISK mkpart primary ext4 $(echo $efi_size $root_size $swap_size | awk '{print $1 + $2 + $3}') 100%
            
            # Assignation des partitions
            EFI_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "1p")"
            ROOT_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "2p")"
            SWAP_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "3p")"
            HOME_PARTITION="/dev/$(lsblk -o NAME /dev/$DISK | grep -v 'NAME' | grep 'part' | sed -n "4p")"
            
            # Formatage
            echo -e "${MAGENTA}● Formatage des partitions...${NC}"
            mkfs.fat -F32 $EFI_PARTITION
            mkfs.ext4 $ROOT_PARTITION
            mkfs.ext4 $HOME_PARTITION
            mkswap $SWAP_PARTITION
            swapon $SWAP_PARTITION
            ;;
            
        *)
            echo -e "${RED}✗ Choix invalide!${NC}"
            exit 1
            ;;
    esac
    
    # Montage des partitions
    echo -e "${MAGENTA}● Montage des partitions...${NC}"
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/boot
    mount $EFI_PARTITION /mnt/boot
    
    if [ -n "$HOME_PARTITION" ]; then
        mkdir -p /mnt/home
        mount $HOME_PARTITION /mnt/home
    fi
}

# Installation de base
function install_base() {
    header
    echo -e "${GREEN}▶ Installation du système de base${NC}"
    
    echo -e "${MAGENTA}● Mise à jour des miroirs...${NC}"
    pacman -Syy --noconfirm
    pacman -S reflector --noconfirm > /dev/null 2>&1
    reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    echo -e "${MAGENTA}● Installation des paquets de base...${NC}"
    pacstrap /mnt base base-devel linux linux-firmware git nano sudo --noconfirm > /dev/null 2>&1
    
    echo -e "${MAGENTA}● Génération du fstab...${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configuration système
function configure_system() {
    header
    echo -e "${GREEN}▶ Configuration système${NC}"
    
    echo -e "${MAGENTA}● Configuration du fuseau horaire ($TIMEZONE)...${NC}"
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    echo -e "${MAGENTA}● Configuration des locales ($LANG)...${NC}"
    echo "LANG=$LANG" > /mnt/etc/locale.conf
    sed -i "s/#$LANG/$LANG/" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen > /dev/null 2>&1
    
    echo -e "${MAGENTA}● Configuration du clavier ($KEYMAP)...${NC}"
    echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
    
    echo -e "${MAGENTA}● Configuration du nom d'hôte ($HOSTNAME)...${NC}"
    echo $HOSTNAME > /mnt/etc/hostname
    
    echo -e "${MAGENTA}● Création de l'utilisateur${NC}"
    while true; do
        read -p "Nom d'utilisateur (sans espaces/caractères spéciaux): " USERNAME
        if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            echo -e "${RED}✗ Format invalide! Utilisez seulement des minuscules, chiffres et tirets.${NC}"
        fi
    done
    
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
    
    while true; do
        read -sp "Mot de passe pour $USERNAME: " PASSWORD
        echo
        read -sp "Confirmation: " PASSWORD2
        echo
        [ "$PASSWORD" = "$PASSWORD2" ] && break
        echo -e "${RED}✗ Les mots de passe ne correspondent pas!${NC}"
    done
    echo -e "${MAGENTA}● Définition du mot de passe...${NC}"
    echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd
    
    # Ajout de l'utilisateur au groupe sudo
    echo -e "${MAGENTA}● Configuration des privilèges sudo...${NC}"
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
}

# Installation Hyprland et logiciels
function install_hyprland() {
    header
    echo -e "${GREEN}▶ Installation de l'environnement graphique${NC}"
    
    echo -e "${MAGENTA}● Installation des pilotes et dépendances...${NC}"
    arch-chroot /mnt pacman -S --noconfirm \
        xdg-desktop-portal-hyprland \
        mesa libva-mesa-driver \
        pipewire pipewire-alsa pipewire-pulse wireplumber \
        noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-font-awesome \
        > /dev/null 2>&1

    echo -e "${MAGENTA}● Installation de Hyprland...${NC}"
    arch-chroot /mnt pacman -S --noconfirm hyprland --noconfirm > /dev/null 2>&1
    
    echo -e "${MAGENTA}● Installation des logiciels demandés...${NC}"
    arch-chroot /mnt pacman -S --noconfirm \
        brave-browser google-chrome \
        spotify-launcher \
        code android-studio \
        wine-staging \
        nmap wireshark-qt \
        jdk-openjdk python nodejs npm go rust \
        vlc mpv \
        firefox discord steam \
        --noconfirm > /dev/null 2>&1
    
    echo -e "${MAGENTA}● Installation des extensions VS Code...${NC}"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension ms-python.python"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension ms-vscode.cpptools"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension GitHub.copilot"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension redhat.java"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension vscodevim.vim"
    arch-chroot /mnt sudo -u $USERNAME bash -c "code --install-extension esbenp.prettier-vscode"
}

# Personnalisations
function customizations() {
    header
    echo -e "${GREEN}▶ Personnalisations${NC}"
    
    echo -e "${MAGENTA}● Installation de FastFetch...${NC}"
    arch-chroot /mnt pacman -S --noconfirm fastfetch > /dev/null 2>&1
    echo "fastfetch --logo arch --logo-color-1 blue --logo-color-2 0xff --logo-color-3 0xff" >> /mnt/home/$USERNAME/.bashrc
    
    echo -e "${MAGENTA}● Installation des thèmes GRUB...${NC}"
    arch-chroot /mnt git clone https://github.com/ChrisTitusTech/fallout-grub-theme /tmp/fallout-grub-theme
    arch-chroot /mnt cp -r /tmp/fallout-grub-theme /boot/grub/themes/
    echo "GRUB_THEME=\"/boot/grub/themes/fallout-grub-theme/theme.txt\"" >> /mnt/etc/default/grub
    
    themes=(
        "https://github.com/mateosss/grub2-theme-bsol"
        "https://github.com/Patato777/dark_matter"
        "https://github.com/AdisonCavani/Arc-GRUB"
        "https://github.com/sleekmike/star-wars-grub-theme"
        "https://github.com/ChrisTitusTech/grub-themes"
    )
    
    for theme in "${themes[@]}"; do
        theme_name=$(basename $theme)
        echo -e "${CYAN}● Téléchargement du thème $theme_name...${NC}"
        arch-chroot /mnt git clone $theme /boot/grub/themes/$theme_name > /dev/null 2>&1 || \
            echo -e "${YELLOW}⚠ Impossible de télécharger $theme_name${NC}"
    done
    
    echo -e "${MAGENTA}● Configuration de SDDM...${NC}"
    arch-chroot /mnt pacman -S --noconfirm sddm qt5-quickcontrols2 qt5-graphicaleffects > /dev/null 2>&1
    arch-chroot /mnt git clone https://github.com/arc-design/sddm-arcane-theme /tmp/sddm-arcane-theme
    arch-chroot /mnt cp -r /tmp/sddm-arcane-theme /usr/share/sddm/themes/arcane
    
    echo -e "[Theme]" > /mnt/etc/sddm.conf
    echo "Current=arcane" >> /mnt/etc/sddm.conf
    
    echo -e "${MAGENTA}● Téléchargement du fond animé...${NC}"
    arch-chroot /mnt mkdir -p /usr/share/backgrounds
    arch-chroot /mnt curl -L https://github.com/ArcDesignResources/AnimatedBackgrounds/raw/main/arcane-loop.mp4 -o /usr/share/backgrounds/arcane-loop.mp4
    
    echo -e "${MAGENTA}● Configuration de Hyprland...${NC}"
    arch-chroot /mnt mkdir -p /home/$USERNAME/.config/hypr/
    cat > /mnt/home/$USERNAME/.config/hypr/hyprland.conf << 'EOF'
exec-once = swww init
exec-once = swww img /usr/share/backgrounds/arcane-loop.mp4 --transition-type wipe --transition-angle 30 --transition-step 90

# Barre Waybar transparente
exec-once = waybar -c ~/.config/waybar/config.json

# Transparence applications
windowrulev2 = opacity 0.95, class:^(kitty)$
windowrulev2 = opacity 0.90, class:^(Code)$
windowrulev2 = opacity 0.92, class:^(Brave-browser)$
windowrulev2 = opacity 0.94, class:^(discord)$

# Positionnement fenêtre
windowrulev2 = float, title:^(Volume Control)$
windowrulev2 = move 75% 90%, title:^(Volume Control)$
windowrulev2 = size 400 200, title:^(Volume Control)$

# Détection des basses sonores
exec-once = bass-detector
EOF

    echo -e "${MAGENTA}● Installation de Waybar...${NC}"
    arch-chroot /mnt pacman -S --noconfirm waybar > /dev/null 2>&1
    arch-chroot /mnt sudo -u $USERNAME git clone https://github.com/Alexays/Waybar /home/$USERNAME/.config/waybar
    
    # Configuration Waybar personnalisée
    cat > /mnt/home/$USERNAME/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "width": 1400,
    "margin-top": 5,
    "margin-left": "auto",
    "margin-right": "auto",
    "modules-left": ["custom/launcher", "hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "backlight", "battery", "network", "tray"],
    "background": "rgba(30, 30, 46, 0.7)",
    "border-radius": 10,
    "spacing": 4,
}
EOF
    
    # Installation de Spicetify pour Spotify
    echo -e "${MAGENTA}● Configuration de Spicetify...${NC}"
    arch-chroot /mnt sudo -u $USERNAME bash -c "curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh"
    arch-chroot /mnt sudo -u $USERNAME bash -c "spicetify config current_theme Arcane color_scheme purple"
    arch-chroot /mnt sudo -u $USERNAME bash -c "spicetify apply"
    
    # Installation de l'animation Fallout pour le verrouillage
    echo -e "${MAGENTA}● Installation de l'animation Fallout...${NC}"
    arch-chroot /mnt git clone https://github.com/Fallout-Theme/fallout-lock /tmp/fallout-lock
    arch-chroot /mnt cp /tmp/fallout-lock/fallout-lock /usr/local/bin/
    chmod +x /mnt/usr/local/bin/fallout-lock
    
    # Ajout au fichier de configuration Hyprland
    echo "bind = SUPER, L, exec, fallout-lock" >> /mnt/home/$USERNAME/.config/hypr/hyprland.conf
    
    # Bip sonore au démarrage
    echo -e "${MAGENTA}● Téléchargement du bip sonore...${NC}"
    arch-chroot /mnt curl -L https://github.com/ArcDesignResources/SoundEffects/raw/main/boot_sound.mp3 -o /usr/share/sounds/boot_sound.mp3
    echo "aplay /usr/share/sounds/boot_sound.mp3" >> /mnt/etc/profile
}

# Finalisation
function finalize() {
    header
    echo -e "${GREEN}▶ Finalisation de l'installation${NC}"
    
    echo -e "${MAGENTA}● Configuration de GRUB...${NC}"
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB > /dev/null 2>&1
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
    
    echo -e "${MAGENTA}● Activation des services...${NC}"
    arch-chroot /mnt systemctl enable sddm > /dev/null 2>&1
    arch-chroot /mnt systemctl enable NetworkManager > /dev/null 2>&1
    
    echo -e "${GREEN}"
    echo -e "██████╗  ██████╗ ██████╗ ███████╗"
    echo -e "██╔══██╗██╔═══██╗██╔══██╗██╔════╝"
    echo -e "██████╔╝██║   ██║██████╔╝███████╗"
    echo -e "██╔═══╝ ██║   ██║██╔═══╝ ╚════██║"
    echo -e "██║     ╚██████╔╝██║     ███████║"
    echo -e "╚═╝      ╚═════╝ ╚═╝     ╚══════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}========================================================================================"
    echo -e "Installation terminée avec succès!"
    echo -e "Redémarrez avec : ${CYAN}umount -R /mnt && reboot${NC}"
    echo -e "${YELLOW}========================================================================================${NC}"
    echo -e "${MAGENTA}Informations importantes:${NC}"
    echo -e "- Le thème GRUB par défaut est Fallout"
    echo -e "- Les autres thèmes sont disponibles dans /boot/grub/themes/"
    echo -e "- Pour changer de thème GRUB:"
    echo -e "  1. Éditez /etc/default/grub"
    echo -e "  2. Modifiez la ligne GRUB_THEME"
    echo -e "  3. Exécutez: grub-mkconfig -o /boot/grub/grub.cfg"
    echo -e "${YELLOW}========================================================================================${NC}"
}

# Exécution des étapes
set -e
header
setup_disks
install_base
configure_system
install_hyprland
customizations
finalize
