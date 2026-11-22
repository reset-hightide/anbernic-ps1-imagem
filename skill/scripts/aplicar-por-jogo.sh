#!/bin/bash
# Receita LEVE para todos os jogos de PS1 + receita COMPLETA só para os jogos escolhidos.
# Para quando a receita completa deixa jogos pesados lentos. Rota A (EmuELEC/Batocera de fábrica).
# Rodar com pkexec:
#   aplicar-por-jogo.sh <montagem da STORAGE> <pasta de backup> "Jogo (Disc 1).cue" ["Jogo (Disc 2).cue" ...]
# O nome é o do ARQUIVO que o menu abre (com extensão), sem a pasta. Sem nenhum jogo = só a receita leve.
set -e
LEVE="sharp/sharp-bilinear-simple.glslp"   # do sistema: limpo e leve
COMPLETO="psx-hq-vivid.glslp"              # da skill: 2xScaleHQ + cores vivas
SKILL_SHADERS="$(cd "$(dirname "$0")/../shaders" && pwd)"
ST=${1:?falta a montagem da STORAGE}; BK=${2:?falta a pasta de backup}; shift 2

CONF=$(find "$ST" -maxdepth 4 \( -name anbernic.conf -o -name emuelec.conf -o -name batocera.conf \) -path '*configs*' | head -1)
[ -n "$CONF" ] || { echo "Não achei anbernic/emuelec/batocera.conf em $ST"; exit 1; }
OPT=$(find "$ST" -maxdepth 6 -name PCSX-ReARMed.opt | head -1)
[ -n "$OPT" ] || OPT="$(dirname "$(find "$ST" -maxdepth 4 -name retroarch.cfg | head -1)")/config/PCSX-ReARMed/PCSX-ReARMed.opt"
D=$(dirname "$OPT"); mkdir -p "$D"; touch "$OPT"

# backup (o reverter.sh entende o CAMINHOS.txt; arquivos .opt por jogo novos ficam marcados .NOVO)
mkdir -p "$BK"; : > "$BK/CAMINHOS.txt"
for f in "$OPT" "$CONF"; do cp -p "$f" "$BK/"; echo "$(basename "$f")|$f" >> "$BK/CAMINHOS.txt"; done
for g in "$@"; do
  o="$D/${g%.*}.opt"; n=$(basename "$o")
  if [ -e "$o" ]; then cp -p "$o" "$BK/$n"; else echo "(não existia)" > "$BK/$n.NOVO"; fi
  echo "$n|$o" >> "$BK/CAMINHOS.txt"
done
chown -R "$(stat -c %U "$(dirname "$BK")")" "$BK" 2>/dev/null || true

# filtro completo disponível? (no aparelho /storage/shaders fica por cima de /tmp/shaders)
if [ $# -gt 0 ]; then
  if [ -d "$ST/shaders" ]; then cp -n "$SKILL_SHADERS"/* "$ST/shaders"/; else COMPLETO="rpi/2xScaleHQ.glslp"; fi
fi

set_opt(){ sed -i "/^$2 = /d" "$1"; echo "$2 = \"$3\"" >> "$1"; }
# todos os jogos: leve (sem 3D aprimorado, que é o que pesa)
set_opt "$OPT" pcsx_rearmed_dithering disabled
set_opt "$OPT" pcsx_rearmed_screen_centering borderless
set_opt "$OPT" pcsx_rearmed_neon_enhancement_enable disabled
set_opt "$OPT" pcsx_rearmed_neon_enhancement_no_main disabled

sed -i '/^psx\.\(shaderset\|ratio\|smooth\|integerscale\)=/d;/^psx\["[^"]*"\]\.shaderset=/d;/^## PS1 - imagem (anbernic-ps1-imagem)/d' "$CONF"
printf '%s\n' "## PS1 - imagem (anbernic-ps1-imagem) $(date +%F) leve + por jogo" "psx.shaderset=$LEVE" 'psx.ratio=4/3' 'psx.smooth=0' 'psx.integerscale=0' >> "$CONF"

# jogos escolhidos: receita completa
#  - opções do núcleo: RetroArch lê config/PCSX-ReARMed/<nome do jogo>.opt (game_specific_options = true)
#  - filtro: o setsettings.sh procura psx["<arquivo>"].shaderset antes de psx.shaderset
for g in "$@"; do
  o="$D/${g%.*}.opt"; cp "$OPT" "$o"
  set_opt "$o" pcsx_rearmed_neon_enhancement_enable enabled
  set_opt "$o" pcsx_rearmed_neon_enhancement_no_main enabled
  echo "psx[\"$g\"].shaderset=$COMPLETO" >> "$CONF"
done
sync
echo "== anbernic.conf (psx)"; grep -n '^psx' "$CONF"
echo "== todos os jogos"; grep -E 'dithering|centering =|enhancement_(enable|no_main)' "$OPT"
for g in "$@"; do echo "== só ${g%.*}"; grep -E 'enhancement_(enable|no_main)' "$D/${g%.*}.opt"; done
echo "Backup em: $BK"
