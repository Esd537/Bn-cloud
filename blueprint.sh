#!/bin/bash

# ============================================================
#   BLUEPRINT INSTALLER PARA PTERODACTYL
#   Feito por BN Cloud | Discord: eabn8
# ============================================================

# Cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
MAGENTA='\033[0;35m'
BRANCO='\033[1;37m'
NC='\033[0m' # Sem cor

# Função para cabeçalhos de seção
print_header() {
    echo -e "\n${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CIANO} $1 ${NC}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Função para mensagens de status
print_status() {
    echo -e "${AMARELO}⏳ $1...${NC}"
}

print_success() {
    echo -e "${VERDE}✅ $1${NC}"
}

print_error() {
    echo -e "${VERMELHO}❌ $1${NC}"
}

print_warning() {
    echo -e "${MAGENTA}⚠️  $1${NC}"
}

# Verifica sucesso do último comando
check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
        return 0
    else
        print_error "$2"
        return 1
    fi
}

# Barra de progresso animada
animate_progress() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Animação de boas-vindas (substituída pela logo BN Cloud)
welcome_animation() {
    clear
    echo -e "${VERDE}"
    cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        FEITO POR BN CLOUD | DISCORD: eabn8
EOF
    echo -e "${NC}"
    echo -e "${CIANO}              Instalador do Blueprint${NC}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 2
}

# Função: Instalar (Configuração nova)
install_blueprint() {
    # ================= VARIÁVEIS =================
    export PTERODACTYL_DIRECTORY=/var/www/pterodactyl

    # ================= INÍCIO =================
    print_header "INSTALANDO DEPENDÊNCIAS BÁSICAS"
    print_status "Instalando curl, wget, unzip"
    apt update -y && apt install -y curl wget unzip ca-certificates git gnupg zip || fail "Falha ao instalar dependências"
    check_success "Dependências instaladas"

    print_header "ACESSANDO DIRETÓRIO DO PTERODACTYL"
    print_status "Indo para o diretório do painel"
    cd "$PTERODACTYL_DIRECTORY" || { print_error "Diretório do Pterodactyl não encontrado"; return 1; }
    check_success "Diretório acessado"

    print_header "BAIXANDO O BLUEPRINT"
    print_status "Baixando a versão mais recente do Blueprint Framework"
    wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PTERODACTYL_DIRECTORY/release.zip"
    unzip -o release.zip || { print_error "Falha ao descompactar"; return 1; }
    check_success "Blueprint baixado e extraído"

    # ================= NODE.JS =================
    print_header "INSTALANDO NODE.JS 20"
    print_status "Configurando repositório e instalando Node.js"
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list
    apt update -y && apt install -y nodejs || { print_error "Falha ao instalar Node.js"; return 1; }
    check_success "Node.js instalado"

    # ================= YARN & DEPENDÊNCIAS =================
    print_header "INSTALANDO DEPENDÊNCIAS"
    print_status "Instalando Yarn e dependências Node"
    npm i -g yarn || { print_error "Falha ao instalar Yarn"; return 1; }
    yarn install || { print_error "Falha nas dependências do Yarn"; return 1; }
    check_success "Dependências Node prontas"

    # ================= CONFIGURAÇÃO DO BLUEPRINT =================
    print_header "CONFIGURANDO BLUEPRINT"
    print_status "Criando arquivo .blueprintrc"
    cat <<EOF > "$PTERODACTYL_DIRECTORY/.blueprintrc"
WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";
EOF
    check_success ".blueprintrc criado"

    # ================= PERMISSÕES =================
    print_header "AJUSTANDO PERMISSÕES"
    print_status "Aplicando permissões"
    chmod +x "$PTERODACTYL_DIRECTORY/blueprint.sh" || { print_error "Falha de permissão"; return 1; }
    chown -R www-data:www-data "$PTERODACTYL_DIRECTORY"
    check_success "Permissões corrigidas"

    # ================= EXECUTAR BLUEPRINT =================
    print_header "EXECUTANDO INSTALADOR DO BLUEPRINT"
    print_status "Iniciando Blueprint"
    bash "$PTERODACTYL_DIRECTORY/blueprint.sh"

    # ================= CONCLUÍDO =================
    echo -e "\n${VERDE}🎉 Instalação do Blueprint concluída!${NC}"
    echo -e "${AMARELO}Agora você pode aplicar temas e personalizar seu painel.${NC}"
}

# Função: Reinstalar (Apenas reexecutar)
reinstall_blueprint() {
    print_header "REINSTALANDO O BLUEPRINT"
    print_status "Iniciando reinstalação"
    blueprint -rerun-install > /dev/null 2>&1 &
    animate_progress $! "Reinstalando"
    check_success "Reinstalação concluída" "Falha na reinstalação"
}

# Função: Atualizar
update_blueprint() {
    print_header "ATUALIZANDO O BLUEPRINT"
    print_status "Iniciando atualização"
    blueprint -upgrade > /dev/null 2>&1 &
    animate_progress $! "Atualizando"
    check_success "Atualização concluída" "Falha na atualização"
}

# Menu principal
show_menu() {
    clear
    echo -e "${VERDE}"
    cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|
EOF
    echo -e "${NC}"
    echo -e "${CIANO}              INSTALADOR DO BLUEPRINT${NC}"
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e ""
    echo -e "${BRANCO}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BRANCO}║                📋 MENU PRINCIPAL               ║${NC}"
    echo -e "${BRANCO}╠═══════════════════════════════════════════════╣${NC}"
    echo -e "${BRANCO}║   ${VERDE}1)${NC} ${CIANO}Instalação Limpa (Fresh Install)${NC}       ${BRANCO}║${NC}"
    echo -e "${BRANCO}║   ${VERDE}2)${NC} ${CIANO}Reinstalar (Rerun Only)${NC}                ${BRANCO}║${NC}"
    echo -e "${BRANCO}║   ${VERDE}3)${NC} ${CIANO}Atualizar Blueprint${NC}                    ${BRANCO}║${NC}"
    echo -e "${BRANCO}║   ${VERDE}0)${NC} ${VERMELHO}Sair${NC}                               ${BRANCO}║${NC}"
    echo -e "${BRANCO}╚═══════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${AMARELO}📝 Selecione uma opção [0-3]: ${NC}"
}

# Execução principal
welcome_animation

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1) install_blueprint ;;
        2) reinstall_blueprint ;;
        3) update_blueprint ;;
        0) 
            echo -e "${VERDE}Saindo do Instalador do Blueprint...${NC}"
            echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${CIANO}      Obrigado por usar BN Cloud! | Discord: eabn8   ${NC}"
            echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            sleep 2
            exit 0 
            ;;
        *) 
            print_error "Opção inválida! Escolha entre 0-3"
            sleep 2
            ;;
    esac
    
    echo -e ""
    read -p "$(echo -e "${AMARELO}Pressione Enter para continuar...${NC}")" -n 1
done