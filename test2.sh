#!/bin/bash

# Arch Hyprland Ultimate Installer - Configuration automatisée
# -----------------------------------------------------------

### VARIABLES PERSONNALISABLES - MODIFIEZ CES VALEURS ###
USERNAME="votre_user"
HOSTNAME="arch-hypr"
ROOT_PASSWORD="votre_mdp_root"
USER_PASSWORD="votre_mdp_user"
TIMEZONE="Europe/Paris"
LANG="fr_FR.UTF-8"
KEYMAP="fr-latin1"
DISK="/dev/sda"  # Modifier selon votre configuration
EFI_PART="${DISK}1" # Partition EFI
ROOT_PART="${DISK}2" # Partition root
# -----------------------------------------------------

### !!! AVERTISSEMENT !!! 
### Ce script va formater les partitions spécifiées ci-dessus
### Vérifiez deux fois les noms de partitions avant d'exécuter !

# Fonction de vérification
confirm_install() {
    echo "---------------------------------------------"
    echo "Configuration:"
    echo "Utilisateur: $USERNAME"
    echo "Hostname: $HOSTNAME"
    echo "Disque: $DISK"
    echo "EFI: $EFI_PART"
    echo "Root: $ROOT_PART"
    echo "---------------------------------------------"
    read -p "Continuer l'installation? (o/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Installation annulée!"
        exit 1
    fi
}

# Partitionnement automatique
auto_partition() {
    echo "Création des partitions..."
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart "EFI" fat32 1MiB 512MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart "ROOT" ext4 512MiB 100%
    
    echo "Formatage des partitions..."
    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -F "$ROOT_PART"
    
    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
}

# Installation de base
base_install() {
    echo "Installation du système de base..."
    pacstrap /mnt base base-devel linux linux-firmware \
        networkmanager grub efibootmgr os-prober ntfs-3g \
        git nano man-db man-pages zsh sudo
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Configuration système
system_config() {
    arch-chroot /mnt /bin/bash <<EOF
    # Configuration de base
    echo "$HOSTNAME" > /etc/hostname
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
    echo "LANG=$LANG" > /etc/locale.conf
    sed -i "s/#$LANG/$LANG/" /etc/locale.gen
    locale-gen
    
    # Mot de passe root
    echo "root:$ROOT_PASSWORD" | chpasswd
    
    # Utilisateur
    useradd -m -G wheel -s /bin/zsh "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
    echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers
    
    # Réseau
    systemctl enable NetworkManager
EOF
}

# Installation graphique
graphics_install() {
    arch-chroot /mnt /bin/bash <<EOF
    # Pilotes
    pacman -S --noconfirm mesa vulkan-intel nvidia nvidia-utils
    
    # Hyprland
    sudo -u $USERNAME bash -c 'git clone https://aur.archlinux.org/yay-bin.git /tmp/yay'
    cd /tmp/yay
    sudo -u $USERNAME makepkg -si --noconfirm
    sudo -u $USERNAME yay -S --noconfirm hyprland-git \
        waybar-hyprland-git rofi-lbonn-wayland-git \
        kitty swaybg swaylock-effects wl-clipboard \
        mako pavucontrol pulseaudio-alsa bluez bluez-utils
    
    # Thèmes
    sudo -u $USERNAME bash -c 'git clone https://github.com/Arcane-Theme/arcanetheme /home/$USERNAME/.themes/Arcane'
    sudo -u $USERNAME bash -c 'git clone https://github.com/Fallout-Theme/fallouttheme /home/$USERNAME/.themes/Fallout'
EOF
}

# Personnalisations
customizations() {
    arch-chroot /mnt /bin/bash <<EOF
    # FastFetch avec logo Arch
    pacman -S --noconfirm fastfetch
    sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/fastfetch
    echo '--logo arch' > /home/$USERNAME/.config/fastfetch/config.conf
    
    # Fond vidéo animé
    sudo -u $USERNAME bash -c 'git clone https://github.com/Givemo/VideoWall /home/$USERNAME/.config/videowall'
    echo "exec_always videowall --loop ~/.config/videowall/arcane.mp4" >> /home/$USERNAME/.config/hypr/hyprland.conf
    
    # Barre des tâches transparente
    sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/waybar
    cat > /home/$USERNAME/.config/waybar/config <<'WAYBAR'
position: "bottom",
height: 36,
width: 1400,
margin: "0 auto",
modules-center: [...],
background-color: "rgba(0,0,0,0.5)",
WAYBAR
    
    # Verrouillage Fallout
    sudo -u $USERNAME bash -c 'git clone https://github.com/Fallout-Theme/fallout-lockscreen /home/$USERNAME/.config/lockscreen'
    echo "exec swaylock -C /home/$USERNAME/.config/lockscreen/config" >> /home/$USERNAME/.config/hypr/hyprland.conf
EOF
}

# Applications
install_apps() {
    arch-chroot /mnt /bin/bash <<EOF
    # Dev tools
    pacman -S --noconfirm code android-studio jdk-openjdk python nodejs npm docker
    
    # Browsers
    sudo -u $USERNAME yay -S --noconfirm google-chrome brave-bin
    
    # Médias
    sudo -u $USERNAME yay -S --noconfirm spotify-launcher spicetify-cli netflix-disney
    sudo -u $USERNAME bash -c 'spicetify apply'
    
    # Gaming/Réseau
    pacman -S --noconfirm wine-staging lutris steam wireshark nmap
    
    # Extensions VSCode
    sudo -u $USERNAME code --install-extension GitHub.copilot
    sudo -u $USERNAME code --install-extension ms-vscode.cpptools
    sudo -u $USERNAME code --install-extension redhat.java
    sudo -u $USERNAME code --install-extension ms-python.python
EOF
}

# GRUB et thèmes
grub_config() {
    arch-chroot /mnt /bin/bash <<EOF
    # Installation GRUB
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    pacman -S --noconfirm grub-theme-vimix
    
    # Thèmes supplémentaires
    git clone https://github.com/AdisonCavani/BSOL-Grub-Theme /boot/grub/themes/BSOL
    git clone https://github.com/MartinHeinz/Minegrub-Theme /boot/grub/themes/Minegrub
    git clone https://github.com/Patato777/dark_matter_grub /boot/grub/themes/DarkMatter
    
    # Configuration GRUB
    echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    
    # Bip sonore
    mkdir -p /boot/grub/sounds
    curl -L https://github.com/Fallout-Theme/grub-sound/raw/main/fallout.wav -o /boot/grub/sounds/fallout.wav
    echo "GRUB_INIT_TUNE='\\aplay /boot/grub/sounds/fallout.wav'" >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

# Installation finale
final_steps() {
    arch-chroot /mnt /bin/bash <<EOF
    # Services
    systemctl enable bluetooth
EOF
}

# Exécution de l'installation
confirm_install
auto_partition
base_install
system_config
graphics_install
customizations
install_apps
grub_config
final_steps

echo "---------------------------------------------"
echo "Installation terminée avec succès !"
echo "Redémarrez avec : umount -R /mnt && reboot"
echo "Utilisateur: $USERNAME"
echo "Hostname: $HOSTNAME"
echo "---------------------------------------------"