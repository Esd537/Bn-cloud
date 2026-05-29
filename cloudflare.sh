#!/bin/bash

# ==========================================
#   CLOUDFLARE TUNNEL - INSTALADOR & REMOVEDOR
#   Traduzido por BN Cloud | Discord: eabn8
# ==========================================

VERDE="\033[1;32m"
VERMELHO="\033[1;31m"
AMARELO="\033[1;33m"
AZUL="\033[1;34m"
CIANO="\033[1;36m"
RESET="\033[0m"

pausa() {
    read -rp "Pressione Enter para continuar..."
}

instalar_cloudflared() {
    clear
    echo -e "${AZUL}┌────────────────────────────────────┐"
    echo -e "│      Instalando o Cloudflared      │"
    echo -e "└────────────────────────────────────┘${RESET}"

    # Adicionar repositório e instalar
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
        | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' \
        | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

    sudo apt update
    sudo apt install -y cloudflared

    if ! command -v cloudflared >/dev/null 2>&1; then
        echo -e "${VERMELHO}✘ Falha na instalação do Cloudflared${RESET}"
        pausa
        return
    fi

    echo -e "${VERDE}✔ Cloudflared instalado com sucesso${RESET}"
    echo ""

    # Verificar serviço existente
    if systemctl list-units --type=service | grep -q cloudflared; then
        echo -e "${AMARELO}⚠ Serviço Cloudflared antigo detectado${RESET}"
        echo -e "${CIANO}→ Removendo serviço antigo...${RESET}"
        sudo cloudflared service uninstall
        echo -e "${VERDE}✔ Serviço antigo removido${RESET}"
        echo ""
    fi

    # Solicitar token ou comando
    echo -e "${AZUL}🔑 Cole o token do Cloudflare Tunnel"
    echo -e "(apenas o token ou o comando completo)${RESET}"
    read -rp "> " ENTRADA_USUARIO

    # Limpar entrada (remover comando se colado)
    CF_TOKEN=$(echo "$ENTRADA_USUARIO" \
        | sed 's/sudo cloudflared service install //g' \
        | sed 's/cloudflared service install //g' \
        | xargs)

    if [[ -z "$CF_TOKEN" ]]; then
        echo -e "${VERMELHO}✘ Token inválido ou vazio${RESET}"
        pausa
        return
    fi

    echo -e "${CIANO}🚀 Instalando serviço Cloudflared...${RESET}"
    sudo cloudflared service install "$CF_TOKEN"

    sleep 1

    if systemctl is-active --quiet cloudflared; then
        echo -e "${VERDE}✔ Serviço Cloudflared instalado e em execução${RESET}"
    else
        echo -e "${AMARELO}⚠ Serviço instalado, mas não está rodando${RESET}"
        echo -e "${AMARELO}→ Verifique com: systemctl status cloudflared${RESET}"
    fi

    pausa
}

remover_cloudflared() {
    clear
    echo -e "${AZUL}┌────────────────────────────────────┐"
    echo -e "│     Removendo o Cloudflared        │"
    echo -e "└────────────────────────────────────┘${RESET}"

    sudo cloudflared service uninstall 2>/dev/null
    sudo apt remove -y cloudflared
    sudo rm -f /etc/apt/sources.list.d/cloudflared.list
    sudo rm -f /usr/share/keyrings/cloudflare-main.gpg

    echo -e "${VERDE}✔ Cloudflared removido completamente${RESET}"
    pausa
}

# ================= MENU =================

while true; do
    clear
    echo -e "${AMARELO}"
    echo "╔═════════════════════════════════════════════╗"
    echo "║      GERENCIADOR CLOUDFLARED - BN CLOUD     ║"
    echo "╠═════════════════════════════════════════════╣"
    echo "║                                             ║"
    echo -e "║ ${VERDE}1) Instalar / Configurar Tunnel${RESET}${AMARELO}         ║"
    echo "║                                             ║"
    echo -e "║ ${VERMELHO}2) Desinstalar completamente${RESET}${AMARELO}            ║"
    echo "║                                             ║"
    echo "║ 3) Sair                                     ║"
    echo "╚═════════════════════════════════════════════╝"
    echo -ne "${AZUL}Selecione uma opção: ${RESET}"
    read opcao

    case $opcao in
        1) instalar_cloudflared ;;
        2) remover_cloudflared ;;
        3) clear; exit ;;
        *) echo -e "${VERMELHO}Opção inválida!${RESET}"; sleep 1 ;;
    esac
done