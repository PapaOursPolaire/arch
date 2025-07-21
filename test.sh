# Arch Linux + Hyprland Installation Script
# Thème: Dev/Gaming/Arcane inspired setup
# Auteur: GitHub Repository
# Version: 1.0

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'affichage stylée
print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
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

# Fonction de titre stylé
print_title() {
    echo -e "${PURPLE}"
    echo "=================================="
    echo "    $1"
    echo "=================================="
    echo -e "${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    print_title "Vérification des prérequis"
    
    if [[ $EUID -eq 0 ]]; then
        print_error "Ce script ne doit pas être exécuté en tant que root"
        exit 1
    fi
    
    if ! command -v pacman &> /dev/null; then
        print_error "Ce script nécessite Arch Linux (pacman non trouvé)"
        exit 1
    fi
    
    print_success "Prérequis validés"
}

# Configuration du système de base
setup_base_system() {
    print_title "Configuration du système de base"
    
    # Mise à jour du système
    sudo pacman -Syu --noconfirm
    
    # Installation des paquets de base essentiels
    sudo pacman -S --noconfirm \
        base-devel git curl wget unzip \
        networkmanager network-manager-applet \
        bluez bluez-utils \
        pulseaudio pulseaudio-alsa pulseaudio-bluetooth \
        pipewire pipewire-alsa pipewire-pulse wireplumber \
        xdg-desktop-portal-hyprland \
        polkit-gnome \
        grim slurp wl-clipboard \
        dunst libnotify \
        thunar thunar-archive-plugin \
        firefox chromium \
        kitty \
        neofetch fastfetch \
        htop btop \
        vim neovim \
        ranger \
        fzf ripgrep fd \
        tree \
        openssh \
        rsync \
        zip unrar p7zip
    
    print_success "Système de base configuré"
}

# Installation d'AUR helper (yay)
install_yay() {
    print_title "Installation de yay (AUR helper)"
    
    if ! command -v yay &> /dev/null; then
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
        print_success "yay installé"
    else
        print_warning "yay déjà installé"
    fi
}

# Installation d'Hyprland et composants graphiques
install_hyprland() {
    print_title "Installation d'Hyprland et composants graphiques"
    
    # Installation d'Hyprland et dépendances
    sudo pacman -S --noconfirm \
        hyprland \
        waybar \
        rofi-wayland \
        swww \
        hypridle \
        hyprlock \
        xdg-desktop-portal-hyprland \
        qt5-wayland qt6-wayland \
        cliphist \
        brightnessctl \
        pamixer \
        playerctl \
        wlogout
    
    # Installation des thèmes et icônes
    yay -S --noconfirm \
        nwg-look \
        papirus-icon-theme \
        arc-gtk-theme \
        numix-circle-icon-theme-git \
        tela-circle-icon-theme-git
    
    print_success "Hyprland installé"
}

# Configuration de Grub avec thèmes
setup_grub_themes() {
    print_title "Configuration de GRUB avec thèmes multiples"
    
    # Installation de GRUB si pas déjà installé
    sudo pacman -S --noconfirm grub efibootmgr os-prober
    
    # Création du dossier des thèmes
    sudo mkdir -p /boot/grub/themes
    
    # Thème Fallout (par défaut)
    print_status "Installation du thème Fallout pour GRUB..."
    cd /tmp
    git clone https://github.com/shvchk/fallout-grub-theme.git
    sudo cp -r fallout-grub-theme/fallout /boot/grub/themes/
    
    # Autres thèmes GRUB
    print_status "Installation d'autres thèmes GRUB..."
    
    # BSOL Theme
    git clone https://github.com/VandalByte/dedsec-grub2-theme.git
    sudo cp -r dedsec-grub2-theme/dedsec /boot/grub/themes/bsol
    
    # Minegrub
    git clone https://github.com/Lxtharia/minegrub-theme.git
    sudo cp -r minegrub-theme/minegrub /boot/grub/themes/
    
    # CRT-Amber
    git clone https://github.com/VandalByte/CRT-Amber-GRUB-Theme.git
    sudo cp -r CRT-Amber-GRUB-Theme/CRT-Amber /boot/grub/themes/
    
    # Dark Matter
    git clone https://github.com/VandalByte/darkmatter-grub2-theme.git
    sudo cp -r darkmatter-grub2-theme/darkmatter /boot/grub/themes/
    
    # Thème Arcane (si disponible)
    if git clone https://github.com/AdisonCavani/distro-grub-themes.git 2>/dev/null; then
        sudo cp -r distro-grub-themes/themes/* /boot/grub/themes/ 2>/dev/null || true
    fi
    
    # Configuration GRUB par défaut (Fallout)
    sudo tee -a /etc/default/grub << EOF

# Thème personnalisé
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
GRUB_GFXMODE="1920x1080"
GRUB_DISABLE_OS_PROBER=false
EOF
    
    # Régénération de la configuration GRUB
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    print_success "GRUB configuré avec thèmes multiples"
}

# Installation des outils de développement
install_dev_tools() {
    print_title "Installation des outils de développement"
    
    # VS Code
    yay -S --noconfirm visual-studio-code-bin
    
    # Android Studio
    yay -S --noconfirm android-studio
    
    # Java (OpenJDK)
    sudo pacman -S --noconfirm jdk-openjdk jre-openjdk
    
    # Outils de développement
    sudo pacman -S --noconfirm \
        nodejs npm yarn \
        python python-pip \
        gcc gdb \
        cmake make \
        docker docker-compose \
        postman-bin \
        dbeaver \
        git-lfs
    
    # Outils réseau et sécurité
    sudo pacman -S --noconfirm \
        nmap \
        wireshark-qt \
        netcat \
        tcpdump \
        iftop \
        iotop \
        nethogs \
        traceroute \
        whois \
        dig \
        curl \
        wget \
        rsync \
        ssh \
        scp \
        sftp
    
    # Wine pour les applications Windows
    sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks
    
    print_success "Outils de développement installés"
}

# Configuration des extensions VS Code
setup_vscode_extensions() {
    print_title "Configuration des extensions VS Code"
    
    # Liste des extensions essentielles
    extensions=(
        "GitHub.copilot"
        "ms-vscode.cpptools"
        "ms-python.python"
        "Extension Pack for Java"
        "ms-vscode.vscode-typescript-next"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-json"
        "redhat.vscode-yaml"
        "ms-azuretools.vscode-docker"
        "GitLens"
        "Auto Rename Tag"
        "Bracket Pair Colorizer"
        "Material Icon Theme"
        "One Dark Pro"
        "Live Server"
        "REST Client"
    )
    
    for extension in "${extensions[@]}"; do
        code --install-extension "$extension" &
    done
    wait
    
    print_success "Extensions VS Code installées"
}

# Installation des navigateurs et applications multimédia
install_browsers_media() {
    print_title "Installation des navigateurs et applications multimédia"
    
    # Navigateurs
    yay -S --noconfirm google-chrome brave-bin
    
    # Applications multimédia
    yay -S --noconfirm \
        spotify \
        netflix-desktop \
        disney-plus-desktop
    
    # Spicetify pour Spotify
    yay -S --noconfirm spicetify-cli
    
    print_success "Navigateurs et applications multimédia installés"
}

# Configuration de fastfetch avec logo Arch
setup_fastfetch() {
    print_title "Configuration de fastfetch"
    
    mkdir -p ~/.config/fastfetch
    
    cat > ~/.config/fastfetch/config.jsonc << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "builtin",
        "source": "arch"
        // "source": "/path/to/custom/image.png"  // Décommentez pour une image personnalisée
    },
    "display": {
        "separator": " -> ",
        "color": {
            "keys": "cyan",
            "output": "white"
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
    
    print_success "fastfetch configuré"
}

# Configuration d'Hyprland avec thèmes Arcane/Gaming
setup_hyprland_config() {
    print_title "Configuration d'Hyprland avec thème Gaming/Arcane"
    
    mkdir -p ~/.config/hypr
    
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration - Gaming/Arcane Theme
# Monitor configuration
monitor=,preferred,auto,1

# Input configuration
input {
    kb_layout = fr
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    
    follow_mouse = 1
    sensitivity = 0
    
    touchpad {
        natural_scroll = yes
    }
}

# General configuration
general {
    gaps_in = 8
    gaps_out = 12
    border_size = 3
    col.active_border = rgba(00d4ffee) rgba(a855f7ee) 45deg
    col.inactive_border = rgba(595959aa)
    
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 12
    
    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        xray = true
    }
    
    drop_shadow = yes
    shadow_range = 15
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = yes
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, overshot
}

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Gestures
gestures {
    workspace_swipe = on
}

# Miscellaneous
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    enable_swallow = true
    swallow_regex = ^(kitty)$
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(rofi)$

# Workspace rules
windowrulev2 = workspace 2, class:^(Google-chrome)$
windowrulev2 = workspace 2, class:^(brave-browser)$
windowrulev2 = workspace 3, class:^(code)$
windowrulev2 = workspace 4, class:^(spotify)$
windowrulev2 = workspace 5, class:^(discord)$

# Key bindings
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, rofi -show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, hyprlock
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

# Move active window to a workspace
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

# Scroll through existing workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Audio controls
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

# Brightness controls
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Media controls
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Screenshot
bind = , Print, exec, grim -g "$(slurp)"

# Auto-start applications
exec-once = waybar &
exec-once = dunst &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = swww init &
exec-once = hypridle &
exec-once = cliphist &

# Wallpaper (video)
exec-once = swww img ~/.config/wallpapers/video-wallpaper.mp4 --transition-type wipe --transition-duration 2
EOF
    
    print_success "Configuration Hyprland créée"
}

# Configuration de Waybar (barre des tâches transparente centrée)
setup_waybar() {
    print_title "Configuration de Waybar"
    
    mkdir -p ~/.config/waybar
    
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "width": 1200,
    "spacing": 4,
    
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "pulseaudio", "network", "battery", "custom/power"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "󰈹",
            "2": "󰖟",
            "3": "󰨞",
            "4": "󰎆",
            "5": "󰙯",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "hyprland/window": {
        "format": "{title}",
        "max-length": 50
    },
    
    "clock": {
        "interval": 1,
        "format": "{:%H:%M:%S}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% 󰂄",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) 󰤨",
        "format-ethernet": "{ipaddr}/{cidr} 󰈀",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "󰸈",
        "format-icons": {
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    
    "tray": {
        "spacing": 10
    },
    
    "custom/power": {
        "format": "⏻",
        "on-click": "wlogout"
    }
}
EOF
    
    cat > ~/.config/waybar/style.css << 'EOF'
* {
    font-family: 'JetBrains Mono', monospace;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.8);
    border-radius: 15px;
    color: #ffffff;
    transition-property: background-color;
    transition-duration: 0.5s;
    margin-top: 8px;
    margin-left: 360px;
    margin-right: 360px;
}

#workspaces {
    background-color: rgba(26, 27, 38, 0.6);
    border-radius: 10px;
    margin: 4px;
    padding: 0 5px;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #ffffff;
    border: none;
    border-radius: 8px;
    transition: all 0.3s ease;
}

#workspaces button:hover {
    background-color: rgba(168, 85, 247, 0.4);
    box-shadow: inset 0 -3px #a855f7;
}

#workspaces button.active {
    background-color: rgba(0, 212, 255, 0.6);
    color: #ffffff;
}

#clock {
    background-color: rgba(26, 27, 38, 0.6);
    border-radius: 10px;
    margin: 4px;
    padding: 0 15px;
    color: #00d4ff;
    font-weight: bold;
}

#battery,
#network,
#pulseaudio,
#tray,
#custom-power {
    background-color: rgba(26, 27, 38, 0.6);
    border-radius: 10px;
    margin: 4px;
    padding: 0 10px;
}

#battery {
    color: #50fa7b;
}

#battery.warning {
    color: #f1fa8c;
}

#battery.critical {
    color: #ff5555;
}

#network {
    color: #8be9fd;
}

#pulseaudio {
    color: #bd93f9;
}

#custom-power {
    color: #ff79c6;
}

#custom-power:hover {
    background-color: rgba(255, 121, 198, 0.3);
}
EOF
    
    print_success "Waybar configuré"
}

# Configuration d'hyprlock (écran de verrouillage Fallout/Arcane)
setup_hyprlock() {
    print_title "Configuration d'hyprlock avec thème Fallout/Arcane"
    
    mkdir -p ~/.config/hypr
    
    cat > ~/.config/hypr/hyprlock.conf << 'EOF'
# Hyprlock configuration - Fallout/Arcane theme
general {
    disable_loading_bar = false
    grace = 0
    hide_cursor = true
    no_fade_in = false
}

background {
    monitor = 
    path = ~/.config/wallpapers/lock-screen.jpg
    blur_passes = 3
    blur_size = 8
    brightness = 0.4
}

# Avatar
image {
    monitor = 
    path = ~/.config/avatars/user-avatar.png
    size = 150
    rounding = -1
    border_size = 4
    border_color = rgba(0, 212, 255, 1)
    position = 0, 60
    halign = center
    valign = center
}

# Input field
input-field {
    monitor =
    size = 300, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    outer_color = rgba(0, 212, 255, 1)
    inner_color = rgba(26, 27, 38, 0.9)
    font_color = rgba(255, 255, 255, 1)
    fade_on_empty = true
    placeholder_text = <span foreground="##a855f7">Entrez votre mot de passe...</span>
    hide_input = false
    position = 0, -80
    halign = center
    valign = center
}

# Time
label {
    monitor =
    text = cmd[update:1000] echo "<span foreground='##00d4ff'>$(date +'%H:%M:%S')</span>"
    font_size = 64
    font_family = JetBrains Mono
    position = 0, 200
    halign = center
    valign = center
}

# Date
label {
    monitor =
    text = cmd[update:1000] echo "<span foreground='##a855f7'>$(date +'%A, %d %B %Y')</span>"
    font_size = 20
    font_family = JetBrains Mono
    position = 0, 150
    halign = center
    valign = center
}

# User name
label {
    monitor =
    text = Bienvenue, $USER
    font_size = 18
    font_family = JetBrains Mono
    color = rgba(255, 255, 255, 1)
    position = 0, -30
    halign = center
    valign = center
}

# Système info
label {
    monitor =
    text = cmd[update:5000] echo "<span foreground='##50fa7b'>$(uname -r)</span>"
    font_size = 12
    font_family = JetBrains Mono
    position = 0, -200
    halign = center
    valign = center
}
EOF
    
    print_success "Hyprlock configuré"
}

# Installation du détecteur de basses sonores
install_bass_detector() {
    print_title "Installation du détecteur de basses sonores"
    
    # Installation de cava pour la visualisation audio
    sudo pacman -S --noconfirm cava
    
    # Configuration de cava
    mkdir -p ~/.config/cava
    
    cat > ~/.config/cava/config << 'EOF'
[general]
mode = normal
framerate = 60
autosens = 1
overshoot = 20
sensitivity = 100

[input]
method = pulse
source = auto

[output]
method = ncurses
channels = stereo
mono_option = average
reverse = 0
raw_target = /dev/stdout
data_format = binary
bit_format = 16bit
ascii_max_range = 1000

[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '#00d4ff'
gradient_color_2 = '#a855f7'
gradient_color_3 = '#50fa7b'
gradient_color_4 = '#f1fa8c'
gradient_color_5 = '#ff79c6'
gradient_color_6 = '#ff5555'

[smoothing]
monstercat = 1
waves = 0
gravity = 200
ignore = 0

[eq]
1 = 2
2 = 2
3 = 1
4 = 1
5 = 0.5
EOF
    
    print_success "Détecteur de basses installé (cava)"
}

# Configuration des fonds d'écran et animations
setup_wallpapers() {
    print_title "Configuration des fonds d'écran"
    
    mkdir -p ~/.config/wallpapers
    mkdir -p ~/.config/avatars
    
    # Téléchargement des fonds d'écran Arcane/Fallout
    cd ~/.config/wallpapers
    
    # Fond d'écran Arcane (exemple)
    wget -O arcane-wallpaper.jpg "https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
    
    # Fond d'écran Fallout pour l'écran de verrouillage
    wget -O lock-screen.jpg "https://images.unsplash.com/photo-1518709268805-4e9042af2176?ixlib=rb-4.0.3&auto=format&fit=crop&w=1920&q=80"
    
    # Script pour fond d'écran vidéo avec swww
    cat > ~/.config/hypr/wallpaper-changer.sh << 'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/.config/wallpapers"
VIDEO_EXTENSIONS=("mp4" "avi" "mkv" "webm")

# Fonction pour changer le fond d'écran
change_wallpaper() {
    local file="$1"
    if [[ "${VIDEO_EXTENSIONS[@]}" =~ "${file##*.}" ]]; then
        # Si c'est une vidéo
        swww img "$file" --transition-type wipe --transition-duration 2
    else
        # Si c'est une image
        swww img "$file" --transition-type fade --transition-duration 1
    fi
}

# Changer le fond d'écran toutes les 30 minutes
while true; do
    for wallpaper in "$WALLPAPER_DIR"/*; do
        if [[ -f "$wallpaper" ]]; then
            change_wallpaper "$wallpaper"
            sleep 1800  # 30 minutes
        fi
    done
done
EOF
    
    chmod +x ~/.config/hypr/wallpaper-changer.sh
    
    print_success "Fonds d'écran configurés"
}

# Configuration de Spicetify pour Spotify
setup_spicetify() {
    print_title "Configuration de Spicetify"
    
    # Installation et configuration de Spicetify
    curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
    
    # Ajout au PATH
    echo 'export PATH="$HOME/.spicetify:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.spicetify:$PATH"
    
    # Configuration de Spotify pour Spicetify
    sudo chmod a+wr /opt/spotify/Apps -R
    
    # Application du thème Arcane
    spicetify config current_theme Dribbblish
    spicetify config color_scheme purple
    spicetify apply
    
    print_success "Spicetify configuré"
}

# Installation d'animation Fallout pour l'écran de verrouillage
install_fallout_animation() {
    print_title "Installation de l'animation Fallout"
    
    # Recherche d'animations Fallout sur GitHub
    cd /tmp
    
    # Téléchargement d'une animation de terminal style Fallout
    if git clone https://github.com/bartobri/no-more-secrets.git 2>/dev/null; then
        cd no-more-secrets
        make nms
        make sneakers
        sudo make install
        print_success "Animation 'no-more-secrets' installée (style Fallout)"
    fi
    
    # Installation d'hollywood (effet hacker/terminal)
    yay -S --noconfirm hollywood
    
    # Script d'animation personnalisé pour l'écran de verrouillage
    cat > ~/.config/hypr/fallout-boot.sh << 'EOF'
#!/bin/bash

# Animation de boot style Fallout
clear
echo -e "\033[32m"
echo "████████  ████████  ██        ██        ██████    ██    ██  ████████"
echo "██        ██    ██  ██        ██        ██    ██  ██    ██     ██   "
echo "██████    ████████  ██        ██        ██    ██  ██    ██     ██   "
echo "██        ██    ██  ██        ██        ██    ██  ██    ██     ██   "
echo "██        ██    ██  ████████  ████████  ██████      ██████      ██   "
echo -e "\033[0m"
echo
echo -e "\033[33mSYSTÈME EN COURS D'INITIALISATION...\033[0m"
sleep 2

echo -e "\033[36m[OK]\033[0m Chargement des modules noyau"
sleep 0.5
echo -e "\033[36m[OK]\033[0m Configuration réseau"
sleep 0.5
echo -e "\033[36m[OK]\033[0m Initialisation Hyprland"
sleep 0.5
echo -e "\033[36m[OK]\033[0m Chargement des thèmes"
sleep 0.5
echo -e "\033[32mSYSTÈME PRÊT\033[0m"
sleep 1
EOF
    
    chmod +x ~/.config/hypr/fallout-boot.sh
    
    print_success "Animation Fallout configurée"
}

# Configuration des icônes modernes et transparence
setup_modern_theme() {
    print_title "Configuration du thème moderne avec transparence"
    
    # Installation des thèmes GTK
    yay -S --noconfirm \
        arc-gtk-theme \
        arc-icon-theme \
        papirus-icon-theme \
        numix-circle-icon-theme-git \
        tela-circle-icon-theme-git \
        sweet-theme-git \
        candy-icons-git
    
    # Configuration des thèmes système
    mkdir -p ~/.config/gtk-3.0
    mkdir -p ~/.config/gtk-4.0
    
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrains Mono 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF
    
    # Configuration de Qt
    echo 'export QT_QPA_PLATFORMTHEME=gtk2' >> ~/.bashrc
    
    print_success "Thème moderne configuré"
}

# Configuration finale et scripts de démarrage
setup_autostart() {
    print_title "Configuration des scripts de démarrage"
    
    # Script de démarrage principal
    cat > ~/.config/hypr/autostart.sh << 'EOF'
#!/bin/bash

# Script de démarrage automatique pour Hyprland

# Attendre que Hyprland soit complètement chargé
sleep 2

# Démarrage des services essentiels
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
dunst &
nm-applet &
blueman-applet &

# Initialisation de swww pour les fonds d'écran
swww init
sleep 1

# Démarrage du changeur de fond d'écran
~/.config/hypr/wallpaper-changer.sh &

# Démarrage de waybar
waybar &

# Démarrage du daemon d'historique du presse-papier
wl-paste --watch cliphist store &

# Démarrage d'hypridle
hypridle &

# Démarrage des applications en arrière-plan
discord --start-minimized &
spotify &

# Configuration de l'audio
sleep 3
pactl set-default-sink $(pactl list short sinks | grep -E "(analog|stereo)" | head -1 | cut -f1)

# Notification de démarrage terminé
notify-send "Système prêt" "Hyprland chargé avec succès" --icon=dialog-information
EOF
    
    chmod +x ~/.config/hypr/autostart.sh
    
    # Ajout à la configuration Hyprland
    echo "exec-once = ~/.config/hypr/autostart.sh" >> ~/.config/hypr/hyprland.conf
    
    print_success "Scripts de démarrage configurés"
}

# Configuration de l'audio et des effets sonores
setup_audio_effects() {
    print_title "Configuration de l'audio et des effets sonores"
    
    # Installation des outils audio avancés
    sudo pacman -S --noconfirm \
        pulseeffects \
        easyeffects \
        lsp-plugins \
        calf \
        mda.lv2
    
    # Configuration des effets audio
    mkdir -p ~/.config/easyeffects/output
    mkdir -p ~/.config/easyeffects/input
    
    # Téléchargement de sons système style Fallout/Cyberpunk
    mkdir -p ~/.local/share/sounds/custom
    
    # Sons de notification (vous devrez les télécharger depuis des sources libres)
    cat > ~/.config/sounds-setup.sh << 'EOF'
#!/bin/bash
# Script pour télécharger des sons système personnalisés
# Remplacez ces URLs par des sources de sons libres

SOUND_DIR="$HOME/.local/share/sounds/custom"
mkdir -p "$SOUND_DIR"

# Exemple de téléchargement de sons libres (à personnaliser)
# wget -O "$SOUND_DIR/notification.wav" "URL_DU_SON_LIBRE"
# wget -O "$SOUND_DIR/login.wav" "URL_DU_SON_LIBRE"
# wget -O "$SOUND_DIR/logout.wav" "URL_DU_SON_LIBRE"

echo "Configuration des sons terminée"
EOF
    
    chmod +x ~/.config/sounds-setup.sh
    
    print_success "Audio et effets sonores configurés"
}

# Installation de tous les outils réseau et programmation
install_network_programming_tools() {
    print_title "Installation des outils réseau et de programmation avancés"
    
    # Outils réseau avancés
    sudo pacman -S --noconfirm \
        nmap zenmap \
        wireshark-qt tshark \
        ettercap \
        aircrack-ng \
        hashcat \
        john \
        hydra \
        sqlmap \
        metasploit \
        nikto \
        dirb \
        gobuster \
        ffuf \
        masscan \
        rustscan \
        whatweb \
        wpscan \
        nuclei
    
    # Outils de développement avancés
    sudo pacman -S --noconfirm \
        gdb lldb \
        valgrind \
        strace ltrace \
        binutils \
        radare2 \
        ghidra \
        ida-free \
        burpsuite \
        zaproxy \
        sqlitebrowser \
        postman-bin \
        insomnia
    
    # Langages et frameworks
    sudo pacman -S --noconfirm \
        rust cargo \
        go \
        php composer \
        ruby rubygems \
        perl \
        lua \
        kotlin \
        scala \
        clojure \
        erlang elixir \
        haskell-platform
    
    # Outils DevOps
    sudo pacman -S --noconfirm \
        docker docker-compose \
        kubectl helm \
        terraform \
        ansible \
        vagrant \
        virtualbox \
        qemu virt-manager
    
    # Bases de données
    sudo pacman -S --noconfirm \
        postgresql \
        mariadb \
        mongodb \
        redis \
        sqlite
    
    print_success "Outils réseau et programmation installés"
}

# Configuration des raccourcis et gestures
setup_shortcuts() {
    print_title "Configuration des raccourcis personnalisés"
    
    # Ajout de raccourcis supplémentaires à la configuration Hyprland
    cat >> ~/.config/hypr/hyprland.conf << 'EOF'

# Raccourcis personnalisés supplémentaires
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod, period, exec, rofi -show emoji
bind = $mainMod, C, exec, code
bind = $mainMod, B, exec, brave
bind = $mainMod, G, exec, google-chrome-stable
bind = $mainMod SHIFT, T, exec, thunar
bind = $mainMod, T, exec, kitty
bind = $mainMod SHIFT, R, exec, hyprctl reload
bind = $mainMod SHIFT, Q, exec, wlogout
bind = $mainMod, Space, exec, rofi -show drun
bind = $mainMod SHIFT, Space, exec, rofi -show run
bind = $mainMod, Tab, workspace, previous
bind = $mainMod SHIFT, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy

# Contrôles audio/media avancés
bind = $mainMod SHIFT, P, exec, playerctl play-pause
bind = $mainMod SHIFT, N, exec, playerctl next
bind = $mainMod SHIFT, B, exec, playerctl previous
bind = $mainMod SHIFT, M, exec, pavucontrol

# Raccourcis pour applications spécifiques
bind = $mainMod, S, exec, spotify
bind = $mainMod, D, exec, discord
bind = $mainMod, A, exec, android-studio
bind = $mainMod, N, exec, netflix-desktop

# Gestion des fenêtres avancée
bind = $mainMod ALT, left, resizeactive, -50 0
bind = $mainMod ALT, right, resizeactive, 50 0
bind = $mainMod ALT, up, resizeactive, 0 -50
bind = $mainMod ALT, down, resizeactive, 0 50

# Contrôles système
bind = $mainMod SHIFT, L, exec, hyprlock
bind = $mainMod CTRL, R, exec, hyprctl reload && notify-send "Hyprland" "Configuration rechargée"
bind = $mainMod CTRL, Q, exec, wlogout
EOF
    
    print_success "Raccourcis configurés"
}

# Exécution du script principal
main "$@"