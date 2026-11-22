#!/bin/bash
# Volta os arquivos do backup feito pelo aplicar.sh. Rodar com pkexec.  Uso: reverter.sh <pasta do backup>
set -e
BK=${1:?falta a pasta do backup}
while IFS='|' read -r n path; do
  if [ -e "$BK/$n.NOVO" ]; then rm -f "$path"; echo "apagado (não existia antes): $path"
  else cp -p "$BK/$n" "$path"; echo "restaurado: $path"; fi
done < "$BK/CAMINHOS.txt"
sync
