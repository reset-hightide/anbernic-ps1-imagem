---
name: anbernic-ps1-imagem
description: Melhora a imagem dos jogos de PlayStation 1 num portátil Anbernic (RG 35, RG35XX, RG40XX H e parecidos) mexendo no cartão de memória do SISTEMA pelo Steam Deck/PC Linux — tira o pontilhado, centraliza a tela (some a faixa preta), liga a resolução 3D aprimorada e põe um filtro que suaviza os cenários com cores mais vivas (2xScaleHQ + ajuste de cor). Faz backup antes e dá para reverter. Use quando pedirem "melhorar a imagem do PS1 no Anbernic", "Chrono Cross/FF/PS1 tá feio/pixelado no Anbernic", "arrumar o cartão do Anbernic de um amigo", ou /anbernic-ps1-imagem.
---

# Imagem do PS1 no Anbernic

Receita que funcionou num RG 35 com o sistema de fábrica (2026-11-21): o dono testou e aprovou.
A ROM não muda nada; o que deixa a imagem feia é a configuração do emulador (PCSX ReARMed).

## O que vai ser aplicado (só PS1)

| Ajuste | Valor | Por quê |
|---|---|---|
| `pcsx_rearmed_dithering` | `disabled` | tira o padrão de pontinhos/xadrez |
| `pcsx_rearmed_screen_centering` | `borderless` | centraliza e tira a faixa preta embaixo |
| `pcsx_rearmed_neon_enhancement_enable` | `enabled` | 3D em 640×480 (o máximo que a tela mostra) |
| `pcsx_rearmed_neon_enhancement_no_main` | `enabled` | o "speed hack" da opção acima |
| filtro (shader) | `psx-hq-vivid.glslp` (pasta `shaders/` da skill) | 2xScaleHQ suaviza os cenários + `psx-vivid.glsl`: saturação 1.25, contraste 1.06, gama 0.95 (céu mais azul e brilhante) |
| proporção / smooth / escala inteira | `4/3` / `0` / `0` | preenche a tela 640×480 sem borrar |

Histórico do teste no RG 35: CRT (`zfast-crt`) ele achou ruim; `sharp-bilinear-simple` ficou ok; `2xScaleHQ` ficou melhor mas com cores apagadas; `2xScaleHQ` + cores vivas foi o aprovado. Cenários em HD **não** são possíveis nesses aparelhos (o pacote HD só roda no Beetle PSX HW, que o chip não aguenta) — dizer isso logo se perguntarem.

## Como conduzir

Uma pergunta por mensagem, em texto.

1. Perguntar qual o modelo do aparelho (está atrás dele) e pedir o **cartão do sistema** (slot 1 / TF1) no leitor do Deck.
2. Rodar `scripts/detectar.sh` — mostra as partições, o tipo de sistema e onde ficam as configurações.
3. Conforme o resultado:
   - **Rota A — sistema de fábrica estilo EmuELEC/Batocera** (o detector acha `anbernic.conf`, `emuelec.conf` ou `batocera.conf`): rodar
     `pkexec <skill>/scripts/aplicar.sh <ponto de montagem da partição STORAGE/SHARE> "$HOME/Backups/anbernic-ps1-<data>"`.
     O script copia `shaders/psx-hq-vivid.glslp` e `psx-vivid.glsl` para `<STORAGE>/shaders` (no aparelho é `/storage/shaders`, que fica por cima de `/tmp/shaders`, então o caminho `rpi/shaders/2xScaleHQ.glsl` do sistema funciona). Se essa pasta não existir, usa `rpi/2xScaleHQ.glslp` puro.
     O `pkexec` abre uma janela pedindo **a senha do usuário do Steam Deck** (a mesma do `sudo`, não é senha de internet). Avisar antes.
     Nesses sistemas o `setsettings.sh` regrava o `retroarch.cfg` a cada jogo, por isso o filtro vai como `psx.shaderset=` no `.conf` e não direto no `retroarch.cfg`.
   - **Rota B — outro sistema** (muOS, Knulli, MinUI, sistema de fábrica dos H700 como o RG40XX H/RG35XX H...): o script também cobre o caso genérico do RetroArch quando recebe a pasta de configuração do RetroArch
     (`aplicar.sh --retroarch <pasta que contém config/> <backup>`): grava só o `PCSX-ReARMed.opt`. O filtro: copiar `shaders/*` para a pasta de shaders do RetroArch do aparelho e escolher no aparelho (Shaders → Carregar → psx-hq-vivid.glslp, ou rpi → 2xScaleHQ → Salvar predefinição do núcleo), porque o caminho dos shaders dentro do aparelho não é o que aparece no Deck.
     **Isso não foi testado em aparelho** — conferir com o detector onde fica o `retroarch.cfg` e se o núcleo usado é o PCSX ReARMed. Se o sistema regravar a configuração a cada jogo (como a Rota A), achar o arquivo de origem antes. Na dúvida, usar o **plano manual** abaixo.
4. Desmontar todas as partições (`udisksctl unmount -b ...`) e devolver o cartão.
5. Pedir para testar e ajustar:
   - ficou lento → `neon_enhancement_enable = disabled`
   - cortou demais nas bordas → `screen_centering = game`
   - cores fortes/fracas demais → no aparelho: Menu rápido → Shaders → Parâmetros do shader (Saturacao, Contraste, Gama); ou mudar os padrões em `shaders/psx-vivid.glsl`
   - ficou pesado → `psx.shaderset=sharp/sharp-bilinear-simple.glslp` (imagem limpa, leve)
   - quer pixel cru → `psx.shaderset=none`
   - não gostou da suavização → `sharp/sharp-bilinear-simple.glslp`; CRT só se a pessoa pedir
6. Para desfazer: `pkexec <skill>/scripts/reverter.sh <pasta do backup>`.

## Plano manual (sem cartão, a pessoa faz no aparelho)

Com o jogo aberto, abrir o menu do RetroArch (MENU, ou MENU+X / SELECT+X) → Menu rápido:
- **Opções do núcleo**: Padrão de pontilhado DESLIGADO; Centralização da tela = borderless (ou Game); Resolução aprimorada LIGADO + Speed Hack LIGADO → Gerenciar opções do núcleo → Salvar opções do núcleo.
- **Shaders**: Ativar; Carregar → rpi → 2xScaleHQ (ou psx-hq-vivid.glslp se ele foi copiado para a pasta de shaders) → Parâmetros/Saturação se existir → Salvar → Salvar predefinição do núcleo.
- **Configurações → Vídeo → Escala**: Proporção 4:3. Depois Menu rápido → Substituições → Salvar substituições do núcleo.

## Lições

- Arquivos da partição STORAGE (ext4) são do root: ler/gravar só com `pkexec` + script. As partições vfat montam e gravam sem senha.
- Para entender um sistema novo sem ligar o aparelho: `unsquashfs -l <partição de boot>/SYSTEM` e extrair só `usr/bin/setsettings.sh` e o `.so` do núcleo (`strings ... | grep pcsx_rearmed_`) para ver as opções que aquela versão aceita.
- O núcleo padrão de PS1 no RG 35 de fábrica é o `pcsx_rearmed_32b`; o nome da pasta de opções é `PCSX-ReARMed` nos dois.
- Shader próprio: escrever no estilo RetroArch GLSL (`#if defined(VERTEX)` / `FRAGMENT`, `#pragma parameter`), declarar `precision` ANTES de `out vec4 FragColor` (senão não compila em GLES 3), e testar com `glslangValidator` nas versões `100` e `300 es` antes de copiar.
- SwanStation/DuckStation não ajuda nesses chips: sem upscaling a imagem é igual e com upscaling fica lento.
