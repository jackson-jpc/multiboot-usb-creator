# multiboot-usb-creator — Claude Code Context

## Projeto
Ferramenta open-source para criar pendrives bootaveis multi-sistema (Windows + Linux),
compativel com Legacy BIOS, UEFI e hardware problematico (X99 chinesas).

## Estrutura do Projeto

```
multiboot-usb-creator/
├── src/
│   └── multiboot-usb-creator.sh    # Script principal (Bash)
├── assets/
│   ├── banners/                     # Banner GitHub e promocional
│   ├── icons/                       # Icones em varias resolucoes + .ico
│   └── screenshots/                 # Screenshots do terminal
├── docs/
│   └── ROADMAP.md                   # Roadmap detalhado do projeto
├── .claude/                         # Dados do Claude Code (local, nao vai pro git)
│   ├── memory.md                    # Memoria persistente entre sessoes
│   ├── skills/                      # Skills customizadas
│   └── sessions/                    # Logs de sessoes anteriores
├── tmp/                             # Arquivos temporarios (nao vai pro git)
├── referencias/                     # Projetos de referencia (nao vai pro git)
├── .gitignore
├── CLAUDE.md                        # Este arquivo
├── LICENSE                          # MIT
└── README.md                        # README bilingue (PT-BR / EN)
```

## O que vai para o Git
- `src/` — codigo fonte
- `assets/` — imagens (banners, icones, screenshots)
- `docs/` — documentacao (ROADMAP.md)
- `README.md`, `LICENSE`, `.gitignore`, `CLAUDE.md`

## O que fica apenas local
- `.claude/` — dados do Claude Code (memoria, sessoes, skills)
- `tmp/` — arquivos temporarios, zips de imagens
- `referencias/` — repos de projetos de referencia (ventoy, woeusb-ng, etc.)
- `Kit de Identidade*.png` — arte original do branding

## Script Principal
- **Arquivo**: `src/multiboot-usb-creator.sh`
- **Copia de trabalho**: `/mnt/arquivos/Softwares/ISO/windows/criar_pendrive_bootavel.sh`
- **Sempre sincronizar**: apos editar a copia de trabalho, copiar para `src/`
- **Linguagem**: Bash (Fase 1). Fase 2 sera Python + tkinter.

## Modos de Criacao
1. **COMPAT** — MBR + FAT32 unica (funciona em tudo)
2. **MULTIBOOT** — MBR + FAT32 + GRUB2 (varios OS)
3. **MODERNO** — GPT + FAT32/NTFS (UEFI apenas)

## Hardware Testado
- X99 Machinist (placa-mae chinesa) — modo COMPAT funciona ✅
- Pendrive SanDisk Cruzer Blade 32GB

## ISOs Disponiveis (local)
- `/mnt/arquivos/Softwares/ISO/windows/Win10_22H2_BrazilianPortuguese_x64v1.iso` (5.5G)
- `/mnt/arquivos/Softwares/ISO/windows/pt_windows_7_professional_with_sp1_x64_dvd_u_676950.iso` (3.0G)
- `/mnt/arquivos/Softwares/ISO/windows/Win11_24H2_BrazilianPortuguese_x64.iso` (5.2G)
- `/mnt/arquivos/Softwares/ISO/ubuntu-20.04.6-live-server-amd64.iso` (1.4G)
- `/mnt/arquivos/Softwares/ISO/ubuntu-22.04.5-live-server-amd64.iso` (2.0G)
- `/mnt/arquivos/Softwares/ISO/linux-lite-7.0-64bit.iso` (2.7G)

## Dependencias
- Basicas: parted, dosfstools, ntfs-3g, wimtools, rsync, whiptail
- Multi-Boot: grub-pc-bin, grub-efi-amd64-bin, grub-common
- Objetivo futuro: encapsular dependencias no projeto (sem instalar pacotes extras)

## Regras do Projeto
- Commits sem Co-Authored-By (apenas o autor Jackson)
- Tudo no projeto local e git, nada no claude.ai ou sites externos
- Interface em portugues (pt-BR), README bilingue
- Foco em facilidade de uso para leigos
- Nao over-engineer, manter simples

## Proximos Passos
- [ ] Testar modo MULTIBOOT no pendrive 32GB
- [ ] Instalar grub-efi-amd64-bin antes do teste
- [ ] Encapsular dependencias GRUB no projeto
- [ ] Visual estilo Etcher (Fase 2 — GUI Python)
- [ ] Suporte a Proxmox VE e Hiren's Boot PE
- [ ] Launcher .desktop para Linux
