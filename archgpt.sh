#!/usr/bin/env bash
set -euo pipefail

# Fonctions utilitaires
pause() { read -rp "Appuyez sur Entrée pour continuer..." _; }
error() { echo "Erreur : $*" >&2; exit 1; }

# 1) Nom du PC
while true; do
  read -rp "Entrez le nom de la machine (hostname) (lettres, chiffres, tirets ; pas d'espaces) : " HOSTNAME
  [[ $HOSTNAME =~ ^[a-zA-Z0-9-]+$ ]] && break
  echo "Nom invalide. Réessayez."
done

# 2) Compte principal
while true; do
  read -rp "Entrez le nom d’utilisateur principal (lettres, chiffres ; pas de spéciaux) : " USERNAME
  [[ $USERNAME =~ ^[a-zA-Z0-9]+$ ]] && break
  echo "Nom d’utilisateur invalide. Réessayez."
done
while true; do
  read -rsp "Mot de passe pour $USERNAME (pas de spéciaux) : " PASSWORD
  echo
  read -rsp "Confirmation : " PASSWORD2
  echo
  if [[ "$PASSWORD" == "$PASSWORD2" && $PASSWORD =~ ^[a-zA-Z0-9]+$ ]]; then break; fi
  echo "Mots de passe invalides ou non assortis. Réessayez."
done

# 3) Autre utilisateur
read -rp "Ajouter un autre utilisateur ? (O/n) : " RESP
if [[ $RESP =~ ^[Oo]$ ]]; then
  while true; do
    read -rp "Nom d’utilisateur supplémentaire : " USER2
    [[ $USER2 =~ ^[a-zA-Z0-9]+$ ]] && break
    echo "Nom invalide."
  done
  while true; do
    read -rsp "Mot de passe pour $USER2 : " PASS2
    echo
    read -rsp "Confirmation : " PASS2B
    echo
    if [[ "$PASS2" == "$PASS2B" && $PASS2 =~ ^[a-zA-Z0-9]+$ ]]; then break; fi
    echo "Mots de passe invalides ou non assortis."
  done
fi

# 4) Sélection du disque
echo "Disques disponibles :"
lsblk -do NAME,SIZE,TYPE | awk '$3=="disk"{print NR") /dev/"$1" ("$2")"}'
read -rp "Numéro du disque cible : " DISKIDX
DISKDEV=$(lsblk -do NAME | sed -n "${DISKIDX}p")
DISK="/dev/$DISKDEV"
echo "-> $DISK"

# 5) Choix partitions
declare -A WANT
WANT[root]=oui
for p in swap home; do
  prompt="Créer partition ${p^^} (optionnel, suggéré: $([[ $p==swap ]] && echo '2G' || echo '100G')) ? (O/n) : "
  read -rp "$prompt" ans
  WANT[$p]=$( [[ $ans =~ ^[Oo] ]] && echo oui || echo non )
done

# 6) Tailles
declare -A SIZE
for p in root swap home; do
  if [[ ${WANT[$p]} == oui ]]; then
    default=$([[ $p==root ]] && echo '20G' || ([[ $p==swap ]] && echo '2G' || echo '100G'))
    while true; do
      read -rp "Taille $p ($default, ex: 512M, 30G) : " sz
      [[ $sz =~ ^[0-9]+[MG]$ ]] && { SIZE[$p]=$sz; break; }
      echo "Format invalide."
    done
  fi
done

# 7) Création & formatage
echo "Initialisation table GPT sur $DISK..."
parted -s "$DISK" mklabel gpt
START=1MiB
# root
parted -s "$DISK" mkpart primary ext4 "$START" "${SIZE[root]}"
START=${SIZE[root]}
# swap
if [[ ${WANT[swap]} == oui ]]; then
  parted -s "$DISK" mkpart primary linux-swap "$START" "$(( ${SIZE[swap]%?} + ${START%MiB} ))MiB"
  START="$(( ${START%MiB} + ${SIZE[swap]%M} ))MiB"
fi
# home
if [[ ${WANT[home]} == oui ]]; then
  parted -s "$DISK" mkpart primary ext4 "$START" "${SIZE[home]}"
fi

partprobe "$DISK" && sleep 1
ROOT_DEV="${DISK}1"
mkfs.ext4 "$ROOT_DEV"
if [[ ${WANT[swap]} == oui ]]; then SWAP_DEV="${DISK}2"; mkswap "$SWAP_DEV"; swapon "$SWAP_DEV"; fi
if [[ ${WANT[home]} == oui ]]; then HOME_DEV="${DISK}$(( 1 + (${WANT[swap]}==oui?1:0) + 0 ))"; mkfs.ext4 "$HOME_DEV"; fi

# montage
mount "$ROOT_DEV" /mnt
if [[ ${WANT[home]} == oui ]]; then mkdir -p /mnt/home; mount "$HOME_DEV" /mnt/home; fi

# 8) Base & fstab
pacstrap /mnt base linux linux-firmware sudo git
genfstab -U /mnt >> /mnt/etc/fstab

# 9) Script chroot
cat <<EOF > /mnt/root/arch-chroot-setup.sh
#!/usr/bin/env bash
set -e
ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts <<HOSTS
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS
# comptes
echo root:$PASSWORD | chpasswd
useradd -m -G wheel "$USERNAME" && echo "$USERNAME:$PASSWORD" | chpasswd
$( [[ -n "${USER2-}" ]] && cat <<CH2
useradd -m -G wheel "$USER2" && echo "$USER2:$PASS2" | chpasswd
CH2
)
# GRUB & thème Fallout
git clone https://github.com/adi1090x/arch-grub-fallout-theme.git /boot/grub/themes/fallout
cat >> /etc/default/grub <<GCFG
GRUB_THEME="/boot/grub/themes/fallout/theme.txt"
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
# animation par défaut
GRUB_BACKGROUND="/boot/grub/themes/fallout/background.png"
GCFG
# installer Plymouth pour animations (optionnel)
pacman -S --noconfirm plymouth plymouth-theme-arch-logo
# Display Manager + interface GUI lock
pacman -S --noconfirm lightdm lightdm-gtk-greeter light-locker
systemctl enable lightdm
# installer et configurer GRUB
pacman -S --noconfirm grub
grub-install --target=i386-pc "$DISK"
grub-mkconfig -o /boot/grub/grub.cfg
# sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
EOF
chmod +x /mnt/root/arch-chroot-setup.sh

# 10) Chroot
arch-chroot /mnt /root/arch-chroot-setup.sh

echo "Installation terminée avec thème Fallout et GUI lockscreen !"
