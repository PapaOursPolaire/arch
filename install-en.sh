#!/bin/bash

if ! command -v arch-chroot &>/dev/null; then
    echo "[INFO] arch-chroot missing, attempting immediate installation..."
    pacman -Sy --noconfirm arch-install-scripts || {
        echo "[ERROR] Unable to install arch-install-scripts. Stopping the script."
        exit 1
    }
fi
# Arch Linux automated installation script
# Made by PapaOursPolaire - available on GitHub
# Version: 734.4, patch 4 of version 734.4
# Updated: 08/10/2025 at 9:00 p.m.
# GET THE NEW VERSION after running dos2unix ON LINUX or in chroot, pacman -Sy dos2unix
# Correction of 2358 errors referenced by ShellCheck and by the ISO TTY console corrected
# Errors in step 17: do not install paru in the temp
# Errors in step 23: gtk-theme is not recognized
# Error in the automatic execution of fastfetch: it is there, but does not open automatically
# Virtual Studio has not been installed! 
# The boot is on the fallback of the fallout theme and the grub menu is not displayed
# The GitHub image is visible in Plymouth when it should be in the background of the session and not in Plymouth!
# No software has been installed!
# Error STEP 18 -> finished
# Error with the yay command  -> finished
# Errors Steps 18 bis, 21 & 23 (in progress)
# Removal of Vulkan software/extensions because they were giving me headaches and didn't work under automation
# Redesign of the install_paru() variable -> Second redesign on 08/14 for permission denied
#[community] -> REMOVED because the servers are whores 08/13/2025 around 8 p.m.
#Include = /etc/pacman.d/mirrorlist -> Those assholes cleaned up the dcp servers, causing a 404 error, and on top of that, most of them crashed because of it. Two hours wasted on bullshit like that, no way, I'm pissed off, argh
# Remember to remove DRY RUN mode, as it has become useless since version 246.6. Its purpose was to simulate the operating mode and check the script's appearance.
# Global configuration -> Theme (under development, no declared function)
# Translated by DBG - my local AI


set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="734.4"
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
readonly NC='\033[0m' # No Color

# Additional variables
readonly KDESPLASH_URL="https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/fallout-splashscreen4k.zip"
readonly SDDM_THEME_URL="https://github.com/PapaOursPolaire/arch/archive/refs/heads/Projets.zip"
readonly SDDM_VIDEO_URL="https://mega.nz/file/PpJzyBjB#ONC7iTpdJkUxcOtLRuclrzJ-vsRRDgqR2oEkJPcHEbk"
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/SDDM-Fallout-theme"
readonly LOCKSCREEN_THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.falloutlock"

# Global variables
DISK=""
EFI_PART=""
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

    # Check if /usr/bin/arch-chroot is installed, install if not
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot missing, attempting installation..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERROR] Unable to install arch-install-scripts. Script termination."
            exit 1
        }
    fi

    # Signal handling
    trap cleanup EXIT INT TERM

    # Install required commands
    install_required_commands || {
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

    # PHASE 1: SYSTEM PREPARATION
    echo -e "${PURPLE}PHASE 1: SYSTEM PREPARATION${NC}"
    
    check_requirements || {
        print_error "Requirements check failed"
        return 1
    }
    
    test_environment || {
        print_error "Environment test failed"
        return 1
    }
    
    optimize_pacman || {
        print_warning "Partial Pacman optimization"
    }

    echo -e "${PURPLE}PHASE 2: DISK AND PARTITION CONFIGURATION${NC}"
    
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

    echo -e "${PURPLE}PHASE 4: GRAPHICAL INTERFACE${NC}"
    
    select_desktop || {
        print_warning "No desktop environment selected"
    }
    
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_desktop || {
            print_error "Desktop environment installation failed"
            return 1
        }
    else
        print_info "Console/server mode - no graphical interface"
    fi

    echo -e "${PURPLE}PHASE 5: BOOTLOADER AND THEMES${NC}"
    
    # Bootloader configuration adapted to mode
    configure_bootloader || {
        print_error "Bootloader configuration failed"
        return 1
    }
    
    install_fallout_theme || {
        print_warning "Fallout theme installation failed"
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

    echo -e "${PURPLE}PHASE 7: APPLICATIONS AND SOFTWARE${NC}"
    
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
        print_warning "Post-installation script generation failed"
    }
    
    # Finalization
    finish_install || {
        print_error "Installation finalization failed"
        return 1
    }

    echo -e "${GREEN}INSTALLATION REPORT COMPLETED${NC}"
    echo ""
    
    # Mode-specific summary display
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
    echo -e "2. Reboot the system"
    echo -e "3. Log in with user: ${USERNAME}"
    
    if [[ "$BOOT_MODE" == "bios" ]]; then
        echo -e "4. Verify BIOS boots from hard disk"
    fi
    
    echo ""
    print_success "Arch Linux installation completed successfully!"
    
    # Final log backup
    if [[ -f "$LOG_FILE" ]] && [[ -n "$USERNAME" ]]; then
        local user_log="/mnt/home/$USERNAME/installation.log"
        if cp "$LOG_FILE" "$user_log" 2>/dev/null; then
            print_info "Installation journal saved: $user_log"
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

configure_bootloader() {
    print_header "STEP 13/$TOTAL_STEPS: BOOTLOADER CONFIGURATION"
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
    print_info "Installing and configuring GRUB for BIOS..."
    
    # GRUB installation for BIOS
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "Installing GRUB for BIOS on $DISK"
grub-install --target=i386-pc --recheck "$DISK"
EOF

    if [[ $? -ne 0 ]]; then
        print_error "GRUB installation for BIOS failed"
        return 1
    fi

    # Common GRUB configuration
    cat > /mnt/etc/default/grub <<'EOF'
# GRUB Configuration
GRUB_DEFAULT=0
GRUB_TIMEOUT=15
GRUB_DISTRIBUTOR="Arch Linux - by PapaOursPolaire on GitHub"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""

# Force menu display
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=console

# Disable hidden menu
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=false

GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    # GRUB configuration generation
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "GRUB configuration generation failed"
        return 1
    }

    print_success "GRUB configured and installed for BIOS on $DISK"
}

configure_grub_uefi() {
    print_info "Installing and configuring GRUB for UEFI..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "Installing GRUB for UEFI"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    if [[ $? -ne 0 ]]; then
        print_error "GRUB installation for UEFI failed"
        return 1
    fi

    # GRUB configuration identical to BIOS version
    cat > /mnt/etc/default/grub <<'EOF'
# GRUB Configuration
GRUB_DEFAULT=0
GRUB_TIMEOUT=15
GRUB_DISTRIBUTOR="Arch Linux - by PapaOursPolaire on GitHub"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""

# Force menu display
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=console

# Disable hidden menu
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=false

GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "GRUB configuration generation failed"
        return 1
    }

    print_success "GRUB configured and installed for UEFI"
}

install_web() {
    print_header "STEP 21/$TOTAL_STEPS: WEB BROWSERS INSTALLATION"
    CURRENT_STEP=21

    flatpak install -y flathub com.vivaldi.Vivaldi || true
    flatpak install -y flathub com.opera.Opera || true
    flatpak install -y flathub org.midori_browser.Midori || true

    browsers=(
        # Check which ones are installed on GNOME & KDE, they are sometimes different
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser" # Doesn't work (only  postinstall script)
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi" # Doesn't work either
        "Opera|opera|opera||com.opera.Opera" # Doesn't work either
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher"
        "GNOME Web (Epiphany)|epiphany|epiphany||org.gnome.Epiphany" # Doesn't work (I didn't check GNOME, I'm stupid)
        "Midori|midori||midori|" # Doesn't work
        "Google Chrome|google-chrome||google-chrome|com.google.Chrome" # Doesn't work but installed  via the post-install.sh script
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

    # Check that Flatpak is installed in the chroot
    if ! /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        print_info "Flatpak missing — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Unable to install Flatpak"
        return 1
    }
    # Enable Flathub if not already configured
    /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

    # Install Steam via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.valvesoftware.Steam; then
        print_success "Steam (Flatpak) successfully installed"
    else
        print_warning "Failed to install Steam (Flatpak). Check your connection or Flathub."
    fi
}

fix_spicetify_prefs() { # Doesn't work because Spotify & spicetify are not installed in the chroot due to multi I don't know what anymore # Maybe it should be removed in the stable version if I don't succeed anyway the post-install succeeds
    print_header "CORRECTION SPICETIFY PREFS (ROBUST, NON-BLOCKING)"

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

# Cumulative state of warnings/errors (but we exit with 0)
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
    ok "Spotify Flatpak detected."
else
    info "Spotify Flatpak not detected."
fi

if [[ "$IS_NATIVE" != true && "$IS_FLATPAK" != true ]]; then
    warn_wrap "No Spotify installation detected (native nor Flatpak)."
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
# Fallback addition just in case I know the script 90% fails this bastard
CANDIDATES+=("${HOME}/.config/spotify/prefs" "${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")

PREFS_PATH=""
for p in "${CANDIDATES[@]}"; do
    if [[ -f "$p" ]]; then
        PREFS_PATH="$p"
        ok "Existing prefs found: $PREFS_PATH"
        break
    fi
done

# If not found, carefully create a skeleton without launching Spotify (because chroot/tty)
if [[ -z "$PREFS_PATH" ]]; then
    # Choose priority target folder
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
        ok "prefs created: $PREFS_PATH (will be completed after the first launch of Spotify)."
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

# 1) Declare the prefs_path
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
    warn_wrap "spicetify: apply failed (probably prefs incomplete before 1st launch)."
    APPLY_OK=false
fi

# Fallback post-install: autostart at 1st real graphical launch  
# If we had to create the prefs empty, or if apply failed, we prepare a user task
# that will retry automatically after the first launch of Spotify.
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
# Wait for Spotify to have generated a "real" prefs, then reapply spicetify
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
    log "prefs still not found/empty, silent abort."
    exit 0
    fi

log "prefs detected: $FOUND"
spicetify config prefs_path "$FOUND" || true
spicetify backup || true
spicetify apply || true

# Self-cleanup: remove this service after success
rm -f "${HOME}/.config/autostart/spicetify-postfirststart.desktop" || true
rm -f "${HOME}/.local/bin/spicetify-postfirststart.sh" || true
exit 0
EOSH
    chmod +x "$FIX_SCRIPT" || true

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Spicetify Post-First-Start
Comment=Finalizes Spicetify after the 1st launch of Spotify
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
        # Don't fail the global script: message and continue
        print_warning "fix_spicetify_prefs: the chroot subcommand returned a non-zero (see user log). Step CONTINUED."
        return 0

    print_success "fix_spicetify_prefs executed (see user log ~/.local/share/spicetify-fix/fix.log in the chroot)."
}

# Utility functions and logging
# Check for the presence of a command in the chroot
chroot_cmd_exists() {
    /usr/bin/arch-chroot /mnt bash -lc "command -v '${1}' >/dev/null 2>&1"
}

# (Re)ensure the installation of paru in the chroot -> Doesn't work either
ensure_paru_in_chroot() {
    # Check if paru is already present in the chroot
    if chroot_cmd_exists paru; then
        print_success "Paru already present in the chroot"
        return 0
    fi

    print_info "Paru absent — installation via AUR in the chroot"

    # Install base-devel and git to compile from AUR
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Unable to install base-devel and git in the chroot"
        return 1
    }

    # Launch installation via dedicated function
    if install_paru; then
        print_success "Paru successfully installed in the chroot"
        return 0
    fi

    print_warning "Paru installation failed — yay fallback attempt"
    install_yay_in_chroot || return 1
}

install_required_commands() {
    print_info "Verification and installation of required commands..."
    
    local missing_pkgs=()
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk" 
        "curl" "git" "timedatectl" "unzip"
    )

    # Check for missing commands
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

    # Ensure unzip also in the target chroot (/mnt)
    if [[ -d /mnt && -d /mnt/usr ]]; then
        if ! /usr/bin/arch-chroot /mnt bash -lc "command -v unzip >/dev/null 2>&1"; then
            print_info "unzip absent in the chroot /mnt — attempt to install in the chroot..."
            /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed unzip || {
                print_warning "Unable to install unzip in the chroot (/mnt). Install it manually: /usr/bin/arch-chroot /mnt pacman -S unzip"
            }
        else
            print_info "unzip already present in the chroot /mnt"
        fi
    fi

    print_success "All required commands are available"
}

# Optimization of Pacman configuration for speed
optimize_pacman() {
    print_header "STEP 3/$TOTAL_STEPS: PACMAN OPTIMIZATION"
    CURRENT_STEP=3

    # Backup original configuration
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
# Removal of [community] because it is no longer in the repositories recently

    # Block rust to avoid rustup conflict # Obsolete since I cleaned up rust & rustup, there's only rustup left
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
        print_success "Mirrors successfully optimized (filtered mode)"
    else
        print_warning "Filtered optimization failed, large mode attempt..."
        # Large fallback: all countries, no strict filtering # This one works
        if reflector --sort score --protocol https --latest 20 \
                        --save /etc/pacman.d/mirrorlist; then
            print_success "Mirrors successfully optimized (large mode)"
        else
            print_warning "Unable to generate a mirrorlist with reflector, ultimate fallback"
            # Ultimate fallback: official archlinux.org mirror
            cat > /etc/pacman.d/mirrorlist <<'EOF'
## Fallback ArchLinux official
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
    
    echo "Installation Arch Linux Fallout - $(date)" >> "$LOG_FILE"
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

# Do I keep in English or not? To think about doing a full English version but with google translate :/
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

# Input validation with minimum password length 6 characters
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
    
    case "$unit" in
        "M"|"m") echo "$number" ;;
        "G"|"g") echo $((number * 1024)) ;;
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
    
    # Boot (BIOS) or EFI (UEFI) configuration
    if [[ "$BOOT_MODE" == "uefi" ]]; then
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
    
    # Root configuration
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
        print_info "Separate /home partition disabled - Will be in Root partition"
    fi
    
    # Configuration summary
    echo ""
    echo -e "${GREEN}CONFIGURATION SUMMARY${NC}"
    echo -e "${WHITE}• Boot mode:${NC} $BOOT_MODE"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${WHITE}• EFI Partition:${NC} $PARTITION_EFI_SIZE (FAT32)"
    else
        echo -e "${WHITE}• Boot Partition:${NC} $PARTITION_BOOT_SIZE (ext4)"
    fi
    echo -e "${WHITE}• Root Partition:${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Swap Partition:${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Home Partition:${NC} Remaining available space"
        else
            echo -e "${WHITE}• Home Partition:${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Home Partition:${NC} Integrated in Root"
    fi
    echo ""
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
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██╗╚██╗██╔╝
███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ 
██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ �╚═╝  ╚═╝                                                                         

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

# Purely decorative because too lazy to make a real menu
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
    • Splashscreen with PipBoy animation
    • Arch logo Plymouth (can be changed via BearGrubChanger, available on my GitHub account: PapaOursPolaire)
    • SDDM configuration with custom Fallout wallpaper (video, .gif or random images for you to change)
    • Icon themes (Tela, Papirus) and modern visual themes

    PROFESSIONAL AUDIO SYSTEM:

    • PipeWire + WirePlumber (professional low latency audio)
    • CAVA (terminal audio visualizer with green Matrix theme)
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
    • Enhanced terminal with Fastfetch and development aliases (to activate via a script from my repo, unavailable in the script for stupid reasons)

    PREINSTALLED WEB NAVIGATION:

    • Firefox (configured for Netflix, Disney+ with DRM)
    • Google Chrome, Chromium, Brave Browser, Google Chrome & Brave are installed in the post-install script
    • DuckDuckGo Browser (privacy) (unavailable for now)

    MULTIMEDIA AND ENTERTAINMENT:

    • Spotify + Spicetify CLI with Dribbblish Nord-Dark theme, installed during post-install script
    • Spicetify Marketplace enabled for extensions
    • VLC, MPV, OBS Studio, Audacity
    • GIMP, Inkscape for design and creation

    GAMING AND WINDOWS COMPATIBILITY:

    • Steam with Proton configured automatically
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

    NEW FEATURES OF VERSION 734.4:

    • Custom partition size configuration
    • Optional separate /home partition with Y/N interface
    • Minimum password reduced to 6 characters
    • Speed optimization with parallel downloads
    • Fixed PipeWire-Jack conflict bug
    • Installation using full bandwidth
    • Fixed 2358 errors referenced by ShellCheck
    • User interface redesign for more clarity
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
    • Patience, as installation may take time (between 30 to 60 minutes according to several tests performed on my trash machines)
    • At least 60GB free disk space
    • RAM: minimum 8GB recommended (4GB minimum), starting from DDR3, I haven't tested DDR1 & 2
    • Execution from Arch Linux ISO

    Post-installation:

    • Automatic reboot proposed
    • Complete installation log saved for consultation and to send to me if problem
    • Post-install verification script included (For software that couldn't be installed in the chroot)
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
                echo "Arch Linux Fallout Edition Complete Installation Script - Version: $SCRIPT_VERSION"
                echo "Features: Pro Audio + Development + Gaming + Navigation + Fallout Themes"
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
    print_header "STEP 1/$TOTAL_STEPS: SYSTEM REQUIREMENTS CHECK"
    CURRENT_STEP=1
    
    # Remove [community] repository if present (no longer exists)
    if grep -q "^\[community\]" /etc/pacman.conf; then
        print_info "Removing [community] repository (merged into extra)"
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
    fi
    
    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        return 1
    fi
    
    # Adapted boot mode verification
    detect_boot_mode
    
    # Check internet connection with multiple hosts
    print_info "Checking internet connection..."
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com")
    local connected=false
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            print_success "Internet connection active (tested: $host)"
            connected=true
            break
        fi
    done
    if [[ "$connected" != true ]]; then
        print_error "No internet connection detected!"
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
        print_warning "Update failed, attempting repair..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Sy --noconfirm || {
            print_error "Unable to update pacman databases"
            return 1
        }
    fi
    
    print_success "Requirements verified for ${BOOT_MODE} mode"
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
    
    # UEFI test
    if [[ -d /sys/firmware/efi ]]; then
        print_success " UEFI system detected"
    else
        print_error " UEFI system required"
        errors=$((errors + 1))
    fi
    
    # Root test
    if [[ $EUID -eq 0 ]]; then
        print_success " Root permissions"
    else
        print_error " Root permissions required"
        errors=$((errors + 1))
    fi
    
    # Disk space test
    local available_space
    available_space=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    if [[ $available_space -gt 2000 ]]; then
        print_success " Sufficient temporary space (${available_space}MB)"
    else
        print_warning " Limited temporary space (${available_space}MB)"
    fi
    
    # RAM test
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
    
    local disks
    mapfile -t disks < <(lsblk -dno NAME | grep -E '^(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "No disk detected!"
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
        read -r -p "Select disk (number):" disk_choice
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && \
            [[ "$disk_choice" -ge 1 ]] && \
            [[ "$disk_choice" -le "${#disks[@]}" ]]; then
            break
        fi
        print_warning "Invalid selection!"
    done
    
    DISK="/dev/${disks[$((disk_choice - 1))]}"
    print_success "Disk selected: $DISK"
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
                # Submenu for option 1
                echo -e "${WHITE}Sub-options:${NC}"
                echo -e "${CYAN}a.${NC} Use a single partition and split it"
                echo -e "${CYAN}b.${NC} Use already created existing partitions"
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
    print_info "Selecting a single partition to split"
    
    # Detect available partitions
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "No partition found on $DISK"
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
        read -r -p "Select the partition to split (number): " part_choice
        if [[ "$part_choice" =~ ^[0-9]+$ ]] && \
           [[ "$part_choice" -ge 1 ]] && \
           [[ "$part_choice" -le "${#partitions[@]}" ]]; then
            local selected_part="/dev/${partitions[$((part_choice - 1))]}"
            break
        fi
        print_warning "Invalid selection!"
    done
    
    # Configure sizes for new partitions
    print_info "Configuring sizes for new partitions"
    configure_custom_partitioning
    
    # Wipe the selected partition and create new partition table
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
    
    # Delete the partition
    parted -s "$selected_part" rm 1 || {
        print_error "Cannot delete partition"
        return 1
    }
    
    # Create new partition table
    parted -s "$selected_part" mklabel gpt || {
        print_error "Cannot create partition table"
        return 1
    }
    
    # Create partitions
    local current_pos=1
    
    # EFI Partition
    local efi_end=$((current_pos + efi_mb))
    parted -s "$selected_part" mkpart primary fat32 ${current_pos}MiB ${efi_end}MiB
    parted -s "$selected_part" set 1 esp on
    EFI_PART="${selected_part}1"
    current_pos=$efi_end
    
    # Root Partition
    local root_end=$((current_pos + root_mb))
    parted -s "$selected_part" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB
    ROOT_PART="${selected_part}2"
    current_pos=$root_end
    
    # Swap Partition (optional)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        parted -s "$selected_part" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB
        SWAP_PART="${selected_part}3"
        current_pos=$swap_end
    fi
    
    # Home Partition (optional)
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
    if confirm_action "Configure a separate Home partition?"; then
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
    
    if confirm_action "Configure a Swap partition?"; then
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

    # Verify disk status
    if ! lsblk "$DISK" >/dev/null 2>&1; then
        print_error "Disk $DISK is not accessible"
        return 1
    fi
}

create_new_partitioning() {
    print_header "CREATING PARTITION LAYOUT"
    
    print_warning "WARNING: All data on $DISK will be erased!"
    
    if ! confirm_action "Confirm disk erasure?"; then
        return 1
    fi

    # Complete and forced disk cleaning
    print_info "Performing complete disk cleanup..."
    
    # Force unmount all partitions
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true
    
    # Clean partition signatures using multiple methods
    print_info "Erasing partition signatures..."
    wipefs -af "$DISK" 2>/dev/null || true
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none 2>/dev/null || true
    
    # Synchronization and waiting
    sync
    sleep 3
    partprobe "$DISK" 2>/dev/null || true
    sleep 3

    # Create partition table according to boot mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Creating GPT table for UEFI..."
        if ! parted -s "$DISK" mklabel gpt; then
            print_error "Failed to create GPT table"
            return 1
        fi
    else
        print_info "Creating MBR table for BIOS..."
        
        # More robust method for MBR
        echo "o\nw\n" | fdisk "$DISK" >/dev/null 2>&1 || {
            # Fallback with parted
            if ! parted -s "$DISK" mklabel msdos; then
                print_error "Failed to create MBR table with all methods"
                return 1
            fi
        }
    fi

    # Synchronization after table creation
    sync
    sleep 2
    partprobe "$DISK" 2>/dev/null || true
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
    else
        print_info "Creating Boot partition (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Failed to create Boot partition"
            return 1
        fi
        parted -s "$DISK" set 1 boot on
        EFI_PART="${DISK}1"
    fi
    current_pos=$boot_end

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
    current_pos=$root_end

    sync
    sleep 1

    # Partition 3: Swap (optional)
    local part_num=3
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Creating Swap partition (${current_pos}MiB-${swap_end}MiB)..."
        if parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB; then
            SWAP_PART="${DISK}3"
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
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        else
            local home_end=$((current_pos + home_mb))
            print_info "Creating Home partition (${current_pos}MiB-${home_end}MiB)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB; then
                HOME_PART="${DISK}${part_num}"
            else
                print_warning "Failed to create Home partition, continuing without separate home"
                USE_SEPARATE_HOME=false
            fi
        fi
    fi

    # Final synchronization
    sync
    sleep 3
    partprobe "$DISK" 2>/dev/null || true
    sleep 3

    # Verify partitions exist
    print_info "Verifying created partitions..."
    local partitions_ok=true
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "ROOT partition not found: $ROOT_PART"
        partitions_ok=false
    fi
    
    if [[ ! -b "$EFI_PART" ]]; then
        print_error "EFI/Boot partition not found: $EFI_PART"
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
        lsblk "$DISK"
        return 1
    fi

    print_success "Partitioning completed successfully"
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
    print_header "STEP 6/$TOTAL_STEPS: FORMATTING PARTITIONS"
    CURRENT_STEP=6
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Formatting simulation"
        return 0
    fi
    
    # Wait for partitions to be available
    print_info "Waiting for partitions to become available..."
    sleep 5
    sync
    partprobe "$DISK" 2>/dev/null || true
    sleep 3
    
    # Verify partitions exist
    print_info "Verifying partitions..."
    local partitions_ok=true
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "ROOT partition not found: $ROOT_PART"
        partitions_ok=false
    fi
    
    if [[ ! -b "$EFI_PART" ]]; then
        print_error "EFI/Boot partition not found: $EFI_PART"
        partitions_ok=false
    fi
    
    if [[ "$partitions_ok" != true ]]; then
        print_error "Missing partitions, cannot format"
        return 1
    fi

    # Preventive unmounting
    print_info "Preventive unmounting..."
    umount -f "$EFI_PART" "$ROOT_PART" "$HOME_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    sleep 2

    # Format EFI/Boot
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Formatting EFI partition: $EFI_PART"
        if mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
            print_success "EFI partition formatted (FAT32)"
        else
            print_error "EFI formatting failed"
            return 1
        fi
    else
        print_info "Formatting Boot partition: $EFI_PART"
        if mkfs.ext4 -F -L 'ArchBoot' "$EFI_PART"; then
            print_success "Boot partition formatted (ext4)"
        else
            print_error "Boot formatting failed"
            return 1
        fi
    fi

    # Format Root
    print_info "Formatting Root partition: $ROOT_PART"
    if mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_success "Root partition formatted (ext4)"
    else
        print_error "Root formatting failed"
        return 1
    fi

    # Format Home (optional)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -b "$HOME_PART" ]]; then
        print_info "Formatting Home partition: $HOME_PART"
        if mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_success "Home partition formatted (ext4)"
        else
            print_warning "Home formatting failed, disabling..."
            USE_SEPARATE_HOME=false
        fi
    fi

    # Configure Swap (optional)
    if [[ "$USE_SWAP" == true ]] && [[ -b "$SWAP_PART" ]]; then
        print_info "Configuring Swap partition: $SWAP_PART"
        if mkswap -L 'ArchSwap' "$SWAP_PART"; then
            if swapon "$SWAP_PART"; then
                print_success "Swap partition configured and activated"
            else
                print_warning "Could not activate swap"
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
    print_header "STEP 7/$TOTAL_STEPS: MOUNTING PARTITIONS"
    CURRENT_STEP=7
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating mounting"
        return 0
    fi
    
    # Verify partitions exist before mounting
    print_info "Verifying partitions before mounting..."
    
    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "CRITICAL: Root partition $ROOT_PART not found for mounting!"
        return 1
    fi
    
    if [[ ! -b "$EFI_PART" ]]; then
        print_error "CRITICAL: Boot/EFI partition $EFI_PART not found for mounting!"
        return 1
    fi
    
    # Unmount any existing mounts
    print_info "Unmounting any existing mounts..."
    if mountpoint -q /mnt; then
        umount -R /mnt || true
    fi
    
    # Create mount point
    mkdir -p /mnt
    
    # Mount Root partition
    print_info "Mounting Root partition: $ROOT_PART on /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Unable to mount Root partition $ROOT_PART"
        return 1
    fi
    print_success "Root partition mounted"
    
    # Mount Boot/EFI partition
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        mkdir -p /mnt/boot/efi
        print_info "Mounting EFI partition: $EFI_PART on /mnt/boot/efi"
        if ! mount "$EFI_PART" /mnt/boot/efi; then
            print_error "Unable to mount EFI partition $EFI_PART"
            return 1
        fi
        print_success "EFI partition mounted"
    else
        mkdir -p /mnt/boot
        print_info "Mounting Boot partition: $EFI_PART on /mnt/boot"
        if ! mount "$EFI_PART" /mnt/boot; then
            print_error "Unable to mount Boot partition $EFI_PART"
            return 1
        fi
        print_success "Boot partition mounted"
    fi
    
    # Mount Home partition (optional)
    if [[ -n "$HOME_PART" ]] && [[ "$USE_SEPARATE_HOME" == true ]] && [[ -b "$HOME_PART" ]]; then
        mkdir -p /mnt/home
        print_info "Mounting Home partition: $HOME_PART on /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Unable to mount Home partition, disabling..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        else
            print_success "Home partition mounted"
        fi
    elif [[ "$USE_SEPARATE_HOME" == true ]] && [[ ! -b "$HOME_PART" ]]; then
        print_warning "Home partition not found, disabling..."
        USE_SEPARATE_HOME=false
        HOME_PART=""
    fi
    
    # Verify mounts
    print_info "Verifying mounts..."
    if ! mountpoint -q /mnt; then
        print_error "Root partition not mounted!"
        return 1
    fi
    
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        if ! mountpoint -q /mnt/boot/efi; then
            print_error "EFI partition not mounted!"
            return 1
        fi
    else
        if ! mountpoint -q /mnt/boot; then
            print_error "Boot partition not mounted!"
            return 1
        fi
    fi
    
    print_success "All partitions mounted successfully for ${BOOT_MODE} mode"
    
    # Show final mount status
    echo ""
    echo -e "${GREEN}MOUNT STATUS:${NC}"
    mount | grep /mnt
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
    
    # Force database update
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
    
    # Base packages adapted for boot mode
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )
    
    # Mode-specific additions
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
        print_info "[DRY RUN] Simulating user creation"
        return 0
    fi

    # Create main user
    while true; do
        read -r -p "Main username: " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Invalid username (min 3 characters, lowercase letters, numbers, hyphens and underscores only, must start with a letter)"
    done

    # Create password for main user
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
            print_warning "Passwords don't match"
        else
            print_warning "Password too short (minimum 6 characters)"
        fi
    done

    # Configure sudo to allow wheel group to execute commands without password
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Sudo configuration for wheel group - NOPASSWD
if ! grep -q "^%wheel ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    # Temporarily disable password requirement for wheel
    sed -i '/^%wheel ALL=(ALL:ALL) ALL/s/^/# /' /etc/sudoers
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
EOF

    # Create main user with password
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Create main user
useradd -m -G wheel,audio,video,storage,optical,network "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Create personal directories
mkdir -p "/home/$USERNAME"/{Documents,Downloads,Images,Videos,Music,Desktop,.ssh}
chown -R "$USERNAME":"$USERNAME" "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
EOF

    print_success "User created: $USERNAME (with passwordless sudo rights)"

    # Create additional users with their own passwords
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
                        print_warning "Passwords don't match"
                    else
                        print_warning "Password too short (minimum 6 characters)"
                    fi
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Create additional user
useradd -m -G wheel,audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd

# Create personal directories
mkdir -p "/home/$additional_user"/{Documents,Downloads,Images,Videos,Music,Desktop,.ssh}
chown -R "$additional_user":"$additional_user" "/home/$additional_user"
chmod 700 "/home/$additional_user/.ssh"
EOF

                print_success "Additional user created: $additional_user (with passwordless sudo rights)"
            else
                print_warning "Invalid username, skipped"
            fi
        done
    fi

    # Configure root password (optional and different)
    if confirm_action "Set a root password? (recommended: NO)"; then
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
                    print_success "Root password set (different from user passwords)"
                    break
                else
                    print_warning "Passwords don't match"
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
    echo -e "${YELLOW}Root account has been disabled for better security${NC}"
    echo -e "${CYAN}Use 'sudo' for commands requiring elevated privileges${NC}"
}

select_desktop() {
    print_header "STEP 11/$TOTAL_STEPS: DESKTOP ENVIRONMENT SELECTION"
    CURRENT_STEP=11
    
    echo -e "${WHITE}Available environments:${NC}"
    echo -e "${CYAN}1.${NC} KDE Plasma"
    echo -e "${CYAN}2.${NC} GNOME"
    echo -e "${CYAN}3.${NC} No graphical interface (server/minimal)"
    echo -e "${CYAN}4.${NC} Hyperland (under development, do not select)" # Besides the external doesn't work either
    
    local choice
    while true; do
        read -r -p "Your choice (1-3): " choice
        case $choice in
            1) DE_CHOICE="kde"; break ;;
            2) DE_CHOICE="gnome"; break ;;
            3) DE_CHOICE="none"; break ;;
            # 4) DE_CHOICE="hyperland"; print_warning "Hyperland is under development"; break ;;
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

# Bootloader and theme functions
configure_grub() {
    print_header "STEP 13/$TOTAL_STEPS: GRUB CONFIGURATION"
    CURRENT_STEP=13

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] GRUB configuration simulation"
        return 0
    fi

    print_info "Installing and configuring GRUB..."

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    cat > /mnt/etc/default/grub <<'EOF'
# GRUB Configuration
GRUB_DEFAULT=0
GRUB_TIMEOUT=15
GRUB_DISTRIBUTOR="Arch Linux - by PapaOursPolaire on GitHub"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""

# Force menu display
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep

# Disable hidden menu
# GRUB_HIDDEN_TIMEOUT=0
# GRUB_HIDDEN_TIMEOUT_QUIET=false

GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

#    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
#       print_error "Failed to generate GRUB configuration"
#        return 1
#    } -> Commented because it prevents Fallout theme installation

    print_success "GRUB configured and installed"
}

install_fallout_theme() {
    print_header "STEP 14/$TOTAL_STEPS: FALLOUT GRUB THEME INSTALLATION"
    CURRENT_STEP=14

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Fallout theme installation simulation"
        return 0
    fi

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installing Git if necessary..."
pacman -Sy --noconfirm --needed git

cd /tmp
echo "[INFO] Cleaning temporary repositories..."
rm -rf fallout-grub-theme

echo "[INFO] Cloning Fallout GRUB repository..."
git clone --depth=1 https://github.com/shvchk/fallout-grub-theme.git

echo "[INFO] Automatic search for folder containing theme.txt..."
THEME_DIR=$(find fallout-grub-theme -type f -name "theme.txt" -printf '%h\n' | head -n1)

if [[ -z "$THEME_DIR" ]]; then
    echo "[ERROR] Unable to find theme.txt in repository."
    echo "[DEBUG] Repository structure:"
    ls -R fallout-grub-theme || true
    exit 1
fi

echo "[INFO] Theme folder detected: $THEME_DIR"
install -d -m 0755 /boot/grub/themes
rm -rf /boot/grub/themes/fallout
cp -a "$THEME_DIR" /boot/grub/themes/fallout

echo "[INFO] Configuring GRUB_THEME in /etc/default/grub..."
if grep -q "^#*GRUB_THEME=" /etc/default/grub; then
    sed -i 's|^#*GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/fallout/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub
fi

echo "[INFO] Regenerating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "[SUCCESS] Fallout theme installed and configured."
EOF
}

# Audio and multimedia functions
install_audio_system() {
    print_header "STEP 16/$TOTAL_STEPS: PIPEWIRE AUDIO SYSTEM INSTALLATION"
    CURRENT_STEP=16

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Audio system installation simulation"
        return 0
    fi

    print_info "Installing PipeWire and audio tools..." # PipeWire doesn't install, I think

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

install_boot_sound() {
    print_header "STEP 17/$TOTAL_STEPS: CONFIGURING BOOT SOUND"
    CURRENT_STEP=17
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating boot sound installation"
        return 0
    fi
    
    # Create sounds directory
    mkdir -p /mnt/usr/share/sounds/fallout
    
    # Download Fallout boot sound
    print_info "Downloading Fallout boot sound..."
    if curl -fL -o /mnt/usr/share/sounds/fallout/boot.wav \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projets/boot.wav' 2>/dev/null; then
        
        print_success "Boot sound downloaded successfully"
        
        # Install audio dependencies
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed alsa-utils || {
            print_warning "Could not install all audio dependencies"
        }
        
        # Systemd service configuration
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
        print_warning "Could not download sound file, creating system beep fallback"
        
        # System beep fallback
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
    
    # Enable the service
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Could not enable boot sound service"
    }
    
    print_success "Boot sound configured"
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
    print_header "STEP 19/$TOTAL_STEPS: DISPLAY MANAGER CONFIGURATION"
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
        print_error "Failed to extract GitHub archive"
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
        print_warning "Warning: background.mp4 video is missing"
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

    print_success "SDDM successfully configured with Fallout theme"
}

configure_kde_lockscreen() {
    # Lockscreen configuration for KDE only (via KSplash QML)
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

    print_info "Configuring automatic KDE Fallout lockscreen..."
    
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

# Variables
THEME_ID="org.kde.falloutlock"
THEME_DIR="/usr/share/plasma/look-and-feel/$THEME_ID"
TEMP_DIR="/tmp/fallout-lockscreen"
LOG_FILE="/var/log/fallout-lockscreen-install.log"

echo "[$(date)] Starting Fallout lockscreen configuration" > "$LOG_FILE"

# Logging functions
log_info() { echo "[INFO] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERROR] $1" | tee -a "$LOG_FILE"; exit 1; }
log_warning() { echo "[WARNING] $1" | tee -a "$LOG_FILE"; }

# Clean previous installations
rm -rf "$TEMP_DIR" "$THEME_DIR"
mkdir -p "$TEMP_DIR"

# Download Fallout lockscreen theme
log_info "Downloading Fallout lockscreen theme..."
if ! curl -fL -o "$TEMP_DIR/fallout-splashscreen4k.zip" "https://github.com/PapaOursPolaire/arch/blob/Projets/fallout-splashscreen4k.zip; then
    log_warning "Download failed, creating basic Fallout theme"
    
    # Create basic Fallout theme
    mkdir -p "$THEME_DIR/contents/components"
    mkdir -p "$THEME_DIR/contents/lockscreen"
    
    # Main metadata file
    cat > "$THEME_DIR/metadata.desktop" <<'META_EOF'
[Desktop Entry]
Name=Fallout Lock Screen
Comment=Fallout-themed lock screen for KDE Plasma
X-KDE-PluginInfo-Author=PapaOursPolaire
X-KDE-PluginInfo-Email=contact@example.com
X-KDE-PluginInfo-Name=org.kde.falloutlock
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://github.com/PapaOursPolaire
X-KDE-PluginInfo-License=GPLv3
X-KDE-PluginInfo-EnabledByDefault=true
X-KDE-PlasmaLookAndFeel-Title=Fallout Lock Screen
X-KDE-PlasmaLookAndFeel-Description=Fallout-themed lock screen with Pip-Boy style
META_EOF

    # Lockscreen component configuration
    cat > "$THEME_DIR/contents/components/falloutlockscreen/metadata.desktop" <<'COMP_META_EOF'
[Desktop Entry]
Name=Fallout Lock Screen
Type=Service
X-KDE-ServiceTypes=Plasma/LockScreen
X-KDE-PluginInfo-Author=PapaOursPolaire
X-KDE-PluginInfo-Email=contact@example.com
X-KDE-PluginInfo-Name=falloutlockscreen
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Website=https://github.com/PapaOursPolaire
X-KDE-PluginInfo-License=GPLv3
X-KDE-PluginInfo-EnabledByDefault=true
COMP_META_EOF

    # Main QML file for lockscreen
    mkdir -p "$THEME_DIR/contents/components/falloutlockscreen/contents/ui"
    cat > "$THEME_DIR/contents/components/falloutlockscreen/contents/ui/main.qml" <<'QML_EOF'
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore

PlasmaCore.FrameSvgItem {
    id: root
    imagePath: "widgets/background"
    
    width: 1920
    height: 1080
    
    Rectangle {
        anchors.fill: parent
        color: "#002b36" // Fallout-style dark green background
        
        // Background image or color
        Image {
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/fallout-background.jpg"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.3
        }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 30
            
            // Fallout logo/text
            Text {
                text: "ARCH LINUX\nFALLOUT EDITION"
                color: "#00ff00" // Fallout fluorescent green
                font.pixelSize: 32
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
            
            // Password field
            PlasmaComponents.TextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
                focus: true
                Layout.preferredWidth: 300
                Layout.alignment: Qt.AlignHCenter
                
                background: Rectangle {
                    color: "#073642"
                    border.color: "#00ff00"
                    border.width: 2
                    radius: 5
                }
                
                onAccepted: {
                    // Authentication logic
                    authenticator.tryUnlock(passwordField.text)
                }
            }
            
            // Unlock button
            PlasmaComponents.Button {
                text: "UNLOCK"
                Layout.alignment: Qt.AlignHCenter
                
                background: Rectangle {
                    color: "#00ff00"
                    radius: 5
                }
                
                onClicked: {
                    authenticator.tryUnlock(passwordField.text)
                }
            }
            
            // Date and time
            Text {
                text: Qt.formatDateTime(new Date(), "dddd, MMMM dd yyyy\nhh:mm:ss AP")
                color: "#00ff00"
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
QML_EOF

else
    # Extract downloaded theme
    log_info "Extracting lockscreen theme..."
    if ! unzip -o "$TEMP_DIR/fallout-splashscreen4k.zip" -d "$TEMP_DIR"; then
        log_error "Archive extraction failed"
    fi
    
    # Find theme directory
    THEME_SOURCE=$(find "$TEMP_DIR" -name "metadata.desktop" -exec dirname {} \; | head -1)
    if [[ -z "$THEME_SOURCE" ]]; then
        log_error "Invalid theme structure - metadata.desktop not found"
    fi
    
    # Copy theme
    mkdir -p "$THEME_DIR"
    cp -r "$THEME_SOURCE"/* "$THEME_DIR/" || log_error "Theme copy failed"
fi

# Set permissions
chmod -R 755 "$THEME_DIR"
chown -R root:root "$THEME_DIR"

# System configuration to force lockscreen theme
log_info "Configuring system to force Fallout lockscreen..."

# SDDM configuration for theme
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/fallout-theme.conf <<'SDDM_EOF'
[Theme]
Current=fallout
CursorTheme=Breeze
Font=Noto Sans
SDDM_EOF

# Plasma configuration to force lockscreen theme
mkdir -p /etc/xdg/plasma-workspace/env
cat > /etc/xdg/plasma-workspace/env/fallout-lockscreen.sh <<'ENV_EOF'
#!/bin/bash
export KSCREENLOCKER_THEME="org.kde.falloutlock"
ENV_EOF
chmod +x /etc/xdg/plasma-workspace/env/fallout-lockscreen.sh

# KScreenLocker configuration
mkdir -p /etc/xdg/kscreenlockerrc
cat > /etc/xdg/kscreenlockerrc <<'LOCKER_EOF'
[Daemon]
Theme=org.kde.falloutlock
Timeout=60
LockOnResume=true
LockOnSuspend=true

[Greeter]
Theme=org.kde.falloutlock
LOCKER_EOF

# Configuration for all future users
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/kscreenlockerrc <<'USER_LOCKER_EOF'
[Daemon]
Theme=org.kde.falloutlock
Timeout=60
LockOnResume=true
LockOnSuspend=true

[Greeter]
Theme=org.kde.falloutlock
USER_LOCKER_EOF

# Force theme via lookandfeeltool
if command -v lookandfeeltool >/dev/null; then
    log_info "Applying lookandfeel theme..."
    lookandfeeltool -a org.kde.breeze.desktop 2>/dev/null || true
    # Lockscreen theme will be applied via system configuration
fi

# Fallback script to ensure theme is applied at startup
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/fallout-lockscreen-helper.desktop <<'AUTO_EOF'
[Desktop Entry]
Type=Application
Name=Fallout Lock Screen Helper
Exec=bash -c "sleep 5 && dbus-send --session --dest=org.kde.ksmserver --type=method_call /KSMServer org.kde.KSMServerInterface.setLockScreenTheme string:org.kde.falloutlock"
Hidden=false
NoDisplay=true
X-KDE-autostart-phase=1
AUTO_EOF

log_info "Fallout lockscreen configuration completed successfully"
EOF

    # Apply configuration for existing user
    if [[ -n "$USERNAME" ]]; then
        print_info "Applying configuration for user $USERNAME..."
        
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -c '
            # Copy lockscreen configuration
            mkdir -p ~/.config
            cp /etc/skel/.config/kscreenlockerrc ~/.config/ 2>/dev/null || true
            
            # Force theme via DBUS (immediate method)
            if command -v dbus-send >/dev/null && [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
                dbus-send --session --dest=org.kde.ksmserver --type=method_call /KSMServer org.kde.KSMServerInterface.setLockScreenTheme string:org.kde.falloutlock 2>/dev/null || true
            fi
            
            echo "Fallout lockscreen configured for user"
        ' || print_warning "Could not configure lockscreen for user"
    fi

    # Restart relevant services
    print_info "Restarting services..."
    /usr/bin/arch-chroot /mnt systemctl restart sddm 2>/dev/null || true
    
    print_success "KDE Fallout lockscreen configured and automatically enabled"
    print_info "Theme will be applied on next lock or reboot"
}

# Functions for installing applications, never worked - REMEMBER TO DELETE IN THE FINAL VERSION
install_paru() {
    print_header "STEP 24/$TOTAL_STEPS: PARU (AUR HELPER) INSTALLATION"
    CURRENT_STEP=24
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating Paru installation"
        return 0
    fi
    
    print_info "Starting Paru installation in chroot..."
    
    /usr/bin/arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

echo "STARTING PARU INSTALLATION"

# Installing dependencies + rustup to be sure
echo "Installing dependencies..."
pacman -Sy --noconfirm --needed base-devel git sudo rust cargo

# Creating temporary user
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
echo "Running makepkg..."
sudo -u builduser makepkg -si --noconfirm
echo "Compilation completed"

# Immediate verification in chroot
echo "IMMEDIATE VERIFICATION"
echo "Current PATH: $PATH"

# Explicitly adding /usr/local/bin to PATH
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
echo "New PATH: $PATH"

# Immediate test
if command -v paru; then
    echo "PARU FOUND: $(which paru)"
    paru --version
else
    echo "Paru not found, searching randomly..."
    find /usr -name "*paru*" -type f 2>/dev/null
    
    # If found elsewhere, create link
    if [[ -f /usr/local/bin/paru ]]; then
        echo "Creating link /usr/local/bin/paru -> /usr/bin/paru"
        ln -sf /usr/local/bin/paru /usr/bin/paru
    fi
fi

# Adding permanent PATH in bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc

# Final test
echo "FINAL TEST"
export PATH="/usr/local/bin:/usr/bin:/bin"
command -v paru && paru --version

# Cleanup (but keep paru!)
echo "Cleaning..."
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
        print_info "Final search for paru..."
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

    print_success "yay successfully installed in chroot"
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

refresh_mirrors() { # To use if download errors in future variables  # Disabled because dysfunctional
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

install_development() {
    print_header "STEP 25/$TOTAL_STEPS: DEVELOPMENT ENVIRONMENT INSTALLATION"
    CURRENT_STEP=25

    # Check and remove rust installed by pacman to avoid conflict with rustup
    print_info "Checking rust/rustup conflict..."
    if /usr/bin/arch-chroot /mnt pacman -Q rust &>/dev/null; then
        /usr/bin/arch-chroot /mnt pacman -Rns --noconfirm rust
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating development environment installation"
        return 0
    fi

    print_info "Installing programming languages and development tools..."

    # List of development packages - Add more if I forgot some
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

# Function to inform user about what will happen - Doesn't work in chroot, available in post-install
vscode_post_install_info() {
    print_info ""
    print_info "  VS CODE INFORMATION:"
    print_info "   VS Code extensions will install automatically"
    print_info "   on first startup of your graphical session."
    print_info "   You can also install them manually with:"
    print_info "   • ~/install-vscode-extensions.sh"
    print_info "   • ~/manual-vscode-setup.sh (simplified version)"
    print_info ""
}

install_web() {
    print_header "STEP 19/$TOTAL_STEPS: INSTALLING WEB BROWSERS"
    CURRENT_STEP=19

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulating web browser installation"
        return 0
    fi

    print_info "Installing web browsers in the system..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'CHROOT_EOF'
set -e

# List of web browsers to install: package:command
web_browsers=(
    "firefox:firefox"
    "chromium:chromium"
    "brave-browser:brave-browser" # Installed in post-install
    "vivaldi-stable:vivaldi" # lost in the forest
    "opera:opera" # buried in the desert of papaoursland
    "torbrowser-launcher:torbrowser-launcher" # disappeared
    "epiphany:epiphany" # didn't know it originally, found in a gloomy forum
    "midori:midori" # same gloomy forum
)

for browser_entry in "${web_browsers[@]}"; do
    IFS=":" read -r browser_pkg browser_cmd <<< "$browser_entry"

    echo "[INFO] Installing $browser_pkg..."

    if command -v "$browser_cmd" &>/dev/null; then
        echo "[WARNING] $browser_pkg is already installed."
    else
        if pacman -S --noconfirm --needed "$browser_pkg"; then
            echo "[SUCCESS] $browser_pkg successfully installed."
        else
            echo "[ERROR] Failed to install $browser_pkg, moving to next."
            continue
        fi
    fi

    # Update MIME cache only if browser is properly installed
    if command -v "$browser_cmd" &>/dev/null; then
        echo "[INFO] Updating MIME cache for $browser_pkg..."
        update-desktop-database /usr/share/applications || true
    else
        echo "[WARNING] $browser_pkg not found after installation, skipping MIME cache."
    fi
done
CHROOT_EOF

    print_success "Web browser installation completed."
}

install_spotify() {
    print_header "STEP 22/$TOTAL_STEPS: SPOTIFY INSTALLATION"
    CURRENT_STEP=22

    # Check that Flatpak is installed in chroot
    if ! chroot_cmd_exists flatpak; then
        print_info "Flatpak absent — installing..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Unable to install Flatpak"
            return 1
        }
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    local spotify_ok=false

    # Attempt Spotify installation via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.spotify.Client; then
        print_success "Spotify (Flatpak) successfully installed"
        spotify_ok=true
    else
        print_warning "Failed Spotify installation (Flatpak, extra-data). Attempting AUR version..."

        if chroot_cmd_exists paru; then
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm spotify-launcher && spotify_ok=true || \
                print_warning "Failed installation via AUR (spotify-launcher)."
        else
            print_warning "Paru absent, unable to install Spotify via AUR."
        fi
    fi

    # Verify Spotify installation
    if [[ "$spotify_ok" == false ]]; then
        print_warning "Spotify could not be installed automatically. It can be installed manually after reboot."
        return 0
    fi

    # Install Spicetify CLI
    if /usr/bin/arch-chroot /mnt command -v spicetify &>/dev/null; then
        print_success "Spicetify already present"
    else
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed spicetify-cli && \
            print_success "Spicetify CLI installed" || \
            print_warning "Failed Spicetify CLI installation"
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

# Safe cleanup of /tmp before font installation (to avoid "No space left on device")
clean_tmp() { # More effective since version 238.0, to remove in final version
    print_header "CLEANING /tmp — Before font installation"
    local CLEAN_TMP_MINUTES="${CLEAN_TMP_MINUTES:-120}"  # files inactive older than X minutes will be deleted
    local LARGE_FILE_MB="${LARGE_FILE_MB:-100}"         # files > X MB will be deleted
    local DRY="${DRY_RUN:-false}"
    local BEFORE_MB AFTER_MB

    # Show state before
    BEFORE_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "Space used /tmp: ${BEFORE_MB} MB (before cleanup)."
    if [[ "$DRY" == "true" ]]; then
        print_info "[DRY RUN] Simulation - no files will be deleted."
        return 0
    fi

    # Safety: don't delete if /tmp is non-standard link
    if [[ ! -d /tmp ]]; then
        print_warning "/tmp not found or not directory — canceling cleanup."
        return 0
    fi

    # Switch to tolerant mode for errors during deletions
    set +e

    # 1) Delete large files (> LARGE_FILE_MB) (regular files)
    print_info "Deleting files > ${LARGE_FILE_MB} MB in /tmp (to free space)..."
    find /tmp -type f -size +"${LARGE_FILE_MB}"M -print -exec rm -f {} \; 2>/dev/null || true

    # 2) Delete files/dirs in /tmp inactive for CLEAN_TMP_MINUTES minutes
    print_info "Deleting entries inactive for > ${CLEAN_TMP_MINUTES} minutes..."
    # Limit depth to 1 to avoid recursively traversing very large trees
    find /tmp -mindepth 1 -maxdepth 1 -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -rf {} \; 2>/dev/null || true

    # 3) Delete old temporary archives (additional safety)
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
    
    # Install Wine and tools
    local wine_packages=(
        wine wine-staging winetricks
        wine-mono wine-gecko
    )
    
    run_with_progress "Installing Wine" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm ${wine_packages[*]}"
    
    # Configure Wine for user
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Failed Wine configuration"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Wine initialization (Windows 10)
export WINEPREFIX=/home/$USERNAME/.wine
wineboot --init >/dev/null 2>&1 || true

# Configure Wine as Windows 10
winecfg /v win10 >/dev/null 2>&1 || true

# Install essential components via Winetricks
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
        print_warning "clean_tmp function absent — minimal /tmp cleanup"
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
        thunderbird # to verify
        telegram-desktop  # to verify
    )
    
    run_with_progress "Installing Internet" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${internet_packages[*]}"
    
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
    # *: Didn't install before version 411, to recheck
    run_with_progress "Installing Multimedia" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${multimedia_packages[*]}"
    
        # Category 3: Gaming (if graphical interface installed) 
        if [[ "$DE_CHOICE" != "none" ]]; then
            print_header "INSTALLING GAMING SOFTWARE"
            print_info "Installing complete Gaming suite..."

            # Ensure multilib in chroot before installing Steam
            /usr/bin/arch-chroot /mnt pacman -Syyu --noconfirm

            # Enable multilib repo if not already enabled (again)
            if ! grep -q "^\[multilib\]" /mnt/etc/pacman.conf; then
                echo "[multilib]" >> /mnt/etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
            fi

            # Update package database with multilib
            /usr/bin/arch-chroot /mnt pacman -Sy


            # Ensure paru is present before any AUR Gaming install
            if ! chroot_cmd_exists paru; then
                print_info "Paru not available — attempting installation via pacman..."
                if /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed paru; then
                    print_success "Paru successfully installed via repositories"
                else
                    print_warning "Binary installation failed — attempting via AUR..."
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


            # Verify Paru in chroot - Still doesn't work
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

            # Install specific AUR packages via paru - Doesn't work yet
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
        #neofetch  -> recently removed from repositories and I think fastfetch is better anyway
        lsb-release # OK
        wget # OK
        curl # OK
        rsync # OK
        ark # IDK
        filelight # IDK
    )

    clean_tmp
    
    run_with_progress "Installing Utilities" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${utility_packages[*]}"
    
    # Category 5: Fonts and themes - To verify as I don't think all fonts were installed
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
    
    run_with_progress "Installing Fonts" 60 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${font_packages[*]}"
    

    /usr/bin/arch-chroot /mnt /bin/bash -lc '
    set -e
    mkdir -p /etc/sysctl.d
    printf "%s\n" "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/99-unprivileged.conf
    '


    sysctl kernel.unprivileged_userns_clone
    # should return: 1 - otherwise screwed

    # Advanced Flatpak configuration
    print_info "Configuring Flatpak and applications..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF' || print_warning "Failed Flatpak configuration"
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
        /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Failed Steam configuration"
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
echo "VERIFYING INSTALLED SOFTWARE"

# Verification of critical software
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

# List of installed packages
echo "Total number of installed packages: $(pacman -Q | wc -l)"
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
    
    # Icons and themes via pacman - CORRECTION: correct package names - not sure as not many are installed, to recheck
    local theme_packages=(
        papirus-icon-theme
        tela-icon-theme
        breeze-icons
        breeze-gtk
        materia-gtk-theme
        qogir-gtk-theme
        sweet-theme-git
    )
    
    # Installation of base themes
    run_with_progress "Installing themes and icons" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed papirus-icon-theme breeze-icons breeze-gtk"
    
    # Additional themes via AUR - Apart from Tela, others weren't installed TO RECHECK
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
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "Failed KDE theme configuration"
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
    # Copy SDDM image as fallback
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png
    fi
}
EOF
    elif [[ "$DE_CHOICE" == "gnome" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "Failed GNOME theme configuration"
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

install_vscode() {
    print_header "STEP 30/$TOTAL_STEPS: VISUAL STUDIO CODE INSTALLATION"
    CURRENT_STEP=30

    # Check if Flatpak is available
    if ! command -v flatpak &>/dev/null; then
        print_info "Flatpak not found - installing..."
        pacman -S --noconfirm --needed flatpak || {
            print_error "Unable to install Flatpak"
            return 1
        }
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    # Install VS Code via Flatpak
    if flatpak install -y flathub com.visualstudio.code; then
        print_success "Visual Studio Code installed via Flatpak"
    else
        print_warning "Failed to install VS Code (com.visualstudio.code)"
    fi

    # Install VSCodium via Flatpak
    if flatpak install -y flathub com.vscodium.codium; then
        print_success "VSCodium installed via Flatpak"
    else
        print_warning "Failed to install VSCodium (com.vscodium.codium)"
    fi
}

generate_postinstall() {
    print_header "STEP 31/$TOTAL_STEPS: POST-INSTALL SCRIPT GENERATION"
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
# Complete post-install tasks for user session usage.
# - Logs ONLY stderr to ~/post-install-errors.log
# - Continues after each failure (displays warning, logs error)
# - Idempotent: re-executable without breaking
#
# Usage:
#   chmod +x ~/post-install.sh
#   ~/post-install.sh
#
# NOTE: adapts some commands according to your distro (script tries to detect package manager)

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

    # Helper: execute command that must be root, try sudo if not root
    run_cmd_sudo() {
    local desc="$1"; shift
    if (( EUID == 0 )); then
        run_cmd "$desc" "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
        run_cmd "$desc" sudo "$@"
        else
        red "[ERROR] sudo not found — cannot execute (root): $desc"
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
        red "[WARN] install_packages: unknown manager, try apt-get/pacman manually"
        return 1 ;;
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
        red "[ERROR] flatpak unavailable, cannot install $ref"
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
        red "[WARN] No AUR helper detected (paru/yay). Ignore $pkg or install an AUR helper."
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
    yellow "[TASK] Debug Steam / verification of 32-bit libraries (lib32)"

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
    yellow "[TASK] Install Android Studio (flatpak preferred)"

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
    yellow "[TASK] Install Spotify and Spicetify (if available)"

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
    yellow "[TASK] Install browsers (Brave / Google Chrome / DuckDuckGo Browser if possible)"

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
        echo "[INFO] Install PipeWire/codecs/fonts manually if needed" >&3
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
    run_cmd "Create .config backup (if absent)" bash -c 'mkdir -p "$HOME/.config.backup" || true; cp -a --backup=numbered "$HOME/.config/." "$HOME/.config.backup/" || true'
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

    # 3) Spotify & Spicetify -> I think I overdid the long name
    install_spotify_and_spicetify

    # 4) Visual Studio Code extensions -> I think I overdid the long name
    install_vscode_extensions_user

    # 5) Browsers
    install_browsers

    # 6) Multimedia & Fonts -> I think I overdid the long name
    install_multimedia_and_fonts

    # 7) Misc user tweaks
    user_misc_tweaks

    # 8) Deploy helper -> I think I overdid the long name
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




# Fastfetch runs automatically -> To reexamine, meanwhile proceed with installation via fastfetch.sh available on the repo
install_fastfetch() {
    print_header "STEP 28/$TOTAL_STEPS: INSTALLING AND CONFIGURING FASTFETCH"
    CURRENT_STEP=28

    if [[ -z "${USERNAME:-}" ]]; then
        print_error "USERNAME not defined. Aborting."
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] install_fastfetch for ${USERNAME}"
        return 0
    fi

    local USER_HOME="/home/${USERNAME}"
    local CHROOT_USER_HOME="/mnt${USER_HOME}"
    local CONFIG_DIR="${CHROOT_USER_HOME}/.config/fastfetch"
    local PROFILE_FILE="${CHROOT_USER_HOME}/.bashrc"
    local INVOKE_MARKER="# fastfetch autostart entry - added by install script"
    local installed_in_chroot=false

    # 1) Install fastfetch
    print_info "Installing fastfetch..."
    
    if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch 2>/dev/null; then
        print_success "fastfetch installed via pacman"
        installed_in_chroot=true
    else
        print_warning "Failed to install via pacman, trying Flatpak..."
        
        # Install via Flatpak
        if /usr/bin/arch-chroot /mnt flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null; then
            print_success "fastfetch installed via Flatpak"
            installed_in_chroot=true
        else
            print_warning "Failed to install via Flatpak"
        fi
    fi

    # 2) Advanced configuration with all modules
    print_info "Configuring fastfetch with complete modules..."
    
    mkdir -p "$CONFIG_DIR" || {
        print_error "Cannot create $CONFIG_DIR"
        return 1
    }

    # Complete configuration with all available modules
    cat > "${CONFIG_DIR}/config.jsonc" <<'FFCFG'
{
    "display": {
        "separator": " : ",
        "keyWidth": 20,
        "keyColor": "#00ff00",
        "valueColor": "#ffffff",
        "showColors": true,
        "barChar": "█",
        "barWidth": 15,
        "barStyle": "gradient"
    },
    "modules": [
        {
            "type": "title",
            "format": "Arch Linux - {user}@{host}",
            "color": "#00ff00"
        },
        {
            "type": "separator",
            "color": "#00ff00"
        },
        {
            "type": "os",
            "key": "System",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "host",
            "key": "Host",
            "format": "{product} {version}",
            "color": "#00ff00"
        },
        {
            "type": "kernel",
            "key": "Kernel",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "uptime",
            "key": "Uptime",
            "format": "{days}d {hours}h {minutes}m",
            "color": "#00ff00"
        },
        {
            "type": "shell",
            "key": "Shell",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "de",
            "key": "Desktop",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "wm",
            "key": "Window Manager",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "terminal",
            "key": "Terminal",
            "format": "{name} {version}",
            "color": "#00ff00"
        },
        {
            "type": "packages",
            "key": "Packages",
            "format": "{count}",
            "color": "#00ff00"
        },
        {
            "type": "cpu",
            "key": "CPU",
            "format": "{name} @ {frequency}",
            "color": "#00ff00"
        },
        {
            "type": "gpu",
            "key": "GPU",
            "format": "{name}",
            "color": "#00ff00"
        },
        {
            "type": "memory",
            "key": "Memory",
            "format": "{used} / {total}",
            "color": "#00ff00"
        },
        {
            "type": "swap",
            "key": "Swap",
            "format": "{used} / {total}",
            "color": "#00ff00"
        },
        {
            "type": "disk",
            "key": "Disk",
            "format": "{used} / {total} ({percent}%)",
            "color": "#00ff00"
        },
        {
            "type": "battery",
            "key": "Battery",
            "format": "{percentage}% ({status})",
            "color": "#00ff00"
        },
        {
            "type": "locale",
            "key": "Locale",
            "format": "{name}",
            "color": "#00ff00"
        },
        {
            "type": "datetime",
            "key": "Date/Time",
            "format": "{date} {time}",
            "color": "#00ff00"
        },
        {
            "type": "publicip",
            "key": "Public IP",
            "format": "{address}",
            "color": "#00ff00"
        },
        {
            "type": "localip",
            "key": "Local IP",
            "format": "{address}",
            "color": "#00ff00"
        },
        {
            "type": "weather",
            "key": "Weather",
            "format": "{location}: {temperature}°C {condition}",
            "color": "#00ff00"
        },
        {
            "type": "processes",
            "key": "Processes",
            "format": "{count}",
            "color": "#00ff00"
        },
        {
            "type": "break",
            "color": "#00ff00"
        },
        {
            "type": "colors",
            "key": "Color Palette",
            "blockStyle": "vertical",
            "color": "#00ff00"
        }
    ],
    "logo": {
        "type": "ascii",
        "source": "arch",
        "color": "#00ff00",
        "padding": {
            "top": 1,
            "right": 2,
            "bottom": 0,
            "left": 0
        }
    }
}
FFCFG

    # 3) Configure autorun in .bashrc
    print_info "Configuring autorun in .bashrc..."
    
    if ! grep -q "$INVOKE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        cat >> "$PROFILE_FILE" <<'BASHRC_FF'
# fastfetch autostart - displays system information in every shell
# Only runs in interactive shells
$INVOKE_MARKER
if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    # Check if we're in a graphical terminal or TTY
    if [[ -n "$DISPLAY" ]] || [[ "$TERM" =~ ^xterm|^rxvt|^screen|^tmux|^linux|^vt ]]; then
        # Use custom configuration if available
        if [[ -f ~/.config/fastfetch/config.jsonc ]]; then
            fastfetch --load-config ~/.config/fastfetch/config.jsonc 2>/dev/null || \
            fastfetch 2>/dev/null
        else
            fastfetch 2>/dev/null
        fi
        echo ""
    fi
fi
BASHRC_FF
    fi

    # 4) Additional configuration for login shells
    local BASHRC_LOGIN="${CHROOT_USER_HOME}/.profile"
    if [[ ! -f "$BASHRC_LOGIN" ]]; then
        touch "$BASHRC_LOGIN"
    fi
    
    if ! grep -q "fastfetch" "$BASHRC_LOGIN" 2>/dev/null; then
        cat >> "$BASHRC_LOGIN" <<'PROFILE_FF'
# Run fastfetch for login shells
if [ -n "$BASH_VERSION" ] && [ -n "$PS1" ] && command -v fastfetch >/dev/null 2>&1; then
    if [[ -f ~/.config/fastfetch/config.jsonc ]]; then
        fastfetch --load-config ~/.config/fastfetch/config.jsonc 2>/dev/null || true
    else
        fastfetch 2>/dev/null || true
    fi
    echo ""
fi
PROFILE_FF
    fi

    # 5) Configuration for Zsh (if installed)
    local ZSHRC="${CHROOT_USER_HOME}/.zshrc"
    if [[ -f "$ZSHRC" ]] || /usr/bin/arch-chroot /mnt command -v zsh >/dev/null 2>&1; then
        if [[ ! -f "$ZSHRC" ]]; then
            touch "$ZSHRC"
        fi
        
        if ! grep -q "fastfetch" "$ZSHRC" 2>/dev/null; then
            cat >> "$ZSHRC" <<'ZSHRC_FF'
# fastfetch for Zsh
if command -v fastfetch >/dev/null 2>&1 && [[ -o interactive ]]; then
    if [[ -f ~/.config/fastfetch/config.jsonc ]]; then
        fastfetch --load-config ~/.config/fastfetch/config.jsonc 2>/dev/null || \
        fastfetch 2>/dev/null
    else
        fastfetch 2>/dev/null
    fi
    echo ""
fi
ZSHRC_FF
        fi
    fi

    # 6) Fix permissions
    /usr/bin/arch-chroot /mnt /bin/bash -lc "chown -R ${USERNAME}:${USERNAME} '/home/${USERNAME}/.config/fastfetch' >/dev/null 2>&1 || true"
    /usr/bin/arch-chroot /mnt /bin/bash -lc "chown ${USERNAME}:${USERNAME} '/home/${USERNAME}/.bashrc' '/home/${USERNAME}/.profile' >/dev/null 2>&1 || true"
    
    if [[ -f "$ZSHRC" ]]; then
        /usr/bin/arch-chroot /mnt /bin/bash -lc "chown ${USERNAME}:${USERNAME} '/home/${USERNAME}/.zshrc' >/dev/null 2>&1 || true"
    fi

    # 7) Create a convenient alias
    local BASHRC_ALIAS="${CHROOT_USER_HOME}/.bash_aliases"
    if [[ ! -f "$BASHRC_ALIAS" ]]; then
        touch "$BASHRC_ALIAS"
    fi
    
    if ! grep -q "alias ff=" "$BASHRC_ALIAS" 2>/dev/null; then
        echo "alias ff='fastfetch --load-config ~/.config/fastfetch/config.jsonc'" >> "$BASHRC_ALIAS"
    fi

    # 8) Test message
    print_info "Testing fastfetch configuration..."
    if /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -c "command -v fastfetch >/dev/null 2>&1"; then
        print_success "Fastfetch configured successfully"
        echo ""
        echo -e "${GREEN}Enabled modules:${NC}"
        echo -e "• ${CYAN}System${NC} - OS, Host, Kernel, Uptime"
        echo -e "• ${CYAN}Shell${NC} - Shell, Desktop, WM, Terminal"
        echo -e "• ${CYAN}Resources${NC} - CPU, GPU, Memory, Swap, Disk"
        echo -e "• ${CYAN}Network${NC} - Public IP, Local IP"
        echo -e "• ${CYAN}Misc${NC} - Battery, Locale, Date/Time, Weather"
        echo -e "• ${CYAN}Visual${NC} - Color Palette, Progress bars"
        echo ""
        echo -e "${YELLOW}Fastfetch will run automatically in:${NC}"
        echo -e "• ${WHITE}Bash terminals${NC} (.bashrc)"
        echo -e "• ${WHITE}Login shells${NC} (.profile)"
        echo -e "• ${WHITE}Zsh${NC} (if installed)"
        echo ""
        echo -e "${PURPLE}Available command:${NC} ${CYAN}ff${NC} - Run fastfetch with configuration"
    else
        print_warning "Fastfetch installed but not accessible in chroot"
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

# GUARANTEED automatic Fastfetch
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

# Create user directories
mkdir -p /home/$USERNAME/{Projets,Scripts,Téléchargements/{Logiciels,Musique,Vidéos},Documents/{Dev,Personnel,Notes},Images/{Screenshots,Wallpapers}}

# Full permissions
chown -R $USERNAME:$USERNAME /home/$USERNAME/
chmod 755 /home/$USERNAME
chmod -R 755 /home/$USERNAME/{Projets,Scripts,Documents,Images}
chmod -R 775 /home/$USERNAME/Téléchargements
EOF
    
    print_info "Final verification of ALL corrections..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo ""
echo "FINAL VERIFICATION OF CORRECTIONS"
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
    grep -q "fastfetch" /home/$USERNAME/.bashrc && echo "    Auto-launch configured"
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
systemctl is-enabled NetworkManager >/dev/null && echo "    NetworkManager enabled"
systemctl --global is-enabled pipewire >/dev/null 2>&1 && echo "    PipeWire enabled"

echo ""
echo "FINAL SUMMARY"
if [[ $theme_ok -ge 2 && "$vscode_ok" == true && $software_count -ge 4 ]]; then
    echo "System ready for use"
else
    echo "Some corrections may require manual intervention because too lazy to create a correction script or debug this script, you think I don't have other scripts on the floor?"
fi
EOF
    
    print_success "Final configuration completed with ALL CORRECTIONS"
}

finish_install() {
    print_header "STEP 32/$TOTAL_STEPS: INSTALLATION FINALIZATION"
    CURRENT_STEP=32
    
    if [[ "$DRY_RUN" == true ]]; then
        print_success " SIMULATION COMPLETED - No actual modifications made"
        echo ""
        echo -e "${YELLOW}For real installation, run without --dry-run${NC}"
        return 0
    fi
    
    print_success "Complete Arch Linux Fallout Edition installation is now finished!"
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
    echo -e "${CYAN}• Desktop Environment:${NC} $DE_CHOICE"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitioning:${NC} Custom"
    echo ""
    
    echo -e "${YELLOW}SPECIFIC INFORMATION FOR ${BOOT_MODE^^} MODE:${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "• Bootloader: GRUB x86_64-efi"
        echo -e "• Partition table: GPT"
        echo -e "• EFI Partition: FAT32"
    else
        echo -e "• Bootloader: GRUB i386-pc"
        echo -e "• Partition table: MBR"
        echo -e "• Boot Partition: ext4"
    fi
    echo ""
    
    # Rest of the function remains identical...
    # [identical content for features display]
    
    # Adapted post-installation instructions
    echo -e "${BLUE} POST-INSTALLATION INSTRUCTIONS:${NC}"
    echo -e "1. ${WHITE}Remove installation media${NC}"
    echo -e "2. ${WHITE}Reboot the system${NC}"
    echo -e "3. ${WHITE}Login with:${NC} ${CYAN}$USERNAME${NC}"
    if [[ "$BOOT_MODE" == "bios" ]]; then
        echo -e "4. ${WHITE}Verify BIOS boots from hard disk${NC}"
    fi
    echo -e "5. ${WHITE}First update:${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo ""
    
    # Log backup
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation.log" 2>/dev/null || true
        print_info "Installation log saved: /home/$USERNAME/installation.log"
    fi
    
    if confirm_action "Reboot now?" "Y"; then
        print_info "Rebooting in 5 seconds..."
        
        print_info "Unmounting partitions..."
        sync
        
        # Clean unmounting
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || print_warning "Partial unmount"
        
        echo ""
        for i in {5..1}; do
            echo -ne "\r${YELLOW} Rebooting in $i seconds... (Ctrl+C to cancel)${NC}"
            sleep 1
        done
        echo ""
        echo ""
        print_success " Rebooting... Welcome to Arch Linux (${BOOT_MODE})!"
        
        reboot
    else
        print_info "Installation completed. Reboot manually when ready."
        echo -e "${YELLOW} Don't forget to remove the bootable USB media!${NC}"
        
        # Manual unmounting
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN} Complete V734.4-BIOS installation! Your Arch Linux system is ready.${NC}"
        echo ""
    fi
}

# Secure entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure paru is present before any AUR Gaming install
    if ! chroot_cmd_exists paru; then
        print_info "Paru not available — automatic (re)installation…"
        ensure_paru_in_chroot || print_warning "Unable to (re)install an AUR helper — AUR Gaming packages will be ignored"
    fi

    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    main "$@"
    
    # Explicit exit
    exit 0
fi
