# anbernic-ps1-imagem

Deixa a imagem dos jogos de PlayStation 1 bem melhor em portáteis Anbernic (RG 35, RG35XX, RG40XX H e parecidos), mexendo direto no cartão de memória do sistema a partir de um Steam Deck ou PC com Linux.

Nasceu de um Chrono Cross que estava pixelado, com uma faixa preta embaixo e cheio de pontinhos. A ROM estava certa: o problema era a configuração do emulador.

## O que muda (só no PS1)

- **Sem pontilhado** (`dithering` desligado): some o padrão de pontinhos.
- **Tela centralizada** (`screen_centering = borderless`): some a faixa preta.
- **3D em 640×480** (resolução aprimorada do PCSX ReARMed + speed hack).
- **Filtro que suaviza com cores vivas** (`psx-hq-vivid`): o 2xScaleHQ arredonda os pixels dos cenários e um ajuste de cor próprio deixa o céu mais azul e brilhante (saturação +25%, um pouco de contraste e brilho). Dá para regular no aparelho em *Shaders → Parâmetros do shader*.

Cenários em HD não dá: o pacote de fundos HD do PS1 só roda no Beetle PSX HW, que esses chips não aguentam.

## Uso

É uma skill para o Claude Code (pasta `skill/`). Para instalar:

```bash
bash install.sh
```

Depois, com o cartão do sistema do Anbernic no leitor, peça "melhora a imagem do PS1 no meu Anbernic" ou rode `/anbernic-ps1-imagem`.

O filtro está em `skill/shaders/`.

Os scripts também funcionam sozinhos:

```bash
skill/scripts/detectar.sh                       # mostra partições e onde estão as configurações
pkexec skill/scripts/aplicar.sh /run/media/$USER/STORAGE ~/Backups/anbernic-ps1-$(date +%F)
pkexec skill/scripts/reverter.sh ~/Backups/anbernic-ps1-AAAA-MM-DD
```

O `pkexec` pede a senha do usuário do computador, porque a partição de configurações do cartão pertence ao root.

## Testado

- Anbernic RG 35 com o sistema de fábrica (baseado no EmuELEC): aplicado e aprovado.
- Outros sistemas (muOS, Knulli, sistema de fábrica dos H700): a rota genérica existe, mas ainda não foi testada num aparelho. O `SKILL.md` tem também o passo a passo manual pelo menu do RetroArch.

Sempre é feito backup antes, e o `reverter.sh` volta tudo como estava.

## Licença

MIT
