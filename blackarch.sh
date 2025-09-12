#!/bin/bash

# Script d'installation automatisée BlackArch Linux pour l'ISO NetInstall 
# Version: 113.0, mise à jour le 26/08/2025 à 15:50 ATTENTION : Version non testée hotmis via shellcheck
# Auteur: PapaOursPolaire, script disponible via le repo GitHub Linux-Tools

set -e  # Arrêter le script en cas d'erreur
exec 2> >(tee -a "/tmp/blackarch_install.log" >&2)

# Variables globales
SCRIPT_DIR="/tmp/blackarch_install"
LOG_FILE="/tmp/blackarch_install.log"
HOSTNAME=""
USERNAME=""
USER_PASSWORD=""
SELECTED_DISK=""
DESKTOP_ENV=""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Fonctions utilitaires
print_banner() {
    clear
    echo -e "${RED}"
    echo "██████╗ ██╗      █████╗  ██████╗██╗  ██╗ █████╗ ██████╗  ██████╗██╗  ██╗"
    echo "██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║"
    echo "██████╔╝██║     ███████║██║     █████╔╝ ███████║██████╔╝██║     ███████║"
    echo "██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██╗██║     ██╔══██║"
    echo "██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╗██║  ██║"
    echo "╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"                                                                  
    echo -e "${NC}"
}

log_message() {
    local message="$1"
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[✗]${NC} $message" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[!]${NC} $message" | tee -a "$LOG_FILE"
}

show_progress() {
    local current=$1
    local total=$2
    local message="$3"
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}[%-50s] %d%% - %s${NC}" \
        "$(printf '#%.0s' $(seq 1 $filled))$(printf ' %.0s' $(seq 1 $empty))" \
        "$percentage" "$message"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

progress_with_timer() {
    local duration=$1
    local message="$2"
    local step=0
    local total_steps=$((duration / 2))
    
    while [ $step -le $total_steps ]; do
        show_progress $step $total_steps "$message"
        sleep 2
        step=$((step + 1))
    done
    echo ""
}

confirm_action() {
    local message="$1"
    local response
    while true; do
        echo -e "${YELLOW}$message (O/N): ${NC}"
        read -r response
        case $response in
            [Oo]|[Oo][Uu][Ii]) return 0 ;;
            [Nn]|[Nn][Oo][Nn]) return 1 ;;
            *) echo -e "${RED}Veuillez répondre par O (Oui) ou N (Non)${NC}" ;;
        esac
    done
}

check_internet() {
    log_message "Vérification de la connexion internet..."
    if ping -c 1 google.com &> /dev/null; then
        log_success "Connexion internet active"
        return 0
    else
        log_error "Pas de connexion internet. Vérifiez votre réseau."
        exit 1
    fi
}

# Détection et sélection du/des disque(s)
detect_disks() {
    print_banner
    log_message "Détection des disques disponibles..."
    
    echo -e "${CYAN}Disques détectés :${NC}"
    local disk_list=()
    local i=1
    
    while IFS= read -r line; do
        if [[ $line =~ ^[a-z]+[0-9]*[[:space:]]+[0-9]+.*disk$ ]]; then
            local disk_name=$(echo "$line" | awk '{print $1}')
            local disk_size=$(echo "$line" | awk '{print $4}')
            echo -e "${WHITE}$i)${NC} /dev/$disk_name ($disk_size)"
            disk_list+=("$disk_name")
            ((i++))
        fi
    done < <(lsblk -d -o NAME,SIZE,TYPE | grep -E "disk$")
    
    if [ ${#disk_list[@]} -eq 0 ]; then
        log_error "Aucun disque détecté"
        exit 1
    fi
    
    while true; do
        echo -e "${YELLOW}Choisissez le disque d'installation (1-${#disk_list[@]}): ${NC}"
        read -r disk_choice
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && 
            [ "$disk_choice" -ge 1 ] && 
            [ "$disk_choice" -le ${#disk_list[@]} ]; then
            SELECTED_DISK="/dev/${disk_list[$((disk_choice-1))]}"
            log_success "Disque sélectionné : $SELECTED_DISK"
            break
        else
            log_error "Choix invalide. Veuillez entrer un nombre entre 1 et ${#disk_list[@]}"
        fi
    done
}

# Partitionnement
partition_disk() {
    log_message "Configuration du partitionnement..."
    
    echo -e "${CYAN}Options de partitionnement :${NC}"
    echo "1) Conserver les partitions existantes"
    echo "2) Créer un nouveau partitionnement automatique"
    
    while true; do
        echo -e "${YELLOW}Choisissez une option (1-2) : ${NC}"
        read -r partition_choice
        
        case $partition_choice in
            1)
                log_message "Conservation des partitions existantes"
                detect_existing_partitions
                break
                ;;
            2)
                log_message "Création d'un nouveau partitionnement..."
                create_new_partitions
                break
                ;;
            *)
                log_error "Choix invalide"
                ;;
        esac
    done
}

detect_existing_partitions() {
    log_message "Détection des partitions existantes sur $SELECTED_DISK"
    
    echo -e "${CYAN}Partitions détectées :${NC}"
    lsblk "$SELECTED_DISK"
    
    # Variables pour stocker les partitions
    EFI_PARTITION=""
    ROOT_PARTITION=""
    HOME_PARTITION=""
    SWAP_PARTITION=""
    
    # Demander à l'utilisateur d'identifier chaque partition
    identify_partitions
}

identify_partitions() {
    local partitions=($(lsblk -ln -o NAME "$SELECTED_DISK" | grep -E "${SELECTED_DISK##*/}[0-9]+"))
    
    for part in "${partitions[@]}"; do
        part="/dev/$part"
        echo -e "${YELLOW}Quelle est la fonction de la partition $part ?${NC}"
        echo "1) EFI/Boot"
        echo "2) Root (/)"
        echo "3) Home (/home)"
        echo "4) Swap"
        echo "5) Ignorer"
        
        read -r function_choice
        case $function_choice in
            1) EFI_PARTITION="$part" ;;
            2) ROOT_PARTITION="$part" ;;
            3) HOME_PARTITION="$part" ;;
            4) SWAP_PARTITION="$part" ;;
            5) continue ;;
        esac
    done
    
    # Vérification des partitions essentielles
    if [ -z "$EFI_PARTITION" ] || [ -z "$ROOT_PARTITION" ]; then
        log_error "Les partitions EFI et Root sont obligatoires"
        exit 1
    fi
}

create_new_partitions() {
    if ! confirm_action "ATTENTION : Cela effacera toutes les données sur $SELECTED_DISK. Continuer ?"; then
        log_message "Opération annulée"
        exit 0
    fi
    
    log_message "Création des partitions sur $SELECTED_DISK..."
    
    # Nettoyage du disque
    wipefs -af "$SELECTED_DISK" 2>/dev/null || true
    
    # Création de la table de partition GPT
    parted -s "$SELECTED_DISK" mklabel gpt
    
    # Calcul des tailles
    local disk_size=$(lsblk -bno SIZE "$SELECTED_DISK" | head -n1)
    local efi_size="512MiB"
    local root_size="50GiB"
    local swap_size="4GiB"
    
    # Création des partitions
    parted -s "$SELECTED_DISK" mkpart primary fat32 1MiB "$efi_size"
    parted -s "$SELECTED_DISK" set 1 esp on
    parted -s "$SELECTED_DISK" mkpart primary ext4 "$efi_size" $((512*1024*1024 + 50*1024*1024*1024))
    parted -s "$SELECTED_DISK" mkpart primary linux-swap $((512*1024*1024 + 50*1024*1024*1024)) $((512*1024*1024 + 50*1024*1024*1024 + 4*1024*1024*1024))
    parted -s "$SELECTED_DISK" mkpart primary ext4 $((512*1024*1024 + 50*1024*1024*1024 + 4*1024*1024*1024)) 100%
    
    # Attendre que les partitions soient créées
    sleep 2
    partprobe "$SELECTED_DISK"
    sleep 2
    
    # Attribution des variables de partition
    if [[ $SELECTED_DISK =~ nvme ]]; then
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
    
    log_success "Partitions créées avec succès"
}

# Formatage & Montage
format_partitions() {
    log_message "Formatage des partitions..."
    
    # Formatage EFI
    log_message "Formatage de la partition EFI: $EFI_PARTITION"
    mkfs.fat -F32 "$EFI_PARTITION" > /dev/null 2>&1 &
    progress_with_timer 10 "Formatage EFI en cours..."
    
    # Formatage Root
    log_message "Formatage de la partition Root: $ROOT_PARTITION"
    mkfs.ext4 -F "$ROOT_PARTITION" > /dev/null 2>&1 &
    progress_with_timer 20 "Formatage Root en cours..."
    
    # Formatage Home (si existe)
    if [ -n "$HOME_PARTITION" ]; then
        log_message "Formatage de la partition Home: $HOME_PARTITION"
        mkfs.ext4 -F "$HOME_PARTITION" > /dev/null 2>&1 &
        progress_with_timer 15 "Formatage Home en cours..."
    fi
    
    # Configuration Swap (si existe)
    if [ -n "$SWAP_PARTITION" ]; then
        log_message "Configuration du Swap: $SWAP_PARTITION"
        mkswap "$SWAP_PARTITION"
        swapon "$SWAP_PARTITION"
    fi
    
    log_success "Formatage terminé"
}

mount_partitions() {
    log_message "Montage des partitions..."
    
    # Montage Root
    mount "$ROOT_PARTITION" /mnt
    
    # Création et montage EFI
    mkdir -p /mnt/boot/efi
    mount "$EFI_PARTITION" /mnt/boot/efi
    
    # Montage Home (si existe)
    if [ -n "$HOME_PARTITION" ]; then
        mkdir -p /mnt/home
        mount "$HOME_PARTITION" /mnt/home
    fi
    
    log_success "Partitions montées"
}

# Sélection de l'environnement de bureau
select_desktop_environment() {
    log_message "Sélection de l'environnement de bureau..."
    
    echo -e "${CYAN}Environnements disponibles :${NC}"
    echo "1) KDE Plasma (Recommandé pour BlackArch)"
    echo "2) GNOME"
    echo "3) Sans interface graphique (serveur)"
    
    while true; do
        echo -e "${YELLOW}Choisissez un environnement (1-3): ${NC}"
        read -r desktop_choice
        
        case $desktop_choice in
            1)
                DESKTOP_ENV="kde"
                log_success "KDE Plasma sélectionné"
                break
                ;;
            2)
                DESKTOP_ENV="gnome"
                log_success "GNOME sélectionné"
                break
                ;;
            3)
                DESKTOP_ENV="none"
                log_success "Mode serveur sélectionné"
                break
                ;;
            *)
                log_error "Choix invalide"
                ;;
        esac
    done
}

# Installation des bases du système
install_base_system() {
    log_message "Installation du système de base BlackArch..."
    
    # Mise à jour des miroirs
    log_message "Mise à jour des miroirs..."
    reflector --country France,Germany,Belgium --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    # Installation des paquets de base
    local base_packages=(
        "base"
        "base-devel"
        "linux"
        "linux-headers"
        "linux-firmware"
        "networkmanager"
        "sudo"
        "grub"
        "efibootmgr"
        "os-prober"
        "vim"
        "nano"
        "curl"
        "wget"
        "git"
        "unzip"
        "p7zip"
        "lsb-release"
        "reflector"
        "pacman-contrib"
        "bash-completion"
    )
    
    log_message "Installation des paquets de base (cela peut prendre du temps)..."
    pacstrap /mnt "${base_packages[@]}" 2>/dev/null &
    local pacstrap_pid=$!
    
    # Barre de progression pour pacstrap
    local count=0
    while kill -0 $pacstrap_pid 2>/dev/null; do
        show_progress $count 100 "Installation paquets de base..."
        sleep 5
        count=$((count + 2))
        if [ $count -gt 100 ]; then count=99; fi
    done
    show_progress 100 100 "Installation paquets de base terminée"
    
    wait $pacstrap_pid
    log_success "Système de base installé"
}

# COnfiguration du système
configure_system() {
    log_message "Configuration du système..."
    
    # Génération du fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    log_success "fstab généré"
    
    # Configuration dans chroot
    arch_chroot_configure
}

arch_chroot_configure() {
    log_message "Configuration dans l'environnement chroot..."
    
    # Création du script de configuration chroot
    cat << 'EOF' > /mnt/root/configure_system.sh
#!/bin/bash

# Configuration du fuseau horaire
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

# Configuration locale française
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf

# Configuration réseau
systemctl enable NetworkManager

EOF
    
    chmod +x /mnt/root/configure_system.sh
    arch-chroot /mnt /root/configure_system.sh
    rm /mnt/root/configure_system.sh
    
    log_success "Configuration système terminée"
}

# Confiugration des utilisateurs
configure_hostname() {
    while true; do
        echo -e "${YELLOW}Nom d'hôte pour ce système: ${NC}"
        read -r hostname_input
        
        if [[ "$hostname_input" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]?$ ]]; then
            HOSTNAME="$hostname_input"
            echo "$HOSTNAME" > /mnt/etc/hostname
            
            # Configuration du fichier hosts
            cat << EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
            log_success "Nom d'hôte configuré: $HOSTNAME"
            break
        else
            log_error "Nom d'hôte invalide. Utilisez uniquement lettres, chiffres et tirets."
        fi
    done
}

configure_users() {
    log_message "Configuration des utilisateurs..."
    
    # Configuration root password
    while true; do
        echo -e "${YELLOW}Mot de passe root: ${NC}"
        read -s root_password
        echo -e "\n${YELLOW}Confirmation: ${NC}"
        read -s root_password_confirm
        
        if [ "$root_password" = "$root_password_confirm" ] && [ ${#root_password} -ge 6 ]; then
            echo "$root_password" | arch-chroot /mnt passwd root
            log_success "Mot de passe root configuré"
            break
        else
            echo -e "\n${RED}Les mots de passe ne correspondent pas ou sont trop courts (min 6 caractères)${NC}"
        fi
    done
    
    # Configuration utilisateur principal
    configure_main_user
    
    # Utilisateurs supplémentaires
    if confirm_action "Créer des utilisateurs supplémentaires ?"; then
        create_additional_users
    fi
}

configure_main_user() {
    # Nom d'utilisateur
    while true; do
        echo -e "${YELLOW}Nom d'utilisateur principal (min 3 caractères, pas d'espaces): ${NC}"
        read -r username_input
        
        if [[ "$username_input" =~ ^[a-z][a-z0-9_]{2,31}$ ]]; then
            USERNAME="$username_input"
            break
        else
            log_error "Nom invalide. Minuscules, 3+ caractères, commence par une lettre."
        fi
    done
    
    # Mot de passe utilisateur
    while true; do
        echo -e "${YELLOW}Mot de passe pour $USERNAME: ${NC}"
        read -s user_password
        echo -e "\n${YELLOW}Confirmation: ${NC}"
        read -s user_password_confirm
        
        if [ "$user_password" = "$user_password_confirm" ] && [ ${#user_password} -ge 6 ]; then
            USER_PASSWORD="$user_password"
            break
        else
            echo -e "\n${RED}Les mots de passe ne correspondent pas ou sont trop courts${NC}"
        fi
    done
    
    # Création de l'utilisateur
    arch-chroot /mnt useradd -m -G wheel,audio,video,storage,optical,lp,scanner "$USERNAME"
    echo "$USER_PASSWORD" | arch-chroot /mnt passwd "$USERNAME"
    
    # Configuration sudo
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    
    log_success "Utilisateur $USERNAME créé et configuré"
}

create_additional_users() {
    while true; do
        echo -e "${YELLOW}Nom du nouvel utilisateur (ou 'fin' pour terminer): ${NC}"
        read -r new_username
        
        if [ "$new_username" = "fin" ]; then
            break
        fi
        
        if [[ "$new_username" =~ ^[a-z][a-z0-9_]{2,31}$ ]]; then
            echo -e "${YELLOW}Mot de passe pour $new_username: ${NC}"
            read -s new_password
            
            arch-chroot /mnt useradd -m -G audio,video,storage,optical,lp,scanner "$new_username"
            echo "$new_password" | arch-chroot /mnt passwd "$new_username"
            
            log_success "Utilisateur $new_username créé"
        else
            log_error "Nom d'utilisateur invalide"
        fi
    done
}

# Installation  & configuration de Blackarch
install_blackarch_repo() {
    log_message "Installation du dépôt BlackArch..."
    
    # Téléchargement et installation de la clé BlackArch
    arch-chroot /mnt bash -c "
        curl -O https://blackarch.org/strap.sh
        chmod +x strap.sh
        ./strap.sh
        rm strap.sh
    "
    
    # Mise à jour des paquets
    arch-chroot /mnt pacman -Sy
    
    log_success "Dépôt BlackArch installé"
}

install_blackarch_tools() {
    log_message "Installation des outils BlackArch essentiels..."
    
    # Outils de base BlackArch
    local blackarch_tools=(
        "blackarch-keyring"
        "blackarch-mirrorlist"
        "nmap"
        "wireshark-qt"
        "metasploit"
        "burpsuite"
        "sqlmap"
        "nikto"
        "gobuster"
        "hydra"
        "john"
        "hashcat"
        "aircrack-ng"
        "recon-ng"
        "maltego"
        "beef"
        "ettercap"
        "armitage"
        "zaproxy"
        "wpscan"
    )
    
    log_message "Installation des outils de sécurité (longue opération)..."
    for tool in "${blackarch_tools[@]}"; do
        arch-chroot /mnt pacman -S --noconfirm "$tool" 2>/dev/null || log_warning "Impossible d'installer $tool"
    done
    
    log_success "Outils BlackArch installés"
}

# Installation de l'environnement graphique
install_desktop_environment() {
    if [ "$DESKTOP_ENV" = "none" ]; then
        log_message "Mode serveur - pas d'environnement graphique"
        return
    fi
    
    log_message "Installation de l'environnement de bureau: $DESKTOP_ENV"
    
    case $DESKTOP_ENV in
        "kde")
            install_kde_plasma
            ;;
        "gnome")
            install_gnome
            ;;
    esac
}

install_kde_plasma() {
    log_message "Installation de KDE Plasma..."
    
    local kde_packages=(
        "plasma-desktop"
        "plasma-workspace"
        "plasma-nm"
        "plasma-pa"
        "kscreen"
        "sddm"
        "sddm-kcm"
        "konsole"
        "dolphin"
        "kate"
        "spectacle"
        "gwenview"
        "okular"
        "ark"
        "kwalletmanager"
        "plasma-systemmonitor"
        "filelight"
        "partitionmanager"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${kde_packages[@]}"
    arch-chroot /mnt systemctl enable sddm
    
    log_success "KDE Plasma installé"
}

install_gnome() {
    log_message "Installation de GNOME..."
    
    local gnome_packages=(
        "gnome-shell"
        "gnome-desktop"
        "gnome-session"
        "gnome-settings-daemon"
        "gnome-control-center"
        "gnome-terminal"
        "nautilus"
        "gedit"
        "gnome-screenshot"
        "eog"
        "file-roller"
        "gnome-system-monitor"
        "baobab"
        "gparted"
        "gdm"
        "gnome-tweaks"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${gnome_packages[@]}"
    arch-chroot /mnt systemctl enable gdm
    
    log_success "GNOME installé"
}

# Personnalisation
install_custom() {
    if [ "$DESKTOP_ENV" = "none" ]; then
        return
    fi
    
    log_message "Installation de la personnalisation Fallout..."
    
    install_fallout_grub_theme
    install_boot_sound
    install_plymouth_theme
    configure_sddm_theme
}

install_fallout_grub_theme() {
    log_message "Installation du thème GRUB Fallout..."
    
    # Téléchargement du thème
    arch-chroot /mnt bash -c "
        cd /tmp
        git clone https://github.com/shvchk/fallout-grub-theme.git
        mkdir -p /boot/grub/themes/fallout
        cp -r fallout-grub-theme/* /boot/grub/themes/fallout/
        rm -rf fallout-grub-theme
    "
    
    # Configuration GRUB
    arch-chroot /mnt bash -c "
        sed -i 's/#GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub\/themes\/fallout\/theme.txt\"/' /etc/default/grub
        sed -i 's/#GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080/' /etc/default/grub
        echo 'GRUB_THEME=\"/boot/grub/themes/fallout/theme.txt\"' >> /etc/default/grub
    "
    
    log_success "Thème GRUB Fallout installé"
}

install_boot_sound() {
    log_message "Installation du bip sonore de démarrage..."
    
    # Téléchargement du son
    arch-chroot /mnt bash -c "
        mkdir -p /usr/share/sounds/fallout
        curl -o /usr/share/sounds/fallout/boot.mp3 \
            'https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/FalloutBip.mp3' 2>/dev/null || true
    "
    
    # Création du service systemd
    cat << 'EOF' > /mnt/etc/systemd/system/boot-sound.service
[Unit]
Description=Play boot sound
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/paplay /usr/share/sounds/fallout/boot.mp3
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF
    
    arch-chroot /mnt systemctl enable boot-sound.service
    
    log_success "Bip sonore de démarrage configuré"
}

install_plymouth_theme() {
    log_message "Installation du thème Plymouth..."
    
    # Installation Plymouth
    arch-chroot /mnt pacman -S --noconfirm plymouth
    
    # Téléchargement du thème
    arch-chroot /mnt bash -c "
        mkdir -p /usr/share/plymouth/themes/fallout-pipboy
        curl -o /usr/share/plymouth/themes/fallout-pipboy/pipboyanim.gif \
            'https://raw.githubusercontent.com/LuMarans30/FalloutPipBoy-Plasma6-Splashscreen/main/FalloutPipBoy-Loading-Plasma6/contents/splash/images/pipboyanim.gif' 2>/dev/null || true
    "
    
    # Création du fichier de configuration Plymouth
    cat << 'EOF' > /mnt/usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.plymouth
[Plymouth Theme]
Name=Fallout PipBoy
Description=Fallout PipBoy animated theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/fallout-pipboy
ScriptFile=/usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.script
EOF
    
    # Script Plymouth
    cat << 'EOF' > /mnt/usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.script
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

logo.image = Image("pipboyanim.gif");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

progress = 0;

fun refresh_callback() {
    progress++;
}

Plymouth.SetRefreshFunction(refresh_callback);
EOF
    
    # Configuration Plymouth
    arch-chroot /mnt bash -c "
        plymouth-set-default-theme fallout-pipboy
        mkinitcpio -p linux
    "
    
    log_success "Thème Plymouth installé"
}

configure_sddm_theme() {
    if [ "$DESKTOP_ENV" != "kde" ]; then
        return
    fi
    
    log_message "Configuration du thème SDDM..."
    
    # Téléchargement de l'image de fond
    arch-chroot /mnt bash -c "
        mkdir -p /usr/share/sddm/themes/fallout
        curl -o /usr/share/sddm/themes/fallout/background.png \
            'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/Projets/GitHub.png' 2>/dev/null || true
    "
    
    # Création du thème SDDM personnalisé
    cat << 'EOF' > /mnt/usr/share/sddm/themes/fallout/theme.conf
[General]
background=background.png
type=image

[Input]
Font="Noto Sans"
FontSize=12
PreFilledUser=true

[Footer]
ShowLogo=false
Text="Powered by PapaOursPolaire — source available on GitHub"
TextColor=#ffffff
EOF
    
    # Configuration SDDM
    cat << EOF > /mnt/etc/sddm.conf
[Theme]
Current=fallout
CursorTheme=breeze_cursors
Font=Noto Sans,10,-1,0,50,0,0,0,0,0

[Users]
DefaultSession=plasma.desktop
RememberLastUser=true
RememberLastSession=true

[General]
Numlock=on
EOF
    
    log_success "Thème SDDM configuré"
}

# installation du menu grub
install_grub() {
    log_message "Installation et configuration de GRUB..."
    
    # Installation GRUB
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=BlackArch
    
    # Configuration GRUB pour os-prober
    arch-chroot /mnt bash -c "
        sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
    "
    
    # Génération de la configuration
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    log_success "GRUB installé et configuré"
}

# Installation des logiciels
install_essential_software() {
    log_message "Installation des logiciels essentiels..."
    
    install_development_tools
    install_multimedia_tools
    install_internet_tools
    install_security_tools
    install_system_tools
    install_gaming_tools
    install_paru_and_flatpak
}

install_development_tools() {
    log_message "Installation des outils de développement..."
    
    local dev_packages=(
        "git"
        "git-lfs" 
        "docker"
        "docker-compose"
        "neovim"
        "nodejs"
        "npm"
        "python"
        "python-pip"
        "go"
        "rust"
        "jdk-openjdk"
        "cmake"
        "make"
        "gcc"
        "gdb"
        "clang"
        "sqlite"
        "postgresql"
        "mariadb"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${dev_packages[@]}"
    
    # Activation des services
    arch-chroot /mnt systemctl enable docker
    
    log_success "Outils de développement installés"
}

install_multimedia_tools() {
    log_message "Installation des outils multimédia..."
    
    local media_packages=(
        "vlc"
        "mpv"
        "audacity"
        "obs-studio"
        "kdenlive"
        "gimp"
        "krita"
        "inkscape"
        "blender"
        "imagemagick"
        "ffmpeg"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${media_packages[@]}"
    
    log_success "Outils multimédia installés"
}

install_internet_tools() {
    log_message "Installation des outils internet..."
    
    local internet_packages=(
        "firefox"
        "thunderbird"
        "discord"
        "telegram-desktop"
        "qbittorrent"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${internet_packages[@]}"
    
    log_success "Outils internet installés"
}

install_security_tools() {
    log_message "Installation d'outils de sécurité supplémentaires..."
    
    local security_packages=(
        "keepassxc"
        "ufw"
        "fail2ban"
        "lynis"
        "chkrootkit"
        "rkhunter"
        "clamav"
        "tor"
        "proxychains-ng"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${security_packages[@]}"
    
    # Configuration UFW
    arch-chroot /mnt systemctl enable ufw
    arch-chroot /mnt ufw --force enable
    
    log_success "Outils de sécurité installés"
}

install_system_tools() {
    log_message "Installation des outils système..."
    
    local system_packages=(
        "htop"
        "btop"
        "neofetch"
        "tree"
        "rsync"
        "rclone"
        "timeshift"
        "gparted"
        "bleachbit"
        "stacer"
        "flameshot"
        "copyq"
        "redshift"
        "barrier"
        "synergy"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${system_packages[@]}"
    
    log_success "Outils système installés"
}

install_gaming_tools() {
    log_message "Installation des outils gaming..."
    
    local gaming_packages=(
        "steam"
        "lutris"
        "wine"
        "winetricks"
        "gamemode"
        "lib32-gamemode"
        "mangohud"
        "lib32-mangohud"
    )
    
    # Activation multilib pour Steam
    arch-chroot /mnt bash -c "
        sed -i '/^\[multilib\]/,/Include.*multilib/ s/^#//' /etc/pacman.conf
        pacman -Sy
    "
    
    arch-chroot /mnt pacman -S --noconfirm "${gaming_packages[@]}"
    
    log_success "Outils gaming installés"
}

install_paru_and_flatpak() {
    log_message "Installation de Paru (AUR helper) et Flatpak..."
    
    # Installation de Paru
    arch-chroot /mnt bash -c "
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        chown -R $USERNAME:$USERNAME paru
        cd paru
        sudo -u $USERNAME makepkg -si --noconfirm
        cd ..
        rm -rf paru
    "
    
    # Installation Flatpak
    arch-chroot /mnt pacman -S --noconfirm flatpak
    arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Installation AUR packages avec Paru
    install_aur_packages
    
    log_success "Paru et Flatpak installés"
}

install_aur_packages() {
    log_message "Installation des paquets AUR..."
    
    local aur_packages=(
        "visual-studio-code-bin"
        "brave-bin"
        "discord"
        "spotify"
        "slack-desktop"
        "zoom"
        "postman-bin"
        "obsidian"
        "heroic-games-launcher-bin"
        "protonup-qt"
    )
    
    for package in "${aur_packages[@]}"; do
        arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm "$package" 2>/dev/null || log_warning "Impossible d'installer $package"
    done
    
    log_success "Paquets AUR installés"
}

# Personnalisation de l'interface
install_themes_and_icons() {
    if [ "$DESKTOP_ENV" = "none" ]; then
        return
    fi
    
    log_message "Installation des thèmes et icônes..."
    
    local theme_packages=(
        "papirus-icon-theme"
        "arc-gtk-theme"
        "materia-gtk-theme"
        "adapta-gtk-theme"
        "numix-gtk-theme"
        "breeze-gtk"
        "breeze-icons"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${theme_packages[@]}"
    
    # Installation thèmes AUR
    local aur_themes=(
        "tela-icon-theme"
        "zafiro-icon-theme"
        "qogir-icon-theme"
        "vimix-icon-theme"
    )
    
    for theme in "${aur_themes[@]}"; do
        arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm "$theme" 2>/dev/null || log_warning "Impossible d'installer $theme"
    done
    
    log_success "Thèmes et icônes installés"
}

post_install_configuration() {
    log_message "Configuration post-installation..."
    
    configure_firewall
    configure_automatic_updates
    configure_zsh_shell
    configure_fonts
    configure_java
    clean_system
}

configure_firewall() {
    log_message "Configuration du pare-feu..."
    
    arch-chroot /mnt bash -c "
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw --force enable
    "
    
    log_success "Pare-feu configuré"
}

configure_automatic_updates() {
    log_message "Configuration des mises à jour automatiques..."
    
    # Installation et configuration de systemd timer pour les mises à jour
    cat << 'EOF' > /mnt/etc/systemd/system/system-update.service
[Unit]
Description=System Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/pacman -Syu --noconfirm
StandardOutput=journal
EOF

    cat << 'EOF' > /mnt/etc/systemd/system/system-update.timer
[Unit]
Description=System Update Timer
Requires=system-update.service

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    arch-chroot /mnt systemctl enable system-update.timer
    
    log_success "Mises à jour automatiques configurées"
}

configure_zsh_shell() {
    log_message "Configuration de Zsh avec Oh-My-Zsh..."
    
    # Installation Zsh
    arch-chroot /mnt pacman -S --noconfirm zsh zsh-completions
    
    # Installation Oh-My-Zsh pour l'utilisateur
    arch-chroot /mnt sudo -u "$USERNAME" bash -c "
        sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended
        chsh -s /usr/bin/zsh
    "
    
    log_success "Zsh configuré"
}

configure_fonts() {
    log_message "Installation des polices..."
    
    local font_packages=(
        "ttf-dejavu"
        "ttf-liberation"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-roboto"
        "ttf-opensans"
        "ttf-hack"
        "ttf-fira-code"
    )
    
    arch-chroot /mnt pacman -S --noconfirm "${font_packages[@]}"
    
    log_success "Polices installées"
}

configure_java() {
    log_message "Configuration de Java..."
    
    arch-chroot /mnt archlinux-java set java-17-openjdk # Je ne pense pas que c'est la plus récente
    
    log_success "Java configuré"
}

clean_system() {
    log_message "Nettoyage du système..."
    
    arch-chroot /mnt bash -c "
        pacman -Rns \$(pacman -Qtdq) 2>/dev/null || true
        pacman -Scc --noconfirm
        journalctl --vacuum-time=7d
    "
    
    log_success "Système nettoyé"
}

# Grub +
install_additional_grub_themes() {
    log_message "Installation des thèmes GRUB supplémentaires..."
    
    # Création du répertoire pour les thèmes
    arch-chroot /mnt mkdir -p /boot/grub/themes
    
    # BSOL Theme
    install_grub_theme_bsol() {
        arch-chroot /mnt bash -c "
            cd /tmp
            git clone https://github.com/Lxtharia/grub-bsol-theme.git bsol-theme 2>/dev/null || true
            if [ -d bsol-theme ]; then
                mkdir -p /boot/grub/themes/bsol
                cp -r bsol-theme/* /boot/grub/themes/bsol/ 2>/dev/null || true
                rm -rf bsol-theme
            fi
        "
    }
    
    # Minegrub Theme
    install_grub_theme_minegrub() {
        arch-chroot /mnt bash -c "
            cd /tmp
            git clone https://github.com/Lxtharia/minegrub-theme.git minegrub-theme 2>/dev/null || true
            if [ -d minegrub-theme ]; then
                mkdir -p /boot/grub/themes/minegrub
                cp -r minegrub-theme/* /boot/grub/themes/minegrub/ 2>/dev/null || true
                rm -rf minegrub-theme
            fi
        "
    }
    
    # CRT-Amber Theme
    install_grub_theme_crt() {
        arch-chroot /mnt bash -c "
            cd /tmp
            git clone https://github.com/derek-fong/grub-theme-crt-amber.git crt-theme 2>/dev/null || true
            if [ -d crt-theme ]; then
                mkdir -p /boot/grub/themes/crt-amber
                cp -r crt-theme/* /boot/grub/themes/crt-amber/ 2>/dev/null || true
                rm -rf crt-theme
            fi
        "
    }
    
    # Arcade Theme
    install_grub_theme_arcade() {
        arch-chroot /mnt bash -c "
            cd /tmp
            git clone https://github.com/mahmoudfathy557/Arcade-GRUB-theme.git arcade-theme 2>/dev/null || true
            if [ -d arcade-theme ]; then
                mkdir -p /boot/grub/themes/arcade
                cp -r arcade-theme/* /boot/grub/themes/arcade/ 2>/dev/null || true
                rm -rf arcade-theme
            fi
        "
    }
    
    # Dark Matter Theme
    install_grub_theme_darkmatter() {
        arch-chroot /mnt bash -c "
            cd /tmp
            git clone https://github.com/VandalByte/darkmatter-grub2-theme.git darkmatter-theme 2>/dev/null || true
            if [ -d darkmatter-theme ]; then
                mkdir -p /boot/grub/themes/darkmatter
                cp -r darkmatter-theme/* /boot/grub/themes/darkmatter/ 2>/dev/null || true
                rm -rf darkmatter-theme
            fi
        "
    }
    
    # Installation des thèmes
    install_grub_theme_bsol
    install_grub_theme_minegrub
    install_grub_theme_crt
    install_grub_theme_arcade
    install_grub_theme_darkmatter
    
    # Création d'un script pour changer de thème facilement
    cat << 'EOF' > /mnt/usr/local/bin/change-grub-theme
#!/bin/bash
# Script pour changer le thème GRUB

THEMES_DIR="/boot/grub/themes"
GRUB_CONFIG="/etc/default/grub"

echo "Thèmes disponibles:"
echo "1) Fallout (actuel)"
echo "2) BSOL"
echo "3) Minegrub"
echo "4) CRT-Amber"
echo "5) Arcade"
echo "6) Dark Matter"
echo "7) Défaut (pas de thème)"

read -p "Choisir un thème (1-7): " choice

case $choice in
    1) THEME_PATH="/boot/grub/themes/fallout/theme.txt" ;;
    2) THEME_PATH="/boot/grub/themes/bsol/theme.txt" ;;
    3) THEME_PATH="/boot/grub/themes/minegrub/theme.txt" ;;
    4) THEME_PATH="/boot/grub/themes/crt-amber/theme.txt" ;;
    5) THEME_PATH="/boot/grub/themes/arcade/theme.txt" ;;
    6) THEME_PATH="/boot/grub/themes/darkmatter/theme.txt" ;;
    7) THEME_PATH="" ;;
    *) echo "Choix invalide"; exit 1 ;;
esac

if [ -n "$THEME_PATH" ]; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" $GRUB_CONFIG
    if ! grep -q "^GRUB_THEME=" $GRUB_CONFIG; then
        echo "GRUB_THEME=\"$THEME_PATH\"" >> $GRUB_CONFIG
    fi
else
    sed -i '/^GRUB_THEME=/d' $GRUB_CONFIG
fi

grub-mkconfig -o /boot/grub/grub.cfg
echo "Thème GRUB mis à jour. Redémarrez pour voir les changements."
EOF
    
    chmod +x /mnt/usr/local/bin/change-grub-theme
    
    log_success "Thèmes GRUB supplémentaires installés"
}

# Finalisation
finalize_installation() {
    log_message "Finalisation de l'installation..."
    
    # Génération des clés SSH pour l'utilisateur
    arch-chroot /mnt sudo -u "$USERNAME" ssh-keygen -t ed25519 -f /home/"$USERNAME"/.ssh/id_ed25519 -N "" 2>/dev/null || true
    
    # Configuration des permissions
    arch-chroot /mnt bash -c "
        chown -R $USERNAME:$USERNAME /home/$USERNAME
        chmod 700 /home/$USERNAME/.ssh
        chmod 600 /home/$USERNAME/.ssh/* 2>/dev/null || true
    "
    
    # Création d'un script de première connexion
    cat << 'EOF' > /mnt/home/"$USERNAME"/premier-demarrage.sh
#!/bin/bash
echo "BlackArch Linux - Premier démarrage"
echo "Bienvenue dans votre installation BlackArch personnalisée !"
echo ""
echo "Outils installés :"
echo "- Tous les outils BlackArch essentiels"
echo "- Environnement de développement complet"
echo "- Outils multimédia et gaming"
echo "- Sécurité renforcée"
echo ""
echo "Commandes utiles :"
echo "- change-grub-theme : Changer le thème de GRUB"
echo "- blackarch-config-cursor : Configurer les outils BlackArch"
echo "- systemctl --user enable boot-sound : Activer le son de démarrage"
echo ""
echo "Documentation : https://blackarch.org/guide.html"
echo ""
echo "Installation créée par PapaOursPolaire - GitHub disponible"
EOF
    
    chmod +x /mnt/home/"$USERNAME"/premier-demarrage.sh
    chown "$USERNAME":"$USERNAME" /mnt/home/"$USERNAME"/premier-demarrage.sh
    
    # Ajout du script au .bashrc
    echo 'if [ -f ~/premier-demarrage.sh ]; then ~/premier-demarrage.sh && rm ~/premier-demarrage.sh; fi' >> /mnt/home/"$USERNAME"/.bashrc
    
    log_success "Installation finalisée"
}

main() {
    print_banner
    
    # Vérifications préalables
    check_internet
    
    log_message "Début de l'installation BlackArch Linux automatisée"
    
    # Étapes d'installation
    detect_disks
    partition_disk
    format_partitions
    mount_partitions
    select_desktop_environment
    install_base_system
    configure_system
    configure_hostname
    configure_users
    install_blackarch_repo
    install_blackarch_tools
    install_desktop_environment
    install_custom
    install_grub
    install_essential_software
    install_themes_and_icons
    install_additional_grub_themes
    post_install_configuration
    finalize_installation
    
    log_success "Installation BlackArch Linux terminée avec succès !"
    
    # Proposition de redémarrage
    echo ""
    echo -e "${GREEN}                 INSTALLATION TERMINÉE !                   ${NC}"
    echo -e "${GREEN}                                                           ${NC}"
    echo -e "${GREEN}  BlackArch Linux avec personnalisation Fallout installé   ${NC}"
    echo -e "${GREEN}  Thème GRUB, Plymouth, sons et outils de sécurité prêts   ${NC}"
    echo -e "${GREEN}                                                           ${NC}"
    echo -e "${GREEN}       Powered by PapaOursPolaire - Source sur GitHub      ${NC}"
    echo ""
    
    if confirm_action "Voulez-vous redémarrer maintenant ?"; then
        log_message "Redémarrage dans 5 secondes..."
        echo -e "${YELLOW}Redémarrage en cours...${NC}"
        sleep 5
        reboot
    else
        log_message "Installation terminée. Redémarrez manuellement quand vous le souhaitez."
        echo -e "${CYAN}Tapez 'reboot' pour redémarrer${NC}"
    fi
}

# Vérification que le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root${NC}"
    echo "Utilisez : sudo $0"
    exit 1
fi

# Vérification de l'environnement live
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Ce script doit être exécuté depuis l'ISO live d'Arch Linux${NC}"
    exit 1
fi

# Création du répertoire de travail
mkdir -p "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

# Désactivation des symboles de debug pour accélérer l'installation
export BUILDTOOL_OPTIONS="strip,docs,!debug"

# Lancement de l'installation
main "$@"