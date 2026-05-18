#!/bin/bash

if ! command -v arch-chroot &>/dev/null; then
    echo "[INFO] arch-chroot manquant, tentative d'installation immédiate..."
    pacman -Sy --noconfirm arch-install-scripts || {
        echo "[ERREUR] Impossible d'installer arch-install-scripts. Arrêt du script."
        exit 1
    }
fi

# Script d'installation automatisée Arch Linux
# Made by PapaOursPolaire - available on GitHub PapaOursPolaire
# Version: 864.4, correctif 4 de la version 864.4
# Mise à jour : 08/02/2026 à 15H34
# PRENDRE  LA  NOUVELLE VERSION après un dos2unix SUR LINUX ou dans le chroot, pacman -Sy dos2unix
# Correction de 2358 erreurs référencées par ShellCheck et par la conssole  TTY de l'ISO corrigées
# Erreur de l'éxécution automatique de fastfetch : il est bien là, mais ne s'éxécute pas automatiquement
# Virtual Studio ne s'installe tj pas meme avec sa propre fonction !
# Suppression des logiciels/extensions vulkan car elles me cassaient la tete et ne fonctionnaient pas sous automatisation
# Refonte de la variable install_paru() -> 130eme refonte le 14/08 et marche tj pas
#[community] -> RETIRE prcq les serveurs packages [community] sont devenus obsolètes le 13/08/2025 vers 20 heures
#Include = /etc/pacman.d/mirrorlist -> Ces ptn de fdp ont nettoyé les serveurs dcp ça faisait eerreur 404 et en plus la plupart ont crash à cause de cel 2 heures de perdus pour des conneries pareil non mais wlh je cable argh
# Penser à enlever le mode DRY RUN, car il est devenu futile depuis la version 246.6, il avait pour but de simuler le mode apératoire ainsi que de vérifier l'apparence du script.
# Configuration globale -> Thème (en cours de dévellopement, pas de fonction déclarée)

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="864.4"
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
readonly KDESPLASH_URL="https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/fallout-splashscreen4k.zip"
readonly SDDM_VIDEO_URL="https://mega.nz/file/PpJzyBjB#ONC7iTpdJkUxcOtLRuclrzJ-vsRRDgqR2oEkJPcHEbk" # Inutilisée bug API MegaNZ
readonly SDDM_THEME_DIR="/usr/share/sddm/themes/SDDM-Fallout-theme" # Inutilisée, rework de la logique
readonly LOCKSCREEN_THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.falloutlock"

# Variables globales
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

# Variables pour le partitionnement personnalisé
PARTITION_EFI_SIZE="512M"
PARTITION_ROOT_SIZE="60G"
PARTITION_SWAP_SIZE="8G"
PARTITION_HOME_SIZE="remaining"
CUSTOM_PARTITIONING=false

# Fonction main - point d'entrée principale
main() {
    # Initialisation
    init_logging
    parse_arguments "$@"

    echo "Chargement des ressources..."
    echo -e "${CYAN}Arch Linux Fallout Edition - Version ${SCRIPT_VERSION}${NC}"
    echo ""

    # Détection automatique du mode de boot (DOIT être en premier)
    detect_boot_mode

    # Vérifie si /usr/bin/arch-chroot est installé, sinon l'installe
    if ! command -v /usr/bin/arch-chroot &>/dev/null; then
        echo "[INFO] /usr/bin/arch-chroot manquant, tentative d'installation..."
        pacman -Sy --noconfirm arch-install-scripts || {
            echo "[ERREUR] Impossible d'installer arch-install-scripts. Arrêt du script."
            exit 1
        }
    fi

    # Gestion des signaux
    trap cleanup EXIT INT TERM

    # Installation des commandes requises
    check_requirements || {
        print_error "Échec de l'installation des commandes requises"
        return 1
    }

    # Affichage
    show_banner

    if [[ "$DRY_RUN" == true ]]; then
        print_warning "MODE SIMULATION ACTIVE"
        echo -e "${YELLOW}   • Aucune modification ne sera effectuée${NC}"
        echo -e "${YELLOW}   • Toutes les opérations seront simulées${NC}"
        echo -e "${YELLOW}   • Mode boot détecté: ${BOOT_MODE}${NC}"
        echo ""
    fi

    # Séquence complète d'installation
    echo -e "${CYAN}DÉMARRAGE DE L'INSTALLATION D'ARCH LINUX...${NC}"
    echo -e "${YELLOW}Mode de boot: ${BOOT_MODE}${NC}"
    echo ""

    echo -e "${PURPLE}PHASE 1: PRÉPARATION SYSTÈME${NC}"

    check_requirements || {
        print_error "Échec de la vérification des prérequis"
        return 1
    }

    test_environment || {
        print_error "Échec du test de l'environnement"
        return 1
    }

    optimize_pacman || {
        print_warning "Optimisation Pacman partielle"
    }

    echo -e "${PURPLE}PHASE 2: CONFIGURATION DISQUE ET PARTITIONS${NC}"

    select_disk || {
        print_error "Échec de la sélection du disque"
        return 1
    }

    choose_partitioning || {
        print_error "Échec du choix du partitionnement"
        return 1
    }

    format_partitions || {
        print_error "Échec du formatage des partitions"
        return 1
    }

    mount_partitions || {
        print_error "Échec du montage des partitions"
        return 1
    }

    echo -e "${PURPLE}PHASE 3: INSTALLATION SYSTÈME DE BASE${NC}"

    install_system || {
        print_error "Échec de l'installation du système de base"
        return 1
    }

    configure_system || {
        print_error "Échec de la configuration système"
        return 1
    }

    create_users || {
        print_error "Échec de la création des utilisateurs"
        return 1
    }

    echo -e "${PURPLE}PHASE 4: INTERFACE GRAPHIQUE${NC}"

    select_desktop || {
        print_warning "Aucun environnement de bureau sélectionné"
    }

    if [[ "$DE_CHOICE" != "none" ]]; then
        install_desktop || {
            print_error "Échec de l'installation de l'environnement de bureau"
            return 1
        }
    else
        print_info "Mode console/serveur - pas d'interface graphique"
    fi

    echo -e "${PURPLE}PHASE 5: BOOTLOADER ET THÈMES${NC}"

    # Configuration du bootloader adaptée au mode
    configure_grub || {
        print_error "Échec de la configuration du bootloader"
        return 1
    }

    # Configuration KDE uniquement si KDE est installé
    if [[ "$DE_CHOICE" == "kde" ]]; then
        configure_kde_lockscreen || {
            print_warning "Échec de la configuration du lockscreen KDE"
        }
    fi

    echo -e "${PURPLE}PHASE 6: AUDIO ET MULTIMÉDIA${NC}"

    install_audio_system || {
        print_warning "Échec de l'installation du système audio"
    }

    install_boot_sound || {
        print_warning "Échec de l'installation du son de boot"
    }

    # Plymouth uniquement pour les environnements graphiques
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_plymouth || {
            print_warning "Échec de la configuration de Plymouth"
        }
    fi

    # Gestionnaire d'affichage uniquement pour les environnements graphiques
    if [[ "$DE_CHOICE" != "none" ]]; then
        configure_sddm || {
            print_warning "Échec de la configuration du gestionnaire d'affichage"
        }
    fi

    echo -e "${PURPLE}PHASE 7: APPLICATIONS ET LOGICIELS${NC}"

    install_software || {
        print_warning "Échec partiel de l'installation des logiciels"
    }

    install_web || {
        print_warning "Échec partiel de l'installation des navigateurs"
    }

    install_spotify || {
        print_warning "Échec de l'installation de Spotify"
    }

    install_wine || {
        print_warning "Échec de l'installation de Wine"
    }

    echo -e "${PURPLE}PHASE 8: OUTILS ET DÉVELOPPEMENTT${NC}"

    install_paru || {
        print_warning "Échec de l'installation de Paru"
    }

    install_development || {
        print_warning "Échec partiel de l'installation des outils de développement"
    }

    # Steam uniquement pour les environnements graphiques
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_steam || {
            print_warning "Échec de l'installation de Steam"
        }
    fi

    echo -e "${PURPLE}PHASE 9: THÈMES ET PERSONNALISATION${NC}"

    # Thèmes uniquement pour les environnements graphiques
    if [[ "$DE_CHOICE" != "none" ]]; then
        install_themes || {
            print_warning "Échec partiel de l'installation des thèmes"
        }
    fi

    install_fastfetch || {
        print_warning "Échec de l'installation de Fastfetch"
    }

    echo -e "${PURPLE}PHASE 10: CONFIGURATION FINALE${NC}"

    final_config || {
        print_warning "Échec partiel de la configuration finale"
    }

    install_vscode || {
        print_warning "Échec de l'installation de VS Code"
    }

    generate_postinstall || {
        print_warning "Échec de la génération du script post-installation"
    }

    # Finalisation
    finish_install || {
        print_error "Échec de la finalisation de l'installation"
        return 1
    }

    echo -e "${GREEN}RAPPORT D'INSTALLATION TERMINÉ${NC}"
    echo ""

    # Affichage du résumé selon le mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${GREEN}✓ Installation UEFI réussie${NC}"
        echo -e "  • Table GPT créée"
        echo -e "  • Partition EFI configurée"
        echo -e "  • GRUB UEFI installé"
    else
        echo -e "${GREEN}✓ Installation BIOS/Legacy réussie${NC}"
        echo -e "  • Table MBR créée"
        echo -e "  • Partition Boot configurée"
        echo -e "  • GRUB BIOS installé"
    fi

    echo ""
    echo -e "${CYAN}Prochaines étapes:${NC}"
    echo -e "1. Retirer le support d'installation"
    echo -e "2. Redémarrer le système"
    echo -e "3. Se connecter avec l'utilisateur: ${USERNAME}"

    if [[ "$BOOT_MODE" == "bios" ]]; then
        while true; do
            read -r -p "Taille partition Boot (défaut : 512M): " boot_input
            boot_input=${boot_input:-512M}
            if validate_input "$boot_input" "size"; then
                PARTITION_BOOT_SIZE="$boot_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    fi

    echo ""
    print_success "Installation d'Arch Linux Fallout Edition terminée avec succès!"

    # Sauvegarde finale du log
    if [[ -f "$LOG_FILE" ]] && [[ -n "$USERNAME" ]]; then
        local user_log="/mnt/home/$USERNAME/installation.log"
        if cp "$LOG_FILE" "$user_log" 2>/dev/null; then
            print_info "Journal d'installation sauvegardé: $user_log"
        fi
    fi

    return 0
}

detect_boot_mode() {
    print_header "DETECTION DU MODE DE BOOT"

    if [[ -d /sys/firmware/efi ]]; then
        BOOT_MODE="uefi"
        print_success "Mode UEFI détecté"
        echo -e "${GREEN}• Table de partitions: GPT${NC}"
        echo -e "${GREEN}• Partition boot: EFI (FAT32)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB x86_64-efi${NC}"
    else
        BOOT_MODE="bios"
        print_success "Mode BIOS/Legacy détecté"
        echo -e "${GREEN}• Table de partitions: MBR${NC}"
        echo -e "${GREEN}• Partition boot: Boot (ext4)${NC}"
        echo -e "${GREEN}• Bootloader: GRUB i386-pc${NC}"
    fi

    # Vérification cohérence du mode de boot
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -d /sys/firmware/efi ]]; then
        print_error "Incohérence détectée: BOOT_MODE=uefi mais /sys/firmware/efi n'existe pas"
        echo "Forçage du mode BIOS"
        BOOT_MODE="bios"
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ -d /sys/firmware/efi ]]; then
        print_error "Incohérence détectée: BOOT_MODE=bios mais /sys/firmware/efi existe"
        echo "Forçage du mode UEFI"
        BOOT_MODE="uefi"
    fi

    echo ""
    echo -e "${YELLOW}Configuration pour le mode: ${BOOT_MODE}${NC}"
    echo ""
}

configure_grub() {
    print_header "ETAPE 13/$TOTAL_STEPS: CONFIGURATION BOOTLOADER selon le firmware"
    CURRENT_STEP=13

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration du bootloader"
        return 0
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        configure_grub_uefi
    else
        configure_grub_bios
    fi
}

configure_grub_bios() {
    print_header "ETAPE 14/$TOTAL_STEPS: CONFIGURATION GRUB BIOS"
    CURRENT_STEP=14
    print_info "Installation et configuration du bootloader GRUB pour BIOS..."

    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installation de GRUB pour BIOS sur ${DISK}"
grub-install --target=i386-pc --recheck "${DISK}"
EOF

    if [[ $? -ne 0 ]]; then
        print_error "Échec de l'installation de GRUB pour BIOS"
        return 1
    fi

    print_info "Téléchargement du thème Fallout depuis GitHub..."
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

    print_info "Configuration de /etc/default/grub avec le thème Fallout..."
    cat > /mnt/etc/default/grub <<'EOF'
# Configuration GRUB BIOS avec thème Fallout
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

    print_info "Génération du fichier grub.cfg..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Échec de génération du fichier grub.cfg"
        return 1
    }

    print_success "GRUB BIOS installé et thème Fallout appliqué !"
}

configure_grub_uefi() {
    print_header "ETAPE 14/$TOTAL_STEPS: CONFIGURATION GRUB UEFI"
    CURRENT_STEP=14
    print_info "Installation et configuration du bootloader GRUB pour UEFI..."

    # Installation de GRUB pour UEFI
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
echo "[INFO] Installation de GRUB pour UEFI..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
EOF

    if [[ $? -ne 0 ]]; then
        print_error "Échec de l'installation de GRUB pour UEFI"
        return 1
    fi

    print_info "Téléchargement du thème Fallout depuis GitHub..."
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

    print_info "Configuration de /etc/default/grub avec le thème Fallout..."
    cat > /mnt/etc/default/grub <<'EOF'
# Configuration GRUB UEFI avec thème Fallout
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

    print_info "Génération du fichier grub.cfg..."
    /usr/bin/arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || {
        print_error "Échec de génération du fichier grub.cfg"
        return 1
    }

    print_success "GRUB UEFI installé et thème Fallout appliqué !"
}

install_web() {
    print_header "ETAPE 21/$TOTAL_STEPS: INSTALLATION DES NAVIGATEURS WEB"
    CURRENT_STEP=21

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub com.vivaldi.Vivaldi || true
    flatpak install -y flathub com.opera.Opera || true
    flatpak install -y flathub org.midori_browser.Midori || true

    browsers=(
        # Vérifier lesquels sont installés sur GNOME & KDE , sont différents parfois
        "Firefox|firefox|firefox||org.mozilla.firefox"
        "Chromium|chromium|chromium||org.chromium.Chromium"
        "Brave|brave-browser||brave-bin|com.brave.Browser" # Ne marche pas -> Installé via le script post-install.sh
        "Vivaldi|vivaldi|vivaldi||com.vivaldi.Vivaldi" # GNOME uniquement (enfin je pense)
        "Tor Browser|torbrowser-launcher|torbrowser-launcher||org.torproject.torbrowser-launcher" # Ne marche pas
        "GNOME Web (Epiphany)|epiphany|epiphany||org.gnome.Epiphany"
        "Midori|midori||midori|" # Ne marche pas
        "Google Chrome|google-chrome||google-chrome|com.google.Chrome" # Ne marche pas mais installé  via le script post-install.sh
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
    print_header "ETAPE 26/$TOTAL_STEPS: INSTALLATION DE STEAM"
    CURRENT_STEP=26

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

fix_spicetify_prefs() { # Ne fonctionne pas car Spotify & spicetify ne sont pas installés dans le chroot à cause de multi je sais plus quoi # Faudrait peut etre le supprimer dans la version stable si je réussis pas de tt façon le post-install réussi lui
    print_header "CORRECTION SPICETIFY PREFS (ROBUSTE, NON BLOQUANT)"

    # Sécurité : s'assurer que USERNAME est défini
    if [[ -z "${USERNAME:-}" ]]; then
        print_warning "USERNAME non défini – impossible d'appliquer Spicetify pour un utilisateur."
        return 0
    fi

    /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -lc '
set -u

# Journalisation dédiée utilisateur
LOG_DIR="${HOME}/.local/share/spicetify-fix"
LOG_FILE="${LOG_DIR}/fix.log"
mkdir -p "$LOG_DIR" || true
# Redirige tout vers le log + stdout
exec > >(tee -a "$LOG_FILE") 2>&1
echo ""
echo "[$(date "+%F %T")] Démarrage fix_spicetify_prefs"

# Helpers d affichage locaux
info(){ echo "[INFO]  $*"; }
ok(){ echo "[OK]    $*"; }
warn(){ echo "[WARN]  $*"; }
err(){ echo "[ERROR] $*"; }

# Etat cumul des avertissements/erreurs (mais on sort avec 0)
WARN_COUNT=0
ERR_COUNT=0
warn_wrap(){ warn "$@"; WARN_COUNT=$((WARN_COUNT+1)); }
err_wrap(){  err  "$@"; ERR_COUNT=$((ERR_COUNT+1)); }

# Détection outillage
if ! command -v spicetify >/dev/null 2>&1; then
    warn_wrap "spicetify introuvable pour ${USER}. Etape ignorée."
    echo "Fin (spicetify absent)"
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
    echo "Fin (Spotify absent"
    exit 0
fi

# Localisation du fichier prefs
# Chemins possibles (on privilégie Flatpak si présent)
CANDIDATES=()
if [[ "$IS_FLATPAK" == true ]]; then
    CANDIDATES+=("${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")
fi
if [[ "$IS_NATIVE" == true ]]; then
    CANDIDATES+=("${HOME}/.config/spotify/prefs")
fi
# Ajout de secours au cas où je connais le script y'a 90% qui foire ce salopiot
CANDIDATES+=("${HOME}/.config/spotify/prefs" "${HOME}/.var/app/com.spotify.Client/config/spotify/prefs")

PREFS_PATH=""
for p in "${CANDIDATES[@]}"; do
    if [[ -f "$p" ]]; then
        PREFS_PATH="$p"
        ok "prefs existant trouvé: $PREFS_PATH"
        break
    fi
done

# Si non trouvé, on crée prudemment un squelette sans lancer Spotify (prcq  chroot/tty)
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

    mkdir -p "$TARGET_DIR" || { err_wrap "Impossible de créer ${TARGET_DIR}"; echo "Fin (échec création dossier)"; exit 0; }
    PREFS_PATH="${TARGET_DIR}/prefs"

    if [[ ! -f "$PREFS_PATH" ]]; then
        : > "$PREFS_PATH" || { err_wrap "Impossible de créer ${PREFS_PATH}"; echo "Fin (échec création prefs)"; exit 0; }
        ok "prefs créé: $PREFS_PATH (sera complété après le premier lancement de Spotify)."
        PREFS_WAS_CREATED="yes"
    else
        ok "prefs trouvé juste après création du dossier: $PREFS_PATH"
        PREFS_WAS_CREATED="no"
    fi
else
    PREFS_WAS_CREATED="no"
fi

# Configuration Spicetify
APPLY_OK=true

# 1) Déclare le prefs_path
if spicetify config prefs_path "$PREFS_PATH"; then
    ok "spicetify: prefs_path enregistré."
else
    warn_wrap "spicetify config prefs_path a échoué."
    APPLY_OK=false
fi

# 2) Thème
if spicetify config current_theme "DribbblishNordDark"; then
    ok "spicetify: thème défini (DribbblishNordDark)."
else
    warn_wrap "spicetify: impossible de définir le thème (peut être non installé)."
fi

# 3) Backup + apply
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

# Fallback post-install : autostart au 1er vrai lancement graphique
# Si on a dû créer le prefs à vide, ou si apply a échoué, on prépare une tâche
# utilisateur qui réessaiera automatiquement après le premier lancement de Spotify.
# Je fais une multitude de commentaires pour celui-là mais IL MARCHE PAS
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

# Récapitulatif et fin
if [[ $ERR_COUNT -gt 0 ]]; then
    warn "Terminé avec ${ERR_COUNT} erreur(s) et ${WARN_COUNT} avertissement(s). Voir le log: ${LOG_FILE}"
elif [[ $WARN_COUNT -gt 0 ]]; then
    warn "Terminé avec ${WARN_COUNT} avertissement(s). Voir le log: ${LOG_FILE}"
else
    ok "Terminé sans avertissement."
fi

echo "Fin fix_spicetify_prefs"
exit 0
' || {
        # On n'échoue pas le script global : message et on continue
        print_warning "fix_spicetify_prefs: la sous-commande chroot a remonté un non-zéro (voir log utilisateur). Étape CONTINUÉE."
        return 0

    print_success "fix_spicetify_prefs exécuté (voir le journal utilisateur ~/.local/share/spicetify-fix/fix.log dans le chroot)."
}

# Fonctions utilitaires et logging
# Vérifie la présence d'une commande dans le chroot
chroot_cmd_exists() {
    /usr/bin/arch-chroot /mnt bash -lc "command -v '${1}' >/dev/null 2>&1"
}

# (Ré)assure l'installation de paru dans le chroot -> Ne fonctionne pas nn plus
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

# Optimisation de la configuration Pacman pour la vitesse
optimize_pacman() {
    print_header "ETAPE 3/$TOTAL_STEPS: OPTIMISATION DE PACMAN"

    # Sauvegarde configuration originale
    if [[ -f /etc/pacman.conf ]]; then
        cp /etc/pacman.conf /etc/pacman.conf.backup.$(date +%s)
    fi

    print_info "Configuration de Pacman pour performances maximales..."

    # Configuration optimisée
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

    print_info "Nettoyage des miroirs obsolètes..."

    # Supprimer [community] s'il existe (obsolète)
    if grep -q "^\[community\]" /etc/pacman.conf; then
        sed -i '/^\[community\]/,/^Include/d' /etc/pacman.conf
        print_warning "Dépôt [community] supprimé (obsolète)"
    fi

    print_info "Optimisation des miroirs avec reflector..."

    # Installation reflector si manquant
    if ! command -v reflector &>/dev/null; then
        pacman -S --noconfirm reflector || {
            print_warning "Reflector non installable, utilisation miroirs par défaut"
            return 0
        }
    fi

    # Génération miroirs optimisés
    local reflector_success=false

    # Essai 1: Pays rapides
    if reflector \
        --country France,Germany,Netherlands,Belgium,Switzerland \
        --protocol https \
        --latest 20 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist; then
        reflector_success=true
        print_success "Miroirs optimisés (pays ciblés)"

    # Essai 2: Tous pays
    elif reflector \
        --protocol https \
        --latest 20 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist; then
        reflector_success=true
        print_success "Miroirs optimisés (tous pays)"

    # Essai 3: Fallback minimum
    else
        print_warning "Reflector échoué, utilisation miroir de secours"
        cat > /etc/pacman.d/mirrorlist <<'EOF'
## Fallback ArchLinux
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
EOF
    fi

    print_info "Nettoyage du cache Pacman..."

    # Nettoyage agressif mais sûr
    pacman -Scc --noconfirm 2>/dev/null || true
    rm -rf /var/lib/pacman/sync/* 2>/dev/null || true

    print_info "Synchronisation des bases de données..."

    # Resync avec nouvelle configuration
    if pacman -Syy --noconfirm; then
        print_success "Bases de données synchronisées"
    else
        print_warning "Synchronisation partielle, continuation..."
    fi

    print_success "PACMAN OPTIMISÉ - Prêt pour l'installation rapide"
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

# Affichage formaté - trouver mieux comme "mise  en page" si j'ai le temps
print_header() {
    local message="$1"
    echo ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo -e "${WHITE}$message${NC}"
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
    log_message "HEADER" "$message"
}

# Je garde en anglais ou pas ? A penser faire un full en anglais mais ave google trad :/
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

# Barre de progression avec estimation de temps # A améliorer si possible
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

    case "${unit^^}" in
        "M") echo "$number" ;;
        "G") echo $((number * 1024)) ;;
        *) echo "0" ;;
    esac
}

# Interface pour la configuration personnalisée des partitions
configure_custom_partitioning() {
    print_header "CONFIGURATION PERSONNALISEE DES PARTITIONS"

    echo -e "${WHITE}Configuration des tailles de partitions :${NC}"
    echo -e "${YELLOW}Format attendu : nombre suivi de M/m (Mo) ou G/g (Go)${NC}"
    echo -e "${YELLOW}Exemples : 512M, 512m, 2G, 2g, 100G, 100g${NC}"
    echo ""

    # Configuration différente selon le mode de boot
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        # Configuration EFI pour UEFI
        while true; do
            read -r -p "Taille partition EFI (défaut : 512M): " efi_input
            efi_input=${efi_input:-512M}
            if validate_input "$efi_input" "size"; then
                PARTITION_EFI_SIZE="$efi_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    else
        # Configuration Boot pour BIOS
        while true; do
            read -r -p "Taille partition Boot (défaut : 512M): " boot_input
            boot_input=${boot_input:-512M}
            if validate_input "$boot_input" "size"; then
                PARTITION_BOOT_SIZE="$boot_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 512M, 512m, 2G, 2g)"
        done
    fi

    # Configuration Root (identique pour les deux modes)
    while true; do
        read -r -p "Taille partition Root (défaut: 60G) : " root_input
        root_input=${root_input:-60G}
        if validate_input "$root_input" "size"; then
            PARTITION_ROOT_SIZE="$root_input"
            break
        fi
        print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex : 60G, 60g)"
    done

    # Configuration Swap (optionnelle)
    if confirm_action "Créer une partition Swap?" "O"; then
        USE_SWAP=true
        while true; do
            read -r -p "Taille partition Swap (défaut: 8G) : " swap_input
            swap_input=${swap_input:-8G}
            if validate_input "$swap_input" "size"; then
                PARTITION_SWAP_SIZE="$swap_input"
                break
            fi
            print_warning "Format invalide ! Utilisez : nombre + M/m ou G/g (ex: 8G, 8g)"
        done
    else
        USE_SWAP=false
        print_info "Partition Swap désactivée"
    fi

    # Configuration Home (optionnelle)
    if confirm_action "Créer une partition /home séparée ?" "N"; then
        USE_SEPARATE_HOME=true
        echo -e "${WHITE}Options pour la partition Home :${NC}"
        echo -e "${CYAN}1.${NC} Utiliser le reste de l'espace disponible"
        echo -e "${CYAN}2.${NC} Spécifier une taille personnalisée"

        local home_choice
        while true; do
            read -r -p "Votre choix (1-2) : " home_choice
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
        print_info "Partition /home séparée désactivée - Il sera dans la partition Root"
    fi

    # Résumé de la configuration
    echo ""
    echo -e "${GREEN}RESUME DE LA CONFIGURATION${NC}"
    echo -e "${WHITE}• Mode boot :${NC} $BOOT_MODE"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "${WHITE}• Partition EFI :${NC} $PARTITION_EFI_SIZE (FAT32)"
    else
        echo -e "${WHITE}• Partition Boot :${NC} $PARTITION_BOOT_SIZE (ext4)"
    fi
    echo -e "${WHITE}• Partition Root :${NC} $PARTITION_ROOT_SIZE"
    [[ "$USE_SWAP" == true ]] && echo -e "${WHITE}• Partition Swap :${NC} $PARTITION_SWAP_SIZE"
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$PARTITION_HOME_SIZE" == "remaining" ]]; then
            echo -e "${WHITE}• Partition Home :${NC} Reste de l'espace disponible"
        else
            echo -e "${WHITE}• Partition Home :${NC} $PARTITION_HOME_SIZE"
        fi
    else
        echo -e "${WHITE}• Partition Home :${NC} Intégrée dans Root"
    fi
    echo ""

    if ! confirm_action "Confirmer cette configuration ?" "O"; then
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
        read -r -p "$message (O/N, défaut : $default): " response
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
    # Eviter les exécutions multiples -> Ne pas désactiver, sans cela ça buggue
    if $CLEANUP_DONE; then
        return 0
    fi
    CLEANUP_DONE=true

    local exit_code=$?
    echo "Début du nettoyage (code  : $exit_code)..." >> "$LOG_FILE"

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

# Configuration des traps
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
    echo ""
    echo -e "${WHITE}Par PapaOursPolaire (disponible sur GitHub) - Version $SCRIPT_VERSION${NC}"
    echo ""
    echo -e "${WHITE}Pour les flemmards et débutants • Développement • Gaming • Thème par défaut Fallout${NC}"
    echo  ""
    echo -e "${CYAN}===============================================================================${NC}"
    echo ""
}

show_help() {
    cat << EOF
Usage : $0 [OPTIONS]

# Purement décoratif car flemme de faire un vrai menu
Options :
    -h, --help     Afficher cette aide
    -d, --dry-run  Mode simulation (ne fait aucune modification)
    --version      Afficher la version

    FONCTIONNALITES COMPLETES DE CETTE EDITION:

    SYSTEME DE BASE :

    • Installation automatisée d'Arch Linux (UEFI uniquement)
    • Configuration française complète (locale, clavier, fuseau horaire)
    • Choix entre KDE Plasma, GNOME ou mode console (pour serveur minimaliste)
    • Configuration personnalisée des tailles de partitions
    • Partition /home séparée optionnelle (O/N)

    INTERFACE ET THEMES FALLOUT :

    • Thème Fallout pour GRUB
    • Son de boot Fallout (MP3 ou bip système de fallback) # Ne fonctionne pas
    • Splashscreen avec animation PipBoy
    • Plymouth du logo arch (peut etre changé via BearGrubChanger, disponible sur mon compte GitHub : PapaOursPolaire)
    • Configuration SDDM avec fond d'écran personnalisé Fallout (vidéo, .gif ou images aléatoires à vous de changer)
    • Thèmes d'icones (Tela, Papirus) et thèmes visuels modernes

    SYSTEME AUDIO PROFESSIONNEL :

    • PipeWire + WirePlumber (audio basse latence professionnel)
    • CAVA (visualiseur audio terminal avec thème vert Matrix)
    • PavuControl (interface graphique de controle audio)
    • Configuration automatique pour streaming et enregistrement

    ENVIRONNEMENT DE DEVELOPPEMENT COMPLET :

    • Langages : Python, Node.js, Java OpenJDK, Go, Rust & C/C++
    • Outils : Git, Docker, cmake, make, gcc, clang & gdb
    • Visual Studio Code avec extensions préinstallées :
        - GitHub Copilot (IA)
        - Python, C++, Java
        - Tailwind CSS, Prettier, ESLint
        - Live Server, Jupyter
        - Material Icon Theme, Error Lens
    • Android Studio pour développement mobile
    • Terminal amélioré avec Fastfetch et aliases de développement (à activer via un script de mon repo, indispobile dans le  script pour des raisons débiles)

    NAVIGATION WEB PREINSTALLEE:

    • Firefox (configuré pour Netflix, Disney+ avec DRM)
    • Google Chrome, Chromium, Brave Browser, Google Chrome & Brave sont installés dans le script post-install
    • DuckDuckGo Browser (confidentialité) (indisponible pour l'instant)

    MULTIMEDIA ET DIVERTISSEMENT:

    • Spotify + Spicetify CLI avec thème Dribbblish Nord-Dark, installé lors du script post-install
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

    • AUR Helper Paru pré-installé et configuré (indisponible)
    • Flatpak
    • TimeShift (sauvegardes système), GParted, KeePassXC
    • Fastfetch avec logo Arch ASCII et informations système (indisponible)
    • Configuration Bash complète avec 50+ aliases utiles (indisponible)

    OPTIMISATIONS SYSTEME:

    • Configuration Pacman optimisée (ParallelDownloads=10)
    • Miroirs optimisés avec Reflector avancé
    • Optimisations réseau (BBR, TCP)
    • Gestion mémoire optimisée (swappiness)
    • Services système configurés pour performance
    • Barres de progression avec estimations de temps réelles
    • Gestion d'erreurs robuste avec fallbacks automatiques

    NOUVELLES FONCTIONNALITES DE LA VERSION 864.4:

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
    • Débugguage  de plus de 3000 erreurs

    Exemples d'utilisation: # Ne marche pas
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
    • Exécution depuis l'ISO Arch Linux

    Post-installation:

    • Redémarrage automatique proposé
    • Log d'installation complet sauvegardé pour consultation et pour me l'envoyer si problème
    • Script de vérification post-installation inclus (Pour les logiciels n'ayant pu etre installés dans le chroot)
    • Configuration optimisée prête à l'emploi
    • Tous les logiciels importants de développement et multimédia installés

EOF
}

parse_arguments() { # Est-ce qu'il marche réellement ? J'ai réussi qu'une fois à le faire marcher !
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

    # Vérification root
    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être exécuté en tant que root !"
        return 1
    fi

    # Vérification connexion Internet AVANT toute installation
    print_info "Vérification de la connexion Internet..."
    local internet_ok=false
    local test_hosts=("archlinux.org" "8.8.8.8" "1.1.1.1" "github.com")

    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" &> /dev/null; then
            print_success "Connexion Internet active (testé: $host)"
            internet_ok=true
            break
        fi
    done

    if [[ "$internet_ok" != true ]]; then
        print_error "AUCUNE CONNEXION INTERNET DÉTECTÉE !"
        echo "Vérifiez votre connexion et réessayez."
        return 1
    fi

    # Liste COMPLÈTE des commandes REQUISES avec leurs paquets
    local requirements=(
        # Commande:Paquet
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
        "reflector:reflector"
        "rsync:rsync"
        "gzip:gzip"
        "tar:tar"
    )

    # Vérification et installation des dépendances
    print_info "Vérification des outils système..."
    local missing_packages=()
    local all_ok=true

    # Étape 1: Vérifier ce qui manque
    for req in "${requirements[@]}"; do
        IFS=":" read -r cmd pkg <<< "$req"

        if ! command -v "$cmd" &>/dev/null; then
            print_warning "$cmd manquant (paquet: $pkg)"
            if [[ ! " ${missing_packages[@]} " =~ " ${pkg} " ]]; then
                missing_packages+=("$pkg")
            fi
            all_ok=false
        else
            print_success "$cmd disponible"
        fi
    done

    # Étape 2: Installer les paquets manquants
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_info "Installation des paquets manquants..."
        echo "Paquets à installer: ${missing_packages[*]}"

        # Mise à jour des miroirs avant installation
        print_info "Mise à jour des bases de données pacman..."
        pacman -Sy --noconfirm || {
            print_error "Échec de la mise à jour des bases"
            return 1
        }

        # Installation en bloc
        if pacman -S --noconfirm "${missing_packages[@]}"; then
            print_success "Tous les paquets installés avec succès"
            all_ok=true
        else
            # Fallback: installation un par un
            print_warning "Installation en bloc échouée, tentative un par un..."
            local failed_packages=()

            for pkg in "${missing_packages[@]}"; do
                if pacman -S --noconfirm "$pkg"; then
                    print_success "$pkg installé"
                else
                    print_error "Échec installation de $pkg"
                    failed_packages+=("$pkg")
                    all_ok=false
                fi
            done

            if [[ ${#failed_packages[@]} -gt 0 ]]; then
                print_error "Paquets en échec: ${failed_packages[*]}"
            fi
        fi
    fi

    # Étape 3: Vérification FORCÉE de git et unzip (critiques)
    print_info "Vérification CRITIQUE de git et unzip..."

    if ! command -v git &>/dev/null; then
        print_error "GIT ABSENT - Installation FORCÉE..."
        pacman -S --noconfirm git || {
            print_error "ÉCHEC CRITIQUE: Impossible d'installer git"
            return 1
        }
    fi

    if ! command -v unzip &>/dev/null; then
        print_error "UNZIP ABSENT - Installation FORCÉE..."
        pacman -S --noconfirm unzip || {
            print_error "ÉCHEC CRITIQUE: Impossible d'installer unzip"
            return 1
        }
    fi

    # Vérification finale
    print_info "Vérification finale des outils critiques..."
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
        print_error "OUTILS CRITIQUES MANQUANTS - ARRÊT"
        return 1
    fi

    # Activation user namespaces pour Flatpak
    if sysctl -n kernel.unprivileged_userns_clone 2>/dev/null | grep -q '^0$'; then
        print_info "Activation de kernel.unprivileged_userns_clone=1 pour Flatpak"
        sysctl -w kernel.unprivileged_userns_clone=1 || true
        echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.d/00-local-userns.conf
    fi

    # Synchronisation horloge
    timedatectl set-ntp true
    sleep 2

    print_success "TOUS LES PRÉREQUIS SONT SATISFAITS"
    return 0
}

test_environment() {
    print_header "ETAPE 2/$TOTAL_STEPS: TEST DE L'ENVIRONNEMENT D'INSTALLATION"

    local errors=0
    local warnings=0

    echo -e "${WHITE}=== TEST DES OUTILS SYSTÈME ===${NC}"

    # Outils CRITIQUES (doivent être présents)
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

    # Outils IMPORTANTS (avertissement si manquants)
    local important_tools=("reflector" "rsync" "p7zip")
    for tool in "${important_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "  ${YELLOW}!${NC} $tool - manquant (non critique)"
            warnings=$((warnings + 1))
        fi
    done

    echo ""
    echo -e "${WHITE}=== TEST RÉSEAU ===${NC}"

    # Test Internet avec timeout court
    if ping -c 1 -W 2 archlinux.org &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Connexion Internet stable"
    else
        echo -e "  ${YELLOW}!${NC} Connexion Internet lente/instable"
        warnings=$((warnings + 1))
    fi

    echo ""
    echo -e "${WHITE}=== TEST DISPONIBILITÉ SYSTÈME ===${NC}"

    # Test espace disque
    local available_space=$(df /tmp --output=avail | tail -1 | awk '{print int($1/1024)}')
    if [[ $available_space -gt 1000 ]]; then
        echo -e "  ${GREEN}✓${NC} Espace disque: ${available_space}MB (suffisant)"
    elif [[ $available_space -gt 500 ]]; then
        echo -e "  ${YELLOW}!${NC} Espace disque: ${available_space}MB (limité)"
        warnings=$((warnings + 1))
    else
        echo -e "  ${RED}✗${NC} Espace disque: ${available_space}MB (INSUFFISANT)"
        errors=$((errors + 1))
    fi

    # Test RAM
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

    # Test CPU
    local cpu_cores=$(nproc 2>/dev/null || echo 1)
    if [[ $cpu_cores -ge 2 ]]; then
        echo -e "  ${GREEN}✓${NC} CPU: ${cpu_cores} cœurs"
    else
        echo -e "  ${YELLOW}!${NC} CPU: 1 cœur (limité)"
        warnings=$((warnings + 1))
    fi

    echo ""
    echo -e "${WHITE}=== TEST MODE BOOT ===${NC}"

    # Détection et affichage mode boot
    detect_boot_mode

    # Vérification mode boot cohérent
    if [[ "$BOOT_MODE" == "uefi" ]] && [[ ! -d /sys/firmware/efi ]]; then
        echo -e "  ${RED}✗${NC} INCOHÉRENCE: Mode UEFI détecté mais pas de /sys/firmware/efi"
        errors=$((errors + 1))
    elif [[ "$BOOT_MODE" == "bios" ]] && [[ -d /sys/firmware/efi ]]; then
        echo -e "  ${RED}✗${NC} INCOHÉRENCE: Mode BIOS détecté mais /sys/firmware/efi existe"
        errors=$((errors + 1))
    else
        echo -e "  ${GREEN}✓${NC} Mode boot cohérent: $BOOT_MODE"
    fi

    echo ""
    echo -e "${WHITE}=== RÉSUMÉ FINAL ===${NC}"

    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -eq 0 ]]; then
            print_success "ENVIRONNEMENT OPTIMAL - Prêt pour l'installation"
            return 0
        else
            print_warning "ENVIRONNEMENT ACCEPTABLE avec $warnings avertissement(s)"
            echo "L'installation peut continuer mais certaines fonctionnalités"
            echo "pourraient être limitées."
            return 0
        fi
    else
        print_error "ENVIRONNEMENT INCOMPATIBLE - $errors erreur(s) critique(s)"
        echo "Corrigez les problèmes ci-dessus avant de continuer."
        return 1
    fi
}

# Fonctions de gestion des disques et partitions
select_disk() {
    print_header "ETAPE 4/$TOTAL_STEPS: SELECTION DU DISQUE"
    CURRENT_STEP=4

    # Attendre que les disques soient détectés
    sleep 2
    sync

    local disks
    mapfile -t disks < <(lsblk -dno NAME,SIZE,MODEL | grep -E '^(sd[a-z]|nvme[0-9]n[0-9]|vd[a-z])' | awk '{print $1}')

    if [[ ${#disks[@]} -eq 0 ]]; then
        print_error "Aucun disque détecté !"
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
        read -r -p "Sélectionnez le disque (numéro) : " disk_choice

        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && \
            [[ "$disk_choice" -ge 1 ]] && \
            [[ "$disk_choice" -le "${#disks[@]}" ]]; then
            DISK="/dev/${disks[$((disk_choice - 1))]}"
            break
        fi
        print_warning "Sélection invalide !"
    done

    # Vérification finale du disque
    if [[ ! -b "$DISK" ]]; then
        print_error "Le disque $DISK n'existe pas !"
        return 1
    fi

    print_success "Disque sélectionné : $DISK"
    return 0
}

choose_partitioning() {
    print_header "ETAPE 5/$TOTAL_STEPS: CHOIX DU PARTITIONNEMENT"
    CURRENT_STEP=5

    echo -e "${WHITE}Options de partitionnement :${NC}"
    echo -e "${CYAN}1.${NC} Conserver les partitions existantes"
    echo -e "${CYAN}2.${NC} Créer un nouveau partitionnement automatique"
    echo -e "${CYAN}3.${NC} Créer un nouveau partitionnement personnalisé"

    local choice
    while true; do
        read -r -p "Votre choix (1-3): " choice
        case $choice in
            1)
                print_info "Conservation des partitions existantes"
                # Sous-menu pour l'option 1
                echo -e "${WHITE}Sous-options :${NC}"
                echo -e "${CYAN}a.${NC} Utiliser une partition unique et la diviser"
                echo -e "${CYAN}b.${NC} Utiliser des partitions existantes déjà créées"
                local sub_choice
                while true; do
                    read -r -p "Votre choix (a/b): " sub_choice
                    case $sub_choice in
                        a)
                            print_info "Utilisation d'une partition unique à diviser"
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
                print_info "Création d'un nouveau partitionnement automatique"
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

use_single_partition_and_split() {
    print_info "Sélection d'une partition unique à diviser"

    # Détection des partitions disponibles
    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")

    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "Aucune partition trouvée sur $DISK"
        return 1
    fi

    echo -e "${WHITE}Partitions détectées :${NC}"
    for i in "${!partitions[@]}"; do
        local part="/dev/${partitions[i]}"
        local size=$(lsblk -no SIZE "$part" 2>/dev/null || echo "Inconnu")
        local fstype=$(lsblk -no FSTYPE "$part" 2>/dev/null || echo "Inconnu")
        echo -e "${CYAN}$((i + 1)).${NC} $part - $size - $fstype"
    done

    local part_choice
    while true; do
        read -r -p "Sélectionnez la partition à diviser (numéro) : " part_choice
        if [[ "$part_choice" =~ ^[0-9]+$ ]] && \
           [[ "$part_choice" -ge 1 ]] && \
           [[ "$part_choice" -le "${#partitions[@]}" ]]; then
            local selected_part="/dev/${partitions[$((part_choice - 1))]}"
            break
        fi
        print_warning "Sélection invalide !"
    done

    # Configuration des tailles pour les nouvelles partitions
    print_info "Configuration des tailles des nouvelles partitions"
    configure_custom_partitioning

    # Effacer la partition sélectionnée et créer nouvelle table de partitions
    print_warning "ATTENTION : Toutes les données sur $selected_part seront effacées !"
    if ! confirm_action "Confirmer l'effacement de la partition ?"; then
        return 1
    fi

    # Calculer la taille totale disponible
    local total_size=$(lsblk -bno SIZE "$selected_part" | head -1)
    local total_size_mb=$((total_size / 1024 / 1024))

    # Convertir les tailles en MB
    local efi_mb=$(convert_to_mb "$PARTITION_EFI_SIZE")
    local root_mb=$(convert_to_mb "$PARTITION_ROOT_SIZE")
    local swap_mb=0
    local home_mb=0

    [[ "$USE_SWAP" == true ]] && swap_mb=$(convert_to_mb "$PARTITION_SWAP_SIZE")
    [[ "$USE_SEPARATE_HOME" == true ]] && home_mb=$(convert_to_mb "$PARTITION_HOME_SIZE")

    # Vérifier l'espace disponible
    local total_required_mb=$((efi_mb + root_mb + swap_mb + home_mb))
    if [[ $total_required_mb -gt $total_size_mb ]]; then
        print_error "Espace insuffisant sur la partition !"
        print_error "Disponible: ${total_size_mb}MB, Requis: ${total_required_mb}MB"
        return 1
    fi

    # Commencer le partitionnement
    print_info "Début du partitionnement de $selected_part"

    # Effacer la partition
    parted -s "$selected_part" rm 1 || {
        print_error "Impossible de supprimer la partition"
        return 1
    }

    # Créer nouvelle table de partitions
    parted -s "$selected_part" mklabel gpt || {
        print_error "Impossible de créer la table de partitions"
        return 1
    }

    # Créer les partitions
    local current_pos=1

    # Partition EFI
    local efi_end=$((current_pos + efi_mb))
    parted -s "$selected_part" mkpart primary fat32 ${current_pos}MiB ${efi_end}MiB
    parted -s "$selected_part" set 1 esp on
    EFI_PART="${selected_part}1"
    current_pos=$efi_end

    # Partition Root
    local root_end=$((current_pos + root_mb))
    parted -s "$selected_part" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB
    ROOT_PART="${selected_part}2"
    current_pos=$root_end

    # Partition Swap (optionnelle)
    if [[ "$USE_SWAP" == true ]]; then
        local swap_end=$((current_pos + swap_mb))
        parted -s "$selected_part" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB
        SWAP_PART="${selected_part}3"
        current_pos=$swap_end
    fi

    # Partition Home (optionnelle)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        parted -s "$selected_part" mkpart primary ext4 ${current_pos}MiB 100%
        HOME_PART="${selected_part}$((USE_SWAP ? 4 : 3))"
    fi

    print_success "Partitionnement terminé"
    return 0
}

detect_existing_partitions() {
    print_info "Détection des partitions existantes sur $DISK..."

    local partitions
    mapfile -t partitions < <(lsblk -no NAME "$DISK" | grep -E "${DISK##*/}[0-9p]")

    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "Aucune partition trouvée sur $DISK"
        return 1
    fi

    echo -e "${WHITE}Partitions détectées :${NC}"
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
        read -r -p "Partition Root (numéro) : " root_choice
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
            read -r -p "Partition Home (numéro) : " home_choice
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
        echo -e "${WHITE}Sélectionnez la partition Swap :${NC}"
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

    # Vérifier que le disque n'est pas utilisé
    if lsof "$DISK" 2>/dev/null; then
        print_error "Le disque $DISK est encore utilisé par des processus"
        lsof "$DISK" | head -10
        return 1
    fi

    # Vérifier l'état du disque
    if ! lsblk "$DISK" >/dev/null 2>&1; then
        print_error "Le disque $DISK n'est pas accessible"
        return 1
    fi
}

create_new_partitioning() {
    print_header "CREATION DU PARTITIONNEMENT"

    print_warning "ATTENTION : Toutes les données sur $DISK seront effacées !"

    if ! confirm_action "Confirmer l'effacement du disque ?"; then
        return 1
    fi

    # Nettoyage complet et forcé du disque
    print_info "Nettoyage complet du disque..."

    # Démontage forcé de toutes les partitions
    umount -f "${DISK}"* 2>/dev/null || true
    swapoff "${DISK}"* 2>/dev/null || true

    # Nettoyage des signatures avec méthodes multiples
    print_info "Effacement des signatures de partition..."
    wipefs -af "$DISK" 2>/dev/null || true
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none 2>/dev/null || true

    # Synchronisation et attente
    sync
    sleep 3

    # Réinitialisation des variables de partition
    EFI_PART=""
    BOOT_PART=""
    ROOT_PART=""
    HOME_PART=""
    SWAP_PART=""

    # Création de la table de partitions selon le mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Création de la table GPT pour UEFI..."
        if ! parted -s "$DISK" mklabel gpt; then
            print_error "Echec de création de la table GPT"
            return 1
        fi
    else
        print_info "Création de la table MBR pour BIOS..."
        if ! parted -s "$DISK" mklabel msdos; then
            print_error "Echec de création de la table MBR"
            return 1
        fi
    fi

    # Synchronisation après création table
    sync
    sleep 2

    # Calcul des tailles en MB
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

    # Partition 1: Boot/EFI selon le mode
    local boot_end=$((current_pos + boot_mb))
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Création partition EFI (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary fat32 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Echec création partition EFI"
            return 1
        fi
        parted -s "$DISK" set 1 esp on
        EFI_PART=$(get_partition_number "$DISK" 1)
        print_success "Partition EFI créée: $EFI_PART"
    else
        print_info "Création partition Boot (${current_pos}MiB-${boot_end}MiB)..."
        if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${boot_end}MiB; then
            print_error "Echec création partition Boot"
            return 1
        fi
        parted -s "$DISK" set 1 boot on
        BOOT_PART=$(get_partition_number "$DISK" 1)
        print_success "Partition Boot créée: $BOOT_PART"
    fi
    current_pos=$boot_end
    part_num=2

    # Synchronisation après première partition
    sync
    sleep 1

    # Partition 2: Root
    local root_end=$((current_pos + root_mb))
    print_info "Création partition Root (${current_pos}MiB-${root_end}MiB)..."
    if ! parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${root_end}MiB; then
        print_error "Echec création partition Root"
        return 1
    fi
    ROOT_PART=$(get_partition_number "$DISK" 2)
    print_success "Partition Root créée: $ROOT_PART"
    current_pos=$root_end
    part_num=3

    sync
    sleep 1

    # Partition 3: Swap (optionnelle)
    if [[ "$USE_SWAP" == true ]] && [[ $swap_mb -gt 0 ]]; then
        local swap_end=$((current_pos + swap_mb))
        print_info "Création partition Swap (${current_pos}MiB-${swap_end}MiB)..."
        if parted -s "$DISK" mkpart primary linux-swap ${current_pos}MiB ${swap_end}MiB; then
            SWAP_PART=$(get_partition_number "$DISK" $part_num)
            print_success "Partition Swap créée: $SWAP_PART"
            current_pos=$swap_end
            part_num=$((part_num + 1))
        else
            print_warning "Echec création partition Swap, continuation sans swap"
            USE_SWAP=false
        fi
        sync
        sleep 1
    fi

    # Partition 4: Home (optionnelle)
    if [[ "$USE_SEPARATE_HOME" == true ]]; then
        if [[ "$home_mb" == "remaining" ]]; then
            print_info "Création partition Home (reste de l'espace)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB 100%; then
                HOME_PART=$(get_partition_number "$DISK" $part_num)
                print_success "Partition Home créée: $HOME_PART"
            else
                print_warning "Echec création partition Home, continuation sans home séparé"
                USE_SEPARATE_HOME=false
            fi
        elif [[ $home_mb -gt 0 ]]; then
            local home_end=$((current_pos + home_mb))
            print_info "Création partition Home (${current_pos}MiB-${home_end}MiB)..."
            if parted -s "$DISK" mkpart primary ext4 ${current_pos}MiB ${home_end}MiB; then
                HOME_PART=$(get_partition_number "$DISK" $part_num)
                print_success "Partition Home créée: $HOME_PART"
            else
                print_warning "Echec création partition Home, continuation sans home séparé"
                USE_SEPARATE_HOME=false
            fi
        fi
    fi

    # Synchronisation finale
    sync
    sleep 3

    # Rafraîchir les informations des partitions
    print_info "Rafraîchissement des informations de partition..."
    partprobe "$DISK" 2>/dev/null || {
        print_warning "partprobe échoué, tentative alternative..."
        # Alternative: forcer la relecture des partitions
        echo 1 > /sys/block/${DISK##*/}/device/rescan 2>/dev/null || true
    }

    # Attendre que les périphériques soient disponibles
    sleep 5

    # Vérification que les partitions existent
    print_info "Vérification des partitions créées..."

    # Fonction pour vérifier une partition
    check_partition_exists() {
        local part="$1"
        local part_name="$2"

        if [[ -n "$part" ]] && [[ ! -b "$part" ]]; then
            print_warning "Partition $part_name ($part) non détectée, recherche alternative..."

            # Chercher la partition par label ou numéro
            local found_part=""
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
                    # Vérifier si c'est probablement la bonne partition
                    if [[ "$part_name" == "ROOT" ]] && lsblk -n -o MOUNTPOINT "$p" 2>/dev/null | grep -q "/mnt"; then
                        found_part="$p"
                        break
                    fi
                fi
            done

            if [[ -n "$found_part" ]]; then
                print_success "Partition $part_name trouvée: $found_part"
                eval "${part_name}_PART=\"$found_part\""
            else
                print_error "Partition $part_name introuvable"
                return 1
            fi
        fi
        return 0
    }

    # Vérifier chaque partition
    check_partition_exists "$ROOT_PART" "ROOT" || return 1

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        check_partition_exists "$EFI_PART" "EFI" || return 1
    else
        check_partition_exists "$BOOT_PART" "BOOT" || return 1
    fi

    if [[ "$USE_SWAP" == true ]] && [[ -n "$SWAP_PART" ]]; then
        check_partition_exists "$SWAP_PART" "SWAP" || {
            print_warning "Partition Swap introuvable, désactivation..."
            USE_SWAP=false
            SWAP_PART=""
        }
    fi

    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]]; then
        check_partition_exists "$HOME_PART" "HOME" || {
            print_warning "Partition Home introuvable, désactivation..."
            USE_SEPARATE_HOME=false
            HOME_PART=""
        }
    fi

    # Afficher le résumé final
    print_success "Partitionnement terminé avec succès"
    print_info "Résumé du partitionnement:"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$DISK"

    echo ""
    echo -e "${GREEN}Partitions configurées:${NC}"
    echo -e "  • Root: $ROOT_PART"
    [[ -n "$EFI_PART" ]] && echo -e "  • EFI: $EFI_PART"
    [[ -n "$BOOT_PART" ]] && echo -e "  • Boot: $BOOT_PART"
    [[ -n "$SWAP_PART" ]] && echo -e "  • Swap: $SWAP_PART"
    [[ -n "$HOME_PART" ]] && echo -e "  • Home: $HOME_PART"

    return 0
}

create_mbr_with_fdisk() {
    print_info "Création table MBR avec fdisk..."

    # Création de la table MBR avec fdisk
    echo "o\nw\n" | fdisk "$DISK" >/dev/null 2>&1

    # Vérification
    if ! parted -s "$DISK" print | grep -q "msdos"; then
        print_error "Échec création MBR avec fdisk"
        return 1
    fi

    print_success "Table MBR créée avec fdisk"
    return 0
}

format_partitions() {
    print_header "ETAPE 6/$TOTAL_STEPS: FORMATAGE DES PARTITIONS"
    CURRENT_STEP=6

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du formatage"
        return 0
    fi

    # Attendre que les partitions soient disponibles
    print_info "Attente de la disponibilité des partitions..."
    partprobe "$DISK" 2>/dev/null || true
    sleep 8  # Augmenter le temps d'attente
    sync

    # Vérification que les partitions existent
    print_info "Vérification des partitions..."

    if [[ ! -b "$ROOT_PART" ]]; then
        print_error "Partition ROOT non trouvée: $ROOT_PART"
        print_info "Partitions disponibles sur $DISK:"
        lsblk -no NAME,SIZE,TYPE "$DISK" | grep -E "^${DISK##*/}(p?[0-9]+)"
        print_info "Tentative de recherche alternative..."

        # Chercher la partition root
        for p in "${DISK}"*; do
            if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
                print_info "  Trouvé: $p"
                # Supposer que la plus grande partition est root
                local size1=$(lsblk -bno SIZE "$ROOT_PART" 2>/dev/null | head -1)
                local size2=$(lsblk -bno SIZE "$p" 2>/dev/null | head -1)
                if [[ -z "$size1" ]] || [[ $size2 -gt $size1 ]]; then
                    ROOT_PART="$p"
                fi
            fi
        done

        if [[ ! -b "$ROOT_PART" ]]; then
            print_error "Impossible de trouver la partition root"
            return 1
        fi
        print_success "Partition root identifiée: $ROOT_PART"
    fi

    # Vérification selon le mode de boot
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        if [[ ! -b "$EFI_PART" ]]; then
            print_error "Partition EFI non trouvée: $EFI_PART"
            print_info "Recherche de partition EFI..."
            # Chercher une partition FAT32
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ "$p" != "$ROOT_PART" ]] && [[ -b "$p" ]]; then
                    local fstype=$(lsblk -no FSTYPE "$p" 2>/dev/null || blkid -s TYPE -o value "$p" 2>/dev/null)
                    if [[ "$fstype" == "vfat" ]] || [[ "$fstype" == "fat32" ]]; then
                        EFI_PART="$p"
                        print_success "Partition EFI identifiée: $EFI_PART"
                        break
                    fi
                fi
            done
            if [[ ! -b "$EFI_PART" ]]; then
                print_error "Impossible de trouver la partition EFI"
                return 1
            fi
        fi
    else
        if [[ ! -b "$BOOT_PART" ]]; then
            print_error "Partition Boot non trouvée: $BOOT_PART"
            # La partition boot est généralement la première après EFI
            for p in "${DISK}"*; do
                if [[ "$p" != "$DISK" ]] && [[ "$p" != "$ROOT_PART" ]] && [[ -b "$p" ]]; then
                    BOOT_PART="$p"
                    print_success "Partition Boot identifiée: $BOOT_PART"
                    break
                fi
            done
            if [[ ! -b "$BOOT_PART" ]]; then
                print_error "Impossible de trouver la partition Boot"
                return 1
            fi
        fi
    fi

    # Démontage préventif
    print_info "Démontage préventif..."
    umount -f "$EFI_PART" "$BOOT_PART" "$ROOT_PART" "$HOME_PART" 2>/dev/null || true
    swapoff "$SWAP_PART" 2>/dev/null || true
    sleep 2

    # Formatage selon le mode de boot
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        print_info "Formatage partition EFI: $EFI_PART"
        if mkfs.fat -F32 -n 'EFI' "$EFI_PART"; then
            print_success "Partition EFI formatée (FAT32)"
        else
            print_error "Echec formatage EFI"
            return 1
        fi
    else
        print_info "Formatage partition Boot: $BOOT_PART"
        if mkfs.ext4 -F -L 'ArchBoot' "$BOOT_PART"; then
            print_success "Partition Boot formatée (ext4)"
        else
            print_error "Echec formatage Boot"
            return 1
        fi
    fi

    # Formatage Root
    print_info "Formatage partition Root: $ROOT_PART"
    if mkfs.ext4 -F -L 'ArchRoot' "$ROOT_PART"; then
        print_success "Partition Root formatée (ext4)"
    else
        print_error "Echec formatage Root"
        return 1
    fi

    # Formatage Home (optionnel)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]] && [[ -b "$HOME_PART" ]]; then
        print_info "Formatage partition Home: $HOME_PART"
        if mkfs.ext4 -F -L 'ArchHome' "$HOME_PART"; then
            print_success "Partition Home formatée (ext4)"
        else
            print_warning "Echec formatage Home, désactivation..."
            USE_SEPARATE_HOME=false
        fi
    fi

    # Configuration Swap (optionnel)
    if [[ "$USE_SWAP" == true ]] && [[ -n "$SWAP_PART" ]] && [[ -b "$SWAP_PART" ]]; then
        print_info "Configuration partition Swap: $SWAP_PART"
        if mkswap -L 'ArchSwap' "$SWAP_PART"; then
            if swapon "$SWAP_PART"; then
                print_success "Partition Swap configurée et activée"
            else
                print_warning "Impossible d'activer le swap"
            fi
        else
            print_warning "Echec configuration Swap, désactivation..."
            USE_SWAP=false
        fi
    fi

    print_success "Formatage terminé avec succès"
    return 0
}

# Fonction utilitaire pour obtenir le numéro de partition correct
get_partition_number() {
    local disk="$1"
    local part_index="$2"

    # Vérifier si le disque est un périphérique NVMe
    if [[ "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
        # Format NVMe: /dev/nvme0n1p1, /dev/nvme0n1p2, etc.
        echo "${disk}p${part_index}"
    # Vérifier si c'est un disque standard (SATA/SCSI)
    elif [[ "$disk" =~ /dev/(sd[a-z]|vd[a-z]|hd[a-z])$ ]]; then
        # Format SATA: /dev/sda1, /dev/sda2, etc.
        echo "${disk}${part_index}"
    else
        # Fallback: utiliser le format standard
        echo "${disk}${part_index}"
    fi
}

mount_partitions() {
    print_header "ETAPE 7/$TOTAL_STEPS: MONTAGE DES PARTITIONS"
    CURRENT_STEP=7

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation du montage"
        return 0
    fi

    # Démontage préventif
    print_info "Démontage préventif..."
    umount -R /mnt 2>/dev/null || true
    mkdir -p /mnt

    # Montage Root
    print_info "Montage partition Root: $ROOT_PART sur /mnt"
    if ! mount "$ROOT_PART" /mnt; then
        print_error "Echec montage partition Root"
        print_info "Tentative avec vérification du système de fichiers..."
        # Vérifier et réparer le système de fichiers si nécessaire
        if fsck -y "$ROOT_PART"; then
            if mount "$ROOT_PART" /mnt; then
                print_success "Partition Root montée après réparation"
            else
                return 1
            fi
        else
            return 1
        fi
    fi

    # Montage Boot/EFI selon le mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        mkdir -p /mnt/boot/efi
        print_info "Montage partition EFI: $EFI_PART sur /mnt/boot/efi"
        if ! mount "$EFI_PART" /mnt/boot/efi; then
            print_error "Echec montage partition EFI"
            return 1
        fi
    else
        mkdir -p /mnt/boot
        print_info "Montage partition Boot: $BOOT_PART sur /mnt/boot"
        if ! mount "$BOOT_PART" /mnt/boot; then
            print_error "Echec montage partition Boot"
            return 1
        fi
    fi

    # Montage Home (optionnel)
    if [[ "$USE_SEPARATE_HOME" == true ]] && [[ -n "$HOME_PART" ]] && [[ -b "$HOME_PART" ]]; then
        mkdir -p /mnt/home
        print_info "Montage partition Home: $HOME_PART sur /mnt/home"
        if ! mount "$HOME_PART" /mnt/home; then
            print_warning "Echec montage partition Home, continuation sans home séparé"
            USE_SEPARATE_HOME=false
        else
            print_success "Partition Home montée"
        fi
    fi

    # Vérification du montage
    print_info "Vérification des points de montage..."

    if ! mountpoint -q /mnt; then
        print_error "Échec montage /mnt"
        return 1
    fi

    if [[ "$BOOT_MODE" == "uefi" ]]; then
        if ! mountpoint -q /mnt/boot/efi; then
            print_error "Échec montage /mnt/boot/efi"
            return 1
        fi
    else
        if ! mountpoint -q /mnt/boot; then
            print_error "Échec montage /mnt/boot"
            return 1
        fi
    fi

    print_success "Partitions montées avec succès"
    echo "Points de montage:"
    mount | grep -E "/mnt|$(basename "$DISK")"
    return 0
}

detect_partitions() {
    print_info "Détection des partitions..."

    # Liste toutes les partitions du disque
    local partitions=()
    for p in "${DISK}"*; do
        if [[ "$p" != "$DISK" ]] && [[ -b "$p" ]]; then
            partitions+=("$p")
        fi
    done

    if [[ ${#partitions[@]} -eq 0 ]]; then
        print_error "Aucune partition détectée sur $DISK"
        return 1
    fi

    print_info "Partitions détectées:"
    for p in "${partitions[@]}"; do
        local size=$(lsblk -no SIZE "$p" 2>/dev/null || echo "inconnu")
        local fstype=$(lsblk -no FSTYPE "$p" 2>/dev/null || blkid -s TYPE -o value "$p" 2>/dev/null || echo "inconnu")
        local label=$(lsblk -no LABEL "$p" 2>/dev/null || echo "")
        echo "  - $p ($size, $fstype${label:+, label: $label})"
    done

    return 0
}

# Fonctions d'installation du système de base
install_system() {
    print_header "ETAPE 8/$TOTAL_STEPS: INSTALLATION DU SYSTEME DE BASE"
    CURRENT_STEP=8

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

    # Paquets de base adaptés selon le mode de boot
    local base_packages=(
        base base-devel linux linux-firmware
        networkmanager sudo grub os-prober
        vim nano curl wget git unzip p7zip
        bash-completion man-db lsb-release
        reflector pacman-contrib
        dosfstools e2fsprogs
    )

    # Ajout spécifique selon le mode
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        base_packages+=("efibootmgr")
        print_info "Ajout d'efibootmgr pour UEFI"
    else
        print_info "Configuration BIOS - pas d'efibootmgr nécessaire"
    fi

    print_info "Installation des paquets de base pour le mode ${BOOT_MODE}..."
    run_with_progress "Installation système de base" 300 "pacstrap /mnt ${base_packages[*]}"

    print_success "Système de base installé pour le mode ${BOOT_MODE}"
}

configure_system() {
    print_header "ETAPE 9/$TOTAL_STEPS: CONFIGURATION SYSTEME"
    CURRENT_STEP=9

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
        read -r -p "Nom d'hote : " HOSTNAME
        if validate_input "$HOSTNAME" "hostname"; then
            break
        fi
        print_warning "Nom d'hote invalide (lettres, chiffres et tirets uniquement)"
    done

    # Ce qui est bizarre c'est que g tj le clavier américain alors que je le configure en français elle est où la douille ?
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
    print_header "ETAPE 10/$TOTAL_STEPS: CREATION UTILISATEURS"
    CURRENT_STEP=10

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la création d'utilisateurs"
        return 0
    fi

    # Création de l'utilisateur principal
    while true; do
        read -r -p "Nom d'utilisateur principal : " USERNAME
        export USERNAME
        if validate_input "$USERNAME" "username"; then
            break
        fi
        print_warning "Nom d'utilisateur invalide (min 3 caractères, lettres minuscules, chiffres, tirets et underscores uniquement, doit commencer par une lettre)"
    done

    # Création du mot de passe pour l'utilisateur principal
    local password password2
    while true; do
        read -r -s -p "Mot de passe pour $USERNAME (min 6 caractères) : " password
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

    # Configuration de sudo pour permettre au groupe wheel d'exécuter des commandes sans mot de passe
    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Configuration sudo pour le groupe wheel - NOPASSWD
if ! grep -q "^%wheel ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    # Désactiver temporairement la demande de mot de passe pour wheel
    sed -i '/^%wheel ALL=(ALL:ALL) ALL/s/^/# /' /etc/sudoers
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
EOF

    # Création de l'utilisateur principal avec son mot de passe
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Création de l'utilisateur principal
useradd -m -G wheel,audio,video,storage,optical,network "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Création des répertoires personnels
mkdir -p "/home/$USERNAME"/{Documents,Téléchargements,Images,Vidéos,Musique,Bureau,.ssh}
chown -R "$USERNAME":"$USERNAME" "/home/$USERNAME"
chmod 700 "/home/$USERNAME/.ssh"
EOF

    print_success "Utilisateur créé : $USERNAME (avec droits sudo sans mot de passe)"

    # Création d'utilisateurs supplémentaires avec leurs propres mots de passe
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
                    if validate_input "$add_password" "password" 6; then
                        read -r -s -p "Confirmez le mot de passe : " add_password2
                        echo ""
                        if [[ "$add_password" == "$add_password2" ]]; then
                            break
                        fi
                        print_warning "Mots de passe différents"
                    else
                        print_warning "Mot de passe trop court (minimum 6 caractères)"
                    fi
                done

                /usr/bin/arch-chroot /mnt /bin/bash <<EOF
set -e
# Création de l'utilisateur supplémentaire
useradd -m -G wheel,audio,video,storage,optical,network "$additional_user"
echo "$additional_user:$add_password" | chpasswd

# Création des répertoires personnels
mkdir -p "/home/$additional_user"/{Documents,Téléchargements,Images,Vidéos,Musique,Bureau,.ssh}
chown -R "$additional_user":"$additional_user" "/home/$additional_user"
chmod 700 "/home/$additional_user/.ssh"
EOF

                print_success "Utilisateur supplémentaire créé : $additional_user (avec droits sudo sans mot de passe)"
            else
                print_warning "Nom d'utilisateur invalide, ignoré"
            fi
        done
    fi

    # Configuration du mot de passe root (optionnel et différent)
    if confirm_action "Définir un mot de passe pour root ? (recommandé: NON)"; then
        local root_password root_password2
        while true; do
            read -r -s -p "Mot de passe root (laisser vide pour désactiver le compte root): " root_password
            echo ""
            if [[ -z "$root_password" ]]; then
                print_info "Compte root désactivé (pas de mot de passe défini)"
                /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
# Désactiver le compte root
passwd -l root
EOF
                break
            elif validate_input "$root_password" "password" 6; then
                read -r -s -p "Confirmez le mot de passe root: " root_password2
                echo ""
                if [[ "$root_password" == "$root_password2" ]]; then
                    /usr/bin/arch-chroot /mnt /bin/bash <<EOF
echo "root:$root_password" | chpasswd
EOF
                    print_success "Mot de passe root défini (différent des utilisateurs)"
                    break
                else
                    print_warning "Mots de passe différents"
                fi
            else
                print_warning "Mot de passe trop court (minimum 6 caractères)"
            fi
        done
    else
        # Désactiver le compte root par défaut
        /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
passwd -l root
EOF
        print_info "Compte root désactivé (recommandé pour la sécurité)"
    fi

    # Message final de configuration
    echo ""
    print_success "Configuration des utilisateurs terminée"
    echo -e "${GREEN}Tous les utilisateurs peuvent utiliser sudo sans mot de passe${NC}"
    echo -e "${YELLOW}Le compte root a été désactivé pour plus de sécurité${NC}"
    echo -e "${CYAN}Utilisez 'sudo' pour les commandes nécessitant des privilèges élevés${NC}"
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
        read -r -p "Votre choix (1-3): " choice
        case $choice in
            1) DE_CHOICE="kde"; break ;;
            2) DE_CHOICE="gnome"; break ;;
            3) DE_CHOICE="none"; break ;;
            *) print_warning "Choix invalide! Utilisez 1, 2 ou 3." ;;
        esac
    done

    print_success "Environnement sélectionné : $DE_CHOICE"
}

install_desktop() {
    print_header "ETAPE 12/$TOTAL_STEPS: INSTALLATION DE L'ENVIRONNEMENT DE BUREAU"
    CURRENT_STEP=12

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

# Fonctions audia et multimedia
install_audio_system() {
    print_header "ETAPE 16/$TOTAL_STEPS: INSTALLATION SYSTEME AUDIO PIPEWIRE"
    CURRENT_STEP=16

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du système audio"
        return 0
    fi

    print_info "Installation de PipeWire et outils audio..." # PipeWire ne s'installe pas enfin je crois

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

install_boot_sound() { # Bip sonore de boot disfonctionnel, à y remédier ou non
    print_header "ETAPE 17/$TOTAL_STEPS: CONFIGURATION BIP SONORE BOOT"
    CURRENT_STEP=17

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de l'installation du bip sonore"
        return 0
    fi

    # Création du répertoire des sons
    mkdir -p /mnt/usr/share/sounds/fallout

    # Téléchargement du son Fallout (correction de l'URL)
    print_info "Téléchargement du son de boot Fallout..."
    if curl -fL -o /mnt/usr/share/sounds/fallout/boot.wav \
        'https://raw.githubusercontent.com/PapaOursPolaire/arch/refs/heads/Projets/boot.wav' 2>/dev/null; then

        print_success "Son de boot téléchargé avec succès"

        # Installation des dépendances audio
        /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed alsa-utils pulseaudio-alsa || {
            print_warning "Impossible d'installer les dépendances audio complètes"
        }

        # Service systemd corrigé
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
        print_warning "Impossible de télécharger le son, création d'un bip système"

        # Fallback vers bip système intégré
        cat > /mnt/usr/local/bin/fallout-beep <<'EOF'
#!/bin/bash
# Bip système Fallout style
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

    # Activation du service
    /usr/bin/arch-chroot /mnt systemctl enable boot-sound.service || {
        print_warning "Impossible d'activer le service de son de boot"
    }

    print_success "Bip sonore de boot configuré"
}

configure_plymouth() {
    print_header "ETAPE 18/$TOTAL_STEPS: CONFIGURATION PLYMOUTH"
    CURRENT_STEP=18

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration de Plymouth"
        return 0
    fi

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installation de Plymouth..."
pacman -Sy --noconfirm --needed plymouth unzip curl

cd /tmp
rm -f arch-mac-style.zip
rm -rf /usr/share/plymouth/themes/arch-mac-style

echo "[INFO] Téléchargement du thème Plymouth..."
curl -fL -o arch-mac-style.zip "https://raw.githubusercontent.com/PapaOursPolaire/arch/Projets/arch-mac-style.zip"

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
    print_header "ETAPE 19/$TOTAL_STEPS: CONFIGURATION DU  SDDM (DISPLAY MANAGER)"
    CURRENT_STEP=19

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
    print_info "Téléchargement du dépot GitHub (branche Projets)..."
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
    print_header "ETAPE 15/$TOTAL_STEPS: CONFIGURATION KDE SPLASH"
    CURRENT_STEP=15

    if [[ "$DE_CHOICE" != "kde" ]]; then
        print_info "Environnement KDE non détecté - lockscreen ignoré"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation configuration lockscreen KDE"
        return 0
    fi

    print_info "Configuration du splash screen KDE Fallout..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

echo "[INFO] Installation composants KDE Splash..."
pacman -S --noconfirm --needed ksplash

# Créer le répertoire du thème
THEME_DIR="/usr/share/plasma/look-and-feel/org.kde.fallout.desktop"
mkdir -p "$THEME_DIR/contents/componentsets"
mkdir -p "$THEME_DIR/contents/plasmacolorschemes"

# Fichier metadata.desktop principal
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

# Configuration du splash screen
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
        console.log("Splash screen Fallout chargé")
    }
}
SPLASH_EOF

# Créer une image de fond simple (pixel vert Fallout)
cat > "$THEME_DIR/contents/splash/fallout-bg.png" << 'PNG_EOF'
# Création simplifiée - utiliser une couleur unie
PNG_EOF

# Configuration du schéma de couleur Fallout
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

# Configuration lookandfeel
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

echo "[SUCCESS] Thème KDE Splash créé"
EOF

    # Configuration pour forcer l'utilisation du thème
    /usr/bin/arch-chroot /mnt /bin/bash <<EOF || print_warning "Configuration partielle KDE"
# Configuration SDDM pour le splash
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/kde-splash.conf <<'SDDM_EOF'
[General]
Session=plasmaX11
Locale=fr_FR
Session=KDE
SDDM_EOF

# Configuration Plasma pour tous les utilisateurs
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/plasmarc <<'PLASMA_EOF'
[Theme]
name=breeze-dark

[Splash]
Engine=KSplash
Theme=org.kde.fallout
PLASMA_EOF

# Copier pour utilisateur existant si présent
if [[ -n "$USERNAME" && -d "/mnt/home/$USERNAME" ]]; then
    mkdir -p "/mnt/home/$USERNAME/.config"
    cp /etc/skel/.config/plasmarc "/mnt/home/$USERNAME/.config/" 2>/dev/null || true
    /usr/bin/arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/.config/plasmarc" 2>/dev/null || true
fi

# Force le thème à charger via lookandfeel
lookandfeeltool -a org.kde.fallout.desktop 2>/dev/null || true
EOF

    print_success "KDE Splash Fallout configuré"
}

# Fonctions d'installation des applications, n'a jamais marché - PENSER A LE SUPPRIMER DANS LA VERSION DEF
install_paru() {
    print_header "ETAPE 24/$TOTAL_STEPS: INSTALLATION PARU (AUR HELPER)"
    CURRENT_STEP=24

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
    echo "PARU TROUVE : $(which paru)"
    paru --version
else
    echo "Paru non trouvé, recherche aléatoire..."
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
echo "TEST FINAL"
export PATH="/usr/local/bin:/usr/bin:/bin"
command -v paru && paru --version

# Nettoyage (mais garde paru!)
echo "Nettoyage..."
rm -f /etc/sudoers.d/99-aur
userdel -r builduser 2>/dev/null || true
# NE PAS supprimer /tmp/paru-bin tant que paru n'est pas confirmé

echo "FIN DE L'INSTALLATION PARU"

CHROOT_EOF

    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        print_error "Erreur durant l'installation (code: $exit_code)"
        return 1
    fi

    # Vérification finale avec le bon PATH
    print_info "Vérification finale avec PATH étendu..."

    if /usr/bin/arch-chroot /mnt /bin/bash -c 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"; command -v paru >/dev/null 2>&1'; then
        print_success "Paru installé et disponible"
        # Nettoie maintenant que c'est confirmé
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

    # Installe base-devel et git en root
    /usr/bin/arch-chroot /mnt pacman -Sy --noconfirm --needed base-devel git || {
        print_error "Impossible d’installer base-devel et git"
        return 1
    }

    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ca-certificates ca-certificates-utils
    /usr/bin/arch-chroot /mnt update-ca-trust

    # Compile yay en tant qu'utilisateur normal
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

refresh_mirrors() { # A utiliser si erreurs de téléchargement dans les futures variables  # Désacitvé car disfonctionelle
    print_info "Rafraichissement des miroirs rapides..."
    if command -v reflector &> /dev/null; then
        reflector \
            --country France,Germany,Netherlands,Belgium,Switzerland \
            --age 6 \
            --protocol https \
            --fastest 20 \
            --sort rate \
            --threads 10 \
            --save /etc/pacman.d/mirrorlist || {
            print_warning "Impossible de rafraichir les miroirs, utilisation de la liste actuelle"
        }
    else
        print_warning "Reflector introuvable, tentative d'installation..."
        pacman -S --noconfirm reflector && \
        reflector --fastest 10 --save /etc/pacman.d/mirrorlist || true
    fi
    pacman -Syy --noconfirm
}

install_development() { # VS Code ne s'installe tj pas, à y remédier ou non
    print_header "ETAPE 25/$TOTAL_STEPS: INSTALLATION ENVIRONNEMENT DE DEVELOPPEMENT"
    CURRENT_STEP=25

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

    # Liste des paquets de développement - A ajouter plus si j'en ai oublié
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

# Fonction pour indiquer à l'utilisateur ce qui se passera - Ne marche pas dans le chroot, dispo dans le post-install
vscode_post_install_info() {
    print_info ""
    print_info "  INFORMATION VS CODE :"
    print_info "   Les extensions VS Code s'installeront automatiquement"
    print_info "   au premier démarrage de votre session graphique."
    print_info "   Vous pouvez aussi les installer manuellement avec:"
    print_info "   • ~/install-vscode-extensions.sh"
    print_info "   • ~/manual-vscode-setup.sh (version simplifiée)"
    print_info ""
}

install_spotify() {  # N'installe que le launcher, pas le client natif (spotify-client) donc est dupliqué
    # avec le spotify-client du post-install -> A y remédier ou non
    print_header "ETAPE 22/$TOTAL_STEPS: INSTALLATION DE SPOTIFY"
    CURRENT_STEP=22

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
            print_warning "Échec installation Spicetify CLI"
    fi

    # Configuration minimale Spicetify
    if [[ -n "${USERNAME:-}" ]]; then
        print_info "Préparation configuration Spicetify pour $USERNAME"
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify config current_theme DribbblishNordDark || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify backup || true
        /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" spicetify apply || true
    else
        print_warning "USERNAME non défini — Spicetify sera configuré après premier boot." # Obsolète depuis la version 361.2; nouvelle méthode marchant un peu mieux (le laucnher s'installe)
    fi

    print_success "Installation Spotify + Spicetify terminée (avec fallbacks)."
}

# Nettoyage sûr de /tmp avant installation des polices (pour éviter "No space left on device")
clean_tmp() { # Plus efficace depuis la version 238.0, à enelver dans la version définitive
    print_header "NETTOYAGE /tmp"
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

install_wine() {
    print_header "ETAPE 23/$TOTAL_STEPS: INSTALLATION DE WINE"
    CURRENT_STEP=23

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

install_software() {
    print_header "ETAPE 20/$TOTAL_STEPS: INSTALLATION DES LOGICIELS ESSENTIELS"
    CURRENT_STEP=20

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
        firefox # installé
        thunderbird # à vérifier
        telegram-desktop  #  à vérifier
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
        vlc # OK
        mpv  # OK
        obs-studio # OK
        audacity # OK
        gimp # OK
        inkscape # OK
        imagemagick # A vérifier*
        kdenlive # A vérifier*
        blender # OK
        krita # A vérifier*
    )
    # * : Ne s'installaient pas avant la version 411, à revérifier
    run_with_progress "Installation Multimédia" 180 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${multimedia_packages[*]}"

        # Catégorie 3 : Gaming (si interface graphique installée)
        if [[ "$DE_CHOICE" != "none" ]]; then
            print_header "INSTALLATION LOGICIELS GAMING"
            print_info "Installation de la suite Gaming complète..."

            # Assurer multilib dans le chroot avant d'installer Steam
            /usr/bin/arch-chroot /mnt pacman -Syyu --noconfirm

            # Activer le dépot multilib si pas déjà activé (à nouveau)
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
                    print_success "Paru installé avec succès via dépots"
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
                lutris # OK

                # Émulation multi-systèmes -> Aucun installé  avant version 411, à revérifier
                retroarch
                retroarch-assets-xmb
                retroarch-assets-ozone
                libretro-gambatte
                libretro-snes9x
                libretro-mupen64plus-next

                # Émulateurs standalone
                fceux # JSP
                snes9x-gtk # JSP
                mupen64plus # JSP
                dolphin-emu # OK
                ppsspp # OK
                desmume # JSP

                # Optimisations gaming
                gamemode # JSP
                lib32-gamemode # JSP
                mangohud # JSP
                lib32-mangohud # JSP

                # Proton & compatibilité
                lib32-gcc-libs # JSP
                lib32-glibc # JSP

                # Outils et streaming
                discord # OK
                obs-studio # OK

                # Émulation
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
            print_success "Tous les paquets gaming installés"
        else
            print_warning "$install_errors paquet(s) gaming n’ont pas pu être installés"
        fi


            # Vérification de Paru dans le chroot - Ner marche tj pas
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

            # Installation paquets AUR spécifiques via paru - Ne marche pas dcp
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

            # Configuration de Gamemode - Pas vérifié
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
        #neofetch  -> a été retiré des depots récemment et je pense que fastfetch et mieux de tt façon
        lsb-release # OK
        wget # OK
        curl # OK
        rsync # OK
        ark # JSP
        filelight # JSP
    )

    clean_tmp

    run_with_progress "Installation Utilitaires" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed ${utility_packages[*]}"

    # Catégorie 5: Polices et thèmes - A vérifier car je ne pense pas que toutes les polices aient été installées
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
    # doit renvoyer : 1 - sinon foutu

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
echo "VERIFICATION DES LOGICIELS INSTALLES"

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

echo "RÉSUMÉ: $installed_count/$total_count logiciels installés"

# Liste des paquets installés
echo "Nombre total de paquets installés: $(pacman -Q | wc -l)"
EOF

    print_success "TOUS LES LOGICIELS ESSENTIELS ONT ÉTÉ INSTALLÉS "
}

install_themes() {
    print_header "ETAPE 27/$TOTAL_STEPS: INSTALLATION THEMES ET ICONES"
    CURRENT_STEP=27

    if [[ "$DRY_RUN" == true ]] || [[ "$DE_CHOICE" == "none" ]]; then
        print_info "Thèmes et icones ignorés (mode console ou dry-run)"
        return 0
    fi

    print_info "Installation des thèmes et icones..."

    # Icones et thèmes via pacman - CORRECTION: noms de paquets corrects - pas sur car pas beaucoup sont installés, à reverifier
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
    run_with_progress "Installation thèmes et icones" 120 "/usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed papirus-icon-theme breeze-icons breeze-gtk"

    # Thèmes additionnels via AUR - A part Tela, les autres n'ont pas été installés A REVERIFIER
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

    # Configuration du thème par défaut - CORRECTION: Thèmes existants (correction inneficace)
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

    print_success "Thèmes et icones installés et configurés"
}

install_vscode() { # Ne fonctionne pas
    print_header "ETAPE 30/$TOTAL_STEPS: INSTALLATION VISUAL STUDIO CODE"
    CURRENT_STEP=30

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation installation VSCode"
        return 0
    fi

    print_info "Installation de Visual Studio Code..."

    # Tentative 1 : via pacman directement
    if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed code 2>/dev/null; then
        print_success "Visual Studio Code installé via pacman"

        # Créer raccourci bureau
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

    print_warning "VSCode non disponible via pacman, tentative AUR..."

    # Tentative 2 : via AUR avec paru
    if /usr/bin/arch-chroot /mnt command -v paru &>/dev/null; then
        if /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" paru -S --noconfirm visual-studio-code-bin 2>/dev/null; then
            print_success "Visual Studio Code installé via AUR (paru)"
            return 0
        fi
    fi

    # Tentative 3 : via Flatpak
    if /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        /usr/bin/arch-chroot /mnt flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

        if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.visualstudio.code 2>/dev/null; then
            print_success "Visual Studio Code installé via Flatpak"
            return 0
        fi
    fi

    # Tentative 4 : VSCodium (alternative open-source)
    print_warning "VSCode officiel indisponible, tentative VSCodium..."
    if /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed vscodium 2>/dev/null; then
        print_success "VSCodium (alternative open-source) installé"
        return 0
    fi

    # Tentative 5 : VSCodium via Flatpak
    if /usr/bin/arch-chroot /mnt command -v flatpak &>/dev/null; then
        if /usr/bin/arch-chroot /mnt flatpak install -y flathub com.vscodium.codium 2>/dev/null; then
            print_success "VSCodium installé via Flatpak"
            return 0
        fi
    fi

    print_error "Impossible d'installer Visual Studio Code ou VSCodium"
    print_info "Installation manuelle possible après reboot via:"
    echo "  • pacman -S code"
    echo "  • paru -S visual-studio-code-bin"
    echo "  • flatpak install flathub com.visualstudio.code"

    return 1
}

generate_postinstall() {
    print_header "ETAPE 31/$TOTAL_STEPS: GENERATION SCRIPT POST-INSTALLATION"
    CURRENT_STEP=31

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

set -o pipefail

LOGFILE="$HOME/post-install-errors.log"
: > "$LOGFILE"   # tronquer le log précédent (erreurs uniquement)

# Rediriger uniquement stderr vers LOGFILE, garder stdout visible
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
    echo ""
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

# Ensure HOME variable exists
if [[ -z "${HOME:-}" ]]; then
    export HOME="/home/$(whoami)"
fi

# Ensure sudo is present or we are root for operations needing root
if ! command -v sudo >/dev/null 2>&1 && (( EUID != 0 )); then
    red "[WARN] sudo non trouvé et vous n'êtes pas root — certaines opérations nécessiteront root"
fi

# SECTION A: Debug Steam / fixes Steam common issues
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

# SECTION B: Android Studio installation (flatpak preferred)
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

# SECTION C: Spotify & Spicetify
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

    # Spicetify - installation via pacman si absent
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
        echo "[INFO] spicetify non présent; ignoré" >&3
    fi
    fi
}

# SECTION D: Visual Studio Code + extensions (user session)
install_vscode_extensions_user() {
    echo
    yellow "[TASK] Installer Visual Studio Code (si binaire 'code' présent) et extensions utiles"

    if ! command -v code >/dev/null 2>&1 ; then
    yellow "Binaire 'code' non trouvé : installation via pacman"
    /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed code || {
        echo "[ERREUR] Impossible d’installer Visual Studio Code avec pacman" >&2
    }
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

# SECTION E: Navigateurs (Brave, Chrome, DuckDuckGo Browser)
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

# SECTION F: Fixes et utilitaires (pulseaudio/pipewire, codecs, fonts)
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

# SECTION H: Main
main() {
    yellow "Début des tâches post-install"

    # 0) mise à jour index
    update_db

    # 1) Steam debug
    steam_debug

    # 2) Android Studio
    install_android_studio

    # 3) Spotify & Spicetify -> J'ai abusé sur le nom à rallonge je pense
    install_spotify_and_spicetify

    # 4) Visual Studio Code extensions -> J'ai abusé sur le nom à rallonge je pense
    install_vscode_extensions_user

    # 5) Navigateurs
    install_browsers

    # 6) Multimedia & Fonts -> J'ai abusé sur le nom à rallonge je pense
    install_multimedia_and_fonts

    # 7) Misc user tweaks
    user_misc_tweaks

    # 8) Deploy helper -> J'ai abusé sur le nom à rallonge je pense
    deploy_post_install_helper

    yellow "Tâches post-install terminées"
    echo
    green "Résumé: si des erreurs ont eu lieu, elles sont consignées dans : $LOGFILE"
    echo "Consultez-les avec : tail -n 200 $LOGFILE"
}

main "$@"

# Restore stderr
exec 2>&3

echo "[INFO] post-install fini à $(date '+%Y-%m-%d %H:%M:%S')"
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

install_fastfetch() {
    print_header "ETAPE 28/$TOTAL_STEPS: INSTALLATION ET CONFIGURATION FASTFETCH"
    CURRENT_STEP=28

    if [[ -z "${USERNAME:-}" ]]; then
        print_error "USERNAME non défini. Abandon."
        return 1
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY RUN] install_fastfetch pour ${USERNAME}"
        return 0
    fi

    print_info "Installation de fastfetch..."

    # Installation du paquet
    if ! /usr/bin/arch-chroot /mnt pacman -S --noconfirm --needed fastfetch; then
        print_warning "Ã‰chec pacman, tentative Flatpak..."
        if ! /usr/bin/arch-chroot /mnt flatpak install -y flathub io.github.fastfetch_cli 2>/dev/null; then
            print_error "Impossible d'installer fastfetch"
            return 1
        fi
    fi

    local USER_HOME="/home/${USERNAME}"
    local CONFIG_DIR="${USER_HOME}/.config/fastfetch"

    print_info "Création de la configuration fastfetch..."

    # Créer répertoire config
    /usr/bin/arch-chroot /mnt mkdir -p "$CONFIG_DIR"

    # Configuration fastfetch
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

    # Configuration bashrc pour l'autostart GARANTIE
    print_info "Configuration autostart dans bashrc..."

    /usr/bin/arch-chroot /mnt /bin/bash <<'BASHRC_CONFIG'
USERNAME='$USERNAME'
BASHRC="/home/${USERNAME}/.bashrc"
MARKER="### FASTFETCH AUTOSTART - Installation Arch"

# Si le marker n'existe pas, ajouter la config
if ! grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" <<'FASTFETCH_EOF'
### FASTFETCH AUTOSTART - Installation Arch
if [[ $- == *i* ]]; then
    # Exécuter uniquement une fois par session shell
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

    # Configuration zshrc si installé
    /usr/bin/arch-chroot /mnt /bin/bash <<'ZSHRC_CONFIG'
if /usr/bin/arch-chroot /mnt command -v zsh >/dev/null 2>&1; then
    ZSHRC="/home/${USERNAME}/.zshrc"
    if [[ ! -f "$ZSHRC" ]]; then
        touch "$ZSHRC"
    fi

    if ! grep -q "FASTFETCH AUTOSTART" "$ZSHRC" 2>/dev/null; then
        cat >> "$ZSHRC" <<'ZSHFETCH_EOF'
### FASTFETCH AUTOSTART - Installation Arch
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

    # Créer un alias pratique
    /usr/bin/arch-chroot /mnt /bin/bash <<'ALIAS_CONFIG'
USERNAME='$USERNAME'
BASHALIASES="/home/${USERNAME}/.bash_aliases"

if ! grep -q "alias ff=" "$BASHALIASES" 2>/dev/null; then
    echo "alias ff='fastfetch --config ~/.config/fastfetch/config.json'" >> "$BASHALIASES"
fi
ALIAS_CONFIG

    # Fixer les permissions
    /usr/bin/arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.config/fastfetch" 2>/dev/null || true
    /usr/bin/arch-chroot /mnt chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.bashrc" "/home/${USERNAME}/.bash_aliases" 2>/dev/null || true

    # Test
    if /usr/bin/arch-chroot /mnt sudo -u "$USERNAME" bash -c "command -v fastfetch >/dev/null 2>&1 && fastfetch --help >/dev/null 2>&1"; then
        print_success "Fastfetch installé et configuré avec autostart"
        print_info "Fastfetch s'exécutera automatiquement à chaque lancement du terminal"
        print_info "Raccourci disponible: ff"
    else
        print_warning "Fastfetch installé mais la configuration peut nécessiter une vérification"
    fi

    return 0
}

# Fonctions pour la configuration finale du système
final_config() {
    print_header "ETAPE 29/$TOTAL_STEPS: CONFIGURATION FINALE"
    CURRENT_STEP=29

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[DRY RUN] Simulation de la configuration finale"
        return 0
    fi

    print_info "Configuration finale..."

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
cat > /home/$USERNAME/.bashrc <<'BASHRC_EOF'
#!/bin/bash

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
    echo "INFORMATIONS SYSTÈME :"
    echo "OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel: \$(uname -r)"
    echo "Uptime: \$(uptime -p)"
    echo "CPU: \$(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "RAM: \$(free -h | awk '/^Mem:/ {print \$3 "/" \$2}')"
    echo "Disque: \$(df -h / | awk 'NR==2{print \$3 "/" \$2 " (" \$5 " utilisé)"}')"
    echo "Paquets: \$(pacman -Q | wc -l) installés"
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

# Permissions complètes
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
echo "1.  THÈMES ET ICONES:"
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
    echo "Système prêt pour utilisation"
else
    echo "Certaines corrections peuvent nécessiter une intervention manuelle car flemme de créer un script de correction ou de  débugguer ce script, vous pensez que je n'ai pas d'autres scripts sur le plancher ?"
fi
EOF

    print_success "Configuration finale terminée avec TOUTES LES CORRECTIONS"
}

finish_install() {
    print_header "ETAPE 32/$TOTAL_STEPS: FINALISATION DE L'INSTALLATION"
    CURRENT_STEP=32

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
    [[ "$CUSTOM_PARTITIONING" == true ]] && echo -e "${CYAN}• Partitionnement :${NC} Personnalisé"
    echo ""

    echo -e "${YELLOW}INFORMATIONS SPECIFIQUES AU MODE ${BOOT_MODE^^}:${NC}"
    if [[ "$BOOT_MODE" == "uefi" ]]; then
        echo -e "• Bootloader: GRUB x86_64-efi"
        echo -e "• Table de partitions: GPT"
        echo -e "• Partition EFI: FAT32"
    else
        echo -e "• Bootloader: GRUB i386-pc"
        echo -e "• Table de partitions: MBR"
        echo -e "• Partition Boot: ext4"
    fi
    echo ""

    # Le reste de la fonction reste identique...
    # [contenu identique de l'affichage des fonctionnalités]

    # Instructions post-installation adaptées
    echo -e "${BLUE} INSTRUCTIONS POST-INSTALLATION :${NC}"
    echo -e "1. ${WHITE}Retirez le support d'installation${NC}"
    echo -e "2. ${WHITE}Redémarrez le système${NC}"
    echo -e "3. ${WHITE}Connectez-vous avec :${NC} ${CYAN}$USERNAME${NC}"
    if [[ "$BOOT_MODE" == "bios" ]]; then
        echo -e "4. ${WHITE}Vérifiez que le BIOS boot bien sur le disque dur${NC}"
    fi
    echo -e "5. ${WHITE}Première mise à jour :${NC} ${CYAN}sudo pacman -Syu${NC}"
    echo ""

    # Sauvegarde du log
    if [[ -f "$LOG_FILE" ]]; then
        cp "$LOG_FILE" "/mnt/home/$USERNAME/installation.log" 2>/dev/null || true
        print_info "Log d'installation sauvegardé: /home/$USERNAME/installation.log"
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
        print_success " Redémarrage en cours... Bienvenue dans Arch Linux (${BOOT_MODE})!"

        reboot
    else
        print_info "Installation terminée. Redémarrez manuellement quand vous le souhaitez."
        echo -e "${YELLOW} N'oubliez pas de retirer la clé USB bootable !${NC}"

        # Démontage manuel
        sync
        [[ -n "$SWAP_PART" ]] && swapoff "$SWAP_PART" 2>/dev/null || true
        umount -R /mnt 2>/dev/null || true

        echo ""
        echo -e "${GREEN} Installation complète V864.4-BIOS ! Votre système Arch Linux est prêt.${NC}"
        echo ""
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
fi
