#!/bin/bash
set -e

# ============================================================
#   PTERODACTYL WINGS INSTALLER
#   Feito por BN Cloud | Discord: eabn8
# ============================================================

# Cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Sem cor

# Elementos visuais
CHECK="✓"
CROSS="✗"
ARROW="➤"

# Função para imprimir cabeçalhos
print_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}${CIANO}   $1${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════╝${NC}"
}

print_status() {
    echo -e "${AMARELO}${ARROW} $1...${NC}"
}

print_success() {
    echo -e "${VERDE}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${VERMELHO}${CROSS} $1${NC}"
}

# Verifica se o comando anterior foi bem-sucedido
check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
        return 0
    else
        print_error "$2"
        return 1
    fi
}

# Limpa a tela e exibe a logo BN Cloud
clear
echo -e "${VERDE}"
cat <<'EOF'
   ____  _   _    ____ _                 _
  | __ )| \ | |  / ___| | ___  _   _  __| |
  |  _ \|  \| | | |   | |/ _ \| | | |/ _` |
  | |_) | |\  | | |___| | (_) | |_| | (_| |
  |____/|_| \_|  \____|_|\___/ \__,_|\__,_|

        FEITO POR BN CLOUD | DISCORD: eabn8
EOF
echo -e "${NC}"
echo -e "${AMARELO}=========== Pterodactyl Wings Installer ===========${NC}"
echo

# Verifica se está rodando como root
if [ "$EUID" -ne 0 ]; then
    print_error "Execute como root"
    exit 1
fi

# ------------------------
# 1. Instalar Docker
# ------------------------
print_header "INSTALANDO DOCKER"
print_status "Instalando Docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
check_success "Docker instalado"

print_status "Iniciando serviço Docker"
sudo systemctl enable --now docker > /dev/null 2>&1
check_success "Serviço Docker iniciado"

# ------------------------
# 2. Atualizar GRUB
# ------------------------
print_header "ATUALIZANDO SISTEMA"
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    print_status "Atualizando GRUB"
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' $GRUB_FILE
    sudo update-grub > /dev/null 2>&1
    check_success "GRUB atualizado"
fi

# ------------------------
# 3. Instalar Wings
# ------------------------
print_header "INSTALANDO WINGS"
print_status "Criando diretórios"
sudo mkdir -p /etc/pterodactyl
check_success "Diretórios criados"

print_status "Detectando arquitetura"
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then 
    ARCH="amd64"
else 
    ARCH="arm64"
fi

print_status "Baixando Wings"
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH" > /dev/null 2>&1
check_success "Wings baixado"

print_status "Configurando permissões"
sudo chmod u+x /usr/local/bin/wings
check_success "Permissões definidas"

# ------------------------
# 4. Serviço do Wings
# ------------------------
print_header "CONFIGURANDO SERVIÇO"
print_status "Criando arquivo de serviço"
WINGS_SERVICE_FILE="/etc/systemd/system/wings.service"
sudo tee $WINGS_SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
check_success "Arquivo de serviço criado"

print_status "Recarregando systemd"
sudo systemctl daemon-reload > /dev/null 2>&1
check_success "Systemd recarregado"

print_status "Ativando serviço"
sudo systemctl enable wings > /dev/null 2>&1
check_success "Serviço ativado"

# ------------------------
# 5. Certificado SSL
# ------------------------
print_header "GERANDO SSL"
print_status "Criando certificado"
sudo mkdir -p /etc/certs/wing
cd /etc/certs/wing || exit
sudo openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
check_success "Certificado SSL gerado"

# ------------------------
# 6. Comando auxiliar 'wing'
# ------------------------
print_header "CRIANDO COMANDO AUXILIAR"
print_status "Criando comando wing"
sudo tee /usr/local/bin/wing > /dev/null <<'EOF'
#!/bin/bash
echo -e "\033[1;33mℹ️  Comando auxiliar do Wings\033[0m"
echo -e "\033[1;36mPara iniciar o Wings, execute:\033[0m"
echo -e "    \033[1;32msudo systemctl start wings\033[0m"
echo -e "\033[1;36mPara verificar o status:\033[0m"
echo -e "    \033[1;32msudo systemctl status wings\033[0m"
echo -e "\033[1;36mPara ver os logs:\033[0m"
echo -e "    \033[1;32msudo journalctl -u wings -f\033[0m"
echo -e "\033[1;33m⚠️  Certifique-se de mapear a porta 8080 do Node → 443.\033[0m"
EOF

print_status "Ajustando permissões do comando auxiliar"
sudo chmod +x /usr/local/bin/wing
check_success "Comando auxiliar criado" "Falha ao criar comando auxiliar"

# ------------------------
# Instalação concluída
# ------------------------
print_header "INSTALAÇÃO CONCLUÍDA"
echo -e "${VERDE}🎉 Wings instalado com sucesso!${NC}"
echo -e ""
echo -e "${AMARELO}📋 PRÓXIMOS PASSOS:${NC}"
echo -e "  ${CIANO}1.${NC} Configure o Wings com os dados do seu painel"
echo -e "  ${CIANO}2.${NC} Inicie o serviço: ${VERDE}sudo systemctl start wings${NC}"
echo -e "  ${CIANO}3.${NC} Use o comando auxiliar: ${VERDE}wing${NC}"
echo -e ""

# ------------------------
# 7. Configuração automática opcional
# ------------------------
echo -e "${AMARELO}🔧 AUTO-CONFIGURAÇÃO${NC}"
read -p "$(echo -e "${AMARELO}Deseja configurar o Wings automaticamente agora? (s/N): ${NC}")" AUTO_CONFIG

if [[ "$AUTO_CONFIG" =~ ^[Ss]$ ]]; then
    print_header "AUTO-CONFIGURANDO WINGS"
    
    echo -e "${AMARELO}Forneça as seguintes informações do seu painel Pterodactyl:${NC}"
    echo -e ""
    
    read -p "$(echo -e "${CIANO}UUID: ${NC}")" UUID
    read -p "$(echo -e "${CIANO}Token ID: ${NC}")" TOKEN_ID
    read -p "$(echo -e "${CIANO}Token: ${NC}")" TOKEN
    read -p "$(echo -e "${CIANO}URL do Painel (ex: https://panel.exemplo.com): ${NC}")" REMOTE

    print_status "Criando configuração do Wings"
    mkdir -p /etc/pterodactyl
    tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG

    check_success "Configuração salva em /etc/pterodactyl/config.yml" "Falha ao salvar configuração"
    
    print_status "Iniciando serviço Wings"
    systemctl start wings
    check_success "Serviço Wings iniciado" "Falha ao iniciar Wings"
    
    echo -e ""
    echo -e "${VERDE}✅ Configuração automática concluída com sucesso!${NC}"
    echo -e ""
    echo -e "${AMARELO}Verifique o status com:${NC} ${VERDE}systemctl status wings${NC}"
    echo -e "${AMARELO}Veja os logs com:${NC} ${VERDE}journalctl -u wings -f${NC}"
else
    echo -e ""
    echo -e "${AMARELO}⚠️  Configuração automática ignorada.${NC}"
    echo -e "${AMARELO}Para configurar manualmente:${NC}"
    echo -e "  1. Edite ${VERDE}/etc/pterodactyl/config.yml${NC}"
    echo -e "  2. Inicie o Wings: ${VERDE}sudo systemctl start wings${NC}"
    echo -e ""
    echo -e "${AMARELO}Use o comando auxiliar:${NC} ${VERDE}wing${NC} ${AMARELO}para referência rápida${NC}"
fi

echo -e ""
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CIANO}      Obrigado por usar BN Cloud! | Discord: eabn8   ${NC}"
echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""