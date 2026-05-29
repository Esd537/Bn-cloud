#!/bin/bash

# ============================================================
#   BN CLOUD - MENU PRINCIPAL
#   Feito por BN | Discord: eabn8
# ============================================================

# Cores
VERDE="\033[1;32m"
VERMELHO="\033[1;31m"
AMARELO="\033[1;33m"
AZUL="\033[1;34m"
CIANO="\033[1;36m"
NEGRITO="\033[1m"
RESET="\033[0m"

# Links dos scripts (substitua com os links raw do GitHub)
VM_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/vm1bet.sh"
CLOUDFLARED_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/cloudflare.sh"
PTERODACTYL_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/pterocly.sh"
AIRLINK_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/airlink.sh"
PTERODACTYL_UPDATER_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/updater.sh"
WINGS_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/wings.sh"
BLUEPRINT_URL="https://raw.githubusercontent.com/Esd537/Bn-cloud/refs/heads/main/blueprint.sh"

# Função para baixar e executar um script remoto
run_remote_script() {
    local url="$1"
    local nome="$2"
    echo -e "${CIANO}🔗 Baixando $nome...${RESET}"
    curl -sSL "$url" | bash
    echo ""
    read -rp "$(echo -e "${AMARELO}⏎ Pressione Enter para voltar ao menu...${RESET}")"
}

# Menu principal
while true; do
    clear
    echo -e "${VERDE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║        🌐 BN CLOUD - MENU PRINCIPAL      ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║ Feito por BN | Discord: eabn8           ║"
    echo "║                                          ║"
    echo -e "║ ${NEGRITO}1) Gerenciador de VMs${RESET}${VERDE}                ║"
    echo -e "║ ${NEGRITO}2) Cloudflare Tunnel${RESET}${VERDE}                ║"
    echo -e "║ ${NEGRITO}3) Pterodactyl Panel (Instalador)${RESET}${VERDE}   ║"
    echo -e "║ ${NEGRITO}4) Airlink Panel${RESET}${VERDE}                     ║"
    echo -e "║ ${NEGRITO}5) Pterodactyl Updater${RESET}${VERDE}               ║"
    echo -e "║ ${NEGRITO}6) Wings Installer${RESET}${VERDE}                   ║"
    echo -e "║ ${NEGRITO}7) Blueprint Installer${RESET}${VERDE}               ║"
    echo -e "║ ${NEGRITO}0) Sair${RESET}${VERDE}                              ║"
    echo "╚══════════════════════════════════════════╝"
    echo -ne "${RESET}${AZUL}Escolha uma opção: ${RESET}"
    read -r opcao

    case $opcao in
        1) run_remote_script "$VM_URL" "Gerenciador de VMs" ;;
        2) run_remote_script "$CLOUDFLARED_URL" "Cloudflare Tunnel" ;;
        3) run_remote_script "$PTERODACTYL_URL" "Pterodactyl Panel" ;;
        4) run_remote_script "$AIRLINK_URL" "Airlink Panel" ;;
        5) run_remote_script "$PTERODACTYL_UPDATER_URL" "Pterodactyl Updater" ;;
        6) run_remote_script "$WINGS_URL" "Wings Installer" ;;
        7) run_remote_script "$BLUEPRINT_URL" "Blueprint Installer" ;;
        0) clear; echo -e "${VERDE}Até logo! 👋${RESET}"; exit 0 ;;
        *) echo -e "${VERMELHO}❌ Opção inválida!${RESET}"; sleep 1 ;;
    esac
done
