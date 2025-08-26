#!/bin/bash

# Script d'installation d'Hyprland compatible sur  plusieurs distros Linux
# Version 212.2 : Mise à jour  le 26/08/2025 à  17:33 ATTENTION : Version non testée hotmis via shellcheck
# Compatible: Arch, Ubuntu/Debian, Fedora, OpenSUSE
# Fonctionnalités: Transparence, Blur, Vidéos animées, 
# Verrouillage stylé, Spicetify, Fastfetch, etc.

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

# Désinstalllation de l'environnement graphique detecté
remove_current_de() {
    if [ -n "$CURRENT_DE" ] && [ -n "$DE_PACKAGES_TO_REMOVE" ]; then
        echo -e "${YELLOW}Désinstallation de $CURRENT_DE...${NC}"
        
        # Arrêt des services graphiques
        sudo systemctl stop display-manager 2>/dev/null || true
        sudo systemctl stop gdm 2>/dev/null || true
        sudo systemctl stop sddm 2>/dev/null || true
        sudo systemctl stop lightdm 2>/dev/null || true
        
        # Désinstallation des paquets
        for package in $DE_PACKAGES_TO_REMOVE; do
            echo -e "${BLUE}  Suppression de $package...${NC}"
            sudo $REMOVE_CMD $package 2>/dev/null || true
        done
        
        # Nettoyage des configurations utilisateur
        echo -e "${BLUE}  Nettoyage des configurations...${NC}"
        rm -rf "$USER_HOME/.config/plasma"* 2>/dev/null || true
        rm -rf "$USER_HOME/.config/kde"* 2>/dev/null || true
        rm -rf "$USER_HOME/.config/gnome"* 2>/dev/null || true
        rm -rf "$USER_HOME/.config/xfce4" 2>/dev/null || true
        rm -rf "$USER_HOME/.config/lxqt" 2>/dev/null || true
        
        # Désactivation des services
        sudo systemctl disable gdm 2>/dev/null || true
        sudo systemctl disable lightdm 2>/dev/null || true
        
        echo -e "${GREEN}$CURRENT_DE désinstallé${NC}"
    fi
}

# Installation des paquets Hyprland
install_base_packages() {
    echo -e "${BLUE}Installation des paquets de base...${NC}"
    
    # Mise à jour du système
    sudo $UPDATE_CMD
    
    case $DISTRO in
        "arch")
            # Installation des dépôts AUR helper si nécessaire
            if ! command -v yay >/dev/null 2>&1; then
                echo -e "${BLUE}Installation de yay (AUR helper)...${NC}"
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay && makepkg -si --noconfirm
                cd -
            fi
            
            # Paquets Arch
            PACKAGES="hyprland hyprpaper hypridle hyprlock xdg-desktop-portal-hyprland polkit-gnome waybar wofi kitty thunar dunst mpvpaper sddm pipewire wireplumber pavucontrol cava fastfetch git curl wget unzip"
            sudo $INSTALL_CMD $PACKAGES
            
            # Paquets AUR
            yay -S --noconfirm spicetify-cli
            ;;
            
        "debian")
            # Ajout des dépôts nécessaires pour Ubuntu/Debian
            if ! grep -q "ppa:hyprland" /etc/apt/sources.list.d/* 2>/dev/null; then
                sudo apt install -y software-properties-common
                sudo add-apt-repository ppa:hyprland/hyprland -y
                sudo apt update
            fi
            
            PACKAGES="hyprland waybar wofi kitty thunar dunst pipewire-pulse pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD $PACKAGES
            
            # Installation manuelle pour les paquets non disponibles
            install_from_source_debian
            ;;
            
        "fedora")
            # Activation des dépôts RPM Fusion
            sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            
            PACKAGES="hyprland waybar wofi kitty thunar dunst pipewire-pulseaudio pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD $PACKAGES
            
            install_from_source_fedora
            ;;
            
        "opensuse")
            PACKAGES="hyprland waybar wofi kitty thunar dunst pipewire-pulseaudio pavucontrol fastfetch git curl wget unzip sddm"
            sudo $INSTALL_CMD $PACKAGES
            
            install_from_source_opensuse
            ;;
    esac
}

install_from_source_debian() {
    echo -e "${BLUE}Installation depuis les sources (Debian/Ubuntu)...${NC}"
    
    # Hyprpaper, hypridle, hyprlock depuis les sources
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
    
    # Installation similaire à Debian mais avec les dépendances Fedora
    install_hypr_tools_from_source
}

install_from_source_opensuse() {
    echo -e "${BLUE}Installation depuis les sources (OpenSUSE)...${NC}"
    
    cd /tmp
    sudo zypper install -y gcc-c++ cmake meson ninja pkg-config wayland-devel libxkbcommon-devel
    
    install_hypr_tools_from_source
}

install_hypr_tools_from_source() {
    # Fonction commune pour installer les outils Hypr depuis les sources
    git clone https://github.com/hyprwm/hyprpaper.git
    cd hyprpaper && make all && sudo make install && cd ..
    
    git clone https://github.com/hyprwm/hypridle.git
    cd hypridle && make all && sudo make install && cd ..
    
    git clone https://github.com/hyprwm/hyprlock.git
    cd hyprlock && make all && sudo make install && cd ..
    
    git clone https://github.com/GhostNaN/mpvpaper.git
    cd mpvpaper && meson build && ninja -C build && sudo ninja -C build install
}

# Configuration d'Hyprland
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
    }
    sensitivity = 0
}

# Apparence générale
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    resize_on_border = false
    allow_tearing = false
    layout = dwindle
}

# Décoration
decoration {
    rounding = 10
    active_opacity = 0.98
    inactive_opacity = 0.95
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)

    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
    }
}

# Animations
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

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# Gestes
gestures {
    workspace_swipe = true
}

# Divers
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}

# Apparence d'une fenetre
# Transparence par application
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.92 0.92,class:^(thunar)$
windowrulev2 = opacity 0.85 0.85,class:^(waybar)$

# Fenêtres flottantes
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(nm-connection-editor)$
windowrulev2 = float,class:^(thunar)$,title:^(.*Properties.*)$


# Racccourcis clavier -> Touche du logo Windows
$mainMod = SUPER

# Applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# Système
bind = $mainMod, L, exec, hyprlock
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

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
EOF

    echo -e "${GREEN}Configuration Hyprland créée${NC}"
}

# Arrière-plan vidéo
setup_video_wallpaper() {
    echo -e "${BLUE}Configuration du fond vidéo animé...${NC}"
    
    # Création du dossier pour les vidéos
    mkdir -p "$USER_HOME/.config/hypr/wallpapers"
    
    # Script de gestion des fonds vidéo
    cat > "$CONFIG_DIR/hypr/video-wallpaper.sh" << 'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
FALLBACK_COLOR="#1a1a1a"

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
    
    # Démarrage de la nouvelle vidéo
    mpvpaper -o "loop --no-audio --hwdec=auto" '*' "$selected_video" &
fi
EOF

    chmod +x "$CONFIG_DIR/hypr/video-wallpaper.sh"
    
    # Configuration Hyprpaper pour le fallback
    cat > "$CONFIG_DIR/hypr/hyprpaper.conf" << EOF
preload = ~/.config/hypr/wallpapers/default.jpg
wallpaper = ,~/.config/hypr/wallpapers/default.jpg
ipc = on
EOF

    echo -e "${GREEN}Configuration vidéo wallpaper créée${NC}"
    echo -e "${YELLOW}Placez vos vidéos .mp4 dans ~/.config/hypr/wallpapers/${NC}"
}

# COnfiguration  Waybar
setup_waybar() {
    echo -e "${BLUE}Configuration de Waybar...${NC}"
    
    mkdir -p "$CONFIG_DIR/waybar"
    
    # Configuration Waybar
    cat > "$CONFIG_DIR/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "spacing": 10,
    "margin-top": 5,
    "margin-left": 10,
    "margin-right": 10,
    
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "active-only": false,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "1",
            "2": "2",
            "3": "3",
            "4": "4",
            "5": "5",
            "6": "6",
            "7": "7",
            "8": "8",
            "9": "9",
            "10": "10"
        },
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },

    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%A %d %B %Y - %H:%M:%S}",
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

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-icons": ["", "", "", "", ""]
    },

    "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "Câblé ",
        "format-linked": "Connecté (Sans IP) ",
        "format-disconnected": "Déconnecté ⚠",
        "tooltip-format-wifi": "Adresse IP: {ipaddr}\nSignal: {signalStrength}%"
    },

    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "",
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

    # Style CSS Waybar
    cat > "$CONFIG_DIR/waybar/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: 'JetBrainsMono Nerd Font', 'Font Awesome 6 Free';
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(26, 27, 38, 0.85);
    color: #cdd6f4;
    border-radius: 15px;
    border: 2px solid rgba(137, 180, 250, 0.3);
    margin: 0;
}

#workspaces {
    background: rgba(49, 50, 68, 0.8);
    border-radius: 10px;
    padding: 8px 12px;
    margin: 5px 2px;
    color: #cdd6f4;
    transition: all 0.3s ease;
}

#battery:hover,
#network:hover,
#pulseaudio:hover {
    background: rgba(137, 180, 250, 0.1);
    box-shadow: 0 0 10px rgba(137, 180, 250, 0.2);
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

    echo -e "${GREEN}Configuration Waybar créée${NC}"
}

# Configuration Hyprlock
setup_hyprlock() {
    echo -e "${BLUE}🔒 Configuration Hyprlock...${NC}"
    
    mkdir -p "$CONFIG_DIR/hypr"
    
    cat > "$CONFIG_DIR/hypr/hyprlock.conf" << 'EOF'

general {
    disable_loading_bar = true
    grace = 2
    hide_cursor = false
    no_fade_in = false
    no_fade_out = false
    ignore_empty_input = false
}

background {
    monitor =
    path = ~/.config/hypr/lockscreen.jpg
    blur_passes = 3
    blur_size = 8
    color = rgba(25, 20, 20, 1.0)
}

# Horloge
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%-H:%M")"
    color = rgba(255, 255, 255, 0.9)
    font_size = 120
    font_family = JetBrains Mono Bold
    position = 0, 200
    halign = center
    valign = center
}

# Date
label {
    monitor =
    text = cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"
    color = rgba(255, 255, 255, 0.7)
    font_size = 24
    font_family = JetBrains Mono
    position = 0, 150
    halign = center
    valign = center
}

# Message Fallout
label {
    monitor =
    text = [ VEUILLEZ SAISIR VOTRE MOT DE PASSE ]
    color = rgba(0, 255, 100, 0.8)
    font_size = 18
    font_family = JetBrains Mono Bold
    position = 0, 30
    halign = center
    valign = center
}

# Message système
label {
    monitor =
    text = SYSTÈME DE SÉCURITÉ VAULT-TEC ACTIVÉ
    color = rgba(0, 255, 100, 0.6)
    font_size = 14
    font_family = JetBrains Mono
    position = 0, -50
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
    outer_color = rgba(0, 255, 100, 0.8)
    inner_color = rgba(0, 0, 0, 0.8)
    font_color = rgba(0, 255, 100, 1.0)
    fade_on_empty = false
    placeholder_text = <span foreground="##00ff64">Mot de passe...</span>
    hide_input = false
    rounding = 10
    check_color = rgba(0, 255, 100, 0.8)
    fail_color = rgba(255, 50, 50, 0.8)
    fail_text = <i>ACCÈS REFUSÉ</i>
    capslock_color = rgba(255, 255, 0, 0.8)
    position = 0, -120
    halign = center
    valign = center
}

# Indicateur de Caps Lock
label {
    monitor =
    text = CAPS LOCK ACTIVÉ
    color = rgba(255, 255, 0, 0.8)
    font_size = 12
    font_family = JetBrains Mono
    position = 0, -200
    halign = center
    valign = center
}
EOF

    echo -e "${GREEN}Configuration Hyprlock créée${NC}"
}

# Installation de Spotify & de Spicetify
setup_spicetify() {
    echo -e "${BLUE}🎵 Installation et configuration de Spicetify...${NC}"
    
    # Installation de Spotify si nécessaire
    if ! command -v spotify >/dev/null 2>&1; then
        case $DISTRO in
            "arch")
                yay -S --noconfirm spotify
                ;;
            "debian")
                curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
                echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
                sudo apt update && sudo apt install -y spotify-client
                ;;
            "fedora")
                sudo dnf config-manager --add-repo=https://negativo17.org/repos/fedora-spotify.repo
                sudo dnf install -y spotify-client
                ;;
            "opensuse")
                sudo zypper addrepo -f https://download.spotify.com/repository/spotify.repo
                sudo zypper install -y spotify-client
                ;;
        esac
    fi
    
    # Installation Spicetify
    if [ "$DISTRO" != "arch" ]; then
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
        export PATH="$HOME/.spicetify:$PATH"
        echo 'export PATH="$HOME/.spicetify:$PATH"' >> ~/.bashrc
    fi
    
    # Configuration Spicetify
    spicetify config current_theme Dribbblish color_scheme nord-dark
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
    
    # Installation du thème Dribbblish
    curl -fsSL https://raw.githubusercontent.com/morpheusthewhite/spicetify-themes/master/Dribbblish/install.sh | sh
    
    # Application des modifications
    spicetify backup apply
    
    echo -e "${GREEN}Spicetify configuré avec le thème Dribbblish Nord Dark${NC}"
}

# Installation des outils de développement
setup_dev_tools() {
    echo -e "${BLUE}💻 Installation des outils de développement...${NC}"
    
    case $DISTRO in
        "arch")
            DEV_PACKAGES="visual-studio-code-bin android-studio jdk-openjdk python nodejs npm docker gcc clang cmake make"
            yay -S --noconfirm $DEV_PACKAGES
            ;;
        "debian")
            # Visual Studio Code
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
            
            sudo apt update
            DEV_PACKAGES="code default-jdk python3 python3-pip nodejs npm docker.io gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES
            ;;
        "fedora")
            # Visual Studio Code
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            
            DEV_PACKAGES="code java-openjdk-devel python3 python3-pip nodejs npm docker gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES
            ;;
        "opensuse")
            # Visual Studio Code
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/zypp/repos.d/vscode.repo'
            
            DEV_PACKAGES="code java-openjdk-devel python3 python3-pip nodejs npm docker gcc clang cmake make"
            sudo $INSTALL_CMD $DEV_PACKAGES
            ;;
    esac
    
    # Extensions VS Code
    echo -e "${BLUE}  Installation des extensions VS Code...${NC}"
    code --install-extension ms-python.python
    code --install-extension ms-vscode.cpptools
    code --install-extension redhat.java
    code --install-extension bradlc.vscode-tailwindcss
    code --install-extension github.copilot
    
    # Configuration Docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}Outils de développement installés${NC}"
}

# Configuration de fastfetch
setup_fastfetch() {
    echo -e "${BLUE}Configuration de Fastfetch...${NC}"
    
    mkdir -p "$CONFIG_DIR/fastfetch"
    
    cat > "$CONFIG_DIR/fastfetch/config.jsonc" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-rs/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "padding": {
            "top": 2,
            "left": 2
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

# Configuration de Wofi (launcher d'applis)
setup_wofi() {
    echo -e "${BLUE}Configuration de Wofi...${NC}"
    
    mkdir -p "$CONFIG_DIR/wofi"
    
    cat > "$CONFIG_DIR/wofi/config" << 'EOF'
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

    cat > "$CONFIG_DIR/wofi/style.css" << 'EOF'
window {
    margin: 0px;
    border: 2px solid rgba(137, 180, 250, 0.6);
    background-color: rgba(26, 27, 38, 0.9);
    border-radius: 15px;
    font-family: "JetBrains Mono";
}

#input {
    margin: 10px;
    border: 2px solid rgba(137, 180, 250, 0.4);
    background-color: rgba(49, 50, 68, 0.8);
    border-radius: 10px;
    padding: 10px;
    color: #cdd6f4;
    font-size: 14px;
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
    color: #cdd6f4;
    font-size: 13px;
}

#entry {
    border-radius: 8px;
    margin: 2px;
    padding: 8px;
    background-color: transparent;
}

#entry:selected {
    background-color: rgba(137, 180, 250, 0.2);
    border: 1px solid rgba(137, 180, 250, 0.4);
}

#text:selected {
    color: #89b4fa;
}
EOF

    echo -e "${GREEN}Configuration Wofi créée${NC}"
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
EOF
    
    sudo mv /tmp/sddm-hyprland.conf /etc/sddm.conf.d/
    
    # Activation des services
    sudo systemctl enable sddm
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    
    # Configuration du démarrage automatique Hyprland
    if ! grep -q "Hyprland" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# Démarrage automatique de Hyprland sur TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec Hyprland
fi
EOF
    fi
    
    # Service de son au démarrage (optionnel)
    cat > /tmp/boot-sound.service << 'EOF'
[Unit]
Description=Son de démarrage
After=sound.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'paplay /usr/share/sounds/alsa/Front_Left.wav 2>/dev/null || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv /tmp/boot-sound.service /etc/systemd/system/
    sudo systemctl enable boot-sound.service
    
    echo -e "${GREEN}Services système configurés${NC}"
}

# Configuratioon du  terminal Kitty
setup_kitty() {
    echo -e "${BLUE}Configuration de Kitty terminal...${NC}"
    
    mkdir -p "$CONFIG_DIR/kitty"
    
    cat > "$CONFIG_DIR/kitty/kitty.conf" << 'EOF'

# Police
font_family      JetBrains Mono
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

# Sélection
selection_foreground none
selection_background #44475a

# Performance
repaint_delay 10
input_delay 3

# Bell
enable_audio_bell no
visual_bell_duration 0.0

# Fenêtre
window_padding_width 10
background_opacity 0.90
dynamic_background_opacity yes

# Couleurs de base
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

# Configuration audia avancée
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
gradient_color_1 = '#00ff00'
gradient_color_2 = '#00ff64'
gradient_color_3 = '#64ff00'
gradient_color_4 = '#ffff00'
gradient_color_5 = '#ff6400'
gradient_color_6 = '#ff0000'

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

# Téléchargement  des ressources nécessaires
download_resources() {
    echo -e "${BLUE}Téléchargement des ressources...${NC}"
    
    # Création des dossiers
    mkdir -p "$USER_HOME/.config/hypr/wallpapers"
    mkdir -p "$USER_HOME/.local/share/icons"
    
    # Image de verrouillage par défaut
    curl -s -o "$CONFIG_DIR/hypr/lockscreen.jpg" "https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=1920&h=1080&fit=crop" 2>/dev/null || {
        # Création d'une image de secours
        convert -size 1920x1080 xc:'#1a1a1a' "$CONFIG_DIR/hypr/lockscreen.jpg" 2>/dev/null || true
    }
    
    # Wallpaper par défaut
    curl -s -o "$USER_HOME/.config/hypr/wallpapers/default.jpg" "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=1920&h=1080&fit=crop" 2>/dev/null || {
        convert -size 1920x1080 xc:'#2a2a2a' "$USER_HOME/.config/hypr/wallpapers/default.jpg" 2>/dev/null || true
    }
    
    echo -e "${GREEN}✅ Ressources téléchargées${NC}"
}

# Nettoyage & optimisation
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
    chmod +x "$CONFIG_DIR/hypr/video-wallpaper.sh"
    chmod 644 "$CONFIG_DIR/hypr/hyprland.conf"
    chmod 644 "$CONFIG_DIR/hypr/hyprlock.conf"
    
    # Optimisation des services
    sudo systemctl daemon-reload
    
    echo -e "${GREEN}Nettoyage terminé${NC}"
}

# Récap de l'installation
print_summary() {
    clear
    echo -e "${GREEN}"

    echo -e "${NC}"
    
    echo -e "${CYAN}Hyprland Ultimate Edition installé avec succès !${NC}"
    echo ""
    echo -e "${YELLOW}Configurations créées :${NC}"
    echo -e "  • Hyprland: ~/.config/hypr/hyprland.conf"
    echo -e "  • Waybar: ~/.config/waybar/"
    echo -e "  • Hyprlock: ~/.config/hypr/hyprlock.conf"
    echo -e "  • Kitty: ~/.config/kitty/kitty.conf"
    echo -e "  • Wofi: ~/.config/wofi/"
    echo -e "  • Fastfetch: ~/.config/fastfetch/"
    echo ""
    echo -e "${BLUE}Raccourcis principaux :${NC}"
    echo -e "  • Super + Q: Terminal"
    echo -e "  • Super + E: Gestionnaire de fichiers"
    echo -e "  • Super + R: Menu d'applications"
    echo -e "  • Super + L: Verrouiller l'écran"
    echo -e "  • Print: Capture d'écran"
    echo ""
    echo -e "${PURPLE}Pour les fonds vidéo animés :${NC}"
    echo -e "  Placez vos fichiers .mp4 dans ~/.config/hypr/wallpapers/"
    echo ""
    echo -e "${GREEN}Redémarrez votre système pour finaliser l'installation.${NC}"
    echo -e "${CYAN}Au prochain démarrage, Hyprland se lancera automatiquement !${NC}"
    echo ""
}

# Main
main() {
    # Vérification des droits
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Ne pas exécuter ce script en tant que root${NC}"
        exit 1
    fi
    
    print_banner
    
    echo -e "${YELLOW}Cette installation va :${NC}"
    echo -e "  • Détecter et désinstaller votre environnement graphique actuel"
    echo -e "  • Installer Hyprland et tous ses composants"
    echo -e "  • Configurer un thème personnalisé avec transparence et blur"
    echo -e "  • Installer les outils de développement"
    echo ""
    
    read -p "Continuer l'installation ? (o/N) : " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        echo -e "${YELLOW}Installation annulée.${NC}"
        exit 0
    fi
    
    # Étapes de l'installation
    detect_distro
    detect_current_de
    remove_current_de
    install_base_packages
    setup_hyprland_config
    setup_waybar
    setup_wofi
    setup_kitty
    setup_hyprlock
    setup_video_wallpaper
    setup_audio
    setup_fastfetch
    setup_spicetify
    setup_dev_tools
    download_resources
    setup_system_services
    cleanup_and_optimize
    
    print_summary
}

# Configuration poru les notifs (via Dunst)
setup_dunst() {
    echo -e "${BLUE}Configuration de Dunst (notifications)...${NC}"
    
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
    notification_limit = 0
    progress_bar = true
    progress_bar_height = 10
    progress_bar_frame_width = 1
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    indicate_hidden = yes
    transparency = 10
    separator_height = 2
    padding = 20
    horizontal_padding = 20
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#89b4fa"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = JetBrains Mono 11
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
    icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/
    sticky_history = yes
    history_length = 20
    dmenu = /usr/bin/dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 10
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
    timeout = 10

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_critical]
    background = "#f38ba8"
    foreground = "#1e1e2e"
    frame_color = "#f38ba8"
    timeout = 0
EOF

    echo -e "${GREEN}Configuration Dunst créée${NC}"
}

# COnfiguration du gestionnaire des fichiers
setup_thunar() {
    echo -e "${BLUE}Configuration de Thunar...${NC}"
    
    # Configuration de base Thunar
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
    <property name="last-details-view-zoom-level" type="string" value="THUNAR_ZOOM_LEVEL_SMALLER"/>
    <property name="last-details-view-column-widths" type="string" value="50,133,50,50,178,50,50,73,70"/>
    <property name="misc-single-click" type="bool" value="false"/>
    <property name="misc-folders-first" type="bool" value="true"/>
    <property name="misc-show-thumbnails" type="bool" value="true"/>
    <property name="shortcuts-icon-emblems" type="bool" value="true"/>
    <property name="shortcuts-icon-size" type="string" value="THUNAR_ICON_SIZE_SMALLER"/>
</channel>
EOF

    echo -e "${GREEN}Configuration Thunar créée${NC}"
}

# COnfiguration de mpvpaper (fond vidéo)
setup_mpvpaper_config() {
    echo -e "${BLUE}Configuration avancée MPVPaper...${NC}"
    
    mkdir -p "$CONFIG_DIR/mpv"
    
    cat > "$CONFIG_DIR/mpv/mpv.conf" << 'EOF'
# Configuration MPV pour wallpapers
profile=gpu-hq
vo=gpu
hwdec=auto-safe
video-sync=display-resample
interpolation
tscale=oversample

# Optimisations pour les wallpapers
no-border
no-osc
no-input-default-bindings
really-quiet=yes
no-audio
loop-file=inf
panscan=1.0

# Performance
opengl-pbo=yes
vd-lavc-threads=0
EOF

    echo -e "${GREEN}Configuration MPV créée${NC}"
}

# Config de grim & slurp (screenshots)
setup_screenshot_tools() {
    echo -e "${BLUE}Installation des outils de capture...${NC}"
    
    case $DISTRO in
        "arch")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
        "debian")
            sudo $INSTALL_CMD grim slurp wl-clipboard-tools
            ;;
        "fedora")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
        "opensuse")
            sudo $INSTALL_CMD grim slurp wl-clipboard
            ;;
    esac
    
    # Script de capture avancé
    mkdir -p "$USER_HOME/.local/bin"
    
    cat > "$USER_HOME/.local/bin/screenshot.sh" << 'EOF'
#!/bin/bash

# Script de capture d'écran avancé pour Hyprland
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

case "$1" in
    "area")
        # Capture de zone sélectionnée
        grim -g "$(slurp)" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send "Capture" "Zone sélectionnée sauvegardée"
        ;;
    "window")
        # Capture de la fenêtre active
        grim -g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send "Capture" "Fenêtre active sauvegardée"
        ;;
    "full"|*)
        # Capture plein écran
        grim "$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
        notify-send "Capture" "Écran complet sauvegardé"
        ;;
esac
EOF

    chmod +x "$USER_HOME/.local/bin/screenshot.sh"
    
    # Ajout au PATH si nécessaire
    if ! grep -q ".local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    
    echo -e "${GREEN}Outils de capture installés${NC}"
}

# Optimisations Gaming
setup_gaming_optimizations() {
    echo -e "${BLUE}Application des optimisations gaming...${NC}"
    
    # Installation de GameMode si disponible
    case $DISTRO in
        "arch")
            sudo $INSTALL_CMD gamemode lib32-gamemode
            ;;
        "debian")
            sudo $INSTALL_CMD gamemode
            ;;
        "fedora")
            sudo $INSTALL_CMD gamemode
            ;;
        "opensuse")
            sudo $INSTALL_CMD gamemode
            ;;
    esac
    
    # Configuration pour les jeux
    cat >> "$CONFIG_DIR/hypr/hyprland.conf" << 'EOF'

# Règles pour les jeux (performance maximale)
windowrulev2 = immediate, class:^(steam_app_)(.*)$
windowrulev2 = immediate, class:^(lutris)$
windowrulev2 = immediate, class:^(heroic)$
windowrulev2 = immediate, class:^(minecraft)$

# Plein écran sans bordures pour les jeux
windowrulev2 = noborder, class:^(steam_app_)(.*)$, fullscreen:1
windowrulev2 = noborder, class:^(lutris)$, fullscreen:1

# Désactiver les effets en jeu
windowrulev2 = noblur, class:^(steam_app_)(.*)$
windowrulev2 = noshadow, class:^(steam_app_)(.*)$
EOF

    echo -e "${GREEN}Optimisations gaming appliquées${NC}"
}

# Création d'un script post-install
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

# Installation des polices si nécessaires
echo "Vérification des polices..."
if ! fc-list | grep -qi "jetbrains"; then
    echo "Police JetBrains Mono non trouvée. Installation recommandée."
fi

# Test des commandes essentielles
echo "Test des composants..."
command -v hyprctl >/dev/null && echo "Hyprland OK" || echo "Hyprland manquant"
command -v waybar >/dev/null && echo "Waybar OK" || echo "Waybar manquant" 
command -v wofi >/dev/null && echo "Wofi OK" || echo "Wofi manquant"
command -v dunst >/dev/null && echo "Dunst OK" || echo "Dunst manquant"

echo ""
echo "Post-installation terminée !"
echo "Redémarrez votre session pour appliquer tous les changements."
EOF

    chmod +x "$USER_HOME/hyprland-postinstall.sh"
    
    echo -e "${GREEN}Script de post-installation créé${NC}"
}

# Fonctions de dépannage
create_troubleshooting_guide() {
    echo -e "${BLUE}📋 Création du guide de dépannage...${NC}"
    
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

### Changer le fond d'écran
```bash
hyprctl hyprpaper wallpaper "DP-1,/path/to/image.jpg"
```

## Support

En cas de problème persistant :
1. Vérifiez les logs dans `~/.local/share/hyprland/`
2. Consultez la documentation officielle : https://hyprland.org
3. Utilisez le script de post-installation : `~/hyprland-postinstall.sh`
4. En dernier recours, contactez moi via mon compte GitHub (PapaOursPolaire) ou par adresse électronique : papaourspolairegithub@gmail.com
EOF

    echo -e "${GREEN}Guide de dépannage créé${NC}"
}

# Maj du Main
main() {
    # Vérification des droits
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Ne pas exécuter ce script en tant que root${NC}"
        exit 1
    fi
    
    print_banner
    
    echo -e "${YELLOW}Cette installation va :${NC}"
    echo -e "  • Détecter et désinstaller votre environnement graphique actuel"
    echo -e "  • Installer Hyprland et tous ses composants"
    echo -e "  • Configurer un thème personnalisé avec transparence et blur"
    echo -e "  • Installer les outils de développement"
    echo -e "  • Configurer Spicetify pour Spotify"
    echo -e "  • Optimiser le système pour les performances"
    echo ""
    
    read -p "Continuer l'installation ? (o/N) : " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        echo -e "${YELLOW}Installation annulée.${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}Début de l'installation...${NC}"
    echo ""
    
    detect_distro
    detect_current_de
    remove_current_de
    install_base_packages
    setup_hyprland_config
    setup_waybar
    setup_wofi
    setup_kitty
    setup_dunst
    setup_thunar
    setup_hyprlock
    setup_video_wallpaper
    setup_mpvpaper_config
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
    
    print_summary
}

# Gestion des signaux pour nettoyage en cas d'interruption
trap 'echo -e "\n${RED}Installation interrompue${NC}"; exit 1' INT TERM

# Exécution du script principal
main "$@"

# Fin du script
echo -e "${BLUE}Script terminé. Logs disponibles dans /tmp/hyprland-install.log${NC}"
