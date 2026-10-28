# multiboot-usb-creator — Roadmap

## Visao Geral
Ferramenta open-source para criar pendrives bootaveis multi-sistema, compativel
com Legacy BIOS, UEFI e Secure Boot. Suporta Windows e Linux em um unico pendrive.

**Objetivo principal:** Qualquer pessoa, mesmo leiga, consegue criar um pendrive
bootavel sem precisar de conhecimento tecnico.

## Sistemas Suportados
| OS | Versoes | Tipo | Status |
|----|---------|------|--------|
| Windows 7 | SP1 x64 | Instalador | Suportado |
| Windows 10 | 22H2 x64 | Instalador | Testado (X99 Machinist) |
| Windows 11 | 24H2 x64 | Instalador | Suportado |
| Ubuntu | LTS (20.04/22.04/24.04) | Live + Instalador | Suportado |
| Linux Lite | 7.0 | Live + Instalador | Suportado |
| Debian | Stable (12+) | Instalador | Planejado |
| Proxmox VE | 8.x | Instalador | Planejado |
| Hiren's Boot PE | Latest | Ferramentas/Rescue | Planejado |

## Modos de Criacao
1. **Compativel** — MBR + FAT32 unica (funciona em tudo, inclusive X99 chinesas)
2. **Multi-Boot** — MBR + FAT32 + GRUB2 (varios OS no mesmo pendrive)
3. **Moderno** — GPT + FAT32/NTFS (PCs UEFI recentes)

## Plataformas da Ferramenta
| Plataforma | Tecnologia | Status |
|------------|------------|--------|
| Linux (CLI) | Bash + whiptail | Funcionando |
| Linux (GUI) | Python + tkinter | Fase 2 |
| Linux (distribuicao) | AppImage | Fase 2 |
| Windows | Python + tkinter | Fase 3 |
| Windows (distribuicao) | .exe (PyInstaller) | Fase 3 |

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
- [x] Progresso real do wimlib split
- [x] Deteccao USB 2.0 vs 3.0
- [x] Verificacao SHA256 de ISO
- [x] Parametros CLI (--mode, --iso, --dev, --verify, --help)
- [x] Log de operacoes em arquivo
- [x] Modo Multi-Boot (GRUB2 + wimboot)
- [x] Classificacao automatica de ISOs (Windows/Linux)
- [x] Boot Linux via GRUB2 loopback
- [ ] Suporte a Proxmox VE
- [ ] Suporte a Hiren's Boot PE
- [ ] Launcher .desktop (duplo clique no Linux)

### Fase 2 — GUI Python + Distribuicao Linux
Objetivo: usuario leigo baixa, clica duas vezes, e usa.

- [ ] Interface grafica com Python + tkinter
  - [ ] Janela principal com drag-and-drop de ISOs
  - [ ] Selecao visual de pendrive (nome, tamanho, icone)
  - [ ] Barra de progresso nativa
  - [ ] Botao "Criar" / "Verificar" claro e grande
- [ ] Backend reutiliza logica do Bash (subprocess)
- [ ] Empacotamento AppImage (Linux)
- [ ] Instalador .deb/.rpm
- [ ] Auto-elevacao de privilegios (pkexec)
- [ ] Perfis salvos (lembrar ultimas configs)
- [ ] Testes automatizados em VM (QEMU)
- [ ] CI/CD no GitHub Actions

### Fase 3 — Versao Windows + Cross-Platform
Objetivo: mesma ferramenta roda em Linux e Windows.

- [ ] Backend Windows (diskpart, formato, robocopy)
- [ ] Empacotamento .exe (PyInstaller / cx_Freeze)
- [ ] Instalador Windows (NSIS ou Inno Setup)
- [ ] Assinatura de codigo (opcional)
- [ ] Teste em Windows 10/11

### Fase 4 — Comunidade
- [ ] GitHub Releases com binarios (AppImage + .exe)
- [ ] Wiki com guias por hardware
- [ ] CONTRIBUTING.md
- [ ] Traducoes (pt-BR, en-US, es)
- [ ] Canal de suporte (Discussions)
- [ ] Video tutorial de uso

## Decisoes Tecnicas

### Por que Python + tkinter?
- **tkinter** vem embutido no Python — zero dependencias extras
- Roda em Linux e Windows sem mudancas
- Interface simples (ideal para usuario leigo)
- Python pode chamar os mesmos comandos do Bash (parted, mkfs, rsync, grub-install)
- Empacota como AppImage (Linux) e .exe (Windows)

### Por que nao Electron/Tauri/Qt?
- Electron: muito pesado (~200MB) para uma ferramenta simples
- Tauri: precisa de Rust (complexidade de build)
- Qt: licenciamento mais restritivo, pacotes maiores
- tkinter resolve o problema com o menor custo

## Projetos de Referencia
| Projeto | Foco | Relevancia |
|---------|------|------------|
| Ventoy | Multi-boot, GRUB2, arquitetura | Alto (arquitetura de boot) |
| WoeUSB-ng | Windows USB, Python, GUI | Alto (referencia para GUI Python) |
| WoeUSB | Windows USB, Bash original | Medio (logica de particoes) |
| windows2usb | Bash, MBR/GPT, Secure Boot | Medio (MBR boot) |
| WindUSB | Bash + Rust GUI | Baixo (referencia Rust) |
| MultiBootUSB | Multi-boot Linux, Python | Alto (multi-boot + Python GUI) |
