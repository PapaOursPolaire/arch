set -e

# 🌌 Script d'automatisation d'Arch Linux avec le moteur graphique Hyprland

echo "🚀 Démarrage de l'installation... Prépare-toi à vivre l'expérience Arcane x Fallout sur Arch."

# PARAMÈTRES 
USERNAME="papaours"
HOSTNAME="papaours"
VIDEO_WALLPAPER_PATH="/usr/share/wallpapers/arcane-background.mp4"
LOGO_IMAGE_PATH="/usr/share/pictures/custom-fastfetch-logo.png"
BEEP_SOUND_PATH="/usr/share/sounds/fallout-beep.wav"
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_DEFAULT_THEME="Fallout"

#MISE À JOUR
echo "📦 Mise à jour des dépôts..."
pacman -Syu --noconfirm

# INSTALLATION DU KERNEL
echo "📁 Installation des paquets additionnels..."
pacman -S --noconfirm base base-devel linux linux-firmware grub efibootmgr networkmanager git vim sudo pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber

#UEFI + GRUB
echo "🧬 Installation UEFI + GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
mkdir -p $GRUB_THEMES_DIR

#THÈMES GRUB
echo "🎨 Téléchargement des thèmes GRUB..."
cd /tmp
git clone https://github.com/shvchk/fallout-grub-theme
git clone https://github.com/vinceliuice/BSOL-GRUB-Theme
git clone https://github.com/JeansLucifer/Minegrub-Theme
git clone https://github.com/Mangeshrex/CRT-Amber-GRUB-Theme
git clone https://github.com/vinceliuice/Arcade-GRUB-Theme
git clone https://github.com/vinceliuice/Dark-Matter-Grub-Theme

mkdir -p "$GRUB_THEMES_DIR/Fallout" "$GRUB_THEMES_DIR/BSOL" "$GRUB_THEMES_DIR/Minegrub" "$GRUB_THEMES_DIR/CRT-Amber" "$GRUB_THEMES_DIR/Arcade" "$GRUB_THEMES_DIR/Dark-Matter"

cp -r fallout-grub-theme/* "$GRUB_THEMES_DIR/Fallout/"
cp -r BSOL-GRUB-Theme/* "$GRUB_THEMES_DIR/BSOL/"
cp -r Minegrub-Theme/* "$GRUB_THEMES_DIR/Minegrub/"
cp -r CRT-Amber-GRUB-Theme/* "$GRUB_THEMES_DIR/CRT-Amber/"
cp -r Arcade-GRUB-Theme/* "$GRUB_THEMES_DIR/Arcade/"
cp -r Dark-Matter-Grub-Theme/* "$GRUB_THEMES_DIR/Dark-Matter/"

# Ajout du thème Fallout par défaut
echo "GRUB_THEME=\"$GRUB_THEMES_DIR/Fallout/theme.txt\"" >> /etc/default/grub

# Optionnel : Ajout d’un bip sonore style Fallout
mkdir -p /usr/share/sounds
curl -Lo "$BEEP_SOUND_PATH" https://github.com/fallout-theme-sounds/beep.wav
aplay "$BEEP_SOUND_PATH" &

#INSTALLATION HYPRLAND
echo "🖥️ Installation d'Hyprland et des dépendances..."
pacman -S --noconfirm hyprland kitty waybar wofi rofi nwg-look brightnessctl \
  pavucontrol thunar thunar-archive-plugin neofetch mpv xdg-desktop-portal-hyprland \
  ffmpeg playerctl

#FASTFETCH
echo "⚡ Installation de Fastfetch..."
git clone https://github.com/fastfetch-cli/fastfetch.git /opt/fastfetch
cd /opt/fastfetch
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target fastfetch
cp build/fastfetch /usr/local/bin/

mkdir -p /home/$USERNAME/.config/fastfetch/
cat <<EOF > /home/$USERNAME/.config/fastfetch/config.jsonc
{
  "logo": "arch",
  // 🔧 Pour utiliser un logo personnalisé, décommentez la ligne ci-dessous :
  // "image": "$LOGO_IMAGE_PATH",
  "color": "magenta"
}
EOF

#VIDÉO EN FOND D'ÉCRAN
echo "🎞️ Configuration du fond d’écran vidéo..."
mkdir -p /usr/share/wallpapers
curl -Lo "$VIDEO_WALLPAPER_PATH" https://example.com/arcane.mp4 # Remplacer par chemin d'accès correct
echo "[Service]
ExecStart=mpv --loop --no-audio --wid=\$(xdotool search --onlyvisible --class Hyprland | head -n1) \"$VIDEO_WALLPAPER_PATH\"
" > /etc/systemd/system/video-wallpaper.service

systemctl enable video-wallpaper.service

# TRANSPARENCE
echo "🌫️ Activation de la transparence (picom)..."
pacman -S --noconfirm picom
mkdir -p /home/$USERNAME/.config/picom
cat <<EOF > /home/$USERNAME/.config/picom/picom.conf
opacity-rule = [ "90:class_g = 'kitty'" ];
backend = "glx";
vsync = true;
blur-method = "dual_kawase";
blur-strength = 5;
EOF

#DÉTECTION DES BASSES
echo "🔊 Installation de Cava (analyseur audio)..."
pacman -S --noconfirm cava
mkdir -p /home/$USERNAME/.config/cava
cp /etc/cava/config /home/$USERNAME/.config/cava/config

#UTILISATEUR
echo "👤 Création de l’utilisateur..."
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:arch" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

#RÉSEAU
systemctl enable NetworkManager

#GRUB FINAL
echo "🧠 Mise à jour de GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ Installation complète ! Redémarre maintenant et découvre l'architecture Hyprland sur Arch"