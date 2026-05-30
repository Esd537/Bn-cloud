#!/bin/bash

# ============================================================
#   BN CLOUD - MENU PRINCIPAL
#   Feito por BN | Discord: eabn8
# ============================================================

# Cores
B_RED='\033[1;31m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'
B_CYAN='\033[1;36m'
B_WHITE='\033[1;37m'
NC='\033[0m'

# Links dos scripts
VM_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/vm1bet.sh"
CLOUDFLARED_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/cloudflare.sh"
PTERODACTYL_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/pterocly.sh"
AIRLINK_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/airlink.sh"
PTERODACTYL_UPDATER_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/updater.sh"
WINGS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/wings.sh"
BLUEPRINT_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/blueprint.sh"
DEPS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/deps.sh"

# Banner estilizado
banner() {
    clear
    echo -e "${B_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${B_RED}"
    cat << "EOF"
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|
EOF
    echo -e "${NC}"
    echo -e "${B_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${B_WHITE}                  Feito por BN | Discord: eabn8${NC}"
    echo -e "${B_RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Função que baixa e executa script sem travar o teclado
run_remote_script() {
    local url="$1"
    local nome="$2"
    local tmpfile="/tmp/bncloud_$RANDOM.sh"

    echo -e "${B_CYAN}🔗 Baixando $nome...${NC}"
    if ! curl -sSL "$url" -o "$tmpfile"; then
        echo -e "${B_RED}❌ Falha ao baixar $nome${NC}"
        rm -f "$tmpfile"
        read -rp "Pressione Enter..."
        return 1
    fi

    bash "$tmpfile"
    local saida=$?
    rm -f "$tmpfile"

    if [ $saida -ne 0 ]; then
        echo -e "${B_RED}⚠️ $nome terminou com erro (código $saida)${NC}"
    fi
    echo ""
    read -rp "$(echo -e "${B_YELLOW}⏎ Pressione Enter para voltar ao menu...${NC}")"
}

# Menu principal
while true; do
    banner
    echo -e "${B_RED}────────────── MENU PRINCIPAL ──────────────${NC}"
    echo -e "${B_RED} 1)${B_WHITE} Gerenciador de VMs"
    echo -e "${B_RED} 2)${B_WHITE} Cloudflare Tunnel"
    echo -e "${B_RED} 3)${B_WHITE} Pterodactyl Panel (Instalador)"
    echo -e "${B_RED} 4)${B_WHITE} Airlink Panel"
    echo -e "${B_RED} 5)${B_WHITE} Pterodactyl Updater"
    echo -e "${B_RED} 6)${B_WHITE} Wings Installer"
    echo -e "${B_RED} 7)${B_WHITE} Blueprint Installer"
    echo -e "${B_RED} 8)${B_WHITE} Instalar Dependências"
    echo -e "${B_RED} 0)${B_WHITE} Sair"
    echo -e "${B_RED}────────────────────────────────────────────${NC}"
    echo -ne "${B_WHITE}Escolha uma opção: ${NC}"
    read -r opcao

    if ! [[ "$opcao" =~ ^[0-8]$ ]]; then
        echo -e "${B_RED}❌ Opção inválida!${NC}"
        sleep 1
        continue
    fi

    case $opcao in
        1) run_remote_script "$VM_URL" "Gerenciador de VMs" ;;
        2) run_remote_script "$CLOUDFLARED_URL" "Cloudflare Tunnel" ;;
        3) run_remote_script "$PTERODACTYL_URL" "Pterodactyl Panel" ;;
        4) run_remote_script "$AIRLINK_URL" "Airlink Panel" ;;
        5) run_remote_script "$PTERODACTYL_UPDATER_URL" "Pterodactyl Updater" ;;
        6) run_remote_script "$WINGS_URL" "Wings Installer" ;;
        7) run_remote_script "$BLUEPRINT_URL" "Blueprint Installer" ;;
        8) run_remote_script "$DEPS_URL" "Instalar Dependências" ;;
        0)
            clear
            echo -e "${B_GREEN}Obrigado por usar BN Cloud!${NC}"
            echo -e "${B_YELLOW}Até logo! 👋${NC}"
            exit 0
            ;;
    esac
done
