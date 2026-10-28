<p align="center">
  <img src="https://img.shields.io/badge/USB-Bootable_Creator-blue?style=for-the-badge&logo=usb&logoColor=white" alt="USB Bootable Creator"/>
  <br/>
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black" alt="Linux"/>
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Bash"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License"/>
  <img src="https://img.shields.io/github/stars/jackson-jpc/multiboot-usb-creator?style=flat-square&color=yellow" alt="Stars"/>
  <img src="https://img.shields.io/github/last-commit/jackson-jpc/multiboot-usb-creator?style=flat-square&color=blue" alt="Last Commit"/>
</p>

<h1 align="center">🔥 multiboot-usb-creator</h1>

<p align="center">
  <b>Crie pendrives bootáveis multi-sistema com suporte a Legacy BIOS e UEFI.</b><br/>
  <i>Create multi-system bootable USB drives with Legacy BIOS and UEFI support.</i>
</p>

<p align="center">
  <a href="#-português">Português</a> •
  <a href="#-english">English</a> •
  <a href="#-instalação--installation">Instalação</a> •
  <a href="#-contribuindo--contributing">Contribuir</a>
</p>

---

## 🇧🇷 Português

### 📖 Sobre

Ferramenta **open-source** para criar pendrives bootáveis com **Windows** e **Linux**, compatível com praticamente qualquer hardware — incluindo placas-mãe chinesas (X99/B75), PCs antigos com BIOS Legacy e computadores modernos com UEFI.

> **💡 Por que mais um criador de USB?**
> Testado e validado em hardware problemático como placas X99 Machinist, onde ferramentas populares falham. O modo compatível (MBR + FAT32) garante boot em qualquer máquina.

---

### ✨ Funcionalidades

| Recurso | Descrição |
|:--------|:----------|
| 💿 **Criação a partir de ISO** | Seleciona a ISO automaticamente na pasta do script |
| 🔄 **BIOS + UEFI** | Mesmo pendrive funciona em Legacy BIOS e UEFI |
| 🛡️ **Modo Compatível** | MBR + FAT32 — funciona em qualquer hardware |
| ⚡ **Modo Moderno** | GPT + FAT32/NTFS — para PCs UEFI recentes |
| 🔍 **Detecção automática** | Encontra pendrives USB e ISOs automaticamente |
| 📊 **Progresso detalhado** | Velocidade, ETA, arquivos transferidos, tempo decorrido |
| ✅ **Validador** | Verifica se o pendrive está correto após criação |
| 🏷️ **Detecção de versão** | Identifica Windows 7/8/10/11 e edições via wimlib |
| 📦 **Split automático** | Divide install.wim > 4GB para FAT32 |
| 🖥️ **Menu interativo** | Interface whiptail com fallback para terminal |

---

### 🖥️ Modos de Criação

```
┌─────────────────────────────────────────────────────────────┐
│                   MODO COMPATÍVEL (Recomendado)             │
│                                                             │
│   Partição:  MBR + FAT32 única                             │
│   Boot:      Legacy BIOS ✅  UEFI ✅  Secure Boot ⚠️      │
│   Hardware:  Qualquer PC (X99, B75, antigos, modernos)     │
│   Limite:    install.wim > 4GB é dividido automaticamente  │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                   MODO MODERNO                              │
│                                                             │
│   Partição:  GPT + FAT32 (EFI) + NTFS (dados)             │
│   Boot:      Legacy BIOS ❌  UEFI ✅  Secure Boot ✅      │
│   Hardware:  PCs UEFI recentes                             │
│   Limite:    Sem limite de tamanho de arquivo               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 💽 Sistemas Suportados

| OS | Versões | Status | Obs |
|:---|:--------|:------:|:----|
| <img src="https://img.shields.io/badge/Windows_10-0078D6?style=flat-square&logo=windows&logoColor=white"/> | 22H2 x64 | ✅ Funcional | Testado em X99 Machinist |
| <img src="https://img.shields.io/badge/Windows_11-0078D4?style=flat-square&logo=windows11&logoColor=white"/> | 24H2 x64 | 🔧 Em dev | |
| <img src="https://img.shields.io/badge/Windows_7-0078D6?style=flat-square&logo=windows&logoColor=white"/> | SP1 x64 | 🔧 Em dev | |
| <img src="https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white"/> | LTS | 📋 Planejado | |
| <img src="https://img.shields.io/badge/Debian-A81D33?style=flat-square&logo=debian&logoColor=white"/> | Stable | 📋 Planejado | |
| <img src="https://img.shields.io/badge/Proxmox-E57000?style=flat-square&logo=proxmox&logoColor=white"/> | 8.x | 📋 Planejado | |
| <img src="https://img.shields.io/badge/Hiren's_Boot-333333?style=flat-square&logo=windows-terminal&logoColor=white"/> | Latest | 📋 Planejado | |

---

### 🔍 Verificador de Pendrive

O modo **Verificar** analisa qualquer pendrive USB e gera um relatório completo:

```
==========================================
  RELATÓRIO DO PENDRIVE
==========================================

  Dispositivo:  /dev/sdc (57,8G)
  Modelo:       DataTraveler 3.0
  Windows:      Windows 10 (Build 19045)

  Edições disponíveis:
    1. Windows 10 Home
    2. Windows 10 Pro
    3. Windows 10 Education

  ------------------------------------------
  Verificações:
  ------------------------------------------
  [OK]    Tabela de partição GPT
  [OK]    Partição 1 (vfat)
  [OK]    Partição 2 (ntfs)
  [OK]    Boot UEFI (bootx64.efi)
  [OK]    Boot Manager (Legacy BIOS)
  [OK]    BCD (Legacy boot config)
  [OK]    BCD EFI (UEFI boot config)
  [OK]    boot.wim (instalador)
  [OK]    Imagem de instalação (install.wim 4,2G)

  ------------------------------------------
  Compatibilidade:
  ------------------------------------------
  [OK]    Legacy BIOS: Compatível
  [OK]    UEFI: Compatível

  Resultado: PENDRIVE OK (0 problemas)
==========================================
```

---

## 🇺🇸 English

### 📖 About

**Open-source** tool to create bootable USB drives with **Windows** and **Linux**, compatible with virtually any hardware — including Chinese motherboards (X99/B75), legacy BIOS PCs and modern UEFI computers.

> **💡 Why another USB creator?**
> Tested and validated on problematic hardware like X99 Machinist boards, where popular tools fail. The compatible mode (MBR + FAT32) guarantees boot on any machine.

---

### ✨ Features

| Feature | Description |
|:--------|:------------|
| 💿 **ISO-based creation** | Automatically detects ISOs in the script folder |
| 🔄 **BIOS + UEFI** | Same USB works on Legacy BIOS and UEFI |
| 🛡️ **Compatible Mode** | MBR + FAT32 — works on any hardware |
| ⚡ **Modern Mode** | GPT + FAT32/NTFS — for recent UEFI PCs |
| 🔍 **Auto detection** | Finds USB drives and ISOs automatically |
| 📊 **Detailed progress** | Speed, ETA, transferred files, elapsed time |
| ✅ **Validator** | Checks if USB was created correctly |
| 🏷️ **Version detection** | Identifies Windows 7/8/10/11 and editions via wimlib |
| 📦 **Auto split** | Splits install.wim > 4GB for FAT32 |
| 🖥️ **Interactive menu** | Whiptail UI with terminal fallback |

---

### 💽 Supported Systems

| OS | Versions | Status | Notes |
|:---|:---------|:------:|:------|
| <img src="https://img.shields.io/badge/Windows_10-0078D6?style=flat-square&logo=windows&logoColor=white"/> | 22H2 x64 | ✅ Working | Tested on X99 Machinist |
| <img src="https://img.shields.io/badge/Windows_11-0078D4?style=flat-square&logo=windows11&logoColor=white"/> | 24H2 x64 | 🔧 In dev | |
| <img src="https://img.shields.io/badge/Windows_7-0078D6?style=flat-square&logo=windows&logoColor=white"/> | SP1 x64 | 🔧 In dev | |
| <img src="https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white"/> | LTS | 📋 Planned | |
| <img src="https://img.shields.io/badge/Debian-A81D33?style=flat-square&logo=debian&logoColor=white"/> | Stable | 📋 Planned | |
| <img src="https://img.shields.io/badge/Proxmox-E57000?style=flat-square&logo=proxmox&logoColor=white"/> | 8.x | 📋 Planned | |
| <img src="https://img.shields.io/badge/Hiren's_Boot-333333?style=flat-square&logo=windows-terminal&logoColor=white"/> | Latest | 📋 Planned | |

---

## 📦 Instalação / Installation

### Dependências / Dependencies

```bash
# Ubuntu / Debian / Pop!_OS
sudo apt install parted dosfstools ntfs-3g wimtools rsync

# Fedora
sudo dnf install parted dosfstools ntfs-3g wimlib-utils rsync

# Arch Linux
sudo pacman -S parted dosfstools ntfs-3g wimlib rsync
```

### Download

```bash
git clone https://github.com/jackson-jpc/multiboot-usb-creator.git
cd multiboot-usb-creator
```

### Uso / Usage

```bash
sudo bash src/multiboot-usb-creator.sh
```

---

## 🗺️ Roadmap

```mermaid
graph LR
    A[Fase 1<br/>Script Bash] --> B[Fase 2<br/>Modular + Testes]
    B --> C[Fase 3<br/>GUI + AppImage]
    C --> D[Fase 4<br/>Comunidade]

    style A fill:#4CAF50,color:#fff
    style B fill:#2196F3,color:#fff
    style C fill:#FF9800,color:#fff
    style D fill:#9C27B0,color:#fff
```

| Fase | Descrição | Status |
|:-----|:----------|:------:|
| **1. Script Bash** | Windows 7/10/11 + Linux + validador | 🟡 Em andamento |
| **2. Modular** | Funções separadas, configs, CI/CD | ⬜ Planejado |
| **3. GUI** | Interface gráfica + AppImage + Windows | ⬜ Planejado |
| **4. Comunidade** | Releases, wiki, traduções, contribuições | ⬜ Planejado |

---

## 🤝 Contribuindo / Contributing

Contribuições são bem-vindas! / Contributions are welcome!

1. Fork o projeto / Fork the project
2. Crie sua branch / Create your branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças / Commit your changes (`git commit -m 'Add nova feature'`)
4. Push para a branch / Push to branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request / Open a Pull Request

---

## 📄 Licença / License

Este projeto é distribuído sob a licença [MIT](LICENSE).
This project is distributed under the [MIT](LICENSE) license.

---

## 👤 Autor / Author

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/jackson-jpc">
        <img src="https://github.com/jackson-jpc.png" width="100px;" alt="Jackson"/><br/>
        <sub><b>Jackson</b></sub>
      </a><br/>
      <a href="https://github.com/jackson-jpc">@jackson-jpc</a>
    </td>
  </tr>
</table>

---

<p align="center">
  Feito com ❤️ no Brasil 🇧🇷<br/>
  <i>Made with ❤️ in Brazil 🇧🇷</i>
</p>

<p align="center">
  <a href="https://github.com/jackson-jpc/multiboot-usb-creator/stargazers">⭐ Deixe uma estrela se este projeto te ajudou! / Star if this helped you!</a>
</p>
