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
# Version: 524.5, patch 5 of version 524.5
# Updated: 08/26/2025 at 4:43 p.m.
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

Translated with DeepL.com (free version)
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="524.5"
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

# Main function - main entry point
Translated with DeepL.com (free version)

main() {
# Initialization
    init_logging
    parse_arguments "$@"
    echo "Loading resources..."

    # Checks if /usr/bin/arch-chroot is installed, otherwise installs it
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot missing, attempting to install..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERROR] Unable to install arch-install-scripts. Stopping script."
            exit 1
        }
    fi

    # Signal handling
    trap cleanup EXIT INT TERM

    install_required_commands || return 1

    # Display
    show_banner

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "SIMULATION MODE ACTIVE"
        echo -e "${YELLOW}   • No changes will be made${NC}"
        echo -e "${YELLOW}   • All operations will be simulated${NC}"
        echo ""
    fi

    # Full installation sequence
    echo -e "${CYAN}STARTING ARCH LINUX INSTALLATION...${NC}"
    echo ""

    # Phase 1: System preparation
    check_requirements
    test_environment
    optimize_pacman
    
    # Phase 2: Disk and partition configuration
    select_disk
    choose_partitioning
    format_partitions
    mount_partitions
    
    # Phase 3: Base system installation
    install_system
    configure_system
    create_users
    
    # Phase 4: Graphical interface
    select_desktop
    install_desktop
    
    # Phase 5: Bootloader and themes
    configure_grub
    install_fallout_theme
    configure_kde_lockscreen
    
    # Phase 6: Audio and multimedia
    install_audio_system
    install_boot_sound
    configure_plymouth
    configure_sddm
    
    # Phase 7: Applications and software
    install_software
    install_web
    install_spotify
    install_wine

    # Phase 8: Tools and development
    install_paru # -> Doesn't work, never wanted to work even on the session, it's crazy!
    install_development

    # Phase 8 bis: Debugging required for Steam & Spicetify
    install_steam
    #fix_spicetify_prefs  # Internal errors + handled by post-install; useless in the main
    
    # Phase 9: Themes and customization
    install_themes
    install_fastfetch
    
    # Phase 10: Final configuration
    final_config
    generate_postinstall
    finish_install

    print_success "Arch Linux installation completed successfully!"
}

install_web() {
    print_header "INSTALLING WEB BROWSERS"
    browsers=(
        # Check which ones are installed on GNOME & KDE, they are sometimes different
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser" # Doesn't work
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi" # Doesn't work either
        "Opera|opera|opera||com.opera.Opera" # Doesn't work either
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher" # Doesn't work
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
    print_header "INSTALLING STEAM"

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
    print_info "Optimizing Pacman configuration..."

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
    
    # EFI configuration
    while true; do
        read -r -p "EFI partition size (default: 512M): " efi_input
        efi_input=${efi_input:-512M}
        if validate_input "$efi_input" "size"; then
            PARTITION_EFI_SIZE="$efi_input"
            break
        fi
        print_warning "Invalid format! Use: number + M/m or G/g (ex: 512M, 512m, 2G, 2g)"
    done
    
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
    if confirm_action "Create a Swap partition?" "Y"; then
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
    if confirm_action "Create a separate /home partition?" "N"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Options for Home partition:${NC}"
        echo -e "${CYAN}1.${NC} Use remaining available space"
        echo -e "${CYAN}2.${NC} Specify a custom size"
        
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
        print_info "Separate /home partition disabled - It will be in the Root partition"
    fi
    
    # Configuration summary
    echo ""
    echo -e "${GREEN}CONFIGURATION SUMMARY${NC}"
    echo -e "${WHITE}• EFI Partition:${NC} $PARTITION_EFI_SIZE"
    echo -e "${WHITE}• Root Partition:${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Swap Partition:${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Home Partition:${NC} Remaining available space"
        else
            echo -e "${WHITE}• Home Partition:${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Home Partition:${NC} Integrated into Root"
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

    NEW FEATURES OF VERSION 524.5:

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
    print_header "STEP 1/$TOTAL_STEPS: PREREQUISITES VERIFICATION"
    CURRENT_STEP=1
    
    # Immediately remove the [community] repository if present because it no longer exists
    if grep -q "^\[community\]" /etc/pacman.conf; then
        print_info "Removing [community] repository (merged into extra)"
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
    fi
    
    # Check root # Obsolete, root doesn't exist in the ISO TTY lol
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be executed as root!"
        return 1
    fi
    
    # Check UEFI
    if [[ ! -d /sys/firmware/efi ]]; then
        print_error "This script requires a UEFI system!"
        return 1
    fi
    
    # Check Internet connection with multiple hosts
    print_info "Checking Internet connection..."
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com") # 8.8.8.8: google.com & 1.1.1.1: cloudflare.com
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
    
    print_success "Prerequisites verified"
}

test_environment() {
    print_header "INSTALLATION ENVIRONMENT TEST"
    
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
    print_header "STEP 2/$TOTAL_STEPS: DISK SELECTION"
    CURRENT_STEP=2
    
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
    print_header "STEP 3/$TOTAL_STEPS: PARTITIONING CHOICE"
    CURRENT_STEP=3
    
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
                detect_existing_partitions
                return 0
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
}

create_new_partitioning() {
    print_warning "WARNING: All data on $DISK will be erased!"
    
    if ! confirm_action "Confirm disk erasure?"; then
        return 1
    fi
    
    # Automatic or custom configuration
    local disk_size_bytes
    disk_size_bytes=$(lsblk -bno SIZE "$DISK" | head -1)
    local disk_size_gb=$((disk_size_bytes / 1024 / 1024 / 1024))
    
    print_info "Total disk space: ${disk_size_gb}GB"
    
    # If no custom configuration, use default values

    if [[ "$CUSTOM_PARTITIONING" != true ]]; then

        PARTITION_EFI_SIZE="512M"

        PARTITION_ROOT_SIZE="60G"
        
        local ram_gb
        ram_gb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
        PARTITION_SWAP_SIZE="8G"
        
        local remaining_gb=$((disk_size_gb - 1 - 60 - 8))
        if [[ $remaining_gb -ge 20 ]]; then
            USE_SEPARATE_HOME=true
        else
            USE_SEPARATE_HOME=false
        fi
    fi
    
    # Available space validation
    local efi_mb=$(convert_to_mb "$PARTITION_EFI_SIZE")
    local root_mb=$(convert_to_mb "$PARTITION_ROOT_SIZE")
    local swap_mb=0
    local home_mb=0
    
    [[ "$USE_SWAP" == true ]] && swap_mb=$(convert_to_mb "$PARTITION_SWAP_SIZE")
    
    if [[ "$USE_SEPARATE_HOME" == true && "$PARTITION_HOME_SIZE" != "remaining" ]]; then
        home_mb=$(convert_to_mb "$PARTITION_HOME_SIZE")
    fi
    
    local total_required_mb=$((efi_mb + root_mb + swap_mb + home_mb))
    local available_mb=$((disk_size_gb * 1024))
    
    if [[ $total_required_mb -gt $available_mb ]]; then
        print_error "Insufficient space! Required: ${total_required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    echo -e "${GREEN}FINAL CONFIGURATION${NC}"
    echo -e "${WHITE}Disk:${NC} $DISK - ${disk_size_gb}GB"
    echo -e "${WHITE}• EFI:${NC} $PARTITION_EFI_SIZE (FAT32)"
    echo -e "${WHITE}• Root:${NC} $PARTITION_ROOT_SIZE (ext4)"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Swap:${NC} $PARTITION_SWAP_SIZE (linux-swap)"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Home:${NC} Remaining space (ext4)"
        else
            echo -e "${WHITE}• Home:${NC} $PARTITION_HOME_SIZE (ext4)"
        fi
    else
        echo -e "${WHITE}• Home:${NC} Integrated into Root"
    fi
    echo ""
    
    if ! confirm_action "Accept this configuration?"; then
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Partitioning simulation"
        return 0
    fi
    
    # Preventive unmounting
    print_info "Unmounting partitions..."
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true
    
    # Signature cleanup
    print_info "Cleaning existing signatures..."
    wipefs -af "$DISK" || {
        print_warning "wipefs failed, using dd"
        dd if=/dev/zero of="$DISK" bs=1M count=10 status=none || true
    }
    
    sleep 2
    partprobe "$DISK" || true
    sleep 2
    
    # GPT table creation
    print_info "Creating GPT table..."
    parted -s "$DISK" mklabel gpt || {
        print_error "Failed to create GPT table"
        return 1
    }
    
    local current_pos=1
    
    # EFI Partition
    local efi_end=$((current_pos + efi_mb))
    print_info "Creating EFI partition:${current_pos}MiB to ${efi_end}MiB"
    parted -s "$DISK" mkpart primary fat32 ${current_pos}MiB ${efi_end}MiB || {
        print_error "Failed to create EFI partition"
        return 1
    }
    parted -s "$DISK" set 1 esp on || {
        print_error "Failed to configure ESP"
        return 1
    }
    current_pos=$efi_end
    
    # Root Partition
    local root_end=$((current_pos + root_mb))
    print_info "Creating Root partition:${current_pos}MiB to ${root_end}MiB"
    parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB || {
        print_error "Failed to create Root partition"
        return 1
    }
    current_pos=$root_end
    
    # Swap Partition (if enabled)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Creating Swap partition:${current_pos}MiB to ${swap_end}MiB"
        parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB || {
            print_warning "Failed to create Swap partition"
            USE_SWAP=false
        }
        if [[ "$USE_SWAP" == true ]]; then
            current_pos=$swap_end
        fi
    fi
    
    # Home Partition (if enabled)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            print_info "Creating Home partition: ${current_pos}MiB to 100%"
            parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB 100% || {
                print_warning "Failed to create Home partition"
                USE_SEPARATE_HOME=false
            }
        else
            local home_end=$((current_pos + home_mb))
            print_info "Creating Home partition: ${current_pos}MiB to ${home_end}MiB"
            parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB || {
                print_warning "Failed to create Home partition"
                USE_SEPARATE_HOME=false
            }
        fi
    fi
    
    sync
    partprobe "$DISK" || true
    sleep 5
    
    # Detection of created partitions
    print_info "Verifying created partitions..."
    lsblk "$DISK"
    
    local detected_parts
    mapfile -t detected_parts < <(lsblk -rno NAME "$DISK" | grep -E "${DISK##*/}[0-9p]" | head -10)
    
    if [[ ${#detected_parts[@]} -lt 2 ]]; then
        print_error "Not enough partitions detected after creation"
        return 1
    fi
    
    EFI_PART="/dev/${detected_parts[0]}"
    ROOT_PART="/dev/${detected_parts[1]}"
    
    local part_index=2
    if [[ "$USE_SWAP" == true ]] && [[ ${#detected_parts[@]} -gt $part_index ]]; then
        SWAP_PART="/dev/${detected_parts[$part_index]}"
        part_index=$((part_index + 1))
    fi
    
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ ${#detected_parts[@]} -gt $part_index ]]; then
        HOME_PART="/dev/${detected_parts[$part_index]}"
    fi
    
    print_success "Partitions created successfully"
    echo ""
    echo -e "${GREEN}Final partitions:${NC}"
    echo -e "${CYAN}EFI:${NC} $EFI_PART"
    echo -e "${CYAN}Root:${NC} $ROOT_PART"
    [[ -n "$SWAP_PART" ]] && echo -e "${CYAN}Swap:${NC} $SWAP_PART"
    [[ -n "$HOME_PART" ]] && echo -e "${CYAN}Home:${NC} $HOME_PART"
    
    return 0
}

format_partitions() {
    print_header "STEP 4/$TOTAL_STEPS: PARTITION FORMATTING"
    CURRENT_STEP=4
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Formatting simulation"
        return 0
    fi
    
    # Preventive unmounting
    umount -f "$EFI_PART" "$ROOT_PART" "$HOME_PART" "$SWAP_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    
    sleep 2
    
    # EFI Formatting
    print_info "Formatting EFI partition: $EFI_PART"
    if ! mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
        print_warning "FAT32 formatting failed, trying another alternative..."
        wipefs -af "$EFI_PART" || true
        if ! mkfs.fat -F32 "$EFI_PART"; then
            print_error "Unable to format EFI partition"
            return 1
        fi
    fi
    print_success "EFI partition formatted"
    
    # Root Formatting
    print_info "Formatting Root partition: $ROOT_PART"
    if ! mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_warning "ext4 formatting failed, trying with cleanup..."
        wipefs -af "$ROOT_PART" || true
        if ! mkfs.ext4 -F "$ROOT_PART"; then
            print_error "Unable to format Root partition"
            return 1
        fi
    fi
    print_success "Root partition formatted"
    
    # Home Formatting (optional)
    if [[ -n "$HOME_PART" ]] && [[ "$USE_SEPARATE_HOME" == true ]]; then
        print_info "Formatting Home partition: $HOME_PART"
        if ! mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_warning "Home formatting failed, disabling..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        else
            print_success "Home partition formatted"
        fi
    fi
    
    # Swap Configuration (optional)
    if [[ -n "$SWAP_PART" ]] && [[ "$USE_SWAP" == true ]]; then
        print_info "Configuring Swap partition: $SWAP_PART"
        if ! mkswap -L 'ArchSwap' "$SWAP_PART"; then
            print_warning "Swap configuration failed, disabling..."
            USE_SWAP=false
            SWAP_PART=""
        else
            swapon "$SWAP_PART" && print_success "Swap partition configured and activated"
        fi
    fi
    
    sleep 2
    print_success "Formatting completed"
}

mount_partitions() { # Taken directly from the Arch Linux installation guide
    print_header "STEP 5/$TOTAL_STEPS: MOUNTING PARTITIONS"
    CURRENT_STEP=5
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Mounting simulation"
        return 0
    fi
    
    # Unmounting
    if mountpoint -q /mnt; then
        umount -R /mnt || true
    fi
    
    mkdir -p /mnt
    
    # Mount Root
    print_info "Mounting Root partition: $ROOT_PART on /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Unable to mount Root partition"
        return 1
    fi
    
    # Mount EFI
    mkdir -p /mnt/boot/efi
    print_info "Mounting EFI partition: $EFI_PART on /mnt/boot/efi"
    if ! mount "$EFI_PART" /mnt/boot/efi; then
        print_error "Unable to mount EFI partition"
        return 1
    fi
    
    # Mount Home (optional)
    if [[ -n "$HOME_PART" ]] && [[ "$USE_SEPARATE_HOME" == true ]]; then
        mkdir -p /mnt/home
        print_info "Mounting Home partition: $HOME_PART on /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Unable to mount Home partition, disabling..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        else
            print_success "Home partition mounted"
        fi
    fi
    
    print_success "Partitions mounted"
}

# Base system installation functions

install_system() {
    print_header "STEP 6/$TOTAL_STEPS: BASE SYSTEM INSTALLATION"
    CURRENT_STEP=6
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Base system installation simulation"
        return 0
    fi
    
    # Mirror optimization
    print_info "Optimizing Pacman mirrors..."
    if command -v reflector &> /dev/null; then # First optimization dysfunctional
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
    
    # Base packages
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub efibootmrmgr os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )
    
    print_info "Installing base packages..."
    run_with_progress "Base system installation" 300 "pacstrap /mnt ${base_packages[*]}"
    
    print_success "Base system installed"
}

configure_system() {
    print_header "STEP 7/$TOTAL_STEPS: SYSTEM CONFIGURATION"
    CURRENT_STEP=7

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
    print_header "STEP 8/$TOTAL_STEPS: USER CREATION"
    CURRENT_STEP=8

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] User creation simulation"
        return 0
    fi

    while true; do
        read -r -p "Main username: " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Invalid username"
    done

    local password password2
    while true; do
        read -r -s -p "Password (min 6 characters): " password
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

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
useradd -m -G wheel,audio,video,storage,optical,network "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
echo "root:$USER_PASSWORD" | chpasswd
mkdir -p /home/"$USERNAME"/{Documents,Téléchargements,Images,Vidéos,Musique,Bureau}
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"
EOF

    print_success "User created: $USERNAME"

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
                    read -r -s -p "Confirm password: " add_password2
                    echo ""
                    if [[ "$add_password" == "$add_password2" ]]; then
                        break
                    fi
                    print_warning "Passwords don't match"
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
useradd -m -G audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd
mkdir -p /home/"$additional_user"/{Documents,Téléchargements,Images,Vidéos,Musique,Bureau}
chown -R "$additional_user":"$additional_user" /home/"$additional_user"
EOF

                print_success "Additional user created: $additional_user"
            else
                print_warning "Invalid username, ignored"
            fi
        done
    fi
}

select_desktop() {
    print_header "STEP 9/$TOTAL_STEPS: DESKTOP ENVIRONMENT SELECTION"
    CURRENT_STEP=9
    
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
    print_header "STEP 10/$TOTAL_STEPS: DESKTOP ENVIRONMENT INSTALLATION"
    CURRENT_STEP=10
    
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
    print_header "STEP 11/$TOTAL_STEPS: GRUB CONFIGURATION"
    CURRENT_STEP=11

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
    print_header "STEP 12/$TOTAL_STEPS: GRUB FALLOUT THEME INSTALLATION" # I realize the steps are no longer in order, damn it
    CURRENT_STEP=12

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
    print_header "STEP 13/$TOTAL_STEPS: PIPEWIRE AUDIO SYSTEM INSTALLATION"
    CURRENT_STEP=13

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

install_boot_sound() { # Boot sound installation is dysfunctional, we'll have to go fuck ourselves
    print_header "STEP 14/$TOTAL_STEPS: BOOT SOUND BEEP CONFIGURATION"
    CURRENT_STEP=14
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Boot sound installation simulation"
        return 0
    fi
    
    mkdir -p /mnt/usr/share/sounds
    
    # Fallout sound download
    if curl -o /mnt/usr/share/sounds/fallout-bip.mp3 \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projets/FalloutBip.mp3' 2>/dev/null; then # Maybe it's not compatible with .mp3, try .wav?
        
        # Systemd service for MP3 sound
        cat > /mnt/etc/systemd/system/boot-sound.service <<EOF
[Unit]
Description=Boot Sound Fallout
After=default.target

[Service]
Type=oneshot
ExecStart=/usr/bin/mpg123 -a pulse /usr/share/sounds/fallout-bip.mp3
RemainAfterExit=true

[Install]
WantedBy=default.target
EOF
        
        # Install mpg123 to play MP3 - Which is "supposed" to make it compatible
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm mpg123 || {
            print_warning "mpg123 not installed, creating system beep"
            # Fallback to system beep
            cat > /mnt/usr/local/bin/boot-beep <<'EOF'
#!/bin/bash
for i in {1..3}; do
    echo -e '\a'
    sleep 0.2
done
EOF
            chmod +x /mnt/usr/local/bin/boot-beep
            
            cat > /mnt/etc/systemd/system/boot-sound.service <<'EOF'
[Unit]
Description=Boot Beep Sound
DefaultDependencies=false
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/boot-beep
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
        }
    else
        print_warning "Unable to download sound, creating system beep" # fallback that doesn't work either lol
        
        cat > /mnt/usr/local/bin/boot-beep <<'EOF'
#!/bin/bash
for i in {1..3}; do
    echo -e '\a'
    sleep 0.2
done
EOF
        chmod +x /mnt/usr/local/bin/boot-beep
        
        cat > /mnt/etc/systemd/system/boot-sound.service <<'EOF'
[Unit]
Description=Boot Beep Sound
DefaultDependencies=false
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/boot-beep
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Service activation - This probably comes from this
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Unable to activate boot sound service"
    }
    
    print_success "Boot sound beep configured"
}

configure_plymouth() {
    print_header "STEP $((++CURRENT_STEP))/$TOTAL_STEPS: PLYMOUTH CONFIGURATION"

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
    print_header "DISPLAY MANAGER CONFIGURATION (SDDM OR GDM DEPENDING ON ENVIRONMENT)"

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
    print_header "KDE SPLASH CONFIGURATION (look-and-feel)"
    CURRENT_STEP=$((CURRENT_STEP+1))

    # Respect existing global variables, without redeclaring readonly - I'll still put local
    local kde_splash_url="${KDESPLASH_URL:-}"
    local dest_pkg_dir="${LOCKSCREEN_THEME_DIR:-/usr/share/plasma/look-and-feel/org.kde.falloutlock}"

    # Detection: deploy in live system or in chroot /mnt?
    local in_chroot=false
    if [[ -d /mnt && -d /mnt/usr ]]; then
        in_chroot=true
    fi
    local effective_dest
    if $in_chroot; then
        effective_dest="/mnt${dest_pkg_dir}"
    else
        effective_dest="${dest_pkg_dir}"
    fi

    # Simulation mode
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] configure_kde_lockscreen url=${kde_splash_url:-<not defined>} dest=${effective_dest}"
        return 0
    fi

    # Tool checks (extract on host side)
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is required to download splash archive."
        return 1
    fi
    local have_bsdtar=false have_unzip=false
    command -v bsdtar >/dev/null 2>&1 && have_bsdtar=true
    command -v unzip  >/dev/null 2>&1 && have_unzip=true
    if [[ "$have_bsdtar" == false && "$have_unzip" == false ]]; then
        print_error "Neither bsdtar nor unzip available to extract .zip."
        return 1
    fi

    # Temporary workspace (cleaned at end of function)
    local tmp_dir archive_zip theme_root=""
    tmp_dir="$(mktemp -d -t kdesplash.XXXXXXXX)" || { print_error "mktemp failed"; return 1; }
    archive_zip="${tmp_dir}/splash.zip"
    trap 'rm -rf "$tmp_dir" 2>/dev/null || true' RETURN

    # Download
    if [[ -z "${kde_splash_url}" ]]; then
        print_error "KDESPLASH_URL is empty: unable to download theme."
        return 1
    fi
    print_info "Downloading splash from: ${kde_splash_url}"
    if ! curl -fL --retry 3 --connect-timeout 20 -o "$archive_zip" "$kde_splash_url"; then
        print_error "Splash download failed."
        return 1
    fi
    if [[ ! -s "$archive_zip" ]]; then
        print_error "Downloaded archive is empty."
        return 1
    fi

    # Extraction
    print_info "Extracting archive..."
    if $have_bsdtar; then
        if ! bsdtar -C "$tmp_dir" -xf "$archive_zip"; then
            print_error "Extraction failed (bsdtar)."
            return 1
        fi
    else
        if ! unzip -qq -o "$archive_zip" -d "$tmp_dir"; then
            print_error "Extraction failed (unzip)."
            return 1
        fi
    fi

    # Robust theme root detection (handles double subfolder)
    # Look for folder containing metadata.desktop + contents/Splash.qml (or contents/splash/Splash.qml)
    while IFS= read -r dir; do
        if [[ -f "$dir/metadata.desktop" ]] && { [[ -f "$dir/contents/Splash.qml" ]] || [[ -f "$dir/contents/splash/Splash.qml" ]]; }; then
            theme_root="$dir"
            break
        fi
    done < <(find "$tmp_dir" -maxdepth 5 -type d -print)

    if [[ -z "$theme_root" ]]; then
        for dir in "$tmp_dir"/*/fallout-splashscreen4k "$tmp_dir"/* "$tmp_dir"/*/*; do
            [[ -d "$dir" ]] || continue
            if [[ -f "$dir/metadata.desktop" && -d "$dir/contents" ]]; then
                theme_root="$dir"
                break
            fi
        done
    fi

    if [[ -z "$theme_root" ]]; then
        print_error "Unable to locate theme root (metadata.desktop + contents/Splash.qml)."
        return 1
    fi
    print_info "Theme root detected: $theme_root"

    # Destination preparation
    local dest_parent
    dest_parent="$(dirname "$effective_dest")"
    mkdir -p "$dest_parent" || { print_error "Unable to create $dest_parent"; return 1; }

    if [[ -d "$effective_dest" ]]; then
        local backup="${effective_dest}.bak.$(date +%s)"
        print_info "Backing up old theme -> $backup"
        rm -rf "$backup" 2>/dev/null || true
        mv "$effective_dest" "$backup" || print_warning "Backup impossible (permissions?), will overwrite directly."
    fi
    mkdir -p "$effective_dest" || { print_error "Unable to create $effective_dest"; return 1; }

    # Copy (rsync if available else cp -a)
    if command -v rsync >/dev/null 2>&1; then
        print_info "Copying theme (via rsync)…"
        if ! rsync -a --delete "$theme_root"/ "$effective_dest"/; then
            print_error "Copy failed with rsync."
            return 1
        fi
    else
        print_info "Copying theme (cp -a)…"
        if ! cp -a "$theme_root"/. "$effective_dest"/; then
            print_error "Copy failed with cp."
            return 1
        fi
    fi

    # If Splash.qml is at root and not under contents/, fix it
    if [[ -f "$effective_dest/Splash.qml" && ! -f "$effective_dest/contents/Splash.qml" ]]; then
        mkdir -p "$effective_dest/contents"
        mv -f "$effective_dest/Splash.qml" "$effective_dest/contents/Splash.qml" 2>/dev/null || true
    fi

    # Permissions
    chown -R root:root "$effective_dest" || true
    chmod -R u+rwX,go+rX,go-w "$effective_dest" || true

    # Set default KSplash (system): /etc/xdg/ksplashrc
    print_info "Setting default splash via /etc/xdg/ksplashrc"
    if $in_chroot; then
        /usr/bin/arch-chroot /mnt /bin/bash -lc "mkdir -p /etc/xdg && printf '%s\n' '[KSplash]' 'Theme=org.kde.falloutlock' 'Engine=KSplashQML' > /etc/xdg/ksplashrc"
    else
        mkdir -p /etc/xdg
        printf '%s\n' '[KSplash]' 'Theme=org.kde.falloutlock' 'Engine=KSplashQML' > /etc/xdg/ksplashrc
    fi

    print_success "KDE Splashscreen deployed in ${effective_dest}"
    return 0
}

prepare_aur_in_chroot() { # Dysfunctional
    /usr/bin/arch-chroot /mnt bash -lc '
set -e
pacman -Sy --noconfirm --needed base-devel git
echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" >/etc/sudoers.d/01-pacman-nopasswd
chmod 440 /etc/sudoers.d/01-pacman-nopasswd
'
}

# Functions for installing applications, never worked - REMEMBER TO DELETE IN THE FINAL VERSION
install_paru() {
    print_header "INSTALLATION PARU (AUR Helper)"
    
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
    print_header "STEP 18/$TOTAL_STEPS: INSTALLING DEVELOPMENT ENVIRONMENT"
    CURRENT_STEP=18

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
    print_header "INSTALLING SPOTIFY + SPICETIFY" # Doesn't work in chroot, available in post-install -> Recap: Spotify (launcher) installed but not the other stuff

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
    print_header "STEP 21/$TOTAL_STEPS: INSTALLING WINE"
    CURRENT_STEP=21
    
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
    print_header "STEP 22/$TOTAL_STEPS: INSTALLING ESSENTIAL SOFTWARE"
    CURRENT_STEP=22

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
    print_header "STEP 23/$TOTAL_STEPS: INSTALLING THEMES AND ICONS"
    CURRENT_STEP=23
    
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

generate_postinstall() {
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
    print_header "INSTALLING AND CONFIGURING FASTFETCH"

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
    local PROFILE_FILE="${CHROOT_USER_HOME}/.bash_profile"
    local INVOKE_MARKER="# fastfetch autostart entry - added by alpha.sh"
    local FASTFETCH_BIN="/usr/bin/fastfetch"
    local installed_in_chroot=false

    # 1) Check if fastfetch is available in chroot
    if /usr/bin/arch-chroot /mnt /usr/bin/env bash -lc 'command -v fastfetch >/dev/null 2>&1'; then
        print_info "fastfetch already installed in chroot."
        installed_in_chroot=true
    else
        print_info "Attempting to install fastfetch in chroot via pacman..."
        if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch >/dev/null 2>&1; then
            print_success "fastfetch installed via pacman in chroot."
            installed_in_chroot=true
        else
            print_warning "pacman failed to install fastfetch in chroot."
            # try AUR helper if present
            if /usr/bin/arch-chroot /mnt command -v paru >/dev/null 2>&1; then
                print_info "Attempting installation via paru (AUR) in chroot..."
                /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm fastfetch >/dev/null 2>&1 && installed_in_chroot=true || print_warning "paru failed."
            elif /usr/bin/arch-chroot /mnt command -v yay >/dev/null 2>&1; then
                print_info "Attempting installation via yay (AUR) in chroot..."
                /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" yay -S --noconfirm fastfetch >/dev/null 2>&1 && installed_in_chroot=true || print_warning "yay failed."
            else
                print_warning "No AUR helper detected in chroot. If fastfetch is not installed, install it manually or add an AUR helper."
            fi
        fi
    fi

    if [[ "$installed_in_chroot" != true ]]; then
        print_warning "fastfetch not automatically installed in chroot. User configuration will be written, but executable will be missing."
    fi

    # 2) Create user configuration (idempotent)
    mkdir -p "$CONFIG_DIR" || {
        print_error "Cannot create $CONFIG_DIR"
        return 1
    }

    cat > "${CONFIG_DIR}/config.jsonc" <<'FFCFG'
{
    "display": {
    "separator": " : ",
    "keyWidth": 18,
    "showColors": true
    },
    "modules": [
    { "type": "title", "key": "Arch - Powered by alpha.sh" },
    { "type": "ascii", "logo": "arch" },
    { "type": "os" },
    { "type": "host" },
    { "type": "kernel" },
    { "type": "uptime" },
    { "type": "shell" },
    { "type": "de" },
    { "type": "wm" },
    { "type": "terminal" },
    { "type": "cpu" },
    { "type": "gpu" },
    { "type": "memory" },
    { "type": "disk" },
    { "type": "packages" }
    ]
}
FFCFG

    # 3) Fix rights to user in chroot
    /usr/bin/arch-chroot /mnt /bin/bash -lc "chown -R ${USERNAME}:${USERNAME} '/home/${USERNAME}/.config/fastfetch' >/dev/null 2>&1 || true"

    print_success "fastfetch configuration written for ${USERNAME}"

    # 4) Add idempotent invocation in .bash_profile to display fastfetch at login
    #    - Add a block protected by a marker to avoid duplication
    if ! grep -qF "$INVOKE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        cat >> "$PROFILE_FILE" <<'BASHFF'

# fastfetch autostart (displays system info in login shells)
# Only executes in interactive shell and if fastfetch is available.
$INVOKE_MARKER
if [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
    # Avoid fastfetch polluting non-terminal graphical sessions
    if [ -z "$DISPLAY" ] || [[ "$TERM" =~ ^xterm|^rxvt|^screen|^tmux|^linux|^vt ]]; then
    fastfetch --config ~/.config/fastfetch/config.jsonc || true
    fi
fi
BASHFF
        # fix owner
        /usr/bin/arch-chroot /mnt /bin/bash -lc "chown ${USERNAME}:${USERNAME} '/home/${USERNAME}/.bash_profile' >/dev/null 2>&1 || true"
        print_success "fastfetch entry added to $PROFILE_FILE"
    else
        print_info "fastfetch entry already present in $PROFILE_FILE — nothing to do."
    fi

    # 5) Optional: if KDE/XDG user, indicate how to do graphical autostart (don't force terminal)
    print_info "If you want graphical autostart (terminal that launches fastfetch), create a .desktop in ~/.config/autostart that launches your terminal with 'fastfetch' at startup."

    return 0
}

# Functions for final system configuration
final_config() {
    print_header "STEP 25/$TOTAL_STEPS: FINAL CONFIGURATION"
    CURRENT_STEP=25
    
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
    print_header "ARCH LINUX FALLOUT EDITION COMPLETE INSTALLATION FINISHED!"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_success " SIMULATION COMPLETED - No actual modifications made"
        echo ""
        echo -e "${YELLOW}For a real installation, restart without --dry-run${NC}"
        return 0
    fi
    
    print_success "The complete installation of Arch Linux Fallout Edition is now finished!"
    echo ""
    echo -e "${GREEN} COMPLETE INSTALLATION SUMMARY:${NC}"
    echo -e "${CYAN}• Disk :${NC} $DISK"
    echo -e "${CYAN}• Partitions :${NC}"
    echo -e "  - EFI: $EFI_PART ($PARTITION_EFI_SIZE)"
    echo -e "  - Root: $ROOT_PART ($PARTITION_ROOT_SIZE)"
    [[ -n "$HOME_PART" ]] && echo -e "  - Home : $HOME_PART ($PARTITION_HOME_SIZE)"
    [[ -n "$SWAP_PART" ]] && echo -e "  - Swap : $SWAP_PART ($PARTITION_SWAP_SIZE)"
    echo -e "${CYAN}• Hostname :${NC} $HOSTNAME"
    echo -e "${CYAN}• User :${NC} $USERNAME"
    echo -e "${CYAN}• Environment :${NC} $DE_CHOICE"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitioning :${NC} Custom"
    echo ""
    
    echo -e "${YELLOW}INSTALLED FEATURES :${NC}"
    echo ""
    echo -e "${GREEN}BASE SYSTEM :${NC}"
    echo -e "• Complete French configuration (locale, keyboard, timezone)"
    echo -e "• System and network optimizations (BBR, swappiness, limits)"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "• Custom partition configuration"
    [[ "$USE_SEPARATE_HOME" == true ]] && echo -e "• Separate /home partition enabled"
    echo ""
    echo -e "${GREEN}INTERFACE AND THEMES :${NC}"
    echo -e "• Fallout GRUB theme with integrated fallback"
    echo -e "• Fallout boot sound (MP3 or system beep)"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Plymouth splashscreen with PipBoy Fallout animation"
    [[ "$DE_CHOICE" == "kde" ]] && echo -e "• SDDM configuration with Fallout wallpaper"
    echo -e "• Icon themes (Tela, Papirus) and Sweet/Arc themes"
    echo -e "• Additional GRUB themes (BSOL, Minegrub, etc.)"
    echo ""
    echo -e "${GREEN}PROFESSIONAL AUDIO SYSTEM :${NC}"
    echo -e "• PipeWire + WirePlumber (low latency audio)"
    echo -e "• CAVA (configured terminal audio visualizer)"
    echo -e "• PavuControl (graphical audio control)"
    echo -e "• PipeWire-Jack conflict bug fix applied"
    echo ""
    echo -e "${GREEN}DEVELOPMENT :${NC}"
    echo -e "• Languages: Python, Node.js, Java OpenJDK, Go, Rust, C/C++"
    echo -e "• Tools: Git, Docker, cmake, make, gcc, clang"
    echo -e "• IDEs: Visual Studio Code with extensions (Copilot, Python, C++, Java, Tailwind)"
    echo -e "• Android Studio (mobile development)"
    echo -e "• Enhanced terminal with Fastfetch and useful aliases"
    echo ""
    echo -e "${GREEN}WEB BROWSING :${NC}"
    echo -e "• Firefox (configured for Netflix/Disney+ DRM)"
    echo -e "• Google Chrome, Chromium, Brave Browser"
    echo -e "• DuckDuckGo Browser (if available)"
    echo ""
    echo -e "${GREEN}MULTIMEDIA AND ENTERTAINMENT :${NC}"
    echo -e "• Spotify + Spicetify (Dribbblish Nord-Dark theme)"
    echo -e "• VLC, MPV, OBS Studio, Audacity"
    echo -e "• GIMP, Inkscape (design and image)"
    echo ""
    echo -e "${GREEN}GAMING AND COMPATIBILITY :${NC}"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Steam with Proton configured"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Lutris, GameMode"
    echo -e "• Wine + Winetricks (complete Windows compatibility)"
    echo -e "• Wine-mono, Wine-gecko for .NET applications"
    echo ""
    echo -e "${GREEN}  UTILITIES AND TOOLS :${NC}"
    echo -e "• Pre-configured AUR Helper Paru"
    echo -e "• Flatpak with Flathub enabled"
    echo -e "• TimeShift (backups), GParted, KeePassXC"
    echo -e "• Fastfetch with Arch logo and custom configuration"
    echo -e "• Complete Bash configuration with aliases and functions"
    echo ""
    echo -e "${GREEN} V524.5 OPTIMIZATIONS :${NC}"
    echo -e "• Optimized Pacman configuration (ParallelDownloads=10)"
    echo -e "• Optimized mirrors with advanced Reflector"
    echo -e "• Maximized parallel downloads"
    echo -e "• BBR network configuration for maximum performance"
    echo ""
    echo -e "${GREEN} NEW FEATURES V524.5 :${NC}"
    echo -e "• Custom partition size configuration"
    echo -e "• Optional separate /home partition with Y/N interface"
    echo -e "• Minimum password length reduced to 6 characters"
    echo -e "• Definitive fix for PipeWire-Jack conflict bug"
    echo -e "• Automatic partition size validation"
    echo ""
    
    echo -e "${BLUE} POST-INSTALLATION INSTRUCTIONS :${NC}"
    echo -e "1. ${WHITE}Remove the installation media${NC}"
    echo -e "2. ${WHITE}Reboot the system${NC}"
    echo -e "3. ${WHITE}Login with:${NC} ${CYAN}$USERNAME${NC}"
    echo -e "4. ${WHITE}First update:${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo -e "5. ${WHITE}Audio test:${NC} ${CYAN}cava${NC} (visualizer) or ${CYAN}pavucontrol${NC}"
    echo -e "6. ${WHITE}AUR installation:${NC} ${CYAN}paru -S <package>${NC}"
    echo -e "7. ${WHITE}GRUB theme change:${NC} modify ${CYAN}/etc/default/grub${NC}"
    echo -e "8. ${WHITE}Spicetify configuration:${NC} ${CYAN}spicetify apply${NC}"
    echo ""
    
    echo -e "${PURPLE} USEFUL POST-INSTALLATION COMMANDS :${NC}"
    echo -e "• ${WHITE}fastfetch${NC} - System information with Arch logo"
    echo -e "• ${WHITE}cava${NC} - Real-time audio visualizer"
    echo -e "• ${WHITE}audio-restart${NC} - Restart audio system"
    echo -e "• ${WHITE}docker-clean${NC} - Clean Docker"
    echo -e "• ${WHITE}extract <file>${NC} - Extract any archive"
    echo -e "• ${WHITE}serve${NC} - Local Python web server (port 8000)"
    echo -e "• ${WHITE}spicetify apply${NC} - Apply Spotify themes"
    echo -e "• ${WHITE}systemctl --user status pipewire${NC} - Audio system status"
    echo ""
    
    # Log backup
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation.log" 2>/dev/null || true
        print_info "Installation log saved: /home/$USERNAME/installation.log"
    fi
    
    if confirm_action "Do you want to reboot now?" "Y"; then
        print_info "Rebooting in 5 seconds..."
        
        print_info "Unmounting partitions..."
        sync
        
        # Clean unmount
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || print_warning "Partial unmount"
        
        echo ""
        for i in {5..1}; do
            echo -ne "\r${YELLOW} Rebooting in $i seconds... (Ctrl+C to cancel)${NC}"
            sleep 1
        done
        echo ""
        echo ""
        print_success " Rebooting... Welcome to Arch Linux!"
        
        reboot
    else
        print_info "Installation completed. Reboot manually when you wish."
        echo -e "${YELLOW} Don't forget to remove the bootable USB key!${NC}"
        
        # Manual unmount
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN} Complete installation V524.5! Your Arch Linux system is ready.${NC}"
        echo ""
        echo -e "${CYAN}Once rebooted, execute:${NC}"
        echo -e "• ${WHITE}~/post-install.sh${NC} - Post-installation script"
        echo -e "• ${WHITE}fastfetch${NC} - Display system information"
        echo -e "• ${WHITE}cava${NC} - Test audio visualizer"
        echo ""
        echo -e "${PURPLE} Thank you for using the Arch Linux installation script (version 524.5)${NC}"
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
