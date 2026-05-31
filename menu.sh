#!/bin/bash

# ============================================================
#   BN CLOUD - MENU PRINCIPAL
#   Feito por BN | Discord: eabn8
# ============================================================

# --- Cores ---
B_RED='\033[1;31m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_CYAN='\033[1;36m'
B_WHITE='\033[1;37m'
NC='\033[0m'

# --- Links dos scripts ---
VM_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/vm1bet.sh"
CLOUDFLARED_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/cloudflare.sh"
PTERODACTYL_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/pterocly.sh"
AIRLINK_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/airlink.sh"
PTERODACTYL_UPDATER_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/updater.sh"
WINGS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/wings.sh"
BLUEPRINT_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/blueprint.sh"
SETUP_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/main/setup.sh"
ATIVIDADE_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/main/24h.sh"

# --- Teclado ---
exec < /dev/tty

# --- Animação ---
loading_bar() {
    clear
    echo -e "${B_CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${B_CYAN}║${B_WHITE}         🌐 BN CLOUD INICIALIZANDO         ${B_CYAN}║${NC}"
    echo -e "${B_CYAN}╚══════════════════════════════════════════╝${NC}"
    echo -ne "${B_CYAN}[${NC}"
    for i in {1..30}; do
        if [ $((i % 2)) -eq 0 ]; then
            echo -ne "${B_GREEN}█${NC}"
        else
            echo -ne "${B_CYAN}█${NC}"
        fi
        sleep 0.05
    done
    echo -e "${B_CYAN}]${NC}"
    echo -e "${B_GREEN}  Pronto!${NC}"
    sleep 0.3
}

# --- Banner ---
banner() {
    clear
    echo -e "${B_CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║                                          ║"
    cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|
EOF
    echo -e "║                                          ║"
    echo -e "║      ${B_WHITE}FEITO POR BN | DISCORD: eabn8${B_CYAN} ║"
    echo -e "╚══════════════════════════════════════════╝${NC}"
    echo ""
}

# --- Execução ---
run_remote_script() {
    local url="$1"
    local nome="$2"
    local tmpfile="/tmp/bncloud_$RANDOM.sh"

    echo -e "${B_GREEN}🔗 Baixando $nome...${NC}"
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
        echo -e "${B_RED}⚠️ $nome encerrado com erro (código $saida)${NC}"
    fi
    echo ""
    read -rp "$(echo -e "${B_YELLOW}⏎ Pressione Enter para voltar ao menu...${NC}")"
}

# --- Menu ---
loading_bar

while true; do
    banner
    echo -e "${B_CYAN}────────────── MENU PRINCIPAL ──────────────${NC}"
    printf "${B_GREEN} 1)${B_WHITE} %-35s${NC}\n" "Gerenciador de VMs"
    printf "${B_GREEN} 2)${B_WHITE} %-35s${NC}\n" "Cloudflare Tunnel"
    printf "${B_GREEN} 3)${B_WHITE} %-35s${NC}\n" "Pterodactyl Panel (Instalador)"
    printf "${B_GREEN} 4)${B_WHITE} %-35s${NC}\n" "Airlink Panel"
    printf "${B_GREEN} 5)${B_WHITE} %-35s${NC}\n" "Pterodactyl Updater"
    printf "${B_GREEN} 6)${B_WHITE} %-35s${NC}\n" "Wings Installer"
    printf "${B_GREEN} 7)${B_WHITE} %-35s${NC}\n" "Blueprint Installer"
    printf "${B_GREEN} 8)${B_WHITE} %-35s${NC}\n" "Instalar Dependências"
    printf "${B_GREEN} 9)${B_WHITE} %-35s${NC}\n" "Ativar Sistema 24/7"
    echo ""
    printf "${B_RED} 0)${B_WHITE} %-35s${NC}\n" "Sair"
    echo -e "${B_CYAN}────────────────────────────────────────────${NC}"
    echo -ne "${B_CYAN}➤ ${B_WHITE}Escolha uma opção: ${NC}"
    read -r opcao

    if ! [[ "$opcao" =~ ^[0-9]$ ]]; then
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
        8) run_remote_script "$SETUP_URL" "Instalar Dependências" ;;
        9) run_remote_script "$ATIVIDADE_URL" "Sistema 24/7" ;;
        0)
            clear
            echo -e "${B_GREEN}Obrigado por usar BN Cloud!${NC}"
            echo -e "${B_YELLOW}Até logo! 👋${NC}"
            exit 0
            ;;
    esac
done
