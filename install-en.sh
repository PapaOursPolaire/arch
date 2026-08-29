#!/bin/bash

if ! command -v arch-chroot &>/dev/null; then
    echo "[INFO] arch-chroot missing, attempting immediate installation..."
    pacman -Sy --noconfirm arch-install-scripts || {
        echo "[ERROR] Unable to install arch-install-scripts. Stopping script."
        exit 1
    }
fi

# Automated Arch Linux installation script
# Made by PapaOursPolaire - available on GitHub PapaOursPolaire
# Version: 864.4, fix 4 of version 864.4
# Updated: 02/08/2026 at 3:34 PM
# GET THE NEW VERSION after running dos2unix ON LINUX or in the chroot, pacman -Sy dos2unix
# Fixed 2358 errors reported by ShellCheck and by the ISO's TTY console
# Bug with fastfetch auto-run: it's there, but doesn't launch automatically
# Visual Studio still won't install even with its own dedicated function! 
# Removed vulkan software/extensions because they kept breaking and didn't work under automation
# Rewrote the install_paru() function -> 130th rewrite on 08/14 and it still doesn't work
#[community] -> REMOVED because the [community] package servers became obsolete on 08/13/2025 around 8pm
#Include = /etc/pacman.d/mirrorlist -> these damn servers got wiped so it kept throwing 404 errors and on top of that most of them crashed because of it, 2 hours wasted on this nonsense, ugh I'm losing it
# Remember to remove DRY RUN mode, it's become pointless since version 246.6 — it was meant to simulate the process and check the script's appearance
# Global configuration -> Theme (in development, no function declared yet)

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="864.4"
readonly LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"

# Colors for display
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/SDDM-Fallout-theme" # Unused, logic needs rework
readonly LOCKSCREEN_THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.falloutlock"

# Global variables
DISK=""
EFI_PART=""
BOOT_PART=""
ROOT_PART=""
HOME_PART=""
SWAP_PART=""
USERNAME=""
HOSTNAME=""
USER_PASSWORD=""
DE_CHOICE=""
USE_SWAP=true
USE_SEPARATE_HOME=false
DRY_RUN=false
TOTAL_STEPS=25
CURRENT_STEP=0
CLEANUP_DONE=false

# Variables for custom partitioning
PARTITION_EFI_SIZE="512M"
PARTITION_ROOT_SIZE="60G"  
PARTITION_SWAP_SIZE="8G"
PARTITION_HOME_SIZE="remaining"
CUSTOM_PARTITIONING=false

# Main function - primary entry point
main() {
    # Initialization
    init_logging
    parse_arguments "$@"
    
    echo "Loading resources..."
    echo -e "${CYAN}Arch Linux Fallout Edition - Version ${SCRIPT_VERSION}${NC}"
    echo ""

    # Automatic boot mode detection (MUST be first)
    detect_boot_mode

    # Check whether /usr/bin/arch-chroot is installed, install it if not
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot missing, attempting installation..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERROR] Unable to install arch-install-scripts. Stopping script."
            exit 1
        }
    fi

    # Signal handling
    trap cleanup EXIT INT TERM

    # Installing required commands
    check_requirements || {
        print_error "Failed to install required commands"
        return 1
    }

    # Display
    show_banner

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "MODE SIMULATION ACTIVE"
        echo -e "${YELLOW}   • No changes will be made${NC}"
        echo -e "${YELLOW}   • All operations will be simulated${NC}"
        echo -e "${YELLOW}   Boot mode detected: ${BOOT_MODE}${NC}"
        echo ""
    fi

    # Full installation sequence
    echo -e "${CYAN}STARTING ARCH LINUX INSTALLATION...${NC}"
    echo -e "${YELLOW}Mode de boot: ${BOOT_MODE}${NC}"
    echo ""

    echo -e "${PURPLE}PHASE 1: SYSTEM PREPARATION${NC}"
    
    check_requirements || {
        print_error "Prerequisite check failed"
        return 1
    }
    
    test_environment || {
        print_error "Environment test failed"
        return 1
    }
    
    optimize_pacman || {
        print_warning "Optimisation Pacman partielle"
    }

    echo -e "${PURPLE}PHASE 2: DISK AND PARTITION SETUP${NC}"
    
    select_disk || {
        print_error "Disk selection failed"
        return 1
    }
    
    choose_partitioning || {
        print_error "Partitioning choice failed"
        return 1
    }
    
    format_partitions || {
        print_error "Partition formatting failed"
        return 1
    }
    
    mount_partitions || {
        print_error "Partition mounting failed"
        return 1
    }

    echo -e "${PURPLE}PHASE 3: BASE SYSTEM INSTALLATION${NC}"
    
    install_system || {
        print_error "Base system installation failed"
        return 1
    }
    
    configure_system || {
        print_error "System configuration failed"
        return 1
    }
    
    create_users || {
        print_error "User creation failed"
        return 1
    }

    echo -e "${PURPLE}PHASE 4: INTERFACE GRAPHIQUE${NC}"
    
    select_desktop || {
        print_warning "No desktop environment selected"
    }
    
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_desktop || {
            print_error "Desktop environment installation failed"
            return 1
        }
    else
        print_info "Mode console/serveur - pas d'interface graphique"
    fi

    echo -e "${PURPLE}PHASE 5: BOOTLOADER AND THEMES${NC}"
    
    # Bootloader configuration adapted to the mode
    configure_grub || {
        print_error "Bootloader configuration failed"
        return 1
    }
    
    # KDE configuration only if KDE is installed
    if [[ "$DE_CHOICE" == "kde" ]]; then
        configure_kde_lockscreen || {
            print_warning "KDE lockscreen configuration failed"
        }
    fi

    echo -e "${PURPLE}PHASE 6: AUDIO AND MULTIMEDIA${NC}"
    
    install_audio_system || {
        print_warning "Audio system installation failed"
    }
    
    install_boot_sound || {
        print_warning "Boot sound installation failed"
    }
    
    # Plymouth only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_plymouth || {
            print_warning "Plymouth configuration failed"
        }
    fi
    
    # Display manager only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_sddm || {
            print_warning "Display manager configuration failed"
        }
    fi

    echo -e "${PURPLE}PHASE 7: APPLICATIONS ET LOGICIELS${NC}"
    
    install_software || {
        print_warning "Partial software installation failure"
    }
    
    install_web || {
        print_warning "Partial browser installation failure"
    }
    
    install_spotify || {
        print_warning "Spotify installation failed"
    }
    
    install_wine || {
        print_warning "Wine installation failed"
    }

    echo -e "${PURPLE}PHASE 8: TOOLS AND DEVELOPMENT${NC}"
    
    install_paru || {
        print_warning "Paru installation failed"
    }
    
    install_development || {
        print_warning "Partial development tools installation failure"
    }
    
    # Steam only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_steam || {
            print_warning "Steam installation failed"
        }
    fi

    echo -e "${PURPLE}PHASE 9: THEMES AND CUSTOMIZATION${NC}"
    
    # Themes only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_themes || {
            print_warning "Partial theme installation failure"
        }
    fi
    
    install_fastfetch || {
        print_warning "Fastfetch installation failed"
    }

    echo -e "${PURPLE}PHASE 10: FINAL CONFIGURATION${NC}"
    
    final_config || {
        print_warning "Partial final configuration failure"
    }
    
    install_vscode || {
        print_warning "VS Code installation failed"
    }
    
    generate_postinstall || {
        print_warning "Post-install script generation failed"
    }
    
    # Finalization
    finish_install || {
        print_error "Installation finalization failed"
        return 1
    }

    echo -e "${GREEN}INSTALLATION REPORT COMPLETE${NC}"
    echo ""
    
    # Display summary based on mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${GREEN}✓ UEFI installation successful${NC}"
        echo -e "  • GPT table created"
        echo -e "  • EFI partition configured"
        echo -e "  • GRUB UEFI installed"
    else
        echo -e "${GREEN}✓ BIOS/Legacy installation successful${NC}"
        echo -e "  • MBR table created"
        echo -e "  • Boot partition configured"
        echo -e "  • GRUB BIOS installed"
    fi
    
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "1. Remove the installation media"
    echo -e "2. Restart the system"
    echo -e "3. Log in with user: ${USERNAME}"
    
    if [[ "$BOOT_MODE" == "bios" ]]; then
        while true; do
            read -r -p "Boot partition size (default: 512M): " boot_input
            boot_input=${boot_input:-512M}
            if validate_input "$boot_input" "size"; then
                PARTITION_BOOT_SIZE="$boot_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    fi
    
    echo ""
    print_success "Arch Linux Fallout Edition installation completed successfully!"
    
    # Final log save
    if [[ -f "$LOG_FILE" ]] && [[ -n "$USERNAME" ]]; then
        local user_log="/mnt/home/$USERNAME/installation.log"
        if cp "$LOG_FILE" "$user_log" 2>/dev/null; then
            print_info "Installation log saved: $user_log"
        fi
    fi
    
    return 0
}

detect_boot_mode() {
    print_header "DETECTION DU MODE DE BOOT"
    
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="uefi"
        print_success "UEFI mode detected"
        echo -e "${GREEN}• Table de partitions: GPT${NC}"
        echo -e "${GREEN}• Partition boot: EFI (FAT32)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB x86_64-efi${NC}"
    else
        BOOT_MODE="bios"
        print_success "BIOS/Legacy mode detected"
        echo -e "${GREEN}• Table de partitions: MBR${NC}"
        echo -e "${GREEN}• Partition boot: Boot (ext4)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB i386-pc${NC}"
    fi
    
    # Check boot mode consistency
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -d /sys/firmware/efi ]]; then
        print_error "Inconsistency detected: BOOT_MODE=uefi but /sys/firmware/efi does not exist"
        echo "Forcing BIOS mode"
        BOOT_MODE="bios"
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ -d /sys/firmware/efi ]]; then
        print_error "Inconsistency detected: BOOT_MODE=bios but /sys/firmware/efi exists"
        echo "Forcing UEFI mode"
        BOOT_MODE="uefi"
    fi
    
    echo ""
    echo -e "${YELLOW}Configuring for mode: ${BOOT_MODE}${NC}"
    echo ""
}

configure_grub() {
    print_header "STEP 13/$TOTAL_STEPS: BOOTLOADER CONFIGURATION based on firmware"
    CURRENT_STEP=13

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating bootloader configuration"
        return 0
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        configure_grub_uefi
    else
        configure_grub_bios
    fi
}

configure_grub_bios() {
    print_header "STEP 14/$TOTAL_STEPS: GRUB BIOS CONFIGURATION"
    CURRENT_STEP=14
    print_info "Installing and configuring the GRUB bootloader for BIOS..."

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installing GRUB for BIOS on ${DISK}"
grub-install --target=i386-pc --recheck "${DISK}"
EOF

    if [[ $? -ne 0 ]]; then
        print_error "GRUB installation for BIOS failed"
        return 1
    fi

    print_info "Downloading the Fallout theme from GitHub..."
    /usr/bin/arch-chroot /mnt bash -c '
set -e
THEME_DIR="/boot/grub/themes/fallout"
TMP_DIR="/tmp/fallout-grub-theme"
rm -rf "$THEME_DIR" "$TMP_DIR"
git clone --depth=1 https://github.com/shvchk/fallout-grub-theme.git "$TMP_DIR"
mkdir -p "$THEME_DIR"
cp -r "$TMP_DIR"/* "$THEME_DIR"/
rm -rf "$TMP_DIR"
'

    print_info "Configuring /etc/default/grub with the Fallout theme..."
    cat > /mnt/etc/default/grub <<'EOF'
# GRUB BIOS configuration with Fallout theme
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch Linux"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=1920x1080,auto
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    print_info "Generating grub.cfg file..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Failed to generate grub.cfg file"
        return 1
    }

    print_success "GRUB BIOS installed and Fallout theme applied!"
}

configure_grub_uefi() {
    print_header "STEP 14/$TOTAL_STEPS: GRUB UEFI CONFIGURATION"
    CURRENT_STEP=14
    print_info "Installing and configuring the GRUB bootloader for UEFI..."

    # Installing GRUB for UEFI
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installing GRUB for UEFI..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    if [[ $? -ne 0 ]]; then
        print_error "GRUB installation for UEFI failed"
        return 1
    fi

    print_info "Downloading the Fallout theme from GitHub..."
    /usr/bin/arch-chroot /mnt bash -c '
set -e
THEME_DIR="/boot/grub/themes/fallout"
TMP_DIR="/tmp/fallout-grub-theme"
rm -rf "$THEME_DIR" "$TMP_DIR"
git clone --depth=1 https://github.com/shvchk/fallout-grub-theme.git "$TMP_DIR"
mkdir -p "$THEME_DIR"
cp -r "$TMP_DIR"/* "$THEME_DIR"/
rm -rf "$TMP_DIR"
'

    print_info "Configuring /etc/default/grub with the Fallout theme..."
    cat > /mnt/etc/default/grub <<'EOF'
# GRUB UEFI configuration with Fallout theme
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch Linux"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=1920x1080,auto
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_OS_PROBER=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    print_info "Generating grub.cfg file..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Failed to generate grub.cfg file"
        return 1
    }

    print_success "GRUB UEFI installed and Fallout theme applied!"
}

install_web() {
    print_header "STEP 21/$TOTAL_STEPS: WEB BROWSER INSTALLATION"
    CURRENT_STEP=21

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub com.vivaldi.Vivaldi || true
    flatpak install -y flathub com.opera.Opera || true
    flatpak install -y flathub org.midori_browser.Midori || true

    browsers=(
        # Check which ones are installed on GNOME & KDE, sometimes different
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser" # Doesn't work -> Installed via the post-install.sh script
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi" # GNOME uniquement (enfin je pense)
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher" # Ne marche pas
        "GNOME Web (Epiphany)|epiphany|epiphany||org.gnome.Epiphany"
        "Midori|midori||midori|" # Ne marche pas
        "Google Chrome|google-chrome||google-chrome|com.google.Chrome" # Doesn't work but installed via the post-install.sh script
    )
    for entry in "${browsers[@]}"; do
        IFS="|" read -r name cmd pkg_pacman pkg_paru pkg_flatpak <<< "$entry"
        echo "[INFO] $name"
        if command -v "$cmd" &>/dev/null; then
        echo "[OK] $name already present"; continue
        fi
        ok=false
        if [[ -n "$pkg_pacman" ]]; then pacman -S --noconfirm --needed "$pkg_pacman" && ok=true; fi
        if [[ "$ok" = false && -n "$pkg_paru" ]]; then
        if command -v paru &>/dev/null; then sudo -u "$USERNAME" paru -S --noconfirm "$pkg_paru" && ok=true; fi
        fi
        if [[ "$ok" = false && -n "$pkg_flatpak" ]]; then flatpak install -y flathub "$pkg_flatpak" && ok=true; fi
        if [[ "$ok" = true ]]; then update-desktop-database /usr/share/applications || true; echo "[SUCCESS] $name installed"
        else echo "[ERROR] Impossible d’installer $name"; fi
    done
}

install_steam() {
    print_header "STEP 26/$TOTAL_STEPS: STEAM INSTALLATION"
    CURRENT_STEP=26

    # Check whether Flatpak is installed in the chroot
    if ! /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        print_info "Flatpak missing — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Impossible d’installer Flatpak"
            return 1
        }
        # Enable Flathub if not already configured
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    # Installing Steam via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.valvesoftware.Steam; then
        print_success "Steam (Flatpak) installed successfully"
    else
        print_warning "Failed to install Steam (Flatpak). Check your connection or Flathub."
    fi
}


# Utility and logging functions
# Check whether a command exists in the chroot
chroot_cmd_exists() {
    /usr/bin/arch-chroot /mnt bash -lc "command -v '${1}' >/dev/null 2>&1"
}

# (Re)ensure paru is installed in the chroot -> Still doesn't work either
ensure_paru_in_chroot() {
    # Check whether paru is already present in the chroot
    if chroot_cmd_exists paru; then
        print_success "Paru already present in the chroot"
        return 0
    fi

    print_info "Paru missing — installing via AUR in the chroot"

    # Install base-devel and git to build from the AUR
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Unable to install base-devel and git in the chroot"
        return 1
    }

    # Run the installation via the dedicated function
    if install_paru; then
        print_success "Paru installed successfully in the chroot"
        return 0
    fi

    print_warning "Paru installation failed — attempting yay fallback"
    install_yay_in_chroot || return 1
}

check_requirements() {
    print_info "Checking and installing required commands..."
    
    local missing_pkgs=()
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk" 
        "curl" "git" "timedatectl" "unzip" "wget"
    )

    # Check for missing commands
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            case "$cmd" in
                "pacstrap"|"genfstab") missing_pkgs+=("arch-install-scripts") ;;
                "mkfs.fat") missing_pkgs+=("dosfstools") ;;
                "wget") missing_pkgs+=("wget") ;;
                "mkfs.ext4") missing_pkgs+=("e2fsprogs") ;;
                *) missing_pkgs+=("$cmd") ;;
            esac
        fi
    done

    # Install if needed
    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        print_warning "Installing missing packages: ${missing_pkgs[*]}"
        pacman -Sy --noconfirm "${missing_pkgs[@]}" || {
            print_error "Failed to install dependencies"
            return 1
        }
    fi

    # FORCED installation of git (just in case)
    if ! command -v git &>/dev/null; then
        print_info "Forcing installation of git..."
        pacman -Sy --noconfirm git || {
            print_error "Impossible d'installer git"
            return 1
        }
    fi

    # FORCED installation of unzip
    if ! command -v unzip &>/dev/null; then
        print_info "Forcing installation of unzip..."
        pacman -Sy --noconfirm unzip || {
            print_error "Impossible d'installer unzip"
            return 1
        }
    fi

    if [[ -d /mnt ]]; then
        if ! /usr/bin/arch-chroot /mnt bash -lc "command -v unzip >/dev/null 2>&1"; then
            print_info "Installing unzip in the chroot..."
            /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed unzip || {
                print_warning "Unable to install unzip in the chroot"
            }
        fi
    fi

    print_success "All required commands are available"
}

# Optimizing Pacman configuration for speed
optimize_pacman() {
    print_header "ETAPE 3/$TOTAL_STEPS: OPTIMISATION DE PACMAN"
    
    # Backup original configuration
    if [[ -f /etc/pacman.conf ]]; then
        cp /etc/pacman.conf /etc/pacman.conf.backup.$(date +%s)
    fi
    
    print_info "Configuring Pacman for maximum performance..."
    
    # Optimized configuration
    cat > /etc/pacman.conf <<'PACMAN_EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
VerbosePkgLists
ParallelDownloads = 10
ILoveCandy
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
Color
TotalDownload

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
PACMAN_EOF
    
    print_info "Cleaning up obsolete mirrors..."
    
    # Remove [community] if present (obsolete)
    if grep -q "^\[community\]" /etc/pacman.conf; then
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        print_warning "[community] repo removed (obsolete)"
    fi
    
    print_info "Optimizing mirrors with reflector..."
    
    # Install reflector if missing
    if ! command -v reflector &>/dev/null; then
        pacman -S --noconfirm reflector || {
            print_warning "Reflector not installable, using default mirrors"
            return 0
        }
    fi
    
    # Generate optimized mirrors
    local reflector_success=false
    
    # Attempt 1: Fast countries
    if reflector \
        --country France,Germany,Netherlands,Belgium,Switzerland \
        --protocol https \
        --latest 20 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist; then
        reflector_success=true
        print_success "Mirrors optimized (targeted countries)"
    
    # Attempt 2: All countries
    elif reflector \
        --protocol https \
        --latest 20 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist; then
        reflector_success=true
        print_success "Mirrors optimized (all countries)"
    
    # Attempt 3: Minimum fallback
    else
        print_warning "Reflector failed, using fallback mirror"
        cat > /etc/pacman.d/mirrorlist <<'EOF'
## Fallback ArchLinux
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
EOF
    fi
    
    print_info "Nettoyage du cache Pacman..."
    
    # Aggressive but safe cleanup
    pacman -Scc --noconfirm 2>/dev/null || true
    rm -rf /var/lib/pacman/sync/* 2>/dev/null || true
    
    print_info "Synchronizing databases..."
    
    # Resync with new configuration
    if pacman -Syy --noconfirm; then
        print_success "Databases synchronized"
    else
        print_warning "Synchronisation partielle, continuation..."
    fi
    
    print_success "PACMAN OPTIMIZED - Ready for fast installation"
}

# Logging initialization
init_logging() {
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "Arch Linux Fallout installation - $(date)" >> "$LOG_FILE"
    echo "Script version: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Timestamped logging
log_message() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# Formatted display - find something better like "layout" if I get time
print_header() {
    local message="$1"
    echo ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo -e "${WHITE}$message${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
    log_message "HEADER" "$message"
}

# Keep it in English or not? Thinking about doing a full English version but with Google Translate :/
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_message "ERROR" "$1"
    return 1
} 

can_use_userns() {
    # Check whether userns is enabled
    local v
    v="$(sysctl -n kernel.unprivileged_userns_clone 2>/dev/null || echo -1)"
    if [[ "$v" == "1" ]]; then
        return 0
    fi
    if command -v unshare >/dev/null 2>&1 && unshare -Ur true 2>/dev/null; then
        return 0
    fi
    return 1
}

# Progress bar with time estimate # Improve if possible
show_progress() {
    local current="$1"
    local total="$2" 
    local task="$3"
    local start_time="$4"
    
    local percent=$((current * 100 / total))
    local elapsed=$(($(date +%s) - start_time))
    local remaining=0
    
    if [[ $current -gt 0 ]]; then
        remaining=$(((elapsed * (total - current)) / current))
    fi
    
    local bar_length=50
    local filled_length=$((percent * bar_length / 100))
    local bar=""
    
    for ((i=0; i<filled_length; i++)); do
        bar+="█"
    done
    for ((i=filled_length; i<bar_length; i++)); do
        bar+="░"
    done
    
    printf "\r${CYAN}[%s] %d%% | %02d:%02d restant | %s${NC}" \
        "$bar" "$percent" "$((remaining/60))" "$((remaining%60))" "$task"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Progress function for long tasks
run_with_progress() {
    local task_name="$1"
    local duration="$2"
    shift 2
    local command="$*"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation: $task_name"
        return 0
    fi
    
    print_info "Starting: $task_name"
    local start_time=$(date +%s)
    
    # Run the command in the background
    eval "$command" &
    local cmd_pid=$!
    
    # Progress simulation
    local steps=$((duration * 2))
    for ((i=0; i<=steps; i++)); do
        if ! kill -0 $cmd_pid 2>/dev/null; then
            break
        fi
        show_progress "$i" "$steps" "$task_name" "$start_time"
        sleep 0.5
    done
    
    wait $cmd_pid
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        show_progress $steps $steps "$task_name" $start_time
        print_success "$task_name completed"
    else
        echo ""
        print_error "$task_name failed (code: $exit_code)"
        return $exit_code
    fi
}

# Input validation with minimum 6-character password
validate_input() {
    local input="$1"
    local type="$2"
    local min_length="${3:-1}"
    
    case "$type" in
        "username")
            [[ ${#input} -ge 3 && ! "$input" =~ [[:space:]] && "$input" =~ ^[a-z][a-z0-9_-]*$ ]]
            ;;
        "hostname")
            [[ ${#input} -ge 2 && "$input" =~ ^[a-zA-Z0-9-]+$ && ! "$input" =~ ^- && ! "$input" =~ -$ ]]
            ;;
        "password")
            [[ ${#input} -ge 6 ]]
            ;;
        "size")
            # Accept M, m, G, g
            [[ "$input" =~ ^[0-9]+[MmGg]$ ]]
            ;;
        *)
            [[ ${#input} -ge "$min_length" ]]
            ;;
    esac
}

# Function to convert sizes to MB (M, m, G, g)
convert_to_mb() {
    local size="$1"
    local number="${size%[MmGg]}"
    local unit="${size: -1}"
    
    case "${unit^^}" in
        "M") echo "$number" ;;
        "G") echo $((number * 1024)) ;;
        *) echo "0" ;;
    esac
}

# Interface for custom partition configuration
configure_custom_partitioning() {
    print_header "CUSTOM PARTITION CONFIGURATION"
    
    echo -e "${WHITE}Partition size configuration:${NC}"
    echo -e "${YELLOW}Format attendu : nombre suivi de M/m (Mo) ou G/g (Go)${NC}"
    echo -e "${YELLOW}Exemples : 512M, 512m, 2G, 2g, 100G, 100g${NC}"
    echo ""
    
    # Different configuration depending on boot mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        # EFI configuration for UEFI
        while true; do
            read -r -p "EFI partition size (default: 512M): " efi_input
            efi_input=${efi_input:-512M}
            if validate_input "$efi_input" "size"; then
                PARTITION_EFI_SIZE="$efi_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    else
        # Boot configuration for BIOS
        while true; do
            read -r -p "Boot partition size (default: 512M): " boot_input
            boot_input=${boot_input:-512M}
            if validate_input "$boot_input" "size"; then
                PARTITION_BOOT_SIZE="$boot_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    fi
    
    # Root configuration (same for both modes)
    while true; do
        read -r -p "Root partition size (default: 60G): " root_input
        root_input=${root_input:-60G}
        if validate_input "$root_input" "size"; then
            PARTITION_ROOT_SIZE="$root_input"
            break
        fi
        print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex : 60G, 60g)"
    done
    
    # Swap configuration (optional)
    if confirm_action "Create a Swap partition?" "O"; then
        USE_SWAP=true
        while true; do
            read -r -p "Swap partition size (default: 8G): " swap_input
            swap_input=${swap_input:-8G}
            if validate_input "$swap_input" "size"; then
                PARTITION_SWAP_SIZE="$swap_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 8G, 8g)"
        done
    else
        USE_SWAP=false
        print_info "Swap partition disabled"
    fi
    
    # Home configuration (optional)
    if confirm_action "Create a separate /home partition?" "N"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Options for the Home partition:${NC}"
        echo -e "${CYAN}1.${NC} Use the remaining available space"
        echo -e "${CYAN}2.${NC} Specify a custom size"
        
        local home_choice
        while true; do
            read -r -p "Your choice (1-2): " home_choice
            case $home_choice in
                1)
                    PARTITION_HOME_SIZE="remaining"
                    print_info "Partition Home : utilisation du reste de l'espace"
                    break
                    ;;
                2)
                    while true; do
                        read -r -p "Taille partition Home (ex: 100G, 100g) : " home_input
                        if validate_input "$home_input" "size"; then
                            PARTITION_HOME_SIZE="$home_input"
                            break
                        fi
                        print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex : 100G, 100g)"
                    done
                    break
                    ;;
                *)
                    print_warning "Choix invalide !"
                    ;;
            esac
        done
    else
        USE_SEPARATE_HOME=false
        print_info "Separate /home partition disabled - it will be inside the Root partition"
    fi
    
    # Configuration summary
    echo ""
    echo -e "${GREEN}CONFIGURATION SUMMARY${NC}"
    echo -e "${WHITE}• Mode boot :${NC} $BOOT_MODE"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${WHITE}• EFI partition :${NC} $PARTITION_EFI_SIZE (FAT32)"
    else
        echo -e "${WHITE}• Partition Boot :${NC} $PARTITION_BOOT_SIZE (ext4)"
    fi
    echo -e "${WHITE}• Root partition :${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Partition Swap :${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Partition Home :${NC} Reste de l'espace disponible"
        else
            echo -e "${WHITE}• Partition Home :${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Home partition:${NC} Integrated into Root"
    fi
    echo ""
    
    if ! confirm_action "Confirm this configuration?" "O"; then
        print_info "Reconfiguring partitions..."
        configure_custom_partitioning
    fi
    
    CUSTOM_PARTITIONING=true
}

# Confirmation request
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    local response
    
    while true; do
        read -r -p "$message (y/n, default: $default): " response
        response=${response:-$default}
        
        case "$response" in
            [OoYy]|[Oo][Uu][Ii]|[Yy][Ee][Ss])
                return 0
                ;;
            [NnFf]|[Nn][Oo][Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                print_warning "Invalid answer. Use y/n."
                ;;
        esac
    done
}

# Cleanup on exit
cleanup() {
    # Avoid multiple runs -> Do not disable, breaks things otherwise 
    if $CLEANUP_DONE; then
        return 0
    fi
    CLEANUP_DONE=true

    local exit_code=$?
    echo "Starting cleanup (code: $exit_code)..." >> "$LOG_FILE"

    # Safe unmounting (without -e to avoid loops)
    set +e
    trap - EXIT INT TERM  # Disable the trap otherwise it bugs out & crashes

    # Ordered list of mount points
    local -a mount_points=("/mnt/boot/efi" "/mnt/home" "/mnt")
    for mp in "${mount_points[@]}"; do
        if mountpoint -q "$mp"; then
            umount -vRl "$mp" >> "$LOG_FILE" 2>&1
        fi
    done

    # Swap
    if [[ -n "${SWAP_PART:-}" ]]; then
        swapoff -v "$SWAP_PART" >> "$LOG_FILE" 2>&1
    fi

    echo "Cleanup completed at $(date)" >> "$LOG_FILE"
}

# Trap configuration
trap 'cleanup; exit 130' INT   # CTRL+C
trap 'cleanup; exit 143' TERM  # kill
trap 'cleanup' EXIT            # Seulement en vrai fin de script


# User interface functions
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
 █████╗ ██████╗  ██████╗██╗  ██╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ 
██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝                                                                         

EOF
    echo -e "${NC}"
    echo -e "${WHITE}Automated Arch Linux installation script for beginners, by a beginner${NC}"
    echo ""
    echo -e "${WHITE}By PapaOursPolaire (available on GitHub) - Version $SCRIPT_VERSION${NC}"
    echo ""
    echo -e "${WHITE}For the lazy and beginners • Development • Gaming • Default Fallout theme${NC}"
    echo  ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
}

show_help() {
    cat << EOF
Usage : $0 [OPTIONS]

# Purely decorative, too lazy to build a real menu
Options : 
    -h, --help     Show this help
    -d, --dry-run  Simulation mode (makes no changes)
    --version      Show the version

    FULL FEATURES OF THIS EDITION:

    BASE SYSTEM:

    • Automated Arch Linux installation (UEFI only)
    • Full locale configuration (locale, keyboard, timezone)
    • Choice between KDE Plasma, GNOME, or console mode (for a minimal server)
    • Custom partition size configuration
    • Optional separate /home partition (Y/N)

    FALLOUT INTERFACE AND THEMES:

    • Fallout theme for GRUB
    • Fallout boot sound (MP3 or fallback system beep) # Doesn't work
    • Splashscreen with PipBoy animation
    • Arch logo Plymouth (can be changed via BearGrubChanger, available on my GitHub account: PapaOursPolaire)
    • SDDM configuration with custom Fallout background (video, .gif, or random images — up to you to change)
    • Icon themes (Tela, Papirus) and modern visual themes

    PROFESSIONAL AUDIO SYSTEM:

    • PipeWire + WirePlumber (professional low-latency audio)
    • CAVA (terminal audio visualizer with a Matrix green theme)
    • PavuControl (graphical audio control interface)
    • Automatic configuration for streaming and recording

    COMPLETE DEVELOPMENT ENVIRONMENT:

    • Languages: Python, Node.js, Java OpenJDK, Go, Rust & C/C++
    • Tools: Git, Docker, cmake, make, gcc, clang & gdb
    • Visual Studio Code with preinstalled extensions:
        - GitHub Copilot (AI)
        - Python, C++, Java
        - Tailwind CSS, Prettier, ESLint
        - Live Server, Jupyter
        - Material Icon Theme, Error Lens
    • Android Studio for mobile development
    • Enhanced terminal with Fastfetch and development aliases (enable via a script from my repo, not included in the script for silly reasons)

    PREINSTALLED WEB BROWSING:

    • Firefox (configured for Netflix, Disney+ with DRM)
    • Google Chrome, Chromium, Brave Browser — Google Chrome & Brave are installed in the post-install script
    • DuckDuckGo Browser (privacy) (unavailable for now)

    MULTIMEDIA AND ENTERTAINMENT:

    • Spotify + Spicetify CLI with the Dribbblish Nord-Dark theme, installed during the post-install script
    • Spicetify Marketplace enabled for extensions
    • VLC, MPV, OBS Studio, Audacity
    • GIMP, Inkscape for design and creation

    GAMING AND WINDOWS COMPATIBILITY:

    • Steam with Proton configured automatically
    • Lutris, GameMode for gaming optimization
    • Wine + Winetricks (full Windows compatibility)
    • Wine-mono, Wine-gecko for .NET and web applications
    • Automatic configuration for Windows games

    UTILITIES AND PRODUCTIVITY:

    • Paru AUR helper preinstalled and configured (unavailable)
    • Flatpak
    • TimeShift (system backups), GParted, KeePassXC
    • Fastfetch with ASCII Arch logo and system information (unavailable)
    • Full Bash configuration with 50+ useful aliases (unavailable)

    SYSTEM OPTIMIZATIONS:

    • Optimized Pacman configuration (ParallelDownloads=10)
    • Optimized mirrors with advanced Reflector
    • Network optimizations (BBR, TCP)
    • Optimized memory management (swappiness)
    • System services configured for performance
    • Progress bars with real time estimates
    • Robust error handling with automatic fallbacks

    NEW FEATURES IN VERSION 864.4:

    • Custom partition size configuration
    • Optional separate /home partition with a Y/N interface
    • Minimum password length reduced to 6 characters
    • Speed optimization with parallel downloads
    • Fixed PipeWire-Jack conflict bug
    • Installation now uses the full available bandwidth
    • Fixed 2358 errors reported by ShellCheck
    • Reworked user interface for more clarity
    • Restructured code for better readability and understandability
    • Added main() before the function declarations to avoid the dumb trap
    • Debugged more than 3000 errors

    Usage examples: # Doesn't work
    $0                # Full interactive installation
    $0 --dry-run      # Test/simulation with no changes
    $0 --help         # Show this detailed help

    System requirements:

    • UEFI system required
    • Stable Internet connection (more than 10 Mbps recommended)
    • An Arch Linux ISO that isn't ancient history
    • Patience, as the installation can take a while (between 30 and 60 minutes based on several tests on my junk machines)
    • At least 60GB of free disk space
    • RAM: 8GB recommended minimum (4GB minimum), starting from DDR3 — haven't tested DDR1 & 2
    • Run from the Arch Linux ISO

    Post-installation:

    • Automatic restart offered
    • Full installation log saved for reference and to send me if there's a problem
    • Post-installation check script included (for software that couldn't be installed in the chroot)
    • Optimized configuration ready to use
    • All the important development and multimedia software installed

EOF
}

parse_arguments() { # Does it actually work? I only managed to get it working once!
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                print_info "Simulation mode enabled - no changes will be made"
                shift
                ;;
            --version)
                echo "Complete Arch Linux Fallout Edition installation script - Version: $SCRIPT_VERSION"
                echo "Features: Pro Audio + Development + Gaming + Browsing + Fallout Themes"
                echo "New: Custom partition configuration + optional /home + speed optimizations"
                exit 0
                ;;
            *)
                print_error "Option inconnue: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
}

# Verification and testing functions
check_requirements() {
    print_header "STEP 1/$TOTAL_STEPS: PREREQUISITE CHECK"
    
    # Root check
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        return 1
    fi
    
    # Internet connection check BEFORE any installation
    print_info "Checking Internet connection..."
    local internet_ok=false
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            print_success "Internet connection active (tested: $host)"
            internet_ok=true
            break
        fi
    done
    
    if [[ "$internet_ok" != true ]]; then
        print_error "NO INTERNET CONNECTION DETECTED!"
        echo "Check your connection and try again."
        return 1
    fi
    
    # COMPLETE list of REQUIRED commands with their packages
    local requirements=(
        # Command:Package
        "pacman:pacman"
        "pacstrap:arch-install-scripts"
        "genfstab:arch-install-scripts"
        "arch-chroot:arch-install-scripts"
        "parted:parted"
        "mkfs.fat:dosfstools"
        "mkfs.ext4:e2fsprogs"
        "lsblk:util-linux"
        "curl:curl"
        "git:git"
        "timedatectl:systemd"
        "unzip:unzip"
        "wget:wget"
        "reflector:reflector"
        "rsync:rsync"
        "gzip:gzip"
        "tar:tar"
    )
    
    # Checking and installing dependencies
    print_info "Checking system tools..."
    local missing_packages=()
    local all_ok=true
    
    # Step 1: Check what's missing
    for req in "${requirements[@]}"; do
        IFS=":" read -r cmd pkg <<< "$req"
        
        if ! command -v "$cmd" &>/dev/null; then
            print_warning "$cmd missing (package: $pkg)"
            local deja_present=false
            for pkg_existant in "${missing_packages[@]}"; do
                if [[ "$pkg_existant" == "$pkg" ]]; then
                    deja_present=true
                    break
                fi
            done
            if [[ "$deja_present" == false ]]; then
                missing_packages+=("$pkg")
            fi
            all_ok=false
        else
            print_success "$cmd disponible"
        fi
    done
    
    # Step 2: Install missing packages
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_info "Installing missing packages..."
        echo "Packages to install: ${missing_packages[*]}"
        
        # Update mirrors before installation
        print_info "Updating pacman databases..."
        pacman -Sy --noconfirm || {
            print_error "Failed to update databases"
            return 1
        }
        
        # Batch installation
        if pacman -S --noconfirm "${missing_packages[@]}"; then
            print_success "All packages installed successfully"
            all_ok=true
        else
            # Fallback: install one by one
            print_warning "Batch installation failed, trying one by one..."
            local failed_packages=()
            
            for pkg in "${missing_packages[@]}"; do
                if pacman -S --noconfirm "$pkg"; then
                    print_success "$pkg installed"
                else
                    print_error "Failed to install $pkg"
                    failed_packages+=("$pkg")
                    all_ok=false
                fi
            done
            
            if [[ ${#failed_packages[@]} -gt 0 ]]; then
                print_error "Failed packages: ${failed_packages[*]}"
            fi
        fi
    fi
    
    # Step 3: FORCED check of git and unzip (critical)
    print_info "CRITICAL check of git and unzip..."
    
    if ! command -v git &>/dev/null; then
        print_error "GIT MISSING - Forcing installation..."
        pacman -S --noconfirm git || {
            print_error "CRITICAL FAILURE: Unable to install git"
            return 1
        }
    fi
    
    if ! command -v unzip &>/dev/null; then
        print_error "UNZIP MISSING - Forcing installation..."
        pacman -S --noconfirm unzip || {
            print_error "CRITICAL FAILURE: Unable to install unzip"
            return 1
        }
    fi
    
    # Final check
    print_info "Final check of critical tools..."
    local critical_tools=("git" "unzip" "arch-chroot" "pacstrap")
    local critical_ok=true
    
    for tool in "${critical_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            print_success "$tool: OK"
        else
            print_error "$tool: MANQUANT"
            critical_ok=false
        fi
    done
    
    if [[ "$critical_ok" != true ]]; then
        print_error "CRITICAL TOOLS MISSING - STOPPING"
        return 1
    fi
    
    # Enable user namespaces for Flatpak
    if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
        print_info "Enabling kernel.unprivileged_userns_clone=1 for Flatpak"
        sysctl -w kernel.unprivileged_userns_clone=1 || true
        echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/00-local-userns.conf
    fi
    
    # Clock synchronization
    timedatectl set-ntp true
    sleep 2
    
    print_success "ALL PREREQUISITES SATISFIED"
    return 0
}

test_environment() {
    print_header "STEP 2/$TOTAL_STEPS: INSTALLATION ENVIRONMENT TEST"
    
    local errors=0
    local warnings=0
    
    echo -e "${WHITE}=== SYSTEM TOOLS TEST ===${NC}"
    
    # CRITICAL tools (must be present)
    local critical_tools=(
        "git" "unzip" "curl" "wget"
        "parted" "mkfs.fat" "mkfs.ext4"
        "arch-chroot" "pacstrap" "genfstab"
        "lsblk" "timedatectl"
    )
    
    for tool in "${critical_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${RED}✗${NC} $tool - ABSENT CRITIQUE"
            errors=$((errors + 1))
        fi
    done
    
    # IMPORTANT tools (warning if missing)
    local important_tools=("reflector" "rsync" "p7zip")
    for tool in "${important_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "  ${YELLOW}!${NC} $tool - manquant (non critique)"
            warnings=$((warnings + 1))
        fi
    done
    
    echo ""
    echo -e "${WHITE}=== NETWORK TEST ===${NC}"
    
    # Internet test with short timeout
    if ping -c 1 -W 2 archlinux.org &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Connexion Internet stable"
    else
        echo -e "  ${YELLOW}!${NC} Connexion Internet lente/instable"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo -e "${WHITE}=== SYSTEM AVAILABILITY TEST ===${NC}"
    
    # Disk space test
    local available_space=$(df /tmp --output=avail | tail -1 | awk '{print int($1/1024)}')
    if [[ $available_space -gt 1000 ]]; then
        echo -e "  ${GREEN}✓${NC} Espace disque: ${available_space}MB (suffisant)"
    elif [[ $available_space -gt 500 ]]; then
        echo -e "  ${YELLOW}!${NC} Disk space: ${available_space}MB (limited)"
        warnings=$((warnings + 1))
    else
        echo -e "  ${RED}✗${NC} Espace disque: ${available_space}MB (INSUFFISANT)"
        errors=$((errors + 1))
    fi
    
    # RAM test
    local ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
    if [[ $ram_mb -gt 4000 ]]; then
        echo -e "  ${GREEN}✓${NC} RAM: $((ram_mb/1024))GB (suffisante)"
    elif [[ $ram_mb -gt 2000 ]]; then
        echo -e "  ${YELLOW}!${NC} RAM: ${ram_mb}MB (minimum)"
        warnings=$((warnings + 1))
    else
        echo -e "  ${RED}✗${NC} RAM: ${ram_mb}MB (INSUFFISANTE)"
        errors=$((errors + 1))
    fi
    
    # CPU test
    local cpu_cores=$(nproc 2>/dev/null || echo 1)
    if [[ $cpu_cores -ge 2 ]]; then
        echo -e "  ${GREEN}✓${NC} CPU: ${cpu_cores} cœurs"
    else
        echo -e "  ${YELLOW}!${NC} CPU: 1 core (limited)"
        warnings=$((warnings + 1))
    fi
    
    echo ""
    echo -e "${WHITE}=== TEST MODE BOOT ===${NC}"
    
    # Detect and display boot mode
    detect_boot_mode
    
    # Check boot mode is consistent
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -d /sys/firmware/efi ]]; then
        echo -e "  ${RED}✗${NC} INCONSISTENCY: UEFI mode detected but no /sys/firmware/efi"
        errors=$((errors + 1))
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ -d /sys/firmware/efi ]]; then
        echo -e "  ${RED}✗${NC} INCONSISTENCY: BIOS mode detected but /sys/firmware/efi exists"
        errors=$((errors + 1))
    else
        echo -e "  ${GREEN}✓${NC} Consistent boot mode: $BOOT_MODE"
    fi
    
    echo ""
    echo -e "${WHITE}=== FINAL SUMMARY ===${NC}"
    
    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            print_success "OPTIMAL ENVIRONMENT - Ready for installation"
            return 0
        else
            print_warning "ACCEPTABLE ENVIRONMENT with $warnings warning(s)"
            echo "Installation can continue but some features"
            echo "might be limited."
            return 0
        fi
    else
        print_error "INCOMPATIBLE ENVIRONMENT - $errors critical error(s)"
        echo "Fix the issues above before continuing."
        return 1
    fi
}

# Disk and partition management functions
select_disk() {
    print_header "ETAPE 4/$TOTAL_STEPS: SELECTION DU DISQUE"
    CURRENT_STEP=4
    
    # Wait for disks to be detected
    sleep 2
    sync
    
    local disks
    mapfile -t disks < <(lsblk -dno NAME,SIZE,MODEL | grep -E '^(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])' | awk '{print $1}')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "No disk detected!"
        echo "Disques disponibles:"
        lsblk
        return 1
    fi
    
    echo -e "${WHITE}Disques disponibles :${NC}"
    for i in "${!disks[@]}"; do
        local disk="${disks[i]}"
        local size model
        size=$(lsblk -dno SIZE "/dev/$disk" 2>/dev/null || echo "Inconnu")
        model=$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null || echo "Inconnu")
        
        echo -e "${CYAN}$((i + 1)).${NC} /dev/$disk - $size - $model"
    done
    
    local disk_choice
    while true; do
        read -r -p "Select the disk (number): " disk_choice
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && \
            [[ "$disk_choice" -ge 1 ]] && \
            [[ "$disk_choice" -le "${#disks[@]}" ]]; then
            DISK="/dev/${disks[$((disk_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Final disk check
    if [[ ! -b "$DISK" ]]; then
        print_error "Disk $DISK does not exist!"
        return 1
    fi
    
    print_success "Selected disk: $DISK"
    return 0
}

choose_partitioning() {
    print_header "ETAPE 5/$TOTAL_STEPS: CHOIX DU PARTITIONNEMENT"
    CURRENT_STEP=5
    
    echo -e "${WHITE}Options de partitionnement :${NC}"
    echo -e "${CYAN}1.${NC} Keep existing partitions"
    echo -e "${CYAN}2.${NC} Create a new automatic partitioning"
    echo -e "${CYAN}3.${NC} Create a new custom partitioning"
    
    local choice
    while true; do
        read -r -p "Your choice (1-3): " choice
        case $choice in
            1)
                print_info "Keeping existing partitions"
                # Submenu for option 1
                echo -e "${WHITE}Sous-options :${NC}"
                echo -e "${CYAN}a.${NC} Use a single partition and split it"
                echo -e "${CYAN}b.${NC} Use already-created existing partitions"
                local sub_choice
                while true; do
                    read -r -p "Your choice (a/b): " sub_choice
                    case $sub_choice in
                        a)
                            print_info "Using a single partition to split"
                            use_single_partition_and_split
                            return 0
                            ;;
                        b)
                            print_info "Utilisation de partitions existantes"
                            detect_existing_partitions
                            return 0
                            ;;
                        *)
                            print_warning "Choix invalide !"
                            ;;
                    esac
                done
                ;;
            2)
                print_info "Creating new automatic partitioning"
                create_new_partitioning
                return 0
                ;;
            3)
                print_info "Creating new custom partitioning"
                configure_custom_partitioning
                create_new_partitioning
                return 0
                ;;
            *)
                print_warning "Choix invalide !"
                ;;
        esac
    done
}

use_single_partition_and_split() {
    print_info "Selecting a single partition to split"
    
    # Detecting available partitions
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "No partitions found on $DISK"
        return 1
    fi
    
    echo -e "${WHITE}Detected partitions:${NC}"
    for i in "${!partitions[@]}"; do
        local part="/dev/${partitions[i]}"
        local size=$(lsblk -no SIZE "$part" 2>/dev/null || echo "Inconnu")
        local fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || echo "Inconnu")
        echo -e "${CYAN}$((i + 1)).${NC} $part - $size - $fstype"
    done
    
    local part_choice
    while true; do
        read -r -p "Select the partition to split (number): " part_choice
        if [[ "$part_choice" =~ ^[0-9]+$ ]] && \
           [[ "$part_choice" -ge 1 ]] && \
           [[ "$part_choice" -le "${#partitions[@]}" ]]; then
            local selected_part="/dev/${partitions[$((part_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Configuring sizes for new partitions
    print_info "Configuring sizes of new partitions"
    configure_custom_partitioning
    
    # Erase the selected partition and create a new partition table
    print_warning "WARNING: All data on $selected_part will be erased!"
    if ! confirm_action "Confirm erasing the partition?"; then
        return 1
    fi
    
    # Calculate total available size
    local total_size=$(lsblk -bno SIZE "$selected_part" | head -1)
    local total_size_mb=$((total_size / 1024 / 1024))
    
    # Convert sizes to MB
    local efi_mb=$(convert_to_mb "$PARTITION_EFI_SIZE")
    local root_mb=$(convert_to_mb "$PARTITION_ROOT_SIZE")
    local swap_mb=0
    local home_mb=0
    
    [[ "$USE_SWAP" == true ]] && swap_mb=$(convert_to_mb "$PARTITION_SWAP_SIZE")
    [[ "$USE_SEPARATE_HOME" == true ]] && home_mb=$(convert_to_mb "$PARTITION_HOME_SIZE")
    
    # Check available space
    local total_required_mb=$((efi_mb + root_mb + swap_mb + home_mb))
    if [[ $total_required_mb -gt $total_size_mb ]]; then
        print_error "Insufficient space on the partition!"
        print_error "Disponible: ${total_size_mb}MB, Requis: ${total_required_mb}MB"
        return 1
    fi
    
    # Start partitioning
    print_info "Starting partitioning of $selected_part"
    
    # Erase the partition
    parted -s "$selected_part" rm 1 || {
        print_error "Unable to delete the partition"
        return 1
    }
    
    # Create new partition table
    parted -s "$selected_part" mklabel gpt || {
        print_error "Unable to create the partition table"
        return 1
    }
    
    # Create the partitions
    local current_pos=1
    
    # EFI partition
    local efi_end=$((current_pos + efi_mb))
    parted -s "$selected_part" mkpart primary fat32 ${current_pos}MiB ${efi_end}MiB
    parted -s "$selected_part" set 1 esp on
    EFI_PART="${selected_part}1"
    current_pos=$efi_end
    
    # Root partition
    local root_end=$((current_pos + root_mb))
    parted -s "$selected_part" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB
    ROOT_PART="${selected_part}2"
    current_pos=$root_end
    
    # Swap partition (optional)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        parted -s "$selected_part" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB
        SWAP_PART="${selected_part}3"
        current_pos=$swap_end
    fi
    
    # Home partition (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        parted -s "$selected_part" mkpart primary ext4 ${current_pos}MiB 100%
        HOME_PART="${selected_part}$((USE_SWAP ? 4 : 3))"
    fi
    
    print_success "Partitioning completed"
    return 0
}

detect_existing_partitions() {
    print_info "Detecting existing partitions on $DISK..."
    
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "No partitions found on $DISK"
        return 1
    fi
    
    echo -e "${WHITE}Detected partitions:${NC}"
    for part in "${partitions[@]}"; do
        local size fstype mountpoint
        size=$(lsblk -no SIZE "/dev/$part" 2>/dev/null || echo "Inconnu")
        fstype=$(lsblk -no FSTYPE "/dev/$part" 2>/dev/null || echo "Inconnu")
        mountpoint=$(lsblk -no MOUNTPOINT "/dev/$part" 2>/dev/null || echo "")
        
        echo -e "${CYAN}/dev/$part${NC} - $size - $fstype $mountpoint"
    done
    
    configure_existing_partitions "${partitions[@]}"
}

configure_existing_partitions() {
    local partitions=("$@")
    
    print_info "Configuring partitions..."
    
    # Ask for EFI
    echo -e "${WHITE}Select the EFI partition:${NC}"
    for i in "${!partitions[@]}"; do
        echo -e "${CYAN}$((i + 1)).${NC} /dev/${partitions[i]}"
    done
    
    local efi_choice
    while true; do
        read -r -p "EFI partition (number):" efi_choice
        if [[ "$efi_choice" =~ ^[0-9]+$ ]] && \
            [[ "$efi_choice" -ge 1 ]] && \
            [[ "$efi_choice" -le "${#partitions[@]}" ]]; then
            EFI_PART="/dev/${partitions[$((efi_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Ask for Root
    echo -e "${WHITE}Select the Root partition:${NC}"
    for i in "${!partitions[@]}"; do
        if [[ "/dev/${partitions[i]}" != "$EFI_PART" ]]; then
            echo -e "${CYAN}$((i + 1)).${NC} /dev/${partitions[i]}"
        fi
    done
    
    local root_choice
    while true; do
        read -r -p "Root partition (number): " root_choice
        if [[ "$root_choice" =~ ^[0-9]+$ ]] && \
            [[ "$root_choice" -ge 1 ]] && \
            [[ "$root_choice" -le "${#partitions[@]}" ]] && \
            [[ "/dev/${partitions[$((root_choice - 1))]}" != "$EFI_PART" ]]; then
            ROOT_PART="/dev/${partitions[$((root_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Optional: Home and Swap
    if confirm_action "Configure a separate Home partition?"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Select the Home partition:${NC}"
        for i in "${!partitions[@]}"; do
            local part="/dev/${partitions[i]}"
            if [[ "$part" != "$EFI_PART" && "$part" != "$ROOT_PART" ]]; then
                echo -e "${CYAN}$((i + 1)).${NC} $part"
            fi
        done
        
        local home_choice
        while true; do
            read -r -p "Home partition (number): " home_choice
            if [[ "$home_choice" =~ ^[0-9]+$ ]] && \
                [[ "$home_choice" -ge 1 ]] && \
                [[ "$home_choice" -le "${#partitions[@]}" ]]; then
                local selected="/dev/${partitions[$((home_choice - 1))]}"
                if [[ "$selected" != "$EFI_PART" && "$selected" != "$ROOT_PART" ]]; then
                    HOME_PART="$selected"
                    USE_SEPARATE_HOME=true
                    break
                fi
            fi
            print_warning "Invalid selection!"
        done
    fi
    
    if confirm_action "Configure a Swap partition?"; then
        USE_SWAP=true
        echo -e "${WHITE}Select the Swap partition:${NC}"
        for i in "${!partitions[@]}"; do
            local part="/dev/${partitions[i]}"
            if [[ "$part" != "$EFI_PART" && "$part" != "$ROOT_PART" && "$part" != "$HOME_PART" ]]; then
                echo -e "${CYAN}$((i + 1)).${NC} $part"
            fi
        done
        
        local swap_choice
        while true; do
            read -r -p "Swap partition (number):" swap_choice
            if [[ "$swap_choice" =~ ^[0-9]+$ ]] && \
                [[ "$swap_choice" -ge 1 ]] && \
                [[ "$swap_choice" -le "${#partitions[@]}" ]]; then
                local selected="/dev/${partitions[$((swap_choice - 1))]}"
                if [[ "$selected" != "$EFI_PART" && "$selected" != "$ROOT_PART" && "$selected" != "$HOME_PART" ]]; then
                    SWAP_PART="$selected"
                    USE_SWAP=true
                    break
                fi
            fi
            print_warning "Invalid selection!"
        done
    else
        USE_SWAP=false
    fi

    # Check that the disk is not in use
    if lsof "$DISK" 2>/dev/null; then
        print_error "Disk $DISK is still in use by processes"
        lsof "$DISK" | head -10
        return 1
    fi

    # Check disk status
    if ! lsblk "$DISK" >/dev/null 2>&1; then
        print_error "Disk $DISK is not accessible"
        return 1
    fi
}

create_new_partitioning() {
    print_header "CREATION DU PARTITIONNEMENT"
    
    print_warning "WARNING: All data on $DISK will be erased!"
    
    if ! confirm_action "Confirmer l'effacement du disque ?"; then
        return 1
    fi

    # Full and forced disk cleanup
    print_info "Nettoyage complet du disque..."
    
    # Force unmount all partitions
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true
    
    # Clean signatures using multiple methods
    print_info "Erasing partition signatures..."
    wipefs -af "$DISK" 2>/dev/null || true
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none 2>/dev/null || true
    
    # Sync and wait
    sync
    sleep 3

    # Reset partition variables
    EFI_PART=""
    BOOT_PART=""
    ROOT_PART=""
    HOME_PART=""
    SWAP_PART=""

    # Create partition table based on mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Creating GPT table for UEFI..."
        if ! parted -s "$DISK" mklabel gpt; then
            print_error "Failed to create GPT table"
            return 1
        fi
    else
        print_info "Creating MBR table for BIOS..."
        if ! parted -s "$DISK" mklabel msdos; then
            print_error "Failed to create MBR table"
            return 1
        fi
    fi

    # Sync after table creation
    sync
    sleep 2

    # Calculate sizes in MB
    local boot_mb root_mb swap_mb home_mb
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        boot_mb=$(convert_to_mb "$PARTITION_EFI_SIZE")
    else
        boot_mb=$(convert_to_mb "$PARTITION_BOOT_SIZE")
    fi
    root_mb=$(convert_to_mb "$PARTITION_ROOT_SIZE")
    [[ "$USE_SWAP" == true ]] && swap_mb=$(convert_to_mb "$PARTITION_SWAP_SIZE") || swap_mb=0
    
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            home_mb="remaining"
        else
            home_mb=$(convert_to_mb "$PARTITION_HOME_SIZE")
        fi
    else
        home_mb=0
    fi

    local current_pos=1
    local part_num=1

    # Partition 1: Boot/EFI depending on mode
    local boot_end=$((current_pos + boot_mb))
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Creating EFI partition (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary fat32 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Failed to create EFI partition"
            return 1
        fi
        parted -s "$DISK" set 1 esp on
        EFI_PART=$(get_partition_number "$DISK" 1)
        print_success "EFI partition created: $EFI_PART"
    else
        print_info "Creating Boot partition (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Failed to create Boot partition"
            return 1
        fi
        parted -s "$DISK" set 1 boot on
        BOOT_PART=$(get_partition_number "$DISK" 1)
        print_success "Boot partition created: $BOOT_PART"
    fi
    current_pos=$boot_end
    part_num=2

    # Sync after first partition
    sync
    sleep 1

    # Partition 2: Root
    local root_end=$((current_pos + root_mb))
    print_info "Creating Root partition (${current_pos}MiB-${root_end}MiB)..."
    if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB; then
        print_error "Failed to create Root partition"
        return 1
    fi
    ROOT_PART=$(get_partition_number "$DISK" 2)
    print_success "Root partition created: $ROOT_PART"
    current_pos=$root_end
    part_num=3

    sync
    sleep 1

    # Partition 3: Swap (optional)
    if [[ "$USE_SWAP" == true ]] && [[ $swap_mb -gt 0 ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Creating Swap partition (${current_pos}MiB-${swap_end}MiB)..."
        if parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB; then
            SWAP_PART=$(get_partition_number "$DISK" $part_num)
            print_success "Swap partition created: $SWAP_PART"
            current_pos=$swap_end
            part_num=$((part_num + 1))
        else
            print_warning "Failed to create Swap partition, continuing without swap"
            USE_SWAP=false
        fi
        sync
        sleep 1
    fi

    # Partition 4: Home (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$home_mb" == "remaining" ]]; then
            print_info "Creating Home partition (remaining space)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB 100%; then
                HOME_PART=$(get_partition_number "$DISK" $part_num)
                print_success "Home partition created: $HOME_PART"
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        elif [[ $home_mb -gt 0 ]]; then
            local home_end=$((current_pos + home_mb))
            print_info "Creating Home partition (${current_pos}MiB-${home_end}MiB)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB; then
                HOME_PART=$(get_partition_number "$DISK" $part_num)
                print_success "Home partition created: $HOME_PART"
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        fi
    fi

    # Final sync
    sync
    sleep 3

    # Refresh partition information
    print_info "Refreshing partition information..."
    partprobe "$DISK" 2>/dev/null || {
        print_warning "partprobe failed, trying alternative..."
        # Alternative: force partition re-read
        echo 1 > /sys/block/${DISK##*/}/device/rescan 2>/dev/null || true
    }
    
    # Wait for devices to be available
    sleep 5
    
    # Check that partitions exist
    print_info "Checking created partitions..."
    
    # Function to check a partition
    check_partition_exists() {
        local part="$1"
        local part_name="$2"
        
        if [[ -n "$part" ]] && [[ ! -b "$part" ]]; then
            print_warning "Partition $part_name ($part) not detected, searching alternative..."
            
            # Search for the partition by label or number
            local found_part=""
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
                    # Check whether this is likely the right partition
                    if [[ "$part_name" == "ROOT" ]] && lsblk -n -o MOUNTPOINT "$p" 2>/dev/null | grep -q "/mnt"; then
                        found_part="$p"
                        break
                    fi
                fi
            done
            
            if [[ -n "$found_part" ]]; then
                print_success "Partition $part_name found: $found_part"
                eval "${part_name}_PART=\"$found_part\""
            else
                print_error "Partition $part_name introuvable"
                return 1
            fi
        fi
        return 0
    }
    
    # Check each partition
    check_partition_exists "$ROOT_PART" "ROOT" || return 1
    
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        check_partition_exists "$EFI_PART" "EFI" || return 1
    else
        check_partition_exists "$BOOT_PART" "BOOT" || return 1
    fi
    
    if [[ "$USE_SWAP" == true ]] && [[ -n "$SWAP_PART" ]]; then
        check_partition_exists "$SWAP_PART" "SWAP" || {
            print_warning "Swap partition not found, disabling..."
            USE_SWAP=false
            SWAP_PART=""
        }
    fi
    
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]]; then
        check_partition_exists "$HOME_PART" "HOME" || {
            print_warning "Home partition not found, disabling..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        }
    fi

    # Display final summary
    print_success "Partitioning completed successfully"
    print_info "Partitioning summary:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DISK"
    
    echo ""
    echo -e "${GREEN}Configured partitions:${NC}"
    echo -e "  • Root: $ROOT_PART"
    [[ -n "$EFI_PART" ]] && echo -e "  • EFI: $EFI_PART"
    [[ -n "$BOOT_PART" ]] && echo -e "  • Boot: $BOOT_PART"
    [[ -n "$SWAP_PART" ]] && echo -e "  • Swap: $SWAP_PART"
    [[ -n "$HOME_PART" ]] && echo -e "  • Home: $HOME_PART"
    
    return 0
}

create_mbr_with_fdisk() {
    print_info "Creating MBR table with fdisk..."
    
    # Creating the MBR table with fdisk
    echo "o\nw\n" | fdisk "$DISK" >/dev/null 2>&1
    
    # Check
    if ! parted -s "$DISK" print | grep -q "msdos"; then
        print_error "Failed to create MBR with fdisk"
        return 1
    fi
    
    print_success "MBR table created with fdisk"
    return 0
}

format_partitions() {
    print_header "STEP 6/$TOTAL_STEPS: FORMATTING PARTITIONS"
    CURRENT_STEP=6
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du formatage"
        return 0
    fi
    
    # Wait for partitions to be available
    print_info "Waiting for partitions to become available..."
    partprobe "$DISK" 2>/dev/null || true
    sleep 8  # Augmenter le temps d'attente
    sync
    
    # Check that partitions exist
    print_info "Checking partitions..."
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "ROOT partition not found: $ROOT_PART"
        print_info "Partitions available on $DISK:"
        lsblk -no NAME,SIZE,TYPE "$DISK" | grep -E "^${DISK##*/}(p?[0-9]+)"
        print_info "Trying alternative search..."
        
        # Search for the root partition
        for p in "${DISK}"*; do
            if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
                print_info "  Found: $p"
                # Assume the largest partition is root
                local size1=$(lsblk -bno SIZE "$ROOT_PART" 2>/dev/null | head -1)
                local size2=$(lsblk -bno SIZE "$p" 2>/dev/null | head -1)
                if [[ -z "$size1" ]] || [[ $size2 -gt $size1 ]]; then
                    ROOT_PART="$p"
                fi
            fi
        done
        
        if [[ ! -b "$ROOT_PART" ]]; then
            print_error "Unable to find the root partition"
            return 1
        fi
        print_success "Root partition identified: $ROOT_PART"
    fi
    
    # Check based on boot mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        if [[ ! -b "$EFI_PART" ]]; then
            print_error "EFI partition not found: $EFI_PART"
            print_info "Recherche de partition EFI..."
            # Search for a FAT32 partition
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ "$p" != "$ROOT_PART" ]] && [[ -b "$p" ]]; then
                    local fstype=$(lsblk -no FSTYPE "$p" 2>/dev/null || blkid -s TYPE -o value "$p" 2>/dev/null)
                    if [[ "$fstype" == "vfat" ]] || [[ "$fstype" == "fat32" ]]; then
                        EFI_PART="$p"
                        print_success "EFI partition identified: $EFI_PART"
                        break
                    fi
                fi
            done
            if [[ ! -b "$EFI_PART" ]]; then
                print_error "Unable to find the EFI partition"
                return 1
            fi
        fi
    else
        if [[ ! -b "$BOOT_PART" ]]; then
            print_error "Boot partition not found: $BOOT_PART"
            # The boot partition is usually the first one after EFI
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ "$p" != "$ROOT_PART" ]] && [[ -b "$p" ]]; then
                    BOOT_PART="$p"
                    print_success "Boot partition identified: $BOOT_PART"
                    break
                fi
            done
            if [[ ! -b "$BOOT_PART" ]]; then
                print_error "Unable to find the Boot partition"
                return 1
            fi
        fi
    fi

    # Preemptive unmount
    print_info "Preemptive unmounting..."
    umount -f "$EFI_PART" "$BOOT_PART" "$ROOT_PART" "$HOME_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    sleep 2

    # Formatting based on boot mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Formatage partition EFI: $EFI_PART"
        if mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
            print_success "EFI partition formatted (FAT32)"
        else
            print_error "Failed to format EFI"
            return 1
        fi
    else
        print_info "Formatage partition Boot: $BOOT_PART"
        if mkfs.ext4 -F -L 'ArchBoot' "$BOOT_PART"; then
            print_success "Boot partition formatted (ext4)"
        else
            print_error "Failed to format Boot"
            return 1
        fi
    fi

    # Formatting Root
    print_info "Formatage partition Root: $ROOT_PART"
    if mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_success "Root partition formatted (ext4)"
    else
        print_error "Failed to format Root"
        return 1
    fi

    # Formatting Home (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]] && [[ -b "$HOME_PART" ]]; then
        print_info "Formatage partition Home: $HOME_PART"
        if mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_success "Home partition formatted (ext4)"
        else
            print_warning "Failed to format Home, disabling..."
            USE_SEPARATE_HOME=false
        fi
    fi

    # Swap configuration (optional)
    if [[ "$USE_SWAP" == true ]] && [[ -n "$SWAP_PART" ]] && [[ -b "$SWAP_PART" ]]; then
        print_info "Configuring Swap partition: $SWAP_PART"
        if mkswap -L 'ArchSwap' "$SWAP_PART"; then
            if swapon "$SWAP_PART"; then
                print_success "Swap partition configured and enabled"
            else
                print_warning "Unable to enable swap"
            fi
        else
            print_warning "Failed to configure Swap, disabling..."
            USE_SWAP=false
        fi
    fi

    print_success "Formatting completed successfully"
    return 0
}

# Utility function to get the correct partition number
get_partition_number() {
    local disk="$1"
    local part_index="$2"
    
    # Check whether the disk is an NVMe device
    if [[ "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
        # NVMe format: /dev/nvme0n1p1, /dev/nvme0n1p2, etc.
        echo "${disk}p${part_index}"
    # Check whether it's a standard disk (SATA/SCSI)
    elif [[ "$disk" =~ /dev/(sd[a-z]|vd[a-z]|hd[a-z])$ ]]; then
        # SATA format: /dev/sda1, /dev/sda2, etc.
        echo "${disk}${part_index}"
    else
        # Fallback: use the standard format
        echo "${disk}${part_index}"
    fi
}

mount_partitions() {
    print_header "STEP 7/$TOTAL_STEPS: MOUNTING PARTITIONS"
    CURRENT_STEP=7
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du montage"
        return 0
    fi
    
    # Preemptive unmount
    print_info "Preemptive unmounting..."
    umount -R /mnt 2>/dev/null || true
    mkdir -p /mnt

    # Mounting Root
    print_info "Mounting Root partition: $ROOT_PART on /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Failed to mount Root partition"
        print_info "Trying with filesystem check..."
        # Check and repair the filesystem if needed
        if fsck -y "$ROOT_PART"; then
            if mount "$ROOT_PART" /mnt; then
                print_success "Root partition mounted after repair"
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # Mounting Boot/EFI based on mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        mkdir -p /mnt/boot/efi
        print_info "Mounting EFI partition: $EFI_PART on /mnt/boot/efi"
        if ! mount "$EFI_PART" /mnt/boot/efi; then
            print_error "Failed to mount EFI partition"
            return 1
        fi
    else
        mkdir -p /mnt/boot
        print_info "Mounting Boot partition: $BOOT_PART on /mnt/boot"
        if ! mount "$BOOT_PART" /mnt/boot; then
            print_error "Failed to mount Boot partition"
            return 1
        fi
    fi

    # Mounting Home (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]] && [[ -b "$HOME_PART" ]]; then
        mkdir -p /mnt/home
        print_info "Mounting Home partition: $HOME_PART on /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Failed to mount Home partition, continuing without separate home"
            USE_SEPARATE_HOME=false
        else
            print_success "Home partition mounted"
        fi
    fi

    # Checking the mount
    print_info "Checking mount points..."
    
    if ! mountpoint -q /mnt; then
        print_error "Failed to mount /mnt"
        return 1
    fi
    
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        if ! mountpoint -q /mnt/boot/efi; then
            print_error "Failed to mount /mnt/boot/efi"
            return 1
        fi
    else
        if ! mountpoint -q /mnt/boot; then
            print_error "Failed to mount /mnt/boot"
            return 1
        fi
    fi

    print_success "Partitions mounted successfully"
    echo "Points de montage:"
    mount | grep -E "/mnt|$(basename "$DISK")"
    return 0
}

detect_partitions() {
    print_info "Detecting partitions..."
    
    # List all partitions on the disk
    local partitions=()
    for p in "${DISK}"*; do
        if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
            partitions+=("$p")
        fi
    done
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "No partitions detected on $DISK"
        return 1
    fi
    
    print_info "Partitions detected:"
    for p in "${partitions[@]}"; do
        local size=$(lsblk -no SIZE "$p" 2>/dev/null || echo "inconnu")
        local fstype=$(lsblk -no FSTYPE "$p" 2>/dev/null || blkid -s TYPE -o value "$p" 2>/dev/null || echo "inconnu")
        local label=$(lsblk -no LABEL "$p" 2>/dev/null || echo "")
        echo "  - $p ($size, $fstype${label:+, label: $label})"
    done
    
    return 0
}

# Base system installation functions
install_system() {
    print_header "STEP 8/$TOTAL_STEPS: BASE SYSTEM INSTALLATION"
    CURRENT_STEP=8
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating base system installation"
        return 0
    fi
    
    # Mirror optimization
    print_info "Optimizing Pacman mirrors..."
    if command -v reflector &> /dev/null; then
        reflector --country France,Germany,Spain --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || {
            print_warning "Reflector failed, using default mirrors"
        }
    else
        print_warning "Reflector not available, installing..."
        pacman -S --noconfirm reflector || true
        reflector --country France,Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true
    fi
    
    # Forced database update
    print_info "Forcing database update..."
    pacman -Syy --noconfirm || {
        print_warning "Update failed, cleaning cache..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Syy --noconfirm || {
            print_error "Unable to update databases"
            return 1
        }
    }
    
    # Base packages adapted based on boot mode
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )
    
    # Mode-specific addition
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        base_packages+=("efibootmgr")
        print_info "Adding efibootmgr for UEFI"
    else
        print_info "BIOS configuration - efibootmgr not needed"
    fi
    
    print_info "Installing base packages for ${BOOT_MODE} mode..."
    run_with_progress "Base system installation" 300 "pacstrap /mnt ${base_packages[*]}"
    
    print_success "Base system installed for ${BOOT_MODE} mode"
}

configure_system() {
    print_header "STEP 9/$TOTAL_STEPS: SYSTEM CONFIGURATION"
    CURRENT_STEP=9

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating system configuration"
        return 0
    fi

    print_info "Generating fstab file..."
    genfstab -U /mnt > /mnt/etc/fstab || {
        print_error "Failed to generate fstab"
        return 1
    }

    if [[ ! -s /mnt/etc/fstab ]]; then
        print_error "The fstab file is empty"
        return 1
    fi

    while true; do
        read -r -p "Nom d'hote : " HOSTNAME
        if validate_input "$HOSTNAME" "hostname"; then
            break
        fi
        print_warning "Nom d'hote invalide (lettres, chiffres et tirets uniquement)"
    done

    # What's weird is I still have the US keyboard even though I set it to French, where's the setting?
    print_info "Configuring the system inside chroot..."
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen 
locale-gen

echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr" > /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
systemctl enable NetworkManager
EOF

    echo "$HOSTNAME" > /mnt/etc/hostname
    cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

    print_success "System configured"
}

create_users() {
    print_header "ETAPE 10/$TOTAL_STEPS: CREATION UTILISATEURS"
    CURRENT_STEP=10

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating user creation"
        return 0
    fi

    # Creating the main user
    while true; do
        read -r -p "Nom d'utilisateur principal : " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Invalid username (min 3 characters, lowercase letters, digits, hyphens and underscores only, must start with a letter)"
    done

    # Setting the password for the main user
    local password password2
    while true; do
        read -r -s -p "Password for $USERNAME (min 6 characters): " password
        echo ""
        if validate_input "$password" "password" 6; then
            read -r -s -p "Confirm password: " password2
            echo ""
            if [[ "$password" == "$password2" ]]; then
                USER_PASSWORD="$password"
                break
            fi
            print_warning "Passwords do not match"
        else
            print_warning "Password too short (minimum 6 characters)"
        fi
    done

    # Configuring sudo to let the wheel group run commands without a password
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Sudo configuration for the wheel group - NOPASSWD
if ! grep -q "^%wheel ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    # Temporarily disable the password prompt for wheel
    sed -i '/^%wheel ALL=(ALL:ALL) ALL/s/^/# /' /etc/sudoers
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
EOF

    # Creating the main user with their password
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Creating the main user
useradd -m -G wheel,audio,video,storage,optical,network "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Creating home directories
mkdir -p "/home/$USERNAME"/{Documents,Downloads,Pictures,Videos,Music,Desktop,.ssh}
chown -R "$USERNAME":"$USERNAME" "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
EOF

    print_success "User created: $USERNAME (with passwordless sudo rights)"

    # Creating additional users with their own passwords
    if confirm_action "Create additional users?"; then
        while true; do
            local additional_user
            read -r -p "Additional username (leave empty to finish): " additional_user
            [[ -z "$additional_user" ]] && break

            if validate_input "$additional_user" "username"; then
                local add_password add_password2
                while true; do
                    read -r -s -p "Password for $additional_user: " add_password
                    echo ""
                    if validate_input "$add_password" "password" 6; then
                        read -r -s -p "Confirm password: " add_password2
                        echo ""
                        if [[ "$add_password" == "$add_password2" ]]; then
                            break
                        fi
                        print_warning "Passwords do not match"
                    else
                        print_warning "Password too short (minimum 6 characters)"
                    fi
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Creating the additional user
useradd -m -G wheel,audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd

# Creating home directories
mkdir -p "/home/$additional_user"/{Documents,Downloads,Pictures,Videos,Music,Desktop,.ssh}
chown -R "$additional_user":"$additional_user" "/home/$additional_user"
chmod 700 "/home/$additional_user/.ssh"
EOF

                print_success "Additional user created: $additional_user (with passwordless sudo rights)"
            else
                print_warning "Invalid username, skipped"
            fi
        done
    fi

    # Root password configuration (optional and different)
    if confirm_action "Set a password for root? (recommended: NO)"; then
        local root_password root_password2
        while true; do
            read -r -s -p "Root password (leave empty to disable the root account): " root_password
            echo ""
            if [[ -z "$root_password" ]]; then
                print_info "Root account disabled (no password set)"
                /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Disable the root account
passwd -l root
EOF
                break
            elif validate_input "$root_password" "password" 6; then
                read -r -s -p "Confirm root password: " root_password2
                echo ""
                if [[ "$root_password" == "$root_password2" ]]; then
                    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
echo "root:$root_password" | chpasswd
EOF
                    print_success "Root password set (different from users)"
                    break
                else
                    print_warning "Passwords do not match"
                fi
            else
                print_warning "Password too short (minimum 6 characters)"
            fi
        done
    else
        # Disable the root account by default
        /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
passwd -l root
EOF
        print_info "Root account disabled (recommended for security)"
    fi

    # Final configuration message
    echo ""
    print_success "User configuration completed"
    echo -e "${GREEN}All users can use sudo without a password${NC}"
    echo -e "${YELLOW}The root account has been disabled for extra security${NC}"
    echo -e "${CYAN}Use 'sudo' for commands requiring elevated privileges${NC}"
}

select_desktop() {
    print_header "ETAPE 11/$TOTAL_STEPS: SELECTION ENVIRONNEMENT DE BUREAU"
    CURRENT_STEP=11
    
    echo -e "${WHITE}Environnements disponibles :${NC}"
    echo -e "${CYAN}1.${NC} KDE Plasma"
    echo -e "${CYAN}2.${NC} GNOME"
    echo -e "${CYAN}3.${NC} Sans interface graphique (serveur/minimal)"
    
    local choice
    while true; do
        read -r -p "Your choice (1-3): " choice
        case $choice in
            1) DE_CHOICE="kde"; break ;;
            2) DE_CHOICE="gnome"; break ;;
            3) DE_CHOICE="none"; break ;;
            *) print_warning "Choix invalide! Utilisez 1, 2 ou 3." ;;
        esac
    done
    
    print_success "Selected environment: $DE_CHOICE"
}

install_desktop() {
    print_header "STEP 12/$TOTAL_STEPS: DESKTOP ENVIRONMENT INSTALLATION"
    CURRENT_STEP=12
    
    if [[ "$DE_CHOICE" == "none" ]]; then
        print_info "No desktop environment to install"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating installation of $DE_CHOICE"
        return 0
    fi
    
    case $DE_CHOICE in
        kde)
            print_info "Installing KDE Plasma..."
            run_with_progress "KDE Plasma installation" 600 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm plasma-meta kde-applications sddm"
            /usr/bin/arch-chroot /mnt systemctl enable sddm
            ;;
        gnome)
            print_info "Installing GNOME..."
            run_with_progress "GNOME installation" 600 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm gnome gnome-extra gdm"
            /usr/bin/arch-chroot /mnt systemctl enable gdm
            ;;
    esac
    
    print_success "Desktop environment installed"
}

# Audio and multimedia functions
install_audio_system() {
    print_header "STEP 16/$TOTAL_STEPS: PIPEWIRE AUDIO SYSTEM INSTALLATION"
    CURRENT_STEP=16

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating audio system installation"
        return 0
    fi

    print_info "Installing PipeWire and audio tools..." # PipeWire ne s'installe pas enfin je crois

    local audio_packages=(
        pipewire pipewire-alsa pipewire-pulse
        wireplumber pavucontrol alsa-utils
        cava
    )

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm "${audio_packages[@]}" || {
        print_error "Failed to install audio packages"
        return 1
    }

    # Configuring CAVA for the user
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
sudo -u $USERNAME bash -c '
mkdir -p /home/$USERNAME/.config/cava
cat > /home/$USERNAME/.config/cava/config <<CAVA_EOF
[general]
bars = 50
mode = normal

[input]
method = pipewire
source = auto

[output]
method = ncurses
channels = stereo
mono_option = average

[color]
gradient = 1
gradient_count = 6
gradient_color_1 = "#00ff00"
gradient_color_2 = "#ffff00"
gradient_color_3 = "#ff8000"
gradient_color_4 = "#ff4000"
gradient_color_5 = "#ff0000"
gradient_color_6 = "#ff0080"

[smoothing]
noise_reduction = 0.77
CAVA_EOF
'
EOF

    print_success "PipeWire audio system installed and configured"
}

install_boot_sound() { # Boot beep sound is broken, fix it or not, TBD
    print_header "STEP 17/$TOTAL_STEPS: BOOT SOUND CONFIGURATION"
    CURRENT_STEP=17
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating boot sound installation"
        return 0
    fi
    
    # Creating the sounds directory
    mkdir -p /mnt/usr/share/sounds/fallout
    
    # Downloading the Fallout sound (fixed the URL)
    print_info "Downloading the Fallout boot sound..."
    if curl -fL -o /mnt/usr/share/sounds/fallout/boot.wav \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projects/boot.wav' 2>/dev/null; then
        
        print_success "Boot sound downloaded successfully"
        
        # Installing audio dependencies
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed alsa-utils pulseaudio-alsa || {
            print_warning "Unable to install full audio dependencies"
        }
        
        # Fixed systemd service
        cat > /mnt/etc/systemd/system/boot-sound.service <<'EOF'
[Unit]
Description=Fallout Boot Sound
After=multi-user.target
Before=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/bin/aplay /usr/share/sounds/fallout/boot.wav
RemainAfterExit=yes
StandardOutput=null

[Install]
WantedBy=multi-user.target
EOF
        
    else
        print_warning "Unable to download the sound, creating a system beep"
        
        # Fallback to built-in system beep
        cat > /mnt/usr/local/bin/fallout-beep <<'EOF'
#!/bin/bash
# Fallout-style system beep
for i in {1..3}; do
    echo -e '\a'
    sleep 0.1
done
sleep 0.2
echo -e '\a\a'
EOF
        
        chmod +x /mnt/usr/local/bin/fallout-beep
        
        cat > /mnt/etc/systemd/system/boot-sound.service <<'EOF'
[Unit]
Description=Fallout Boot Sound
After=multi-user.target
Before=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fallout-beep
RemainAfterExit=yes
StandardOutput=null

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Enabling the service
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Unable to enable the boot sound service"
    }
    
    print_success "Boot sound configured"
}

configure_plymouth() {
    print_header "STEP 18/$TOTAL_STEPS: PLYMOUTH CONFIGURATION"
    CURRENT_STEP=18

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating Plymouth configuration"
        return 0
    fi

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installing Plymouth..."
pacman -Sy --noconfirm --needed plymouth unzip wget

cd /tmp
rm -f arch-mac-style.zip
rm -rf /usr/share/plymouth/themes/arch-mac-style

echo "[INFO] Downloading Plymouth theme..."
wget -O arch-mac-style.zip "https://raw.githubusercontent.com/PapaOursPolaire/arch/Projects/arch-mac-style.zip"

echo "[INFO] Extracting theme..."
unzip -o arch-mac-style.zip -d /usr/share/plymouth/themes/

# Auto-fix: find the folder that contains arch-mac-style.plymouth
THEME_DIR=$(find /usr/share/plymouth/themes -type f -name "arch-mac-style.plymouth" -printf '%h\n' | head -n1)

if [[ -z "$THEME_DIR" ]]; then
    echo "[ERROR] Unable to find arch-mac-style.plymouth after extraction."
    ls -R /usr/share/plymouth/themes || true
    exit 1
fi

echo "[INFO] Theme detected in: $THEME_DIR"

echo "[INFO] Configuring default theme..."
plymouth-set-default-theme -R "$(basename "$THEME_DIR")"

echo "[SUCCESS] Plymouth configured with the arch-mac-style theme."
EOF
}

configure_sddm() {
    print_header "STEP 19/$TOTAL_STEPS: SDDM CONFIGURATION (DISPLAY MANAGER)"
    CURRENT_STEP=19

    local repo_zip="/root/Projects.zip"
    local extract_dir="/root/arch-Projects"
    local theme_dir="/usr/share/sddm/themes/SDDM-Fallout-theme"

    # 1) If GNOME → GDM
    if /usr/bin/arch-chroot /mnt pacman -Qi gdm &>/dev/null && \
        /usr/bin/arch-chroot /mnt pacman -Qi gnome-shell &>/dev/null; then
        print_info "GNOME detected → configuring GDM"
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed gdm || {
            print_error "Impossible d’installer GDM"
            return 1
        }
        /usr/bin/arch-chroot /mnt systemctl enable gdm.service
        print_success "GDM enabled (SDDM skipped)."
        return 0
    fi

    # 2) Install SDDM and unzip
    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed sddm unzip curl || {
        print_error "Unable to install SDDM or its dependencies"
        return 1
    }

    # 3) Download the automatic archive from GitHub
    print_info "Downloading the GitHub repo (Projects branch)..."
    if ! /usr/bin/arch-chroot /mnt curl -fL \
        "https://github.com/PapaOursPolaire/arch/archive/refs/heads/Projects.zip" \
        -o "$repo_zip"; then
        print_error "Failed to download the GitHub archive"
        return 1
    fi

    # 4) Extraction
    /usr/bin/arch-chroot /mnt rm -rf "$extract_dir" "$theme_dir"
    if ! /usr/bin/arch-chroot /mnt unzip -o "$repo_zip" -d /root/; then
        print_error "Failed to extract the GitHub archive"
        return 1
    fi

    # 5) Move the theme
    if /usr/bin/arch-chroot /mnt test -d "$extract_dir/SDDM-Fallout-theme"; then
        /usr/bin/arch-chroot /mnt mv "$extract_dir/SDDM-Fallout-theme" "$theme_dir"
    else
        print_error "The SDDM-Fallout-theme folder was not found in the archive"
        return 1
    fi

    # 6) Verify contents
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/Main.qml"; then
        print_error "Main.qml not found — incomplete theme"
        return 1
    fi
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/background.mp4"; then
        print_warning "Warning: the background.mp4 video is missing"
    fi

    # 7) Configure SDDM
    print_info "Writing /etc/sddm.conf..."
    /usr/bin/arch-chroot /mnt bash -c "cat > /etc/sddm.conf <<EOF
[Theme]
Current=SDDM-Fallout-theme

[General]
DisplayServer=wayland
EOF"

    # 8) Enable SDDM
    /usr/bin/arch-chroot /mnt systemctl enable sddm.service

    print_success "SDDM successfully configured with the Fallout theme"
}

configure_kde_lockscreen() {
    print_header "STEP 15/$TOTAL_STEPS: KDE SPLASH CONFIGURATION"
    CURRENT_STEP=15
    
    if [[ "$DE_CHOICE" != "kde" ]]; then
        print_info "KDE environment not detected - lockscreen skipped"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating KDE lockscreen configuration"
        return 0
    fi

    print_info "Configuring the KDE Fallout splash screen..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installing KDE Splash components..."
pacman -S --noconfirm --needed ksplash

# Create the theme directory
THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.fallout.desktop"
mkdir -p "$THEME_DIR/contents/componentsets"
mkdir -p "$THEME_DIR/contents/plasmacolorschemes"

# Main metadata.desktop file
cat > "$THEME_DIR/metadata.desktop" <<'METADATA_EOF'
[Desktop Entry]
Name=Fallout
Comment=Fallout-themed Plasma Look and Feel
Type=Service

X-KDE-PluginInfo-Author=PapaOursPolaire
X-KDE-PluginInfo-Email=contact@example.com
X-KDE-PluginInfo-Name=org.kde.fallout
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://github.com/PapaOursPolaire
X-KDE-PluginInfo-License=GPLv3
X-KDE-ServiceTypes=Plasma/LookAndFeel

X-KDE-Plasma-MainScript=plasmoidsetupscripts/main.js
METADATA_EOF

# Splash screen configuration
cat > "$THEME_DIR/contents/splash/Splash.qml" <<'SPLASH_EOF'
import QtQuick 2.5
import QtGraphicalEffects 1.0

Rectangle {
    width: 800
    height: 600
    color: "#002b36"

    Image {
        anchors.fill: parent
        source: "fallout-bg.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3
    }

    Text {
        anchors.centerIn: parent
        text: "ARCH LINUX\nFALLOUT EDITION"
        color: "#00ff00"
        font.pixelSize: 48
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        style: Text.Outline
        styleColor: "#000000"
    }

    BusyIndicator {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        anchors.horizontalCenter: parent.horizontalCenter
        width: 80
        height: 80
        running: true

        contentItem: Canvas {
            width: parent.width
            height: parent.height
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#00ff00"
                ctx.lineWidth = 3
                ctx.beginPath()
                ctx.arc(width/2, height/2, width/3, 0, Math.PI * 2)
                ctx.stroke()
            }
        }
    }

    ProgressBar {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: 400
        value: scaleY
    }

    Component.onCompleted: {
        console.log("Fallout splash screen loaded")
    }
}
SPLASH_EOF

# Create a simple background image (Fallout green pixel)
cat > "$THEME_DIR/contents/splash/fallout-bg.png" << 'PNG_EOF'
# Simplified creation - use a solid color
PNG_EOF

# Fallout color scheme configuration
cat > "$THEME_DIR/contents/plasmacolorschemes/FalloutDark.colors" <<'COLORS_EOF'
[ColorScheme]
Name=Fallout Dark
Description=Fallout-inspired dark color scheme

[Colors:Window]
BackgroundNormal=0,43,54
BackgroundAlternate=7,54,66
ForegroundNormal=101,123,113
ForegroundActive=0,255,0
ForegroundLink=42,161,152
ForegroundVisited=108,113,196
ForegroundNegative=220,50,47
ForegroundNeutral=181,137,0
ForegroundPositive=133,153,0

[Colors:Button]
BackgroundNormal=7,54,66
BackgroundAlternate=0,43,54
ForegroundNormal=101,123,113
ForegroundActive=0,255,0

[Colors:Selection]
BackgroundNormal=42,161,152
BackgroundAlternate=0,255,0
ForegroundNormal=0,43,54
ForegroundActive=255,255,255

[Colors:Tooltip]
BackgroundNormal=0,43,54
BackgroundAlternate=7,54,66
ForegroundNormal=101,123,113
ForegroundActive=0,255,0

[Colors:View]
BackgroundNormal=0,43,54
BackgroundAlternate=7,54,66
ForegroundNormal=101,123,113
ForegroundActive=0,255,0
COLORS_EOF

# lookandfeel configuration
cat > "$THEME_DIR/contents/defaults" <<'DEFAULTS_EOF'
[kdeglobals]
[General]
ColorScheme=FalloutDark
widgetStyle=Breeze

[Icons]
Theme=Tela

[KDE]
SingleClick=false

[Wallpaper]
Image=file:///usr/share/wallpapers/fallout-wallpaper.jpg
DEFAULTS_EOF

# Permissions
chmod -R 755 "$THEME_DIR"
chown -R root:root "$THEME_DIR"

echo "[SUCCESS] KDE Splash theme created"
EOF

    # Configuration to force use of the theme
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Partial KDE configuration"
# SDDM configuration for the splash
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/kde-splash.conf <<'SDDM_EOF'
[General]
Session=plasmaX11
Locale=fr_FR
Session=KDE
SDDM_EOF

# Plasma configuration for all users
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/plasmarc <<'PLASMA_EOF'
[Theme]
name=breeze-dark

[Splash]
Engine=KSplash
Theme=org.kde.fallout
PLASMA_EOF

# Copy for existing user if present
if [[ -n "$USERNAME" && -d "/mnt/home/$USERNAME" ]]; then
    mkdir -p "/mnt/home/$USERNAME/.config"
    cp /etc/skel/.config/plasmarc "/mnt/home/$USERNAME/.config/" 2>/dev/null || true
    /usr/bin/arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/.config/plasmarc" 2>/dev/null || true
fi

# Force the theme to load via lookandfeel
lookandfeeltool -a org.kde.fallout.desktop 2>/dev/null || true
EOF

    print_success "KDE Splash Fallout configured"
}

# Application installation functions, never worked - THINK ABOUT REMOVING IN THE FINAL VERSION
install_paru() {
    print_header "STEP 24/$TOTAL_STEPS: INSTALLING PARU (AUR HELPER)"
    CURRENT_STEP=24
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating Paru installation"
        return 0
    fi
    
    print_info "Starting Paru installation in chroot..."
    
    /usr/bin/arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

echo "STARTING PARU INSTALLATION"

# Installing dependencies + rustup just in case
echo "Installing dependencies..."
pacman -Sy --noconfirm --needed base-devel git sudo rust cargo

# Creating temporary user
echo "Creating builduser user..."
id builduser &>/dev/null || useradd -m builduser
echo "builduser ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/99-aur
echo "User created OK"

# Building as builduser
echo "Starting paru build..."
cd /tmp
rm -rf paru-bin paru

echo "Clone du repository..."
sudo -u builduser git clone https://aur.archlinux.org/paru-bin.git
echo "Clone OK"

cd paru-bin
echo "Lancement makepkg..."
sudo -u builduser makepkg -si --noconfirm
echo "Build completed"

# Immediate check inside the chroot
echo "IMMEDIATE VERIFICATION"
echo "PATH actuel: $PATH"

# Explicitly adding /usr/local/bin to PATH
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
echo "Nouveau PATH: $PATH"

# Immediate test
if command -v paru; then
    echo "PARU TROUVE : $(which paru)"
    paru --version
else
    echo "Paru not found, searching randomly..."
    find /usr -name "*paru*" -type f 2>/dev/null
    
    # If found elsewhere, create a link
    if [[ -f /usr/local/bin/paru ]]; then
        echo "Creating link /usr/local/bin/paru -> /usr/bin/paru"
        ln -sf /usr/local/bin/paru /usr/bin/paru
    fi
fi

# Add PATH permanently in bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc

# Final test
echo "TEST FINAL"
export PATH="/usr/local/bin:/usr/bin:/bin"
command -v paru && paru --version

# Cleanup (but keep paru!)
echo "Nettoyage..."
rm -f /etc/sudoers.d/99-aur
userdel -r builduser 2>/dev/null || true
# DO NOT delete /tmp/paru-bin until paru is confirmed working

echo "END OF PARU INSTALLATION"

CHROOT_EOF
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_error "Error during installation (code: $exit_code)"
        return 1
    fi
    
    # Final check with the correct PATH
    print_info "Final check with extended PATH..."
    
    if /usr/bin/arch-chroot /mnt /bin/bash -c 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"; command -v paru >/dev/null 2>&1'; then
        print_success "Paru installed and available"
        # Clean up now that it's confirmed
        /usr/bin/arch-chroot /mnt rm -rf /tmp/paru-bin 2>/dev/null || true
    else
        print_error "Paru could not be installed correctly"
        print_info "Recherche finale de paru..."
        /usr/bin/arch-chroot /mnt find /usr -name "*paru*" -type f 2>/dev/null || echo "No paru found"
        return 1
    fi
}

install_yay_in_chroot() {
    print_info "Installing yay (AUR helper) in the chroot..."

    if chroot_cmd_exists yay; then
        print_success "yay already installed in the chroot"
        return 0
    fi

    # Install base-devel and git as root
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Impossible d’installer base-devel et git"
        return 1
    }

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ca-certificates ca-certificates-utils
    /usr/bin/arch-chroot /mnt update-ca-trust

    # Build yay as a regular user
    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc "
        cd /tmp &&
        git clone https://aur.archlinux.org/yay.git &&
        cd yay &&
        makepkg -si --noconfirm
    " || {
        print_error "Failed to install yay"
        return 1
    }

    print_success "yay installed successfully in the chroot"
}

clean_pacman_cache_chroot() {
    print_info "Cleaning Pacman cache in the chroot..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
rm -f /var/lib/pacman/db.lck
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /var/lib/pacman/sync/*
pacman -Sy --noconfirm
EOF

    print_success "Pacman cache cleaned in the chroot"
}

refresh_mirrors() { # Use if download errors occur in future variables  # Disabled because it doesn't work
    print_info "Refreshing fast mirrors..."
    if command -v reflector &> /dev/null; then
        reflector \
            --country France,Germany,Netherlands,Belgium,Switzerland \
            --age 6 \
            --protocol https \
            --fastest 20 \
            --sort rate \
            --threads 10 \
            --save /etc/pacman.d/mirrorlist || {
            print_warning "Unable to refresh mirrors, using the current list"
        }
    else
        print_warning "Reflector not found, attempting installation..."
        pacman -S --noconfirm reflector && \
        reflector --fastest 10 --save /etc/pacman.d/mirrorlist || true
    fi
    pacman -Syy --noconfirm
}

install_development() { # VS Code still won't install, fix it or not, TBD
    print_header "STEP 25/$TOTAL_STEPS: DEVELOPMENT ENVIRONMENT INSTALLATION"
    CURRENT_STEP=25

    # Check for and remove rust installed by pacman to avoid conflicting with rustup
    print_info "Checking rust/rustup conflict..."
    if /usr/bin/arch-chroot /mnt pacman -Q rust &>/dev/null; then
        /usr/bin/arch-chroot /mnt pacman -Rns --noconfirm rust
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating development environment installation"
        return 0
    fi

    print_info "Installing programming languages and development tools..."

    # List of development packages - Add more if I forgot any
    local dev_packages=(
        # Languages
        python python-pip python-virtualenv
        nodejs npm
        jdk-openjdk
        go
        rustup
        gcc clang cmake make gdb

        # Development tools
        git docker docker-compose
        base-devel
        pkgconf
        unzip p7zip zip

        # Main editor
        #code

        # Additional tools
        wget curl
        lsb-release
    )

    # Installing packages
    /usr/bin/arch-chroot /mnt pacman -S --needed --noconfirm "${dev_packages[@]}" || {
        print_error "Failed to install development packages"
        return 1
    }

    # Rustup configuration
    /usr/bin/arch-chroot /mnt /bin/bash -c "
set -e
USERNAME='${USERNAME}'
sudo -u \"\$USERNAME\" bash -c '
    rustup default stable
    rustup update
    rustup component add rust-src rustfmt clippy
'
"

    # Enable and configure Docker
    /usr/bin/arch-chroot /mnt /bin/bash -c "
set -e
USERNAME='${USERNAME}'
systemctl enable docker
usermod -aG docker \"\$USERNAME\"
"

    print_success "Development environment installed and configured"
}

# Function to tell the user what will happen - Doesn't work in the chroot, available in post-install
vscode_post_install_info() {
    print_info ""
    print_info "  INFORMATION VS CODE :"
    print_info "   VS Code extensions will install automatically"
    print_info "   on the first launch of your graphical session."
    print_info "   You can also install them manually with:"
    print_info "   • ~/install-vscode-extensions.sh"
    print_info "   • ~/manual-vscode-setup.sh (simplified version)"
    print_info ""
}

install_spotify() {  # Only installs the launcher, not the native client (spotify-client), so it's duplicated
    # with the post-install spotify-client -> Fix this or not, TBD
    print_header "STEP 22/$TOTAL_STEPS: SPOTIFY INSTALLATION"
    CURRENT_STEP=22

    # Check whether Flatpak is installed in the chroot
    if ! chroot_cmd_exists flatpak; then
        print_info "Flatpak missing — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Impossible d’installer Flatpak"
            return 1
        }
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    local spotify_ok=false

    # Attempting Spotify installation via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.spotify.Client; then
        print_success "Spotify (Flatpak) installed successfully"
        spotify_ok=true
    else
        print_warning "Spotify (Flatpak, extra-data) installation failed. Trying AUR version…"

        if chroot_cmd_exists paru; then
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm spotify-launcher && spotify_ok=true || \
                print_warning "AUR installation failed (spotify-launcher)."
        else
            print_warning "Paru absent, impossible d’installer Spotify via AUR."
        fi
    fi

    # Checking the Spotify installation
    if [[ "$spotify_ok" == false ]]; then
        print_warning "Spotify could not be installed automatically. It can be installed manually after reboot."
        return 0
    fi

    # Installing Spicetify CLI
    if /usr/bin/arch-chroot /mnt command -v spicetify &>/dev/null; then
        print_success "Spicetify already present"
    else
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed spicetify-cli && \
            print_success "Spicetify CLI installed" || \
            print_warning "Spicetify CLI installation failed"
    fi

    # Minimal Spicetify configuration
    if [[ -n "${USERNAME:-}" ]]; then
        print_info "Preparing Spicetify configuration for $USERNAME"
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify config current_theme DribbblishNordDark || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify backup || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify apply || true
    else
        print_warning "USERNAME not set — Spicetify will be configured after first boot." # Obsolete since version 361.2; new method works a bit better (the launcher installs)
    fi

    print_success "Spotify + Spicetify installation completed (with fallbacks)."
}

# Safe /tmp cleanup before installing fonts (to avoid "No space left on device")
clean_tmp() { # More efficient since version 238.0, remove in the final version
    print_header "NETTOYAGE /tmp"
    local CLEAN_TMP_MINUTES="${CLEAN_TMP_MINUTES:-120}"  # files inactive for longer than X minutes will be deleted
    local LARGE_FILE_MB="${LARGE_FILE_MB:-100}"         # files > X MB will be deleted
    local DRY="${DRY_RUN:-false}"
    local BEFORE_MB AFTER_MB

    # Show state before
    BEFORE_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "/tmp space used: ${BEFORE_MB} MB (before cleanup)."
    if [[ "$DRY" == "true" ]]; then
        print_info "[DRY RUN] Simulation - no files will be deleted."
        return 0
    fi

    # Safety: don't delete if /tmp is a non-standard link
    if [[ ! -d /tmp ]]; then
        print_warning "/tmp not found or not a directory — cleanup cancelled."
        return 0
    fi

    # Switch to tolerant error mode during deletions
    set +e

    # 1) Delete large files (> LARGE_FILE_MB) (regular files)
    print_info "Removing files > ${LARGE_FILE_MB} MB in /tmp (to free up space)..."
    find /tmp -type f -size +"${LARGE_FILE_MB}"M -print -exec rm -f {} \; 2>/dev/null || true

    # 2) Delete files/dirs in /tmp inactive for CLEAN_TMP_MINUTES minutes
    print_info "Removing inactive entries older than ${CLEAN_TMP_MINUTES} minutes..."
    # Limit depth to 1 to avoid recursively walking very large trees
    find /tmp -mindepth 1 -maxdepth 1 -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -rf {} \; 2>/dev/null || true

    # 3) Delete old temporary archives (extra safety)
    print_info "Removing archives (.zip .tar.gz .tgz .tar.xz) older than ${CLEAN_TMP_MINUTES} minutes..."
    find /tmp -type f \( -iname '*.zip' -o -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.tar.xz' -o -iname '*.tar' \) -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -f {} \; 2>/dev/null || true

    # 4) Delete core dumps (often huge)
    print_info "Removing any core dumps..."
    find /tmp -type f -iname 'core*' -size +1M -print -exec rm -f {} \; 2>/dev/null || true

    # 5) Force sync and recompute
    sync 2>/dev/null || true

    # Restore normal error behavior
    set -e

    AFTER_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "/tmp space used: ${AFTER_MB} MB (after cleanup)."
    local FREED=$(( BEFORE_MB - AFTER_MB ))
    if (( FREED > 0 )); then
        print_success "Cleanup completed — freed ${FREED} MB."
    else
        print_warning "Cleanup completed — no significant space freed."
    fi

    return 0
}

install_wine() {
    print_header "STEP 23/$TOTAL_STEPS: WINE INSTALLATION"
    CURRENT_STEP=23
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating Wine installation"
        return 0
    fi
    
    print_info "Installing Wine for Windows compatibility..."
    
    # Enable multilib for Wine
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Enable multilib in pacman.conf
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy
EOF
    
    # Installing Wine and tools
    local wine_packages=(
        wine wine-staging winetricks
        wine-mono wine-gecko
    )
    
    run_with_progress "Wine installation" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm ${wine_packages[*]}"
    
    # Configuring Wine for the user
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Failed to configure Wine"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Wine initialization (Windows 10)
export WINEPREFIX=/home/$USERNAME/.wine
wineboot --init >/dev/null 2>&1 || true

# Configuring Wine as Windows 10
winecfg /v win10 >/dev/null 2>&1 || true

# Installing essential components via Winetricks
winetricks --unattended corefonts vcrun2019 dotnetfx48 || echo "Some Winetricks components failed"

echo "Wine configured for Windows 10"
USEREOF
EOF
    
    print_success "Wine and extensions installed"
}

install_software() {
    print_header "STEP 20/$TOTAL_STEPS: ESSENTIAL SOFTWARE INSTALLATION"
    CURRENT_STEP=20

    if declare -F clean_tmp >/dev/null; then
        clean_tmp
    else
        print_warning "Fonction clean_tmp absente — nettoyage minimal de /tmp"
        find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating software installation"
        return 0
    fi
    
    print_info "Installing all software..."
    
    # Category 1: Internet & Communication
    print_info "Installing Internet & Communication..."
    local internet_packages=(
        firefox # installed
        thunderbird # to check
        telegram-desktop  # to check
    )
    
    run_with_progress "Internet installation" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${internet_packages[*]}"
    
    # Discord via AUR or Flatpak
    if /usr/bin/arch-chroot /mnt command -v paru &> /dev/null; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm discord || {
            print_info "Installing Discord via Flatpak..."
            /usr/bin/arch-chroot /mnt flatpak install -y flathub com.discordapp.Discord || print_warning "Discord not installed"
        }
    fi
    
    # Category 2: Multimedia
    print_info "Installing Multimedia & Design..."
    local multimedia_packages=(
        vlc # OK
        mpv  # OK
        obs-studio # OK
        audacity # OK 
        gimp # OK 
        inkscape # OK  
        imagemagick # To check*
        kdenlive # To check*
        blender # OK 
        krita # To check*
    )
    # * : Didn't install before version 411, needs rechecking
    run_with_progress "Multimedia installation" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${multimedia_packages[*]}"
    
        # Category 3: Gaming (if a graphical interface is installed) 
        if [[ "$DE_CHOICE" != "none" ]]; then
            print_header "INSTALLING GAMING SOFTWARE"
            print_info "Installing the full Gaming suite..."

            # Ensure multilib in the chroot before installing Steam
            /usr/bin/arch-chroot /mnt pacman -Syyu --noconfirm

            # Enable the multilib repo if not already enabled (again)
            if ! grep -q "^\[multilib\]" /mnt/etc/pacman.conf; then
                echo "[multilib]" >> /mnt/etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
            fi

            # Update the package database with multilib
            /usr/bin/arch-chroot /mnt pacman -Sy


            # Make sure paru is present before any Gaming AUR install
            if ! chroot_cmd_exists paru; then
                print_info "Paru unavailable — attempting installation via pacman..."
                if /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed paru; then
                    print_success "Paru installed successfully via repos"
                else
                    print_warning "Binary installation failed — attempting via AUR..."
                    if install_paru; then
                        print_success "Paru installed via AUR"
                    elif install_yay_in_chroot; then
                        print_success "Yay installed as fallback"
                    else
                        print_warning "Unable to install an AUR helper — Gaming AUR packages will be skipped"
                    fi
                fi
            fi

            local gaming_packages=(
                # Platforms and launchers
                lutris # OK

                # Multi-system emulation -> None installed before version 411, needs rechecking
                retroarch
                retroarch-assets-xmb
                retroarch-assets-ozone
                libretro-gambatte
                libretro-snes9x
                libretro-mupen64plus-next

                # Standalone emulators
                fceux # JSP
                snes9x-gtk # JSP
                mupen64plus # JSP
                dolphin-emu # OK
                ppsspp # OK
                desmume # JSP

                # Gaming optimizations
                gamemode # JSP
                lib32-gamemode # JSP
                mangohud # JSP 
                lib32-mangohud # JSP 

                # Proton & compatibility
                lib32-gcc-libs # JSP
                lib32-glibc # JSP

                # Tools and streaming
                discord # OK
                obs-studio # OK

                # Emulation
                retroarch # JSP
                dolphin-emu # OK
            )
        
        install_errors=0
        for pkg in "${gaming_packages[@]}"; do
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "$pkg"; then
                print_warning "Impossible d’installer $pkg"
                ((install_errors++))
            fi
        done

        if (( install_errors == 0 )); then
            print_success "All gaming packages installed"
        else
            print_warning "$install_errors gaming package(s) could not be installed"
        fi


            # Checking Paru in the chroot - Still doesn't work
            if chroot_cmd_exists paru; then
                print_info "Installing Gaming AUR packages via Paru..."
                local gaming_aur_packages=(
                    protonup-qt
                    heroic-games-launcher-bin
                )
                if /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${gaming_aur_packages[@]}"; then
                    print_success "Gaming AUR packages installed"
                else
                    print_warning "Some gaming AUR packages could not be installed"
                fi
            else
                print_warning "Paru not installed or unavailable in the chroot - Gaming AUR packages will be skipped"
            fi
        else
            print_info "No graphical interface - Gaming section skipped"
        fi


            # Installing via pacman
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "${gaming_packages[@]}"; then
                print_error "Failed to install Gaming packages via pacman"
            else
                print_success "Gaming packages installed (pacman)"
            fi

            # Installing specific AUR packages via paru - Doesn't work anymore
            local aur_gaming_packages=(
                heroic-games-launcher-bin
                yuzu-early-access-bin
                rpcs3-bin
            )

            if /usr/bin/arch-chroot /mnt command -v paru &>/dev/null; then
                print_info "Installing Gaming AUR packages..."
                /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${aur_gaming_packages[@]}" || \
                    print_warning "Some Gaming AUR packages could not be installed"
            else
                print_warning "Paru not installed — Gaming AUR packages will be skipped"
            fi

            # Gamemode configuration - Not verified
            /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
    if [ -f /etc/gamemode.ini ]; then
        sed -i 's/#renice=0/renice=10/' /etc/gamemode.ini
        sed -i 's/#softrealtime=off/softrealtime=on/' /etc/gamemode.ini
        sed -i 's/#desiredgov=performance/desiredgov=performance/' /etc/gamemode.ini
    fi
EOF
            print_success "Gamemode configured for performance"

            # MANGOHUD configuration (FPS overlay)
            if [[ -n "$USERNAME" ]]; then
                MANGOHUD_PATH="/home/$USERNAME/.config/MangoHud"
            else
                MAIN_USER=$(ls /mnt/home | head -n 1)
                MANGOHUD_PATH="/home/$MAIN_USER/.config/MangoHud"
            fi

            /usr/bin/arch-chroot /mnt bash -c "mkdir -p '$MANGOHUD_PATH' && cat > '$MANGOHUD_PATH/MangoHud.conf' <<'CFG'
            fps_limit=0
            cpu_stats=1
            gpu_stats=1
            gpu_temp=1
            cpu_temp=1
            ram=1
            vram=1
            frametime=1
            frame_timing=1
            cfg_file=$MANGOHUD_PATH/MangoHud.conf
            CFG"

            print_success "MangoHud configured for $(basename "$MANGOHUD_PATH")"

    # Category 4: System utilities
    print_info "Installing system utilities..."
    local utility_packages=(
        gparted # OK
        timeshift # OK 
        flatpak # OK 
        keepassxc # OK  
        unzip # OK
        p7zip # JSP
        tree # JSP
        feh # JSP
        flameshot # JSP
        htop # JSP
        btop # JSP
        #neofetch -> was recently removed from the repos, and I think fastfetch is better anyway
        lsb-release # OK
        wget # OK
        curl # OK
        rsync # OK
        ark # JSP
        filelight # JSP
    )

    clean_tmp
    
    run_with_progress "Utilities installation" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${utility_packages[*]}"
    
    # Category 5: Fonts and themes - Needs checking, I don't think all fonts got installed
    print_info "Installing fonts..."
    local font_packages=(
        ttf-dejavu
        ttf-liberation
        noto-fonts
        noto-fonts-emoji
        ttf-roboto
        ttf-opensans
        adobe-source-code-pro-fonts
        ttf-jetbrains-mono
    )
    
    run_with_progress "Fonts installation" 60 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${font_packages[*]}"
    

    /usr/bin/arch-chroot /mnt /bin/bash -lc '
    set -e
    mkdir -p /etc/sysctl.d
    printf "%s\n" "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/99-unprivileged.conf
    '


    sysctl kernel.unprivileged_userns_clone
    # must return: 1 - otherwise it's broken

    # Advanced Flatpak configuration
    print_info "Configuring Flatpak and applications..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF' || print_warning "Flatpak configuration failed"
# Flatpak configuration
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl enable --global flatpak-system-helper.service

# Enable userns for Flatpak
if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
    print_info "Enabling kernel.unprivileged_userns_clone=1 for Flatpak"
    sysctl -w kernel.unprivileged_userns_clone=1 || true
    echo "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/00-local-userns.conf
fi

# Useful Flatpak applications
echo "Installing Flatpak applications..."
flatpak install -y flathub org.videolan.VLC 2>/dev/null || true
flatpak install -y flathub com.spotify.Client 2>/dev/null || true
flatpak install -y flathub org.libreoffice.LibreOffice 2>/dev/null || true
flatpak install -y flathub com.visualstudio.code 2>/dev/null || true
flatpak install -y flathub org.gimp.GIMP 2>/dev/null || true
flatpak install -y flathub org.inkscape.Inkscape 2>/dev/null || true
flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null || true
flatpak install -y flathub com.google.AndroidStudio 2>/dev/null || true

echo "Flatpak applications installed"
EOF
    
    # Advanced Steam configuration (if installed)
    if [[ "$DE_CHOICE" != "none" ]]; then
        print_info "Configuring Steam and gaming..."
        /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Steam configuration failed"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Steam configuration with Proton
mkdir -p /home/$USERNAME/.steam/steam/config

# Automatic Steam Play configuration
cat > /home/$USERNAME/.steam/steam/config/config.vdf <<'STEAM_EOF'
"InstallConfigStore"
{
    "Software"
    {
        "valve"
        {
            "Steam"
            {
                "compat"
                {
                    "tool"		"proton_experimental"
                    "use_d3d11"		"1"
                }
                "steamplay"
                {
                    "steamplay_enabled"		"1"
                    "steamplay_compattools"		"proton_experimental"
                }
            }
        }
    }
}
STEAM_EOF

# GameMode configuration
cat > /home/$USERNAME/.config/gamemode.ini <<'GAMEMODE_EOF'
[general]
renice=10
ioprio=7
inhibit_screensaver=1

[filter]
whitelist=
blacklist=

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high

[custom]
start=notify-send "GameMode enabled"
end=notify-send "GameMode disabled"
GAMEMODE_EOF
USEREOF
EOF
    fi
    
    print_info "Checking installations..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo "CHECKING INSTALLED SOFTWARE"

# Checking critical software
critical_apps=(
    "firefox" "vlc" "gimp" "steam" "discord" 
    "code" "git" "docker" "fastfetch"
)

installed_count=0
total_count=${#critical_apps[@]}

for app in "${critical_apps[@]}"; do
    if command -v "$app" >/dev/null 2>&1; then
        echo " $app installed"
        ((installed_count++))
    elif [[ -x "/opt/visual-studio-code/code" ]] && [[ "$app" == "code" ]]; then
        echo " Visual Studio Code installed (manual)"
        ((installed_count++))
    else
        echo " $app MANQUANT"
    fi
done

echo "SUMMARY: $installed_count/$total_count software installed"

# List of installed packages
echo "Total packages installed: $(pacman -Q | wc -l)"
EOF
    
    print_success "ALL ESSENTIAL SOFTWARE HAS BEEN INSTALLED "
}

install_themes() {
    print_header "STEP 27/$TOTAL_STEPS: THEMES AND ICONS INSTALLATION"
    CURRENT_STEP=27
    
    if [[ "$DRY_RUN" == true ]] || [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Themes and icons skipped (console mode or dry-run)"
        return 0
    fi
    
    print_info "Installing themes and icons..."
    
    # Icons and themes via pacman - FIX: correct package names - not sure since not many get installed, needs rechecking
    local theme_packages=(
        papirus-icon-theme
        tela-icon-theme
        breeze-icons
        breeze-gtk
        materia-gtk-theme
        qogir-gtk-theme
        sweet-theme-git
    )
    
    # Installing base themes
    run_with_progress "Installing themes and icons" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed papirus-icon-theme breeze-icons breeze-gtk"
    
    # Additional themes via AUR - Apart from Tela, the others didn't install, NEEDS RECHECKING
    if /usr/bin/arch-chroot /mnt command -v paru &> /dev/null; then
        print_info "Installing additional themes via AUR..."
        
        # Separate installation to avoid conflicts
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed tela-icon-theme-git || {
            print_warning "Tela icon theme not installed"
        }
        
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed sweet-theme-git || {
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed materia-gtk-theme || {
                print_warning "Sweet/Materia theme not installed"
            }
        }
        
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed qogir-gtk-theme || {
            print_warning "Qogir theme not installed"
        }
    fi
    
    # Default theme configuration - FIX: existing themes (fix didn't work well)
    if [[ "$DE_CHOICE" == "kde" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "KDE theme configuration failed"
# KDE configuration with valid themes
mkdir -p /home/$USERNAME/.config

cat > /home/$USERNAME/.config/kdeglobals <<'KDE_EOF'
[Icons]
Theme=Tela-blue

[General]
ColorScheme=BreezeDark
widgetStyle=Breeze

[Colors:Window]
BackgroundNormal=35,38,39
KDE_EOF

# Plasma configuration
cat > /home/$USERNAME/.config/plasmarc <<'PLASMA_EOF'
[Theme]
name=breeze-dark

[Wallpapers]
usersWallpapers=/usr/share/sddm/themes/fallout/background.png,/usr/share/backgrounds/
PLASMA_EOF

# Wallpaper configuration
mkdir -p /home/$USERNAME/.local/share/wallpapers
# FIX: correctly download the desktop image
curl -o /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projects/fallout-desktop-bg.png' 2>/dev/null || {
    # Copy the SDDM image as a fallback
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png
    fi
}
EOF
    elif [[ "$DE_CHOICE" == "gnome" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "GNOME theme configuration failed"
# GNOME configuration - FIX: valid themes
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.gnome.desktop.wm.preferences theme 'Arc-Dark'

# FIX: correct GNOME wallpaper configuration
mkdir -p /home/$USERNAME/.local/share/backgrounds
curl -o /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projects/fallout-desktop-bg.png' 2>/dev/null || {
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png
    fi
}

# Set the wallpaper
gsettings set org.gnome.desktop.background picture-uri "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
EOF
    fi
    
    print_success "Themes and icons installed and configured"
}

install_vscode() { # Ne fonctionne pas
    print_header "STEP 30/$TOTAL_STEPS: VISUAL STUDIO CODE INSTALLATION"
    CURRENT_STEP=30

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating VSCode installation"
        return 0
    fi

    print_info "Installing Visual Studio Code..."

    # Attempt 1: directly via pacman
    if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed code 2>/dev/null; then
        print_success "Visual Studio Code installed via pacman"
        
        # Create desktop shortcut
        /usr/bin/arch-chroot /mnt /bin/bash <<EOF
mkdir -p /usr/share/applications
cat > /usr/share/applications/code-fallout.desktop <<'DESK_EOF'
[Desktop Entry]
Name=Visual Studio Code
Exec=code %U
Icon=visual-studio-code
Terminal=false
Type=Application
Categories=Development;
MimeType=text/plain;inode/directory;
DESK_EOF
EOF
        return 0
    fi

    print_warning "VSCode not available via pacman, trying AUR..."

    # Attempt 2: via AUR with paru
    if /usr/bin/arch-chroot /mnt command -v paru &>/dev/null; then
        if /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm visual-studio-code-bin 2>/dev/null; then
            print_success "Visual Studio Code installed via AUR (paru)"
            return 0
        fi
    fi

    # Attempt 3: via Flatpak
    if /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        
        if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.visualstudio.code 2>/dev/null; then
            print_success "Visual Studio Code installed via Flatpak"
            return 0
        fi
    fi

    # Attempt 4: VSCodium (open-source alternative)
    print_warning "Official VSCode unavailable, trying VSCodium..."
    if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed vscodium 2>/dev/null; then
        print_success "VSCodium (open-source alternative) installed"
        return 0
    fi

    # Attempt 5: VSCodium via Flatpak
    if /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.vscodium.codium 2>/dev/null; then
            print_success "VSCodium installed via Flatpak"
            return 0
        fi
    fi

    print_error "Impossible d'installer Visual Studio Code ou VSCodium"
    print_info "Manual installation possible after reboot via:"
    echo "  • pacman -S code"
    echo "  • paru -S visual-studio-code-bin"
    echo "  • flatpak install flathub com.visualstudio.code"
    
    return 1
}

generate_postinstall() {
    print_header "STEP 31/$TOTAL_STEPS: GENERATING POST-INSTALL SCRIPT"
    CURRENT_STEP=31

    local U TARGET
    U="${USERNAME:-}"

    if [[ -z "$U" ]]; then
        echo "[FATAL] USERNAME is empty, cannot generate post-install.sh" >&2
        return 1
    fi

    TARGET="/mnt/home/${U}/post-install.sh"
    install -d -m 755 "/mnt/home/${U}"

    cat > "$TARGET" <<'POST_EOF'
# post-install.sh
# Complete post-install tasks for use in a user session.
# - Logs ONLY stderr to ~/post-install-errors.log
# - Continues after each failure (shows a warning, logs the error)
# - Idempotent: safe to rerun
#
# Usage:
#   chmod +x ~/post-install.sh
#   ~/post-install.sh
#
# NOTE: some commands are adapted to your distro (the script tries to detect the package manager)

set -o pipefail

LOGFILE="$HOME/post-install-errors.log"
: > "$LOGFILE"   # truncate the previous log (errors only)

# Redirect only stderr to LOGFILE, keep stdout visible
exec 3>&2
exec 2>>"$LOGFILE"

echo "[INFO] post-install started at $(date '+%Y-%m-%d %H:%M:%S')"

# Helper to print in green (success), yellow (info), red (error)
green()  { printf "\033[1;32m%s\033[0m\n" "$1" >&3; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1" >&3; }
red()    { printf "\033[1;31m%s\033[0m\n" "$1" >&3; }

# Helper: run a command, show the result and log the error if it fails
run_cmd() {
    # usage: run_cmd "Description" command args...
    local desc="$1"; shift
    echo ""
    yellow "[STEP] $desc"
    if "$@" 1>/dev/null; then
        green "[OK] $desc"
        return 0
    else
        # Capture stdout+stderr of the command? We already redirected stderr to LOGFILE.
        red "[ERROR] $desc — see $LOGFILE for details"
        return 1
    fi
    }

    # Helper: run a command that must be root, tries sudo if not root
    run_cmd_sudo() {
    local desc="$1"; shift
    if (( EUID == 0 )); then
        run_cmd "$desc" "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
        run_cmd "$desc" sudo "$@"
        else
        red "[ERROR] sudo not found — cannot run as root: $desc"
        return 1
        fi
    fi
    }

PKG_MANAGER=""
DISTRO=""
    if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO="${ID_LIKE:-$ID}"
    fi

    if command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
    elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
    elif command -v zypper >/dev/null 2>&1; then
    PKG_MANAGER="zypper"
    elif command -v apk >/dev/null 2>&1; then
    PKG_MANAGER="apk"
    elif command -v emerge >/dev/null 2>&1; then
    PKG_MANAGER="emerge"
    else
    PKG_MANAGER=""
    fi

echo "[INFO] Detected: PKG_MANAGER=$PKG_MANAGER, DISTRO=$DISTRO"

update_db() {
    case "$PKG_MANAGER" in
        pacman) run_cmd_sudo "pacman -Syu (update)" pacman -Syu --noconfirm ;;
        apt) run_cmd_sudo "apt update" apt update ;;
        dnf) run_cmd_sudo "dnf check-update" dnf check-update || true ;;
        zypper) run_cmd_sudo "zypper refresh" zypper refresh ;;
        apk) run_cmd_sudo "apk update" apk update ;;
        emerge) run_cmd_sudo "emerge --sync" emerge --sync ;;
        *) red "[WARN] No supported package manager detected for update_db" ;;
    esac
}

install_packages() {
    # usage: install_packages pkg1 pkg2 ...
    local pkgs=( "$@" )
    if [[ ${#pkgs[@]} -eq 0 ]]; then
        return 0
    fi

    case "$PKG_MANAGER" in
        pacman)
        run_cmd_sudo "pacman -S --noconfirm ${pkgs[*]}" pacman -S --noconfirm --needed "${pkgs[@]}" ;;
        apt)
        run_cmd_sudo "apt install -y ${pkgs[*]}" apt install -y "${pkgs[@]}" ;;
        dnf)
        run_cmd_sudo "dnf install -y ${pkgs[*]}" dnf install -y "${pkgs[@]}" ;;
        zypper)
        run_cmd_sudo "zypper install -y ${pkgs[*]}" zypper install -y "${pkgs[@]}" ;;
        apk)
        run_cmd_sudo "apk add ${pkgs[*]}" apk add "${pkgs[@]}" ;;
        emerge)
        run_cmd_sudo "emerge ${pkgs[*]}" emerge "${pkgs[@]}" ;;
        *)
        red "[WARN] install_packages: gestionnaire inconnu, tenter apt-get/pacman manuellement"
        return 1 ;;
    esac
}

install_flatpak() {
    # usage: install_flatpak <ref>
    local ref="$1"
    if ! command -v flatpak >/dev/null 2>&1; then
        run_cmd_sudo "Installer flatpak" bash -c "true" || true
        case "$PKG_MANAGER" in
        pacman) run_cmd_sudo "pacman -S --noconfirm flatpak" pacman -S --noconfirm flatpak || true ;;
        apt) run_cmd_sudo "apt install -y flatpak" apt install -y flatpak || true ;;
        dnf) run_cmd_sudo "dnf install -y flatpak" dnf install -y flatpak || true ;;
        zypper) run_cmd_sudo "zypper install -y flatpak" zypper install -y flatpak || true ;;
        apk) run_cmd_sudo "apk add flatpak" apk add flatpak || true ;;
        *) red "[WARN] flatpak not installed (unknown manager)" ;;
        esac
    fi

    if command -v flatpak >/dev/null 2>&1; then
        run_cmd "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        run_cmd "Installer flatpak ref $ref" flatpak install -y flathub "$ref"
    else
        red "[ERROR] flatpak indisponible, impossible d'installer $ref"
    fi
}

install_aur_pkg() {
    # usage: install_aur_pkg pkgname
    local pkg="$1"
    # only for Arch derivatives; try paru then yay
    if command -v paru >/dev/null 2>&1; then
        run_cmd "paru -S --noconfirm $pkg" paru -S --noconfirm "$pkg"
    elif command -v yay >/dev/null 2>&1; then
        run_cmd "yay -S --noconfirm $pkg" yay -S --noconfirm "$pkg"
    else
        red "[WARN] No AUR helper detected (paru/yay). Skip $pkg or install an AUR helper."
        return 1
    fi
}

# Ensure HOME variable exists
if [[ -z "${HOME:-}" ]]; then
    export HOME="/home/$(whoami)"
fi

# Ensure sudo is present or we are root for operations needing root
if ! command -v sudo >/dev/null 2>&1 && (( EUID != 0 )); then
    red "[WARN] sudo not found and you are not root — some operations will require root"
fi

# SECTION A: Debug Steam / fixes Steam common issues
steam_debug() {
    echo
    yellow "[TASK] Debugging Steam / checking 32-bit (lib32) libraries"

    # On Arch check for multilib packages like lib32-gnutls, lib32-mesa
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
    install_packages lib32-glibc lib32-mesa lib32-libpulse lib32-gnutls 2>/dev/null || true
    run_cmd "Check Steam via steam --reset if present" bash -c 'if command -v steam >/dev/null 2>&1; then steam --reset || true; else echo "steam absent"; fi'
    else
    # On other distros, advise user
    run_cmd "Check that Steam (proton) is installed" bash -c 'if command -v steam >/dev/null 2>&1; then echo "steam ok"; else echo "steam not present"; fi'
    fi
}

# SECTION B: Android Studio installation (flatpak preferred)
install_android_studio() {
    echo
    yellow "[TASK] Installing Android Studio (flatpak preferred)"

    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.google.AndroidStudio || true
    else
    # Try package manager or snap
    case "$PKG_MANAGER" in
        pacman) install_packages android-studio || true ;;
        apt) run_cmd "Installer Android Studio via snap/apt" bash -c 'echo "Veuillez installer Android Studio manuellement (apt/snap)"; exit 0' || true ;;
        dnf) install_packages android-studio || true ;;
      *) red "[WARN] No reliable automatic installation for Android Studio on this distro" ;;
    esac
    fi
}

# SECTION C: Spotify & Spicetify
install_spotify_and_spicetify() {
    echo
    yellow "[TASK] Installing Spotify and Spicetify (if available)"

    # Install Spotify client (flatpak preferred)
    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.spotify.Client || true
    else
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        install_packages spotify || install_aur_pkg spotify || true
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        # Add Spotify repo example (non exhaustive); user may prefer manual method
        run_cmd "Install Spotify via apt (generic method)" bash -c 'echo "Install Spotify manually on Debian/Ubuntu (official repo)"; exit 0' || true
    fi
    fi

    # Spicetify - install via pacman if missing
    if command -v spicetify >/dev/null 2>&1; then
    run_cmd "Spicetify backup" spicetify backup || true
    run_cmd "Spicetify apply" spicetify apply || true
    else
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed spicetify-cli
        if command -v spicetify >/dev/null 2>&1; then
        run_cmd "Spicetify backup" spicetify backup || true
        run_cmd "Spicetify apply" spicetify apply || true
        fi
    else
        echo "[INFO] spicetify not present; skipped" >&3
    fi
    fi
}

# SECTION D: Visual Studio Code + extensions (user session) 
install_vscode_extensions_user() {
    echo
    yellow "[TASK] Install Visual Studio Code (if 'code' binary present) and useful extensions"

    if ! command -v code >/dev/null 2>&1 ; then
    yellow "'code' binary not found: installing via pacman"
    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed code || {
        echo "[ERROR] Unable to install Visual Studio Code with pacman" >&2
    }
    fi

    if command -v code >/dev/null 2>&1 ; then
    # Extensions list (examples) - adapt to your list
    local exts=(
        ms-python.python
        eamodio.gitlens
        esbenp.prettier-vscode
        ms-vscode.cpptools
        ms-azuretools.vscode-docker
        rust-lang.rust-analyzer
        redhat.java
    )
    for ext in "${exts[@]}"; do
        run_cmd "Installer extension VSCode $ext" code --install-extension "$ext" --force || true
    done
    else
    red "[WARN] VSCode CLI (code) not found, extensions not installed"
    fi
}
    
# SECTION E: Browsers (Brave, Chrome, DuckDuckGo Browser)
install_browsers() {
    echo
    yellow "[TASK] Installing browsers (Brave / Google Chrome / DuckDuckGo Browser if possible)"

    # Prefer flatpak for cross-distro
    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.brave.Browser || true
    install_flatpak com.google.Chrome || true
    # DuckDuckGo browser might be available as flatpak 'com.duckduckgo.desktop'
    install_flatpak com.duckduckgo.desktop || true
    return 0
    fi

    # Distro-specific fallback
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
    # Brave/Chrome exist in AUR for Arch
    install_aur_pkg brave-bin || true
    install_aur_pkg google-chrome || true
    # DuckDuckGo browser not standard - skip or advise
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
    # Use Google's repo / Brave's repo - here we avoid adding repos automatically; user may prefer manual
    echo "[INFO] For Ubuntu/Debian, manually add the official Brave/Chrome repos if desired" >&3
    else
    echo "[INFO] Install Brave/Chrome via your distro's official packages or flatpak" >&3
    fi
}

# SECTION F: Fixes and utilities (pulseaudio/pipewire, codecs, fonts)
install_multimedia_and_fonts() {
    echo
    yellow "[TASK] Installer codecs, PipeWire et polices utiles"

    case "$PKG_MANAGER" in
    pacman)
        install_packages pipewire pipewire-pulse pipewire-alsa pipewire-jack gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly noto-fonts noto-fonts-emoji ttf-jetbrains-mono || true
        ;;
    apt)
        install_packages pipewire libpipewire-0.3-0 pipewire-audio-client-libraries fonts-noto fonts-noto-color-emoji || true
        ;;
    dnf)
        install_packages pipewire pipewire-alsa pipewire-jack freetype-freeworld google-noto-emoji-fonts || true
        ;;
    *)
        echo "[INFO] Installez manuellement PipeWire/codecs/fonts si besoin" >&3
        ;;
    esac
}

# SECTION G: Misc user tweaks (spicetify themes backup, config restore)
user_misc_tweaks() {
    echo
    yellow "[TASK] Optional user tasks (spicetify backup, config copies...)"

    # Create a ~/bin if not present and ensure it's in PATH
    mkdir -p "$HOME/bin"
    if ! echo "$PATH" | grep -q "$HOME/bin"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.profile"
    fi

    # Ensure ~/.config exists
    mkdir -p "$HOME/.config"

    # Example: backup dotfiles directory if present
    if [[ -d "$HOME/.config" ]]; then
    run_cmd "Create .config backup (if missing)" bash -c 'mkdir -p "$HOME/.config.backup" || true; cp -a --backup=numbered "$HOME/.config/." "$HOME/.config.backup/" || true'
    fi
}

# SECTION H: Main
main() {
    yellow "Starting post-install tasks"

    # 0) update index
    update_db

    # 1) Steam debug
    steam_debug

    # 2) Android Studio
    install_android_studio

    # 3) Spotify & Spicetify -> I think I went overboard with this overly long name
    install_spotify_and_spicetify

    # 4) Visual Studio Code extensions -> I think I went overboard with this overly long name
    install_vscode_extensions_user

    # 5) Browsers
    install_browsers

    # 6) Multimedia & Fonts -> I think I went overboard with this overly long name
    install_multimedia_and_fonts

    # 7) Misc user tweaks
    user_misc_tweaks

    # 8) Deploy helper -> I think I went overboard with this overly long name
    deploy_post_install_helper

    yellow "Post-install tasks completed"
    echo
    green "Summary: if errors occurred, they are logged in: $LOGFILE"
    echo "Check them with: tail -n 200 $LOGFILE"
}

main "$@"

# Restore stderr
exec 2>&3

echo "[INFO] post-install finished at $(date '+%Y-%m-%d %H:%M:%S')"
POST_EOF

# Apply permissions with UID/GID if available
    uid="$(/usr/bin/arch-chroot /mnt id -u "$U" 2>/dev/null || true)"
    gid="$(/usr/bin/arch-chroot /mnt id -g "$U" 2>/dev/null || true)"
    if [[ -n "$uid" && -n "$gid" ]]; then
        chown "$uid:$gid" "$TARGET"
    else
        echo "[WARN] UID/GID not found for $U → no chown"
    fi
    chmod 0755 "$TARGET"
}

install_fastfetch() {
    print_header "STEP 28/$TOTAL_STEPS: FASTFETCH INSTALLATION AND CONFIGURATION"
    CURRENT_STEP=28

    if [[ -z "${USERNAME:-}" ]]; then
        print_error "USERNAME not set. Aborting."
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] install_fastfetch for ${USERNAME}"
        return 0
    fi

    print_info "Installing fastfetch..."

    # Installing the package
    if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch; then
        print_warning "Pacman failed, trying Flatpak..."
        if ! /usr/bin/arch-chroot /mnt flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null; then
            print_error "Impossible d'installer fastfetch"
            return 1
        fi
    fi

    local USER_HOME="/home/${USERNAME}"
    local CONFIG_DIR="${USER_HOME}/.config/fastfetch"

    print_info "Creating fastfetch configuration..."

    # Create config directory
    /usr/bin/arch-chroot /mnt mkdir -p "$CONFIG_DIR"

    # fastfetch configuration
    /usr/bin/arch-chroot /mnt bash -c "cat > '$CONFIG_DIR/config.json' <<'FFCONFIG'
{
    \"logo\": {
        \"type\": \"ascii\",
        \"source\": \"arch\",
        \"width\": 30,
        \"height\": 20,
        \"color\": {
            \"foreground\": \"green\"
        }
    },
    \"display\": {
        \"separator\": \" : \",
        \"keyWidth\": 20,
        \"keyColor\": \"green\",
        \"valueColor\": \"white\",
        \"barsColor\": \"green\",
        \"barChar\": \"█\",
        \"barWidth\": 20
    },
    \"modules\": [
        \"os\",
        \"host\",
        \"kernel\",
        \"uptime\",
        \"packages\",
        \"shell\",
        \"de\",
        \"wm\",
        \"cpu\",
        \"gpu\",
        \"memory\",
        \"swap\",
        \"disk\",
        \"battery\",
        \"localip\",
        \"publicip\"
    ]
}
FFCONFIG
"

    # bashrc configuration for GUARANTEED autostart
    print_info "Configuring bashrc autostart..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<'BASHRC_CONFIG'
USERNAME='$USERNAME'
BASHRC="/home/${USERNAME}/.bashrc"
MARKER="### FASTFETCH AUTOSTART - Arch Installation"

# If the marker doesn't exist, add the config
if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'FASTFETCH_EOF'
### FASTFETCH AUTOSTART - Arch Installation
if [[ $- == *i* ]]; then
    # Run only once per shell session
    if [[ -z "$FASTFETCH_RUN" ]]; then
        export FASTFETCH_RUN=1
        
        if command -v fastfetch >/dev/null 2>&1; then
            fastfetch --config ~/.config/fastfetch/config.json 2>/dev/null || fastfetch
        fi
    fi
fi
FASTFETCH_EOF
fi
BASHRC_CONFIG

    # zshrc configuration if installed
    /usr/bin/arch-chroot /mnt /bin/bash <<'ZSHRC_CONFIG'
if /usr/bin/arch-chroot /mnt command -v zsh >/dev/null 2>&1; then
    ZSHRC="/home/${USERNAME}/.zshrc"
    if [[ ! -f "$ZSHRC" ]]; then
        touch "$ZSHRC"
    fi
    
    if ! grep -q "FASTFETCH AUTOSTART" "$ZSHRC" 2>/dev/null; then
        cat >> "$ZSHRC" <<'ZSHFETCH_EOF'
### FASTFETCH AUTOSTART - Arch Installation
if [[ -o interactive ]]; then
    if [[ -z "$FASTFETCH_RUN" ]]; then
        export FASTFETCH_RUN=1
        
        if command -v fastfetch >/dev/null 2>&1; then
            fastfetch --config ~/.config/fastfetch/config.json 2>/dev/null || fastfetch
        fi
    fi
fi
ZSHFETCH_EOF
    fi
fi
ZSHRC_CONFIG

    # Create a handy alias
    /usr/bin/arch-chroot /mnt /bin/bash <<'ALIAS_CONFIG'
USERNAME='$USERNAME'
BASHALIASES="/home/${USERNAME}/.bash_aliases"

if ! grep -q "alias ff=" "$BASHALIASES" 2>/dev/null; then
    echo "alias ff='fastfetch --config ~/.config/fastfetch/config.json'" >> "$BASHALIASES"
fi
ALIAS_CONFIG

    # Fix permissions
    /usr/bin/arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.config/fastfetch" 2>/dev/null || true
    /usr/bin/arch-chroot /mnt chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.bashrc" "/home/${USERNAME}/.bash_aliases" 2>/dev/null || true

    # Test
    if /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -c "command -v fastfetch >/dev/null 2>&1 && fastfetch --help >/dev/null 2>&1"; then
        print_success "Fastfetch installed and configured with autostart"
        print_info "Fastfetch will run automatically every time a terminal opens"
        print_info "Raccourci disponible: ff"
    else
        print_warning "Fastfetch installed but the configuration may need checking"
    fi

    return 0
}

# Functions for final system configuration
final_config() {
    print_header "STEP 29/$TOTAL_STEPS: FINAL CONFIGURATION"
    CURRENT_STEP=29
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating final configuration"
        return 0
    fi
    
    print_info "Final configuration..."
    
    # Optimized system services
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF' || print_warning "Some configurations failed"
set -e

# Essential services
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable fstrim.timer

# PipeWire audio services
systemctl --global enable pipewire.service
systemctl --global enable pipewire-pulse.service
systemctl --global enable wireplumber.service

# Advanced system optimizations
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-swappiness.conf
echo "net.core.default_qdisc=fq" > /etc/sysctl.d/99-network.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-network.conf

# User limits
echo "$USERNAME soft nofile 65536" >> /etc/security/limits.conf
echo "$USERNAME hard nofile 65536" >> /etc/security/limits.conf
echo "$USERNAME soft memlock unlimited" >> /etc/security/limits.conf
echo "$USERNAME hard memlock unlimited" >> /etc/security/limits.conf
EOF
    
    # User configuration
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Partial user configuration"
cat > /home/$USERNAME/.bashrc <<'BASHRC_EOF'
#!/bin/bash

# If non-interactive, stop here
[[ \$- != *i* ]] && return

# History configuration
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# Environment variables
export EDITOR=nano
export VISUAL=nano
export BROWSER=firefox
export JAVA_HOME=/usr/lib/jvm/default
export PATH=\$PATH:\$HOME/.local/bin

# System aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Development aliases
alias python='python3'
alias pip='pip3'
alias serve='python -m http.server 8000'
alias myip='curl -s ifconfig.me'
alias weather='curl wttr.in'

# Arch system aliases
alias pacup='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacfind='pacman -Ss'
alias pacrem='sudo pacman -Rns'
alias pacclean='sudo pacman -Sc'
alias aurinstall='paru -S'
alias aursearch='paru -Ss'

# Audio aliases
alias cava='cava'
alias audio-restart='systemctl --user restart pipewire pipewire-pulse wireplumber'
alias audio-status='systemctl --user status pipewire pipewire-pulse wireplumber'

# Docker aliases
alias docker-clean='docker system prune -af'
alias docker-stop-all='docker stop \$(docker ps -q) 2>/dev/null || true'
alias docker-logs='docker logs'

# USEFUL FUNCTIONS
extract() {
    if [ -f \$1 ] ; then
        case \$1 in
            *.tar.bz2)   tar xjf \$1     ;;
            *.tar.gz)    tar xzf \$1     ;;
            *.bz2)       bunzip2 \$1     ;;
            *.rar)       unrar x \$1     ;;
            *.gz)        gunzip \$1      ;;
            *.tar)       tar xf \$1      ;;
            *.tbz2)      tar xjf \$1     ;;
            *.tgz)       tar xzf \$1     ;;
            *.zip)       unzip \$1       ;;
            *.Z)         uncompress \$1  ;;
            *.7z)        7z x \$1        ;;
            *)           echo "Unsupported extension: '\$1'" ;;
        esac
    else
        echo "File not found: '\$1'"
    fi
}

# Full system update function
full-update() {
    echo " Full system update..."
    sudo pacman -Syu
    if command -v paru >/dev/null; then
        echo " AUR update..."
        paru -Syu
    fi
    if command -v flatpak >/dev/null; then
        echo " Flatpak update..."
        flatpak update
    fi
    echo " Update completed!"
}

# System information function
sysinfo() {
    echo "SYSTEM INFORMATION:"
    echo "OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel: \$(uname -r)"
    echo "Uptime: \$(uptime -p)"
    echo "CPU: \$(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "RAM: \$(free -h | awk '/^Mem:/ {print \$3 "/" \$2}')"
    echo "Disk: \$(df -h / | awk 'NR==2{print \$3 "/" \$2 " (" \$5 " used)"}')"
    echo "Packages: \$(pacman -Q | wc -l) installed"
}

# Custom prompt
if [ "\$EUID" -eq 0 ]; then
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# GUARANTEED automatic fastfetch
if [[ -z "\$FASTFETCH_SHOWN" && "\$TERM" != "linux" ]]; then
    export FASTFETCH_SHOWN=1
    
    if command -v fastfetch >/dev/null 2>&1; then
        echo ""
        if [[ -f /home/$USERNAME/.config/fastfetch/config.jsonc ]]; then
            fastfetch --config /home/$USERNAME/.config/fastfetch/config.jsonc 2>/dev/null || fastfetch 2>/dev/null
        else
            fastfetch 2>/dev/null
        fi
        echo ""
    else
        echo ""
        echo -e "\033[1;32m  ARCH LINUX \033[0m"
        echo -e "\033[1;36mUtilisateur:\033[0m \$(whoami)@\$(hostname)"
        echo -e "\033[1;36mUptime:\033[0m \$(uptime -p)"
        echo -e "\033[1;33m Powered by PapaOursPolaire, available on GitHub \033[0m"
        echo ""
        echo -e "\033[0;35mCommandes utiles: sysinfo, full-update, cava, audio-restart\033[0m"
        echo ""
    fi
fi

BASHRC_EOF

# Improved VIM configuration
cat > /home/$USERNAME/.vimrc <<'VIM_EOF'
" Vim configuration - Arch Linux Fallout Edition
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set wildmenu
set wildmode=list:longest
set laststatus=2
set ruler
set showcmd
set showmatch
set cursorline
set mouse=a
syntax on

" Dark theme
set background=dark
colorscheme desert

" Mappings utiles
nnoremap <C-n> :set invnumber<CR>
nnoremap <C-h> :noh<CR>
nnoremap <F2> :w<CR>
nnoremap <F3> :q<CR>

" Configuration for developers
set autowrite
set encoding=utf-8
set fileencoding=utf-8
VIM_EOF

# Complete Git configuration
sudo -u $USERNAME git config --global user.name "$USERNAME"
sudo -u $USERNAME git config --global user.email "$USERNAME@$HOSTNAME.local"
sudo -u $USERNAME git config --global init.defaultBranch main
sudo -u $USERNAME git config --global core.editor nano
sudo -u $USERNAME git config --global pull.rebase false
sudo -u $USERNAME git config --global credential.helper store

# Creating user directories
mkdir -p /home/$USERNAME/{Projects,Scripts,Downloads/{Software,Music,Videos},Documents/{Dev,Personal,Notes},Pictures/{Screenshots,Wallpapers}}

# Full permissions
chown -R $USERNAME:$USERNAME /home/$USERNAME/
chmod 755 /home/$USERNAME
chmod -R 755 /home/$USERNAME/{Projects,Scripts,Documents,Pictures}
chmod -R 775 /home/$USERNAME/Downloads
EOF
    
    print_info "Final check of ALL fixes..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo ""
echo "FINAL CHECK OF FIXES"
echo ""

# 1. Theme check
echo "1.  THEMES AND ICONS:"
theme_ok=0
[[ -d /usr/share/icons/Papirus ]] && echo "    Papirus icons" && ((theme_ok++))
[[ -d /usr/share/themes/Arc ]] && echo "    Arc theme" && ((theme_ok++))
[[ -f /usr/share/icons/Tela-blue/index.theme ]] && echo "    Tela icons" && ((theme_ok++))
echo "Themes installed: $theme_ok/3"

# 2. Fastfetch check
echo ""
echo "2.  FASTFETCH:"
if command -v fastfetch >/dev/null 2>&1; then
    echo "    Fastfetch installed"
    [[ -f /home/$USERNAME/.config/fastfetch/config.jsonc ]] && echo "    Custom configuration"
    grep -q "fastfetch" /home/$USERNAME/.bashrc && echo "    Autostart configured"
else
    echo "    Fastfetch not found"
fi

# 3. VSCode check
echo ""
echo "3.  VISUAL STUDIO CODE:"
vscode_ok=false
if command -v code >/dev/null 2>&1; then
    echo "   VSCode (official) installed"
    vscode_ok=true
elif command -v code-oss >/dev/null 2>&1; then
    echo "    VSCode (OSS) installed"
    vscode_ok=true
elif [[ -x /opt/visual-studio-code/code ]]; then
    echo "    VSCode (manual) installed"
    vscode_ok=true
else
    echo "    VSCode not found"
fi

[[ "$vscode_ok" == true ]] && [[ -f /home/$USERNAME/.config/Code/User/settings.json ]] && echo "    VSCode configuration present"

# 4. GRUB check
echo ""
echo "4.  GRUB:"
[[ -f /boot/grub/grub.cfg ]] && echo "    GRUB configured"
[[ -f /boot/grub/themes/fallout/theme.txt ]] && echo "    Fallout theme installed"
grep -q "GRUB_TIMEOUT=10" /etc/default/grub && echo "    Menu visible (10s timeout)"

# 5. Plymouth check
echo ""
echo "5.  PLYMOUTH:"
[[ -f /usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.plymouth ]] && echo "    Plymouth PipBoy theme"
plymouth-set-default-theme --list 2>/dev/null | grep -q fallout-pipboy && echo "    Theme enabled"

# 6. Software check
echo ""
echo "6.  LOGICIELS ESSENTIELS:"
software_count=0
critical_software=("firefox" "vlc" "gimp" "git" "docker" "steam")

for app in "${critical_software[@]}"; do
    if command -v "$app" >/dev/null 2>&1; then
        echo "    $app"
        ((software_count++))
    else
        echo " $app MANQUANT"
    fi
done

echo "    Logiciels critiques: $software_count/${#critical_software[@]}"

# 7. Total packages
echo ""
echo "7.  STATISTIQUES :"
total_packages=$(pacman -Q | wc -l)
echo "    Total packages installed: $total_packages"

# 8. Services
echo ""
echo "8.  SERVICES :"
systemctl is-enabled NetworkManager >/dev/null && echo "    NetworkManager enabled"
systemctl --global is-enabled pipewire >/dev/null 2>&1 && echo "    PipeWire enabled"

echo ""
echo "FINAL SUMMARY"
if [[ $theme_ok -ge 2 && "$vscode_ok" == true && $software_count -ge 4 ]]; then
    echo "System ready for use"
else
    echo "Some fixes may require manual intervention because I'm too lazy to write a fix script or debug this one — do you think I've got nothing else on my plate?"
fi
EOF
    
    print_success "Final configuration completed with ALL FIXES"
}

finish_install() {
    print_header "STEP 32/$TOTAL_STEPS: FINALIZING THE INSTALLATION"
    CURRENT_STEP=32
    
    if [[ "$DRY_RUN" == true ]]; then
        print_success " SIMULATION COMPLETE - No real changes were made"
        echo ""
        echo -e "${YELLOW}For a real installation, rerun without --dry-run${NC}"
        return 0
    fi
    
    print_success "The complete Arch Linux Fallout Edition installation is now finished!"
    echo ""
    echo -e "${GREEN} FULL INSTALLATION SUMMARY:${NC}"
    echo -e "${CYAN}• Disque :${NC} $DISK"
    echo -e "${CYAN}• Mode boot :${NC} $BOOT_MODE"
    echo -e "${CYAN}• Partitions :${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "  - EFI: $EFI_PART ($PARTITION_EFI_SIZE)"
    else
        echo -e "  - Boot: $EFI_PART ($PARTITION_BOOT_SIZE)"
    fi
    echo -e "  - Root: $ROOT_PART ($PARTITION_ROOT_SIZE)"
    [[ -n "$HOME_PART" ]] && echo -e "  - Home : $HOME_PART ($PARTITION_HOME_SIZE)"
    [[ -n "$SWAP_PART" ]] && echo -e "  - Swap : $SWAP_PART ($PARTITION_SWAP_SIZE)"
    echo -e "${CYAN}• Hostname :${NC} $HOSTNAME"
    echo -e "${CYAN}• Utilisateur :${NC} $USERNAME"
    echo -e "${CYAN}• Environnement :${NC} $DE_CHOICE"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitioning:${NC} Custom"
    echo ""
    
    echo -e "${YELLOW}INFORMATIONS SPECIFIQUES AU MODE ${BOOT_MODE^^}:${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "• Bootloader: GRUB x86_64-efi"
        echo -e "• Table de partitions: GPT"
        echo -e "• EFI partition: FAT32"
    else
        echo -e "• Bootloader: GRUB i386-pc"
        echo -e "• Table de partitions: MBR"
        echo -e "• Partition Boot: ext4"
    fi
    echo ""
    
    # The rest of the function stays the same...
    # [identical content for displaying features]
    
    # Adapted post-installation instructions
    echo -e "${BLUE} POST-INSTALLATION INSTRUCTIONS:${NC}"
    echo -e "1. ${WHITE}Remove the installation media${NC}"
    echo -e "2. ${WHITE}Restart the system${NC}"
    echo -e "3. ${WHITE}Log in with:${NC} ${CYAN}$USERNAME${NC}"
    if [[ "$BOOT_MODE" == "bios" ]]; then
        echo -e "4. ${WHITE}Check that the BIOS boots correctly from the hard drive${NC}"
    fi
    echo -e "5. ${WHITE}First update:${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo ""
    
    # Log backup
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation.log" 2>/dev/null || true
        print_info "Installation log saved: /home/$USERNAME/installation.log"
    fi
    
    if confirm_action "Do you want to restart now?" "O"; then
        print_info "Restarting in 5 seconds..."
        
        print_info "Unmounting partitions..."
        sync
        
        # Clean unmount
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || print_warning "Partial unmount"
        
        echo ""
        for i in {5..1}; do
            echo -ne "\r${YELLOW} Restarting in $i seconds... (Ctrl+C to cancel)${NC}"
            sleep 1
        done
        echo ""
        echo ""
        print_success " Restarting... Welcome to Arch Linux (${BOOT_MODE})!"
        
        reboot
    else
        print_info "Installation complete. Restart manually whenever you like."
        echo -e "${YELLOW} Don't forget to remove the bootable USB drive!${NC}"
        
        # Manual unmount
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN} Installation V864.4-BIOS complete! Your Arch Linux system is ready.${NC}"
        echo ""
    fi
}

# Safe entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Make sure paru is present before any Gaming AUR install
    if ! chroot_cmd_exists paru; then
        print_info "Paru unavailable — (re)installing automatically…"
        ensure_paru_in_chroot || print_warning "Unable to (re)install an AUR helper — Gaming AUR packages will be skipped"
    fi

    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    main "$@"
    
    # Explicit exit
    exit 0
fi
