#!/bin/bash

# Script d'installation d'Hyprland compatible sur plusieurs distros Linux
# Version 235.7 - 27/08/2025 14:26 : Mise à jour corrigée avec détection GPU/CPU et améliorations
# Compatible: Arch, Ubuntu/Debian, Fedora, OpenSUSE

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
DISTRO=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
REMOVE_CMD=""
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"
GPU_TYPE=""
CPU_TYPE=""

# Fonctions de détection
print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗ 
██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ 

EOF
    echo -e "${NC}"
    echo -e "${CYAN}Installation complète de Hyprland avec thème personnalisé${NC}"
    echo -e "${YELLOW}Compatible: Arch, Ubuntu, Debian, Fedora & OpenSUSE${NC}"
    echo ""
}

detect_hardware() {
    echo -e "${BLUE}Détection du matériel...${NC}"
    
    # Détection GPU
    if lspci | grep -i nvidia > /dev/null 2>&1; then
        GPU_TYPE="nvidia"
        echo -e "${GREEN}GPU NVIDIA détecté${NC}"
    elif lspci | grep -i amd > /dev/null 2>&1; then
        GPU_TYPE="amd"
        echo -e "${GREEN}GPU AMD détecté${NC}"
    elif lspci | grep -i intel > /dev/null 2>&1; then
        GPU_TYPE="intel"
        echo -e "${GREEN}GPU Intel détecté${NC}"
    else
        GPU_TYPE="unknown"
        echo -e "${YELLOW}GPU non détecté ou générique${NC}"
    fi
    
    # Détection CPU
    if grep -i "AuthenticAMD" /proc/cpuinfo > /dev/null 2>&1; then
        CPU_TYPE="amd"
        echo -e "${GREEN}CPU AMD détecté${NC}"
    elif grep -i "GenuineIntel" /proc/cpuinfo > /dev/null 2>&1; then
        CPU_TYPE="intel"
        echo -e "${GREEN}CPU Intel détecté${NC}"
    else
        CPU_TYPE="unknown"
        echo -e "${YELLOW}CPU non détecté ou générique${NC}"
    fi
}

detect_distro() {
    echo -e "${BLUE}Détection de la distribution...${NC}"
    
    if [ -f /etc/arch-release ]; then
        DISTRO="arch"
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
        UPDATE_CMD="pacman -Syu --noconfirm"
        REMOVE_CMD="pacman -Rns --noconfirm"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="apt install -y"
        UPDATE_CMD="apt update && apt upgrade -y"
        REMOVE_CMD="apt purge -y"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
        PACKAGE_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD="dnf update -y"
        REMOVE_CMD="dnf remove -y"
    elif [ -f /etc/opensuse-release ]; then
        DISTRO="opensuse"
        PACKAGE_MANAGER="zypper"
        INSTALL_CMD="zypper install -y"
        UPDATE_CMD="zypper update -y"
        REMOVE_CMD="zypper remove -y"
    else
        echo -e "${RED}Distribution non supportée${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Détecté: $DISTRO ($PACKAGE_MANAGER)${NC}"
}

install_yay() {
    case "$DISTRO" in 
        arch)
            echo "Installation de yay (AUR helper)..."
            sudo pacman -S --needed --noconfirm git base-devel
            if ! command -v yay &> /dev/null; then
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay || exit
                makepkg -si --noconfirm
                cd - || exit
            else
                echo "yay déjà installé"
            fi
            ;;
        debian|ubuntu)
            echo "yay est un outil spécifique à Arch Linux (AUR)."
            echo "Vous pouvez utiliser apt/aptitude à la place."
            ;;
        fedora)
            echo "yay est un outil spécifique à Arch Linux (AUR)."
            echo "Vous pouvez utiliser dnf ou rpm-ostree selon vos besoins."
            ;;
        *)
            echo "Distribution non supportée pour yay."
            ;;
    esac
}

install_gpu_drivers() {
    echo -e "${BLUE}Installation des pilotes GPU...${NC}"
    
    case $DISTRO in
        "arch")
            case $GPU_TYPE in
                "nvidia")
                    sudo $INSTALL_CMD nvidia nvidia-utils nvidia-settings
                    ;;
                "amd")
                    sudo $INSTALL_CMD xf86-video-amdgpu mesa vulkan-radeon
                    ;;
                "intel")
                    sudo $INSTALL_CMD xf86-video-intel mesa vulkan-intel
                    ;;
            esac
            ;;
        "debian")
            case $GPU_TYPE in
                "nvidia")
                    sudo $INSTALL_CMD nvidia-driver nvidia-settings
                    ;;
                "amd")
                    sudo $INSTALL_CMD xserver-xorg-video-amdgpu mesa-vulkan-drivers
                    ;;
                "intel")
                    sudo $INSTALL_CMD xserver-xorg-video-intel mesa-vulkan-drivers
                    ;;
            esac
            ;;
        "fedora")
            case $GPU_TYPE in
                "nvidia")
                    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
                    ;;
                "amd")
                    sudo $INSTALL_CMD xorg-x11-drv-amdgpu mesa-vulkan-drivers
                    ;;
                "intel")
                    sudo $INSTALL_CMD xorg-x11-drv-intel mesa-vulkan-drivers
                    ;;
            esac
            ;;
        "opensuse")
            case $GPU_TYPE in
                "nvidia")
                    sudo $INSTALL_CMD nvidia-glG05 nvidia-computeG05
                    ;;
                "amd")
                    sudo $INSTALL_CMD xf86-video-amdgpu Mesa-vulkan-device-select
                    ;;
                "intel")
                    sudo $INSTALL_CMD xf86-video-intel Mesa-vulkan-device-select
                    ;;
            esac
            ;;
    esac
}

clean_bashrc() {
    echo -e "${BLUE}Nettoyage du .bashrc...${NC}"
    sed -i '/Hyprland/d' ~/.bashrc
    sed -i '/hyprland/d' ~/.bashrc
    echo -e "${GREEN}Ancien contenu Hyprland supprimé du .bashrc${NC}"
}

create_wayland_desktop_file() {
    echo -e "${BLUE}Création du fichier desktop Hyprland...${NC}"
    
    sudo mkdir -p /usr/share/wayland-sessions
    
    cat > /tmp/Hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    
    sudo mv /tmp/Hyprland.desktop /usr/share/wayland-sessions/
    echo -e "${GREEN}Fichier Hyprland.desktop créé${NC}"
}

install_nerd_fonts() {
    echo -e "${BLUE}Installation de JetBrainsMono Nerd Font...${NC}"
    
    FONT_DIR="$USER_HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    # Vérification si JetBrainsMono est déjà installée
    if fc-list | grep -i "JetBrainsMono" > /dev/null 2>&1; then
        echo -e "${YELLOW}JetBrainsMono Nerd Font déjà installée, pas de téléchargement${NC}"
        return 0
    fi
    
    # Téléchargement JetBrainsMono Nerd Font
    echo -e "${BLUE}Téléchargement de JetBrainsMono Nerd Font...${NC}"
    cd /tmp
    if wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
        unzip -q JetBrainsMono.zip -d JetBrainsMono
        cp JetBrainsMono/*.ttf "$FONT_DIR/" 2>/dev/null || true
        
        # Mise à jour du cache des polices
        fc-cache -fv > /dev/null 2>&1
        
        echo -e "${GREEN}JetBrainsMono Nerd Font installée${NC}"
    else
        echo -e "${YELLOW}Erreur de téléchargement, utilisation des polices système${NC}"
    fi
}

install_icon_themes() {
    echo -e "${BLUE}Installation des thèmes d'icônes...${NC}"
    
    case $DISTRO in
        "arch")
            # Utilisation de yay pour Papirus et Tela
            yay -S --noconfirm papirus-icon-theme tela-icon-theme || true
            ;;
        "debian"|"fedora"|"opensuse")
            # Papirus depuis les dépôts
            sudo $INSTALL_CMD -y papirus-icon-theme || true

            # Installation manuelle de Tela sans exécuter install.sh
            TMPDIR=$(mktemp -d)
            git clone https://github.com/vinceliuice/Tela-icon-theme.git "$TMPDIR/Tela-icon-theme" || true
            if [ -d "$TMPDIR/Tela-icon-theme" ]; then
                sudo mkdir -p /usr/share/icons
                sudo cp -r "$TMPDIR/Tela-icon-theme"/{Tela*,src} /usr/share/icons/ 2>/dev/null || true
                echo "Tela-icon-theme installé (copie manuelle)"
            fi
            rm -rf "$TMPDIR"
            ;;
        *)
            echo "Distribution non supportée pour l'installation des thèmes d'icônes"
            ;;
    esac

    # Mise à jour du cache d'icônes (sécurisée, ne bloque jamais)
    if command -v gtk-update-icon-cache &>/dev/null; then
        echo "Mise à jour du cache d'icônes..."
        for dir in /usr/share/icons/*; do
            if [ -d "$dir" ]; then
                sudo gtk-update-icon-cache -f -t "$dir" || true
            fi
        done
    else
        echo "gtk-update-icon-cache non trouvé, étape ignorée."
    fi
    
    echo -e "${GREEN}Thèmes d'icônes installés${NC}"
}

detect_current_de() {
    echo -e "${BLUE}Détection de l'environnement graphique actuel...${NC}"
    
    CURRENT_DE=""
    DE_PACKAGES_TO_REMOVE=""
    
    # Détection KDE
    if command -v plasmashell >/dev/null 2>&1 || [ -d "/usr/share/plasma" ]; then
        CURRENT_DE="KDE"
        case $DISTRO in
            "arch")
                DE_PACKAGES_TO_REMOVE="plasma plasma-desktop plasma-workspace kde-applications kdebase kdeplasma-addons"
                ;;
            "debian")
                DE_PACKAGES_TO_REMOVE="kde-full kde-standard kde-plasma-desktop plasma-desktop"
                ;;
            "fedora")
                DE_PACKAGES_TO_REMOVE="@kde-desktop kde-plasma-workspaces plasma-workspace"
                ;;
            "opensuse")
                DE_PACKAGES_TO_REMOVE="patterns-kde-kde_yast patterns-kde-kde4_basis plasma5-desktop"
                ;;
        esac
    fi
    
    # Détection GNOME
    if command -v gnome-shell >/dev/null 2>&1 || [ -d "/usr/share/gnome-shell" ]; then
        CURRENT_DE="GNOME"
        case $DISTRO in
            "arch")
                DE_PACKAGES_TO_REMOVE="gnome gnome-shell gnome-desktop gdm gnome-session"
                ;;
            "debian")
                DE_PACKAGES_TO_REMOVE="gnome-core gnome-desktop-environment gnome-shell gdm3"
                ;;
            "fedora")
                DE_PACKAGES_TO_REMOVE="@gnome-desktop gnome-shell gdm"
                ;;
            "opensuse")
                DE_PACKAGES_TO_REMOVE="patterns-gnome-gnome patterns-gnome-gnome_basis gnome-shell"
                ;;
        esac
    fi
    
    # Détection XFCE
    if command -v xfce4-session >/dev/null 2>&1 || [ -d "/usr/share/xfce4" ]; then
        CURRENT_DE="XFCE"
        case $DISTRO in
            "arch")
                DE_PACKAGES_TO_REMOVE="xfce4 xfce4-goodies"
                ;;
            "debian")
                DE_PACKAGES_TO_REMOVE="xfce4 xfce4-goodies"
                ;;
            "fedora")
                DE_PACKAGES_TO_REMOVE="@xfce-desktop xfce4-session"
                ;;
            "opensuse")
                DE_PACKAGES_TO_REMOVE="patterns-xfce-xfce patterns-xfce-xfce_basis"
                ;;
        esac
    fi
    
    # Détection LXQt
    if command -v lxqt-session >/dev/null 2>&1; then
        CURRENT_DE="LXQt"
        case $DISTRO in
            "arch")
                DE_PACKAGES_TO_REMOVE="lxqt lxqt-qtplugin"
                ;;
            "debian")
                DE_PACKAGES_TO_REMOVE="lxqt-core lxqt"
                ;;
            "fedora")
                DE_PACKAGES_TO_REMOVE="@lxqt-desktop lxqt-session"
                ;;
            "opensuse")
                DE_PACKAGES_TO_REMOVE="patterns-lxqt-lxqt"
                ;;
        esac
    fi
    
    if [ -n "$CURRENT_DE" ]; then
        echo -e "${YELLOW}Environnement détecté : $CURRENT_DE${NC}"
        echo -e "${YELLOW}Nous allons le désinstaller proprement${NC}"
    else
        echo -e "${GREEN}Aucun environnement graphique majeur détecté${NC}"
    fi
}

# Désinstallation propre de l'environnement graphique
remove_current_de() {
    echo -e "${BLUE}Suppression de l'environnement de bureau actuel...${NC}"

    case $DISTRO in
        "arch")
            echo "Suppression des environnements sur Arch"
            sudo pacman -Rns --noconfirm gnome gdm plasma-desktop sddm xfce4 lightdm || true
            ;;
        "debian"|"ubuntu")
            echo "Suppression des environnements sur Debian/Ubuntu"
            sudo apt purge -y gnome-shell gdm3 plasma-desktop sddm xfce4 lightdm || true
            sudo apt autoremove -y || true
            ;;
        "fedora")
            echo "Suppression des environnements sur Fedora"
            sudo dnf remove -y gnome-shell gdm plasma-desktop sddm xfce4 lightdm || true
            ;;
        "opensuse")
            echo "Suppression des environnements sur openSUSE"
            sudo zypper remove -y gnome-shell gdm plasma5-desktop sddm xfce4 lightdm || true
            ;;
        *)
            echo "Distribution non reconnue pour la suppression des environnements."
            ;;
    esac

    # Pas d'arrêt brutal des services en cours
    echo -e "${YELLOW}Les gestionnaires de sessions (gdm, sddm, lightdm) NE seront PAS stoppés maintenant.${NC}"
    echo -e "${YELLOW}Les changements prendront effet après un redémarrage.${NC}"
}

# Installation des dépendances manquantes
install_dependencies() {
    echo -e "${BLUE}Installation des dépendances essentielles...${NC}"
    
    case $DISTRO in
        "arch")
            DEPS="jq libnotify imagemagick"
            sudo $INSTALL_CMD $DEPS
            ;;
        "debian")
            DEPS="jq libnotify-bin imagemagick"
            sudo $INSTALL_CMD $DEPS
            ;;
        "fedora")
            DEPS="jq libnotify ImageMagick"
            sudo $INSTALL_CMD $DEPS
            ;;
        "opensuse")
            DEPS="jq libnotify-tools ImageMagick"
            sudo $INSTALL_CMD $DEPS
            ;;
    esac
    
    echo -e "${GREEN}Dépendances installées${NC}"
}

# Installation des paquets Hyprland
install_base_packages() {
    echo -e "${BLUE}Installation des paquets de base...${NC}"
    
    # Mise à jour du système
    if ! sudo $UPDATE_CMD; then
        echo "==> Impossible de mettre le système à jour, mais on continue..."
    fi
    
    case $DISTRO in
        "arch")
            # Installation de yay (AUR helper) si nécessaire
            if ! command -v yay >/dev/null 2>&1; then
                echo -e "${BLUE}Installation de yay (AUR helper)...${NC}"
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay && makepkg -si --noconfirm || echo "==> yay déjà installé ou erreur bénigne."
                cd -
            fi

            # Vérification et activation de multilib si non déjà activé
            if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                echo "==> Activation du dépôt multilib..."
                sudo bash -c 'echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf'
                sudo pacman -Sy || echo "==> Impossible de synchroniser pacman, on continue..."
            else
                echo "==> Dépôt multilib déjà activé, on passe."
            fi
            
            # Paquets Arch - remplacer wofi par rofi-wayland
            PACKAGES="hyprland hyprpaper hypridle hyprlock xdg-desktop-portal-hyprland polkit-gnome waybar rofi-wayland kitty thunar dunst sddm pipewire wireplumber pavucontrol cava fastfetch git curl wget unzip"
            sudo $INSTALL_CMD --needed $PACKAGES || echo "==> Paquets déjà installés ou rien à faire."

            # mpvpaper doit être installé via AUR
            yay -S --noconfirm --needed mpvpaper || echo "==> mpvpaper déjà installé ou rien à faire."

            # Paquets AUR supplémentaires
            yay -S --noconfirm --needed spicetify-cli || echo "==> spicetify-cli déjà installé ou rien à faire."
            ;;
            
        "debian")
            # Ajout des dépôts nécessaires pour Ubuntu/Debian
            if ! grep -q "ppa:hyprland" /etc/apt/sources.list.d/* 2>/dev/null; then
                sudo apt install -y software-properties-common || echo "==> software-properties-common déjà présent."
                sudo add-apt-repository ppa:hyprland/hyprland -y || echo "==> Dépôt Hyprland déjà ajouté."
                sudo apt update || echo "==> apt update a échoué, on continue."
            fi
            
            PACKAGES="hyprland waybar rofi kitty thunar dunst pipewire-pulse pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD --needed $PACKAGES || echo "==> Paquets Debian déjà installés ou rien à faire."
            
            # Installation manuelle pour les paquets non disponibles
            install_from_source_debian
            ;;
            
        "fedora")
            # Activation des dépôts RPM Fusion
            sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm || echo "==> RPM Fusion déjà activé."
            
            PACKAGES="hyprland waybar rofi kitty thunar dunst pipewire-pulseaudio pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD --needed $PACKAGES || echo "==> Paquets Fedora déjà installés ou rien à faire."
            
            install_from_source_fedora
            ;;
            
        "opensuse")
            PACKAGES="hyprland waybar rofi kitty thunar dunst pipewire-pulseaudio pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD --needed $PACKAGES || echo "==> Paquets openSUSE déjà installés ou rien à faire."
            
            install_from_source_opensuse
            ;;
    esac
}

install_from_source_debian() {
    echo -e "${BLUE}Installation depuis les sources (Debian/Ubuntu)...${NC}"
    
    cd /tmp
    
    # Dépendances de compilation
    sudo apt install -y build-essential cmake meson ninja-build pkg-config libwayland-dev libxkbcommon-dev
    
    # Hyprpaper
    git clone https://github.com/hyprwm/hyprpaper.git
    cd hyprpaper && make all && sudo make install && cd ..
    
    # Hypridle
    git clone https://github.com/hyprwm/hypridle.git
    cd hypridle && make all && sudo make install && cd ..
    
    # Hyprlock
    git clone https://github.com/hyprwm/hyprlock.git
    cd hyprlock && make all && sudo make install && cd ..
    
    # MPVPaper
    git clone https://github.com/GhostNaN/mpvpaper.git
    cd mpvpaper && meson build && ninja -C build && sudo ninja -C build install
}

install_from_source_fedora() {
    echo -e "${BLUE}Installation depuis les sources (Fedora)...${NC}"
    
    cd /tmp
    sudo dnf install -y gcc-c++ cmake meson ninja-build pkg-config wayland-devel libxkbcommon-devel
    
    install_hypr_tools_from_source
}

install_from_source_opensuse() {
    echo -e "${BLUE}Installation depuis les sources (OpenSUSE)...${NC}"
    
    cd /tmp
    sudo zypper install -y gcc-c++ cmake meson ninja pkg-config wayland-devel libxkbcommon-devel
    
    install_hypr_tools_from_source
}

install_hypr_tools_from_source() {
    git clone https://github.com/hyprwm/hyprpaper.git
    cd hyprpaper && make all && sudo make install && cd ..
    
    git clone https://github.com/hyprwm/hypridle.git
    cd hypridle && make all && sudo make install && cd ..
    
    git clone https://github.com/hyprwm/hyprlock.git
    cd hyprlock && make all && sudo make install && cd ..
    
    git clone https://github.com/GhostNaN/mpvpaper.git
    cd mpvpaper && meson build && ninja -C build && sudo ninja -C build install
}

# Configuration Hyprland avec améliorations visuelles
setup_hyprland_config() {
    echo -e "${BLUE}⚙️ Configuration de Hyprland...${NC}"
    
    mkdir -p "$CONFIG_DIR/hypr"
    
    cat > "$CONFIG_DIR/hypr/hyprland.conf" << 'EOF'
# Moniteur
monitor = ,preferred,auto,1

# Variables d'environnement
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct

# Exécution au démarrage
exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = ~/.config/hypr/video-wallpaper.sh

# Configuration d'entrée
input {
    kb_layout = fr
    follow_mouse = 1
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
    sensitivity = 0
}

# Apparence générale avec coins arrondis
general {
    gaps_in = 5
    gaps_out = 15
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    resize_on_border = false
    allow_tearing = false
    layout = dwindle
}

# Décoration avec blur et ombres douces
decoration {
    rounding = 12

    blur {
        enabled = true
        size = 3
        passes = 3
    }

    shadow {
        enabled = true
        range = 20
        render_power = 3
        color = rgba(1a1a1aee)
    }
}

# Animations fluides
animations {
    enabled = true
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    
    animation = windows, 1, 5, overshot, slide
    animation = windowsOut, 1, 4, smoothOut, slide
    animation = windowsMove, 1, 4, overshot
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, smoothIn
    animation = fadeDim, 1, 7, smoothIn
    animation = workspaces, 1, 6, overshot, slidevert
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
    smart_split = false
    smart_resizing = true
}

# Gestes
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 30
}

# Divers
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
    vfr = true
}

# Règles de fenêtres avec transparence
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.92 0.92,class:^(thunar)$
windowrulev2 = opacity 0.88 0.88,class:^(waybar)$
windowrulev2 = opacity 0.85 0.85,class:^(rofi)$

# Fenêtres flottantes
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(nm-connection-editor)$
windowrulev2 = float,class:^(thunar)$,title:^(.*Properties.*)$

# Règles pour les jeux (performance maximale)
windowrulev2 = immediate, class:^(steam_app_)(.*)$
windowrulev2 = immediate, class:^(lutris)$
windowrulev2 = immediate, class:^(heroic)$

# Plein écran sans bordures pour les jeux
windowrulev2 = noborder, class:^(steam_app_)(.*)$, fullscreen:1
windowrulev2 = noblur, class:^(steam_app_)(.*)$
windowrulev2 = noshadow, class:^(steam_app_)(.*)$

# Raccourcis clavier
$mainMod = SUPER

# Applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Système
bind = $mainMod, L, exec, hyprlock
bind = , Print, exec, ~/.local/bin/screenshot.sh area
bind = $mainMod, Print, exec, ~/.local/bin/screenshot.sh full

# Focus et déplacement
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces
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

# Déplacer vers workspace
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

# Workspace spécial
bind = $mainMod, S, togglespecialworkspace, magic
bind = $mainMod SHIFT, S, movetoworkspace, special:magic

# Souris
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Volume et luminosité
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF

    echo -e "${GREEN}Configuration Hyprland créée${NC}"
}

# Configuration Waybar avec transparence et Nerd Font
setup_waybar() {
    echo -e "${BLUE}Configuration de Waybar...${NC}"
    
    mkdir -p "$CONFIG_DIR/waybar"
    
    cat > "$CONFIG_DIR/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "spacing": 10,
    "margin-top": 5,
    "margin-left": 10,
    "margin-right": 10,
    
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["cpu", "memory", "temperature", "pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "active-only": false,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "󰲠",
            "2": "󰲢",
            "3": "󰲤",
            "4": "󰲦",
            "5": "󰲨",
            "6": "󰲪",
            "7": "󰲬",
            "8": "󰲮",
            "9": "󰲰",
            "10": "󰿬"
        },
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },

    "hyprland/window": {
        "format": "{}",
        "max-length": 50,
        "separate-outputs": true
    },

    "clock": {
        "format": " {:%H:%M}",
        "format-alt": " {:%A %d %B %Y - %H:%M:%S}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "year",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "weeks": "<span color='#99ffdd'><b>W{}</b></span>",
                "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        }
    },

    "cpu": {
        "format": " {usage}%",
        "tooltip": false,
        "interval": 2
    },

    "memory": {
        "format": " {}%",
        "tooltip-format": "RAM: {used:0.1f}G/{total:0.1f}G"
    },

    "temperature": {
        "thermal-zone": 2,
        "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        "critical-threshold": 80,
        "format-critical": " {temperatureC}°C",
        "format": " {temperatureC}°C"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },

    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": "󰈀 Câblé",
        "format-linked": "󰈀 Connecté (Sans IP)",
        "format-disconnected": "⚠ Déconnecté",
        "tooltip-format-wifi": "Adresse IP: {ipaddr}\nSignal: {signalStrength}%"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-bluetooth": "{icon} {volume}%",
        "format-muted": "󰝟",
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
    },

    "tray": {
        "spacing": 10
    }
}
EOF

    # Style CSS Waybar avec transparence avancée
    cat > "$CONFIG_DIR/waybar/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: 'JetBrainsMono Nerd Font', 'Font Awesome 6 Free';
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 46, 0.85);
    color: #cdd6f4;
    border-radius: 15px;
    border: 2px solid rgba(137, 180, 250, 0.3);
    margin: 0;
}

#workspaces {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 12px;
    padding: 8px 12px;
    margin: 5px 2px;
    color: #cdd6f4;
    transition: all 0.3s ease;
}

#workspaces button {
    padding: 5px 8px;
    margin: 0 2px;
    border-radius: 8px;
    color: #6c7086;
    transition: all 0.3s ease;
}

#workspaces button.active {
    background: rgba(137, 180, 250, 0.3);
    color: #89b4fa;
    box-shadow: 0 0 10px rgba(137, 180, 250, 0.2);
}

#workspaces button:hover {
    background: rgba(137, 180, 250, 0.1);
    color: #89b4fa;
}

#window {
    background: rgba(49, 50, 68, 0.6);
    border-radius: 10px;
    padding: 5px 15px;
    margin: 5px;
    color: #cdd6f4;
}

#clock {
    background: rgba(203, 166, 247, 0.2);
    border-radius: 10px;
    padding: 5px 15px;
    margin: 5px;
    color: #cba6f7;
    font-weight: bold;
}

#cpu, #memory, #temperature, #battery, #network, #pulseaudio {
    background: rgba(49, 50, 68, 0.6);
    border-radius: 8px;
    padding: 5px 12px;
    margin: 5px 2px;
    color: #cdd6f4;
    transition: all 0.3s ease;
}

#cpu {
    color: #f9e2af;
    border: 1px solid rgba(249, 226, 175, 0.3);
}

#memory {
    color: #a6e3a1;
    border: 1px solid rgba(166, 227, 161, 0.3);
}

#temperature {
    color: #f38ba8;
    border: 1px solid rgba(243, 139, 168, 0.3);
}

#temperature.critical {
    background: rgba(243, 139, 168, 0.3);
    color: #1e1e2e;
}

#battery {
    color: #94e2d5;
    border: 1px solid rgba(148, 226, 213, 0.3);
}

#battery.critical {
    color: #f38ba8;
    background: rgba(243, 139, 168, 0.1);
}

#battery.warning {
    color: #fab387;
    background: rgba(250, 179, 135, 0.1);
}

#battery.charging {
    color: #a6e3a1;
    background: rgba(166, 227, 161, 0.1);
}

#network {
    color: #89b4fa;
    border: 1px solid rgba(137, 180, 250, 0.3);
}

#pulseaudio {
    color: #f5c2e7;
    border: 1px solid rgba(245, 194, 231, 0.3);
}

#cpu:hover, #memory:hover, #temperature:hover,
#battery:hover, #network:hover, #pulseaudio:hover {
    background: rgba(137, 180, 250, 0.1);
    box-shadow: 0 0 10px rgba(137, 180, 250, 0.2);
    transform: translateY(-1px);
}

#tray {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 10px;
    padding: 5px;
    margin: 5px;
}

#tray > .passive > #idle_inhibitor {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: rgba(243, 139, 168, 0.2);
}
EOF

    echo -e "${GREEN}Configuration Waybar créée avec transparence et Nerd Fonts${NC}"
}

# Configuration Rofi (remplace Wofi)
setup_rofi() {
    echo -e "${BLUE}Configuration de Rofi...${NC}"
    
    mkdir -p "$CONFIG_DIR/rofi"
    
    cat > "$CONFIG_DIR/rofi/config.rasi" << 'EOF'
configuration {
    display-drun: "Applications";
    display-run: "Commands";
    display-window: "Windows";
    show-icons: true;
    icon-theme: "Papirus";
    font: "JetBrainsMono Nerd Font 12";
    modi: "drun,run,window";
    terminal: "kitty";
    drun-display-format: "{name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    sidebar-mode: false;
}

@theme "catppuccin-mocha"
EOF

    # Thème Catppuccin pour Rofi
    mkdir -p "$CONFIG_DIR/rofi/themes"
    cat > "$CONFIG_DIR/rofi/themes/catppuccin-mocha.rasi" << 'EOF'
* {
    bg-col:  #1e1e2e;
    bg-col-light: #313244;
    border-col: #89b4fa;
    selected-col: #89b4fa;
    blue: #89b4fa;
    fg-col: #cdd6f4;
    fg-col2: #f38ba8;
    grey: #6c7086;
    
    width: 600;
    font: "JetBrainsMono Nerd Font 14";
}

element-text, element-icon, mode-switcher {
    background-color: inherit;
    text-color: inherit;
}

window {
    height: 500px;
    border: 2px;
    border-color: @border-col;
    background-color: @bg-col;
    border-radius: 15px;
}

mainbox {
    background-color: @bg-col;
    border-radius: 15px;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col-light;
    border-radius: 8px;
    padding: 2px;
    margin: 10px;
}

prompt {
    background-color: @blue;
    padding: 6px;
    text-color: @bg-col;
    border-radius: 6px;
    margin: 20px 0px 0px 20px;
}

textbox-prompt-colon {
    expand: false;
    str: ":";
}

entry {
    padding: 6px;
    margin: 20px 0px 0px 10px;
    text-color: @fg-col;
    background-color: @bg-col-light;
}

listview {
    border: 0px 0px 0px;
    padding: 6px 0px 0px;
    margin: 10px 20px 0px 20px;
    columns: 1;
    lines: 8;
    background-color: @bg-col;
}

element {
    padding: 8px;
    background-color: @bg-col;
    text-color: @fg-col;
    border-radius: 8px;
}

element-icon {
    size: 25px;
}

element selected {
    background-color: @selected-col;
    text-color: @bg-col;
}

mode-switcher {
    spacing: 0;
}

button {
    padding: 10px;
    background-color: @bg-col-light;
    text-color: @grey;
    vertical-align: 0.5;
    horizontal-align: 0.5;
}

button selected {
    background-color: @bg-col;
    text-color: @blue;
}

message {
    background-color: @bg-col-light;
    margin: 2px;
    padding: 2px;
    border-radius: 5px;
}

textbox {
    padding: 6px;
    margin: 20px 0px 0px 20px;
    text-color: @blue;
    background-color: @bg-col-light;
}
EOF

    echo -e "${GREEN}Configuration Rofi créée${NC}"
}

# Configuration Hyprlock avec blur et avatar
setup_hyprlock() {
    echo -e "${BLUE}Configuration Hyprlock avec blur avancé...${NC}"
    
    mkdir -p "$CONFIG_DIR/hypr"
    
    cat > "$CONFIG_DIR/hypr/hyprlock.conf" << 'EOF'
general {
    disable_loading_bar = false
    grace = 2
    hide_cursor = false
    no_fade_in = false
    no_fade_out = false
    ignore_empty_input = false
    immediate_render = true
}

background {
    monitor =
    path = ~/.config/hypr/lockscreen.jpg
    blur_passes = 4
    blur_size = 12
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
    color = rgba(25, 20, 20, 1.0)
}

# Horloge principale
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%-H:%M")"
    color = rgba(255, 255, 255, 0.9)
    font_size = 120
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 200
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 5
    shadow_color = rgba(0, 0, 0, 0.5)
}

# Date
label {
    monitor =
    text = cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"
    color = rgba(255, 255, 255, 0.7)
    font_size = 24
    font_family = JetBrainsMono Nerd Font
    position = 0, 150
    halign = center
    valign = center
}

# Avatar utilisateur (si disponible)
image {
    monitor =
    path = ~/.face
    size = 120
    rounding = -1
    border_size = 4
    border_color = rgba(137, 180, 250, 0.8)
    position = 0, 50
    halign = center
    valign = center
}

# Message de connexion
label {
    monitor =
    text = Saisissez votre mot de passe
    color = rgba(137, 180, 250, 0.8)
    font_size = 18
    font_family = JetBrainsMono Nerd Font Bold
    position = 0, 30
    halign = center
    valign = center
}

# Nom d'utilisateur
label {
    monitor =
    text = $USER
    color = rgba(255, 255, 255, 0.6)
    font_size = 16
    font_family = JetBrainsMono Nerd Font
    position = 0, -20
    halign = center
    valign = center
}

# Champ de saisie mot de passe
input-field {
    monitor =
    size = 400, 60
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.64
    dots_center = true
    outer_color = rgba(137, 180, 250, 0.8)
    inner_color = rgba(30, 30, 46, 0.8)
    font_color = rgba(205, 214, 244, 1.0)
    fade_on_empty = false
    placeholder_text = <span foreground="##89b4fa">Mot de passe...</span>
    hide_input = false
    rounding = 12
    check_color = rgba(166, 227, 161, 0.8)
    fail_color = rgba(243, 139, 168, 0.8)
    fail_text = <i>Mot de passe incorrect</i>
    capslock_color = rgba(249, 226, 175, 0.8)
    position = 0, -120
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 3
    shadow_color = rgba(0, 0, 0, 0.3)
}

# Indicateur de Caps Lock
label {
    monitor =
    text = CAPS LOCK ACTIVÉ
    color = rgba(249, 226, 175, 0.8)
    font_size = 12
    font_family = JetBrainsMono Nerd Font
    position = 0, -200
    halign = center
    valign = center
}

# Informations système
label {
    monitor =
    text = cmd[update:5000] echo " $(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "AC")% | $(uptime -p | sed 's/up //')"
    color = rgba(255, 255, 255, 0.4)
    font_size = 12
    font_family = JetBrainsMono Nerd Font
    position = 20, -20
    halign = left
    valign = bottom
}
EOF

    echo -e "${GREEN}Configuration Hyprlock créée avec blur et thème cohérent${NC}"
}

setup_dunst() {
    echo -e "${BLUE}Configuration de Dunst avec thème Catppuccin...${NC}"

    # Vérification multilib (seulement pour Arch)
    if [ "$DISTRO" = "arch" ]; then
        if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
            echo "==> Activation du dépôt multilib..."
            sudo bash -c 'echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf'
            sudo pacman -Sy
        else
            echo "==> Dépôt multilib déjà activé, on passe."
        fi
    fi
    
    mkdir -p "$CONFIG_DIR/dunst"
    
    cat > "$CONFIG_DIR/dunst/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 350
    height = 300
    origin = top-right
    offset = 15x50
    scale = 0
    notification_limit = 5
    progress_bar = true
    progress_bar_height = 12
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    transparency = 15
    separator_height = 2
    padding = 20
    horizontal_padding = 20
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#89b4fa"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = JetBrainsMono Nerd Font 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    min_icon_size = 32
    max_icon_size = 64
    icon_path = /usr/share/icons/Papirus/16x16/status/:/usr/share/icons/Papirus/22x22/status/:/usr/share/icons/Papirus/32x32/status/:/usr/share/icons/Papirus/48x48/status/:/usr/share/icons/Papirus/scalable/status/
    sticky_history = yes
    history_length = 30
    dmenu = rofi -dmenu -p dunst: || /usr/bin/dmenu -p dunst:
    browser = /usr/bin/xdg-open
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 15
    ignore_dbusclose = false
    force_xinerama = false
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    highlight = "#89b4fa"
    timeout = 5

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    highlight = "#89b4fa"
    timeout = 10

[urgency_critical]
    background = "#f38ba8"
    foreground = "#1e1e2e"
    frame_color = "#f38ba8"
    timeout = 0
EOF

    echo -e "${GREEN}Configuration Dunst créée avec thème Catppuccin${NC}"
}

# Scripts de capture d'écran améliorés
setup_screenshot_tools() {
    echo -e "${BLUE}Installation des outils de capture...${NC}"
    
    case $DISTRO in
        "arch")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
        "debian")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
        "fedora")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
        "opensuse")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
    esac
    
    mkdir -p "$USER_HOME/.local/bin"
    
    cat > "$USER_HOME/.local/bin/screenshot.sh" << 'EOF'
#!/bin/bash

# Script de capture d'écran avancé pour Hyprland
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case "$1" in
    "area")
        # Capture de zone sélectionnée avec bordure colorée
        grim -g "$(slurp -d -c 89b4faff -b 1e1e2e88 -s 00000000)" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send -i camera-photo "Capture d'écran" "Zone sélectionnée sauvegardée" -t 2000
        ;;
    "window")
        # Capture de la fenêtre active
        hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send -i camera-photo "Capture d'écran" "Fenêtre active sauvegardée" -t 2000
        ;;
    "full"|*)
        # Capture plein écran
        grim "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send -i camera-photo "Capture d'écran" "Écran complet sauvegardé" -t 2000
        ;;
esac
EOF

    chmod +x "$USER_HOME/.local/bin/screenshot.sh"
    
    # Ajout au PATH si nécessaire
    if ! grep -q ".local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    
    echo -e "${GREEN}Outils de capture installés avec notifications${NC}"
}

# Arrière-plan vidéo amélioré
setup_video_wallpaper() {
    echo -e "${BLUE}Configuration du fond vidéo animé...${NC}"
    
    mkdir -p "$USER_HOME/.config/hypr/wallpapers"
    
    cat > "$CONFIG_DIR/hypr/video-wallpaper.sh" << 'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
FALLBACK_COLOR="#1e1e2e"

# Vérification du dossier
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
    echo "Dossier wallpapers créé. Placez vos vidéos .mp4 dans $WALLPAPER_DIR"
    exit 0
fi

# Recherche des vidéos MP4
videos=($(find "$WALLPAPER_DIR" -name "*.mp4" 2>/dev/null))

if [ ${#videos[@]} -eq 0 ]; then
    echo "Aucune vidéo trouvée dans $WALLPAPER_DIR"
    # Fond de couleur de secours
    hyprctl hyprpaper wallpaper ",color:$FALLBACK_COLOR" 2>/dev/null || true
else
    # Sélection aléatoire d'une vidéo
    selected_video=${videos[$RANDOM % ${#videos[@]}]}
    echo "Lecture de: $(basename "$selected_video")"
    
    # Arrêt de l'ancienne instance
    pkill -f mpvpaper 2>/dev/null || true
    sleep 1
    
    # Démarrage de la nouvelle vidéo avec optimisations
    mpvpaper -o "loop --no-audio --hwdec=auto --vo=gpu --profile=gpu-hq" '*' "$selected_video" &
    
    # Notification
    notify-send -i video-x-generic "Fond d'écran" "Lecture de $(basename "$selected_video")" -t 3000
fi
EOF

    chmod +x "$CONFIG_DIR/hypr/video-wallpaper.sh"
    
    # Configuration Hyprpaper pour le fallback
    cat > "$CONFIG_DIR/hypr/hyprpaper.conf" << EOF
preload = ~/.config/hypr/wallpapers/default.jpg
wallpaper = ,~/.config/hypr/wallpapers/default.jpg
ipc = on
splash = false
EOF

    echo -e "${GREEN}Configuration vidéo wallpaper créée${NC}"
}

# Check final des binaires
check_installation() {
    echo -e "${BLUE}Vérification finale de l'installation...${NC}"
    
    MISSING=""
    BINARIES=("hyprland" "waybar" "rofi" "kitty" "dunst" "hyprlock" "grim" "slurp")
    
    for binary in "${BINARIES[@]}"; do
        if ! command -v $binary >/dev/null 2>&1; then
            MISSING="$MISSING $binary"
        else
            echo -e "${GREEN}✓ $binary${NC}"
        fi
    done
    
    if [ -n "$MISSING" ]; then
        echo -e "${RED}Binaires manquants:$MISSING${NC}"
        return 1
    else
        echo -e "${GREEN}Tous les binaires sont présents${NC}"
        return 0
    fi
}

# Installation de Spicetify
setup_spicetify() {
    echo -e "${BLUE}Installation et configuration de Spicetify...${NC}"
    
    # Installation de Spotify si nécessaire
    if ! command -v spotify >/dev/null 2>&1; then
        case $DISTRO in
            "arch")
                if ! yay -S --noconfirm --needed spotify; then
                    echo "==> Spotify déjà installé ou erreur bénigne. On continue."
                fi
                ;;
            "debian")
                curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
                echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
                sudo apt update || echo "==> apt update échoué, on continue..."
                sudo apt install -y spotify-client || echo "==> Spotify déjà présent."
                ;;
            "fedora")
                sudo dnf config-manager --add-repo=https://negativo17.org/repos/fedora-spotify.repo || echo "==> Dépôt déjà présent."
                sudo dnf install -y spotify-client || echo "==> Spotify déjà présent."
                ;;
            "opensuse")
                sudo zypper addrepo -f https://download.spotify.com/repository/spotify.repo || echo "==> Dépôt déjà présent."
                sudo zypper install -y spotify-client || echo "==> Spotify déjà présent."
                ;;
        esac
    fi
    
    # Installation Spicetify
    if [ "$DISTRO" != "arch" ]; then
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
        export PATH="$HOME/.spicetify:$PATH"
        if ! grep -q 'spicetify' ~/.bashrc; then
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> ~/.bashrc
        fi
    else
        # Vérification pour Arch si spicetify est bien dispo dans le PATH
        if ! command -v spicetify >/dev/null 2>&1; then
            if [ -f /opt/spicetify-cli/spicetify ]; then
                sudo ln -sf /opt/spicetify-cli/spicetify /usr/local/bin/spicetify
                echo "==> spicetify ajouté à /usr/local/bin."
            else
                echo "==> spicetify introuvable après installation. Vérifiez manuellement."
            fi
        fi
    fi
    
    # Configuration Spicetify avec thème Catppuccin
    if command -v spicetify >/dev/null 2>&1; then
        spicetify config current_theme catppuccin color_scheme mocha
        spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1

        # Installation du thème Catppuccin
        curl -fsSL https://raw.githubusercontent.com/catppuccin/spicetify/main/install.sh | sh

        # Application des modifications
        spicetify backup apply || echo "==> Échec backup/apply, on continue..."
    else
        echo "==> spicetify n'a pas pu être configuré car la commande est introuvable."
    fi
    
    echo -e "${GREEN}Spicetify configuré avec le thème Catppuccin Mocha${NC}"
}

# Configuration de Kitty terminal
setup_kitty() {
    echo -e "${BLUE}Configuration de Kitty terminal...${NC}"
    
    mkdir -p "$CONFIG_DIR/kitty"
    
    cat > "$CONFIG_DIR/kitty/kitty.conf" << 'EOF'
# Police
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# Curseur
cursor_shape beam
cursor_blink_interval 0.5

# Scrolling
scrollback_lines 10000

# URLs
url_style curly
open_url_with default

# Performance
repaint_delay 10
input_delay 3

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Fenêtre
window_padding_width 15
background_opacity 0.90
dynamic_background_opacity yes
background_blur 20

# Thème Catppuccin Mocha
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Cursor
cursor #f5e0dc
cursor_text_color #1e1e2e

# URL
url_color #f5e0dc

# Border
active_border_color #b4befe
inactive_border_color #6c7086
bell_border_color #f9e2af

# Tab bar
active_tab_foreground #11111b
active_tab_background #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background #11111b

# Normal colors
color0 #45475a
color1 #f38ba8
color2 #a6e3a1
color3 #f9e2af
color4 #89b4fa
color5 #f5c2e7
color6 #94e2d5
color7 #bac2de

# Bright colors
color8 #585b70
color9 #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8

# Gestion des onglets
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab

# Zoom
map ctrl+shift+equal change_font_size all +1.0
map ctrl+shift+minus change_font_size all -1.0
map ctrl+shift+0 change_font_size all 0

# Copier/Coller
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
EOF

    echo -e "${GREEN}Configuration Kitty créée${NC}"
}

# Configuration Thunar
setup_thunar() {
    echo -e "${BLUE}Configuration de Thunar...${NC}"
    
    mkdir -p "$CONFIG_DIR/xfce4/xfconf/xfce-perchannel-xml"
    
    cat > "$CONFIG_DIR/xfce4/xfconf/xfce-perchannel-xml/thunar.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="thunar" version="1.0">
    <property name="default-view" type="string" value="ThunarIconView"/>
    <property name="last-view" type="string" value="ThunarIconView"/>
    <property name="last-icon-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_NORMAL"/>
    <property name="last-window-width" type="int" value="900"/>
    <property name="last-window-height" type="int" value="700"/>
    <property name="last-window-maximized" type="bool" value="false"/>
    <property name="last-separator-position" type="int" value="170"/>
    <property name="last-show-hidden" type="bool" value="false"/>
    <property name="misc-single-click" type="bool" value="false"/>
    <property name="misc-folders-first" type="bool" value="true"/>
    <property name="misc-show-thumbnails" type="bool" value="true"/>
    <property name="shortcuts-icon-emblems" type="bool" value="true"/>
    <property name="shortcuts-icon-size" type="string" value="THUNAR_ICON_SIZE_SMALLER"/>
</channel>
EOF

    echo -e "${GREEN}Configuration Thunar créée${NC}"
}

# Configuration audio avancée
setup_audio() {
    echo -e "${BLUE}Configuration audio avancée...${NC}"
    
    # Configuration Pipewire
    mkdir -p "$CONFIG_DIR/pipewire"
    
    # Configuration CAVA (visualiseur audio)
    mkdir -p "$CONFIG_DIR/cava"
    
    cat > "$CONFIG_DIR/cava/config" << 'EOF'
[general]
bars = 50
sleep_timer = 1

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
gradient_color_1 = '#89b4fa'
gradient_color_2 = '#74c7ec'
gradient_color_3 = '#a6e3a1'
gradient_color_4 = '#f9e2af'
gradient_color_5 = '#fab387'
gradient_color_6 = '#f38ba8'

[smoothing]
integral = 77
monstercat = 0
waves = 0

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
EOF

    echo -e "${GREEN}Configuration audio terminée${NC}"
}

# Configuration de fastfetch
setup_fastfetch() {
    echo -e "${BLUE}Configuration de Fastfetch...${NC}"
    
    mkdir -p "$CONFIG_DIR/fastfetch"
    
    cat > "$CONFIG_DIR/fastfetch/config.jsonc" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-rs/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "auto",
        "padding": {
            "top": 2,
            "left": 2
        }
    },
    "display": {
        "separator": " ➜ ",
        "color": {
            "keys": "blue",
            "title": "yellow"
        }
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
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "colors"
    ]
}
EOF

    # Ajout de Fastfetch au .bashrc
    if ! grep -q "fastfetch" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Fastfetch au démarrage" >> ~/.bashrc
        echo "if [ -t 0 ]; then" >> ~/.bashrc
        echo "    fastfetch" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
    fi
    
    echo -e "${GREEN}Fastfetch configuré${NC}"
}

# Configuration des services système
setup_system_services() {
    echo -e "${BLUE}Configuration des services système...${NC}"
    
    # Configuration SDDM
    sudo mkdir -p /etc/sddm.conf.d
    cat > /tmp/sddm-hyprland.conf << 'EOF'
[General]
InputMethod=

[Theme]
Current=breeze

[Users]
MaximumUid=65000
MinimumUid=1000

[Wayland]
SessionDir=/usr/share/wayland-sessions

[X11]
SessionDir=/usr/share/xsessions
EOF
    
    sudo mv /tmp/sddm-hyprland.conf /etc/sddm.conf.d/
    
    # Activation des services
    sudo systemctl enable sddm
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable bluetooth 2>/dev/null || true
    
    echo -e "${GREEN}Services système configurés${NC}"
}

# Téléchargement des ressources nécessaires
download_resources() {
    echo -e "${BLUE}Téléchargement des ressources...${NC}"
    
    # Création des dossiers
    mkdir -p "$USER_HOME/.config/hypr/wallpapers"
    mkdir -p "$USER_HOME/.local/share/icons"
    mkdir -p "$USER_HOME/Pictures/Screenshots"
    
    # Image de verrouillage par défaut
    if ! curl -s -o "$CONFIG_DIR/hypr/lockscreen.jpg" "https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1920&h=1080&fit=crop" 2>/dev/null; then
        # Création d'une image de secours
        if command -v convert >/dev/null 2>&1; then
            convert -size 1920x1080 xc:'#1e1e2e' "$CONFIG_DIR/hypr/lockscreen.jpg" 2>/dev/null || true
        fi
    fi
    
    # Wallpaper par défaut
    if ! curl -s -o "$USER_HOME/.config/hypr/wallpapers/default.jpg" "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=1920&h=1080&fit=crop" 2>/dev/null; then
        if command -v convert >/dev/null 2>&1; then
            convert -size 1920x1080 xc:'#2a2a2a' "$USER_HOME/.config/hypr/wallpapers/default.jpg" 2>/dev/null || true
        fi
    fi
    
    echo -e "${GREEN}Ressources téléchargées${NC}"
}

# Installation des outils de développement
setup_dev_tools() {
    echo -e "${BLUE}Installation des outils de développement...${NC}"

    case $DISTRO in
        "arch")
            # Arch : utiliser yay mais éviter les réinstallations inutiles
            DEV_PACKAGES="code android-studio jdk-openjdk python nodejs npm docker gcc clang cmake make"
            if ! command -v yay >/dev/null 2>&1; then
                echo -e "${BLUE}Installation de yay (AUR helper)...${NC}"
                git clone https://aur.archlinux.org/yay.git /tmp/yay || true
                (cd /tmp/yay && makepkg -si --noconfirm) || true
            fi
            # --needed évite de réinstaller ; || true empêche l'arrêt sur 'rien à faire'
            yay -S --needed --noconfirm $DEV_PACKAGES || true
            ;;

        "debian")
            # Visual Studio Code (repo Microsoft) — idempotent
            if ! command -v code >/dev/null 2>&1; then
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg || true
                sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ || true
                echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
                  | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null || true
                sudo apt update || true
            fi
            DEV_PACKAGES="code default-jdk python3 python3-pip nodejs npm docker.io gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES || true
            ;;

        "fedora")
            # Visual Studio Code (repo Microsoft) — idempotent
            if ! command -v code >/dev/null 2>&1; then
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
                sudo sh -c 'echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' || true
                sudo dnf -y makecache || true
            fi
            DEV_PACKAGES="code java-openjdk-devel python3 python3-pip nodejs npm docker gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES || true
            ;;

        "opensuse")
            # Visual Studio Code (repo Microsoft) — idempotent
            if ! command -v code >/dev/null 2>&1; then
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || true
                sudo sh -c 'echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/zypp/repos.d/vscode.repo' || true
                sudo zypper --non-interactive refresh || true
            fi
            DEV_PACKAGES="code java-openjdk-devel python3 python3-pip nodejs npm docker gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES || true
            ;;
    esac

    # Extensions VS Code (tolérantes si déjà installées)
    echo -e "${BLUE}  Installation des extensions VS Code...${NC}"
    if command -v code >/dev/null 2>&1; then
        code --install-extension ms-python.python 2>/dev/null || true
        code --install-extension ms-vscode.cpptools 2>/dev/null || true
        code --install-extension redhat.java 2>/dev/null || true
        code --install-extension bradlc.vscode-tailwindcss 2>/dev/null || true
        code --install-extension github.copilot 2>/dev/null || true
    fi

    # Configuration Docker (ne casse pas si le service existe déjà / docker absent)
    sudo systemctl enable docker 2>/dev/null || true
    sudo usermod -aG docker "$USER" 2>/dev/null || true

    echo -e "${GREEN}Outils de développement installés${NC}"
}

# Optimisations Gaming
setup_gaming_optimizations() {
    echo -e "${BLUE}Application des optimisations gaming...${NC}"
    
    # Installation de GameMode si disponible
    case $DISTRO in
        "arch")
            sudo $INSTALL_CMD gamemode lib32-gamemode 2>/dev/null || true
            ;;
        "debian")
            sudo $INSTALL_CMD gamemode 2>/dev/null || true
            ;;
        "fedora")
            sudo $INSTALL_CMD gamemode 2>/dev/null || true
            ;;
        "opensuse")
            sudo $INSTALL_CMD gamemode 2>/dev/null || true
            ;;
    esac
    
    echo -e "${GREEN}Optimisations gaming appliquées${NC}"
}

# Nettoyage et optimisation
cleanup_and_optimize() {
    echo -e "${BLUE}Nettoyage et optimisation...${NC}"
    
    # Nettoyage des caches
    case $DISTRO in
        "arch")
            sudo pacman -Sc --noconfirm 2>/dev/null || true
            yay -Sc --noconfirm 2>/dev/null || true
            ;;
        "debian")
            sudo apt autoremove -y
            sudo apt autoclean
            ;;
        "fedora")
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        "opensuse")
            sudo zypper clean -a
            ;;
    esac
    
    # Permissions des fichiers de configuration
    chmod +x "$CONFIG_DIR/hypr/video-wallpaper.sh" 2>/dev/null || true
    chmod +x "$USER_HOME/.local/bin/screenshot.sh" 2>/dev/null || true
    chmod 644 "$CONFIG_DIR/hypr/hyprland.conf" 2>/dev/null || true
    chmod 644 "$CONFIG_DIR/hypr/hyprlock.conf" 2>/dev/null || true
    
    # Optimisation des services
    sudo systemctl daemon-reload
    
    echo -e "${GREEN}Nettoyage terminé${NC}"
}

# Script de post-installation
create_post_install_script() {
    echo -e "${BLUE}Création du script de post-installation...${NC}"
    
    cat > "$USER_HOME/hyprland-postinstall.sh" << 'EOF'
#!/bin/bash

echo "Configuration post-installation..."

# Rechargement de Hyprland si en cours d'exécution
if pgrep -x "Hyprland" > /dev/null; then
    echo "Rechargement de la configuration Hyprland..."
    hyprctl reload
fi

# Redémarrage des services
echo "Redémarrage des services..."
systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber 2>/dev/null || true

# Test du fond vidéo
echo "Test du script de fond vidéo..."
~/.config/hypr/video-wallpaper.sh

# Vérification des permissions
echo "Vérification des permissions..."
chmod +x ~/.config/hypr/video-wallpaper.sh
chmod +x ~/.local/bin/screenshot.sh 2>/dev/null || true

# Test des commandes essentielles
echo "Test des composants..."
command -v hyprctl >/dev/null && echo "Hyprland OK" || echo "Hyprland manquant"
command -v waybar >/dev/null && echo "Waybar OK" || echo "Waybar manquant" 
command -v rofi >/dev/null && echo "Rofi OK" || echo "Rofi manquant"
command -v dunst >/dev/null && echo "Dunst OK" || echo "Dunst manquant"

echo ""
echo "Post-installation terminée !"
echo "Redémarrez votre session pour appliquer tous les changements."
EOF

    chmod +x "$USER_HOME/hyprland-postinstall.sh"
    
    echo -e "${GREEN}Script de post-installation créé${NC}"
}

# Guide de dépannage
create_troubleshooting_guide() {
    echo -e "${BLUE}Création du guide de dépannage...${NC}"
    
    cat > "$USER_HOME/TROUBLESHOOTING.md" << 'EOF'
# Guide de dépannage Hyprland

## Problèmes courants

### Hyprland ne démarre pas
```bash
# Vérifier les logs
journalctl -u sddm
# ou
cat ~/.local/share/hyprland/hyprland.log
```

### Fond d'écran vidéo ne fonctionne pas
```bash
# Test manuel
~/.config/hypr/video-wallpaper.sh
# Vérifier mpvpaper
which mpvpaper
```

### Waybar ne s'affiche pas
```bash
# Redémarrage manuel
killall waybar
waybar &
```

### Audio ne fonctionne pas
```bash
# Redémarrage des services audio
systemctl --user restart pipewire pipewire-pulse wireplumber
```

### Écran de verrouillage ne fonctionne pas
```bash
# Test hyprlock
hyprlock
# Vérifier la configuration
cat ~/.config/hypr/hyprlock.conf
```

## Commandes utiles

### Recharger Hyprland
```bash
hyprctl reload
```

### Redémarrer Waybar
```bash
killall waybar; waybar &
```

### Voir les fenêtres actives
```bash
hyprctl clients
```

## Support

En cas de problème persistant :
1. Vérifiez les logs dans `~/.local/share/hyprland/`
2. Consultez la documentation officielle : https://hyprland.org
3. Utilisez le script de post-installation : `~/hyprland-postinstall.sh`
EOF

    echo -e "${GREEN}Guide de dépannage créé${NC}"
}

# Récap de l'installation
print_summary() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 INSTALLATION TERMINÉE !                      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}Hyprland Ultimate Edition installé avec succès !${NC}"
    echo ""
    echo -e "${YELLOW}Configurations créées :${NC}"
    echo -e "  • Hyprland: ~/.config/hypr/hyprland.conf"
    echo -e "  • Waybar: ~/.config/waybar/ (avec transparence et Nerd Fonts)"
    echo -e "  • Hyprlock: ~/.config/hypr/hyprlock.conf (avec blur et avatar)"
    echo -e "  • Kitty: ~/.config/kitty/kitty.conf (thème Catppuccin)"
    echo -e "  • Rofi: ~/.config/rofi/ (remplace Wofi)"
    echo -e "  • Dunst: ~/.config/dunst/ (thème Catppuccin avec coins arrondis)"
    echo -e "  • Fastfetch: ~/.config/fastfetch/"
    echo ""
    echo -e "${BLUE}Raccourcis principaux :${NC}"
    echo -e "  • Super + Q: Terminal"
    echo -e "  • Super + E: Gestionnaire de fichiers"
    echo -e "  • Super + R: Menu d'applications (Rofi)"
    echo -e "  • Super + L: Verrouiller l'écran"
    echo -e "  • Print: Capture d'écran zone"
    echo -e "  • Super + Print: Capture plein écran"
    echo ""
    echo -e "${PURPLE}Améliorations visuelles :${NC}"
    echo -e "  • Coins arrondis et ombres douces"
    echo -e "  • Transparence et blur sur toutes les applications"
    echo -e "  • Wallpapers dynamiques (placez vos .mp4 dans ~/.config/hypr/wallpapers/)"
    echo -e "  • Thème Catppuccin cohérent"
    echo -e "  • JetBrainsMono Nerd Font et icônes Papirus/Tela"
    echo ""
    echo -e "${GREEN}Matériel détecté :${NC}"
    echo -e "  • GPU: $GPU_TYPE"
    echo -e "  • CPU: $CPU_TYPE"
    echo ""
    echo -e "${RED}IMPORTANT: Redémarrez votre système pour finaliser l'installation.${NC}"
    echo -e "${CYAN}Au prochain démarrage, Hyprland se lancera automatiquement !${NC}"
    echo ""
    echo -e "${YELLOW}Scripts utiles créés :${NC}"
    echo -e "  • ~/hyprland-postinstall.sh - Configuration post-installation"
    echo -e "  • ~/TROUBLESHOOTING.md - Guide de dépannage"
    echo ""
}

# Fonction principale
main() {
    # Vérification des droits
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Ne pas exécuter ce script en tant que root${NC}"
        exit 1
    fi
    
    # Redirection des logs
    exec > >(tee -a /tmp/hyprland-install.log)
    exec 2>&1
    
    print_banner
    
    echo -e "${YELLOW}Cette installation va :${NC}"
    echo -e "  • Détecter votre matériel (GPU/CPU) et installer les pilotes appropriés"
    echo -e "  • Détecter et désinstaller votre environnement graphique actuel"
    echo -e "  • Installer Hyprland avec tous ses composants optimisés"
    echo -e "  • Configurer un thème Catppuccin cohérent avec transparence et blur"
    echo -e "  • Installer JetBrainsMono Nerd Font et les thèmes d'icônes"
    echo -e "  • Remplacer Wofi par Rofi pour plus de style"
    echo -e "  • Installer les outils de développement et Spicetify"
    echo -e "  • Créer un environnement gaming optimisé"
    echo ""
    
    read -p "Continuer l'installation ? (o/N) : " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        echo -e "${YELLOW}Installation annulée.${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}Début de l'installation...${NC}"
    echo ""
    
    # Étapes de l'installation
    detect_hardware
    detect_distro
    install_yay
    clean_bashrc
    create_wayland_desktop_file
    install_dependencies
    install_nerd_fonts
    install_icon_themes
    detect_current_de
    remove_current_de
    install_gpu_drivers
    install_base_packages
    setup_hyprland_config
    setup_waybar
    setup_rofi
    setup_kitty
    setup_dunst
    setup_thunar
    setup_hyprlock
    setup_video_wallpaper
    setup_audio
    setup_fastfetch
    setup_screenshot_tools
    setup_spicetify
    setup_dev_tools
    setup_gaming_optimizations
    download_resources
    setup_system_services
    create_post_install_script
    create_troubleshooting_guide
    cleanup_and_optimize
    
    # Vérification finale
    if check_installation; then
        print_summary
    else
        echo -e "${RED}Installation incomplète. Consultez ~/TROUBLESHOOTING.md${NC}"
        exit 1
    fi
}

# Gestion des signaux pour nettoyage en cas d'interruption
trap 'echo -e "\n${RED}Installation interrompue${NC}"; exit 1' INT TERM

# Exécution du script principal
main "$@"

# Fin du script
echo -e "${BLUE}Script terminé. Logs disponibles dans /tmp/hyprland-install.log${NC}"
