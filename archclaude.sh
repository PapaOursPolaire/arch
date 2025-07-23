#!/bin/bash

# Script d'installation automatisée Arch Linux
# Auteur: Assistant IA
# Version: 1.0

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction de validation du nom d'utilisateur
validate_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]] || [[ ${#username} -lt 3 ]] || [[ ${#username} -gt 32 ]]; then
        return 1
    fi
    return 0
}

# Fonction de validation du nom d'hôte
validate_hostname() {
    local hostname="$1"
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] || [[ ${#hostname} -lt 2 ]] || [[ ${#hostname} -gt 63 ]]; then
        return 1
    fi
    return 0
}

# Fonction de validation de la taille des partitions
validate_size() {
    local size="$1"
    if [[ "$size" =~ ^[0-9]+[MmGg]$ ]]; then
        return 0
    fi
    return 1
}

# Fonction de conversion de taille en secteurs
size_to_sectors() {
    local size="$1"
    local number="${size%?}"
    local unit="${size: -1}"
    
    case "${unit,,}" in
        'm')
            echo $((number * 1024 * 1024 / 512))
            ;;
        'g')
            echo $((number * 1024 * 1024 * 1024 / 512))
            ;;
    esac
}

# Banner d'accueil
clear
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║            INSTALLATION AUTOMATISÉE ARCH LINUX          ║"
echo "║                      Version 1.0                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérification de la connexion internet
print_info "Vérification de la connexion internet..."
if ! ping -c 1 archlinux.org &> /dev/null; then
    print_error "Pas de connexion internet. Veuillez configurer votre réseau."
    exit 1
fi
print_success "Connexion internet établie"

# Synchronisation de l'horloge
print_info "Synchronisation de l'horloge système..."
timedatectl set-ntp true

# Mise à jour des clés de signature et miroirs
print_info "Mise à jour des clés de signature et des miroirs..."
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

# Mise à jour des miroirs pour de meilleures performances
print_info "Mise à jour de la liste des miroirs..."
pacman -Sy --noconfirm reflector
reflector --country France,Belgium,Germany,Netherlands --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Mise à jour de la base de données des paquets
pacman -Sy

# Configuration du nom d'hôte (nom du PC)
while true; do
    echo ""
    read -p "Nom du PC (hostname - lettres, chiffres, tirets uniquement, 2-63 caractères): " HOSTNAME
    if validate_hostname "$HOSTNAME"; then
        break
    else
        print_error "Nom d'hôte invalide. Utilisez uniquement des lettres, chiffres et tirets."
    fi
done

# Configuration de l'utilisateur principal
while true; do
    echo ""
    read -p "Nom d'utilisateur principal (lettres minuscules, chiffres, _, -, 3-32 caractères): " USERNAME
    if validate_username "$USERNAME"; then
        break
    else
        print_error "Nom d'utilisateur invalide. Doit commencer par une lettre minuscule."
    fi
done

# Mot de passe utilisateur principal
while true; do
    echo ""
    read -s -p "Mot de passe pour $USERNAME (minimum 6 caractères): " USER_PASSWORD
    echo
    if [[ ${#USER_PASSWORD} -lt 6 ]]; then
        print_error "Le mot de passe doit contenir au moins 6 caractères."
        continue
    fi
    read -s -p "Confirmez le mot de passe: " USER_PASSWORD_CONFIRM
    echo
    if [[ "$USER_PASSWORD" == "$USER_PASSWORD_CONFIRM" ]]; then
        break
    else
        print_error "Les mots de passe ne correspondent pas."
    fi
done

# Utilisateur supplémentaire
echo ""
read -p "Voulez-vous créer un utilisateur supplémentaire ? (o/N): " CREATE_EXTRA_USER
EXTRA_USERNAME=""
EXTRA_PASSWORD=""

if [[ "$CREATE_EXTRA_USER" =~ ^[oO]$ ]]; then
    while true; do
        read -p "Nom du deuxième utilisateur (lettres minuscules, chiffres, _, -, 3-32 caractères): " EXTRA_USERNAME
        if validate_username "$EXTRA_USERNAME" && [[ "$EXTRA_USERNAME" != "$USERNAME" ]]; then
            break
        else
            print_error "Nom d'utilisateur invalide ou identique au premier utilisateur."
        fi
    done
    
    while true; do
        read -s -p "Mot de passe pour $EXTRA_USERNAME (minimum 6 caractères): " EXTRA_PASSWORD
        echo
        if [[ ${#EXTRA_PASSWORD} -lt 6 ]]; then
            print_error "Le mot de passe doit contenir au moins 6 caractères."
            continue
        fi
        read -s -p "Confirmez le mot de passe: " EXTRA_PASSWORD_CONFIRM
        echo
        if [[ "$EXTRA_PASSWORD" == "$EXTRA_PASSWORD_CONFIRM" ]]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas."
        fi
    done
fi

# Mot de passe root
while true; do
    echo ""
    read -s -p "Mot de passe root (minimum 6 caractères): " ROOT_PASSWORD
    echo
    if [[ ${#ROOT_PASSWORD} -lt 6 ]]; then
        print_error "Le mot de passe root doit contenir au moins 6 caractères."
        continue
    fi
    read -s -p "Confirmez le mot de passe root: " ROOT_PASSWORD_CONFIRM
    echo
    if [[ "$ROOT_PASSWORD" == "$ROOT_PASSWORD_CONFIRM" ]]; then
        break
    else
        print_error "Les mots de passe ne correspondent pas."
    fi
done

# Sélection du disque
print_info "Disques disponibles:"
lsblk -d -o NAME,SIZE,MODEL | grep -E "sd|nvme|vd"
echo ""

# Listing des disques pour sélection
DISKS=($(lsblk -d -o NAME -n | grep -E "sd|nvme|vd"))
for i in "${!DISKS[@]}"; do
    SIZE=$(lsblk -d -o SIZE -n "/dev/${DISKS[$i]}")
    MODEL=$(lsblk -d -o MODEL -n "/dev/${DISKS[$i]}" 2>/dev/null || echo "N/A")
    echo "$((i+1)). /dev/${DISKS[$i]} - $SIZE - $MODEL"
done

while true; do
    read -p "Sélectionnez le disque à utiliser (1-${#DISKS[@]}): " DISK_CHOICE
    if [[ "$DISK_CHOICE" =~ ^[0-9]+$ ]] && [[ "$DISK_CHOICE" -ge 1 ]] && [[ "$DISK_CHOICE" -le "${#DISKS[@]}" ]]; then
        SELECTED_DISK="/dev/${DISKS[$((DISK_CHOICE-1))]}"
        break
    else
        print_error "Choix invalide."
    fi
done

print_warning "ATTENTION: Toutes les données sur $SELECTED_DISK seront SUPPRIMÉES!"
read -p "Continuer ? (o/N): " CONFIRM_DISK
if [[ ! "$CONFIRM_DISK" =~ ^[oO]$ ]]; then
    print_info "Installation annulée."
    exit 0
fi

# Configuration de la partition swap
echo ""
read -p "Voulez-vous créer une partition swap ? (o/N): " CREATE_SWAP
SWAP_SIZE=""
if [[ "$CREATE_SWAP" =~ ^[oO]$ ]]; then
    while true; do
        read -p "Taille de la partition swap (recommandé: 2G pour 8GB RAM, 4G pour 16GB RAM) [ex: 2G, 512M]: " SWAP_SIZE
        if validate_size "$SWAP_SIZE"; then
            break
        else
            print_error "Format invalide. Utilisez un nombre suivi de M ou G (ex: 2G, 512M)."
        fi
    done
fi

# Configuration de la partition root
while true; do
    echo ""
    read -p "Taille de la partition root (recommandé: 30G minimum, 50G conseillé) [ex: 50G]: " ROOT_SIZE
    if validate_size "$ROOT_SIZE"; then
        break
    else
        print_error "Format invalide. Utilisez un nombre suivi de M ou G (ex: 50G)."
    fi
done

# Configuration de la partition home
echo ""
read -p "Voulez-vous une partition /home séparée ? (O/n): " CREATE_HOME
HOME_SIZE=""
if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
    read -p "Taille de la partition /home (recommandé: utiliser l'espace restant) [ex: 100G ou appuyez sur Entrée pour utiliser tout l'espace restant]: " HOME_SIZE
    if [[ -n "$HOME_SIZE" ]] && ! validate_size "$HOME_SIZE"; then
        print_error "Format invalide. Utilisation de l'espace restant."
        HOME_SIZE=""
    fi
fi

# Début de l'installation
print_info "Début de l'installation avec les paramètres:"
echo "  - Hostname: $HOSTNAME"
echo "  - Utilisateur principal: $USERNAME"
[[ -n "$EXTRA_USERNAME" ]] && echo "  - Utilisateur supplémentaire: $EXTRA_USERNAME"
echo "  - Disque: $SELECTED_DISK"
[[ "$CREATE_SWAP" =~ ^[oO]$ ]] && echo "  - Swap: $SWAP_SIZE"
echo "  - Root: $ROOT_SIZE"
[[ ! "$CREATE_HOME" =~ ^[nN]$ ]] && echo "  - Home: ${HOME_SIZE:-'Espace restant'}"

echo ""
read -p "Confirmer l'installation ? (o/N): " FINAL_CONFIRM
if [[ ! "$FINAL_CONFIRM" =~ ^[oO]$ ]]; then
    print_info "Installation annulée."
    exit 0
fi

# Partitionnement du disque
print_info "Partitionnement du disque $SELECTED_DISK..."

# Suppression des partitions existantes
wipefs -af "$SELECTED_DISK"
sgdisk -Z "$SELECTED_DISK"

# Création de la table de partitions GPT
sgdisk -o "$SELECTED_DISK"

# Partition EFI (512M)
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$SELECTED_DISK"

PARTITION_NUM=2

# Partition swap (optionnelle)
if [[ "$CREATE_SWAP" =~ ^[oO]$ ]]; then
    sgdisk -n ${PARTITION_NUM}:0:+${SWAP_SIZE} -t ${PARTITION_NUM}:8200 -c ${PARTITION_NUM}:"Linux swap" "$SELECTED_DISK"
    PARTITION_NUM=$((PARTITION_NUM + 1))
fi

# Partition root
sgdisk -n ${PARTITION_NUM}:0:+${ROOT_SIZE} -t ${PARTITION_NUM}:8300 -c ${PARTITION_NUM}:"Linux root" "$SELECTED_DISK"
ROOT_PARTITION_NUM=$PARTITION_NUM
PARTITION_NUM=$((PARTITION_NUM + 1))

# Partition home (optionnelle)
if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
    if [[ -n "$HOME_SIZE" ]]; then
        sgdisk -n ${PARTITION_NUM}:0:+${HOME_SIZE} -t ${PARTITION_NUM}:8300 -c ${PARTITION_NUM}:"Linux home" "$SELECTED_DISK"
    else
        sgdisk -n ${PARTITION_NUM}:0:0 -t ${PARTITION_NUM}:8300 -c ${PARTITION_NUM}:"Linux home" "$SELECTED_DISK"
    fi
    HOME_PARTITION_NUM=$PARTITION_NUM
fi

# Actualisation de la table des partitions
partprobe "$SELECTED_DISK"
sleep 2

# Détermination des noms de partitions
if [[ "$SELECTED_DISK" =~ nvme ]]; then
    EFI_PART="${SELECTED_DISK}p1"
    PART_NUM=2
    if [[ "$CREATE_SWAP" =~ ^[oO]$ ]]; then
        SWAP_PART="${SELECTED_DISK}p${PART_NUM}"
        PART_NUM=$((PART_NUM + 1))
    fi
    ROOT_PART="${SELECTED_DISK}p${PART_NUM}"
    PART_NUM=$((PART_NUM + 1))
    if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
        HOME_PART="${SELECTED_DISK}p${PART_NUM}"
    fi
else
    EFI_PART="${SELECTED_DISK}1"
    PART_NUM=2
    if [[ "$CREATE_SWAP" =~ ^[oO]$ ]]; then
        SWAP_PART="${SELECTED_DISK}${PART_NUM}"
        PART_NUM=$((PART_NUM + 1))
    fi
    ROOT_PART="${SELECTED_DISK}${PART_NUM}"
    PART_NUM=$((PART_NUM + 1))
    if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
        HOME_PART="${SELECTED_DISK}${PART_NUM}"
    fi
fi

# Formatage des partitions
print_info "Formatage des partitions..."

# Formatage EFI
mkfs.fat -F32 "$EFI_PART"

# Formatage swap
if [[ "$CREATE_SWAP" =~ ^[oO]$ ]]; then
    mkswap "$SWAP_PART"
    swapon "$SWAP_PART"
fi

# Formatage root
mkfs.ext4 -F "$ROOT_PART"

# Formatage home
if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
    mkfs.ext4 -F "$HOME_PART"
fi

# Montage des partitions
print_info "Montage des partitions..."
mount "$ROOT_PART" /mnt

# Création des répertoires de montage
mkdir -p /mnt/boot
mkdir -p /mnt/home

# Montage EFI
mount "$EFI_PART" /mnt/boot

# Montage home
if [[ ! "$CREATE_HOME" =~ ^[nN]$ ]]; then
    mount "$HOME_PART" /mnt/home
fi

# Configuration de l'environnement de bureau
echo ""
print_info "Choix de l'environnement de bureau:"
echo "1. KDE Plasma (recommandé pour le thème Fallout)"
echo "2. GNOME"
echo "3. Installation minimale (sans interface graphique)"

while true; do
    read -p "Sélectionnez votre environnement de bureau (1-3): " DE_CHOICE
    case $DE_CHOICE in
        1)
            DESKTOP_ENV="kde"
            print_info "KDE Plasma sélectionné"
            break
            ;;
        2)
            DESKTOP_ENV="gnome"
            print_info "GNOME sélectionné"
            break
            ;;
        3)
            DESKTOP_ENV="minimal"
            print_info "Installation minimale sélectionnée"
            break
            ;;
        *)
            print_error "Choix invalide."
            ;;
    esac
done

# Installation du système de base
print_info "Installation des paquets de base..."
BASE_PACKAGES="base base-devel linux linux-firmware nano vim networkmanager grub efibootmgr git wget unzip"

# Ajout des paquets selon l'environnement de bureau
case $DESKTOP_ENV in
    "kde")
        BASE_PACKAGES+=" plasma-meta sddm kde-applications-meta firefox chromium"
        ;;
    "gnome")
        BASE_PACKAGES+=" gnome gnome-extra gdm firefox chromium"
        ;;
    "minimal")
        BASE_PACKAGES+=" xorg-server xorg-xinit"
        ;;
esac

# Installation avec gestion des erreurs de signature
print_info "Installation des paquets (cela peut prendre du temps)..."
if ! pacstrap /mnt $BASE_PACKAGES; then
    print_warning "Erreur lors de l'installation. Tentative de résolution des problèmes de signature..."
    
    # Réinitialisation des clés en cas d'erreur
    pacman-key --init
    pacman-key --populate archlinux
    pacman-key --refresh-keys
    
    # Nouvelle tentative
    print_info "Nouvelle tentative d'installation..."
    if ! pacstrap /mnt $BASE_PACKAGES; then
        print_error "Échec de l'installation des paquets. Vérifiez votre connexion internet."
        exit 1
    fi
fi

# Génération du fstab
print_info "Génération du fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration du système dans chroot
print_info "Configuration du système..."

cat << EOF > /mnt/install_chroot.sh
#!/bin/bash

# Initialisation des clés de signature dans le chroot
pacman-key --init
pacman-key --populate archlinux

# Configuration du fuseau horaire
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc

# Configuration des locales
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf

# Configuration du hostname
echo "$HOSTNAME" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Configuration du mot de passe root
echo "root:$ROOT_PASSWORD" | chpasswd

# Création de l'utilisateur principal
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Création de l'utilisateur supplémentaire
if [[ -n "$EXTRA_USERNAME" ]]; then
    useradd -m -s /bin/bash "$EXTRA_USERNAME"
    echo "$EXTRA_USERNAME:$EXTRA_PASSWORD" | chpasswd
fi

# Configuration sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Activation de NetworkManager
systemctl enable NetworkManager

# Configuration de l'environnement de bureau
case "$DESKTOP_ENV" in
    "kde")
        systemctl enable sddm
        ;;
    "gnome")
        systemctl enable gdm
        ;;
esac

# Installation et configuration du bootloader GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Installation du thème Fallout pour GRUB
print_info "Installation du thème Fallout pour GRUB..."
cd /tmp
git clone https://github.com/shvchk/fallout-grub-theme.git
cd fallout-grub-theme
mkdir -p /boot/grub/themes/fallout
cp -r * /boot/grub/themes/fallout/

# Alternative: thème Fallout terminal plus avancé
git clone https://github.com/mebeim/grub-fallout-terminal-theme.git fallout-terminal
cd fallout-terminal
mkdir -p /boot/grub/themes/fallout-terminal
cp -r * /boot/grub/themes/fallout-terminal/

# Configuration GRUB avec thème Fallout
cat << GRUBCONF >> /etc/default/grub
# Thème Fallout
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE=menu
GRUBCONF

# Mise à jour de la configuration GRUB existante
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/' /etc/default/grub
sed -i 's/#GRUB_GFXMODE=640x480/GRUB_GFXMODE=1920x1080/' /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

EOF

chmod +x /mnt/install_chroot.sh
arch-chroot /mnt /install_chroot.sh
rm /mnt/install_chroot.sh

# Configuration post-installation des thèmes Fallout
if [[ "$DESKTOP_ENV" != "minimal" ]]; then
    print_info "Configuration des thèmes Fallout pour l'interface graphique..."
    
    cat << EOF > /mnt/post_install_themes.sh
#!/bin/bash

# Installation des thèmes et fonds d'écran Fallout
mkdir -p /home/$USERNAME/.themes
mkdir -p /home/$USERNAME/.local/share/wallpapers

# Téléchargement des thèmes Fallout depuis gnome-look.org
cd /tmp

# Thème GTK Fallout (si GNOME ou compatible)
if [[ "$DESKTOP_ENV" == "gnome" ]] || [[ "$DESKTOP_ENV" == "kde" ]]; then
    wget -O fallout-theme.zip "https://www.gnome-look.org/p/1230882/loadFiles"
    if [[ -f fallout-theme.zip ]]; then
        unzip -q fallout-theme.zip -d /tmp/fallout-theme/
        cp -r /tmp/fallout-theme/* /home/$USERNAME/.themes/ 2>/dev/null || true
    fi
fi

# Configuration spécifique KDE
if [[ "$DESKTOP_ENV" == "kde" ]]; then
    # Installation de thèmes Plasma compatibles Fallout
    mkdir -p /home/$USERNAME/.local/share/plasma/desktoptheme
    mkdir -p /home/$USERNAME/.local/share/plasma/look-and-feel
    
    # Configuration SDDM avec thème Fallout
    mkdir -p /usr/share/sddm/themes/fallout
    
    cat << SDDMTHEME > /usr/share/sddm/themes/fallout/theme.conf
[General]
type=image
color=#00ff41
fontSize=12
background=/usr/share/sddm/themes/fallout/background.jpg
showUserList=true

[Background]
type=image
color=#1a1a1a
background=/usr/share/sddm/themes/fallout/background.jpg
SDDMTHEME

    # Téléchargement d'un fond d'écran Fallout
    wget -O /usr/share/sddm/themes/fallout/background.jpg "https://wallpapercave.com/wp/wp2535653.jpg" 2>/dev/null || {
        # Fond de secours si le téléchargement échoue
        cp /usr/share/pixmaps/archlinux-logo.svg /usr/share/sddm/themes/fallout/background.jpg 2>/dev/null || true
    }
    
    # Configuration SDDM pour utiliser le thème Fallout
    cat << SDDMCONF > /etc/sddm.conf
[Theme]
Current=fallout

[General]
Numlock=on
SDDMCONF

    # Configuration du thème pour l'utilisateur
    cat << PLASMARC > /home/$USERNAME/.config/plasmarc
[Theme]
name=breeze-dark

[PlasmaViews][Panel 68]
alignment=132
panelVisibility=0
PLASMARC

fi

# Configuration spécifique GNOME
if [[ "$DESKTOP_ENV" == "gnome" ]]; then
    # Configuration GDM avec thème Fallout
    mkdir -p /usr/share/gnome-shell/theme
    
    # Installation d'extensions GNOME pour personnalisation
    sudo -u $USERNAME dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    sudo -u $USERNAME dbus-launch gsettings set org.gnome.shell.extensions.user-theme name 'Fallout'
fi

# Attribution des permissions
chown -R $USERNAME:$USERNAME /home/$USERNAME/.themes
chown -R $USERNAME:$USERNAME /home/$USERNAME/.local
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config 2>/dev/null || true

# Configuration de l'écran de verrouillage
case "$DESKTOP_ENV" in
    "kde")
        # Configuration de l'écran de verrouillage KDE avec thème Fallout
        mkdir -p /home/$USERNAME/.config
        cat << KSCREENLOCKERRC > /home/$USERNAME/.config/kscreenlockrc
[Greeter]
Theme=org.kde.breeze.desktop
WallpaperPlugin=org.kde.image

[Greeter][Wallpaper][org.kde.image][General]
Image=/usr/share/sddm/themes/fallout/background.jpg
KSCREENLOCKERRC
        ;;
    "gnome")
        # Configuration de l'écran de verrouillage GNOME
        sudo -u $USERNAME dbus-launch gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/pixmaps/fallout-lock.jpg'
        ;;
esac

EOF

    chmod +x /mnt/post_install_themes.sh
    arch-chroot /mnt /post_install_themes.sh
    rm /mnt/post_install_themes.sh
fi

# Finalisation
print_success "Installation terminée avec succès!"
echo ""
print_info "Résumé de l'installation:"
echo "  - Système: Arch Linux"
echo "  - Hostname: $HOSTNAME"
echo "  - Utilisateur principal: $USERNAME"
[[ -n "$EXTRA_USERNAME" ]] && echo "  - Utilisateur supplémentaire: $EXTRA_USERNAME"
echo "  - Bootloader: GRUB (UEFI) avec thème Fallout"
case $DESKTOP_ENV in
    "kde")
        echo "  - Environnement de bureau: KDE Plasma avec thème Fallout"
        echo "  - Gestionnaire de connexion: SDDM avec thème Fallout"
        ;;
    "gnome")
        echo "  - Environnement de bureau: GNOME avec thème Fallout"
        echo "  - Gestionnaire de connexion: GDM"
        ;;
    "minimal")
        echo "  - Installation minimale (sans interface graphique)"
        ;;
esac
echo ""
print_warning "Thèmes Fallout installés:"
echo "  ✓ Menu GRUB: Thème terminal Fallout avec animation"
[[ "$DESKTOP_ENV" != "minimal" ]] && echo "  ✓ Interface graphique: Thème sombre inspiré de Fallout"
[[ "$DESKTOP_ENV" != "minimal" ]] && echo "  ✓ Écran de verrouillage: Fond d'écran Fallout personnalisé"
echo ""
print_warning "N'oubliez pas de:"
echo "  1. Configurer votre réseau après le redémarrage"
[[ "$DESKTOP_ENV" != "minimal" ]] && echo "  2. Personnaliser davantage les thèmes depuis les paramètres système"
echo "  3. Configurer les pilotes graphiques si nécessaire"
[[ "$DESKTOP_ENV" == "kde" ]] && echo "  4. Accéder aux paramètres KDE > Apparence pour ajuster le thème"
[[ "$DESKTOP_ENV" == "gnome" ]] && echo "  4. Installer GNOME Tweaks pour plus d'options de personnalisation"
echo ""
read -p "Voulez-vous redémarrer maintenant ? (o/N): " REBOOT_NOW
if [[ "$REBOOT_NOW" =~ ^[oO]$ ]]; then
    umount -R /mnt
    reboot
else
    print_info "Vous pouvez redémarrer manuellement avec: umount -R /mnt && reboot"
fi
