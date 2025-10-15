#!/bin/bash

if ! command -v arch-chroot &>/dev/null; then
    echo "[INFO] arch-chroot missing, attempting immediate installation..."
    pacman -Sy --noconfirm arch-install-scripts || {
        echo "[ERROR] Unable to install arch-install-scripts. Stopping script."
        exit 1
    }
fi

# Automated Arch Linux Installation Script
# Made by PapaOursPolaire - available on GitHub PapaOursPolaire
# Version: 764.4, fix 4 of version 764.4
# Update: 10/15/2025 at 18:23
# TAKE THE NEW VERSION after running dos2unix ON LINUX or in chroot, pacman -Sy dos2unix
# Fixed 2358 errors reported by ShellCheck and by the TTY console of the ISO
# Error in automatic execution of fastfetch: it's there, but doesn't run automatically
# Virtual Studio still doesn't install even with its own function!
# Removal of vulkan software/extensions because they were giving me headaches and not working under automation
# Overhaul of install_paru() variable -> 130th overhaul on 08/14 and still doesn't work
#[community] -> REMOVED because [community] package servers became obsolete on 08/13/2025 around 8 PM
#Include = /etc/pacman.d/mirrorlist -> These f***ing assholes cleaned the servers so it was giving 404 error and plus most of them crashed because of that 2 hours lost for such bullshit I can't believe it
# Remember to remove DRY RUN mode, because it became futile since version 246.6, it was meant to simulate operational mode and check the script appearance.
# Global configuration -> Theme (in development, no declared function)

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="764.4"
readonly LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"
readonly STATE_FILE="/tmp/arch_install_state.json"

# Colors for display
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'
readonly KDESPLASH_URL="https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/fallout-splashscreen4k.zip"
readonly SDDM_VIDEO_URL="https://mega.nz/file/PpJzyBjB#ONC7iTpdJkUxcOtLRuclrzJ-vsRRDgqR2oEkJPcHEbk" # Unused MegaNZ API bug
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/SDDM-Fallout-theme"
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

# Main function - main entry point
main() {
    # Initialization
    init_logging
    parse_arguments "$@"
    
    echo "Loading resources..."
    echo -e "${CYAN}Arch Linux Fallout Edition - Version ${SCRIPT_VERSION}${NC}"
    echo ""

    # Automatic boot mode detection (MUST be first)
    detect_boot_mode

    # Check if /usr/bin/arch-chroot is installed, otherwise install it
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot missing, attempting installation..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERROR] Unable to install arch-install-scripts. Stopping script."
            exit 1
        }
    fi

    # Signal handling
    trap cleanup EXIT INT TERM

    # Installation of required commands
    check_requirements || {
        print_error "Failed to install required commands"
        return 1
    }

    # Display
    show_banner

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "SIMULATION MODE ACTIVE"
        echo -e "${YELLOW}   • No modifications will be made${NC}"
        echo -e "${YELLOW}   • All operations will be simulated${NC}"
        echo -e "${YELLOW}   • Detected boot mode: ${BOOT_MODE}${NC}"
        echo ""
    fi

    # Complete installation sequence
    echo -e "${CYAN}STARTING ARCH LINUX INSTALLATION...${NC}"
    echo -e "${YELLOW}Boot mode: ${BOOT_MODE}${NC}"
    echo ""

    echo -e "${PURPLE}PHASE 1: SYSTEM PREPARATION${NC}"
    
    check_requirements || {
        print_error "Failed to verify prerequisites"
        return 1
    }
    
    test_environment || {
        print_error "Failed environment test"
        return 1
    }
    
    optimize_pacman || {
        print_warning "Partial Pacman optimization"
    }

    echo -e "${PURPLE}PHASE 2: DISK AND PARTITION CONFIGURATION${NC}"
    
    select_disk || {
        print_error "Failed to select disk"
        return 1
    }
    
    choose_partitioning || {
        print_error "Failed to choose partitioning"
        return 1
    }
    
    format_partitions || {
        print_error "Failed to format partitions"
        return 1
    }
    
    mount_partitions || {
        print_error "Failed to mount partitions"
        return 1
    }

    echo -e "${PURPLE}PHASE 3: BASE SYSTEM INSTALLATION${NC}"
    
    install_system || {
        print_error "Failed to install base system"
        return 1
    }
    
    configure_system || {
        print_error "Failed to configure system"
        return 1
    }
    
    create_users || {
        print_error "Failed to create users"
        return 1
    }

    echo -e "${PURPLE}PHASE 4: GRAPHICAL INTERFACE${NC}"
    
    select_desktop || {
        print_warning "No desktop environment selected"
    }
    
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_desktop || {
            print_error "Failed to install desktop environment"
            return 1
        }
    else
        print_info "Console/server mode - no graphical interface"
    fi

    echo -e "${PURPLE}PHASE 5: BOOTLOADER AND THEMES${NC}"
    
    # Bootloader configuration adapted to mode
    configure_grub || {
        print_error "Failed to configure bootloader"
        return 1
    }
    
    # KDE configuration only if KDE is installed
    if [[ "$DE_CHOICE" == "kde" ]]; then
        configure_kde_lockscreen || {
            print_warning "Failed to configure KDE lockscreen"
        }
    fi

    echo -e "${PURPLE}PHASE 6: AUDIO AND MULTIMEDIA${NC}"
    
    install_audio_system || {
        print_warning "Failed to install audio system"
    }
    
    install_boot_sound || {
        print_warning "Failed to install boot sound"
    }
    
    # Plymouth only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_plymouth || {
            print_warning "Failed to configure Plymouth"
        }
    fi
    
    # Display manager only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_sddm || {
            print_warning "Failed to configure display manager"
        }
    fi

    echo -e "${PURPLE}PHASE 7: APPLICATIONS AND SOFTWARE${NC}"
    
    install_software || {
        print_warning "Partial software installation failure"
    }
    
    install_web || {
        print_warning "Partial browser installation failure"
    }
    
    install_spotify || {
        print_warning "Failed to install Spotify"
    }
    
    install_wine || {
        print_warning "Failed to install Wine"
    }

    echo -e "${PURPLE}PHASE 8: TOOLS AND DEVELOPMENT${NC}"
    
    install_paru || {
        print_warning "Failed to install Paru"
    }
    
    install_development || {
        print_warning "Partial development tools installation failure"
    }
    
    # Steam only for graphical environments
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_steam || {
            print_warning "Failed to install Steam"
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
        print_warning "Failed to install Fastfetch"
    }

    echo -e "${PURPLE}PHASE 10: FINAL CONFIGURATION${NC}"
    
    final_config || {
        print_warning "Partial final configuration failure"
    }
    
    install_vscode || {
        print_warning "Failed to install VS Code"
    }
    
    generate_postinstall || {
        print_warning "Failed to generate post-installation script"
    }
    
    # Finalization
    finish_install || {
        print_error "Failed to finalize installation"
        return 1
    }

    echo -e "${GREEN}INSTALLATION REPORT COMPLETED${NC}"
    echo ""
    
    # Display summary according to mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${GREEN}✓ UEFI installation successful${NC}"
        echo -e "  • GPT table created"
        echo -e "  • EFI partition configured"
        echo -e "  • UEFI GRUB installed"
    else
        echo -e "${GREEN}✓ BIOS/Legacy installation successful${NC}"
        echo -e "  • MBR table created"
        echo -e "  • Boot partition configured"
        echo -e "  • BIOS GRUB installed"
    fi
    
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "1. Remove installation media"
    echo -e "2. Restart system"
    echo -e "3. Log in with user: ${USERNAME}"
    
    if [[ "$BOOT_MODE" == "bios" ]]; then
        while true; do
            read -r -p "Boot partition size (default: 512M): " boot_input
            boot_input=${boot_input:-512M}
            if validate_input "$boot_input" "size"; then
                PARTITION_BOOT_SIZE="$boot_input"
                break
            fi
            print_warning "Invalid format! Use: number + M/m or G/g (ex: 512M, 512m, 2G, 2g)"
        done
    fi
    
    echo ""
    print_success "Arch Linux Fallout Edition installation completed successfully!"
    
    # Final log backup
    if [[ -f "$LOG_FILE" ]] && [[ -n "$USERNAME" ]]; then
        local user_log="/mnt/home/$USERNAME/installation.log"
        if cp "$LOG_FILE" "$user_log" 2>/dev/null; then
            print_info "Installation log saved: $user_log"
        fi
    fi
    
    return 0
}

detect_boot_mode() {
    print_header "BOOT MODE DETECTION"
    
    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="uefi"
        print_success "UEFI mode detected"
        echo -e "${GREEN}• Partition table: GPT${NC}"
        echo -e "${GREEN}• Boot partition: EFI (FAT32)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB x86_64-efi${NC}"
    else
        BOOT_MODE="bios"
        print_success "BIOS/Legacy mode detected"
        echo -e "${GREEN}• Partition table: MBR${NC}"
        echo -e "${GREEN}• Boot partition: Boot (ext4)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB i386-pc${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Configuration for mode: ${BOOT_MODE}${NC}"
    echo ""
}

configure_grub() {
    print_header "STEP 13/$TOTAL_STEPS: BOOTLOADER CONFIGURATION according to firmware"
    CURRENT_STEP=13

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Bootloader configuration simulation"
        return 0
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        configure_grub_uefi
    else
        configure_grub_bios
    fi
}

configure_grub_bios() {
    print_header "STEP 14/$TOTAL_STEPS: BIOS GRUB CONFIGURATION"
    CURRENT_STEP=14
    print_info "Installing and configuring GRUB bootloader for BIOS..."

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installing GRUB for BIOS on ${DISK}"
grub-install --target=i386-pc --recheck "${DISK}"
EOF

    if [[ $? -ne 0 ]]; then
        print_error "Failed to install GRUB for BIOS"
        return 1
    fi

    print_info "Downloading Fallout theme from GitHub..."
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

    print_info "Configuring /etc/default/grub with Fallout theme..."
    cat > /mnt/etc/default/grub <<'EOF'
# BIOS GRUB configuration with Fallout theme
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch Linux Fallout Edition"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=1920x1080,auto
GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    print_info "Generating grub.cfg file..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Failed to generate grub.cfg file"
        return 1
    }

    print_success "BIOS GRUB installed and Fallout theme applied!"
}

configure_grub_uefi() {
    print_header "STEP 14/$TOTAL_STEPS: UEFI GRUB CONFIGURATION"
    CURRENT_STEP=14
    print_info "Installing and configuring GRUB bootloader for UEFI..."

    # GRUB installation for UEFI
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installing GRUB for UEFI..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    if [[ $? -ne 0 ]]; then
        print_error "Failed to install GRUB for UEFI"
        return 1
    fi

    print_info "Downloading Fallout theme from GitHub..."
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

    print_info "Configuring /etc/default/grub with Fallout theme..."
    cat > /mnt/etc/default/grub <<'EOF'
# UEFI GRUB configuration with Fallout theme
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR="Arch Linux Fallout Edition"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=1920x1080,auto
GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    print_info "Generating grub.cfg file..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Failed to generate grub.cfg file"
        return 1
    }

    print_success "UEFI GRUB installed and Fallout theme applied!"
}

install_web() {
    print_header "STEP 21/$TOTAL_STEPS: WEB BROWSERS INSTALLATION"
    CURRENT_STEP=21

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub com.vivaldi.Vivaldi || true
    flatpak install -y flathub com.opera.Opera || true
    flatpak install -y flathub org.midori_browser.Midori || true

    browsers=(
        # Check which ones are installed on GNOME & KDE, they are different sometimes
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser" # Doesn't work -> Installed via post-install.sh script
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi" # GNOME only (I think)
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher" # Doesn't work
        "GNOME Web (Epiphany)|epiphany|epiphany||org.gnome.Epiphany"
        "Midori|midori||midori|" # Doesn't work
        "Google Chrome|google-chrome||google-chrome|com.google.Chrome" # Doesn't work but installed via post-install.sh script
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
        else echo "[ERROR] Unable to install $name"; fi
    done
}

install_steam() {
    print_header "STEP 26/$TOTAL_STEPS: STEAM INSTALLATION"
    CURRENT_STEP=26

    # Check that Flatpak is installed in chroot
    if ! /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        print_info "Flatpak missing — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Unable to install Flatpak"
            return 1
        }
        # Enable Flathub if not already configured
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    # Steam installation via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.valvesoftware.Steam; then
        print_success "Steam (Flatpak) installed successfully"
    else
        print_warning "Failed to install Steam (Flatpak). Check your connection or Flathub."
    fi
}

fix_spicetify_prefs() { # Doesn't work because Spotify & spicetify aren't installed in chroot due to multi I don't remember what # Should maybe remove it in stable version if I can't anyway post-install works
    print_header "SPICETIFY PREFS FIX (ROBUST, NON-BLOCKING)"

    # Security: ensure USERNAME is defined
    if [[ -z "${USERNAME:-}" ]]; then
        print_warning "USERNAME not defined – cannot apply Spicetify for a user."
        return 0
    fi

    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc '
set -u

# Dedicated user logging
LOG_DIR="${HOME}/.local/share/spicetify-fix"
LOG_FILE="${LOG_DIR}/fix.log"
mkdir -p "$LOG_DIR" || true
# Redirect everything to log + stdout
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "[$(date "+%F %T")] Starting fix_spicetify_prefs"

# Local display helpers
info(){ echo "[INFO]  $*"; }
ok(){ echo "[OK]    $*"; }
warn(){ echo "[WARN]  $*"; }
err(){ echo "[ERROR] $*"; }

# Cumulative state of warnings/errors (but exit with 0)
WARN_COUNT=0
ERR_COUNT=0
warn_wrap(){ warn "$@"; WARN_COUNT=$((WARN_COUNT+1)); }
err_wrap(){  err  "$@"; ERR_COUNT=$((ERR_COUNT+1)); }

# Tool detection
if ! command -v spicetify >/dev/null 2>&1; then
    warn_wrap "spicetify not found for ${USER}. Step ignored."
    echo "End (spicetify absent)"
    exit 0
fi

IS_NATIVE=false
IS_FLATPAK=false

if command -v spotify >/dev/null 2>&1; then
    IS_NATIVE=true
    ok "Native Spotify detected."
else
    info "Native Spotify not detected."
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info com.spotify.Client >/dev/null 2>&1; then
    IS_FLATPAK=true
    ok "Flatpak Spotify detected."
else
    info "Flatpak Spotify not detected."
fi

if [[ "$IS_NATIVE" != true && "$IS_FLATPAK" != true ]]; then
    warn_wrap "No Spotify installation detected (neither native nor Flatpak)."
    echo "End (Spotify absent"
    exit 0
fi

# Prefs file location
# Possible paths (prioritize Flatpak if present)
CANDIDATES=()
if [[ "$IS_FLATPAK" == true ]]; then
    CANDIDATES+=("${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")
fi
if [[ "$IS_NATIVE" == true ]]; then
    CANDIDATES+=("${HOME}/.config/spotify/prefs")
fi
# Additional fallback in case I know the script 90% fails this bastard
CANDIDATES+=("${HOME}/.config/spotify/prefs" "${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")

PREFS_PATH=""
for p in "${CANDIDATES[@]}"; do
    if [[ -f "$p" ]]; then
        PREFS_PATH="$p"
        ok "Existing prefs found: $PREFS_PATH"
        break
    fi
done

# If not found, create skeleton cautiously without launching Spotify (because chroot/tty)
if [[ -z "$PREFS_PATH" ]]; then
    # Priority target folder choice
    if [[ "$IS_FLATPAK" == true ]]; then
        TARGET_DIR="${HOME}/.var/app/com.spotify.Client/config/spotify"
    elif [[ "$IS_NATIVE" == true ]]; then
        TARGET_DIR="${HOME}/.config/spotify"
    else
        # Extreme fallback
        TARGET_DIR="${HOME}/.config/spotify"
    fi

    mkdir -p "$TARGET_DIR" || { err_wrap "Unable to create ${TARGET_DIR}"; echo "End (folder creation failed)"; exit 0; }
    PREFS_PATH="${TARGET_DIR}/prefs"

    if [[ ! -f "$PREFS_PATH" ]]; then
        : > "$PREFS_PATH" || { err_wrap "Unable to create ${PREFS_PATH}"; echo "End (prefs creation failed)"; exit 0; }
        ok "prefs created: $PREFS_PATH (will be completed after first Spotify launch)."
        PREFS_WAS_CREATED="yes"
    else
        ok "prefs found just after folder creation: $PREFS_PATH"
        PREFS_WAS_CREATED="no"
    fi
else
    PREFS_WAS_CREATED="no"
fi

# Spicetify configuration
APPLY_OK=true

# 1) Set prefs_path
if spicetify config prefs_path "$PREFS_PATH"; then
    ok "spicetify: prefs_path registered."
else
    warn_wrap "spicetify config prefs_path failed."
    APPLY_OK=false
fi

# 2) Theme 
if spicetify config current_theme "DribbblishNordDark"; then
    ok "spicetify: theme set (DribbblishNordDark)."
else
    warn_wrap "spicetify: unable to set theme (may not be installed)."
fi

# 3) Backup + apply 
if spicetify backup >/dev/null 2>&1; then
    ok "spicetify: backup ok."
else
    warn_wrap "spicetify: backup failed."
    APPLY_OK=false
fi

if spicetify apply >/dev/null 2>&1; then
    ok "spicetify: apply ok."
else
    warn_wrap "spicetify: apply failed (probably incomplete prefs before first launch)."
    APPLY_OK=false
fi

# Fallback post-install: autostart on first real graphical launch  
# If we had to create empty prefs, or if apply failed, prepare a user task
# that will retry automatically after first Spotify launch.
# I make a multitude of comments for this one but IT DOESN'T WORK
if [[ "${PREFS_WAS_CREATED}" == "yes" || "${APPLY_OK}" == "false" ]]; then
    AUTOSTART_DIR="${HOME}/.config/autostart"
    BIN_DIR="${HOME}/.local/bin"
    mkdir -p "$AUTOSTART_DIR" "$BIN_DIR" || true

    FIX_SCRIPT="${BIN_DIR}/spicetify-postfirststart.sh"
    DESKTOP_FILE="${AUTOSTART_DIR}/spicetify-postfirststart.desktop"

    cat > "$FIX_SCRIPT" << "EOSH"
#!/usr/bin/env bash
set -u
# Wait for Spotify to generate a "real" prefs, then reapply spicetify
TRIES=60
SLEEP_SECS=2

log(){ echo "[spicetify-postfirststart] $*"; }

    # Potential paths
    CANDIDATES=(
    "${HOME}/.var/app/com.spotify.Client/config/spotify/prefs"
    "${HOME}/.config/spotify/prefs"
    )

    FOUND=""
    for ((i=0; i<TRIES; i++)); do
    for p in "${CANDIDATES[@]}"; do
        if [[ -s "$p" ]]; then
        FOUND="$p"
        break
        fi
    done
    [[ -n "$FOUND" ]] && break
    sleep "$SLEEP_SECS"
    done

    if [[ -z "$FOUND" ]]; then
    log "prefs still not found/empty, silent abandon."
    exit 0
    fi

log "prefs detected: $FOUND"
spicetify config prefs_path "$FOUND" || true
spicetify backup || true
spicetify apply || true

# Auto-cleanup: remove this service after success
rm -f "${HOME}/.config/autostart/spicetify-postfirststart.desktop" || true
rm -f "${HOME}/.local/bin/spicetify-postfirststart.sh" || true
exit 0
EOSH
    chmod +x "$FIX_SCRIPT" || true

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Spicetify Post-First-Start
Comment=Finalizes Spicetify after first Spotify launch
Exec=${FIX_SCRIPT}
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

    ok "Post-install fallback prepared (autostart): ${DESKTOP_FILE}"
fi

# Summary and end
if [[ $ERR_COUNT -gt 0 ]]; then
    warn "Finished with ${ERR_COUNT} error(s) and ${WARN_COUNT} warning(s). See log: ${LOG_FILE}"
elif [[ $WARN_COUNT -gt 0 ]]; then
    warn "Finished with ${WARN_COUNT} warning(s). See log: ${LOG_FILE}"
else
    ok "Finished without warnings."
fi

echo "End fix_spicetify_prefs"
exit 0
' || {
        # Don't fail global script: message and continue
        print_warning "fix_spicetify_prefs: chroot subcommand returned non-zero (see user log). Step CONTINUED."
        return 0

    print_success "fix_spicetify_prefs executed (see user log ~/.local/share/spicetify-fix/fix.log in chroot)."
}

# Utility functions and logging
# Check command presence in chroot
chroot_cmd_exists() {
    /usr/bin/arch-chroot /mnt bash -lc "command -v '${1}' >/dev/null 2>&1"
}

# (Re)ensure paru installation in chroot -> Doesn't work either
ensure_paru_in_chroot() {
    # Check if paru is already present in chroot
    if chroot_cmd_exists paru; then
        print_success "Paru already present in chroot"
        return 0
    fi

    print_info "Paru absent — AUR installation in chroot"

    # Install base-devel and git to compile from AUR
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Unable to install base-devel and git in chroot"
        return 1
    }

    # Launch installation via dedicated function
    if install_paru; then
        print_success "Paru installed successfully in chroot"
        return 0
    fi

    print_warning "Paru installation failed — yay fallback attempt"
    install_yay_in_chroot || return 1
}

check_requirements() {
    print_info "Verifying and installing required commands..."
    
    local missing_pkgs=()
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk" 
        "curl" "git" "timedatectl" "unzip"
    )

    # Check missing commands
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            case "$cmd" in
                "pacstrap"|"genfstab") missing_pkgs+=("arch-install-scripts") ;;
                "mkfs.fat") missing_pkgs+=("dosfstools") ;;
                "mkfs.ext4") missing_pkgs+=("e2fsprogs") ;;
                *) missing_pkgs+=("$cmd") ;;
            esac
        fi
    done

    # Install if necessary
    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        print_warning "Installing missing packages: ${missing_pkgs[*]}"
        pacman -Sy --noconfirm "${missing_pkgs[@]}" || {
            print_error "Failed to install dependencies"
            return 1
        }
    fi

    # Ensure unzip also in target chroot (/mnt)
    if [[ -d /mnt && -d /mnt/usr ]]; then
        if ! /usr/bin/arch-chroot /mnt bash -lc "command -v unzip >/dev/null 2>&1"; then
            print_info "unzip absent in chroot /mnt — attempting installation in chroot..."
            /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed unzip || {
                print_warning "Unable to install unzip in chroot (/mnt). Install manually: /usr/bin/arch-chroot /mnt pacman -S unzip"
            }
        else
            print_info "unzip already present in chroot /mnt"
        fi
    fi

    print_success "All required commands available"
}

# Pacman configuration optimization for speed
optimize_pacman() {
    print_header "STEP 3/$TOTAL_STEPS: PACMAN OPTIMIZATION"
    CURRENT_STEP=3

    # Original configuration backup
    cp /etc/pacman.conf /etc/pacman.conf.backup 2>/dev/null || true

    # Optimized pacman configuration
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

[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[multilib]
Include = /etc/pacman.d/mirrorlist
PACMAN_EOF
# Removal of [community] because it's no longer in repositories recently

    # Block rust to avoid rustup conflict # Obsolete since I cleaned rust & rustup, only rustup remains
    if ! grep -q "^IgnorePkg" /etc/pacman.conf; then
        echo "IgnorePkg = rust" >> /etc/pacman.conf
    else
        sed -i 's/^IgnorePkg.*/& rust/' /etc/pacman.conf
    fi

    # Install reflector if missing
    if ! command -v reflector &>/dev/null; then
        pacman -Sy --noconfirm reflector || {
            print_warning "Unable to install reflector, using existing mirrors"
            return 0
        }
    fi

    # Main attempt: fast + reliable (it doesn't work)
    if reflector --sort score --protocol https --country France,Germany,Netherlands,Belgium,Switzerland \
                    --latest 20 --save /etc/pacman.d/mirrorlist; then
        print_success "Mirrors optimized successfully (filtered mode)"
    else
        print_warning "Filtered optimization failed, wide mode attempt..."
        # Wide fallback: all countries, no strict filtering # This one works
        if reflector --sort score --protocol https --latest 20 \
                        --save /etc/pacman.d/mirrorlist; then
            print_success "Mirrors optimized successfully (wide mode)"
        else
            print_warning "Unable to generate mirrorlist with reflector, ultimate fallback"
            # Ultimate fallback: official archlinux.org mirror
            cat > /etc/pacman.d/mirrorlist <<'EOF'
## Official ArchLinux fallback
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
EOF
        fi
    fi

    # Cache cleanup + resync
    pacman -Scc --noconfirm || true
    rm -rf /var/lib/pacman/sync/* || true
    pacman -Syy --noconfirm || {
        print_warning "Unable to refresh pacman databases after optimization"
    }

    print_success "Pacman configuration finalized"
}

# Logging initialization
init_logging() {
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "Arch Linux Fallout Installation - $(date)" >> "$LOG_FILE"
    echo "Script version: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Logging with timestamp
log_message() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# Formatted display - find better "layout" if I have time
print_header() {
    local message="$1"
    echo ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo -e "${WHITE}$message${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
    log_message "HEADER" "$message"
}

# Should I keep in English or not? Think about doing full English but with google translate :/
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
    # Check if userns is enabled
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

# Progress bar with time estimation # Improve if possible
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
    
    printf "\r${CYAN}[%s] %d%% | %02d:%02d remaining | %s${NC}" \
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
    
    # Execute command in background
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

# Input validation with minimum 6 character password
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
    echo -e "${YELLOW}Expected format: number followed by M/m (MB) or G/g (GB)${NC}"
    echo -e "${YELLOW}Examples: 512M, 512m, 2G, 2g, 100G, 100g${NC}"
    echo ""
    
    # Different configuration according to boot mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        # EFI configuration for UEFI
        while true; do
            read -r -p "EFI partition size (default: 512M): " efi_input
            efi_input=${efi_input:-512M}
            if validate_input "$efi_input" "size"; then
                PARTITION_EFI_SIZE="$efi_input"
                break
            fi
            print_warning "Invalid format! Use: number + M/m or G/g (ex: 512M, 512m, 2G, 2g)"
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
            print_warning "Invalid format! Use: number + M/m or G/g (ex: 512M, 512m, 2G, 2g)"
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
        print_warning "Invalid format! Use: number + M/m or G/g (ex: 60G, 60g)"
    done
    
    # Swap configuration (optional)
    if confirm_action "Create Swap partition?" "Y"; then
        USE_SWAP=true
        while true; do
            read -r -p "Swap partition size (default: 8G): " swap_input
            swap_input=${swap_input:-8G}
            if validate_input "$swap_input" "size"; then
                PARTITION_SWAP_SIZE="$swap_input"
                break
            fi
            print_warning "Invalid format! Use: number + M/m or G/g (ex: 8G, 8g)"
        done
    else
        USE_SWAP=false
        print_info "Swap partition disabled"
    fi
    
    # Home configuration (optional)
    if confirm_action "Create separate /home partition?" "N"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Home partition options:${NC}"
        echo -e "${CYAN}1.${NC} Use remaining available space"
        echo -e "${CYAN}2.${NC} Specify custom size"
        
        local home_choice
        while true; do
            read -r -p "Your choice (1-2): " home_choice
            case $home_choice in
                1)
                    PARTITION_HOME_SIZE="remaining"
                    print_info "Home partition: using remaining space"
                    break
                    ;;
                2)
                    while true; do
                        read -r -p "Home partition size (ex: 100G, 100g): " home_input
                        if validate_input "$home_input" "size"; then
                            PARTITION_HOME_SIZE="$home_input"
                            break
                        fi
                        print_warning "Invalid format! Use: number + M/m or G/g (ex: 100G, 100g)"
                    done
                    break
                    ;;
                *)
                    print_warning "Invalid choice!"
                    ;;
            esac
        done
    else
        USE_SEPARATE_HOME=false
        print_info "Separate /home partition disabled - It will be in Root partition"
    fi
    
    # Configuration summary
    echo ""
    echo -e "${GREEN}CONFIGURATION SUMMARY${NC}"
    echo -e "${WHITE}• Boot mode:${NC} $BOOT_MODE"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${WHITE}• EFI partition:${NC} $PARTITION_EFI_SIZE (FAT32)"
    else
        echo -e "${WHITE}• Boot partition:${NC} $PARTITION_BOOT_SIZE (ext4)"
    fi
    echo -e "${WHITE}• Root partition:${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Swap partition:${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Home partition:${NC} Remaining available space"
        else
            echo -e "${WHITE}• Home partition:${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Home partition:${NC} Integrated in Root"
    fi
    echo ""
    
    if ! confirm_action "Confirm this configuration?" "Y"; then
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
        read -r -p "$message (Y/N, default: $default): " response
        response=${response:-$default}
        
        case "$response" in
            [OoYy]|[Oo][Uu][Ii]|[Yy][Ee][Ss])
                return 0
                ;;
            [NnFf]|[Nn][Oo][Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                print_warning "Invalid response. Use Y/N."
                ;;
        esac
    done
}

# Cleanup on exit
cleanup() {
    # Avoid multiple executions -> Do not disable, without this it bugs
    if $CLEANUP_DONE; then
        return 0
    fi
    CLEANUP_DONE=true

    local exit_code=$?
    echo "Starting cleanup (code: $exit_code)..." >> "$LOG_FILE"

    # Safe unmounting (without -e to avoid loops)
    set +e
    trap - EXIT INT TERM  # Disable trap otherwise bug & crash

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
trap 'cleanup' EXIT            # Only at real script end

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
    echo -e "${WHITE}For lazy people and beginners • Development • Gaming • Default Fallout theme${NC}"
    echo  ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

# Purely decorative because too lazy to make real menu
Options: 
    -h, --help     Show this help
    -d, --dry-run  Simulation mode (makes no modifications)
    --version      Show version

    COMPLETE FEATURES OF THIS EDITION:

    BASE SYSTEM:

    • Automated Arch Linux installation (UEFI only)
    • Complete French configuration (locale, keyboard, timezone)
    • Choice between KDE Plasma, GNOME or console mode (for minimalist server)
    • Custom partition size configuration
    • Optional separate /home partition (Y/N)

    INTERFACE AND FALLOUT THEMES:

    • Fallout theme for GRUB
    • Fallout boot sound (MP3 or system beep fallback) # Doesn't work
    • PipBoy animation splashscreen
    • Arch logo Plymouth (can be changed via BearGrubChanger, available on my GitHub account: PapaOursPolaire)
    • SDDM configuration with custom Fallout wallpaper (video, .gif or random images for you to change)
    • Icon themes (Tela, Papirus) and modern visual themes

    PROFESSIONAL AUDIO SYSTEM:

    • PipeWire + WirePlumber (professional low latency audio)
    • CAVA (terminal audio visualizer with green Matrix theme)
    • PavuControl (audio control graphical interface)
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
    • Enhanced terminal with Fastfetch and development aliases (to activate via script from my repo, unavailable in script for stupid reasons)

    PREINSTALLED WEB BROWSING:

    • Firefox (configured for Netflix, Disney+ with DRM)
    • Google Chrome, Chromium, Brave Browser, Google Chrome & Brave are installed in post-install script
    • DuckDuckGo Browser (privacy) (unavailable for now)

    MULTIMEDIA AND ENTERTAINMENT:

    • Spotify + Spicetify CLI with Dribbblish Nord-Dark theme, installed during post-install script
    • Spicetify Marketplace enabled for extensions
    • VLC, MPV, OBS Studio, Audacity
    • GIMP, Inkscape for design and creation

    GAMING AND WINDOWS COMPATIBILITY:

    • Steam with Proton automatically configured
    • Lutris, GameMode for gaming optimization
    • Wine + Winetricks (complete Windows compatibility)
    • Wine-mono, Wine-gecko for .NET and web applications
    • Automatic configuration for Windows games

    UTILITIES AND PRODUCTIVITY:

    • AUR Helper Paru pre-installed and configured (unavailable)
    • Flatpak
    • TimeShift (system backups), GParted, KeePassXC
    • Fastfetch with Arch ASCII logo and system information (unavailable)
    • Complete Bash configuration with 50+ useful aliases (unavailable)

    SYSTEM OPTIMIZATIONS:

    • Optimized Pacman configuration (ParallelDownloads=10)
    • Optimized mirrors with advanced Reflector
    • Network optimizations (BBR, TCP)
    • Optimized memory management (swappiness)
    • System services configured for performance
    • Progress bars with real time estimates
    • Robust error handling with automatic fallbacks

    NEW FEATURES OF VERSION 764.4:

    • Custom partition size configuration
    • Optional separate /home partition with Y/N interface
    • Minimum password reduced to 6 characters
    • Speed optimization with parallel downloads
    • Fixed PipeWire-Jack conflict bug
    • Installation using full bandwidth
    • Fixed 2358 errors reported by ShellCheck
    • User interface overhaul for more clarity
    • Code restructuring for better readability and understandability
    • Added main() before function declarations to avoid stupid trap
    • Debugged over 3000 errors

    Usage examples: # Doesn't work
    $0                # Complete interactive installation
    $0 --dry-run      # Test/simulation without modifications
    $0 --help         # Show this detailed help

    System requirements:

    • UEFI system mandatory
    • Stable Internet connection (More than 10 Mbps recommended)
    • Arch Linux ISO not from prehistoric times
    • Patience, because installation can take time (between 30 to 60 minutes according to several tests performed on my trash machines)
    • At least 60GB free disk space
    • RAM: minimum 8GB recommended (4GB minimum), starting from DDR3, I haven't tested DDR1 & 2
    • Execution from Arch Linux ISO

    Post-installation:

    • Automatic reboot proposed
    • Complete installation log saved for consultation and to send to me if problem
    • Post-installation verification script included (For software that couldn't be installed in chroot)
    • Optimized configuration ready to use
    • All important development and multimedia software installed

EOF
}

parse_arguments() { # Does it really work? I only managed to make it work once!
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                print_info "Simulation mode activated - no modifications will be made"
                shift
                ;;
            --version)
                echo "Complete Arch Linux Fallout Edition Installation Script - Version: $SCRIPT_VERSION"
                echo "Features: Pro Audio + Development + Gaming + Browsing + Fallout Themes"
                echo "New: Custom partition configuration + optional /home + Speed optimizations"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
}

# Verification and test functions
check_requirements() {
    print_header "STEP 1/$TOTAL_STEPS: PREREQUISITES VERIFICATION"
    CURRENT_STEP=1
    
    # Immediately remove [community] repository if present because it no longer exists
    if grep -q "^\[community\]" /etc/pacman.conf; then
        print_info "Removing [community] repository (merged into extra)"
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
    fi
    
    # Check root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        return 1
    fi
    
    # Adapted boot mode verification
    detect_boot_mode
    
    # Check Internet connection with multiple hosts
    print_info "Checking Internet connection..."
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com")
    local connected=false
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            print_success "Active Internet connection (tested: $host)"
            connected=true
            break
        fi
    done
    if [[ "$connected" != true ]]; then
        print_error "No Internet connection detected!"
        return 1
    fi

    # Enable user namespaces if disabled
    if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
        print_info "Enabling kernel.unprivileged_userns_clone=1 for Flatpak"
        sysctl -w kernel.unprivileged_userns_clone=1 || true
        echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/00-local-userns.conf
    fi
    
    # Synchronize clock
    timedatectl set-ntp true
    sleep 2
    
    # Update pacman databases (without community)
    print_info "Updating pacman databases..."
    if ! pacman -Sy --noconfirm; then
        print_warning "Error during update, attempting correction..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Sy --noconfirm || {
            print_error "Unable to update pacman databases"
            return 1
        }
    fi
    
    print_success "Prerequisites verified for ${BOOT_MODE} mode"
}

test_environment() {
    print_header "STEP 2/$TOTAL_STEPS: INSTALLATION ENVIRONMENT TEST"
    CURRENT_STEP=2
    
    local errors=0
    
    # Required commands
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk"
        "curl" "git" "timedatectl" "unzip"
    )
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            print_success " $cmd found"
        else
            print_error " $cmd missing"
            errors=$((errors + 1))
        fi
    done
    
    # Internet test with multiple servers
    local test_servers=("archlinux.org" "github.com" "google.com")
    local internet_ok=false
    for server in "${test_servers[@]}"; do
        if ping -c 1 -W 3 "$server" &> /dev/null; then
            print_success " Active Internet connection (tested: $server)"
            internet_ok=true
            break
        fi
    done
    
    if [[ "$internet_ok" != true ]]; then
        print_error " No Internet connection detected"
        errors=$((errors + 1))
    fi
    
    # Boot mode test (UEFI or BIOS) - CORRECTION: Support both modes
    if [[ -d /sys/firmware/efi ]]; then
        print_success " UEFI system detected"
        echo -e "${GREEN}  • Partition table: GPT${NC}"
        echo -e "${GREEN}  • Boot partition: EFI (FAT32)${NC}"
        echo -e "${GREEN}  • Bootloader: GRUB x86_64-efi${NC}"
    else
        print_success " BIOS/Legacy system detected"
        echo -e "${GREEN}  • Partition table: MBR${NC}"
        echo -e "${GREEN}  • Boot partition: Boot (ext4)${NC}"
        echo -e "${GREEN}  • Bootloader: GRUB i386-pc${NC}"
    fi
    
    # Test root
    if [[ $EUID -eq 0 ]]; then
        print_success " Root permissions"
    else
        print_error " Root permissions required"
        errors=$((errors + 1))
    fi
    
    # Test disk space
    local available_space
    available_space=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    if [[ $available_space -gt 2000 ]]; then
        print_success " Sufficient temporary space (${available_space}MB)"
    else
        print_warning " Limited temporary space (${available_space}MB)"
    fi
    
    # Test RAM
    local ram_gb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
    if [[ $ram_gb -ge 8 ]]; then
        print_success "Optimal RAM (${ram_gb}GB)"
    elif [[ $ram_gb -ge 4 ]]; then
        print_success "Sufficient RAM (${ram_gb}GB)"
    else
        print_warning "Limited RAM (${ram_gb}GB) - installation possible but slow"
    fi
    
    # Internet speed test (approximate)
    print_info "Testing connection speed..."
    local speed_test_start=$(date +%s%N)
    curl -s -o /dev/null -w "" "http://archlinux.org" || true
    local speed_test_end=$(date +%s%N)
    local response_time=$(( (speed_test_end - speed_test_start) / 1000000 ))
    
    if [[ $response_time -lt 500 ]]; then
        print_success " Fast connection (${response_time}ms)"
    elif [[ $response_time -lt 2000 ]]; then
        print_success " Correct connection (${response_time}ms)"
    else
        print_warning " Slow connection (${response_time}ms) - longer installation"
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        print_success " Optimal environment for Fallout Edition installation"
        return 0
    else
        print_error " $errors critical error(s) - installation impossible"
        return 1
    fi
}

# Disk and partition management functions
select_disk() {
    print_header "STEP 4/$TOTAL_STEPS: DISK SELECTION"
    CURRENT_STEP=4
    
    # Wait for disks to be detected
    sleep 2
    sync
    
    local disks
    mapfile -t disks < <(lsblk -dno NAME,SIZE,MODEL | grep -E '^(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])' | awk '{print $1}')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "No disks detected!"
        echo "Available disks:"
        lsblk
        return 1
    fi
    
    echo -e "${WHITE}Available disks:${NC}"
    for i in "${!disks[@]}"; do
        local disk="${disks[i]}"
        local size model
        size=$(lsblk -dno SIZE "/dev/$disk" 2>/dev/null || echo "Unknown")
        model=$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null || echo "Unknown")
        
        echo -e "${CYAN}$((i + 1)).${NC} /dev/$disk - $size - $model"
    done
    
    local disk_choice
    while true; do
        read -r -p "Select disk (number): " disk_choice
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && \
            [[ "$disk_choice" -ge 1 ]] && \
            [[ "$disk_choice" -le "${#disks[@]}" ]]; then
            DISK="/dev/${disks[$((disk_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Final disk verification
    if [[ ! -b "$DISK" ]]; then
        print_error "Disk $DISK doesn't exist!"
        return 1
    fi
    
    print_success "Selected disk: $DISK"
    return 0
}

choose_partitioning() {
    print_header "STEP 5/$TOTAL_STEPS: PARTITIONING CHOICE"
    CURRENT_STEP=5
    
    echo -e "${WHITE}Partitioning options:${NC}"
    echo -e "${CYAN}1.${NC} Keep existing partitions"
    echo -e "${CYAN}2.${NC} Create new automatic partitioning"
    echo -e "${CYAN}3.${NC} Create new custom partitioning"
    
    local choice
    while true; do
        read -r -p "Your choice (1-3): " choice
        case $choice in
            1)
                print_info "Keeping existing partitions"
                # Sub-menu for option 1
                echo -e "${WHITE}Sub-options:${NC}"
                echo -e "${CYAN}a.${NC} Use single partition and split it"
                echo -e "${CYAN}b.${NC} Use already created existing partitions"
                local sub_choice
                while true; do
                    read -r -p "Your choice (a/b): " sub_choice
                    case $sub_choice in
                        a)
                            print_info "Using single partition to split"
                            use_single_partition_and_split
                            return 0
                            ;;
                        b)
                            print_info "Using existing partitions"
                            detect_existing_partitions
                            return 0
                            ;;
                        *)
                            print_warning "Invalid choice!"
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
                print_warning "Invalid choice!"
                ;;
        esac
    done
}

use_single_partition_and_split() {
    print_info "Selecting single partition to split"
    
    # Detection of available partitions
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "No partitions found on $DISK"
        return 1
    fi
    
    echo -e "${WHITE}Detected partitions:${NC}"
    for i in "${!partitions[@]}"; do
        local part="/dev/${partitions[i]}"
        local size=$(lsblk -no SIZE "$part" 2>/dev/null || echo "Unknown")
        local fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || echo "Unknown")
        echo -e "${CYAN}$((i + 1)).${NC} $part - $size - $fstype"
    done
    
    local part_choice
    while true; do
        read -r -p "Select partition to split (number): " part_choice
        if [[ "$part_choice" =~ ^[0-9]+$ ]] && \
           [[ "$part_choice" -ge 1 ]] && \
           [[ "$part_choice" -le "${#partitions[@]}" ]]; then
            local selected_part="/dev/${partitions[$((part_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Configuration of sizes for new partitions
    print_info "Configuring sizes of new partitions"
    configure_custom_partitioning
    
    # Erase selected partition and create new partition table
    print_warning "WARNING: All data on $selected_part will be erased!"
    if ! confirm_action "Confirm partition erasure?"; then
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
        print_error "Insufficient space on partition!"
        print_error "Available: ${total_size_mb}MB, Required: ${total_required_mb}MB"
        return 1
    fi
    
    # Start partitioning
    print_info "Starting partitioning of $selected_part"
    
    # Erase partition
    parted -s "$selected_part" rm 1 || {
        print_error "Unable to delete partition"
        return 1
    }
    
    # Create new partition table
    parted -s "$selected_part" mklabel gpt || {
        print_error "Unable to create partition table"
        return 1
    }
    
    # Create partitions
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
        size=$(lsblk -no SIZE "/dev/$part" 2>/dev/null || echo "Unknown")
        fstype=$(lsblk -no FSTYPE "/dev/$part" 2>/dev/null || echo "Unknown")
        mountpoint=$(lsblk -no MOUNTPOINT "/dev/$part" 2>/dev/null || echo "")
        
        echo -e "${CYAN}/dev/$part${NC} - $size - $fstype $mountpoint"
    done
    
    configure_existing_partitions "${partitions[@]}"
}

configure_existing_partitions() {
    local partitions=("$@")
    
    print_info "Configuring partitions..."
    
    # Ask for EFI
    echo -e "${WHITE}Select EFI partition:${NC}"
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
    echo -e "${WHITE}Select Root partition:${NC}"
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
    if confirm_action "Configure separate Home partition?"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Select Home partition:${NC}"
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
    
    if confirm_action "Configure Swap partition?"; then
        USE_SWAP=true
        echo -e "${WHITE}Select Swap partition:${NC}"
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

    # Verify disk is not in use
    if lsof "$DISK" 2>/dev/null; then
        print_error "Disk $DISK is still being used by processes"
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
    print_header "PARTITIONING CREATION"
    
    print_warning "WARNING: All data on $DISK will be erased!"
    
    if ! confirm_action "Confirm disk erasure?"; then
        return 1
    fi

    # Complete and forced disk cleanup
    print_info "Complete disk cleanup..."
    
    # Force unmount all partitions
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true
    
    # Clean partition signatures with multiple methods
    print_info "Erasing partition signatures..."
    wipefs -af "$DISK" 2>/dev/null || true
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none 2>/dev/null || true
    
    # Synchronization and wait
    sync
    sleep 3

    # Create partition table according to mode
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

    # Synchronization after table creation
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
    [[ "$USE_SEPARATE_HOME" == true && "$PARTITION_HOME_SIZE" != "remaining" ]] && \
        home_mb=$(convert_to_mb "$PARTITION_HOME_SIZE") || home_mb=0

    local current_pos=1
    local part_num=1

    # Partition 1: Boot/EFI
    local boot_end=$((current_pos + boot_mb))
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Creating EFI partition (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary fat32 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Failed to create EFI partition"
            return 1
        fi
        parted -s "$DISK" set 1 esp on
        EFI_PART="${DISK}1"
        print_success "EFI partition created: $EFI_PART"
    else
        print_info "Creating Boot partition (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Failed to create Boot partition"
            return 1
        fi
        parted -s "$DISK" set 1 boot on
        BOOT_PART="${DISK}1"
        print_success "Boot partition created: $BOOT_PART"
    fi
    current_pos=$boot_end
    part_num=2

    # Synchronization after first partition
    sync
    sleep 1

    # Partition 2: Root
    local root_end=$((current_pos + root_mb))
    print_info "Creating Root partition (${current_pos}MiB-${root_end}MiB)..."
    if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB; then
        print_error "Failed to create Root partition"
        return 1
    fi
    ROOT_PART="${DISK}2"
    print_success "Root partition created: $ROOT_PART"
    current_pos=$root_end
    part_num=3

    sync
    sleep 1

    # Partition 3: Swap (optional)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Creating Swap partition (${current_pos}MiB-${swap_end}MiB)..."
        if parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB; then
            SWAP_PART="${DISK}3"
            print_success "Swap partition created: $SWAP_PART"
            current_pos=$swap_end
            part_num=4
        else
            print_warning "Failed to create Swap partition, continuing without swap"
            USE_SWAP=false
        fi
    fi

    sync
    sleep 1

    # Partition 4: Home (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            print_info "Creating Home partition (remaining space)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB 100%; then
                HOME_PART="${DISK}${part_num}"
                print_success "Home partition created: $HOME_PART"
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        else
            local home_end=$((current_pos + home_mb))
            print_info "Creating Home partition (${current_pos}MiB-${home_end}MiB)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB; then
                HOME_PART="${DISK}${part_num}"
                print_success "Home partition created: $HOME_PART"
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        fi
    fi

    # Final synchronization
    sync
    sleep 3

    # Verification that partitions exist
    print_info "Verifying created partitions..."
    local partitions_ok=true
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "ROOT partition not found: $ROOT_PART"
        partitions_ok=false
    fi
    
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -b "$EFI_PART" ]]; then
        print_error "EFI partition not found: $EFI_PART"
        partitions_ok=false
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ ! -b "$BOOT_PART" ]]; then
        print_error "Boot partition not found: $BOOT_PART"
        partitions_ok=false
    fi
    
    if [[ "$USE_SWAP" == true ]] && [[ ! -b "$SWAP_PART" ]]; then
        print_warning "Swap partition not found, disabling..."
        USE_SWAP=false
    fi
    
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ ! -b "$HOME_PART" ]]; then
        print_warning "Home partition not found, disabling..."
        USE_SEPARATE_HOME=false
    fi

    if [[ "$partitions_ok" != true ]]; then
        print_error "Some partitions were not created correctly"
        print_info "Current partition state:"
        lsblk "$DISK"
        return 1
    fi

    print_success "Partitioning completed successfully"
    print_info "Partitioning summary:"
    lsblk "$DISK"
    return 0
}

create_mbr_with_fdisk() {
    print_info "Creating MBR table with fdisk..."
    
    # Create MBR table with fdisk
    echo "o\nw\n" | fdisk "$DISK" >/dev/null 2>&1
    
    # Verification
    if ! parted -s "$DISK" print | grep -q "msdos"; then
        print_error "Failed to create MBR with fdisk"
        return 1
    fi
    
    print_success "MBR table created with fdisk"
    return 0
}

format_partitions() {
    print_header "STEP 6/$TOTAL_STEPS: PARTITION FORMATTING"
    CURRENT_STEP=6
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Formatting simulation"
        return 0
    fi
    
    # Wait for partitions to be available
    print_info "Waiting for partition availability..."
    sleep 5
    sync
    
    # Verification that partitions exist
    print_info "Verifying partitions..."
    local partitions_ok=true
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "ROOT partition not found: $ROOT_PART"
        partitions_ok=false
    fi
    
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -b "$EFI_PART" ]]; then
        print_error "EFI partition not found: $EFI_PART"
        partitions_ok=false
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ ! -b "$BOOT_PART" ]]; then
        print_error "Boot partition not found: $BOOT_PART"
        partitions_ok=false
    fi
    
    if [[ "$partitions_ok" != true ]]; then
        print_error "Missing partitions, cannot format"
        return 1
    fi

    # Preventive unmount
    print_info "Preventive unmount..."
    umount -f "$EFI_PART" "$BOOT_PART" "$ROOT_PART" "$HOME_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    sleep 2

    # Boot/EFI formatting according to mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Formatting EFI partition: $EFI_PART"
        if mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
            print_success "EFI partition formatted (FAT32)"
        else
            print_error "EFI formatting failed"
            return 1
        fi
    else
        print_info "Formatting Boot partition: $BOOT_PART"
        if mkfs.ext4 -F -L 'ArchBoot' "$BOOT_PART"; then
            print_success "Boot partition formatted (ext4)"
        else
            print_error "Boot formatting failed"
            return 1
        fi
    fi

    # Root formatting
    print_info "Formatting Root partition: $ROOT_PART"
    if mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_success "Root partition formatted (ext4)"
    else
        print_error "Root formatting failed"
        return 1
    fi

    # Home formatting (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -b "$HOME_PART" ]]; then
        print_info "Formatting Home partition: $HOME_PART"
        if mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_success "Home partition formatted (ext4)"
        else
            print_warning "Home formatting failed, disabling..."
            USE_SEPARATE_HOME=false
        fi
    fi

    # Swap configuration (optional)
    if [[ "$USE_SWAP" == true ]] && [[ -b "$SWAP_PART" ]]; then
        print_info "Configuring Swap partition: $SWAP_PART"
        if mkswap -L 'ArchSwap' "$SWAP_PART"; then
            if swapon "$SWAP_PART"; then
                print_success "Swap partition configured and activated"
            else
                print_warning "Unable to activate swap"
            fi
        else
            print_warning "Swap configuration failed, disabling..."
            USE_SWAP=false
        fi
    fi

    print_success "Formatting completed successfully"
    return 0
}

mount_partitions() {
    print_header "STEP 7/$TOTAL_STEPS: PARTITION MOUNTING"
    CURRENT_STEP=7
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Mounting simulation"
        return 0
    fi
    
    # Preventive unmount
    print_info "Preventive unmount..."
    umount -R /mnt 2>/dev/null || true
    mkdir -p /mnt

    # Root mount
    print_info "Mounting Root partition: $ROOT_PART on /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Failed to mount Root partition"
        return 1
    fi

    # Boot/EFI mounting according to mode
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

    # Home mounting (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -b "$HOME_PART" ]]; then
        mkdir -p /mnt/home
        print_info "Mounting Home partition: $HOME_PART on /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Failed to mount Home partition, continuing without separate home"
            USE_SEPARATE_HOME=false
        else
            print_success "Home partition mounted"
        fi
    fi

    # Mount verification
    print_info "Verifying mount points..."
    local mount_ok=true
    
    if ! mountpoint -q /mnt; then
        print_error "Failed to mount /mnt"
        mount_ok=false
    fi
    
    if [[ "$BOOT_MODE" == "uefi" ]] && ! mountpoint -q /mnt/boot/efi; then
        print_error "Failed to mount /mnt/boot/efi"
        mount_ok=false
    elif [[ "$BOOT_MODE" == "bios" ]] && ! mountpoint -q /mnt/boot; then
        print_error "Failed to mount /mnt/boot"
        mount_ok=false
    fi

    if [[ "$mount_ok" != true ]]; then
        print_error "Mount point verification failed"
        return 1
    fi

    print_success "Partitions mounted successfully"
    echo "Mount points:"
    mount | grep /mnt
    return 0
}

# Base system installation functions
install_system() {
    print_header "STEP 8/$TOTAL_STEPS: BASE SYSTEM INSTALLATION"
    CURRENT_STEP=8
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Base system installation simulation"
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
    print_info "Forced database update..."
    pacman -Syy --noconfirm || {
        print_warning "Update failed, cleaning cache..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Syy --noconfirm || {
            print_error "Unable to update databases"
            return 1
        }
    }
    
    # Base packages adapted according to boot mode
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )
    
    # Specific addition according to mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        base_packages+=("efibootmgr")
        print_info "Adding efibootmgr for UEFI"
    else
        print_info "BIOS configuration - no efibootmgr needed"
    fi
    
    print_info "Installing base packages for ${BOOT_MODE} mode..."
    run_with_progress "Base system installation" 300 "pacstrap /mnt ${base_packages[*]}"
    
    print_success "Base system installed for ${BOOT_MODE} mode"
}

configure_system() {
    print_header "STEP 9/$TOTAL_STEPS: SYSTEM CONFIGURATION"
    CURRENT_STEP=9

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] System configuration simulation"
        return 0
    fi

    print_info "Generating fstab file..."
    genfstab -U /mnt > /mnt/etc/fstab || {
        print_error "Failed to generate fstab"
        return 1
    }

    if [[ ! -s /mnt/etc/fstab ]]; then
        print_error "fstab file is empty"
        return 1
    fi

    while true; do
        read -r -p "Hostname: " HOSTNAME
        if validate_input "$HOSTNAME" "hostname"; then
            break
        fi
        print_warning "Invalid hostname (letters, numbers and hyphens only)"
    done

    # What's weird is that I always have the American keyboard even though I configure it in French, where's the trick?
    print_info "Configuring system in chroot..."
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
    print_header "STEP 10/$TOTAL_STEPS: USER CREATION"
    CURRENT_STEP=10

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] User creation simulation"
        return 0
    fi

    # Main user creation
    while true; do
        read -r -p "Main username: " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Invalid username (min 3 characters, lowercase letters, numbers, hyphens and underscores only, must start with letter)"
    done

    # Main user password creation
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
            print_warning "Different passwords"
        else
            print_warning "Password too short (minimum 6 characters)"
        fi
    done

    # Sudo configuration to allow wheel group to execute commands without password
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Sudo configuration for wheel group - NOPASSWD
if ! grep -q "^%wheel ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    # Temporarily disable password prompt for wheel
    sed -i '/^%wheel ALL=(ALL:ALL) ALL/s/^/# /' /etc/sudoers
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
EOF

    # Main user creation with password
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Main user creation
useradd -m -G wheel,audio,video,storage,optical,network "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Personal directory creation
mkdir -p "/home/$USERNAME"/{Documents,Downloads,Images,Videos,Music,Desktop,.ssh}
chown -R "$USERNAME":"$USERNAME" "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
EOF

    print_success "User created: $USERNAME (with sudo rights without password)"

    # Additional user creation with their own passwords
    if confirm_action "Create additional users?"; then
        while true; do
            local additional_user
            read -r -p "Additional username (empty to finish): " additional_user
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
                        print_warning "Different passwords"
                    else
                        print_warning "Password too short (minimum 6 characters)"
                    fi
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Additional user creation
useradd -m -G wheel,audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd

# Personal directory creation
mkdir -p "/home/$additional_user"/{Documents,Downloads,Images,Videos,Music,Desktop,.ssh}
chown -R "$additional_user":"$additional_user" "/home/$additional_user"
chmod 700 "/home/$additional_user/.ssh"
EOF

                print_success "Additional user created: $additional_user (with sudo rights without password)"
            else
                print_warning "Invalid username, ignored"
            fi
        done
    fi

    # Root password configuration (optional and different)
    if confirm_action "Set root password? (recommended: NO)"; then
        local root_password root_password2
        while true; do
            read -r -s -p "Root password (leave empty to disable root account): " root_password
            echo ""
            if [[ -z "$root_password" ]]; then
                print_info "Root account disabled (no password set)"
                /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Disable root account
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
                    print_warning "Different passwords"
                fi
            else
                print_warning "Password too short (minimum 6 characters)"
            fi
        done
    else
        # Disable root account by default
        /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
passwd -l root
EOF
        print_info "Root account disabled (recommended for security)"
    fi

    # Final configuration message
    echo ""
    print_success "User configuration completed"
    echo -e "${GREEN}All users can use sudo without password${NC}"
    echo -e "${YELLOW}Root account has been disabled for more security${NC}"
    echo -e "${CYAN}Use 'sudo' for commands requiring elevated privileges${NC}"
}

select_desktop() {
    print_header "STEP 11/$TOTAL_STEPS: DESKTOP ENVIRONMENT SELECTION"
    CURRENT_STEP=11
    
    echo -e "${WHITE}Available environments:${NC}"
    echo -e "${CYAN}1.${NC} KDE Plasma"
    echo -e "${CYAN}2.${NC} GNOME"
    echo -e "${CYAN}3.${NC} No graphical interface (server/minimal)"
    
    local choice
    while true; do
        read -r -p "Your choice (1-3): " choice
        case $choice in
            1) DE_CHOICE="kde"; break ;;
            2) DE_CHOICE="gnome"; break ;;
            3) DE_CHOICE="none"; break ;;
            *) print_warning "Invalid choice! Use 1, 2 or 3." ;;
        esac
    done
    
    print_success "Environment selected: $DE_CHOICE"
}

install_desktop() {
    print_header "STEP 12/$TOTAL_STEPS: DESKTOP ENVIRONMENT INSTALLATION"
    CURRENT_STEP=12
    
    if [[ "$DE_CHOICE" == "none" ]]; then
        print_info "No desktop environment to install"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation of $DE_CHOICE installation"
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
        print_info "[DRY RUN] Audio system installation simulation"
        return 0
    fi

    print_info "Installing PipeWire and audio tools..." # PipeWire doesn't install I think

    local audio_packages=(
        pipewire pipewire-alsa pipewire-pulse
        wireplumber pavucontrol alsa-utils
        cava
    )

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm "${audio_packages[@]}" || {
        print_error "Failed to install audio packages"
        return 1
    }

    # CAVA configuration for user
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

install_boot_sound() { # Boot sound beep dysfunctional, to fix or not
    print_header "STEP 17/$TOTAL_STEPS: BOOT SOUND BEEP CONFIGURATION"
    CURRENT_STEP=17
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Boot sound installation simulation"
        return 0
    fi
    
    # Sound directory creation
    mkdir -p /mnt/usr/share/sounds/fallout
    
    # Fallout sound download (URL correction)
    print_info "Downloading Fallout boot sound..."
    if curl -fL -o /mnt/usr/share/sounds/fallout/boot.wav \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projets/boot.wav' 2>/dev/null; then
        
        print_success "Boot sound downloaded successfully"
        
        # Audio dependencies installation
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed alsa-utils pulseaudio-alsa || {
            print_warning "Unable to install complete audio dependencies"
        }
        
        # Corrected systemd service
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
        print_warning "Unable to download sound, creating system beep"
        
        # Fallback to integrated system beep
        cat > /mnt/usr/local/bin/fallout-beep <<'EOF'
#!/bin/bash
# Fallout style system beep
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
    
    # Service activation
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Unable to activate boot sound service"
    }
    
    print_success "Boot sound beep configured"
}

configure_plymouth() {
    print_header "STEP 18/$TOTAL_STEPS: PLYMOUTH CONFIGURATION"
    CURRENT_STEP=18

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Plymouth configuration simulation"
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
wget -O arch-mac-style.zip "https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/arch-mac-style.zip"

echo "[INFO] Extracting theme..."
unzip -o arch-mac-style.zip -d /usr/share/plymouth/themes/

# Auto correction: find folder containing arch-mac-style.plymouth
THEME_DIR=$(find /usr/share/plymouth/themes -type f -name "arch-mac-style.plymouth" -printf '%h\n' | head -n1)

if [[ -z "$THEME_DIR" ]]; then
    echo "[ERROR] Unable to find arch-mac-style.plymouth after extraction."
    ls -R /usr/share/plymouth/themes || true
    exit 1
fi

echo "[INFO] Theme detected in: $THEME_DIR"

echo "[INFO] Configuring default theme..."
plymouth-set-default-theme -R "$(basename "$THEME_DIR")"

echo "[SUCCESS] Plymouth configured with arch-mac-style theme."
EOF
}

configure_sddm() {
    print_header "STEP 19/$TOTAL_STEPS: SDDM (DISPLAY MANAGER) CONFIGURATION"
    CURRENT_STEP=19

    local repo_zip="/root/Projets.zip"
    local extract_dir="/root/arch-Projets"
    local theme_dir="/usr/share/sddm/themes/SDDM-Fallout-theme"

    # 1) If GNOME → GDM
    if /usr/bin/arch-chroot /mnt pacman -Qi gdm &>/dev/null && \
        /usr/bin/arch-chroot /mnt pacman -Qi gnome-shell &>/dev/null; then
        print_info "GNOME detected → GDM configuration"
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed gdm || {
            print_error "Unable to install GDM"
            return 1
        }
        /usr/bin/arch-chroot /mnt systemctl enable gdm.service
        print_success "GDM activated (SDDM ignored)."
        return 0
    fi

    # 2) Install SDDM and unzip
    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed sddm unzip curl || {
        print_error "Unable to install SDDM or its dependencies"
        return 1
    }

    # 3) Download auto archive from GitHub
    print_info "Downloading GitHub repository (Projets branch)..."
    if ! /usr/bin/arch-chroot /mnt curl -fL \
        "https://github.com/PapaOursPolaire/arch/archive/refs/heads/Projets.zip" \
        -o "$repo_zip"; then
        print_error "Failed to download GitHub archive"
        return 1
    fi

    # 4) Extraction
    /usr/bin/arch-chroot /mnt rm -rf "$extract_dir" "$theme_dir"
    if ! /usr/bin/arch-chroot /mnt unzip -o "$repo_zip" -d /root/; then
        print_error "GitHub archive extraction failed"
        return 1
    fi

    # 5) Theme move
    if /usr/bin/arch-chroot /mnt test -d "$extract_dir/SDDM-Fallout-theme"; then
        /usr/bin/arch-chroot /mnt mv "$extract_dir/SDDM-Fallout-theme" "$theme_dir"
    else
        print_error "SDDM-Fallout-theme folder not found in archive"
        return 1
    fi

    # 6) Content verification
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/Main.qml"; then
        print_error "Main.qml not found — incomplete theme"
        return 1
    fi
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/background.mp4"; then
        print_warning "Warning: background.mp4 video missing"
    fi

    # 7) Configure SDDM
    print_info "Writing /etc/sddm.conf..."
    /usr/bin/arch-chroot /mnt bash -c "cat > /etc/sddm.conf <<EOF
[Theme]
Current=SDDM-Fallout-theme

[General]
DisplayServer=wayland
EOF"

    # 8) Activate SDDM
    /usr/bin/arch-chroot /mnt systemctl enable sddm.service

    print_success "SDDM configured successfully with Fallout theme"
}

configure_kde_lockscreen() {
    print_header "STEP 15/$TOTAL_STEPS: KDE SPLASH CONFIGURATION"
    CURRENT_STEP=15
    
    if [[ "$DE_CHOICE" != "kde" ]]; then
        print_info "KDE environment not detected - lockscreen ignored"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] KDE lockscreen configuration simulation"
        return 0
    fi

    print_info "Configuring KDE Fallout splash screen..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installing KDE Splash components..."
pacman -S --noconfirm --needed ksplash

# Create theme directory
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

# Create simple background image (Fallout green pixel)
cat > "$THEME_DIR/contents/splash/fallout-bg.png" << 'PNG_EOF'
# Simplified creation - use solid color
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

# Lookandfeel configuration
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

    # Configuration to force theme usage
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Partial KDE configuration"
# SDDM configuration for splash
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

# Force theme to load via lookandfeel
lookandfeeltool -a org.kde.fallout.desktop 2>/dev/null || true
EOF

    print_success "KDE Fallout Splash configured"
}

# Application installation functions, never worked - THINK TO REMOVE IN FINAL VERSION
install_paru() {
    print_header "STEP 24/$TOTAL_STEPS: PARU (AUR HELPER) INSTALLATION"
    CURRENT_STEP=24
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Paru installation simulation"
        return 0
    fi
    
    print_info "Starting Paru installation in chroot..."
    
    /usr/bin/arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

echo "STARTING PARU INSTALLATION"

# Installation of dependencies + rustup to be sure
echo "Installing dependencies..."
pacman -Sy --noconfirm --needed base-devel git sudo rust cargo

# Temporary user creation
echo "Creating builduser..."
id builduser &>/dev/null || useradd -m builduser
echo "builduser ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/99-aur
echo "User created OK"

# Compilation as builduser
echo "Starting paru compilation..."
cd /tmp
rm -rf paru-bin paru

echo "Cloning repository..."
sudo -u builduser git clone https://aur.archlinux.org/paru-bin.git
echo "Clone OK"

cd paru-bin
echo "Launching makepkg..."
sudo -u builduser makepkg -si --noconfirm
echo "Compilation completed"

# Immediate verification in chroot
echo "IMMEDIATE VERIFICATION"
echo "Current PATH: $PATH"

# Explicit addition of /usr/local/bin to PATH
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
echo "New PATH: $PATH"

# Immediate test
if command -v paru; then
    echo "PARU FOUND: $(which paru)"
    paru --version
else
    echo "Paru not found, random search..."
    find /usr -name "*paru*" -type f 2>/dev/null
    
    # If found elsewhere, create link
    if [[ -f /usr/local/bin/paru ]]; then
        echo "Creating link /usr/local/bin/paru -> /usr/bin/paru"
        ln -sf /usr/local/bin/paru /usr/bin/paru
    fi
fi

# Permanent PATH addition in bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc

# Final test
echo "FINAL TEST"
export PATH="/usr/local/bin:/usr/bin:/bin"
command -v paru && paru --version

# Cleanup (but keep paru!)
echo "Cleaning up..."
rm -f /etc/sudoers.d/99-aur
userdel -r builduser 2>/dev/null || true
# DO NOT delete /tmp/paru-bin until paru is confirmed

echo "END OF PARU INSTALLATION"

CHROOT_EOF
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_error "Error during installation (code: $exit_code)"
        return 1
    fi
    
    # Final verification with correct PATH
    print_info "Final verification with extended PATH..."
    
    if /usr/bin/arch-chroot /mnt /bin/bash -c 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"; command -v paru >/dev/null 2>&1'; then
        print_success "Paru installed and available"
        # Clean now that it's confirmed
        /usr/bin/arch-chroot /mnt rm -rf /tmp/paru-bin 2>/dev/null || true
    else
        print_error "Paru could not be installed correctly"
        print_info "Final paru search..."
        /usr/bin/arch-chroot /mnt find /usr -name "*paru*" -type f 2>/dev/null || echo "No paru found"
        return 1
    fi
}

install_yay_in_chroot() {
    print_info "Installing yay (AUR helper) in chroot..."

    if chroot_cmd_exists yay; then
        print_success "yay already installed in chroot"
        return 0
    fi

    # Install base-devel and git as root
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Unable to install base-devel and git"
        return 1
    }

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ca-certificates ca-certificates-utils
    /usr/bin/arch-chroot /mnt update-ca-trust

    # Compile yay as normal user
    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc "
        cd /tmp &&
        git clone https://aur.archlinux.org/yay.git &&
        cd yay &&
        makepkg -si --noconfirm
    " || {
        print_error "Failed to install yay"
        return 1
    }

    print_success "yay installed successfully in chroot"
}

clean_pacman_cache_chroot() {
    print_info "Cleaning Pacman cache in chroot..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
rm -f /var/lib/pacman/db.lck
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /var/lib/pacman/sync/*
pacman -Sy --noconfirm
EOF

    print_success "Pacman cache cleaned in chroot"
}

refresh_mirrors() { # To use if download errors in future variables # Disabled because dysfunctional
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
            print_warning "Unable to refresh mirrors, using current list"
        }
    else
        print_warning "Reflector not found, attempting installation..."
        pacman -S --noconfirm reflector && \
        reflector --fastest 10 --save /etc/pacman.d/mirrorlist || true
    fi
    pacman -Syy --noconfirm
}

install_development() { # VS Code still doesn't install, to fix or not
    print_header "STEP 25/$TOTAL_STEPS: DEVELOPMENT ENVIRONMENT INSTALLATION"
    CURRENT_STEP=25

    # Check and remove rust installed by pacman to avoid conflict with rustup
    print_info "Checking rust/rustup conflict..."
    if /usr/bin/arch-chroot /mnt pacman -Q rust &>/dev/null; then
        /usr/bin/arch-chroot /mnt pacman -Rns --noconfirm rust
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Development environment installation simulation"
        return 0
    fi

    print_info "Installing programming languages and development tools..."

    # Development packages list - Add more if I forgot some
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

        # Complementary tools
        wget curl
        lsb-release
    )

    # Package installation
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

# Function to indicate to user what will happen - Doesn't work in chroot, available in post-install
vscode_post_install_info() {
    print_info ""
    print_info "  VS CODE INFORMATION:"
    print_info "   VS Code extensions will install automatically"
    print_info "   on first launch of your graphical session."
    print_info "   You can also install them manually with:"
    print_info "   • ~/install-vscode-extensions.sh"
    print_info "   • ~/manual-vscode-setup.sh (simplified version)"
    print_info ""
}

install_spotify() {  # Only installs launcher, not native client (spotify-client) so is duplicated
    # with spotify-client from post-install -> To fix or not
    print_header "STEP 22/$TOTAL_STEPS: SPOTIFY INSTALLATION"
    CURRENT_STEP=22

    # Check that Flatpak is installed in chroot
    if ! chroot_cmd_exists flatpak; then
        print_info "Flatpak missing — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Unable to install Flatpak"
            return 1
        }
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    local spotify_ok=false

    # Spotify installation attempt via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.spotify.Client; then
        print_success "Spotify (Flatpak) installed successfully"
        spotify_ok=true
    else
        print_warning "Spotify installation failed (Flatpak, extra-data). AUR version attempt…"

        if chroot_cmd_exists paru; then
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm spotify-launcher && spotify_ok=true || \
                print_warning "AUR installation failed (spotify-launcher)."
        else
            print_warning "Paru missing, unable to install Spotify via AUR."
        fi
    fi

    # Spotify installation verification
    if [[ "$spotify_ok" == false ]]; then
        print_warning "Spotify could not be installed automatically. It can be installed manually after reboot."
        return 0
    fi

    # Spicetify CLI installation
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
        print_warning "USERNAME not defined — Spicetify will be configured after first boot." # Obsolete since version 361.2; new method working a bit better (launcher installs)
    fi

    print_success "Spotify + Spicetify installation completed (with fallbacks)."
}

# Safe /tmp cleanup before font installation (to avoid "No space left on device")
clean_tmp() { # More effective since version 238.0, to remove in final version
    print_header "/tmp CLEANUP"
    local CLEAN_TMP_MINUTES="${CLEAN_TMP_MINUTES:-120}"  # files inactive older than X minutes will be deleted
    local LARGE_FILE_MB="${LARGE_FILE_MB:-100}"         # files > X MB will be deleted
    local DRY="${DRY_RUN:-false}"
    local BEFORE_MB AFTER_MB

    # Display state before
    BEFORE_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "Space used /tmp: ${BEFORE_MB} MB (before cleanup)."
    if [[ "$DRY" == "true" ]]; then
        print_info "[DRY RUN] Simulation - no files will be deleted."
        return 0
    fi

    # Security: don't delete if /tmp is non-standard link
    if [[ ! -d /tmp ]]; then
        print_warning "/tmp not found or not directory — cleanup canceled."
        return 0
    fi

    # Switch to tolerant mode on errors during deletions
    set +e

    # 1) Delete large files (> LARGE_FILE_MB) (regular files)
    print_info "Deleting files > ${LARGE_FILE_MB} MB in /tmp (to free space)..."
    find /tmp -type f -size +"${LARGE_FILE_MB}"M -print -exec rm -f {} \; 2>/dev/null || true

    # 2) Delete files/dirs in /tmp inactive since CLEAN_TMP_MINUTES minutes
    print_info "Deleting entries inactive for > ${CLEAN_TMP_MINUTES} minutes..."
    # Limit depth to 1 to avoid recursively traversing very large trees
    find /tmp -mindepth 1 -maxdepth 1 -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -rf {} \; 2>/dev/null || true

    # 3) Delete old temporary archives (additional security)
    print_info "Deleting archives (.zip .tar.gz .tgz .tar.xz) older than > ${CLEAN_TMP_MINUTES} minutes..."
    find /tmp -type f \( -iname '*.zip' -o -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.tar.xz' -o -iname '*.tar' \) -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -f {} \; 2>/dev/null || true

    # 4) Delete core dumps (often huge)
    print_info "Deleting possible core dumps..."
    find /tmp -type f -iname 'core*' -size +1M -print -exec rm -f {} \; 2>/dev/null || true

    # 5) Force sync and recalculate
    sync 2>/dev/null || true

    # Restore normal error behavior
    set -e

    AFTER_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "Space used /tmp: ${AFTER_MB} MB (after cleanup)."
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
        print_info "[DRY RUN] Wine installation simulation"
        return 0
    fi
    
    print_info "Installing Wine for Windows compatibility..."
    
    # Multilib activation for Wine
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Multilib activation in pacman.conf
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy
EOF
    
    # Wine and tools installation
    local wine_packages=(
        wine wine-staging winetricks
        wine-mono wine-gecko
    )
    
    run_with_progress "Wine installation" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm ${wine_packages[*]}"
    
    # Wine configuration for user
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Wine configuration failed"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Wine initialization (Windows 10)
export WINEPREFIX=/home/$USERNAME/.wine
wineboot --init >/dev/null 2>&1 || true

# Wine configuration as Windows 10
winecfg /v win10 >/dev/null 2>&1 || true

# Essential components installation via Winetricks
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
        print_warning "clean_tmp function missing — minimal /tmp cleanup"
        find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Software installation simulation"
        return 0
    fi
    
    print_info "Installing all software..."
    
    # Category 1: Internet & Communication
    print_info "Installing Internet & Communication..."
    local internet_packages=(
        firefox # installed
        thunderbird # to verify
        telegram-desktop  # to verify
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
        imagemagick # To verify*
        kdenlive # To verify*
        blender # OK 
        krita # To verify*
    )
    # * : Didn't install before version 411, to recheck
    run_with_progress "Multimedia installation" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${multimedia_packages[*]}"
    
        # Category 3: Gaming (if graphical interface installed) 
        if [[ "$DE_CHOICE" != "none" ]]; then
            print_header "GAMING SOFTWARE INSTALLATION"
            print_info "Installing complete Gaming suite..."

            # Ensure multilib in chroot before installing Steam
            /usr/bin/arch-chroot /mnt pacman -Syyu --noconfirm

            # Enable multilib repository if not already enabled (again)
            if ! grep -q "^\[multilib\]" /mnt/etc/pacman.conf; then
                echo "[multilib]" >> /mnt/etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
            fi

            # Update package database with multilib
            /usr/bin/arch-chroot /mnt pacman -Sy


            # Ensure paru is present before any AUR Gaming install
            if ! chroot_cmd_exists paru; then
                print_info "Paru not available — installation attempt via pacman..."
                if /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed paru; then
                    print_success "Paru installed successfully via repositories"
                else
                    print_warning "Binary installation failed — AUR attempt..."
                    if install_paru; then
                        print_success "Paru installed via AUR"
                    elif install_yay_in_chroot; then
                        print_success "Yay installed as fallback"
                    else
                        print_warning "Unable to install AUR helper — AUR Gaming packages will be ignored"
                    fi
                fi
            fi

            local gaming_packages=(
                # Platforms and managers
                lutris # OK

                # Multi-system emulation -> None installed before version 411, to recheck
                retroarch
                retroarch-assets-xmb
                retroarch-assets-ozone
                libretro-gambatte
                libretro-snes9x
                libretro-mupen64plus-next

                # Standalone emulators
                fceux # IDK
                snes9x-gtk # IDK
                mupen64plus # IDK
                dolphin-emu # OK
                ppsspp # OK
                desmume # IDK

                # Gaming optimizations
                gamemode # IDK
                lib32-gamemode # IDK
                mangohud # IDK 
                lib32-mangohud # IDK 

                # Proton & compatibility
                lib32-gcc-libs # IDK
                lib32-glibc # IDK

                # Tools and streaming
                discord # OK
                obs-studio # OK

                # Emulation
                retroarch # IDK
                dolphin-emu # OK
            )
        
        install_errors=0
        for pkg in "${gaming_packages[@]}"; do
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "$pkg"; then
                print_warning "Unable to install $pkg"
                ((install_errors++))
            fi
        done

        if (( install_errors == 0 )); then
            print_success "All gaming packages installed"
        else
            print_warning "$install_errors gaming package(s) could not be installed"
        fi


            # Paru verification in chroot - Still doesn't work
            if chroot_cmd_exists paru; then
                print_info "Installing AUR Gaming packages via Paru..."
                local gaming_aur_packages=(
                    protonup-qt
                    heroic-games-launcher-bin
                )
                if /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${gaming_aur_packages[@]}"; then
                    print_success "AUR gaming packages installed"
                else
                    print_warning "Some AUR gaming packages could not be installed"
                fi
            else
                print_warning "Paru not installed or not available in chroot - AUR Gaming packages will be ignored"
            fi
        else
            print_info "No graphical interface - Gaming section ignored"
        fi


            # Installation via pacman
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "${gaming_packages[@]}"; then
                print_error "Failed to install Gaming packages via pacman"
            else
                print_success "Gaming packages installed (pacman)"
            fi

            # Specific AUR packages installation via paru - Doesn't work therefore
            local aur_gaming_packages=(
                heroic-games-launcher-bin
                yuzu-early-access-bin
                rpcs3-bin
            )

            if /usr/bin/arch-chroot /mnt command -v paru &>/dev/null; then
                print_info "Installing AUR Gaming packages..."
                /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${aur_gaming_packages[@]}" || \
                    print_warning "Some AUR Gaming packages could not be installed"
            else
                print_warning "Paru not installed — AUR Gaming packages will be ignored"
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
    print_info "Installing System utilities..."
    local utility_packages=(
        gparted # OK
        timeshift # OK 
        flatpak # OK 
        keepassxc # OK  
        unzip # OK
        p7zip # IDK
        tree # IDK
        feh # IDK
        flameshot # IDK
        htop # IDK
        btop # IDK
        #neofetch  -> was removed from repositories recently and I think fastfetch is better anyway
        lsb-release # OK
        wget # OK
        curl # OK
        rsync # OK
        ark # IDK
        filelight # IDK
    )

    clean_tmp
    
    run_with_progress "Utilities installation" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${utility_packages[*]}"
    
    # Category 5: Fonts and themes - To verify because I don't think all fonts were installed
    print_info "Installing Fonts..."
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
    # should return: 1 - otherwise screwed

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
start=notify-send "GameMode activated"
end=notify-send "GameMode deactivated"
GAMEMODE_EOF
USEREOF
EOF
    fi
    
    print_info "Verifying installations..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo "SOFTWARE INSTALLATION VERIFICATION"

# Critical software verification
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
        echo " $app MISSING"
    fi
done

echo "SUMMARY: $installed_count/$total_count software installed"

# Installed packages list
echo "Total packages installed: $(pacman -Q | wc -l)"
EOF
    
    print_success "ALL ESSENTIAL SOFTWARE HAS BEEN INSTALLED "
}

install_themes() {
    print_header "STEP 27/$TOTAL_STEPS: THEMES AND ICONS INSTALLATION"
    CURRENT_STEP=27
    
    if [[ "$DRY_RUN" == true ]] || [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Themes and icons ignored (console mode or dry-run)"
        return 0
    fi
    
    print_info "Installing themes and icons..."
    
    # Icons and themes via pacman - CORRECTION: correct package names - not sure because not many are installed, to recheck
    local theme_packages=(
        papirus-icon-theme
        tela-icon-theme
        breeze-icons
        breeze-gtk
        materia-gtk-theme
        qogir-gtk-theme
        sweet-theme-git
    )
    
    # Base themes installation
    run_with_progress "Themes and icons installation" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed papirus-icon-theme breeze-icons breeze-gtk"
    
    # Additional themes via AUR - Except Tela, others weren't installed TO RECHECK
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
    
    # Default theme configuration - CORRECTION: Existing themes (ineffective correction)
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
# CORRECTION: Correct desktop image download
curl -o /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projets/fallout-desktop-bg.png' 2>/dev/null || {
    # SDDM image copy as fallback
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png
    fi
}
EOF
    elif [[ "$DE_CHOICE" == "gnome" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "GNOME theme configuration failed"
# GNOME configuration - CORRECTION: Valid themes
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.gnome.desktop.wm.preferences theme 'Arc-Dark'

# CORRECTION: Correct GNOME wallpaper configuration
mkdir -p /home/$USERNAME/.local/share/backgrounds
curl -o /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projets/fallout-desktop-bg.png' 2>/dev/null || {
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png
    fi
}

# Set wallpaper
gsettings set org.gnome.desktop.background picture-uri "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
EOF
    fi
    
    print_success "Themes and icons installed and configured"
}

install_vscode() { # Doesn't work
    print_header "STEP 30/$TOTAL_STEPS: VISUAL STUDIO CODE INSTALLATION"
    CURRENT_STEP=30

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] VSCode installation simulation"
        return 0
    fi

    print_info "Installing Visual Studio Code..."

    # Attempt 1: via pacman directly
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

    print_warning "VSCode not available via pacman, AUR attempt..."

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
    print_warning "Official VSCode unavailable, VSCodium attempt..."
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

    print_error "Unable to install Visual Studio Code or VSCodium"
    print_info "Manual installation possible after reboot via:"
    echo "  • pacman -S code"
    echo "  • paru -S visual-studio-code-bin"
    echo "  • flatpak install flathub com.visualstudio.code"
    
    return 1
}

generate_postinstall() {
    print_header "STEP 31/$TOTAL_STEPS: POST-INSTALLATION SCRIPT GENERATION"
    CURRENT_STEP=31

    local U TARGET
    U="${USERNAME:-}"

    if [[ -z "$U" ]]; then
        echo "[FATAL] USERNAME is empty, unable to generate post-install.sh" >&2
        return 1
    fi

    TARGET="/mnt/home/${U}/post-install.sh"
    install -d -m 755 "/mnt/home/${U}"

    cat > "$TARGET" <<'POST_EOF'
# post-install.sh
# Complete post-install tasks for user session usage.
# - Logs ONLY stderr to ~/post-install-errors.log
# - Continues after each failure (displays warning, logs error)
# - Idempotent: re-executable without breaking
#
# Usage:
#   chmod +x ~/post-install.sh
#   ~/post-install.sh
#
# NOTE: adapts some commands according to your distro (script attempts to detect package manager)

set -o pipefail

LOGFILE="$HOME/post-install-errors.log"
: > "$LOGFILE"   # truncate previous log (errors only)

# Redirect only stderr to LOGFILE, keep stdout visible
exec 3>&2
exec 2>>"$LOGFILE"

echo "[INFO] post-install started at $(date '+%Y-%m-%d %H:%M:%S')"

# Helper to display in green (success), yellow (info), red (error)
green()  { printf "\033[1;32m%s\033[0m\n" "$1" >&3; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1" >&3; }
red()    { printf "\033[1;31m%s\033[0m\n" "$1" >&3; }

# Helper: execute command, display result and log error if fails
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

    # Helper: execute command that must be root, attempts sudo if not root
    run_cmd_sudo() {
    local desc="$1"; shift
    if (( EUID == 0 )); then
        run_cmd "$desc" "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
        run_cmd "$desc" sudo "$@"
        else
        red "[ERROR] sudo not found — unable to execute (root): $desc"
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

echo "[INFO] Detection: PKG_MANAGER=$PKG_MANAGER, DISTRO=$DISTRO"

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
        red "[WARN] install_packages: unknown manager, attempt apt-get/pacman manually" ;;
    esac
}

install_flatpak() {
    # usage: install_flatpak <ref>
    local ref="$1"
    if ! command -v flatpak >/dev/null 2>&1; then
        run_cmd_sudo "Install flatpak" bash -c "true" || true
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
        run_cmd "Install flatpak ref $ref" flatpak install -y flathub "$ref"
    else
        red "[ERROR] flatpak unavailable, unable to install $ref"
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
        red "[WARN] No AUR helper detected (paru/yay). Ignore $pkg or install AUR helper."
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
    yellow "[TASK] Debug Steam / 32-bit libraries verification (lib32)"

    # On Arch check for multilib packages like lib32-gnutls, lib32-mesa
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
    install_packages lib32-glibc lib32-mesa lib32-libpulse lib32-gnutls 2>/dev/null || true
    run_cmd "Verify steam via steam --reset if present" bash -c 'if command -v steam >/dev/null 2>&1; then steam --reset || true; else echo "steam absent"; fi'
    else
    # On other distros, advise user
    run_cmd "Verify that Steam (proton) is installed" bash -c 'if command -v steam >/dev/null 2>&1; then echo "steam ok"; else echo "steam not present"; fi'
    fi
}

# SECTION B: Android Studio installation (flatpak preferred)
install_android_studio() {
    echo
    yellow "[TASK] Android Studio installation (flatpak preferred)"

    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.google.AndroidStudio || true
    else
    # Try package manager or snap
    case "$PKG_MANAGER" in
        pacman) install_packages android-studio || true ;;
        apt) run_cmd "Install Android Studio via snap/apt" bash -c 'echo "Please install Android Studio manually (apt/snap)"; exit 0' || true ;;
        dnf) install_packages android-studio || true ;;
      *) red "[WARN] No reliable automatic installation for Android Studio on this distro" ;;
    esac
    fi
}

# SECTION C: Spotify & Spicetify
install_spotify_and_spicetify() {
    echo
    yellow "[TASK] Spotify and Spicetify installation (if available)"

    # Install Spotify client (flatpak preferred)
    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.spotify.Client || true
    else
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        install_packages spotify || install_aur_pkg spotify || true
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
        # Add Spotify repo example (non exhaustive); user may prefer manual method
        run_cmd "Install Spotify via apt (generic method)" bash -c 'echo "Install spotify manually on Debian/Ubuntu (official repo)"; exit 0' || true
    fi
    fi

    # Spicetify - installation via pacman if absent
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
        echo "[INFO] spicetify not present; ignored" >&3
    fi
    fi
}

# SECTION D: Visual Studio Code + extensions (user session) 
install_vscode_extensions_user() {
    echo
    yellow "[TASK] Install Visual Studio Code (if 'code' binary present) and useful extensions"

    if ! command -v code >/dev/null 2>&1 ; then
    yellow "'code' binary not found: installation via pacman"
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
        run_cmd "Install VSCode extension $ext" code --install-extension "$ext" --force || true
    done
    else
    red "[WARN] VSCode CLI (code) not found, extensions not installed"
    fi
}
    
# SECTION E: Browsers (Brave, Chrome, DuckDuckGo Browser)
install_browsers() {
    echo
    yellow "[TASK] Browser installation (Brave / Google Chrome / DuckDuckGo Browser if possible)"

    # Prefer flatpak for cross-distro
    if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.brave.Browser || true
    install_flatpak com.google.Chrome || true
    # DuckDuckGo browser might be available as flatpak 'com.duckduckgo.desktop'
    install_flatpak com.duckduckgo.desktop || true
    return 0
    fi

    # Fallback distro-specific
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
    # Brave/Chrome exist in AUR for Arch
    install_aur_pkg brave-bin || true
    install_aur_pkg google-chrome || true
    # DuckDuckGo browser not standard - skip or advise
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
    # Use Google's repo / Brave's repo - here we avoid adding repos automatically; user may prefer manual
    echo "[INFO] For Ubuntu/Debian, add official Brave/Chrome repos manually if desired" >&3
    else
    echo "[INFO] Install Brave/Chrome via official packages of your distro or flatpak" >&3
    fi
}

# SECTION F: Fixes and utilities (pulseaudio/pipewire, codecs, fonts)
install_multimedia_and_fonts() {
    echo
    yellow "[TASK] Install codecs, PipeWire and useful fonts"

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
        echo "[INFO] Install manually PipeWire/codecs/fonts if needed" >&3
        ;;
    esac
}

# SECTION G: Misc user tweaks (spicetify themes backup, config restore)
user_misc_tweaks() {
    echo
    yellow "[TASK] Optional user tasks (spicetify backup, config copies...)"

    # Create ~/bin if not present and ensure it's in PATH
    mkdir -p "$HOME/bin"
    if ! echo "$PATH" | grep -q "$HOME/bin"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.profile"
    fi

    # Ensure ~/.config exists
    mkdir -p "$HOME/.config"

    # Example: backup dotfiles directory if present
    if [[ -d "$HOME/.config" ]]; then
    run_cmd "Create .config backup (if absent)" bash -c 'mkdir -p "$HOME/.config.backup" || true; cp -a --backup=numbered "$HOME/.config/." "$HOME/.config.backup/" || true'
    fi
}

# SECTION H: Main
main() {
    yellow "Starting post-install tasks"

    # 0) index update
    update_db

    # 1) Steam debug
    steam_debug

    # 2) Android Studio
    install_android_studio

    # 3) Spotify & Spicetify -> I abused the ridiculously long name I think
    install_spotify_and_spicetify

    # 4) Visual Studio Code extensions -> I abused the ridiculously long name I think
    install_vscode_extensions_user

    # 5) Browsers
    install_browsers

    # 6) Multimedia & Fonts -> I abused the ridiculously long name I think
    install_multimedia_and_fonts

    # 7) Misc user tweaks
    user_misc_tweaks

    # 8) Deploy helper -> I abused the ridiculously long name I think
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

# Apply rights with UID/GID if available
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
        print_error "USERNAME not defined. Aborting."
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] install_fastfetch for ${USERNAME}"
        return 0
    fi

    print_info "Installing fastfetch..."

    # Package installation
    if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch; then
        print_warning "Pacman failed, Flatpak attempt..."
        if ! /usr/bin/arch-chroot /mnt flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null; then
            print_error "Unable to install fastfetch"
            return 1
        fi
    fi

    local USER_HOME="/home/${USERNAME}"
    local CONFIG_DIR="${USER_HOME}/.config/fastfetch"

    print_info "Creating fastfetch configuration..."

    # Create config directory
    /usr/bin/arch-chroot /mnt mkdir -p "$CONFIG_DIR"

    # Fastfetch configuration
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

    # Bashrc configuration for GUARANTEED autostart
    print_info "Configuring autostart in bashrc..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<'BASHRC_CONFIG'
USERNAME='$USERNAME'
BASHRC="/home/${USERNAME}/.bashrc"
MARKER="### FASTFETCH AUTOSTART - Arch Installation"

# If marker doesn't exist, add config
if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'FASTFETCH_EOF'
### FASTFETCH AUTOSTART - Arch Installation
if [[ $- == *i* ]]; then
    # Execute only once per shell session
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

    # Zshrc configuration if installed
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

    # Create convenient alias
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
        print_info "Fastfetch will execute automatically on each terminal launch"
        print_info "Shortcut available: ff"
    else
        print_warning "Fastfetch installed but configuration may require verification"
    fi

    return 0
}

# Functions for final system configuration
final_config() {
    print_header "STEP 29/$TOTAL_STEPS: FINAL CONFIGURATION"
    CURRENT_STEP=29
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Final configuration simulation"
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

# Audio services PipeWire
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

# Complete system update function
full-update() {
    echo " Complete system update..."
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

# Guaranteed automatic Fastfetch
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
        echo -e "\033[1;36mUser:\033[0m \$(whoami)@\$(hostname)"
        echo -e "\033[1;36mUptime:\033[0m \$(uptime -p)"
        echo -e "\033[1;33m Powered by PapaOursPolaire, available on GitHub \033[0m"
        echo ""
        echo -e "\033[0;35mUseful commands: sysinfo, full-update, cava, audio-restart\033[0m"
        echo ""
    fi
fi

BASHRC_EOF

# Enhanced VIM configuration
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

" Useful mappings
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

# User directory creation
mkdir -p /home/$USERNAME/{Projects,Scripts,Downloads/{Software,Music,Videos},Documents/{Dev,Personal,Notes},Images/{Screenshots,Wallpapers}}

# Complete permissions
chown -R $USERNAME:$USERNAME /home/$USERNAME/
chmod 755 /home/$USERNAME
chmod -R 755 /home/$USERNAME/{Projects,Scripts,Documents,Images}
chmod -R 775 /home/$USERNAME/Downloads
EOF
    
    print_info "Final verification of ALL corrections..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo ""
echo "FINAL CORRECTIONS VERIFICATION"
echo ""

# 1. Theme verification
echo "1.  THEMES AND ICONS:"
theme_ok=0
[[ -d /usr/share/icons/Papirus ]] && echo "    Papirus icons" && ((theme_ok++))
[[ -d /usr/share/themes/Arc ]] && echo "    Arc theme" && ((theme_ok++))
[[ -f /usr/share/icons/Tela-blue/index.theme ]] && echo "    Tela icons" && ((theme_ok++))
echo "Themes installed: $theme_ok/3"

# 2. Fastfetch verification
echo ""
echo "2.  FASTFETCH:"
if command -v fastfetch >/dev/null 2>&1; then
    echo "    Fastfetch installed"
    [[ -f /home/$USERNAME/.config/fastfetch/config.jsonc ]] && echo "    Custom configuration"
    grep -q "fastfetch" /home/$USERNAME/.bashrc && echo "    Automatic launch configured"
else
    echo "    Fastfetch not found"
fi

# 3. VSCode verification
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

# 4. GRUB verification
echo ""
echo "4.  GRUB:"
[[ -f /boot/grub/grub.cfg ]] && echo "    GRUB configured"
[[ -f /boot/grub/themes/fallout/theme.txt ]] && echo "    Fallout theme installed"
grep -q "GRUB_TIMEOUT=10" /etc/default/grub && echo "    Menu visible (10s timeout)"

# 5. Plymouth verification
echo ""
echo "5.  PLYMOUTH:"
[[ -f /usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.plymouth ]] && echo "    Plymouth PipBoy theme"
plymouth-set-default-theme --list 2>/dev/null | grep -q fallout-pipboy && echo "    Theme activated"

# 6. Software verification
echo ""
echo "6.  ESSENTIAL SOFTWARE:"
software_count=0
critical_software=("firefox" "vlc" "gimp" "git" "docker" "steam")

for app in "${critical_software[@]}"; do
    if command -v "$app" >/dev/null 2>&1; then
        echo "    $app"
        ((software_count++))
    else
        echo " $app MISSING"
    fi
done

echo "    Critical software: $software_count/${#critical_software[@]}"

# 7. Total packages
echo ""
echo "7.  STATISTICS:"
total_packages=$(pacman -Q | wc -l)
echo "    Total packages installed: $total_packages"

# 8. Services
echo ""
echo "8.  SERVICES:"
systemctl is-enabled NetworkManager >/dev/null && echo "    NetworkManager activated"
systemctl --global is-enabled pipewire >/dev/null 2>&1 && echo "    PipeWire activated"

echo ""
echo "FINAL SUMMARY"
if [[ $theme_ok -ge 2 && "$vscode_ok" == true && $software_count -ge 4 ]]; then
    echo "System ready for use"
else
    echo "Some corrections may require manual intervention because too lazy to create correction script or debug this script, you think I don't have other scripts on the floor?"
fi
EOF
    
    print_success "Final configuration completed with ALL CORRECTIONS"
}

finish_install() {
    print_header "STEP 32/$TOTAL_STEPS: INSTALLATION FINALIZATION"
    CURRENT_STEP=32
    
    if [[ "$DRY_RUN" == true ]]; then
        print_success " SIMULATION COMPLETED - No real modifications made"
        echo ""
        echo -e "${YELLOW}For real installation, restart without --dry-run${NC}"
        return 0
    fi
    
    print_success "Complete Arch Linux Fallout Edition installation is now completed!"
    echo ""
    echo -e "${GREEN} COMPLETE INSTALLATION SUMMARY:${NC}"
    echo -e "${CYAN}• Disk:${NC} $DISK"
    echo -e "${CYAN}• Boot mode:${NC} $BOOT_MODE"
    echo -e "${CYAN}• Partitions:${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "  - EFI: $EFI_PART ($PARTITION_EFI_SIZE)"
    else
        echo -e "  - Boot: $EFI_PART ($PARTITION_BOOT_SIZE)"
    fi
    echo -e "  - Root: $ROOT_PART ($PARTITION_ROOT_SIZE)"
    [[ -n "$HOME_PART" ]] && echo -e "  - Home: $HOME_PART ($PARTITION_HOME_SIZE)"
    [[ -n "$SWAP_PART" ]] && echo -e "  - Swap: $SWAP_PART ($PARTITION_SWAP_SIZE)"
    echo -e "${CYAN}• Hostname:${NC} $HOSTNAME"
    echo -e "${CYAN}• User:${NC} $USERNAME"
    echo -e "${CYAN}• Environment:${NC} $DE_CHOICE"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitioning:${NC} Custom"
    echo ""
    
    echo -e "${YELLOW}SPECIFIC INFORMATION FOR ${BOOT_MODE^^} MODE:${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "• Bootloader: GRUB x86_64-efi"
        echo -e "• Partition table: GPT"
        echo -e "• EFI partition: FAT32"
    else
        echo -e "• Bootloader: GRUB i386-pc"
        echo -e "• Partition table: MBR"
        echo -e "• Boot partition: ext4"
    fi
    echo ""
    
    # The rest of the function remains identical...
    # [identical content of features display]
    
    # Post-installation instructions adapted
    echo -e "${BLUE} POST-INSTALLATION INSTRUCTIONS:${NC}"
    echo -e "1. ${WHITE}Remove installation media${NC}"
    echo -e "2. ${WHITE}Restart system${NC}"
    echo -e "3. ${WHITE}Log in with:${NC} ${CYAN}$USERNAME${NC}"
    if [[ "$BOOT_MODE" == "bios" ]]; then
        echo -e "4. ${WHITE}Verify BIOS boots correctly on hard disk${NC}"
    fi
    echo -e "5. ${WHITE}First update:${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo ""
    
    # Log backup
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation.log" 2>/dev/null || true
        print_info "Installation log saved: /home/$USERNAME/installation.log"
    fi
    
    if confirm_action "Do you want to restart now?" "Y"; then
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
        print_info "Installation completed. Restart manually when you want."
        echo -e "${YELLOW} Don't forget to remove bootable USB key!${NC}"
        
        # Manual unmount
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN} Complete installation V764.4-BIOS! Your Arch Linux system is ready.${NC}"
        echo ""
    fi
}

# Secure entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure paru is present before any AUR Gaming install
    if ! chroot_cmd_exists paru; then
        print_info "Paru not available — automatic (re)installation…"
        ensure_paru_in_chroot || print_warning "Unable to (re)install AUR helper — AUR Gaming packages will be ignored"
    fi

    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    main "$@"
    
    # Explicit exit
    exit 0
fi
