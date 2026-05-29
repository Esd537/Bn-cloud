#!/usr/bin/env bash
# ===========================================================
#   BN CLOUD - INSTALADOR DE DEPENDÊNCIAS
#   Feito por BN | Discord: eabn8
# ===========================================================
set -euo pipefail

# Cores
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
AZUL='\033[1;34m'
NC='\033[0m'

# Logo BN Cloud
clear
echo -e "${AZUL}"
cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        FEITO POR BN CLOUD | DISCORD: eabn8
EOF
echo -e "${NC}"
echo -e "${AMARELO}=========== Instalador de Dependências ===========${NC}\n"

echo -e "${CIANO}🔧 Iniciando instalação das dependências do Bn Clouds...${NC}"
sleep 1

# Atualizar repositórios
apt-get update -y

# Pacotes essenciais para VMs, rede e utilitários
apt-get install -y \
    qemu-kvm libvirt-daemon-system libvirt-clients virt-manager \
    cloud-init genisoimage \
    curl wget git unzip \
    openssl

# Ativar o serviço de virtualização
systemctl enable --now libvirtd || systemctl enable --now libvirt-daemon || true

echo -e "\n${VERDE}✅ Instalação concluída com sucesso!${NC}"
echo -e "${YELLOW}Agora você pode criar suas VMs com ou sem interface gráfica pelo menu principal.${NC}"
