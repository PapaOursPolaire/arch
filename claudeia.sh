#!/bin/bash
# =============================================================================
# Script d'installation Arch Linux + Hyprland avec thème Dev/Gaming/Arcane
# =============================================================================
# Auteur: Generated for custom Arch setup
# Description: Installation complète d'Arch Linux avec environnement Hyprland
# =============================================================================

set -e  # Arrêt en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
USERNAME=""
PASSWORD=""
HOSTNAME=""
DISK=""
ROOT_PARTITION=""
HOME_PARTITION=""
BOOT_PARTITION=""

# Fonction d'affichage stylisé
print_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║              ARCH LINUX + HYPRLAND INSTALLER                      ║"
    echo "║                   Dev/Gaming/Arcane Theme                         ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}$1${NC}"
    echo
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
    exit 1
}

# Configuration initiale
setup_variables() {
    print_header "Configuration des variables"
    
    echo -e "${CYAN}Nom d'utilisateur:${NC}"
    read -p "> " USERNAME
    
    echo -e "${CYAN}Mot de passe utilisateur:${NC}"
    read -s PASSWORD
    echo
    
    echo -e "${CYAN}Nom de la machine:${NC}"
    read -p "> " HOSTNAME
    
    echo -e "${CYAN}Disque d'installation (ex: /dev/sda):${NC}"
    lsblk
    read -p "> " DISK
    
    echo -e "${CYAN}Partition root existante (ex: /dev/sda2):${NC}"
    read -p "> " ROOT_PARTITION
    
    echo -e "${CYAN}Partition home existante (ex: /dev/sda3):${NC}"
    read -p "> " HOME_PARTITION
    
    echo -e "${CYAN}Partition boot/EFI existante (ex: /dev/sda1):${NC}"
    read -p "> " BOOT_PARTITION
}

# Préparation du système
prepare_system() {
    print_header "Préparation du système"
    
    log "Mise à jour de l'horloge système"
    timedatectl set-ntp true
    
    log "Montage des partitions existantes"
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/home
    mount $HOME_PARTITION /mnt/home
    mkdir -p /mnt/boot
    mount $BOOT_PARTITION /mnt/boot
    
    log "Configuration des miroirs"
    reflector --country France,Germany,Netherlands --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
}

# Installation du système de base
install_base_system() {
    print_header "Installation du système de base"
    
    log "Installation des paquets de base"
    pacstrap /mnt base base-devel linux linux-firmware linux-headers
    
    log "Génération du fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    
    log "Configuration du système dans chroot"
    arch-chroot /mnt /bin/bash -c "
        # Timezone et locale
        ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
        hwclock --systohc
        
        echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
        echo 'fr_FR.UTF-8 UTF-8' >> /etc/locale.gen
        locale-gen
        echo 'LANG=en_US.UTF-8' > /etc/locale.conf
        
        # Hostname
        echo '$HOSTNAME' > /etc/hostname
        echo '127.0.0.1 localhost' > /etc/hosts
        echo '::1 localhost' >> /etc/hosts
        echo '127.0.1.1 $HOSTNAME.localdomain $HOSTNAME' >> /etc/hosts
        
        # Root password
        echo 'root:password123' | chpasswd
    "
}

# Installation des pilotes et utilitaires
install_drivers_utilities() {
    print_header "Installation des pilotes et utilitaires"
    
    arch-chroot /mnt /bin/bash -c "
        # Pilotes graphiques
        pacman -S --noconfirm mesa vulkan-radeon vulkan-intel nvidia nvidia-utils
        
        # Son
        pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
        
        # Réseau
        pacman -S --noconfirm networkmanager wpa_supplicant dhcpcd iwd
        systemctl enable NetworkManager
        
        # Utilitaires système
        pacman -S --noconfirm git wget curl unzip p7zip neofetch fastfetch htop btop
        pacman -S --noconfirm vim nano sudo bash-completion man-db
        
        # Bluetooth
        pacman -S --noconfirm bluez bluez-utils
        systemctl enable bluetooth
    "
}

# Installation de Hyprland et environnement graphique
install_hyprland() {
    print_header "Installation de Hyprland et environnement graphique"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation de Hyprland depuis les dépôts officiels
        pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland
        
        # Gestionnaire de connexion
        pacman -S --noconfirm sddm
        systemctl enable sddm
        
        # Terminal et utilitaires Wayland
        pacman -S --noconfirm kitty wofi waybar
        pacman -S --noconfirm swww grim slurp wl-clipboard
        pacman -S --noconfirm mako dunst
        
        # Gestionnaire de fichiers et utilitaires
        pacman -S --noconfirm thunar thunar-volman thunar-archive-plugin
        pacman -S --noconfirm file-roller ark
        
        # Polices
        pacman -S --noconfirm ttf-font-awesome ttf-fira-code noto-fonts noto-fonts-emoji
        pacman -S --noconfirm ttf-jetbrains-mono ttf-roboto
    "
}

# Installation des logiciels de développement
install_dev_tools() {
    print_header "Installation des outils de développement"
    
    arch-chroot /mnt /bin/bash -c "
        # Langages de programmation
        pacman -S --noconfirm python python-pip nodejs npm
        pacman -S --noconfirm jdk-openjdk openjdk-doc openjdk-src
        pacman -S --noconfirm gcc gdb cmake make
        
        # Outils réseau et sécurité
        pacman -S --noconfirm nmap wireshark-qt tcpdump netcat
        pacman -S --noconfirm openvpn wireguard-tools
        pacman -S --noconfirm hashcat john aircrack-ng
        
        # Git et outils de version
        pacman -S --noconfirm git git-lfs github-cli
        
        # Wine pour compatibilité Windows
        pacman -S --noconfirm wine wine-gecko wine-mono winetricks
        
        # Docker
        pacman -S --noconfirm docker docker-compose
        systemctl enable docker
    "
}

# Installation des navigateurs et applications
install_applications() {
    print_header "Installation des applications"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation de paru (AUR helper)
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        chown -R $USERNAME:$USERNAME paru
        cd paru
        sudo -u $USERNAME makepkg -si --noconfirm
        cd ..
        rm -rf paru
        
        # Navigateurs via AUR
        sudo -u $USERNAME paru -S --noconfirm google-chrome brave-bin
        
        # Applications multimédia
        pacman -S --noconfirm vlc mpv
        
        # Communication
        sudo -u $USERNAME paru -S --noconfirm discord telegram-desktop
        
        # Outils système
        pacman -S --noconfirm psensor lm_sensors
        sensors-detect --auto
    "
}

# Configuration de l'utilisateur
setup_user() {
    print_header "Configuration de l'utilisateur"
    
    arch-chroot /mnt /bin/bash -c "
        # Création utilisateur
        useradd -m -G wheel,audio,video,optical,storage,docker -s /bin/bash $USERNAME
        echo '$USERNAME:$PASSWORD' | chpasswd
        
        # Configuration sudo
        echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers
        
        # Création des dossiers utilisateur
        sudo -u $USERNAME mkdir -p /home/$USERNAME/{Downloads,Documents,Pictures,Videos,Music}
        sudo -u $USERNAME mkdir -p /home/$USERNAME/.config
    "
}

# Configuration de GRUB avec thème Fallout
install_grub() {
    print_header "Installation et configuration de GRUB"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation de GRUB
        pacman -S --noconfirm grub efibootmgr os-prober
        
        # Configuration pour multiboot
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
        echo 'GRUB_GFXMODE=1920x1080' >> /etc/default/grub
        echo 'GRUB_THEME=\"/boot/grub/themes/fallout/theme.txt\"' >> /etc/default/grub
        
        # Installation GRUB
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
        
        # Téléchargement du thème Fallout
        mkdir -p /boot/grub/themes
        cd /boot/grub/themes
        git clone https://github.com/shvchk/fallout-grub-theme.git fallout
        
        # Téléchargement d'autres thèmes GRUB
        # BSOL Theme
        git clone https://github.com/AdisonCavani/distro-grub-themes.git bsol-temp
        cp -r bsol-temp/themes/bsol /boot/grub/themes/
        rm -rf bsol-temp
        
        # CRT-Amber Theme
        git clone https://github.com/VandalByte/CRT-Amber-GRUB-Theme.git crt-amber
        
        # Dark Matter Theme
        git clone https://github.com/VandalByte/darkmatter-grub2-theme.git darkmatter
        
        # Minegrub Theme
        git clone https://github.com/VandalByte/minegrub-theme.git minegrub
        
        # Génération de la configuration GRUB
        grub-mkconfig -o /boot/grub/grub.cfg
    "
}

# Configuration de Hyprland
configure_hyprland() {
    print_header "Configuration de Hyprland"
    
    arch-chroot /mnt /bin/bash -c "
        # Configuration Hyprland de base
        sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/hypr
        
        cat > /home/$USERNAME/.config/hypr/hyprland.conf << 'EOF'
# Hyprland Configuration
# Arcane/Dev/Gaming Theme

monitor=,1920x1080@60,auto,1

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
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
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
        
        vibrancy = 0.1696
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

misc {
    force_default_wallpaper = 0
}

# Window rules
windowrulev2 = opacity 0.8 0.8,class:^(kitty)$
windowrulev2 = opacity 0.9 0.9,class:^(thunar)$
windowrulev2 = opacity 0.9 0.9,class:^(code)$

# Keybindings
\$mainMod = SUPER

bind = \$mainMod, Q, exec, kitty
bind = \$mainMod, C, killactive,
bind = \$mainMod, M, exit,
bind = \$mainMod, E, exec, thunar
bind = \$mainMod, V, togglefloating,
bind = \$mainMod, R, exec, wofi --show drun
bind = \$mainMod, P, pseudo,
bind = \$mainMod, J, togglesplit,

# Move focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Switch workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

# Move window to workspace
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g \"\$(slurp)\" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Lock screen
bind = \$mainMod, L, exec, swaylock

# Volume
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness
binde = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
binde = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Autostart
exec-once = waybar
exec-once = mako
exec-once = swww init
exec-once = swww img /home/$USERNAME/Pictures/wallpapers/arcane_jinx.mp4
exec-once = fastfetch
EOF

        chown $USERNAME:$USERNAME /home/$USERNAME/.config/hypr/hyprland.conf
    "
}

# Configuration de Waybar
configure_waybar() {
    print_header "Configuration de Waybar"
    
    arch-chroot /mnt /bin/bash -c "
        sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/waybar
        
        # Configuration Waybar
        cat > /home/$USERNAME/.config/waybar/config << 'EOF'
{
    \"layer\": \"top\",
    \"position\": \"top\",
    \"height\": 40,
    \"width\": 1200,
    \"margin-top\": 10,
    \"margin-left\": 360,
    \"margin-right\": 360,
    
    \"modules-left\": [\"hyprland/workspaces\", \"hyprland/mode\"],
    \"modules-center\": [\"clock\"],
    \"modules-right\": [\"pulseaudio\", \"network\", \"battery\", \"tray\"],
    
    \"hyprland/workspaces\": {
        \"disable-scroll\": true,
        \"all-outputs\": true,
        \"format\": \"{icon}\",
        \"format-icons\": {
            \"1\": \"󰣇\",
            \"2\": \"\",
            \"3\": \"\",
            \"4\": \"\",
            \"5\": \"\",
            \"urgent\": \"\",
            \"focused\": \"\",
            \"default\": \"\"
        }
    },
    
    \"clock\": {
        \"format\": \"{:%H:%M}\",
        \"format-alt\": \"{:%A, %B %d, %Y (%R)}\",
        \"tooltip-format\": \"<tt><small>{calendar}</small></tt>\",
        \"calendar\": {
            \"mode\"          : \"year\",
            \"mode-mon-col\"  : 3,
            \"weeks-pos\"     : \"right\",
            \"on-scroll\"     : 1,
            \"on-click-right\": \"mode\",
            \"format\": {
                \"months\":     \"<span color='#ffead3'><b>{}</b></span>\",
                \"days\":       \"<span color='#ecc6d9'><b>{}</b></span>\",
                \"weeks\":      \"<span color='#99ffdd'><b>W{}</b></span>\",
                \"weekdays\":   \"<span color='#ffcc66'><b>{}</b></span>\",
                \"today\":      \"<span color='#ff6699'><b><u>{}</u></b></span>\"
            }
        }
    },
    
    \"battery\": {
        \"states\": {
            \"good\": 95,
            \"warning\": 30,
            \"critical\": 15
        },
        \"format\": \"{capacity}% {icon}\",
        \"format-charging\": \"{capacity}% \",
        \"format-plugged\": \"{capacity}% \",
        \"format-alt\": \"{time} {icon}\",
        \"format-icons\": [\"\", \"\", \"\", \"\", \"\"]
    },
    
    \"network\": {
        \"format-wifi\": \"{essid} ({signalStrength}%) \",
        \"format-ethernet\": \"{ipaddr}/{cidr} \",
        \"tooltip-format\": \"{ifname} via {gwaddr} \",
        \"format-linked\": \"{ifname} (No IP) \",
        \"format-disconnected\": \"Disconnected ⚠\",
        \"format-alt\": \"{ifname}: {ipaddr}/{cidr}\"
    },
    
    \"pulseaudio\": {
        \"format\": \"{volume}% {icon} {format_source}\",
        \"format-bluetooth\": \"{volume}% {icon} {format_source}\",
        \"format-bluetooth-muted\": \" {icon} {format_source}\",
        \"format-muted\": \" {format_source}\",
        \"format-source\": \"{volume}% \",
        \"format-source-muted\": \"\",
        \"format-icons\": {
            \"headphone\": \"\",
            \"hands-free\": \"\",
            \"headset\": \"\",
            \"phone\": \"\",
            \"portable\": \"\",
            \"car\": \"\",
            \"default\": [\"\", \"\", \"\"]
        },
        \"on-click\": \"pavucontrol\"
    }
}
EOF

        # Style CSS pour Waybar
        cat > /home/$USERNAME/.config/waybar/style.css << 'EOF'
* {
    font-family: \"JetBrains Mono\", monospace;
    font-size: 13px;
    border: none;
    border-radius: 0;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.8);
    border-radius: 20px;
    color: #ffffff;
    transition-property: background-color;
    transition-duration: .5s;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #ffffff;
    border-radius: 15px;
    margin: 0 3px;
}

#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused,
#workspaces button.active {
    background-color: rgba(51, 204, 255, 0.8);
    color: #000000;
}

#clock {
    color: #64FFDA;
    font-weight: bold;
}

#battery {
    color: #A8E6CF;
}

#battery.charging,
#battery.plugged {
    color: #26A69A;
}

#battery.critical:not(.charging) {
    color: #f53c3c;
}

#network {
    color: #FFB74D;
}

#pulseaudio {
    color: #BA68C8;
}

#pulseaudio.muted {
    color: #90A4AE;
}

#tray {
    color: #FFCDD2;
}
EOF

        chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/waybar
    "
}

# Installation et configuration VS Code avec extensions
install_vscode() {
    print_header "Installation de VS Code et extensions"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation VS Code via AUR
        sudo -u $USERNAME paru -S --noconfirm visual-studio-code-bin
        
        # Android Studio
        sudo -u $USERNAME paru -S --noconfirm android-studio
        
        # Installation des extensions VS Code
        sudo -u $USERNAME code --install-extension ms-vscode.cpptools
        sudo -u $USERNAME code --install-extension ms-python.python
        sudo -u $USERNAME code --install-extension redhat.java
        sudo -u $USERNAME code --install-extension ms-vscode.vscode-typescript-next
        sudo -u $USERNAME code --install-extension GitHub.copilot
        sudo -u $USERNAME code --install-extension ms-vscode-remote.remote-ssh
        sudo -u $USERNAME code --install-extension bradlc.vscode-tailwindcss
        sudo -u $USERNAME code --install-extension esbenp.prettier-vscode
        sudo -u $USERNAME code --install-extension ms-vscode.vscode-json
        sudo -u $USERNAME code --install-extension rust-lang.rust-analyzer
        sudo -u $USERNAME code --install-extension golang.go
        sudo -u $USERNAME code --install-extension ms-vscode.hexeditor
        sudo -u $USERNAME code --install-extension ms-vscode.live-server
    "
}

# Installation Spotify avec Spicetify
install_spotify_spicetify() {
    print_header "Installation de Spotify avec Spicetify"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation Spotify et Spicetify
        sudo -u $USERNAME paru -S --noconfirm spotify spicetify-cli
        
        # Configuration de base Spicetify
        sudo -u $USERNAME spicetify backup apply enable-devtool
        sudo -u $USERNAME spicetify config extensions autoVolume.js
        sudo -u $USERNAME spicetify config extensions shuffle+.js
        sudo -u $USERNAME spicetify config extensions trashbin.js
        sudo -u $USERNAME spicetify config current_theme Dribbblish
        sudo -u $USERNAME spicetify config color_scheme purple
        sudo -u $USERNAME spicetify apply
    "
}

# Configuration des fonds d'écran et thèmes
setup_wallpapers_themes() {
    print_header "Configuration des fonds d'écran et thèmes"
    
    arch-chroot /mnt /bin/bash -c "
        # Création du dossier wallpapers
        sudo -u $USERNAME mkdir -p /home/$USERNAME/Pictures/wallpapers
        
        # Téléchargement des fonds d'écran Arcane/Fallout
        cd /home/$USERNAME/Pictures/wallpapers
        
        # Fonds d'écran statiques (exemples - vous devrez ajouter vos liens)
        sudo -u $USERNAME wget -O arcane_jinx.jpg \"https://example.com/arcane_jinx.jpg\"
        sudo -u $USERNAME wget -O fallout_pipboy.jpg \"https://example.com/fallout_pipboy.jpg\"
        
        # Configuration swww pour fonds d'écran vidéo
        echo '#!/bin/bash
if [ -f \"/home/$USERNAME/Pictures/wallpapers/arcane_jinx.mp4\" ]; then
    swww img /home/$USERNAME/Pictures/wallpapers/arcane_jinx.mp4 --transition-type fade --transition-duration 2
else
    swww img /home/$USERNAME/Pictures/wallpapers/arcane_jinx.jpg --transition-type fade --transition-duration 2
fi' > /home/$USERNAME/.config/set-wallpaper.sh
        
        chmod +x /home/$USERNAME/.config/set-wallpaper.sh
        chown $USERNAME:$USERNAME /home/$USERNAME/.config/set-wallpaper.sh
    "
}

# Installation du détecteur de basses sonores
install_bass_detector() {
    print_header "Installation du détecteur de basses sonores"
    
    arch-chroot /mnt /bin/bash -c "
        # Installation des dépendances pour l'analyse audio
        pacman -S --noconfirm python-pyaudio python-numpy python-matplotlib
        
        # Création du script détecteur de basses
        cat > /home/$USERNAME/.config/bass_detector.py << 'EOF'


import pyaudio
import numpy as np
import threading
import time

class BassDetector:
    def __init__(self):
        self.CHUNK = 4096
        self.FORMAT = pyaudio.paInt16
        self.CHANNELS = 1
        self.RATE = 44100
        self.bass_threshold = 1000
        
        self.p = pyaudio.PyAudio()
        self.stream = self.p.stream(
            format=self.FORMAT,
            channels=self.CHANNELS,
            rate=self.RATE,
            input=True,
            frames_per_buffer=self.CHUNK
        )
        
    def detect_bass(self):
        data = np.frombuffer(self.stream.read(self.CHUNK), dtype=np.int16)
        
        # FFT pour analyser les fréquences
        fft = np.fft.fft(data)
        freqs = np.fft.fftfreq(len(fft))
        
        # Analyse des basses (20-250 Hz)
        bass_range = np.where((freqs >= 20/self.RATE) & (freqs <= 250/self.RATE))
        bass_magnitude = np.sum(np.abs(fft[bass_range]))
        
        if bass_magnitude > self.bass_threshold:
            print(f\"🔊 BASS DETECTED! Magnitude: {bass_magnitude:.2f}\")
            return True
        return False
    
    def run(self):
        print(\"🎵 Bass detector started...\")
        try:
            while True:
                self.detect_bass()
                time.sleep(0.1)
        except KeyboardInterrupt:
            print(\"\\n🛑 Bass detector stopped.\")
        finally:
            self.stream.stop_stream()
            self.stream.close()
            self.p.terminate()

if __name__ == \"__
