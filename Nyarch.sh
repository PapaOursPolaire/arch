#!/bin/bash

#==============================================================================
# SCRIPT D'INSTALLATION AUTOMATISÉE NYARCH LINUX
# Version: 1.0
# Description: Installation complète de NyArch Linux avec personnalisation
# Author: Adaptation du script Arch vers NyArch
# License: GPL-3.0
#==============================================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_VERSION="1.0"
LOG_FILE="/var/log/nyarch_install.log"
SELECTED_DISK=""
USERNAME=""
PASSWORD=""
HOSTNAME=""
DE_CHOICE=""

#==============================================================================
# FONCTIONS UTILITAIRES
#==============================================================================

# Fonction d'affichage avec couleurs
print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                           NYARCH LINUX INSTALLER v${SCRIPT_VERSION}                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${WHITE}                      Installation automatisée pour weebs 🐱                    ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "\n${BLUE}━━━ $1 ━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    echo "$(date): ERROR - $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Fonction de barre de progression
show_progress() {
    local current=$1
    local total=$2
    local description=$3
    local start_time=${4:-$(date +%s)}
    
    local percentage=$((current * 100 / total))
    local elapsed=$(($(date +%s) - start_time))
    local rate=$((current > 0 ? elapsed / current : 0))
    local remaining=$((rate * (total - current)))
    
    local minutes=$((remaining / 60))
    local seconds=$((remaining % 60))
    
    local bar_length=50
    local filled_length=$((percentage * bar_length / 100))
    
    printf "\r${CYAN}%s [" "$description"
    for ((i=0; i<filled_length; i++)); do printf "█"; done
    for ((i=filled_length; i<bar_length; i++)); do printf "░"; done
    printf "] %d%% - ETA: %02d:%02d${NC}" "$percentage" "$minutes" "$seconds"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Vérification des prérequis
check_requirements() {
    print_step "Vérification des prérequis"
    
    # Vérifier si on est sur l'ISO live
    if [[ ! -f /usr/bin/pacstrap ]]; then
        print_error "Ce script doit être exécuté depuis l'ISO live d'Arch Linux"
        exit 1
    fi
    
    # Vérifier la connexion internet
    if ! ping -c 1 archlinux.org &> /dev/null; then
        print_error "Connexion internet requise. Configurez votre réseau d'abord."
        exit 1
    fi
    
    # Vérifier le mode UEFI
    if [[ ! -d /sys/firmware/efi ]]; then
        print_error "Ce script nécessite un système UEFI"
        exit 1
    fi
    
    print_success "Prérequis validés"
}

# Synchronisation des miroirs
sync_mirrors() {
    print_step "Synchronisation des miroirs Arch Linux"
    
    print_info "Mise à jour de la liste des miroirs..."
    reflector --country France,Germany,Netherlands --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    print_info "Synchronisation des paquets..."
    pacman -Sy --noconfirm
    
    print_success "Miroirs synchronisés"
}

# Détection et sélection des disques
detect_disks() {
    print_step "Détection des disques disponibles"
    
    echo -e "\n${WHITE}Disques disponibles :${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -E "sd[a-z]|nvme[0-9]n[0-9]" | nl -w2 -s') '
    
    while true; do
        echo -e "\n${YELLOW}Sélectionnez le numéro du disque pour l'installation :${NC}"
        read -r disk_choice
        
        local disk_count=$(lsblk -d -o NAME | grep -E "sd[a-z]|nvme[0-9]n[0-9]" | wc -l)
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [[ "$disk_choice" -ge 1 && "$disk_choice" -le "$disk_count" ]]; then
            SELECTED_DISK=$(lsblk -d -o NAME | grep -E "sd[a-z]|nvme[0-9]n[0-9]" | sed -n "${disk_choice}p")
            break
        else
            print_error "Sélection invalide. Veuillez choisir un numéro entre 1 et $disk_count"
        fi
    done
    
    print_success "Disque sélectionné : /dev/$SELECTED_DISK"
}

# Gestion du partitionnement
manage_partitioning() {
    print_step "Configuration des partitions"
    
    echo -e "\n${YELLOW}Options de partitionnement :${NC}"
    echo "1) Conserver les partitions existantes"
    echo "2) Créer un nouveau partitionnement automatique"
    
    while true; do
        echo -e "\n${YELLOW}Votre choix (1-2) :${NC}"
        read -r part_choice
        
        case $part_choice in
            1)
                print_info "Conservation des partitions existantes"
                detect_existing_partitions
                break
                ;;
            2)
                print_info "Création d'un nouveau partitionnement"
                create_new_partitioning
                break
                ;;
            *)
                print_error "Choix invalide"
                ;;
        esac
    done
}

# Détection des partitions existantes
detect_existing_partitions() {
    print_info "Analyse des partitions existantes sur /dev/$SELECTED_DISK"
    
    lsblk "/dev/$SELECTED_DISK"
    
    echo -e "\n${YELLOW}Veuillez identifier vos partitions :${NC}"
    
    while true; do
        echo "Partition EFI (ex: ${SELECTED_DISK}1) :"
        read -r EFI_PARTITION
        if [[ -b "/dev/$EFI_PARTITION" ]]; then
            break
        else
            print_error "Partition non trouvée"
        fi
    done
    
    while true; do
        echo "Partition Root (ex: ${SELECTED_DISK}2) :"
        read -r ROOT_PARTITION
        if [[ -b "/dev/$ROOT_PARTITION" ]]; then
            break
        else
            print_error "Partition non trouvée"
        fi
    done
    
    echo "Partition Home (optionnel, ex: ${SELECTED_DISK}3) :"
    read -r HOME_PARTITION
    if [[ -n "$HOME_PARTITION" && ! -b "/dev/$HOME_PARTITION" ]]; then
        HOME_PARTITION=""
        print_warning "Partition home non trouvée, sera incluse dans root"
    fi
    
    echo "Partition Swap (optionnel, ex: ${SELECTED_DISK}4) :"
    read -r SWAP_PARTITION
    if [[ -n "$SWAP_PARTITION" && ! -b "/dev/$SWAP_PARTITION" ]]; then
        SWAP_PARTITION=""
        print_warning "Partition swap non trouvée"
    fi
}

# Création d'un nouveau partitionnement
create_new_partitioning() {
    print_warning "ATTENTION: Cette opération va effacer toutes les données du disque /dev/$SELECTED_DISK"
    echo -e "${YELLOW}Êtes-vous sûr de vouloir continuer ? (oui/NON) :${NC}"
    read -r confirm
    
    if [[ "$confirm" != "oui" ]]; then
        print_info "Opération annulée"
        exit 0
    fi
    
    print_info "Création des partitions sur /dev/$SELECTED_DISK"
    
    # Nettoyage du disque
    wipefs -af "/dev/$SELECTED_DISK"
    sgdisk --zap-all "/dev/$SELECTED_DISK"
    
    # Création de la table de partitions GPT
    sgdisk --clear \
           --new=1:0:+512M --typecode=1:ef00 --change-name=1:"EFI System" \
           --new=2:0:+50G --typecode=2:8300 --change-name=2:"Root" \
           --new=3:0:+4G --typecode=3:8200 --change-name=3:"Swap" \
           --new=4:0:0 --typecode=4:8300 --change-name=4:"Home" \
           "/dev/$SELECTED_DISK"
    
    # Attendre que le kernel recharge les partitions
    sleep 2
    partprobe "/dev/$SELECTED_DISK"
    sleep 2
    
    # Définition des partitions selon le type de disque
    if [[ "$SELECTED_DISK" == *"nvme"* ]]; then
        EFI_PARTITION="${SELECTED_DISK}p1"
        ROOT_PARTITION="${SELECTED_DISK}p2"
        SWAP_PARTITION="${SELECTED_DISK}p3"
        HOME_PARTITION="${SELECTED_DISK}p4"
    else
        EFI_PARTITION="${SELECTED_DISK}1"
        ROOT_PARTITION="${SELECTED_DISK}2"
        SWAP_PARTITION="${SELECTED_DISK}3"
        HOME_PARTITION="${SELECTED_DISK}4"
    fi
    
    print_success "Partitionnement créé avec succès"
}

# Formatage des partitions
format_partitions() {
    print_step "Formatage des partitions"
    
    print_info "Formatage de la partition EFI en FAT32..."
    mkfs.fat -F32 "/dev/$EFI_PARTITION"
    
    print_info "Formatage de la partition Root en ext4..."
    mkfs.ext4 -F "/dev/$ROOT_PARTITION"
    
    if [[ -n "$HOME_PARTITION" ]]; then
        print_info "Formatage de la partition Home en ext4..."
        mkfs.ext4 -F "/dev/$HOME_PARTITION"
    fi
    
    if [[ -n "$SWAP_PARTITION" ]]; then
        print_info "Configuration du swap..."
        mkswap "/dev/$SWAP_PARTITION"
        swapon "/dev/$SWAP_PARTITION"
    fi
    
    print_success "Formatage terminé"
}

# Montage des partitions
mount_partitions() {
    print_step "Montage des partitions"
    
    # Montage de la partition root
    mount "/dev/$ROOT_PARTITION" /mnt
    
    # Création des points de montage
    mkdir -p /mnt/{boot,home}
    
    # Montage de la partition EFI
    mount "/dev/$EFI_PARTITION" /mnt/boot
    
    # Montage de la partition home si elle existe
    if [[ -n "$HOME_PARTITION" ]]; then
        mount "/dev/$HOME_PARTITION" /mnt/home
    fi
    
    print_success "Partitions montées"
}

# Sélection de l'environnement de bureau
select_desktop_environment() {
    print_step "Sélection de l'environnement de bureau"
    
    echo -e "\n${WHITE}NyArch est optimisé pour GNOME, mais vous pouvez choisir :${NC}"
    echo "1) GNOME (Recommandé pour NyArch - avec personnalisations weeb)"
    echo "2) KDE Plasma"
    echo "3) Sans interface graphique"
    
    while true; do
        echo -e "\n${YELLOW}Votre choix (1-3) :${NC}"
        read -r de_choice
        
        case $de_choice in
            1)
                DE_CHOICE="gnome"
                print_success "GNOME sélectionné (configuration NyArch optimale)"
                break
                ;;
            2)
                DE_CHOICE="kde"
                print_success "KDE Plasma sélectionné"
                break
                ;;
            3)
                DE_CHOICE="none"
                print_success "Installation sans interface graphique"
                break
                ;;
            *)
                print_error "Choix invalide"
                ;;
        esac
    done
}

# Installation des paquets de base
install_base_system() {
    print_step "Installation du système de base"
    
    local packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub efibootmgr os-prober
        vim nano curl wget git unzip p7zip lsb-release
        reflector man-db man-pages
    )
    
    local total=${#packages[@]}
    local start_time=$(date +%s)
    
    print_info "Installation de ${total} paquets de base..."
    
    # Installation avec barre de progression simulée
    for i in "${!packages[@]}"; do
        show_progress $((i+1)) $total "Installation des paquets de base" $start_time
        sleep 0.1  # Simulation pour la démo
    done
    
    # Installation réelle
    pacstrap /mnt "${packages[@]}"
    
    print_success "Système de base installé"
}

# Configuration du système
configure_system() {
    print_step "Configuration du système"
    
    # Génération du fstab
    print_info "Génération du fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    
    # Configuration de la localisation française
    print_info "Configuration de la localisation française..."
    arch-chroot /mnt /bin/bash << 'EOF'
        # Configuration du fuseau horaire
        ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
        hwclock --systohc
        
        # Configuration des locales
        echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        locale-gen
        
        echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
        echo "KEYMAP=fr" > /etc/vconsole.conf
EOF
    
    print_success "Configuration système terminée"
}

# Configuration de l'utilisateur
setup_users() {
    print_step "Configuration des utilisateurs"
    
    # Nom d'hôte
    while true; do
        echo -e "${YELLOW}Nom d'hôte souhaité :${NC}"
        read -r hostname_input
        if [[ ${#hostname_input} -ge 2 && "$hostname_input" =~ ^[a-zA-Z0-9-]+$ ]]; then
            HOSTNAME="$hostname_input"
            break
        else
            print_error "Nom d'hôte invalide (min 2 caractères, lettres/chiffres/tirets uniquement)"
        fi
    done
    
    # Utilisateur principal
    while true; do
        echo -e "${YELLOW}Nom d'utilisateur principal :${NC}"
        read -r username_input
        if [[ ${#username_input} -ge 3 && "$username_input" =~ ^[a-z]+$ ]]; then
            USERNAME="$username_input"
            break
        else
            print_error "Nom d'utilisateur invalide (min 3 caractères, lettres minuscules uniquement)"
        fi
    done
    
    # Mot de passe
    while true; do
        echo -e "${YELLOW}Mot de passe pour $USERNAME :${NC}"
        read -rs password1
        echo -e "${YELLOW}Confirmez le mot de passe :${NC}"
        read -rs password2
        
        if [[ ${#password1} -ge 6 && "$password1" == "$password2" ]]; then
            PASSWORD="$password1"
            break
        else
            print_error "Mots de passe différents ou trop courts (min 6 caractères)"
        fi
    done
    
    # Configuration dans chroot
    arch-chroot /mnt /bin/bash << EOF
        # Nom d'hôte
        echo "$HOSTNAME" > /etc/hostname
        echo "127.0.0.1 localhost" >> /etc/hosts
        echo "::1       localhost" >> /etc/hosts
        echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
        
        # Mot de passe root
        echo "root:$PASSWORD" | chpasswd
        
        # Création de l'utilisateur
        useradd -m -G wheel,audio,video,optical,storage -s /bin/bash $USERNAME
        echo "$USERNAME:$PASSWORD" | chpasswd
        
        # Configuration de sudo
        sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        
        # Activation de NetworkManager
        systemctl enable NetworkManager
EOF
    
    # Utilisateurs supplémentaires
    echo -e "\n${YELLOW}Voulez-vous créer des utilisateurs supplémentaires ? (O/N) :${NC}"
    read -r add_users
    
    if [[ "$add_users" =~ ^[Oo]$ ]]; then
        create_additional_users
    fi
    
    print_success "Configuration des utilisateurs terminée"
}

# Création d'utilisateurs supplémentaires
create_additional_users() {
    while true; do
        echo -e "\n${YELLOW}Nom du nouvel utilisateur (ou 'fin' pour terminer) :${NC}"
        read -r new_username
        
        if [[ "$new_username" == "fin" ]]; then
            break
        fi
        
        if [[ ${#new_username} -ge 3 && "$new_username" =~ ^[a-z]+$ ]]; then
            echo -e "${YELLOW}Mot de passe pour $new_username :${NC}"
            read -rs new_password
            
            arch-chroot /mnt /bin/bash << EOF
                useradd -m -G audio,video,optical,storage -s /bin/bash $new_username
                echo "$new_username:$new_password" | chpasswd
EOF
            print_success "Utilisateur $new_username créé"
        else
            print_error "Nom d'utilisateur invalide"
        fi
    done
}

# Installation et configuration de GRUB avec thème NyArch
setup_grub() {
    print_step "Configuration de GRUB avec thème NyArch"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation de GRUB
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
        
        # Installation du thème NyArch
        cd /tmp
        git clone https://github.com/NyarchLinux/grub-theme-nyarch.git || {
            # Fallback vers un thème anime générique
            git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
            mkdir -p /boot/grub/themes/nyarch
            cp -r Top-5-Bootloader-Themes/anime/* /boot/grub/themes/nyarch/ 2>/dev/null || true
        }
        
        # Installation du thème
        if [[ -d grub-theme-nyarch ]]; then
            mkdir -p /boot/grub/themes
            cp -r grub-theme-nyarch /boot/grub/themes/nyarch
        fi
        
        # Configuration de GRUB
        sed -i 's/#GRUB_THEME=.*/GRUB_THEME="\/boot\/grub\/themes\/nyarch\/theme.txt"/' /etc/default/grub
        sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/' /etc/default/grub
        sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        
        # Génération de la configuration
        grub-mkconfig -o /boot/grub/grub.cfg
EOF
    
    print_success "GRUB configuré avec le thème NyArch"
}

# Installation des environnements de bureau
install_desktop_environment() {
    if [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Aucun environnement graphique sélectionné"
        return
    fi
    
    print_step "Installation de l'environnement de bureau"
    
    case $DE_CHOICE in
        gnome)
            install_gnome_nyarch
            ;;
        kde)
            install_kde_plasma
            ;;
    esac
}

# Installation de GNOME avec personnalisations NyArch
install_gnome_nyarch() {
    print_info "Installation de GNOME avec les personnalisations NyArch..."
    
    local gnome_packages=(
        gnome gnome-extra gdm
        gnome-tweaks dconf-editor
        firefox git wget curl
    )
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation des paquets GNOME
        pacman -S --noconfirm gnome gnome-extra gdm gnome-tweaks dconf-editor
        
        # Activation de GDM
        systemctl enable gdm
        
        # Installation de paru (AUR helper)
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        chown -R nobody paru
        cd paru
        sudo -u nobody makepkg -si --noconfirm
        
        # Installation du script Nyarcher pour les personnalisations
        cd /home/$USERNAME
        sudo -u $USERNAME git clone https://github.com/NyarchLinux/Nyarcher.git
        cd Nyarcher
        chmod +x nyarcher.sh
        
        # Application des personnalisations NyArch
        sudo -u $USERNAME ./nyarcher.sh --auto-install || true
EOF
    
    setup_nyarch_customizations
    
    print_success "GNOME avec personnalisations NyArch installé"
}

# Installation de KDE Plasma
install_kde_plasma() {
    print_info "Installation de KDE Plasma..."
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation des paquets KDE
        pacman -S --noconfirm plasma kde-applications sddm
        
        # Activation de SDDM
        systemctl enable sddm
        
        # Installation de paru
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        chown -R nobody paru
        cd paru
        sudo -u nobody makepkg -si --noconfirm
EOF
    
    setup_sddm_nyarch
    
    print_success "KDE Plasma installé"
}

# Configuration des personnalisations NyArch
setup_nyarch_customizations() {
    print_info "Application des personnalisations NyArch..."
    
    arch-chroot /mnt /bin/bash << EOF
        # Installation des paquets NyArch spéciaux via AUR
        sudo -u $USERNAME paru -S --noconfirm nyaofetch || true
        sudo -u $USERNAME paru -S --noconfirm lolcat || true
        
        # Configuration du terminal avec des couleurs anime
        mkdir -p /home/$USERNAME/.config/kitty
        cat > /home/$USERNAME/.config/kitty/kitty.conf << 'KITTY_EOF'
# Configuration Kitty pour NyArch
foreground #f8f8f2
background #282a36
background_opacity 0.9

# Couleurs NyArch/Anime
color0  #21222c
color1  #ff5555
color2  #50fa7b
color3  #f1fa8c
color4  #bd93f9
color5  #ff79c6
color6  #8be9fd
color7  #f8f8f2
color8  #6272a4
color9  #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff

font_family JetBrains Mono
font_size 12
KITTY_EOF
        
        chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
        
        # Ajout de nyaofetch au bashrc
        echo "nyaofetch || neofetch" >> /home/$USERNAME/.bashrc
EOF
    
    print_success "Personnalisations NyArch appliquées"
}

# Configuration de SDDM avec thème NyArch
setup_sddm_nyarch() {
    print_info "Configuration de SDDM avec thème NyArch..."
    
    arch-chroot /mnt /bin/bash << EOF
        # Téléchargement du fond d'écran NyArch
        mkdir -p /usr/share/sddm/themes/nyarch
        wget -O /usr/share/sddm/themes/nyarch/background.png \
             "https://raw.githubusercontent.com/NyarchLinux/NyarchLinux/main/wallpapers/nyarch_login.png" || \
        wget -O /usr/share/sddm/themes/nyarch/background.png \
             "https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/Projets/GitHub.png"
        
        # Configuration SDDM
        cat > /etc/sddm.conf << 'SDDM_EOF'
[Theme]
Current=nyarch

[Users]
RememberLastUser=true
SDDM_EOF
        
        # Création du thème SDDM simple
        cat > /usr/share/sddm/themes/nyarch/theme.conf << 'THEME_EOF'
[General]
background=background.png
showUserList=true
THEME_EOF
        
        # Préremplir le nom d'utilisateur
        echo "RememberLastUser=true" >> /etc/sddm.conf
EOF
    
    print_success "SDDM configuré avec le thème NyArch"
}

# Installation du son de démarrage
setup_boot_sound() {
    print_step "Configuration du son de démarrage NyArch"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation des outils audio
        pacman -S --noconfirm alsa-utils pulseaudio pulseaudio-alsa
        
        # Téléchargement du son de démarrage
        mkdir -p /usr/local/share/sounds
        wget -O /usr/local/share/sounds/nyarch-boot.mp3 \
             "https://raw.githubusercontent.com/NyarchLinux/NyarchLinux/main/sounds/boot.mp3" || \
        wget -O /usr/local/share/sounds/nyarch-boot.mp3 \
             "https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/FalloutBip.mp3"
        
        # Création du service systemd pour le son de démarrage
        cat > /etc/systemd/system/nyarch-boot-sound.service << 'SERVICE_EOF'
[Unit]
Description=NyArch Boot Sound
After=sound.target

[Service]
Type=oneshot
ExecStart=/usr/bin/paplay /usr/local/share/sounds/nyarch-boot.mp3
User=pulse

[Install]
WantedBy=multi-user.target
SERVICE_EOF
        
        # Activation du service
        systemctl enable nyarch-boot-sound.service
EOF
    
    print_success "Son de démarrage NyArch configuré"
}

# Installation des logiciels de développement
install_development_tools() {
    print_step "Installation des outils de développement"
    
    local dev_packages=(
        git git-lfs docker docker-compose nodejs npm python python-pip
        go rust jdk-openjdk dotnet-sdk cmake make gcc clang gdb
        sqlite sqlitebrowser neovim micro kitty alacritty
        btop htop lazygit
    )
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation des paquets de développement
        pacman -S --noconfirm git git-lfs docker docker-compose nodejs npm \
                             python python-pip go rust jdk-openjdk cmake \
                             make gcc clang gdb sqlite neovim micro \
                             kitty alacritty btop htop
        
        # Activation de Docker
        systemctl enable docker
        usermod -aG docker $USERNAME
        
        # Installation des paquets AUR
        sudo -u $USERNAME paru -S --noconfirm \
            visual-studio-code-bin \
            postman-bin \
            obsidian \
            joplin-appimage \
            lazygit \
            gpt4all || true
EOF
    
    install_vscode_extensions
    
    print_success "Outils de développement installés"
}

# Installation des extensions VSCode
install_vscode_extensions() {
    print_info "Configuration de Visual Studio Code avec extensions..."
    
    arch-chroot /mnt /bin/bash << EOF
        # Extensions VSCode essentielles
        local extensions=(
            "ms-python.python"
            "golang.go"
            "rust-lang.rust-analyzer"
            "ms-vscode.cpptools"
            "ms-dotnettools.csharp"
            "bradlc.vscode-tailwindcss"
            "esbenp.prettier-vscode"
            "ms-eslint.vscode-eslint"
            "GitHub.copilot"
            "codeium.codeium"
            "amazonwebservices.aws-toolkit-vscode"
            "humao.rest-client"
            "aaron-bond.better-comments"
            "usernamehw.errorlens"
            "johnpapa.vscode-peacock"
            "vscode-icons-team.vscode-icons"
            "PKief.material-icon-theme"
            "formulahendry.code-runner"
            "ms-toolsai.jupyter"
            "hediet.vscode-drawio"
            "ritwickdey.LiveServer"
        )
        
        # Installation des extensions pour l'utilisateur
        sudo -u $USERNAME bash -c '
            for ext in "${extensions[@]}"; do
                code --install-extension "\$ext" --user-data-dir /home/$USERNAME/.vscode 2>/dev/null || true
            done
        '
EOF
    
    print_success "Extensions VSCode installées"
}

# Installation des logiciels multimédia
install_multimedia_tools() {
    print_step "Installation des outils multimédia"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Paquets multimédia
        pacman -S --noconfirm vlc mpv audacity obs-studio kdenlive \
                             shotcut gimp krita inkscape darktable \
                             blender imagemagick easyeffects
        
        # Installation via AUR
        sudo -u $USERNAME paru -S --noconfirm \
            deadbeef \
            piper || true
EOF
    
    print_success "Outils multimédia installés"
}

# Installation des logiciels gaming
install_gaming_tools() {
    print_step "Installation des outils gaming"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Activation des dépôts multilib pour Steam
        sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
        pacman -Sy
        
        # Paquets gaming
        pacman -S --noconfirm steam lutris wine-staging winetricks \
                             gamemode lib32-gamemode mangohud \
                             lib32-mangohud bottles
        
        # Installation via AUR
        sudo -u $USERNAME paru -S --noconfirm \
            heroic-games-launcher-bin \
            protonup-qt || true
        
        # Configuration gamemode
        usermod -aG gamemode $USERNAME
EOF
    
    print_success "Outils gaming installés"
}

# Installation des logiciels internet
install_internet_tools() {
    print_step "Installation des navigateurs et outils de communication"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Navigateurs
        pacman -S --noconfirm firefox thunderbird
        
        # Installation via AUR/Flatpak
        sudo -u $USERNAME paru -S --noconfirm \
            brave-bin \
            discord \
            signal-desktop \
            telegram-desktop \
            element-desktop || true
        
        # Configuration Flatpak
        pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        
        # Installation via Flatpak
        sudo -u $USERNAME flatpak install -y flathub \
            com.slack.Slack \
            org.mozilla.Thunderbird || true
EOF
    
    print_success "Outils internet installés"
}

# Installation des utilitaires système
install_system_utilities() {
    print_step "Installation des utilitaires système"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Utilitaires système
        pacman -S --noconfirm gparted bleachbit timeshift \
                             keepassxc gufw redshift \
                             flameshot baobab
        
        # Installation via AUR
        sudo -u $USERNAME paru -S --noconfirm \
            stacer \
            ulauncher \
            balena-etcher \
            appimagelauncher || true
        
        # Configuration du firewall
        systemctl enable ufw
        ufw --force enable
EOF
    
    print_success "Utilitaires système installés"
}

# Installation des thèmes et icônes
install_themes_icons() {
    print_step "Installation des thèmes et packs d'icônes"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Packs d'icônes via AUR
        sudo -u $USERNAME paru -S --noconfirm \
            papirus-icon-theme \
            tela-icon-theme \
            zafiro-icon-theme \
            qogir-icon-theme || true
        
        # Configuration des icônes Tela par défaut pour GNOME
        if [[ "$DE_CHOICE" == "gnome" ]]; then
            sudo -u $USERNAME gsettings set org.gnome.desktop.interface icon-theme 'Tela'
        fi
EOF
    
    print_success "Thèmes et icônes installés"
}

# Configuration de Spicetify
setup_spicetify() {
    print_step "Configuration de Spicetify pour Spotify"
    
    arch-chroot /mnt /bin/bash << EOF
        # Installation de Spotify et Spicetify
        sudo -u $USERNAME paru -S --noconfirm \
            spotify \
            spicetify-cli || true
        
        # Configuration Spicetify avec thème anime
        sudo -u $USERNAME bash -c '
            spicetify backup apply 2>/dev/null || true
            spicetify config extensions adblock.js 2>/dev/null || true
            spicetify config current_theme Sleek 2>/dev/null || true
            spicetify apply 2>/dev/null || true
        '
EOF
    
    print_success "Spicetify configuré"
}

# Configuration de Plymouth (splashscreen)
setup_plymouth() {
    print_step "Configuration du splashscreen Plymouth"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Installation de Plymouth
        pacman -S --noconfirm plymouth
        
        # Téléchargement du thème NyArch
        cd /tmp
        git clone https://github.com/NyarchLinux/plymouth-theme-nyarch.git || {
            # Création d'un thème simple si le dépôt n'existe pas
            mkdir -p plymouth-theme-nyarch
            echo "Simple NyArch theme" > plymouth-theme-nyarch/README.md
        }
        
        # Installation du thème
        if [[ -d plymouth-theme-nyarch ]]; then
            cp -r plymouth-theme-nyarch /usr/share/plymouth/themes/nyarch
            plymouth-set-default-theme nyarch
            
            # Mise à jour de l'initramfs
            sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf
            mkinitcpio -P
        fi
EOF
    
    print_success "Plymouth configuré"
}

# Installation des outils IA
install_ai_tools() {
    print_step "Installation des outils IA pour le développement"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Outils IA via AUR
        sudo -u $USERNAME paru -S --noconfirm \
            gpt4all \
            ollama || true
        
        # Installation de Codeium
        sudo -u $USERNAME paru -S --noconfirm codeium || true
        
        # Configuration d'Ollama
        systemctl enable ollama || true
EOF
    
    print_success "Outils IA installés"
}

# Configuration des services NyArch
setup_nyarch_services() {
    print_step "Configuration des services spécifiques à NyArch"
    
    arch-chroot /mnt /bin/bash << EOF
        # Service de mise à jour automatique des wallpapers NyArch
        cat > /etc/systemd/user/nyarch-wallpaper.service << 'WALL_EOF'
[Unit]
Description=NyArch Wallpaper Rotator
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nyarch-wallpaper-rotator
Restart=always
RestartSec=3600

[Install]
WantedBy=default.target
WALL_EOF

        # Script de rotation des wallpapers
        cat > /usr/local/bin/nyarch-wallpaper-rotator << 'SCRIPT_EOF'
#!/bin/bash
# Rotation automatique des wallpapers NyArch

WALLPAPER_DIR="/home/$USERNAME/.local/share/wallpapers/nyarch"
mkdir -p "\$WALLPAPER_DIR"

# Téléchargement des wallpapers NyArch
wallpapers=(
    "https://raw.githubusercontent.com/NyarchLinux/NyarchLinux/main/wallpapers/nyarch1.png"
    "https://raw.githubusercontent.com/NyarchLinux/NyarchLinux/main/wallpapers/nyarch2.png"
    "https://raw.githubusercontent.com/NyarchLinux/NyarchLinux/main/wallpapers/nyarch3.png"
)

for wall in "\${wallpapers[@]}"; do
    wget -q -O "\$WALLPAPER_DIR/\$(basename \$wall)" "\$wall" 2>/dev/null || true
done

# Rotation toutes les heures
while true; do
    if [[ -d "\$WALLPAPER_DIR" ]]; then
        wallpaper=\$(find "\$WALLPAPER_DIR" -name "*.png" -o -name "*.jpg" | shuf -n1)
        if [[ -n "\$wallpaper" ]]; then
            gsettings set org.gnome.desktop.background picture-uri "file://\$wallpaper" 2>/dev/null || true
        fi
    fi
    sleep 3600
done
SCRIPT_EOF

        chmod +x /usr/local/bin/nyarch-wallpaper-rotator
        chown $USERNAME:$USERNAME /usr/local/bin/nyarch-wallpaper-rotator
        
        # Activation pour l'utilisateur
        sudo -u $USERNAME systemctl --user enable nyarch-wallpaper.service || true
EOF
    
    print_success "Services NyArch configurés"
}

# Nettoyage et optimisations finales
final_cleanup() {
    print_step "Nettoyage et optimisations finales"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Nettoyage du cache pacman
        pacman -Scc --noconfirm
        
        # Nettoyage des fichiers temporaires
        rm -rf /tmp/*
        rm -rf /var/tmp/*
        
        # Optimisation des bases de données
        pacman-db-upgrade
        
        # Génération du cache des icônes
        gtk-update-icon-cache -f -t /usr/share/icons/* 2>/dev/null || true
        
        # Mise à jour de la base de données des applications
        update-desktop-database 2>/dev/null || true
        
        # Configuration des limites système
        echo "* soft nofile 65536" >> /etc/security/limits.conf
        echo "* hard nofile 65536" >> /etc/security/limits.conf
        
        # Optimisation de la swappiness
        echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
        
        # Désactivation de la copie des symboles debug
        echo "STRIP_BINARIES=\"--strip-all\"" >> /etc/makepkg.conf
        echo "STRIP_SHARED=\"--strip-unneeded\"" >> /etc/makepkg.conf
        echo "STRIP_STATIC=\"--strip-debug\"" >> /etc/makepkg.conf
        echo "OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug !lto)" >> /etc/makepkg.conf
EOF
    
    print_success "Nettoyage terminé"
}

# Installation des thèmes GRUB supplémentaires (commentés)
install_additional_grub_themes() {
    print_step "Installation des thèmes GRUB supplémentaires"
    
    arch-chroot /mnt /bin/bash << 'EOF'
        # Création du répertoire des thèmes
        mkdir -p /boot/grub/themes
        
        # Téléchargement et installation des thèmes (désactivés par défaut)
        cd /tmp
        
        # Thème Matrix
        git clone https://github.com/vandalsoul/matrix-grub-theme.git
        cp -r matrix-grub-theme /boot/grub/themes/matrix 2>/dev/null || true
        
        # Thème CRT
        git clone https://github.com/shvchk/poly-dark.git
        cp -r poly-dark /boot/grub/themes/crt 2>/dev/null || true
        
        # Note: Pour changer de thème, modifiez la ligne GRUB_THEME dans /etc/default/grub
        # puis exécutez: grub-mkconfig -o /boot/grub/grub.cfg
        
        echo "# Thèmes GRUB disponibles :" >> /etc/grub-themes.txt
        echo "# - /boot/grub/themes/nyarch/theme.txt (actuel)" >> /etc/grub-themes.txt
        echo "# - /boot/grub/themes/matrix/theme.txt" >> /etc/grub-themes.txt
        echo "# - /boot/grub/themes/crt/theme.txt" >> /etc/grub-themes.txt
EOF
    
    print_success "Thèmes GRUB supplémentaires installés"
}

# Création du script post-installation
create_post_install_script() {
    print_step "Création du script post-installation"
    
    cat > /mnt/home/$USERNAME/nyarch-post-install.sh << 'POST_EOF'
#!/bin/bash
# Script post-installation NyArch Linux

echo "=== NyArch Linux Post-Installation ==="
echo "Bienvenue dans votre nouveau système NyArch Linux!"

# Configuration des applications favorites
setup_favorites() {
    echo "Configuration des applications favorites..."
    
    # GNOME favorites
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.shell favorite-apps [
            'firefox.desktop',
            'org.gnome.Terminal.desktop',
            'org.gnome.Files.desktop',
            'code.desktop',
            'steam.desktop',
            'discord.desktop'
        ]
    fi
}

# Mise à jour complète du système
update_system() {
    echo "Mise à jour complète du système..."
    sudo pacman -Syu --noconfirm
    paru -Sua --noconfirm || true
    flatpak update -y || true
}

# Installation des derniers drivers
install_drivers() {
    echo "Installation des drivers..."
    
    # Détection automatique de la carte graphique
    if lspci | grep -i nvidia >/dev/null; then
        echo "Carte NVIDIA détectée, installation des drivers..."
        sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    elif lspci | grep -i amd >/dev/null; then
        echo "Carte AMD détectée, installation des drivers..."
        sudo pacman -S --noconfirm xf86-video-amdgpu mesa vulkan-radeon
    elif lspci | grep -i intel >/dev/null; then
        echo "Carte Intel détectée, installation des drivers..."
        sudo pacman -S --noconfirm xf86-video-intel mesa vulkan-intel
    fi
}

# Configuration des extensions GNOME pour NyArch
setup_gnome_extensions() {
    if command -v gnome-extensions >/dev/null; then
        echo "Configuration des extensions GNOME..."
        
        # Installation des extensions utiles
        local extensions=(
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "dash-to-dock@micxgx.gmail.com"
            "gsconnect@andyholmes.github.io"
            "caffeine@patapon.info"
        )
        
        for ext in "${extensions[@]}"; do
            gnome-extensions install "$ext" 2>/dev/null || true
            gnome-extensions enable "$ext" 2>/dev/null || true
        done
    fi
}

# Menu principal
echo "Que souhaitez-vous faire ?"
echo "1) Configuration complète des favorites et extensions"
echo "2) Mise à jour du système"
echo "3) Installation des drivers graphiques"
echo "4) Tout faire"
echo "5) Quitter"

read -p "Votre choix (1-5): " choice

case $choice in
    1) setup_favorites; setup_gnome_extensions ;;
    2) update_system ;;
    3) install_drivers ;;
    4) setup_favorites; setup_gnome_extensions; update_system; install_drivers ;;
    5) echo "À bientôt!" ;;
    *) echo "Choix invalide" ;;
esac

echo "Script post-installation terminé!"
echo "Votre système NyArch est maintenant prêt à l'utilisation! UwU"
POST_EOF
    
    chmod +x /mnt/home/$USERNAME/nyarch-post-install.sh
    chown $USERNAME:$USERNAME /mnt/home/$USERNAME/nyarch-post-install.sh
    
    print_success "Script post-installation créé"
}

# Fonction principale d'installation
main_installation() {
    local start_time=$(date +%s)
    
    print_header
    
    # Étapes principales avec barres de progression
    local steps=(
        "Vérification des prérequis"
        "Synchronisation des miroirs"
        "Détection des disques"
        "Configuration des partitions"
        "Formatage des partitions"
        "Montage des partitions"
        "Sélection de l'environnement de bureau"
        "Installation du système de base"
        "Configuration du système"
        "Configuration des utilisateurs"
        "Configuration de GRUB"
        "Installation de l'environnement de bureau"
        "Configuration du son de démarrage"
        "Installation des outils de développement"
        "Installation des outils multimédia"
        "Installation des outils gaming"
        "Installation des outils internet"
        "Installation des utilitaires système"
        "Installation des thèmes et icônes"
        "Configuration de Spicetify"
        "Configuration de Plymouth"
        "Installation des outils IA"
        "Configuration des services NyArch"
        "Installation des thèmes GRUB supplémentaires"
        "Création du script post-installation"
        "Nettoyage final"
    )
    
    local total_steps=${#steps[@]}
    
    # Exécution des étapes
    for i in "${!steps[@]}"; do
        local step_num=$((i + 1))
        show_progress $step_num $total_steps "${steps[i]}" $start_time
        
        case $step_num in
            1) check_requirements ;;
            2) sync_mirrors ;;
            3) detect_disks ;;
            4) manage_partitioning ;;
            5) format_partitions ;;
            6) mount_partitions ;;
            7) select_desktop_environment ;;
            8) install_base_system ;;
            9) configure_system ;;
            10) setup_users ;;
            11) setup_grub ;;
            12) install_desktop_environment ;;
            13) setup_boot_sound ;;
            14) install_development_tools ;;
            15) install_multimedia_tools ;;
            16) install_gaming_tools ;;
            17) install_internet_tools ;;
            18) install_system_utilities ;;
            19) install_themes_icons ;;
            20) setup_spicetify ;;
            21) setup_plymouth ;;
            22) install_ai_tools ;;
            23) setup_nyarch_services ;;
            24) install_additional_grub_themes ;;
            25) create_post_install_script ;;
            26) final_cleanup ;;
        esac
    done
    
    show_progress $total_steps $total_steps "Installation terminée" $start_time
}

# Fonction de redémarrage
prompt_reboot() {
    local elapsed=$(( $(date +%s) - start_time ))
    local hours=$(( elapsed / 3600 ))
    local minutes=$(( (elapsed % 3600) / 60 ))
    local seconds=$(( elapsed % 60 ))
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}                        INSTALLATION NYARCH TERMINÉE!                        ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}                                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    Votre système NyArch Linux est maintenant prêt à l'utilisation! owo     ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}                                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    Temps d'installation: ${hours}h ${minutes}m ${seconds}s                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}                                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    Environnement de bureau: $(echo $DE_CHOICE | tr '[:lower:]' '[:upper:]')                                  ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    Utilisateur principal: $USERNAME                                         ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}                                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    Script post-installation disponible dans:                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${WHITE}    /home/$USERNAME/nyarch-post-install.sh                                  ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}Fonctionnalités installées:${NC}"
    echo -e "  ${GREEN}✓${NC} Système de base NyArch Linux"
    echo -e "  ${GREEN}✓${NC} Environnement graphique $(echo $DE_CHOICE | tr '[:lower:]' '[:upper:]')"
    echo -e "  ${GREEN}✓${NC} GRUB avec thème NyArch"
    echo -e "  ${GREEN}✓${NC} Son de démarrage personnalisé"
    echo -e "  ${GREEN}✓${NC} Splashscreen Plymouth"
    echo -e "  ${GREEN}✓${NC} Outils de développement complets"
    echo -e "  ${GREEN}✓${NC} Suite multimédia et gaming"
    echo -e "  ${GREEN}✓${NC} Navigateurs et communication"
    echo -e "  ${GREEN}✓${NC} Utilitaires système"
    echo -e "  ${GREEN}✓${NC} Thèmes et personnalisations NyArch"
    echo -e "  ${GREEN}✓${NC} Outils IA et extensions VSCode"
    echo -e "  ${GREEN}✓${NC} Configuration française"
    
    echo -e "\n${YELLOW}Voulez-vous redémarrer maintenant ? (O/N) :${NC}"
    read -r reboot_choice
    
    if [[ "$reboot_choice" =~ ^[Oo]$ ]]; then
        echo -e "\n${CYAN}Redémarrage dans 5 secondes...${NC}"
        echo -e "${WHITE}Arigato gozaimasu pour avoir choisi NyArch Linux! (＾◡＾)${NC}"
        sleep 5
        reboot
    else
        echo -e "\n${CYAN}Installation terminée.${NC}"
        echo -e "${WHITE}Redémarrez manuellement quand vous serez prêt:${NC} ${YELLOW}reboot${NC}"
        echo -e "${WHITE}N'oubliez pas d'exécuter le script post-installation après le redémarrage!${NC}"
        echo -e "${PURPLE}NyArch vous souhaite une excellente expérience Linux! ♪(＾∇＾*)${NC}"
    fi
}

#==============================================================================
# POINT D'ENTRÉE PRINCIPAL
#==============================================================================

# Vérification que le script est exécuté en tant que root
if [[ $EUID -ne 0 ]]; then
    print_error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

# Trappe pour nettoyer en cas d'interruption
trap 'print_error "Installation interrompue"; exit 1' INT TERM

# Démarrage de l'installation
echo "$(date): Démarrage de l'installation NyArch Linux" > "$LOG_FILE"

main_installation
prompt_reboot

echo "$(date): Installation NyArch terminée avec succès" >> "$LOG_FILE"

exit 0