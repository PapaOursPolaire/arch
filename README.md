# Script d'installation Arch Linux Fallout Edition (v344.2)

Ce script automatise l'installation complète d'Arch Linux avec une
thématisation par défaut Fallout.
Version : **344.2, correctif 2**
Auteur : PapaOursPolaire

------------------------------------------------------------------------

## 🛠️ Étapes principales du script

### Phase 1 : Préparation système

1.  **check_requirements** :
    -   Vérifie : root, UEFI, connexion Internet, espace disque, RAM.
    -   Supprime `[community]` de pacman.conf (fusionné dans
        `[extra]`).
    -   Met à jour pacman.
2.  **test_environment** :
    -   Vérifie la présence des commandes (`pacman`, `arch-chroot`,
        `parted`, `git`, etc.).
    -   Vérifie connexion Internet, UEFI, RAM, espace disque.
    -   Test de vitesse réseau.
3.  **optimize_pacman_configuration** :
    -   Sauvegarde `pacman.conf` et applique une config optimisée.
    -   Active `ParallelDownloads=10`, `ILoveCandy`.
    -   Utilise `reflector` pour générer la meilleure liste de miroirs.

------------------------------------------------------------------------

### Phase 2 : Configuration disque

4.  **select_disk** : l'utilisateur choisit le disque.
5.  **choose_partitioning** :
    -   Partitionnement existant, automatique ou personnalisé.
    -   EFI 512M, Root 60G, Swap 8G, Home = reste.
6.  **format_partitions** : formatage EFI (FAT32), Root & Home (ext4),
    Swap (linux-swap).
7.  **mount_partitions** : montage EFI sur `/mnt/boot/efi`, Root sur
    `/mnt`, Home sur `/mnt/home`.

------------------------------------------------------------------------

### Phase 3 : Installation système

8.  **install_base_system** : installe via `pacstrap` :
    -   `base`, `base-devel`, `linux`, `linux-firmware`
    -   `networkmanager`, `sudo`, `grub`, `efibootmgr`, `os-prober`
    -   `vim`, `nano`, `curl`, `wget`, `git`, `unzip`, `p7zip`
    -   `bash-completion`, `man-db`, `lsb-release`, `reflector`,
        `pacman-contrib`, `dosfstools`, `e2fsprogs`
9.  **configure_system** :
    -   Configure locales (`fr_FR.UTF-8`), clavier (`fr`).
    -   Configure fuseau horaire Europe/Paris.
    -   Active NetworkManager.
    -   Ajoute `sudo` pour le groupe wheel.
10. **create_users** : crée un utilisateur + root avec mot de passe.

------------------------------------------------------------------------

### Phase 4 : Environnement graphique

11. **select_desktop_environment** : choix KDE Plasma, GNOME ou aucun.
12. **install_desktop_environment** : installe l'environnement choisi.

-   KDE : `plasma-meta`, `kde-applications`, `sddm`.
-   GNOME : `gnome`, `gnome-extra`, `gdm`.

------------------------------------------------------------------------

### Phase 5 : Bootloader & thèmes

13. **configure_grub** : installe GRUB UEFI avec thème Fallout.
14. **install_fallout_theme** : applique thème GRUB Fallout.

------------------------------------------------------------------------

### Phase 6 : Audio & multimédia

15. **install_audio_system** : installe PipeWire + WirePlumber +
    PavuControl.\
16. **install_boot_sound** : ajoute son Fallout au démarrage.
17. **configure_plymouth** : splashscreen animé Fallout (PipBoy).
18. **configure_sddm** : fond Fallout pour l'écran de login.

------------------------------------------------------------------------

### Phase 7 : Logiciels principaux

19. **install_software_packages** :

-   VLC, MPV, OBS Studio, Audacity.
-   GIMP, Inkscape.
-   KeePassXC, GParted, TimeShift.

20. **install_web_browsers** : Firefox, Chromium, Brave, Vivaldi, Opera,
    Tor Browser, GNOME Web, Midori, Chrome.

21. **install_spotify_spicetify** : installe Spotify (Flatpak) +
    Spicetify + thème Dribbblish Nord Dark.

22. **install_wine_compatibility** : Wine, Winetricks, Wine-mono,
    Wine-gecko pour compatibilité Windows.

------------------------------------------------------------------------

### Phase 8 : Développement

23. **install_paru** : installe l'AUR helper `paru`.
24. **install_development_environment** :

-   Visual Studio Code + extensions : Python, C++, Java, Tailwind CSS,
    Prettier, ESLint, Jupyter, GitHub Copilot, etc.
-   Langages : Python, Node.js, Go, Rust, C/C++, OpenJDK, Docker, cmake,
    gcc, clang.
-   Android Studio (Flatpak `com.google.AndroidStudio`).

25. **install_steam** : Steam (Flatpak, avec Proton).
26. **fix_spicetify_prefs** : corrige Spicetify si Spotify n'a pas
    encore généré ses fichiers.

------------------------------------------------------------------------

### Phase 9 : Thèmes & personnalisation

27. **install_themes_and_icons** : Papirus, Arc, Breeze, Tela.
28. **install_fastfetch** : logo ASCII Arch + infos système.

------------------------------------------------------------------------

### Phase 10 : Finalisation

29. **final_configuration** : nettoie, optimise les services.
30. **finish_installation** : affiche succès, propose reboot.

------------------------------------------------------------------------

## ⚙️ Particularités de la version 344.2

-   Correction des 2358 erreurs ShellCheck.
-   Partition `/home` séparée optionnelle.
-   Mot de passe minimum 6 caractères.
-   Téléchargements parallèles pacman.
-   Correction bug PipeWire-Jack.
-   Optimisations réseau (BBR, TCP).
-   Thème Fallout complet (GRUB, Plymouth, SDDM).

------------------------------------------------------------------------

## 📌 Remarques importantes

-   **Nécessite UEFI + Internet stable*.**
-   Installation peut prendre entre **30 à 60 minutes** selon la technologie du disque durr et de la bande passante disponible.
-   Android Studio peut échouer si
    `kernel.unprivileged_userns_clone=0`.
-   Log complet disponible dans `/tmp/arch_install_*.log`.

*Un internet stable signifie selon moi un débit stable d'environ 40 Mbps par seconde. En guise d'exemple, l'installation d'Arch avec 10 Mbps m'a pris environ une heure.

------------------------------------------------------------------------

## Sources :

### 🌱 Apprentissage Shell & GitHub
- ShellCheck Wiki : https://www.shellcheck.net/wiki/
- GNU Bash Manual : https://www.gnu.org/software/bash/manual/
- The Linux Documentation Project : https://tldp.org/
- Shell Scripting Tutorial : https://www.shellscript.sh/
- Codédex (intro GitHub, pas de ShellScript) : https://www.codedex.io/

### 🖥️ Guides distributions Linux
- Arch Linux Installation Guide : https://wiki.archlinux.org/title/Installation_guide
- BlackArch Linux : https://blackarch.org/
- Nyarch Linux : https://nyarchlinux.moe/
- Hyprland Wiki : https://wiki.hyprland.org/

### 🎨 Personnalisation & environnements graphiques
- KDE Plasma : https://kde.org/plasma-desktop
- GNOME Look : https://www.gnome-look.org/
- SDDM Themes : https://store.kde.org/browse?cat=108&ord=latest

### ⚡ Utilitaires
- Fastfetch : https://github.com/fastfetch-cli/fastfetch
- CAVA (visualiseur audio dans le terminal) : https://github.com/karlstav/cava
- Spicetify (personnalisation Spotify) : https://spicetify.app/
- GRUB (GNU GRUB bootloader) : https://www.gnu.org/software/grub/
- SDDM (Simple Desktop Display Manager) : https://github.com/sddm/sddm





