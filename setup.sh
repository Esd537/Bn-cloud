#!/usr/bin/env bash
# ===========================================================
#   BN CLOUD - INSTALADOR DE DEPENDÊNCIAS (MULTI-AMBIENTE)
#   Feito por BN | Discord: eabn8
# ===========================================================
set -euo pipefail

VERDE='\033[1;32m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
AZUL='\033[1;34m'
NC='\033[0m'

clear
echo -e "${AZUL}"
cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|
EOF
echo -e "${NC}"
echo -e "${AMARELO}=========== Instalador de Dependências ===========${NC}\n"

# --- Detecção do ambiente ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

# --- Ambiente Nix / IDX ---
if command -v nix-env >/dev/null 2>&1 || [ -d /home/user/.idx ]; then
    echo -e "${CIANO}Ambiente Nix/IDX detectado. Criando .idx/dev.nix...${NC}"
    mkdir -p .idx
    cat > .idx/dev.nix <<'NIX'
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
NIX
    echo -e "${VERDE}✅ Arquivo .idx/dev.nix criado.${NC}"
    echo -e "${YELLOW}Recarregue o ambiente IDX para aplicar os pacotes.${NC}"
    exit 0
fi

# --- Ubuntu / Debian ---
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    echo -e "${CIANO}Sistema Ubuntu/Debian detectado. Usando apt...${NC}"
    sudo apt-get update -y
    sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager cloud-init genisoimage curl wget git unzip openssl
    sudo systemctl enable --now libvirtd || sudo systemctl enable --now libvirt-daemon || true
    echo -e "\n${VERDE}✅ Instalação concluída!${NC}"
    exit 0
fi

# --- Fedora / RHEL ---
if [[ "$OS" == "fedora" || "$OS" == "centos" || "$OS" == "rhel" ]]; then
    echo -e "${CIANO}Sistema Fedora/RHEL detectado. Usando dnf...${NC}"
    sudo dnf install -y qemu-kvm libvirt virt-manager cloud-init genisoimage curl wget git unzip openssl
    sudo systemctl enable --now libvirtd || true
    echo -e "\n${VERDE}✅ Instalação concluída!${NC}"
    exit 0
fi

# --- Alpine ---
if [[ "$OS" == "alpine" ]]; then
    echo -e "${CIANO}Sistema Alpine detectado. Usando apk...${NC}"
    sudo apk add qemu-system-x86_64 qemu-img qemu-system-arm libvirt-daemon qemu-kvm libvirt-client virt-manager cloud-init cdrkit curl wget git unzip openssl
    sudo rc-update add libvirtd
    sudo rc-service libvirtd start
    echo -e "\n${VERDE}✅ Instalação concluída!${NC}"
    exit 0
fi

# --- Sistema desconhecido ---
echo -e "${AMARELO}Sistema não identificado automaticamente.${NC}"
echo -e "${YELLOW}Tente instalar manualmente os pacotes necessários.${NC}"
exit 1
