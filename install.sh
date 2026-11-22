#!/bin/bash
# Instala a skill em ~/.claude/skills/anbernic-ps1-imagem  (--link cria um link em vez de copiar)
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/skill"
DST="$HOME/.claude/skills/anbernic-ps1-imagem"
mkdir -p "$HOME/.claude/skills"
if [ -e "$DST" ] || [ -L "$DST" ]; then mv "$DST" "$DST.bak-$(date +%s)"; fi
if [ "$1" = "--link" ]; then ln -s "$SRC" "$DST"; else cp -r "$SRC" "$DST"; fi
chmod +x "$DST"/scripts/*.sh
echo "Skill instalada em $DST"
