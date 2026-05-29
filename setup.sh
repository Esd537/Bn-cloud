#!/usr/bin/env bash
# ===========================================================
# ⚙️ Bn Clouds - Instalação de Dependências
# Autor: discord:eabn8
# ===========================================================

set -euo pipefail

# ---------- CORES ----------
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Iniciando instalação das dependências do Bn Clouds...${NC}"
sleep 1

apt-get update -y
apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager cloud-init genisoimage curl

systemctl enable --now libvirtd || systemctl enable --now libvirt-daemon || true

echo -e "${GREEN}✅ Instalação concluída com sucesso!${NC}"
echo -e "${YELLOW}Agora você pode criar suas VMs com ou sem interface gráfica pelo menu principal.${NC}"
