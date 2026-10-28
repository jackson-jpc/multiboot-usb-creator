# multiboot-usb-creator — Roadmap

## Visao Geral
Ferramenta open-source para criar pendrives bootaveis multi-sistema, compativel
com Legacy BIOS, UEFI e Secure Boot. Suporta Windows e Linux em um unico pendrive.

## Sistemas Suportados
| OS | Versoes | Tipo |
|----|---------|------|
| Windows 7 | SP1 x64 | Instalador |
| Windows 10 | 22H2 x64 | Instalador |
| Windows 11 | 24H2 x64 | Instalador |
| Ubuntu | LTS (22.04/24.04) | Live + Instalador |
| Debian | Stable (12+) | Instalador |
| Proxmox VE | 8.x | Instalador |
| Hiren's Boot PE | Latest | Ferramentas/Rescue |

## Modos de Criacao
1. **Single OS** — Um sistema por pendrive (MBR/GPT, FAT32/NTFS)
2. **Multi Boot** — Varios sistemas no mesmo pendrive (GRUB2 menu)

## Perfis de Compatibilidade
- **Compativel** — MBR + FAT32 (funciona em tudo, inclusive X99 chinesas)
- **Moderno** — GPT + FAT32/NTFS (PCs UEFI recentes)
- **Multi Boot** — GPT + exFAT/NTFS + GRUB2 (menu com multiplos OS)

## Plataformas da Ferramenta
- **Linux** — Script bash (atual) + GUI futura (GTK/Qt ou Electron)
- **Windows** — PowerShell/batch ou wrapper nativo
- **AppImage** — Distribuicao unica para Linux

## Fases de Desenvolvimento

### Fase 1 — Script Bash (atual)
- [x] Criar pendrive bootavel Windows (MBR + FAT32)
- [x] Criar pendrive bootavel Windows (GPT + dual partition)
- [x] Deteccao automatica de pendrives USB
- [x] Deteccao automatica de ISOs
- [x] Menu interativo (whiptail + fallback terminal)
- [x] Barra de progresso com taxa/ETA
- [x] Validador de pendrive (verificar boot files)
- [x] Deteccao de versao do Windows via wimlib
- [ ] Suporte a ISOs Linux (Ubuntu, Debian)
- [ ] Suporte a Proxmox VE
- [ ] Suporte a Hiren's Boot PE
- [ ] Modo Multi Boot (GRUB2)

### Fase 2 — Projeto Estruturado
- [ ] Modularizar script (funcoes em arquivos separados)
- [ ] Arquivo de configuracao (perfis salvos)
- [ ] Testes automatizados (verificacao em VM)
- [ ] CI/CD no GitHub Actions
- [ ] Documentacao completa

### Fase 3 — GUI + Distribuicao
- [ ] Interface grafica (GTK4 ou Electron)
- [ ] Empacotamento AppImage
- [ ] Versao Windows (PowerShell ou Rust)
- [ ] Pendrive unico Linux+Windows (cross-platform)

### Fase 4 — Comunidade
- [ ] GitHub Releases com binarios
- [ ] Wiki com guias por hardware
- [ ] Suporte a contribuicoes (CONTRIBUTING.md)
- [ ] Traducoes (pt-BR, en-US, es)

## Projetos de Referencia
| Projeto | Diretorio | Foco |
|---------|-----------|------|
| Ventoy | `referencias/ventoy/` | Multi-boot, GRUB2, arquitetura |
| WoeUSB-ng | `referencias/woeusb-ng/` | Windows USB, Python, GUI |
| WoeUSB | `referencias/woeusb/` | Windows USB, Bash original |
| windows2usb | `referencias/windows2usb/` | Bash, MBR/GPT, Secure Boot |
| WindUSB | `referencias/windusb/` | Bash + Rust GUI |
| MultiBootUSB | `referencias/multibootusb/` | Multi-boot Linux, Python |
