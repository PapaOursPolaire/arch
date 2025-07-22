#!/bin/bash
# ──────────────── ⚙ INSTALLATION PERSONNALISÉE ARCH LINUX HYPRLAND ⚙ ────────────────
# Compatible environnement chroot post-install - NE RÉINITIALISE PAS LES DISQUES

set -euo pipefail

# ╭──────────────────────────────╮
# │ 0. Dépendances essentielles  │
# ╰──────────────────────────────╯
echo "[0] Installation des paquets de base..."
pacman -Sy --noconfirm git base-devel curl wget nano sudo unzip zip pipewire wireplumber

# ╭────────────────────────╮
# │ 1. Ajout utilisateur   │
# ╰────────────────────────╯
read -p "Nom d’utilisateur à créer : " username
useradd -m -G wheel,audio,video,network -s /bin/bash "$username"
passwd "$username"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# ╭───────────────────────────╮
# │ 2. Installation d’Hyprland │
# ╰───────────────────────────╯
echo "[1] Installation de Hyprland + environnement graphique..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland \
  xwayland kitty waybar rofi dunst swww \
  qt5-wayland qt6-wayland gvfs thunar thunar-archive-plugin file-roller

# ╭───────────────────────────╮
# │ 3. Apparence / Thèmes     │
# ╰───────────────────────────╯
echo "[2] Installation des thèmes, icônes et police moderne..."
pacman -S --noconfirm papirus-icon-theme ttf-jetbrains-mono ttf-nerd-fonts-symbols

# ╭──────────────────────╮
# │ 4. Fastfetch & Cava  │
# ╰──────────────────────╯
echo "[3] Installation de Fastfetch et Cava (détection des basses)..."
git clone https://github.com/fastfetch-cli/fastfetch.git /opt/fastfetch
cd /opt/fastfetch && cmake -B build -DCMAKE_INSTALL_PREFIX=/usr && cmake --build build && cmake --install build
cd ~
pacman -S --noconfirm cava

# (Optionnel) Image au lieu du logo :
# fastfetch --image /chemin/vers/logo.png

# ╭──────────────────────────╮
# │ 5. Fond animé & transparence │
# ╰──────────────────────────╯
echo "[4] Installation du fond vidéo et transparence..."
pacman -S --noconfirm mpv xwinwrap
# Exemple : xwinwrap -ni -fs -s -st -sp -b -nf -- mpv --loop --no-audio /chemin/video.mp4

# ╭────────────────────────────╮
# │ 6. Applications & dev tools│
# ╰────────────────────────────╯
echo "[5] Installation des applications développeur..."
pacman -S --noconfirm code android-studio jdk-openjdk \
  python python-pip gcc clang cmake make nodejs npm \
  wireshark-qt postman git curl wget

# Extensions VS Code :
sudo -u "$username" code --install-extension GitHub.copilot \
  --install-extension ms-python.python \
  --install-extension ms-vscode.cpptools \
  --install-extension redhat.java

# ╭──────────────────────────╮
# │ 7. Navigateurs et multimédia │
# ╰──────────────────────────╯
echo "[6] Installation des navigateurs & clients multimédia..."
pacman -S --noconfirm google-chrome brave spicetify-cli vlc

# Spotify personnalisé :
sudo -u "$username" spicetify backup apply enable-devtools

# Netflix/Disney+ via navigateur, ou :
# pacman -S --noconfirm gnome-browser-connector webcord (pour Discord/Netflix alternatifs)

# ╭────────────────────────────╮
# │ 8. Barre des tâches moderne │
# ╰────────────────────────────╯
echo "[7] Personnalisation de Waybar..."
# Exemple de config Waybar centrée, transparente (via ~/.config/waybar)
# Laisse l’utilisateur personnaliser selon son fond / style

# ╭────────────────────────╮
# │ 9. Effets & animation  │
# ╰────────────────────────╯
echo "[8] Verrouillage animé style Fallout / Arcane..."
# Dépend d’un script externe :
git clone https://github.com/adi1090x/lockscreen.git /opt/lockscreen
cd /opt/lockscreen && chmod +x setup.sh && ./setup.sh

# Thème Arcane/Fallout à configurer manuellement via ~/.config

# ╭────────────────────────────╮
# │ 10. GRUB + multiboot thèmes│
# ╰────────────────────────────╯
echo "[9] GRUB avec thème Fallout par défaut..."
pacman -S --noconfirm grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Thèmes :
mkdir -p /boot/grub/themes
cd /boot/grub/themes

# Exemple pour Fallout :
git clone https://github.com/shvchk/fallout-grub-theme.git fallout
cp -r fallout /boot/grub/themes/

# GRUB conf :
echo 'GRUB_THEME="/boot/grub/themes/fallout/theme.txt"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Commentaire pour remplacer :
# Autres thèmes (préinstallés) :
# - BSOL
# - Minegrub Word Select
# - CRT-Amber
# - Arcade
# - Dark Matter GRUB
# - Arcane (Netflix)
# - Star Wars
# - Seigneur des Anneaux

# Ajoutez-les dans /boot/grub/themes et modifiez GRUB_THEME

# ╭──────────────────────────────╮
# │ 11. Wine pour applis Windows │
# ╰──────────────────────────────╯
pacman -S --noconfirm wine winetricks

# ╭────────────────────────╮
# │ 12. Nettoyage final    │
# ╰────────────────────────╯
echo "[✔] Installation terminée. Reboot pour lancer Hyprland."

