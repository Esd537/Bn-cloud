#!/bin/bash
set -euo pipefail

# =============================
# Gerenciador Multi-VM Avançado
# =============================

# Função para exibir o cabeçalho
display_header() {
    clear
    cat << "EOF"
========================================================================
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        POWERED BY BN CLOUD | FEITO POR BN
               DISCORD: eabn8
========================================================================
EOF
    echo
}

# Função para exibir saída colorida com emojis
print_status() {
    local type=$1
    local message=$2

    case $type in
        "INFO") echo -e "\033[1;34m📋 [INFO]\033[0m $message" ;;
        "WARN") echo -e "\033[1;33m⚠️  [AVISO]\033[0m $message" ;;
        "ERROR") echo -e "\033[1;31m❌ [ERRO]\033[0m $message" ;;
        "SUCCESS") echo -e "\033[1;32m✅ [SUCESSO]\033[0m $message" ;;
        "INPUT") echo -e "\033[1;36m🎯 [ENTRADA]\033[0m $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

# Verifica se o arquivo de imagem está bloqueado
check_image_lock() {
    local img_file=$1
    local vm_name=$2

    if lsof "$img_file" 2>/dev/null | grep -q qemu-system; then
        print_status "WARN" "🔒 O arquivo de imagem $img_file já está em uso por outro processo QEMU"
        
        local pid=$(lsof "$img_file" 2>/dev/null | grep qemu-system | awk '{print $2}' | head -1)
        if [[ -n "$pid" ]]; then
            print_status "INFO" "🔍 ID do processo usando a imagem: $pid"
            
            if ps -p "$pid" -o cmd= | grep -q "$vm_name"; then
                print_status "INFO" "🤔 Parece ser a mesma VM já em execução"
                read -p "$(print_status "INPUT" "🔄 Matar processo existente e reiniciar? (s/N): ")" kill_choice
                if [[ "$kill_choice" =~ ^[Ss]$ ]]; then
                    kill "$pid"
                    sleep 2
                    if kill -0 "$pid" 2>/dev/null; then
                        kill -9 "$pid"
                        print_status "WARN" "⚠️  Processo $pid finalizado forçadamente"
                    fi
                    return 0
                else
                    return 1
                fi
            else
                print_status "ERROR" "🚫 Outra instância do QEMU está usando esta imagem"
                return 1
            fi
        fi
        return 1
    fi

    local lock_file="${img_file}.lock"
    if [[ -f "$lock_file" ]]; then
        print_status "WARN" "🔒 Arquivo de lock encontrado: $lock_file"
        
        if [[ $(find "$lock_file" -mmin +5 2>/dev/null) ]]; then
            print_status "WARN" "⏰ O arquivo de lock parece estar obsoleto (mais de 5 minutos)"
            read -p "$(print_status "INPUT" "🗑️  Remover arquivo de lock obsoleto? (s/N): ")" remove_lock
            if [[ "$remove_lock" =~ ^[Ss]$ ]]; then
                rm -f "$lock_file"
                print_status "SUCCESS" "✅ Arquivo de lock obsoleto removido"
                return 0
            else
                return 1
            fi
        fi
        return 1
    fi
    return 0
}

# Valida entradas do usuário
validate_input() {
    local type=$1
    local value=$2

    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "❌ Deve ser um número"
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "❌ Deve ser um tamanho com unidade (ex: 100G, 512M)"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 23 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "❌ Deve ser um número de porta válido (23-65535)"
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "❌ O nome da VM só pode conter letras, números, hífens e sublinhados"
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "❌ O nome de usuário deve começar com letra ou sublinhado e conter apenas letras minúsculas, números, hífens e sublinhados"
                return 1
            fi
            ;;
    esac
    return 0
}

# Verifica dependências do sistema
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img" "lsof")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "ERROR" "🔧 Dependências ausentes: ${missing_deps[*]}"
        print_status "INFO" "💡 No Ubuntu/Debian, tente: sudo apt install qemu-system cloud-image-utils wget lsof"
        exit 1
    fi
}

# Limpa arquivos temporários
cleanup() {
    if [ -f "user-data" ]; then rm -f "user-data"; fi
    if [ -f "meta-data" ]; then rm -f "meta-data"; fi
}

# Lista as VMs existentes
get_vm_list() {
    find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

# Carrega a configuração de uma VM
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"

    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        
        source "$config_file"
        return 0
    else
        print_status "ERROR" "📂 Configuração para VM '$vm_name' não encontrada"
        return 1
    fi
}

# Salva a configuração da VM
save_vm_config() {
    local config_file="$VM_DIR/$VM_NAME.conf"

    cat > "$config_file" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF

    print_status "SUCCESS" "💾 Configuração salva em $config_file"
}

# Cria uma nova VM
create_new_vm() {
    print_status "INFO" "🆕 Criando uma nova VM"

    # Seleção de SO
    print_status "INFO" "🌍 Selecione um sistema operacional:"
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo "  $i) $os"
        os_options[$i]="$os"
        ((i++))
    done

    while true; do
        read -p "$(print_status "INPUT" "🎯 Digite sua escolha (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "❌ Seleção inválida. Tente novamente."
        fi
    done

    # Entradas personalizadas
    while true; do
        read -p "$(print_status "INPUT" "🏷️  Nome da VM (padrão: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "⚠️  Já existe uma VM com o nome '$VM_NAME'"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🏠 Hostname (padrão: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "👤 Nome de usuário (padrão: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then
            break
        fi
    done

    while true; do
        read -s -p "$(print_status "INPUT" "🔑 Senha (padrão: $DEFAULT_PASSWORD): ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then
            break
        else
            print_status "ERROR" "❌ A senha não pode estar vazia"
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "💾 Tamanho do disco (padrão: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🧠 Memória em MB (padrão: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "⚡ Número de CPUs (padrão: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "🔌 Porta SSH (padrão: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "🚫 Porta $SSH_PORT já está em uso"
            else
                break
            fi
        fi
    done

    # Modo gráfico (Desktop) ou servidor (console)
    while true; do
        read -p "$(print_status "INPUT" "🖥️  Deseja VM com interface gráfica (LXDE Desktop)? (s/n, padrão: n): ")" gui_input
        GUI_MODE=false
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Ss]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            break
        else
            print_status "ERROR" "❌ Por favor, responda s ou n"
        fi
    done

    # Redirecionamentos de porta adicionais
    read -p "$(print_status "INPUT" "🌐 Redirecionamentos de porta adicionais (ex: 8080:80, pressione Enter para nenhum): ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    # Baixar e preparar imagem da VM
    setup_vm_image

    # Salvar configuração
    save_vm_config
}

# Prepara a imagem e o cloud-init (agora com suporte a desktop)
setup_vm_image() {
    print_status "INFO" "📥 Baixando e preparando imagem..."

    mkdir -p "$VM_DIR"

    # Download da imagem base
    if [[ -f "$IMG_FILE" ]]; then
        print_status "INFO" "✅ Arquivo de imagem já existe. Pulando download."
    else
        print_status "INFO" "🌐 Baixando imagem de $IMG_URL..."
        if ! wget --progress=bar:force "$IMG_URL" -O "$IMG_FILE.tmp"; then
            print_status "ERROR" "❌ Falha ao baixar imagem de $IMG_URL"
            exit 1
        fi
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    fi

    # Redimensiona se necessário
    if ! qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null; then
        print_status "WARN" "⚠️  Falha ao redimensionar. Criando nova imagem com o tamanho especificado..."
        rm -f "$IMG_FILE"
        qemu-img create -f qcow2 -F qcow2 -b "$IMG_FILE" "$IMG_FILE.tmp" "$DISK_SIZE" 2>/dev/null || \
        qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
        if [ -f "$IMG_FILE.tmp" ]; then
            mv "$IMG_FILE.tmp" "$IMG_FILE"
        fi
    fi

    # Gera a configuração cloud-init base
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    # Se for VM desktop, adiciona instalação do LXDE e configuração gráfica
    if [[ "$GUI_MODE" == true ]]; then
        print_status "INFO" "🖥️  Configurando VM como desktop (LXDE)..."

        # Para Debian/Ubuntu
        if [[ "$OS_TYPE" == "ubuntu" || "$OS_TYPE" == "debian" ]]; then
            cat >> user-data <<EOF

# Pacotes necessários para o desktop LXDE
packages:
  - lxde
  - lightdm
  - xorg
  - firefox

# Comandos pós-instalação
runcmd:
  - systemctl set-default graphical.target
  - systemctl enable lightdm
  - reboot
EOF

        # Para Fedora / CentOS / RHEL
        elif [[ "$OS_TYPE" == "fedora" || "$OS_TYPE" == "centos" || "$OS_TYPE" == "almalinux" || "$OS_TYPE" == "rockylinux" ]]; then
            cat >> user-data <<EOF

# Pacotes para LXDE (grupo de ambiente)
packages:
  - @lxde-desktop
  - @base-x
  - firefox

runcmd:
  - systemctl set-default graphical.target
  - systemctl enable lightdm
  - reboot
EOF
        else
            # Fallback para outras distros (tentativa genérica)
            cat >> user-data <<EOF
packages:
  - lxde
  - lightdm
  - xorg

runcmd:
  - systemctl set-default graphical.target
  - systemctl enable lightdm
  - reboot
EOF
        fi
    fi

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    if ! cloud-localds "$SEED_FILE" user-data meta-data; then
        print_status "ERROR" "❌ Falha ao criar imagem seed cloud-init"
        exit 1
    fi

    print_status "SUCCESS" "🎉 VM '$VM_NAME' criada com sucesso."
    print_status "INFO" "🔑 Login com: usuário=$USERNAME, senha=$PASSWORD"
    print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
    if [[ "$GUI_MODE" == true ]]; then
        print_status "INFO" "🖥️  Ambiente gráfico LXDE será instalado no primeiro boot."
    fi
}

# Inicia uma VM
start_vm() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        if ! check_image_lock "$IMG_FILE" "$vm_name"; then
            print_status "ERROR" "🔒 Não é possível iniciar a VM: arquivo de imagem bloqueado"
            read -p "$(print_status "INPUT" "🔄 Forçar finalização dos processos QEMU? (s/N): ")" force_kill
            if [[ "$force_kill" =~ ^[Ss]$ ]]; then
                pkill -f "qemu-system.*$IMG_FILE"
                sleep 2
                if pgrep -f "qemu-system.*$IMG_FILE" >/dev/null; then
                    pkill -9 -f "qemu-system.*$IMG_FILE"
                fi
                rm -f "${IMG_FILE}.lock" 2>/dev/null
                print_status "SUCCESS" "✅ Processos finalizados"
            else
                return 1
            fi
        fi
        
        if is_vm_running "$vm_name"; then
            print_status "WARN" "⚠️  VM '$vm_name' já está em execução"
            read -p "$(print_status "INPUT" "🔄 Parar e reiniciar? (s/N): ")" restart_choice
            if [[ "$restart_choice" =~ ^[Ss]$ ]]; then
                stop_vm "$vm_name"
                sleep 2
            else
                return 1
            fi
        fi
        
        print_status "INFO" "🚀 Iniciando VM: $vm_name"
        print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
        print_status "INFO" "🔑 Senha: $PASSWORD"
        
        if [[ ! -f "$IMG_FILE" ]]; then
            print_status "ERROR" "❌ Arquivo de imagem da VM não encontrado: $IMG_FILE"
            return 1
        fi
        
        if [[ ! -f "$SEED_FILE" ]]; then
            print_status "WARN" "⚠️  Arquivo seed não encontrado, recriando..."
            setup_vm_image
        fi
        
        local qemu_cmd=(
            qemu-system-x86_64
            -enable-kvm
            -m "$MEMORY"
            -smp "$CPUS"
            -cpu host
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
        )

        # Redirecionamentos extras
        if [[ -n "$PORT_FORWARDS" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-device "virtio-net-pci,netdev=n${#qemu_cmd[@]}")
                qemu_cmd+=(-netdev "user,id=n${#qemu_cmd[@]},hostfwd=tcp::$host_port-:$guest_port")
            done
        fi

        # Ambiente gráfico (desktop) ou console
        if [[ "$GUI_MODE" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk)
            print_status "INFO" "🖥️  Iniciando em modo gráfico (LXDE)..."
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
            print_status "INFO" "📟 Iniciando em modo console (servidor)..."
            print_status "INFO" "🛑 Pressione Ctrl+A e depois X para sair do QEMU"
        fi

        qemu_cmd+=(
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
        )

        print_status "INFO" "⚡ Iniciando QEMU..."
        echo "📊 Configuração: ${MEMORY}MB RAM, ${CPUS} CPUs, ${DISK_SIZE} disco"
        
        if ! "${qemu_cmd[@]}"; then
            print_status "ERROR" "❌ Falha ao iniciar a VM."
            rm -f "${IMG_FILE}.lock" 2>/dev/null
            return 1
        fi
        
        print_status "INFO" "🛑 VM $vm_name foi desligada"
    fi
}

# Exclui uma VM
delete_vm() {
    local vm_name=$1

    print_status "WARN" "⚠️  ⚠️  ⚠️  Isso excluirá permanentemente a VM '$vm_name' e todos os seus dados!"
    read -p "$(print_status "INPUT" "🗑️  Tem certeza? (s/N): ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        if load_vm_config "$vm_name"; then
            if is_vm_running "$vm_name"; then
                print_status "WARN" "⚠️  A VM está em execução. Parando primeiro..."
                stop_vm "$vm_name"
                sleep 2
            fi
            
            rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf" "${IMG_FILE}.lock" 2>/dev/null
            print_status "SUCCESS" "✅ VM '$vm_name' foi excluída"
        fi
    else
        print_status "INFO" "👍 Exclusão cancelada"
    fi
}

# Mostra informações de uma VM
show_vm_info() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        echo
        print_status "INFO" "📊 Informações da VM: $vm_name"
        echo "🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹"
        echo "🌍 SO: $OS_TYPE"
        echo "🏷️  Hostname: $HOSTNAME"
        echo "👤 Usuário: $USERNAME"
        echo "🔑 Senha: $PASSWORD"
        echo "🔌 Porta SSH: $SSH_PORT"
        echo "🧠 Memória: $MEMORY MB"
        echo "⚡ CPUs: $CPUS"
        echo "💾 Disco: $DISK_SIZE"
        echo "🖥️  Modo: $([ "$GUI_MODE" == true ] && echo "Desktop (LXDE)" || echo "Servidor (console)")"
        echo "🌐 Redirecionamentos: ${PORT_FORWARDS:-Nenhum}"
        echo "📅 Criada em: $CREATED"
        echo "💿 Imagem: $IMG_FILE"
        echo "🌱 Seed: $SEED_FILE"
        
        if check_image_lock "$IMG_FILE" "$vm_name" >/dev/null 2>&1; then
            echo "🔓 Status da imagem: Desbloqueada"
        else
            echo "🔒 Status da imagem: Bloqueada (em uso)"
        fi
        
        if is_vm_running "$vm_name"; then
            echo "🚀 Status: Em execução"
        else
            echo "💤 Status: Parada"
        fi
        
        echo "🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹🔹"
        echo
        read -p "$(print_status "INPUT" "⏎ Pressione Enter para continuar...")"
    fi
}

# Verifica se a VM está rodando
is_vm_running() {
    local vm_name=$1

    if pgrep -f "qemu-system.*$vm_name" >/dev/null; then
        return 0
    fi

    if load_vm_config "$vm_name" 2>/dev/null; then
        if pgrep -f "qemu-system.*$IMG_FILE" >/dev/null; then
            return 0
        fi
    fi

    return 1
}

# Para uma VM em execução
stop_vm() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "🛑 Parando VM: $vm_name"
            
            pkill -f "qemu-system.*$IMG_FILE"
            sleep 2
            
            if is_vm_running "$vm_name"; then
                pkill -9 -f "qemu-system.*$IMG_FILE"
                sleep 1
            fi
            
            rm -f "${IMG_FILE}.lock" 2>/dev/null
            
            if is_vm_running "$vm_name"; then
                print_status "ERROR" "❌ Falha ao parar VM"
                return 1
            else
                print_status "SUCCESS" "✅ VM $vm_name parada"
            fi
        else
            print_status "INFO" "💤 VM $vm_name não está em execução"
            rm -f "${IMG_FILE}.lock" 2>/dev/null
        fi
    fi
}

# Edita configuração da VM
edit_vm_config() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        print_status "INFO" "✏️  Editando VM: $vm_name"
        
        while true; do
            echo "📝 O que você gostaria de editar?"
            echo "  1) 🏷️  Hostname"
            echo "  2) 👤 Nome de usuário"
            echo "  3) 🔑 Senha"
            echo "  4) 🔌 Porta SSH"
            echo "  5) 🖥️  Modo gráfico (aviso: não altera pacotes instalados)"
            echo "  6) 🌐 Redirecionamentos de porta"
            echo "  7) 🧠 Memória (RAM)"
            echo "  8) ⚡ CPUs"
            echo "  9) 💾 Tamanho do disco"
            echo "  0) ↩️  Voltar ao menu principal"
            
            read -p "$(print_status "INPUT" "🎯 Digite sua escolha: ")" edit_choice
            
            case $edit_choice in
                1)
                    while true; do
                        read -p "$(print_status "INPUT" "🏷️  Novo hostname (atual: $HOSTNAME): ")" new_hostname
                        new_hostname="${new_hostname:-$HOSTNAME}"
                        if validate_input "name" "$new_hostname"; then
                            HOSTNAME="$new_hostname"
                            break
                        fi
                    done
                    ;;
                2)
                    while true; do
                        read -p "$(print_status "INPUT" "👤 Novo nome de usuário (atual: $USERNAME): ")" new_username
                        new_username="${new_username:-$USERNAME}"
                        if validate_input "username" "$new_username"; then
                            USERNAME="$new_username"
                            break
                        fi
                    done
                    ;;
                3)
                    while true; do
                        read -s -p "$(print_status "INPUT" "🔑 Nova senha: ")" new_password
                        new_password="${new_password:-$PASSWORD}"
                        echo
                        if [ -n "$new_password" ]; then
                            PASSWORD="$new_password"
                            break
                        else
                            print_status "ERROR" "❌ A senha não pode estar vazia"
                        fi
                    done
                    ;;
                4)
                    while true; do
                        read -p "$(print_status "INPUT" "🔌 Nova porta SSH (atual: $SSH_PORT): ")" new_ssh_port
                        new_ssh_port="${new_ssh_port:-$SSH_PORT}"
                        if validate_input "port" "$new_ssh_port"; then
                            if [ "$new_ssh_port" != "$SSH_PORT" ] && ss -tln 2>/dev/null | grep -q ":$new_ssh_port "; then
                                print_status "ERROR" "🚫 Porta $new_ssh_port já está em uso"
                            else
                                SSH_PORT="$new_ssh_port"
                                break
                            fi
                        fi
                    done
                    ;;
                5)
                    print_status "WARN" "⚠️  Alterar o modo gráfico não instala/remove o ambiente desktop."
                    print_status "INFO" "   Apenas define se a VM usará saída gráfica na próxima inicialização."
                    while true; do
                        read -p "$(print_status "INPUT" "🖥️  Ativar modo gráfico? (s/n, atual: $GUI_MODE): ")" gui_input
                        gui_input="${gui_input:-}"
                        if [[ "$gui_input" =~ ^[Ss]$ ]]; then 
                            GUI_MODE=true
                            break
                        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
                            GUI_MODE=false
                            break
                        elif [ -z "$gui_input" ]; then
                            break
                        else
                            print_status "ERROR" "❌ Por favor, responda s ou n"
                        fi
                    done
                    ;;
                6)
                    read -p "$(print_status "INPUT" "🌐 Redirecionamentos (atual: ${PORT_FORWARDS:-Nenhum}): ")" new_port_forwards
                    PORT_FORWARDS="${new_port_forwards:-$PORT_FORWARDS}"
                    ;;
                7)
                    while true; do
                        read -p "$(print_status "INPUT" "🧠 Nova memória em MB (atual: $MEMORY): ")" new_memory
                        new_memory="${new_memory:-$MEMORY}"
                        if validate_input "number" "$new_memory"; then
                            MEMORY="$new_memory"
                            break
                        fi
                    done
                    ;;
                8)
                    while true; do
                        read -p "$(print_status "INPUT" "⚡ Novo número de CPUs (atual: $CPUS): ")" new_cpus
                        new_cpus="${new_cpus:-$CPUS}"
                        if validate_input "number" "$new_cpus"; then
                            CPUS="$new_cpus"
                            break
                        fi
                    done
                    ;;
                9)
                    while true; do
                        read -p "$(print_status "INPUT" "💾 Novo tamanho de disco (atual: $DISK_SIZE): ")" new_disk_size
                        new_disk_size="${new_disk_size:-$DISK_SIZE}"
                        if validate_input "size" "$new_disk_size"; then
                            DISK_SIZE="$new_disk_size"
                            break
                        fi
                    done
                    ;;
                0)
                    return 0
                    ;;
                *)
                    print_status "ERROR" "❌ Seleção inválida"
                    continue
                    ;;
            esac
            
            # Se mudou hostname, username ou password, recria seed
            if [[ "$edit_choice" -eq 1 || "$edit_choice" -eq 2 || "$edit_choice" -eq 3 ]]; then
                print_status "INFO" "🔄 Atualizando cloud-init..."
                setup_vm_image
            fi
            
            save_vm_config
            
            read -p "$(print_status "INPUT" "🔄 Continuar editando? (s/N): ")" continue_editing
            if [[ ! "$continue_editing" =~ ^[Ss]$ ]]; then
                break
            fi
        done
    fi
}

# Redimensiona disco
resize_vm_disk() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "ERROR" "❌ Pare a VM antes de redimensionar o disco."
            return 1
        fi
        
        print_status "INFO" "💾 Tamanho atual: $DISK_SIZE"
        
        while true; do
            read -p "$(print_status "INPUT" "📈 Novo tamanho (ex: 50G): ")" new_disk_size
            if validate_input "size" "$new_disk_size"; then
                if [[ "$new_disk_size" == "$DISK_SIZE" ]]; then
                    print_status "INFO" "ℹ️  Tamanho idêntico. Nada a fazer."
                    return 0
                fi
                
                # Alerta se estiver diminuindo
                local cur_num=${DISK_SIZE%[GgMm]}
                local new_num=${new_disk_size%[GgMm]}
                local cur_unit=${DISK_SIZE: -1}
                local new_unit=${new_disk_size: -1}
                
                [[ "$cur_unit" =~ [Gg] ]] && cur_num=$((cur_num * 1024))
                [[ "$new_unit" =~ [Gg] ]] && new_num=$((new_num * 1024))
                
                if [[ $new_num -lt $cur_num ]]; then
                    print_status "WARN" "⚠️  Reduzir disco pode causar perda de dados!"
                    read -p "$(print_status "INPUT" "Continuar mesmo assim? (s/N): ")" confirm
                    [[ ! "$confirm" =~ ^[Ss]$ ]] && return 0
                fi
                
                if qemu-img resize "$IMG_FILE" "$new_disk_size"; then
                    DISK_SIZE="$new_disk_size"
                    save_vm_config
                    print_status "SUCCESS" "✅ Disco redimensionado para $new_disk_size"
                else
                    print_status "ERROR" "❌ Falha ao redimensionar"
                fi
                break
            fi
        done
    fi
}

# Métricas de desempenho
show_vm_performance() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "📊 Métricas de desempenho: $vm_name"
            local pid=$(pgrep -f "qemu-system.*$IMG_FILE")
            if [[ -n "$pid" ]]; then
                ps -p "$pid" -o pid,%cpu,%mem,sz,rss,vsz,cmd --no-headers
                echo
                free -h
                echo
                df -h "$IMG_FILE" 2>/dev/null || du -h "$IMG_FILE"
            fi
        else
            print_status "INFO" "💤 VM parada. Configuração:"
            echo "  🧠 $MEMORY MB | ⚡ $CPUS CPUs | 💾 $DISK_SIZE"
        fi
        read -p "$(print_status "INPUT" "⏎ Pressione Enter...")"
    fi
}

# Corrige problemas comuns
fix_vm_issues() {
    local vm_name=$1

    if load_vm_config "$vm_name"; then
        print_status "INFO" "🔧 Corrigindo problemas para VM: $vm_name"
        
        echo "🔧 Selecione:"
        echo "  1) 🔓 Remover arquivos de lock"
        echo "  2) 🗑️  Recriar imagem seed"
        echo "  3) 🔄 Recriar configuração"
        echo "  4) 💀 Finalizar processos travados"
        echo "  0) ↩️  Voltar"
        
        read -p "$(print_status "INPUT" "🎯 Escolha: ")" fix_choice
        
        case $fix_choice in
            1)
                rm -f "${IMG_FILE}.lock"* 2>/dev/null
                print_status "SUCCESS" "✅ Locks removidos"
                ;;
            2)
                rm -f "$SEED_FILE"
                setup_vm_image
                ;;
            3)
                save_vm_config
                ;;
            4)
                pkill -f "qemu-system.*$IMG_FILE" 2>/dev/null
                sleep 1
                pgrep -f "qemu-system.*$IMG_FILE" >/dev/null && pkill -9 -f "qemu-system.*$IMG_FILE"
                print_status "SUCCESS" "✅ Processos finalizados"
                ;;
            0) return 0 ;;
            *) print_status "ERROR" "❌ Inválido" ;;
        esac
    fi
}

# Menu principal
main_menu() {
    while true; do
        display_header

        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        if [ $vm_count -gt 0 ]; then
            print_status "INFO" "📁 $vm_count VM(s) encontrada(s):"
            for i in "${!vms[@]}"; do
                local status="💤"
                is_vm_running "${vms[$i]}" && status="🚀"
                printf "  %2d) %s %s\n" $((i+1)) "${vms[$i]}" "$status"
            done
            echo
        fi
        
        echo "📋 Menu Principal:"
        echo "  1) 🆕 Criar nova VM"
        if [ $vm_count -gt 0 ]; then
            echo "  2) 🚀 Iniciar VM"
            echo "  3) 🛑 Parar VM"
            echo "  4) 📊 Informações da VM"
            echo "  5) ✏️  Editar VM"
            echo "  6) 🗑️  Excluir VM"
            echo "  7) 📈 Redimensionar disco"
            echo "  8) 📊 Desempenho da VM"
            echo "  9) 🔧 Corrigir problemas"
        fi
        echo "  0) 👋 Sair"
        echo
        
        read -p "$(print_status "INPUT" "🎯 Digite sua escolha: ")" choice
        
        case $choice in
            1) create_new_vm ;;
            2)
                [ $vm_count -gt 0 ] && read -p "🚀 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                start_vm "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            3)
                [ $vm_count -gt 0 ] && read -p "🛑 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                stop_vm "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            4)
                [ $vm_count -gt 0 ] && read -p "📊 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                show_vm_info "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            5)
                [ $vm_count -gt 0 ] && read -p "✏️  Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                edit_vm_config "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            6)
                [ $vm_count -gt 0 ] && read -p "🗑️  Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                delete_vm "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            7)
                [ $vm_count -gt 0 ] && read -p "📈 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                resize_vm_disk "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            8)
                [ $vm_count -gt 0 ] && read -p "📊 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                show_vm_performance "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            9)
                [ $vm_count -gt 0 ] && read -p "🔧 Número da VM: " vm_num && \
                [[ "$vm_num" =~ ^[0-9]+$ && $vm_num -ge 1 && $vm_num -le $vm_count ]] && \
                fix_vm_issues "${vms[$((vm_num-1))]}" || print_status "ERROR" "❌ Inválido"
                ;;
            0) print_status "INFO" "👋 Até logo!"; exit 0 ;;
            *) print_status "ERROR" "❌ Opção inválida" ;;
        esac
        
        read -p "$(print_status "INPUT" "⏎ Pressione Enter para continuar...")"
    done
}

# Inicialização
trap cleanup EXIT
check_dependencies

VM_DIR="${VM_DIR:-$HOME/vms}"
mkdir -p "$VM_DIR"

declare -A OS_OPTIONS=(
    ["Ubuntu 22.04"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu22|ubuntu|ubuntu"
    ["Ubuntu 24.04"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu24|ubuntu|ubuntu"
    ["Debian 11"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2|debian11|debian|debian"
    ["Debian 12"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian12|debian|debian"
    ["Debian 13"]="debian|trixie|https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2|debian13|debian|debian"
    ["Fedora 40"]="fedora|40|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora40|fedora|fedora"
    ["CentOS Stream 9"]="centos|stream9|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos9|centos|centos"
    ["AlmaLinux 9"]="almalinux|9|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|almalinux9|alma|alma"
    ["Rocky Linux 9"]="rockylinux|9|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky9|rocky|rocky"
)

main_menu