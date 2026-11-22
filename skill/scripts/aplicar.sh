#!/bin/bash
# Aplica a receita de imagem do PS1. Rodar com pkexec (precisa de root para a partição ext4).
#   Rota A (EmuELEC/Batocera de fábrica): aplicar.sh <montagem da partição STORAGE> <pasta de backup>
#   Rota B (RetroArch genérico, não testado): aplicar.sh --retroarch <pasta do RetroArch (contém config/)> <pasta de backup>
#     Na Rota B só as opções do núcleo são gravadas; o filtro se escolhe no menu do aparelho
#     (o caminho dos shaders dentro do aparelho não é o mesmo que aparece no Deck).
set -e
SHADER="psx-hq-vivid.glslp"          # 2xScaleHQ + cores vivas (pasta shaders/ da skill)
SHADER_FALLBACK="rpi/2xScaleHQ.glslp" # se não der para copiar o filtro próprio
SKILL_SHADERS="$(cd "$(dirname "$0")/../shaders" && pwd)"
MODE=A; [ "$1" = "--retroarch" ] && { MODE=B; shift; }
BASE=${1:?falta a montagem}; BK=${2:?falta a pasta de backup}
mkdir -p "$BK"
OWNER=$(stat -c %U "$(dirname "$BK")")

if [ $MODE = A ]; then
  CONF=$(find "$BASE" -maxdepth 4 \( -name anbernic.conf -o -name emuelec.conf -o -name batocera.conf \) -path '*configs*' | head -1)
  OPT=$(find "$BASE" -maxdepth 6 -name PCSX-ReARMed.opt | head -1)
  [ -n "$CONF" ] || { echo "Não achei anbernic/emuelec/batocera.conf em $BASE — use a Rota B"; exit 1; }
  if [ -z "$OPT" ]; then
    RA=$(dirname "$(find "$BASE" -maxdepth 4 -name retroarch.cfg | head -1)")
    OPT="$RA/config/PCSX-ReARMed/PCSX-ReARMed.opt"
  fi
else
  OPT="$BASE/config/PCSX-ReARMed/PCSX-ReARMed.opt"
fi

# backup (com o caminho original anotado para o reverter.sh)
: > "$BK/CAMINHOS.txt"
if [ $MODE = A ]; then
  SHDIR="$BASE/shaders"   # vira /storage/shaders no aparelho (por cima de /tmp/shaders)
  if [ -d "$SHDIR" ]; then for x in "$SKILL_SHADERS"/*; do SHFILES+=("$SHDIR/$(basename "$x")"); done; else SHADER=$SHADER_FALLBACK; fi
fi
for f in "$OPT" ${CONF:+"$CONF"} "${SHFILES[@]}"; do
  n=$(basename "$f"); if [ -e "$f" ]; then cp -p "$f" "$BK/$n"; else echo "(não existia)" > "$BK/$n.NOVO"; fi
  echo "$n|$f" >> "$BK/CAMINHOS.txt"
done
chown -R "$OWNER" "$BK" 2>/dev/null || true
mkdir -p "$(dirname "$OPT")"; touch "$OPT"
if [ ${#SHFILES[@]} -gt 0 ]; then cp "$SKILL_SHADERS"/* "$SHDIR"/; fi

set_opt(){ sed -i "/^$1 = /d" "$OPT"; echo "$1 = \"$2\"" >> "$OPT"; }
set_opt pcsx_rearmed_dithering disabled
set_opt pcsx_rearmed_screen_centering borderless
set_opt pcsx_rearmed_neon_enhancement_enable enabled
set_opt pcsx_rearmed_neon_enhancement_no_main enabled

if [ $MODE = A ]; then
  sed -i '/^psx\.\(shaderset\|ratio\|smooth\|integerscale\)=/d;/^## PS1 - imagem (anbernic-ps1-imagem)/d' "$CONF"
  printf '%s\n' "## PS1 - imagem (anbernic-ps1-imagem) $(date +%F)" "psx.shaderset=$SHADER" 'psx.ratio=4/3' 'psx.smooth=0' 'psx.integerscale=0' >> "$CONF"
else
  echo "Filtro: copie skill/shaders/* para a pasta de shaders do RetroArch do aparelho e, no aparelho,"
  echo "  Menu rápido → Shaders → Carregar → psx-hq-vivid.glslp → Salvar predefinição do núcleo (ou use rpi/2xScaleHQ)"
fi
sync
echo "== Aplicado"; grep -E 'dithering|screen_centering =|enhancement_(enable|no_main)' "$OPT"
[ -n "$CONF" ] && grep '^psx\.' "$CONF"
if [ ${#SHFILES[@]} -gt 0 ]; then ls -la "${SHFILES[@]}"; fi
echo "Backup em: $BK"
