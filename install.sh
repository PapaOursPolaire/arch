set -e

# 🌌 Script d'installation Arch Linux + Hyprland + GRUB personnalisé

echo "🚀 Bienvenue dans l'installation Arcane x Fallout sur Arch Linux."

# 🔧 Saisie des paramètres utilisateur
read -p "💾 Sur quelle partition souhaitez-vous installer Arch ? (ex: /dev/sda1) : " INSTALL_PARTITION
read -p "👤 Nom d'utilisateur à créer : " USERNAME
read -p "🖥️ Nom de la machine (hostname) : " HOSTNAME

# 🔐 Saisie + confirmation mot de passe
while true; do
  read -s -p "🔐 Mot de passe de l'utilisateur : " USER_PASSWORD
  echo
  read -s -p "🔁 Confirmez le mot de passe : " USER_PASSWORD_CONFIRM
  echo
  if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
    break
  else
    echo "❌ Les mots de passe ne correspondent pas. Veuillez réessayer."
  fi
done

# 📁 Points de montage
mount "$INSTALL_PARTITION" /mnt

# Chemins personnalisés
VIDEO_WALLPAPER_PATH="/usr/share/wallpapers/arcane-background.mp4"
LOGO_IMAGE_PATH="/usr/share/pictures/custom-fastfetch-logo.png"
BEEP_SOUND_PATH="/usr/share/sounds/fallout-beep.wav"
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_DEFAULT_THEME="Fallout"

# 📦 Mise à jour des dépôts
echo "📦 Mise à jour des dépôts..."
pacman -Syu --noconfirm

# 📁 Installation de base
echo "📁 Installation des paquets système..."
pacman -S --noconfirm base base-devel linux linux-firmware grub efibootmgr networkmanager git vim sudo pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber

# 🧬 Configuration UEFI + GRUB
echo "🧬 Installation de GRUB (UEFI)..."
mkdir -p /mnt/boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
mkdir -p "$GRUB_THEMES_DIR"

# 🎨 Thèmes GRUB
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

echo "GRUB_THEME=\"$GRUB_THEMES_DIR/Fallout/theme.txt\"" >> /etc/default/grub

# 🔊 Bip sonore Fallout (optionnel)
mkdir -p /usr/share/sounds
curl -Lo "$BEEP_SOUND_PATH" https://github.com/fallout-theme-sounds/beep.wav
aplay "$BEEP_SOUND_PATH" &

# 🖥️ Installation de Hyprland
echo "🖥️ Installation de Hyprland et des composants graphiques..."
pacman -S --noconfirm hyprland kitty waybar wofi rofi nwg-look brightnessctl \
  pavucontrol thunar thunar-archive-plugin neofetch mpv xdg-desktop-portal-hyprland \
  ffmpeg playerctl

# ⚡ Fastfetch
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
  // "image": "$LOGO_IMAGE_PATH",
  "color": "magenta"
}
EOF

# 🎞️ Fond d’écran vidéo
echo "🎞️ Configuration du fond vidéo..."
mkdir -p /usr/share/wallpapers
curl -Lo "$VIDEO_WALLPAPER_PATH" https://example.com/arcane.mp4
cat <<EOF > /etc/systemd/system/video-wallpaper.service
[Unit]
Description=Video Wallpaper
After=hyprland.service

[Service]
ExecStart=/usr/bin/mpv --loop --no-audio --wid=\$(xdotool search --onlyvisible --class Hyprland | head -n1) "$VIDEO_WALLPAPER_PATH"

[Install]
WantedBy=default.target
EOF

systemctl enable video-wallpaper.service

# 🌫️ Transparence Picom
echo "🌫️ Configuration de la transparence..."
pacman -S --noconfirm picom
mkdir -p /home/$USERNAME/.config/picom
cat <<EOF > /home/$USERNAME/.config/picom/picom.conf
opacity-rule = [ "90:class_g = 'kitty'" ];
backend = "glx";
vsync = true;
blur-method = "dual_kawase";
blur-strength = 5;
EOF

# 🔊 Cava
echo "🔊 Installation de Cava..."
pacman -S --noconfirm cava
mkdir -p /home/$USERNAME/.config/cava
cp /etc/cava/config /home/$USERNAME/.config/cava/config

# 👤 Création de l'utilisateur
echo "👤 Création de l'utilisateur $USERNAME..."
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# 🖥️ Nom de machine
echo "$HOSTNAME" > /etc/hostname

# 🌐 Réseau
systemctl enable NetworkManager

# 🧠 Mise à jour du GRUB
echo "🧠 Mise à jour du GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ Installation terminée avec succès ! Redémarre vers ton nouvel univers Arch x Hyprland 🌌"
