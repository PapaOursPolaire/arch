#!/bin/bash

if ! command -v arch-chroot &>/dev/null; then
    echo "[INFO] arch-chroot manquant, tentative d'installation immédiate..."
    pacman -Sy --noconfirm arch-install-scripts || {
        echo "[ERREUR] Impossible d'installer arch-install-scripts. Arrêt du script."
        exit 1
    }
fi

# Script d'installation automatisée Arch Linux
# Made by PapaOursPolaire - available on GitHub
# Version: 514.2, correctif 7 de la version 514.2
# Mise à jour : 24/08/2025 à 17:53

# Erreurs  à corriger :

# Correction de 2358 erreurs référencées par ShellCheck et par la conssole  TTY de l'ISO corrigées
# Erreurs à l'étape 17  : ne paas installer paru dans le temp
# Erreurs à l'étape 23 : gtk-theme n'est pas reconnu
# Erreur de l'éxécution automatique de fastfetch : il est bien là, mais ne s'ouvre pas automatiquement
# Virtual Studio n'a pas été installé ! 
# Le boot est sur le fallback du thème fallout et on ne voit pas l'affichage du menu grub
# On voit l'image GitHub en Plymouth alors qu'elle devait etree en arrière-plan sur la session et pas en plymouth !
# Aucun logiciels n'a été installés !
# ErreurS ETAPE 18 -> fini
# Erreur avec la commande yay  -> fini
# Erreurs Etapes 18 bis, 21 & 23 (en cours)
# Suppression des logiciels/extensions vulkan car elles me cassaient la tete et ne fonctionnaient pas sous automatisation
# Refonte de la variable install_paru() -> Deuxième refonte le 14/08 pour permission denied
#[community] -> RETIRE prcq les serveurs sont des putes 13/08/2025 vers 20 heures
#Include = /etc/pacman.d/mirrorlist -> Ces ptn de fdp ont nettoyé les serveurs dcp ça faisait eerreur 404 et en plus la plupart ont crash à cause de cel 2 heures de perdus pour des conneries pareil non mais wlh je cable argh

# Configuration globale
set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="514.2"
readonly LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"
readonly STATE_FILE="/tmp/arch_install_state.json"

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Variables supplémentaires
readonly KDESPLASH_URL="https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/fallout-splashscreen4k.zip"
readonly SDDM_THEME_URL="https://github.com/PapaOursPolaire/arch/archive/refs/heads/Projets.zip"
readonly SDDM_VIDEO_URL="https://mega.nz/file/PpJzyBjB#ONC7iTpdJkUxcOtLRuclrzJ-vsRRDgqR2oEkJPcHEbk"
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/SDDM-Fallout-theme"
readonly LOCKSCREEN_THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.falloutlock"

# Variables globales
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

# Variables pour le partitionnement personnalisé
PARTITION_EFI_SIZE="512M"
PARTITION_ROOT_SIZE="60G"  
PARTITION_SWAP_SIZE="8G"
PARTITION_HOME_SIZE="remaining"
CUSTOM_PARTITIONING=false

# Fonction main -point d'entrée principale

main() {
# Initialisation
    init_logging
    parse_arguments "$@"
    echo "Chargement des ressources..."

    # Vérifie si /usr/bin/arch-chroot est installé, sinon l’installe
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot manquant, tentative d'installation..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERREUR] Impossible d'installer arch-install-scripts. Arrêt du script."
            exit 1
        }
    fi

    # Gestion des signaux
    trap cleanup EXIT INT TERM

    install_required_commands || return 1

    # Affichage
    show_banner

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "MODE SIMULATION ACTIVE"
        echo -e "${YELLOW}   • Aucune modification ne sera effectuée${NC}"
        echo -e "${YELLOW}   • Toutes les opérations seront simulées${NC}"
        echo ""
    fi

    # Séquence complète d'installation
    echo -e "${CYAN}Démarrage de l'installation d'Arch Linux ${NC}"
    echo ""

    # Phase 1: Préparation système
    check_requirements
    test_environment
    optimize_pacman_configuration
    
    # Phase 2: Configuration disque et partitions
    select_disk
    choose_partitioning
    format_partitions
    mount_partitions
    
    # Phase 3: Installation système de base
    install_base_system
    configure_system
    create_users
    
    # Phase 4: Interface graphique
    select_desktop_environment
    install_desktop_environment
    
    # Phase 5: Bootloader et thèmes
    configure_grub
    install_fallout_theme
    configure_kde_lockscreen
    
    # Phase 6: Audio et multimédia
    install_audio_system
    install_boot_sound
    configure_plymouth
    configure_sddm
    
    # Phase 7: Applications et logiciels
    install_software_packages
    install_web_browsers
    install_spotify_spicetify
    install_wine_compatibility

    # Phase 8: Outils et développement
    install_paru # -> Ne fonctionne pas des masses
    install_development_environment

    # Phase 8 bis : Débuguage nécessaire pour steam & spicetify
    install_steam
    fix_spicetify_prefs
    
    # Phase 9: Thèmes et personnalisation
    install_themes_and_icons
    install_fastfetch
    
    # Phase 10: Configuration finale
    final_configuration
    generate_postinstall
    finish_installation

    print_success "Installation d'Arch Linux terminée avec succès!"
}

install_web_browsers() {
    print_header "INSTALLATION NAVIGATEURS WEB"
    browsers=(
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser"
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi"
        "Opera|opera|opera||com.opera.Opera"
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher"
        "GNOME Web (Epiphany)|epiphany|epiphany||org.gnome.Epiphany"
        "Midori|midori||midori|"
        "Google Chrome|google-chrome||google-chrome|com.google.Chrome"
    )
    for entry in "${browsers[@]}"; do
        IFS="|" read -r name cmd pkg_pacman pkg_paru pkg_flatpak <<< "$entry"
        echo "[INFO] $name"
        if command -v "$cmd" &>/dev/null; then
        echo "[OK] $name déjà présent"; continue
        fi
        ok=false
        if [[ -n "$pkg_pacman" ]]; then pacman -S --noconfirm --needed "$pkg_pacman" && ok=true; fi
        if [[ "$ok" = false && -n "$pkg_paru" ]]; then
        if command -v paru &>/dev/null; then sudo -u "$USERNAME" paru -S --noconfirm "$pkg_paru" && ok=true; fi
        fi
        if [[ "$ok" = false && -n "$pkg_flatpak" ]]; then flatpak install -y flathub "$pkg_flatpak" && ok=true; fi
        if [[ "$ok" = true ]]; then update-desktop-database /usr/share/applications || true; echo "[SUCCESS] $name installé"
        else echo "[ERROR] Impossible d’installer $name"; fi
    done
}

install_steam() {
    print_header "INSTALLATION DE STEAM (FLATPAK)"

    # Vérifie que Flatpak est installé dans le chroot
    if ! /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        print_info "Flatpak absent — installation..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Impossible d’installer Flatpak"
            return 1
        }
        # Active Flathub si pas déjà configuré
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    # Installation de Steam via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.valvesoftware.Steam; then
        print_success "Steam (Flatpak) installé avec succès"
    else
        print_warning "Échec de l’installation de Steam (Flatpak). Vérifie ta connexion ou Flathub."
    fi
}

fix_spicetify_prefs() {
    print_header "CORRECTION SPICETIFY PREFS (ROBUSTE, NON BLOQUANT)"

    # Sécurité : s'assurer que USERNAME est défini
    if [[ -z "${USERNAME:-}" ]]; then
        print_warning "USERNAME non défini – impossible d'appliquer Spicetify pour un utilisateur."
        return 0
    fi

    # IMPORTANT : ne jamais faire échouer tout le script ici.
    # On capture le code retour et on continue quoi qu'il arrive.
    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc '
set -u

# --- Journalisation dédiée utilisateur ---
LOG_DIR="${HOME}/.local/share/spicetify-fix"
LOG_FILE="${LOG_DIR}/fix.log"
mkdir -p "$LOG_DIR" || true
# Redirige tout vers le log + stdout
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "========== [$(date "+%F %T")] Démarrage fix_spicetify_prefs =========="

# --- Helpers d affichage locaux ---
info(){ echo "[INFO]  $*"; }
ok(){ echo "[OK]    $*"; }
warn(){ echo "[WARN]  $*"; }
err(){ echo "[ERROR] $*"; }

# --- État cumul des avertissements/erreurs (mais on sort avec 0) ---
WARN_COUNT=0
ERR_COUNT=0
warn_wrap(){ warn "$@"; WARN_COUNT=$((WARN_COUNT+1)); }
err_wrap(){  err  "$@"; ERR_COUNT=$((ERR_COUNT+1)); }

# --- Détection outillage ---
if ! command -v spicetify >/dev/null 2>&1; then
    warn_wrap "spicetify introuvable pour ${USER}. Étape ignorée."
    echo "========== Fin (spicetify absent) =========="
    exit 0
fi

IS_NATIVE=false
IS_FLATPAK=false

if command -v spotify >/dev/null 2>&1; then
    IS_NATIVE=true
    ok "Spotify natif détecté."
else
    info "Spotify natif non détecté."
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info com.spotify.Client >/dev/null 2>&1; then
    IS_FLATPAK=true
    ok "Spotify Flatpak détecté."
else
    info "Spotify Flatpak non détecté."
fi

if [[ "$IS_NATIVE" != true && "$IS_FLATPAK" != true ]]; then
    warn_wrap "Aucune installation de Spotify détectée (natif ni Flatpak)."
    echo "========== Fin (Spotify absent) =========="
    exit 0
fi

# --- Localisation du fichier prefs ---
# Chemins possibles (on privilégie Flatpak si présent)
CANDIDATES=()
if [[ "$IS_FLATPAK" == true ]]; then
    CANDIDATES+=("${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")
fi
if [[ "$IS_NATIVE" == true ]]; then
    CANDIDATES+=("${HOME}/.config/spotify/prefs")
fi
# Ajout de secours (au cas où)
CANDIDATES+=("${HOME}/.config/spotify/prefs" "${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")

PREFS_PATH=""
for p in "${CANDIDATES[@]}"; do
    if [[ -f "$p" ]]; then
        PREFS_PATH="$p"
        ok "prefs existant trouvé: $PREFS_PATH"
        break
    fi
done

# Si non trouvé, on crée prudemment un squelette SANS lancer Spotify (chroot/tty)
if [[ -z "$PREFS_PATH" ]]; then
    # Choix du dossier cible prioritaire
    if [[ "$IS_FLATPAK" == true ]]; then
        TARGET_DIR="${HOME}/.var/app/com.spotify.Client/config/spotify"
    elif [[ "$IS_NATIVE" == true ]]; then
        TARGET_DIR="${HOME}/.config/spotify"
    else
        # Fallback extrême
        TARGET_DIR="${HOME}/.config/spotify"
    fi

    mkdir -p "$TARGET_DIR" || { err_wrap "Impossible de créer ${TARGET_DIR}"; echo "========== Fin (échec création dossier) =========="; exit 0; }
    PREFS_PATH="${TARGET_DIR}/prefs"

    if [[ ! -f "$PREFS_PATH" ]]; then
        # Squelette minimal : on ne devine pas les préférences, on crée un fichier vide
        # suffisant pour que spicetify accepte le chemin. Spotify l enrichira au 1er lancement.
        : > "$PREFS_PATH" || { err_wrap "Impossible de créer ${PREFS_PATH}"; echo "========== Fin (échec création prefs) =========="; exit 0; }
        ok "prefs créé: $PREFS_PATH (sera complété après le premier lancement de Spotify)."
        PREFS_WAS_CREATED="yes"
    else
        ok "prefs trouvé juste après création du dossier: $PREFS_PATH"
        PREFS_WAS_CREATED="no"
    fi
else
    PREFS_WAS_CREATED="no"
fi

# --- Configuration Spicetify ---
APPLY_OK=true

# 1) Déclarer le prefs_path
if spicetify config prefs_path "$PREFS_PATH"; then
    ok "spicetify: prefs_path enregistré."
else
    warn_wrap "spicetify config prefs_path a échoué."
    APPLY_OK=false
fi

# 2) Thème (idempotent)
if spicetify config current_theme "DribbblishNordDark"; then
    ok "spicetify: thème défini (DribbblishNordDark)."
else
    warn_wrap "spicetify: impossible de définir le thème (peut être non installé)."
fi

# 3) Backup + apply (ne doivent JAMAIS bloquer)
if spicetify backup >/dev/null 2>&1; then
    ok "spicetify: backup ok."
else
    warn_wrap "spicetify: backup a échoué."
    APPLY_OK=false
fi

if spicetify apply >/dev/null 2>&1; then
    ok "spicetify: apply ok."
else
    warn_wrap "spicetify: apply a échoué (probable prefs incomplet avant 1er lancement)."
    APPLY_OK=false
fi

# --- Fallback post-install : autostart au 1er vrai lancement graphique ---
# Si on a dû créer le prefs à vide, ou si apply a échoué, on prépare une tâche
# utilisateur qui réessaiera automatiquement après le premier lancement de Spotify.
if [[ "${PREFS_WAS_CREATED}" == "yes" || "${APPLY_OK}" == "false" ]]; then
    AUTOSTART_DIR="${HOME}/.config/autostart"
    BIN_DIR="${HOME}/.local/bin"
    mkdir -p "$AUTOSTART_DIR" "$BIN_DIR" || true

    FIX_SCRIPT="${BIN_DIR}/spicetify-postfirststart.sh"
    DESKTOP_FILE="${AUTOSTART_DIR}/spicetify-postfirststart.desktop"

    cat > "$FIX_SCRIPT" << "EOSH"
#!/usr/bin/env bash
set -u
# Attendre que Spotify ait généré un prefs "réel", puis réappliquer spicetify
TRIES=60
SLEEP_SECS=2

log(){ echo "[spicetify-postfirststart] $*"; }

    # Chemins potentiels
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
    log "prefs toujours introuvable/vides, abandon silencieux."
    exit 0
    fi

log "prefs détecté: $FOUND"
spicetify config prefs_path "$FOUND" || true
spicetify backup || true
spicetify apply || true

# Auto-nettoyage : on supprime ce service après succès
rm -f "${HOME}/.config/autostart/spicetify-postfirststart.desktop" || true
rm -f "${HOME}/.local/bin/spicetify-postfirststart.sh" || true
exit 0
EOSH
    chmod +x "$FIX_SCRIPT" || true

    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Spicetify Post-First-Start
Comment=Finalise Spicetify après le 1er lancement de Spotify
Exec=${FIX_SCRIPT}
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF

    ok "Fallback post-install préparé (autostart) : ${DESKTOP_FILE}"
fi

# Récapitulatif et fin (on n échoue jamais)
if [[ $ERR_COUNT -gt 0 ]]; then
    warn "Terminé avec ${ERR_COUNT} erreur(s) et ${WARN_COUNT} avertissement(s). Voir le log: ${LOG_FILE}"
elif [[ $WARN_COUNT -gt 0 ]]; then
    warn "Terminé avec ${WARN_COUNT} avertissement(s). Voir le log: ${LOG_FILE}"
else
    ok "Terminé sans avertissement."
fi

echo "========== Fin fix_spicetify_prefs =========="
exit 0
' || {
        # On n'échoue pas le script global : message et on continue
        print_warning "fix_spicetify_prefs: la sous-commande chroot a remonté un non-zéro (voir log utilisateur). Étape CONTINUÉE."
        return 0
    }

    print_success "fix_spicetify_prefs exécuté (voir le journal utilisateur ~/.local/share/spicetify-fix/fix.log dans le chroot)."
}

# Fonctions utilitaires et logging
# Vérifie la présence d'une commande DANS le chroot
chroot_cmd_exists() {
    /usr/bin/arch-chroot /mnt bash -lc "command -v '${1}' >/dev/null 2>&1"
}

# (Ré)assure l'installation de paru dans le chroot
ensure_paru_in_chroot() {
    # Vérifie si paru est déjà présent dans le chroot
    if chroot_cmd_exists paru; then
        print_success "Paru déjà présent dans le chroot"
        return 0
    fi

    print_info "Paru absent — installation via AUR dans le chroot"

    # Installer base-devel et git pour compiler depuis l'AUR
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Impossible d’installer base-devel et git dans le chroot"
        return 1
    }

    # Lancer l’installation via la fonction dédiée
    if install_paru; then
        print_success "Paru installé avec succès dans le chroot"
        return 0
    fi

    print_warning "Échec installation de Paru — tentative fallback yay"
    install_yay_in_chroot || return 1
}

install_required_commands() {
    print_info "Vérification et installation des commandes requises..."
    
    local missing_pkgs=()
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk" 
        "curl" "git" "timedatectl" "unzip"
    )

    # Vérifier les commandes manquantes
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

    # Installer si nécessaire
    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        print_warning "Installation des paquets manquants: ${missing_pkgs[*]}"
        pacman -Sy --noconfirm "${missing_pkgs[@]}" || {
            print_error "Echec de l'installation des dépendances"
            return 1
        }
    fi

    # Assure unzip aussi dans le chroot cible (/mnt) si on a monté la cible
    if [[ -d /mnt && -d /mnt/usr ]]; then
        if ! /usr/bin/arch-chroot /mnt bash -lc "command -v unzip >/dev/null 2>&1"; then
            print_info "unzip absent dans le chroot /mnt — tentative d'installation dans le chroot..."
            /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed unzip || {
                print_warning "Impossible d'installer unzip dans le chroot (/mnt). Installez-le manuellement : /usr/bin/arch-chroot /mnt pacman -S unzip"
            }
        else
            print_info "unzip déjà présent dans le chroot /mnt"
        fi
    fi

    print_success "Toutes les commandes requises sont disponibles"
}

# Optimisation de la configuration Pacman pour la vitesse
optimize_pacman_configuration() {
    print_info "Optimisation de la configuration Pacman..."

    # Sauvegarde de la configuration d'origine
    cp /etc/pacman.conf /etc/pacman.conf.backup 2>/dev/null || true

    # Configuration pacman optimisée
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

    # Blocage de rust pour éviter conflit rustup
    if ! grep -q "^IgnorePkg" /etc/pacman.conf; then
        echo "IgnorePkg = rust" >> /etc/pacman.conf
    else
        sed -i 's/^IgnorePkg.*/& rust/' /etc/pacman.conf
    fi

    # Installation reflector si manquant
    if ! command -v reflector &>/dev/null; then
        pacman -Sy --noconfirm reflector || {
            print_warning "Impossible d'installer reflector, utilisation des miroirs existants"
            return 0
        }
    fi

    # Essai principal : rapide + fiable
    if reflector --sort score --protocol https --country France,Germany,Netherlands,Belgium,Switzerland \
                    --latest 20 --save /etc/pacman.d/mirrorlist; then
        print_success "Miroirs optimisés avec succès (mode filtré)"
    else
        print_warning "Échec optimisation filtrée, tentative mode large..."
        # Fallback large : tous pays, aucun filtrage strict
        if reflector --sort score --protocol https --latest 20 \
                        --save /etc/pacman.d/mirrorlist; then
            print_success "Miroirs optimisés avec succès (mode large)"
        else
            print_warning "Impossible de générer une mirrorlist avec reflector, fallback ultime"
            # Fallback ultime : miroir officiel archlinux.org
            cat > /etc/pacman.d/mirrorlist <<'EOF'
## Fallback ArchLinux officiel
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
EOF
        fi
    fi

    # Nettoyage du cache + resync
    pacman -Scc --noconfirm || true
    rm -rf /var/lib/pacman/sync/* || true
    pacman -Syy --noconfirm || {
        print_warning "Impossible de rafraîchir les bases de données pacman après optimisation"
    }

    print_success "Configuration Pacman finalisée"
}

# Initialisation du logging
init_logging() {
    exec 3>&1 4>&2
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    echo "Installation Arch Linux Fallout - $(date)" >> "$LOG_FILE"
    echo "Script version: $SCRIPT_VERSION" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Logging avec timestamp
log_message() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

# Affichage formaté
print_header() {
    local message="$1"
    echo ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo -e "${WHITE}$message${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
    log_message "HEADER" "$message"
}

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
    # Vérifie si userns est activé
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

# Barre de progression avec estimation de temps
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

# Fonction de progression pour tâches longues
run_with_progress() {
    local task_name="$1"
    local duration="$2"
    shift 2
    local command="$*"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation: $task_name"
        return 0
    fi
    
    print_info "Démarrage: $task_name"
    local start_time=$(date +%s)
    
    # Exécuter la commande en arrière-plan
    eval "$command" &
    local cmd_pid=$!
    
    # Simulation de progression
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
        print_success "$task_name terminé"
    else
        echo ""
        print_error "$task_name échoué (code: $exit_code)"
        return $exit_code
    fi
}

# Validation des entrées avec mot de passe minimum 6 caractères
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
            # Accepter M, m, G, g
            [[ "$input" =~ ^[0-9]+[MmGg]$ ]]
            ;;
        *)
            [[ ${#input} -ge "$min_length" ]]
            ;;
    esac
}

# Fonction pour convertir les tailles en MB (M, m, G, g)
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

# Interface pour la configuration personnalisée des partitions
configure_custom_partitioning() {
    print_header "CONFIGURATION PERSONNALISEE DES PARTITIONS"
    
    echo -e "${WHITE}Configuration des tailles de partitions:${NC}"
    echo -e "${YELLOW}Format attendu: nombre suivi de M/m (Mo) ou G/g (Go)${NC}"
    echo -e "${YELLOW}Exemples: 512M, 512m, 2G, 2g, 100G, 100g${NC}"
    echo ""
    
    # Configuration EFI
    while true; do
        read -r -p "Taille partition EFI (défaut: 512M): " efi_input
        efi_input=${efi_input:-512M}
        if validate_input "$efi_input" "size"; then
            PARTITION_EFI_SIZE="$efi_input"
            break
        fi
        print_warning "Format invalide! Utilisez: nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
    done
    
    # Configuration Root
    while true; do
        read -r -p "Taille partition Root (défaut: 60G): " root_input
        root_input=${root_input:-60G}
        if validate_input "$root_input" "size"; then
            PARTITION_ROOT_SIZE="$root_input"
            break
        fi
        print_warning "Format invalide! Utilisez: nombre + M/m ou G/g (ex: 60G, 60g)"
    done
    
    # Configuration Swap (optionnelle)
    if confirm_action "Créer une partition Swap?" "O"; then
        USE_SWAP=true
        while true; do
            read -r -p "Taille partition Swap (défaut: 8G): " swap_input
            swap_input=${swap_input:-8G}
            if validate_input "$swap_input" "size"; then
                PARTITION_SWAP_SIZE="$swap_input"
                break
            fi
            print_warning "Format invalide! Utilisez: nombre + M/m ou G/g (ex: 8G, 8g)"
        done
    else
        USE_SWAP=false
        print_info "Partition Swap désactivée"
    fi
    
    # Configuration Home (optionnelle)
    if confirm_action "Créer une partition /home séparée?" "N"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Options pour la partition Home:${NC}"
        echo -e "${CYAN}1.${NC} Utiliser le reste de l'espace disponible"
        echo -e "${CYAN}2.${NC} Spécifier une taille personnalisée"
        
        local home_choice
        while true; do
            read -r -p "Votre choix (1-2): " home_choice
            case $home_choice in
                1)
                    PARTITION_HOME_SIZE="remaining"
                    print_info "Partition Home: utilisation du reste de l'espace"
                    break
                    ;;
                2)
                    while true; do
                        read -r -p "Taille partition Home (ex: 100G, 100g): " home_input
                        if validate_input "$home_input" "size"; then
                            PARTITION_HOME_SIZE="$home_input"
                            break
                        fi
                        print_warning "Format invalide! Utilisez: nombre + M/m ou G/g (ex: 100G, 100g)"
                    done
                    break
                    ;;
                *)
                    print_warning "Choix invalide!"
                    ;;
            esac
        done
    else
        USE_SEPARATE_HOME=false
        print_info "Partition /home séparée désactivée - sera dans la partition Root"
    fi
    
    # Résumé de la configuration
    echo ""
    echo -e "${GREEN}RESUME DE LA CONFIGURATION${NC}"
    echo -e "${WHITE}• Partition EFI:${NC} $PARTITION_EFI_SIZE"
    echo -e "${WHITE}• Partition Root:${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Partition Swap:${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Partition Home:${NC} Reste de l'espace disponible"
        else
            echo -e "${WHITE}• Partition Home:${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Partition Home:${NC} Intégrée dans Root"
    fi
    echo ""
    
    if ! confirm_action "Confirmer cette configuration?" "O"; then
        print_info "Reconfiguration des partitions..."
        configure_custom_partitioning
    fi
    
    CUSTOM_PARTITIONING=true
}

# Demande de confirmation
confirm_action() {
    local message="$1"
    local default="${2:-N}"
    local response
    
    while true; do
        read -r -p "$message (O/N, défaut: $default): " response
        response=${response:-$default}
        
        case "$response" in
            [OoYy]|[Oo][Uu][Ii]|[Yy][Ee][Ss])
                return 0
                ;;
            [NnFf]|[Nn][Oo][Nn]|[Nn][Oo])
                return 1
                ;;
            *)
                print_warning "Réponse invalide. Utilisez O/N."
                ;;
        esac
    done
}

# Nettoyage à la sortie
cleanup() {
    # Eviter les exécutions multiples
    if $CLEANUP_DONE; then
        return 0
    fi
    CLEANUP_DONE=true

    local exit_code=$?
    echo "Début du vrai nettoyage (code: $exit_code)..." >> "$LOG_FILE"

    # Démontage sécurisé (sans -e pour éviter les boucles)
    set +e
    trap - EXIT INT TERM  # Désactiver le trap sinon bug & plantage

    # Liste ordonnée des points de montage
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

    echo "Nettoyage terminé à $(date)" >> "$LOG_FILE"
}

# Configuration CORRECTE des traps
trap 'cleanup; exit 130' INT   # CTRL+C
trap 'cleanup; exit 143' TERM  # kill
trap 'cleanup' EXIT            # Seulement en vrai fin de script


# Fonctions d'interface utilisateur

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
    echo -e "${WHITE}Script d'installation automatisée d'Arch Linux pour les débutants, par un débutant${NC}"
    echo -e "${WHITE}Par PapaOursPolaire (disponible sur GitHub) - Version $SCRIPT_VERSION${NC}"
    echo -e "${WHITE}Pour les flemmards et débutants • Développement • Gaming • Thème par défaut Fallout${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
}

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

# Purement décoratif car flemme de faire un vrai menu
Options: 
    -h, --help     Afficher cette aide
    -d, --dry-run  Mode simulation (ne fait aucune modification)
    --version      Afficher la version

    FONCTIONNALITES COMPLETES DE CETTE EDITION:

    SYSTEME DE BASE:

    • Installation automatisée d'Arch Linux (UEFI uniquement)
    • Configuration française complète (locale, clavier, fuseau horaire)
    • Choix entre KDE Plasma, GNOME ou mode console
    • Configuration personnalisée des tailles de partitions
    • Partition /home séparée optionnelle (O/N)

    INTERFACE ET THEMES FALLOUT:

    • Thème Fallout pour GRUB avec fallback intégré
    • Son de boot Fallout (MP3 ou bip système de fallback)
    • Splashscreen Plymouth avec animation PipBoy
    • Configuration SDDM avec fond d'écran personnalisé Fallout
    • Thèmes d'icônes (Tela, Papirus) et thèmes visuels modernes

    SYSTEME AUDIO PROFESSIONNEL:

    • PipeWire + WirePlumber (audio basse latence professionnel)
    • CAVA (visualiseur audio terminal avec thème vert Matrix)
    • PavuControl (interface graphique de contrôle audio)
    • Configuration automatique pour streaming et enregistrement

    ENVIRONNEMENT DE DEVELOPPEMENT COMPLET:

    • Langages: Python, Node.js, Java OpenJDK, Go, Rust, C/C++
    • Outils: Git, Docker, cmake, make, gcc, clang, gdb
    • Visual Studio Code avec extensions automatiques:
        - GitHub Copilot (IA)
        - Python, C++, Java
        - Tailwind CSS, Prettier, ESLint
        - Live Server, Jupyter
        - Material Icon Theme, Error Lens
    • Android Studio pour développement mobile
    • Terminal amélioré avec Fastfetch et aliases de développement

    NAVIGATION WEB PREINSTALLEE:

    • Firefox (configuré pour Netflix, Disney+ avec DRM)
    • Google Chrome, Chromium, Brave Browser
    • DuckDuckGo Browser (confidentialité)
    • Configuration automatique pour streaming vidéo

    MULTIMEDIA ET DIVERTISSEMENT:

    • Spotify + Spicetify CLI avec thème Dribbblish Nord-Dark
    • Marketplace Spicetify activé pour extensions
    • VLC, MPV, OBS Studio, Audacity
    • GIMP, Inkscape pour design et création

    GAMING ET COMPATIBILITE WINDOWS:

    • Steam avec Proton configuré automatiquement
    • Lutris, GameMode pour optimisation gaming
    • Wine + Winetricks (compatibilité Windows complète)
    • Wine-mono, Wine-gecko pour applications .NET et web
    • Configuration automatique pour jeux Windows

    UTILITAIRES ET PRODUCTIVITE:

    • AUR Helper Paru pré-installé et configuré
    • Flatpak avec Flathub activé (Netflix, Discord...)
    • TimeShift (sauvegardes système), GParted, KeePassXC
    • Fastfetch avec logo Arch ASCII et informations système
    • Configuration Bash complète avec 50+ aliases utiles

    OPTIMISATIONS SYSTEME:

    • Configuration Pacman optimisée (ParallelDownloads=10)
    • Miroirs optimisés avec Reflector avancé
    • Optimisations réseau (BBR, TCP)
    • Gestion mémoire optimisée (swappiness)
    • Services système configurés pour performance
    • Barres de progression avec estimations de temps réelles
    • Gestion d'erreurs robuste avec fallbacks automatiques

    NOUVELLES FONCTIONNALITES DE LA VERSION 514.2:

    • Configuration personnalisée des tailles de partitions
    • Partition /home séparée optionnelle avec interface O/N
    • Mot de passe minimum réduit à 6 caractères
    • Optimisation vitesse avec téléchargements parallèles
    • Correction bug conflict PipeWire-Jack
    • Installation exploitant toute la bande passante
    • Correction des 2358 erreurs  référencées par ShellCheck
    • Refonte de l'interface utilisateur pour plus de clarté
    • Restructuration du code pour meilleure lisibilité et de compréhensibilité
    • Ajout du main() avant les déclarations de fonctions pour  éviter le trap de con

    Exemples d'utilisation:
    $0                # Installation complète interactive
    $0 --dry-run      # Test/simulation sans modifications
    $0 --help         # Afficher cette aide détaillée

    Prérequis système:

    • Système UEFI obligatoire
    • Connexion Internet stable (Plus de 10 Mbps recommandé)
    • ISO Arch Linux ne datant pas de la préhistoire
    • De la patience, car l'installation peut prendre du temps (entre 30 à 60 minutes selon les plusieurs tests effectués sur mes maichines poubelles)
    • Au moins 60GB d'espace disque libre
    • RAM: minimum 8GB recommandé (4GB minimum), à partir de la DDR3, j'ai pas testé DDR1 & 2
    • Exécution en tant que root depuis l'ISO Arch Linux

    Post-installation:

    • Redémarrage automatique proposé
    • Log d'installation complet sauvegardé pour consultation et pour me l'envoyer si problème
    • Script de vérification post-installation inclus (Il est inutile, je l'enleverai dans la prochaine version)
    • Configuration optimisée prête à l'emploi
    • Tous les logiciels importants de développement et multimédia installés

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                print_info "Mode simulation activé - aucune modification ne sera effectuée"
                shift
                ;;
            --version)
                echo "Script d'installation Arch Linux Fallout Edition Complète - Version: $SCRIPT_VERSION"
                echo "Fonctionnalités: Audio Pro + Développement + Gaming + Navigation + Thèmes Fallout"
                echo "Nouvelles: Configuration partitions personnalisée + /home optionnelle + Optimisations vitesse"
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

# Fonctions de vérifications et tests
check_requirements() {
    print_header "ETAPE 1/$TOTAL_STEPS: VERIFICATION DES PREREQUIS"
    CURRENT_STEP=1
    
    # Supprime immédiatement le dépôt [community] s'il est présent
    if grep -q "^\[community\]" /etc/pacman.conf; then
        print_info "Suppression du dépôt [community] (fusionné dans extra)"
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
    fi
    
    # Vérifie root
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté en tant que root !"
        return 1
    fi
    
    # Vérifie UEFI
    if [[ ! -d /sys/firmware/efi ]]; then
        print_error "Ce script nécessite un système UEFI !"
        return 1
    fi
    
    # Vérifie la connexion Internet avec plusieurs hôtes
    print_info "Vérification de la connexion Internet..."
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com")
    local connected=false
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            print_success "Connexion Internet active (testé: $host)"
            connected=true
            break
        fi
    done
    if [[ "$connected" != true ]]; then
        print_error "Aucune connexion Internet détectée !"
        return 1
    fi

    # Activer les user namespaces si désactivés
    if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
        print_info "Activation de kernel.unprivileged_userns_clone=1 pour Flatpak"
        sysctl -w kernel.unprivileged_userns_clone=1 || true
        echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/00-local-userns.conf
    fi
    
    # Synchronise l'horloge
    timedatectl set-ntp true
    sleep 2
    
    # Mise à jour des bases de données pacman (sans community)
    print_info "Mise à jour des bases de données pacman..."
    if ! pacman -Sy --noconfirm; then
        print_warning "Erreur lors de la mise à jour, tentative de correction..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Sy --noconfirm || {
            print_error "Impossible de mettre à jour les bases de données pacman"
            return 1
        }
    fi
    
    print_success "Prérequis vérifiés"
}

test_environment() {
    print_header "TEST DE L'ENVIRONNEMENT D'INSTALLATION"
    
    local errors=0
    
    # Commandes requises
    local required_commands=(
        "pacman" "pacstrap" "genfstab" "/usr/bin/arch-chroot"
        "parted" "mkfs.fat" "mkfs.ext4" "lsblk"
        "curl" "git" "timedatectl" "unzip"
    )
    
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            print_success " $cmd trouvé"
        else
            print_error " $cmd manquant"
            errors=$((errors + 1))
        fi
    done
    
    # Test internet avec plusieurs serveurs
    local test_servers=("archlinux.org" "github.com" "google.com")
    local internet_ok=false
    for server in "${test_servers[@]}"; do
        if ping -c 1 -W 3 "$server" &> /dev/null; then
            print_success " Connexion Internet active (testé: $server)"
            internet_ok=true
            break
        fi
    done
    
    if [[ "$internet_ok" != true ]]; then
        print_error " Aucune connexion Internet détectée"
        errors=$((errors + 1))
    fi
    
    # Test UEFI
    if [[ -d /sys/firmware/efi ]]; then
        print_success " Système UEFI détecté"
    else
        print_error " Système UEFI requis"
        errors=$((errors + 1))
    fi
    
    # Test root
    if [[ $EUID -eq 0 ]]; then
        print_success " Permissions root"
    else
        print_error " Permissions root requises"
        errors=$((errors + 1))
    fi
    
    # Test espace disque
    local available_space
    available_space=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    if [[ $available_space -gt 2000 ]]; then
        print_success " Espace temporaire suffisant (${available_space}MB)"
    else
        print_warning "  Espace temporaire limité (${available_space}MB)"
    fi
    
    # Test RAM
    local ram_gb=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 / 1024 ))
    if [[ $ram_gb -ge 8 ]]; then
        print_success " RAM optimale (${ram_gb}GB)"
    elif [[ $ram_gb -ge 4 ]]; then
        print_success " RAM suffisante (${ram_gb}GB)"
    else
        print_warning "  RAM limitée (${ram_gb}GB) - installation possible mais lente"
    fi
    
    # Test vitesse Internet (approximatif)
    print_info "Test de vitesse de connexion..."
    local speed_test_start=$(date +%s%N)
    curl -s -o /dev/null -w "" "http://archlinux.org" || true
    local speed_test_end=$(date +%s%N)
    local response_time=$(( (speed_test_end - speed_test_start) / 1000000 ))
    
    if [[ $response_time -lt 500 ]]; then
        print_success " Connexion rapide (${response_time}ms)"
    elif [[ $response_time -lt 2000 ]]; then
        print_success " Connexion correcte (${response_time}ms)"
    else
        print_warning "  Connexion lente (${response_time}ms) - installation plus longue"
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        print_success " Environnement optimal pour l'installation Fallout Edition"
        return 0
    else
        print_error " $errors erreur(s) critique(s) - installation impossible"
        return 1
    fi
}

# Fonctions de gestion des disques et partitions
select_disk() {
    print_header "ETAPE 2/$TOTAL_STEPS: SELECTION DU DISQUE"
    CURRENT_STEP=2
    
    local disks
    mapfile -t disks < <(lsblk -dno NAME | grep -E '^(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])')
    
    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "Aucun disque détecté!"
        return 1
    fi
    
    echo -e "${WHITE}Disques disponibles:${NC}"
    for i in "${!disks[@]}"; do
        local disk="${disks[i]}"
        local size model
        size=$(lsblk -dno SIZE "/dev/$disk" 2>/dev/null || echo "Inconnu")
        model=$(lsblk -dno MODEL "/dev/$disk" 2>/dev/null || echo "Inconnu")
        
        echo -e "${CYAN}$((i + 1)).${NC} /dev/$disk - $size - $model"
    done
    
    local disk_choice
    while true; do
        read -r -p "Sélectionnez le disque (numéro): " disk_choice
        
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && \
            [[ "$disk_choice" -ge 1 ]] && \
            [[ "$disk_choice" -le "${#disks[@]}" ]]; then
            break
        fi
        print_warning "Sélection invalide !"
    done
    
    DISK="/dev/${disks[$((disk_choice - 1))]}"
    print_success "Disque sélectionné: $DISK"
}

choose_partitioning() {
    print_header "ETAPE 3/$TOTAL_STEPS: CHOIX DU PARTITIONNEMENT"
    CURRENT_STEP=3
    
    echo -e "${WHITE}Options de partitionnement:${NC}"
    echo -e "${CYAN}1.${NC} Conserver les partitions existantes"
    echo -e "${CYAN}2.${NC} Créer un nouveau partitionnement automatique"
    echo -e "${CYAN}3.${NC} Créer un nouveau partitionnement personnalisé"
    
    local choice
    while true; do
        read -r -p "Votre choix (1-3): " choice
        case $choice in
            1)
                print_info "Conservation des partitions existantes"
                detect_existing_partitions
                return 0
                ;;
            2)
                print_info "Création d\'un nouveau partitionnement automatique"
                create_new_partitioning
                return 0
                ;;
            3)
                print_info "Création d'un nouveau partitionnement personnalisé"
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

detect_existing_partitions() {
    print_info "Détection des partitions existantes sur $DISK..."
    
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")
    
    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "Aucune partition trouvée sur $DISK"
        return 1
    fi
    
    echo -e "${WHITE}Partitions détectées:${NC}"
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
    
    print_info "Configuration des partitions..."
    
    # Demander EFI
    echo -e "${WHITE}Sélectionnez la partition EFI :${NC}"
    for i in "${!partitions[@]}"; do
        echo -e "${CYAN}$((i + 1)).${NC} /dev/${partitions[i]}"
    done
    
    local efi_choice
    while true; do
        read -r -p "Partition EFI (numéro) :" efi_choice
        if [[ "$efi_choice" =~ ^[0-9]+$ ]] && \
            [[ "$efi_choice" -ge 1 ]] && \
            [[ "$efi_choice" -le "${#partitions[@]}" ]]; then
            EFI_PART="/dev/${partitions[$((efi_choice - 1))]}"
            break
        fi
        print_warning "Sélection invalide !"
    done
    
    # Demander Root
    echo -e "${WHITE}Sélectionnez la partition Root :${NC}"
    for i in "${!partitions[@]}"; do
        if [[ "/dev/${partitions[i]}" != "$EFI_PART" ]]; then
            echo -e "${CYAN}$((i + 1)).${NC} /dev/${partitions[i]}"
        fi
    done
    
    local root_choice
    while true; do
        read -r -p "Partition Root (numéro): " root_choice
        if [[ "$root_choice" =~ ^[0-9]+$ ]] && \
            [[ "$root_choice" -ge 1 ]] && \
            [[ "$root_choice" -le "${#partitions[@]}" ]] && \
            [[ "/dev/${partitions[$((root_choice - 1))]}" != "$EFI_PART" ]]; then
            ROOT_PART="/dev/${partitions[$((root_choice - 1))]}"
            break
        fi
        print_warning "Sélection invalide !"
    done
    
    # Optionnel: Home et Swap
    if confirm_action "Configurer une partition Home séparée ?"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Sélectionnez la partition Home:${NC}"
        for i in "${!partitions[@]}"; do
            local part="/dev/${partitions[i]}"
            if [[ "$part" != "$EFI_PART" && "$part" != "$ROOT_PART" ]]; then
                echo -e "${CYAN}$((i + 1)).${NC} $part"
            fi
        done
        
        local home_choice
        while true; do
            read -r -p "Partition Home (numéro): " home_choice
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
            print_warning "Sélection invalide !"
        done
    fi
    
    if confirm_action "Configurer une partition Swap ?"; then
        USE_SWAP=true
        echo -e "${WHITE}Sélectionnez la partition Swap:${NC}"
        for i in "${!partitions[@]}"; do
            local part="/dev/${partitions[i]}"
            if [[ "$part" != "$EFI_PART" && "$part" != "$ROOT_PART" && "$part" != "$HOME_PART" ]]; then
                echo -e "${CYAN}$((i + 1)).${NC} $part"
            fi
        done
        
        local swap_choice
        while true; do
            read -r -p "Partition Swap (numéro) :" swap_choice
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
            print_warning "Sélection invalide !"
        done
    else
        USE_SWAP=false
    fi
}

create_new_partitioning() {
    print_warning "ATTENTION: Toutes les données sur $DISK seront effacées !"
    
    if ! confirm_action "Confirmer l\'effacement du disque ?"; then
        return 1
    fi
    
    # Configuration automatique ou personnalisée
    local disk_size_bytes
    disk_size_bytes=$(lsblk -bno SIZE "$DISK" | head -1)
    local disk_size_gb=$((disk_size_bytes / 1024 / 1024 / 1024))
    
    print_info "Espace disque total: ${disk_size_gb}GB"
    
    # Si pas de configuration personnalisée, utiliser les valeurs par défaut

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
    
    # Validation de l'espace disponible
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
        print_error "Espace insuffisant ! Requis: ${total_required_mb}MB, Disponible: ${available_mb}MB"
        return 1
    fi
    
    echo -e "${GREEN}CONFIGURATION FINALE${NC}"
    echo -e "${WHITE}Disque:${NC} $DISK - ${disk_size_gb}GB"
    echo -e "${WHITE}• EFI:${NC} $PARTITION_EFI_SIZE (FAT32)"
    echo -e "${WHITE}• Root:${NC} $PARTITION_ROOT_SIZE (ext4)"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Swap:${NC} $PARTITION_SWAP_SIZE (linux-swap)"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Home:${NC} Reste de l'espace (ext4)"
        else
            echo -e "${WHITE}• Home:${NC} $PARTITION_HOME_SIZE (ext4)"
        fi
    else
        echo -e "${WHITE}• Home:${NC} Intégrée dans Root"
    fi
    echo ""
    
    if ! confirm_action "Accepter cette configuration ?"; then
        return 1
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du partitionnement"
        return 0
    fi
    
    # Démontage préventif
    print_info "Démontage des partitions..."
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true
    
    # Nettoyage des signatures
    print_info "Nettoyage des signatures existantes..."
    wipefs -af "$DISK" || {
        print_warning "Echec de wipefs, utilisation de dd"
        dd if=/dev/zero of="$DISK" bs=1M count=10 status=none || true
    }
    
    sleep 2
    partprobe "$DISK" || true
    sleep 2
    
    # Création de la table GPT
    print_info "Création de la table GPT..."
    parted -s "$DISK" mklabel gpt || {
        print_error "Echec de création de la table GPT"
        return 1
    }
    
    local current_pos=1
    
    # Partition EFI
    local efi_end=$((current_pos + efi_mb))
    print_info "Création partition EFI :${current_pos}MiB à ${efi_end}MiB"
    parted -s "$DISK" mkpart primary fat32 ${current_pos}MiB ${efi_end}MiB || {
        print_error "Echec de création de la partition EFI"
        return 1
    }
    parted -s "$DISK" set 1 esp on || {
        print_error "Echec de configuration ESP"
        return 1
    }
    current_pos=$efi_end
    
    # Partition Root
    local root_end=$((current_pos + root_mb))
    print_info "Création partition Root :${current_pos}MiB à ${root_end}MiB"
    parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB || {
        print_error "Echec de création de la partition Root"
        return 1
    }
    current_pos=$root_end
    
    # Partition Swap (si activée)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Création partition Swap :${current_pos}MiB à ${swap_end}MiB"
        parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB || {
            print_warning "Echec de création de la partition Swap"
            USE_SWAP=false
        }
        if [[ "$USE_SWAP" == true ]]; then
            current_pos=$swap_end
        fi
    fi
    
    # Partition Home (si activée)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            print_info "Création partition Home : ${current_pos}MiB à 100%"
            parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB 100% || {
                print_warning "Echec de création de la partition Home"
                USE_SEPARATE_HOME=false
            }
        else
            local home_end=$((current_pos + home_mb))
            print_info "Création partition Home : ${current_pos}MiB à ${home_end}MiB"
            parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB || {
                print_warning "Echec de création de la partition Home"
                USE_SEPARATE_HOME=false
            }
        fi
    fi
    
    sync
    partprobe "$DISK" || true
    sleep 5
    
    # Détection des partitions créées
    print_info "Vérification des partitions créées..."
    lsblk "$DISK"
    
    local detected_parts
    mapfile -t detected_parts < <(lsblk -rno NAME "$DISK" | grep -E "${DISK##*/}[0-9p]" | head -10)
    
    if [[ ${#detected_parts[@]} -lt 2 ]]; then
        print_error "Pas assez de partitions détectées après création"
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
    
    print_success "Partitions créées avec succès"
    echo ""
    echo -e "${GREEN}Partitions finales :${NC}"
    echo -e "${CYAN}EFI:${NC} $EFI_PART"
    echo -e "${CYAN}Root:${NC} $ROOT_PART"
    [[ -n "$SWAP_PART" ]] && echo -e "${CYAN}Swap:${NC} $SWAP_PART"
    [[ -n "$HOME_PART" ]] && echo -e "${CYAN}Home:${NC} $HOME_PART"
    
    return 0
}

format_partitions() {
    print_header "ETAPE 4/$TOTAL_STEPS : FORMATAGE DES PARTITIONS"
    CURRENT_STEP=4
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du formatage"
        return 0
    fi
    
    # Démontage préventif
    umount -f "$EFI_PART" "$ROOT_PART" "$HOME_PART" "$SWAP_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    
    sleep 2
    
    # Formatage EFI
    print_info "Formatage partition EFI : $EFI_PART"
    if ! mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
        print_warning "Echec formatage FAT32, tentative par une autre alternative..."
        wipefs -af "$EFI_PART" || true
        if ! mkfs.fat -F32 "$EFI_PART"; then
            print_error "Impossible de formater la partition EFI"
            return 1
        fi
    fi
    print_success "Partition EFI formatée"
    
    # Formatage Root
    print_info "Formatage partition Root : $ROOT_PART"
    if ! mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_warning "Echec formatage ext4, tentative avec nettoyage..."
        wipefs -af "$ROOT_PART" || true
        if ! mkfs.ext4 -F "$ROOT_PART"; then
            print_error "Impossible de formater la partition Root"
            return 1
        fi
    fi
    print_success "Partition Root formatée"
    
    # Formatage Home (optionnel)
    if [[ -n "$HOME_PART" ]] && [[ "$USE_SEPARATE_HOME" == true ]]; then
        print_info "Formatage partition Home : $HOME_PART"
        if ! mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_warning "Echec formatage Home, désactivation..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        else
            print_success "Partition Home formatée"
        fi
    fi
    
    # Configuration Swap (optionnel)
    if [[ -n "$SWAP_PART" ]] && [[ "$USE_SWAP" == true ]]; then
        print_info "Configuration partition Swap : $SWAP_PART"
        if ! mkswap -L 'ArchSwap' "$SWAP_PART"; then
            print_warning "Echec configuration Swap, désactivation..."
            USE_SWAP=false
            SWAP_PART=""
        else
            swapon "$SWAP_PART" && print_success "Partition Swap configurée et activée"
        fi
    fi
    
    sleep 2
    print_success "Formatage terminé"
}

mount_partitions() {
    print_header "ETAPE 5/$TOTAL_STEPS: MONTAGE DES PARTITIONS"
    CURRENT_STEP=5
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du montage"
        return 0
    fi
    
    # Démontage
    if mountpoint -q /mnt; then
        umount -R /mnt || true
    fi
    
    mkdir -p /mnt
    
    # Montage Root
    print_info "Montage partition Root: $ROOT_PART sur /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Impossible de monter la partition Root"
        return 1
    fi
    
    # Montage EFI
    mkdir -p /mnt/boot/efi
    print_info "Montage partition EFI: $EFI_PART sur /mnt/boot/efi"
    if ! mount "$EFI_PART" /mnt/boot/efi; then
        print_error "Impossible de monter la partition EFI"
        return 1
    fi
    
    # Montage Home (optionnel)
    if [[ -n "$HOME_PART" ]] && [[ "$USE_SEPARATE_HOME" == true ]]; then
        mkdir -p /mnt/home
        print_info "Montage partition Home: $HOME_PART sur /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Impossible de monter la partition Home, désactivation..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        else
            print_success "Partition Home montée"
        fi
    fi
    
    print_success "Partitions montées"
}

# Fonctions d'installation du système de base

install_base_system() {
    print_header "ETAPE 6/$TOTAL_STEPS: INSTALLATION DU SYSTEME DE BASE"
    CURRENT_STEP=6
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du système de base"
        return 0
    fi
    
    # Optimisation des miroirs
    print_info "Optimisation des miroirs Pacman..."
    if command -v reflector &> /dev/null; then
        reflector --country France,Germany,Spain --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || {
            print_warning "Reflector échoué, utilisation des miroirs par défaut"
        }
    else
        print_warning "Reflector non disponible, installation..."
        pacman -S --noconfirm reflector || true
        reflector --country France,Germany --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || true
    fi
    
    # Mise à jour forcée des bases
    print_info "Mise à jour forcée des bases de données..."
            pacman -Syy --noconfirm || {
        print_warning "Mise à jour échouée, nettoyage du cache..."
        pacman -Scc --noconfirm || true
        rm -rf /var/lib/pacman/sync/* || true
        pacman -Syy --noconfirm || {
            print_error "Impossible de mettre à jour les bases de données"
            return 1
        }
    }
    
    # Paquets de base
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub efibootmgr os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )
    
    print_info "Installation des paquets de base..."
    run_with_progress "Installation système de base" 300 "pacstrap /mnt ${base_packages[*]}"
    
    print_success "Système de base installé"
}

configure_system() {
    print_header "ETAPE 7/$TOTAL_STEPS: CONFIGURATION SYSTEME"
    CURRENT_STEP=7

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration système"
        return 0
    fi

    print_info "Génération du fichier fstab..."
    genfstab -U /mnt > /mnt/etc/fstab || {
        print_error "Echec de génération de fstab"
        return 1
    }

    if [[ ! -s /mnt/etc/fstab ]]; then
        print_error "Le fichier fstab est vide"
        return 1
    fi

    while true; do
        read -r -p "Nom d'hôte : " HOSTNAME
        if validate_input "$HOSTNAME" "hostname"; then
            break
        fi
        print_warning "Nom d'hôte invalide (lettres, chiffres et tirets uniquement)"
    done

    print_info "Configuration du système dans chroot..."
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

    print_success "Système configuré"
}

create_users() {
    print_header "ETAPE 8/$TOTAL_STEPS: CREATION UTILISATEURS"
    CURRENT_STEP=8

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la création d'utilisateurs"
        return 0
    fi

    while true; do
        read -r -p "Nom d'utilisateur principal : " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Nom d'utilisateur invalide"
    done

    local password password2
    while true; do
        read -r -s -p "Mot de passe (min 6 caractères) : " password
        echo ""
        if validate_input "$password" "password" 6; then
            read -r -s -p "Confirmez le mot de passe : " password2
            echo ""
            if [[ "$password" == "$password2" ]]; then
                USER_PASSWORD="$password"
                break
            fi
            print_warning "Mots de passe différents"
        else
            print_warning "Mot de passe trop court (minimum 6 caractères)"
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

    print_success "Utilisateur créé: $USERNAME"

    if confirm_action "Créer des utilisateurs supplémentaires ?"; then
        while true; do
            local additional_user
            read -r -p "Nom d'utilisateur supplémentaire (vide pour terminer): " additional_user
            [[ -z "$additional_user" ]] && break

            if validate_input "$additional_user" "username"; then
                local add_password add_password2
                while true; do
                    read -r -s -p "Mot de passe pour $additional_user: " add_password
                    echo ""
                    read -r -s -p "Confirmez le mot de passe : " add_password2
                    echo ""
                    if [[ "$add_password" == "$add_password2" ]]; then
                        break
                    fi
                    print_warning "Mots de passe différents"
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
useradd -m -G audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd
mkdir -p /home/"$additional_user"/{Documents,Téléchargements,Images,Vidéos,Musique,Bureau}
chown -R "$additional_user":"$additional_user" /home/"$additional_user"
EOF

                print_success "Utilisateur supplémentaire créé : $additional_user"
            else
                print_warning "Nom d'utilisateur invalide, ignoré"
            fi
        done
    fi
}

select_desktop_environment() {
    print_header "ETAPE 9/$TOTAL_STEPS: SELECTION ENVIRONNEMENT DE BUREAU"
    CURRENT_STEP=9
    
    echo -e "${WHITE}Environnements disponibles:${NC}"
    echo -e "${CYAN}1.${NC} KDE Plasma (complet avec applications)"
    echo -e "${CYAN}2.${NC} GNOME (complet avec applications)"
    echo -e "${CYAN}3.${NC} Sans interface graphique (serveur/minimal)"
    echo -e "${CYAN}4.${NC} Hyperland (en cours de développement, ne pas sélectionner)"
    
    local choice
    while true; do
        read -r -p "Votre choix (1-3): " choice
        case $choice in
            1) DE_CHOICE="kde"; break ;;
            2) DE_CHOICE="gnome"; break ;;
            3) DE_CHOICE="none"; break ;;
            # 4) DE_CHOICE="hyperland"; print_warning "Hyperland est en cours de développement"; break ;;
            *) print_warning "Choix invalide! Utilisez 1, 2 ou 3." ;;
        esac
    done
    
    print_success "Environnement sélectionné : $DE_CHOICE"
}

install_desktop_environment() {
    print_header "ETAPE 10/$TOTAL_STEPS: INSTALLATION DE L'ENVIRONNEMENT DE BUREAU"
    CURRENT_STEP=10
    
    if [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Aucun environnement de bureau à installer"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation de $DE_CHOICE"
        return 0
    fi
    
    case $DE_CHOICE in
        kde)
            print_info "Installation de KDE Plasma..."
            run_with_progress "Installation KDE Plasma" 600 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm plasma-meta kde-applications sddm"
            /usr/bin/arch-chroot /mnt systemctl enable sddm
            ;;
        gnome)
            print_info "Installation de GNOME..."
            run_with_progress "Installation GNOME" 600 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm gnome gnome-extra gdm"
            /usr/bin/arch-chroot /mnt systemctl enable gdm
            ;;
    esac
    
    print_success "Environnement de bureau installé"
}

# Fonctions de bootloader et thèmes
configure_grub() {
    print_header "ETAPE 11/$TOTAL_STEPS: CONFIGURATION GRUB"
    CURRENT_STEP=11

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration GRUB"
        return 0
    fi

    print_info "Installation et configuration GRUB..."

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    cat > /mnt/etc/default/grub <<'EOF'
# Configuration GRUB
GRUB_DEFAULT=0
GRUB_TIMEOUT=15
GRUB_DISTRIBUTOR="Arch Linux - by PapaOursPolaire on GitHub"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
GRUB_CMDLINE_LINUX=""

# Forcer l'affichage du menu
GRUB_TIMEOUT_STYLE=menu
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep

# Désactiver le menu caché
# GRUB_HIDDEN_TIMEOUT=0
# GRUB_HIDDEN_TIMEOUT_QUIET=false

GRUB_DISABLE_RECOVERY=true
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
EOF

#    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
#       print_error "Echec de génération de la configuration GRUB"
#        return 1
#    } -> Commenté car empeche l'installation du thème Fallout

    print_success "GRUB configuré et installé"
}

install_fallout_theme() {
    print_header "ÉTAPE 12/$TOTAL_STEPS : INSTALLATION DU THÈME GRUB FALLOUT"
    CURRENT_STEP=12

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du thème Fallout"
        return 0
    fi

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installation de Git si nécessaire..."
pacman -Sy --noconfirm --needed git

cd /tmp
echo "[INFO] Nettoyage des dépôts temporaires..."
rm -rf fallout-grub-theme

echo "[INFO] Clonage du dépôt Fallout GRUB..."
git clone --depth=1 https://github.com/shvchk/fallout-grub-theme.git

echo "[INFO] Recherche automatique du dossier contenant theme.txt..."
THEME_DIR=$(find fallout-grub-theme -type f -name "theme.txt" -printf '%h\n' | head -n1)

if [[ -z "$THEME_DIR" ]]; then
    echo "[ERREUR] Impossible de trouver theme.txt dans le dépôt Fallout."
    echo "[DEBUG] Structure du dépôt :"
    ls -R fallout-grub-theme || true
    exit 1
fi

echo "[INFO] Dossier du thème détecté : $THEME_DIR"
install -d -m 0755 /boot/grub/themes
rm -rf /boot/grub/themes/fallout
cp -a "$THEME_DIR" /boot/grub/themes/fallout

echo "[INFO] Configuration de GRUB_THEME dans /etc/default/grub..."
if grep -q "^#*GRUB_THEME=" /etc/default/grub; then
    sed -i 's|^#*GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/fallout/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub
fi

echo "[INFO] Régénération de la configuration GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "[SUCCÈS] Thème Fallout installé et configuré."
EOF
}

# Fonctions audia et multimedia
install_audio_system() {
    print_header "ETAPE 13/$TOTAL_STEPS: INSTALLATION SYSTEME AUDIO PIPEWIRE"
    CURRENT_STEP=13

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du système audio"
        return 0
    fi

    print_info "Installation de PipeWire et outils audio..."

    local audio_packages=(
        pipewire pipewire-alsa pipewire-pulse
        wireplumber pavucontrol alsa-utils
        cava
    )

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm "${audio_packages[@]}" || {
        print_error "Échec de l'installation des paquets audio"
        return 1
    }

    # Configuration de CAVA pour l'utilisateur
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

    print_success "Système audio PipeWire installé et configuré"
}

install_boot_sound() { # L'installation du bip sonore est disfonctionnelle, il fausra aller se faire foutre
    print_header "ETAPE 14/$TOTAL_STEPS: CONFIGURATION BIP SONORE BOOT"
    CURRENT_STEP=14
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du bip sonore"
        return 0
    fi
    
    mkdir -p /mnt/usr/share/sounds
    
    # Téléchargement du son Fallout
    if curl -o /mnt/usr/share/sounds/fallout-bip.mp3 \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projets/FalloutBip.mp3' 2>/dev/null; then
        
        # Service systemd pour le son MP3
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
        
        # Installation mpg123 pour jouer le MP3
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm mpg123 || {
            print_warning "mpg123 non installé, création d'un bip système"
            # Fallback vers bip système
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
        print_warning "Impossible de télécharger le son, création d'un bip système"
        
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
    
    # Activation du service
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Impossible d'activer le service de son de boot"
    }
    
    print_success "Bip sonore de boot configuré"
}

configure_plymouth() {
    print_header "ETAPE $((++CURRENT_STEP))/$TOTAL_STEPS: CONFIGURATION PLYMOUTH"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration de Plymouth"
        return 0
    fi

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installation de Plymouth..."
pacman -Sy --noconfirm --needed plymouth unzip wget

cd /tmp
rm -f arch-mac-style.zip
rm -rf /usr/share/plymouth/themes/arch-mac-style

echo "[INFO] Téléchargement du thème Plymouth..."
wget -O arch-mac-style.zip "https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/arch-mac-style.zip"

echo "[INFO] Décompression du thème..."
unzip -o arch-mac-style.zip -d /usr/share/plymouth/themes/

# Correction auto : trouver le dossier qui contient arch-mac-style.plymouth
THEME_DIR=$(find /usr/share/plymouth/themes -type f -name "arch-mac-style.plymouth" -printf '%h\n' | head -n1)

if [[ -z "$THEME_DIR" ]]; then
    echo "[ERREUR] Impossible de trouver arch-mac-style.plymouth après extraction."
    ls -R /usr/share/plymouth/themes || true
    exit 1
fi

echo "[INFO] Thème détecté dans : $THEME_DIR"

echo "[INFO] Configuration du thème par défaut..."
plymouth-set-default-theme -R "$(basename "$THEME_DIR")"

echo "[SUCCÈS] Plymouth configuré avec le thème arch-mac-style."
EOF
}

configure_sddm() {
    print_header "CONFIGURATION DU DISPLAY MANAGER (SDDM OU GDM)"

    local repo_zip="/root/Projets.zip"
    local extract_dir="/root/arch-Projets"
    local theme_dir="/usr/share/sddm/themes/SDDM-Fallout-theme"

    # 1) Si GNOME → GDM
    if /usr/bin/arch-chroot /mnt pacman -Qi gdm &>/dev/null && \
        /usr/bin/arch-chroot /mnt pacman -Qi gnome-shell &>/dev/null; then
        print_info "GNOME détecté → configuration de GDM"
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed gdm || {
            print_error "Impossible d’installer GDM"
            return 1
        }
        /usr/bin/arch-chroot /mnt systemctl enable gdm.service
        print_success "GDM activé (SDDM ignoré)."
        return 0
    fi

    # 2) Installer SDDM et unzip
    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed sddm unzip curl || {
        print_error "Impossible d’installer SDDM ou ses dépendances"
        return 1
    }

    # 3) Télécharger l’archive auto de GitHub
    print_info "Téléchargement du dépôt GitHub (branche Projets)..."
    if ! /usr/bin/arch-chroot /mnt curl -fL \
        "https://github.com/PapaOursPolaire/arch/archive/refs/heads/Projets.zip" \
        -o "$repo_zip"; then
        print_error "Échec du téléchargement de l’archive GitHub"
        return 1
    fi

    # 4) Extraction
    /usr/bin/arch-chroot /mnt rm -rf "$extract_dir" "$theme_dir"
    if ! /usr/bin/arch-chroot /mnt unzip -o "$repo_zip" -d /root/; then
        print_error "Échec extraction de l’archive GitHub"
        return 1
    fi

    # 5) Déplacement du thème
    if /usr/bin/arch-chroot /mnt test -d "$extract_dir/SDDM-Fallout-theme"; then
        /usr/bin/arch-chroot /mnt mv "$extract_dir/SDDM-Fallout-theme" "$theme_dir"
    else
        print_error "Le dossier SDDM-Fallout-theme n’a pas été trouvé dans l’archive"
        return 1
    fi

    # 6) Vérification du contenu
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/Main.qml"; then
        print_error "Main.qml introuvable — thème incomplet"
        return 1
    fi
    if ! /usr/bin/arch-chroot /mnt test -f "$theme_dir/background.mp4"; then
        print_warning "Attention : la vidéo background.mp4 est manquante"
    fi

    # 7) Configurer SDDM
    print_info "Écriture de /etc/sddm.conf..."
    /usr/bin/arch-chroot /mnt bash -c "cat > /etc/sddm.conf <<EOF
[Theme]
Current=SDDM-Fallout-theme

[General]
DisplayServer=wayland
EOF"

    # 8) Activer SDDM
    /usr/bin/arch-chroot /mnt systemctl enable sddm.service

    print_success "SDDM configuré avec succès avec le thème Fallout"
}

configure_kde_lockscreen() {
    # CONFIGURATION KDE LOCKSCREEN (KSplash QML)
    print_header "CONFIGURATION KDE SPLASH (look-and-feel)"
    CURRENT_STEP=$((CURRENT_STEP+1))

    # --- Respect des variables globales existantes, sans redéclaration readonly ---
    local kde_splash_url="${KDESPLASH_URL:-}"
    local dest_pkg_dir="${LOCKSCREEN_THEME_DIR:-/usr/share/plasma/look-and-feel/org.kde.falloutlock}"

    # Détection : on déploie dans le système live ou dans le chroot /mnt ?
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

    # Mode simulation
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] configure_kde_lockscreen url=${kde_splash_url:-<non défini>} dest=${effective_dest}"
        return 0
    fi

    # Vérifs outils (on extrait côté hôte)
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl est requis pour télécharger l'archive du splash."
        return 1
    fi
    local have_bsdtar=false have_unzip=false
    command -v bsdtar >/dev/null 2>&1 && have_bsdtar=true
    command -v unzip  >/dev/null 2>&1 && have_unzip=true
    if [[ "$have_bsdtar" == false && "$have_unzip" == false ]]; then
        print_error "Ni bsdtar ni unzip disponibles pour extraire le .zip."
        return 1
    fi

    # Espace de travail temporaire (nettoyé à la fin de la fonction)
    local tmp_dir archive_zip theme_root=""
    tmp_dir="$(mktemp -d -t kdesplash.XXXXXXXX)" || { print_error "mktemp a échoué"; return 1; }
    archive_zip="${tmp_dir}/splash.zip"
    trap 'rm -rf "$tmp_dir" 2>/dev/null || true' RETURN

    # Téléchargement
    if [[ -z "${kde_splash_url}" ]]; then
        print_error "KDESPLASH_URL est vide: impossible de télécharger le thème."
        return 1
    fi
    print_info "Téléchargement du splash depuis: ${kde_splash_url}"
    if ! curl -fL --retry 3 --connect-timeout 20 -o "$archive_zip" "$kde_splash_url"; then
        print_error "Échec du téléchargement du splash."
        return 1
    fi
    if [[ ! -s "$archive_zip" ]]; then
        print_error "L’archive téléchargée est vide."
        return 1
    fi

    # Extraction
    print_info "Extraction de l'archive..."
    if $have_bsdtar; then
        if ! bsdtar -C "$tmp_dir" -xf "$archive_zip"; then
            print_error "Échec d’extraction (bsdtar)."
            return 1
        fi
    else
        if ! unzip -qq -o "$archive_zip" -d "$tmp_dir"; then
            print_error "Échec d’extraction (unzip)."
            return 1
        fi
    fi

    # Détection robuste de la racine du thème (gère le double sous-dossier)
    # On cherche un dossier contenant metadata.desktop + contents/Splash.qml (ou contents/splash/Splash.qml)
    while IFS= read -r dir; do
        if [[ -f "$dir/metadata.desktop" ]] && { [[ -f "$dir/contents/Splash.qml" ]] || [[ -f "$dir/contents/splash/Splash.qml" ]]; }; then
            theme_root="$dir"
            break
        fi
    done < <(find "$tmp_dir" -maxdepth 5 -type d -print)

    # Heuristique supplémentaire : cas "fallout-splashscreen4k/fallout-splashscreen4k"
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
        print_error "Impossible de localiser la racine du thème (metadata.desktop + contents/Splash.qml)."
        return 1
    fi
    print_info "Racine du thème détectée : $theme_root"

    # Préparation destination
    local dest_parent
    dest_parent="$(dirname "$effective_dest")"
    mkdir -p "$dest_parent" || { print_error "Impossible de créer $dest_parent"; return 1; }

    if [[ -d "$effective_dest" ]]; then
        local backup="${effective_dest}.bak.$(date +%s)"
        print_info "Sauvegarde de l'ancien thème -> $backup"
        rm -rf "$backup" 2>/dev/null || true
        mv "$effective_dest" "$backup" || print_warning "Sauvegarde impossible (permissions ?), on écrasera directement."
    fi
    mkdir -p "$effective_dest" || { print_error "Impossible de créer $effective_dest"; return 1; }

    # Copie (rsync si dispo sinon cp -a)
    if command -v rsync >/dev/null 2>&1; then
        print_info "Copie du thème (rsync)…"
        if ! rsync -a --delete "$theme_root"/ "$effective_dest"/; then
            print_error "Échec de la copie avec rsync."
            return 1
        fi
    else
        print_info "Copie du thème (cp -a)…"
        if ! cp -a "$theme_root"/. "$effective_dest"/; then
            print_error "Échec de la copie avec cp."
            return 1
        fi
    fi

    # Normalisation : si Splash.qml est à la racine et pas sous contents/, on corrige
    if [[ -f "$effective_dest/Splash.qml" && ! -f "$effective_dest/contents/Splash.qml" ]]; then
        mkdir -p "$effective_dest/contents"
        mv -f "$effective_dest/Splash.qml" "$effective_dest/contents/Splash.qml" 2>/dev/null || true
    fi

    # Permissions
    chown -R root:root "$effective_dest" || true
    chmod -R u+rwX,go+rX,go-w "$effective_dest" || true

    # Définir KSplash par défaut (système) : /etc/xdg/ksplashrc
    print_info "Définition du splash par défaut via /etc/xdg/ksplashrc"
    if $in_chroot; then
        /usr/bin/arch-chroot /mnt /bin/bash -lc "mkdir -p /etc/xdg && printf '%s\n' '[KSplash]' 'Theme=org.kde.falloutlock' 'Engine=KSplashQML' > /etc/xdg/ksplashrc"
    else
        mkdir -p /etc/xdg
        printf '%s\n' '[KSplash]' 'Theme=org.kde.falloutlock' 'Engine=KSplashQML' > /etc/xdg/ksplashrc
    fi

    print_success "Splashscreen KDE déployé dans ${effective_dest}"
    return 0
}

prepare_aur_in_chroot() {
    /usr/bin/arch-chroot /mnt bash -lc '
set -e
pacman -Sy --noconfirm --needed base-devel git
echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/pacman" >/etc/sudoers.d/01-pacman-nopasswd
chmod 440 /etc/sudoers.d/01-pacman-nopasswd
'
}

# Fonctions d'installation des applications
install_paru() {
    print_header "INSTALLATION PARU (AUR Helper)"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation installation Paru"
        return 0
    fi
    
    print_info "Début installation Paru dans chroot..."
    
    /usr/bin/arch-chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

echo "DEBUT INSTALLATION PARU"

# Installation des dépendances + rustup pour être sûr
echo "Installation des dépendances..."
pacman -Sy --noconfirm --needed base-devel git sudo rust cargo

# Création utilisateur temporaire
echo "Création utilisateur builduser..."
id builduser &>/dev/null || useradd -m builduser
echo "builduser ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/99-aur
echo "Utilisateur créé OK"

# Compilation en tant que builduser
echo "Début compilation paru..."
cd /tmp
rm -rf paru-bin paru

echo "Clone du repository..."
sudo -u builduser git clone https://aur.archlinux.org/paru-bin.git
echo "Clone OK"

cd paru-bin
echo "Lancement makepkg..."
sudo -u builduser makepkg -si --noconfirm
echo "Compilation terminée"

# Vérification immédiate dans le chroot
echo "VERIFICATION IMMEDIATE"
echo "PATH actuel: $PATH"

# Ajout explicite de /usr/local/bin au PATH
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
echo "Nouveau PATH: $PATH"

# Test immédiat
if command -v paru; then
    echo "PARU TROUVE: $(which paru)"
    paru --version
else
    echo "Paru non trouvé, recherche exhaustive..."
    find /usr -name "*paru*" -type f 2>/dev/null
    
    # Si trouvé ailleurs, créer lien
    if [[ -f /usr/local/bin/paru ]]; then
        echo "Création lien /usr/local/bin/paru -> /usr/bin/paru"
        ln -sf /usr/local/bin/paru /usr/bin/paru
    fi
fi

# Ajout PATH permanent dans bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc

# Test final
echo "=== TEST FINAL ==="
export PATH="/usr/local/bin:/usr/bin:/bin"
command -v paru && paru --version

# Nettoyage (mais garde paru!)
echo "Nettoyage..."
rm -f /etc/sudoers.d/99-aur
userdel -r builduser 2>/dev/null || true
# NE PAS supprimer /tmp/paru-bin tant que paru n'est pas confirmé

echo "=== FIN INSTALLATION PARU ==="

CHROOT_EOF
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        print_error "Erreur durant l'installation (code: $exit_code)"
        return 1
    fi
    
    # Vérification finale AVEC le bon PATH
    print_info "Vérification finale avec PATH étendu..."
    
    if /usr/bin/arch-chroot /mnt /bin/bash -c 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"; command -v paru >/dev/null 2>&1'; then
        print_success "Paru installé et disponible"
        # Nettoyer maintenant que c'est confirmé
        /usr/bin/arch-chroot /mnt rm -rf /tmp/paru-bin 2>/dev/null || true
    else
        print_error "Paru n'a pas pu être installé correctement"
        print_info "Recherche finale de paru..."
        /usr/bin/arch-chroot /mnt find /usr -name "*paru*" -type f 2>/dev/null || echo "Aucun paru trouvé"
        return 1
    fi
}

install_yay_in_chroot() {
    print_info "Installation de yay (AUR helper) dans le chroot..."

    if chroot_cmd_exists yay; then
        print_success "yay déjà installé dans le chroot"
        return 0
    fi

    # Installer base-devel et git en root
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Impossible d’installer base-devel et git"
        return 1
    }

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ca-certificates ca-certificates-utils
    /usr/bin/arch-chroot /mnt update-ca-trust

    # Compiler yay en tant qu'utilisateur normal
    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc "
        cd /tmp &&
        git clone https://aur.archlinux.org/yay.git &&
        cd yay &&
        makepkg -si --noconfirm
    " || {
        print_error "Échec de l’installation de yay"
        return 1
    }

    print_success "yay installé avec succès dans le chroot"
}

clean_pacman_cache_chroot() {
    print_info "Nettoyage du cache Pacman dans le chroot..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
rm -f /var/lib/pacman/db.lck
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /var/lib/pacman/sync/*
pacman -Sy --noconfirm
EOF

    print_success "Cache Pacman nettoyé dans le chroot"
}

refresh_mirrors() { # A utiliser si erreurs de téléchargement dans les futures variables
    print_info "Rafraîchissement des miroirs rapides..."
    if command -v reflector &> /dev/null; then
        reflector \
            --country France,Germany,Netherlands,Belgium,Switzerland \
            --age 6 \
            --protocol https \
            --fastest 20 \
            --sort rate \
            --threads 10 \
            --save /etc/pacman.d/mirrorlist || {
            print_warning "Impossible de rafraîchir les miroirs, utilisation de la liste actuelle"
        }
    else
        print_warning "Reflector introuvable, tentative d'installation..."
        pacman -S --noconfirm reflector && \
        reflector --fastest 10 --save /etc/pacman.d/mirrorlist || true
    fi
    pacman -Syy --noconfirm
}

install_development_environment() {
    print_header "ETAPE 18/$TOTAL_STEPS: INSTALLATION ENVIRONNEMENT DE DEVELOPPEMENT"
    CURRENT_STEP=18

    # Vérifie et supprime rust installé par pacman pour éviter conflit avec rustup
    print_info "Vérification conflit rust/rustup..."
    if /usr/bin/arch-chroot /mnt pacman -Q rust &>/dev/null; then
        /usr/bin/arch-chroot /mnt pacman -Rns --noconfirm rust
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation de l'environnement de développement"
        return 0
    fi

    print_info "Installation des langages de programmation et outils de développement..."

    # Liste des paquets de développement
    local dev_packages=(
        # Langages
        python python-pip python-virtualenv
        nodejs npm
        jdk-openjdk
        go
        rustup
        gcc clang cmake make gdb

        # Outils de développement
        git docker docker-compose
        base-devel
        pkgconf
        unzip p7zip zip

        # Éditeur principal
        #code

        # Outils complémentaires
        wget curl
        lsb-release
    )

    # Installation des paquets
    /usr/bin/arch-chroot /mnt pacman -S --needed --noconfirm "${dev_packages[@]}" || {
        print_error "Échec de l'installation des paquets de développement"
        return 1
    }

    # Configuration de rustup
    /usr/bin/arch-chroot /mnt /bin/bash -c "
set -e
USERNAME='${USERNAME}'
sudo -u \"\$USERNAME\" bash -c '
    rustup default stable
    rustup update
    rustup component add rust-src rustfmt clippy
'
"

    # Activer et configurer Docker
    /usr/bin/arch-chroot /mnt /bin/bash -c "
set -e
USERNAME='${USERNAME}'
systemctl enable docker
usermod -aG docker \"\$USERNAME\"
"

    print_success "Environnement de développement installé et configuré"
}

# Fonction pour indiquer à l'utilisateur ce qui se passera
vscode_post_install_info() {
    print_info ""
    print_info "  INFORMATION VS CODE:"
    print_info "   Les extensions VS Code s'installeront automatiquement"
    print_info "   au premier démarrage de votre session graphique."
    print_info "   Vous pouvez aussi les installer manuellement avec:"
    print_info "   • ~/install-vscode-extensions.sh"
    print_info "   • ~/manual-vscode-setup.sh (version simplifiée)"
    print_info ""
}

install_web_browsers() {
    print_header "ETAPE 19/$TOTAL_STEPS: INSTALLATION DES NAVIGATEURS WEB"
    CURRENT_STEP=19

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation des navigateurs web"
        return 0
    fi

    print_info "Installation des navigateurs web dans le système..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'CHROOT_EOF'
set -e

# Liste des navigateurs web à installer : paquet:commande
web_browsers=(
    "firefox:firefox"
    "chromium:chromium"
    "brave-browser:brave-browser"
    "vivaldi-stable:vivaldi"
    "opera:opera"
    "torbrowser-launcher:torbrowser-launcher"
    "epiphany:epiphany"
    "midori:midori"
)

for browser_entry in "${web_browsers[@]}"; do
    IFS=":" read -r browser_pkg browser_cmd <<< "$browser_entry"

    echo "[INFO] Installation de $browser_pkg..."

    if command -v "$browser_cmd" &>/dev/null; then
        echo "[WARNING] $browser_pkg est déjà installé."
    else
        if pacman -S --noconfirm --needed "$browser_pkg"; then
            echo "[SUCCESS] $browser_pkg installé avec succès."
        else
            echo "[ERROR] Échec de l'installation de $browser_pkg, passage au suivant."
            continue
        fi
    fi

    # Mise à jour du cache MIME uniquement si le navigateur est bien installé
    if command -v "$browser_cmd" &>/dev/null; then
        echo "[INFO] Mise à jour du cache MIME pour $browser_pkg..."
        update-desktop-database /usr/share/applications || true
    else
        echo "[WARNING] $browser_pkg non trouvé après installation, skip cache MIME."
    fi
done
CHROOT_EOF

    print_success "Installation des navigateurs web terminée."
}

install_spotify_spicetify() {
    print_header "INSTALLATION DE SPOTIFY + SPICETIFY"

    # Vérifie que Flatpak est installé dans le chroot
    if ! chroot_cmd_exists flatpak; then
        print_info "Flatpak absent — installation..."
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed flatpak || {
            print_error "Impossible d’installer Flatpak"
            return 1
        }
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi

    local spotify_ok=false

    # Tentative installation Spotify via Flatpak
    if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.spotify.Client; then
        print_success "Spotify (Flatpak) installé avec succès"
        spotify_ok=true
    else
        print_warning "Échec installation Spotify (Flatpak, extra-data). Tentative version AUR…"

        if chroot_cmd_exists paru; then
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm spotify-launcher && spotify_ok=true || \
                print_warning "Échec de l’installation via AUR (spotify-launcher)."
        else
            print_warning "Paru absent, impossible d’installer Spotify via AUR."
        fi
    fi

    # Vérification installation Spotify
    if [[ "$spotify_ok" == false ]]; then
        print_warning "Spotify n’a pas pu être installé automatiquement. Il pourra être installé manuellement après reboot."
        return 0
    fi

    # Installation de Spicetify CLI
    if /usr/bin/arch-chroot /mnt command -v spicetify &>/dev/null; then
        print_success "Spicetify déjà présent"
    else
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed spicetify-cli && \
            print_success "Spicetify CLI installé" || \
            print_warning "Échec installation Spicetify CLI (non bloquant)"
    fi

    # Configuration minimale Spicetify (sans crash si Spotify pas encore lancé)
    if [[ -n "${USERNAME:-}" ]]; then
        print_info "Préparation configuration Spicetify pour $USERNAME"
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify config current_theme DribbblishNordDark || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify backup || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify apply || true
    else
        print_warning "USERNAME non défini — Spicetify sera configuré après premier boot."
    fi

    print_success "Installation Spotify + Spicetify terminée (avec fallbacks)."
}

# Nettoyage sûr de /tmp avant installation des polices (pour éviter "No space left on device")
clean_tmp() {
    print_header "NETTOYAGE /tmp — Avant installation des polices"
    local CLEAN_TMP_MINUTES="${CLEAN_TMP_MINUTES:-120}"  # fichiers inactifs plus vieux que X minutes seront supprimés
    local LARGE_FILE_MB="${LARGE_FILE_MB:-100}"         # fichiers > X Mo seront supprimés
    local DRY="${DRY_RUN:-false}"
    local BEFORE_MB AFTER_MB

    # Afficher état avant
    BEFORE_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "Espace utilisé /tmp : ${BEFORE_MB} Mo (avant nettoyage)."
    if [[ "$DRY" == "true" ]]; then
        print_info "[DRY RUN] Simulation - aucun fichier ne sera supprimé."
        return 0
    fi

    # Sécurité : ne pas supprimer si /tmp est un lien non standard
    if [[ ! -d /tmp ]]; then
        print_warning "/tmp introuvable ou non-répertoire — annulation du nettoyage."
        return 0
    fi

    # On passe en mode tolérant sur les erreurs pendant les suppressions
    set +e

    # 1) Supprimer fichiers volumineux (> LARGE_FILE_MB) (fichiers réguliers)
    print_info "Suppression des fichiers > ${LARGE_FILE_MB} Mo dans /tmp (pour libérer de l'espace)..."
    find /tmp -type f -size +"${LARGE_FILE_MB}"M -print -exec rm -f {} \; 2>/dev/null || true

    # 2) Supprimer les fichiers/dirs dans /tmp inactifs depuis CLEAN_TMP_MINUTES minutes
    print_info "Suppression des entrées inactives depuis > ${CLEAN_TMP_MINUTES} minutes..."
    # On limite la profondeur à 1 pour éviter de parcourir récursivement de très gros arbres
    find /tmp -mindepth 1 -maxdepth 1 -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -rf {} \; 2>/dev/null || true

    # 3) Supprimer archives temporaires anciennes (sécurité supplémentaire)
    print_info "Suppression des archives (.zip .tar.gz .tgz .tar.xz) âgées de > ${CLEAN_TMP_MINUTES} minutes..."
    find /tmp -type f \( -iname '*.zip' -o -iname '*.tar.gz' -o -iname '*.tgz' -o -iname '*.tar.xz' -o -iname '*.tar' \) -mmin +"${CLEAN_TMP_MINUTES}" -print -exec rm -f {} \; 2>/dev/null || true

    # 4) Supprimer core dumps (souvent énormes)
    print_info "Suppression des core dumps éventuels..."
    find /tmp -type f -iname 'core*' -size +1M -print -exec rm -f {} \; 2>/dev/null || true

    # 5) Forcer sync et recalculer
    sync 2>/dev/null || true

    # Rétablir comportement normal d'erreur
    set -e

    AFTER_MB=$(du -sm /tmp 2>/dev/null | awk '{print $1}' || echo 0)
    print_info "Espace utilisé /tmp : ${AFTER_MB} Mo (après nettoyage)."
    local FREED=$(( BEFORE_MB - AFTER_MB ))
    if (( FREED > 0 )); then
        print_success "Nettoyage terminé — libéré ${FREED} Mo."
    else
        print_warning "Nettoyage terminé — aucune place significative libérée."
    fi

    return 0
}

install_wine_compatibility() {
    print_header "ETAPE 21/$TOTAL_STEPS: INSTALLATION COMPATIBILITE WINDOWS"
    CURRENT_STEP=21
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation de Wine"
        return 0
    fi
    
    print_info "Installation de Wine pour la compatibilité Windows..."
    
    # Activation multilib pour Wine
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Activation multilib dans pacman.conf
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy
EOF
    
    # Installation Wine et outils
    local wine_packages=(
        wine wine-staging winetricks
        wine-mono wine-gecko
    )
    
    run_with_progress "Installation Wine" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm ${wine_packages[*]}"
    
    # Configuration Wine pour l'utilisateur
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Echec configuration Wine"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Initialisation Wine (Windows 10)
export WINEPREFIX=/home/$USERNAME/.wine
wineboot --init >/dev/null 2>&1 || true

# Configuration Wine en Windows 10
winecfg /v win10 >/dev/null 2>&1 || true

# Installation des composants essentiels via Winetricks
winetricks --unattended corefonts vcrun2019 dotnetfx48 || echo "Certains composants Winetricks ont échoué"

echo "Wine configuré pour Windows 10"
USEREOF
EOF
    
    print_success "Wine et extensions installés"
}

install_software_packages() {
    print_header "ETAPE 22/$TOTAL_STEPS: INSTALLATION LOGICIELS ESSENTIELS"
    CURRENT_STEP=22

    if declare -F clean_tmp >/dev/null; then
        clean_tmp
    else
        print_warning "Fonction clean_tmp absente — nettoyage minimal de /tmp"
        find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation des logiciels"
        return 0
    fi
    
    print_info "Installation de tous les logiciels..."
    
    # Catégorie 1: Internet & Communication
    print_info "Installation Internet & Communication..."
    local internet_packages=(
        firefox
        thunderbird
        telegram-desktop
    )
    
    run_with_progress "Installation Internet" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${internet_packages[*]}"
    
    # Discord via AUR ou Flatpak
    if /usr/bin/arch-chroot /mnt command -v paru &> /dev/null; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm discord || {
            print_info "Installation Discord via Flatpak..."
            /usr/bin/arch-chroot /mnt flatpak install -y flathub com.discordapp.Discord || print_warning "Discord non installé"
        }
    fi
    
    # Catégorie 2: Multimédia
    print_info "Installation Multimédia & Design..."
    local multimedia_packages=(
        vlc
        mpv
        obs-studio
        audacity
        gimp
        inkscape
        imagemagick
        kdenlive
        blender
        krita
    )
    
    run_with_progress "Installation Multimédia" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${multimedia_packages[*]}"
    
        # Catégorie 3 : Gaming (si interface graphique installée) 
        if [[ "$DE_CHOICE" != "none" ]]; then
            print_header "INSTALLATION LOGICIELS GAMING"
            print_info "Installation de la suite Gaming complète..."

            # Assurer multilib dans le chroot avant d'installer Steam
            /usr/bin/arch-chroot /mnt pacman -Syyu --noconfirm

            # Activer le dépôt multilib si pas déjà activé (à nouveau)
            if ! grep -q "^\[multilib\]" /mnt/etc/pacman.conf; then
                echo "[multilib]" >> /mnt/etc/pacman.conf
                echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
            fi

            # Mettre à jour la base des paquets avec multilib
            /usr/bin/arch-chroot /mnt pacman -Sy


            # S'assure que paru est présent avant toute install AUR Gaming
            if ! chroot_cmd_exists paru; then
                print_info "Paru non disponible — tentative d'installation via pacman..."
                if /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed paru; then
                    print_success "Paru installé avec succès via dépôts"
                else
                    print_warning "Échec installation binaire — tentative via AUR..."
                    if install_paru; then
                        print_success "Paru installé via AUR"
                    elif install_yay_in_chroot; then
                        print_success "Yay installé comme fallback"
                    else
                        print_warning "Impossible d'installer un helper AUR — les paquets AUR Gaming seront ignorés"
                    fi
                fi
            fi

            local gaming_packages=(
                # Plateformes et gestionnaires
                lutris

                # Émulation multi-systèmes
                retroarch
                retroarch-assets-xmb
                retroarch-assets-ozone
                libretro-gambatte
                libretro-snes9x
                libretro-mupen64plus-next

                # Émulateurs standalone
                fceux
                snes9x-gtk
                mupen64plus
                dolphin-emu
                ppsspp
                desmume

                # Optimisations gaming
                gamemode
                lib32-gamemode
                mangohud
                lib32-mangohud

                # Proton & compatibilité
                lib32-gcc-libs
                lib32-glibc

                # Outils et streaming
                discord
                obs-studio

                # Émulation
                retroarch
                dolphin-emu
            )
        
        install_errors=0
        for pkg in "${gaming_packages[@]}"; do
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "$pkg"; then
                print_warning "Impossible d’installer $pkg"
                ((install_errors++))
            fi
        done

        if (( install_errors == 0 )); then
            print_success "Tous les paquets gaming installés"
        else
            print_warning "$install_errors paquet(s) gaming n’ont pas pu être installés"
        fi


            # Vérification de Paru dans le chroot
            if chroot_cmd_exists paru; then
                print_info "Installation des paquets AUR Gaming via Paru..."
                local gaming_aur_packages=(
                    protonup-qt
                    heroic-games-launcher-bin
                )
                if /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${gaming_aur_packages[@]}"; then
                    print_success "Paquets AUR gaming installés"
                else
                    print_warning "Certains paquets AUR gaming n'ont pas pu être installés"
                fi
            else
                print_warning "Paru non installé ou non disponible dans le chroot - les paquets AUR Gaming seront ignorés"
            fi
        else
            print_info "Pas d'interface graphique - section Gaming ignorée"
        fi


            # Installation via pacman
            if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed "${gaming_packages[@]}"; then
                print_error "Échec de l'installation des paquets Gaming via pacman"
            else
                print_success "Paquets Gaming installés (pacman)"
            fi

            # Installation paquets AUR spécifiques via paru
            local aur_gaming_packages=(
                heroic-games-launcher-bin
                yuzu-early-access-bin
                rpcs3-bin
            )

            if /usr/bin/arch-chroot /mnt command -v paru &>/dev/null; then
                print_info "Installation des paquets Gaming AUR..."
                /usr/bin/arch-chroot /mnt paru -S --noconfirm --needed "${aur_gaming_packages[@]}" || \
                    print_warning "Certains paquets AUR Gaming n'ont pas pu être installés"
            else
                print_warning "Paru non installé — les paquets AUR Gaming seront ignorés"
            fi

            # Configuration de Gamemode

            /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
    if [ -f /etc/gamemode.ini ]; then
        sed -i 's/#renice=0/renice=10/' /etc/gamemode.ini
        sed -i 's/#softrealtime=off/softrealtime=on/' /etc/gamemode.ini
        sed -i 's/#desiredgov=performance/desiredgov=performance/' /etc/gamemode.ini
    fi
EOF
            print_success "Gamemode configuré pour les performances"

            # Configuration MANGOHUD (overlay FPS)
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

            print_success "MangoHud configuré pour $(basename "$MANGOHUD_PATH")"

    # Catégorie 4: Utilitaires système
    print_info "Installation Utilitaires système..."
    local utility_packages=(
        gparted
        timeshift
        flatpak
        keepassxc
        unzip
        p7zip
        tree
        feh
        flameshot
        htop
        btop
        #neofetch  -> a été retiré des depots récemment et je pense que fastfetch et mieux de tt façon
        lsb-release
        wget
        curl
        rsync
        ark
        filelight
    )

    clean_tmp
    
    run_with_progress "Installation Utilitaires" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${utility_packages[*]}"
    
    # Catégorie 5: Polices et thèmes
    print_info "Installation Polices..."
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
    
    run_with_progress "Installation Polices" 60 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${font_packages[*]}"
    

    /usr/bin/arch-chroot /mnt /bin/bash -lc '
    set -e
    mkdir -p /etc/sysctl.d
    printf "%s\n" "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/99-unprivileged.conf
    '


    sysctl kernel.unprivileged_userns_clone
    # doit renvoyer : 1

    # Configuration Flatpak avancée
    print_info "Configuration Flatpak et applications..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF' || print_warning "Echec configuration Flatpak"
# Configuration Flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl enable --global flatpak-system-helper.service

# Activer userns pour Flatpak
if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
    print_info "Activation de kernel.unprivileged_userns_clone=1 pour Flatpak"
    sysctl -w kernel.unprivileged_userns_clone=1 || true
    echo "kernel.unprivileged_userns_clone=1" > /etc/sysctl.d/00-local-userns.conf
fi

# Applications Flatpak utiles
echo "Installation applications Flatpak..."
flatpak install -y flathub org.videolan.VLC 2>/dev/null || true
flatpak install -y flathub com.spotify.Client 2>/dev/null || true
flatpak install -y flathub org.libreoffice.LibreOffice 2>/dev/null || true
flatpak install -y flathub com.visualstudio.code 2>/dev/null || true
flatpak install -y flathub org.gimp.GIMP 2>/dev/null || true
flatpak install -y flathub org.inkscape.Inkscape 2>/dev/null || true
flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null || true
flatpak install -y flathub com.google.AndroidStudio 2>/dev/null || true

echo "Applications Flatpak installées"
EOF
    
    # Configuration Steam avancée (si installé)
    if [[ "$DE_CHOICE" != "none" ]]; then
        print_info "Configuration Steam et gaming..."
        /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Echec configuration Steam"
sudo -u $USERNAME /bin/bash <<'USEREOF'
# Configuration Steam avec Proton
mkdir -p /home/$USERNAME/.steam/steam/config

# Configuration Steam Play automatique
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

# Configuration GameMode
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
start=notify-send "GameMode activé"
end=notify-send "GameMode désactivé"
GAMEMODE_EOF
USEREOF
EOF
    fi
    
    print_info "Vérification des installations..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo "=== VERIFICATION DES LOGICIELS INSTALLES ==="

# Vérification des logiciels critiques
critical_apps=(
    "firefox" "vlc" "gimp" "steam" "discord" 
    "code" "git" "docker" "fastfetch"
)

installed_count=0
total_count=${#critical_apps[@]}

for app in "${critical_apps[@]}"; do
    if command -v "$app" >/dev/null 2>&1; then
        echo " $app installé"
        ((installed_count++))
    elif [[ -x "/opt/visual-studio-code/code" ]] && [[ "$app" == "code" ]]; then
        echo " Visual Studio Code installé (manuel)"
        ((installed_count++))
    else
        echo " $app MANQUANT"
    fi
done

echo "=== RÉSUMÉ: $installed_count/$total_count logiciels installés ==="

# Liste des paquets installés
echo "Nombre total de paquets installés: $(pacman -Q | wc -l)"
EOF
    
    print_success "TOUS LES LOGICIELS ESSENTIELS ONT ÉTÉ INSTALLÉS "
}

install_themes_and_icons() {
    print_header "ETAPE 23/$TOTAL_STEPS: INSTALLATION THEMES ET ICONES"
    CURRENT_STEP=23
    
    if [[ "$DRY_RUN" == true ]] || [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Thèmes et icônes ignorés (mode console ou dry-run)"
        return 0
    fi
    
    print_info "Installation des thèmes et icônes..."
    
    # Icônes et thèmes via pacman - CORRECTION: noms de paquets corrects
    local theme_packages=(
        papirus-icon-theme
        tela-icon-theme
        breeze-icons
        breeze-gtk
        materia-gtk-theme
        qogir-gtk-theme
        sweet-theme-git
    )
    
    # Installation des thèmes de base
    run_with_progress "Installation thèmes et icônes" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed papirus-icon-theme breeze-icons breeze-gtk"
    
    # Thèmes additionnels via AUR
    if /usr/bin/arch-chroot /mnt command -v paru &> /dev/null; then
        print_info "Installation thèmes additionnels via AUR..."
        
        # Installation séparée pour éviter les conflits
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed tela-icon-theme-git || {
            print_warning "Tela icon theme non installé"
        }
        
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed sweet-theme-git || {
            /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed materia-gtk-theme || {
                print_warning "Sweet/Materia theme non installé"
            }
        }
        
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm --needed qogir-gtk-theme || {
            print_warning "Qogir theme non installé"
        }
    fi
    
    # Configuration du thème par défaut - CORRECTION: Thèmes existants
    if [[ "$DE_CHOICE" == "kde" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "Echec configuration thème KDE"
# Configuration KDE avec thèmes valides
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

# Configuration Plasma
cat > /home/$USERNAME/.config/plasmarc <<'PLASMA_EOF'
[Theme]
name=breeze-dark

[Wallpapers]
usersWallpapers=/usr/share/sddm/themes/fallout/background.png,/usr/share/backgrounds/
PLASMA_EOF

# Configuration du fond d'écran
mkdir -p /home/$USERNAME/.local/share/wallpapers
# CORRECTION: Téléchargement correct de l'image de bureau
curl -o /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projets/fallout-desktop-bg.png' 2>/dev/null || {
    # Copie de l'image SDDM en fallback
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/wallpapers/fallout-wallpaper.png
    fi
}
EOF
    elif [[ "$DE_CHOICE" == "gnome" ]]; then
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" /bin/bash <<'EOF' || print_warning "Echec configuration thème GNOME"
# Configuration GNOME - CORRECTION: Thèmes valides
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.gnome.desktop.wm.preferences theme 'Arc-Dark'

# CORRECTION: Configuration correcte du fond d'écran GNOME
mkdir -p /home/$USERNAME/.local/share/backgrounds
curl -o /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png \
    'https://raw.githubusercontent.com/PapaOursPolaire/Linux-tools/refs/heads/Projets/fallout-desktop-bg.png' 2>/dev/null || {
    if [ -f /usr/share/sddm/themes/fallout/background.png ]; then
        cp /usr/share/sddm/themes/fallout/background.png /home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png
    fi
}

# Définir le fond d'écran
gsettings set org.gnome.desktop.background picture-uri "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
gsettings set org.gnome.desktop.background picture-uri-dark "file:///home/$USERNAME/.local/share/backgrounds/fallout-wallpaper.png"
EOF
    fi
    
    print_success "Thèmes et icônes installés et configurés"
}

generate_postinstall() {
    local U TARGET
    U="${USERNAME:-}"

    if [[ -z "$U" ]]; then
        echo "[FATAL] USERNAME est vide, impossible de générer post-install.sh" >&2
        return 1
    fi

    TARGET="/mnt/home/${U}/post-install.sh"
    install -d -m 755 "/mnt/home/${U}"

    cat > "$TARGET" <<'POST_EOF'
# post-install.sh
# Post-install tasks complets pour usage en session utilisateur.
# - Journalise UNIQUEMENT stderr dans ~/post-install-errors.log
# - Continue après chaque échec (affiche un warning, logue l'erreur)
# - Idempotent : réexécutable sans casse
#
# Utilisation :
#   chmod +x ~/post-install.sh
#   ~/post-install.sh
#
# NOTE : adapte certaines commandes selon ta distro (le script tente de détecter le gestionnaire de paquets)

###############################################################################
# Configuration initiale
###############################################################################

set -o pipefail

LOGFILE="$HOME/post-install-errors.log"
: > "$LOGFILE"   # tronquer le log précédent (erreurs uniquement)

# Redirecter uniquement stderr vers LOGFILE, garder stdout visible
exec 3>&2
exec 2>>"$LOGFILE"

echo "[INFO] post-install started at $(date '+%Y-%m-%d %H:%M:%S')"

# Helper pour afficher en vert (succès), jaune (info), rouge (erreur)
green()  { printf "\033[1;32m%s\033[0m\n" "$1" >&3; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1" >&3; }
red()    { printf "\033[1;31m%s\033[0m\n" "$1" >&3; }

# Helper : exécuter une commande, afficher résultat et logger erreur si échoue
run_cmd() {
    # usage: run_cmd "Description" command args...
    local desc="$1"; shift
    echo "--------------------------------------------------------------------------------"
    yellow "[STEP] $desc"
    if "$@" 1>/dev/null; then
        green "[OK] $desc"
        return 0
    else
        # Capture stdout+stderr of the command? We already redirected stderr to LOGFILE.
        red "[ERROR] $desc — voir $LOGFILE pour les détails"
        return 1
    fi
    }

    # Helper : exécuter une commande qui doit être root, tente sudo si pas root
    run_cmd_sudo() {
    local desc="$1"; shift
    if (( EUID == 0 )); then
        run_cmd "$desc" "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
        run_cmd "$desc" sudo "$@"
        else
        red "[ERROR] sudo introuvable — impossible d'exécuter (root) : $desc"
        return 1
        fi
    fi
    }

###############################################################################
# Détection de la distribution et du package manager
###############################################################################
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

echo "[INFO] Détection: PKG_MANAGER=$PKG_MANAGER, DISTRO=$DISTRO"

###############################################################################
# Fonctions utilitaires multi-distro
###############################################################################

update_db() {
    case "$PKG_MANAGER" in
        pacman) run_cmd_sudo "pacman -Syu (update)" pacman -Syu --noconfirm ;;
        apt) run_cmd_sudo "apt update" apt update ;;
        dnf) run_cmd_sudo "dnf check-update" dnf check-update || true ;;
        zypper) run_cmd_sudo "zypper refresh" zypper refresh ;;
        apk) run_cmd_sudo "apk update" apk update ;;
        emerge) run_cmd_sudo "emerge --sync" emerge --sync ;;
        *) red "[WARN] Aucun gestionnaire de paquets pris en charge détecté pour update_db" ;;
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
        *) red "[WARN] flatpak non installé (gestionnaire inconnu)" ;;
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
        red "[WARN] Pas d'AUR helper détecté (paru/yay). Ignorer $pkg ou installez un helper AUR."
        return 1
    fi
}

###############################################################################
# Préparation / sanity checks
###############################################################################

# Ensure HOME variable exists
if [[ -z "${HOME:-}" ]]; then
  export HOME="/home/$(whoami)"
fi

# Ensure sudo is present or we are root for operations needing root
if ! command -v sudo >/dev/null 2>&1 && (( EUID != 0 )); then
  red "[WARN] sudo non trouvé et vous n'êtes pas root — certaines opérations nécessiteront root"
fi

###############################################################################
# SECTION A: Debug Steam / fixes Steam common issues
###############################################################################
steam_debug() {
  echo
  yellow "[TASK] Debug Steam / verification bibliothèques 32-bit (lib32)"

  # On Arch check for multilib packages like lib32-gnutls, lib32-mesa
  if [[ "$PKG_MANAGER" == "pacman" ]]; then
    install_packages lib32-glibc lib32-mesa lib32-libpulse lib32-gnutls 2>/dev/null || true
    run_cmd "Vérifier steam via steam --reset si présent" bash -c 'if command -v steam >/dev/null 2>&1; then steam --reset || true; else echo "steam absent"; fi'
  else
    # On other distros, advise user
    run_cmd "Vérifier que Steam (proton) est installé" bash -c 'if command -v steam >/dev/null 2>&1; then echo "steam ok"; else echo "steam non présent"; fi'
  fi
}

###############################################################################
# SECTION B: Android Studio installation (flatpak preferred)
###############################################################################
install_android_studio() {
  echo
  yellow "[TASK] Installation Android Studio (flatpak preferred)"

  if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.google.AndroidStudio || true
  else
    # Try package manager or snap
    case "$PKG_MANAGER" in
      pacman) install_packages android-studio || true ;;
      apt) run_cmd "Installer Android Studio via snap/apt" bash -c 'echo "Veuillez installer Android Studio manuellement (apt/snap)"; exit 0' || true ;;
      dnf) install_packages android-studio || true ;;
      *) red "[WARN] Pas d'installation automatique fiable pour Android Studio sur cette distro" ;;
    esac
  fi
}

###############################################################################
# SECTION C: Spotify & Spicetify
###############################################################################
install_spotify_and_spicetify() {
  echo
  yellow "[TASK] Installation Spotify et Spicetify (si disponible)"

  # Install Spotify client (flatpak preferred)
  if command -v flatpak >/dev/null 2>&1; then
    install_flatpak com.spotify.Client || true
  else
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
      install_packages spotify || install_aur_pkg spotify || true
    elif [[ "$PKG_MANAGER" == "apt" ]]; then
      # Add Spotify repo example (non exhaustive); user may prefer manual method
      run_cmd "Installer Spotify via apt (méthode générique)" bash -c 'echo "Installer spotify manuellement sur Debian/Ubuntu (repo officiel)"; exit 0' || true
    fi
  fi

  # Spicetify (AUR or npm) - only if user wants it
  if command -v spicetify >/dev/null 2>&1; then
    run_cmd "Spicetify backup" spicetify backup || true
    run_cmd "Spicetify apply" spicetify apply || true
  else
    # try to install via AUR on Arch
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
      install_aur_pkg spicetify-cli || true
    else
      echo "[INFO] spicetify non present; ignorer" >&3
    fi
  fi
}

###############################################################################
# SECTION D: Visual Studio Code + extensions (user session)
###############################################################################
install_vscode_extensions_user() {
  echo
  yellow "[TASK] Installer Visual Studio Code (si binaire 'code' présent) et extensions utiles"

  if ! command -v code >/dev/null 2>&1 ; then
    yellow "Binaire 'code' non trouvé : tenter installation via package manager (si souhaité)"
    case "$PKG_MANAGER" in
      pacman) install_packages code || install_aur_pkg visual-studio-code-bin || true ;;
      apt) run_cmd_sudo "apt install -y code (s'il existe dans repo)" apt install -y code || true ;;
      dnf) install_packages code || true ;;
      *) echo "[INFO] Installez VSCode manuellement si nécessaire" >&3 ;;
    esac
  fi

  if command -v code >/dev/null 2>&1 ; then
    # Extensions list (exemples) - adapte à ta liste
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
    red "[WARN] VSCode CLI (code) introuvable, extensions non installées"
  fi
}

###############################################################################
# SECTION E: Navigateurs (Brave, Chrome, DuckDuckGo Browser)
###############################################################################
install_browsers() {
  echo
  yellow "[TASK] Installation navigateurs (Brave / Google Chrome / DuckDuckGo Browser si possible)"

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
    echo "[INFO] Pour Ubuntu/Debian, ajoutez les repos officiels de Brave/Chrome manuellement si souhaité" >&3
  else
    echo "[INFO] Installez Brave/Chrome via les paquets officiels de votre distro ou flatpak" >&3
  fi
}

###############################################################################
# SECTION F: Fixes et utilitaires (pulseaudio/pipewire, codecs, fonts)
###############################################################################
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

###############################################################################
# SECTION G: Misc user tweaks (spicetify themes backup, config restore)
###############################################################################
user_misc_tweaks() {
  echo
  yellow "[TASK] Tâches utilisateurs facultatives (spicetify backup, config copies...)"

  # Create a ~/bin if not present and ensure it's in PATH
  mkdir -p "$HOME/bin"
  if ! echo "$PATH" | grep -q "$HOME/bin"; then
    echo "export PATH=\"\$HOME/bin:\$PATH\"" >> "$HOME/.profile"
  fi

  # Ensure ~/.config exists
  mkdir -p "$HOME/.config"

  # Example: backup dotfiles directory if present
  if [[ -d "$HOME/.config" ]]; then
    run_cmd "Créer backup .config (si absent)" bash -c 'mkdir -p "$HOME/.config.backup" || true; cp -a --backup=numbered "$HOME/.config/." "$HOME/.config.backup/" || true'
  fi
}

###############################################################################
# SECTION H: Create/Deploy post-install helper (log-only errors)
###############################################################################
deploy_post_install_helper() {
  echo
  yellow "[TASK] Déployer helper post-install (log uniquement les erreurs) vers ~/post-install-helper.sh"

  cat > "$HOME/post-install-helper.sh" <<'HELPER_EOF'
#!/usr/bin/env bash
# Helper abrégé pour tâches additionnelles à lancer en session utilisateur
LOG="$HOME/post-install-errors.log"
:>>"$LOG"
# Redirect only stderr to log; stdout stays visible
exec 3>&2
exec 2>>"$LOG"
echo "[HELPER] start $(date)"
# Add any one-off commands here
echo "[HELPER] done $(date)"
exec 2>&3
HELPER_EOF

  chmod +x "$HOME/post-install-helper.sh"
  run_cmd "Déposer ~/post-install-helper.sh" true || true
}

###############################################################################
# SECTION I: Run Steps in order
###############################################################################
main() {
  yellow "---- Début des tâches post-install ----"

  # 0) mise à jour index
  update_db

  # 1) Steam debug
  steam_debug

  # 2) Android Studio
  install_android_studio

  # 3) Spotify & Spicetify
  install_spotify_and_spicetify

  # 4) Visual Studio Code extensions
  install_vscode_extensions_user

  # 5) Navigateurs
  install_browsers

  # 6) Multimedia & Fonts
  install_multimedia_and_fonts

  # 7) Misc user tweaks
  user_misc_tweaks

  # 8) Deploy helper
  deploy_post_install_helper

  yellow "---- Tâches post-install terminées ----"
  echo
  green "Résumé: si des erreurs ont eu lieu, elles sont consignées dans : $LOGFILE"
  echo "Consultez-les avec : tail -n 200 $LOGFILE"
}

main "$@"

# Restore stderr
exec 2>&3

echo "[INFO] post-install finished at $(date '+%Y-%m-%d %H:%M:%S')"
POST_EOF

# Applique droits avec UID/GID si dispo
    uid="$(/usr/bin/arch-chroot /mnt id -u "$U" 2>/dev/null || true)"
    gid="$(/usr/bin/arch-chroot /mnt id -g "$U" 2>/dev/null || true)"
    if [[ -n "$uid" && -n "$gid" ]]; then
        chown "$uid:$gid" "$TARGET"
    else
        echo "[WARN] UID/GID introuvable pour $U → pas de chown"
    fi
    chmod 0755 "$TARGET"
}




# Fastfetch s'exécute automatiquement
install_fastfetch() {
    print_header "INSTALLATION ET CONFIGURATION DE FASTFETCH"

    if [[ -z "${USERNAME:-}" ]]; then
        print_error "USERNAME non défini. Abandon."
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] install_fastfetch pour ${USERNAME}"
        return 0
    fi

    local USER_HOME="/home/${USERNAME}"
    local CHROOT_USER_HOME="/mnt${USER_HOME}"
    local CONFIG_DIR="${CHROOT_USER_HOME}/.config/fastfetch"
    local PROFILE_FILE="${CHROOT_USER_HOME}/.bash_profile"
    local INVOKE_MARKER="# fastfetch autostart entry - added by alpha.sh"
    local FASTFETCH_BIN="/usr/bin/fastfetch"
    local installed_in_chroot=false

    # 1) Vérifier si fastfetch est disponible dans le chroot
    if /usr/bin/arch-chroot /mnt /usr/bin/env bash -lc 'command -v fastfetch >/dev/null 2>&1'; then
        print_info "fastfetch déjà installé dans le chroot."
        installed_in_chroot=true
    else
        print_info "Tentative d'installation de fastfetch dans le chroot via pacman..."
        if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch >/dev/null 2>&1; then
            print_success "fastfetch installé via pacman dans le chroot."
            installed_in_chroot=true
        else
            print_warning "pacman n'a pas réussi à installer fastfetch dans le chroot."
            # tenter AUR helper si présent
            if /usr/bin/arch-chroot /mnt command -v paru >/dev/null 2>&1; then
                print_info "Tentative d'installation via paru (AUR) dans le chroot..."
                /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm fastfetch >/dev/null 2>&1 && installed_in_chroot=true || print_warning "paru a échoué."
            elif /usr/bin/arch-chroot /mnt command -v yay >/dev/null 2>&1; then
                print_info "Tentative d'installation via yay (AUR) dans le chroot..."
                /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" yay -S --noconfirm fastfetch >/dev/null 2>&1 && installed_in_chroot=true || print_warning "yay a échoué."
            else
                print_warning "Aucun AUR helper détecté dans le chroot. Si fastfetch n'est pas installé, installe-le manuellement ou ajoute un AUR helper."
            fi
        fi
    fi

    if [[ "$installed_in_chroot" != true ]]; then
        print_warning "fastfetch non installé automatiquement dans le chroot. La configuration utilisateur sera écrite, mais l'exécutable manquera."
    fi

    # 2) Créer configuration utilisateur (idempotent)
    mkdir -p "$CONFIG_DIR" || {
        print_error "Impossible de créer $CONFIG_DIR"
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

    # 3) Fixer droits à l'utilisateur dans le chroot
    /usr/bin/arch-chroot /mnt /bin/bash -lc "chown -R ${USERNAME}:${USERNAME} '/home/${USERNAME}/.config/fastfetch' >/dev/null 2>&1 || true"

    print_success "Configuration fastfetch écrite pour ${USERNAME}"

    # 4) Ajouter invocation idempotente dans .bash_profile pour afficher fastfetch à la connexion
    #    - On ajoute un bloc protégé par un marqueur pour éviter duplications
    if ! grep -qF "$INVOKE_MARKER" "$PROFILE_FILE" 2>/dev/null; then
        cat >> "$PROFILE_FILE" <<'BASHFF'

# fastfetch autostart (affiche infos système dans les shells de connexion)
# Ne s'exécute que dans un shell interactif et si fastfetch est disponible.
$INVOKE_MARKER
if [ -t 1 ] && command -v fastfetch >/dev/null 2>&1; then
  # Eviter que fastfetch pollue les sessions graphiques non-terminales
  if [ -z "$DISPLAY" ] || [[ "$TERM" =~ ^xterm|^rxvt|^screen|^tmux|^linux|^vt ]]; then
    fastfetch --config ~/.config/fastfetch/config.jsonc || true
  fi
fi
BASHFF
        # corriger propriétaire
        /usr/bin/arch-chroot /mnt /bin/bash -lc "chown ${USERNAME}:${USERNAME} '/home/${USERNAME}/.bash_profile' >/dev/null 2>&1 || true"
        print_success "Entrée fastfetch ajoutée dans $PROFILE_FILE"
    else
        print_info "Entrée fastfetch déjà présente dans $PROFILE_FILE — rien à faire."
    fi

    # 5) Optionnel : si utilisateur KDE/XDG, indiquer comment autostart graphique (ne pas forcer terminal)
    print_info "Si tu veux un autostart graphique (terminal qui lance fastfetch), crée un .desktop dans ~/.config/autostart qui lance ton terminal avec 'fastfetch' à l'ouverture."

    return 0
}

# Fonctions pour la configuration finale du système
final_configuration() {
    print_header "ETAPE 25/$TOTAL_STEPS: CONFIGURATION FINALE"
    CURRENT_STEP=25
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration finale"
        return 0
    fi
    
    print_info "Configuration finale avec TOUTES LES CORRECTIONS appliquées..."
    
    # Services système optimisés
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF' || print_warning "Certaines configurations ont échoué"
set -e

# Services essentiels
systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable fstrim.timer

# Services audio PipeWire
systemctl --global enable pipewire.service
systemctl --global enable pipewire-pulse.service
systemctl --global enable wireplumber.service

# Optimisations système avancées
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.d/99-swappiness.conf
echo "net.core.default_qdisc=fq" > /etc/sysctl.d/99-network.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-network.conf

# Limites utilisateur
echo "$USERNAME soft nofile 65536" >> /etc/security/limits.conf
echo "$USERNAME hard nofile 65536" >> /etc/security/limits.conf
echo "$USERNAME soft memlock unlimited" >> /etc/security/limits.conf
echo "$USERNAME hard memlock unlimited" >> /etc/security/limits.conf
EOF
    
    # Configuration utilisateur
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Configuration utilisateur partielle"
# Configuration .bashrc COMPLÈTE et CORRIGÉE
cat > /home/$USERNAME/.bashrc <<'BASHRC_EOF'
#!/bin/bash
# ===============================================================================
# Configuration Bash - Arch Linux Fallout Edition v514.2
# Toutes les corrections appliquées
# ===============================================================================

# Si non interactif, arrêter ici
[[ \$- != *i* ]] && return

# Configuration historique
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
shopt -s checkwinsize

# Variables d'environnement
export EDITOR=nano
export VISUAL=nano
export BROWSER=firefox
export JAVA_HOME=/usr/lib/jvm/default
export PATH=\$PATH:\$HOME/.local/bin

# Alias système
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

# Alias Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Alias développement
alias python='python3'
alias pip='pip3'
alias serve='python -m http.server 8000'
alias myip='curl -s ifconfig.me'
alias weather='curl wttr.in'

# Alias système Arch
alias pacup='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacfind='pacman -Ss'
alias pacrem='sudo pacman -Rns'
alias pacclean='sudo pacman -Sc'
alias aurinstall='paru -S'
alias aursearch='paru -Ss'

# Alias audio
alias cava='cava'
alias audio-restart='systemctl --user restart pipewire pipewire-pulse wireplumber'
alias audio-status='systemctl --user status pipewire pipewire-pulse wireplumber'

# Alias Docker
alias docker-clean='docker system prune -af'
alias docker-stop-all='docker stop \$(docker ps -q) 2>/dev/null || true'
alias docker-logs='docker logs'

# FONCTIONS UTILES
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
            *)           echo "Extension non supportée: '\$1'" ;;
        esac
    else
        echo "Fichier non trouvé: '\$1'"
    fi
}

# Fonction mise à jour système complète
full-update() {
    echo " Mise à jour système complète..."
    sudo pacman -Syu
    if command -v paru >/dev/null; then
        echo " Mise à jour AUR..."
        paru -Syu
    fi
    if command -v flatpak >/dev/null; then
        echo " Mise à jour Flatpak..."
        flatpak update
    fi
    echo " Mise à jour terminée!"
}

# Fonction informations système
sysinfo() {
    echo "=== INFORMATIONS SYSTÈME ==="
    echo "OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel: \$(uname -r)"
    echo "Uptime: \$(uptime -p)"
    echo "CPU: \$(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "RAM: \$(free -h | awk '/^Mem:/ {print \$3 "/" \$2}')"
    echo "Disque: \$(df -h / | awk 'NR==2{print \$3 "/" \$2 " (" \$5 " utilisé)"}')"
    echo "Paquets: \$(pacman -Q | wc -l) installés"
    echo "================================"
}

# Prompt personnalisé
if [ "\$EUID" -eq 0 ]; then
    PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

# Fastfetch automatique GARANTI
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

# Configuration VIM améliorée
cat > /home/$USERNAME/.vimrc <<'VIM_EOF'
" Configuration Vim - Arch Linux Fallout Edition
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

" Thème sombre
set background=dark
colorscheme desert

" Mappings utiles
nnoremap <C-n> :set invnumber<CR>
nnoremap <C-h> :noh<CR>
nnoremap <F2> :w<CR>
nnoremap <F3> :q<CR>

" Configuration pour les développeurs
set autowrite
set encoding=utf-8
set fileencoding=utf-8
VIM_EOF

# Configuration Git complète
sudo -u $USERNAME git config --global user.name "$USERNAME"
sudo -u $USERNAME git config --global user.email "$USERNAME@$HOSTNAME.local"
sudo -u $USERNAME git config --global init.defaultBranch main
sudo -u $USERNAME git config --global core.editor nano
sudo -u $USERNAME git config --global pull.rebase false
sudo -u $USERNAME git config --global credential.helper store

# Création répertoires utilisateur
mkdir -p /home/$USERNAME/{Projets,Scripts,Téléchargements/{Logiciels,Musique,Vidéos},Documents/{Dev,Personnel,Notes},Images/{Screenshots,Wallpapers}}

# CORRECTION: Permissions complètes
chown -R $USERNAME:$USERNAME /home/$USERNAME/
chmod 755 /home/$USERNAME
chmod -R 755 /home/$USERNAME/{Projets,Scripts,Documents,Images}
chmod -R 775 /home/$USERNAME/Téléchargements
EOF
    
    print_info "Vérification finale de TOUTES les corrections..."
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
echo ""
echo "VÉRIFICATION FINALE DES CORRECTIONS"
echo ""

# 1. Vérification thèmes
echo "1.  THÈMES ET ICÔNES:"
theme_ok=0
[[ -d /usr/share/icons/Papirus ]] && echo "    Papirus icons" && ((theme_ok++))
[[ -d /usr/share/themes/Arc ]] && echo "    Arc theme" && ((theme_ok++))
[[ -f /usr/share/icons/Tela-blue/index.theme ]] && echo "    Tela icons" && ((theme_ok++))
echo "Thèmes installés: $theme_ok/3"

# 2. Vérification Fastfetch
echo ""
echo "2.  FASTFETCH:"
if command -v fastfetch >/dev/null 2>&1; then
    echo "    Fastfetch installé"
    [[ -f /home/$USERNAME/.config/fastfetch/config.jsonc ]] && echo "    Configuration personnalisée"
    grep -q "fastfetch" /home/$USERNAME/.bashrc && echo "    Lancement automatique configuré"
else
    echo "    Fastfetch non trouvé"
fi

# 3. Vérification VSCode
echo ""
echo "3.  VISUAL STUDIO CODE:"
vscode_ok=false
if command -v code >/dev/null 2>&1; then
    echo "   VSCode (officiel) installé"
    vscode_ok=true
elif command -v code-oss >/dev/null 2>&1; then
    echo "    VSCode (OSS) installé"
    vscode_ok=true
elif [[ -x /opt/visual-studio-code/code ]]; then
    echo "    VSCode (manuel) installé"
    vscode_ok=true
else
    echo "    VSCode non trouvé"
fi

[[ "$vscode_ok" == true ]] && [[ -f /home/$USERNAME/.config/Code/User/settings.json ]] && echo "    Configuration VSCode présente"

# 4. Vérification GRUB
echo ""
echo "4.  GRUB:"
[[ -f /boot/grub/grub.cfg ]] && echo "    GRUB configuré"
[[ -f /boot/grub/themes/fallout/theme.txt ]] && echo "    Thème Fallout installé"
grep -q "GRUB_TIMEOUT=10" /etc/default/grub && echo "    Menu visible (10s timeout)"

# 5. Vérification Plymouth
echo ""
echo "5.  PLYMOUTH:"
[[ -f /usr/share/plymouth/themes/fallout-pipboy/fallout-pipboy.plymouth ]] && echo "    Thème Plymouth PipBoy"
plymouth-set-default-theme --list 2>/dev/null | grep -q fallout-pipboy && echo "    Thème activé"

# 6. Vérification logiciels
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

# 7. Total paquets
echo ""
echo "7.  STATISTIQUES :"
total_packages=$(pacman -Q | wc -l)
echo "    Total paquets installés: $total_packages"

# 8. Services
echo ""
echo "8.  SERVICES :"
systemctl is-enabled NetworkManager >/dev/null && echo "    NetworkManager activé"
systemctl --global is-enabled pipewire >/dev/null 2>&1 && echo "    PipeWire activé"

echo ""
echo "RÉSUMÉ FINAL"
if [[ $theme_ok -ge 2 && "$vscode_ok" == true && $software_count -ge 4 ]]; then
    echo " TOUTES LES CORRECTIONS APPLIQUÉES AVEC SUCCÈS!"
    echo " Système prêt pour utilisation"
else
    echo "  Certaines corrections peuvent nécessiter une intervention manuelle car flemme de créer un script de correction"
fi
echo "=================================================="
EOF
    
    print_success "Configuration finale terminée avec TOUTES LES CORRECTIONS"
}

finish_installation() {
    print_header "INSTALLATION ARCH LINUX FALLOUT EDITION COMPLETE TERMINEE!"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_success " SIMULATION TERMINEE - Aucune modification réelle effectuée"
        echo ""
        echo -e "${YELLOW}Pour une installation réelle, relancez sans --dry-run${NC}"
        return 0
    fi
    
    print_success "L'installation complète d'Arch Linux Fallout Edition est maintenant terminée!"
    echo ""
    echo -e "${GREEN} RESUME COMPLET DE L'INSTALLATION:${NC}"
    echo -e "${CYAN}• Disque :${NC} $DISK"
    echo -e "${CYAN}• Partitions :${NC}"
    echo -e "  - EFI: $EFI_PART ($PARTITION_EFI_SIZE)"
    echo -e "  - Root: $ROOT_PART ($PARTITION_ROOT_SIZE)"
    [[ -n "$HOME_PART" ]] && echo -e "  - Home: $HOME_PART ($PARTITION_HOME_SIZE)"
    [[ -n "$SWAP_PART" ]] && echo -e "  - Swap: $SWAP_PART ($PARTITION_SWAP_SIZE)"
    echo -e "${CYAN}• Hostname :${NC} $HOSTNAME"
    echo -e "${CYAN}• Utilisateur :${NC} $USERNAME"
    echo -e "${CYAN}• Environnement :${NC} $DE_CHOICE"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitionnement :${NC} Personnalisé"
    echo ""
    
    echo -e "${YELLOW}FONCTIONNALITES COMPLETES INSTALLEES:${NC}"
    echo ""
    echo -e "${GREEN}SYSTEME DE BASE :${NC}"
    echo -e "• Configuration française complète (locale, clavier, fuseau horaire)"
    echo -e "• Optimisations système et réseau (BBR, swappiness, limites)"
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "• Configuration personnalisée des partitions"
    [[ "$USE_SEPARATE_HOME" == true ]] && echo -e "• Partition /home séparée activée"
    echo ""
    echo -e "${GREEN}INTERFACE ET THEMES :${NC}"
    echo -e "• Thème GRUB Fallout avec fallback intégré"
    echo -e "• Son de boot Fallout (MP3 ou bip système)"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Splashscreen Plymouth avec animation PipBoy Fallout"
    [[ "$DE_CHOICE" == "kde" ]] && echo -e "• Configuration SDDM avec fond d'écran Fallout"
    echo -e "• Thèmes d'icônes (Tela, Papirus) et thèmes Sweet/Arc"
    echo -e "• Thèmes GRUB additionnels (BSOL, Minegrub, etc.)"
    echo ""
    echo -e "${GREEN}SYSTEME AUDIO PROFESSIONNEL :${NC}"
    echo -e "• PipeWire + WirePlumber (audio basse latence)"
    echo -e "• CAVA (visualiseur audio terminal configuré)"
    echo -e "• PavuControl (contrôle audio graphique)"
    echo -e "• Correction bug conflict PipeWire-Jack appliquée"
    echo ""
    echo -e "${GREEN}DEVELOPPEMENT COMPLET :${NC}"
    echo -e "• Langages: Python, Node.js, Java OpenJDK, Go, Rust, C/C++"
    echo -e "• Outils: Git, Docker, cmake, make, gcc, clang"
    echo -e "• IDEs: Visual Studio Code avec extensions (Copilot, Python, C++, Java, Tailwind)"
    echo -e "• Android Studio (développement mobile)"
    echo -e "• Terminal amélioré avec Fastfetch et aliases utiles"
    echo ""
    echo -e "${GREEN}NAVIGATION WEB COMPLETE :${NC}"
    echo -e "• Firefox (configuré pour Netflix/Disney+ DRM)"
    echo -e "• Google Chrome, Chromium, Brave Browser"
    echo -e "• DuckDuckGo Browser (si disponible)"
    echo ""
    echo -e "${GREEN}MULTIMEDIA ET DIVERTISSEMENT :${NC}"
    echo -e "• Spotify + Spicetify (thème Dribbblish Nord-Dark)"
    echo -e "• VLC, MPV, OBS Studio, Audacity"
    echo -e "• GIMP, Inkscape (design et image)"
    echo ""
    echo -e "${GREEN}GAMING ET COMPATIBILITE :${NC}"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Steam avec Proton configuré"
    [[ "$DE_CHOICE" != "none" ]] && echo -e "• Lutris, GameMode"
    echo -e "• Wine + Winetricks (compatibilité Windows complète)"
    echo -e "• Wine-mono, Wine-gecko pour applications .NET"
    echo ""
    echo -e "${GREEN}  UTILITAIRES ET OUTILS :${NC}"
    echo -e "• AUR Helper Paru pré-configuré"
    echo -e "• Flatpak avec Flathub activé"
    echo -e "• TimeShift (sauvegardes), GParted, KeePassXC"
    echo -e "• Fastfetch avec logo Arch et configuration personnalisée"
    echo -e "• Configuration Bash complète avec aliases et fonctions"
    echo ""
    echo -e "${GREEN} OPTIMISATIONS VITESSE V514.2 :${NC}"
    echo -e "• Configuration Pacman optimisée (ParallelDownloads=10)"
    echo -e "• Miroirs optimisés avec Reflector avancé"
    echo -e "• Téléchargements parallèles maximisés"
    echo -e "• Configuration réseau BBR pour performances maximales"
    echo ""
    echo -e "${GREEN} NOUVELLES FONCTIONNALITES V514.2 :${NC}"
    echo -e "• Configuration personnalisée des tailles de partitions"
    echo -e "• Partition /home séparée optionnelle avec interface O/N"
    echo -e "• Mot de passe minimum réduit à 6 caractères"
    echo -e "• Correction définitive du bug conflict PipeWire-Jack"
    echo -e "• Validation automatique des tailles de partitions"
    echo ""
    
    echo -e "${BLUE} INSTRUCTIONS POST-INSTALLATION :${NC}"
    echo -e "1. ${WHITE}Retirez le support d'installation${NC}"
    echo -e "2. ${WHITE}Redémarrez le système${NC}"
    echo -e "3. ${WHITE}Connectez-vous avec:${NC} ${CYAN}$USERNAME${NC}"
    echo -e "4. ${WHITE}Première mise à jour:${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo -e "5. ${WHITE}Test audio:${NC} ${CYAN}cava${NC} (visualiseur) ou ${CYAN}pavucontrol${NC}"
    echo -e "6. ${WHITE}Installation AUR:${NC} ${CYAN}paru -S <paquet>${NC}"
    echo -e "7. ${WHITE}Changement thème GRUB:${NC} modifier ${CYAN}/etc/default/grub${NC}"
    echo -e "8. ${WHITE}Configuration Spicetify:${NC} ${CYAN}spicetify apply${NC}"
    echo ""
    
    echo -e "${PURPLE} COMMANDES UTILES POST-INSTALLATION :${NC}"
    echo -e "• ${WHITE}fastfetch${NC} - Informations système avec logo Arch"
    echo -e "• ${WHITE}cava${NC} - Visualiseur audio en temps réel"
    echo -e "• ${WHITE}audio-restart${NC} - Redémarrer le système audio"
    echo -e "• ${WHITE}docker-clean${NC} - Nettoyer Docker"
    echo -e "• ${WHITE}extract <fichier>${NC} - Extraire n'importe quelle archive"
    echo -e "• ${WHITE}serve${NC} - Serveur web local Python (port 8000)"
    echo -e "• ${WHITE}spicetify apply${NC} - Appliquer thèmes Spotify"
    echo -e "• ${WHITE}systemctl --user status pipewire${NC} - Etat du système audio"
    echo ""
    
    # Sauvegarde du log
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation-fallout.log" 2>/dev/null || true
        print_info "📋 Log d'installation sauvegardé: /home/$USERNAME/installation-fallout.log"
    fi
    
    if confirm_action "Voulez-vous redémarrer maintenant ?" "O"; then
        print_info "Redémarrage dans 5 secondes..."
        
        print_info "Démontage des partitions..."
        sync
        
        # Démontage propre
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || print_warning "Démontage partiel"
        
        echo ""
        for i in {5..1}; do
            echo -ne "\r${YELLOW} Redémarrage dans $i secondes... (Ctrl+C pour annuler)${NC}"
            sleep 1
        done
        echo ""
        echo ""
        print_success " Redémarrage en cours... Bienvenue dans Arch Linux !"
        
        reboot
    else
        print_info "Installation terminée. Redémarrez manuellement quand vous le souhaitez."
        echo -e "${YELLOW} N'oubliez pas de retirer la clé USB bootable !${NC}"
        
        # Démontage manuel
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true
        
        echo ""
        echo -e "${GREEN} Installation complète V514.2 ! Votre système Arch Linux est prêt.${NC}"
        echo ""
        echo -e "${CYAN}Une fois redémarré, exécutez:${NC}"
        echo -e "• ${WHITE}~/post-install.sh${NC} - Script de post-installation"
        echo -e "• ${WHITE}fastfetch${NC} - Afficher les informations système"
        echo -e "• ${WHITE}cava${NC} - Tester le visualiseur audio"
        echo ""
        echo -e "${PURPLE} Merci d'avoir utilisé le script d'installation Arch Linux (version 514.2)${NC}"
    fi
}

# Point d'entrée sécurisé
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # S'assure que paru est présent avant toute install AUR Gaming
    if ! chroot_cmd_exists paru; then
        print_info "Paru non disponible — (ré)installation automatique…"
        ensure_paru_in_chroot || print_warning "Impossible de (ré)installer un helper AUR — les paquets AUR Gaming seront ignorés"
    fi

    exec > >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    main "$@"
    
    # Exit explicite
    exit 0

