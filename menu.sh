#!/usr/bin/env bash
# ===========================================================
# 🌩️ Bn Clouds - Painel de Criação de VMs
# Autor: discord:eabn8
# ===========================================================

set -euo pipefail

# ---------- CORES ----------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
GRAY='\033[0;37m'
NC='\033[0m'

# ---------- BANNER ----------
banner() {
  clear
  echo -e "${MAGENTA}"
  echo "██████╗ ███╗   ██╗      ███╗   ██╗     ██████╗██╗      ██████╗ ██╗   ██╗██████╗ "
  echo "██╔══██╗████╗  ██║      ████╗  ██║    ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗"
  echo "██████╔╝██╔██╗ ██║      ██╔██╗ ██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║"
  echo "██╔══██╗██║╚██╗██║      ██║╚██╗██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║"
  echo "██████╔╝██║ ╚████║      ██║ ╚████║    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝"
  echo "╚═════╝ ╚═╝  ╚═══╝      ╚═╝  ╚═══╝     ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ "
  echo -e "              ${CYAN}🌩️ Bn Clouds - Criador de VMs${NC}"
  echo -e "                    ${GRAY}Feito por: discord:eabn8${NC}"
  echo
}

# ---------- MENU PRINCIPAL ----------
main_menu() {
  while true; do
    banner
    echo -e "${CYAN}Selecione uma opção:${NC}"
    echo -e "  ${YELLOW}[A]${NC} 🖥️ Criar VM sem interface gráfica"
    echo -e "  ${YELLOW}[B]${NC} 💻 Criar VM com interface gráfica (Windows e outras)"
    echo -e "  ${YELLOW}[C]${NC} ⚙️ Instalar dependências do sistema"
    echo -e "  ${YELLOW}[D]${NC} ❌ Sair"
    echo
    read -rp "Digite a opção desejada (A-D): " opt

    case "$opt" in
      A|a)
        echo -e "${BLUE}[INFO]${NC} Iniciando criação de VM sem GUI..."
        bash <(curl -s "COLOCA_AQUI_O_LINK_DO_SCRIPT_SEM_GUI")
        ;;
      B|b)
        echo -e "${BLUE}[INFO]${NC} Iniciando criação de VM com GUI..."
        bash <(curl -s "COLOCA_AQUI_O_LINK_DO_SCRIPT_COM_GUI")
        ;;
      C|c)
        echo -e "${BLUE}[INFO]${NC} Instalando dependências necessárias..."
        bash <(curl -s "COLOCA_AQUI_O_LINK_DO_SCRIPT_DE_DEPENDENCIAS")
        ;;
      D|d)
        echo -e "${RED}Saindo do Bn Clouds... Até logo! 👋${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Opção inválida. Tente novamente.${NC}"
        sleep 1
        ;;
    esac
  done
}

main_menu
