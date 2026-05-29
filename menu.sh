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
RESET="\033[0m"

# Links dos scripts (já configurados)
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
    if ! curl -sSL "$url" | bash; then
        echo -e "${VERMELHO}❌ Falha ao executar $nome${RESET}"
    fi
    echo ""
    read -rp "$(echo -e "${AMARELO}⏎ Pressione Enter para voltar ao menu...${RESET}")"
}

# Loop principal
while true; do
    clear
    echo -e "${VERDE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║        🌐 BN CLOUD - MENU PRINCIPAL      ║"
    echo "╠══════════════════════════════════════════╣"
    echo "║ Feito por BN | Discord: eabn8           ║"
    echo "║                                          ║"
    printf "║ 1) %-35s ║\n" "Gerenciador de VMs"
    printf "║ 2) %-35s ║\n" "Cloudflare Tunnel"
    printf "║ 3) %-35s ║\n" "Pterodactyl Panel (Instalador)"
    printf "║ 4) %-35s ║\n" "Airlink Panel"
    printf "║ 5) %-35s ║\n" "Pterodactyl Updater"
    printf "║ 6) %-35s ║\n" "Wings Installer"
    printf "║ 7) %-35s ║\n" "Blueprint Installer"
    echo -e "║                                          ║"
    printf "${VERMELHO}║ 0) %-35s ${VERDE}║\n" "Sair"
    echo "╚══════════════════════════════════════════╝"
    echo -ne "${AZUL}Escolha uma opção: ${RESET}"
    read -r opcao

    # Garante que a opção seja um número de 0 a 7
    if ! [[ "$opcao" =~ ^[0-7]$ ]]; then
        echo -e "${VERMELHO}❌ Opção inválida! Digite um número de 0 a 7.${RESET}"
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
        0) clear; echo -e "${VERDE}Até logo! 👋${RESET}"; exit 0 ;;
    esac
done
