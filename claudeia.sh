# ========================================
# Arch Linux + Hyprland Complete Setup
# Style: Dev/Gaming/Arcane Theme
# ========================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logo ASCII Art
print_logo() {
    echo -e "${PURPLE}"
    echo "    ╔══════════════════════════════════════╗"
    echo "    ║     ARCH LINUX HYPRLAND SETUP       ║"
    echo "    ║        Dev • Gaming • Arcane        ║"
    echo "    ╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Ne pas exécuter en tant que root!"
    fi
}

# Check internet connection
check_internet() {
    log "Vérification de la connexion internet..."
    if ! ping -c 1 google.com &> /dev/null; then
        error "Pas de connexion internet!"
    fi
}

# System information
get_system_info() {
    log "Collecte des informations système..."
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.1f", $2/1024}')
    CPU_CORES=$(nproc)
    GPU_INFO=$(lspci | grep -E "VGA|3D" | head -1)
    
    echo -e "${CYAN}Mémoire: ${TOTAL_MEM}GB${NC}"
    echo -e "${CYAN}CPU Cores: ${CPU_CORES}${NC}"
    echo -e "${CYAN}GPU: ${GPU_INFO}${NC}"
}

# Update system
update_system() {
    log "Mise à jour du système..."
    sudo pacman -Syu --noconfirm
}

# Install AUR helper (yay)
install_yay() {
    if ! command -v yay &> /dev/null; then
        log "Installation de yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
    else
        log "yay déjà installé"
    fi
}

# Install base packages
install_base_packages() {
    log "Installation des paquets de base..."
    
    local packages=(
        # Base system
        "base-devel" "git" "curl" "wget" "unzip" "zip" "tar" "htop" "neofetch"
        "fastfetch" "tree" "vim" "nano" "zsh" "fish" "tmux" "screen"
        
        # Audio
        "pipewire" "pipewire-alsa" "pipewire-pulse" "pipewire-jack" "wireplumber"
        "pavucontrol" "alsa-utils" "cava" "pulseaudio-bass-boost"
        
        # Network tools
        "networkmanager" "network-manager-applet" "wireless_tools" "wpa_supplicant"
        "nmap" "wireshark-qt" "tcpdump" "netcat" "iperf3" "traceroute" "whois"
        "dnsutils" "openssh" "openvpn" "wireguard-tools"
        
        # Fonts and themes
        "ttf-font-awesome" "ttf-jetbrains-mono" "ttf-fira-code" "noto-fonts"
        "noto-fonts-emoji" "ttf-roboto" "ttf-ubuntu-font-family"
        
        # File management
        "ranger" "thunar" "thunar-volman" "thunar-archive-plugin" "gvfs"
        "file-roller" "p7zip" "unrar"
        
        # System monitoring
        "btop" "iotop" "lsof" "strace" "gdb" "valgrind"
        
        # Development tools
        "gcc" "clang" "make" "cmake" "ninja" "python" "python-pip" "nodejs" "npm"
        "jdk-openjdk" "jre-openjdk" "maven" "gradle" "docker" "docker-compose"
        
        # Wine
        "wine" "winetricks" "wine-gecko" "wine-mono"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# Install Hyprland and Wayland packages
install_hyprland() {
    log "Installation d'Hyprland et des composants Wayland..."
    
    local hyprland_packages=(
        "hyprland" "hyprpaper" "hyprlock" "hypridle" "hyprpicker"
        "waybar" "wofi" "mako" "grim" "slurp" "wl-clipboard"
        "xdg-desktop-portal-hyprland" "polkit-kde-agent" "qt5-wayland" "qt6-wayland"
        "wlroots" "wayland-protocols" "xorg-xwayland"
    )
    
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# Install AUR packages
install_aur_packages() {
    log "Installation des paquets AUR..."
    
    local aur_packages=(
        # Browsers
        "google-chrome" "brave-bin"
        
        # Development
        "visual-studio-code-bin" "android-studio"
        
        # Media
        "spotify" "spicetify-cli" "netflix-webapp" "disney-plus-webapp"
        
        # Themes and customization
        "nordic-theme" "papirus-icon-theme" "bibata-cursor-theme"
        
        # Audio visualization
        "cava-git" "glava"
        
        # Video wallpapers
        "mpvpaper" "swww-git"
        
        # Terminal
        "kitty-git" "oh-my-zsh-git"
        
        # Other
        "discord" "telegram-desktop" "notion-app"
    )
    
    yay -S --needed --noconfirm "${aur_packages[@]}"
}

# Configure fastfetch
setup_fastfetch() {
    log "Configuration de fastfetch..."
    
    mkdir -p ~/.config/fastfetch
    cat > ~/.config/fastfetch/config.jsonc << 'EOF'
{
    "logo": {
        "source": "arch",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": " -> ",
        "color": {
            "keys": "cyan",
            "separator": "white",
            "output": "blue"
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

    # Alternative with custom image (commented)
    cat > ~/.config/fastfetch/config_image.jsonc << 'EOF'
{
    "logo": {
        // "source": "/path/to/your/custom/image.png",
        "source": "arch",
        "width": 40,
        "height": 20,
        "padding": {
            "top": 1,
            "left": 2
        }
    }
}
EOF
}

# Setup audio with bass detection
setup_audio() {
    log "Configuration audio avec détection des basses..."
    
    # Enable audio services
    systemctl --user enable --now pipewire pipewire-pulse wireplumber
    
    # Install and configure cava for audio visualization
    mkdir -p ~/.config/cava
    cat > ~/.config/cava/config << 'EOF'
[general]
bars = 50
framerate = 60
sensitivity = 100
autosens = 1

[input]
method = pulse
source = auto

[output]
method = ncurses
style = stereo
bar_width = 2
bar_spacing = 1

[color]
gradient = 1
gradient_count = 6
gradient_color_1 = '#6441A4'
gradient_color_2 = '#2DF5FF'
gradient_color_3 = '#FFA500'
gradient_color_4 = '#FF6B35'
gradient_color_5 = '#F7931E'
gradient_color_6 = '#FFD700'

[smoothing]
noise_reduction = 77
integral = 77
gravity = 100
ignore = 0

[eq]
1 = 2
2 = 2
3 = 1
4 = 1
5 = 0.5
EOF
}

# Configure transparent backgrounds and modern styling
setup_transparency() {
    log "Configuration des arrière-plans transparents..."
    
    # Kitty terminal transparency
    mkdir -p ~/.config/kitty
    cat > ~/.config/kitty/kitty.conf << 'EOF'
# Font configuration
font_family JetBrains Mono
font_size 12.0
bold_font auto
italic_font auto
bold_italic_font auto

# Transparency
background_opacity 0.85
dynamic_background_opacity yes

# Colors (Arcane theme inspired)
background #0f0f0f
foreground #c9aa71
selection_background #6441a4
selection_foreground #c9aa71

# Normal colors
color0 #0f0f0f
color1 #ff6b35
color2 #2df5ff
color3 #ffa500
color4 #6441a4
color5 #f7931e
color6 #2df5ff
color7 #c9aa71

# Bright colors
color8 #555555
color9 #ff8c69
color10 #5ffaff
color11 #ffd700
color12 #8a2be2
color13 #ffa500
color14 #5ffaff
color15 #ffffff

# Cursor
cursor #c9aa71
cursor_text_color #0f0f0f

# Window settings
window_padding_width 10
confirm_os_window_close 0
EOF
}

# Setup video wallpapers
setup_video_wallpapers() {
    log "Configuration des fonds d'écran vidéo..."
    
    # Create wallpapers directory
    mkdir -p ~/Pictures/wallpapers/videos
    
    # Download Arcane/Fallout themed video wallpapers
    cd ~/Pictures/wallpapers/videos
    
    # Note: Ces liens sont des exemples, remplacez par de vrais liens
    echo "# Téléchargez vos fonds d'écran vidéo ici" > README.md
    echo "# Formats supportés: .mp4, .webm, .gif" >> README.md
    
    # Configure swww for video wallpapers
    cat > ~/.config/hypr/wallpaper.sh << 'EOF'
#!/bin/bash
# Video wallpaper script

# Kill existing wallpaper daemon
pkill swww-daemon 2>/dev/null || true
sleep 1

# Start swww daemon
swww-daemon &
sleep 2

# Set video wallpaper
WALLPAPER_DIR="$HOME/Pictures/wallpapers/videos"
if [ -d "$WALLPAPER_DIR" ] && [ "$(ls -A $WALLPAPER_DIR/*.{mp4,webm,gif} 2>/dev/null)" ]; then
    WALLPAPER=$(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.webm" -o -name "*.gif" | shuf -n 1)
    swww img "$WALLPAPER" --transition-type fade --transition-duration 2
else
    # Fallback to static image
    swww img "$HOME/Pictures/wallpapers/default.jpg" --transition-type fade --transition-duration 2
fi
EOF
    
    chmod +x ~/.config/hypr/wallpaper.sh
}

# Setup Hyprland configuration
setup_hyprland_config() {
    log "Configuration d'Hyprland..."
    
    mkdir -p ~/.config/hypr
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration - Arcane/Dev/Gaming Theme

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
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
    sensitivity = 0
}

# General settings
general {
    gaps_in = 10
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(6441A4ee) rgba(2DF5FFee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 15
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
        ignore_opacity = true
    }
    
    active_opacity = 0.95
    inactive_opacity = 0.85
    fullscreen_opacity = 1.0
    
    drop_shadow = true
    shadow_range = 30
    shadow_render_power = 3
    col.shadow = 0x66000000
    col.shadow_inactive = 0x66000000
    
    dim_inactive = false
    dim_strength = 0.1
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = smooth, 0.25, 0.1, 0.25, 1
    bezier = fadeIn, 0, 0, 0.58, 1
    bezier = fadeOut, 0.42, 0, 1, 1
    
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
    animation = specialWorkspace, 1, 6, myBezier, slidevert
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
    force_split = 2
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# Miscellaneous
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    vfr = true
    vrr = 1
}

# Window rules
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.85 0.85,class:^(thunar)$
windowrulev2 = opacity 1.0 override,class:^(google-chrome)$
windowrulev2 = opacity 1.0 override,class:^(brave-browser)$
windowrulev2 = opacity 1.0 override,class:^(firefox)$
windowrulev2 = opacity 1.0 override,class:^(discord)$
windowrulev2 = opacity 1.0 override,class:^(Spotify)$

# Startup applications
exec-once = waybar
exec-once = mako
exec-once = ~/.config/hypr/wallpaper.sh
exec-once = /usr/lib/polkit-kde-authentication-agent-1

# Key bindings
$mainMod = SUPER

# Application launchers
bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive
bind = $mainMod, M, exit
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating
bind = $mainMod, R, exec, wofi --show drun
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit
bind = $mainMod, F, fullscreen, 1
bind = $mainMod SHIFT, F, fullscreen, 0

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Audio controls
bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

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

# Move windows to workspace
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

# Mouse bindings
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF
}

# Setup Waybar (transparent centered taskbar)
setup_waybar() {
    log "Configuration de Waybar..."
    
    mkdir -p ~/.config/waybar
    
    # Waybar configuration
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "width": 1200,
    "margin-left": 360,
    "margin-right": 360,
    "margin-top": 10,
    "spacing": 8,
    "modules-left": ["hyprland/workspaces", "hyprland/mode"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    
    "hyprland/workspaces": {
        "format": "{icon}",
        "format-icons": {
            "1": "󰈹",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "6": "",
            "7": "",
            "8": "",
            "9": "󰕧",
            "10": ""
        },
        "persistent_workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },
    
    "clock": {
        "timezone": "Europe/Brussels",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}"
    },
    
    "battery": {
        "states": {
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
        "format-wifi": "{signalStrength}% ",
        "format-ethernet": "",
        "tooltip-format": "{ifname} via {gwaddr}",
        "format-linked": "{ifname} (No IP)",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
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
    },
    
    "tray": {
        "icon-size": 21,
        "spacing": 10
    }
}
EOF

    # Waybar styling
    cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrains Mono", "Font Awesome 6 Free";
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(15, 15, 15, 0.8);
    border-radius: 20px;
    border: 2px solid rgba(100, 65, 164, 0.6);
    backdrop-filter: blur(10px);
    color: #c9aa71;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 15px;
    margin: 5px 3px;
    padding: 0 8px;
    color: #c9aa71;
    background: transparent;
}

#workspaces button {
    padding: 0 8px;
    margin: 4px 2px;
    background: rgba(100, 65, 164, 0.3);
    border-radius: 12px;
    transition: all 0.3s ease;
}

#workspaces button:hover {
    background: rgba(45, 245, 255, 0.4);
    transform: scale(1.1);
}

#workspaces button.active {
    background: linear-gradient(45deg, #6441A4, #2DF5FF);
    box-shadow: 0 0 10px rgba(100, 65, 164, 0.5);
}

#clock {
    background: linear-gradient(45deg, rgba(255, 163, 0, 0.3), rgba(247, 147, 30, 0.3));
    padding: 8px 16px;
    border-radius: 15px;
    font-weight: bold;
    margin: 4px;
}

#battery,
#network,
#pulseaudio,
#tray {
    background: rgba(100, 65, 164, 0.2);
    padding: 8px 12px;
    border-radius: 12px;
    margin: 4px 2px;
}

#battery.charging {
    background: rgba(45, 245, 255, 0.3);
}

#battery.warning {
    background: rgba(255, 163, 0, 0.4);
}

#battery.critical {
    background: rgba(255, 107, 53, 0.4);
}

#network.disconnected {
    background: rgba(255, 107, 53, 0.4);
}

#pulseaudio.muted {
    background: rgba(85, 85, 85, 0.4);
}
EOF
}

# Setup lock screen with Fallout/Arcane theme
setup_lockscreen() {
    log "Configuration de l'écran de verrouillage..."
    
    mkdir -p ~/.config/hypr
    
    # Download Fallout animation from GitHub (example)
    cd /tmp
    # git clone https://github.com/user/fallout-lockscreen-animation.git
    # Note: Remplacez par un vrai dépôt
    
    # Hyprlock configuration
    cat > ~/.config/hypr/hyprlock.conf << 'EOF'
general {
    disable_loading_bar = false
    grace = 0
    hide_cursor = true
    no_fade_in = false
    no_fade_out = false
}

background {
    monitor =
    path = ~/Pictures/wallpapers/lockscreen.jpg
    blur_passes = 3
    blur_size = 8
}

input-field {
    monitor =
    size = 300, 60
    outline_thickness = 2
    dots_size = 0.2
    dots_spacing = 0.2
    dots_center = true
    outer_color = rgba(100, 65, 164, 0.8)
    inner_color = rgba(15, 15, 15, 0.8)
    font_color = rgb(201, 170, 113)
    fade_on_empty = false
    placeholder_text = <span foreground="##c9aa71">Mot de passe...</span>
    hide_input = false
    position = 0, -120
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%-H:%M")"
    color = rgba(201, 170, 113, 0.8)
    font_size = 120
    font_family = JetBrains Mono ExtraBold
    position = 0, -300
    halign = center
    valign = top
}

label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%A, %B %d")"
    color = rgba(201, 170, 113, 0.6)
    font_size = 25
    font_family = JetBrains Mono
    position = 0, -420
    halign = center
    valign = top
}
EOF
    
    # Create default lockscreen wallpapers directory
    mkdir -p ~/Pictures/wallpapers
    
    # Download default lockscreen images
    echo "# Ajoutez vos images de fond d'écran de verrouillage ici" > ~/Pictures/wallpapers/README.md
    echo "# Images recommandées: Fallout, Arcane Netflix" >> ~/Pictures/wallpapers/README.md
}

# Install and configure GRUB with themes
setup_grub() {
    log "Installation et configuration de GRUB..."
    
    # Install GRUB and os-prober for multiboot
    sudo pacman -S --needed --noconfirm grub efibootmgr os-prober
    
    # Enable os-prober
    echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub
    
    # Create themes directory
    sudo mkdir -p /usr/share/grub/themes
    
    # Download and install GRUB themes
    cd /tmp
    
    log "Installation du thème GRUB Fallout..."
    # Note: Remplacez par de vrais dépôts GitHub
    echo "# Téléchargement des thèmes GRUB depuis GitHub" > grub_themes_install.log
    
    # Fallout theme (default)
    # git clone https://github.com/user/fallout-grub-theme.git
    # sudo cp -r fallout-grub-theme /usr/share/grub/themes/fallout
    
    # Other themes to be installed:
    themes_list=(
        "BSOL"
        "Minegrub-World-Select"
        "CRT-Amber"
        "Arcade"
        "Dark-Matter"
        "Arcane-Netflix"
        "Star-Wars"
        "Lord-of-the-Rings"
    )
    
    echo "# Thèmes GRUB disponibles:" >> grub_themes_install.log
    for theme in "${themes_list[@]}"; do
        echo "# - $theme" >> grub_themes_install.log
        # Installation logic would go here
        # git clone "https://github.com/user/$theme-grub-theme.git"
        # sudo cp -r "$theme-grub-theme" "/usr/share/grub/themes/$theme"
    done
    
    # Configure GRUB to use Fallout theme by default
    sudo sed -i 's/#GRUB_THEME=.*/GRUB_THEME="\/usr\/share\/grub\/themes\/fallout\/theme.txt"/' /etc/default/grub
    
    # Set GRUB timeout
    sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
    
    # Generate GRUB configuration
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    warn "GRUB installé avec thème Fallout par défaut. Voir README pour autres thèmes disponibles."
}

# Install development tools and IDEs
install_development_tools() {
    log "Installation des outils de développement..."
    
    # Java development
    sudo pacman -S --needed --noconfirm jdk-openjdk jre-openjdk maven gradle
    
    # Set JAVA_HOME
    echo 'export JAVA_HOME=/usr/lib/jvm/default' >> ~/.bashrc
    echo 'export JAVA_HOME=/usr/lib/jvm/default' >> ~/.zshrc
    
    # Install VS Code extensions via command line
    log "Installation des extensions VS Code..."
    
    local vscode_extensions=(
        "ms-vscode.cpptools"
        "ms-python.python"
        "Extension Pack for Java"
        "ms-vscode.vscode-typescript-next"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-eslint"
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "ms-dotnettools.csharp"
        "rust-lang.rust-analyzer"
        "golang.go"
        "ms-vscode.powershell"
        "ms-vscode.cmake-tools"
        "ms-vscode.hexeditor"
        "formulahendry.auto-rename-tag"
        "christian-kohler.path-intellisense"
        "ms-vscode.live-server"
        "ritwickdey.liveserver"
        "PKief.material-icon-theme"
        "zhuangtongfa.material-theme"
        "dracula-theme.theme-dracula"
        "GitHub.github-vscode-theme"
    )
    
    # Create VS Code extensions install script
    cat > ~/.local/bin/install-vscode-extensions.sh << 'EOF'
#!/bin/bash
extensions=(
    "ms-vscode.cpptools"
    "ms-python.python"
    "vscjava.vscode-java-pack"
    "ms-vscode.vscode-typescript-next"
    "bradlc.vscode-tailwindcss"
    "esbenp.prettier-vscode"
    "ms-vscode.vscode-eslint"
    "GitHub.copilot"
    "GitHub.copilot-chat"
    "ms-dotnettools.csharp"
    "rust-lang.rust-analyzer"
    "golang.go"
    "ms-vscode.powershell"
    "ms-vscode.cmake-tools"
    "formulahendry.auto-rename-tag"
    "christian-kohler.path-intellisense"
    "PKief.material-icon-theme"
    "zhuangtongfa.material-theme"
    "dracula-theme.theme-dracula"
)

for ext in "${extensions[@]}"; do
    echo "Installing $ext..."
    code --install-extension "$ext" --force
done
EOF
    
    chmod +x ~/.local/bin/install-vscode-extensions.sh
    
    # Additional development tools
    yay -S --needed --noconfirm postman-bin insomnia dbeaver gitkraken
}

# Setup Spotify with Spicetify
setup_spicetify() {
    log "Configuration de Spicetify pour Spotify..."
    
    # Install spicetify themes
    curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
    curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-themes/master/install.sh | sh
    
    # Apply Arcane-inspired theme
    spicetify config current_theme Dribbblish
    spicetify config color_scheme purple
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
    
    # Custom CSS for Arcane theme
    mkdir -p ~/.config/spicetify/Themes/Arcane
    cat > ~/.config/spicetify/Themes/Arcane/color.ini << 'EOF'
[purple]
text = c9aa71
subtext = a18956
main = 0f0f0f
sidebar = 1a1a1a
player = 0f0f0f
card = 1a1a1a
shadow = 000000
selected-row = 6441a4
button = 6441a4
button-active = 2df5ff
button-disabled = 555555
tab-active = 6441a4
notification = 2df5ff
notification-error = ff6b35
misc = 333333
EOF
    
    cat > ~/.config/spicetify/Themes/Arcane/user.css << 'EOF'
/* Arcane Theme for Spicetify */
:root {
    --spice-rgb-main: 15, 15, 15;
    --spice-rgb-sidebar: 26, 26, 26;
    --spice-rgb-player: 15, 15, 15;
    --spice-rgb-card: 26, 26, 26;
    --spice-rgb-shadow: 0, 0, 0;
    --spice-rgb-selected-row: 100, 65, 164;
    --spice-rgb-button: 100, 65, 164;
    --spice-rgb-button-active: 45, 245, 255;
    --spice-rgb-tab-active: 100, 65, 164;
    --spice-rgb-notification: 45, 245, 255;
}

.main-rootlist-rootlistDivider {
    background: linear-gradient(90deg, #6441A4, #2DF5FF);
    height: 2px;
}

.main-playButton-PlayButton {
    background: linear-gradient(135deg, #6441A4, #2DF5FF) !important;
    border-radius: 50%;
}

.main-playButton-PlayButton:hover {
    transform: scale(1.1);
    box-shadow: 0 0 20px rgba(100, 65, 164, 0.6);
}
EOF
    
    spicetify config current_theme Arcane
    spicetify apply
}

# Setup modern icons and cursor theme
setup_icons_and_cursors() {
    log "Configuration des icônes et curseurs modernes..."
    
    # Set icon theme
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    gsettings set org.gnome.desktop.interface gtk-theme 'Nordic-darker'
    
    # Configure icon theme for different applications
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Nordic-darker
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Ubuntu 11
gtk-application-prefer-dark-theme=1
EOF
    
    mkdir -p ~/.config/gtk-4.0
    cat > ~/.config/gtk-4.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Nordic-darker
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-font-name=Ubuntu 11
gtk-application-prefer-dark-theme=1
EOF
}

# Install network and programming tools
install_network_programming_tools() {
    log "Installation d'outils réseau et de programmation avancés..."
    
    local network_tools=(
        # Network analysis
        "wireshark-qt" "tcpdump" "nmap" "masscan" "zmap"
        "netcat" "socat" "iperf3" "bandwhich" "speedtest-cli"
        
        # Network utilities
        "traceroute" "mtr" "whois" "dig" "host" "nslookup"
        "curl" "wget" "httpie" "aria2"
        
        # Security tools
        "john" "hashcat" "aircrack-ng" "macchanger"
        "metasploit" "sqlmap" "gobuster" "dirb"
        
        # Development tools
        "gdb" "valgrind" "strace" "ltrace" "perf"
        "hexedit" "xxd" "binutils" "radare2"
    )
    
    # Install from official repos
    sudo pacman -S --needed --noconfirm "${network_tools[@]}"
    
    # Additional AUR packages
    local aur_network_tools=(
        "burpsuite" "zaproxy" "nessus" "openvas"
        "ghidra" "ida-free" "cutter-re"
        "sublime-text-4" "sublime-merge"
        "jetbrains-toolbox"
    )
    
    yay -S --needed --noconfirm "${aur_network_tools[@]}"
    
    # Install programming language environments
    log "Installation des environnements de programmation..."
    
    # Python tools
    pip install --user virtualenv pipenv poetry black autopep8 flake8 mypy
    pip install --user django flask fastapi requests beautifulsoup4 selenium
    pip install --user numpy pandas matplotlib seaborn scikit-learn tensorflow pytorch
    
    # Node.js tools
    sudo npm install -g yarn pnpm typescript ts-node
    sudo npm install -g @angular/cli @vue/cli create-react-app
    sudo npm install -g eslint prettier nodemon pm2
    
    # Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    
    # Go
    yay -S --needed --noconfirm go
    
    # Docker setup
    sudo usermod -aG docker $USER
    sudo systemctl enable --now docker
}

# Configure shell and terminal
setup_shell_environment() {
    log "Configuration de l'environnement shell..."
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install Zsh plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    
    # Configure .zshrc
    cat > ~/.zshrc << 'EOF'
# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
    git
    docker
    docker-compose
    node
    npm
    python
    rust
    golang
    vscode
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

source $ZSH/oh-my-zsh.sh

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Development aliases
alias code='code .'
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'
alias jsonpp='python3 -m json.tool'

# Network aliases
alias myip='curl ipinfo.io/ip'
alias ports='netstat -tulanp'
alias ping='ping -c 5'

# System aliases
alias df='df -H'
alias du='du -ch'
alias free='free -m'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias mkdir='mkdir -pv'
alias histg='history | grep'
alias myps='ps -f -u $USER'

# Fun aliases
alias matrix='cmatrix -s'
alias clock='tty-clock -c'
alias weather='curl wttr.in'
alias news='curl -s hackernews.api-search.io/api/v1/search\?tags\=front_page | jq'

# Environment variables
export EDITOR='code'
export VISUAL='code'
export BROWSER='google-chrome-stable'
export JAVA_HOME='/usr/lib/jvm/default'
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

# Auto-start fastfetch on new terminal
if [[ -z "$TMUX" ]] && [[ -z "$VTE_VERSION" ]]; then
    fastfetch
fi

# Custom functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

function backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Load custom functions if they exist
[ -f ~/.zsh_functions ] && source ~/.zsh_functions

# Load work-specific configuration if it exists
[ -f ~/.zsh_work ] && source ~/.zsh_work
EOF

    # Change default shell to zsh
    chsh -s $(which zsh)
}

# Setup Wine for Windows applications
setup_wine() {
    log "Configuration de Wine..."
    
    # Configure Wine prefix
    export WINEPREFIX="$HOME/.wine"
    
    # Initialize Wine
    winecfg &
    sleep 5
    pkill winecfg
    
    # Install common Windows libraries
    winetricks corefonts vcrun2019 dotnet48 d3dx9 d3dcompiler_47
    
    # Configure Wine for better performance
    cat > ~/.wine_setup.sh << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/.wine"

# Set Wine to Windows 10 mode
winecfg

# Install additional components as needed
# winetricks steam
# winetricks discord
EOF
    
    chmod +x ~/.wine_setup.sh
}

# Create desktop entries for applications
create_desktop_entries() {
    log "Création des entrées de bureau..."
    
    mkdir -p ~/.local/share/applications
    
    # Netflix webapp
    cat > ~/.local/share/applications/netflix.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Netflix
Comment=Watch Netflix
Exec=google-chrome-stable --app=https://netflix.com --name=Netflix
Icon=netflix
Categories=AudioVideo;Video;
StartupNotify=true
EOF

    # Disney+ webapp
    cat > ~/.local/share/applications/disneyplus.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Disney+
Comment=Watch Disney+
Exec=google-chrome-stable --app=https://disneyplus.com --name=DisneyPlus
Icon=disneyplus
Categories=AudioVideo;Video;
StartupNotify=true
EOF

    # Audio visualizer
    cat > ~/.local/share/applications/cava.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Audio Visualizer
Comment=CAVA Audio Visualizer
Exec=kitty -e cava
Icon=audio-headphones
Categories=AudioVideo;Audio;
StartupNotify=true
EOF

    # System monitor
    cat > ~/.local/share/applications/system-monitor.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=System Monitor
Comment=Advanced System Monitor
Exec=kitty -e btop
Icon=utilities-system-monitor
Categories=System;Monitor;
StartupNotify=true
EOF
}

# Setup systemd services
setup_services() {
    log "Configuration des services système..."
    
    # Enable NetworkManager
    sudo systemctl enable --now NetworkManager
    
    # Enable Docker (if installed)
    if command -v docker &> /dev/null; then
        sudo systemctl enable --now docker
    fi
    
    # Create user service for wallpaper
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/wallpaper.service << 'EOF'
[Unit]
Description=Dynamic Wallpaper Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.config/hypr/wallpaper.sh
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    
    # Enable wallpaper service
    systemctl --user enable --now wallpaper.service
}

# Final system optimization
optimize_system() {
    log "Optimisation finale du système..."
    
    # Create swap file if not enough RAM
    if (( $(echo "$TOTAL_MEM < 8" | bc -l) )); then
        log "Création d'un fichier swap (RAM < 8GB)..."
        sudo fallocate -l 4G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    # Optimize SSD (if applicable)
    if lsblk -d -o name,rota | grep -q 0; then
        log "Optimisation SSD détectée..."
        sudo systemctl enable --now fstrim.timer
    fi
    
    # Set up automatic package cache cleaning
    sudo systemctl enable --now paccache.timer
    
    # Configure DNS for better performance
    echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf
    echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
    
    # Optimize boot time
    sudo systemctl disable --now bluetooth.service  # Can be re-enabled if needed
    
    # Set performance governor for CPU (gaming optimization)
    echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
}

# Main installation function
main() {
    print_logo
    
    log "Début de l'installation Arch Linux + Hyprland..."
    log "Style: Dev • Gaming • Arcane Theme"
    echo
    
    # Pre-installation checks
    check_root
    check_internet
    get_system_info
    
    echo
    read -p "Continuer l'installation ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Installation annulée."
        exit 1
    fi
    
    log "Démarrage de l'installation..."
    
    # Installation steps
    update_system
    install_yay
    install_base_packages
    install_hyprland
    install_aur_packages
    
    # Configuration steps
    setup_fastfetch
    setup_audio
    setup_transparency
    setup_video_wallpapers
    setup_hyprland_config
    setup_waybar
    setup_lockscreen
    setup_grub
    
    # Development environment
    install_development_tools
    setup_spicetify
    setup_icons_and_cursors
    install_network_programming_tools
    setup_shell_environment
    setup_wine
    
    # Final setup
    create_desktop_entries
    setup_services
    optimize_system
    
    log "Installation terminée !"
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
    echo -e "║                    INSTALLATION TERMINÉE                    ║"
    echo -e "║                                                              ║"
    echo -e "║  • Redémarrez le système pour appliquer tous les changements║"
    echo -e "║  • Lancez 'Hyprland' depuis votre gestionnaire de session  ║"
    echo -e "║  • Exécutez ~/.local/bin/install-vscode-extensions.sh       ║"
    echo -e "║    pour installer les extensions VS Code                    ║"
    echo -e "║  • Consultez le README.md pour les thèmes GRUB disponibles  ║"
    echo -e "║                                                              ║"
    echo -e "║  Enjoy your new Arcane-themed Arch Linux setup! 🚀         ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    log "Commandes utiles post-installation :"
    echo -e "${CYAN}  • Changer le fond d'écran : ~/.config/hypr/wallpaper.sh${NC}"
    echo -e "${CYAN}  • Visualiseur audio : cava${NC}"
    echo -e "${CYAN}  • Moniteur système : btop${NC}"
    echo -e "${CYAN}  • Informations système : fastfetch${NC}"
    echo -e "${CYAN}  • Thème Spicetify : spicetify apply${NC}"
    
    warn "N'oubliez pas de :"
    warn "1. Configurer vos comptes (GitHub, services cloud, etc.)"
    warn "2. Importer vos données depuis vos sauvegardes"
    warn "3. Personnaliser les raccourcis clavier dans Hyprland"
    warn "4. Installer les thèmes GRUB additionnels si désiré"
    
    read -p "Redémarrer maintenant ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Redémarrage du système..."
        sleep 3
        sudo reboot
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi