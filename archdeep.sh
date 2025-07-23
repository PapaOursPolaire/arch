#!/bin/bash

# Vérification du mode UEFI/BIOS
if [ -d /sys/firmware/efi/efivars ]; then
    firmware="UEFI"
else
    firmware="BIOS"
fi

# Vérification de la connexion internet
ping -c 1 archlinux.org &> /dev/null || { echo "Erreur: Pas de connexion internet"; exit 1; }

# Synchronisation de l'horloge
timedatectl set-ntp true

# Saisie des informations système
read -p "Nom du PC (hostname) : " hostname
while [[ ! "$hostname" =~ ^[a-z][a-z0-9-]{0,62}$ ]]; do
    echo "Erreur: Uniquement minuscules, chiffres et tirets (doit commencer par une lettre)"
    read -p "Nom du PC (hostname) : " hostname
done

read -p "Nom de l'utilisateur principal : " main_user
while [[ ! "$main_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; do
    echo "Erreur: Format utilisateur invalide (minuscules, chiffres, tirets/underscores)"
    read -p "Nom de l'utilisateur principal : " main_user
done

add_other_user=""
while [[ ! "$add_other_user" =~ ^(oui|non)$ ]]; do
    read -p "Ajouter un autre utilisateur ? (oui/non) : " add_other_user
done

other_users=()
if [[ "$add_other_user" == "oui" ]]; then
    while true; do
        read -p "Nom du nouvel utilisateur (laissez vide pour terminer) : " user
        [[ -z "$user" ]] && break
        while [[ ! "$user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; do
            echo "Erreur: Format utilisateur invalide"
            read -p "Nom du nouvel utilisateur : " user
        done
        other_users+=("$user")
    done
fi

set_password() {
    local user=$1
    while true; do
        read -sp "Mot de passe pour $user : " password
        echo
        read -sp "Confirmation : " password_confirm
        echo
        if [ "$password" != "$password_confirm" ]; then
            echo "Erreur: Les mots de passe ne correspondent pas"
        elif [[ ${#password} -lt 8 ]]; then
            echo "Erreur: Le mot de passe doit faire au moins 8 caractères"
        else
            break
        fi
    done
    eval "$2='$password'"
}

set_password "$main_user" main_password
for user in "${other_users[@]}"; do
    set_password "$user" "password_$user"
done

# Partitionnement
lsblk
echo "Disques disponibles :"
disks=($(lsblk -d -n -l -o NAME))
select disk in "${disks[@]}"; do
    [[ -n "$disk" ]] && break
done
disk="/dev/$disk"

# Configuration des partitions
declare -A partitions
partitions["root"]="/"
partitions["home"]="/home"
partitions["swap"]="swap"

# Taille recommandée swap = RAM * 1.5 (en GiB)
ram_gb=$(free -g | awk '/Mem:/ {print $2}')
swap_recommended=$((ram_gb * 3 / 2)) # Format en GiB

echo "Configuration des partitions (tapez 'auto' pour taille recommandée)"
for part in "${!partitions[@]}"; do
    size=0
    unit=""
    while true; do
        rec=""
        if [[ "$part" == "swap" ]]; then
            rec=" (recommandé: ${swap_recommended}G)"
        elif [[ "$part" == "root" ]]; then
            rec=" (minimum: 20G)"
        fi
        
        read -p "Taille pour $part$rec : " input
        if [[ "$input" == "auto" ]]; then
            [[ "$part" == "swap" ]] && size=${swap_recommended} && unit="G"
            [[ "$part" == "root" ]] && size=20 && unit="G"
            [[ "$part" == "home" ]] && continue # Pas de valeur auto pour home
        fi

        if [[ -z "$size" ]]; then
            unit="${input: -1}"
            size="${input%?}"
            if [[ ! "$unit" =~ ^[GgMm]$ ]] || ! [[ "$size" =~ ^[0-9]+$ ]]; then
                echo "Erreur: Format invalide. Exemple: 20G ou 512M"
                continue
            fi
        fi
        break
    done
    partitions["$part"]="${partitions[$part]}:${size}${unit^^}"
done

# Création de la table de partition
if [[ "$firmware" == "UEFI" ]]; then
    parted -s $disk mklabel gpt
    parted -s $disk mkpart primary fat32 1MiB 513MiB
    parted -s $disk set 1 esp on
    mkfs.fat -F32 ${disk}1
    boot_part="${disk}1"
    start=513MiB
else
    parted -s $disk mklabel msdos
    parted -s $disk mkpart primary 1MiB 513MiB
    parted -s $disk set 1 boot on
    mkfs.ext4 ${disk}1
    boot_part="${disk}1"
    start=513MiB
fi

# Création des autres partitions
for part in root swap home; do
    config=${partitions[$part]}
    IFS=':' read -r path size <<< "$config"
    [[ -z "$size" ]] && continue
    
    end="$start+$size"
    parted -s $disk mkpart primary $start $end
    num=$(echo $disk | awk -F'[^0-9]+' '{print $2}') && num=$((num+1))
    part_dev="${disk}$num"
    
    case $part in
        root) root_dev=$part_dev;;
        swap) swap_dev=$part_dev;;
        home) home_dev=$part_dev;;
    esac
    
    start="$end"
done

# Formatage et montage
mkfs.ext4 $root_dev
mount $root_dev /mnt

[[ -n "$home_dev" ]] && {
    mkfs.ext4 $home_dev
    mkdir /mnt/home
    mount $home_dev /mnt/home
}

[[ -n "$swap_dev" ]] && {
    mkswap $swap_dev
    swapon $swap_dev
}

mkdir /mnt/boot
mount $boot_part /mnt/boot

# Installation de base
pacstrap /mnt base linux linux-firmware

# Génération fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuration système
arch-chroot /mnt /bin/bash <<EOF
    # Configuration de base
    echo "$hostname" > /etc/hostname
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
    
    # Utilisateurs
    useradd -m -G wheel -s /bin/bash "$main_user"
    echo "$main_user:$main_password" | chpasswd
    for user in ${other_users[@]}; do
        useradd -m -s /bin/bash "\$user"
        var="password_\$user"
        echo "\$user:\${!var}" | chpasswd
    done
    
    # Bootloader
    if [[ "$firmware" == "UEFI" ]]; then
        pacman -S --noconfirm grub efibootmgr
        grub-install --target=x86_64-efi --efi-directory=/boot
    else
        pacman -S --noconfirm grub
        grub-install --target=i386-pc $disk
    fi

    # Installation du thème GRUB Fallout
    pacman -S --noconfirm git
    cd /tmp
    git clone https://github.com/shvchk/fallout-grub-theme.git
    mkdir -p /boot/grub/themes
    cp -r fallout-grub-theme /boot/grub/themes/
    echo 'GRUB_THEME="/boot/grub/themes/fallout-grub-theme/theme.txt"' >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg

    # Activation réseau
    systemctl enable dhcpcd

    # Installation de l'environnement graphique (KDE Plasma + SDDM)
    pacman -S --noconfirm xorg plasma plasma-wayland-session kde-utilities sddm
    systemctl enable sddm

    # Configuration du thème Fallout pour SDDM
    cd /usr/share/sddm/themes
    git clone https://github.com/MrGunpla/fallout-sddm-theme.git
    cat > /etc/sddm.conf <<SDDM_EOF
[Theme]
Current=fallout-sddm-theme
SDDM_EOF

    # Configuration du thème Fallout pour l'utilisateur
    for user in "$main_user" ${other_users[@]}; do
        user_home="/home/\$user"
        [ -d "\$user_home" ] || continue
        
        # Téléchargement du thème Plasma
        sudo -u "\$user" mkdir -p "\$user_home/.local/share/plasma/desktoptheme"
        cd "\$user_home/.local/share/plasma/desktoptheme"
        sudo -u "\$user" git clone https://github.com/dzervas/fallout-plasma-theme.git
        mv fallout-plasma-theme fallout

        # Application automatique du thème
        mkdir -p "\$user_home/.config"
        cat > "\$user_home/.config/plasma-org.kde.plasma.desktop-appletsrc" <<PLASMA_EOF
[Containments][1][General]
theme=fallout

[Containments][1][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/fallout.jpg
PLASMA_EOF

        # Configuration de l'écran de verrouillage
        mkdir -p "\$user_home/.local/share/wallpapers"
        curl -L -o "\$user_home/.local/share/wallpapers/fallout.jpg" https://raw.githubusercontent.com/shvchk/fallout-grub-theme/master/background.jpg
        cat > "\$user_home/.config/kscreenlockerrc" <<LOCK_EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=\$user_home/.local/share/wallpapers/fallout.jpg
LOCK_EOF
    done

    # Fond d'écran système
    curl -L -o /usr/share/wallpapers/fallout.jpg https://raw.githubusercontent.com/shvchk/fallout-grub-theme/master/background.jpg
EOF

# Nettoyage
umount -R /mnt
swapoff -a
echo "Installation terminée ! Rebootez avec 'reboot'"