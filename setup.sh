#!/usr/bin/env bash
# ===========================================================
#   BN CLOUD - SETUP NIX / IDX
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
echo -e "${AMARELO}=========== Setup de Dependências (Nix) ===========${NC}\n"

echo -e "${CIANO}🔧 Criando configuração do ambiente Nix...${NC}"

# Cria a pasta .idx (se não existir)
mkdir -p .idx

# Escreve o arquivo dev.nix com os pacotes solicitados
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
echo -e "${AMARELO}Agora recarregue o ambiente do IDX para aplicar os pacotes.${NC}"
