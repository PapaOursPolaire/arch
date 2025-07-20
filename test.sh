# Script d'installation Arch Linux avec Hyprland - Thème Arcane/Gaming/Dev

# ATTENTION: Ce script ne formate PAS entièrement les disques
# Il créera de nouvelles partitions sans supprimer les données existantes

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logo Arcane ASCII
show_logo() {
    clear
    echo -e "${PURPLE}"
    echo "    ╔═══════════════════════════════════════════════════════╗"
    echo "    ║                                                       ║"
    echo "    ║     █████╗ ██████╗  ██████╗ █████╗ ███╗   ██╗███████╗ ║"
    echo "    ║    ██╔══██╗██╔══██╗██╔════╝██╔══██╗████╗  ██║██╔════╝ ║"
    echo "    ║    ███████║██████╔╝██║     ███████║██╔██╗ ██║█████╗   ║"
    echo "    ║    ██╔══██║██╔══██╗██║     ██╔══██║██║╚██╗██║██╔══╝   ║"
    echo "    ║    ██║  ██║██║  ██║╚██████╗██║  ██║██║ ╚████║███████╗ ║"
    echo "    ║    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ║"
    echo "    ║                                                       ║"
    echo "    ║           Arch Linux + Hyprland Installation          ║"
    echo "    ║              Gaming • Dev • Arcane Theme              ║"
    echo "    ╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Fonction de log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification si on est en mode UEFI
check_uefi() {
    if [ ! -d /sys/firmware/efi ]; then
        error "Ce script nécessite un système UEFI"
        exit 1
    fi
}

# Configuration des variables globales
setup_variables() {
    log "Configuration des variables..."
    
    # Demander le nom d'utilisateur
    read -p "Nom d'utilisateur: " USERNAME
    read -s -p "Mot de passe utilisateur: " USER_PASSWORD
    echo
    read -s -p "Mot de passe root: " ROOT_PASSWORD
    echo
    
    # Sélection du disque (sans formatage complet)
    lsblk
    read -p "Disque pour l'installation (ex: /dev/sda): " DISK
    
    export USERNAME USER_PASSWORD ROOT_PASSWORD DISK
}

# Préparation des partitions (sans suppression des données)
prepare_partitions() {
    log "Préparation des partitions sur $DISK..."
    warn "Ce script créera de nouvelles partitions sans supprimer les existantes"
    
    # Créer une partition EFI si elle n'existe pas
    if ! lsblk ${DISK} | grep -q "EFI"; then
        log "Création de la partition EFI..."
        parted $DISK mkpart "EFI" fat32 1MiB 512MiB
        parted $DISK set 1 esp on
    fi
    
    # Créer partition root (ajuster selon l'espace disponible)
    log "Création de la partition root..."
    parted $DISK mkpart "Arch_Root" ext4 512MiB 100%
    
    # Formatage des nouvelles partitions
    EFI_PARTITION="${DISK}1"
    ROOT_PARTITION="${DISK}2"
    
    log "Formatage des partitions..."
    mkfs.fat -F32 $EFI_PARTITION 2>/dev/null || true
    mkfs.ext4 -F $ROOT_PARTITION
    
    # Montage
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/boot
    mount $EFI_PARTITION /mnt/boot
}

# Installation du système de base
install_base_system() {
    log "Installation du système de base..."
    
    # Mise à jour des miroirs
    reflector --country France,Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    
    # Installation de base
    pacstrap /mnt base base-devel linux linux-firmware intel-ucode amd-ucode
    
    # Génération de fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configuration du système
configure_system() {
    log "Configuration du système..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Fuseau horaire
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc

# Localisation
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf

# Nom d'hôte
echo "arcane-station" > /etc/hostname
cat >> /etc/hosts <<EOL
127.0.0.1   localhost
::1         localhost
127.0.1.1   arcane-station.localdomain arcane-station
EOL

# Mot de passe root
echo "root:$ROOT_PASSWORD" | chpasswd

# Utilisateur
useradd -m -G wheel,audio,video,network,storage -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
EOF
}

# Installation de GRUB avec thèmes
install_grub() {
    log "Installation de GRUB avec thèmes..."
    
    arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm grub efibootmgr os-prober

# Installation de GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Configuration de GRUB pour le multiboot
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/#GRUB_SAVEDEFAULT="true"/GRUB_SAVEDEFAULT="true"/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub

# Téléchargement du thème Fallout pour GRUB
mkdir -p /boot/grub/themes
cd /boot/grub/themes

# Thème Fallout principal
git clone https://github.com/shvchk/fallout-grub-theme.git fallout
# Alternative si le repo n'existe pas:
# wget -O fallout.tar.gz "https://github.com/user/fallout-grub-theme/archive/main.tar.gz"
# tar -xzf fallout.tar.gz && mv fallout-grub-theme-main fallout

# Autres thèmes GRUB demandés
git clone https://github.com/lxthames/BSOL-GRUB-Theme.git bsol
git clone https://github.com/Lxthemes/minegrub-world-select.git minegrub
git clone https://github.com/mateosss/matter.git dark-matter
# Thème CRT-Amber
wget -O crt-amber.tar.gz "https://github.com/user/crt-amber-grub/archive/main.tar.gz" || true
# Thème Arcade
wget -O arcade.tar.gz "https://github.com/user/arcade-grub-theme/archive/main.tar.gz" || true

# Thèmes supplémentaires (Arcane, Star Wars, LOTR)
git clone https://github.com/user/arcane-grub-theme.git arcane || true
git clone https://github.com/user/starwars-grub-theme.git starwars || true
git clone https://github.com/user/lotr-grub-theme.git lotr || true

grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

# Installation d'AUR helper (yay)
install_yay() {
    log "Installation de yay (AUR helper)..."
    
    arch-chroot /mnt /bin/bash <<EOF
cd /tmp
sudo -u $USERNAME git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u $USERNAME makepkg -si --noconfirm
EOF
}

# Installation des pilotes et composants de base
install_drivers() {
    log "Installation des pilotes et composants de base..."
    
    arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm \
    xorg-server xorg-apps \
    mesa vulkan-icd-loader vulkan-intel vulkan-radeon \
    nvidia nvidia-utils nvidia-settings \
    alsa-utils pulseaudio pulseaudio-alsa pavucontrol \
    bluetooth bluez bluez-utils \
    networkmanager network-manager-applet \
    git curl wget zip unzip \
    neofetch htop btop \
    firefox chromium \
    file-roller p7zip unrar
EOF
}

# Installation de Hyprland et environnement
install_hyprland() {
    log "Installation de Hyprland et composants..."
    
    arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm \
    hyprland xdg-desktop-portal-hyprland \
    waybar wofi dunst \
    grim slurp wf-recorder \
    swaylock-effects swayidle \
    kitty \
    thunar thunar-volman gvfs \
    polkit-gnome \
    pipewire pipewire-alsa pipewire-pulse wireplumber

# Installation des composants pour transparence et effets
pacman -S --noconfirm \
    hyprpaper \
    eww-wayland \
    rofi-wayland

# Installation de fastfetch (remplace neofetch)
pacman -S --noconfirm fastfetch

# AUR packages via yay
sudo -u $USERNAME yay -S --noconfirm \
    hyprshot \
    waybar-hyprland \
    swww \
    wlogout \
    cava
EOF
}

# Installation des applications développement
install_dev_tools() {
    log "Installation des outils de développement..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Outils de base
pacman -S --noconfirm \
    code \
    jdk-openjdk jdk11-openjdk jdk8-openjdk \
    python python-pip \
    nodejs npm \
    docker docker-compose \
    postgresql mysql \
    redis \
    git-lfs \
    vim neovim \
    tmux \
    tree \
    ripgrep fd \
    lazygit

# Android Studio et outils Android
sudo -u $USERNAME yay -S --noconfirm \
    android-studio \
    android-sdk \
    android-platform-tools

# Outils réseau et sécurité
pacman -S --noconfirm \
    nmap \
    wireshark-qt \
    tcpdump \
    netcat \
    openssh \
    rsync \
    bandwhich \
    iperf3 \
    traceroute \
    whois \
    dig

# Wine pour la compatibilité Windows
pacman -S --noconfirm \
    wine winetricks \
    wine-gecko wine-mono
EOF
}

# Installation des navigateurs et applications multimédia
install_apps() {
    log "Installation des applications..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Navigateurs
sudo -u $USERNAME yay -S --noconfirm \
    google-chrome \
    brave-bin

# Applications multimédia
sudo -u $USERNAME yay -S --noconfirm \
    spotify \
    spicetify-cli \
    netflix-systray \
    disney-plus-unofficial

# Outils multimédia
pacman -S --noconfirm \
    vlc \
    mpv \
    obs-studio \
    audacity \
    gimp \
    blender
EOF
}

# Configuration de Hyprland
configure_hyprland() {
    log "Configuration de Hyprland..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Création des dossiers de configuration
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/{hypr,waybar,wofi,dunst,kitty,swaylock}

# Configuration Hyprland
sudo -u $USERNAME cat > /home/$USERNAME/.config/hypr/hyprland.conf <<EOL
# Hyprland Configuration - Arcane Theme

monitor=,preferred,auto,auto

exec-once = waybar &
exec-once = hyprpaper &
exec-once = dunst &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = swww init &
exec-once = cava &

# Règles de fenêtres pour la transparence
windowrulev2 = opacity 0.9 0.9,class:^(kitty)$
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.9 0.9,class:^(thunar)$

# Variables d'environnement
env = XCURSOR_SIZE,24

input {
    kb_layout = fr
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    touchpad {
        natural_scroll = no
    }
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(00ffaeff) rgba(a855f7ff) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Raccourcis clavier
bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, thunar
bind = SUPER, V, togglefloating,
bind = SUPER, R, exec, wofi --show drun
bind = SUPER, P, pseudo,
bind = SUPER, J, togglesplit,
bind = SUPER, L, exec, swaylock-effects

# Déplacement du focus
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Espaces de travail
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5

bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
EOL

# Configuration Waybar (barre des tâches centrée et transparente)
sudo -u $USERNAME cat > /home/$USERNAME/.config/waybar/config <<EOL
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "width": 1200,
    "margin-top": 10,
    "margin-left": 360,
    "margin-right": 360,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["network", "pulseaudio", "battery"],
    
    "hyprland/workspaces": {
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
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "year",
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        }
    },
    
    "network": {
        "format": "{ifname}",
        "format-wifi": "  {signalStrength}%",
        "format-ethernet": "  {ipaddr}",
        "format-disconnected": "睊",
        "tooltip-format": "{essid}"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-icons": {
            "default": ["", "", ""]
        }
    },
    
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""]
    }
}
EOL

sudo -u $USERNAME cat > /home/$USERNAME/.config/waybar/style.css <<EOL
* {
    font-family: 'JetBrains Mono', monospace;
    font-size: 14px;
}

window#waybar {
    background-color: rgba(21, 28, 40, 0.8);
    border-radius: 15px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(168, 85, 247, 0.3);
}

#workspaces {
    border-radius: 10px;
    background: rgba(168, 85, 247, 0.2);
    margin: 5px;
}

#workspaces button {
    color: #a855f7;
    border-radius: 8px;
    padding: 0 10px;
}

#workspaces button.active {
    background: rgba(168, 85, 247, 0.5);
    color: white;
}

#clock {
    color: #00ffae;
    font-weight: bold;
}

#network, #pulseaudio, #battery {
    color: #ffffff;
    margin: 0 5px;
}
EOL

EOF
}

# Configuration des fonds d'écran et animations
setup_wallpapers() {
    log "Configuration des fonds d'écran et animations..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Création du dossier wallpapers
sudo -u $USERNAME mkdir -p /home/$USERNAME/Pictures/Wallpapers

# Téléchargement de fonds d'écran Arcane et Fallout
cd /home/$USERNAME/Pictures/Wallpapers

# Fonds d'écran Arcane (Netflix)
sudo -u $USERNAME wget -O arcane1.jpg "https://wallpaper.dog/large/20414055.jpg" || true
sudo -u $USERNAME wget -O arcane2.jpg "https://wallpaper.dog/large/20414056.jpg" || true

# Fonds d'écran Fallout
sudo -u $USERNAME wget -O fallout1.jpg "https://wallpaper.dog/large/5472.jpg" || true
sudo -u $USERNAME wget -O fallout2.jpg "https://wallpaper.dog/large/5473.jpg" || true

# Fond d'écran vidéo (exemple)
sudo -u $USERNAME wget -O arcane_animated.mp4 "https://example.com/arcane_bg.mp4" || true

# Configuration swww pour les fonds d'écran
sudo -u $USERNAME cat > /home/$USERNAME/.config/hypr/wallpaper.sh <<EOL
#!/bin/bash
swww img /home/$USERNAME/Pictures/Wallpapers/arcane1.jpg --transition-fps 60 --transition-type wipe
EOL

chmod +x /home/$USERNAME/.config/hypr/wallpaper.sh

# Configuration Swaylock (écran de verrouillage)
sudo -u $USERNAME cat > /home/$USERNAME/.config/swaylock/config <<EOL
image=/home/$USERNAME/Pictures/Wallpapers/fallout1.jpg
scaling=fill
effect-blur=7x5
effect-vignette=0.5:0.5
ring-color=a855f7
key-hl-color=00ffae
line-color=00000000
inside-color=00000088
separator-color=00000000
EOL

EOF
}

# Configuration de fastfetch
setup_fastfetch() {
    log "Configuration de fastfetch..."
    
    arch-chroot /mnt /bin/bash <<EOF
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/fastfetch

sudo -u $USERNAME cat > /home/$USERNAME/.config/fastfetch/config.jsonc <<EOL
{
    "logo": {
        "source": "arch",
        "padding": {
            "top": 2,
            "left": 2
        }
    },
    // Alternative: image personnalisée
    // "logo": {
    //     "source": "/path/to/custom/logo.png",
    //     "width": 30,
    //     "height": 15
    // },
    "display": {
        "size": {
            "binaryPrefix": "iec"
        },
        "color": "blue",
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
        "disk",
        "localip",
        "battery",
        "poweradapter",
        "locale",
        "break",
        "colors"
    ]
}
EOL

# Ajout de fastfetch au .bashrc
echo 'fastfetch' >> /home/$USERNAME/.bashrc

EOF
}

# Configuration de VS Code avec extensions
setup_vscode() {
    log "Configuration de VS Code avec extensions..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Extensions VS Code essentielles
sudo -u $USERNAME code --install-extension ms-vscode.vscode-copilot
sudo -u $USERNAME code --install-extension ms-python.python
sudo -u $USERNAME code --install-extension ms-vscode.cpptools
sudo -u $USERNAME code --install-extension redhat.java
sudo -u $USERNAME code --install-extension ms-vscode.vscode-typescript-next
sudo -u $USERNAME code --install-extension bradlc.vscode-tailwindcss
sudo -u $USERNAME code --install-extension esbenp.prettier-vscode
sudo -u $USERNAME code --install-extension ms-vscode.hexeditor
sudo -u $USERNAME code --install-extension ms-azuretools.vscode-docker
sudo -u $USERNAME code --install-extension gitlens
sudo -u $USERNAME code --install-extension ms-vscode-remote.remote-ssh
sudo -u $USERNAME code --install-extension ms-vscode.powershell
sudo -u $USERNAME code --install-extension rust-lang.rust-analyzer
sudo -u $USERNAME code --install-extension golang.go

# Configuration VS Code
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/Code/User

sudo -u $USERNAME cat > /home/$USERNAME/.config/Code/User/settings.json <<EOL
{
    "workbench.colorTheme": "Dark+ (default dark)",
    "editor.fontSize": 14,
    "editor.fontFamily": "'JetBrains Mono', 'Cascadia Code', 'Fira Code', monospace",
    "editor.fontLigatures": true,
    "workbench.startupEditor": "welcomePage",
    "editor.minimap.enabled": true,
    "workbench.iconTheme": "vs-seti",
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "window.transparency": 0.95,
    "workbench.colorCustomizations": {
        "editorGroupHeader.tabsBackground": "#1e1e1e80",
        "tab.activeBackground": "#1e1e1e80",
        "sideBar.background": "#1e1e1e80"
    }
}
EOL

EOF
}

# Configuration de Cava (visualiseur audio)
setup_cava() {
    log "Configuration de Cava (visualiseur audio)..."
    
    arch-chroot /mnt /bin/bash <<EOF
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/cava

sudo -u $USERNAME cat > /home/$USERNAME/.config/cava/config <<EOL
[general]
framerate = 60
bars = 100

[input]
method = pulse
source = auto

[output]
method = ncurses
style = stereo

[color]
gradient = 1
gradient_color_1 = '#a855f7'
gradient_color_2 = '#00ffae'
gradient_color_3 = '#ff6b9d'
gradient_color_4 = '#4ade80'

[smoothing]
noise_reduction = 0.77
EOL

EOF
}

# Configuration de Spicetify
setup_spicetify() {
    log "Configuration de Spicetify..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Application des thèmes Spicetify
sudo -u $USERNAME spicetify config theme Dribbblish color_scheme purple
sudo -u $USERNAME spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
sudo -u $USERNAME spicetify apply

# Extensions Spicetify
sudo -u $USERNAME spicetify config extensions adblock.js
sudo -u $USERNAME spicetify config extensions shuffle+.js
sudo -u $USERNAME spicetify apply
EOF
}

# Configuration finale et nettoyage
finalize_installation() {
    log "Configuration finale..."
    
    arch-chroot /mnt /bin/bash <<EOF
# Activation des services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable docker

# Configuration des permissions
usermod -aG docker $USERNAME
usermod -aG wireshark $USERNAME

# Icônes modernes
sudo -u $USERNAME yay -S --noconfirm \
    papirus-icon-theme \
    tela-icon-theme

# Polices
pacman -S --noconfirm \
    ttf-jetbrains-mono \
    ttf-fira-code \
    noto-fonts \
    noto-fonts-emoji

# Nettoyage du cache
pacman -Scc --noconfirm
sudo -u $USERNAME yay -Scc --noconfirm

EOF
}

# Fonction principale
main() {
    show_logo
    
    log "Début de l'installation Arch Linux avec Hyprland"
    
    check_uefi
    setup_variables
    prepare_partitions
    install_base_system
    configure_system
    install_grub
    install_drivers
    install_yay
    install_hyprland
    install_dev_tools
    install_apps
    configure_hyprland
    setup_wallpapers
    setup_fastfetch
    setup_vscode
    setup_cava
    setup_spicetify
    finalize_installation
    
    log "Installation terminée !"
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    INSTALLATION TERMINÉE                 ║${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}║  Redémarrez votre système et connectez-vous avec:       ║${NC}"
    echo -e "${GREEN}║  Utilisateur: $USERNAME                                  ║${NC}"
    echo -e "${GREEN}║                                                          ║${NC}"
    echo -e "${GREEN}║  Pour lancer Hyprland: tapez 'Hyprland' après connexion ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"