#!/usr/bin/env bash
# ===========================================================
#   BN CLOUD - SISTEMA DE ATIVIDADE 24/7
#   Feito por BN | Discord: eabn8
# ===========================================================
set -euo pipefail

VERDE='\033[1;32m'
AMARELO='\033[1;33m'
CIANO='\033[1;36m'
AZUL='\033[1;34m'
NC='\033[0m'

PASTA_24H="24h"
ARQUIVO="Bncloud"
CAMINHO="$PASTA_24H/$ARQUIVO"
INTERVALO=60

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
echo -e "${AMARELO}=========== Sistema 24/7 BN Cloud ===========${NC}\n"

criar_arquivo() {
    mkdir -p "$PASTA_24H"
    rm -f "$CAMINHO"
    cat > "$CAMINHO" <<'FRASE'
© 2025-2026 BN Cloud. Todos os direitos reservados.
Feito por BN | Discord: eabn8
FRASE
    echo -e "${VERDE}✔ Arquivo $CAMINHO atualizado em $(date '+%H:%M:%S')${NC}"
}

echo -e "${CIANO}🔁 Ciclo de recriação a cada ${INTERVALO}s...${NC}"
echo -e "${AMARELO}Pressione CTRL+C para interromper.${NC}\n"

while true; do
    criar_arquivo
    sleep "$INTERVALO"
done
