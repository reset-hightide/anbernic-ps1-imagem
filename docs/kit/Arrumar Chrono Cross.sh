#!/bin/bash
# Arrumar Chrono Cross — roda NO PRÓPRIO Anbernic (menu Ports).
# Todos os jogos de PS1: imagem limpa e leve. Só o Chrono Cross: receita completa
# (3D em 640x480 + filtro 2xScaleHQ com cores vivas). Faz backup e cria "Desfazer Chrono Cross".
# Projeto: https://github.com/reset-hightide/anbernic-ps1-imagem

HERE="$(cd "$(dirname "$0")" && pwd)"
KIT="$HERE/.anbernic-ps1"
LOG="$HERE/Chrono Cross - resultado.txt"
exec > >(tee "$LOG") 2>&1
say(){ echo "$*"; for t in /dev/tty1 /dev/tty0; do [ -w "$t" ] && echo "$*" > "$t" 2>/dev/null && break; done; }
fim(){ say "$1"; sync; sleep 6; exit "${2:-0}"; }

say "== Arrumar Chrono Cross $(date '+%F %T')"

# 1) sistema: só a família EmuELEC/Batocera de fábrica (testado no RG 35)
CONF=""
for c in /storage/.config/anbernic/configs/anbernic.conf /storage/.config/emuelec/configs/emuelec.conf \
         /storage/.config/system/configs/system.cfg; do
  [ -f "$c" ] && { CONF="$c"; break; }
done
[ -n "$CONF" ] || fim "Sistema não reconhecido. Nada foi mudado. Use o passo a passo do site (pelo menu do jogo)." 1
RA=""
for r in /storage/.config/retroarch /storage/.config/emuelec/configs/retroarch; do
  [ -f "$r/retroarch.cfg" ] && { RA="$r"; break; }
done
[ -n "$RA" ] || fim "Não achei o RetroArch. Nada foi mudado." 1
D="$RA/config/PCSX-ReARMed"; OPT="$D/PCSX-ReARMed.opt"
mkdir -p "$D"; touch "$OPT"
say "Configuração: $CONF"

# 2) Chrono Cross: o arquivo que o menu abre (não o .bin que o .cue usa)
ROMS=()
while IFS= read -r f; do ROMS+=("$(basename "$f")"); done < <(
  find /storage/roms /var/media /storage/roms2 /roms /roms2 /media /mnt /storage/games-external 2>/dev/null \
       -maxdepth 4 -ipath '*psx*' -iname 'chrono cross*' \
       \( -iname '*.cue' -o -iname '*.chd' -o -iname '*.pbp' -o -iname '*.m3u' -o -iname '*.iso' \
          -o -iname '*.img' -o -iname '*.ccd' -o -iname '*.7z' -o -iname '*.zip' \) \
       -not -ipath '*/images/*' 2>/dev/null | sort -u)
if [ ${#ROMS[@]} -eq 0 ]; then
  # sem o jogo no cartão agora: deixa pronto para os nomes mais comuns
  ROMS=("Chrono Cross (USA) (Disc 1).cue" "Chrono Cross (USA) (Disc 2).cue" "Chrono Cross (USA) (Disc 1).chd" "Chrono Cross (USA) (Disc 2).chd")
  say "Não achei o Chrono Cross nos cartões; preparei para os nomes mais comuns."
fi
mapfile -t ROMS < <(for g in "${ROMS[@]}"; do echo "$g"; echo "${g/Disc 1/Disc 2}"; done | sort -u)
for g in "${ROMS[@]}"; do say "Jogo: $g"; done

# 3) backup
BK="$HERE/.anbernic-ps1-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"; : > "$BK/CAMINHOS.txt"
bk(){ n=$(basename "$1"); if [ -e "$1" ]; then cp -p "$1" "$BK/$n"; else echo novo > "$BK/$n.NOVO"; fi; echo "$n|$1" >> "$BK/CAMINHOS.txt"; }
bk "$OPT"; bk "$CONF"
for g in "${ROMS[@]}"; do bk "$D/${g%.*}.opt"; done

# 4) filtro completo (no aparelho /storage/shaders fica por cima de /tmp/shaders)
COMPLETO="psx-hq-vivid.glslp"
if [ -d /storage/shaders ] && [ -f "$KIT/psx-hq-vivid.glslp" ]; then
  for s in psx-hq-vivid.glslp psx-vivid.glsl; do bk "/storage/shaders/$s"; cp "$KIT/$s" /storage/shaders/; done
else
  COMPLETO="rpi/2xScaleHQ.glslp"
fi

# 5) todos os PS1: leve
set_opt(){ sed -i "/^$2 = /d" "$1"; echo "$2 = \"$3\"" >> "$1"; }
set_opt "$OPT" pcsx_rearmed_dithering disabled
set_opt "$OPT" pcsx_rearmed_screen_centering borderless
set_opt "$OPT" pcsx_rearmed_neon_enhancement_enable disabled
set_opt "$OPT" pcsx_rearmed_neon_enhancement_no_main disabled
sed -i '/^psx\.\(shaderset\|ratio\|smooth\|integerscale\)=/d;/^psx\["[^"]*"\]\.shaderset=/d;/^## PS1 - imagem (anbernic-ps1-imagem)/d' "$CONF"
printf '%s\n' "## PS1 - imagem (anbernic-ps1-imagem) $(date +%F) leve + Chrono Cross" \
  'psx.shaderset=sharp/sharp-bilinear-simple.glslp' 'psx.ratio=4/3' 'psx.smooth=0' 'psx.integerscale=0' >> "$CONF"

# 6) só o Chrono Cross: completa
for g in "${ROMS[@]}"; do
  o="$D/${g%.*}.opt"; cp "$OPT" "$o"
  set_opt "$o" pcsx_rearmed_neon_enhancement_enable enabled
  set_opt "$o" pcsx_rearmed_neon_enhancement_no_main enabled
  echo "psx[\"$g\"].shaderset=$COMPLETO" >> "$CONF"
done

# 7) botão de desfazer
cat > "$HERE/Desfazer Chrono Cross.sh" <<EOF
#!/bin/bash
# Volta a configuração de PS1 como estava antes do "Arrumar Chrono Cross".
BK="$BK"
while IFS='|' read -r n p; do
  if [ -e "\$BK/\$n.NOVO" ]; then rm -f "\$p"; else cp -p "\$BK/\$n" "\$p"; fi
done < "\$BK/CAMINHOS.txt"
sync
for t in /dev/tty1 /dev/tty0; do [ -w "\$t" ] && echo "Desfeito. Tudo voltou como era." > "\$t" && break; done
sleep 4
EOF
chmod +x "$HERE/Desfazer Chrono Cross.sh"

fim "Pronto! Abra o Chrono Cross. Para voltar: Ports > Desfazer Chrono Cross."
