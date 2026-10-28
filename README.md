# multiboot-usb-creator

**Crie pendrives bootaveis multi-sistema com suporte a Legacy BIOS e UEFI.**
**Create multi-system bootable USB drives with Legacy BIOS and UEFI support.**

---

## Portugues

### Sobre

Ferramenta open-source para criar pendrives bootaveis com Windows e Linux, compativel com praticamente qualquer hardware — incluindo placas-mae chinesas (X99/B75), PCs antigos com BIOS Legacy e computadores modernos com UEFI.

### Funcionalidades

- Criacao de pendrive bootavel a partir de ISOs
- Suporte a **Legacy BIOS** e **UEFI** no mesmo pendrive
- Dois modos de criacao:
  - **Compativel (MBR + FAT32)** — funciona em qualquer hardware
  - **Moderno (GPT + FAT32/NTFS)** — para PCs UEFI recentes
- Deteccao automatica de pendrives USB e ISOs
- Menu interativo (whiptail ou terminal)
- Barra de progresso com velocidade, ETA e contagem de arquivos
- Verificador/validador de pendrive existente
- Deteccao de versao do Windows e edicoes via wimlib
- Divisao automatica de install.wim > 4GB para FAT32

### Sistemas suportados

| OS | Versoes | Status |
|----|---------|--------|
| Windows 7 | SP1 x64 | Em desenvolvimento |
| Windows 10 | 22H2 x64 | Funcional |
| Windows 11 | 24H2 x64 | Em desenvolvimento |
| Ubuntu | LTS | Planejado |
| Debian | Stable | Planejado |
| Proxmox VE | 8.x | Planejado |
| Hiren's Boot PE | Latest | Planejado |

### Dependencias

```bash
sudo apt install parted dosfstools ntfs-3g wimtools rsync
```

### Como usar

```bash
sudo bash multiboot-usb-creator.sh
```

### Autor

**Jackson** — [@jackson-jpc](https://github.com/jackson-jpc)

### Licenca

Este projeto e distribuido sob a licenca [MIT](LICENSE).

---

## English

### About

Open-source tool to create bootable USB drives with Windows and Linux, compatible with virtually any hardware — including Chinese motherboards (X99/B75), legacy BIOS PCs and modern UEFI computers.

### Features

- Create bootable USB drives from ISO images
- **Legacy BIOS** and **UEFI** support on the same drive
- Two creation modes:
  - **Compatible (MBR + FAT32)** — works on any hardware
  - **Modern (GPT + FAT32/NTFS)** — for recent UEFI PCs
- Automatic detection of USB drives and ISO files
- Interactive menu (whiptail or terminal fallback)
- Progress bar with transfer speed, ETA and file count
- Existing USB drive validator/checker
- Windows version and edition detection via wimlib
- Automatic install.wim splitting for FAT32 (files > 4GB)

### Supported systems

| OS | Versions | Status |
|----|----------|--------|
| Windows 7 | SP1 x64 | In development |
| Windows 10 | 22H2 x64 | Working |
| Windows 11 | 24H2 x64 | In development |
| Ubuntu | LTS | Planned |
| Debian | Stable | Planned |
| Proxmox VE | 8.x | Planned |
| Hiren's Boot PE | Latest | Planned |

### Dependencies

```bash
sudo apt install parted dosfstools ntfs-3g wimtools rsync
```

### Usage

```bash
sudo bash multiboot-usb-creator.sh
```

### Author

**Jackson** — [@jackson-jpc](https://github.com/jackson-jpc)

### License

This project is distributed under the [MIT](LICENSE) license.
