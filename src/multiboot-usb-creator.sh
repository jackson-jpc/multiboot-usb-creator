#!/bin/bash
set -e

# === Constantes ===
MNT_SCAN="/tmp/win_scan"
MNT_ISO="/tmp/win_iso"
MNT_FAT="/tmp/win_fat"
MNT_NTFS="/tmp/win_ntfs"
MNT_PROBE="/tmp/win_probe"
TITULO="Pendrive Bootavel (BIOS + UEFI)"
LARGURA_BARRA=50
VERSION="1.1.0"
LOG_FILE="/tmp/multiboot-usb-creator.log"
WIMBOOT_URL="https://github.com/ipxe/wimboot/releases/latest/download/wimboot"
GRUB_I386_DIR="/usr/lib/grub/i386-pc"
GRUB_X64_EFI_DIR="/usr/lib/grub/x86_64-efi"

# Arrays para multi-boot
declare -a MB_ISOS=()
declare -a MB_ISO_NAMES=()
declare -a MB_ISO_TYPES=()
declare -a MB_ISO_SUBTYPES=()
MB_PRIMARY_WIN=""
MB_PRIMARY_WIN_NAME=""

# === Cores ===
VERDE="\e[32m"
VERMELHO="\e[31m"
AMARELO="\e[33m"
AZUL="\e[34m"
CIANO="\e[36m"
NEGRITO="\e[1m"
RESET="\e[0m"

# === Funcoes utilitarias ===
cleanup() {
    umount "$MNT_SCAN" 2>/dev/null || true
    umount "$MNT_ISO" 2>/dev/null || true
    umount "$MNT_FAT" 2>/dev/null || true
    umount "$MNT_NTFS" 2>/dev/null || true
    umount "$MNT_PROBE" 2>/dev/null || true
    rmdir "$MNT_SCAN" "$MNT_ISO" "$MNT_FAT" "$MNT_NTFS" "$MNT_PROBE" 2>/dev/null || true
}
trap cleanup EXIT

erro() {
    if usar_whiptail; then
        whiptail --title "Erro" --msgbox "$1" 10 60
    else
        echo -e "\n${NEGRITO}${VERMELHO} ERRO: $1${RESET}"
    fi
    exit 1
}

usar_whiptail() {
    command -v whiptail &>/dev/null
}

log() {
    local nivel="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$nivel] $msg" >> "$LOG_FILE"
}

barra_progresso() {
    local pct=$1
    local texto="$2"
    local preenchido=$((pct * LARGURA_BARRA / 100))
    local vazio=$((LARGURA_BARRA - preenchido))
    local barra=$(printf "%${preenchido}s" | tr ' ' '#')
    local espacos=$(printf "%${vazio}s" | tr ' ' '-')
    printf "\r  ${CIANO}[${VERDE}%s${CIANO}%s${CIANO}]${RESET} ${NEGRITO}%3d%%${RESET}  %s  " \
        "$barra" "$espacos" "$pct" "$texto"
}

etapa() {
    local num=$1
    local total=$2
    local desc="$3"
    local pct=$((num * 100 / total))
    echo ""
    barra_progresso "$pct" "[$num/$total] $desc"
    echo ""
}

copiar_com_progresso() {
    local origem="$1"
    local destino="$2"
    local titulo="$3"
    shift 3
    local extra_args=("$@")
    local inicio=$(date +%s)

    if usar_whiptail; then
        rsync -ah --info=progress2 --no-inc-recursive "${extra_args[@]}" \
            "$origem" "$destino" 2>&1 | \
        while IFS= read -r linha; do
            if [[ "$linha" =~ ([0-9,\.]+[KMGT]?i?B?)\s+([0-9]+)%\s+([0-9,\.]+[KMGT]?i?B/s)\s+([0-9:]+)\s+\(xfr#([0-9]+),\ to-chk=([0-9]+)/([0-9]+)\) ]]; then
                local transferido="${BASH_REMATCH[1]}"
                local pct="${BASH_REMATCH[2]}"
                local velocidade="${BASH_REMATCH[3]}"
                local eta="${BASH_REMATCH[4]}"
                local arq_feito="${BASH_REMATCH[5]}"
                local arq_falta="${BASH_REMATCH[6]}"
                local arq_total="${BASH_REMATCH[7]}"
                local agora=$(date +%s)
                local decorrido=$((agora - inicio))
                local min=$((decorrido / 60))
                local seg=$((decorrido % 60))
                local tempo_dec=$(printf "%02d:%02d" $min $seg)
                echo "XXX"
                echo "$pct"
                echo "$titulo"
                echo ""
                echo "  Transferido: $transferido  |  Velocidade: $velocidade"
                echo "  Arquivos:    $arq_feito / $arq_total"
                echo "  Tempo:       $tempo_dec  |  ETA: $eta"
                echo "XXX"
            elif [[ "$linha" =~ ([0-9,\.]+[KMGT]?i?B?)\s+([0-9]+)%\s+([0-9,\.]+[KMGT]?i?B/s)\s+([0-9:]+) ]]; then
                local transferido="${BASH_REMATCH[1]}"
                local pct="${BASH_REMATCH[2]}"
                local velocidade="${BASH_REMATCH[3]}"
                local eta="${BASH_REMATCH[4]}"
                local agora=$(date +%s)
                local decorrido=$((agora - inicio))
                local min=$((decorrido / 60))
                local seg=$((decorrido % 60))
                local tempo_dec=$(printf "%02d:%02d" $min $seg)
                echo "XXX"
                echo "$pct"
                echo "$titulo"
                echo ""
                echo "  Transferido: $transferido  |  Velocidade: $velocidade"
                echo "  Tempo:       $tempo_dec  |  ETA: $eta"
                echo "XXX"
            fi
        done | whiptail --title "$TITULO" --gauge "$titulo\n\n  Iniciando copia..." 10 70 0
    else
        echo ""
        rsync -ah --info=progress2 --no-inc-recursive "${extra_args[@]}" \
            "$origem" "$destino" 2>&1 | \
        while IFS= read -r linha; do
            if [[ "$linha" =~ ([0-9,\.]+[KMGT]?i?B?)\s+([0-9]+)%\s+([0-9,\.]+[KMGT]?i?B/s)\s+([0-9:]+) ]]; then
                local transferido="${BASH_REMATCH[1]}"
                local pct="${BASH_REMATCH[2]}"
                local velocidade="${BASH_REMATCH[3]}"
                local tempo="${BASH_REMATCH[4]}"
                local agora=$(date +%s)
                local decorrido=$((agora - inicio))
                local min=$((decorrido / 60))
                local seg=$((decorrido % 60))
                local tempo_dec=$(printf "%02d:%02d" $min $seg)
                barra_progresso "$pct" "${transferido} | ${velocidade} | ETA: ${tempo} | ${tempo_dec}"
            fi
        done
        echo ""
    fi
}

# ============================================================
# FUNCOES MULTI-BOOT
# ============================================================

verificar_deps_multiboot() {
    local faltando=()

    if [ ! -d "$GRUB_I386_DIR" ] || [ ! -f "$GRUB_I386_DIR/ntldr.mod" ]; then
        faltando+=("grub-pc-bin")
    fi

    if [ ! -d "$GRUB_X64_EFI_DIR" ] || [ ! -f "$GRUB_X64_EFI_DIR/normal.mod" ]; then
        faltando+=("grub-efi-amd64-bin")
    fi

    for cmd in grub-mkstandalone grub-install; do
        command -v "$cmd" &>/dev/null || faltando+=("grub-common")
    done

    if [ ${#faltando[@]} -gt 0 ]; then
        local msg="Dependencias faltando para modo MULTIBOOT:\n\n"
        for dep in "${faltando[@]}"; do
            msg+="  - $dep\n"
        done
        msg+="\nInstale com:\n  sudo apt install grub-pc-bin grub-efi-amd64-bin grub-common"
        erro "$msg"
    fi
    log "INFO" "Dependencias multiboot verificadas OK"
}

classificar_iso() {
    local iso="$1"
    local nome=$(basename "$iso")
    local tipo=""
    local subtipo=""

    mkdir -p "$MNT_PROBE"
    if ! mount -o loop,ro "$iso" "$MNT_PROBE" 2>/dev/null; then
        rmdir "$MNT_PROBE" 2>/dev/null || true
        echo "desconhecido|desconhecido"
        return
    fi

    if [ -f "$MNT_PROBE/sources/boot.wim" ] || [ -f "$MNT_PROBE/sources/install.wim" ] || \
       [ -f "$MNT_PROBE/sources/install.esd" ]; then
        tipo="windows"
        local ver=$(detectar_versao_windows "$MNT_PROBE")
        case "$ver" in
            *"Windows 7"*)  subtipo="win7" ;;
            *"Windows 10"*) subtipo="win10" ;;
            *"Windows 11"*) subtipo="win11" ;;
            *"Windows 8"*|*"8.1"*) subtipo="win8" ;;
            *) subtipo="windows" ;;
        esac
    elif [ -d "$MNT_PROBE/casper" ]; then
        tipo="linux"
        local info=""
        [ -f "$MNT_PROBE/.disk/info" ] && info=$(cat "$MNT_PROBE/.disk/info" 2>/dev/null)
        if echo "$info" | grep -qi "ubuntu.*server"; then
            subtipo="ubuntu-server"
        elif echo "$info" | grep -qi "ubuntu"; then
            subtipo="ubuntu-desktop"
        elif echo "$nome" | grep -qi "linux.lite\|linuxlite"; then
            subtipo="linuxlite"
        else
            subtipo="ubuntu-like"
        fi
    elif [ -d "$MNT_PROBE/install.amd" ] || [ -d "$MNT_PROBE/install" ]; then
        tipo="linux"
        subtipo="debian"
    elif [ -d "$MNT_PROBE/isolinux" ] || [ -d "$MNT_PROBE/boot/grub" ]; then
        tipo="linux"
        subtipo="generic-linux"
    else
        tipo="desconhecido"
        subtipo="desconhecido"
    fi

    umount "$MNT_PROBE" 2>/dev/null || true
    rmdir "$MNT_PROBE" 2>/dev/null || true
    echo "${tipo}|${subtipo}"
}

probar_linux_iso() {
    local iso="$1"
    local subtipo="$2"
    local kernel="" initrd="" boot_opts="" has_loopback="no"

    mkdir -p "$MNT_PROBE"
    mount -o loop,ro "$iso" "$MNT_PROBE" 2>/dev/null || { echo "ERRO"; return; }

    case "$subtipo" in
        ubuntu-server|ubuntu-desktop|ubuntu-like)
            [ -f "$MNT_PROBE/casper/vmlinuz" ] && kernel="/casper/vmlinuz"
            [ -f "$MNT_PROBE/casper/vmlinuz.efi" ] && kernel="/casper/vmlinuz.efi"
            for f in initrd initrd.gz initrd.lz; do
                [ -f "$MNT_PROBE/casper/$f" ] && initrd="/casper/$f" && break
            done
            boot_opts="boot=casper quiet splash ---"
            ;;
        linuxlite)
            [ -f "$MNT_PROBE/casper/vmlinuz" ] && kernel="/casper/vmlinuz"
            for f in initrd.lz initrd.gz initrd; do
                [ -f "$MNT_PROBE/casper/$f" ] && initrd="/casper/$f" && break
            done
            boot_opts="boot=casper quiet splash ---"
            ;;
        debian)
            if [ -f "$MNT_PROBE/install.amd/vmlinuz" ]; then
                kernel="/install.amd/vmlinuz"
                initrd="/install.amd/initrd.gz"
            elif [ -f "$MNT_PROBE/install/vmlinuz" ]; then
                kernel="/install/vmlinuz"
                initrd="/install/initrd.gz"
            fi
            boot_opts="vga=788 quiet ---"
            ;;
        generic-linux)
            for kpath in /casper/vmlinuz /live/vmlinuz /boot/vmlinuz /isolinux/vmlinuz; do
                [ -f "$MNT_PROBE$kpath" ] && kernel="$kpath" && break
            done
            for ipath in /casper/initrd /casper/initrd.gz /live/initrd.img /boot/initrd.gz; do
                [ -f "$MNT_PROBE$ipath" ] && initrd="$ipath" && break
            done
            boot_opts="quiet ---"
            ;;
    esac

    [ -f "$MNT_PROBE/boot/grub/loopback.cfg" ] && has_loopback="yes"

    umount "$MNT_PROBE" 2>/dev/null || true
    rmdir "$MNT_PROBE" 2>/dev/null || true
    echo "${kernel}|${initrd}|${boot_opts}|${has_loopback}"
}

selecionar_isos_multiboot() {
    local search_dirs=("$SCRIPT_DIR")
    local parent_dir="$(dirname "$SCRIPT_DIR")"
    [ "$parent_dir" != "$SCRIPT_DIR" ] && search_dirs+=("$parent_dir")

    local -a iso_paths=()
    local -a iso_list=()

    for dir in "${search_dirs[@]}"; do
        while IFS= read -r arquivo; do
            [ -z "$arquivo" ] && continue
            local dup=false
            for existing in "${iso_paths[@]}"; do
                [ "$existing" = "$arquivo" ] && { dup=true; break; }
            done
            $dup && continue
            local nome=$(basename "$arquivo")
            local tamanho=$(du -h "$arquivo" 2>/dev/null | cut -f1)
            iso_paths+=("$arquivo")
            iso_list+=("$arquivo" "${nome} (${tamanho})" "OFF")
        done < <(find "$dir" -maxdepth 1 -iname "*.iso" -type f 2>/dev/null | sort)
    done

    [ ${#iso_list[@]} -eq 0 ] && erro "Nenhuma ISO encontrada."

    if usar_whiptail; then
        local selecionadas
        selecionadas=$(whiptail --title "$TITULO - Multi-Boot" \
            --checklist "Selecione as ISOs para o pendrive multi-boot:\n(Use ESPACO para selecionar, ENTER para confirmar)" \
            22 85 10 \
            "${iso_list[@]}" \
            3>&1 1>&2 2>&3) || exit 1
        eval "MB_ISOS=($selecionadas)"
    else
        echo ""
        echo -e "${NEGRITO}ISOs disponiveis:${RESET}"
        echo ""
        for ((i=0; i<${#iso_paths[@]}; i++)); do
            local nome=$(basename "${iso_paths[$i]}")
            local tamanho=$(du -h "${iso_paths[$i]}" 2>/dev/null | cut -f1)
            echo -e "  ${VERDE}[$((i+1))]${RESET} $nome (${tamanho})"
        done
        echo ""
        echo -e "Digite os numeros separados por espaco (ex: 1 3 5):"
        read -p "> " escolhas
        for num in $escolhas; do
            local idx=$((num - 1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#iso_paths[@]} ]; then
                MB_ISOS+=("${iso_paths[$idx]}")
            fi
        done
    fi

    [ ${#MB_ISOS[@]} -eq 0 ] && erro "Nenhuma ISO selecionada."

    # Classificar cada ISO
    log "INFO" "Classificando ${#MB_ISOS[@]} ISOs..."
    for iso in "${MB_ISOS[@]}"; do
        if usar_whiptail; then
            whiptail --title "$TITULO" --infobox "Analisando: $(basename "$iso")..." 5 60
        else
            echo -e "  Analisando: $(basename "$iso")..."
        fi
        local result=$(classificar_iso "$iso")
        local tipo="${result%%|*}"
        local subtipo="${result##*|}"
        MB_ISO_NAMES+=("$(basename "$iso")")
        MB_ISO_TYPES+=("$tipo")
        MB_ISO_SUBTYPES+=("$subtipo")
        log "INFO" "  $(basename "$iso"): tipo=$tipo subtipo=$subtipo"
    done
}

selecionar_windows_primario() {
    local -a win_indices=()

    for ((i=0; i<${#MB_ISO_TYPES[@]}; i++)); do
        [ "${MB_ISO_TYPES[$i]}" = "windows" ] && win_indices+=("$i")
    done

    if [ ${#win_indices[@]} -eq 0 ]; then
        MB_PRIMARY_WIN=""
        return
    fi

    if [ ${#win_indices[@]} -eq 1 ]; then
        local idx=${win_indices[0]}
        MB_PRIMARY_WIN="${MB_ISOS[$idx]}"
        MB_PRIMARY_WIN_NAME="${MB_ISO_NAMES[$idx]}"
        log "INFO" "Windows primario (unico): $MB_PRIMARY_WIN_NAME"
        return
    fi

    if usar_whiptail; then
        local -a menu_items=()
        for idx in "${win_indices[@]}"; do
            local nome="${MB_ISO_NAMES[$idx]}"
            local sub="${MB_ISO_SUBTYPES[$idx]}"
            local tamanho=$(du -h "${MB_ISOS[$idx]}" 2>/dev/null | cut -f1)
            menu_items+=("$idx" "${nome} [${sub}] (${tamanho})")
        done

        local escolha
        escolha=$(whiptail --title "$TITULO - Windows Primario" \
            --menu "Qual Windows sera PRIMARIO (extraido)?\n\nO primario tera boot Legacy BIOS + UEFI.\nOs demais serao via wimboot (somente BIOS)." \
            18 78 6 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3) || exit 1

        MB_PRIMARY_WIN="${MB_ISOS[$escolha]}"
        MB_PRIMARY_WIN_NAME="${MB_ISO_NAMES[$escolha]}"
    else
        echo ""
        echo -e "${NEGRITO}Selecione o Windows PRIMARIO (extraido, BIOS+UEFI):${RESET}"
        echo -e "${AMARELO}Os demais Windows usarao wimboot (somente BIOS).${RESET}"
        echo ""
        for idx in "${win_indices[@]}"; do
            echo -e "  ${VERDE}[$((idx+1))]${RESET} ${MB_ISO_NAMES[$idx]} [${MB_ISO_SUBTYPES[$idx]}]"
        done
        echo ""
        read -p "Numero: " escolha
        local real_idx=$((escolha - 1))
        MB_PRIMARY_WIN="${MB_ISOS[$real_idx]}"
        MB_PRIMARY_WIN_NAME="${MB_ISO_NAMES[$real_idx]}"
    fi
    log "INFO" "Windows primario: $MB_PRIMARY_WIN_NAME"
}

calcular_espaco_multiboot() {
    local dev="$1"
    local total_bytes=0
    local detalhes=""

    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        local iso="${MB_ISOS[$i]}"
        local size=$(stat -c%s "$iso" 2>/dev/null || echo 0)
        local size_h=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "${size}B")

        if [ "$iso" = "$MB_PRIMARY_WIN" ]; then
            detalhes+="  [PRIMARIO] ${MB_ISO_NAMES[$i]}: ${size_h}\n"
            total_bytes=$((total_bytes + size))
        elif [ "${MB_ISO_TYPES[$i]}" = "windows" ]; then
            # Wimboot files only (~400MB)
            detalhes+="  [WIMBOOT]  ${MB_ISO_NAMES[$i]}: ~400MiB (boot files)\n"
            total_bytes=$((total_bytes + 419430400))
        else
            detalhes+="  [ISO]      ${MB_ISO_NAMES[$i]}: ${size_h}\n"
            total_bytes=$((total_bytes + size))
        fi
    done

    total_bytes=$((total_bytes + 52428800))  # +50MB GRUB2/wimboot overhead
    local total_h=$(numfmt --to=iec-i --suffix=B "$total_bytes" 2>/dev/null || echo "${total_bytes}B")
    local dev_bytes=$(blockdev --getsize64 "$dev" 2>/dev/null || echo 0)
    local dev_h=$(numfmt --to=iec-i --suffix=B "$dev_bytes" 2>/dev/null || echo "${dev_bytes}B")

    detalhes+="  GRUB2 + wimboot: ~50MiB\n"
    detalhes+="\n  Total estimado: ${total_h}\n"
    detalhes+="  Pendrive:       ${dev_h}\n"

    if [ "$total_bytes" -gt "$dev_bytes" ]; then
        erro "Espaco insuficiente!\n\n${detalhes}\nAs ISOs selecionadas nao cabem no pendrive."
    fi
    echo -e "$detalhes"
}

instalar_grub2_multiboot() {
    local dev="$1"
    local mnt_fat="$2"

    log "INFO" "Instalando GRUB2 Legacy BIOS em $dev"
    grub-install \
        --target=i386-pc \
        --boot-directory="$mnt_fat/boot" \
        --recheck \
        --force \
        "$dev" >> "$LOG_FILE" 2>&1

    log "INFO" "Criando GRUB2 EFI standalone"
    mkdir -p "$mnt_fat/EFI/BOOT"

    local early_cfg=$(mktemp /tmp/grub_early.XXXXXX)
    local part_uuid=$(blkid -o value -s UUID "${dev}1")
    cat > "$early_cfg" << EARLYEOF
search.fs_uuid ${part_uuid} root
set prefix=(\$root)/boot/grub
configfile \$prefix/grub.cfg
EARLYEOF

    grub-mkstandalone \
        --format=x86_64-efi \
        --output="$mnt_fat/EFI/BOOT/bootx64.efi" \
        --locales="" \
        --fonts="" \
        --themes="" \
        --modules="part_msdos part_gpt fat iso9660 udf loopback chain normal configfile linux search search_fs_uuid search_fs_file search_label ntfs" \
        "boot/grub/grub.cfg=$early_cfg" >> "$LOG_FILE" 2>&1

    rm -f "$early_cfg"
    touch "$mnt_fat/boot/grub/.multiboot_marker"
    log "INFO" "GRUB2 instalado (BIOS + UEFI)"
}

gerar_grub_cfg() {
    local mnt_fat="$1"
    local cfg_file="$mnt_fat/boot/grub/grub.cfg"

    cat > "$cfg_file" << 'GRUBHEADER'
# grub.cfg - Gerado por multiboot-usb-creator
insmod part_msdos
insmod part_gpt
insmod fat
insmod ntfs
insmod iso9660
insmod udf
insmod loopback
insmod chain
insmod ntldr
insmod linux
insmod normal
insmod search
insmod configfile
insmod all_video
insmod echo

set timeout=30
set default=0

if [ "${grub_platform}" == "efi" ]; then
    insmod efi_gop
    insmod efi_uga
    set BOOT_MODE="UEFI"
else
    insmod vbe
    insmod vga
    set BOOT_MODE="BIOS Legacy"
fi

set color_normal=white/black
set color_highlight=black/white
set menu_color_normal=white/black
set menu_color_highlight=black/white

probe -u $root --set=rootuuid
set imgdevpath="/dev/disk/by-uuid/$rootuuid"
export imgdevpath rootuuid

GRUBHEADER

    # Windows primario
    if [ -n "$MB_PRIMARY_WIN" ]; then
        local win_ver=""
        for ((i=0; i<${#MB_ISOS[@]}; i++)); do
            [ "${MB_ISOS[$i]}" = "$MB_PRIMARY_WIN" ] && { win_ver="${MB_ISO_SUBTYPES[$i]}"; break; }
        done
        local win_label=$(echo "$MB_PRIMARY_WIN_NAME" | sed 's/\.iso$//')

        cat >> "$cfg_file" << WINEOF

# === WINDOWS PRIMARIO: $MB_PRIMARY_WIN_NAME ===
if [ "\${grub_platform}" == "pc" ]; then
    menuentry ">>> $win_label [BIOS] - Instalador" {
        insmod ntldr
        ntldr /bootmgr
    }
fi

if [ "\${grub_platform}" == "efi" ]; then
    menuentry ">>> $win_label [UEFI] - Instalador" {
        insmod chain
        chainloader /efi/microsoft/boot/bootmgfw.efi
    }
fi
WINEOF
    fi

    # Windows secundarios via wimboot
    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        [ "${MB_ISO_TYPES[$i]}" != "windows" ] && continue
        [ "${MB_ISOS[$i]}" = "$MB_PRIMARY_WIN" ] && continue

        local iso_name="${MB_ISO_NAMES[$i]}"
        local win_label=$(echo "$iso_name" | sed 's/\.iso$//')
        local safe_name=$(echo "$iso_name" | tr ' .' '__' | tr -cd 'a-zA-Z0-9_-')

        cat >> "$cfg_file" << WIMEOF

# Windows secundario: $iso_name (wimboot)
if [ "\${grub_platform}" == "pc" ]; then
    menuentry "    $win_label [BIOS - wimboot]" {
        linux16 /boot/wimboot
        initrd16 \\
            newc:bootmgr:/boot/multiboot/${safe_name}/bootmgr \\
            newc:bcd:/boot/multiboot/${safe_name}/BCD \\
            newc:boot.sdi:/boot/multiboot/${safe_name}/boot.sdi \\
            newc:boot.wim:/boot/multiboot/${safe_name}/boot.wim
    }
fi
WIMEOF
    done

    # Linux ISOs via loopback
    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        [ "${MB_ISO_TYPES[$i]}" != "linux" ] && continue

        local iso_name="${MB_ISO_NAMES[$i]}"
        local iso_path="/iso/${iso_name}"
        local subtipo="${MB_ISO_SUBTYPES[$i]}"
        local linux_label=$(echo "$iso_name" | sed 's/\.iso$//')

        local probe_result=$(probar_linux_iso "${MB_ISOS[$i]}" "$subtipo")
        local kernel=$(echo "$probe_result" | cut -d'|' -f1)
        local initrd_val=$(echo "$probe_result" | cut -d'|' -f2)
        local boot_opts=$(echo "$probe_result" | cut -d'|' -f3)
        local has_loopback=$(echo "$probe_result" | cut -d'|' -f4)

        if [ "$has_loopback" = "yes" ]; then
            cat >> "$cfg_file" << LOOPEOF

# Linux: $iso_name (loopback.cfg)
menuentry "    $linux_label [BIOS+UEFI]" {
    set iso_path="$iso_path"
    export iso_path
    loopback loop \$iso_path
    set root=(loop)
    configfile /boot/grub/loopback.cfg
    loopback --delete loop
}
LOOPEOF
        elif [ -n "$kernel" ] && [ -n "$initrd_val" ]; then
            cat >> "$cfg_file" << LINEOF

# Linux: $iso_name
menuentry "    $linux_label [BIOS+UEFI]" {
    set iso_path="$iso_path"
    export iso_path
    loopback loop \$iso_path
    linux (loop)${kernel} iso-scan/filename=\$iso_path ${boot_opts}
    initrd (loop)${initrd_val}
}
LINEOF
        else
            log "WARN" "Kernel/initrd nao detectados para $iso_name"
            cat >> "$cfg_file" << FALLEOF

# Linux: $iso_name (deteccao automatica falhou)
menuentry "    $linux_label [PODE PRECISAR AJUSTE]" {
    set iso_path="$iso_path"
    export iso_path
    loopback loop \$iso_path
    echo "Kernel/initrd nao detectados automaticamente."
    echo "Edite /boot/grub/grub.cfg no pendrive."
    echo "Pressione qualquer tecla..."
    sleep --interruptible 9999
}
FALLEOF
        fi
    done

    # Boot local + reiniciar + desligar
    cat >> "$cfg_file" << 'LOCALEOF'

# === UTILIDADES ===
menuentry "--- Boot do disco local (HD/SSD) ---" {
    if [ "${grub_platform}" == "pc" ]; then
        set root=(hd1)
        chainloader +1
    else
        exit
    fi
}

menuentry "--- Reiniciar ---" {
    reboot
}

menuentry "--- Desligar ---" {
    halt
}
LOCALEOF

    local num_entries=$(grep -c 'menuentry' "$cfg_file")
    log "INFO" "grub.cfg gerado com $num_entries entradas"
}

extrair_wimboot_files() {
    local iso="$1"
    local safe_name="$2"
    local mnt_fat="$3"
    local dest_dir="$mnt_fat/boot/multiboot/${safe_name}"

    mkdir -p "$dest_dir" "$MNT_PROBE"
    mount -o loop,ro "$iso" "$MNT_PROBE" 2>/dev/null || return 1

    [ -f "$MNT_PROBE/sources/boot.wim" ] && cp "$MNT_PROBE/sources/boot.wim" "$dest_dir/"
    [ -f "$MNT_PROBE/bootmgr" ] && cp "$MNT_PROBE/bootmgr" "$dest_dir/"

    # BCD (case insensitive paths)
    for bcd_path in boot/bcd boot/BCD Boot/BCD Boot/bcd; do
        if [ -f "$MNT_PROBE/$bcd_path" ]; then
            cp "$MNT_PROBE/$bcd_path" "$dest_dir/BCD"
            break
        fi
    done

    # boot.sdi
    for sdi_path in boot/boot.sdi Boot/boot.sdi; do
        if [ -f "$MNT_PROBE/$sdi_path" ]; then
            cp "$MNT_PROBE/$sdi_path" "$dest_dir/boot.sdi"
            break
        fi
    done

    umount "$MNT_PROBE" 2>/dev/null || true
    rmdir "$MNT_PROBE" 2>/dev/null || true
    log "INFO" "Wimboot files extraidos para $dest_dir"
}

obter_wimboot() {
    local mnt_fat="$1"
    local wimboot_dest="$mnt_fat/boot/wimboot"

    local script_wimboot="$SCRIPT_DIR/assets/wimboot"
    if [ -f "$script_wimboot" ]; then
        cp "$script_wimboot" "$wimboot_dest"
        log "INFO" "wimboot copiado de assets/"
        return 0
    fi

    if command -v wget &>/dev/null; then
        log "INFO" "Baixando wimboot..."
        wget -q -O "$wimboot_dest" "$WIMBOOT_URL" 2>/dev/null && return 0
    elif command -v curl &>/dev/null; then
        log "INFO" "Baixando wimboot..."
        curl -sL -o "$wimboot_dest" "$WIMBOOT_URL" 2>/dev/null && return 0
    fi

    log "WARN" "Nao foi possivel obter wimboot"
    return 1
}

# === Detectar velocidade USB ===
detectar_velocidade_usb() {
    local dev="$1"
    local dev_name=$(basename "$dev")
    local speed=""

    # Procurar no sysfs
    for usb_dev in /sys/bus/usb/devices/[0-9]*; do
        [ -d "$usb_dev" ] || continue
        if find "$usb_dev" -name "$dev_name" -type d 2>/dev/null | grep -q .; then
            speed=$(cat "$usb_dev/speed" 2>/dev/null || echo "")
            break
        fi
    done

    if [ -n "$speed" ]; then
        case "$speed" in
            12)    echo "USB 1.1 (12 Mbps)" ;;
            480)   echo "USB 2.0 (480 Mbps)" ;;
            5000)  echo "USB 3.0 (5 Gbps)" ;;
            10000) echo "USB 3.1 (10 Gbps)" ;;
            20000) echo "USB 3.2 (20 Gbps)" ;;
            *)     echo "USB ($speed Mbps)" ;;
        esac
    else
        echo "Desconhecida"
    fi
}

# === Verificar checksum de ISO ===
verificar_checksum_iso() {
    local iso="$1"
    local sha_file=""

    # Procurar arquivo .sha256 correspondente
    for ext in sha256 sha256sum SHA256 SHA256SUM; do
        if [ -f "${iso}.${ext}" ]; then
            sha_file="${iso}.${ext}"
            break
        fi
    done

    # Procurar arquivo SHA256SUMS no mesmo diretorio
    if [ -z "$sha_file" ] && [ -f "$(dirname "$iso")/SHA256SUMS" ]; then
        sha_file="$(dirname "$iso")/SHA256SUMS"
    fi

    if [ -z "$sha_file" ]; then
        echo "SEM_CHECKSUM"
        return
    fi

    local iso_nome=$(basename "$iso")
    local hash_esperado=$(grep -i "$iso_nome" "$sha_file" 2>/dev/null | awk '{print $1}' | head -1)

    if [ -z "$hash_esperado" ]; then
        echo "SEM_CHECKSUM"
        return
    fi

    local hash_real=$(sha256sum "$iso" 2>/dev/null | awk '{print $1}')

    if [ "$hash_real" = "$hash_esperado" ]; then
        echo "OK"
    else
        echo "FALHOU|$hash_esperado|$hash_real"
    fi
}

# === Split WIM com progresso real ===
split_wim_com_progresso() {
    local wim_file="$1"
    local destino="$2"
    local etapa_num="$3"
    local total_etapas="$4"
    local wim_size=$(stat -c%s "$wim_file" 2>/dev/null || echo 0)
    local wim_nome=$(basename "$wim_file")
    local dest_dir=$(dirname "$destino")

    log "INFO" "Iniciando split de $wim_nome ($wim_size bytes)"

    # Executar wimlib-imagex split em background
    wimlib-imagex split "$wim_file" "$destino" 3800 >/dev/null 2>&1 &
    local pid=$!

    if usar_whiptail; then
        (
            while kill -0 "$pid" 2>/dev/null; do
                # Calcular tamanho total dos arquivos .swm ja criados
                local total_escrito=0
                for swm in "$dest_dir"/install*.swm; do
                    [ -f "$swm" ] || continue
                    local sz=$(stat -c%s "$swm" 2>/dev/null || echo 0)
                    total_escrito=$((total_escrito + sz))
                done

                local pct=0
                if [ "$wim_size" -gt 0 ]; then
                    pct=$((total_escrito * 100 / wim_size))
                    [ "$pct" -gt 99 ] && pct=99
                fi

                local escrito_h=$(numfmt --to=iec-i --suffix=B "$total_escrito" 2>/dev/null || echo "${total_escrito}B")
                local total_h=$(numfmt --to=iec-i --suffix=B "$wim_size" 2>/dev/null || echo "${wim_size}B")
                local num_swm=$(ls "$dest_dir"/install*.swm 2>/dev/null | wc -l)

                echo "XXX"
                echo "$pct"
                echo "[$etapa_num/$total_etapas] Dividindo $wim_nome..."
                echo ""
                echo "  Progresso:   $escrito_h / $total_h"
                echo "  Partes:      $num_swm arquivo(s) .swm criados"
                echo "XXX"
                sleep 2
            done
            wait "$pid" 2>/dev/null
            echo "XXX"
            echo 100
            echo "[$etapa_num/$total_etapas] $wim_nome dividido com sucesso!"
            echo "XXX"
        ) | whiptail --title "$TITULO" --gauge \
            "[$etapa_num/$total_etapas] Dividindo $wim_nome..." 10 70 0
    else
        echo ""
        while kill -0 "$pid" 2>/dev/null; do
            local total_escrito=0
            for swm in "$dest_dir"/install*.swm; do
                [ -f "$swm" ] || continue
                local sz=$(stat -c%s "$swm" 2>/dev/null || echo 0)
                total_escrito=$((total_escrito + sz))
            done

            local pct=0
            if [ "$wim_size" -gt 0 ]; then
                pct=$((total_escrito * 100 / wim_size))
                [ "$pct" -gt 99 ] && pct=99
            fi

            local escrito_h=$(numfmt --to=iec-i --suffix=B "$total_escrito" 2>/dev/null || echo "${total_escrito}B")
            local total_h=$(numfmt --to=iec-i --suffix=B "$wim_size" 2>/dev/null || echo "${wim_size}B")

            barra_progresso "$pct" "Split: $escrito_h / $total_h"
            sleep 2
        done
        wait "$pid" 2>/dev/null
        barra_progresso 100 "$wim_nome dividido!"
        echo ""
    fi

    wait "$pid" 2>/dev/null
    local exit_code=$?
    log "INFO" "Split concluido com exit code: $exit_code"
    return $exit_code
}

PENDRIVES_ARRAY=()
detectar_pendrives() {
    PENDRIVES_ARRAY=()
    while IFS= read -r disco; do
        local dev="/dev/$disco"
        local tamanho=$(lsblk -dno SIZE "$dev" 2>/dev/null | xargs)
        local modelo=$(lsblk -dno MODEL "$dev" 2>/dev/null | xargs)
        local tran=$(lsblk -dno TRAN "$dev" 2>/dev/null | xargs)
        if [ "$tran" = "usb" ]; then
            PENDRIVES_ARRAY+=("$dev" "${tamanho} - ${modelo}")
        fi
    done < <(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1}')
}

# Detecta versao do Windows a partir dos arquivos do pendrive
# Uso: detectar_versao_windows <ponto_de_montagem>
detectar_versao_windows() {
    local mnt="$1"
    local versao="Desconhecida"
    local build=""

    # Tentar via wimlib (mais confiavel)
    if command -v wimlib-imagex &>/dev/null; then
        local wim=""
        if [ -f "$mnt/sources/install.wim" ]; then
            wim="$mnt/sources/install.wim"
        elif [ -f "$mnt/sources/install.esd" ]; then
            wim="$mnt/sources/install.esd"
        elif ls "$mnt/sources/install"*.swm &>/dev/null 2>&1; then
            wim=$(ls "$mnt/sources/install"*.swm 2>/dev/null | head -1)
        fi

        if [ -n "$wim" ]; then
            local info=$(wimlib-imagex info "$wim" 1 2>/dev/null || true)
            if [ -n "$info" ]; then
                local desc=$(echo "$info" | grep -i "^Description:" | head -1 | sed 's/Description:\s*//')
                build=$(echo "$info" | grep -i "^Build:" | head -1 | sed 's/Build:\s*//' | xargs)

                if echo "$desc" | grep -qi "Windows 11"; then
                    versao="Windows 11"
                elif echo "$desc" | grep -qi "Windows 10"; then
                    versao="Windows 10"
                elif echo "$desc" | grep -qi "Windows 8.1"; then
                    versao="Windows 8.1"
                elif echo "$desc" | grep -qi "Windows 8"; then
                    versao="Windows 8"
                elif echo "$desc" | grep -qi "Windows 7"; then
                    versao="Windows 7"
                elif [ -n "$desc" ]; then
                    versao="$desc"
                fi
            fi
        fi
    fi

    # Fallback: verificar por arquivos conhecidos
    if [ "$versao" = "Desconhecida" ]; then
        if [ -f "$mnt/sources/install.wim" ] || [ -f "$mnt/sources/install.esd" ]; then
            # Tentar inferir pela presenca de arquivos EFI
            if [ -f "$mnt/efi/boot/bootx64.efi" ]; then
                versao="Windows 8/10/11 (UEFI detectado)"
            else
                versao="Windows 7 ou anterior"
            fi
        fi
    fi

    if [ -n "$build" ]; then
        echo "$versao (Build $build)"
    else
        echo "$versao"
    fi
}

# Lista edicoes disponiveis no WIM
listar_edicoes_wim() {
    local mnt="$1"
    local wim=""

    if [ -f "$mnt/sources/install.wim" ]; then
        wim="$mnt/sources/install.wim"
    elif [ -f "$mnt/sources/install.esd" ]; then
        wim="$mnt/sources/install.esd"
    elif ls "$mnt/sources/install"*.swm &>/dev/null 2>&1; then
        wim=$(ls "$mnt/sources/install"*.swm 2>/dev/null | head -1)
    fi

    if [ -n "$wim" ] && command -v wimlib-imagex &>/dev/null; then
        local num_images=$(wimlib-imagex info "$wim" 2>/dev/null | grep "^Image Count:" | sed 's/Image Count:\s*//' | xargs)
        if [ -n "$num_images" ] && [ "$num_images" -gt 0 ]; then
            for ((idx=1; idx<=num_images; idx++)); do
                local nome=$(wimlib-imagex info "$wim" "$idx" 2>/dev/null | grep "^Name:" | sed 's/Name:\s*//')
                echo "    $idx. $nome"
            done
        fi
    fi
}

# ============================================================
# Funcao: Validar/Verificar pendrive existente
# ============================================================
verificar_pendrive() {
    set +e  # desativar set -e (verificacao precisa tolerar falhas)
    local dev="$1"
    local erros=0
    local relatorio=""

    val() {
        local desc="$1"
        local resultado="$2"
        if [ "$resultado" = "OK" ]; then
            relatorio+="  ${VERDE}[OK]${RESET}    $desc\n"
        else
            relatorio+="  ${VERMELHO}[FALHA]${RESET} $desc — $resultado\n"
            erros=$((erros + 1))
        fi
    }

    # Montar particoes para verificacao
    local part1="${dev}1"
    local part2="${dev}2"
    local mnt1="/tmp/win_check_p1"
    local mnt2="/tmp/win_check_p2"

    mkdir -p "$mnt1" "$mnt2"

    # --- Verificar tabela de particao ---
    local pttype=$(blkid -o value -s PTTYPE "$dev" 2>/dev/null || echo "")
    if [ "$pttype" = "gpt" ]; then
        val "Tabela de particao GPT" "OK"
    elif [ "$pttype" = "dos" ]; then
        val "Tabela de particao" "MBR (funciona, mas GPT e recomendado para UEFI)"
    else
        val "Tabela de particao" "Tipo: ${pttype:-nao detectado}"
    fi

    # --- Verificar particoes ---
    local num_parts=$(lsblk -no NAME "$dev" 2>/dev/null | grep -c "^" || echo 0)
    local tem_fat=false
    local tem_ntfs=false
    local mnt_principal=""

    # Detectar tipos de filesystem nas particoes
    for part in ${dev}1 ${dev}2 ${dev}3; do
        [ -b "$part" ] || continue
        local fs=$(blkid -o value -s TYPE "$part" 2>/dev/null || echo "")
        case "$fs" in
            vfat) tem_fat=true ;;
            ntfs) tem_ntfs=true ;;
        esac
    done

    # Montar a primeira particao encontrada para analise
    local montou_p1=false
    local montou_p2=false

    if [ -b "$part1" ]; then
        local fs1=$(blkid -o value -s TYPE "$part1" 2>/dev/null || echo "")
        val "Particao 1 ($fs1)" "OK"
        umount "$part1" 2>/dev/null || true
        if mount -o ro "$part1" "$mnt1" 2>/dev/null; then
            montou_p1=true
        fi
    fi

    if [ -b "$part2" ]; then
        local fs2=$(blkid -o value -s TYPE "$part2" 2>/dev/null || echo "")
        val "Particao 2 ($fs2)" "OK"
        umount "$part2" 2>/dev/null || true
        if mount -o ro "$part2" "$mnt2" 2>/dev/null; then
            montou_p2=true
        fi
    fi

    # Determinar qual particao tem os arquivos do Windows
    local mnt_boot="" mnt_dados=""
    if [ "$montou_p1" = true ] && [ -d "$mnt1/sources" ]; then
        mnt_dados="$mnt1"
        mnt_boot="$mnt1"
    fi
    if [ "$montou_p2" = true ] && [ -d "$mnt2/sources" ]; then
        mnt_dados="$mnt2"
    fi
    if [ "$montou_p1" = true ] && [ -d "$mnt1/efi" ]; then
        mnt_boot="$mnt1"
    fi
    # Se so tem uma particao com tudo
    if [ -z "$mnt_boot" ] && [ "$montou_p1" = true ]; then
        mnt_boot="$mnt1"
    fi

    # --- Detectar versao do Windows ---
    local versao="Nao detectada"
    local edicoes=""
    if [ -n "$mnt_dados" ]; then
        versao=$(detectar_versao_windows "$mnt_dados")
        edicoes=$(listar_edicoes_wim "$mnt_dados")
    elif [ -n "$mnt_boot" ]; then
        versao=$(detectar_versao_windows "$mnt_boot")
        edicoes=$(listar_edicoes_wim "$mnt_boot")
    fi

    # --- Verificar arquivos de boot ---
    local algum_mnt=""
    for m in "$mnt_boot" "$mnt_dados" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && [ -d "$m" ] && { algum_mnt="$m"; break; }
    done

    # Boot EFI
    local efi_ok=false
    for m in "$mnt_boot" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && [ -f "$m/efi/boot/bootx64.efi" ] && { efi_ok=true; break; }
    done
    if [ "$efi_ok" = true ]; then
        val "Boot UEFI (bootx64.efi)" "OK"
    else
        val "Boot UEFI (bootx64.efi)" "Nao encontrado — boot UEFI pode falhar"
    fi

    # Boot Manager (Legacy)
    local bootmgr_ok=false
    for m in "$mnt_boot" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && { [ -f "$m/bootmgr" ] || [ -f "$m/bootmgr.efi" ]; } && { bootmgr_ok=true; break; }
    done
    if [ "$bootmgr_ok" = true ]; then
        val "Boot Manager (Legacy BIOS)" "OK"
    else
        val "Boot Manager (Legacy BIOS)" "bootmgr nao encontrado"
    fi

    # BCD Legacy
    local bcd_legacy=false
    for m in "$mnt_boot" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && { [ -f "$m/boot/bcd" ] || [ -f "$m/boot/BCD" ]; } && { bcd_legacy=true; break; }
    done
    if [ "$bcd_legacy" = true ]; then
        val "BCD (Legacy boot config)" "OK"
    else
        val "BCD (Legacy boot config)" "Nao encontrado"
    fi

    # BCD EFI
    local bcd_efi=false
    for m in "$mnt_boot" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && { [ -f "$m/efi/microsoft/boot/bcd" ] || [ -f "$m/efi/microsoft/boot/BCD" ]; } && { bcd_efi=true; break; }
    done
    if [ "$bcd_efi" = true ]; then
        val "BCD EFI (UEFI boot config)" "OK"
    else
        val "BCD EFI (UEFI boot config)" "Nao encontrado"
    fi

    # boot.wim
    local bootwim_ok=false
    for m in "$mnt_boot" "$mnt_dados" "$mnt1" "$mnt2"; do
        [ -n "$m" ] && [ -f "$m/sources/boot.wim" ] && { bootwim_ok=true; break; }
    done
    if [ "$bootwim_ok" = true ]; then
        val "boot.wim (instalador)" "OK"
    else
        val "boot.wim (instalador)" "Nao encontrado"
    fi

    # install.wim / install.esd / install.swm
    local install_ok=false
    local install_tipo=""
    for m in "$mnt_dados" "$mnt_boot" "$mnt1" "$mnt2"; do
        if [ -n "$m" ]; then
            if [ -f "$m/sources/install.wim" ]; then
                install_ok=true
                local sz=$(du -h "$m/sources/install.wim" 2>/dev/null | cut -f1)
                install_tipo="install.wim ($sz)"
                break
            elif [ -f "$m/sources/install.esd" ]; then
                install_ok=true
                local sz=$(du -h "$m/sources/install.esd" 2>/dev/null | cut -f1)
                install_tipo="install.esd ($sz)"
                break
            elif ls "$m/sources/install"*.swm &>/dev/null 2>&1; then
                install_ok=true
                local cnt=$(ls "$m/sources/install"*.swm 2>/dev/null | wc -l)
                install_tipo="install.swm ($cnt partes)"
                break
            fi
        fi
    done
    if [ "$install_ok" = true ]; then
        val "Imagem de instalacao ($install_tipo)" "OK"
    else
        val "Imagem de instalacao" "Nenhum install.wim/esd/swm encontrado"
    fi

    # --- Compatibilidade ---
    local compat_legacy="NAO"
    local compat_uefi="NAO"
    [ "$bootmgr_ok" = true ] && [ "$bcd_legacy" = true ] && [ "$bootwim_ok" = true ] && compat_legacy="SIM"
    [ "$efi_ok" = true ] && [ "$bcd_efi" = true ] && [ "$bootwim_ok" = true ] && compat_uefi="SIM"

    # --- Desmontar ---
    [ "$montou_p1" = true ] && umount "$mnt1" 2>/dev/null || true
    [ "$montou_p2" = true ] && umount "$mnt2" 2>/dev/null || true
    rmdir "$mnt1" "$mnt2" 2>/dev/null || true

    # --- Exibir resultado ---
    local dev_tamanho=$(lsblk -dno SIZE "$dev" | xargs)
    local dev_modelo=$(lsblk -dno MODEL "$dev" | xargs)

    local resumo=""
    resumo+="==========================================\n"
    resumo+="  RELATORIO DO PENDRIVE\n"
    resumo+="==========================================\n"
    resumo+="\n"
    resumo+="  Dispositivo:  $dev ($dev_tamanho)\n"
    resumo+="  Modelo:       $dev_modelo\n"
    resumo+="  Windows:      $versao\n"
    resumo+="\n"
    if [ -n "$edicoes" ]; then
        resumo+="  Edicoes disponiveis:\n"
        resumo+="$edicoes\n"
        resumo+="\n"
    fi
    resumo+="  ------------------------------------------\n"
    resumo+="  Verificacoes:\n"
    resumo+="  ------------------------------------------\n"
    resumo+="$relatorio\n"
    resumo+="  ------------------------------------------\n"
    resumo+="  Compatibilidade:\n"
    resumo+="  ------------------------------------------\n"
    if [ "$compat_legacy" = "SIM" ]; then
        resumo+="  ${VERDE}[OK]${RESET}    Legacy BIOS: Compativel\n"
    else
        resumo+="  ${VERMELHO}[--]${RESET}    Legacy BIOS: Nao compativel\n"
    fi
    if [ "$compat_uefi" = "SIM" ]; then
        resumo+="  ${VERDE}[OK]${RESET}    UEFI: Compativel\n"
    else
        resumo+="  ${VERMELHO}[--]${RESET}    UEFI: Nao compativel\n"
    fi
    resumo+="\n"
    if [ "$erros" -eq 0 ]; then
        resumo+="  ${NEGRITO}${VERDE}Resultado: PENDRIVE OK ($erros problemas)${RESET}\n"
    else
        resumo+="  ${NEGRITO}${AMARELO}Resultado: $erros PROBLEMA(S) ENCONTRADO(S)${RESET}\n"
    fi
    resumo+="==========================================\n"

    if usar_whiptail; then
        # Remover codigos de cor para whiptail
        local resumo_limpo=$(echo -e "$resumo" | sed 's/\x1b\[[0-9;]*m//g')
        whiptail --title "Relatorio - $dev" --scrolltext --msgbox "$resumo_limpo" 30 75
    else
        echo ""
        echo -e "$resumo"
    fi
    set -e  # reativar set -e
}

# === Funcao de ajuda (CLI) ===
mostrar_ajuda() {
    echo "multiboot-usb-creator v$VERSION"
    echo ""
    echo "Uso: sudo bash $(basename "$0") [opcoes]"
    echo ""
    echo "Opcoes:"
    echo "  --mode MODO       Modo de criacao: compat ou moderno"
    echo "  --iso CAMINHO     Caminho para a ISO do Windows/Linux"
    echo "  --dev DISPOSITIVO Dispositivo USB (ex: /dev/sdb)"
    echo "  --verify          Verificar pendrive existente (pula criacao)"
    echo "  --log ARQUIVO     Salvar log em arquivo (padrao: $LOG_FILE)"
    echo "  --help            Exibir esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  sudo bash $(basename "$0")"
    echo "  sudo bash $(basename "$0") --mode compat --iso Win10.iso --dev /dev/sdb"
    echo "  sudo bash $(basename "$0") --verify --dev /dev/sdb"
    echo ""
    echo "Sem argumentos, o modo interativo e iniciado (whiptail ou terminal)."
    exit 0
}

# === Parsear argumentos CLI ===
CLI_MODE=""
CLI_ISO=""
CLI_DEV=""
CLI_VERIFY=false

while [ $# -gt 0 ]; do
    case "$1" in
        --mode)
            shift
            case "$1" in
                compat|COMPAT)       CLI_MODE="COMPAT" ;;
                moderno|MODERNO)     CLI_MODE="MODERNO" ;;
                multiboot|MULTIBOOT) CLI_MODE="MULTIBOOT" ;;
                *) echo "Modo invalido: $1 (use: compat, moderno ou multiboot)"; exit 1 ;;
            esac
            ;;
        --iso)
            shift
            CLI_ISO="$1"
            [ ! -f "$CLI_ISO" ] && echo "ISO nao encontrada: $CLI_ISO" && exit 1
            ;;
        --dev)
            shift
            CLI_DEV="$1"
            [ ! -b "$CLI_DEV" ] && echo "Dispositivo nao encontrado: $CLI_DEV" && exit 1
            ;;
        --verify)
            CLI_VERIFY=true
            ;;
        --log)
            shift
            LOG_FILE="$1"
            ;;
        --help|-h)
            mostrar_ajuda
            ;;
        *)
            echo "Opcao desconhecida: $1"
            echo "Use --help para ver as opcoes disponiveis."
            exit 1
            ;;
    esac
    shift
done

# Inicializar log
echo "=============================================" > "$LOG_FILE"
log "INFO" "multiboot-usb-creator v$VERSION iniciado"
log "INFO" "Argumentos: mode=$CLI_MODE iso=$CLI_ISO dev=$CLI_DEV verify=$CLI_VERIFY"

# === Verificar root ===
if [ "$EUID" -ne 0 ]; then
    erro "Execute como root: sudo bash $0"
fi

# === Verificar dependencias ===
for cmd in parted mkfs.fat mkfs.ntfs rsync wimlib-imagex; do
    if ! command -v "$cmd" &>/dev/null; then
        erro "Comando '$cmd' nao encontrado. Instale antes de continuar."
    fi
done

# === Modo CLI: --verify direto ===
if [ "$CLI_VERIFY" = true ] && [ -n "$CLI_DEV" ]; then
    log "INFO" "Verificacao CLI direta: $CLI_DEV"
    verificar_pendrive "$CLI_DEV"
    exit 0
fi

# ============================================================
# MENU PRINCIPAL (loop)
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

while true; do

# Se CLI_VERIFY foi pedido (sem --dev, que ja foi tratado acima), ir direto para verificar
if [ "$CLI_VERIFY" = true ]; then
    ACAO="VERIFICAR"
    CLI_VERIFY=false  # evitar loop infinito
elif [ -n "$CLI_MODE" ] && [ -n "$CLI_ISO" ] && [ -n "$CLI_DEV" ]; then
    # Todos os args de criacao fornecidos via CLI
    ACAO="CRIAR"
elif usar_whiptail; then
    ACAO=$(whiptail --title "$TITULO" \
        --menu "O que deseja fazer?" \
        14 60 3 \
        "CRIAR"     "Criar pendrive bootavel a partir de ISO" \
        "VERIFICAR" "Verificar/validar pendrive existente" \
        "SAIR"      "Sair" \
        3>&1 1>&2 2>&3) || exit 0
else
    echo ""
    echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
    echo -e "${NEGRITO} $TITULO${RESET}"
    echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
    echo ""
    echo -e "  ${VERDE}[1]${RESET} Criar pendrive bootavel a partir de ISO"
    echo -e "  ${VERDE}[2]${RESET} Verificar/validar pendrive existente"
    echo -e "  ${VERDE}[3]${RESET} Sair"
    echo ""
    read -p "Escolha uma opcao: " opcao_menu
    case "$opcao_menu" in
        1) ACAO="CRIAR" ;;
        2) ACAO="VERIFICAR" ;;
        *) exit 0 ;;
    esac
fi

log "INFO" "Acao selecionada: $ACAO"

# ============================================================
# MODO: VERIFICAR PENDRIVE EXISTENTE
# ============================================================
if [ "$ACAO" = "VERIFICAR" ]; then
    detectar_pendrives
    if [ ${#PENDRIVES_ARRAY[@]} -eq 0 ]; then
        erro "Nenhum pendrive USB detectado."
    fi

    if usar_whiptail; then
        DEV=$(whiptail --title "$TITULO - Verificar" \
            --menu "Selecione o pendrive para verificar:" \
            16 70 6 \
            "${PENDRIVES_ARRAY[@]}" \
            3>&1 1>&2 2>&3) || continue
    else
        echo ""
        echo -e "${NEGRITO}Pendrives detectados:${RESET}"
        echo ""
        for ((i=0; i<${#PENDRIVES_ARRAY[@]}; i+=2)); do
            num=$((i/2+1))
            echo -e "  ${VERDE}[$num]${RESET} ${PENDRIVES_ARRAY[$i]} - ${PENDRIVES_ARRAY[$i+1]}"
        done
        echo ""
        read -p "Escolha o numero do pendrive: " escolha
        idx=$(( (escolha-1)*2 ))
        DEV="${PENDRIVES_ARRAY[$idx]}"
        [ -z "$DEV" ] && erro "Opcao invalida."
    fi

    verificar_pendrive "$DEV"
    continue
fi

# Sair do loop para modo CRIAR
[ "$ACAO" = "SAIR" ] && exit 0
break

done  # fim do loop do menu

# ============================================================
# MODO: CRIAR PENDRIVE
# ============================================================

# --- Selecionar modo de criacao ---
if [ -n "$CLI_MODE" ]; then
    MODO="$CLI_MODE"
    log "INFO" "Modo via CLI: $MODO"
elif usar_whiptail; then
    MODO=$(whiptail --title "$TITULO" \
        --menu "Selecione o modo de criacao:" \
        18 78 3 \
        "COMPAT"    "Compativel (MBR + FAT32) — Funciona em tudo (1 OS)" \
        "MULTIBOOT" "Multi-Boot (MBR + FAT32 + GRUB2) — Varios OS no pendrive" \
        "MODERNO"   "Moderno (GPT + FAT32/NTFS) — Somente PCs UEFI (1 OS)" \
        3>&1 1>&2 2>&3) || exit 1
else
    echo ""
    echo -e "${NEGRITO}Modo de criacao:${RESET}"
    echo ""
    echo -e "  ${VERDE}[1]${RESET} Compativel (MBR + FAT32) — Funciona em tudo (1 OS)"
    echo -e "  ${VERDE}[2]${RESET} Multi-Boot (MBR + FAT32 + GRUB2) — Varios OS no pendrive"
    echo -e "  ${VERDE}[3]${RESET} Moderno (GPT + FAT32/NTFS) — Somente PCs UEFI (1 OS)"
    echo ""
    read -p "Escolha o modo: " modo_escolha
    case "$modo_escolha" in
        2) MODO="MULTIBOOT" ;;
        3) MODO="MODERNO" ;;
        *) MODO="COMPAT" ;;
    esac
fi
log "INFO" "Modo selecionado: $MODO"

# --- Selecionar pendrive ---
if [ -n "$CLI_DEV" ]; then
    DEV="$CLI_DEV"
    log "INFO" "Pendrive via CLI: $DEV"
else
    detectar_pendrives
    if [ ${#PENDRIVES_ARRAY[@]} -eq 0 ]; then
        erro "Nenhum pendrive USB detectado. Conecte um pendrive e tente novamente."
    fi

    if usar_whiptail; then
        DEV=$(whiptail --title "$TITULO" \
            --menu "Selecione o pendrive (TODOS OS DADOS SERAO APAGADOS):" \
            16 70 6 \
            "${PENDRIVES_ARRAY[@]}" \
            3>&1 1>&2 2>&3) || exit 1
    else
        echo ""
        echo -e "${NEGRITO}Pendrives detectados:${RESET}"
        echo ""
        for ((i=0; i<${#PENDRIVES_ARRAY[@]}; i+=2)); do
            num=$((i/2+1))
            echo -e "  ${VERDE}[$num]${RESET} ${PENDRIVES_ARRAY[$i]} - ${PENDRIVES_ARRAY[$i+1]}"
        done
        echo ""
        read -p "Escolha o numero do pendrive: " escolha
        idx=$(( (escolha-1)*2 ))
        DEV="${PENDRIVES_ARRAY[$idx]}"
        [ -z "$DEV" ] && erro "Opcao invalida."
    fi
fi

# --- Detectar velocidade USB ---
USB_SPEED=$(detectar_velocidade_usb "$DEV")
log "INFO" "Pendrive: $DEV | Velocidade: $USB_SPEED"

if echo "$USB_SPEED" | grep -qi "USB 2.0\|USB 1"; then
    if usar_whiptail; then
        whiptail --title "Aviso: Conexao Lenta" \
            --msgbox "O pendrive esta conectado em uma porta $USB_SPEED.\n\nA transferencia sera significativamente mais lenta.\nRecomenda-se usar uma porta USB 3.0 se disponivel." \
            12 65
    else
        echo ""
        echo -e "  ${AMARELO}AVISO: Pendrive conectado em porta ${NEGRITO}$USB_SPEED${RESET}"
        echo -e "  ${AMARELO}A transferencia sera mais lenta. Use USB 3.0 se possivel.${RESET}"
        echo ""
    fi
fi

# --- Selecionar ISO(s) ---
if [ "$MODO" = "MULTIBOOT" ]; then
    # Multi-boot: selecionar multiplas ISOs + classificar + Windows primario
    verificar_deps_multiboot
    selecionar_isos_multiboot
    selecionar_windows_primario
else
    # Modo simples: selecionar uma ISO
    if [ -n "$CLI_ISO" ]; then
        ISO="$CLI_ISO"
        log "INFO" "ISO via CLI: $ISO"
    elif usar_whiptail; then
        WHIP_ISO=()
        while IFS= read -r arquivo; do
            nome=$(basename "$arquivo")
            tamanho=$(du -h "$arquivo" 2>/dev/null | cut -f1)
            WHIP_ISO+=("$arquivo" "${nome} (${tamanho})")
        done < <(find "$SCRIPT_DIR" -maxdepth 1 -iname "*.iso" -type f | sort)

        [ ${#WHIP_ISO[@]} -eq 0 ] && erro "Nenhuma ISO encontrada em $SCRIPT_DIR"

        ISO=$(whiptail --title "$TITULO" \
            --menu "Selecione a ISO:" \
            16 78 6 \
            "${WHIP_ISO[@]}" \
            3>&1 1>&2 2>&3) || exit 1
    else
        echo ""
        echo -e "${NEGRITO}ISOs encontradas:${RESET}"
        echo ""
        iso_files=()
        i=1
        while IFS= read -r arquivo; do
            nome=$(basename "$arquivo")
            tamanho=$(du -h "$arquivo" 2>/dev/null | cut -f1)
            echo -e "  ${VERDE}[$i]${RESET} $nome (${tamanho})"
            iso_files+=("$arquivo")
            ((i++))
        done < <(find "$SCRIPT_DIR" -maxdepth 1 -iname "*.iso" -type f | sort)

        [ ${#iso_files[@]} -eq 0 ] && erro "Nenhuma ISO encontrada em $SCRIPT_DIR"

        echo ""
        read -p "Escolha o numero da ISO: " escolha
        ISO="${iso_files[$((escolha-1))]}"
        [ -z "$ISO" ] || [ ! -f "$ISO" ] && erro "Opcao invalida."
    fi

    # Checksum (modo simples)
    CHECKSUM_RESULT=$(verificar_checksum_iso "$ISO")
    log "INFO" "Checksum ISO: $CHECKSUM_RESULT"
    if [ "$CHECKSUM_RESULT" = "OK" ]; then
        if usar_whiptail; then
            whiptail --title "Checksum" --msgbox "SHA256 da ISO verificado com sucesso!" 8 50
        else
            echo -e "  ${VERDE}[OK]${RESET} SHA256 da ISO verificado com sucesso!"
        fi
    elif echo "$CHECKSUM_RESULT" | grep -q "FALHOU"; then
        if usar_whiptail; then
            whiptail --title "AVISO: Checksum" \
                --yesno "ATENCAO: O SHA256 da ISO NAO confere!\n\nA ISO pode estar corrompida ou adulterada.\n\nDeseja continuar mesmo assim?" \
                12 65
            [ $? -ne 0 ] && exit 1
        else
            echo -e "  ${VERMELHO}[FALHA]${RESET} SHA256 da ISO NAO confere!"
            echo -e "  ${AMARELO}A ISO pode estar corrompida ou adulterada.${RESET}"
            read -p "Continuar mesmo assim? (s/N): " resp_check
            [[ "$resp_check" != "s" && "$resp_check" != "S" ]] && exit 1
        fi
    fi
fi

# --- Confirmacao ---
DEV_TAMANHO=$(lsblk -dno SIZE "$DEV" | xargs)
DEV_MODELO=$(lsblk -dno MODEL "$DEV" | xargs)

if [ "$MODO" = "MULTIBOOT" ]; then
    MODO_DESC="Multi-Boot (MBR + FAT32 + GRUB2)"
    ESPACO_INFO=$(calcular_espaco_multiboot "$DEV")
elif [ "$MODO" = "COMPAT" ]; then
    MODO_DESC="Compativel (MBR + FAT32)"
else
    MODO_DESC="Moderno (GPT + FAT32/NTFS)"
fi

if [ "$MODO" = "MULTIBOOT" ]; then
    # Confirmacao multi-boot
    conf_isos=""
    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        marker=""
        [ "${MB_ISOS[$i]}" = "$MB_PRIMARY_WIN" ] && marker=" [PRIMARIO]"
        conf_isos+="  - ${MB_ISO_NAMES[$i]} (${MB_ISO_TYPES[$i]})${marker}\n"
    done
    if usar_whiptail; then
        conf_limpo=$(echo -e "$ESPACO_INFO" | sed 's/\x1b\[[0-9;]*m//g')
        whiptail --title "$TITULO" --scrolltext \
            --yesno "CONFIRMAR OPERACAO MULTI-BOOT:\n\n\
Modo:     $MODO_DESC\n\
Pendrive: $DEV ($DEV_TAMANHO - $DEV_MODELO)\n\
USB:      $USB_SPEED\n\n\
ISOs selecionadas:\n$(echo -e "$conf_isos")\n\
$conf_limpo\n\
TODOS OS DADOS DO PENDRIVE SERAO APAGADOS!\n\n\
Deseja continuar?" \
            28 75 || exit 1
    else
        echo ""
        echo -e "${NEGRITO}${AMARELO}==========================================${RESET}"
        echo -e "${NEGRITO}${AMARELO} CONFIRMACAO MULTI-BOOT${RESET}"
        echo -e "${NEGRITO}${AMARELO}==========================================${RESET}"
        echo ""
        echo -e "  Modo:     ${NEGRITO}$MODO_DESC${RESET}"
        echo -e "  Pendrive: ${NEGRITO}$DEV${RESET} ($DEV_TAMANHO - $DEV_MODELO)"
        echo -e "  USB:      ${NEGRITO}$USB_SPEED${RESET}"
        echo ""
        echo -e "  ISOs selecionadas:"
        echo -e "$conf_isos"
        echo -e "$ESPACO_INFO"
        echo -e "  ${NEGRITO}${VERMELHO}TODOS OS DADOS DO PENDRIVE SERAO APAGADOS!${RESET}"
        echo ""
        read -p "Deseja continuar? (s/N): " resp
        [[ "$resp" != "s" && "$resp" != "S" ]] && exit 1
    fi
else
    # Confirmacao modo simples
    ISO_NOME=$(basename "$ISO")
    ISO_TAMANHO=$(du -h "$ISO" 2>/dev/null | cut -f1)
    if usar_whiptail; then
        whiptail --title "$TITULO" \
            --yesno "CONFIRMAR OPERACAO:\n\n\
Modo:     $MODO_DESC\n\
Pendrive: $DEV ($DEV_TAMANHO - $DEV_MODELO)\n\
USB:      $USB_SPEED\n\
ISO:      $ISO_NOME ($ISO_TAMANHO)\n\n\
TODOS OS DADOS DO PENDRIVE SERAO APAGADOS!\n\n\
Deseja continuar?" \
            20 70 || exit 1
    else
        echo ""
        echo -e "${NEGRITO}${AMARELO}==========================================${RESET}"
        echo -e "${NEGRITO}${AMARELO} CONFIRMACAO${RESET}"
        echo -e "${NEGRITO}${AMARELO}==========================================${RESET}"
        echo ""
        echo -e "  Modo:     ${NEGRITO}$MODO_DESC${RESET}"
        echo -e "  Pendrive: ${NEGRITO}$DEV${RESET} ($DEV_TAMANHO - $DEV_MODELO)"
        echo -e "  USB:      ${NEGRITO}$USB_SPEED${RESET}"
        echo -e "  ISO:      ${NEGRITO}$ISO_NOME${RESET} ($ISO_TAMANHO)"
        echo ""
        echo -e "  ${NEGRITO}${VERMELHO}TODOS OS DADOS DO PENDRIVE SERAO APAGADOS!${RESET}"
        echo ""
        read -p "Deseja continuar? (s/N): " resp
        [[ "$resp" != "s" && "$resp" != "S" ]] && exit 1
    fi
fi

# ============================================================
# CRIAR PENDRIVE BOOTAVEL
# ============================================================
log "INFO" "Iniciando criacao: modo=$MODO dev=$DEV"
log "INFO" "USB Speed: $USB_SPEED"

if [ "$MODO" = "COMPAT" ]; then
    # ===========================================================
    # MODO COMPATIVEL: MBR + FAT32 unica (funciona em tudo)
    # ===========================================================
    TOTAL_ETAPAS=7

    executar_etapas_compat() {
        if usar_whiptail; then
            echo 5; echo "XXX"; echo "[1/$TOTAL_ETAPAS] Desmontando particoes..."; echo "XXX"
        else
            etapa 1 $TOTAL_ETAPAS "Desmontando particoes..."
        fi
        umount ${DEV}* 2>/dev/null || true
        sleep 1

        if usar_whiptail; then
            echo 12; echo "XXX"; echo "[2/$TOTAL_ETAPAS] Criando tabela MBR..."; echo "XXX"
        else
            etapa 2 $TOTAL_ETAPAS "Criando tabela MBR..."
        fi
        parted "$DEV" --script mklabel msdos

        if usar_whiptail; then
            echo 20; echo "XXX"; echo "[3/$TOTAL_ETAPAS] Criando particao FAT32..."; echo "XXX"
        else
            etapa 3 $TOTAL_ETAPAS "Criando particao FAT32..."
        fi
        parted "$DEV" --script mkpart primary fat32 1MiB 100%
        parted "$DEV" --script set 1 boot on
        parted "$DEV" --script set 1 lba on
        sleep 2
        partprobe "$DEV"
        sleep 2

        if usar_whiptail; then
            echo 30; echo "XXX"; echo "[4/$TOTAL_ETAPAS] Formatando FAT32..."; echo "XXX"
        else
            etapa 4 $TOTAL_ETAPAS "Formatando FAT32..."
        fi
        mkfs.fat -F 32 -n "WIN_BOOT" ${DEV}1 >/dev/null 2>&1

        if usar_whiptail; then
            echo 38; echo "XXX"; echo "[5/$TOTAL_ETAPAS] Montando ISO e pendrive..."; echo "XXX"
        else
            etapa 5 $TOTAL_ETAPAS "Montando ISO e pendrive..."
        fi
        mkdir -p "$MNT_ISO" "$MNT_FAT"
        mount -o loop,ro "$ISO" "$MNT_ISO"
        mount ${DEV}1 "$MNT_FAT"
    }

    if usar_whiptail; then
        executar_etapas_compat | whiptail --title "$TITULO" --gauge \
            "Preparando pendrive (MBR + FAT32)..." 8 70 0
    else
        echo ""
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        echo -e "${NEGRITO} Criando pendrive (MBR + FAT32)...${RESET}"
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        executar_etapas_compat
    fi

    # Copiar arquivos (exceto install.wim que pode ser >4GB)
    if ! usar_whiptail; then
        etapa 6 $TOTAL_ETAPAS "Copiando arquivos para FAT32..."
    fi
    copiar_com_progresso "$MNT_ISO/" "$MNT_FAT/" \
        "[6/$TOTAL_ETAPAS] Copiando arquivos para FAT32..." \
        --no-owner --no-group --exclude='sources/install.wim' --exclude='sources/install.esd'

    # Tratar install.wim (dividir se >4GB, senao copiar direto)
    if ! usar_whiptail; then
        etapa 7 $TOTAL_ETAPAS "Processando install.wim..."
    fi

    WIM_FILE=""
    if [ -f "$MNT_ISO/sources/install.wim" ]; then
        WIM_FILE="$MNT_ISO/sources/install.wim"
    elif [ -f "$MNT_ISO/sources/install.esd" ]; then
        WIM_FILE="$MNT_ISO/sources/install.esd"
    fi

    if [ -n "$WIM_FILE" ]; then
        WIM_SIZE=$(stat -c%s "$WIM_FILE" 2>/dev/null || echo 0)
        WIM_NOME=$(basename "$WIM_FILE")
        if [ "$WIM_SIZE" -gt 4294967296 ]; then
            # Maior que 4GB: dividir em partes .swm com progresso real
            log "INFO" "$WIM_NOME > 4GB ($WIM_SIZE bytes), iniciando split"
            split_wim_com_progresso "$WIM_FILE" "$MNT_FAT/sources/install.swm" 7 $TOTAL_ETAPAS
        else
            # Menor que 4GB: copiar direto
            log "INFO" "$WIM_NOME < 4GB, copiando direto"
            cp "$WIM_FILE" "$MNT_FAT/sources/"
        fi
    fi

elif [ "$MODO" = "MULTIBOOT" ]; then
    # ===========================================================
    # MODO MULTI-BOOT: MBR + FAT32 + GRUB2 (multiplos OS)
    # ===========================================================
    TOTAL_ETAPAS=7

    executar_etapas_multiboot_prep() {
        if usar_whiptail; then
            echo 5; echo "XXX"; echo "[1/$TOTAL_ETAPAS] Desmontando particoes..."; echo "XXX"
        else
            etapa 1 $TOTAL_ETAPAS "Desmontando particoes..."
        fi
        umount ${DEV}* 2>/dev/null || true
        sleep 1

        if usar_whiptail; then
            echo 12; echo "XXX"; echo "[2/$TOTAL_ETAPAS] Criando tabela MBR..."; echo "XXX"
        else
            etapa 2 $TOTAL_ETAPAS "Criando tabela MBR..."
        fi
        parted "$DEV" --script mklabel msdos

        if usar_whiptail; then
            echo 20; echo "XXX"; echo "[3/$TOTAL_ETAPAS] Criando particao FAT32..."; echo "XXX"
        else
            etapa 3 $TOTAL_ETAPAS "Criando particao FAT32..."
        fi
        parted "$DEV" --script mkpart primary fat32 1MiB 100%
        parted "$DEV" --script set 1 boot on
        parted "$DEV" --script set 1 lba on
        sleep 2
        partprobe "$DEV"
        sleep 2

        if usar_whiptail; then
            echo 30; echo "XXX"; echo "[4/$TOTAL_ETAPAS] Formatando FAT32..."; echo "XXX"
        else
            etapa 4 $TOTAL_ETAPAS "Formatando FAT32..."
        fi
        mkfs.fat -F 32 -n "MULTIBOOT" ${DEV}1 >/dev/null 2>&1

        if usar_whiptail; then
            echo 38; echo "XXX"; echo "[5/$TOTAL_ETAPAS] Montando pendrive..."; echo "XXX"
        else
            etapa 5 $TOTAL_ETAPAS "Montando pendrive..."
        fi
        mkdir -p "$MNT_FAT"
        mount ${DEV}1 "$MNT_FAT"
        mkdir -p "$MNT_FAT/iso" "$MNT_FAT/boot/multiboot"
    }

    if usar_whiptail; then
        executar_etapas_multiboot_prep | whiptail --title "$TITULO" --gauge \
            "Preparando pendrive Multi-Boot..." 8 70 0
    else
        echo ""
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        echo -e "${NEGRITO} Criando pendrive Multi-Boot...${RESET}"
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        executar_etapas_multiboot_prep
    fi

    # --- Copiar Windows primario (extraido) ---
    if [ -n "$MB_PRIMARY_WIN" ]; then
        log "INFO" "Copiando Windows primario: $MB_PRIMARY_WIN_NAME"
        mkdir -p "$MNT_ISO"
        mount -o loop,ro "$MB_PRIMARY_WIN" "$MNT_ISO"

        if ! usar_whiptail; then
            etapa 6 $TOTAL_ETAPAS "Copiando $MB_PRIMARY_WIN_NAME..."
        fi
        copiar_com_progresso "$MNT_ISO/" "$MNT_FAT/" \
            "[6/$TOTAL_ETAPAS] Copiando $MB_PRIMARY_WIN_NAME..." \
            --no-owner --no-group --exclude='sources/install.wim' --exclude='sources/install.esd'

        # Tratar install.wim
        WIM_FILE=""
        [ -f "$MNT_ISO/sources/install.wim" ] && WIM_FILE="$MNT_ISO/sources/install.wim"
        [ -f "$MNT_ISO/sources/install.esd" ] && WIM_FILE="$MNT_ISO/sources/install.esd"

        if [ -n "$WIM_FILE" ]; then
            WIM_SIZE=$(stat -c%s "$WIM_FILE" 2>/dev/null || echo 0)
            WIM_NOME=$(basename "$WIM_FILE")
            if [ "$WIM_SIZE" -gt 4294967296 ]; then
                log "INFO" "$WIM_NOME > 4GB, iniciando split"
                split_wim_com_progresso "$WIM_FILE" "$MNT_FAT/sources/install.swm" 7 $TOTAL_ETAPAS
            else
                log "INFO" "$WIM_NOME < 4GB, copiando direto"
                cp "$WIM_FILE" "$MNT_FAT/sources/"
            fi
        fi

        umount "$MNT_ISO" 2>/dev/null || true
        rmdir "$MNT_ISO" 2>/dev/null || true
    fi

    # --- Instalar GRUB2 (DEPOIS do Windows para nao sobrescrever) ---
    log "INFO" "Instalando GRUB2..."
    if usar_whiptail; then
        (
            echo 20; echo "XXX"; echo "Instalando GRUB2 Legacy BIOS..."; echo "XXX"
            instalar_grub2_multiboot "$DEV" "$MNT_FAT"
            echo 100; echo "XXX"; echo "GRUB2 instalado!"; echo "XXX"
        ) | whiptail --title "$TITULO" --gauge "Instalando GRUB2..." 8 70 0
    else
        echo ""
        barra_progresso 50 "Instalando GRUB2..."
        instalar_grub2_multiboot "$DEV" "$MNT_FAT"
        barra_progresso 100 "GRUB2 instalado!"
        echo ""
    fi

    # --- Copiar Windows secundarios (wimboot files) ---
    has_extra_win=false
    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        [ "${MB_ISO_TYPES[$i]}" != "windows" ] && continue
        [ "${MB_ISOS[$i]}" = "$MB_PRIMARY_WIN" ] && continue

        has_extra_win=true
        iso_name="${MB_ISO_NAMES[$i]}"
        safe_name=$(echo "$iso_name" | tr ' .' '__' | tr -cd 'a-zA-Z0-9_-')

        log "INFO" "Extraindo wimboot files: $iso_name -> $safe_name"
        if usar_whiptail; then
            (
                echo 10; echo "XXX"; echo "Extraindo boot files de $iso_name..."; echo "XXX"
                extrair_wimboot_files "${MB_ISOS[$i]}" "$safe_name" "$MNT_FAT"
                echo 100
            ) | whiptail --title "$TITULO" --gauge "Extraindo $iso_name..." 8 70 0
        else
            echo ""
            barra_progresso 50 "Extraindo boot files: $iso_name..."
            extrair_wimboot_files "${MB_ISOS[$i]}" "$safe_name" "$MNT_FAT"
            barra_progresso 100 "$iso_name extraido!"
            echo ""
        fi
    done

    # Baixar wimboot se necessario
    if [ "$has_extra_win" = true ]; then
        log "INFO" "Obtendo wimboot binary..."
        obter_wimboot "$MNT_FAT" || log "WARN" "wimboot nao disponivel, Windows secundarios nao funcionarao"
    fi

    # --- Copiar Linux ISOs ---
    for ((i=0; i<${#MB_ISOS[@]}; i++)); do
        [ "${MB_ISO_TYPES[$i]}" != "linux" ] && continue

        iso_name="${MB_ISO_NAMES[$i]}"
        log "INFO" "Copiando ISO Linux: $iso_name"
        copiar_com_progresso "${MB_ISOS[$i]}" "$MNT_FAT/iso/" \
            "Copiando $iso_name para /iso/..." \
            --no-owner --no-group
    done

    # --- Gerar grub.cfg ---
    log "INFO" "Gerando grub.cfg..."
    gerar_grub_cfg "$MNT_FAT"

else
    # ===========================================================
    # MODO MODERNO: GPT + FAT32 (EFI) + NTFS (dados)
    # ===========================================================
    TOTAL_ETAPAS=8

    executar_etapas_moderno() {
        if usar_whiptail; then
            echo 5; echo "XXX"; echo "[1/$TOTAL_ETAPAS] Desmontando particoes..."; echo "XXX"
        else
            etapa 1 $TOTAL_ETAPAS "Desmontando particoes..."
        fi
        umount ${DEV}* 2>/dev/null || true
        sleep 1

        if usar_whiptail; then
            echo 10; echo "XXX"; echo "[2/$TOTAL_ETAPAS] Criando tabela GPT..."; echo "XXX"
        else
            etapa 2 $TOTAL_ETAPAS "Criando tabela GPT..."
        fi
        parted "$DEV" --script mklabel gpt

        if usar_whiptail; then
            echo 18; echo "XXX"; echo "[3/$TOTAL_ETAPAS] Criando particoes (FAT32 + NTFS)..."; echo "XXX"
        else
            etapa 3 $TOTAL_ETAPAS "Criando particoes (FAT32 + NTFS)..."
        fi
        parted "$DEV" --script mkpart primary fat32 1MiB 1024MiB
        parted "$DEV" --script set 1 msftdata on
        parted "$DEV" --script set 1 boot on
        parted "$DEV" --script mkpart primary ntfs 1024MiB 100%
        parted "$DEV" --script set 2 msftdata on
        sleep 2
        partprobe "$DEV"
        sleep 2

        if usar_whiptail; then
            echo 25; echo "XXX"; echo "[4/$TOTAL_ETAPAS] Formatando FAT32 (EFI)..."; echo "XXX"
        else
            etapa 4 $TOTAL_ETAPAS "Formatando FAT32 (EFI)..."
        fi
        mkfs.fat -F 32 -n "BOOT_EFI" ${DEV}1 >/dev/null 2>&1

        if usar_whiptail; then
            echo 30; echo "XXX"; echo "[5/$TOTAL_ETAPAS] Formatando NTFS..."; echo "XXX"
        else
            etapa 5 $TOTAL_ETAPAS "Formatando NTFS..."
        fi
        mkfs.ntfs -f -L "WINDOWS" ${DEV}2 >/dev/null 2>&1

        if usar_whiptail; then
            echo 35; echo "XXX"; echo "[6/$TOTAL_ETAPAS] Montando ISO e particoes..."; echo "XXX"
        else
            etapa 6 $TOTAL_ETAPAS "Montando ISO e particoes..."
        fi
        mkdir -p "$MNT_ISO" "$MNT_FAT" "$MNT_NTFS"
        mount -o loop,ro "$ISO" "$MNT_ISO"
        mount ${DEV}1 "$MNT_FAT"
        mount ${DEV}2 "$MNT_NTFS"
    }

    if usar_whiptail; then
        executar_etapas_moderno | whiptail --title "$TITULO" --gauge \
            "Preparando pendrive (GPT)..." 8 70 0
    else
        echo ""
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        echo -e "${NEGRITO} Criando pendrive (GPT + dual)...${RESET}"
        echo -e "${NEGRITO}${AZUL}==========================================${RESET}"
        executar_etapas_moderno
    fi

    # Copiar para NTFS
    if ! usar_whiptail; then
        etapa 7 $TOTAL_ETAPAS "Copiando arquivos para NTFS..."
    fi
    copiar_com_progresso "$MNT_ISO/" "$MNT_NTFS/" \
        "[7/$TOTAL_ETAPAS] Copiando arquivos para NTFS..." \
        --no-owner --no-group

    # Copiar boot para FAT32
    if ! usar_whiptail; then
        etapa 8 $TOTAL_ETAPAS "Configurando boot EFI (FAT32)..."
    fi
    copiar_com_progresso "$MNT_ISO/" "$MNT_FAT/" \
        "[8/$TOTAL_ETAPAS] Copiando boot para FAT32..." \
        --no-owner --no-group --exclude='sources/'

    mkdir -p "$MNT_FAT/sources"
    cp "$MNT_ISO/sources/boot.wim" "$MNT_FAT/sources/"

    # Dividir install.wim se > 4GB na FAT32
    WIM_SIZE=$(stat -c%s "$MNT_ISO/sources/install.wim" 2>/dev/null || echo 0)
    if [ "$WIM_SIZE" -gt 4294967296 ]; then
        log "INFO" "install.wim > 4GB ($WIM_SIZE bytes), iniciando split (moderno)"
        split_wim_com_progresso "$MNT_ISO/sources/install.wim" \
            "$MNT_FAT/sources/install.swm" 9 $TOTAL_ETAPAS
    fi
fi

# ============================================================
# VALIDACAO OPCIONAL
# ============================================================
log "INFO" "Copia concluida, sincronizando..."
sync

FAZER_VALIDACAO=false
if usar_whiptail; then
    if whiptail --title "$TITULO" \
        --yesno "Deseja validar o pendrive criado?\n\nVerifica arquivos de boot, particoes e compatibilidade." \
        10 60; then
        FAZER_VALIDACAO=true
    fi
else
    echo ""
    read -p "Deseja validar o pendrive? (s/N): " resp_val
    [[ "$resp_val" = "s" || "$resp_val" = "S" ]] && FAZER_VALIDACAO=true
fi

if [ "$FAZER_VALIDACAO" = true ]; then
    umount "$MNT_ISO" 2>/dev/null || true
    umount "$MNT_FAT" 2>/dev/null || true
    umount "$MNT_NTFS" 2>/dev/null || true
    rmdir "$MNT_ISO" "$MNT_FAT" "$MNT_NTFS" 2>/dev/null || true
    verificar_pendrive "$DEV"
else
    if usar_whiptail; then
        (
            echo 50; echo "XXX"; echo "Sincronizando dados..."; echo "XXX"
            sync
            echo 90; echo "XXX"; echo "Desmontando..."; echo "XXX"
            umount "$MNT_ISO" 2>/dev/null || true
            umount "$MNT_FAT" 2>/dev/null || true
            umount "$MNT_NTFS" 2>/dev/null || true
            rmdir "$MNT_ISO" "$MNT_FAT" "$MNT_NTFS" 2>/dev/null || true
            echo 100
        ) | whiptail --title "$TITULO" --gauge "Finalizando..." 8 70 0
    else
        echo ""
        barra_progresso 90 "Sincronizando dados..."
        sync
        barra_progresso 95 "Desmontando..."
        umount "$MNT_ISO" 2>/dev/null || true
        umount "$MNT_FAT" 2>/dev/null || true
        umount "$MNT_NTFS" 2>/dev/null || true
        rmdir "$MNT_ISO" "$MNT_FAT" "$MNT_NTFS" 2>/dev/null || true
        barra_progresso 100 "Concluido!"
        echo ""
    fi
fi

trap - EXIT
log "INFO" "Pendrive criado com sucesso! Modo: $MODO_DESC"
log "INFO" "Log salvo em: $LOG_FILE"

# Mensagem final
if usar_whiptail; then
    whiptail --title "$TITULO" \
        --msgbox "Pendrive bootavel criado com sucesso!\n\nModo: $MODO_DESC\nUSB: $USB_SPEED\nCompativel com Legacy BIOS e UEFI.\n\nLog: $LOG_FILE\nRemova o pendrive com seguranca." \
        16 65
else
    echo ""
    echo -e "${NEGRITO}${VERDE}==========================================${RESET}"
    echo -e "${NEGRITO}${VERDE} PRONTO! Pendrive bootavel criado!${RESET}"
    echo -e "${NEGRITO}${VERDE} Modo: $MODO_DESC${RESET}"
    echo -e "${NEGRITO}${VERDE} Compativel com Legacy BIOS e UEFI${RESET}"
    echo -e "${NEGRITO}${VERDE}==========================================${RESET}"
    echo -e " Log: $LOG_FILE"
    echo -e " Remova o pendrive com seguranca."
    echo ""
fi
