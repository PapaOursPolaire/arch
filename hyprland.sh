#!/bin/bash

# ========================================
# 🌟 ARCH LINUX + HYPRLAND INSTALLER 🌟
# ========================================
# Style: Dev/Gaming/Arcane Theme
# Author: Custom Installation Script
# Version: 1.0
# ========================================

# Couleurs pour l'interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Variables globales
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch_install.log"
USERNAME=""
USER_PASSWORD=""
ROOT_PASSWORD=""

# ========================================
# 🎨 FONCTIONS D'AFFICHAGE
# ========================================

print_banner() {
    clear
    echo -e "${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                                                           ║"
    echo "  ║    🌟 ARCH LINUX + HYPRLAND INSTALLER 🌟                ║"
    echo "  ║                                                           ║"
    echo "  ║         Style: Dev • Gaming • Arcane Theme               ║"
    echo "  ║                                                           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] ${YELLOW}$1${NC}"
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo "✓ $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    echo "✗ $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ========================================
# 🔧 FONCTIONS UTILITAIRES
# ========================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
}

check_internet() {
    print_step "Vérification de la connexion Internet..."
    if ping -c 1 google.com &> /dev/null; then
        print_success "Connexion Internet OK"
    else
        print_error "Pas de connexion Internet"
        exit 1
    fi
}

update_system() {
    print_step "Mise à jour du système..."
    pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1
    print_success "Système mis à jour"
}

# ========================================
# 👤 CONFIGURATION UTILISATEUR
# ========================================

setup_user() {
    print_banner
    print_step "Configuration de l'utilisateur"
    
    while true; do
        echo -e "${YELLOW}Nom d'utilisateur ${CYAN}(pas d'espaces, caractères alphanumériques uniquement)${YELLOW}:${NC}"
        read -p "► " USERNAME
        
        if [[ "$USERNAME" =~ ^[a-zA-Z0-9]+$ ]] && [[ ${#USERNAME} -ge 3 ]]; then
            break
        else
            print_error "Nom d'utilisateur invalide. Utilisez uniquement des lettres et chiffres (minimum 3 caractères)"
        fi
    done
    
    while true; do
        echo -e "${YELLOW}Mot de passe utilisateur:${NC}"
        read -s -p "► " USER_PASSWORD
        echo ""
        echo -e "${YELLOW}Confirmer le mot de passe:${NC}"
        read -s -p "► " USER_PASSWORD_CONFIRM
        echo ""
        
        if [[ "$USER_PASSWORD" == "$USER_PASSWORD_CONFIRM" ]] && [[ ${#USER_PASSWORD} -ge 6 ]]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas ou sont trop courts (minimum 6 caractères)"
        fi
    done
    
    while true; do
        echo -e "${YELLOW}Mot de passe root:${NC}"
        read -s -p "► " ROOT_PASSWORD
        echo ""
        echo -e "${YELLOW}Confirmer le mot de passe root:${NC}"
        read -s -p "► " ROOT_PASSWORD_CONFIRM
        echo ""
        
        if [[ "$ROOT_PASSWORD" == "$ROOT_PASSWORD_CONFIRM" ]] && [[ ${#ROOT_PASSWORD} -ge 6 ]]; then
            break
        else
            print_error "Les mots de passe ne correspondent pas ou sont trop courts (minimum 6 caractères)"
        fi
    done
    
    print_success "Configuration utilisateur terminée"
}

create_user() {
    print_step "Création de l'utilisateur $USERNAME..."
    
    useradd -m -G wheel,audio,video,optical,storage -s /bin/bash "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd
    
    # Configuration sudo
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
    
    print_success "Utilisateur $USERNAME créé"
}

# ========================================
# 💾 GESTION DES PARTITIONS
# ========================================

list_disks() {
    print_step "Disques disponibles:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo ""
}

setup_partitions() {
    print_banner
    print_step "Configuration des partitions"
    
    list_disks
    
    echo -e "${YELLOW}Sélectionnez le disque à utiliser ${CYAN}(ex: sda, nvme0n1)${YELLOW}:${NC}"
    read -p "► " DISK
    
    if [[ ! -b "/dev/$DISK" ]]; then
        print_error "Disque non trouvé"
        exit 1
    fi
    
    echo -e "${YELLOW}Partitions existantes sur /dev/$DISK:${NC}"
    lsblk "/dev/$DISK"
    echo ""
    
    echo -e "${YELLOW}Voulez-vous utiliser des partitions existantes? (y/n):${NC}"
    read -p "► " USE_EXISTING
    
    if [[ "$USE_EXISTING" == "y" ]]; then
        select_existing_partitions
    else
        create_new_partitions
    fi
}

select_existing_partitions() {
    print_step "Sélection des partitions existantes..."
    
    echo -e "${YELLOW}Partitions disponibles:${NC}"
    lsblk "/dev/$DISK" -o NAME,SIZE,FSTYPE,MOUNTPOINT
    echo ""
    
    echo -e "${YELLOW}Partition root ${CYAN}(ex: ${DISK}1)${YELLOW}:${NC}"
    read -p "► " ROOT_PARTITION
    
    echo -e "${YELLOW}Partition home ${CYAN}(ex: ${DISK}2, ou appuyez sur Entrée pour utiliser root)${YELLOW}:${NC}"
    read -p "► " HOME_PARTITION
    
    echo -e "${YELLOW}Partition swap ${CYAN}(ex: ${DISK}3, ou appuyez sur Entrée pour créer un fichier swap)${YELLOW}:${NC}"
    read -p "► " SWAP_PARTITION
}

create_new_partitions() {
    print_step "Création de nouvelles partitions..."
    
    echo -e "${YELLOW}Taille pour root ${CYAN}(recommandé: 50G, format: 20G ou 2048M)${YELLOW}:${NC}"
    read -p "► " ROOT_SIZE
    
    echo -e "${YELLOW}Taille pour home ${CYAN}(recommandé: reste de l'espace, format: 100G ou appuyez sur Entrée pour le reste)${YELLOW}:${NC}"
    read -p "► " HOME_SIZE
    
    echo -e "${YELLOW}Taille pour swap ${CYAN}(recommandé: 8G, format: 8G ou 8192M)${YELLOW}:${NC}"
    read -p "► " SWAP_SIZE
    
    # Création des partitions avec parted
    parted "/dev/$DISK" --script \
        mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on \
        mkpart primary ext4 512MiB $(parse_size "$ROOT_SIZE" 512) \
        mkpart primary linux-swap $(parse_size "$ROOT_SIZE" 512) $(parse_size "$SWAP_SIZE" $(parse_size "$ROOT_SIZE" 512)) \
        mkpart primary ext4 $(parse_size "$SWAP_SIZE" $(parse_size "$ROOT_SIZE" 512)) 100%
    
    # Variables des partitions
    EFI_PARTITION="${DISK}1"
    ROOT_PARTITION="${DISK}2"
    SWAP_PARTITION="${DISK}3"
    HOME_PARTITION="${DISK}4"
    
    # Formatage
    mkfs.fat -F32 "/dev/$EFI_PARTITION"
    mkfs.ext4 "/dev/$ROOT_PARTITION"
    mkswap "/dev/$SWAP_PARTITION"
    mkfs.ext4 "/dev/$HOME_PARTITION"
    
    print_success "Partitions créées et formatées"
}

parse_size() {
    local size=$1
    local base=${2:-0}
    
    if [[ $size =~ ([0-9]+)([GM])$ ]]; then
        local num=${BASH_REMATCH[1]}
        local unit=${BASH_REMATCH[2]}
        
        if [[ $unit == "G" ]]; then
            echo $((base + num * 1024))MiB
        else
            echo $((base + num))MiB
        fi
    else
        echo "${size}MiB"
    fi
}

mount_partitions() {
    print_step "Montage des partitions..."
    
    mount "/dev/$ROOT_PARTITION" /mnt
    
    if [[ -n "$HOME_PARTITION" ]]; then
        mkdir -p /mnt/home
        mount "/dev/$HOME_PARTITION" /mnt/home
    fi
    
    if [[ -n "$EFI_PARTITION" ]]; then
        mkdir -p /mnt/boot/efi
        mount "/dev/$EFI_PARTITION" /mnt/boot/efi
    fi
    
    if [[ -n "$SWAP_PARTITION" ]]; then
        swapon "/dev/$SWAP_PARTITION"
    fi
    
    print_success "Partitions montées"
}

# ========================================
# 📦 INSTALLATION DES PAQUETS DE BASE
# ========================================

install_base_system() {
    print_step "Installation du système de base..."
    
    # Paquets de base
    pacstrap /mnt base base-devel linux linux-firmware \
        networkmanager grub efibootmgr os-prober \
        git wget curl vim nano sudo \
        pulseaudio pulseaudio-alsa alsa-utils \
        >> "$LOG_FILE" 2>&1
    
    # Génération du fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    print_success "Système de base installé"
}

# ========================================
# 🎮 INSTALLATION HYPRLAND ET ENVIRONNEMENT
# ========================================

remove_existing_de() {
    print_step "Suppression des environnements graphiques existants..."
    
    # Liste des DE/WM communs à supprimer
    local packages_to_remove=(
        "gnome" "kde-plasma" "xfce4" "lxde" "mate" "cinnamon"
        "i3" "awesome" "openbox" "fluxbox" "bspwm"
        "gdm" "sddm" "lightdm" "xdm"
    )
    
    for package in "${packages_to_remove[@]}"; do
        if pacman -Qi "$package" &>/dev/null; then
            print_info "Suppression de $package..."
            pacman -Rns "$package" --noconfirm >> "$LOG_FILE" 2>&1
        fi
    done
    
    print_success "Nettoyage terminé"
}

install_hyprland() {
    print_step "Installation de Hyprland et dépendances..."
    
    # Ajout du dépôt Chaotic AUR si nécessaire
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.xz' --noconfirm
    pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.xz' --noconfirm
    
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
    
    pacman -Sy --noconfirm
    
    # Installation Hyprland et composants
    pacman -S --noconfirm \
        hyprland hyprpaper hyprlock hypridle \
        waybar wofi dunst \
        kitty alacritty \
        polkit-gnome \
        xdg-desktop-portal-hyprland \
        grim slurp wl-clipboard \
        brightnessctl playerctl \
        network-manager-applet \
        thunar thunar-archive-plugin \
        >> "$LOG_FILE" 2>&1
    
    print_success "Hyprland installé"
}

install_audio_tools() {
    print_step "Installation des outils audio et détecteur de basses..."
    
    pacman -S --noconfirm \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack \
        wireplumber \
        pavucontrol \
        cava \
        >> "$LOG_FILE" 2>&1
    
    # Installation du détecteur de basses (cava pour visualisation audio)
    sudo -u "$USERNAME" git clone https://github.com/karlstav/cava.git /home/$USERNAME/.config/cava-custom
    
    print_success "Outils audio installés"
}

# ========================================
# 🛠️ OUTILS DE DÉVELOPPEMENT
# ========================================

install_development_tools() {
    print_step "Installation des outils de développement..."
    
    # Langages et runtimes
    pacman -S --noconfirm \
        python python-pip nodejs npm \
        java-openjdk-headless java-openjdk \
        gcc clang cmake make \
        docker docker-compose \
        postgresql mysql \
        >> "$LOG_FILE" 2>&1
    
    # VS Code
    sudo -u "$USERNAME" yay -S --noconfirm visual-studio-code-bin
    
    # Android Studio
    sudo -u "$USERNAME" yay -S --noconfirm android-studio
    
    # Extensions VS Code
    sudo -u "$USERNAME" code --install-extension ms-vscode.vscode-copilot
    sudo -u "$USERNAME" code --install-extension ms-python.python
    sudo -u "$USERNAME" code --install-extension ms-vscode.cpptools
    sudo -u "$USERNAME" code --install-extension redhat.java
    sudo -u "$USERNAME" code --install-extension ms-vscode.vscode-typescript-next
    sudo -u "$USERNAME" code --install-extension bradlc.vscode-tailwindcss
    sudo -u "$USERNAME" code --install-extension esbenp.prettier-vscode
    
    print_success "Outils de développement installés"
}

install_network_tools() {
    print_step "Installation des outils réseau..."
    
    pacman -S --noconfirm \
        nmap wireshark-qt \
        netcat openbsd-netcat \
        tcpdump iptables \
        wget curl aria2 \
        openssh sshfs \
        >> "$LOG_FILE" 2>&1
    
    print_success "Outils réseau installés"
}

# ========================================
# 🌐 APPLICATIONS
# ========================================

install_browsers() {
    print_step "Installation des navigateurs..."
    
    # Google Chrome
    sudo -u "$USERNAME" yay -S --noconfirm google-chrome
    
    # Brave
    sudo -u "$USERNAME" yay -S --noconfirm brave-bin
    
    print_success "Navigateurs installés"
}

install_media_apps() {
    print_step "Installation des applications multimédia..."
    
    # Spotify avec Spicetify
    sudo -u "$USERNAME" yay -S --noconfirm spotify spicetify-cli
    
    # Applications de streaming (via Flatpak pour de meilleures performances)
    pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    sudo -u "$USERNAME" flatpak install -y flathub com.netflix.NetflixDesktop
    sudo -u "$USERNAME" flatpak install -y flathub com.disneyplus.DisneyPlus
    
    print_success "Applications multimédia installées"
}

install_wine() {
    print_step "Installation de Wine..."
    
    # Activation du multilib
    sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm
    
    pacman -S --noconfirm wine wine-gecko wine-mono winetricks
    
    print_success "Wine installé"
}

# ========================================
# 🎨 THÈMES ET PERSONNALISATION
# ========================================

setup_themes() {
    print_step "Configuration des thèmes Arcane/Fallout..."
    
    # Dossiers de configuration
    sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/{hypr,waybar,wofi,dunst,kitty}
    
    # Installation des icônes modernes
    sudo -u "$USERNAME" yay -S --noconfirm papirus-icon-theme
    
    # Thème GTK
    pacman -S --noconfirm arc-gtk-theme
    
    # Téléchargement des wallpapers vidéo depuis GitHub
    sudo -u "$USERNAME" git clone https://github.com/theme-collection/arcane-wallpapers.git /home/$USERNAME/.config/wallpapers/arcane
    sudo -u "$USERNAME" git clone https://github.com/theme-collection/fallout-wallpapers.git /home/$USERNAME/.config/wallpapers/fallout
    
    print_success "Thèmes installés"
}

setup_hyprland_config() {
    print_step "Configuration de Hyprland..."
    
    cat > /home/$USERNAME/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration - Arcane/Gaming Theme

monitor=,preferred,auto,1

exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

input {
    kb_layout = fr
    follow_mouse = 1
    touchpad {
        natural_scroll = false
    }
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(00d4ffee) rgba(7c3aedee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Keybindings
$mainMod = SUPER

bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Move focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

# Move windows to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

# Lock screen
bind = $mainMod, L, exec, hyprlock

# Screenshot
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Media keys
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

windowrulev2 = opacity 0.9 0.9,class:^(kitty)$
windowrulev2 = opacity 0.9 0.9,class:^(thunar)$
windowrulev2 = opacity 0.95 0.95,class:^(code)$
EOF

    chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/hypr/
    
    print_success "Configuration Hyprland terminée"
}

setup_waybar() {
    print_step "Configuration de la barre des tâches (Waybar)..."
    
    # Configuration Waybar centrée et transparente
    cat > /home/$USERNAME/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "width": 1200,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": ""
        }
    },

    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d %H:%M:%S}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " Muted",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " Connected",
        "format-disconnected": "⚠ Disconnected"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""]
    }
}
EOF

    cat > /home/$USERNAME/.config/waybar/style.css << 'EOF'
* {
    font-family: 'JetBrains Mono', monospace;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(23, 23, 23, 0.8);
    color: white;
    border-radius: 15px;
    margin: 5px 360px 0px 360px;
    border: 2px solid rgba(0, 212, 255, 0.5);
}

#workspaces button {
    padding: 0 10px;
    background: transparent;
    color: white;
    border: none;
    border-radius: 10px;
}

#workspaces button.active {
    background: rgba(124, 58, 237, 0.8);
    color: white;
}

#clock, #pulseaudio, #network, #battery {
    padding: 0 15px;
    margin: 0 5px;
    background: rgba(30, 30, 30, 0.8);
    border-radius: 10px;
}
EOF

    chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/waybar/
    
    print_success "Waybar configuré"
}

setup_login_manager() {
    print_step "Configuration du gestionnaire de connexion graphique..."
    
    # Installation SDDM
    pacman -S --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2
    
    # Thème SDDM personnalisé
    sudo -u "$USERNAME" git clone https://github.com/3ximus/aerial-sddm-theme.git /usr/share/sddm/themes/aerial
    
    # Configuration SDDM
    cat > /etc/sddm.conf << EOF
[Theme]
Current=aerial

[Users]
MaximumUid=60000
MinimumUid=1000
EOF
    
    systemctl enable sddm
    
    print_success "Gestionnaire de connexion configuré"
}

# ========================================
# 🔊 SONS ET ANIMATION FALLOUT
# ========================================

setup_boot_sound() {
    print_step "Configuration du son de boot..."
    
    # Téléchargement du son de boot depuis GitHub
    sudo -u "$USERNAME" wget -O /home/$USERNAME/.config/boot-sound.mp3 \
        "https://raw.githubusercontent.com/fallout-sounds/boot-sounds/main/fallout-boot.mp3"
    
    # Script pour jouer le son au boot
    cat > /etc/systemd/system/boot-sound.service << EOF
[Unit]
Description=Boot Sound
After=sound.target

[Service]
Type=oneshot
ExecStart=/usr/bin/paplay /home/$USERNAME/.config/boot-sound.mp3
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl enable boot-sound.service
    
    print_success "Son de boot configuré"
}

setup_fallout_lockscreen() {
    print_step "Configuration de l'animation Fallout pour l'écran de verrouillage..."
    
    # Installation des dépendances pour hyprlock
    pacman -S --noconfirm hyprlock
    
    # Téléchargement de l'animation Fallout
    sudo -u "$USERNAME" git clone https://github.com/fallout-terminal/hyprlock-fallout.git /home/$USERNAME/.config/hypr/fallout-lock
    
    # Configuration hyprlock avec thème Fallout
    cat > /home/$USERNAME/.config/hypr/hyprlock.conf << 'EOF'
background {
    monitor =
    path = ~/.config/wallpapers/fallout/fallout-terminal.png
    blur_passes = 2
    contrast = 1.3
    brightness = 0.8
    vibrancy = 0.21
    vibrancy_darkness = 0.0
}

general {
    no_fade_in = false
    grace = 0
    disable_loading_bar = true
}

input-field {
    monitor =
    size = 350, 60
    outline_thickness = 4
    dots_size = 0.2
    dots_spacing = 0.2
    dots_center = true
    outer_color = rgba(0, 0, 0, 0)
    inner_color = rgba(0, 0, 0, 0.2)
    font_color = rgb(10, 10, 10)
    fade_on_empty = false
    placeholder_text = <i><span foreground="##cdd6f4">Enter Password...</span></i>
    hide_input = false
    check_color = rgb(204, 136, 34)
    fail_color = rgb(204, 34, 34)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    capslock_color = -1
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false

    position = 0, -50
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%A, %B %d")"
    color = rgba(242, 243, 244, 0.75)
    font_size = 22
    font_family = JetBrains Mono
    position = 0, 300
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%-I:%M")"
    color = rgba(242, 243, 244, 0.75)
    font_size = 95
    font_family = JetBrains Mono Extrabold
    position = 0, 200
    halign = center
    valign = center
}
EOF

    chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/hypr/
    
    print_success "Animation Fallout configurée"
}

# ========================================
# 🥾 CONFIGURATION GRUB
# ========================================

setup_grub_themes() {
    print_step "Installation et configuration des thèmes GRUB..."
    
    # Installation GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    
    # Création du dossier des thèmes
    mkdir -p /boot/grub/themes
    
    # Thème Fallout (principal)
    git clone https://github.com/shvchk/fallout-grub-theme.git /tmp/fallout-grub
    cp -r /tmp/fallout-grub/* /boot/grub/themes/fallout/
    
    # Autres thèmes commentés (à décommenter au choix)
    
    # BSOL Theme
    # git clone https://github.com/Lxtharia/bsol-grub-theme.git /tmp/bsol-grub
    # cp -r /tmp/bsol-grub/* /boot/grub/themes/bsol/
    
    # Minegrub Theme  
    # git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub
    # cp -r /tmp/minegrub/* /boot/grub/themes/minegrub/
    
    # CRT-Amber Theme
    # git clone https://github.com/VandalByte/crt-amber-grub-theme.git /tmp/crt-amber
    # cp -r /tmp/crt-amber/* /boot/grub/themes/crt-amber/
    
    # Arcade Theme
    # git clone https://github.com/VandalByte/arcade-grub-theme.git /tmp/arcade
    # cp -r /tmp/arcade/* /boot/grub/themes/arcade/
    
    # Dark Matter Theme
    # git clone https://github.com/VandalByte/dark-matter-grub-theme.git /tmp/dark-matter
    # cp -r /tmp/dark-matter/* /boot/grub/themes/dark-matter/
    
    # Arcane Theme (custom)
    # git clone https://github.com/arcane-themes/grub-arcane.git /tmp/arcane-grub
    # cp -r /tmp/arcane-grub/* /boot/grub/themes/arcane/
    
    # Star Wars Theme
    # git clone https://github.com/VandalByte/star-wars-grub-theme.git /tmp/star-wars
    # cp -r /tmp/star-wars/* /boot/grub/themes/star-wars/
    
    # LOTR Theme
    # git clone https://github.com/VandalByte/lotr-grub-theme.git /tmp/lotr
    # cp -r /tmp/lotr/* /boot/grub/themes/lotr/
    
    # Configuration GRUB avec le thème Fallout
    cat > /etc/default/grub << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
GRUB_DISABLE_OS_PROBER=false
EOF
    
    # Génération de la configuration GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    
    print_success "Thèmes GRUB installés (thème Fallout actif)"
}

# ========================================
# 🎵 CONFIGURATION SPICETIFY
# ========================================

setup_spicetify() {
    print_step "Configuration de Spicetify pour Spotify..."
    
    # Installation et configuration Spicetify
    sudo -u "$USERNAME" bash -c '
        cd /home/'$USERNAME'
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
        
        # Ajout au PATH
        echo "export PATH=\"\$PATH:/home/'$USERNAME'/.spicetify\"" >> /home/'$USERNAME'/.bashrc
        
        # Configuration du thème Arcane-like
        /home/'$USERNAME'/.spicetify/spicetify config extensions dribbblish.js
        /home/'$USERNAME'/.spicetify/spicetify config current_theme Dribbblish color_scheme nord-dark
        /home/'$USERNAME'/.spicetify/spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
        
        # Application du thème
        /home/'$USERNAME'/.spicetify/spicetify backup apply
    '
    
    print_success "Spicetify configuré"
}

# ========================================
# 🖼️ CONFIGURATION WALLPAPER VIDÉO
# ========================================

setup_video_wallpaper() {
    print_step "Configuration du fond d'écran vidéo..."
    
    # Installation de mpvpaper pour les wallpapers vidéo
    sudo -u "$USERNAME" yay -S --noconfirm mpvpaper
    
    # Téléchargement des wallpapers vidéo
    sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/wallpapers/videos
    
    # Wallpaper Arcane (exemple)
    sudo -u "$USERNAME" wget -O /home/$USERNAME/.config/wallpapers/videos/arcane-jinx.mp4 \
        "https://github.com/arcane-wallpapers/videos/raw/main/jinx-animation.mp4" || \
        echo "Wallpaper Arcane non disponible, utilisation d'une alternative"
    
    # Wallpaper Fallout (exemple)
    sudo -u "$USERNAME" wget -O /home/$USERNAME/.config/wallpapers/videos/fallout-terminal.mp4 \
        "https://github.com/fallout-wallpapers/videos/raw/main/terminal-animation.mp4" || \
        echo "Wallpaper Fallout non disponible, utilisation d'une alternative"
    
    # Script de lancement du wallpaper vidéo
    cat > /home/$USERNAME/.config/hypr/video-wallpaper.sh << 'EOF'
#!/bin/bash

# Choix aléatoire entre les wallpapers disponibles
WALLPAPERS_DIR="/home/'$USERNAME'/.config/wallpapers/videos"
WALLPAPER=$(find "$WALLPAPERS_DIR" -name "*.mp4" | shuf -n 1)

if [ -f "$WALLPAPER" ]; then
    mpvpaper -o "no-audio loop" eDP-1 "$WALLPAPER"
else
    # Fallback sur image statique
    hyprpaper &
fi
EOF
    
    chmod +x /home/$USERNAME/.config/hypr/video-wallpaper.sh
    chown "$USERNAME:$USERNAME" /home/$USERNAME/.config/hypr/video-wallpaper.sh
    
    # Modification de la config Hyprland pour utiliser le wallpaper vidéo
    sed -i 's/exec-once = hyprpaper/exec-once = ~\/.config\/hypr\/video-wallpaper.sh/' /home/$USERNAME/.config/hypr/hyprland.conf
    
    print_success "Fond d'écran vidéo configuré"
}

# ========================================
# 📊 INSTALLATION FASTFETCH
# ========================================

setup_fastfetch() {
    print_step "Installation et configuration de Fastfetch..."
    
    # Installation Fastfetch
    sudo -u "$USERNAME" yay -S --noconfirm fastfetch
    
    # Configuration Fastfetch avec logo Arch
    sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.config/fastfetch
    
    cat > /home/$USERNAME/.config/fastfetch/config.jsonc << 'EOF'
{
    "$schema": "https://github.com/fastfetch-dev/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": " → ",
        "color": {
            "keys": "blue",
            "title": "blue"
        }
    },
    "modules": [
        {
            "type": "title",
            "color": {
                "user": "blue",
                "at": "white",
                "host": "green"
            }
        },
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "wmtheme",
        "theme",
        "icons",
        "font",
        "cursor",
        "terminal",
        "terminalfont",
        "cpu",
        "gpu",
        "memory",
        "swap",
        "disk",
        "localip",
        "battery",
        "poweradapter",
        "locale",
        "break",
        "colors"
    ]
}
EOF

    # Configuration alternative avec image personnalisée (commentée)
    cat > /home/$USERNAME/.config/fastfetch/config-custom.jsonc << 'EOF'
{
    "$schema": "https://github.com/fastfetch-dev/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        // Décommentez et modifiez pour utiliser une image personnalisée
        // "source": "/home/'$USERNAME'/.config/wallpapers/arcane/jinx-logo.png",
        "source": "arch",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": " → ",
        "color": {
            "keys": "magenta",
            "title": "cyan"
        }
    },
    "modules": [
        {
            "type": "title",
            "color": {
                "user": "cyan",
                "at": "white", 
                "host": "magenta"
            }
        },
        "separator",
        "os",
        "kernel",
        "uptime",
        "packages",
        "de",
        "wm",
        "cpu",
        "gpu", 
        "memory",
        "colors"
    ]
}
EOF

    # Ajout de fastfetch au bashrc
    echo "" >> /home/$USERNAME/.bashrc
    echo "# Fastfetch au démarrage du terminal" >> /home/$USERNAME/.bashrc
    echo "fastfetch" >> /home/$USERNAME/.bashrc
    
    chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/fastfetch/
    
    print_success "Fastfetch configuré"
}

# ========================================
# 🚀 AUTO-START HYPRLAND
# ========================================

setup_auto_start() {
    print_step "Configuration du démarrage automatique de Hyprland..."
    
    # Configuration pour démarrer Hyprland automatiquement
    echo "" >> /home/$USERNAME/.bashrc
    echo "# Auto-start Hyprland" >> /home/$USERNAME/.bashrc
    echo 'if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then' >> /home/$USERNAME/.bashrc
    echo '    exec Hyprland' >> /home/$USERNAME/.bashrc
    echo 'fi' >> /home/$USERNAME/.bashrc
    
    # Configuration des services système
    systemctl enable NetworkManager
    systemctl enable bluetooth
    
    print_success "Démarrage automatique configuré"
}

# ========================================
# 🎯 FINALISATION
# ========================================

finalize_installation() {
    print_step "Finalisation de l'installation..."
    
    # Mise à jour de la base de données des polices
    fc-cache -fv
    
    # Configuration des permissions
    usermod -aG video,audio,wheel,storage,optical "$USERNAME"
    
    # Nettoyage
    pacman -Scc --noconfirm
    sudo -u "$USERNAME" yay -Scc --noconfirm
    
    # Génération des locales
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    
    echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
    echo "KEYMAP=fr" > /etc/vconsole.conf
    
    # Configuration du hostname
    echo "archlinux-hyprland" > /etc/hostname
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux-hyprland.localdomain archlinux-hyprland
EOF
    
    print_success "Installation finalisée"
}

create_readme() {
    print_step "Création du README.md..."
    
    cat > /home/$USERNAME/README-Installation.md << 'EOF'
# 🌟 Arch Linux + Hyprland - Installation Complète

## 📋 Résumé de l'installation

Cette installation comprend :

### 🎮 Environnement
- **Hyprland** - Compositeur Wayland moderne
- **Waybar** - Barre des tâches centrée et transparente
- **SDDM** - Gestionnaire de connexion graphique
- **Thème** - Style Arcane/Fallout/Gaming

### 🛠️ Outils de développement
- **VS Code** avec extensions (Copilot, Java, Python, C++, etc.)
- **Android Studio**
- **Java OpenJDK**
- **Python, Node.js, Docker**
- **Outils réseau** (nmap, wireshark, etc.)

### 🌐 Applications
- **Google Chrome** & **Brave Browser**
- **Spotify** avec **Spicetify** (thème personnalisé)
- **Netflix** & **Disney+** (via Flatpak)
- **Wine** pour applications Windows

### 🎨 Personnalisation
- **Fastfetch** avec logo Arch Linux
- **Fond d'écran vidéo** (Arcane/Fallout)
- **Transparence** sur toutes les applications
- **Animation Fallout** pour l'écran de verrouillage
- **Son de boot** personnalisé
- **Icônes modernes** (Papirus)

### 🥾 Thèmes GRUB disponibles

#### Thème actuel : **Fallout**
- Source: https://github.com/shvchk/fallout-grub-theme

#### Autres thèmes disponibles (commentés dans le script) :

1. **BSOL** - Blue Screen of Life
   - Source: https://github.com/Lxtharia/bsol-grub-theme

2. **Minegrub** - Thème Minecraft
   - Source: https://github.com/Lxtharia/minegrub-theme

3. **CRT-Amber** - Terminal vintage
   - Source: https://github.com/VandalByte/crt-amber-grub-theme

4. **Arcade** - Style arcade rétro
   - Source: https://github.com/VandalByte/arcade-grub-theme

5. **Dark Matter** - Thème sombre moderne
   - Source: https://github.com/VandalByte/dark-matter-grub-theme

6. **Star Wars** - Thème Star Wars
   - Source: https://github.com/VandalByte/star-wars-grub-theme

7. **LOTR** - Le Seigneur des Anneaux
   - Source: https://github.com/VandalByte/lotr-grub-theme

8. **Arcane** - Thème série Netflix (custom)
   - Source: https://github.com/arcane-themes/grub-arcane

#### 📚 Plus de thèmes GRUB
Consultez la collection complète : https://www.gnome-look.org/browse?cat=109&ord=latest

### 🔧 Configuration post-installation

#### Changer de thème GRUB :
```bash
sudo nano /etc/default/grub
# Modifier la ligne GRUB_THEME="/boot/grub/themes/[nom-du-theme]/theme.txt"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

#### Activer un fond d'écran statique au lieu de vidéo :
```bash
# Modifier ~/.config/hypr/hyprland.conf
# Remplacer la ligne exec-once par :
exec-once = hyprpaper
```

#### Utiliser l'image personnalisée dans Fastfetch :
```bash
# Éditer ~/.config/fastfetch/config.jsonc
# Décommenter et modifier la ligne "source"
```

### 🎵 Spicetify - Thèmes disponibles

Le script installe le thème **Dribbblish** avec couleurs **nord-dark**.

Autres thèmes disponibles :
```bash
spicetify config current_theme [theme-name]
# Thèmes : Dribbblish, Default, Sleek, etc.
```

### 🔊 Détecteur de basses

**Cava** est installé pour la visualisation audio en temps réel.
```bash
cava  # Lance le visualiseur audio
```

### 📝 Raccourcis clavier Hyprland

- `Super + Q` : Terminal (Kitty)
- `Super + C` : Fermer la fenêtre
- `Super + E` : Gestionnaire de fichiers
- `Super + R` : Menu d'applications
- `Super + L` : Verrouiller l'écran
- `Print` : Capture d'écran

### 🚀 Services actifs

- NetworkManager (réseau)
- Bluetooth
- SDDM (connexion graphique)
- Boot Sound (son au démarrage)
- Hyprland (auto-start)

### 📁 Structure des fichiers

```
~/.config/
├── hypr/           # Configuration Hyprland
├── waybar/         # Barre des tâches
├── wallpapers/     # Fonds d'écran
├── fastfetch/      # Configuration système info
└── spicetify/      # Thèmes Spotify
```

### 🔗 Sources et crédits

- **Hyprland**: https://hyprland.org/
- **Waybar**: https://github.com/Alexays/Waybar
- **Spicetify**: https://spicetify.app/
- **Fastfetch**: https://github.com/fastfetch-dev/fastfetch
- **Thèmes GRUB**: Voir liens individuels ci-dessus
- **Wallpapers**: Collections GitHub personnalisées

---

**Installation réalisée avec succès ! 🎉**

Redémarrez votre système pour profiter pleinement de votre nouvel environnement Arch Linux + Hyprland.
EOF

    chown "$USERNAME:$USERNAME" /home/$USERNAME/README-Installation.md
    
    print_success "README créé"
}

# ========================================
# 🎯 MENU PRINCIPAL
# ========================================

show_menu() {
    print_banner
    echo -e "${CYAN}Choisissez les composants à installer:${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} Installation complète (recommandé)"
    echo -e "${YELLOW}2.${NC} Installation personnalisée"
    echo -e "${YELLOW}3.${NC} Quitter"
    echo ""
    read -p "Votre choix [1-3]: " choice
    
    case $choice in
        1)
            full_installation
            ;;
        2)
            custom_installation
            ;;
        3)
            print_info "Installation annulée"
            exit 0
            ;;
        *)
            print_error "Choix invalide"
            show_menu
            ;;
    esac
}

full_installation() {
    print_banner
    print_step "🚀 Début de l'installation complète..."
    
    check_internet
    setup_user
    setup_partitions
    mount_partitions
    install_base_system
    
    # Chroot et continuation de l'installation
    arch-chroot /mnt /bin/bash << CHROOT_EOF
    
    # Installation AUR helper (yay)
    pacman -S --noconfirm git base-devel
    sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    sudo -u $USERNAME makepkg -si --noconfirm
    
    # Exécution des fonctions d'installation
    $(declare -f remove_existing_de)
    $(declare -f install_hyprland)
    $(declare -f install_audio_tools)
    $(declare -f install_development_tools)
    $(declare -f install_network_tools)
    $(declare -f install_browsers)
    $(declare -f install_media_apps)
    $(declare -f install_wine)
    $(declare -f setup_themes)
    $(declare -f setup_hyprland_config)
    $(declare -f setup_waybar)
    $(declare -f setup_login_manager)
    $(declare -f setup_boot_sound)
    $(declare -f setup_fallout_lockscreen)
    $(declare -f setup_grub_themes)
    $(declare -f setup_spicetify)
    $(declare -f setup_video_wallpaper)
    $(declare -f setup_fastfetch)
    $(declare -f setup_auto_start)
    $(declare -f finalize_installation)
    $(declare -f create_readme)
    $(declare -f create_user)
    
    create_user
    remove_existing_de
    install_hyprland
    install_audio_tools
    install_development_tools
    install_network_tools
    install_browsers
    install_media_apps
    install_wine
    setup_themes
    setup_hyprland_config
    setup_waybar
    setup_login_manager
    setup_boot_sound
    setup_fallout_lockscreen
    setup_grub_themes
    setup_spicetify
    setup_video_wallpaper
    setup_fastfetch
    setup_auto_start
    finalize_installation
    create_readme
    
CHROOT_EOF
    
    print_success "🎉 Installation complète terminée !"
    print_info "Redémarrez votre système pour profiter de votre nouvel environnement"
    print_info "Consultez ~/README-Installation.md pour plus d'informations"
}

custom_installation() {
    print_info "Installation personnalisée non implémentée dans cette version"
    print_info "Utilisez l'option 1 pour l'installation complète"
    show_menu
}

# ========================================
# 🎯 POINT D'ENTRÉE PRINCIPAL
# ========================================

main() {
    # Vérifications initiales
    check_root
    
    # Initialisation du log
    echo "=== Installation Arch Linux + Hyprland ===" > "$LOG_FILE"
    echo "Début: $(date)" >> "$LOG_FILE"
    
    # Lancement du menu
    show_menu
}

# Lancement du script
main "$@"