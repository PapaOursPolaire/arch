#!/bin/bash

# ================================================================
# ARCH LINUX + HYPRLAND INSTALLATION SCRIPT
# Thème: Dev/Gaming/Arcane - Installation complète automatisée
# ================================================================

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logo ASCII Arcane
print_logo() {
    echo -e "${PURPLE}"
    echo "    ╔═══════════════════════════════════════╗"
    echo "    ║         ARCH HYPRLAND SETUP           ║"
    echo "    ║    Gaming • Dev • Arcane Theme        ║"
    echo "    ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour gérer les erreurs
handle_error() {
    log_error "Une erreur s'est produite à la ligne $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# ================================================================
# CONFIGURATION INITIALE
# ================================================================

print_logo

log_info "Démarrage de l'installation Arch Linux + Hyprland..."

# Variables de configuration
USERNAME=""
HOSTNAME=""
DISK=""
ROOT_SIZE="50G"
SWAP_SIZE="8G"

# Fonction de saisie sécurisée
get_user_input() {
    while [[ -z "$USERNAME" ]]; do
        read -p "Nom d'utilisateur: " USERNAME
        if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            log_error "Nom d'utilisateur invalide. Utilisez uniquement des lettres minuscules, chiffres, - et _"
            USERNAME=""
        fi
    done

    while [[ -z "$HOSTNAME" ]]; do
        read -p "Nom de l'ordinateur: " HOSTNAME
        if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
            log_error "Nom d'hôte invalide"
            HOSTNAME=""
        fi
    done

    echo "Disques disponibles:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    while [[ -z "$DISK" ]]; do
        read -p "Choisir le disque (ex: sda, nvme0n1): " DISK
        if [[ ! -b "/dev/$DISK" ]]; then
            log_error "Disque non trouvé: /dev/$DISK"
            DISK=""
        fi
    done
}

# ================================================================
# PRÉPARATION DU SYSTÈME
# ================================================================

prepare_system() {
    log_info "Configuration du système de base..."
    
    # Synchronisation de l'horloge
    timedatectl set-ntp true
    
    # Mise à jour des miroirs
    reflector --country France,Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    
    # Activation du multilib
    sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    pacman -Sy
}

# ================================================================
# PARTITIONNEMENT (SANS EFFACER LES DONNÉES EXISTANTES)
# ================================================================

setup_partitions() {
    log_info "Configuration des partitions (préservation des données)..."
    
    # Affichage des partitions existantes
    echo "Partitions existantes:"
    lsblk "/dev/$DISK"
    
    log_warning "ATTENTION: Ce script va créer de nouvelles partitions sans effacer les existantes"
    read -p "Continuer? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_error "Installation annulée"
        exit 1
    fi
    
    # Création des partitions avec cgdisk (plus sûr)
    log_info "Utilisez cgdisk pour créer manuellement:"
    log_info "1. Partition EFI (512M) - Type EF00 si elle n'existe pas"
    log_info "2. Partition ROOT ($ROOT_SIZE) - Type 8300"
    log_info "3. Partition HOME (reste) - Type 8300"
    log_info "4. Partition SWAP ($SWAP_SIZE) - Type 8200"
    
    read -p "Appuyez sur Entrée quand les partitions sont prêtes..."
    
    # Demander les numéros de partitions
    read -p "Numéro de partition EFI (ex: 1): " EFI_PART
    read -p "Numéro de partition ROOT (ex: 2): " ROOT_PART
    read -p "Numéro de partition HOME (ex: 3): " HOME_PART
    read -p "Numéro de partition SWAP (ex: 4): " SWAP_PART
    
    # Formatage des nouvelles partitions uniquement
    log_info "Formatage des partitions..."
    
    # EFI (seulement si elle n'existe pas déjà)
    if ! mountpoint -q /mnt/boot; then
        mkfs.fat -F32 "/dev/${DISK}${EFI_PART}"
    fi
    
    # ROOT
    mkfs.ext4 "/dev/${DISK}${ROOT_PART}"
    
    # HOME
    mkfs.ext4 "/dev/${DISK}${HOME_PART}"
    
    # SWAP
    mkswap "/dev/${DISK}${SWAP_PART}"
    swapon "/dev/${DISK}${SWAP_PART}"
    
    # Montage
    mount "/dev/${DISK}${ROOT_PART}" /mnt
    mkdir -p /mnt/boot /mnt/home
    mount "/dev/${DISK}${EFI_PART}" /mnt/boot
    mount "/dev/${DISK}${HOME_PART}" /mnt/home
}

# ================================================================
# INSTALLATION DU SYSTÈME DE BASE
# ================================================================

install_base_system() {
    log_info "Installation du système de base..."
    
    # Installation des paquets de base
    pacstrap /mnt base linux linux-firmware linux-headers \
        base-devel git vim nano sudo networkmanager \
        grub efibootmgr os-prober ntfs-3g \
        intel-ucode amd-ucode # Support processeurs Intel et AMD
    
    # Génération du fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    log_success "Système de base installé"
}

# ================================================================
# CONFIGURATION CHROOT
# ================================================================

configure_chroot() {
    log_info "Configuration du système en chroot..."
    
    # Création du script de configuration pour chroot
    cat > /mnt/chroot_config.sh << 'CHROOT_EOF'
#!/bin/bash

# Configuration timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

# Configuration locale
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf

# Configuration réseau
echo "HOSTNAME_PLACEHOLDER" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   HOSTNAME_PLACEHOLDER.localdomain HOSTNAME_PLACEHOLDER
EOF

# Configuration utilisateur
useradd -m -G wheel,audio,video,optical,storage,input,power,users -s /bin/bash USERNAME_PLACEHOLDER
echo "Mot de passe pour USERNAME_PLACEHOLDER:"
passwd USERNAME_PLACEHOLDER
echo "Mot de passe root:"
passwd

# Configuration sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Services
systemctl enable NetworkManager
systemctl enable fstrim.timer

CHROOT_EOF

    # Remplacement des placeholders
    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/chroot_config.sh
    sed -i "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" /mnt/chroot_config.sh
    
    # Exécution en chroot
    arch-chroot /mnt bash /chroot_config.sh
    rm /mnt/chroot_config.sh
}

# ================================================================
# INSTALLATION GRUB ET THÈMES
# ================================================================

install_grub_themes() {
    log_info "Installation de GRUB et thèmes..."
    
    cat > /mnt/install_grub.sh << 'GRUB_EOF'
#!/bin/bash

# Installation GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ARCH --recheck
grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck

# Configuration GRUB pour multiboot
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/' /etc/default/grub

# Création du dossier thèmes
mkdir -p /boot/grub/themes

# Installation des thèmes GRUB
cd /tmp

# Thème Fallout (par défaut)
git clone https://github.com/shvchk/fallout-grub-theme.git
cp -r fallout-grub-theme/fallout /boot/grub/themes/
echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub

# Autres thèmes
# BSOD Theme
git clone https://github.com/Lxtharia/minegrub-theme.git
cp -r minegrub-theme/minegrub /boot/grub/themes/

# CRT-Amber
git clone https://github.com/VandalByte/dedsec-grub2-theme.git
cp -r dedsec-grub2-theme/dedsec /boot/grub/themes/

# Dark Matter
git clone https://github.com/VandalByte/darkmatter-grub2-theme.git
cp -r darkmatter-grub2-theme/darkmatter /boot/grub/themes/

# Arcane Theme (custom)
git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
cp -r Top-5-Bootloader-Themes/themes/* /boot/grub/themes/ 2>/dev/null || true

# Génération de la configuration GRUB
grub-mkconfig -o /boot/grub/grub.cfg

GRUB_EOF

    arch-chroot /mnt bash /install_grub.sh
    rm /mnt/install_grub.sh
    
    log_success "GRUB et thèmes installés"
}

# ================================================================
# INSTALLATION HYPRLAND ET ENVIRONNEMENT GRAPHIQUE
# ================================================================

install_hyprland() {
    log_info "Installation de Hyprland et environnement graphique..."
    
    cat > /mnt/install_hyprland.sh << 'HYPR_EOF'
#!/bin/bash

# Installation des drivers graphiques
pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-intel lib32-vulkan-intel nvidia nvidia-lib32 nvidia-utils lib32-nvidia-utils

# Installation Hyprland et dépendances
pacman -S --noconfirm hyprland waybar wofi dunst kitty thunar \
    grim slurp swaylock-effects swayidle wl-clipboard \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    xdg-desktop-portal-hyprland polkit-gnome \
    ttf-font-awesome ttf-fira-code noto-fonts noto-fonts-emoji \
    brightnessctl playerctl pamixer

# Outils supplémentaires
pacman -S --noconfirm rofi-wayland network-manager-applet \
    bluez bluez-utils pavucontrol firefox \
    file-roller unzip unrar p7zip

# Installation d'un gestionnaire de connexion
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm

# Thème SDDM Arcane
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/theme.conf << EOF
[Theme]
Current=sugar-candy

[General]
InputMethod=
EOF

HYPR_EOF

    arch-chroot /mnt bash /install_hyprland.sh
    rm /mnt/install_hyprland.sh
}

# ================================================================
# CONFIGURATION HYPRLAND ET THÈMES
# ================================================================

configure_hyprland() {
    log_info "Configuration de Hyprland..."
    
    cat > /mnt/setup_hyprland_config.sh << 'HYPR_CONFIG_EOF'
#!/bin/bash

USER_HOME="/home/USERNAME_PLACEHOLDER"
CONFIG_DIR="$USER_HOME/.config"

# Création des dossiers de configuration
sudo -u USERNAME_PLACEHOLDER mkdir -p $CONFIG_DIR/{hypr,waybar,wofi,dunst,kitty,swaylock}

# Configuration Hyprland principale
sudo -u USERNAME_PLACEHOLDER cat > $CONFIG_DIR/hypr/hyprland.conf << 'EOF'
# Configuration Hyprland - Thème Arcane/Gaming/Dev

# Moniteurs
monitor=,preferred,auto,auto

# Variables
$terminal = kitty
$fileManager = thunar
$menu = wofi --show drun

# Programmes au démarrage
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = swayidle -w timeout 300 'swaylock -f' timeout 600 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep 'swaylock -f'

# Wallpaper vidéo (avec mpvpaper)
exec-once = mpvpaper -o "no-audio --loop" '*' ~/.config/wallpapers/arcane_video.mp4

# Variables d'environnement
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct

# Apparence - Thème Arcane
general {
    gaps_in = 8
    gaps_out = 12
    border_size = 3
    col.active_border = rgba(c9aa71ff) rgba(0f2027ff) 45deg
    col.inactive_border = rgba(1e3c72ff)
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 12
    
    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        xray = true
        vibrancy = 0.1696
    }

    drop_shadow = true
    shadow_range = 30
    shadow_render_power = 3
    col.shadow = 0x66000000
    
    # Transparence des fenêtres
    active_opacity = 0.95
    inactive_opacity = 0.85
}

animations {
    enabled = true
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1

    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 1, liner
    animation = borderangle, 1, 30, liner, loop
    animation = fade, 1, 10, default
    animation = workspaces, 1, 5, wind
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# Keybinds - Style gaming
$mainMod = SUPER

bind = $mainMod, Q, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, swaylock
bind = $mainMod, F, fullscreen

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
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Media keys
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioPause, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Screenshots
bind = $mainMod, PRINT, exec, grim -g "$(slurp)" - | wl-copy
bind = , PRINT, exec, grim - | wl-copy

# Window rules pour transparence
windowrulev2 = opacity 0.90 0.90,class:^(firefox)$
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.85 0.85,class:^(thunar)$
windowrulev2 = opacity 0.90 0.90,class:^(discord)$
windowrulev2 = opacity 0.95 0.95,class:^(spotify)$

EOF

# Configuration Waybar (barre des tâches centrée et transparente)
sudo -u USERNAME_PLACEHOLDER cat > $CONFIG_DIR/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "width": 1200,
    "spacing": 4,
    "margin-top": 8,
    "margin-left": 360,
    "margin-right": 360,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "tray"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "6": "",
            "7": "",
            "8": "",
            "9": "",
            "10": ""
        }
    },
    
    "clock": {
        "timezone": "Europe/Paris",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    
    "memory": {
        "format": "{}% "
    },
    
    "temperature": {
        "critical-threshold": 80,
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    
    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-bluetooth-muted": " {icon}",
        "format-muted": "",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    }
}
EOF

sudo -u USERNAME_PLACEHOLDER cat > $CONFIG_DIR/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: 'Fira Code', monospace;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(15, 32, 39, 0.8);
    border: 2px solid rgba(201, 170, 113, 0.6);
    color: #ffffff;
    border-radius: 20px;
    backdrop-filter: blur(10px);
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #ffffff;
    border-bottom: 3px solid transparent;
}

#workspaces button:hover {
    background: rgba(201, 170, 113, 0.3);
}

#workspaces button.active {
    background-color: rgba(201, 170, 113, 0.5);
    border-bottom: 3px solid #c9aa71;
}

#clock,
#battery,
#cpu,
#memory,
#temperature,
#network,
#pulseaudio,
#tray {
    padding: 0 10px;
    color: #ffffff;
}

#battery.charging, #battery.plugged {
    color: #26A65B;
}

@keyframes blink {
    to {
        background-color: #ffffff;
        color: #000000;
    }
}

#battery.critical:not(.charging) {
    background-color: #f53c3c;
    color: #ffffff;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
EOF

HYPR_CONFIG_EOF

    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/setup_hyprland_config.sh
    arch-chroot /mnt bash /setup_hyprland_config.sh
    rm /mnt/setup_hyprland_config.sh
}

# ================================================================
# INSTALLATION DES APPLICATIONS
# ================================================================

install_applications() {
    log_info "Installation des applications..."
    
    cat > /mnt/install_apps.sh << 'APPS_EOF'
#!/bin/bash

# Installation de yay (AUR helper)
sudo -u USERNAME_PLACEHOLDER bash -c '
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
'

# Applications de développement
pacman -S --noconfirm jdk-openjdk jdk8-openjdk jdk11-openjdk \
    python python-pip nodejs npm \
    gcc gdb make cmake \
    docker docker-compose \
    git-lfs

# Installation VS Code
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm visual-studio-code-bin

# Extensions VS Code
sudo -u USERNAME_PLACEHOLDER bash -c '
code --install-extension GitHub.copilot
code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension Extension.java-extension-pack
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension PKief.material-icon-theme
code --install-extension zhuangtongfa.Material-theme
code --install-extension ms-vscode-remote.remote-containers
'

# Android Studio
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm android-studio

# Navigateurs
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm google-chrome brave-bin

# Streaming et multimedia
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm netflix-desktop-app disney-plus-app
pacman -S --noconfirm vlc obs-studio

# Spotify avec Spicetify
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm spotify spicetify-cli
sudo -u USERNAME_PLACEHOLDER spicetify backup apply

# Outils réseau et hacking
pacman -S --noconfirm nmap wireshark-qt aircrack-ng \
    tcpdump netcat openvpn \
    hashcat john hydra \
    metasploit burpsuite

# Gaming
pacman -S --noconfirm steam lutris wine winetricks \
    gamemode lib32-gamemode

# Outils système
pacman -S --noconfirm htop neofetch fastfetch \
    tree ranger fzf \
    discord telegram-desktop

# Thèmes et icônes
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm \
    papirus-icon-theme \
    arc-gtk-theme \
    nordic-theme

# Installation de fastfetch avec logo Arch
sudo -u USERNAME_PLACEHOLDER mkdir -p /home/USERNAME_PLACEHOLDER/.config/fastfetch
sudo -u USERNAME_PLACEHOLDER cat > /home/USERNAME_PLACEHOLDER/.config/fastfetch/config.conf << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "color": {
            "1": "cyan",
            "2": "blue"
        }
    },
    "display": {
        "separator": " -> "
    },
    "modules": [
        "title",
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

# Configuration alternative avec image custom (commentée)
sudo -u USERNAME_PLACEHOLDER cat > /home/USERNAME_PLACEHOLDER/.config/fastfetch/config_custom.conf << 'EOF'
# Configuration avec image personnalisée
# Décommentez et modifiez selon vos besoins
# {
#     "logo": {
#         "source": "/path/to/your/image.png",
#         "width": 40,
#         "height": 20
#     }
# }
EOF

APPS_EOF

    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/install_apps.sh
    arch-chroot /mnt bash /install_apps.sh
    rm /mnt/install_apps.sh
}

# ================================================================
# CONFIGURATION AVANCÉE ET THÈMES
# ================================================================

setup_advanced_config() {
    log_info "Configuration avancée et thèmes..."
    
    cat > /mnt/advanced_setup.sh << 'ADV_EOF'
#!/bin/bash

USER_HOME="/home/USERNAME_PLACEHOLDER"

# Installation mpvpaper pour wallpaper vidéo
sudo -u USERNAME_PLACEHOLDER yay -S --noconfirm mpvpaper-git

# Création du dossier wallpapers
sudo -u USERNAME_PLACEHOLDER mkdir -p $USER_HOME/.config/wallpapers

# Téléchargement wallpaper Arcane (exemple)
sudo -u USERNAME_PLACEHOLDER wget -O $USER_HOME/.config/wallpapers/arcane_video.mp4 \
    "https://github.com/ChrisTitusTech/hyprland-titus/raw/main/wallpapers/arcane.mp4" || \
    echo "# Placeholder - Ajoutez votre vidéo ici" > $USER_HOME/.config/wallpapers/README.md

# Configuration Swaylock (écran de verrouillage) - Thème Fallout/Arcane
sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/swaylock/config << 'EOF'
daemonize
show-failed-attempts
clock
screenshot
effect-blur=9x5
effect-vignette=0.5:0.5
color=1f1f1f
font="Fira Code"
indicator
indicator-radius=200
indicator-thickness=20
line-color=c9aa71
ring-color=0f2027
inside-color=1e3c72
key-hl-color=c9aa71
separator-color=00000000
text-color=ffffff
text-caps-lock-color=ffffff
line-ver-color=c9aa71
ring-ver-color=c9aa71
inside-ver-color=0f2027
text-ver-color=ffffff
ring-wrong-color=ff0000
text-wrong-color=ff0000
inside-wrong-color=1e3c72
inside-clear-color=c9aa71
text-clear-color=ffffff
ring-clear-color=c9aa71
line-clear-color=ffffff
line-wrong-color=ff0000
EOF

# Configuration Kitty terminal - Thème Arcane
sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/kitty/kitty.conf << 'EOF'
# Kitty Configuration - Thème Arcane

# Fonts
font_family     Fira Code Medium
bold_font       Fira Code Bold
italic_font     Fira Code Medium Italic
bold_italic_font Fira Code Bold Italic
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0.5

# Window
background_opacity 0.85
background_blur 20
dynamic_background_opacity yes

# Thème Arcane
foreground #ffffff
background #0f1419
selection_foreground #ffffff
selection_background #c9aa71

# Colors (Arcane inspired)
color0  #1e3c72
color1  #ff6b6b
color2  #4ecdc4
color3  #c9aa71
color4  #3742fa
color5  #f8b500
color6  #70a1ff
color7  #ffffff
color8  #576574
color9  #ff6b6b
color10 #4ecdc4
color11 #c9aa71
color12 #3742fa
color13 #f8b500
color14 #70a1ff
color15 #ffffff

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Advanced
allow_remote_control yes
clipboard_control write-clipboard write-primary
EOF

# Configuration Wofi (menu d'applications)
sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/wofi/config << 'EOF'
width=600
height=400
location=center
show=drun
prompt=Applications
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=40
gtk_dark=true
EOF

sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/wofi/style.css << 'EOF'
window {
    margin: 0px;
    border: 2px solid #c9aa71;
    background-color: rgba(15, 32, 39, 0.9);
    border-radius: 15px;
}

#input {
    padding: 4px;
    margin: 4px;
    padding-left: 20px;
    border: none;
    color: #ffffff;
    font-weight: bold;
    background-color: rgba(30, 60, 114, 0.8);
    border-radius: 15px;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #ffffff;
}

#entry {
    padding: 8px;
    margin: 2px;
    border-radius: 10px;
    background-color: transparent;
}

#entry:selected {
    background-color: rgba(201, 170, 113, 0.3);
}

#text:selected {
    color: #c9aa71;
}
EOF

# Configuration Dunst (notifications)
sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/dunst/dunstrc << 'EOF'
[global]
    monitor = 0
    follow = mouse
    geometry = "300x60-20+48"
    indicate_hidden = yes
    shrink = no
    transparency = 20
    notification_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    frame_width = 2
    frame_color = "#c9aa71"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    
    font = Fira Code 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    
    icon_position = left
    max_icon_size = 32
    icon_path = /usr/share/icons/Papirus/16x16/status/:/usr/share/icons/Papirus/16x16/devices/
    
    sticky_history = yes
    history_length = 20
    
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    
    always_run_script = true
    title = Dunst
    class = Dunst
    
    startup_notification = false
    verbosity = mesg
    
    corner_radius = 10
    
[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#0f2027"
    foreground = "#ffffff"
    timeout = 10

[urgency_normal]
    background = "#1e3c72"
    foreground = "#ffffff"
    timeout = 10

[urgency_critical]
    background = "#ff0000"
    foreground = "#ffffff"
    frame_color = "#ff0000"
    timeout = 0
EOF

# Installation détecteur de basses sonores (cava)
pacman -S --noconfirm cava
sudo -u USERNAME_PLACEHOLDER mkdir -p $USER_HOME/.config/cava
sudo -u USERNAME_PLACEHOLDER cat > $USER_HOME/.config/cava/config << 'EOF'
[general]
framerate = 60
bars = 50
bar_width = 2
bar_spacing = 1

[input]
method = pulse
source = auto

[output]
method = ncurses
channels = stereo
mono_option = average

[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '#0f2027'
gradient_color_2 = '#203a43'
gradient_color_3 = '#2c5364'
gradient_color_4 = '#1e3c72'
gradient_color_5 = '#c9aa71'
gradient_color_6 = '#ffffff'

[smoothing]
noise_reduction = 88
EOF

# Installation animation Fallout pour lock screen
cd /tmp
git clone https://github.com/adi1090x/plymouth-themes.git || true
sudo cp -r plymouth-themes/pack_4/fallout /usr/share/plymouth/themes/ || true

# Services Docker et autres
systemctl enable docker
usermod -aG docker USERNAME_PLACEHOLDER

# Configuration Git globale
sudo -u USERNAME_PLACEHOLDER git config --global init.defaultBranch main
sudo -u USERNAME_PLACEHOLDER git config --global user.name "USERNAME_PLACEHOLDER"
sudo -u USERNAME_PLACEHOLDER git config --global user.email "USERNAME_PLACEHOLDER@localhost"

# Ajout de fastfetch au bashrc
echo "fastfetch" >> $USER_HOME/.bashrc

# Installation thème SDDM Sugar Candy
cd /tmp
git clone https://github.com/Kangie/sddm-sugar-candy.git
sudo cp -r sddm-sugar-candy /usr/share/sddm/themes/sugar-candy

ADV_EOF

    sed -i "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/advanced_setup.sh
    arch-chroot /mnt bash /advanced_setup.sh
    rm /mnt/advanced_setup.sh
}

# ================================================================
# FINALISATION
# ================================================================

finalize_installation() {
    log_info "Finalisation de l'installation..."
    
    # Nettoyage
    arch-chroot /mnt pacman -Scc --noconfirm
    
    # Création du script de post-installation
    cat > /mnt/home/$USERNAME/post_install.sh << 'POST_EOF'
#!/bin/bash

echo "=== Post-Installation Script ==="
echo "Commandes utiles:"
echo ""
echo "# Changer le thème GRUB:"
echo "sudo sed -i 's|fallout|THEME_NAME|' /etc/default/grub"
echo "sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
echo "# Thèmes GRUB disponibles dans /boot/grub/themes/:"
ls /boot/grub/themes/ 2>/dev/null || echo "Pas encore installés"
echo ""
echo "# Démarrer cava (visualiseur audio):"
echo "cava"
echo ""
echo "# Configurer Spicetify:"
echo "spicetify config current_theme Dribbblish"
echo "spicetify config color_scheme nord"
echo "spicetify apply"
echo ""
echo "# Lancer Hyprland:"
echo "Hyprland"
echo ""
echo "=== Installation terminée! ==="

POST_EOF

    chmod +x /mnt/home/$USERNAME/post_install.sh
    chown $USERNAME:$USERNAME /mnt/home/$USERNAME/post_install.sh
    
    log_success "Installation terminée avec succès!"
    log_info "Redémarrez votre système et connectez-vous"
    log_info "Exécutez ~/post_install.sh pour les étapes finales"
}

# ================================================================
# FONCTION PRINCIPALE
# ================================================================

main() {
    print_logo
    
    # Vérification des privilèges root
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Vérification de la connexion internet
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Pas de connexion internet"
        exit 1
    fi
    
    log_info "Début de l'installation Arch Linux + Hyprland"
    
    # Étapes d'installation
    get_user_input
    prepare_system
    setup_partitions
    install_base_system
    configure_chroot
    install_grub_themes
    install_hyprland
    configure_hyprland
    install_applications
    setup_advanced_config
    finalize_installation
    
    echo ""
    log_success "🎉 INSTALLATION TERMINÉE! 🎉"
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           PROCHAINES ÉTAPES          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════╝${NC}"
    echo -e "${CYAN}1. Redémarrez: ${YELLOW}reboot${NC}"
    echo -e "${CYAN}2. Connectez-vous avec votre utilisateur${NC}"
    echo -e "${CYAN}3. Lancez Hyprland: ${YELLOW}Hyprland${NC}"
    echo -e "${CYAN}4. Exécutez: ${YELLOW}~/post_install.sh${NC}"
    echo ""
    echo -e "${GREEN}Thème: Gaming/Dev/Arcane configuré!${NC}"
    echo ""
}

# Exécution du script principal
main "$@"
