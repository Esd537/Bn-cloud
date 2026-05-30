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
NC='\033[0m'   # Sem cor (fundo padrão escuro)

# --- Links dos scripts ---
VM_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/vm1bet.sh"
CLOUDFLARED_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/cloudflare.sh"
PTERODACTYL_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/pterocly.sh"
AIRLINK_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/airlink.sh"
PTERODACTYL_UPDATER_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/updater.sh"
WINGS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/wings.sh"
BLUEPRINT_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/blueprint.sh"
DEPS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/deps.sh"

# --- Força leitura do teclado (evita interferência do pipe) ---
exec < /dev/tty

# ===============================
#   ANIMAÇÃO DE CARREGAMENTO
# ===============================
loading_bar() {
    clear
    echo -e "${B_GREEN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         🌐 BN CLOUD INICIALIZANDO        ║"
    echo "╚══════════════════════════════════════════╝"
    echo -ne "${B_GREEN}[${NC}"
    for i in {1..40}; do
        echo -ne "${B_GREEN}█${NC}"
        sleep 0.03
    done
    echo -e "${B_GREEN}]${NC}"
    sleep 0.5
    echo -e "${B_WHITE} Sistema pronto!${NC}"
    sleep 1
}

# ===============================
#   BANNER PRINCIPAL
# ===============================
banner() {
    clear
    echo -e "${B_GREEN}"
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
    echo -e "║      ${B_WHITE}FEITO POR BN | DISCORD: eabn8${B_GREEN}     ║"
    echo -e "╚══════════════════════════════════════════╝${NC}"
    echo ""
}

# ===============================
#   FUNÇÃO AUXILIAR DE EXECUÇÃO
# ===============================
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
        echo -e "${B_RED}⚠️ $nome encerrado com erro (código $saida)${NC}"
    fi
    echo ""
    read -rp "$(echo -e "${B_YELLOW}⏎ Pressione Enter para voltar ao menu...${NC}")"
}

# ===============================
#   MENU PRINCIPAL
# ===============================

# Mostra animação apenas uma vez
loading_bar

while true; do
    banner
    echo -e "${B_GREEN}────────────── MENU PRINCIPAL ──────────────${NC}"
    printf "${B_GREEN} 1)${B_WHITE} %-35s${NC}\n" "Gerenciador de VMs"
    printf "${B_GREEN} 2)${B_WHITE} %-35s${NC}\n" "Cloudflare Tunnel"
    printf "${B_GREEN} 3)${B_WHITE} %-35s${NC}\n" "Pterodactyl Panel (Instalador)"
    printf "${B_GREEN} 4)${B_WHITE} %-35s${NC}\n" "Airlink Panel"
    printf "${B_GREEN} 5)${B_WHITE} %-35s${NC}\n" "Pterodactyl Updater"
    printf "${B_GREEN} 6)${B_WHITE} %-35s${NC}\n" "Wings Installer"
    printf "${B_GREEN} 7)${B_WHITE} %-35s${NC}\n" "Blueprint Installer"
    printf "${B_GREEN} 8)${B_WHITE} %-35s${NC}\n" "Instalar Dependências"
    echo ""
    printf "${B_RED} 0)${B_WHITE} %-35s${NC}\n" "Sair"
    echo -e "${B_GREEN}────────────────────────────────────────────${NC}"
    echo -ne "${B_CYAN}Escolha uma opção: ${NC}"
    read -r opcao

    # Validação: só números de 0 a 8
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
