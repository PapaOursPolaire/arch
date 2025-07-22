#!/bin/bash

# Configuration de base
HOSTNAME="arch-gaming"
USERNAME="gamer"
TIMEZONE="Europe/Paris"
LANG="fr_FR.UTF-8"
KEYMAP="fr-latin1"

# Partitionnement (ADAPTER LES POINTS DE MONTAGE)
BOOT_PART="/dev/nvme0n1p1"  # À modifier
ROOT_PART="/dev/nvme0n1p2"  # À modifier
EFI_MOUNT="/boot"           # À modifier si différent

# -------------------------------------------------------------------
# PHASE 1: Configuration système de base
# -------------------------------------------------------------------

# Configuration locale et timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "s/#$LANG/$LANG/" /etc/locale.gen
locale-gen
echo "LANG=$LANG" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Configuration réseau
echo $HOSTNAME > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Installer les paquets essentiels
pacman -Syu --noconfirm --needed \
    base-devel linux linux-firmware \
    grub efibootmgr networkmanager \
    sudo zsh git openssh wget curl

# Configurer GRUB (UEFI)
grub-install --target=x86_64-efi --efi-directory=$EFI_MOUNT --bootloader-id=GRUB
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg

# Créer l'utilisateur
useradd -m -G wheel -s /bin/zsh $USERNAME
echo "$USERNAME ALL=(ALL) ALL" >> /etc/sudoers

# Mot de passe
echo "Entrez le mot de passe pour root:"
passwd root
echo "Entrez le mot de passe pour $USERNAME:"
passwd $USERNAME

# -------------------------------------------------------------------
# PHASE 2: Environnement graphique et applications
# -------------------------------------------------------------------

# Installer Hyprland et dépendances
sudo -u $USERNAME yay -S --noconfirm --needed \
    hyprland waybar rofi kitty swaybg swaylock-effects \
    pamixer brightnessctl playerctl mako \
    ttf-jetbrains-mono noto-fonts-emoji \
    papirus-icon-theme nordic-darker-theme \
    xdg-desktop-portal-hyprland

# Installer les applications
sudo -u $USERNAME yay -S --noconfirm --needed \
    brave-bin google-chrome spotify-launcher \
    vscodium-bin android-studio jetbrains-toolbox \
    wine-staging winetricks lutris \
    fastfetch cava neofetch \
    discord steam obs-studio \
    gparted nmap wireshark \
    jdk-openjdk python nodejs npm

# Installer Spicetify
curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
chmod a+wr /opt/spotify
chmod a+wr /opt/spotify/Apps -R

# Installer les extensions VSCodium
extensions=(
    "GitHub.copilot"
    "ms-vscode.cpptools"
    "vscjava.vscode-java-pack"
    "ms-python.python"
)
for ext in "${extensions[@]}"; do
    sudo -u $USERNAME codium --install-extension $ext
done

# -------------------------------------------------------------------
# PHASE 3: Personnalisations graphiques
# -------------------------------------------------------------------

# Configurations Hyprland
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/hypr
cat > /home/$USERNAME/.config/hypr/hyprland.conf << EOF
exec-once = waybar
exec-once = mako
exec-once = swaybg -i ~/wallpapers/arcane.jpg

# Transparence
windowrulev2 = opacity 0.92 0.92, class:^(kitty)$
windowrulev2 = opacity 0.88 0.88, class:^(Code)$
windowrulev2 = opacity 0.85 0.85, class:^(thunar)$

# Fallout animation lock (script personnalisé)
bind = $mainMod, L, exec, ~/.config/hypr/fallout-lock.sh
EOF

# Waybar personnalisée (centrée et transparente)
sudo -u $USERNAME mkdir -p /home/$USERNAME/.config/waybar
cat > /home/$USERNAME/.config/waybar/config << EOF
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "width": 1400,
    "margin-top": 5,
    "margin-bottom": 5,
    "margin-left": "auto",
    "margin-right": "auto",
    "modules-left": ["custom/fallout"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "pulseaudio", "network", "battery"],
    "clock": {
        "format": " {:%H:%M}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-icons": ["", "", ""]
    }
}
EOF

# Fastfetch avec logo Arch (décommenter pour image)
cat > /etc/fastfetch/config.conf << EOF
# --logo-color-1 blue
# --logo-color-2 lightblue
# --logo-color-3 blue
# --logo-color-4 lightblue
# --logo-color-5 blue
# --logo-color-6 lightblue
# --logo-type arch
EOF

# Wallpapers et effets
sudo -u $USERNAME mkdir -p /home/$USERNAME/wallpapers
curl -L "https://example.com/arcane_wallpaper.jpg" -o /home/$USERNAME/wallpapers/arcane.jpg
curl -L "https://example.com/fallout_wallpaper.jpg" -o /home/$USERNAME/wallpapers/fallout.jpg

# Animation Fallout Lock (à placer dans ~/.config/hypr/fallout-lock.sh)
cat > /home/$USERNAME/.config/hypr/fallout-lock.sh << EOF
#!/bin/bash
swaylock \
    --screenshots \
    --effect-blur 10x5 \
    --effect-vignette 0.5:0.5 \
    --indicator-caps-lock \
    --font "Monospace" \
    --ring-color 00ff00 \
    --key-hl-color ff0000 \
    --line-color 00000000 \
    --inside-color 00000088 \
    --separator-color 00000000 \
    --fade-in 0.5 \
    --image ~/wallpapers/fallout.jpg
EOF
chmod +x /home/$USERNAME/.config/hypr/fallout-lock.sh

# -------------------------------------------------------------------
# PHASE 4: Thèmes GRUB (Fallout par défaut)
# -------------------------------------------------------------------

# Installer les thèmes GRUB
themes=(
    "https://github.com/sandesh236/sandesh236.github.io/raw/master/assets/files/Fallout-Grub-Theme.zip"
    "https://github.com/Patato777/dark_matter/releases/latest/download/dark-matter.zip"
    "https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes/raw/master/BSL.zip"
)
mkdir -p /boot/grub/themes
for theme in "${themes[@]}"; do
    wget $theme -O /tmp/theme.zip
    unzip /tmp/theme.zip -d /boot/grub/themes/
done

# Configurer Fallout comme thème par défaut
echo "GRUB_THEME=\"/boot/grub/themes/fallout/theme.txt\"" >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# -------------------------------------------------------------------
# FINALISATION
# -------------------------------------------------------------------

# Activer les services
systemctl enable NetworkManager
systemctl enable bluetooth

# Message final
cat << EOF
Installation terminée !

Personnalisations incluses :
- Hyprland avec transparence et animations
- Waybar centrée et stylée
- Thème GRUB Fallout (par défaut)
- Fastfetch avec logo Arch
- Fond d'écran vidéo (ajouter manuellement)
- Verrouillage style Fallout
- Tous les outils de développement

Thèmes GRUB disponibles :
1. Fallout (défaut)
2. Dark Matter
3. BSOL
4. Minegrub (installer manuellement)
5. Arcane (à créer)

Pour changer de thème GRUB :
1. Éditer /etc/default/grub
2. Modifier GRUB_THEME
3. Exécuter: grub-mkconfig -o /boot/grub/grub.cfg

Redémarrez avec : exit && umount -R /mnt && reboot
EOF
