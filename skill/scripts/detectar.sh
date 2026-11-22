#!/bin/bash
# Mostra o cartão do Anbernic inserido e onde ficam as configurações de PS1.
# Uso: detectar.sh [dispositivo]   (padrão: o primeiro cartão SD, /dev/mmcblk0)
DEV=${1:-/dev/mmcblk0}
echo "== Partições de $DEV"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT "$DEV" || exit 1
for p in $(lsblk -lnpo NAME "$DEV" | tail -n +2); do
  mp=$(lsblk -lnpo MOUNTPOINT "$p")
  [ -z "$mp" ] && udisksctl mount -b "$p" >/dev/null 2>&1
done
echo
echo "== Arquivos de configuração encontrados"
for mp in $(lsblk -lnpo MOUNTPOINT "$DEV" | grep -v '^$'); do
  find "$mp" -maxdepth 6 \( -name anbernic.conf -o -name emuelec.conf -o -name batocera.conf \
       -o -name retroarch.cfg -o -name 'PCSX-ReARMed.opt' -o -name 'retroarch-core-options.cfg' \
       -o -name 'device_info*.txt' -o -name SYSTEM \) 2>/dev/null
  find "$mp" -maxdepth 6 -type d -name 'PCSX-ReARMed' 2>/dev/null
done | sort -u
echo
echo "Dica: pastas que não deram para ler são do root (ext4). Rota A = existe *.conf do sistema (anbernic/emuelec/batocera)."
