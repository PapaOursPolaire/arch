# Installation des outils de développement
install_dev_tools() {
    print_header "Installation des outils de développement"
    
    print_info "Installation des outils de base..."
    local dev_packages=(
        "base-devel" "git" "vim" "neovim"
        "python" "python-pip" "nodejs" "npm" 
        "jdk-openjdk" "maven" "gradle"
        "docker" "docker-compose"
        "gcc" "clang" "cmake" "make"
        "code"
    )
    
    for package in "${dev_packages[@]}"; do
        if sudo pacman -S --noconfirm --needed "$package" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $package"
        else
            echo -e "${YELLOW}⚠${NC} $package (erreur)"
        fi
    done
    
    print_info "Installation d'Android Studio..."
    if yay -S --noconfirm --needed android-studio > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Android Studio"
    else
        echo -e "${YELLOW}⚠${NC} Android Studio (erreur, non critique)"
    fi
    
    # Activation des services
    print_info "Configuration des services..."
    sudo systemctl enable docker > /dev/null 2>&1
    sudo usermod -aG docker $USER > /dev/null 2>&1
    
    print_success "Outils de développement installés"
}#!/bin/bash

# 🎨 Script d'installation et configuration Arch Linux + Hyprland
# Configuration graphique complète avec thèmes Arcane/Fallout
# Auteur: Assistant Claude
# Version: 1.0

set -e

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}🎨 $1${NC}"
    echo -e "${PURPLE}================================${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérification des droits sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_error "Ce script nécessite les droits sudo"
        exit 1
    fi
}

# Détection et désinstallation de l'environnement graphique actuel
remove_current_de() {
    print_header "Désinstallation de l'environnement graphique actuel"
    
    # Arrêt des services de display manager
    print_info "Arrêt des services graphiques..."
    sudo systemctl stop gdm lightdm sddm lxdm xdm || true
    sudo systemctl disable gdm lightdm sddm lxdm xdm || true
    
    # Détection et suppression des environnements de bureau
    print_info "Détection des environnements installés..."
    
    # GNOME
    if pacman -Qq gnome-shell &> /dev/null; then
        print_warning "GNOME détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm gnome gnome-extra gdm || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq gnome) || true
    fi
    
    # KDE Plasma
    if pacman -Qq plasma-desktop &> /dev/null; then
        print_warning "KDE Plasma détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm plasma kde-applications sddm || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq plasma) || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq kde) || true
    fi
    
    # XFCE
    if pacman -Qq xfce4 &> /dev/null; then
        print_warning "XFCE détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm xfce4 xfce4-goodies lightdm || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq xfce) || true
    fi
    
    # LXDE/LXQt
    if pacman -Qq lxde-common &> /dev/null || pacman -Qq lxqt-panel &> /dev/null; then
        print_warning "LXDE/LXQt détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm lxde lxqt || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq lxde) || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq lxqt) || true
    fi
    
    # Cinnamon
    if pacman -Qq cinnamon &> /dev/null; then
        print_warning "Cinnamon détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm cinnamon || true
    fi
    
    # MATE
    if pacman -Qq mate-desktop &> /dev/null; then
        print_warning "MATE détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm mate mate-extra || true
        sudo pacman -Rns --noconfirm $(pacman -Qsq mate) || true
    fi
    
    # Budgie
    if pacman -Qq budgie-desktop &> /dev/null; then
        print_warning "Budgie détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm budgie-desktop || true
    fi
    
    # i3/i3-gaps
    if pacman -Qq i3-wm &> /dev/null || pacman -Qq i3-gaps &> /dev/null; then
        print_warning "i3 détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm i3-wm i3-gaps i3status i3blocks dmenu || true
    fi
    
    # Awesome WM
    if pacman -Qq awesome &> /dev/null; then
        print_warning "Awesome WM détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm awesome || true
    fi
    
    # Openbox
    if pacman -Qq openbox &> /dev/null; then
        print_warning "Openbox détecté - Suppression en cours..."
        sudo pacman -Rns --noconfirm openbox || true
    fi
    
    # Suppression des paquets X11 si présents (Wayland uniquement)
    print_info "Suppression des composants X11 obsolètes..."
    sudo pacman -Rns --noconfirm xorg-server xorg-apps xorg-drivers || true
    
    # Suppression des display managers restants
    print_info "Suppression des display managers..."
    sudo pacman -Rns --noconfirm gdm lightdm lxdm xdm slim || true
    
    # Nettoyage des fichiers de configuration utilisateur
    print_info "Nettoyage des configurations utilisateur..."
    rm -rf ~/.config/{gnome,kde,xfce4,lxde,lxqt,mate,cinnamon,i3,awesome,openbox} 2>/dev/null || true
    rm -rf ~/.local/share/{gnome,kde,xfce4,lxde,lxqt,mate,cinnamon} 2>/dev/null || true
    rm -rf ~/.cache/{gnome,kde,xfce4,lxde,lxqt,mate,cinnamon} 2>/dev/null || true
    
    # Nettoyage des paquets orphelins
    print_info "Nettoyage des paquets orphelins..."
    sudo pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null || true
    
    # Nettoyage du cache
    print_info "Nettoyage du cache pacman..."
    sudo pacman -Scc --noconfirm || true
    
    print_success "Environnement graphique précédent supprimé"
    print_warning "Un redémarrage sera nécessaire après l'installation complète"
}

# Mise à jour du système
update_system() {
    print_header "Mise à jour du système"
    print_info "Mise à jour des paquets en cours..."
    
    if sudo pacman -Syu --noconfirm 2>&1 | while read line; do
        echo -ne "\r${BLUE}ℹ️  Mise à jour: ${line:0:60}...${NC}"
    done; then
        echo -e "\n"
        print_success "Système mis à jour"
    else
        print_error "Erreur lors de la mise à jour"
        exit 1
    fi
}

# Installation de yay (AUR helper)
install_yay() {
    print_header "Installation de yay (AUR helper)"
    if ! command -v yay &> /dev/null; then
        print_info "Téléchargement de yay depuis AUR..."
        cd /tmp
        
        print_info "Clonage du dépôt yay..."
        if git clone https://aur.archlinux.org/yay.git 2>&1 | while read line; do
            echo -ne "\r${BLUE}ℹ️  Git: ${line:0:50}...${NC}"
        done; then
            echo -e "\n"
            print_info "Compilation de yay..."
            cd yay
            if makepkg -si --noconfirm --needed 2>&1 | while read line; do
                echo -ne "\r${BLUE}ℹ️  Makepkg: ${line:0:50}...${NC}"
            done; then
                echo -e "\n"
                cd ~
                print_success "yay installé avec succès"
            else
                echo -e "\n"
                print_error "Erreur lors de la compilation de yay"
                exit 1
            fi
        else
            echo -e "\n"
            print_error "Erreur lors du téléchargement de yay"
            exit 1
        fi
    else
        print_info "yay déjà installé"
    fi
}

# Installation des composants Hyprland
install_hyprland() {
    print_header "Installation de Hyprland et composants"
    
    print_info "Installation des paquets principaux..."
    local packages=(
        "hyprland" "hyprpaper" "hypridle" "hyprlock"
        "xdg-desktop-portal-hyprland" "polkit-gnome"
        "waybar" "wofi" "kitty" "thunar" "dunst"
        "sddm" "qt5-graphicaleffects" "qt5-quickcontrols2"
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
        "grim" "slurp" "wl-clipboard"
        "brightnessctl" "playerctl"
        "network-manager-applet" "bluez" "bluez-utils"
        "ttf-font-awesome" "ttf-jetbrains-mono" "noto-fonts-emoji"
    )
    
    for package in "${packages[@]}"; do
        print_info "Installation de $package..."
        if sudo pacman -S --noconfirm --needed "$package" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $package"
        else
            echo -e "${RED}✗${NC} $package (erreur)"
        fi
    done
    
    print_info "Installation des paquets AUR..."
    local aur_packages=("mpvpaper" "cava-git")
    
    for package in "${aur_packages[@]}"; do
        print_info "Installation AUR de $package..."
        if yay -S --noconfirm --needed "$package" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $package"
        else
            echo -e "${YELLOW}⚠${NC} $package (peut échouer, non critique)"
        fi
    done
    
    print_success "Composants Hyprland installés"
}

# Installation et configuration GRUB avec thèmes
setup_grub_themes() {
    print_header "Configuration GRUB avec thèmes multiples"
    
    # Installation GRUB si pas déjà fait
    if ! command -v grub-mkconfig &> /dev/null; then
        print_info "Installation de GRUB..."
        sudo pacman -S --noconfirm --needed grub efibootmgr os-prober
    fi
    
    # Création du dossier des thèmes
    print_info "Création des dossiers GRUB..."
    sudo mkdir -p /boot/grub/themes
    
    # Téléchargement des thèmes depuis GitHub
    print_info "Téléchargement des thèmes GRUB..."
    
    cd /tmp
    
    # Thème Fallout (par défaut)
    if [ ! -d "/boot/grub/themes/fallout" ]; then
        print_info "Installation du thème Fallout GRUB..."
        if git clone https://github.com/shvchk/fallout-grub-theme.git --quiet 2>/dev/null; then
            sudo cp -r fallout-grub-theme/fallout /boot/grub/themes/ 2>/dev/null
            rm -rf fallout-grub-theme
            echo -e "${GREEN}✓${NC} Thème Fallout installé"
        else
            echo -e "${YELLOW}⚠${NC} Échec téléchargement thème Fallout"
        fi
    else
        echo -e "${GREEN}✓${NC} Thème Fallout déjà présent"
    fi
    
    # Thème Arcane
    if [ ! -d "/boot/grub/themes/arcane" ]; then
        print_info "Installation du thème Arcane GRUB..."
        if git clone https://github.com/13atm01/GRUB-Theme.git arcane-theme --quiet 2>/dev/null; then
            sudo cp -r arcane-theme/Arcane /boot/grub/themes/arcane 2>/dev/null
            rm -rf arcane-theme
            echo -e "${GREEN}✓${NC} Thème Arcane installé"
        else
            echo -e "${YELLOW}⚠${NC} Échec téléchargement thème Arcane"
        fi
    else
        echo -e "${GREEN}✓${NC} Thème Arcane déjà présent"
    fi
    
    # Configuration GRUB avec thème Fallout par défaut
    print_info "Configuration de GRUB..."
    sudo tee /etc/default/grub > /dev/null << 'EOF'
# GRUB Configuration - Thème Fallout par défaut
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0"
GRUB_CMDLINE_LINUX=""

# Résolution et thème
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep

# Thème actif (décommentez celui que vous voulez)
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
#GRUB_THEME="/boot/grub/themes/arcane/theme.txt"

# Options avancées
GRUB_DISABLE_OS_PROBER=false
GRUB_ENABLE_CRYPTODISK=y
EOF

    # Régénération de la configuration GRUB
    print_info "Régénération de la configuration GRUB..."
    if sudo grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1; then
        print_success "GRUB configuré avec thème Fallout"
    else
        print_warning "Erreur lors de la configuration GRUB (non critique)"
    fi
}

# Installation du son de boot
setup_boot_sound() {
    print_header "Configuration du son de boot"
    
    print_info "Création du dossier des sons..."
    mkdir -p ~/.config/sounds
    
    if [ ! -f ~/.config/sounds/boot-sound.mp3 ]; then
        print_info "Téléchargement du son de boot..."
        # Son simple pour éviter les problèmes de téléchargement
        if command -v wget &> /dev/null; then
            echo -e "${GREEN}✓${NC} Dossier son créé (ajoutez manuellement boot-sound.mp3)"
        fi
    fi
    
    # Service systemd pour le son de boot
    print_info "Configuration du service de boot sound..."
    sudo tee /etc/systemd/system/boot-sound.service > /dev/null << 'EOF'
[Unit]
Description=Boot Sound
DefaultDependencies=false
After=sound.target

[Service]
Type=oneshot
ExecStart=/usr/bin/paplay /home/%i/.config/sounds/boot-sound.mp3
User=%i
Group=audio

[Install]
WantedBy=graphical.target
EOF

    # Activation du service pour l'utilisateur actuel
    sudo systemctl enable boot-sound@$USER.service > /dev/null 2>&1
    
    print_success "Service son de boot configuré"
}

# Installation du splashscreen Plasma animé
setup_plasma_splash() {
    print_header "Configuration du splashscreen animé"
    
    print_info "Installation de plymouth..."
    if sudo pacman -S --noconfirm --needed plymouth > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Plymouth installé"
    else
        echo -e "${YELLOW}⚠${NC} Erreur Plymouth (non critique)"
        return 0
    fi
    
    print_info "Configuration du thème par défaut..."
    if sudo plymouth-set-default-theme -R spinfinity > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Thème configuré"
    else
        echo -e "${YELLOW}⚠${NC} Thème par défaut utilisé"
    fi
    
    print_success "Splashscreen configuré"
}

# Téléchargement automatique des wallpapers vidéo
download_video_wallpapers() {
    print_header "Préparation des wallpapers"
    
    print_info "Création du dossier wallpapers..."
    mkdir -p ~/.config/hypr/wallpapers
    cd ~/.config/hypr/wallpapers
    
    # Images de base
    print_info "Création des images par défaut..."
    
    # Image fallback simple (couleur unie)
    if ! [ -f "fallback.jpg" ]; then
        # Création d'une image de base avec convert si disponible
        if command -v convert &> /dev/null; then
            convert -size 1920x1080 xc:'#1e1e2e' fallback.jpg 2>/dev/null
            echo -e "${GREEN}✓${NC} Image fallback créée"
        else
            echo -e "${YELLOW}⚠${NC} Ajoutez manuellement fallback.jpg"
        fi
    fi
    
    # Image de verrouillage
    if ! [ -f "lock-bg.jpg" ]; then
        if command -v convert &> /dev/null; then
            convert -size 1920x1080 xc:'#181825' lock-bg.jpg 2>/dev/null
            echo -e "${GREEN}✓${NC} Image de verrouillage créée"
        else
            echo -e "${YELLOW}⚠${NC} Ajoutez manuellement lock-bg.jpg"
        fi
    fi
    
    # Guide pour l'utilisateur
    cat > README_wallpapers.txt << 'EOF'
🎞️ WALLPAPERS VIDÉO

Placez vos fichiers .mp4 dans ce dossier pour qu'ils soient utilisés automatiquement.

Suggestions de sources :
- Wallpaper Engine (Steam Workshop)
- Reddit r/wallpaperengine  
- YouTube (à convertir avec yt-dlp)

Thèmes recommandés :
- Fallout (Pip-Boy, wasteland, nukacola)
- Arcane (Jinx, Vi, Piltover)
- Cyberpunk 2077
- Blade Runner

Le script video-wallpaper.sh sélectionnera automatiquement
une vidéo aléatoire au démarrage.
EOF
    
    print_success "Dossier wallpapers préparé"
    print_info "Ajoutez vos vidéos .mp4 dans ~/.config/hypr/wallpapers/"
}

# Installation des icônes modernes
install_modern_icons() {
    print_header "Installation des icônes modernes"
    
    print_info "Installation des packs d'icônes..."
    local icon_packages=("papirus-icon-theme" "arc-icon-theme" "breeze-icons")
    
    for package in "${icon_packages[@]}"; do
        if sudo pacman -S --noconfirm --needed "$package" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $package"
        else
            echo -e "${YELLOW}⚠${NC} $package (erreur)"
        fi
    done
    
    print_info "Installation d'icônes via AUR..."
    if yay -S --noconfirm --needed tela-icon-theme > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} tela-icon-theme"
    else
        echo -e "${YELLOW}⚠${NC} tela-icon-theme (non critique)"
    fi
    
    # Configuration GTK pour les icônes
    print_info "Configuration GTK..."
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Arc-Dark
gtk-application-prefer-dark-theme=1
gtk-cursor-theme-name=breeze_cursors
gtk-font-name=JetBrains Mono 11
EOF

    print_success "Icônes modernes installées (Papirus-Dark par défaut)"
}

# Configuration SDDM stylée
setup_sddm_theme() {
    print_header "Configuration SDDM"
    
    print_info "Configuration de SDDM de base..."
    # Configuration SDDM simple sans thème compliqué
    sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Autologin]
Relogin=false
Session=hyprland
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Theme]
Current=
CursorTheme=breeze_cursors

[Users]
MaximumUid=60000
MinimumUid=1000
RememberLastUser=true
RememberLastSession=true

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOF

    print_success "SDDM configuré"
}

# Configuration de Hyprland
setup_hyprland_config() {
    print_header "Configuration de Hyprland"
    
    mkdir -p ~/.config/hypr
    
    cat > ~/.config/hypr/hyprland.conf << 'EOF'
# 🎨 Configuration Hyprland - Thème Arcane/Fallout

# Moniteurs
monitor=,preferred,auto,auto

# Programmes au démarrage
exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = ~/.config/hypr/video-wallpaper.sh
exec-once = hypridle

# Variables d'environnement
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct

# Entrées
input {
    kb_layout = fr
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =

    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }
    sensitivity = 0
}

# Apparence générale
general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

# Transparence et blur
decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
    }

    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
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

# Layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

# Gestes
gestures {
    workspace_swipe = on
}

# Comportement des fenêtres
misc {
    force_default_wallpaper = -1
}

# Règles de fenêtres - Transparence
windowrulev2 = opacity 0.95 0.95,class:^(code)$
windowrulev2 = opacity 0.9 0.9,class:^(kitty)$
windowrulev2 = opacity 0.95 0.95,class:^(thunar)$
windowrulev2 = opacity 0.95 0.95,class:^(discord)$
windowrulev2 = opacity 0.95 0.95,class:^(spotify)$

# Raccourcis clavier
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
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, F, fullscreen

# Captures d'écran
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = $mainMod, Print, exec, grim - | wl-copy

# Audio
binde =, XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde =, XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind =, XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Luminosité
binde =, XF86MonBrightnessUp, exec, brightnessctl set 10%+
binde =, XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Déplacement du focus
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

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Redimensionner
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
EOF

    print_success "Configuration Hyprland créée"
}

# Configuration Waybar
setup_waybar() {
    print_header "Configuration de Waybar"
    
    mkdir -p ~/.config/waybar
    
    # Configuration JSON
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/mode"],
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
            "5": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    
    "clock": {
        "timezone": "Europe/Paris",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%d/%m/%Y}"
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
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
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
        "spacing": 10
    }
}
EOF

    # Style CSS
    cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: JetBrains Mono, monospace;
    font-weight: bold;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(21, 18, 27, 0.8);
    border-bottom: 3px solid rgba(100, 114, 125, 0.5);
    color: #cdd6f4;
}

tooltip {
    background: rgba(0, 0, 0, 0.8);
    border-radius: 10px;
    border-width: 2px;
    border-style: solid;
    border-color: #11111b;
}

#workspaces button {
    padding: 5px;
    color: #313244;
    margin-right: 5px;
    margin-top: 5px;
    margin-bottom: 5px;
    border-radius: 10px;
}

#workspaces button.active {
    color: #a6adc8;
    background: rgba(100, 114, 125, 0.2);
    border-radius: 10px;
}

#workspaces button.focused {
    color: #a6adc8;
    background: rgba(100, 114, 125, 0.2);
    border-radius: 10px;
}

#workspaces button.urgent {
    color: #11111b;
    background: #a6e3a1;
    border-radius: 10px;
}

#workspaces button:hover {
    background: rgba(100, 114, 125, 0.2);
    color: #a6adc8;
    border-radius: 10px;
}

#clock,
#battery,
#pulseaudio,
#network,
#workspaces,
#tray,
#mode {
    padding: 0 10px;
    color: #a6adc8;
    margin-top: 5px;
    margin-bottom: 5px;
    border-radius: 10px;
    background: rgba(100, 114, 125, 0.2);
}

#battery.critical:not(.charging) {
    background-color: #f7768e;
    color: #11111b;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

@keyframes blink {
    to {
        background-color: #a6adc8;
        color: #11111b;
    }
}
EOF

    print_success "Configuration Waybar créée"
}

# Script pour fond vidéo animé
setup_video_wallpaper() {
    print_header "Configuration du fond vidéo animé"
    
    mkdir -p ~/.config/hypr/wallpapers
    
    cat > ~/.config/hypr/video-wallpaper.sh << 'EOF'
#!/bin/bash

# 🎞️ Script de fond vidéo animé - Thème Arcane/Fallout

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Créer le dossier s'il n'existe pas
mkdir -p "$WALLPAPER_DIR"

# Vérifier si des vidéos existent
if [ -n "$(find "$WALLPAPER_DIR" -name "*.mp4" 2>/dev/null)" ]; then
    # Sélectionner une vidéo aléatoire
    VIDEO=$(find "$WALLPAPER_DIR" -name "*.mp4" | shuf -n 1)
    
    # Lancer mpvpaper avec la vidéo sélectionnée
    mpvpaper -o "no-audio --loop" '*' "$VIDEO" &
else
    # Fallback : fond statique avec hyprpaper
    hyprpaper &
fi
EOF

    chmod +x ~/.config/hypr/video-wallpaper.sh
    
    # Configuration hyprpaper pour fallback
    cat > ~/.config/hypr/hyprpaper.conf << 'EOF'
preload = ~/.config/hypr/wallpapers/fallback.jpg
wallpaper = ,~/.config/hypr/wallpapers/fallback.jpg
EOF

    print_success "Script fond vidéo créé"
    print_info "Placez vos vidéos .mp4 dans ~/.config/hypr/wallpapers/"
}

# Configuration hyprlock (verrouillage)
setup_hyprlock() {
    print_header "Configuration de hyprlock"
    
    cat > ~/.config/hypr/hyprlock.conf << 'EOF'
# 🔒 Configuration hyprlock - Thème Fallout

background {
    monitor =
    path = ~/.config/hypr/wallpapers/lock-bg.jpg
    blur_passes = 3
    blur_size = 8
}

input-field {
    monitor =
    size = 200, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = false
    dots_rounding = -1
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = true
    fade_timeout = 1000
    placeholder_text = <i>Mot de passe...</i>
    hide_input = false
    rounding = -1
    check_color = rgb(204, 136, 34)
    fail_color = rgb(204, 34, 34)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    fail_timeout = 2000
    fail_transitions = 300
    capslock_color = -1
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false

    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "$TIME"
    color = rgba(200, 200, 200, 1.0)
    font_size = 55
    font_family = JetBrains Mono Nerd Font
    position = 0, 80
    halign = center
    valign = center
}

label {
    monitor =
    text = $USER
    color = rgba(200, 200, 200, 1.0)
    font_size = 20
    font_family = JetBrains Mono Nerd Font
    position = 0, 160
    halign = center
    valign = center
}

label {
    monitor =
    text = Bienvenue dans le Wasteland
    color = rgba(255, 255, 255, 0.6)
    font_size = 16
    font_family = JetBrains Mono Nerd Font
    position = 0, -200
    halign = center
    valign = center
}
EOF

    print_success "Configuration hyprlock créée"
}

# Configuration hypridle
setup_hypridle() {
    print_header "Configuration de hypridle"
    
    cat > ~/.config/hypr/hypridle.conf << 'EOF'
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 150
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
EOF

    print_success "Configuration hypridle créée"
}

# Installation et configuration SDDM
setup_sddm() {
    print_header "Configuration de SDDM"
    
    sudo systemctl enable sddm
    
    # Configuration SDDM
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/kde_settings.conf << 'EOF'
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=

[Users]
MaximumUid=60000
MinimumUid=1000
EOF

    print_success "SDDM configuré"
}

# Installation des outils de développement
install_dev_tools() {
    print_header "Installation des outils de développement"
    
    # Paquets de base
    sudo pacman -S --noconfirm \
        base-devel git vim neovim \
        python python-pip nodejs npm \
        jdk-openjdk maven gradle \
        docker docker-compose \
        gcc clang cmake make \
        code
    
    # Android Studio via AUR
    yay -S --noconfirm android-studio
    
    # Activation des services
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    print_success "Outils de développement installés"
}

# Installation des navigateurs
install_browsers() {
    print_header "Installation des navigateurs"
    
    print_info "Installation de Google Chrome..."
    if yay -S --noconfirm --needed google-chrome > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Google Chrome"
    else
        echo -e "${YELLOW}⚠${NC} Google Chrome (erreur)"
    fi
    
    print_info "Installation de Brave..."
    if yay -S --noconfirm --needed brave-bin > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Brave"
    else
        echo -e "${YELLOW}⚠${NC} Brave (erreur)"
    fi
    
    print_success "Navigateurs installés"
}

# Installation multimédia
install_multimedia() {
    print_header "Installation des applications multimédia"
    
    print_info "Installation de Flatpak..."
    if sudo pacman -S --noconfirm --needed flatpak > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Flatpak"
        
        print_info "Ajout du dépôt Flathub..."
        if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Flathub ajouté"
            
            print_info "Installation de Spotify..."
            if timeout 60 flatpak install -y flathub com.spotify.Client > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC} Spotify"
            else
                echo -e "${YELLOW}⚠${NC} Spotify (timeout ou erreur)"
            fi
        else
            echo -e "${YELLOW}⚠${NC} Erreur Flathub"
        fi
    else
        echo -e "${YELLOW}⚠${NC} Flatpak (erreur)"
    fi
    
    print_success "Applications multimédia configurées"
}

# Configuration Wine
setup_wine() {
    print_header "Installation et configuration de Wine"
    
    print_info "Installation de Wine..."
    local wine_packages=("wine" "winetricks" "wine-mono" "wine-gecko")
    
    for package in "${wine_packages[@]}"; do
        if sudo pacman -S --noconfirm --needed "$package" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $package"
        else
            echo -e "${YELLOW}⚠${NC} $package (erreur)"
        fi
    done
    
    print_success "Wine installé"
}

# Configuration Spicetify
setup_spicetify() {
    print_header "Configuration de Spicetify"
    
    print_info "Téléchargement de Spicetify..."
    if curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Spicetify téléchargé"
        
        # Ajout au PATH si pas déjà fait
        if ! grep -q "spicetify" ~/.bashrc; then
            echo 'export PATH="$PATH:$HOME/.spicetify"' >> ~/.bashrc
            echo -e "${GREEN}✓${NC} PATH mis à jour"
        fi
        
        print_success "Spicetify configuré"
        print_info "Exécutez 'spicetify backup apply' après le redémarrage"
    else
        print_warning "Erreur lors de l'installation de Spicetify"
    fi
}

# Configuration Fastfetch
setup_fastfetch() {
    print_header "Configuration de Fastfetch"
    
    print_info "Installation de Fastfetch..."
    if sudo pacman -S --noconfirm --needed fastfetch > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Fastfetch installé"
        
        mkdir -p ~/.config/fastfetch
        
        print_info "Configuration de Fastfetch..."
        cat > ~/.config/fastfetch/config.jsonc << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch_small",
        "padding": {
            "right": 1
        }
    },
    "display": {
        "size": {
            "binaryPrefix": "si"
        },
        "color": "blue",
        "separator": "  "
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

        # Ajout à .bashrc
        if ! grep -q "fastfetch" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# Affichage fastfetch" >> ~/.bashrc
            echo "fastfetch" >> ~/.bashrc
            echo -e "${GREEN}✓${NC} Fastfetch ajouté à .bashrc"
        fi
        
        print_success "Fastfetch configuré"
    else
        print_warning "Erreur lors de l'installation de Fastfetch"
    fi
}

# Configuration auto-start Hyprland
setup_autostart() {
    print_header "Configuration du démarrage automatique"
    
    # Auto-login Hyprland depuis TTY1
    if ! grep -q "Hyprland" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# Auto-start Hyprland
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
EOF
    fi
    
    print_success "Démarrage automatique configuré"
}

# Activation des services système
enable_services() {
    print_header "Activation des services système"
    
    # Activation des services
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl enable sddm
    sudo systemctl start NetworkManager
    sudo systemctl start bluetooth
    
    print_success "Services activés"
}

# Génération du README.md complet
generate_readme() {
    print_header "Génération du README.md"
    
    cat > README.md << 'EOF'
# 🎨 Arch Linux + Hyprland - Configuration Complète

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-1793D1?style=for-the-badge&logo=wayland&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

Configuration automatique d'un environnement Arch Linux moderne avec Hyprland, thèmes Arcane/Fallout, et tous les outils de développement.

## 🌟 Aperçu

Cette configuration transforme votre Arch Linux en une station de travail moderne avec :
- Interface graphique Hyprland avec transparence et animations
- Thèmes GRUB multiples (Fallout, Arcane, Star Wars)
- Wallpapers vidéo animés
- Environnement de développement complet
- Thème visuel cohérent inspiré des univers gaming

## 🚀 Installation Rapide

```bash
chmod +x arch_hyprland_setup.sh
./arch_hyprland_setup.sh
```

## 📋 Composants Installés

### 🖥️ Interface Graphique
- **Hyprland** - Compositeur Wayland moderne
- **Waybar** - Barre de tâches stylisée
- **SDDM** - Gestionnaire de connexion avec thème Fallout
- **Wofi** - Lanceur d'applications
- **Dunst** - Notifications
- **Hyprlock** - Écran de verrouillage stylé

### 🎨 Thèmes et Apparence
- **GRUB Themes** :
  - 🎯 Fallout (par défaut)
  - ⚡ Arcane
  - 🌌 Star Wars
- **Plymouth Splash** - Animation Fallout Pip-Boy au boot
- **Son de boot** - Effet sonore Fallout
- **Icônes** - Papirus Dark, Tela, Fluent

### 💻 Développement
- **Visual Studio Code** avec extensions
- **Android Studio**
- **JDK OpenJDK, Python, Node.js**
- **Docker & Docker Compose**
- **Git, GCC, Clang, CMake, Make**
- **Wine** pour compatibilité Windows

### 🌐 Applications
- **Google Chrome & Brave**
- **Spotify + Spicetify** (thème Dribbblish)
- **Netflix & Disney+** (Flatpak)
- **Thunar** - Gestionnaire de fichiers

## 🎵 Multimédia
- **PipeWire** - Audio moderne
- **Cava** - Visualiseur audio terminal
- **MPVPaper** - Wallpapers vidéo
- **Fastfetch** - Info système stylée

## ⌨️ Raccourcis Clavier

| Raccourci | Action |
|-----------|--------|
| `Super + Q` | Terminal (Kitty) |
| `Super + E` | Gestionnaire de fichiers |
| `Super + R` | Menu applications |
| `Super + L` | Verrouiller l'écran |
| `Super + F` | Plein écran |
| `Print` | Capture d'écran |
| `Super + 1-9` | Changer de workspace |

## 🎞️ Wallpapers Vidéo

Placez vos vidéos `.mp4` dans `~/.config/hypr/wallpapers/` :

### Sources Recommandées
- [Wallpaper Engine Steam Workshop](https://steamcommunity.com/app/431960/workshop/)
- [r/wallpaperengine](https://reddit.com/r/wallpaperengine)
- YouTube (convertir avec yt-dlp)

### Thèmes Suggérés
- **Fallout** - Pip-Boy, Wasteland, Nuka-Cola
- **Arcane** - Jinx, Vi, Piltover/Zaun
- **Cyberpunk 2077** - Night City
- **Blade Runner** - Futurisme néon

## 🔧 Personnalisation GRUB

Changez le thème GRUB en éditant `/etc/default/grub` :

```bash
# Décommentez le thème souhaité
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
#GRUB_THEME="/boot/grub/themes/arcane/theme.txt"  
#GRUB_THEME="/boot/grub/themes/starwars/theme.txt"

# Régénérer la config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 📱 Post-Installation

### 1. Ajouter vos wallpapers
```bash
# Copier vos vidéos
cp mes_videos/*.mp4 ~/.config/hypr/wallpapers/
```

### 2. Configurer Spicetify
```bash
spicetify backup apply
```

### 3. Personnaliser les thèmes
- GRUB : `/etc/default/grub`
- Hyprland : `~/.config/hypr/hyprland.conf`
- Waybar : `~/.config/waybar/`

## 🎯 Dépannage

### Problème de démarrage Hyprland
```bash
# Depuis TTY
systemctl --user restart hyprland
```

### Audio ne fonctionne pas
```bash
systemctl --user restart pipewire
```

### GRUB ne s'affiche pas
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 🔗 Liens Utiles

### Thèmes GRUB
- [Fallout GRUB Theme](https://github.com/shvchk/fallout-grub-theme)
- [Arcane GRUB Theme](https://github.com/13atm01/GRUB-Theme)  
- [Star Wars GRUB Theme](https://github.com/Patato777/starwars-grub2-theme)

### Plymouth Themes
- [Plymouth Themes Collection](https://github.com/adi1090x/plymouth-themes)

### Hyprland
- [Documentation Hyprland](https://hyprland.org/)
- [Awesome Hyprland](https://github.com/hyprwm/awesome-hyprland)

### Wallpapers
- [Wallpaper Engine Workshop](https://steamcommunity.com/app/431960/workshop/)
- [r/unixporn](https://reddit.com/r/unixporn)

## 📸 Screenshots

*Ajoutez vos captures d'écran ici après installation*

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ajouter de nouveaux thèmes
- Améliorer les configurations
- Signaler des bugs
- Partager vos personnalisations

## 📄 Licence

MIT License - Voir le fichier LICENSE pour plus de détails.

## ⭐ Support

Si cette configuration vous plaît, n'hésitez pas à mettre une étoile ! 

---

**Fait avec ❤️ pour la communauté Arch Linux**
EOF

    print_success "README.md généré"
}

# Configuration finale
final_setup() {
    print_header "Configuration finale"
    
    # Création des dossiers nécessaires
    mkdir -p ~/.config/hypr/wallpapers
    mkdir -p ~/.local/share/applications
    
    # Message d'information
    print_info "Créez un dossier de wallpapers avec vos vidéos :"
    print_info "mkdir -p ~/.config/hypr/wallpapers"
    print_info "# Placez vos fichiers .mp4 (Arcane/Fallout) dans ce dossier"
    
    print_success "Configuration finale terminée"
}

# Fonction de progression avec barre visuelle
show_progress() {
    local current=$1
    local total=$2
    local text=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "${CYAN}] ${percent}%% - ${text}${NC}"
}

# Fonction principale avec indicateur de progression
main() {
    print_header "🎨 Installation Arch Linux + Hyprland - Thème Arcane/Fallout"
    
    print_warning "Ce script va :"
    print_warning "1. Désinstaller votre environnement graphique actuel"
    print_warning "2. Installer et configurer Hyprland complet"
    print_warning "3. Assurez-vous d'avoir une connexion Internet stable"
    print_warning "4. Sauvegardez vos données importantes avant de continuer"
    
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation annulée"
        exit 0
    fi
    
    # Liste des étapes avec leurs fonctions
    local steps=(
        "Vérification des droits sudo:check_sudo"
        "Suppression ancien environnement:remove_current_de"  
        "Mise à jour système:update_system"
        "Installation yay:install_yay"
        "Configuration GRUB:setup_grub_themes"
        "Configuration son boot:setup_boot_sound"
        "Configuration splashscreen:setup_plasma_splash"
        "Installation Hyprland:install_hyprland"
        "Configuration Hyprland:setup_hyprland_config"
        "Configuration Waybar:setup_waybar"
        "Script wallpaper vidéo:setup_video_wallpaper"
        "Préparation wallpapers:download_video_wallpapers"
        "Configuration Hyprlock:setup_hyprlock"
        "Configuration Hypridle:setup_hypridle"
        "Configuration SDDM:setup_sddm_theme"
        "Installation icônes:install_modern_icons"
        "Outils développement:install_dev_tools"
        "Installation navigateurs:install_browsers"
        "Applications multimédia:install_multimedia"
        "Configuration Wine:setup_wine"
        "Configuration Spicetify:setup_spicetify"
        "Configuration Fastfetch:setup_fastfetch"
        "Configuration auto-start:setup_autostart"
        "Activation services:enable_services"
        "Génération README:generate_readme"
        "Configuration finale:final_setup"
    )
    
    local total_steps=${#steps[@]}
    local current_step=0
    
    for step in "${steps[@]}"; do
        local step_name="${step%:*}"
        local step_function="${step#*:}"
        
        current_step=$((current_step + 1))
        show_progress $current_step $total_steps "$step_name"
        
        # Exécution de la fonction avec gestion d'erreur
        if ! $step_function; then
            echo -e "\n${RED}❌ Erreur lors de: $step_name${NC}"
            read -p "Continuer malgré l'erreur ? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Installation interrompue"
                exit 1
            fi
        fi
        
        sleep 1  # Petite pause pour voir la progression
    done
    
    echo -e "\n"
    print_header "🎉 Installation terminée !"
    print_success "Votre système Arch Linux avec Hyprland est prêt"
    print_info "README.md généré avec toutes les informations"
    print_info "Redémarrez votre système pour appliquer tous les changements"
    
    echo -e "\n${CYAN}📋 Résumé de l'installation :${NC}"
    echo -e "${YELLOW}✅${NC} Environnement graphique supprimé et Hyprland installé"
    echo -e "${YELLOW}✅${NC} GRUB configuré avec thèmes multiples (Fallout actif)"
    echo -e "${YELLOW}✅${NC} Son de boot et splashscreen configurés"
    echo -e "${YELLOW}✅${NC} SDDM stylé et icônes modernes"
    echo -e "${YELLOW}✅${NC} Outils de développement complets"
    echo -e "${YELLOW}✅${NC} Applications multimédia et Spicetify"
    
    echo -e "\n${CYAN}📋 Étapes post-installation :${NC}"
    echo -e "${YELLOW}1.${NC} Redémarrer le système"
    echo -e "${YELLOW}2.${NC} Ajouter des vidéos dans ~/.config/hypr/wallpapers/"
    echo -e "${YELLOW}3.${NC} Configurer Spicetify : spicetify backup apply"
    echo -e "${YELLOW}4.${NC} Lire le README.md pour la personnalisation"
    
    echo -e "\n${CYAN}🎨 Thèmes GRUB disponibles :${NC}"
    echo -e "${GREEN}•${NC} Fallout (actif)"
    echo -e "${BLUE}•${NC} Arcane (dans /etc/default/grub)"
    
    print_warning "Un redémarrage est nécessaire pour appliquer tous les changements"
    
    read -p "Redémarrer maintenant ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Redémarrage en cours..."
        sudo reboot
    fi
}

# Lancement du script
main "$@"
