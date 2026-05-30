#!/usr/bin/env bash
# ===========================================================
#   BN CLOUD - INSTALADOR DE DEPENDÊNCIAS (NIX + APT)
#   Feito por BN | Discord: eabn8
# ===========================================================
set -euo pipefail

# Cores
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
AZUL='\033[1;34m'
VERMELHO='\033[1;31m'
NC='\033[0m'

# Banner
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

# Detecta ambiente
if command -v nix-shell &>/dev/null || [ -d /home/user/.idx ] || [ -d /home/idx ]; then
    # -------------------------------
    # AMBIENTE NIX / GOOGLE IDX
    # -------------------------------
    echo -e "${CIANO}🔧 Ambiente Nix/IDX detectado. Criando .idx/dev.nix...${NC}"
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

    echo -e "${VERDE}✅ Arquivo .idx/dev.nix criado com sucesso!${NC}"
    echo -e "${AMARELO}ℹ️  Recarregue o ambiente do IDX para aplicar os pacotes.${NC}"

else
    # -------------------------------
    # AMBIENTE LINUX TRADICIONAL (APT)
    # -------------------------------
    echo -e "${CIANO}🔧 Instalando dependências via APT...${NC}"

    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${VERMELHO}❌ Este script precisa ser executado como root ou com sudo.${NC}"
        exit 1
    fi

    apt-get update -y
    apt-get install -y \
        qemu-kvm libvirt-daemon-system libvirt-clients virt-manager \
        cloud-init genisoimage \
        curl wget git unzip \
        openssl

    systemctl enable --now libvirtd 2>/dev/null || systemctl enable --now libvirt-daemon 2>/dev/null || true

    echo -e "${VERDE}✅ Pacotes instalados com sucesso!${NC}"
fi

echo -e "${AMARELO}🎉 Agora você pode continuar usando o menu principal.${NC}"
