#!/bin/bash


# Script de configuration Hyprland post-installation pour Arch Linux UNIQUEMENT 
# Version améliorée avec détection et suppression des DE existants
# Thème Arcane/Fallout avec transparence, blur et animations
# Support automatique : Intel, AMD, NVIDIA
# Auteur : PapaOursPolaire - available on GitHub
# Version : 24/08/2025 (j'ai oublié de compter)

set +e

LOGFILE="$HOME/file.log"
exec 2> >(tee -a "$LOGFILE" >&2)


# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales pour la détection GPU
GPU_TYPE=""
GPU_VENDOR=""
IS_NVIDIA=false
IS_AMD=false
IS_INTEL=false

# Variables pour la détection DE
CURRENT_DE=""
DETECTED_DES=()

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

print_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# Vérification des privilèges
check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Ce script ne doit pas être exécuté en tant que root"
        exit 1
    fi
}

# Détection et suppression des environnements de bureau existants
detect_current_desktop_environments() {
    print_header "Détection des environnements de bureau installés"
    
    DETECTED_DES=()
    
    # Détection GNOME
    if pacman -Qs gnome-shell >/dev/null 2>&1; then
        DETECTED_DES+=("GNOME")
        print_message "GNOME détecté"
    fi
    
    # Détection KDE Plasma
    if pacman -Qs plasma-desktop >/dev/null 2>&1; then
        DETECTED_DES+=("KDE")
        print_message "KDE Plasma détecté"
    fi
    
    # Détection XFCE
    if pacman -Qs xfce4-session >/dev/null 2>&1; then
        DETECTED_DES+=("XFCE")
        print_message "XFCE détecté"
    fi
    
    # Détection MATE
    if pacman -Qs mate-session-manager >/dev/null 2>&1; then
        DETECTED_DES+=("MATE")
        print_message "MATE détecté"
    fi
    
    # Détection Cinnamon
    if pacman -Qs cinnamon-session >/dev/null 2>&1; then
        DETECTED_DES+=("Cinnamon")
        print_message "Cinnamon détecté"
    fi
    
    # Détection LXDE/LXQt
    if pacman -Qs lxde-common >/dev/null 2>&1 || pacman -Qs lxqt-session >/dev/null 2>&1; then
        DETECTED_DES+=("LXDE/LXQt")
        print_message "LXDE/LXQt détecté"
    fi
    
    # Détection i3/Sway
    if pacman -Qs i3-wm >/dev/null 2>&1 || pacman -Qs sway >/dev/null 2>&1; then
        DETECTED_DES+=("i3/Sway")
        print_message "i3/Sway détecté"
    fi
    
    # Détection Awesome/dwm/bspwm
    if pacman -Qs awesome >/dev/null 2>&1 || pacman -Qs dwm >/dev/null 2>&1 || pacman -Qs bspwm >/dev/null 2>&1; then
        DETECTED_DES+=("Other WM")
        print_message "Autres gestionnaires de fenêtres détectés"
    fi
    
    if [ ${#DETECTED_DES[@]} -eq 0 ]; then
        print_success "Aucun environnement de bureau détecté"
    else
        print_warning "Environnements détectés : ${DETECTED_DES[*]}"
    fi
}

remove_desktop_environments() {
    if [ ${#DETECTED_DES[@]} -eq 0 ]; then
        print_message "Aucun environnement à supprimer"
        return
    fi
    
    print_header "Suppression des environnements de bureau existants"
    
    echo -e "${YELLOW}Les environnements suivants ont été détectés :${NC}"
    for de in "${DETECTED_DES[@]}"; do
        echo -e "  - $de"
    done
    echo ""
    
    read -p "Voulez-vous supprimer ces environnements ? (y/N) : " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Suppression annulée. Les environnements existants peuvent causer des conflits."
        return
    fi
    
    for de in "${DETECTED_DES[@]}"; do
        case $de in
            "GNOME")
                print_message "Suppression de GNOME..."
                sudo pacman -Rns --noconfirm gnome-shell gnome-desktop gnome-session \
                    gnome-settings-daemon gnome-control-center nautilus gdm \
                    gnome-terminal gnome-tweaks mutter 2>/dev/null || true
                sudo systemctl disable gdm 2>/dev/null || true
                ;;
            "KDE")
                print_message "Suppression de KDE Plasma..."
                sudo pacman -Rns --noconfirm plasma-desktop plasma-workspace \
                    plasma-session kde-applications kwin dolphin konsole \
                    sddm-kcm systemsettings 2>/dev/null || true
                ;;
            "XFCE")
                print_message "Suppression de XFCE..."
                sudo pacman -Rns --noconfirm xfce4-session xfce4-panel \
                    xfdesktop xfwm4 thunar xfce4-terminal lightdm 2>/dev/null || true
                sudo systemctl disable lightdm 2>/dev/null || true
                ;;
            "MATE")
                print_message "Suppression de MATE..."
                sudo pacman -Rns --noconfirm mate-session-manager mate-panel \
                    mate-desktop caja mate-terminal 2>/dev/null || true
                ;;
            "Cinnamon")
                print_message "Suppression de Cinnamon..."
                sudo pacman -Rns --noconfirm cinnamon-session cinnamon-desktop \
                    cinnamon nemo 2>/dev/null || true
                ;;
            "LXDE/LXQt")
                print_message "Suppression de LXDE/LXQt..."
                sudo pacman -Rns --noconfirm lxde-common lxqt-session \
                    lxqt-panel pcmanfm qterminal 2>/dev/null || true
                ;;
            "i3/Sway")
                print_message "Suppression de i3/Sway..."
                sudo pacman -Rns --noconfirm i3-wm i3status i3blocks \
                    sway swaylock swayidle 2>/dev/null || true
                ;;
            "Other WM")
                print_message "Suppression d'autres gestionnaires de fenêtres..."
                sudo pacman -Rns --noconfirm awesome dwm bspwm 2>/dev/null || true
                ;;
        esac
    done
    
    # Nettoyage des display managers
    print_message "Désactivation des display managers existants..."
    sudo systemctl disable gdm lightdm lxdm xdm sddm 2>/dev/null || true
    
    # Nettoyage des configurations utilisateur
    print_message "Nettoyage des configurations utilisateur..."
    rm -rf ~/.config/gnome* ~/.config/kde* ~/.config/xfce* ~/.config/mate* \
            ~/.config/cinnamon* ~/.config/lxde* ~/.config/lxqt* ~/.config/i3* \
            ~/.config/sway* ~/.config/awesome* ~/.config/bspwm* 2>/dev/null || true
    
    print_success "Environnements de bureau supprimés"
}

enable_multilib() {
    print_header "Activation du dépôt multilib"
    if ! grep -Pq '^\[multilib\]' /etc/pacman.conf; then
        sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
        sudo sed -i '/^\[multilib\]/{n;s/^#//}' /etc/pacman.conf
        print_success "multilib activé dans /etc/pacman.conf"
        sudo pacman -Sy --noconfirm
    else
        print_message "multilib déjà activé"
    fi
}

# Déctection du GPU
detect_gpu() {
    print_header "Détection automatique du GPU"

    # Vérifie que lspci est dispo
    if ! command -v lspci &>/dev/null; then
        print_message "Installation de pciutils (lspci)..."
        sudo pacman -S --noconfirm pciutils
    fi

    # Récupère les lignes VGA/3D/Display
    local gpu_lines
    gpu_lines=$(lspci -nn | grep -E "(VGA|3D|Display)" || true)

    if [ -z "$gpu_lines" ]; then
        print_warning "Aucun GPU détecté via lspci"
        GPU_TYPE="generic"
        GPU_VENDOR="Inconnu"
        return
    fi

    print_message "Lignes PCI détectées :"
    echo "$gpu_lines" | while read -r line; do
        print_message "  $line"
    done

    # Init des variables
    IS_NVIDIA=false
    IS_AMD=false
    IS_INTEL=false
    GPU_TYPE=""
    GPU_VENDOR=""

    # Détection par ordre de priorité (si plusieurs GPU)
    if echo "$gpu_lines" | grep -q '\[10de:'; then
        IS_NVIDIA=true
        GPU_VENDOR="NVIDIA"
        GPU_TYPE="nvidia"
        print_success "GPU NVIDIA détecté (Vendor ID 10de)"
    elif echo "$gpu_lines" | grep -q '\[1002:'; then
        IS_AMD=true
        GPU_VENDOR="AMD"
        GPU_TYPE="amd"
        print_success "GPU AMD détecté (Vendor ID 1002)"
    elif echo "$gpu_lines" | grep -q '\[8086:'; then
        IS_INTEL=true
        GPU_VENDOR="Intel"
        GPU_TYPE="intel"
        print_success "GPU Intel détecté (Vendor ID 8086)"
    else
        print_warning "GPU non reconnu par Vendor ID, utilisation de la configuration générique"
        GPU_VENDOR="Générique"
        GPU_TYPE="generic"
    fi

    print_message "Configuration GPU finale : $GPU_TYPE ($GPU_VENDOR)"
    
    # Debug (seulement si demandé via variable d'environnement)
    if [ "$DEBUG_GPU" = "1" ]; then
        print_message "DEBUG GPU_VENDOR = $GPU_VENDOR"
        print_message "DEBUG GPU_TYPE   = $GPU_TYPE"
        print_message "DEBUG IS_INTEL   = $IS_INTEL"
        print_message "DEBUG IS_AMD     = $IS_AMD"
        print_message "DEBUG IS_NVIDIA  = $IS_NVIDIA"
    fi
}

# Installation des drivers GPU
remove_conflicting_drivers() {
    print_header "Suppression des drivers graphiques conflictuels"
    
    # Suppression des drivers NVIDIA conflictuels
    sudo pacman -Rns --noconfirm nvidia nvidia-dkms nvidia-lts \
        nvidia-utils lib32-nvidia-utils nvidia-settings \
        nouveau-dri xf86-video-nouveau 2>/dev/null || true
    
    # Suppression des drivers AMD conflictuels
    sudo pacman -Rns --noconfirm xf86-video-ati xf86-video-amdgpu-pro 2>/dev/null || true
    
    # Suppression des drivers Intel conflictuels
    sudo pacman -Rns --noconfirm xf86-video-intel-legacy 2>/dev/null || true
    
    print_success "Drivers conflictuels supprimés"
}

install_gpu_drivers() {
    print_header "Installation des drivers GPU ($GPU_VENDOR)"
    
    remove_conflicting_drivers
    
    case $GPU_TYPE in
        "nvidia")
            install_nvidia_drivers
            ;;
        "amd")
            install_amd_drivers
            ;;
        "intel")
            install_intel_drivers
            ;;
        *)
            print_warning "GPU non reconnu, installation des drivers génériques"
            install_generic_drivers
            ;;
    esac
}

install_nvidia_drivers() {
    print_message "Installation des drivers NVIDIA..."
    
    # Détection du kernel en cours
    local kernel_version=$(uname -r)
    local nvidia_package="nvidia-dkms"
    
    if [[ $kernel_version == *"-lts" ]]; then
        nvidia_package="nvidia-lts"
        print_message "Kernel LTS détecté, utilisation de nvidia-lts"
    fi
    
    # Installation des drivers NVIDIA
    sudo pacman -S --noconfirm --needed \
        $nvidia_package nvidia-utils lib32-nvidia-utils \
        nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader \
        mesa lib32-mesa egl-wayland
    
    # Configuration du kernel pour DKMS
    if [[ $nvidia_package == "nvidia-dkms" ]]; then
        print_message "Configuration des modules NVIDIA dans initramfs..."
        if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
            sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        fi
    fi
    
    # Hook NVIDIA pour les mises à jour automatiques
    sudo mkdir -p /etc/pacman.d/hooks
    sudo tee /etc/pacman.d/hooks/nvidia.hook > /dev/null << 'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=nvidia-lts
Target=linux
Target=linux-lts

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF
    
    # Configuration des paramètres du kernel
    sudo mkdir -p /etc/modprobe.d
    sudo tee /etc/modprobe.d/nvidia.conf > /dev/null << 'EOF'
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
    
    # Variables d'environnement NVIDIA
    sudo tee /etc/environment > /dev/null << 'EOF'
# NVIDIA Wayland Support
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
LIBVA_DRIVER_NAME=nvidia
XDG_SESSION_TYPE=wayland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
# NVIDIA Performance
__GL_GSYNC_ALLOWED=1
__GL_VRR_ALLOWED=1
WLR_DRM_NO_ATOMIC=1
EOF
    
    print_success "Drivers NVIDIA installés et configurés"
}

install_amd_drivers() {
    print_message "Installation des drivers AMD..."
    
    # Drivers AMD open-source
    sudo pacman -S --noconfirm --needed \
        mesa lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon \
        libva-mesa-driver lib32-libva-mesa-driver \
        mesa-vdpau lib32-mesa-vdpau \
        xf86-video-amdgpu
    
    # Configuration du kernel
    sudo mkdir -p /etc/modprobe.d
    sudo tee /etc/modprobe.d/amdgpu.conf > /dev/null << 'EOF'
options amdgpu si_support=1
options amdgpu cik_support=1
options radeon si_support=0
options radeon cik_support=0
EOF
    
    # Variables d'environnement AMD
    sudo tee /etc/environment > /dev/null << 'EOF'
# AMD Optimizations
RADV_PERFTEST=aco
AMD_VULKAN_ICD=RADV
RADV_DEBUG=zerovram
# Wayland Support
XDG_SESSION_TYPE=wayland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
EOF
    
    print_success "Drivers AMD installés et configurés"
}

install_intel_drivers() {
    print_message "Installation des drivers Intel..."
    
    # Drivers Intel
    sudo pacman -S --noconfirm --needed \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        mesa-vdpau lib32-mesa-vdpau \
        libva-intel-driver lib32-libva-intel-driver \
        intel-media-driver \
        xf86-video-intel
    
    # Configuration Intel
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/20-intel.conf > /dev/null << 'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "AccelMethod" "sna"
    Option "TearFree" "true"
EndSection
EOF
    
    # Variables d'environnement Intel
    sudo tee /etc/environment > /dev/null << 'EOF'
# Intel Optimizations
INTEL_DEBUG=norbc
LIBVA_DRIVER_NAME=iHD
# Wayland Support
XDG_SESSION_TYPE=wayland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
# Intel-specific Wayland fixes
WLR_NO_HARDWARE_CURSORS=1
WLR_DRM_NO_ATOMIC=1
EOF
    
    print_success "Drivers Intel installés et configurés"
}

install_generic_drivers() {
    print_message "Installation des drivers génériques..."
    
    sudo pacman -S --noconfirm --needed \
        mesa lib32-mesa \
        vulkan-icd-loader lib32-vulkan-icd-loader
    
    # Variables d'environnement génériques
    sudo tee /etc/environment > /dev/null << 'EOF'
# Generic Wayland Support
XDG_SESSION_TYPE=wayland
GDK_BACKEND=wayland
QT_QPA_PLATFORM=wayland
WLR_NO_HARDWARE_CURSORS=1
EOF
    
    print_success "Drivers génériques installés"
}

# Installation des packages avec yay (AUR helper)
install_yay() {
    if ! command -v yay &> /dev/null; then
        print_message "Installation de yay (AUR helper)..."
        sudo pacman -S --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
        print_success "yay installé avec succès"
    else
        print_success "yay déjà installé"
    fi
}

# Génération de la configuration Hyprland optimisée selon le GPU
get_gpu_optimized_config() {
    case $GPU_TYPE in
        "nvidia")
            get_nvidia_config
            ;;
        "amd")
            get_amd_config
            ;;
        "intel")
            get_intel_config
            ;;
        *)
            get_generic_config
            ;;
    esac
}

get_nvidia_config() {
    cat << 'EOF'

# Configuration NVIDIA optimisée


# Variables d'environnement NVIDIA
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_SCALE,1
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = LIBVA_DRIVER_NAME,nvidia
env = __GL_GSYNC_ALLOWED,1
env = __GL_VRR_ALLOWED,1

# Optimisations de rendu NVIDIA
render {
    explicit_sync = 2
    explicit_sync_kms = 2
    direct_scanout = true
}

cursor {
    no_hardware_cursors = true
}

# Décoration - Configuration haute performance NVIDIA
decoration {
    rounding = 12
    active_opacity = 0.95
    inactive_opacity = 0.85
    
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = true
        ignore_opacity = false
        contrast = 1.1
        brightness = 1.2
    }
    
    drop_shadow = true
    shadow_range = 8
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    shadow_offset = 2, 2
}

# Animations - Performance élevée NVIDIA
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    
    animation = windows, 1, 6, wind, slide
    animation = windowsIn, 1, 6, winIn, slide
    animation = windowsOut, 1, 5, winOut, slide
    animation = windowsMove, 1, 5, wind, slide
    animation = border, 1, 10, linear
    animation = borderangle, 1, 8, linear
    animation = fade, 1, 7, default
    animation = workspaces, 1, 5, wind
}
EOF
}

get_amd_config() {
    cat << 'EOF'

# Configuration AMD optimisée


# Variables d'environnement AMD
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_SCALE,1
env = RADV_PERFTEST,aco
env = AMD_VULKAN_ICD,RADV
env = RADV_DEBUG,zerovram

# Optimisations de rendu AMD
render {
    explicit_sync = 1
    explicit_sync_kms = 1
    direct_scanout = true
}

# Décoration - Configuration optimisée AMD
decoration {
    rounding = 10
    active_opacity = 0.95
    inactive_opacity = 0.9
    
    blur {
        enabled = true
        size = 6
        passes = 2
        new_optimizations = true
        xray = true
        ignore_opacity = false
        contrast = 1.0
        brightness = 1.0
    }
    
    drop_shadow = true
    shadow_range = 6
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
    shadow_offset = 1, 1
}

# Animations - Performance bonne AMD
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    bezier = linear, 0.0, 0.0, 1.0, 1.0
    
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, linear
    animation = borderangle, 1, 7, linear
    animation = fade, 1, 6, default
    animation = workspaces, 1, 4, myBezier
}
EOF
}

get_intel_config() {
    cat << 'EOF'

# Configuration Intel optimisée


# Variables d'environnement Intel
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_SCALE,1
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_DRM_NO_ATOMIC,1
env = INTEL_DEBUG,norbc
env = LIBVA_DRIVER_NAME,iHD

# Optimisations Intel (performance réduite)
render {
    explicit_sync = 0
    explicit_sync_kms = 0
    direct_scanout = false
}

cursor {
    no_hardware_cursors = true
}

# Décoration - Configuration allégée Intel
decoration {
    rounding = 8
    active_opacity = 1.0
    inactive_opacity = 0.98
    
    blur {
        enabled = true
        size = 3
        passes = 1
        new_optimizations = true
        xray = false
        ignore_opacity = true
    }
    
    drop_shadow = false
    shadow_range = 3
    shadow_render_power = 2
    col.shadow = rgba(1a1a1a88)
}

# Animations - Performance réduite pour Intel
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    
    animation = windows, 1, 4, myBezier
    animation = windowsOut, 1, 4, default, popin 80%
    animation = border, 1, 5, default
    animation = borderangle, 1, 5, default
    animation = fade, 1, 4, default
    animation = workspaces, 1, 3, myBezier
}
EOF
}

get_generic_config() {
    cat << 'EOF'

# Configuration générique


# Variables d'environnement génériques
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_SCALE,1
env = WLR_NO_HARDWARE_CURSORS,1

# Optimisations génériques
render {
    explicit_sync = 1
    explicit_sync_kms = 1
    direct_scanout = false
}

# Décoration - Configuration équilibrée
decoration {
    rounding = 10
    active_opacity = 0.98
    inactive_opacity = 0.92
    
    blur {
        enabled = true
        size = 5
        passes = 2
        new_optimizations = true
        xray = false
        ignore_opacity = false
    }
    
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 2
    col.shadow = rgba(1a1a1aee)
}

# Animations - Performance équilibrée
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 6, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, myBezier
}
EOF
}

# 1. Installation des composants graphiques
install_graphics() {
    print_header "Installation des composants graphiques"
    
    # Packages officiels essentiels
    sudo pacman -S --noconfirm --needed \
        hyprland hyprpaper hypridle hyprlock \
        polkit-gnome \
        waybar wofi kitty thunar dunst \
        sddm qt5-quickcontrols2 qt5-svg qt5-graphicaleffects \
        pipewire pipewire-pulse pipewire-alsa wireplumber \
        pavucontrol cava \
        grim slurp wl-clipboard \
        brightnessctl \
        network-manager-applet \
        bluez bluez-utils blueman \
        noto-fonts noto-fonts-emoji ttf-fira-code \
        python-requests python-pillow \
        qt5ct qt6ct

    sudo pacman -S --noconfirm --needed \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk || print_warning "Échec d'installation de xdg-desktop-portal-gtk"

    
    # Installation des paquets AUR individuellement avec gestion d'erreurs
    for pkg in mpvpaper google-chrome brave-bin visual-studio-code-bin spotify spicetify-cli; do
        print_message "Installation de $pkg..."
        yay -S --noconfirm --needed "$pkg" || print_warning "$pkg a échoué mais on continue"
    done

    if command -v spicetify &>/dev/null; then
        print_message "Configuration de Spicetify..."
        spicetify backup apply || print_warning "Spicetify a échoué, mais on continue"
    fi

    # Configuration Flatpak pour applications supplémentaires
    sudo pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    print_success "Composants graphiques installés"
}

# 2. Installation des outils de développement
install_dev_tools() {
    print_header "Installation des outils de développement"
    
    sudo pacman -S --noconfirm --needed \
        jdk-openjdk python nodejs npm docker \
        gcc clang cmake make git \
        wine winetricks wine-mono wine-gecko

    # Activation de Docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    print_success "Outils de développement installés"
}

# 3. Configuration des dossiers
setup_directories() {
    print_header "Création des dossiers de configuration"
    
    mkdir -p ~/.config/{hypr,waybar,kitty,dunst,wofi,fastfetch}
    mkdir -p ~/.local/share/sounds
    mkdir -p ~/Videos/Wallpapers
    mkdir -p ~/Pictures/Screenshots
    
    print_success "Dossiers créés"
}

# 4. Configuration Hyprland adaptée au GPU
configure_hyprland() {
    print_header "Configuration de Hyprland (optimisée pour $GPU_VENDOR)"
    
    # Configuration de base
    cat > ~/.config/hypr/hyprland.conf << 'EOF'

# Configuration Hyprland - Thème Arcane/Fallout
# Optimisée automatiquement selon le GPU détecté


# Moniteurs
monitor = ,preferred,auto,1

EOF

    # Ajouter la configuration spécifique au GPU
    get_gpu_optimized_config >> ~/.config/hypr/hyprland.conf
    
    # Ajouter la configuration commune
    cat >> ~/.config/hypr/hyprland.conf << 'EOF'

# Démarrage automatique
exec-once = waybar &
exec-once = dunst &
exec-once = ~/.config/hypr/video-wallpaper.sh &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = blueman-applet &
exec-once = nm-applet &
exec-once = hypridle &

# Variables
$terminal = kitty
$fileManager = thunar
$menu = wofi --show drun

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

# Layout dwindle
dwindle {
    pseudotile = true
    preserve_split = true
    force_split = 0
    split_width_multiplier = 1.0
    no_gaps_when_only = false
    use_active_for_splits = true
}

# Layout master
master {
    new_is_master = true
    new_on_top = false
    no_gaps_when_only = false
    orientation = left
    inherit_fullscreen = true
    always_center_master = false
    smart_resizing = true
    drop_at_cursor = true
}

# Gestes
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
    workspace_swipe_distance = 300
    workspace_swipe_invert = true
    workspace_swipe_min_speed_to_force = 30
    workspace_swipe_cancel_ratio = 0.5
    workspace_swipe_create_new = true
    workspace_swipe_forever = false
}

# Divers
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = false
    vrr = 0
    animate_manual_resizes = true
    animate_mouse_windowdragging = true
    enable_swallow = true
    swallow_regex = ^(kitty)$
}

# Binds
binds {
    scroll_event_delay = 300
    workspace_back_and_forth = false
    allow_workspace_cycles = false
    pass_mouse_when_bound = false
}

# Périphériques d'entrée
input {
    kb_layout = fr
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    follow_mouse = 1
    sensitivity = 0
    accel_profile = flat
    
    touchpad {
        natural_scroll = true
        scroll_factor = 1.0
        middle_button_emulation = false
        tap_button_map = lrm
        clickfinger_behavior = false
        tap-to-click = true
        drag_lock = false
        tap-and-drag = false
    }
}

device {
    name = epic-mouse-v1
    sensitivity = -0.5
}

# Règles de fenêtres - Transparence adaptée au GPU
EOF

    # Transparence adaptée selon le GPU
    if $IS_NVIDIA; then
        cat >> ~/.config/hypr/hyprland.conf << 'EOF'
# Règles de transparence optimisées NVIDIA
windowrulev2 = opacity 0.95 0.95,class:^(code|Code)$
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$
windowrulev2 = opacity 0.85 0.85,class:^(thunar)$
windowrulev2 = opacity 0.95 0.95,class:^(spotify|Spotify)$
windowrulev2 = opacity 0.90 0.90,class:^(discord|Discord)$
windowrulev2 = opacity 0.95 0.95,class:^(obsidian)$
EOF
    elif $IS_INTEL; then
        cat >> ~/.config/hypr/hyprland.conf << 'EOF'
# Règles de transparence allégées Intel
windowrulev2 = opacity 1.0 1.0,class:^(code|Code)$
windowrulev2 = opacity 0.98 0.98,class:^(kitty)$
windowrulev2 = opacity 1.0 1.0,class:^(thunar)$
windowrulev2 = opacity 1.0 1.0,class:^(spotify|Spotify)$
windowrulev2 = opacity 1.0 1.0,class:^(discord|Discord)$
windowrulev2 = opacity 1.0 1.0,class:^(obsidian)$
EOF
    else
        cat >> ~/.config/hypr/hyprland.conf << 'EOF'
# Règles de transparence équilibrées AMD/Générique
windowrulev2 = opacity 0.98 0.98,class:^(code|Code)$
windowrulev2 = opacity 0.92 0.92,class:^(kitty)$
windowrulev2 = opacity 0.90 0.90,class:^(thunar)$
windowrulev2 = opacity 0.98 0.98,class:^(spotify|Spotify)$
windowrulev2 = opacity 0.95 0.95,class:^(discord|Discord)$
windowrulev2 = opacity 0.98 0.98,class:^(obsidian)$
EOF
    fi

    # Règles communes
    cat >> ~/.config/hypr/hyprland.conf << 'EOF'

# Règles communes
windowrulev2 = opacity 1.0 1.0,class:^(google-chrome|chrome)$
windowrulev2 = opacity 1.0 1.0,class:^(brave-browser|Brave-browser)$
windowrulev2 = opacity 1.0 1.0,class:^(firefox)$
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(blueman-manager)$
windowrulev2 = float,class:^(nm-applet)$
windowrulev2 = float,class:^(nm-connection-editor)$
windowrulev2 = float,title:^(Picture-in-Picture)$
windowrulev2 = pin,title:^(Picture-in-Picture)$

# Règles pour les jeux (performance maximale)
windowrulev2 = opacity 1.0 override 1.0 override,class:^(steam_app)
windowrulev2 = opacity 1.0 override 1.0 override,class:^(gamescope)
windowrulev2 = fullscreen,class:^(steam_app)
windowrulev2 = monitor 0,class:^(steam_app)
windowrulev2 = workspace 10,class:^(steam_app)

# Raccourcis clavier
$mainMod = SUPER

# Applications principales
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, hyprlock
bind = $mainMod, F, fullscreen
bind = $mainMod, T, exec, ~/.local/bin/toggle-transparency

# Applications spécifiques
bind = $mainMod, W, exec, google-chrome-stable
bind = $mainMod SHIFT, W, exec, brave
bind = $mainMod, D, exec, discord
bind = $mainMod, S, exec, spotify
bind = $mainMod, N, exec, obsidian

# Captures d'écran
bind = , Print, exec, ~/.local/bin/screenshot-menu
bind = $mainMod, Print, exec, grim ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d_%H%M%S).png && notify-send "Capture d'écran" "Écran complet sauvegardé"
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y%m%d_%H%M%S).png && notify-send "Capture d'écran" "Zone sélectionnée sauvegardée"

# Contrôles audio
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Contrôles multimédia
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioPause, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Contrôles de luminosité
bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Navigation fenêtres
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Navigation clavier alternatives
bind = $mainMod, H, movefocus, l
bind = $mainMod, L, movefocus, r
bind = $mainMod, K, movefocus, u
bind = $mainMod, J, movefocus, d

# Redimensionner les fenêtres
bind = $mainMod SHIFT, left, resizeactive, -10 0
bind = $mainMod SHIFT, right, resizeactive, 10 0
bind = $mainMod SHIFT, up, resizeactive, 0 -10
bind = $mainMod SHIFT, down, resizeactive, 0 10

# Déplacer les fenêtres
bind = $mainMod CTRL, left, movewindow, l
bind = $mainMod CTRL, right, movewindow, r
bind = $mainMod CTRL, up, movewindow, u
bind = $mainMod CTRL, down, movewindow, d

# Navigation workspaces
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

# Workspace spécial (scratchpad)
bind = $mainMod, grave, togglespecialworkspace, magic
bind = $mainMod SHIFT, grave, movetoworkspace, special:magic

# Scroll workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Déplacer/redimensionner fenêtres avec la souris
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Gestion de l'énergie
bind = $mainMod SHIFT, Q, exec, ~/.local/bin/power-menu

# Mode redimensionnement
bind = $mainMod, R, submap, resize
submap = resize
binde = , right, resizeactive, 10 0
binde = , left, resizeactive, -10 0
binde = , up, resizeactive, 0 -10
binde = , down, resizeactive, 0 10
bind = , escape, submap, reset
submap = reset
EOF

    print_success "Configuration Hyprland créée et optimisée pour $GPU_VENDOR"
}

# 5. Script de fond vidéo animé (adapté au GPU)
create_video_wallpaper() {
    print_header "Création du script de fond vidéo (optimisé $GPU_VENDOR)"
    
    if $IS_INTEL; then
        # Version simplifiée pour Intel
        cat > ~/.config/hypr/video-wallpaper.sh << 'EOF'
#!/bin/bash
# Script de fond d'écran simplifié pour Intel Graphics

WALLPAPER_DIR="$HOME/Videos/Wallpapers"
FALLBACK_COLOR="#0f0f23"

# Fonction de nettoyage
cleanup() {
    pkill -f mpvpaper 2>/dev/null || true
}

trap cleanup EXIT

# Vérifier les vidéos disponibles
if [ -d "$WALLPAPER_DIR" ] && [ "$(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" 2>/dev/null | head -1)" ]; then
    VIDEO_FILES=()
    while IFS= read -r -d '' file; do
        VIDEO_FILES+=("$file")
    done < <(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" -print0 2>/dev/null)
    
    if [ ${#VIDEO_FILES[@]} -gt 0 ]; then
        RANDOM_VIDEO=${VIDEO_FILES[$RANDOM % ${#VIDEO_FILES[@]}]}
        echo "Lecture du fond d'écran (Intel optimisé): $(basename "$RANDOM_VIDEO")"
        # Options optimisées pour Intel
        exec mpvpaper -o "loop-file=inf --volume=0 --hwdec=no --vo=gpu --gpu-api=opengl --opengl-backend=wayland --profile=low-latency" '*' "$RANDOM_VIDEO"
    else
        echo "Aucune vidéo valide trouvée"
        hyprctl hyprpaper wallpaper ",$FALLBACK_COLOR" 2>/dev/null || true
    fi
else
    echo "Aucune vidéo trouvée, utilisation de la couleur de fallback"
    hyprctl hyprpaper wallpaper ",$FALLBACK_COLOR" 2>/dev/null || true
fi
EOF
    else
        # Version complète pour NVIDIA/AMD
        cat > ~/.config/hypr/video-wallpaper.sh << 'EOF'
#!/bin/bash
# Script de fond d'écran vidéo - Optimisé pour GPU performant

WALLPAPER_DIR="$HOME/Videos/Wallpapers"
FALLBACK_COLOR="#0f0f23"

# Fonction de nettoyage
cleanup() {
    pkill -f mpvpaper 2>/dev/null || true
}

trap cleanup EXIT

mkdir -p "$WALLPAPER_DIR"

if [ -z "$(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" 2>/dev/null | head -1)" ]; then
    echo "Dossier de wallpapers vide, utilisation de la couleur de fallback..."
    hyprctl hyprpaper wallpaper ",$FALLBACK_COLOR" 2>/dev/null || true
    exit 0
fi

VIDEO_FILES=()
while IFS= read -r -d '' file; do
    VIDEO_FILES+=("$file")
done < <(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" -print0 2>/dev/null)

if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
    echo "Aucune vidéo valide trouvée, utilisation de la couleur de fallback..."
    hyprctl hyprpaper wallpaper ",$FALLBACK_COLOR" 2>/dev/null || true
    exit 0
fi

RANDOM_VIDEO=${VIDEO_FILES[$RANDOM % ${#VIDEO_FILES[@]}]}
echo "Lecture du fond d'écran : $(basename "$RANDOM_VIDEO")"

# Options optimisées selon le GPU
if command -v nvidia-smi >/dev/null 2>&1; then
    # Configuration NVIDIA
    exec mpvpaper -o "loop-file=inf --volume=0 --hwdec=nvdec --vo=gpu --gpu-api=vulkan --profile=gpu-hq" '*' "$RANDOM_VIDEO"
else
    # Configuration AMD/générique
    exec mpvpaper -o "loop-file=inf --volume=0 --hwdec=vaapi --vo=gpu --gpu-api=vulkan --profile=gpu-hq" '*' "$RANDOM_VIDEO"
fi

echo "Pour ajouter vos propres vidéos, placez-les dans : $WALLPAPER_DIR"
EOF
    fi

    chmod +x ~/.config/hypr/video-wallpaper.sh
    print_success "Script de fond vidéo créé (optimisé pour $GPU_VENDOR)"
}

# 6. Configuration Waybar
configure_waybar() {
    print_header "Configuration de Waybar"
    
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 42,
    "spacing": 4,
    "margin-top": 8,
    "margin-left": 16,
    "margin-right": 16,
    
    "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/scratchpad", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "idle_inhibitor", "pulseaudio", "network", "cpu", "memory", "temperature", "battery", "custom/power"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
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
            "10": "󰿬",
            "active": "",
            "default": ""
        },
        "persistent_workspaces": {
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
    
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    
    "clock": {
        "timezone": "Europe/Brussels",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format": " {:%H:%M   %d/%m/%Y}",
        "format-alt": " {:%A, %B %d, %Y}"
    },
    
    "cpu": {
        "format": " {usage}%",
        "tooltip": true,
        "interval": 2
    },
    
    "memory": {
        "format": " {}%",
        "tooltip-format": "Memory: {used:0.1f}G/{total:0.1f}G"
    },
    
    "temperature": {
        "critical-threshold": 80,
        "format": "{icon} {temperatureC}°C",
        "format-icons": ["", "", ""]
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% 󰂄",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    
    "network": {
        "format-wifi": "  {essid} ({signalStrength}%)",
        "format-ethernet": "󰈀  {ipaddr}/{cidr}",
        "tooltip-format": "{ifname} via {gwaddr}",
        "format-linked": "󰈀  {ifname} (No IP)",
        "format-disconnected": "⚠  Disconnected",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click-right": "nm-connection-editor"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}% {format_source}",
        "format-bluetooth": "{icon} {volume}% {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": " {volume}%",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "󰂑",
            "headset": "󰂑",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "on-click-middle": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    },
    
    "tray": {
        "spacing": 10
    },
    
    "custom/power": {
        "format": "⏻",
        "tooltip": "Power Menu",
        "on-click": "~/.local/bin/power-menu"
    }
}
EOF

    cat > ~/.config/waybar/style.css << 'EOF'

* {
    border: none;
    border-radius: 0;
    font-family: 'Fira Code', 'Font Awesome 6 Free', monospace;
    font-size: 14px;
    min-height: 0;
    font-weight: 600;
}

window#waybar {
    background: linear-gradient(135deg, rgba(15, 15, 35, 0.95), rgba(25, 25, 45, 0.9));
    border: 2px solid rgba(51, 204, 255, 0.4);
    border-radius: 20px;
    color: #ffffff;
    transition: all 0.3s ease;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(10px);
}

window#waybar.hidden {
    opacity: 0.2;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 12px;
    transition: all 0.3s ease;
}

#workspaces {
    background: rgba(0, 0, 0, 0.2);
    border-radius: 15px;
    margin: 5px;
    padding: 0 5px;
}

#workspaces button {
    padding: 5px 12px;
    background: transparent;
    color: rgba(255, 255, 255, 0.7);
    border-radius: 12px;
    margin: 2px;
    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

#workspaces button:hover {
    background: rgba(51, 204, 255, 0.3);
    color: #33ccff;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(51, 204, 255, 0.4);
}

#workspaces button.active {
    background: linear-gradient(135deg, rgba(51, 204, 255, 0.6), rgba(0, 255, 153, 0.4));
    color: #ffffff;
    box-shadow: 0 0 20px rgba(51, 204, 255, 0.5);
    transform: scale(1.05);
}

#workspaces button.urgent {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.7), rgba(255, 20, 20, 0.5));
    color: #ffffff;
    animation: urgent-pulse 2s infinite;
}

@keyframes urgent-pulse {
    0%, 100% { box-shadow: 0 0 20px rgba(255, 85, 85, 0.5); }
    50% { box-shadow: 0 0 30px rgba(255, 85, 85, 0.8); }
}

#mode,
#scratchpad,
#window,
#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#idle_inhibitor,
#tray,
#custom-power {
    padding: 6px 14px;
    margin: 3px 2px;
    border-radius: 12px;
    background: rgba(0, 0, 0, 0.3);
    color: #ffffff;
    transition: all 0.3s ease;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

#window {
    background: linear-gradient(90deg, rgba(139, 233, 253, 0.2), rgba(189, 147, 249, 0.2));
    color: #8be9fd;
    font-style: italic;
}

#clock {
    background: linear-gradient(135deg, rgba(51, 204, 255, 0.3), rgba(0, 255, 153, 0.2));
    color: #33ccff;
    font-weight: bold;
    font-size: 15px;
    border: 1px solid rgba(51, 204, 255, 0.3);
    box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

#battery {
    background: linear-gradient(135deg, rgba(0, 255, 153, 0.3), rgba(80, 250, 123, 0.2));
    color: #50fa7b;
}

#battery.charging, #battery.plugged {
    background: linear-gradient(135deg, rgba(0, 255, 153, 0.4), rgba(80, 250, 123, 0.3));
    animation: charging-pulse 2s infinite;
}

@keyframes charging-pulse {
    0%, 100% { box-shadow: 0 0 15px rgba(0, 255, 153, 0.3); }
    50% { box-shadow: 0 0 25px rgba(0, 255, 153, 0.6); }
}

@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

#battery.critical:not(.charging) {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.5), rgba(255, 20, 20, 0.3));
    color: #ff5555;
    animation: blink 1s infinite;
}

#cpu {
    background: linear-gradient(135deg, rgba(241, 250, 140, 0.3), rgba(255, 255, 0, 0.2));
    color: #f1fa8c;
}

#memory {
    background: linear-gradient(135deg, rgba(255, 121, 198, 0.3), rgba(255, 20, 147, 0.2));
    color: #ff79c6;
}

#temperature {
    background: linear-gradient(135deg, rgba(255, 184, 108, 0.3), rgba(255, 140, 0, 0.2));
    color: #ffb86c;
}

#temperature.critical {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.5), rgba(255, 0, 0, 0.3));
    color: #ff5555;
    animation: blink 0.5s infinite;
}

#network {
    background: linear-gradient(135deg, rgba(139, 233, 253, 0.3), rgba(0, 191, 255, 0.2));
    color: #8be9fd;
}

#network.disconnected {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.4), rgba(255, 20, 20, 0.2));
    color: #ff5555;
}

#pulseaudio {
    background: linear-gradient(135deg, rgba(189, 147, 249, 0.3), rgba(138, 43, 226, 0.2));
    color: #bd93f9;
}

#pulseaudio.muted {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.4), rgba(255, 20, 20, 0.2));
    color: #ff5555;
}

#idle_inhibitor {
    background: linear-gradient(135deg, rgba(255, 255, 255, 0.2), rgba(200, 200, 200, 0.1));
    color: #f8f8f2;
}

#idle_inhibitor.activated {
    background: linear-gradient(135deg, rgba(255, 215, 0, 0.4), rgba(255, 193, 7, 0.2));
    color: #ffd700;
    box-shadow: 0 0 15px rgba(255, 215, 0, 0.3);
}

#tray {
    background: rgba(68, 71, 90, 0.4);
    border: 1px solid rgba(255, 255, 255, 0.1);
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: rgba(255, 85, 85, 0.3);
}

#custom-power {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.4), rgba(220, 20, 60, 0.3));
    color: #ff5555;
    font-size: 18px;
    font-weight: bold;
    transition: all 0.3s ease;
}

#custom-power:hover {
    background: linear-gradient(135deg, rgba(255, 85, 85, 0.6), rgba(255, 0, 0, 0.4));
    transform: scale(1.1);
    box-shadow: 0 0 20px rgba(255, 85, 85, 0.5);
}

/* Effets de hover généraux */
#battery:hover,
#cpu:hover,
#memory:hover,
#temperature:hover,
#network:hover,
#pulseaudio:hover,
#idle_inhibitor:hover,
#clock:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.3);
}

/* Tooltip styling */
tooltip {
    background: rgba(15, 15, 35, 0.95);
    border: 1px solid rgba(51, 204, 255, 0.5);
    border-radius: 10px;
    color: #ffffff;
    font-family: 'Fira Code', monospace;
}

tooltip label {
    color: #ffffff;
}
EOF

    print_success "Configuration Waybar créée"
}

# 7. Configuration Hyprlock
configure_hyprlock() {
    print_header "Configuration de Hyprlock"
    
    cat > ~/.config/hypr/hyprlock.conf << 'EOF'

# Configuration Hyprlock - Thème Fallout Terminal Amélioré


general {
    disable_loading_bar = true
    grace = 2
    hide_cursor = true
    no_fade_in = false
    no_fade_out = false
    ignore_empty_input = false
    immediate_render = false
}

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 8
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
}

# Animation de scanlines style CRT
background {
    monitor =
    path = ~/.config/hypr/scanlines.png
    blur_passes = 0
    blur_size = 0
    noise = 0.0
    contrast = 1.0
    brightness = 0.1
    vibrancy = 0.0
    vibrancy_darkness = 0.0
}

# Horloge principale avec effet glow
label {
    monitor =
    text = cmd[update:1000] echo "<span font='Fira Code' weight='bold' size='xx-large' foreground='#00ff99'> $(date +"%H:%M:%S") </span>"
    color = rgba(0, 255, 153, 1.0)
    font_size = 72
    font_family = Fira Code
    position = -100, 100
    halign = right
    valign = bottom
    shadow_passes = 3
    shadow_size = 8
    shadow_color = rgba(0, 255, 153, 0.8)
    shadow_boost = 2.0
}

# Date avec style terminal
label {
    monitor =
    text = cmd[update:18000000] echo "<span font='Fira Code' weight='normal' size='large' foreground='#ffffff'> $(date +'%A, %-d %B %Y') </span>"
    color = rgba(255, 255, 255, 0.9)
    font_size = 28
    font_family = Fira Code
    position = -100, 40
    halign = right
    valign = bottom
    shadow_passes = 2
    shadow_size = 4
    shadow_color = rgba(0, 0, 0, 0.8)
}

# Header style Vault-Tec
label {
    monitor =
    text = <span font='Fira Code' weight='bold' size='x-large' foreground='#33ccff'>VAULT-TEC SECURITY TERMINAL</span>
    color = rgba(51, 204, 255, 0.9)
    font_size = 24
    font_family = Fira Code
    position = 0, 250
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 6
    shadow_color = rgba(51, 204, 255, 0.5)
}

# Status line
label {
    monitor =
    text = <span font='Fira Code' weight='normal' size='medium' foreground='#ffff00'>STATUS: LOCKED | CLEARANCE: REQUIRED</span>
    color = rgba(255, 255, 0, 0.8)
    font_size = 16
    font_family = Fira Code
    position = 0, 210
    halign = center
    valign = center
}

# Prompt
label {
    monitor =
    text = <span font='Fira Code' weight='normal' size='medium' foreground='#ffffff'>&gt; Please enter your security credentials</span>
    color = rgba(255, 255, 255, 0.7)
    font_size = 18
    font_family = Fira Code
    position = 0, 150
    halign = center
    valign = center
}

# Champ de saisie du mot de passe amélioré
input-field {
    monitor =
    size = 400, 60
    position = 0, 80
    halign = center
    valign = center
    rounding = 12
    border_size = 3
    border_color = rgba(51, 204, 255, 0.8)
    inner_color = rgba(0, 0, 0, 0.9)
    font_color = rgba(0, 255, 153, 1.0)
    fade_on_empty = false
    fade_timeout = 2000
    placeholder_text = <span font='Fira Code' style='italic' size='medium' foreground='#666666'>Enter Password...</span>
    hide_input = false
    dots_size = 0.25
    dots_spacing = 0.2
    dots_center = true
    dots_rounding = -1
    outer_color = rgba(0, 0, 0, 0)
    font_family = Fira Code
    check_color = rgba(204, 136, 34, 0)
    fail_color = rgba(204, 34, 34, 0)
    fail_text = <span font='Fira Code' weight='bold' foreground='#ff5555'>ACCESS DENIED</span>
    fail_timeout = 2000
    fail_transitions = 300
    capslock_color = rgba(255, 255, 0, 0.5)
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false

    shadow_passes = 2
    shadow_size = 4
    shadow_color = rgba(51, 204, 255, 0.3)
    shadow_boost = 1.5
}

# Indicateur Caps Lock amélioré
label {
    monitor =
    text = cmd[update:1000] if [ "$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | grep -c 1)" -gt 0 ]; then echo "<span font='Fira Code' weight='bold' size='small' foreground='#ff5555'>⚠ CAPS LOCK ACTIVE ⚠</span>"; else echo ""; fi
    color = rgba(255, 85, 85, 1.0)
    font_size = 14
    font_family = Fira Code
    position = 0, 30
    halign = center
    valign = center
    shadow_passes = 2
    shadow_size = 4
    shadow_color = rgba(255, 85, 85, 0.5)
}

# Info utilisateur avec style terminal
label {
    monitor =
    text = cmd[update:60000] echo "<span font='Fira Code' weight='normal' size='medium' foreground='#8be9fd'>USER: $(whoami) | HOST: $(hostname)</span>"
    color = rgba(139, 233, 253, 0.9)
    font_size = 16
    font_family = Fira Code
    position = 0, -80
    halign = center
    valign = center
}

# Footer avec instructions
label {
    monitor =
    text = <span font='Fira Code' weight='normal' size='small' foreground='#666666'>Press ESC to cancel | Enter to authenticate</span>
    color = rgba(102, 102, 102, 0.8)
    font_size = 12
    font_family = Fira Code
    position = 0, -120
    halign = center
    valign = center
}

# Decoration corner elements
label {
    monitor =
    text =
    color = rgba(51, 204, 255, 0.3)
    font_size = 20
    font_family = Fira Code
    position = 50, 50
    halign = left
    valign = top
}

label {
    monitor =
    text =
    color = rgba(51, 204, 255, 0.3)
    font_size = 20
    font_family = Fira Code
    position = -50, 50
    halign = right
    valign = top
}

label {
    monitor =
    text =
    color = rgba(51, 204, 255, 0.3)
    font_size = 20
    font_family = Fira Code
    position = 50, -50
    halign = left
    valign = bottom
}

label {
    monitor =
    text =
    color = rgba(51, 204, 255, 0.3)
    font_size = 20
    font_family = Fira Code
    position = -50, -50
    halign = right
    valign = bottom
}
EOF

    print_success "Configuration Hyprlock créée"
}

# 8. Configuration Hypridle
configure_hypridle() {
    print_header "Configuration de Hypridle"
    
    cat > ~/.config/hypr/hypridle.conf << 'EOF'

# Configuration Hypridle - Gestion intelligente de l'inactivité


general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
}

# Réduction de la luminosité après 5 minutes
listener {
    timeout = 300
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

# Notification avant verrouillage
listener {
    timeout = 540
    on-timeout = notify-send "Système" "Verrouillage dans 60 secondes" -t 5000
}

# Verrouillage après 10 minutes
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

# Arrêt de l'écran après 15 minutes
listener {
    timeout = 900
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

# Suspension après 30 minutes (seulement sur batterie)
listener {
    timeout = 1800
    on-timeout = if [ "$(cat /sys/class/power_supply/A*/online 2>/dev/null | grep -c 0)" -gt 0 ]; then systemctl suspend; fi
}
EOF

    print_success "Configuration Hypridle créée"
}

# 9. Configuration Kitty
configure_kitty() {
    print_header "Configuration de Kitty"
    
    cat > ~/.config/kitty/kitty.conf << 'EOF'

# Configuration Kitty - Thème Arcane/Fallout Premium


# Police et rendu
font_family      Fira Code
bold_font        Fira Code Bold
italic_font      Fira Code Italic
bold_italic_font Fira Code Bold Italic
font_size        13.0
font_features    FiraCode-Regular +cv02 +cv05 +cv09 +cv14 +ss04 +cv16 +cv31 +cv25 +cv26 +cv32 +cv28 +ss10 +zero +onum

# Ajustements de rendu
disable_ligatures never
text_composition_strategy platform
box_drawing_scale 0.001, 1, 1.5, 2

# Transparence et effets visuels
background_opacity 0.92
dynamic_background_opacity yes
dim_opacity 0.75

# Curseur
cursor_shape block
cursor_beam_thickness 1.5
cursor_underline_thickness 2.0
cursor_blink_interval -1
cursor_stop_blinking_after 15.0

# Scrollback
scrollback_lines 10000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
scrollback_pager_history_size 0
scrollback_fill_enlarged_window no
wheel_scroll_multiplier 5.0
wheel_scroll_min_lines 1
touch_scroll_multiplier 1.0

# Souris
mouse_hide_wait 3.0
url_color #33ccff
url_style curly
open_url_with default
url_prefixes file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh
detect_urls yes
copy_on_select no
paste_actions quote-urls-at-prompt
strip_trailing_spaces never
select_by_word_characters @-./_~?&=%+#
click_interval -1.0
focus_follows_mouse no
pointer_shape_when_grabbed arrow
default_pointer_shape beam
pointer_shape_when_dragging beam

# Performance et rendu
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Audio
enable_audio_bell no
visual_bell_duration 0.0
visual_bell_color none
window_alert_on_bell yes
bell_on_tab "🔔"
command_on_bell none
bell_path none

# Fenêtre
remember_window_size yes
initial_window_width 1200
initial_window_height 800
enabled_layouts *
window_resize_step_cells 2
window_resize_step_lines 2
window_border_width 0.5pt
draw_minimal_borders yes
window_margin_width 8
single_window_margin_width -1
window_padding_width 12
placement_strategy center
active_border_color #33ccff
inactive_border_color #595959
bell_border_color #ff5555
inactive_text_alpha 1.0
hide_window_decorations yes
window_logo_path none
window_logo_position bottom-right
window_logo_alpha 0.5
resize_debounce_time 0.1
resize_draw_strategy static
resize_in_steps no
visual_window_select_characters 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ
confirm_os_window_close -1

# Onglets
tab_bar_edge bottom
tab_bar_margin_width 0.0
tab_bar_margin_height 0.0 0.0
tab_bar_style powerline
tab_bar_align left
tab_bar_min_tabs 2
tab_switch_strategy previous
tab_fade 0.25 0.5 0.75 1
tab_separator " ┇"
tab_powerline_style angled
tab_activity_symbol none
tab_title_template "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}"
active_tab_title_template none
active_tab_foreground   #000
active_tab_background   #33ccff
active_tab_font_style   bold-italic
inactive_tab_foreground #f8f8f2
inactive_tab_background #44475a
inactive_tab_font_style normal
tab_bar_background      #0f0f23
tab_bar_margin_color    none

# Couleurs - Thème Arcane/Fallout personnalisé
foreground            #f8f8f2
background            #0f0f23
selection_foreground  #000000
selection_background  #44475a
cursor                #33ccff
cursor_text_color     #0f0f23

# URL underlined
url_color #33ccff

# Border colors
active_border_color     #33ccff
inactive_border_color   #595959
bell_border_color       #ff5555

# OS Window titlebar colors
wayland_titlebar_color  #0f0f23

# Tab bar colors
active_tab_foreground   #000000
active_tab_background   #33ccff
inactive_tab_foreground #f8f8f2
inactive_tab_background #44475a
tab_bar_background      #0f0f23

# Colors for marks (marked text in the terminal)
mark1_foreground #0f0f23
mark1_background #bd93f9
mark2_foreground #0f0f23
mark2_background #f1fa8c
mark3_foreground #0f0f23
mark3_background #50fa7b

# The 16 terminal colors

# normal
color0 #21222c
color1 #ff5555
color2 #50fa7b
color3 #f1fa8c
color4 #bd93f9
color5 #ff79c6
color6 #8be9fd
color7 #f8f8f2

# bright
color8  #6272a4
color9  #ff6e6e
color10 #69ff94
color11 #ffffa5
color12 #d6acff
color13 #ff92df
color14 #a4ffff
color15 #ffffff

# Extended colors
color16 #ffb86c
color17 #ff5555

# Raccourcis clavier personnalisés
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+shift+s paste_from_selection
map shift+insert paste_from_selection
map ctrl+shift+o pass_selection_to_program

# Gestion des fenêtres et onglets
map ctrl+shift+enter new_window
map ctrl+shift+n new_os_window
map ctrl+shift+w close_window
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window
map ctrl+shift+f move_window_forward
map ctrl+shift+b move_window_backward
map ctrl+shift+` move_window_to_top
map ctrl+shift+r start_resizing_window
map ctrl+shift+1 first_window
map ctrl+shift+2 second_window
map ctrl+shift+3 third_window
map ctrl+shift+4 fourth_window
map ctrl+shift+5 fifth_window
map ctrl+shift+6 sixth_window
map ctrl+shift+7 seventh_window
map ctrl+shift+8 eighth_window
map ctrl+shift+9 ninth_window
map ctrl+shift+0 tenth_window

# Gestion des onglets
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
map ctrl+shift+t new_tab
map ctrl+shift+q close_tab
map ctrl+shift+. move_tab_forward
map ctrl+shift+, move_tab_backward
map ctrl+shift+alt+t set_tab_title

# Mise en page
map ctrl+shift+l next_layout

# Contrôle de la police
map ctrl+shift+equal change_font_size all +2.0
map ctrl+shift+plus change_font_size all +2.0
map ctrl+shift+kp_add change_font_size all +2.0
map ctrl+shift+minus change_font_size all -2.0
map ctrl+shift+kp_subtract change_font_size all -2.0
map ctrl+shift+backspace change_font_size all 0

# Sélection
map ctrl+shift+a select_all
map ctrl+shift+x clear_selection

# Scrollback
map ctrl+shift+h show_scrollback
map ctrl+shift+g show_last_command_output

# Divers
map ctrl+shift+f11 toggle_fullscreen
map ctrl+shift+f10 toggle_maximized
map ctrl+shift+u kitten unicode_input
map ctrl+shift+f2 edit_config_file
map ctrl+shift+escape kitty_shell window

# Zoom
map ctrl+shift+kp_home scroll_home
map ctrl+shift+kp_end scroll_end
map ctrl+shift+up scroll_line_up
map ctrl+shift+k scroll_line_up
map ctrl+shift+down scroll_line_down
map ctrl+shift+j scroll_line_down
map ctrl+shift+page_up scroll_page_up
map ctrl+shift+page_down scroll_page_down
map ctrl+shift+home scroll_home
map ctrl+shift+end scroll_end
map ctrl+alt+up move_window up
map ctrl+alt+left move_window left
map ctrl+alt+right move_window right
map ctrl+alt+down move_window down

# Kittens
map f1 launch --location=hsplit --allow-remote-control kitty +kitten panel
EOF

    print_success "Configuration Kitty créée"
}

# 10. Configuration Wofi
configure_wofi() {
    print_header "Configuration de Wofi"
    
    mkdir -p ~/.config/wofi
    
    cat > ~/.config/wofi/config << 'EOF'

# Configuration Wofi - Menu d'applications style Fallout


width=700
height=500
location=center
show=drun
prompt=APPLICATIONS
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=48
gtk_dark=true
layer=overlay
term=kitty
hide_scroll=true
matching=fuzzy
sort_order=alphabetical
columns=1
dynamic_lines=false
cache_file=/dev/null
parse_search=false
exec_search=false
EOF

    cat > ~/.config/wofi/style.css << 'EOF'

* {
    all: unset;
    font-family: 'Fira Code', monospace;
    font-size: 14px;
    transition: all 0.3s ease;
}

window {
    margin: 0px;
    border: 3px solid #33ccff;
    background: linear-gradient(135deg, rgba(15, 15, 35, 0.98), rgba(25, 25, 45, 0.95));
    border-radius: 20px;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.7), 
                inset 0 1px 0 rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(20px);
}

#input {
    all: unset;
    margin: 15px;
    padding: 15px 20px;
    border: 2px solid #33ccff;
    color: #00ff99;
    background: rgba(0, 0, 0, 0.7);
    border-radius: 12px;
    font-family: 'Fira Code', monospace;
    font-size: 16px;
    font-weight: bold;
    box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.5),
                0 0 20px rgba(51, 204, 255, 0.3);
}

#input:focus {
    border-color: #00ff99;
    box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.5),
                0 0 30px rgba(0, 255, 153, 0.5);
}

#input::placeholder {
    color: rgba(255, 255, 255, 0.5);
}

#inner-box {
    margin: 10px;
    border: none;
    background: transparent;
}

#outer-box {
    margin: 0px;
    border: none;
    background: transparent;
}

#scroll {
    margin: 0px;
    border: none;
    background: transparent;
}

#text {
    margin: 8px 12px;
    border: none;
    color: #f8f8f2;
    font-family: 'Fira Code', monospace;
    font-size: 14px;
    font-weight: 500;
}

#entry {
    border-radius: 12px;
    margin: 4px 8px;
    padding: 8px 12px;
    background: transparent;
    border: 1px solid transparent;
    transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

#entry:selected {
    background: linear-gradient(135deg, 
                rgba(51, 204, 255, 0.25), 
                rgba(0, 255, 153, 0.15));
    border: 1px solid rgba(51, 204, 255, 0.6);
    box-shadow: 0 4px 15px rgba(51, 204, 255, 0.3),
                inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

#entry:selected #text {
    color: #33ccff;
    font-weight: bold;
    text-shadow: 0 0 10px rgba(51, 204, 255, 0.5);
}

#entry:hover {
    background: rgba(51, 204, 255, 0.1);
}

#entry image {
    margin-right: 12px;
    border-radius: 8px;
}

/* Style pour les séparateurs si présents */
separator {
    background-color: rgba(51, 204, 255, 0.3);
    margin: 5px 20px;
    min-height: 1px;
}

/* Animation d'entrée */
@keyframes fadeIn {
    from {
        opacity: 0;
        transform: translateY(-20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

window {
    animation: fadeIn 0.3s ease-out;
}

/* Scrollbar personnalisée */
scrollbar {
    width: 6px;
    background: rgba(0, 0, 0, 0.3);
    border-radius: 3px;
}

scrollbar slider {
    background: rgba(51, 204, 255, 0.6);
    border-radius: 3px;
    border: none;
}

scrollbar slider:hover {
    background: rgba(51, 204, 255, 0.8);
}
EOF

    print_success "Configuration Wofi créée"
}

# 11. Configuration Dunst
configure_dunst() {
    print_header "Configuration de Dunst"
    
    cat > ~/.config/dunst/dunstrc << 'EOF'

# Configuration Dunst - Notifications Thème Arcane/Fallout


[global]
    ### Display ###
    monitor = 0
    follow = none
    
    ### Geometry ###
    width = 350
    height = 300
    origin = top-right
    offset = 15x50
    scale = 0
    notification_limit = 5
    
    ### Progress bar ###
    progress_bar = true
    progress_bar_height = 12
    progress_bar_frame_width = 2
    progress_bar_min_width = 150
    progress_bar_max_width = 300
    progress_bar_corner_radius = 6
    
    ### Appearance ###
    indicate_hidden = yes
    transparency = 5
    separator_height = 3
    padding = 12
    horizontal_padding = 15
    text_icon_padding = 15
    frame_width = 3
    frame_color = "#33ccff"
    gap_size = 8
    separator_color = auto
    sort = yes
    idle_threshold = 120
    
    ### Text ###
    font = Fira Code 12
    line_height = 2
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
    
    ### Icons ###
    enable_recursive_icon_lookup = true
    icon_theme = Papirus-Dark
    icon_position = left
    min_icon_size = 24
    max_icon_size = 48
    icon_path = /usr/share/icons/Papirus-Dark/16x16/status/:/usr/share/icons/Papirus-Dark/16x16/devices/:/usr/share/icons/Papirus-Dark/16x16/apps/
    
    ### History ###
    sticky_history = yes
    history_length = 50
    
    ### Misc/Advanced ###
    dmenu = /usr/bin/wofi --show dmenu
    browser = /usr/bin/google-chrome-stable
    always_run_script = true
    title = Dunst
    class = Dunst
    corner_radius = 15
    ignore_dbusclose = false
    
    ### Wayland ###
    force_xwayland = false
    
    ### Mouse ###
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[experimental]
    per_monitor_dpi = false

[urgency_low]
    background = "#0f0f23e6"
    foreground = "#f8f8f2"
    highlight = "#33ccff"
    frame_color = "#33ccff"
    timeout = 8
    # Icon for low urgency notifications
    default_icon = /usr/share/icons/Papirus-Dark/16x16/status/dialog-information.svg

[urgency_normal]
    background = "#0f0f23e6"
    foreground = "#f8f8f2"
    highlight = "#00ff99"
    frame_color = "#00ff99"
    timeout = 10
    override_pause_level = 30
    default_icon = /usr/share/icons/Papirus-Dark/16x16/status/dialog-information.svg

[urgency_critical]
    background = "#0f0f23e6"
    foreground = "#ffffff"
    highlight = "#ff5555"
    frame_color = "#ff5555"
    timeout = 0
    override_pause_level = 60
    default_icon = /usr/share/icons/Papirus-Dark/16x16/status/dialog-error.svg

# Application specific rules
[spotify]
    appname = Spotify
    background = "#1db954e6"
    foreground = "#ffffff"
    frame_color = "#1db954"
    timeout = 5

[discord]
    appname = Discord
    background = "#5865f2e6"
    foreground = "#ffffff"
    frame_color = "#5865f2"
    timeout = 8

[chrome]
    appname = "Google Chrome"
    background = "#4285f4e6"
    foreground = "#ffffff"
    frame_color = "#4285f4"
    timeout = 6

[volume]
    summary = "*olume*"
    background = "#bd93f9e6"
    foreground = "#ffffff"
    frame_color = "#bd93f9"
    timeout = 2
    hide_text = true

[brightness]
    summary = "*rightness*"
    background = "#f1fa8ce6"
    foreground = "#000000"
    frame_color = "#f1fa8c"
    timeout = 2
    hide_text = true

[battery]
    summary = "*attery*"
    background = "#50fa7be6"
    foreground = "#000000"
    frame_color = "#50fa7b"
    timeout = 15

[network]
    summary = "*etwork*"
    appname = "NetworkManager"
    background = "#8be9fde6"
    foreground = "#000000"
    frame_color = "#8be9fd"
    timeout = 8

[screenshot]
    summary = "*apture*"
    background = "#ff79c6e6"
    foreground = "#ffffff"
    frame_color = "#ff79c6"
    timeout = 3
EOF

    print_success "Configuration Dunst créée"
}

# 13. Configuration Fastfetch
configure_fastfetch() {
    print_header "Configuration de Fastfetch"
    
    cat > ~/.config/fastfetch/config.jsonc << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "padding": {
            "top": 2,
            "left": 3,
            "right": 4
        },
        "color": {
            "1": "cyan",
            "2": "blue"
        }
    },
    "display": {
        "separator": " ➜ ",
        "color": {
            "keys": "cyan",
            "title": "blue",
            "separator": "green"
        },
        "brightColor": false,
        "binaryPrefix": "iec"
    },
    "modules": [
        {
            "type": "title",
            "color": {
                "user": "green",
                "at": "white",
                "host": "yellow"
            }
        },
        {
            "type": "separator",
            "string": "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        },
        {
            "type": "os",
            "key": " OS",
            "keyColor": "blue"
        },
        {
            "type": "host",
            "key": "󰌢 Host",
            "keyColor": "green"
        },
        {
            "type": "kernel",
            "key": " Kernel",
            "keyColor": "yellow"
        },
        {
            "type": "uptime",
            "key": " Uptime",
            "keyColor": "magenta"
        },
        {
            "type": "packages",
            "key": "󰏖 Packages",
            "keyColor": "cyan"
        },
        {
            "type": "shell",
            "key": " Shell",
            "keyColor": "blue"
        },
        {
            "type": "display",
            "key": "󰍹 Resolution",
            "keyColor": "red",
            "compactType": "original"
        },
        {
            "type": "de",
            "key": " DE",
            "keyColor": "green"
        },
        {
            "type": "wm",
            "key": " WM",
            "keyColor": "blue"
        },
        {
            "type": "wmtheme",
            "key": "󰉼 WM Theme",
            "keyColor": "yellow"
        },
        {
            "type": "theme",
            "key": " Theme",
            "keyColor": "magenta"
        },
        {
            "type": "icons",
            "key": " Icons",
            "keyColor": "cyan"
        },
        {
            "type": "font",
            "key": " Font",
            "keyColor": "red"
        },
        {
            "type": "cursor",
            "key": " Cursor",
            "keyColor": "green"
        },
        {
            "type": "terminal",
            "key": " Terminal",
            "keyColor": "blue"
        },
        {
            "type": "terminalfont",
            "key": " Term Font",
            "keyColor": "yellow"
        },
        {
            "type": "cpu",
            "key": " CPU",
            "keyColor": "red",
            "temp": true
        },
        {
            "type": "gpu",
            "key": "󰢮 GPU",
            "keyColor": "green",
            "temp": true
        },
        {
            "type": "memory",
            "key": " Memory",
            "keyColor": "blue"
        },
        {
            "type": "swap",
            "key": "󰓡 Swap",
            "keyColor": "cyan"
        },
        {
            "type": "disk",
            "key": "󰋊 Disk (/)",
            "keyColor": "yellow",
            "folders": ["/"]
        },
        {
            "type": "localip",
            "key": "󰩟 Local IP",
            "keyColor": "magenta",
            "compact": true
        },
        {
            "type": "battery",
            "key": " Battery",
            "keyColor": "green"
        },
        {
            "type": "poweradapter",
            "key": "󰚥 Power",
            "keyColor": "red"
        },
        {
            "type": "locale",
            "key": " Locale",
            "keyColor": "blue"
        },
        {
            "type": "break"
        },
        {
            "type": "colors",
            "paddingLeft": 2,
            "symbol": "circle"
        }
    ]
}
EOF

    print_success "Fastfetch configuré"
}

# 14. Configuration SDDM
configure_sddm() {
    print_header "Configuration de SDDM"
    
    # Désactiver les anciens display managers
    sudo systemctl disable gdm lightdm lxdm xdm 2>/dev/null || true
    
    sudo mkdir -p /etc/sddm.conf.d
    
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null << 'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=Hyprland
SessionDir=/usr/share/wayland-sessions

[Theme]
Current=breeze
CursorTheme=Adwaita
Font=Noto Sans,11,-1,0,50,0,0,0,0,0,Regular

[Users]
MaximumUid=60513
MinimumUid=1000
HideUsers=
HideShells=/bin/false,/usr/bin/nologin
RememberLastUser=true
RememberLastSession=true

[Autologin]
Relogin=false
Session=
User=
EOF

    # Activation du service SDDM
    sudo systemctl enable sddm
    sudo systemctl set-default graphical.target
    
    print_success "SDDM configuré et activé"
}

# 15. Configuration des services système
configure_services() {
    print_header "Configuration des services système et utilisateur"

    # Services système à activer
    SYSTEM_SERVICES=(
        "NetworkManager"
        "bluetooth"
        "docker"
    )

    for svc in "${SYSTEM_SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^${svc}\.service"; then
            sudo systemctl enable "${svc}.service"
            print_success "Service système ${svc} activé"
        else
            print_warning "Service système ${svc} non trouvé"
        fi
    done

    # Services utilisateur PipeWire
    USER_SERVICES=(
        "pipewire.service"
        "pipewire.socket"
        "pipewire-pulse.socket"
        "wireplumber.service"
    )

    for svc in "${USER_SERVICES[@]}"; do
        if systemctl --user list-unit-files | grep -q "^${svc}"; then
            systemctl --user enable "${svc}" 2>/dev/null || true
            print_success "Service utilisateur ${svc} activé"
        else
            print_warning "Service utilisateur ${svc} non trouvé"
        fi
    done

    print_success "Configuration des services terminée"
}

# 16. Installation des thèmes GTK
install_gtk_themes() {
    print_header "Installation des thèmes GTK"
    
    sudo pacman -S --noconfirm --needed \
        gtk3 gtk4 \
        papirus-icon-theme \
        qt5ct qt6ct \
        adwaita-qt5 adwaita-qt6 \
        kvantum
    
    # Configuration GTK3
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

    # Configuration GTK4
    mkdir -p ~/.config/gtk-4.0
    cat > ~/.config/gtk-4.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

    # Configuration Qt5ct
    mkdir -p ~/.config/qt5ct
    cat > ~/.config/qt5ct/qt5ct.conf << 'EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/airy.conf
custom_palette=false
icon_theme=Papirus-Dark
standard_dialogs=default
style=Fusion

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x16\0\x46\0i\0r\0\x61\0 \0\x43\0o\0\x64\0\x65@$\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)
general=@Variant(\0\0\0@\0\0\0\x12\0N\0o\0t\0o\0 \0S\0\x61\0n\0s@\"\0\0\0\0\0\0\xff\xff\xff\xff\x5\x1\0\x32\x10)

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x2\x80\0\0\x1\x90\0\0\x5\x7f\0\0\x4\x37\0\0\x2\x80\0\0\x1\xac\0\0\x5\x7f\0\0\x4\x37\0\0\0\0\0\0\0\0\a\x80\0\0\x2\x80\0\0\x1\xac\0\0\x5\x7f\0\0\x4\x37)

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
EOF

    print_success "Thèmes GTK configurés"
}

# 17. Création de scripts utilitaires
create_utilities() {
    print_header "Création de scripts utilitaires"
    
    mkdir -p ~/.local/bin
    
    # Script de changement de wallpaper
    cat > ~/.local/bin/change-wallpaper << 'EOF'
#!/bin/bash
# Script pour changer le fond d'écran vidéo

WALLPAPER_DIR="$HOME/Videos/Wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Dossier $WALLPAPER_DIR non trouvé"
    notify-send "Erreur" "Dossier wallpapers non trouvé"
    exit 1
fi

# Arrêter l'ancien mpvpaper
pkill -f mpvpaper

# Sélectionner une nouvelle vidéo
VIDEO_FILES=()
while IFS= read -r -d '' file; do
    VIDEO_FILES+=("$file")
done < <(find "$WALLPAPER_DIR" -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.webm" -print0 2>/dev/null)

if [ ${#VIDEO_FILES[@]} -eq 0 ]; then
    echo "Aucune vidéo trouvée dans $WALLPAPER_DIR"
    notify-send "Info" "Aucune vidéo trouvée"
    exit 1
fi

# Démarrer le nouveau wallpaper
RANDOM_VIDEO=${VIDEO_FILES[$RANDOM % ${#VIDEO_FILES[@]}]}
echo "Nouveau wallpaper: $(basename "$RANDOM_VIDEO")"
notify-send "Wallpaper" "$(basename "$RANDOM_VIDEO")"

# Options optimisées selon le GPU
if command -v nvidia-smi >/dev/null 2>&1; then
    mpvpaper -o "loop-file=inf --volume=0 --hwdec=nvdec --vo=gpu --gpu-api=vulkan" '*' "$RANDOM_VIDEO" &
else
    mpvpaper -o "loop-file=inf --volume=0 --hwdec=vaapi --vo=gpu" '*' "$RANDOM_VIDEO" &
fi
EOF

    # Script de capture d'écran avancée
    cat > ~/.local/bin/screenshot-menu << 'EOF'
#!/bin/bash
# Menu de capture d'écran avec wofi

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

OPTIONS="Écran complet\n Zone sélectionnée\n Fenêtre active\n Retardée (3s)\n Vers presse-papier\n Enregistrement écran"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Capture d'écran" --width 300 --height 250)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

case "$CHOICE" in
    "Écran complet")
        grim "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        notify-send "Capture d'écran" "Écran complet sauvegardé" -i "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Zone sélectionnée")
        grim -g "$(slurp)" "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        notify-send "Capture d'écran" "Zone sélectionnée sauvegardée" -i "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Fenêtre active")
        WINDOW=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$WINDOW" "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        notify-send "Capture d'écran" "Fenêtre active sauvegardée" -i "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Retardée (3s)")
        notify-send "Capture d'écran" "Capture dans 3 secondes..." -t 3000
        sleep 3
        grim "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        notify-send "Capture d'écran" "Capture retardée sauvegardée" -i "$SCREENSHOT_DIR/screenshot-$TIMESTAMP.png"
        ;;
    "Vers presse-papier")
        grim -g "$(slurp)" - | wl-copy
        notify-send "Capture d'écran" "Copiée vers le presse-papier"
        ;;
    "Enregistrement écran")
        ~/.local/bin/screen-record
        ;;
esac
EOF

    # Script d'enregistrement d'écran
    cat > ~/.local/bin/screen-record << 'EOF'
#!/bin/bash
# Script d'enregistrement d'écran avec wf-recorder

RECORD_DIR="$HOME/Videos/Recordings"
mkdir -p "$RECORD_DIR"

PID_FILE="/tmp/screen-record.pid"

if [ -f "$PID_FILE" ]; then
    # Arrêter l'enregistrement en cours
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null
    rm -f "$PID_FILE"
    notify-send "Enregistrement" "Enregistrement arrêté"
else
    # Démarrer l'enregistrement
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$RECORD_DIR/recording-$TIMESTAMP.mp4"
    
    # Choix de la zone
    CHOICE=$(echo -e "Écran complet\nZone sélectionnée" | wofi --dmenu --prompt "Enregistrer")
    
    case "$CHOICE" in
        "Écran complet")
            wf-recorder -f "$OUTPUT_FILE" &
            ;;
        "Zone sélectionnée")
            wf-recorder -g "$(slurp)" -f "$OUTPUT_FILE" &
            ;;
        *)
            exit 0
            ;;
    esac
    
    echo $! > "$PID_FILE"
    notify-send "Enregistrement" "Enregistrement démarré\nCliquez sur l'icône pour arrêter"
fi
EOF

    # Script de gestion de l'énergie
    cat > ~/.local/bin/power-menu << 'EOF'
#!/bin/bash
# Menu de gestion de l'énergie

OPTIONS=" Verrouiller\n Déconnexion\n Redémarrer\n⏻ Éteindre\n Suspension\n Hibernation"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "⚡ Gestion de l'énergie" --width 250 --height 300)

case "$CHOICE" in
    " Verrouiller")
        hyprlock
        ;;
    " Déconnexion")
        hyprctl dispatch exit
        ;;
    " Redémarrer")
        systemctl reboot
        ;;
    "⏻ Éteindre")
        systemctl poweroff
        ;;
    " Suspension")
        systemctl suspend
        ;;
    " Hibernation")
        systemctl hibernate
        ;;
esac
EOF

    # Script toggle transparence
    cat > ~/.local/bin/toggle-transparency << 'EOF'
#!/bin/bash
# Toggle transparence des fenêtres

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
TEMP_FILE="/tmp/hyprland_transparency_state"

if [ -f "$TEMP_FILE" ]; then
    # Restaurer la transparence
    sed -i 's/opacity 1\.0 override 1\.0 override/opacity 0.95 0.95/g' "$CONFIG_FILE"
    sed -i 's/opacity 1\.0 1\.0/opacity 0.92 0.92/g' "$CONFIG_FILE"
    rm "$TEMP_FILE"
    notify-send "👁️ Transparence" "Transparence activée"
else
    # Désactiver la transparence
    sed -i 's/opacity [0-9.]\+ [0-9.]\+/opacity 1.0 1.0/g' "$CONFIG_FILE"
    touch "$TEMP_FILE"
    notify-send "👁️ Transparence" "Transparence désactivée"
fi

# Recharger Hyprland
hyprctl reload
EOF

    # Script de monitoring système avec GUI
    cat > ~/.local/bin/system-monitor << 'EOF'
#!/bin/bash
# Moniteur système dans terminal avec style

    MONITOR_SCRIPT=$(cat << 'SCRIPT'
#!/bin/bash
while true; do
    clear
    
    # CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    echo -e "\033[36m║\033[0m \033[1;31m  CPU:\033[0m ${CPU_USAGE}%"
    
    # RAM Usage
    RAM_INFO=$(free -h | awk '/^Mem:/ {printf "%.1f/%.1f GB (%.0f%%)", $3, $2, ($3/$2)*100}')
    echo -e "\033[36m║\033[0m \033[1;34m RAM:\033[0m $RAM_INFO"
    
    # GPU Info (NVIDIA)
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits | head -1)
        if [ ! -z "$GPU_INFO" ]; then
            echo -e "\033[36m║\033[0m \033[1;32m GPU:\033[0m $GPU_INFO"
        fi
    fi
    
    # Temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
        echo -e "\033[36m║\033[0m \033[1;35m  CPU Temp:\033[0m $TEMP"
    fi
    
    # Disk Usage
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')
    echo -e "\033[36m║\033[0m \033[1;36m Disk (/):\033[0m $DISK_USAGE"
    
    # Network
    NETWORK=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    if [ ! -z "$NETWORK" ]; then
        echo -e "\033[36m║\033[0m \033[1;33m IP:\033[0m $NETWORK"
    fi
    
    # Uptime
    UPTIME=$(uptime -p | sed 's/up //')
    echo -e "\033[36m║\033[0m \033[1;37m Uptime:\033[0m $UPTIME"
    
    echo -e "\033[36m║\033[0m"
    echo -e "\033[36m╚══════════════════════════════════════════╝\033[0m"
    echo -e "\033[90mPress Ctrl+C to exit\033[0m"
    sleep 2
done
SCRIPT
)

kitty --title "System Monitor" -e bash -c "$MONITOR_SCRIPT"
EOF

    # Script de gestion des workspaces
    cat > ~/.local/bin/workspace-manager << 'EOF'
#!/bin/bash
# Gestionnaire de workspaces intelligent

case "$1" in
    "next")
        hyprctl dispatch workspace +1
        ;;
    "prev")
        hyprctl dispatch workspace -1
        ;;
    "move-next")
        hyprctl dispatch movetoworkspace +1
        ;;
    "move-prev")
        hyprctl dispatch movetoworkspace -1
        ;;
    "menu")
        WORKSPACES=$(hyprctl workspaces -j | jq -r '.[] | "\(.id): \(.name)"' | sort -n)
        CHOICE=$(echo "$WORKSPACES" | wofi --dmenu --prompt " Workspaces")
        if [ ! -z "$CHOICE" ]; then
            WS_ID=$(echo "$CHOICE" | cut -d: -f1)
            hyprctl dispatch workspace "$WS_ID"
        fi
        ;;
    *)
        echo "Usage: $0 {next|prev|move-next|move-prev|menu}"
        ;;
esac
EOF

    # Script de gestion audio avancée
    cat > ~/.local/bin/audio-menu << 'EOF'
#!/bin/bash
# Menu de gestion audio

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'
}

get_mute_status() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q "MUTED" && echo "🔇" || echo "🔊"
}

CURRENT_VOL=$(get_volume)
MUTE_ICON=$(get_mute_status)

OPTIONS="$MUTE_ICON Volume: $CURRENT_VOL%\n🔇 Muet On/Off\n Ouvrir Pavucontrol\n🎵 Redémarrer Audio\n🔊 Volume Max\n🔉 Volume 50%\n🔈 Volume 25%"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "🎵 Audio Control" --width 300)

case "$CHOICE" in
    *"Volume:"*)
        # Ne rien faire, juste affichage
        ;;
    "🔇 Muet On/Off")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    " Ouvrir Pavucontrol")
        pavucontrol &
        ;;
    "🎵 Redémarrer Audio")
        systemctl --user restart pipewire pipewire-pulse wireplumber
        notify-send "🎵 Audio" "Services audio redémarrés"
        ;;
    "🔊 Volume Max")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%
        ;;
    "🔉 Volume 50%")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
        ;;
    "🔈 Volume 25%")
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 25%
        ;;
esac
EOF

    # Script de nettoyage système
    cat > ~/.local/bin/system-cleanup << 'EOF'
#!/bin/bash
# Script de nettoyage système

CLEANUP_SCRIPT=$(cat << 'SCRIPT'
#!/bin/bash
echo -e "\033[1;36m=== NETTOYAGE SYSTÈME ===\033[0m\n"

echo -e "\033[1;33m1. Nettoyage des caches Pacman...\033[0m"
sudo pacman -Sc --noconfirm
echo "✓ Terminé"

echo -e "\n\033[1;33m2. Nettoyage des caches AUR...\033[0m"
yay -Sc --noconfirm
echo "✓ Terminé"

echo -e "\n\033[1;33m3. Suppression des orphelins...\033[0m"
ORPHANS=$(pacman -Qtdq)
if [ ! -z "$ORPHANS" ]; then
    sudo pacman -Rns $ORPHANS --noconfirm
    echo "✓ Orphelins supprimés"
else
    echo "✓ Aucun orphelin trouvé"
fi

echo -e "\n\033[1;33m4. Nettoyage des logs système...\033[0m"
sudo journalctl --vacuum-time=7d
echo "✓ Terminé"

echo -e "\n\033[1;33m5. Nettoyage des fichiers temporaires...\033[0m"
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.cache/mesa_shader_cache/*
rm -rf /tmp/*
echo "✓ Terminé"

echo -e "\n\033[1;33m6. Nettoyage des caches utilisateur...\033[0m"
[ -d ~/.cache/yay ] && rm -rf ~/.cache/yay/*
[ -d ~/.cache/google-chrome ] && rm -rf ~/.cache/google-chrome/Default/Cache/*
[ -d ~/.cache/spotify ] && rm -rf ~/.cache/spotify/*
echo "✓ Terminé"

echo -e "\n\033[1;32m=== NETTOYAGE TERMINÉ ===\033[0m"
echo "Espace disque libéré:"
df -h / | tail -1 | awk '{print "Utilisé: "$3"/"$2" ("$5")"}'

read -p "Appuyez sur Entrée pour continuer..."
SCRIPT
)

kitty --title "System Cleanup" -e bash -c "$CLEANUP_SCRIPT"
EOF

    # Rendre tous les scripts exécutables
    chmod +x ~/.local/bin/*
    
    # Ajouter ~/.local/bin au PATH si pas déjà fait
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    
    print_success "Scripts utilitaires créés et configurés"
}

# 18. Configuration VS Code
configure_vscode() {
    print_header "Configuration de VS Code"
    
    # Extensions essentielles
    EXTENSIONS=(
        "GitHub.copilot"
        "ms-python.python"
        "ms-vscode.cpptools"
        "redhat.java"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-typescript-next"
        "formulahendry.auto-rename-tag"
        "christian-kohler.path-intellisense"
        "PKief.material-icon-theme"
        "zhuangtongfa.Material-theme"
        "aaron-bond.better-comments"
        "streetsidesoftware.code-spell-checker"
        "ms-vscode.hexeditor"
        "ritwickdey.LiveServer"
        "vscode-icons-team.vscode-icons"
    )
    
    print_message "Installation des extensions VS Code..."
    for extension in "${EXTENSIONS[@]}"; do
        code --install-extension "$extension" --force 2>/dev/null || true
    done
    
    # Configuration VS Code
    mkdir -p ~/.config/Code/User
    
    cat > ~/.config/Code/User/settings.json << 'EOF'
{
    "workbench.colorTheme": "Material Theme Darker High Contrast",
    "workbench.iconTheme": "vscode-icons",
    "editor.fontFamily": "'Fira Code', 'Droid Sans Mono', 'monospace'",
    "editor.fontLigatures": true,
    "editor.fontSize": 14,
    "editor.lineHeight": 1.6,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.smoothScrolling": true,
    "editor.minimap.enabled": true,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": "explicit",
        "source.organizeImports": "explicit"
    },
    "editor.rulers": [80, 120],
    "editor.wordWrap": "on",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.detectIndentation": true,
    "editor.renderWhitespace": "boundary",
    "editor.showFoldingControls": "always",
    "terminal.integrated.fontFamily": "'Fira Code', monospace",
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.cursorBlinking": true,
    "terminal.integrated.cursorStyle": "block",
    "workbench.startupEditor": "welcomePage",
    "workbench.editor.enablePreview": false,
    "workbench.editor.closeOnFileDelete": true,
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,
    "explorer.compactFolders": false,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 2000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,
    "git.autofetchPeriod": 180,
    "window.zoomLevel": 0,
    "window.titleBarStyle": "custom",
    "window.menuBarVisibility": "toggle",
    "breadcrumbs.enabled": true,
    "problems.showCurrentInStatus": true,
    "workbench.colorCustomizations": {
        "editor.background": "#0f0f23",
        "terminal.background": "#0f0f23",
        "panel.background": "#1a1a2e",
        "sideBar.background": "#16213e",
        "activityBar.background": "#0f0f23",
        "statusBar.background": "#33ccff",
        "statusBar.foreground": "#000000",
        "titleBar.activeBackground": "#0f0f23",
        "titleBar.activeForeground": "#ffffff",
        "tab.activeBackground": "#44475a",
        "tab.inactiveBackground": "#21222c"
    },
    "workbench.tokenColorCustomizations": {
        "comments": "#6272a4",
        "keywords": "#bd93f9",
        "strings": "#f1fa8c",
        "numbers": "#bd93f9",
        "functions": "#50fa7b",
        "variables": "#f8f8f2"
    },
    "extensions.autoUpdate": true,
    "update.mode": "start",
    "telemetry.telemetryLevel": "off",
    "security.workspace.trust.untrustedFiles": "open",
    "diffEditor.ignoreTrimWhitespace": false,
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/*.code-search": true,
        "**/target": true,
        "**/build": true,
        "**/dist": true
    },
    "emmet.includeLanguages": {
        "javascript": "javascriptreact",
        "typescript": "typescriptreact"
    },
    "prettier.semi": true,
    "prettier.singleQuote": true,
    "prettier.tabWidth": 2,
    "prettier.trailingComma": "es5"
}
EOF

    # Snippets personnalisés
    mkdir -p ~/.config/Code/User/snippets
    
    cat > ~/.config/Code/User/snippets/global.json << 'EOF'
{
    "Header Comment": {
        "prefix": "header",
        "body": [
            "/*",
            " * =============================================================================",
            " * $1",
            " * =============================================================================",
            " * Author: $2",
            " * Date: $CURRENT_DATE",
            " * Description: $3",
            " */"
        ],
        "description": "File header comment"
    },
    "Function Comment": {
        "prefix": "func-comment",
        "body": [
            "/**",
            " * $1",
            " * @param {$2} $3 - $4",
            " * @returns {$5} $6",
            " */"
        ],
        "description": "Function documentation comment"
    },
    "Console Log": {
        "prefix": "cl",
        "body": [
            "console.log('$1:', $1);"
        ],
        "description": "Console log with variable name"
    }
}
EOF

    print_success "VS Code configuré avec thème Arcane et extensions"
}

# 19. Configuration .bashrc améliorée
configure_bashrc() {
    print_header "Configuration de .bashrc"
    
    # Sauvegarde du bashrc existant
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    cat >> ~/.bashrc << 'EOF'


# Configuration Hyprland - Personnalisations Avancées
# Fastfetch au démarrage du terminal (seulement en interactif)
if command -v fastfetch &> /dev/null && [[ $- == *i* ]]; then
    fastfetch
fi

# Alias utiles - Système
alias ll='ls -alFh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'

# Alias utiles - Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Alias utiles - Commandes courtes
alias c='clear'
alias h='history'
alias j='jobs'
alias reload='source ~/.bashrc'

# Alias utiles - Pacman/AUR
alias update='sudo pacman -Syu && yay -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias info='pacman -Si'
alias orphans='sudo pacman -Rns $(pacman -Qtdq)'
alias cleanup='~/.local/bin/system-cleanup'

# Alias utiles - Configuration Hyprland
alias hyprconf='code ~/.config/hypr/hyprland.conf'
alias waybarconf='code ~/.config/waybar/config'
alias kittyconf='code ~/.config/kitty/kitty.conf'
alias hyprreload='hyprctl reload'

# Alias utiles - Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'

# Alias utiles - Docker
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'

# Alias utiles - Système
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias cpuinfo='lscpu'
alias gpuinfo='lspci | grep -E "VGA|3D"'

# Fonctions utiles
mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' ne peut pas être extrait avec extract()" ;;
        esac
    else
        echo "'$1' n'est pas un fichier valide"
    fi
}

weather() {
    curl -s "wttr.in/${1:-Brussels}?format=3"
}

# Prompt personnalisé avec couleurs et informations Git
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Prompt style Arcane/Fallout
PS1='\[\033[01;36m\]┌─[\[\033[01;32m\]\u\[\033[01;36m\]@\[\033[01;33m\]\h\[\033[01;36m\]]\[\033[00m\] \[\033[01;35m\]\w\[\033[00m\] \[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\n\[\033[01;36m\]└─\[\033[01;34m\]▶\[\033[00m\] '

# Variables d'environnement
export EDITOR=code
export BROWSER=google-chrome-stable
export TERMINAL=kitty
export PAGER=less
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# Historique amélioré
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help:history:clear"
export HISTTIMEFORMAT="%F %T "
shopt -s histappend
shopt -s histverify
shopt -s histexpand

# Options Bash améliorées
shopt -s checkwinsize
shopt -s expand_aliases
shopt -s cmdhist
shopt -s dotglob
shopt -s extglob
shopt -s nocaseglob
shopt -s cdspell
shopt -s dirspell

# Complétion automatique améliorée
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Colors pour ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Fonction pour afficher l'état du système
sysinfo() {
    echo -e "\033[1;36m=== INFORMATIONS SYSTÈME ===\033[0m"
    echo -e "\033[1;32mOS:\033[0m $(lsb_release -d | cut -f2)"
    echo -e "\033[1;32mKernel:\033[0m $(uname -r)"
    echo -e "\033[1;32mUptime:\033[0m $(uptime -p)"
    echo -e "\033[1;32mShell:\033[0m $SHELL"
    echo -e "\033[1;32mCPU:\033[0m $(lscpu | grep 'Model name' | cut -f 2 -d ':' | sed 's/^ *//')"
    echo -e "\033[1;32mRAM:\033[0m $(free -h | awk '/^Mem:/ {print $3"/"$2}')"
    echo -e "\033[1;32mDisk:\033[0m $(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')"
}

# Path local bin
export PATH="$HOME/.local/bin:$PATH"

# Alias pour démarrage manuel de Hyprland
alias startx='Hyprland'
alias hypr='Hyprland'
EOF

    print_success ".bashrc configuré avec prompt personnalisé et fonctions avancées"
}

# 20. Rebuild initramfs pour NVIDIA
rebuild_initramfs() {
    if $IS_NVIDIA; then
        print_header "Reconstruction de l'initramfs pour NVIDIA"
        sudo mkinitcpio -P
        print_success "Initramfs reconstruit avec les modules NVIDIA"
    fi
}

# 21. Tests finaux et validation
run_final_tests() {
    print_header "Tests finaux et validation"
    
    # Test Hyprland
    print_message "Test de Hyprland..."
    if command -v Hyprland >/dev/null 2>&1; then
        print_success "✓ Hyprland installé"
    else
        print_error "✗ Hyprland non trouvé"
    fi
    
    # Test des composants
    COMPONENTS=("waybar" "kitty" "wofi" "dunst" "hyprlock" "hypridle")
    for comp in "${COMPONENTS[@]}"; do
        if command -v "$comp" >/dev/null 2>&1; then
            print_success "✓ $comp installé"
        else
            print_warning "✗ $comp non trouvé"
        fi
    done
    
    # Test des drivers GPU
    case $GPU_TYPE in
        "nvidia")
            if command -v nvidia-smi >/dev/null 2>&1; then
                print_success "✓ Drivers NVIDIA détectés"
            else
                print_warning "✗ nvidia-smi non trouvé"
            fi
            ;;
        "amd")
            if lsmod | grep -q amdgpu; then
                print_success "✓ Driver AMD chargé"
            else
                print_warning "✗ Driver AMD non chargé"
            fi
            ;;
        "intel")
            if lsmod | grep -q i915; then
                print_success "✓ Driver Intel chargé"
            else
                print_warning "✗ Driver Intel non chargé"
            fi
            ;;
    esac
    
    # Test des services
    if systemctl is-enabled sddm >/dev/null 2>&1; then
        print_success "✓ SDDM activé"
    else
        print_warning "✗ SDDM non activé"
    fi
    
    print_success "Tests terminés"
}

# 22. Finalisation et instructions
finalize_setup() {
    print_header "Finalisation de l'installation"
    
    # Nettoyage des caches et fichiers temporaires
    print_message "Nettoyage final..."
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm 2>/dev/null || true
    
    # Génération des polices et caches
    print_message "Génération des caches..."
    fc-cache -fv >/dev/null 2>&1
    gtk-update-icon-cache /usr/share/icons/Papirus-Dark/ >/dev/null 2>&1 || true
    
    # Permissions pour les groupes
    sudo usermod -aG audio,video,input,bluetooth,docker $USER
    
    # Création d'un fichier de version
    echo "Hyprland Setup v2.0 - $(date)" > ~/.config/hypr/setup_version.txt
    echo "GPU: $GPU_VENDOR ($GPU_TYPE)" >> ~/.config/hypr/setup_version.txt
    
    # Affichage des informations finales
    clear
    print_success "🎉 INSTALLATION HYPRLAND TERMINÉE AVEC SUCCÈS!"
    echo ""
    
    # Bannière de fin
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${PURPLE}HYPRLAND SETUP COMPLETE${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} Configuration automatique terminée                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} GPU détecté et optimisé: ${YELLOW}$GPU_VENDOR ($GPU_TYPE)${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} Environnements de bureau précédents supprimés              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} Drivers graphiques installés et configurés                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} Thème Arcane/Fallout appliqué                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}✓${NC} Scripts utilitaires créés                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    print_message "ACTIONS REQUISES :"
    echo -e "  ${YELLOW}1.${NC} ${RED}REDÉMARRER MAINTENANT${NC} : ${CYAN}sudo reboot${NC}"
    echo -e "  ${YELLOW}2.${NC} Sélectionner 'Hyprland' dans SDDM"
    echo -e "  ${YELLOW}3.${NC} Ajouter vos vidéos dans ${CYAN}~/Videos/Wallpapers/${NC}"
    
    echo ""
    print_message "RACCOURCIS CLAVIER PRINCIPAUX :"
    echo -e "  ${CYAN}Super + Q${NC}       : Terminal (Kitty)"
    echo -e "  ${CYAN}Super + E${NC}       : Gestionnaire de fichiers"
    echo -e "  ${CYAN}Super + R${NC}       : Menu applications (Wofi)"
    echo -e "  ${CYAN}Super + W${NC}       : Navigateur (Chrome)"
    echo -e "  ${CYAN}Super + L${NC}       : Verrouiller l'écran"
    echo -e "  ${CYAN}Super + F${NC}       : Plein écran"
    echo -e "  ${CYAN}Print${NC}           : Menu capture d'écran"
    echo -e "  ${CYAN}Super + Shift + Q${NC}: Menu d'alimentation"
    
    echo ""
    print_message "SCRIPTS UTILITAIRES DISPONIBLES :"
    echo -e "  ${CYAN}change-wallpaper${NC}   : Changer le fond d'écran vidéo"
    echo -e "  ${CYAN}screenshot-menu${NC}    : Menu capture d'écran avancé"
    echo -e "  ${CYAN}power-menu${NC}         : Menu de gestion de l'énergie"
    echo -e "  ${CYAN}audio-menu${NC}         : Contrôles audio avancés"
    echo -e "  ${CYAN}system-monitor${NC}     : Moniteur système graphique"
    echo -e "  ${CYAN}system-cleanup${NC}     : Nettoyage automatique du système"
    echo -e "  ${CYAN}workspace-manager${NC}  : Gestionnaire de workspaces"
    echo -e "  ${CYAN}toggle-transparency${NC}: Basculer la transparence"
    
    echo ""
    print_message "FICHIERS DE CONFIGURATION IMPORTANTS :"
    echo -e "  ${BLUE}~/.config/hypr/hyprland.conf${NC}     (Configuration principale)"
    echo -e "  ${BLUE}~/.config/waybar/config${NC}          (Barre de statut)"
    echo -e "  ${BLUE}~/.config/hypr/hyprlock.conf${NC}     (Écran de verrouillage)"
    echo -e "  ${BLUE}~/.config/kitty/kitty.conf${NC}       (Terminal)"
    echo -e "  ${BLUE}~/.config/wofi/config${NC}            (Menu applications)"
    echo -e "  ${BLUE}~/.config/dunst/dunstrc${NC}          (Notifications)"
    
    echo ""
    print_message "OPTIMISATIONS GPU APPLIQUÉES :"
    case $GPU_TYPE in
        "nvidia")
            echo -e "  ${GREEN}•${NC} Configuration NVIDIA haute performance"
            echo -e "  ${GREEN}•${NC} Variables d'environnement Wayland optimisées"
            echo -e "  ${GREEN}•${NC} Modules kernel automatiquement configurés"
            echo -e "  ${GREEN}•${NC} Hook de mise à jour NVIDIA installé"
            echo -e "  ${GREEN}•${NC} Transparence et effets visuels maximisés"
            ;;
        "amd")
            echo -e "  ${GREEN}•${NC} Drivers Mesa avec optimisations RADV"
            echo -e "  ${GREEN}•${NC} Configuration Vulkan ACO activée"
            echo -e "  ${GREEN}•${NC} Support Wayland natif configuré"
            echo -e "  ${GREEN}•${NC} Effets visuels équilibrés pour AMD"
            ;;
        "intel")
            echo -e "  ${GREEN}•${NC} Configuration allégée pour Intel Graphics"
            echo -e "  ${GREEN}•${NC} Optimisations de performance spécifiques"
            echo -e "  ${GREEN}•${NC} Transparence adaptée aux capacités"
            echo -e "  ${GREEN}•${NC} Variables d'environnement Intel optimisées"
            ;;
        *)
            echo -e "  ${GREEN}•${NC} Configuration générique équilibrée"
            echo -e "  ${GREEN}•${NC} Support Wayland standard"
            ;;
    esac
    
    echo ""
    print_message "APPLICATIONS INSTALLÉES :"
    echo -e "  ${PURPLE}Développement :${NC} VS Code, Android Studio, Docker"
    echo -e "  ${PURPLE}Internet      :${NC} Google Chrome, Brave Browser"
    echo -e "  ${PURPLE}Multimédia    :${NC} Spotify (avec Spicetify non configuré), mpv"
    echo -e "  ${PURPLE}Système       :${NC} Fastfetch, Pavucontrol, Blueman"
    echo -e "  ${PURPLE}Outils        :${NC} Scripts personnalisés, Gestionnaires"
    
    echo ""
    print_message "⚠️ NOTES IMPORTANTES :"
    if $IS_NVIDIA; then
        echo -e "  ${YELLOW}•${NC} NVIDIA : Initramfs reconstruit avec les modules nécessaires"
        echo -e "  ${YELLOW}•${NC} Redémarrage obligatoire pour charger les drivers NVIDIA"
        echo -e "  ${YELLOW}•${NC} En cas de problème : Ctrl+Alt+F2 puis 'sudo systemctl start sddm'"
    fi
    echo -e "  ${YELLOW}•${NC} Premier démarrage : Sélectionnez 'Hyprland' dans le menu SDDM"
    echo -e "  ${YELLOW}•${NC} Placez vos vidéos de fond dans ~/Videos/Wallpapers/"
    echo -e "  ${YELLOW}•${NC} Utilisez 'hyprconf' pour éditer la configuration"
    echo -e "  ${YELLOW}•${NC} Consultez les logs avec : journalctl --user -xe"
    
    echo ""
    print_message "DÉPANNAGE RAPIDE :"
    echo -e "  ${RED}•${NC} Écran noir ? Essayez : ${CYAN}Super + Q${NC} pour ouvrir un terminal"
    echo -e "  ${RED}•${NC} Pas de son ? Lancez : ${CYAN}audio-menu${NC} puis redémarrer audio"
    echo -e "  ${RED}•${NC} Performance ? Utilisez : ${CYAN}toggle-transparency${NC}"
    echo -e "  ${RED}•${NC} Bluetooth ? Activez : ${CYAN}sudo systemctl start bluetooth${NC}"
    
    echo ""
    print_header "VOTRE SETUP HYPRLAND ARCANE/FALLOUT EST PRÊT !"
    echo -e "${GREEN}Profitez de votre nouvel environnement de bureau immersif et moderne ! 🌟${NC}"
    echo ""
    
    # Demander si l'utilisateur veut redémarrer maintenant
    echo -e "${YELLOW}Voulez-vous redémarrer maintenant ? (Y/n)${NC}"
    read -r -n 1 RESTART_CHOICE
    echo ""
    
    if [[ $RESTART_CHOICE =~ ^[Yy]$ ]] || [[ -z $RESTART_CHOICE ]]; then
        print_message "Redémarrage dans 5 secondes... (Ctrl+C pour annuler)"
        sleep 5
        sudo reboot
    else
        print_warning "N'oubliez pas de redémarrer manuellement : sudo reboot"
    fi
}


# FONCTION PRINCIPALE


main() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                    ${CYAN}HYPRLAND SETUP SCRIPT v2.0${NC}                     ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}             ${YELLOW}Configuration automatique avec détection GPU${NC}         ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                   ${GREEN}Thème Arcane/Fallout Premium${NC}                   ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    print_message "Démarrage de la configuration Hyprland..."
    echo ""
    
    # Avertissement important
    echo -e "${RED}⚠️  AVERTISSEMENT IMPORTANT :${NC}"
    echo -e "   • Ce script va supprimer les environnements de bureau existants"
    echo -e "   • Une sauvegarde sera créée automatiquement"
    echo -e "   • La configuration sera optimisée selon votre GPU"
    echo -e "   • Un redémarrage sera nécessaire à la fin"
    echo ""
    
    read -p "Continuer l'installation ? (y/N) : " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation annulée par l'utilisateur"
        exit 0
    fi
    
    echo ""
    print_message "Lancement de la configuration complète..."
    echo ""
    
    # Vérifications préliminaires
    check_user
    
    # Phase 1 : Détection et nettoyage
    detect_current_desktop_environments
    remove_desktop_environments
    enable_multilib
    detect_gpu
    
    # Phase 2 : Installation des outils de base
    install_yay
    install_gpu_drivers
    
    # Phase 3 : Installation des composants principaux
    install_graphics
    install_dev_tools
    setup_directories
    
    # Phase 4 : Configuration personnalisée
    configure_hyprland
    create_video_wallpaper
    configure_waybar
    configure_hyprlock
    configure_hypridle
    configure_kitty
    configure_wofi
    configure_dunst
    configure_spicetify
    configure_fastfetch
    configure_sddm
    configure_services
    install_gtk_themes
    configure_vscode
    configure_bashrc
    create_utilities
    
    # Phase 5 : Finalisation
    rebuild_initramfs
    run_final_tests
    finalize_setup
}

# Point d'entrée du script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
